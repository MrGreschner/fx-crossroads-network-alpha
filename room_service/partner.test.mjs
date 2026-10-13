import {test} from 'node:test';import assert from 'node:assert/strict';import {Rooms} from './rooms.mjs';
function setup(){const r=new Rooms();const make=()=>{let messages=[];let c=r.connect(p=>messages.push(p));return {c,messages}};return {r,make};}
function send(r,c,value,revision){const raw=JSON.stringify(value);const count=Math.ceil(raw.length/24000);for(let index=0;index<count;index++)r.message(c,{type:'partner_chunk',index,count,revision,text:raw.slice(index*24000,(index+1)*24000)});}
test('two seats, validated envelope, cached draft, pencil transfer and reconnect promotion',()=>{
 const {r,make}=setup();const a=make(),b=make(),c=make();r.message(a.c,{type:'partner_host',version:30,name:'One'});const code=a.c.partnerCode;
 send(r,a.c,{kind:'hero',value:{art:'x'.repeat(70000)}},0);assert.equal(r.partners.get(code).revision,1);
 r.message(b.c,{type:'partner_join',version:30,code,name:'Two'});assert.equal(b.messages.filter(p=>p.type==='partner_chunk').length,3);
 r.message(c.c,{type:'partner_join',version:30,code});assert.equal(c.messages.at(-1).type,'error');
 send(r,b.c,{kind:'hero',value:{}},1);assert.equal(b.messages.at(-1).type,'error');
 r.message(b.c,{type:'partner_request'});assert.equal(a.messages.at(-1).type,'partner_requested');r.message(a.c,{type:'partner_pass'});assert.equal(r.partners.get(code).writer,b.c.id);
 for(const kind of ['ability','enemy','behavior'])send(r,b.c,{kind,value:{name:kind}},r.partners.get(code).revision);
 assert.equal(r.partners.get(code).revision,4);r.disconnect(b.c);assert.equal(r.partners.get(code).writer,a.c.id);r.disconnect(a.c);assert.equal(r.partners.size,0);
});
test('reject stale revisions, invalid JSON, unsupported data and oversize transfer',()=>{const {r,make}=setup();const a=make();r.message(a.c,{type:'partner_host',version:30});const room=r.partners.get(a.c.partnerCode);
 send(r,a.c,{kind:'script',value:{}},0);assert.equal(room.revision,0);send(r,a.c,{kind:'hero',value:{}},99);assert.equal(room.revision,0);
 r.message(a.c,{type:'partner_chunk',index:0,count:97,revision:0,text:'{}'});assert.equal(room.upload,null);
 r.message(a.c,{type:'partner_chunk',index:0,count:1,revision:0,text:'no json'});assert.equal(room.revision,0);
 send(r,a.c,{kind:'hero',value:{large:'x'.repeat(2200001)}},0);assert.equal(room.revision,0);
});
