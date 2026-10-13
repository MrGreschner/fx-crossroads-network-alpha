import test from 'node:test';
import assert from 'node:assert/strict';
import {Rooms} from './rooms.mjs';
test('protocol 30 test powers keep current rooms separate from protocol 29',()=>{
 const r=new Rooms();const attach=()=>{const messages=[];return {c:r.connect(p=>messages.push(p)),messages};};const h=attach(),g=attach(),old=attach();
 assert.equal(h.messages[0].version,30);
 r.message(h.c,{type:'host',mode:'arena',version:30,public:true,seats:8,spectator:true});
 assert.equal(r.rooms.get(h.c.room).config.version,30);assert.equal(r.capacity(r.rooms.get(h.c.room)),9);
 r.message(old.c,{type:'join',code:h.c.room,version:29});assert.equal(old.messages.at(-1).type,'error');
 r.message(g.c,{type:'join',code:h.c.room,version:30});assert.equal(g.messages.at(-1).type,'joined');
 r.message(old.c,{type:'list_rooms',version:29});assert.equal(old.messages.at(-1).rooms.length,0);
 r.message(h.c,{type:'room_update',settings:{seats:4}});assert.equal(g.c.room,h.c.room);assert.equal(r.capacity(r.rooms.get(h.c.room)),5);
});
