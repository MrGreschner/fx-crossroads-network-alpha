import test from 'node:test';
import assert from 'node:assert/strict';
import {Rooms} from './rooms.mjs';
test('protocol 28 realtime games match each other and exclude older builds',()=>{
 const r=new Rooms();const attach=()=>{const messages=[];return {c:r.connect(p=>messages.push(p)),messages};};
 const h=attach(),g=attach(),old=attach();assert.equal(h.messages[0].version,30);assert.ok(h.messages[0].features.includes('realtime_stream'));
 r.message(h.c,{type:'host',mode:'arena',version:28,public:true,seats:8,spectator:true});
 r.message(old.c,{type:'join',code:h.c.room,version:27});assert.equal(old.messages.at(-1).type,'error');
 r.message(old.c,{type:'list_rooms',version:27});assert.equal(old.messages.at(-1).rooms.length,0);
 r.message(g.c,{type:'list_rooms',version:28});assert.equal(g.messages.at(-1).rooms.length,1);
 r.message(g.c,{type:'join',code:h.c.room,version:28});assert.equal(g.messages.at(-1).type,'joined');assert.equal(g.c.version,28);
});
test('waiting host can change bots, seats, realm and mode without losing members',()=>{
 const r=new Rooms(); const attach=()=>{const messages=[];return {c:r.connect(p=>messages.push(p)),messages};}; const h=attach(),g=attach();
 r.message(h.c,{type:'host',mode:'arena',version:28,seats:4});r.message(g.c,{type:'join',code:h.c.room,version:28});const code=h.c.room;
 r.message(h.c,{type:'room_update',settings:{seats:8,bots:3,ai_difficulty:'hard',spectator:true}});
 assert.equal(r.rooms.get(code).config.bots,3);assert.equal(r.rooms.get(code).config.seats,8);assert.equal(r.rooms.get(code).members.size,2);assert.equal(g.c.room,code);assert.equal(g.messages.at(-1).config.ai_difficulty,'hard');
 r.message(h.c,{type:'room_update',settings:{mode:'coop',realm:'moonveil',bots:0,spectator:false}});assert.equal(r.rooms.get(code).config.realm,'moonveil');assert.equal(r.rooms.get(code).config.mode,'coop');
 r.message(g.c,{type:'room_update',settings:{mode:'arena'}});assert.equal(g.messages.at(-1).type,'error');
 r.message(h.c,{type:'room_update',settings:{mode:'arena',seats:2,bots:1}});assert.equal(h.messages.at(-1).type,'error');assert.equal(r.rooms.get(code).config.mode,'coop');
 r.message(h.c,{type:'room_update',started:true});r.message(h.c,{type:'room_update',settings:{mode:'arena',seats:8}});assert.equal(r.rooms.get(code).config.mode,'coop');
});
