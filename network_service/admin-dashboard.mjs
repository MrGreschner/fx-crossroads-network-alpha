import {readFile} from 'node:fs/promises';
import {BUILD} from './release.mjs';
export function createAdminDashboard({pool,admin,state=()=>({}),now=()=>Date.now()}={}){
 let cached=null,until=0,loading=null;
 const send=(res,code,data,headers={})=>{res.writeHead(code,{'content-type':'application/json','cache-control':'no-store','x-content-type-options':'nosniff',...headers});res.end(JSON.stringify(data));};
 async function collect(){
  if(!pool)return {database:{available:false},sections:{},captured_at:new Date(now()).toISOString()};
  let tables;try{tables=new Set((await pool.query("SELECT tablename FROM pg_tables WHERE schemaname=current_schema()")).rows.map(r=>r.tablename));}catch{return {database:{available:false},sections:{},captured_at:new Date(now()).toISOString()};}
  const jobs={
   accounts:[['crossroads_accounts'],`SELECT count(*) FILTER(WHERE NOT disabled)::int active,count(*) FILTER(WHERE NOT disabled AND role='student')::int students,count(*) FILTER(WHERE NOT disabled AND role='teacher')::int teachers,count(*) FILTER(WHERE disabled)::int disabled,count(*) FILTER(WHERE username_warning AND NOT disabled)::int warnings,count(*) FILTER(WHERE save IS NOT NULL)::int cloud_saves,count(*) FILTER(WHERE created_at>now()-interval '7 days')::int new_week FROM crossroads_accounts`],
   heroes:[['crossroads_hero_submissions'],`SELECT count(*) FILTER(WHERE state='pending')::int pending,count(*) FILTER(WHERE state='approved')::int approved,count(*) FILTER(WHERE state='rejected')::int rejected FROM crossroads_hero_submissions`],
   hero_queue:[['crossroads_hero_submissions'],`SELECT id,username,project->'hero'->>'name' name,CASE WHEN length(project->'hero'->'art'->>'idle')<=180000 THEN project->'hero'->'art'->>'idle' ELSE NULL END thumbnail,revision,created_at FROM crossroads_hero_submissions WHERE state='pending' ORDER BY created_at,id LIMIT 4`],
   learning:[['crossroads_submissions','crossroads_grades','crossroads_business_completions','crossroads_classes'],`SELECT (SELECT count(*)::int FROM crossroads_submissions s WHERE NOT EXISTS(SELECT 1 FROM crossroads_grades g WHERE g.submission=s.id AND g.status='returned')) awaiting_review,(SELECT count(*)::int FROM crossroads_business_completions WHERE status='completed') completions,(SELECT count(*)::int FROM crossroads_classes WHERE NOT archived) classes`],
   activity:[['crossroads_activity'],`SELECT count(*)::int reports,count(DISTINCT profile)::int reporting_profiles,max(created_at) latest FROM crossroads_activity WHERE created_at>now()-interval '7 days'`],
   modes:[['crossroads_activity'],`SELECT category,count(*)::int reports FROM crossroads_activity WHERE created_at>now()-interval '7 days' GROUP BY category ORDER BY count(*) DESC,category LIMIT 6`],
   daily:[['crossroads_activity'],`SELECT (created_at AT TIME ZONE 'America/Edmonton')::date::text AS "day",count(*)::int reports FROM crossroads_activity WHERE created_at>now()-interval '7 days' GROUP BY 1 ORDER BY 1`],
   diagnostics:[['fx_reports'],`SELECT count(*)::int reports,max(created_at) latest FROM fx_reports WHERE created_at>now()-interval '7 days'`],
   repairs:[['crossroads_record_repairs'],`SELECT count(*) FILTER(WHERE NOT restored)::int applied,count(*) FILTER(WHERE restored)::int restored FROM crossroads_record_repairs`],
   audit:[['crossroads_account_audit','crossroads_accounts'],`SELECT a.username,x.action,x.created_at FROM crossroads_account_audit x LEFT JOIN crossroads_accounts a ON a.id=x.account ORDER BY x.created_at DESC,x.id DESC LIMIT 8`]
  };
  const entries=Object.entries(jobs);const results=await Promise.allSettled(entries.map(async([name,[required,sql]])=>{if(!required.every(t=>tables.has(t)))return {available:false};const q=await pool.query(sql);return {available:true,rows:q.rows};}));
  const sections={};results.forEach((r,i)=>sections[entries[i][0]]=r.status==='fulfilled'?r.value:{available:false});
  return {database:{available:true},sections,captured_at:new Date(now()).toISOString()};
 }
 async function overview(){if(!cached||now()>=until){if(!loading)loading=collect().then(r=>{cached=r;until=now()+20000;return r;}).finally(()=>loading=null);await loading;}return {...cached,build:BUILD,live:state(),server_time:new Date(now()).toISOString()};}
 async function handle(req,res){const u=new URL(req.url,'http://localhost');if(u.pathname==='/'&&req.method==='GET'){res.writeHead(302,{location:'/admin','cache-control':'no-store'});res.end();return true;}if(!u.pathname.startsWith('/admin'))return false;
  if(!admin(req)){send(res,401,{error:'Sign in as admin using the existing administrator password.'},{'www-authenticate':'Basic realm="Crossroads administration", charset="UTF-8"'});req.resume();return true;}
  if(req.method!=='GET'){send(res,405,{error:'This dashboard is read-only.'});req.resume();return true;}
  try{
   const files={'/admin':'admin-dashboard.html','/admin/':'admin-dashboard.html','/admin/dashboard.js':'admin-dashboard.js','/admin/dashboard.css':'admin-dashboard.css'};
   if(files[u.pathname]){const name=files[u.pathname];res.writeHead(200,{'content-type':name.endsWith('.html')?'text/html; charset=utf-8':name.endsWith('.css')?'text/css':'text/javascript','cache-control':'no-store','x-content-type-options':'nosniff','referrer-policy':'no-referrer','content-security-policy':"default-src 'none'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'"});res.end(await readFile(new URL('./'+name,import.meta.url)));return true;}
   if(u.pathname==='/admin/api/overview'){send(res,200,await overview());return true;}
   send(res,404,{error:'Not found'});
  }catch{send(res,503,{error:'The overview is temporarily unavailable. Existing management tools and saved data are unchanged.'});}return true;
 }
 return {handle,overview};
}
