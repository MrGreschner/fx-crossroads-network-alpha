import {migrateSunfieldProfile} from './sunfield-course.mjs';
import {allowedOrigin} from './origins.mjs';
import {repairSchema,exclusions,scrubProfile} from './record-repair.mjs';
import {randomInt,randomBytes,createHash,scrypt as derive,timingSafeEqual,createCipheriv,createDecipheriv} from 'node:crypto';
import {promisify} from 'node:util';
import {checkUsername} from './usernames.mjs';
const scrypt=promisify(derive),digest=x=>createHash('sha256').update(x).digest('hex');
export const RECOVERY_QUESTION="What is the made-up name of your imaginary portal guardian?";
export function recoveryAnswer(value,{username='',password=''}={}){
 if(typeof value!=='string')fail(400,'Enter a made-up recovery answer of 6–64 letters, numbers or spaces. No real information.');
 const answer=value.normalize('NFKC').trim().toLowerCase().replace(/\s+/g,' ');
 if(!/^[a-z0-9 ]{6,64}$/.test(answer)||['password','secret','guardian','123456','abcdef'].includes(answer)||answer===username.toLowerCase()||answer===password.normalize('NFKC').trim().toLowerCase())fail(400,'Invent a recovery answer of 6–64 letters, numbers or spaces, different from your username and password. No real information.');
 return answer;
}
export const accountSchema=`CREATE TABLE IF NOT EXISTS crossroads_accounts(id text PRIMARY KEY,username text NOT NULL,username_key text UNIQUE NOT NULL,password_hash text NOT NULL,role text NOT NULL DEFAULT 'player',identity text,disabled boolean NOT NULL DEFAULT false,revision integer NOT NULL DEFAULT 0,save text,profile text UNIQUE,created_at timestamptz NOT NULL DEFAULT now(),updated_at timestamptz NOT NULL DEFAULT now());
ALTER TABLE crossroads_accounts ADD COLUMN IF NOT EXISTS school_id text;
ALTER TABLE crossroads_accounts ADD COLUMN IF NOT EXISTS username_warning boolean NOT NULL DEFAULT false;
ALTER TABLE crossroads_accounts ADD COLUMN IF NOT EXISTS student_number text;
ALTER TABLE crossroads_accounts ADD COLUMN IF NOT EXISTS recovery_hash text;
ALTER TABLE crossroads_accounts ADD COLUMN IF NOT EXISTS identity_version integer NOT NULL DEFAULT 0;
CREATE UNIQUE INDEX IF NOT EXISTS crossroads_student_number_unique ON crossroads_accounts(student_number) WHERE student_number IS NOT NULL;
-- Remove obsolete surname fragments from live rows, leaving progress and passwords untouched.
UPDATE crossroads_accounts SET identity=NULL,identity_version=2 WHERE identity IS NOT NULL OR identity_version<>2;
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
export function createAccounts({pool,admin=()=>false,key=process.env.CLOUD_SAVE_KEY||'',now=()=>Date.now(),number=()=>randomInt(0,1000000)}={}){
 let encryption;try{const k=Buffer.from(key,'base64');if(k.length===32)encryption=k;}catch{}
 let ready=false,busy=0,hashing=0;const rate=new Map(),failures=new Map();
 let retryAt=0;const initialize=async()=>{try{await pool.query(accountSchema);await pool.query(repairSchema);ready=!!encryption;}catch{ready=false;}retryAt=now()+30000;};const initialized=pool?initialize():Promise.resolve();
 const seal=v=>{const iv=randomBytes(12),c=createCipheriv('aes-256-gcm',encryption,iv);const b=Buffer.concat([c.update(JSON.stringify(v),'utf8'),c.final()]);return Buffer.concat([iv,c.getAuthTag(),b]).toString('base64');};
 const unseal=s=>{const b=Buffer.from(s,'base64'),d=createDecipheriv('aes-256-gcm',encryption,b.subarray(0,12));d.setAuthTag(b.subarray(12,28));return JSON.parse(Buffer.concat([d.update(b.subarray(28)),d.final()]).toString());};
 async function password(value,saved){
  if(typeof value!=='string'||value.length<9||value.length>128)fail(400,'Create a new unique password of 9–128 characters and do not share it.');
  if(hashing>=2)fail(429,'Sign-in busy; please try again shortly.');hashing++;
  try{const salt=saved?saved.split(':')[0]:randomBytes(16).toString('hex'),out=await scrypt(value,salt,64,{N:131072,r:8,p:1,maxmem:192*1024*1024});return saved?timingSafeEqual(out,Buffer.from(saved.split(':')[1],'hex')):salt+':'+out.toString('hex');}finally{hashing--;}
 }
 async function answerHash(value,saved){
  if(hashing>=2)fail(429,'Account verification busy; please retry shortly.');hashing++;
  try{const salt=saved?saved.split(':')[0]:randomBytes(16).toString('hex'),out=await scrypt(value,salt,64,{N:131072,r:8,p:1,maxmem:192*1024*1024});return saved?timingSafeEqual(out,Buffer.from(saved.split(':')[1],'hex')):salt+':'+out.toString('hex');}finally{hashing--;}
 }
 async function authenticate(req){const raw=(req.headers.authorization||'').replace(/^Bearer /,'');if(!/^[a-f0-9]{64}$/.test(raw))return null;const q=await pool.query(`SELECT a.*,s.token session_token FROM crossroads_sessions s JOIN crossroads_accounts a ON a.id=s.account WHERE s.token=$1 AND s.expires_at>to_timestamp($2) AND NOT a.disabled`,[digest(raw),now()/1000]);return q.rows[0]||null;}
 const publicUser=async a=>({id:a.id,username:a.username,role:a.role,school_id:a.school_id??null,username_warning:!!a.username_warning,needs_identity:false,school_code:await assignNumber(a),revision:a.revision,has_save:!!a.save,has_recovery:!!a.recovery_hash});
 async function assignNumber(a){
  if(a.student_number)return a.student_number;
  for(let retry=0;retry<12;retry++){
   const candidate=String(number()).padStart(6,'0');
   if(!/^\d{6}$/.test(candidate))fail(503,'School code service unavailable. Please retry.');
   try{
    const q=await pool.query('UPDATE crossroads_accounts SET student_number=$1 WHERE id=$2 AND student_number IS NULL RETURNING student_number',[candidate,a.id]);
    if(q.rows.length)return q.rows[0].student_number;
    const fresh=(await pool.query('SELECT student_number FROM crossroads_accounts WHERE id=$1',[a.id])).rows[0];
    if(fresh?.student_number)return fresh.student_number;
   }catch(e){if(e.code!=='23505')throw e;}
  }
  fail(503,'Could not generate a unique private game ID. Please retry.');
 }
 async function body(req){let bytes=0;const chunks=[];const timer=setTimeout(()=>req.destroy(),15000);timer.unref();try{for await(const chunk of req){bytes+=chunk.length;if(bytes>4194304)fail(413,'Cloud profile limit is 4 MB. Download a local backup; your previous cloud save is safe.');chunks.push(chunk);}return JSON.parse(Buffer.concat(chunks));}finally{clearTimeout(timer);}}
 function send(res,status,data,extra={}){res.writeHead(status,{'content-type':'application/json','cache-control':'no-store','x-content-type-options':'nosniff',...extra});res.end(JSON.stringify(data));}
 async function save(a,v,revision){
  v=migrateSunfieldProfile(scrubProfile(v,await exclusions(pool,a.id)));validateCloudSave(v);if(!Number.isInteger(revision)||revision<0)fail(400,'Invalid save revision.');
  // One conditional UPDATE owns the revision. A history row is written with it in one SQL statement.
  const q=await pool.query(`WITH changed AS (UPDATE crossroads_accounts SET save=$1,revision=revision+1,updated_at=now() WHERE id=$2 AND revision=$3 RETURNING id,revision,save) INSERT INTO crossroads_save_history(account,revision,save) SELECT id,revision,save FROM changed RETURNING revision`,[seal(v),a.id,revision]);
  if(!q.rows.length)fail(409,'A newer cloud save exists. Saving paused. Download this device profile, then load the cloud save.');
  await pool.query(`DELETE FROM crossroads_save_history WHERE account=$1 AND revision NOT IN(SELECT revision FROM crossroads_save_history WHERE account=$1 ORDER BY revision DESC LIMIT 10)`,[a.id]);
  return q.rows[0].revision;
 }
 async function handle(req,res){const url=new URL(req.url,'http://localhost'),path=url.pathname;if(!path.startsWith('/accounts/')&&path!=='/accounts')return false;
  const isAdmin=path==='/accounts'||path.startsWith('/accounts/admin')||path==='/accounts/control.js';
  if(isAdmin){if(!admin(req)){send(res,401,{error:'Private account controls'},{'WWW-Authenticate':'Basic realm="Crossroads administration"'});req.resume();return true;}if(req.method==='POST'&&req.headers.origin&&new URL(req.headers.origin).host!==req.headers.host){send(res,403,{error:'Origin rejected'});req.resume();return true;}}
  else{const origin=req.headers.origin||'';if(!allowedOrigin(req)){send(res,403,{error:'Origin rejected'});req.resume();return true;}if(origin){res.setHeader('access-control-allow-origin',origin);res.setHeader('vary','Origin');}if(req.method==='OPTIONS'){send(res,204,{}, {'access-control-allow-methods':'GET,POST','access-control-allow-headers':'content-type,authorization'});return true;}}
  // Temporary reduced release: the browser account console is not shipped.
  if(['/accounts','/accounts/control.js','/accounts/admin/recovery','/accounts/admin/password'].includes(path)){send(res,503,{error:'Browser account controls and administrator password recovery are temporarily unavailable in this profile-core release. Player login and cloud saves remain available.'});req.resume();return true;}
  if(!ready&&pool&&encryption&&now()>retryAt)await initialize();if(!ready){send(res,503,{error:isAdmin?'Cloud accounts unavailable. Set CLOUD_SAVE_KEY (32 random bytes, base64) and DATABASE_URL, then redeploy.':'Cloud accounts are temporarily unavailable. You can keep playing on this device and download a profile backup. Please try again later.'});req.resume();return true;}
  const ip=req.socket.remoteAddress||'unknown';let rr=rate.get(ip);if(!rr||now()-rr.at>60000)rr={at:now(),auth:0,other:0};rate.set(ip,rr);if(rate.size>4096)rate.delete(rate.keys().next().value);
  const authRoute=['/accounts/register','/accounts/login'].includes(path);if((authRoute?++rr.auth>80:++rr.other>1200)||busy>=8){send(res,429,{error:'Please retry shortly.'});req.resume();return true;}
  busy++;
  try{
   if(isAdmin){
    if(path==='/accounts/admin/list'&&req.method==='GET'){
     const raw=(url.searchParams.get('search')||'').slice(0,20),search=raw.toLowerCase().replace(/[^a-z0-9_]/g,'');
     const code=/^\d{6}$/.test(raw)?raw:'';
     const q=await pool.query(`SELECT id,username,role,identity,identity_version,student_number,disabled,revision,created_at,updated_at FROM crossroads_accounts WHERE ($2='' AND position($1 in username_key)>0) OR ($2<>'' AND student_number=$2) ORDER BY username_key LIMIT 100`,[search,code]);
     const rows=[];for(const a of q.rows){const {identity,identity_version,student_number,...safe}=a;rows.push({...safe,school_code:await assignNumber(a)});}send(res,200,{accounts:rows});return true;
    }
    if(req.method!=='POST')fail(405,'POST required');const p=await body(req);if(!/^[a-f0-9]{32}$/.test(p.id||''))fail(400,'Invalid account');const a=(await pool.query('SELECT * FROM crossroads_accounts WHERE id=$1',[p.id])).rows[0];if(!a)fail(404,'Account not found');
    let action='';
    if(path==='/accounts/admin/role'){if(!['player','student','teacher'].includes(p.role))fail(400,'Invalid role');await pool.query('UPDATE crossroads_accounts SET role=$1,identity=NULL,identity_version=2 WHERE id=$2',[p.role,p.id]);action='role:'+p.role;}
    else if(path==='/accounts/admin/disable'){await pool.query('UPDATE crossroads_accounts SET disabled=$1 WHERE id=$2',[!!p.disabled,p.id]);await pool.query('DELETE FROM crossroads_sessions WHERE account=$1',[p.id]);action=p.disabled?'disabled':'enabled';}
    else if(path==='/accounts/admin/history'){const rows=await pool.query('SELECT revision,created_at FROM crossroads_save_history WHERE account=$1 ORDER BY revision DESC LIMIT 10',[p.id]);send(res,200,{history:rows.rows});return true;}
    else if(path==='/accounts/admin/restore'){const old=(await pool.query('SELECT save FROM crossroads_save_history WHERE account=$1 AND revision=$2',[p.id,p.revision])).rows[0];if(!old)fail(404,'Save revision not found');const revision=await save(a,unseal(old.save),a.revision);await pool.query('DELETE FROM crossroads_sessions WHERE account=$1',[p.id]);action='restore:'+p.revision;}
    else fail(404,'Not found');await pool.query('INSERT INTO crossroads_account_audit(account,action) VALUES($1,$2)',[p.id,action]);send(res,200,{saved:true});return true;
   }
   if(authRoute){if(req.method!=='POST')fail(405,'POST required');const p=await body(req);let a;
    if(path.endsWith('/register')){const name=checkUsername(p.username),hashed=await password(p.password),id=randomBytes(16).toString('hex'),recovery=await answerHash(recoveryAnswer(p.answer,{username:name.username,password:p.password}));try{a=(await pool.query('INSERT INTO crossroads_accounts(id,username,username_key,password_hash,recovery_hash) VALUES($1,$2,$3,$4,$5) RETURNING *',[id,name.username,name.key,hashed,recovery])).rows[0];}catch(e){if(e.code==='23505')fail(409,'That username is already taken. Choose another.');throw e;}}
    else{if(typeof p.username!=='string'||p.username.length>20)fail(401,'Username or password is incorrect');const fk=digest(p.username.toLowerCase()),attempt=failures.get(fk)||{at:now(),count:0};if(now()-attempt.at>900000){attempt.at=now();attempt.count=0;}if(attempt.count>=12)fail(429,'Too many attempts for this username. Try again in 15 minutes.');a=(await pool.query('SELECT * FROM crossroads_accounts WHERE username_key=$1',[p.username.toLowerCase()])).rows[0];const dummy='01234567890123456789012345678901:'+('00'.repeat(64));const good=await password(p.password,a?.password_hash||dummy);if(!a||!good||a.disabled){attempt.count++;failures.set(fk,attempt);if(failures.size>8192)failures.delete(failures.keys().next().value);fail(401,'Username or password is incorrect');}failures.delete(fk);}
    const token=randomBytes(32).toString('hex');await pool.query('DELETE FROM crossroads_sessions WHERE expires_at<to_timestamp($1)',[now()/1000]);await pool.query('INSERT INTO crossroads_sessions(token,account,expires_at) VALUES($1,$2,to_timestamp($3))',[digest(token),a.id,now()/1000+43200]);send(res,200,{token,user:await publicUser(a)});return true;
   }
   const a=await authenticate(req);if(!a)fail(401,'Session expired. Sign in again. Your local progress is safe.');
   if(req.method==='GET'&&path==='/accounts/me'){send(res,200,{user:await publicUser(a)});return true;}
   if(req.method==='GET'&&path==='/accounts/save'){send(res,200,{revision:a.revision,profile:a.save?migrateSunfieldProfile(unseal(a.save)):null});return true;}
   if(req.method!=='POST')fail(405,'POST required');const p=await body(req);
   if(path==='/accounts/save'){const revision=await save(a,p.profile,p.revision);send(res,200,{saved:true,revision});}
   else if(path==='/accounts/username'){
    const name=checkUsername(p.username);if(name.key===a.username_key)fail(400,'Please choose a different username.');
    try{await pool.query('UPDATE crossroads_accounts SET username=$1,username_key=$2,username_warning=false,updated_at=now() WHERE id=$3',[name.username,name.key,a.id]);}catch(e){if(e.code==='23505')fail(409,'That username is already taken. Choose another.');throw e;}
    await pool.query('INSERT INTO crossroads_account_audit(account,action) VALUES($1,$2)',[a.id,'username-updated']);a.username=name.username;a.username_warning=false;send(res,200,{user:await publicUser(a)});
   }
   else if(path==='/accounts/identity')fail(410,'Personal identification is no longer collected. Reload the updated game to see your automatic game ID.');
   else if(path==='/accounts/logout'){await pool.query('DELETE FROM crossroads_sessions WHERE token=$1',[a.session_token]);send(res,200,{signed_out:true});}
   else if(path==='/accounts/recovery'){if(!await password(p.current,a.password_hash))fail(401,'Current password is incorrect');const hashed=await answerHash(recoveryAnswer(p.answer,{username:a.username,password:p.current}));await pool.query('UPDATE crossroads_accounts SET recovery_hash=$1 WHERE id=$2',[hashed,a.id]);send(res,200,{saved:true});}
   else if(path==='/accounts/password'){if(!await password(p.current,a.password_hash))fail(401,'Current password is incorrect');const hashed=await password(p.password);await pool.query('UPDATE crossroads_accounts SET password_hash=$1 WHERE id=$2',[hashed,a.id]);await pool.query('DELETE FROM crossroads_sessions WHERE account=$1 AND token<>$2',[a.id,a.session_token]);send(res,200,{saved:true});}
   else fail(404,'Not found');
  }catch(e){send(res,e.status||503,{error:e.status?e.message:'Account service unavailable. Your previous save is safe.'});req.resume();}finally{busy--;}
  return true;
 }
 return {handle,authenticate,ensureNumber:assignNumber,initialized,status:()=>({configured:!!pool&&!!encryption,ready}),seal,unseal};
}
