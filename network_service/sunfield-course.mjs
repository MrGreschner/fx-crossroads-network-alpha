// New Sunfield course: only its speed records are reset. No progression/currency erasure.
export const SUNFIELD_REVISION=257;
const timing=new Set(['time','time_solo','time_coop']);
export const currentSunfieldRow=r=>!(r.key==='sunfield'&&timing.has(r.kind))||r.extra?.layout_revision===SUNFIELD_REVISION;
export function eligibleSunfield(raw,kind,key){
 if(key!=='sunfield'||!timing.has(kind))return true;
 const routes=raw.named?.routes;
 if(kind==='time_solo')return routes?.solo?.sunfield_revision===SUNFIELD_REVISION;
 if(kind==='time_coop')return routes?.coop?.sunfield_revision===SUNFIELD_REVISION;
 return routes?.solo?.sunfield_revision===SUNFIELD_REVISION&&routes?.coop?.sunfield_revision===SUNFIELD_REVISION;
}
export function migrateSunfieldProfile(value){
 if(!value||typeof value!=='object')return value;
 const p=structuredClone(value),n=p.progress?.named_records;
 if(n?.routes?.solo?.sunfield_revision===SUNFIELD_REVISION&&n?.routes?.coop?.sunfield_revision===SUNFIELD_REVISION)return p;
 if(n){
  for(const field of ['times_all','times_week'])if(n[field])delete n[field].sunfield;
  for(const key of Object.keys(n.hero_records||{}))if(/^time(?:_solo|_coop)?:[^:]+:sunfield$/.test(key))delete n.hero_records[key];
  for(const route of ['solo','coop'])if(n.routes?.[route]){
   delete n.routes[route].all?.sunfield;delete n.routes[route].week?.sunfield;n.routes[route].sunfield_revision=SUNFIELD_REVISION;
  }
 }
 const records=p.saves?.['crossroads_profile.json']?.records;
 if(records)for(const key of Object.keys(records))if(key.split(':').includes('sunfield'))delete records[key];
 if(p.saves?.['fx_coop_sunfield.json']){p.saves['fx_coop_sunfield.json'].best=0;p.saves['fx_coop_sunfield.json'].layout_revision=SUNFIELD_REVISION;}
 return p;
}
export const sunfieldSchema=`CREATE TABLE IF NOT EXISTS crossroads_course_revisions(realm text PRIMARY KEY,revision integer NOT NULL);
CREATE TABLE IF NOT EXISTS crossroads_course_record_archive(revision integer NOT NULL,account text NOT NULL,scope text NOT NULL,kind text NOT NULL,key text NOT NULL,value double precision NOT NULL,extra jsonb NOT NULL,archived_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(revision,account,scope,kind,key));
CREATE TABLE IF NOT EXISTS crossroads_course_exclusion_archive(revision integer NOT NULL,account text NOT NULL,scope text NOT NULL,kind text NOT NULL,key text NOT NULL,value double precision NOT NULL,repair text NOT NULL,archived_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(revision,account,scope,kind,key,value));`;
export async function ensureSunfieldCourse(pool){
 await pool.query(sunfieldSchema);
 const db=pool.connect?await pool.connect():pool;
 try{
  await db.query('BEGIN');
  await db.query('INSERT INTO crossroads_course_revisions(realm,revision) VALUES($1,0) ON CONFLICT DO NOTHING',['sunfield']);
  const row=(await db.query('SELECT revision FROM crossroads_course_revisions WHERE realm=$1 FOR UPDATE',['sunfield'])).rows[0];
  if(Number(row?.revision||0)<SUNFIELD_REVISION){
   const args=['sunfield',[...timing]];
   await db.query('INSERT INTO crossroads_course_record_archive(revision,account,scope,kind,key,value,extra) SELECT $3,account,scope,kind,key,value,extra FROM crossroads_named_records WHERE key=$1 AND kind=ANY($2::text[]) ON CONFLICT DO NOTHING',[...args,SUNFIELD_REVISION]);
   await db.query('DELETE FROM crossroads_named_records WHERE key=$1 AND kind=ANY($2::text[])',args);
   await db.query('INSERT INTO crossroads_course_exclusion_archive(revision,account,scope,kind,key,value,repair) SELECT $3,account,scope,kind,key,value,repair FROM crossroads_record_exclusions WHERE key=$1 AND kind=ANY($2::text[]) ON CONFLICT DO NOTHING',[...args,SUNFIELD_REVISION]);
   await db.query('DELETE FROM crossroads_record_exclusions WHERE key=$1 AND kind=ANY($2::text[])',args);
   await db.query('UPDATE crossroads_course_revisions SET revision=$2 WHERE realm=$1',['sunfield',SUNFIELD_REVISION]);
  }
  await db.query('COMMIT');
 }catch(e){await db.query('ROLLBACK');throw e;}finally{if(db!==pool)db.release();}
}
