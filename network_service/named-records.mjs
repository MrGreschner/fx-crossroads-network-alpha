import {readFileSync} from 'node:fs';
import {rankWeek} from './cosmetic-rankings.mjs';
const relics=JSON.parse(readFileSync(new URL('../content/relic_records.json',import.meta.url)));
const manifest=JSON.parse(readFileSync(new URL('../content/manifest.json',import.meta.url))),realms=new Set(manifest.regions);
export const namedSchema=`CREATE TABLE IF NOT EXISTS crossroads_named_records(account text NOT NULL REFERENCES crossroads_accounts(id),scope text NOT NULL,kind text NOT NULL,key text NOT NULL,value double precision NOT NULL,extra jsonb NOT NULL DEFAULT '{}',PRIMARY KEY(account,scope,kind,key));
CREATE TABLE IF NOT EXISTS crossroads_named_damage(account text PRIMARY KEY REFERENCES crossroads_accounts(id),buckets jsonb NOT NULL);`;
const num=(v,max)=>typeof v==='number'&&Number.isFinite(v)&&v>=0&&v<=max;
export async function submitNamed(pool,a,p,raw,now=Date.now()){
 const entries=[];const add=(scope,kind,key,value,extra={})=>entries.push({scope,kind,key,value,extra});
 const lifetime=raw.named?.lifetime??Math.min(1e12,p.totals.filter(x=>x.kind==='hero').reduce((s,x)=>s+x.value,0));if(!num(lifetime,1e12))throw Error('Invalid lifetime damage');add('all','damage','total',lifetime);
 for(const f of p.fish)add(f.scope,'fish','largest',f.kg,{species:f.species,kg:f.kg});
 for(const f of p.rarest){const score=f.grade*1e8+(1-Math.min(1,f.baseweight))*1e6;add(f.scope,'fish','rarest',score,{species:f.species,kg:f.kg});}
 for(const c of p.crops)add(c.scope,'garden',c.crop,c.kg,{crop:c.crop,kg:c.kg});
 for(const v of p.totals.filter(x=>x.kind==='between'))add('all','between',v.key,v.value);
 const n=raw.named||{},week=rankWeek(now).week;
 if(n.buckets!==undefined){if(!Array.isArray(n.buckets)||n.buckets.length>10082)throw Error('Invalid rolling damage');let prev=-1;for(const b of n.buckets){if(!Array.isArray(b)||b.length!==2||!Number.isSafeInteger(b[0])||b[0]<=prev||!num(b[1],1e12)||b[0]*60>now/1000+60)throw Error('Invalid rolling bucket');prev=b[0];}await pool.query(`INSERT INTO crossroads_named_damage(account,buckets) VALUES($1,$2::jsonb) ON CONFLICT(account) DO UPDATE SET buckets=(SELECT COALESCE(jsonb_agg(jsonb_build_array(bucket_minute,damage) ORDER BY bucket_minute),'[]') FROM (SELECT (v->>0)::bigint AS bucket_minute,max((v->>1)::float8) damage FROM jsonb_array_elements(crossroads_named_damage.buckets || EXCLUDED.buckets) v WHERE (v->>0)::bigint*60>$3-604800 GROUP BY 1) m)`,[a.id,JSON.stringify(n.buckets.filter(b=>b[0]*60>now/1000-604800)),now/1000]);}
 for(const scope of ['all',week]){
  const records=n.times?.[scope]||{};if(typeof records!=='object'||Array.isArray(records)||Object.keys(records).length>128)throw Error('Invalid realm times');
  for(const [realm,v]of Object.entries(records)){if(!realms.has(realm)||!num(v,86400)||v<1)throw Error('Invalid realm time');add(scope,'time',realm,v);}
  const streak=n.streak?.[scope]||0;if(!Number.isSafeInteger(streak)||!num(streak,1e6))throw Error('Invalid life streak');add(scope,'streak','realms',streak);
 }
 const relic=n.relic;
 if(relic){if(typeof relic.type!=='string'||!Object.hasOwn(relics,relic.type)||!num(relic.percentile,1)||!Number.isInteger(relic.tier)||relic.tier<1||relic.tier>3||typeof relic.conclave!=='boolean')throw Error('Invalid relic record');add('all','relic','rarest',(relic.conclave?10:0)+relic.tier+relic.percentile, {type:relic.type,tier:relic.tier,percentile:relic.percentile,conclave:relic.conclave});}
 const unique=new Map();for(const e of entries){const k=e.scope+':'+e.kind+':'+e.key,old=unique.get(k);if(!old||(e.kind==='time'?e.value<old.value:e.value>old.value))unique.set(k,e);}
 if(unique.size)await pool.query(`INSERT INTO crossroads_named_records(account,scope,kind,key,value,extra) SELECT $1,x.scope,x.kind,x.key,x.value,x.extra FROM jsonb_to_recordset($2::jsonb) AS x(scope text,kind text,key text,value float8,extra jsonb) ON CONFLICT(account,scope,kind,key) DO UPDATE SET value=EXCLUDED.value,extra=EXCLUDED.extra WHERE CASE WHEN EXCLUDED.kind='time' THEN EXCLUDED.value<crossroads_named_records.value ELSE EXCLUDED.value>crossroads_named_records.value END`,[a.id,JSON.stringify([...unique.values()])]);
}
export async function namedSnapshot(pool,now=Date.now()){
 const week=rankWeek(now).week;
 const rows=(await pool.query(`SELECT r.*,a.username FROM crossroads_named_records r JOIN crossroads_accounts a ON a.id=r.account WHERE NOT a.disabled AND r.value>0 ORDER BY r.value DESC,a.username_key`)).rows;
 const select=(kind,scope,key,limit=5,asc=false)=>rows.filter(r=>r.kind===kind&&r.scope===scope&&(!key||r.key===key)).sort((a,b)=>(asc?a.value-b.value:b.value-a.value)||a.username.localeCompare(b.username)).slice(0,limit).map(({username,key,value,extra})=>({username,key,value:Number(value),...extra}));
 const damage=(await pool.query(`SELECT a.username,d.buckets FROM crossroads_named_damage d JOIN crossroads_accounts a ON a.id=d.account WHERE NOT a.disabled`)).rows.map(r=>({username:r.username,value:r.buckets.filter(b=>b[0]*60>now/1000-604800&&b[0]*60<=now/1000).reduce((s,b)=>s+b[1],0)})).filter(r=>r.value>0).sort((a,b)=>b.value-a.value||a.username.localeCompare(b.username)).slice(0,5);
 return {damage_all:select('damage','all','total'),damage_rolling:damage,streak_all:select('streak','all','realms'),streak_week:select('streak',week,'realms'),realm_times_all:[...realms].flatMap(id=>select('time','all',id,1,true)),realm_times_week:[...realms].flatMap(id=>select('time',week,id,1,true)),between_solo:select('between','all','solo'),between_coop:select('between','all','coop'),fish_all:select('fish','all','largest',1)[0]||null,fish_week:select('fish',week,'largest',1)[0]||null,rarest_all:select('fish','all','rarest',1)[0]||null,rarest_week:select('fish',week,'rarest',1)[0]||null,relic:select('relic','all','rarest',1)[0]||null,garden:rows.filter(r=>r.kind==='garden').map(({username,scope,key,value})=>({username,scope,crop:key,kg:Number(value)})).sort((a,b)=>b.kg-a.kg).filter((v,i,a)=>a.findIndex(x=>x.crop===v.crop&&x.scope===v.scope)===i).slice(0,48)};
}
