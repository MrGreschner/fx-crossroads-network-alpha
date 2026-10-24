import {readFileSync} from 'node:fs';
const data=n=>JSON.parse(readFileSync(new URL('../content/'+n,import.meta.url)));const district=data('business-district.json'),ops=data('business-operations.json'),defaults=data('business-reset-defaults.json');
const spec=id=>[...district.ventures,...(district.legacy_ventures||[])].find(v=>v.id===id);
export const restartSchema=`CREATE TABLE IF NOT EXISTS crossroads_business_restarts(id text PRIMARY KEY,student text NOT NULL,teacher text NOT NULL,attempt text NOT NULL,business text NOT NULL,snapshot jsonb NOT NULL,requested_revision integer NOT NULL,status text NOT NULL DEFAULT 'pending',reason text NOT NULL DEFAULT '',created_at timestamptz NOT NULL DEFAULT now(),reviewed_at timestamptz);CREATE UNIQUE INDEX IF NOT EXISTS crossroads_one_pending_restart ON crossroads_business_restarts(student,teacher,business) WHERE status='pending';`;
export function resetBusiness(id,old){
 const venue=spec(id),model=spec(old.trade);if(!venue||!model)throw Error('Unknown business');const b=structuredClone(defaults);b.name=old.name;b.price=venue.price;b.trade=old.trade;b.acquisition=old.acquisition;b.cash=venue.blank?2200:1200;b.opening_cash=b.cash;b.menu={};b.assets={};b.materials={};b.finished={};b.reset_epoch=(old.reset_epoch||0)+1;
 if(!venue.blank){for(const key of model.base_equipment)b.assets[key]={condition:1,paid:ops.equipment[key].cost,count:1};for(const key of model.starter_products){b.menu[key]={enabled:true,price:ops.products[key].price,target:8};for(const [m,amount]of Object.entries(ops.products[key].materials)){const qty=amount*5,cost=ops.materials[m].cost*qty;if(!b.materials[m])b.materials[m]=[{qty:0,cost:0,age:0,quality:1}];b.materials[m][0].qty+=qty;b.materials[m][0].cost+=cost;}}}
 b.inputs=Object.values(b.materials).flat().reduce((s,l)=>s+l.qty,0);b.input_book=Object.values(b.materials).flat().reduce((s,l)=>s+l.cost,0);b.stock=0;b.stock_book=0;return b;
}
export function guardResets(before,after){
 if(!before)return;if(!after||Number(before.restart_count||0)!==Number(after.restart_count||0))throw Object.assign(Error('Classroom restarts require teacher approval.'),{status:403});
 for(const [id,b]of Object.entries(before.businesses||{})){
 const next=after.businesses?.[id];if(next&&((next.reset_epoch||0)!==(b.reset_epoch||0)||next.day<b.day||(next.summary?.full_days||0)<(b.summary?.full_days||0)))throw Object.assign(Error('Ask your teacher to approve restarting this business.'),{status:403});
 }
}
