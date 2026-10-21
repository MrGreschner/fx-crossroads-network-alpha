import {dashboardFailure,reportNumberSQL} from './dashboard_errors.mjs';
import {BUILD} from './release.mjs';
import {createHmac} from 'node:crypto';
import {readFileSync} from 'node:fs';
const ID=/^[a-f0-9]{32}$/;
const categories=new Set('town realm descent defense arena battlegrounds quest studio mine market fishing gardening menu between overcharge'.split(' '));
const modes=new Set('town run coop descent defense arena battlegrounds quest'.split(' '));
const kinds=new Set(['interval','complete','market_day','mine_depth','graphics_loss','fish_catch','garden_harvest','client_stall']);
const results=new Set(['','cleared','defeated','completed','win','loss','draw','interrupted','returned']);
const numeric=(v,max=1e15,min=0)=>typeof v==='number'&&Number.isFinite(v)&&v>=min&&v<=max;
const key=v=>typeof v==='string'&&/^[a-z0-9_-]{0,64}$/.test(v)?v:'';
const statisticKeys=['town_draw_p95_ms','town_world_p95_ms','town_lighting_p95_ms','frames','frame_p95_upper_ms','frames_over_33','frames_over_50','process_max_ms','physics_max_ms','memory_max_bytes','entities_max','projectiles_max','guards_max','server_work_max_ms','authority_hz_min','quality_scale_min','fps_firing_sum','firing_samples','fps_moving_sum','moving_samples','fps_idle_sum','idle_samples','samples','fps_mean','fps_min','fps_max','below_50','below_40','frame_max_ms','draw_max','video_max_bytes','rtt_mean_ms','rtt_max_ms'];
const metricKeys=['damage','enemies','players','floor','wave','banked_shards','fish_level','mine_depth','mine_level','mine_ore','day','sold','profit','duration_configured','human_players','ai_players','projectiles','guards','depth','streamed_chunks','shards_carried','fps_cap','touch_controls','quality_scale','state_stalls','corrections','rivals','fish_weight','fish_xp_gain','fish_trophy','fish_kept','garden_level','garden_xp','garden_yield','garden_seconds','garden_fair_kg','bg_units','bg_shots','bg_bombs','bg_work_ms','bg_units_ms','bg_spawn_queued','stall_seconds'];
export function cleanActivity(raw){
 if(!raw||raw.version!==1||!['event','session','profile','device'].every(k=>typeof raw[k]==='string'&&ID.test(raw[k]))||!categories.has(raw.category)||!modes.has(raw.mode)||!kinds.has(raw.kind)||!results.has(raw.result)||!['solo','dedicated','legacy'].includes(raw.route)||!['web','mobile','desktop'].includes(raw.platform)||!Number.isInteger(raw.build)||raw.build<171||raw.build>99999||!numeric(raw.seconds,90)||!numeric(raw.active,raw.seconds)||!numeric(raw.duration,604800))throw Error('Invalid activity');
 const p=Object.fromEntries(['version','event','session','profile','device','category','mode','kind','result','route','platform','build','seconds','active','duration'].map(k=>[k,raw[k]]));
 p.release=typeof raw.release==='string'&&/^(V[0-9]+(?:\.[0-9]+)*-[a-z][a-z0-9-]{0,47}|T4\.[0-9.]+)$/.test(raw.release)?raw.release:"unknown";p.attempt=typeof raw.attempt==='string'&&ID.test(raw.attempt)?raw.attempt:"";p.details={};for(const k of ["rules","map","input","graphics","fish_species","garden_seed"])if(raw.details&&key(raw.details[k]))p.details[k]=key(raw.details[k]);p.graphics={};for(const k of ["renderer","vendor","version","webglVersion"])if(typeof raw.graphics?.[k]==='string')p.graphics[k]=raw.graphics[k].slice(0,160);for(const k of ["hardwareConcurrency","deviceMemory","maxTextureSize"])if(numeric(raw.graphics?.[k],1e8))p.graphics[k]=raw.graphics[k];p.hero=key(raw.hero);p.realm=key(raw.realm);p.stats={};p.metrics={};
 for(const k of statisticKeys)if(numeric(raw.stats?.[k],k==='samples'?90:k==='fps_mean'||k==='fps_min'||k==='fps_max'?1000:k==='frame_max_ms'?60000:1e12))p.stats[k]=raw.stats[k];
 for(const k of metricKeys)if(numeric(raw.metrics?.[k],1e15,k==='profit'?-1e15:0))p.metrics[k]=raw.metrics[k];
 if(p.kind!=='interval'){p.seconds=0;p.active=0;}
 return p;
}
const schema=`-- Crossroads v171: additive tables, no profile or existing report migration.
CREATE TABLE IF NOT EXISTS crossroads_activity (
 event text PRIMARY KEY, session text NOT NULL, profile text NOT NULL, device text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), category text NOT NULL, mode text NOT NULL,
 realm text NOT NULL, hero text NOT NULL, route text NOT NULL, kind text NOT NULL, result text NOT NULL,
 build integer NOT NULL, seconds double precision NOT NULL, active double precision NOT NULL,
 duration double precision NOT NULL, payload jsonb NOT NULL);
CREATE INDEX IF NOT EXISTS crossroads_activity_at ON crossroads_activity(created_at);
CREATE INDEX IF NOT EXISTS crossroads_activity_category ON crossroads_activity(category,created_at);
`;
export function createActivity({pool,admin,hashSecret=process.env.ACTIVITY_HASH_SECRET||process.env.REPORT_SIGNING_SECRET||'',now=()=>Date.now()}={}){
 let ready=false,pending=0,retryAt=0;const limits=new Map();const configured=!!pool&&hashSecret.length>=32;
 const hash=v=>createHmac('sha256',hashSecret).update(v).digest('hex');
 const initialize=()=>pool.query(schema).then(()=>{ready=true}).catch(()=>{ready=false;});
 const initialized=configured?initialize():Promise.resolve();
 const retention=setInterval(()=>{if(ready&&pending<4)pool.query("DELETE FROM crossroads_activity WHERE created_at < now() - interval '30 days'").catch(()=>{});for(const [k,v]of limits)if(now()-v.at>120000)limits.delete(k);},3600000);retention.unref();
 function send(res,status,data,headers={}){res.writeHead(status,{'Content-Type':'application/json','Cache-Control':'no-store','X-Content-Type-Options':'nosniff',...headers});res.end(JSON.stringify(data));}
 function days(url){return Math.max(1,Math.min(30,Number(url.searchParams.get('days'))||7));}
 const stat=k=>reportNumberSQL(`payload->'stats'->'${k}'`);
 const aggregate=async n=>{
  const cutoff=new Date(now()-n*86400000).toISOString();
  const activities=await pool.query(`SELECT category,mode,realm,route,count(DISTINCT profile)::int profiles,sum(active)::float active_seconds,sum(seconds)::float observed_seconds, min(${stat('fps_min')}) FILTER (WHERE ${stat('samples')}>0) fps_min, sum(${stat('fps_mean')}*${stat('samples')})/NULLIF(sum(CASE WHEN ${stat('fps_mean')} IS NOT NULL THEN ${stat('samples')} END),0) fps_mean, sum(COALESCE(${stat('below_40')},0))::float low_fps_samples FROM crossroads_activity WHERE created_at >= $1 AND kind='interval' GROUP BY category,mode,realm,route ORDER BY sum(active) DESC LIMIT 100`,[cutoff]);
  const completions=await pool.query(`SELECT kind,mode,realm,route,result,count(*)::int attempts,percentile_cont(0.5) WITHIN GROUP (ORDER BY duration) FILTER (WHERE duration>0) median_seconds,min(NULLIF(duration,0)) fastest_seconds,max(duration) longest_seconds FROM crossroads_activity WHERE created_at >= $1 AND kind!='interval' GROUP BY kind,mode,realm,route,result ORDER BY count(*) DESC LIMIT 100`,[cutoff]);
  const daily=await pool.query(`SELECT to_char(created_at AT TIME ZONE 'America/Edmonton','YYYY-MM-DD') AS "day",count(DISTINCT profile)::int profiles,count(DISTINCT device)::int devices,count(DISTINCT session)::int sessions,sum(active)::float active_seconds,count(*) FILTER (WHERE kind='graphics_loss')::int graphics_losses,0::int disconnects FROM crossroads_activity WHERE created_at >= $1 GROUP BY 1 ORDER BY 1`,[cutoff]);
  const totals=await pool.query(`SELECT count(*)::int batches,count(DISTINCT profile)::int profiles,count(DISTINCT device)::int devices,count(DISTINCT session)::int sessions,COALESCE(sum(active),0)::float active_seconds FROM crossroads_activity WHERE created_at >= $1`,[cutoff]);
  return {version:BUILD,days:n,timezone:'America/Edmonton',retention_days:30,totals:totals.rows[0],activities:activities.rows,completions:completions.rows,daily:daily.rows,notes:['Self-reported play estimates, not verified learning outcomes.','Profiles and devices are anonymous identifiers, not counts of unique students.','Solo gameplay stays local; missing/offline uploads are not counted.','Completion times are gameplay/simulation times. Market days may finish while offline.']};
 };
 async function handle(req,res){
  const url=new URL(req.url,'http://localhost');if(!url.pathname.startsWith('/activity')&&!url.pathname.startsWith('/analytics/'))return false;
  if(url.pathname==='/activity/ingest'){
   const origin=req.headers.origin||'';const permitted=!origin||/^https:\/\/([a-z0-9-]+\.)*(itch\.zone|itch\.io)$/.test(origin)||(process.env.REPORT_ALLOWED_ORIGIN||'').split(',').includes(origin)||(process.env.FX_LOCAL_TEST==='1'&&/^http:\/\/127\.0\.0\.1:\d+$/.test(origin));
   if(!permitted){send(res,403,{error:'Origin rejected'});req.resume();return true;}
   if(origin){res.setHeader('Access-Control-Allow-Origin',origin);res.setHeader('Vary','Origin');}
   if(req.method==='OPTIONS'){res.writeHead(204,{'Access-Control-Allow-Methods':'POST','Access-Control-Allow-Headers':'content-type'});res.end();return true;}
   if(req.method!=='POST'){send(res,405,{error:'POST required'});return true;}
   if(!ready&&configured&&now()>retryAt){retryAt=now()+15000;initialize();}
   if(!ready){send(res,503,{error:'Activity storage unavailable'});req.resume();return true;}
   if(pending>=3){send(res,429,{error:'Retry later'},{'Retry-After':'30'});req.resume();return true;}
   const source=hash(req.socket.remoteAddress||'unknown'),limit=limits.get(source)||{at:now(),count:0};
   if(now()-limit.at>60000){limit.at=now();limit.count=0;}limits.set(source,limit);if(limits.size>2048)limits.delete(limits.keys().next().value);
   // One school often shares an address. This is aggregate admission, not a per-student quota.
   if(++limit.count>1200){send(res,429,{error:'Retry later'});req.resume();return true;}
   pending++;let size=0;const chunks=[];const timeout=setTimeout(()=>req.destroy(),5000);timeout.unref();
   try{
    for await(const part of req){size+=part.length;if(size>16384){send(res,413,{error:'Batch too large'});req.destroy();return true;}chunks.push(part);}
    let p;try{p=cleanActivity(JSON.parse(Buffer.concat(chunks).toString()));}catch{send(res,400,{error:'Invalid activity'});return true;}
    for(const k of ['profile','device','session'])p[k]=hash(p[k]);
    await pool.query('INSERT INTO crossroads_activity (event,session,profile,device,category,mode,realm,hero,route,kind,result,build,seconds,active,duration,payload) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16::jsonb) ON CONFLICT (event) DO NOTHING',[p.event,p.session,p.profile,p.device,p.category,p.mode,p.realm,p.hero,p.route,p.kind,p.result,p.build,p.seconds,p.active,p.duration,JSON.stringify(p)]);
    send(res,201,{saved:true,event:p.event});
   }catch{if(!res.headersSent)send(res,503,{error:'Activity storage unavailable'});}finally{clearTimeout(timeout);pending--;}
   return true;
  }
  const origin=req.headers.origin||'';
  const permitted=/^https:\/\/([a-z0-9-]+\.)*(itch\.zone|itch\.io)$/.test(origin)||(process.env.REPORT_ALLOWED_ORIGIN||'').split(',').includes(origin)||(process.env.FX_LOCAL_TEST==='1'&&/^http:\/\/127\.0\.0\.1:\d+$/.test(origin));
  if(origin&&permitted){res.setHeader('Access-Control-Allow-Origin',origin);res.setHeader('Vary','Origin');}
  if(req.method==='OPTIONS'){if(!permitted){send(res,403,{error:'Origin rejected'});return true;}res.writeHead(204,{'Access-Control-Allow-Methods':'GET','Access-Control-Allow-Headers':'authorization'});res.end();return true;}
  if(!admin?.(req)){send(res,401,{error:'Private dashboard. Sign in as teacher.'},{'WWW-Authenticate':'Basic realm="Crossroads private reports", charset="UTF-8"'});return true;}
  if(req.method!=='GET'){send(res,405,{error:'GET required'});return true;}
  if(url.pathname==='/activity'||url.pathname==='/activity/'){
   res.writeHead(200,{'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store','Content-Security-Policy':"default-src 'none'; script-src 'self'; style-src 'unsafe-inline'; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'"});res.end(readFileSync(new URL('./activity.html',import.meta.url)));return true;
  }
  if(url.pathname==='/activity/dashboard.js'){res.writeHead(200,{'Content-Type':'text/javascript','Cache-Control':'no-store'});res.end(readFileSync(new URL('./activity-dashboard.js',import.meta.url)));return true;}
  if(!ready){send(res,503,{error:'Set DATABASE_URL and a stable REPORT_SIGNING_SECRET of at least 32 characters.'});return true;}
  if(pending>=3){send(res,429,{error:'Busy; try again'});return true;}pending++;
  try{
   if(url.pathname==='/activity/api/summary'||url.pathname==='/analytics/dashboard')send(res,200,await aggregate(days(url)));
   else if(url.pathname==='/activity/api/export'){
    const cutoff=new Date(now()-days(url)*86400000).toISOString();const rows=await pool.query('SELECT payload,created_at FROM crossroads_activity WHERE created_at >= $1 ORDER BY created_at DESC LIMIT 5000',[cutoff]);
    send(res,200,{version:BUILD,retention_days:30,limit:5000,reports:rows.rows.map(r=>({...r.payload,received_at:r.created_at}))},{'Content-Disposition':'attachment; filename="Crossroads_play_insights.json"'});
   }else send(res,404,{error:'Not found'});
  }catch(error){send(res,503,dashboardFailure(error,url.pathname));}finally{pending--;}
  return true;
 }
 return {handle,initialized,status:()=>({configured,ready,pending,retention_days:30}),close(){clearInterval(retention)}};
}
