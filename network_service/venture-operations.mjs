import {readFileSync} from 'node:fs';
const read=n=>JSON.parse(readFileSync(new URL('../content/'+n,import.meta.url)));
const districtData=read('business-district.json');export const premises=districtData.ventures;
const catalog=read('business-operations.json'),ids=new Set([...premises,...(districtData.legacy_ventures||[])].map(p=>p.id)),trades=new Set(premises.filter(p=>!p.blank).map(p=>p.id));
const obj=v=>v!==null&&typeof v==='object'&&!Array.isArray(v),num=(v,lo=0,hi=1e8)=>typeof v==='number'&&Number.isFinite(v)&&v>=lo&&v<=hi,int=(v,lo=0,hi=1e6)=>Number.isInteger(v)&&num(v,lo,hi);
export function ventureAccess(v){return Array.isArray(v)&&v.length<=17&&new Set(v).size===v.length&&v.every(x=>ids.has(x));}
export const defaultVentureAccess=['kitchen'];
export function schoolNameError(value){if(typeof value!=='string'||value.trim().length<3||value.trim().length>32||!/[\p{L}\p{N}]/u.test(value)||!/^[\p{L}\p{N} '&.-]+$/u.test(value))return true;const s=value.trim().toLowerCase().replace(/[013457]/g,x=>({'0':'o','1':'i','3':'e','4':'a','5':'s','7':'t'}[x])).replace(/[ .&'-]/g,'');return ['fuck','shit','bitch','cunt','nigger','faggot','porn','dickhead','asshole'].some(w=>s.includes(w));}
function lots(store,definitions){return obj(store)&&Object.keys(store).length<=80&&Object.entries(store).every(([key,list])=>Object.hasOwn(definitions,key)&&Array.isArray(list)&&list.length<=24&&list.every(l=>obj(l)&&int(l.qty,1,10000)&&num(l.cost)&&int(l.age,0,1000000)&&num(l.quality,.1,2)));}
function profile(p){return obj(p)&&int(p.id,0,1e6)&&typeof p.name==='string'&&p.name.length<=80&&typeof p.species==='string'&&typeof p.coat==='string'&&p.coat.length<=8&&typeof p.skin==='string'&&p.skin.length<=8&&num(p.wage,0,200)&&num(p.service,0,3)&&num(p.logistics,0,3)&&num(p.reliability,0,1)&&obj(p.skills)&&Object.keys(p.skills).length>=9&&Object.keys(p.skills).length<=14&&Object.entries(p.skills).every(([k,v])=>trades.has(k)&&num(v,0,3))&&Array.isArray(p.experience)&&p.experience.length<=4&&p.experience.every(j=>obj(j)&&typeof j.job==='string'&&j.job.length<=150&&int(j.years,0,40)&&int(j.ago,0,50)&&trades.has(j.domain))&&typeof p.bio==='string'&&p.bio.length<=300&&typeof p.reference==='string'&&p.reference.length<=300;}
export function validOperationsState(s){
 if(!Object.values(s.businesses).some(b=>b.operations===2)&&s.pool_epoch===undefined)return true;
 if(!int(s.seed)||!int(s.pool_epoch,0,9999)||typeof s.started!=='boolean'||!int(s.restart_count,0,1000000)||!Array.isArray(s.archives)||s.archives.length>5||!obj(s.people_profiles)||Object.keys(s.people_profiles).length>150||!Array.isArray(s.applicants)||s.applicants.length!==30)return false;
 if(!Object.entries(s.people_profiles).every(([id,p])=>id===String(p.id)&&profile(p))||!s.applicants.every(p=>profile(p)&&JSON.stringify(p)===JSON.stringify(s.people_profiles[String(p.id)]))||new Set(s.applicants.map(p=>p.id)).size!==30)return false;
 for(const b of Object.values(s.businesses)){
  if(b.operations!==2||!trades.has(b.trade)||schoolNameError(b.name)||!obj(b.menu)||Object.keys(b.menu).length>20||!obj(b.assets)||Object.keys(b.assets).length>40||!Array.isArray(b.orders)||b.orders.length>40||!lots(b.materials,catalog.materials)||!lots(b.finished,catalog.products)||typeof b.failed!=='boolean'||!int(b.arrears)||typeof b.production_key!=='string'||b.production_key&&!Object.hasOwn(catalog.products,b.production_key)||!obj(b.observations)||Object.keys(b.observations).length>80||!Object.entries(b.observations).every(([k,v])=>Object.hasOwn(catalog.products,k)&&int(v)))return false;
  if(!Object.entries(b.menu).every(([k,v])=>catalog.products[k]?.trade===b.trade&&obj(v)&&typeof v.enabled==='boolean'&&num(v.price,1,catalog.products[k].price*3)&&int(v.target,1,40)))return false;
  if(!Object.entries(b.assets).every(([k,v])=>Object.hasOwn(catalog.equipment,k)&&obj(v)&&num(v.condition,.1,1)&&num(v.paid)&&int(v.count,1,12)))return false;
  if(!b.orders.every(o=>obj(o)&&Object.hasOwn(catalog.materials,o.material)&&int(o.qty,1,1000)&&num(o.cost)&&num(o.due,0,1000000)&&num(o.quality,.1,2)&&typeof o.supplier==='string'&&o.supplier.length<30))return false;
  if(!num(b.pending_expenses)||!int(b.visitors)||!obj(b.summary)||!Array.isArray(b.rentals)||b.rentals.length>100||!b.rentals.every(h=>obj(h)&&catalog.products[h.product]?.trade==='rental'&&Object.hasOwn(catalog.equipment,h.fleet)&&num(h.remaining,0,60)))return false;
  if(b.services!==undefined&&(!Array.isArray(b.services)||b.services.length>80||!b.services.every(j=>obj(j)&&int(j.id,1)&&catalog.products[j.product]?.service_duration>0&&num(j.remaining,0,200)&&num(j.duration,.1,200)&&Array.isArray(j.slots)&&j.slots.length>0&&j.slots.length<=2&&j.slots.every(x=>int(x,0,100))&&num(j.cost)&&num(j.price)&&num(j.wait)&&num(j.quality,.1,2))))return false;
  for(const e of b.employees)if(e.id>=100&&!Object.hasOwn(s.people_profiles,String(e.id)))return false;
  const qty=store=>Object.values(store).flat().reduce((n,l)=>n+l.qty,0),book=store=>Object.values(store).flat().reduce((n,l)=>n+l.cost,0);
  if(b.inputs!==qty(b.materials)||b.stock!==qty(b.finished)||Math.abs(b.input_book-book(b.materials))>.02||Math.abs(b.stock_book-book(b.finished))>.02)return false;
 }
 return true;
}
// Teacher gates govern the local educational simulation; financial results remain
// explicitly unverified evidence and never confer public game rewards/records.
export function enforceVentureAccess(previous,next,access){
 if(!next)return true;const prior=previous?.businesses||{};
 for(const [id,b]of Object.entries(next.businesses||{})){
  if(access.includes(id))continue;
  if(!prior[id])return false;
  if(b.open||['cash','day','revenue','served','loan'].some(k=>b[k]!==prior[id][k]))return false;
 }
 return true;
}
