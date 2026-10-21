import {readFileSync} from 'node:fs';
import {rankWeek} from './cosmetic-rankings.mjs';
const relics=JSON.parse(readFileSync(new URL('../content/relic_records.json',import.meta.url)));
const fish=JSON.parse(readFileSync(new URL('../content/fishing.json',import.meta.url))).fish;
const grades=['Common','Uncommon','Rare','Very rare','Legendary','Mystical'];
const rareOrder=(a,b)=>{const fa=fish[a.extra.species],fb=fish[b.extra.species];return grades.indexOf(fb.rarity)-grades.indexOf(fa.rarity)||fa.chance-fb.chance||a.extra.species.localeCompare(b.extra.species)||Number(b.extra.kg)-Number(a.extra.kg)||a.username.localeCompare(b.username);};
const manifest=JSON.parse(readFileSync(new URL('../content/manifest.json',import.meta.url))),realms=new Set(manifest.regions),heroes=new Set(manifest.characters);
export const namedSchema=`CREATE TABLE IF NOT EXISTS crossroads_named_records(account text NOT NULL REFERENCES crossroads_accounts(id),scope text NOT NULL,kind text NOT NULL,key text NOT NULL,value double precision NOT NULL,extra jsonb NOT NULL DEFAULT '{}',PRIMARY KEY(account,scope,kind,key));
CREATE TABLE IF NOT EXISTS crossroads_named_damage(account text PRIMARY KEY REFERENCES crossroads_accounts(id),buckets jsonb NOT NULL);
CREATE INDEX IF NOT EXISTS crossroads_named_fish_lookup ON crossroads_named_records(scope,key) WHERE kind='fish';`;
const num=(v,max)=>typeof v==='number'&&Number.isFinite(v)&&v>=0&&v<=max;
export async function submitNamed(pool,a,p,raw,now=Date.now()){
 const entries=[];const heroRecords=raw.named?.hero_records??{};
 if(!heroRecords||typeof heroRecords!=='object'||Array.isArray(heroRecords)||Object.keys(heroRecords).length>1024)throw Error('Invalid record heroes');
 for(const [key,r] of Object.entries(heroRecords)){if(!/^(time(?:_solo|_coop)?|between):(all|[0-9]{4}-[0-9]{2}-[0-9]{2}):[a-z0-9_-]{1,64}$/.test(key)||!r||typeof r!=='object'||Array.isArray(r)||Object.keys(r).length!==2||!heroes.has(r.hero)||!num(r.value,1e6))throw Error('Invalid record hero');}
 const add=(scope,kind,key,value,extra={})=>{const hero=heroRecords[kind+':'+scope+':'+key];entries.push({scope,kind,key,value,extra:hero&&hero.value===value?{...extra,hero:hero.hero}:extra});};
 const lifetime=raw.named?.lifetime??Math.min(1e12,p.totals.filter(x=>x.kind==='hero').reduce((s,x)=>s+x.value,0));if(!num(lifetime,1e12))throw Error('Invalid lifetime damage');add('all','damage','total',lifetime);
 for(const f of p.trophies||[])add('all','trophy',f.species,f.kg,{species:f.species,kg:f.kg});
 for(const f of p.fish)add(f.scope,'fish','largest',f.kg,{species:f.species,kg:f.kg});
 for(const f of p.rarest){const score=f.grade*1e8+(1-Math.min(1,f.baseweight))*1e6;add(f.scope,'fish','rarest',score,{species:f.species,kg:f.kg});}
 for(const c of p.crops)add(c.scope,'garden',c.crop,c.kg,{crop:c.crop,kg:c.kg});
 for(const v of p.totals.filter(x=>x.kind==='between'))add('all','between',v.key,v.value);
 const n=raw.named||{},week=rankWeek(now).week;
 if(n.buckets!==undefined){if(!Array.isArray(n.buckets)||n.buckets.length>10082)throw Error('Invalid rolling damage');let prev=-1;for(const b of n.buckets){if(!Array.isArray(b)||b.length!==2||!Number.isSafeInteger(b[0])||b[0]<=prev||!num(b[1],1e12)||b[0]*60>now/1000+60)throw Error('Invalid rolling bucket');prev=b[0];}await pool.query(`INSERT INTO crossroads_named_damage(account,buckets) VALUES($1,$2::jsonb) ON CONFLICT(account) DO UPDATE SET buckets=(SELECT COALESCE(jsonb_agg(jsonb_build_array(bucket_minute,damage) ORDER BY bucket_minute),'[]') FROM (SELECT (v->>0)::bigint AS bucket_minute,max((v->>1)::float8) damage FROM jsonb_array_elements(crossroads_named_damage.buckets || EXCLUDED.buckets) v WHERE (v->>0)::bigint*60>$3::double precision-604800 GROUP BY 1) m)`,[a.id,JSON.stringify(n.buckets.filter(b=>b[0]*60>now/1000-604800)),now/1000]);}
 for(const scope of ['all',week]){
  const records=n.times?.[scope]||{};if(typeof records!=='object'||Array.isArray(records)||Object.keys(records).length>128)throw Error('Invalid realm times');
  for(const [realm,v]of Object.entries(records)){if(!realms.has(realm)||!num(v,86400)||v<1)throw Error('Invalid realm time');add(scope,'time',realm,v);}
  const streak=n.streak?.[scope]||0;if(!Number.isSafeInteger(streak)||!num(streak,1e6))throw Error('Invalid life streak');add(scope,'streak','realms',streak);
 }
 for(const route of ['solo','coop']){
  const r=n.routes?.[route];if(!r)continue;
  for(const scope of ['all',week]){const values=scope==='all'?r.all:(r.week_id===week?r.week:{});
   if(!values||typeof values!=='object'||Array.isArray(values)||Object.keys(values).length>128)throw Error('Invalid route times');
   for(const [realm,v] of Object.entries(values)){if(!realms.has(realm)||!num(v,86400)||v<1)throw Error('Invalid route time');add(scope,'time_'+route,realm,v);}
  }
 }
 const relic=n.relic;
 if(relic){if(typeof relic.type!=='string'||!Object.hasOwn(relics,relic.type)||!num(relic.percentile,1)||!Number.isInteger(relic.tier)||relic.tier<1||relic.tier>3||typeof relic.conclave!=='boolean')throw Error('Invalid relic record');add('all','relic','rarest',(relic.conclave?10:0)+relic.tier+relic.percentile, {type:relic.type,tier:relic.tier,percentile:relic.percentile,conclave:relic.conclave});}
 const unique=new Map();for(const e of entries){const k=e.scope+':'+e.kind+':'+e.key,old=unique.get(k);if(!old||(e.kind.startsWith('time')?e.value<old.value:(e.value>old.value||(e.kind==='fish'&&e.key==='rarest'&&e.value===old.value&&(e.extra.species<old.extra.species||(e.extra.species===old.extra.species&&e.extra.kg>old.extra.kg))))))unique.set(k,e);}
 if(unique.size)await pool.query(`INSERT INTO crossroads_named_records(account,scope,kind,key,value,extra) SELECT $1,x.scope,x.kind,x.key,x.value,x.extra FROM jsonb_to_recordset($2::jsonb) AS x(scope text,kind text,key text,value float8,extra jsonb) ON CONFLICT(account,scope,kind,key) DO UPDATE SET value=EXCLUDED.value,extra=EXCLUDED.extra WHERE (EXCLUDED.value=crossroads_named_records.value AND EXCLUDED.extra ? 'hero' AND NOT (crossroads_named_records.extra ? 'hero')) OR CASE WHEN EXCLUDED.kind LIKE 'time%' THEN EXCLUDED.value<crossroads_named_records.value ELSE EXCLUDED.value>crossroads_named_records.value OR (EXCLUDED.kind='fish' AND EXCLUDED.key='rarest' AND EXCLUDED.value=crossroads_named_records.value AND ((EXCLUDED.extra->>'species')<(crossroads_named_records.extra->>'species') OR ((EXCLUDED.extra->>'species')=(crossroads_named_records.extra->>'species') AND (EXCLUDED.extra->>'kg')::float8>(crossroads_named_records.extra->>'kg')::float8))) END`,[a.id,JSON.stringify([...unique.values()])]);
}
export async function namedSnapshot(pool,now=Date.now()){
 const week=rankWeek(now).week;
 const rows=(await pool.query(`SELECT r.*,a.username FROM crossroads_named_records r JOIN crossroads_accounts a ON a.id=r.account WHERE NOT a.disabled AND r.value>0 ORDER BY r.value DESC,a.username_key`)).rows;
 const select=(kind,scope,key,limit=5,asc=false)=>rows.filter(r=>r.kind===kind&&r.scope===scope&&(!key||r.key===key)).sort((a,b)=>(asc?a.value-b.value:b.value-a.value)||a.username.localeCompare(b.username)).slice(0,limit).map(({username,key,value,extra})=>({username,key,value:Number(value),...extra}));
 const rareList=scope=>rows.filter(r=>r.kind==='fish'&&r.key==='rarest'&&r.scope===scope&&fish[r.extra.species]).sort(rareOrder).slice(0,5).map(r=>({username:r.username,key:r.key,value:Number(r.value),...r.extra}));
 const rare=scope=>rareList(scope)[0]||null;
 const largestList=scope=>select('fish',scope,'largest',rows.length).filter(r=>fish[r.species]&&Number.isFinite(r.kg)&&r.kg>0).slice(0,5);
 const buckets=(await pool.query(`SELECT a.username,d.buckets FROM crossroads_named_damage d JOIN crossroads_accounts a ON a.id=d.account WHERE NOT a.disabled`)).rows;
 const damageSince=(cutoff,inclusive=false)=>buckets.map(r=>({username:r.username,value:r.buckets.filter(b=>(inclusive?b[0]*60>=cutoff:b[0]*60>cutoff)&&b[0]*60<=now/1000).reduce((s,b)=>s+b[1],0)})).filter(r=>r.value>0).sort((a,b)=>b.value-a.value||a.username.localeCompare(b.username)).slice(0,10);
 const damage=damageSince(now/1000-604800),weekly=damageSince(rankWeek(now).start/1000,true);
 return {fish_boards:{fish_all:largestList('all'),fish_week:largestList(week),rarest_all:rareList('all'),rarest_week:rareList(week)},route_times:{solo:{all:[...realms].flatMap(id=>select('time_solo','all',id,1,true)),week:[...realms].flatMap(id=>select('time_solo',week,id,1,true))},coop:{all:[...realms].flatMap(id=>select('time_coop','all',id,1,true)),week:[...realms].flatMap(id=>select('time_coop',week,id,1,true))}},species_trophies:rows.filter(r=>r.kind==='trophy'&&r.scope==='all').sort((a,b)=>b.value-a.value||a.username.localeCompare(b.username)).filter((r,i,a)=>a.findIndex(x=>x.key===r.key)===i).map(r=>({species:r.key,kg:Number(r.value),username:r.username})),damage_all:select('damage','all','total',10),damage_week:weekly,damage_rolling:damage,streak_all:select('streak','all','realms'),streak_week:select('streak',week,'realms'),realm_times_all:[...realms].flatMap(id=>select('time','all',id,1,true)),realm_times_week:[...realms].flatMap(id=>select('time',week,id,1,true)),between_solo:select('between','all','solo'),between_coop:select('between','all','coop'),fish_all:select('fish','all','largest',1)[0]||null,fish_week:select('fish',week,'largest',1)[0]||null,rarest_all:rare('all'),rarest_week:rare(week),relic:select('relic','all','rarest',1)[0]||null,garden:rows.filter(r=>r.kind==='garden').map(({username,scope,key,value})=>({username,scope,crop:key,kg:Number(value)})).sort((a,b)=>b.kg-a.kg).filter((v,i,a)=>a.findIndex(x=>x.crop===v.crop&&x.scope===v.scope)===i).slice(0,48)};
}
