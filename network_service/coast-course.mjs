// New Coast course: only its speed records are reset. No progression/currency erasure.
export const COAST_REVISION=266;
const timing=new Set(['time','time_solo','time_coop']);
export const currentCoastRow=r=>!(r.key==='folded_coast'&&timing.has(r.kind))||r.extra?.layout_revision===COAST_REVISION;
export function eligibleCoast(raw,kind,key){
 if(key!=='folded_coast'||!timing.has(kind))return true;
 const routes=raw.named?.routes;
 if(kind==='time_solo')return routes?.solo?.folded_coast_revision===COAST_REVISION;
 if(kind==='time_coop')return routes?.coop?.folded_coast_revision===COAST_REVISION;
 return routes?.solo?.folded_coast_revision===COAST_REVISION&&routes?.coop?.folded_coast_revision===COAST_REVISION;
}
export function migrateCoastProfile(value){
 if(!value||typeof value!=='object')return value;
 const p=structuredClone(value),n=p.progress?.named_records;
 if(n?.routes?.solo?.folded_coast_revision===COAST_REVISION&&n?.routes?.coop?.folded_coast_revision===COAST_REVISION)return p;
 if(n){
  for(const field of ['times_all','times_week'])if(n[field])delete n[field].folded_coast;
  for(const key of Object.keys(n.hero_records||{}))if(/^time(?:_solo|_coop)?:[^:]+:folded_coast$/.test(key))delete n.hero_records[key];
  for(const route of ['solo','coop'])if(n.routes?.[route]){
   delete n.routes[route].all?.folded_coast;delete n.routes[route].week?.folded_coast;n.routes[route].folded_coast_revision=COAST_REVISION;
  }
 }
 const records=p.saves?.['crossroads_profile.json']?.records;
 if(records)for(const key of Object.keys(records))if(key.split(':').includes('folded_coast'))delete records[key];
 if(p.saves?.['fx_coop_folded_coast.json']){p.saves['fx_coop_folded_coast.json'].best=0;p.saves['fx_coop_folded_coast.json'].layout_revision=COAST_REVISION;}
 return p;
}
export const folded_coastSchema=`CREATE TABLE IF NOT EXISTS crossroads_course_revisions(realm text PRIMARY KEY,revision integer NOT NULL);
CREATE TABLE IF NOT EXISTS crossroads_course_record_archive(revision integer NOT NULL,account text NOT NULL,scope text NOT NULL,kind text NOT NULL,key text NOT NULL,value double precision NOT NULL,extra jsonb NOT NULL,archived_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(revision,account,scope,kind,key));
CREATE TABLE IF NOT EXISTS crossroads_course_exclusion_archive(revision integer NOT NULL,account text NOT NULL,scope text NOT NULL,kind text NOT NULL,key text NOT NULL,value double precision NOT NULL,repair text NOT NULL,archived_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(revision,account,scope,kind,key,value));`;
export async function ensureCoastCourse(pool){
 await pool.query(folded_coastSchema);
 const db=pool.connect?await pool.connect():pool;
 try{
  await db.query('BEGIN');
  await db.query('INSERT INTO crossroads_course_revisions(realm,revision) VALUES($1,0) ON CONFLICT DO NOTHING',['folded_coast']);
  const row=(await db.query('SELECT revision FROM crossroads_course_revisions WHERE realm=$1 FOR UPDATE',['folded_coast'])).rows[0];
  if(Number(row?.revision||0)<COAST_REVISION){
   const args=['folded_coast',[...timing]];
   await db.query('INSERT INTO crossroads_course_record_archive(revision,account,scope,kind,key,value,extra) SELECT $3,account,scope,kind,key,value,extra FROM crossroads_named_records WHERE key=$1 AND kind=ANY($2::text[]) ON CONFLICT DO NOTHING',[...args,COAST_REVISION]);
   await db.query('DELETE FROM crossroads_named_records WHERE key=$1 AND kind=ANY($2::text[])',args);
   await db.query('INSERT INTO crossroads_course_exclusion_archive(revision,account,scope,kind,key,value,repair) SELECT $3,account,scope,kind,key,value,repair FROM crossroads_record_exclusions WHERE key=$1 AND kind=ANY($2::text[]) ON CONFLICT DO NOTHING',[...args,COAST_REVISION]);
   await db.query('DELETE FROM crossroads_record_exclusions WHERE key=$1 AND kind=ANY($2::text[])',args);
   await db.query('UPDATE crossroads_course_revisions SET revision=$2 WHERE realm=$1',['folded_coast',COAST_REVISION]);
  }
  await db.query('COMMIT');
 }catch(e){await db.query('ROLLBACK');throw e;}finally{if(db!==pool)db.release();}
}
