import {dashboardFailure} from './dashboard_errors.mjs';
import {createHmac,randomBytes,timingSafeEqual} from 'node:crypto';
import {readFileSync} from 'node:fs';
import pg from 'pg';
import {BUILD,REPORT_SCHEMA} from './release.mjs';
import * as insights from './insights.mjs';
const schema=readFileSync(new URL('./reports.sql',import.meta.url),'utf8');
const dashboard=readFileSync(new URL('./reports.html',import.meta.url),'utf8');
const configuredSecret=process.env.REPORT_SIGNING_SECRET||'';
const secret=configuredSecret.length>=32?configuredSecret:randomBytes(32).toString('hex');
if(configuredSecret&&configuredSecret.length<32)console.error('Crossroads reports: signing secret too short; using a temporary random key');
const MAX_BYTES=196608;
export function ticket(claims){const text=Buffer.from(JSON.stringify({...claims,exp:Date.now()+7200000})).toString('base64url');return text+'.'+createHmac('sha256',secret).update(text).digest('base64url');}
function claims(token){try{const [text,sig]=String(token).split('.');const want=createHmac('sha256',secret).update(text).digest();const got=Buffer.from(sig,'base64url');if(got.length!==want.length||!timingSafeEqual(got,want))return null;const c=JSON.parse(Buffer.from(text,'base64url'));return c.exp>Date.now()?c:null;}catch{return null;}}
const safeString=(v,n=120)=>typeof v==='string'?v.slice(0,n):'';
// A fixed diagnostic vocabulary avoids retaining display names or arbitrary client data.
const fields=('last_launch category platform movement_speed_px moving focused frames_p95_upper_ms human_players ai_players run_stage wave floor gate_hp party_size rival_heroes downed_heroes realm_progress network_gaps recent_hit_events replayed_inputs wire_bytes protocol expedition battlegrounds mode realm browser_timing client_frame_gap_ms frame_gap_peak_ms frame_gap_stalls delivery_gap_stalls last_stall_context visual_correction_px terrain_geometry shell_resize_count resume_attempts last_disconnect_reason disconnect_reason last_authority_reset quality_scale quality_changes server_metrics gateway_metrics server_metrics_age_ms state_stalls state_stale_peak_ms recovery_active received_packets received_bytes coalesced_client_snapshots poll_budget_yields client_elapsed_ms match_elapsed_ms active build server_build fps rtt_ms gateway_rtt_ms simulation_ms snapshot_ms authority_hz prediction_queue state_age_ms buffer_ms buffer_holds clock_resyncs max_world_backlog_ms projectile_handoffs projectile_confirmations max_handoff_error_px confirmed_damage_events client_profile long_frames_50ms active_fps_cap engine_process_ms engine_physics_ms draw_calls primitives projectiles contacts damage_labels firing pending_packets last_action release_cues action_input_flushes memory_bytes video_memory_bytes texture_memory_bytes render_objects scenery_chunks dash_afterimages hud_rebuilds authority_resets correction_histogram terrain_chunks mobile_controls graphics_mode render_size snapshot_interarrival_ms target_buffer_ms playback_rate arrival_gap_max_ms ability_view_starts ability_view_active ability_view_offset_px twister_effects position_corrections max_position_correction_px local_view_offset_px action_ack_wait_ms launch_received_ms launch_drawn_ms ice_walls oldest_wall_remaining hero players viewport arena_map arena_variant arena_objective enemies predicted_projectiles prediction_expiries').split(' ');
function numericTree(v,depth=0){if(depth>4)return null;if(typeof v==='number')return Number.isFinite(v)?v:null;if(typeof v==='boolean')return v;if(Array.isArray(v))return v.slice(0,32).map(x=>numericTree(x,depth+1));if(v&&typeof v==='object'){return Object.fromEntries(Object.entries(v).slice(0,40).filter(([k])=>/^[a-z0-9_]+$/i.test(k)&&!/(name|token|password|email)/i.test(k)).map(([k,x])=>[k,numericTree(x,depth+1)]));}return null;}
export function cleanReport(raw,c){
 if(!raw||raw.match_id!==c.match||!Array.isArray(raw.samples)||raw.samples.length<1||raw.samples.length>30||!/^[-a-zA-Z0-9_]{8,80}$/.test(raw.id||'')||!/^[-a-zA-Z0-9_]{8,80}$/.test(raw.device_id||''))throw Error('Invalid report');
 const samples=raw.samples.map(s=>{const out={};for(const k of fields)if(Object.hasOwn(s,k))out[k]=['mode','realm','build','server_build','hero','arena_map','graphics_mode','disconnect_reason','last_authority_reset','last_disconnect_reason','last_stall_context','category','platform','run_stage'].includes(k)?safeString(s[k],64):numericTree(s[k]);for(const field of ['last_action','last_launch'])if(s[field]&&typeof s[field]==='object'){
 const raw=s[field],action={};for(const key of ['seq','client_ms','motion_type','sent_ms','received_ms','drawn_ms'])if(typeof raw[key]==='number'&&Number.isFinite(raw[key]))action[key]=raw[key];
 if(['primary','secondary','special','dodge'].includes(raw.kind))action.kind=raw.kind;
 if(['begin','update','release','cancel','press','start'].includes(raw.phase))action.phase=raw.phase;
 out[field]=action;
 }return out;});
 const g=raw.graphics||{};const graphics={};for(const key of ['renderer','version','maxTextureSize','width','height','vendor','webglVersion','webgl_version','hardwareConcurrency','deviceMemory','contextLosses'])if(Object.hasOwn(g,key))graphics[key]=typeof g[key]==='string'?safeString(g[key],160):numericTree(g[key]);
 const observedBuild=samples.find(s=>/^V[0-9]+(?:\.[0-9]+)*-[a-z][a-z0-9-]*$/.test(s.build||''))?.build;
 return {id:raw.id,match_id:c.match,room:c.room,actor:c.actor,device_id:raw.device_id,build:safeString(observedBuild||raw.build,64),hero:safeString(raw.hero,64),reason:safeString(raw.reason,32),samples,graphics};
}
export function createReporting({pool:provided,adminPassword=process.env.REPORT_ADMIN_PASSWORD||''}={}){
 const pool=provided||(process.env.DATABASE_URL?new pg.Pool({connectionString:process.env.DATABASE_URL,max:2,connectionTimeoutMillis:3000,idleTimeoutMillis:10000,statement_timeout:3000,query_timeout:4000}):null);
 // Keep diagnostic reads off the short-timeout pool used by incoming diagnostics.
 const reads=provided|| (pool?new pg.Pool({connectionString:process.env.DATABASE_URL,max:2,connectionTimeoutMillis:5000,idleTimeoutMillis:10000,statement_timeout:25000,query_timeout:30000}):null);
 reads?.on?.('error',()=>console.error('Crossroads reports: idle read connection failed'));
 let ready=false,pending=0;const limits=new Map();
 pool?.on?.('error',()=>{console.error('Crossroads reports: idle database connection failed');});
 const initialized=pool?Promise.resolve().then(()=>pool.query(schema)).then(()=>{ready=true;}).catch(()=>console.error('Crossroads reports: database unavailable; combat remains available')):Promise.resolve();
 // Retry initialization on subsequent upload after an outage. Never gate combat readiness.
 let retryAt=Date.now()+15000;
 const retention=setInterval(()=>{if(ready)pool.query("DELETE FROM fx_reports WHERE created_at < now() - interval '30 days'").catch(()=>{});for(const [k,v]of limits)if(Date.now()-v.at>60000)limits.delete(k);},3600000);retention.unref();
 function admin(req){if(adminPassword.length<24)return false;const expected=Buffer.from('admin:'+adminPassword);let got;try{got=Buffer.from((req.headers.authorization||'').replace(/^Basic /,''),'base64');}catch{return false;}return got.length===expected.length&&timingSafeEqual(got,expected);}
 function reply(res,status,value,extra={}){res.writeHead(status,{'Content-Type':'application/json','Cache-Control':'no-store','X-Content-Type-Options':'nosniff',...extra});res.end(JSON.stringify(value));}
 async function handle(req,res){
  const url=new URL(req.url,'http://localhost');if(!url.pathname.startsWith('/reports'))return false;
  if(url.pathname==='/reports/ingest'){
   const origin=req.headers.origin||'';
   const permitted=/^https:\/\/([a-z0-9-]+\.)*(itch\.zone|itch\.io)$/.test(origin)||(process.env.REPORT_ALLOWED_ORIGIN||'').split(',').includes(origin)||(process.env.FX_LOCAL_TEST==='1'&&/^http:\/\/127\.0\.0\.1:\d+$/.test(origin));
   if(origin&&!permitted){reply(res,403,{error:'Origin rejected'});return true;}
   res.setHeader('Vary','Origin');if(origin)res.setHeader('Access-Control-Allow-Origin',origin);
   if(req.method==='OPTIONS'){reply(res,204,{}, {'Access-Control-Allow-Methods':'POST','Access-Control-Allow-Headers':'content-type,authorization'});return true;}
   if(req.method!=='POST'){reply(res,405,{error:'POST required'});return true;}
   const c=claims((req.headers.authorization||'').replace(/^Bearer /,''));
   if(!c){reply(res,401,{error:'Match ticket expired or invalid'});req.resume();return true;}
   if(!ready&&pool&&Date.now()>retryAt){retryAt=Date.now()+15000;Promise.resolve().then(()=>pool.query(schema)).then(()=>{ready=true;}).catch(()=>{});}
   if(!ready){reply(res,503,{error:'Reporting not configured or database unavailable'});req.resume();return true;}
   const key=c.actor;let rate=limits.get(key);if(!rate||Date.now()-rate.at>60000){rate={at:Date.now(),count:0};limits.set(key,rate);}if(limits.size>4096)limits.delete(limits.keys().next().value);
   if(++rate.count>8||pending>=4){reply(res,429,{error:'Retry later'},{'Retry-After':'15'});req.resume();return true;}
   pending++;let size=0;const chunks=[];
   const timeout=setTimeout(()=>req.destroy(),5000);timeout.unref();
   try{
    for await(const chunk of req){size+=chunk.length;if(size>MAX_BYTES){reply(res,413,{error:'Report too large'});req.destroy();return true;}chunks.push(chunk);}
    let report;try{report=cleanReport(JSON.parse(Buffer.concat(chunks)),c);}catch{reply(res,400,{error:'Invalid report'});return true;}
    await pool.query('INSERT INTO fx_reports (id,match_id,room,actor,device_id,build,hero,payload) VALUES ($1,$2,$3,$4,$5,$6,$7,$8::jsonb) ON CONFLICT (id) DO NOTHING',[report.id,report.match_id,report.room,report.actor,report.device_id,report.build,report.hero,JSON.stringify(report)]);
    reply(res,201,{saved:true,id:report.id});
   }catch{if(!res.headersSent)reply(res,503,{error:'Could not save report; retry later'});}finally{clearTimeout(timeout);pending--;}
   return true;
  }
  if(!admin(req)){reply(res,401,{error:'Private reports. Sign in as admin.'},{'WWW-Authenticate':'Basic realm="Crossroads administration", charset="UTF-8"'});return true;}
  if(req.method!=='GET'){reply(res,405,{error:'GET required'});return true;}
  if(url.pathname==='/reports'||url.pathname==='/reports/'){
   res.writeHead(200,{'Content-Type':'text/html; charset=utf-8','Cache-Control':'no-store','Content-Security-Policy':"default-src 'none'; script-src 'self'; style-src 'unsafe-inline'; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'",'X-Content-Type-Options':'nosniff'});res.end(dashboard);return true;
  }
  if(url.pathname==='/reports/model.js'){res.writeHead(200,{'Content-Type':'text/javascript','Cache-Control':'no-store'});res.end(readFileSync(new URL('./report-model.mjs',import.meta.url)));return true;}
  if(url.pathname==='/reports/dashboard.js'){res.writeHead(200,{'Content-Type':'text/javascript','Cache-Control':'no-store'});res.end(readFileSync(new URL('./dashboard.js',import.meta.url)));return true;}
  if(!ready){reply(res,503,{error:'Database not connected. Set DATABASE_URL and redeploy.'});return true;}
  if(pending>=4){reply(res,429,{error:'Busy; retry shortly'});return true;}pending++;
  try{
   if(url.pathname==='/reports/api/full-export'){
    await insights.fullExport(reads,insights.filters(url),res,BUILD);
   }else if(url.pathname==='/reports/api/performance-pack'){
    reply(res,200,{build:BUILD,...await insights.performancePack(reads,insights.filters(url))},{'Content-Disposition':`attachment; filename="Crossroads_performance_${new Date().toISOString().slice(0,10)}.json"`});
   }else if(url.pathname==='/reports/api/matches'){
    reply(res,200,await insights.matches(reads,insights.filters(url)));
   }else if(url.pathname==='/reports/api/overview'){reply(res,200,{build:BUILD,...await insights.overview(reads,insights.filters(url))});
   }else if(url.pathname==='/reports/api/sessions'){reply(res,200,await insights.sessions(reads,insights.filters(url)));
   }else if(url.pathname==='/reports/api/activity-export'){reply(res,200,{build:BUILD,...await insights.exportActivities(reads,insights.filters(url))},{'Content-Disposition':`attachment; filename="Crossroads_${BUILD}_activity.json"`});
   }else if(url.pathname==='/reports/api/session'){
    const id=url.searchParams.get('id')||'',attempt=url.searchParams.get('attempt')||'';if(!/^[a-f0-9]{64}$/.test(id)||attempt&&!/^[a-f0-9]{32,64}$/.test(attempt)){reply(res,400,{error:'Invalid session'});return true;}
    reply(res,200,{build:BUILD,...await insights.activityDetail(reads,id,attempt,insights.filters(url).category)},url.searchParams.has('download')?{'Content-Disposition':`attachment; filename="Crossroads_${BUILD}_session.json"`}:{});
   }else if(url.pathname==='/reports/api/match'){
    const id=url.searchParams.get('id')||'';if(!/^[a-f0-9]{32}$/.test(id)){reply(res,400,{error:'Invalid match'});return true;}
    const q=await reads.query('SELECT payload, created_at FROM fx_reports WHERE match_id=$1 ORDER BY created_at LIMIT 2001',[id]);
    reply(res,200,{version:BUILD,report_schema:REPORT_SCHEMA,match_id:id,limited:q.rows.length>2000,reports:q.rows.slice(0,2000).map(r=>({...r.payload,received_at:r.created_at}))},url.searchParams.has('download')?{'Content-Disposition':`attachment; filename="Crossroads_${BUILD}_match_${id}.json"`}:{});
   }else reply(res,404,{error:'Not found'});
  }catch(error){if(!res.headersSent)reply(res,503,dashboardFailure(error,url.pathname));else if(!res.destroyed)res.end();}finally{pending--;}
  return true;
 }
 return {pool,admin,handle,initialized,status:()=>({configured:!!pool,ready,admin_configured:adminPassword.length>=24,pending}),close:async()=>{clearInterval(retention);if(reads!==pool)await reads?.end();await pool?.end();}};
}
