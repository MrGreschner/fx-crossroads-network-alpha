import test from 'node:test';
import assert from 'node:assert/strict';
import {Rooms} from './rooms.mjs';
test('protocol 27 realtime games match each other and exclude older builds',()=>{
 const r=new Rooms();const attach=()=>{const messages=[];return {c:r.connect(p=>messages.push(p)),messages};};
 const h=attach(),g=attach(),old=attach();assert.equal(h.messages[0].version,30);assert.ok(h.messages[0].features.includes('realtime_stream'));
 r.message(h.c,{type:'host',mode:'arena',version:27,public:true,seats:8,spectator:true});
 r.message(old.c,{type:'join',code:h.c.room,version:26});assert.equal(old.messages.at(-1).type,'error');
 r.message(old.c,{type:'list_rooms',version:26});assert.equal(old.messages.at(-1).rooms.length,0);
 r.message(g.c,{type:'list_rooms',version:27});assert.equal(g.messages.at(-1).rooms.length,1);
 r.message(g.c,{type:'join',code:h.c.room,version:27});assert.equal(g.messages.at(-1).type,'joined');assert.equal(g.c.version,27);
});
