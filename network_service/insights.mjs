import {reportNumberSQL} from './dashboard_errors.mjs';
import {readFileSync,readdirSync} from 'node:fs';
// Bounded, parameterized dashboard queries. Existing JSONB tables stay compatible.
const catalogue={realms:{},heroes:{}};
for(const [folder,bucket] of [['regions','realms'],['characters','heroes'],['npc_heroes','heroes']]){try{for(const file of readdirSync(new URL('../content/'+folder+'/',import.meta.url))){if(!file.endsWith('.json'))continue;try{const d=JSON.parse(readFileSync(new URL('../content/'+folder+'/'+file,import.meta.url),'utf8'));if(typeof d.name==='string')catalogue[bucket][file.slice(0,-5)]=d.name.slice(0,100);}catch{}}}catch{}}
export const CATEGORIES=['arena','realm','between','overcharge','descent','defense','battlegrounds','quest','town','fishing','gardening','mine','market','studio','menu'];
export function filters(url){
 const pick=(key,allowed)=>allowed.includes(url.searchParams.get(key))?url.searchParams.get(key):'';
 const key=k=>/^[a-z0-9_-]{1,64}$/.test(url.searchParams.get(k)||'')?url.searchParams.get(k):'';
 const build=url.searchParams.get('build')||'';
 return {days:Math.max(1,Math.min(30,Math.floor(Number(url.searchParams.get('days'))||7))),category:pick('category',CATEGORIES),route:pick('route',['solo','dedicated','legacy']),input:pick('input',['touch','keyboard_mouse']),platform:pick('platform',['web','mobile','desktop']),realm:key('realm'),hero:key('hero'),build:/^[a-zA-Z0-9._-]{1,40}$/.test(build)?build:''};
}
export const categorySQL=`CASE WHEN kind='complete' AND category='menu' AND mode IN ('arena','descent','defense','battlegrounds','quest') THEN mode WHEN kind='complete' AND category='menu' AND mode IN ('run','coop') THEN CASE WHEN realm='wayfarer' THEN 'quest' WHEN realm='between' THEN 'between' ELSE 'realm' END WHEN category='realm' AND realm='wayfarer' THEN 'quest' ELSE category END`;
const realCategory=`CASE WHEN payload->'samples'->0->'expedition'->>'overcharge'='true' THEN 'overcharge' WHEN payload->'samples'->0->'expedition'->>'between'='true' THEN 'between' WHEN payload->'samples'->0->>'realm'='wayfarer' THEN 'quest' WHEN payload->'samples'->0->>'mode' IN ('coop','run') THEN 'realm' ELSE COALESCE(payload->'samples'->0->>'mode','unknown') END`;
function where(f,activity=true,prepared=false){
 const values=[new Date(Date.now()-f.days*86400000).toISOString()];const clauses=['created_at >= $1'];
 const add=(sql,v)=>{if(v){values.push(v);clauses.push(sql+'=$'+values.length);}};
 if(activity){add(categorySQL,f.category);add('route',f.route);add("payload->'details'->>'input'",f.input);add("payload->>'platform'",f.platform);add('realm',f.realm);add('hero',f.hero);add("payload->>'release'",f.build);}
 else{if(f.input)clauses.push(f.input==='touch'?"payload->'samples'->0->>'mobile_controls'='true'":"payload->'samples'->0->>'mobile_controls'='false'");add(realCategory,f.category);add("payload->'samples'->0->>'realm'",f.realm);add('hero',f.hero);add('build',f.build);if(f.route&&f.route!=='dedicated')clauses.push('false');if(f.platform)clauses.push(f.platform==='web'?"COALESCE(payload->'samples'->0->>'platform','web')='web'":"COALESCE(payload->'samples'->0->>'platform','web')=$"+(values.push(f.platform)));}
 let clause=clauses.join(' AND ');if(prepared)for(const [a,b]of [["payload->'details'->>'input'","details->>'input'"],["payload->>'platform'",'platform'],["payload->>'release'",'release']])clause=clause.replaceAll(a,b);
 return {values,clause};
}
const stat=k=>reportNumberSQL(`stats->'${k}'`);
const metric=k=>reportNumberSQL(`metrics->'${k}'`);
// Limit before grouping, sorting or inspecting JSON. Decompress each JSON stats
// object once, rather than once per aggregate expression (large historical payloads).
const ACTIVITY_LIMIT=2000, MATCH_LIMIT=1000;
const activityWindow=`WITH recent AS MATERIALIZED (SELECT * FROM crossroads_activity WHERE created_at >= $1 ORDER BY created_at DESC LIMIT ${ACTIVITY_LIMIT}), report_window AS MATERIALIZED (SELECT event,session,profile,device,created_at,category,mode,realm,hero,route,kind,result,build,seconds,active,duration,payload->'stats' stats,payload->'metrics' metrics,payload->'details' details,payload->>'platform' platform,payload->>'release' release,payload->>'attempt' attempt FROM recent) `;
const matchWindow=`WITH report_window AS MATERIALIZED (SELECT * FROM fx_reports WHERE created_at >= $1 ORDER BY created_at DESC LIMIT ${MATCH_LIMIT}) `;
async function coverage(pool,f,table,limit){
 const q=await pool.query(`SELECT count(*)::int batches,min(created_at) oldest,max(created_at) newest FROM (SELECT created_at FROM ${table} WHERE created_at >= $1 ORDER BY created_at DESC LIMIT ${limit}) recent`,[new Date(Date.now()-f.days*86400000).toISOString()]);
 return {...q.rows[0],limit,limited:q.rows[0].batches>=limit,scope:'Most recent uploaded batches in the selected period, before other filters'};
}
export async function matches(pool,f){
 const w=where(f,false);const q=await pool.query(`${matchWindow}SELECT match_id,max(room) room,max(build) build,min(created_at) started,max(created_at) updated,count(DISTINCT actor)::int devices,count(*)::int batches,max(${realCategory}) category,max(payload->'samples'->0->>'realm') realm,max(payload->'samples'->0->>'mode') mode,max(${reportNumberSQL("payload->'samples'->0->'players'")}) players FROM report_window WHERE ${w.clause} GROUP BY match_id ORDER BY max(created_at) DESC LIMIT 101`,w.values);
 return {matches:q.rows.slice(0,100),limited:q.rows.length>100,filters:f,retention_days:30,source_window:await coverage(pool,f,'fx_reports',MATCH_LIMIT)};
}
export async function overview(pool,f){
 const w=where(f,true,true);const group=`${categorySQL},mode,realm,route,platform,release`;
 const q=await pool.query(`${activityWindow}SELECT (SELECT COALESCE(jsonb_agg(t),'[]'::jsonb) FROM (SELECT ${categorySQL} category,mode,realm,route,platform platform,release release,count(DISTINCT profile)::int profiles,count(DISTINCT device)::int devices,count(DISTINCT session)::int sessions,sum(active)::float active_seconds,sum(seconds)::float observed_seconds,sum(${stat('samples')})::float fps_samples,sum(${stat('fps_mean')}*${stat('samples')})/NULLIF(sum(CASE WHEN ${stat('fps_mean')} IS NOT NULL THEN ${stat('samples')} END),0) fps_mean,min(${stat('fps_min')}) FILTER (WHERE ${stat('samples')}>0) fps_min,sum(${stat('below_40')})::float below_40,sum(${stat('below_target')})::float below_target,sum(${stat('target_samples')})::float target_samples,max(${stat('frame_p95_upper_ms')}) frame_p95_upper_ms,max(${stat('frame_max_ms')}) frame_max_ms,max(${stat('draw_max')}) draw_max,max(${stat('entities_max')}) entities_max,max(${stat('projectiles_max')}) projectiles_max,max(${stat('process_max_ms')}) process_max_ms,max(${stat('physics_max_ms')}) physics_max_ms,max(${stat('rtt_max_ms')}) rtt_max_ms,max(${stat('server_work_max_ms')}) server_work_max_ms,min(${stat('authority_hz_min')}) authority_hz_min,count(*) FILTER (WHERE stats?'frame_p95_upper_ms')::int enhanced_batches FROM report_window WHERE ${w.clause} AND kind='interval' GROUP BY ${group} ORDER BY sum(active) DESC LIMIT 150) t) activities,
(SELECT COALESCE(jsonb_agg(t),'[]'::jsonb) FROM (SELECT count(*)::int batches,count(DISTINCT profile)::int profiles,count(DISTINCT device)::int devices,count(DISTINCT session)::int sessions,COALESCE(sum(active),0)::float active_seconds,count(*) FILTER (WHERE kind='graphics_loss')::int graphics_losses,count(*) FILTER (WHERE kind='complete')::int completions,max(created_at) latest,count(*) FILTER (WHERE stats?'frame_p95_upper_ms')::int enhanced_batches FROM report_window WHERE ${w.clause}) t) totals,
(SELECT COALESCE(jsonb_agg(t),'[]'::jsonb) FROM (SELECT ${categorySQL} category,mode,realm,route,kind,result,count(*)::int attempts,percentile_cont(0.5) WITHIN GROUP (ORDER BY duration) FILTER (WHERE duration>0) median_seconds,min(NULLIF(duration,0)) fastest_seconds,max(duration) longest_seconds,max(${metric('mine_depth')}) mine_depth,max(${metric('fish_level')}) fish_level,sum(${metric('banked_shards')}) banked_shards FROM report_window WHERE ${w.clause} AND kind!='interval' GROUP BY ${categorySQL},mode,realm,route,kind,result ORDER BY count(*) DESC LIMIT 150) t) outcomes,
(SELECT COALESCE(jsonb_agg(t),'[]'::jsonb) FROM (SELECT to_char(created_at AT TIME ZONE 'America/Edmonton','YYYY-MM-DD') AS "day",count(DISTINCT device)::int devices,count(DISTINCT session)::int sessions,sum(active)::float active_seconds,count(*) FILTER (WHERE kind='graphics_loss')::int graphics_losses FROM report_window WHERE ${w.clause} GROUP BY 1 ORDER BY 1) t) daily,
 (SELECT jsonb_build_object('batches',count(*),'oldest',min(created_at),'newest',max(created_at),'limit',${ACTIVITY_LIMIT},'limited',count(*)>=${ACTIVITY_LIMIT},'scope','Most recent uploaded batches in the selected period, before other filters') FROM report_window) source_window`,w.values);
 const d=q.rows[0];return {catalogue,filters:f,totals:d.totals[0],activities:d.activities,outcomes:d.outcomes,daily:d.daily,source_window:d.source_window,retention_days:30,limited:d.activities.length>=150||d.outcomes.length>=150};
}
export async function sessions(pool,f){
 const w=where(f,true,true);const q=await pool.query(`${activityWindow}SELECT session,COALESCE(NULLIF(attempt,''),session) attempt,${categorySQL} category,mode,realm,hero,route,platform platform,release release,min(created_at) started,max(created_at) updated,count(DISTINCT device)::int devices,count(*)::int batches,sum(active)::float active_seconds,sum(${stat('fps_mean')}*${stat('samples')})/NULLIF(sum(CASE WHEN ${stat('fps_mean')} IS NOT NULL THEN ${stat('samples')} END),0) fps_mean,min(${stat('fps_min')}) FILTER (WHERE ${stat('samples')}>0) fps_min,max(${stat('frame_p95_upper_ms')}) frame_p95_upper_ms,string_agg(DISTINCT NULLIF(result,''),', ') result,max(duration) duration FROM report_window WHERE ${w.clause} GROUP BY session,COALESCE(NULLIF(attempt,''),session),${categorySQL},mode,realm,hero,route,platform,release ORDER BY max(created_at) DESC LIMIT 101`,w.values);
 return {sessions:q.rows.slice(0,100),limited:q.rows.length>100,filters:f,source_window:await coverage(pool,f,'crossroads_activity',ACTIVITY_LIMIT)};
}
export async function activityDetail(pool,id,attempt='',category=''){
 const values=[id];let clause='session=$1';if(attempt){values.push(attempt);clause+=" AND COALESCE(NULLIF(payload->>'attempt',''),session)=$2";}
 if(category){values.push(category);clause+=` AND ${categorySQL}=$${values.length}`;}
 const q=await pool.query(`SELECT payload,created_at FROM crossroads_activity WHERE ${clause} ORDER BY created_at LIMIT 2001`,values);
 return {session:id,attempt,category,reports:q.rows.slice(0,2000).map(r=>({...r.payload,received_at:r.created_at})),limited:q.rows.length>2000};
}
export async function exportActivities(pool,f){const w=where(f);const q=await pool.query(`SELECT payload,created_at FROM crossroads_activity WHERE ${w.clause} ORDER BY created_at DESC LIMIT 5001`,w.values);return {filters:f,reports:q.rows.slice(0,5000).map(r=>({...r.payload,received_at:r.created_at})),limited:q.rows.length>5000,retention_days:30};}

