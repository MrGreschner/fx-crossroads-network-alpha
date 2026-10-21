import {readFileSync} from 'node:fs';
const fish=JSON.parse(readFileSync(new URL('../content/fishing.json',import.meta.url))).fish;
const grades=['Common','Uncommon','Rare','Very rare','Legendary','Mystical'];
export const FISH_BOARD_KEYS=['fish_all','fish_week','rarest_all','rarest_week'];
export const FISH_BOARD_LIMIT=5;
export function fishOrder(a,b,rarest=false){
 if(rarest){const x=fish[a.species],y=fish[b.species];return grades.indexOf(y.rarity)-grades.indexOf(x.rarity)||Number(x.chance??1)-Number(y.chance??1)||a.species.localeCompare(b.species)||b.kg-a.kg||(a.username||'').localeCompare(b.username||'');}
 return b.kg-a.kg||(a.username||'').localeCompare(b.username||'')||a.species.localeCompare(b.species);
}
function entries(value){return Array.isArray(value)?value:value?[value]:[];}
function clean(row){
 if(!row||!Object.hasOwn(fish,row.species)||typeof row.kg!=='number'||!Number.isFinite(row.kg)||row.kg<=0||row.kg>Math.min(10000,fish[row.species].max_kg*4+.01))return null;
 return {species:row.species,kg:row.kg,...(typeof row.username==='string'&&row.username?{username:row.username}:{})};
}
export function fishBoards(community={},named={}){
 return Object.fromEntries(FISH_BOARD_KEYS.map(key=>{
  const identified=entries(named.fish_boards?.[key]??named[key]).map(clean).filter(Boolean);
  const signatures=new Set(identified.map(r=>r.species+':'+r.kg));
  const anonymous=entries(community.fish_boards?.[key]??community[key]).map(clean).filter(r=>r&&!signatures.has(r.species+':'+r.kg));
  const sorted=[...identified,...anonymous].sort((a,b)=>fishOrder(a,b,key.startsWith('rarest'))),seen=new Set();
  const rows=sorted.filter(r=>{if(!r.username)return true;const id=r.username.toLowerCase();if(seen.has(id))return false;seen.add(id);return true;}).slice(0,FISH_BOARD_LIMIT);
  return [key,rows];
 }));
}
