import {createHmac,timingSafeEqual} from 'node:crypto';
import {readFileSync} from 'node:fs';
const fishCatalogue=JSON.parse(readFileSync(new URL('../content/fishing.json',import.meta.url),'utf8')).fish;
export const RANK_IDS=['rank_week_damage','rank_week_fish','rank_all_damage'];
const ID=/^[a-f0-9]{32}$/;
const calendar=new Intl.DateTimeFormat('en-CA',{timeZone:'America/Edmonton',year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',second:'2-digit',hourCycle:'h23'});
function parts(ms){return Object.fromEntries(calendar.formatToParts(new Date(ms)).filter(x=>x.type!=='literal').map(x=>[x.type,Number(x.value)]));}
function midnight(civil){const target=Date.parse(civil+'T00:00:00Z');let at=target;for(let i=0;i<3;i++){const p=parts(at);at+=target-Date.UTC(p.year,p.month-1,p.day,p.hour,p.minute,p.second);}return at;}
export function rankWeek(ms=Date.now()){const p=parts(ms),day=Date.UTC(p.year,p.month-1,p.day),dow=new Date(day).getUTCDay(),start=day-((dow+6)%7)*86400000,week=new Date(start).toISOString().slice(0,10);return {week,start:midnight(week),end:midnight(new Date(start+7*86400000).toISOString().slice(0,10))};}
export const rankSchema=`CREATE TABLE IF NOT EXISTS crossroads_cosmetic_lifetime(profile text PRIMARY KEY,damage double precision NOT NULL CHECK(damage>=0),reached_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS crossroads_cosmetic_week(week date NOT NULL,profile text NOT NULL,damage double precision NOT NULL CHECK(damage>=0),fish double precision NOT NULL CHECK(fish>=0),damage_at timestamptz NOT NULL DEFAULT now(),fish_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(week,profile));
CREATE INDEX IF NOT EXISTS crossroads_cosmetic_damage ON crossroads_cosmetic_week(week,damage DESC);
CREATE INDEX IF NOT EXISTS crossroads_cosmetic_fish ON crossroads_cosmetic_week(week,fish DESC);`;
export function postgresRanks(pool){return {
 async submit(id,p){await pool.query(`WITH lifetime AS (INSERT INTO crossroads_cosmetic_lifetime(profile,damage) VALUES($1,$2) ON CONFLICT(profile) DO UPDATE SET damage=GREATEST(crossroads_cosmetic_lifetime.damage,EXCLUDED.damage),reached_at=CASE WHEN EXCLUDED.damage>crossroads_cosmetic_lifetime.damage THEN now() ELSE crossroads_cosmetic_lifetime.reached_at END RETURNING profile)
 INSERT INTO crossroads_cosmetic_week(week,profile,damage,fish) VALUES($3,$1,$4,$5) ON CONFLICT(week,profile) DO UPDATE SET damage=GREATEST(crossroads_cosmetic_week.damage,EXCLUDED.damage),fish=GREATEST(crossroads_cosmetic_week.fish,EXCLUDED.fish),damage_at=CASE WHEN EXCLUDED.damage>crossroads_cosmetic_week.damage THEN now() ELSE crossroads_cosmetic_week.damage_at END,fish_at=CASE WHEN EXCLUDED.fish>crossroads_cosmetic_week.fish THEN now() ELSE crossroads_cosmetic_week.fish_at END`,[id,p.lifetime,p.week,p.damage,p.fish]);},
 async ranks(id,week){const q=await pool.query(`WITH d AS(SELECT profile,row_number() OVER(ORDER BY damage DESC,damage_at,profile)::int rank FROM crossroads_cosmetic_week WHERE week=$2 AND damage>0),f AS(SELECT profile,row_number() OVER(ORDER BY fish DESC,fish_at,profile)::int rank FROM crossroads_cosmetic_week WHERE week=$2 AND fish>0),a AS(SELECT profile,row_number() OVER(ORDER BY damage DESC,reached_at,profile)::int rank FROM crossroads_cosmetic_lifetime WHERE damage>0) SELECT (SELECT rank FROM d WHERE profile=$1) week_damage,(SELECT rank FROM f WHERE profile=$1) week_fish,(SELECT rank FROM a WHERE profile=$1) all_damage`,[id,week]);return q.rows[0];}
};}
function signature(secret,text){return createHmac('sha256',secret).update(text).digest('base64url');}
export function rankTicket(secret,claims){const text=Buffer.from(JSON.stringify(claims)).toString('base64url');return text+'.'+signature(secret,text);}
export function verifyRankTicket(secret,token,now=Date.now()){try{if(secret.length<32||typeof token!=='string'||token.length>2048)return null;const [text,sig]=token.split('.'),a=Buffer.from(sig||'','base64url'),b=Buffer.from(signature(secret,text),'base64url');if(a.length!==b.length||!timingSafeEqual(a,b))return null;const p=JSON.parse(Buffer.from(text,'base64url'));if(!Number.isFinite(p.exp)||p.exp<=now||p.exp>now+95000||p.week!==rankWeek(now).week||!Array.isArray(p.badges)||p.badges.some(x=>!RANK_IDS.includes(x)))return null;return p;}catch{return null;}}
export function cleanRankCosmetic(value,secret,now=Date.now()){if(!value||typeof value!=='object'||Array.isArray(value))return {};const out={...value},proof=verifyRankTicket(secret,out.rank_ticket,now);delete out.rank_ticket;delete out.rank_badges;delete out.rank_until;delete out.rank_week;const enabled=Array.isArray(out.rank_enabled)?out.rank_enabled:[];delete out.rank_enabled;if(proof){out.rank_badges=proof.badges.filter(x=>enabled.includes(x));out.rank_until=Math.floor(proof.exp/1000);out.rank_week=proof.week;}return out;}
export function cleanScores(raw,now=Date.now()){const w=rankWeek(now);if(!raw||!ID.test(raw.profile||'')||raw.version!==1)throw Error('Invalid profile');if(raw.week!==w.week)throw Error('Week changed');for(const k of ['lifetime','damage','fish'])if(typeof raw[k]!=='number'||!Number.isFinite(raw[k])||raw[k]<0||raw[k]>(k==='fish'?10000:1e12))throw Error('Invalid score');if(raw.damage>raw.lifetime)throw Error('Weekly damage exceeds lifetime');if(raw.fish>0&&(!Object.hasOwn(fishCatalogue,raw.fish_species)||raw.fish>fishCatalogue[raw.fish_species].max_kg*4+.01))throw Error('Invalid fish size');return {profile:raw.profile,week:w.week,lifetime:raw.lifetime,damage:raw.damage,fish:raw.fish};}
export function createCosmeticRankings({pool,secret=process.env.REPORT_SIGNING_SECRET||'',now=()=>Date.now(),store}={}){
 let ready=false,pending=0,retryAt=0;const configured=!!(pool||store)&&secret.length>=32,limits=new Map();store=store||(pool?postgresRanks(pool):null);
 const init=async()=>{try{if(pool)await pool.query(rankSchema);ready=configured;}catch{ready=false;}};
 const initialized=configured?init():Promise.resolve();
 const prune=setInterval(()=>{if(ready&&pool&&pending<2)pool.query("DELETE FROM crossroads_cosmetic_week WHERE week < current_date - interval '56 days'").catch(()=>{});for(const [k,v]of limits)if(now()-v.at>120000)limits.delete(k);},3600000);prune.unref();
 function send(res,status,data,headers={}){res.writeHead(status,{'Content-Type':'application/json','Cache-Control':'no-store',...headers});res.end(JSON.stringify(data));}
 async function handle(req,res){const url=new URL(req.url,'http://localhost');if(url.pathname!=='/cosmetics/sync')return false;
  const origin=req.headers.origin||'',permitted=!origin||/^https:\/\/([a-z0-9-]+\.)*(itch\.zone|itch\.io)$/.test(origin)||(process.env.REPORT_ALLOWED_ORIGIN||'').split(',').includes(origin)||(process.env.FX_LOCAL_TEST==='1'&&/^http:\/\/127\.0\.0\.1:\d+$/.test(origin));
  if(!permitted){send(res,403,{error:'Origin rejected'});req.resume();return true;}if(origin){res.setHeader('Access-Control-Allow-Origin',origin);res.setHeader('Vary','Origin');}
  if(req.method==='OPTIONS'){res.writeHead(204,{'Access-Control-Allow-Methods':'POST','Access-Control-Allow-Headers':'content-type'});res.end();return true;}
  if(req.method!=='POST'){send(res,405,{error:'POST required'});return true;}
  if(!ready&&configured&&now()>retryAt){retryAt=now()+15000;void init();}if(!ready){send(res,503,{error:'Rankings unavailable'});req.resume();return true;}
  const ip=createHmac('sha256',secret).update(req.socket.remoteAddress||'unknown').digest('hex'),rate=limits.get(ip)||{at:now(),count:0};if(now()-rate.at>60000){rate.at=now();rate.count=0;}limits.set(ip,rate);if(limits.size>2048)limits.delete(limits.keys().next().value);
  if(++rate.count>600||pending>=3){send(res,429,{error:'Try again later'},{'Retry-After':'15'});req.resume();return true;}
  pending++;const chunks=[];let size=0;const timer=setTimeout(()=>req.destroy(),5000);timer.unref();
  try{for await(const part of req){size+=part.length;if(size>4096){send(res,413,{error:'Too large'});req.destroy();return true;}chunks.push(part);}
   let p;try{p=cleanScores(JSON.parse(Buffer.concat(chunks)),now());}catch(e){send(res,e.message==='Week changed'?409:400,{error:e.message,week:rankWeek(now()).week,week_start:Math.floor(rankWeek(now()).start/1000),reset_at:Math.floor(rankWeek(now()).end/1000),server_time:Math.floor(now()/1000)});return true;}
   const id=createHmac('sha256',secret).update('cosmetics:'+p.profile).digest('hex');await store.submit(id,p);const ranks=await store.ranks(id,p.week),w=rankWeek(now());
   // Do not issue last week's award if midnight passed while the database was busy.
   if(w.week!==p.week){send(res,409,{error:'Week changed',week:w.week,week_start:Math.floor(w.start/1000),reset_at:Math.floor(w.end/1000),server_time:Math.floor(now()/1000)});return true;}
   const badges=[];if(ranks.week_damage>0&&ranks.week_damage<=10)badges.push(RANK_IDS[0]);if(ranks.week_fish>0&&ranks.week_fish<=10)badges.push(RANK_IDS[1]);if(ranks.all_damage>0&&ranks.all_damage<=5)badges.push(RANK_IDS[2]);
   const exp=Math.min(now()+90000,w.end);send(res,200,{version:1,week:w.week,week_start:Math.floor(w.start/1000),reset_at:Math.floor(w.end/1000),server_time:Math.floor(now()/1000),expires:Math.floor(exp/1000),ranks,badges,rank_ticket:rankTicket(secret,{week:w.week,exp,badges})});
  }catch{if(!res.headersSent)send(res,503,{error:'Rankings unavailable'});}finally{clearTimeout(timer);pending--;}return true;
 }
 return {handle,initialized,status:()=>({configured,ready,pending,weekly_reset:'Monday 00:00 America/Edmonton'}),close(){clearInterval(prune);},cleanCosmetic:value=>cleanRankCosmetic(value,secret,now())};
}