// Direct raw download: no GROUP BY, percentile or JSON numeric conversions.
// Each side is independently useful if the other table is temporarily unavailable.
export async function performancePack(pool,f){
 const result={format:'crossroads-performance-pack-v1',exported_at:new Date().toISOString(),filters:f,retention_days:30,activity:[],multiplayer:[],coverage:{},errors:[]};
 for(const [key,table,limit,activity]of [['activity','crossroads_activity',200,true],['multiplayer','fx_reports',100,false]]){
  const w=where(f,activity);
  try{const q=await pool.query(`SELECT payload,created_at FROM ${table} WHERE ${w.clause} ORDER BY created_at DESC LIMIT ${limit+1}`,w.values);
   result[key]=q.rows.slice(0,limit).map(r=>({...r.payload,received_at:r.created_at}));
   result.coverage[key]={returned:result[key].length,limit,limited:q.rows.length>limit,order:'newest first',oldest:result[key].at(-1)?.received_at??null,newest:result[key][0]?.received_at??null};
  }catch(e){result.errors.push({source:key,code:/^[0-9A-Z]{5}$/.test(String(e.code||''))?e.code:'UNAVAILABLE'});}
 }
 if(result.errors.length===2)throw Object.assign(Error('Performance export unavailable'),{code:result.errors[0].code});
 return result;
}

