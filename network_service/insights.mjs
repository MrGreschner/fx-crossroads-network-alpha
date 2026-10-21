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
function where(f,activity=true){
 const values=[new Date(Date.now()-f.days*86400000).toISOString()];const clauses=['created_at >= $1'];
 const add=(sql,v)=>{if(v){values.push(v);clauses.push(sql+'=$'+values.length);}};
 if(activity){add(categorySQL,f.category);add('route',f.route);add("payload->'details'->>'input'",f.input);add("payload->>'platform'",f.platform);add('realm',f.realm);add('hero',f.hero);add("payload->>'release'",f.build);}
 else{if(f.input)clauses.push(f.input==='touch'?"payload->'samples'->0->>'mobile_controls'='true'":"payload->'samples'->0->>'mobile_controls'='false'");add(realCategory,f.category);add("payload->'samples'->0->>'realm'",f.realm);add('hero',f.hero);add('build',f.build);if(f.route&&f.route!=='dedicated')clauses.push('false');if(f.platform)clauses.push(f.platform==='web'?"COALESCE(payload->'samples'->0->>'platform','web')='web'":"COALESCE(payload->'samples'->0->>'platform','web')=$"+(values.push(f.platform)));}
 return {values,clause:clauses.join(' AND ')};
}
const stat=k=>reportNumberSQL(`payload->'stats'->'${k}'`);
const metric=k=>reportNumberSQL(`payload->'metrics'->'${k}'`);
export async function matches(pool,f){
 const w=where(f,false);const q=await pool.query(`SELECT match_id,max(room) room,max(build) build,min(created_at) started,max(created_at) updated,count(DISTINCT actor)::int devices,count(*)::int batches,max(${realCategory}) category,max(payload->'samples'->0->>'realm') realm,max(payload->'samples'->0->>'mode') mode,max(${reportNumberSQL("payload->'samples'->0->'players'")}) players FROM fx_reports WHERE ${w.clause} GROUP BY match_id ORDER BY max(created_at) DESC LIMIT 101`,w.values);
 return {matches:q.rows.slice(0,100),limited:q.rows.length>100,filters:f,retention_days:30};
}
export async function overview(pool,f){
 const w=where(f);const group=`${categorySQL},mode,realm,route,payload->>'platform',payload->>'release'`;
 const rows=await pool.query(`SELECT ${categorySQL} category,mode,realm,route,payload->>'platform' platform,payload->>'release' release,count(DISTINCT profile)::int profiles,count(DISTINCT device)::int devices,count(DISTINCT session)::int sessions,sum(active)::float active_seconds,sum(seconds)::float observed_seconds,sum(${stat('samples')})::float fps_samples,sum(${stat('fps_mean')}*${stat('samples')})/NULLIF(sum(CASE WHEN ${stat('fps_mean')} IS NOT NULL THEN ${stat('samples')} END),0) fps_mean,min(${stat('fps_min')}) FILTER (WHERE ${stat('samples')}>0) fps_min,sum(${stat('below_40')})::float below_40,max(${stat('frame_p95_upper_ms')}) frame_p95_upper_ms,max(${stat('frame_max_ms')}) frame_max_ms,max(${stat('draw_max')}) draw_max,max(${stat('entities_max')}) entities_max,max(${stat('projectiles_max')}) projectiles_max,max(${stat('process_max_ms')}) process_max_ms,max(${stat('physics_max_ms')}) physics_max_ms,max(${stat('rtt_max_ms')}) rtt_max_ms,max(${stat('server_work_max_ms')}) server_work_max_ms,min(${stat('authority_hz_min')}) authority_hz_min,count(*) FILTER (WHERE payload->'stats'?'frame_p95_upper_ms')::int enhanced_batches FROM crossroads_activity WHERE ${w.clause} AND kind='interval' GROUP BY ${group} ORDER BY sum(active) DESC LIMIT 150`,w.values);
 const totals=await pool.query(`SELECT count(*)::int batches,count(DISTINCT profile)::int profiles,count(DISTINCT device)::int devices,count(DISTINCT session)::int sessions,COALESCE(sum(active),0)::float active_seconds,count(*) FILTER (WHERE kind='graphics_loss')::int graphics_losses,count(*) FILTER (WHERE kind='complete')::int completions,max(created_at) latest,count(*) FILTER (WHERE payload->'stats'?'frame_p95_upper_ms')::int enhanced_batches FROM crossroads_activity WHERE ${w.clause}`,w.values);
 const outcomes=await pool.query(`SELECT ${categorySQL} category,mode,realm,route,kind,result,count(*)::int attempts,percentile_cont(0.5) WITHIN GROUP (ORDER BY duration) FILTER (WHERE duration>0) median_seconds,min(NULLIF(duration,0)) fastest_seconds,max(duration) longest_seconds,max(${metric('mine_depth')}) mine_depth,max(${metric('fish_level')}) fish_level,sum(${metric('banked_shards')}) banked_shards FROM crossroads_activity WHERE ${w.clause} AND kind!='interval' GROUP BY ${categorySQL},mode,realm,route,kind,result ORDER BY count(*) DESC LIMIT 150`,w.values);
 const daily=await pool.query(`SELECT to_char(created_at AT TIME ZONE 'America/Edmonton','YYYY-MM-DD') AS "day",count(DISTINCT device)::int devices,count(DISTINCT session)::int sessions,sum(active)::float active_seconds,count(*) FILTER (WHERE kind='graphics_loss')::int graphics_losses FROM crossroads_activity WHERE ${w.clause} GROUP BY 1 ORDER BY 1`,w.values);
 return {catalogue,filters:f,totals:totals.rows[0],activities:rows.rows,outcomes:outcomes.rows,daily:daily.rows,retention_days:30,limited:rows.rows.length>=150||outcomes.rows.length>=150};
}
export async function sessions(pool,f){
 const w=where(f);const q=await pool.query(`SELECT session,COALESCE(NULLIF(payload->>'attempt',''),session) attempt,${categorySQL} category,mode,realm,hero,route,payload->>'platform' platform,payload->>'release' release,min(created_at) started,max(created_at) updated,count(DISTINCT device)::int devices,count(*)::int batches,sum(active)::float active_seconds,sum(${stat('fps_mean')}*${stat('samples')})/NULLIF(sum(CASE WHEN ${stat('fps_mean')} IS NOT NULL THEN ${stat('samples')} END),0) fps_mean,min(${stat('fps_min')}) FILTER (WHERE ${stat('samples')}>0) fps_min,max(${stat('frame_p95_upper_ms')}) frame_p95_upper_ms,string_agg(DISTINCT NULLIF(result,''),', ') result,max(duration) duration FROM crossroads_activity WHERE ${w.clause} GROUP BY session,COALESCE(NULLIF(payload->>'attempt',''),session),${categorySQL},mode,realm,hero,route,payload->>'platform',payload->>'release' ORDER BY max(created_at) DESC LIMIT 101`,w.values);
 return {sessions:q.rows.slice(0,100),limited:q.rows.length>100,filters:f};
}
export async function activityDetail(pool,id,attempt='',category=''){
 const values=[id];let clause='session=$1';if(attempt){values.push(attempt);clause+=" AND COALESCE(NULLIF(payload->>'attempt',''),session)=$2";}
 if(category){values.push(category);clause+=` AND ${categorySQL}=$${values.length}`;}
 const q=await pool.query(`SELECT payload,created_at FROM crossroads_activity WHERE ${clause} ORDER BY created_at LIMIT 2001`,values);
 return {session:id,attempt,category,reports:q.rows.slice(0,2000).map(r=>({...r.payload,received_at:r.created_at})),limited:q.rows.length>2000};
}
export async function exportActivities(pool,f){const w=where(f);const q=await pool.query(`SELECT payload,created_at FROM crossroads_activity WHERE ${w.clause} ORDER BY created_at DESC LIMIT 5001`,w.values);return {filters:f,reports:q.rows.slice(0,5000).map(r=>({...r.payload,received_at:r.created_at})),limited:q.rows.length>5000,retention_days:30};}
