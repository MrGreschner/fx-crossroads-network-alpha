import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {rankWeek} from './cosmetic-rankings.mjs';
import {fishOrder,FISH_BOARD_KEYS} from './fish-leaderboards.mjs';
const fish=JSON.parse(readFileSync(new URL('../content/fishing.json',import.meta.url))).fish;
const grades=['Common','Uncommon','Rare','Very rare','Legendary','Mystical','Fabled'];
export const catchSchema=`CREATE TABLE IF NOT EXISTS crossroads_fish_catches(owner text NOT NULL,catch_id text NOT NULL,profile text NOT NULL,account text,species text NOT NULL,kg float8 NOT NULL,caught_at float8,week text,grade integer NOT NULL,chance float8 NOT NULL,PRIMARY KEY(owner,catch_id));CREATE INDEX IF NOT EXISTS crossroads_catch_weight ON crossroads_fish_catches(kg DESC);CREATE INDEX IF NOT EXISTS crossroads_catch_rarity ON crossroads_fish_catches(grade DESC,chance);CREATE INDEX IF NOT EXISTS crossroads_catch_week ON crossroads_fish_catches(week);CREATE INDEX IF NOT EXISTS crossroads_catch_week_weight ON crossroads_fish_catches(week,kg DESC);CREATE INDEX IF NOT EXISTS crossroads_catch_week_rarity ON crossroads_fish_catches(week,grade DESC,chance);`;
export function cleanCatches(raw,now=Date.now()){
 const rows=raw.catch_records??[];if(!Array.isArray(rows)||rows.length>300)throw Error('Invalid catch records');const seen=new Set();
 return rows.map(c=>{const f=fish[c?.species];if(!f||typeof c.id!=='string'||!c.id.length||c.id.length>100||seen.has(c.id)||typeof c.kg!=='number'||!Number.isFinite(c.kg)||c.kg<=0||c.kg>Math.min(10000,f.max_kg*4+.01))throw Error('Invalid catch record');seen.add(c.id);const at=c.caught_at===undefined||c.caught_at===null?null:c.caught_at;if(at!==null&&(typeof at!=='number'||!Number.isFinite(at)||at<0||at>now/1000+300))throw Error('Invalid catch time');return {id:c.id,species:c.species,kg:c.kg,caught_at:at,week:at===null?null:rankWeek(at*1000).week,grade:grades.indexOf(f.rarity),chance:f.chance??1};});
}
export async function submitCatches(pool,profile,account,rows){
 if(!pool||!rows.length)return;const owner=account||profile;
 if(account)await pool.query('DELETE FROM crossroads_fish_catches WHERE owner=$1 AND account IS NULL',[profile]);
 await pool.query(`INSERT INTO crossroads_fish_catches(owner,catch_id,profile,account,species,kg,caught_at,week,grade,chance) SELECT $1,x.id,$2,$3,x.species,x.kg,x.caught_at,x.week,x.grade,x.chance FROM jsonb_to_recordset($4::jsonb) AS x(id text,species text,kg float8,caught_at float8,week text,grade integer,chance float8) ON CONFLICT(owner,catch_id) DO UPDATE SET kg=EXCLUDED.kg WHERE crossroads_fish_catches.catch_id LIKE 'legacy:%' AND EXCLUDED.kg>crossroads_fish_catches.kg`,[owner,profile,account,JSON.stringify(rows)]);
}
export async function catchBoards(pool,week,named=true){
 if(!pool)return {};const boards={};
 for(const key of FISH_BOARD_KEYS){
  const weekly=key.endsWith('week'),rare=key.startsWith('rarest');
  const sql=`SELECT f.*,${named?'a.username':'NULL::text username'} FROM crossroads_fish_catches f ${named?'LEFT JOIN crossroads_accounts a ON a.id=f.account':''} WHERE ${named?'(f.account IS NULL OR (a.id IS NOT NULL AND NOT a.disabled))':'true'} ${weekly?'AND f.week=$1':''} ORDER BY ${rare?'f.grade DESC,f.chance,f.species,f.kg DESC':'f.kg DESC'},f.owner,f.catch_id LIMIT 10`;
  const rows=(await pool.query(sql,weekly?[week]:[])).rows;
  boards[key]=rows.map(c=>({species:c.species,kg:Number(c.kg),...(c.username?{username:c.username}:{}),catch_id:createHash('sha256').update(c.owner+':'+c.catch_id).digest('hex')}));
 }
 return boards;
}
