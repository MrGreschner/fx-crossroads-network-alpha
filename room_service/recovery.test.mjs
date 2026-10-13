import test from 'node:test';
import assert from 'node:assert/strict';
import { Rooms } from './rooms.mjs';
function harness(){let time=1000;const rooms=new Rooms({now:()=>time});const connect=()=>{let inbox=[];return {c:rooms.connect(p=>inbox.push(p)),inbox}};return {rooms,connect,advance:n=>time+=n};}
const cfg={type:'host',version:13,mode:'defense',name:'Host'};
test('reconnect retains identity and active room; a rotated token cannot be reused',()=>{
 const h=harness(), host=h.connect(), guest=h.connect();h.rooms.message(host.c,cfg);const hosted=host.inbox.at(-1);
 h.rooms.message(guest.c,{type:'join',code:hosted.code,version:13});h.rooms.message(host.c,{type:'room_update',started:true});
 h.rooms.disconnect(host.c);assert.equal(h.rooms.rooms.size,1);assert.equal(guest.inbox.at(-1).type,'peer_reconnecting');
 const fresh=h.connect(), resumed=h.rooms.message(fresh.c,{type:'resume',token:hosted.resume_token});
 assert.equal(resumed.id,host.c.id);assert.equal(fresh.inbox.at(-1).started,true);assert.equal(guest.inbox.at(-1).type,'peer_resumed');assert.notEqual(resumed.token,hosted.resume_token);
 const thief=h.connect();h.rooms.message(thief.c,{type:'resume',token:hosted.resume_token});assert.equal(thief.inbox.at(-1).type,'error');
});
test('grace expires and explicit leave closes immediately',()=>{
 const h=harness(), host=h.connect();h.rooms.message(host.c,cfg);h.rooms.disconnect(host.c);h.advance(45001);h.rooms.sweep();assert.equal(h.rooms.rooms.size,0);
 const again=h.connect();h.rooms.message(again.c,cfg);h.rooms.message(again.c,{type:'leave'});assert.equal(h.rooms.rooms.size,0);
});
test('ordinary joins cannot enter active matches or bypass version checks',()=>{
 const h=harness(), host=h.connect();h.rooms.message(host.c,cfg);const code=host.inbox.at(-1).code;const old=h.connect();h.rooms.message(old.c,{type:'join',code,version:12});assert.equal(old.inbox.at(-1).type,'error');
 h.rooms.message(host.c,{type:'room_update',started:true});const newOne=h.connect();h.rooms.message(newOne.c,{type:'join',code,version:13});assert.equal(newOne.inbox.at(-1).type,'error');
});
