import {randomUUID,createHash} from 'node:crypto';
import {readFile} from 'node:fs/promises';
export const repairSchema=`CREATE TABLE IF NOT EXISTS crossroads_record_repairs(id text PRIMARY KEY,account text NOT NULL REFERENCES crossroads_accounts(id),snapshot jsonb NOT NULL,reason text NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),restored boolean NOT NULL DEFAULT false);
CREATE TABLE IF NOT EXISTS crossroads_record_exclusions(account text NOT NULL,scope text NOT NULL,kind text NOT NULL,key text NOT NULL,value double precision NOT NULL,repair text NOT NULL REFERENCES crossroads_record_repairs(id),PRIMARY KEY(account,scope,kind,key,value));`;
const supported=new Set(['time','time_solo','time_coop','between','descent']);
const digest=x=>createHash('sha256').update(JSON.stringify(x)).digest('hex');
const equal=(a,b)=>typeof a==='number'&&Math.abs(a-Number(b))<1e-8;
const remove=(o,k,v)=>{if(o&&equal(o[k],v))delete o[k];};
export function scrubProfile(value,exclusions){
 if(!value||!exclusions.length)return value;
 const p=structuredClone(value),n=p.progress?.named_records;
 for(const e of exclusions){
  const v=Number(e.value),route=e.kind==='time_solo'?'solo':e.kind==='time_coop'?'coop':null;
  if(n){
   const key=`${e.kind}:${e.scope}:${e.key}`;
   if(equal(n.hero_records?.[key]?.value,v))delete n.hero_records[key];
   if(e.kind==='time')remove(n[e.scope==='all'?'times_all':'times_week'],e.key,v);
   if(route){const r=n.routes?.[route];if(e.scope==='all'||r?.week_id===e.scope)remove(r?.[e.scope==='all'?'all':'week'],e.key,v);}
   if(e.kind==='descent'&&equal(n.descent?.[e.key],v))n.descent[e.key]=0;
  }
  if(e.kind==='between'&&equal(p.progress?.community_records?.[e.key],v))p.progress.community_records[e.key]=0;
  if(e.kind==='descent'){
   if(equal(p.progress?.card?.descent_best,v))p.progress.card.descent_best=0;
   if(e.key==='coop'&&equal(p.progress?.tasks?.coop_descent,v))p.progress.tasks.coop_descent=0;
   if(equal(p.saves?.['fx_descent_best.json']?.best,v))p.saves['fx_descent_best.json'].best=0;
  }
  if(e.kind.startsWith('time')){
   const records=p.saves?.['crossroads_profile.json']?.records||{};
   for(const k of Object.keys(records))if(k.split(':').includes(e.key)&&k.split(':').at(-1).startsWith('custom_')&&equal(records[k],Math.floor(v)))delete records[k];
   if(e.kind==='time_coop'&&equal(p.saves?.[`fx_coop_${e.key}.json`]?.best,Math.floor(v)))p.saves[`fx_coop_${e.key}.json`].best=0;
  }
 }
 return p;
}
export async function exclusions(pool,account){return (await pool.query('SELECT scope,kind,key,value FROM crossroads_record_exclusions WHERE account=$1',[account])).rows;}
export async function scrubUpload(pool,account,raw){
 const list=await exclusions(pool,account);if(!list.length)return raw;
 const r=structuredClone(raw),n=r.named||{};
 for(const e of list){
  const v=Number(e.value),rk=`${e.kind}:${e.scope}:${e.key}`;
  if(equal(n.hero_records?.[rk]?.value,v))delete n.hero_records[rk];
  if(e.kind==='time')remove(n.times?.[e.scope],e.key,v);
  if(e.kind==='time_solo'||e.kind==='time_coop'){const a=n.routes?.[e.kind.slice(5)];if(e.scope==='all'||a?.week_id===e.scope)remove(a?.[e.scope==='all'?'all':'week'],e.key,v);}
  if(e.kind==='descent'&&equal(n.descent?.[e.key],v))n.descent[e.key]=0;
  if(e.kind==='between'&&equal(r.between?.[e.key],v))r.between[e.key]=0;
 }
 return r;
}
export function createRecordRepair({pool,accounts,admin=()=>false,invalidate=()=>{}}){
 let ready=false;const initialized=(async()=>{if(!pool)return;await accounts.initialized;await pool.query(repairSchema);ready=true;})();
 const send=(res,status,data)=>{res.writeHead(status,{'content-type':'application/json','cache-control':'no-store','x-content-type-options':'nosniff'});res.end(JSON.stringify(data));};
 const fail=(status,message)=>{throw Object.assign(Error(message),{status});};
 async function body(req){let n=0,chunks=[];for await(const c of req){n+=c.length;if(n>32768)fail(413,'Request too large');chunks.push(c);}return JSON.parse(Buffer.concat(chunks));}
 async function snapshot(db,id){const a=(await db.query('SELECT id,username,revision,save FROM crossroads_accounts WHERE id=$1',[id])).rows[0];if(!a)fail(404,'Account not found');const rows=(await db.query('SELECT scope,kind,key,value,extra FROM crossroads_named_records WHERE account=$1 ORDER BY scope,kind,key',[id])).rows;return {account:a,rows};}
 async function handle(req,res){const u=new URL(req.url,'http://localhost');if(!u.pathname.startsWith('/records/admin'))return false;
  if(!admin(req)){res.setHeader('WWW-Authenticate','Basic realm="Crossroads private accounts"');send(res,401,{error:'Administrator sign-in required'});req.resume();return true;}
  try{
   if(req.method==='POST'&&req.headers.origin&&new URL(req.headers.origin).host!==req.headers.host)fail(403,'Origin rejected');
   if(u.pathname==='/records/admin'&&req.method==='GET'){res.writeHead(200,{'content-type':'text/html; charset=utf-8','cache-control':'no-store','content-security-policy':"default-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self'; frame-ancestors 'none'"});res.end(await readFile(new URL('./record-repair.html',import.meta.url)));return true;}
   if(u.pathname==='/records/admin/ui.js'&&req.method==='GET'){res.writeHead(200,{'content-type':'text/javascript; charset=utf-8','cache-control':'no-store'});res.end(await readFile(new URL('./record-repair-ui.js',import.meta.url)));return true;}
   if(!ready)fail(503,'Record repair is unavailable; deploy the complete server update first.');
   if(u.pathname==='/records/admin/preview'&&req.method==='GET'){
    const name=(u.searchParams.get('username')||'').toLowerCase();if(!/^[a-z0-9_]{1,20}$/.test(name))fail(400,'Enter the exact username');
    const a=(await pool.query('SELECT id FROM crossroads_accounts WHERE username_key=$1',[name])).rows[0];if(!a)fail(404,'User not found');
    const s=await snapshot(pool,a.id),profile=s.account.save?accounts.unseal(s.account.save):null;
    const history=(await pool.query('SELECT revision,created_at FROM crossroads_save_history WHERE account=$1 ORDER BY revision DESC LIMIT 10',[a.id])).rows;
    const repairs=(await pool.query('SELECT id,reason,created_at,restored FROM crossroads_record_repairs WHERE account=$1 ORDER BY created_at DESC',[a.id])).rows;
    send(res,200,{id:a.id,username:s.account.username,revision:s.account.revision,token:digest(s),rows:s.rows.map(r=>({...r,supported:supported.has(r.kind),provenance:r.extra?.hero?'Recorded hero: '+r.extra.hero:'Unknown hero — requires review, not proof of cheating'})),personal:profile?.progress?.named_records||null,local_records:profile?.saves?.['crossroads_profile.json']?.records||{},history,repairs});return true;
   }
   if(req.method!=='POST')fail(405,'POST required');const p=await body(req);if(!/^[a-f0-9]{32}$/.test(p.id||''))fail(400,'Invalid account');
   const db=await pool.connect();try{await db.query('BEGIN');await db.query('SELECT id FROM crossroads_accounts WHERE id=$1 FOR UPDATE',[p.id]);
    if(u.pathname==='/records/admin/repair'){
     const s=await snapshot(db,p.id);if(p.token!==digest(s))fail(409,'Data changed. Preview again before repairing.');
     if(!Array.isArray(p.rows)||!p.rows.length||p.rows.length>100||typeof p.reason!=='string'||p.reason.length<10||p.reason.length>500)fail(400,'Select exact records and explain the evidence for correction.');
     const selected=[];for(const item of p.rows){const row=s.rows.find(r=>r.scope===item.scope&&r.kind===item.kind&&r.key===item.key&&Number(r.value)===item.value);if(!row||!supported.has(row.kind))fail(400,'Unsupported or changed record. Totals require a separate evidence-based review.');if(!selected.some(r=>r.scope===row.scope&&r.kind===row.kind&&r.key===row.key))selected.push(row);}
     const id=randomUUID();const save=s.account.save?accounts.unseal(s.account.save):null;const patched=scrubProfile(save,selected);
     // A recoverable encrypted snapshot is stored before any record changes.
     const snapshotData={account:s.account,rows:selected,after_revision:s.account.revision+(save?1:0)};
     await db.query('INSERT INTO crossroads_record_repairs(id,account,snapshot,reason) VALUES($1,$2,$3::jsonb,$4)',[id,p.id,JSON.stringify(snapshotData),p.reason]);
     for(const row of selected){await db.query('INSERT INTO crossroads_record_exclusions(account,scope,kind,key,value,repair) VALUES($1,$2,$3,$4,$5,$6) ON CONFLICT DO NOTHING',[p.id,row.scope,row.kind,row.key,row.value,id]);await db.query('DELETE FROM crossroads_named_records WHERE account=$1 AND scope=$2 AND kind=$3 AND key=$4 AND value=$5',[p.id,row.scope,row.kind,row.key,row.value]);}
     if(save){await db.query('UPDATE crossroads_accounts SET save=$1,revision=revision+1,updated_at=now() WHERE id=$2',[accounts.seal(patched),p.id]);await db.query('INSERT INTO crossroads_save_history(account,revision,save) SELECT id,revision,save FROM crossroads_accounts WHERE id=$1',[p.id]);}
     await db.query('INSERT INTO crossroads_account_audit(account,action) VALUES($1,$2)',[p.id,'record-repair:'+id]);await db.query('COMMIT');invalidate();send(res,200,{saved:true,repair:id,removed:selected.length,reload_cloud:!!save});return true;
    }
    if(u.pathname==='/records/admin/restore'){
     const r=(await db.query('SELECT * FROM crossroads_record_repairs WHERE id=$1 AND account=$2 AND NOT restored',[p.repair,p.id])).rows[0];if(!r)fail(404,'Active repair not found');
     const current=(await db.query('SELECT revision FROM crossroads_accounts WHERE id=$1',[p.id])).rows[0];if(current.revision!==r.snapshot.after_revision)fail(409,'New progress exists. Restoration needs a reviewed merge to preserve it.');
     for(const row of r.snapshot.rows){const live=await db.query('SELECT value FROM crossroads_named_records WHERE account=$1 AND scope=$2 AND kind=$3 AND key=$4',[p.id,row.scope,row.kind,row.key]);if(live.rows.length)fail(409,'A new record exists. Restoration needs a reviewed merge to preserve it.');}
     for(const row of r.snapshot.rows)await db.query('INSERT INTO crossroads_named_records(account,scope,kind,key,value,extra) VALUES($1,$2,$3,$4,$5,$6::jsonb) ON CONFLICT(account,scope,kind,key) DO UPDATE SET value=EXCLUDED.value,extra=EXCLUDED.extra',[p.id,row.scope,row.kind,row.key,row.value,JSON.stringify(row.extra)]);
     if(r.snapshot.account.save){await db.query('UPDATE crossroads_accounts SET save=$1,revision=revision+1,updated_at=now() WHERE id=$2',[r.snapshot.account.save,p.id]);await db.query('INSERT INTO crossroads_save_history(account,revision,save) SELECT id,revision,save FROM crossroads_accounts WHERE id=$1',[p.id]);}
     await db.query('DELETE FROM crossroads_record_exclusions WHERE repair=$1',[p.repair]);await db.query('UPDATE crossroads_record_repairs SET restored=true WHERE id=$1',[p.repair]);await db.query('INSERT INTO crossroads_account_audit(account,action) VALUES($1,$2)',[p.id,'record-repair-restored:'+p.repair]);await db.query('COMMIT');invalidate();send(res,200,{restored:true});return true;
    }
    fail(404,'Unknown repair action');
   }catch(e){await db.query('ROLLBACK');throw e;}finally{db.release();}
  }catch(e){send(res,e.status||503,{error:e.status?e.message:'Record repair unavailable. No successful repair has been reported.'});req.resume();}return true;
 }
 return {handle,initialized};
}
