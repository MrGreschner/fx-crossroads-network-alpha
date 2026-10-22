import {readFileSync} from 'node:fs';
const fish=JSON.parse(readFileSync(new URL('../content/fishing.json',import.meta.url))).fish;
const grades=['Common','Uncommon','Rare','Very rare','Legendary','Mystical',"Fabled"];
function rarer(a,b){if(!a||!fish[a.species])return false;if(!b||!fish[b.species])return true;const fa=fish[a.species],fb=fish[b.species];return grades.indexOf(fa.rarity)>grades.indexOf(fb.rarity)||(fa.rarity===fb.rarity&&(fa.chance<fb.chance||(a.species===b.species&&a.kg>b.kg)));}
export function brokenRecords(claims,before,after,username){
 const messages=[];
 for(const c of Array.isArray(claims)?claims.slice(0,12):[]){
  if(c?.kind==='fish'&&fish[c.species]&&Number.isFinite(c.kg)&&c.kg>0){
   const best=after.named?.fish_all;const prior=Math.max(before.fish_all?.kg||0,before.named?.fish_all?.kg||0);
   if(best?.username===username&&best.species===c.species&&Math.abs(best.kg-c.kg)<.001&&c.kg>prior)messages.push('NEW COMMUNITY RECORD • Largest fish • '+fish[c.species].name+' • '+c.kg.toFixed(2)+' kg');
   const trophy=after.named?.species_trophies?.find(r=>r.species===c.species);const old=before.named?.species_trophies?.find(r=>r.species===c.species);
   if(trophy?.username===username&&Math.abs(trophy.kg-c.kg)<.001&&c.kg>(old?.kg||0))messages.push('NEW COMMUNITY SPECIES RECORD • '+fish[c.species].name+' • '+c.kg.toFixed(2)+' kg');
   if(after.named?.rarest_all?.username===username&&after.named.rarest_all.species===c.species&&rarer(c,before.rarest_all)&&rarer(c,before.named?.rarest_all))messages.push('NEW COMMUNITY RECORD • Rarest fish • '+fish[c.species].name);
  }
  if(c?.kind==='time'&&['solo','coop'].includes(c.route)&&typeof c.realm==='string'&&Number.isFinite(c.seconds)&&c.seconds>=1){
   const old=before.named?.route_times?.[c.route]?.all?.find(r=>r.key===c.realm);const best=after.named?.route_times?.[c.route]?.all?.find(r=>r.key===c.realm);
   if(best?.username===username&&Math.abs(best.value-c.seconds)<.001&&c.seconds<(old?.value||86401))messages.push('NEW COMMUNITY RECORD • '+c.route.toUpperCase()+' • '+c.realm.replaceAll('_',' ')+' • '+c.seconds.toFixed(2)+'s');
  }
 }
 return [...new Set(messages)].slice(0,4);
}
