import {combatEligible} from './record-policy.mjs';
export const extractionSchema=`CREATE TABLE IF NOT EXISTS crossroads_extraction_events(account text NOT NULL REFERENCES crossroads_accounts(id),run_id text NOT NULL,route text NOT NULL CHECK(route IN ('solo','coop')),amount integer NOT NULL CHECK(amount>0 AND amount<=1000000),hero text NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(account,run_id));`;
// Deliberately separate event IDs from best-run maxima. ON CONFLICT makes retries,
// restored saves and simultaneous uploads count once per account and expedition.
export function cleanExtractions(raw,heroes){
 const events=raw.extractions??[];
 if(!Array.isArray(events)||events.length>32)throw Error('Invalid extraction list');
 if(events.length&&!combatEligible(raw))throw Error('Unofficial extraction');
 const ids=new Set();
 for(const e of events){
  if(!e||typeof e!=='object'||Array.isArray(e)||Object.keys(e).some(k=>!['id','amount','route','hero','party'].includes(k))||typeof e.id!=='string'||!/^([a-f0-9]{64})$/.test(e.id)||ids.has(e.id)||!['solo','coop'].includes(e.route)||!Number.isSafeInteger(e.amount)||e.amount<1||e.amount>1e6||!heroes.has(e.hero))throw Error('Invalid extraction event');
  if(e.route==='coop'&&(!Array.isArray(e.party)||e.party.length<2||e.party.length>8||e.party.some(m=>!m||!heroes.has(m.hero))))throw Error('Invalid extraction party');
  ids.add(e.id);
 }
 return events;
}
export async function submitExtractions(db,account,events){
 if(!events.length)return;
 // Immutable values also prevent a replay from silently replacing its original haul.
 const old=(await db.query('SELECT run_id,route,amount,hero FROM crossroads_extraction_events WHERE account=$1 AND run_id=ANY($2::text[])',[account,events.map(e=>e.id)])).rows;
 for(const e of events){const prior=old.find(r=>r.run_id===e.id);if(prior&&(prior.route!==e.route||Number(prior.amount)!==e.amount||prior.hero!==e.hero))throw Error('Invalid conflicting extraction replay');}
 await db.query(`INSERT INTO crossroads_extraction_events(account,run_id,route,amount,hero) SELECT $1,x.id,x.route,x.amount,x.hero FROM jsonb_to_recordset($2::jsonb) AS x(id text,route text,amount integer,hero text) ON CONFLICT(account,run_id) DO NOTHING`,[account,JSON.stringify(events)]);
}
export async function extractionLeaders(db){
 return (await db.query(`SELECT a.username,SUM(e.amount)::double precision AS value,COUNT(*)::integer AS runs,SUM(CASE WHEN e.route='solo' THEN e.amount ELSE 0 END)::double precision AS solo,SUM(CASE WHEN e.route='coop' THEN e.amount ELSE 0 END)::double precision AS coop FROM crossroads_extraction_events e JOIN crossroads_accounts a ON a.id=e.account WHERE NOT a.disabled GROUP BY a.id,a.username,a.username_key ORDER BY value DESC,a.username_key LIMIT 10`)).rows.map(r=>({...r,value:Number(r.value),runs:Number(r.runs),solo:Number(r.solo),coop:Number(r.coop)}));
}
