import {randomUUID,createHash} from 'node:crypto';
import {mkdtemp,writeFile,rm,readFile} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
import {execFile} from 'node:child_process';
import {promisify} from 'node:util';
const exec=promisify(execFile);
export function godotValidator({root=resolve(process.env.FX_PROJECT_ROOT||'..'),binary=process.env.GODOT_BIN||'godot'}={}){
 let active=false;
 return async project=>{
  if(active)throw Object.assign(Error('Another hero is being checked. Try again in a moment.'),{status:429});
  active=true;let dir;
  try{dir=await mkdtemp(join(tmpdir(),'crossroads-hero-'));const path=join(dir,'project.json');await writeFile(path,JSON.stringify(project),{mode:0o600});
   const {stdout}=await exec(binary,['--headless','--path',root,'--script','res://network_service/validate_hero.gd','--',path],{timeout:20000,maxBuffer:4*1024*1024,env:{...process.env,FX_HERO_VALIDATOR:'1',XDG_DATA_HOME:dir}});
   const line=stdout.split('\n').find(s=>s.startsWith('HERO_VALIDATION '));if(!line)throw Error('Hero checker unavailable');const result=JSON.parse(line.slice(16));if(result.error)throw Object.assign(Error(result.error),{status:400});return result;
  }finally{if(dir)await rm(dir,{recursive:true,force:true});active=false;}
 };
}
export const schema=`CREATE TABLE IF NOT EXISTS crossroads_hero_submissions(id text PRIMARY KEY,account text NOT NULL,username text NOT NULL,project_id text NOT NULL,revision integer NOT NULL,fingerprint text NOT NULL,project jsonb NOT NULL,coverage jsonb NOT NULL,state text NOT NULL DEFAULT 'pending' CHECK(state IN ('pending','approved','rejected','withdrawn')),review_note text NOT NULL DEFAULT '',created_at timestamptz NOT NULL DEFAULT now(),reviewed_at timestamptz,UNIQUE(account,fingerprint)); CREATE INDEX IF NOT EXISTS crossroads_hero_review_queue ON crossroads_hero_submissions(state,created_at);`;
const fail=(status,message)=>{throw Object.assign(Error(message),{status})};
export function createHeroes({pool,accounts,admin=()=>false,validate=godotValidator()}={}){
 let ready=false;const initialized=(async()=>{if(!pool)return;try{await pool.query(schema);ready=true;}catch{console.error('Community hero schema unavailable');}})();
 const send=(res,status,value)=>{res.writeHead(status,{'content-type':'application/json','cache-control':'no-store','x-content-type-options':'nosniff'});res.end(JSON.stringify(value))};
 async function body(req){let size=0,parts=[];const timer=setTimeout(()=>req.destroy(),15000);timer.unref();try{for await(const part of req){size+=part.length;if(size>2097152)fail(413,'Hero project exceeds 2 MB.');parts.push(part)}try{return JSON.parse(Buffer.concat(parts))}catch{fail(400,'Invalid submission JSON.')}}finally{clearTimeout(timer)}}
 async function handle(req,res){const u=new URL(req.url,'http://localhost'),path=u.pathname;if(path!=='/heroes'&&!path.startsWith('/heroes/'))return false;
  const privateRoute=path==='/heroes'||path.startsWith('/heroes/admin')||path==='/heroes/review.js';
  if(!privateRoute){const origin=req.headers.origin||'';if(origin&&!/^https:\/\/([a-z0-9-]+\.)*(itch\.zone|itch\.io)$/.test(origin)&&!(process.env.REPORT_ALLOWED_ORIGIN||'').split(',').includes(origin)&&!(process.env.FX_LOCAL_TEST==='1'&&/^http:\/\/127\.0\.0\.1:\d+$/.test(origin))){send(res,403,{error:'Origin rejected'});req.resume();return true;}if(origin){res.setHeader('access-control-allow-origin',origin);res.setHeader('vary','Origin');}if(req.method==='OPTIONS'){res.writeHead(204,{'access-control-allow-methods':'GET,POST','access-control-allow-headers':'content-type,authorization'});res.end();return true;}}
  if(privateRoute&&!admin(req)){res.setHeader('WWW-Authenticate','Basic realm="Crossroads hero review"');send(res,401,{error:'Private hero review'});req.resume();return true;}
  try{
   if(privateRoute&&req.method==='POST'&&req.headers.origin&&new URL(req.headers.origin).host!==req.headers.host)fail(403,'Origin rejected');
   if(path==='/heroes'&&req.method==='GET'){res.writeHead(200,{'content-type':'text/html; charset=utf-8','cache-control':'no-store','content-security-policy':"default-src 'self'; img-src 'self' data:; style-src 'self' 'unsafe-inline'; script-src 'self'; frame-ancestors 'none'"});res.end(await readFile(new URL('./heroes.html',import.meta.url)));return true;}
   if(path==='/heroes/review.js'&&req.method==='GET'){res.writeHead(200,{'content-type':'text/javascript; charset=utf-8','cache-control':'no-store'});res.end(await readFile(new URL('./heroes-review.js',import.meta.url)));return true;}
   if(!ready)fail(503,'Community heroes need the database connection. Ask the administrator to deploy the updated server.');
   if(path==='/heroes/catalog'&&req.method==='GET'){
    const offset=Number(u.searchParams.get('offset')||0);if(!Number.isSafeInteger(offset)||offset<0||offset>10000)fail(400,'Invalid catalog page');
    const rows=await pool.query(`SELECT h.id,h.username,h.project,h.coverage FROM crossroads_hero_submissions h JOIN crossroads_accounts a ON a.id=h.account WHERE h.state='approved' AND NOT a.disabled ORDER BY h.created_at,h.id LIMIT 10 OFFSET $1`,[offset]);
    send(res,200,{version:1,heroes:rows.rows,next:rows.rows.length===10?offset+10:null});return true;
   }
   if(path==='/heroes/admin/list'&&req.method==='GET'){
    const state=u.searchParams.get('state')||'pending';if(!['pending','approved','rejected','withdrawn','all'].includes(state))fail(400,'Unknown review category');
    const rows=await pool.query(`SELECT h.id,h.username,h.revision,h.state,h.project,h.coverage,h.review_note,h.created_at,h.reviewed_at FROM crossroads_hero_submissions h WHERE ($1='all' OR h.state=$1) ORDER BY h.created_at DESC LIMIT 100`,[state]);send(res,200,{submissions:rows.rows});return true;
   }
   if(path==='/heroes/admin/review'&&req.method==='POST'){
    const p=await body(req);if(!/^[a-f0-9-]{36}$/.test(p.id||'')||!['approved','rejected','withdrawn'].includes(p.state)||typeof p.note!=='string'||p.note.length>500)fail(400,'Choose a submission, review decision and note of at most 500 characters.');
    const row=(await pool.query('SELECT * FROM crossroads_hero_submissions WHERE id=$1',[p.id])).rows[0];if(!row)fail(404,'Submission not found');
    if(p.state==='approved')await validate(row.project);
    // At most one published revision per author project; replaced copies remain in review history.
    if(p.state==='approved')await pool.query(`UPDATE crossroads_hero_submissions SET state='withdrawn',review_note='Superseded by an approved revision',reviewed_at=now() WHERE account=$1 AND project_id=$2 AND id<>$3 AND state='approved'`,[row.account,row.project_id,row.id]);
    await pool.query(`UPDATE crossroads_hero_submissions SET state=$1,review_note=$2,reviewed_at=now() WHERE id=$3`,[p.state,p.note,p.id]);send(res,200,{ok:true});return true;
   }
   const account=await accounts.authenticate(req);if(!account)fail(401,'Sign in to your cloud account before submitting a hero.');
   if(path==='/heroes/mine'&&req.method==='GET'){const rows=await pool.query(`SELECT id,project->'hero'->>'name' name,revision,state,review_note,created_at FROM crossroads_hero_submissions WHERE account=$1 ORDER BY created_at DESC LIMIT 40`,[account.id]);send(res,200,{submissions:rows.rows});return true;}
   if(path==='/heroes/submit'&&req.method==='POST'){
    const p=await body(req);if(!p||typeof p.project!=='object'||Array.isArray(p.project))fail(400,'Choose a Studio hero project.');
    const count=await pool.query(`SELECT count(*)::integer n FROM crossroads_hero_submissions WHERE account=$1 AND (state='pending' OR created_at>now()-interval '1 day')`,[account.id]);if(count.rows[0].n>=5)fail(429,'You can have five pending submissions or submit five heroes per day.');
    const checked=await validate(p.project);const project=checked.project;project.author=account.username;
    const fingerprint=createHash('sha256').update(JSON.stringify(project)).digest('hex');const id=randomUUID();
    const inserted=await pool.query(`INSERT INTO crossroads_hero_submissions(id,account,username,project_id,revision,fingerprint,project,coverage) VALUES($1,$2,$3,$4,$5,$6,$7::jsonb,$8::jsonb) ON CONFLICT(account,fingerprint) DO NOTHING RETURNING id`,[id,account.id,account.username,project.project_id,project.revision,fingerprint,JSON.stringify(project),JSON.stringify(checked.coverage)]);
    if(!inserted.rows.length)fail(409,'This exact hero has already been submitted. Check My submissions.');send(res,201,{id,state:'pending',message:'Hero sent for admin review. It will appear in Community heroes after approval.'});return true;
   }
   fail(404,'Hero route not found');
  }catch(e){send(res,e.status||503,{error:e.status?e.message:'Hero review is temporarily unavailable. Your draft is safe.'});req.resume();}return true;
 }
 return {handle,initialized,status:()=>({ready,review_required:true,min_art_coverage:.3})};
}