// Stream complete diagnostic history in indexed keyset pages. No 5,000-row cap,
// full-table JSON aggregation, credentials, account rosters or classroom work.
export async function fullExport(pool,f,res,build){
 const until=new Date().toISOString(),since=new Date(Date.parse(until)-f.days*86400000).toISOString(),coverage={},errors=[];
 res.writeHead(200,{'content-type':'application/json','cache-control':'no-store','content-disposition':`attachment; filename="Crossroads_complete_${new Date().toISOString().slice(0,10)}.json"`,'x-content-type-options':'nosniff'});
 const write=async text=>{if(res.destroyed)throw Error('download closed');if(!res.write(text))await new Promise((ok,no)=>{const cleanup=()=>{res.off('drain',drain);res.off('close',close);};const drain=()=>{cleanup();ok();},close=()=>{cleanup();no(Error('download closed'));};res.once('drain',drain);res.once('close',close);});};
 await write(JSON.stringify({format:'crossroads-complete-export-v2',build,exported_at:until,filters:f,retention_days:30}).slice(0,-1));
 for(const [name,table,key,activity]of [['activity','crossroads_activity','event',true],['multiplayer','fx_reports','id',false]]){
  await write(',"'+name+'":[');let cursor=null,count=0,oldest=null,complete=true;
  try{while(!res.destroyed){const w=where(f,activity);w.values[0]=since;w.values.push(until);let clause=w.clause+' AND created_at <= $'+w.values.length;if(cursor){w.values.push(cursor.at,cursor.key);clause+=` AND (created_at,${key}) < ($${w.values.length-1}::timestamptz,$${w.values.length}::text)`;}
   const q=await pool.query(`SELECT ${key} export_key,payload,created_at FROM ${table} WHERE ${clause} ORDER BY created_at DESC,${key} DESC LIMIT 500`,w.values);if(!q.rows.length)break;
   for(const row of q.rows){await write((count?',':'')+JSON.stringify({...row.payload,received_at:row.created_at}));count++;oldest=row.created_at;}
   const last=q.rows.at(-1);cursor={at:last.created_at,key:last.export_key};if(q.rows.length<500)break;
  }}catch(e){if(res.destroyed)return;complete=false;errors.push({source:name,code:/^[0-9A-Z]{5}$/.test(e.code||'')?e.code:'UNAVAILABLE'});}
  coverage[name]={returned:count,complete,limited:!complete,oldest};await write(']');
 }
 await write(',"coverage":'+JSON.stringify(coverage)+',"errors":'+JSON.stringify(errors)+'}');res.end();
}
