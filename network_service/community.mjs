import {BUILD} from './release.mjs';
import {fishBoards} from './fish-leaderboards.mjs';
import {brokenRecords} from './record-claims.mjs';
import {namedSchema,submitNamed,namedSnapshot} from './named-records.mjs';
import {createHmac} from 'node:crypto';
import {readFileSync} from 'node:fs';
import {rankWeek} from './cosmetic-rankings.mjs';
const read=p=>JSON.parse(readFileSync(new URL(p,import.meta.url),'utf8'));
const manifest=read('../content/manifest.json'),fish=read('../content/fishing.json').fish,crops=read('../content/gardening.json').seeds;
const grades={'Common':0,'Uncommon':1,'Rare':2,'Very rare':3,'Legendary':4,'Mystical':5};
export const monthKey=(now=Date.now())=>new Intl.DateTimeFormat('en-CA',{timeZone:'America/Edmonton',year:'numeric',month:'2-digit'}).format(new Date(now));
const heroes=new Set(manifest.characters),realms=new Set(manifest.regions);
export const schema=`CREATE TABLE IF NOT EXISTS crossroads_community_fish_accounts(profile text PRIMARY KEY,account text NOT NULL);
CREATE TABLE IF NOT EXISTS crossroads_community_totals(profile text NOT NULL,kind text NOT NULL,key text NOT NULL,value double precision NOT NULL CHECK(value>=0),PRIMARY KEY(profile,kind,key));
CREATE TABLE IF NOT EXISTS crossroads_community_fish(profile text NOT NULL,scope text NOT NULL,species text NOT NULL,kg double precision NOT NULL CHECK(kg>0),reached_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(profile,scope));
CREATE INDEX IF NOT EXISTS crossroads_community_fish_weight ON crossroads_community_fish(scope,kg DESC);
CREATE TABLE IF NOT EXISTS crossroads_community_rarity(profile text NOT NULL,scope text NOT NULL,species text NOT NULL,kg double precision NOT NULL,grade integer NOT NULL,baseweight double precision NOT NULL,PRIMARY KEY(profile,scope));
CREATE TABLE IF NOT EXISTS crossroads_community_crops(profile text NOT NULL,scope text NOT NULL,crop text NOT NULL,kg double precision NOT NULL CHECK(kg>0),PRIMARY KEY(profile,scope,crop));`;
const number=(x,max)=>typeof x==='number'&&Number.isFinite(x)&&x>=0&&x<=max;
export function clean(raw,now=Date.now()){
 if(!raw||raw.version!==1||!/^[a-f0-9]{32}$/.test(raw.profile||''))throw Error('Invalid profile');
 const out={profile:raw.profile,week:rankWeek(now).week,totals:[],fish:[],rarest:[],crops:[],trophies:[]};
 for(const [kind,allowed,max]of [['hero',heroes,1e12],['realm',realms,1e6]]){
  const values=raw[kind==='hero'?'hero_damage':'realm_clears'];if(!values||typeof values!=='object'||Array.isArray(values)||Object.keys(values).length>128)throw Error('Invalid totals');
  for(const [key,value]of Object.entries(values)){if(!allowed.has(key)||!number(value,max)||(kind==='realm'&&!Number.isInteger(value)))throw Error('Invalid total');if(value>0)out.totals.push({kind,key,value});}
 }
 for(const kind of ['solo','coop']){const value=raw.between?.[kind]??0;if(!number(value,1e6)||!Number.isInteger(value))throw Error('Invalid expedition');if(value)out.totals.push({kind:'between',key:kind,value});}
 for(const scope of ['all','week']){
  const entry=raw[scope==='all'?'fish_all':'fish_week'];if(!entry||!entry.kg)continue;
  if(scope==='week'&&raw.week!==out.week)continue;
  if(!Object.hasOwn(fish,entry.species)||!number(entry.kg,Math.min(10000,fish[entry.species].max_kg*4+.01))||entry.kg<=0)throw Error('Invalid fish');
  out.fish.push({scope:scope==='all'?'all':out.week,species:entry.species,kg:entry.kg});
 }
 for(const scope of ['all','week']){
  for(const entry of [raw[scope==='all'?'rarest_all':'rarest_week'],raw[scope==='all'?'fish_all':'fish_week']]){
   if(!entry||!entry.kg||scope==='week'&&raw.week!==out.week)continue;
   const f=fish[entry.species];if(!f||!number(entry.kg,Math.min(10000,f.max_kg*4+.01))||entry.kg<=0)throw Error('Invalid rare fish');
   out.rarest.push({scope:scope==='all'?'all':out.week,species:entry.species,kg:entry.kg,grade:grades[f.rarity]??0,baseweight:f.chance??1});
  }
 }
 if(raw.trophies!==undefined){
  if(!Array.isArray(raw.trophies)||raw.trophies.length>Object.keys(fish).length)throw Error('Invalid trophies');
  for(const entry of raw.trophies){const f=fish[entry.species];if(!f||!number(entry.kg,Math.min(10000,f.max_kg*4+.01))||entry.kg+1e-7<(f.min_kg+(f.max_kg-f.min_kg)*.4)*2.5)throw Error('Invalid species trophy');out.trophies.push({species:entry.species,kg:entry.kg});}
 }
 if(raw.garden_records!==undefined){
  if(!Array.isArray(raw.garden_records)||raw.garden_records.length>48)throw Error('Invalid garden records');
  const current=monthKey(now);
  for(const r of raw.garden_records){
   const c=crops[r.crop];if(!c||c.source!=='seasonal'||!number(r.kg,c.base_kg*4)||r.kg<=0)throw Error('Invalid crop');
   if(r.scope!=='all'){
    if(!/^20[2-9][0-9]-(0[1-9]|1[0-2])$/.test(r.scope)||Number(r.scope.slice(5))!==c.month||r.scope>current)throw Error('Invalid crop season');
    if(Number(r.scope.slice(0,4))<Number(current.slice(0,4))-2)continue;
   }
   out.crops.push({scope:r.scope,crop:r.crop,kg:r.kg});
  }
 }
 return out;
}
export function postgresStore(pool,{named=false}={}){return {
 async submit(profile,p){
  const a=p.totals;
  if(a.length)await pool.query(`INSERT INTO crossroads_community_totals(profile,kind,key,value) SELECT $1,unnest($2::text[]),unnest($3::text[]),unnest($4::float8[]) ON CONFLICT(profile,kind,key) DO UPDATE SET value=GREATEST(crossroads_community_totals.value,EXCLUDED.value)`,[profile,a.map(x=>x.kind),a.map(x=>x.key),a.map(x=>x.value)]);
  for(const f of p.fish)await pool.query(`INSERT INTO crossroads_community_fish(profile,scope,species,kg) VALUES($1,$2,$3,$4) ON CONFLICT(profile,scope) DO UPDATE SET species=CASE WHEN EXCLUDED.kg>crossroads_community_fish.kg THEN EXCLUDED.species ELSE crossroads_community_fish.species END,kg=GREATEST(crossroads_community_fish.kg,EXCLUDED.kg),reached_at=CASE WHEN EXCLUDED.kg>crossroads_community_fish.kg THEN now() ELSE crossroads_community_fish.reached_at END`,[profile,f.scope,f.species,f.kg]);
  for(const f of p.rarest||[])await pool.query(`INSERT INTO crossroads_community_rarity(profile,scope,species,kg,grade,baseweight) VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT(profile,scope) DO UPDATE SET species=EXCLUDED.species,kg=EXCLUDED.kg,grade=EXCLUDED.grade,baseweight=EXCLUDED.baseweight WHERE (EXCLUDED.grade>crossroads_community_rarity.grade) OR (EXCLUDED.grade=crossroads_community_rarity.grade AND EXCLUDED.baseweight<crossroads_community_rarity.baseweight) OR (EXCLUDED.grade=crossroads_community_rarity.grade AND EXCLUDED.baseweight=crossroads_community_rarity.baseweight AND EXCLUDED.species<crossroads_community_rarity.species) OR (EXCLUDED.species=crossroads_community_rarity.species AND EXCLUDED.kg>crossroads_community_rarity.kg)`,[profile,f.scope,f.species,f.kg,f.grade,f.baseweight]);
  for(const r of p.crops||[])await pool.query(`INSERT INTO crossroads_community_crops(profile,scope,crop,kg) VALUES($1,$2,$3,$4) ON CONFLICT(profile,scope,crop) DO UPDATE SET kg=GREATEST(crossroads_community_crops.kg,EXCLUDED.kg)`,[profile,r.scope,r.crop,r.kg]);
 },
 async snapshot(week,month){
  const heroes=await pool.query(`SELECT key id,sum(value)::float8 value FROM crossroads_community_totals WHERE kind='hero' GROUP BY key ORDER BY sum(value) DESC,key LIMIT 10`);
  const realms=await pool.query(`SELECT key id,sum(value)::float8 value FROM crossroads_community_totals WHERE kind='realm' GROUP BY key ORDER BY sum(value) DESC,key LIMIT 5`);
  const between=await pool.query(`SELECT key id,max(value)::float8 value FROM crossroads_community_totals WHERE kind='between' GROUP BY key`);
  const all=await pool.query(`SELECT species,kg::float8 kg FROM crossroads_community_fish WHERE scope='all' ORDER BY kg DESC,reached_at,species LIMIT 1`);
  const weekly=await pool.query(`SELECT species,kg::float8 kg FROM crossroads_community_fish WHERE scope=$1 ORDER BY kg DESC,reached_at,species LIMIT 1`,[week]);
  const rareall=await pool.query(`SELECT species,kg::float8 kg FROM crossroads_community_rarity WHERE scope='all' ORDER BY grade DESC,baseweight,species,kg DESC LIMIT 1`);
  const rareweek=await pool.query(`SELECT species,kg::float8 kg FROM crossroads_community_rarity WHERE scope=$1 ORDER BY grade DESC,baseweight,species,kg DESC LIMIT 1`,[week]);
  const cropall=await pool.query(`SELECT crop,max(kg)::float8 kg FROM crossroads_community_crops WHERE scope='all' GROUP BY crop ORDER BY crop LIMIT 12`);
  const cropmonth=await pool.query(`SELECT crop,max(kg)::float8 kg FROM crossroads_community_crops WHERE scope=$1 GROUP BY crop ORDER BY crop LIMIT 12`,[month]);
  // Profile/account links suppress future anonymous copies. Exact old catch matches
  // are attributed to their named record without inventing historical account links.
  const leaders=async(table,scope,key,order)=>{
   const known=named?` AND NOT EXISTS(SELECT 1 FROM crossroads_community_fish_accounts m WHERE m.profile=f.profile) AND NOT EXISTS(SELECT 1 FROM crossroads_named_records r JOIN crossroads_accounts a ON a.id=r.account WHERE r.kind='fish' AND r.key='${key}' AND r.scope=f.scope AND r.extra->>'species'=f.species AND (r.extra->>'kg')::float8=f.kg)`:'';
   return (await pool.query(`SELECT f.species,f.kg::float8 kg FROM ${table} f WHERE f.scope=$1${known} ORDER BY ${order} LIMIT 5`,[scope])).rows;
  };
  const fish_boards={fish_all:await leaders('crossroads_community_fish','all','largest','f.kg DESC,f.reached_at,f.species,f.profile'),fish_week:await leaders('crossroads_community_fish',week,'largest','f.kg DESC,f.reached_at,f.species,f.profile'),rarest_all:await leaders('crossroads_community_rarity','all','rarest','f.grade DESC,f.baseweight,f.species,f.kg DESC,f.profile'),rarest_week:await leaders('crossroads_community_rarity',week,'rarest','f.grade DESC,f.baseweight,f.species,f.kg DESC,f.profile')};
  return {fish_boards,rarest_all:rareall.rows[0]||null,rarest_week:rareweek.rows[0]||null,garden_all:cropall.rows,garden_month:cropmonth.rows,heroes:heroes.rows,realms:realms.rows,between:between.rows,fish_all:all.rows[0]||null,fish_week:weekly.rows[0]||null};
 }
};}
export function createCommunity({pool,secret=process.env.REPORT_SIGNING_SECRET||'',store,accounts,now=()=>Date.now()}={}){
 const configured=!!(pool||store)&&secret.length>=32;let ready=false,pending=0,cache=null,expires=0,retry=0;const limits=new Map();store=store||(pool?postgresStore(pool,{named:!!accounts}):null);
 const init=async()=>{try{if(pool){await pool.query(schema);if(accounts){await accounts.initialized;await pool.query(namedSchema);}}ready=configured;}catch{ready=false;}};const initialized=configured?init():Promise.resolve();
 const send=(res,code,data)=>{res.writeHead(code,{'content-type':'application/json','cache-control':'no-store'});res.end(JSON.stringify(data));};
 const hash=s=>createHmac('sha256',secret).update(s).digest('hex');
 async function handle(req,res){const path=new URL(req.url,'http://localhost').pathname;if(!['/community/records','/community/sync'].includes(path))return false;
  const origin=req.headers.origin||'';const permitted=!origin||/^https:\/\/([a-z0-9-]+\.)*(itch\.zone|itch\.io)$/.test(origin)||(process.env.REPORT_ALLOWED_ORIGIN||'').split(',').includes(origin)||(process.env.FX_LOCAL_TEST==='1'&&/^http:\/\/127\.0\.0\.1:\d+$/.test(origin));
  if(!permitted){send(res,403,{error:'Origin rejected'});req.resume();return true;}
  if(origin){res.setHeader('Access-Control-Allow-Origin',origin);res.setHeader('Vary','Origin');}
  if(req.method==='OPTIONS'){res.writeHead(204,{'Access-Control-Allow-Methods':'GET,POST','Access-Control-Allow-Headers':'content-type,authorization'});res.end();return true;}
  if((path.endsWith('/sync')&&req.method!=='POST')||(path.endsWith('/records')&&req.method!=='GET')){send(res,405,{error:'Method rejected'});req.resume();return true;}
  if(!ready&&configured&&now()>retry){retry=now()+15000;void init();}if(!ready){send(res,503,{error:'Community records unavailable'});req.resume();return true;}
  const ip=hash(req.socket.remoteAddress||'unknown'),rate=limits.get(ip)||{at:now(),count:0};if(now()-rate.at>60000){rate.at=now();rate.count=0;}limits.set(ip,rate);if(limits.size>2048)limits.delete(limits.keys().next().value);
  if(++rate.count>1000||pending>=4){send(res,429,{error:'Please retry later'});req.resume();return true;}pending++;
  try{
   if(path.endsWith('/sync')){let size=0;const chunks=[];const timer=setTimeout(()=>req.destroy(),5000);timer.unref();let raw;try{for await(const chunk of req){size+=chunk.length;if(size>524288){send(res,413,{error:'Too large'});req.destroy();return true;}chunks.push(chunk);}raw=JSON.parse(Buffer.concat(chunks));}catch{send(res,400,{error:'Invalid record'});return true;}finally{clearTimeout(timer);}let p;try{p=clean(raw,now());}catch{send(res,400,{error:'Invalid record'});return true;}let claimant=null,before=null;const hasClaims=Array.isArray(raw.claims)&&raw.claims.length>0&&raw.claims.length<=12;if(req.headers.authorization&&accounts){const a=await accounts.authenticate(req);if(!a){send(res,401,{error:'Sign in again to submit named records'});return true;}claimant=a;if(hasClaims)before={...await store.snapshot(p.week,monthKey(now())),named:await namedSnapshot(pool,now())};await submitNamed(pool,a,p,raw,now());await pool.query(`INSERT INTO crossroads_community_fish_accounts(profile,account) VALUES($1,$2) ON CONFLICT(profile) DO UPDATE SET account=EXCLUDED.account`,[hash('community:'+p.profile),a.id]);}await store.submit(hash('community:'+p.profile),p);cache=null;expires=0;const records_broken=before&&claimant?brokenRecords(raw.claims,before,{named:await namedSnapshot(pool,now())},claimant.username):[];send(res,200,{saved:true,week:p.week,records_broken});return true;}
   const w=rankWeek(now());if(!cache||now()>=expires||cache.week!==w.week||cache.month!==monthKey(now())){const community=await store.snapshot(w.week,monthKey(now())),named=accounts?await namedSnapshot(pool,now()):{};cache={version:1,records_schema:3,build:BUILD,limits:{heroes:10,damage:10,fish:5},month:monthKey(now()),week:w.week,reset_at:Math.floor(w.end/1000),updated_at:Math.floor(now()/1000),...community,...(accounts?{named}:{}),fish_boards:fishBoards(community,named)};expires=now()+30000;}
   send(res,200,cache);return true;
  }catch{send(res,503,{error:'Community records unavailable'});return true;}finally{pending--;}
 }
 return {handle,initialized,status:()=>({configured,ready}),stop(){}};
}
