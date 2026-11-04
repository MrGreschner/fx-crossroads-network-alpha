// One boss-era leaderboard reset. Historical results are archived, progress retained.
export const DESCENT_REVISION=292;
export const currentDescentRow=r=>r.kind!=='descent'||r.extra?.course_revision===DESCENT_REVISION;
export const eligibleDescent=(raw,kind)=>kind!=='descent'||raw.named?.descent?.revision===DESCENT_REVISION;
export function migrateDescentProfile(value){
 if(!value||typeof value!=='object')return value;
 const p=structuredClone(value),n=p.progress?.named_records;
 if(n&&n.descent?.revision!==DESCENT_REVISION){
  n.descent={solo:0,coop:0,week:{solo:0,coop:0},week_id:String(n.week||''),revision:DESCENT_REVISION};
  for(const key of Object.keys(n.hero_records||{}))if(key.startsWith('descent:'))delete n.hero_records[key];
 }
 return p;
}
export async function ensureDescentCourse(pool){
 // Course archive tables have already been installed by ensureMarshCourse.
 await pool.query('CREATE TABLE IF NOT EXISTS crossroads_cosmetic_extra_all(profile text PRIMARY KEY,descent integer NOT NULL DEFAULT 0,glimmers double precision NOT NULL DEFAULT 0)');
 const db=pool.connect?await pool.connect():pool;
 try{
  await db.query('BEGIN');
  await db.query('INSERT INTO crossroads_course_revisions(realm,revision) VALUES($1,0) ON CONFLICT DO NOTHING',['cave_descent']);
  const row=(await db.query('SELECT revision FROM crossroads_course_revisions WHERE realm=$1 FOR UPDATE',['cave_descent'])).rows[0];
  if(Number(row?.revision||0)<DESCENT_REVISION){
   await db.query('CREATE TABLE IF NOT EXISTS crossroads_descent_rank_archive(revision integer NOT NULL,profile text NOT NULL,depth integer NOT NULL,PRIMARY KEY(revision,profile))');
   if((await db.query("SELECT to_regclass('crossroads_cosmetic_extra_all') present")).rows[0]?.present){
    await db.query('INSERT INTO crossroads_descent_rank_archive(revision,profile,depth) SELECT $1,profile,descent FROM crossroads_cosmetic_extra_all WHERE descent>0 ON CONFLICT DO NOTHING',[DESCENT_REVISION]);
    await db.query('UPDATE crossroads_cosmetic_extra_all SET descent=0 WHERE descent>0');
   }
   await db.query("INSERT INTO crossroads_course_record_archive(revision,account,scope,kind,key,value,extra) SELECT $1,account,scope,kind,key,value,extra FROM crossroads_named_records WHERE kind='descent' ON CONFLICT DO NOTHING",[DESCENT_REVISION]);
   await db.query("DELETE FROM crossroads_named_records WHERE kind='descent'");
   await db.query("INSERT INTO crossroads_course_exclusion_archive(revision,account,scope,kind,key,value,repair) SELECT $1,account,scope,kind,key,value,repair FROM crossroads_record_exclusions WHERE kind='descent' ON CONFLICT DO NOTHING",[DESCENT_REVISION]);
   await db.query("DELETE FROM crossroads_record_exclusions WHERE kind='descent'");
   await db.query('UPDATE crossroads_course_revisions SET revision=$2 WHERE realm=$1',['cave_descent',DESCENT_REVISION]);
  }
  await db.query('COMMIT');
 }catch(e){await db.query('ROLLBACK');throw e;}finally{if(db!==pool)db.release();}
}
