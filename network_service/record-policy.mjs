import {readFileSync} from 'node:fs';
const official=JSON.parse(readFileSync(new URL('../content/manifest.json',import.meta.url))).characters;
export const RECORD_POLICY=2;
export const combatEligible=raw=>raw?.record_policy===RECORD_POLICY&&raw.unofficial===false;
export async function eligibleHeroes(pool){
 const ids=new Set(official);
 if(pool){
  // An arbitrary client balance flag or community-looking ID is never approval.
  const exists=await pool.query("SELECT to_regclass('crossroads_hero_submissions') present");
  if(exists.rows[0]?.present){const q=await pool.query("SELECT h.id FROM crossroads_hero_submissions h JOIN crossroads_accounts a ON a.id=h.account WHERE h.state='approved' AND NOT a.disabled");for(const r of q.rows)ids.add('community_'+r.id.replaceAll('-',''));}
 }
 return ids;
}
export function eligibleRecord(raw,kind,scope,key,value,heroes){
 if(!combatEligible(raw))return false;
 const r=raw.named?.hero_records?.[`${kind}:${scope}:${key}`];
 if(!r||r.value!==value||!heroes.has(r.hero))return false;
 const coop=kind==='time_coop'||['between','descent'].includes(kind)&&key==='coop';
 if(coop&&(!Array.isArray(r.party)||r.party.length<2))return false;
 return !r.party||r.party.every(m=>heroes.has(m.hero));
}
