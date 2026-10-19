import {randomBytes,createHash,scrypt as derive,timingSafeEqual,createCipheriv,createDecipheriv} from 'node:crypto';
import {promisify} from 'node:util';
import {readFileSync} from 'node:fs';
import {checkUsername} from './usernames.mjs';
const scrypt=promisify(derive),digest=x=>createHash('sha256').update(x).digest('hex');
export const accountSchema=`CREATE TABLE IF NOT EXISTS crossroads_accounts(id text PRIMARY KEY,username text NOT NULL,username_key text UNIQUE NOT NULL,password_hash text NOT NULL,role text NOT NULL DEFAULT 'player',identity text,disabled boolean NOT NULL DEFAULT false,revision integer NOT NULL DEFAULT 0,save text,profile text UNIQUE,created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS crossroads_sessions(token text PRIMARY KEY,account text NOT NULL REFERENCES crossroads_accounts(id) ON DELETE CASCADE,expires_at timestamptz NOT NULL);
CREATE TABLE IF NOT EXISTS crossroads_save_history(account text NOT NULL REFERENCES crossroads_accounts(id) ON DELETE CASCADE,revision integer NOT NULL,save text NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(account,revision));
CREATE TABLE IF NOT EXISTS crossroads_account_audit(id bigserial PRIMARY KEY,account text NOT NULL,action text NOT NULL,created_at timestamptz NOT NULL DEFAULT now());`;
function fail(status,message){throw Object.assign(Error(message),{status});}
export function validateCloudSave(v){
 if(!v||v.format!=='fx-crossroads-profile'||v.version!==1||!v.progress||typeof v.progress!=='object'||Array.isArray(v.progress)||!v.saves||typeof v.saves!=='object'||Array.isArray(v.saves))fail(400,'Unsupported profile. Your cloud save has not changed.');
 if(v.progress.teacher||v.progress.teacher_backup||v.progress.backup_saves)fail(400,'Exit testing mode before saving.');
 if(!v.progress.tasks||!v.progress.heroes||!v.progress.card)fail(400,'Incomplete profile.');
 // Portable profile identifiers never authenticate an account.
 for(const k of Object.keys(v.saves))if(!/^[A-Za-z0-9_-]+\.json$/.test(k)||k==='fx_education_access.json'||k==='fx_teacher_classes.json')fail(400,'Private permissions cannot be uploaded.');
 let count=0;function visit(x,depth=0){if(++count>200000||depth>32)fail(400,'Profile is too complex.');if(typeof x==='number'&&!Number.isFinite(x))fail(400,'Invalid number.');if(x&&typeof x==='object')for(const [k,y] of Object.entries(x)){if(['__proto__','prototype','constructor'].includes(k))fail(400,'Invalid field.');visit(y,depth+1);}}visit(v);
 return v;
}
export function createAccounts({pool,admin=()=>false,key=process.env.CLOUD_SAVE_KEY||'',now=()=>Date.now()}={}){
 let encryption;try{const k=Buffer.from(key,'base64');if(k.length===32)encryption=k;}catch{}
 let ready=false,busy=0,hashing=0;const rate=new Map(),failures=new Map();
 let retryAt=0;const initialize=async()=>{try{await pool.query(accountSchema);ready=!!encryption;}catch{ready=false;}retryAt=now()+30000;};const initialized=pool?initialize():Promise.resolve();
 const seal=v=>{const iv=randomBytes(12),c=createCipheriv('aes-256-gcm',encryption,iv);const b=Buffer.concat([c.update(JSON.stringify(v),'utf8'),c.final()]);return Buffer.concat([iv,c.getAuthTag(),b]).toString('base64');};
 const unseal=s=>{const b=Buffer.from(s,'base64'),d=createDecipheriv('aes-256-gcm',encryption,b.subarray(0,12));d.setAuthTag(b.subarray(12,28));return JSON.parse(Buffer.concat([d.update(b.subarray(28)),d.final()]).toString());};
 async function password(value,saved){
  if(typeof value!=='string'||value.length<15||value.length>128)fail(400,'Choose a password of 15–128 characters. A few words work well. Do not use your school password.');
  if(hashing>=2)fail(429,'Sign-in busy; please try again shortly.');hashing++;
  try{const salt=saved?saved.split(':')[0]:randomBytes(16).toString('hex'),out=await scrypt(value,salt,64,{N:131072,r:8,p:1,maxmem:192*1024*1024});return saved?timingSafeEqual(out,Buffer.from(saved.split(':')[1],'hex')):salt+':'+out.toString('hex');}finally{hashing--;}
 }
 async function authenticate(req){const raw=(req.headers.authorization||'').replace(/^Bearer /,'');if(!/^[a-f0-9]{64}$/.test(raw))return null;const q=await pool.query(`SELECT a.*,s.token session_token FROM crossroads_sessions s JOIN crossroads_accounts a ON a.id=s.account WHERE s.token=$1 AND s.expires_at>to_timestamp($2) AND NOT a.disabled`,[digest(raw),now()/1000]);return q.rows[0]||null;}
 const publicUser=a=>({id:a.id,username:a.username,role:a.role,needs_identity:a.role!=='player'&&!a.identity,revision:a.revision,has_save:!!a.save});
 async function body(req){let bytes=0;const chunks=[];const timer=setTimeout(()=>req.destroy(),15000);timer.unref();try{for await(const chunk of req){bytes+=chunk.length;if(bytes>4194304)fail(413,'Cloud profile limit is 4 MB. Download a local backup; your previous cloud save is safe.');chunks.push(chunk);}return JSON.parse(Buffer.concat(chunks));}finally{clearTimeout(timer);}}
 function send(res,status,data,extra={}){res.writeHead(status,{'content-type':'application/json','cache-control':'no-store','x-content-type-options':'nosniff',...extra});res.end(JSON.stringify(data));}
 async function save(a,v,revision){
  validateCloudSave(v);if(!Number.isInteger(revision)||revision<0)fail(400,'Invalid save revision.');
  // One conditional UPDATE owns the revision. A history row is written with it in one SQL statement.
  const q=await pool.query(`WITH changed AS (UPDATE crossroads_accounts SET save=$1,revision=revision+1,updated_at=now() WHERE id=$2 AND revision=$3 RETURNING id,revision,save) INSERT INTO crossroads_save_history(account,revision,save) SELECT id,revision,save FROM changed RETURNING revision`,[seal(v),a.id,revision]);
  if(!q.rows.length)fail(409,'A newer cloud save exists. Saving paused. Download this device profile, then load the cloud save.');
  await pool.query(`DELETE FROM crossroads_save_history WHERE account=$1 AND revision NOT IN(SELECT revision FROM crossroads_save_history WHERE account=$1 ORDER BY revision DESC LIMIT 10)`,[a.id]);
  return q.rows[0].revision;
 }
 async function handle(req,res){const url=new URL(req.url,'http://localhost'),path=url.pathname;if(!path.startsWith('/accounts/')&&path!=='/accounts')return false;
  const isAdmin=path==='/accounts'||path.startsWith('/accounts/admin')||path==='/accounts/control.js';
  if(isAdmin){if(!admin(req)){send(res,401,{error:'Private account controls'},{'WWW-Authenticate':'Basic realm="Crossroads private accounts"'});req.resume();return true;}if(req.method==='POST'&&req.headers.origin&&new URL(req.headers.origin).host!==req.headers.host){send(res,403,{error:'Origin rejected'});req.resume();return true;}}
  else{const origin=req.headers.origin||'';if(origin&&!/^https:\/\/([a-z0-9-]+\.)*(itch\.zone|itch\.io)$/.test(origin)&&!(process.env.REPORT_ALLOWED_ORIGIN||'').split(',').includes(origin)&&!(process.env.FX_LOCAL_TEST==='1'&&/^http:\/\/127\.0\.0\.1:\d+$/.test(origin))){send(res,403,{error:'Origin rejected'});req.resume();return true;}if(origin){res.setHeader('access-control-allow-origin',origin);res.setHeader('vary','Origin');}if(req.method==='OPTIONS'){send(res,204,{}, {'access-control-allow-methods':'GET,POST','access-control-allow-headers':'content-type,authorization'});return true;}}
  if(isAdmin&&req.method==='GET'&&['/accounts','/accounts/control.js'].includes(path)){res.writeHead(200,{'content-type':path==='/accounts'?'text/html; charset=utf-8':'text/javascript','cache-control':'no-store','content-security-policy':"default-src 'none'; script-src 'self'; style-src 'unsafe-inline'; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'"});res.end(readFileSync(new URL(path==='/accounts'?'./accounts.html':'./accounts-control.js',import.meta.url)));return true;}
  if(!ready&&pool&&encryption&&now()>retryAt)await initialize();if(!ready){send(res,503,{error:isAdmin?'Cloud accounts unavailable. Set CLOUD_SAVE_KEY (32 random bytes, base64) and DATABASE_URL, then redeploy.':'Cloud accounts are not available yet. Keep a downloaded profile backup and ask your teacher or game administrator.'});req.resume();return true;}
  const ip=req.socket.remoteAddress||'unknown';let rr=rate.get(ip);if(!rr||now()-rr.at>60000)rr={at:now(),auth:0,other:0};rate.set(ip,rr);if(rate.size>4096)rate.delete(rate.keys().next().value);
  const authRoute=['/accounts/register','/accounts/login'].includes(path);if((authRoute?++rr.auth>80:++rr.other>1200)||busy>=8){send(res,429,{error:'Please retry shortly.'});req.resume();return true;}
  busy++;
  try{
   if(isAdmin){
    if(path==='/accounts/admin/list'&&req.method==='GET'){const search=(url.searchParams.get('search')||'').slice(0,20).toLowerCase().replace(/[^a-z0-9_]/g,'');const q=await pool.query(`SELECT id,username,role,identity,disabled,revision,created_at,updated_at FROM crossroads_accounts WHERE position($1 in username_key)>0 ORDER BY username_key LIMIT 100`,[search]);send(res,200,{accounts:q.rows.map(a=>({...a,identity:a.identity?unseal(a.identity):null}))});return true;}
    if(req.method!=='POST')fail(405,'POST required');const p=await body(req);if(!/^[a-f0-9]{32}$/.test(p.id||''))fail(400,'Invalid account');const a=(await pool.query('SELECT * FROM crossroads_accounts WHERE id=$1',[p.id])).rows[0];if(!a)fail(404,'Account not found');
    let action='';
    if(path==='/accounts/admin/role'){if(!['player','student','teacher'].includes(p.role))fail(400,'Invalid role');await pool.query('UPDATE crossroads_accounts SET role=$1,identity=NULL WHERE id=$2',[p.role,p.id]);action='role:'+p.role;}
    else if(path==='/accounts/admin/disable'){await pool.query('UPDATE crossroads_accounts SET disabled=$1 WHERE id=$2',[!!p.disabled,p.id]);await pool.query('DELETE FROM crossroads_sessions WHERE account=$1',[p.id]);action=p.disabled?'disabled':'enabled';}
    else if(path==='/accounts/admin/password'){const hashed=await password(p.password);await pool.query('UPDATE crossroads_accounts SET password_hash=$1 WHERE id=$2',[hashed,p.id]);await pool.query('DELETE FROM crossroads_sessions WHERE account=$1',[p.id]);action='password_reset';}
    else if(path==='/accounts/admin/history'){const rows=await pool.query('SELECT revision,created_at FROM crossroads_save_history WHERE account=$1 ORDER BY revision DESC LIMIT 10',[p.id]);send(res,200,{history:rows.rows});return true;}
    else if(path==='/accounts/admin/restore'){const old=(await pool.query('SELECT save FROM crossroads_save_history WHERE account=$1 AND revision=$2',[p.id,p.revision])).rows[0];if(!old)fail(404,'Save revision not found');const revision=await save(a,unseal(old.save),a.revision);await pool.query('DELETE FROM crossroads_sessions WHERE account=$1',[p.id]);action='restore:'+p.revision;}
    else fail(404,'Not found');await pool.query('INSERT INTO crossroads_account_audit(account,action) VALUES($1,$2)',[p.id,action]);send(res,200,{saved:true});return true;
   }
   if(authRoute){if(req.method!=='POST')fail(405,'POST required');const p=await body(req);let a;
    if(path.endsWith('/register')){const name=checkUsername(p.username),hashed=await password(p.password),id=randomBytes(16).toString('hex');try{a=(await pool.query('INSERT INTO crossroads_accounts(id,username,username_key,password_hash) VALUES($1,$2,$3,$4) RETURNING *',[id,name.username,name.key,hashed])).rows[0];}catch(e){if(e.code==='23505')fail(409,'That username is already taken. Choose another.');throw e;}}
    else{if(typeof p.username!=='string'||p.username.length>20)fail(401,'Username or password is incorrect');const fk=digest(p.username.toLowerCase()),attempt=failures.get(fk)||{at:now(),count:0};if(now()-attempt.at>900000){attempt.at=now();attempt.count=0;}if(attempt.count>=12)fail(429,'Too many attempts for this username. Try again in 15 minutes.');a=(await pool.query('SELECT * FROM crossroads_accounts WHERE username_key=$1',[p.username.toLowerCase()])).rows[0];const dummy='01234567890123456789012345678901:'+('00'.repeat(64));const good=await password(p.password,a?.password_hash||dummy);if(!a||!good||a.disabled){attempt.count++;failures.set(fk,attempt);if(failures.size>8192)failures.delete(failures.keys().next().value);fail(401,'Username or password is incorrect');}failures.delete(fk);}
    const token=randomBytes(32).toString('hex');await pool.query('DELETE FROM crossroads_sessions WHERE expires_at<to_timestamp($1)',[now()/1000]);await pool.query('INSERT INTO crossroads_sessions(token,account,expires_at) VALUES($1,$2,to_timestamp($3))',[digest(token),a.id,now()/1000+43200]);send(res,200,{token,user:publicUser(a)});return true;
   }
   const a=await authenticate(req);if(!a)fail(401,'Session expired. Sign in again. Your local progress is safe.');
   if(req.method==='GET'&&path==='/accounts/me'){send(res,200,{user:publicUser(a)});return true;}
   if(req.method==='GET'&&path==='/accounts/save'){send(res,200,{revision:a.revision,profile:a.save?unseal(a.save):null});return true;}
   if(req.method!=='POST')fail(405,'POST required');const p=await body(req);
   if(path==='/accounts/save'){if(a.role!=='player'&&!a.identity)fail(403,'Complete your private school identification first');const revision=await save(a,p.profile,p.revision);send(res,200,{saved:true,revision});}
   else if(path==='/accounts/identity'){if(a.role==='player')fail(403,'No school role assigned');if(a.identity)fail(409,'School identification is already recorded. Ask the administrator to change your role if it needs correction.');if(typeof p.last!=='string'||!/^\p{L}{1,5}$/u.test(p.last)||typeof p.initial!=='string'||!/^\p{L}$/u.test(p.initial))fail(400,'Enter the first five letters of your last name (all letters if shorter), and your first initial.');await pool.query('UPDATE crossroads_accounts SET identity=$1 WHERE id=$2',[seal({last:p.last.toUpperCase(),initial:p.initial.toUpperCase()}),a.id]);send(res,200,{saved:true});}
   else if(path==='/accounts/logout'){await pool.query('DELETE FROM crossroads_sessions WHERE token=$1',[a.session_token]);send(res,200,{signed_out:true});}
   else if(path==='/accounts/password'){if(!await password(p.current,a.password_hash))fail(401,'Current password is incorrect');const hashed=await password(p.password);await pool.query('UPDATE crossroads_accounts SET password_hash=$1 WHERE id=$2',[hashed,a.id]);await pool.query('DELETE FROM crossroads_sessions WHERE account=$1 AND token<>$2',[a.id,a.session_token]);send(res,200,{saved:true});}
   else fail(404,'Not found');
  }catch(e){send(res,e.status||503,{error:e.status?e.message:'Account service unavailable. Your previous save is safe.'});req.resume();}finally{busy--;}
  return true;
 }
 return {handle,authenticate,initialized,status:()=>({configured:!!pool&&!!encryption,ready}),seal,unseal};
}
