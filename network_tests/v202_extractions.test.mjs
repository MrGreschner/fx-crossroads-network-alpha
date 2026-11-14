import assert from 'node:assert/strict';import http from 'node:http';import {PGlite} from '@electric-sql/pglite';import {createHash} from 'node:crypto';
import {repairSchema} from '../network_service/record-repair.mjs';
import {accountSchema} from '../network_service/accounts.mjs';import {createCommunity} from '../network_service/community.mjs';import {rankWeek} from '../network_service/cosmetic-rankings.mjs';import {extractionLeaders} from '../network_service/extraction-ledger.mjs';
const db=new PGlite(),pool={query:async(s,p)=>p?db.query(s,p):(await db.exec(s)).at(-1)||{rows:[]}};await db.exec(accountSchema);await db.exec(repairSchema);let now=Date.parse('2026-10-25T18:00:00Z'),checks=0;
const check=(v,m)=>{assert(v,m);checks++};const accounts={initialized:Promise.resolve(),authenticate:async req=>{const id=req.headers.authorization?.slice(7);return id?(await db.query('SELECT * FROM crossroads_accounts WHERE id=$1 AND NOT disabled',[id])).rows[0]||null:null;}};
const app=createCommunity({pool,accounts,secret:'v202-fixture-only-not-production-32chars',now:()=>now});await app.initialized;check(app.status().ready,'Additive schema initializes');
const server=http.createServer((q,s)=>app.handle(q,s).then(ok=>{if(!ok)s.end()}));await new Promise(r=>server.listen(0,'127.0.0.1',r));const base='http://127.0.0.1:'+server.address().port;
const eid=x=>createHash('sha256').update(x).digest('hex');const event=(id,amount=100,route='solo')=>({id:eid(id),amount,route,hero:'ram',...(route==='coop'?{party:[{name:'One',hero:'ram'},{name:'Two',hero:'ferryman'}]}:{})});
const raw=(i,events=[])=>({record_policy:3,unofficial:false,version:1,profile:String(i).padStart(32,'0'),week:rankWeek(now).week,hero_damage:{ram:100+i},realm_clears:{},between:{solo:100+i,coop:200+i},extractions:events,named:{hero_records:{'between:all:solo':{hero:'ram',value:100+i},'between:all:coop':{hero:'ram',value:200+i,party:[{name:'One',hero:'ram'},{name:'Two',hero:'ferryman'}]}}}});
async function sync(body,id='a1',expected=200){const r=await fetch(base+'/community/sync',{method:'POST',headers:{'content-type':'application/json',...(id?{authorization:'Bearer '+id}:{})},body:JSON.stringify(body)});const text=await r.text();assert.equal(r.status,expected,text);return JSON.parse(text)}
async function board(){const r=await fetch(base+'/community/records');assert.equal(r.status,200);return r.json()}
try{
 for(let i=1;i<=12;i++)await db.query('INSERT INTO crossroads_accounts(id,username,username_key,password_hash) VALUES($1,$2,$3,$4)',['a'+i,'Player'+String(i).padStart(2,'0'),'player'+String(i).padStart(2,'0'),'fixture-only']);
 let b=await board();check(b.named.between_extractors.length===0,'No fabricated historic cumulative totals');
 let response=await sync(raw(1,[event('one',120),event('two',180,'coop')]));check(response.extraction_receipts.length===2,'Authenticated committed receipts');
 await sync(raw(1,[event('one',120),event('two',180,'coop')]));let leaders=await extractionLeaders(pool);check(leaders[0].value===300&&leaders[0].runs===2,'Reupload does not duplicate hauls');check(leaders[0].solo===120&&leaders[0].coop===180,'Route breakdown uses raw carried shards');
 await sync(raw(1,[event('three',20)]));check((await extractionLeaders(pool))[0].value===320,'Smaller later return increases lifetime total');
 await sync(raw(1,[event('one',999)]),'a1',400);check((await extractionLeaders(pool))[0].value===320,'Conflicting replay cannot change original haul');
 await sync(raw(1,[event('valid-before-bad'),{...event('invalid'),hero:'custom_maxed'}]),'a1',400);check((await extractionLeaders(pool))[0].value===320,'Bad batch does not partially enter ledger');
 for(const bad of [{...raw(1,[event('unofficial')]),unofficial:true},{...raw(1,[event('policy')]),record_policy:2},raw(1,[{...event('party',50,'coop'),party:[{hero:'ram'},{hero:'custom_bad'}]}]),raw(1,[event('repeat'),event('repeat')]),raw(1,[event('zero',0)]),raw(1,[event('decimal',1.5)]),raw(1,Array.from({length:33},(_,i)=>event('oversize'+i)))]){await sync(bad,'a1',400);checks++;}
 response=await sync(raw(1,[event('anon')]),null);check(response.extraction_receipts.length===0,'Anonymous uploads do not acknowledge named totals');
 for(let i=2;i<=12;i++)await sync(raw(i,[event('player'+i,100*i)]),'a'+i);
 b=await board();check(b.named.between_extractors.length===10,'Cumulative board returns ten');check(b.named.between_solo.length===10&&b.named.between_coop.length===10,'Best-run boards return ten');check(b.named.between_extractors[0].username==='Player12','Cumulative order');check(!JSON.stringify(b.named.between_extractors).includes('account')&&!JSON.stringify(b.named.between_extractors).includes('run_id'),'Public board hides identifiers');
 await db.query("UPDATE crossroads_accounts SET username='Renamed',username_key='renamed' WHERE id='a12'");now+=31000;b=await board();check(b.named.between_extractors[0].username==='Renamed','Rename follows account ID');
 await db.query("UPDATE crossroads_accounts SET disabled=true WHERE id='a12'");now+=31000;b=await board();check(!b.named.between_extractors.some(r=>r.username==='Renamed'),'Disabled accounts excluded');
 now+=8*86400000;b=await board();check(b.named.between_extractors[0].value===1100,'Cumulative survives weekly reset');
 await sync(raw(2,[]),'a2');check(Number((await db.query("SELECT sum(amount) value FROM crossroads_extraction_events WHERE account='a2'")).rows[0].value)===200,'Old save does not erase server totals');check((await db.query('SELECT count(*)::integer n FROM crossroads_extraction_events')).rows[0].n===14,'Exact event count');
 console.log('V202 EXTRACTIONS:',checks,'checks passed; PostgreSQL-compatible SQL and authenticated HTTP');
}finally{await new Promise(r=>server.close(r));app.stop();await db.close()}
