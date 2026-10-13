import test from 'node:test';
import assert from 'node:assert/strict';
import {Rooms} from './rooms.mjs';
const attach=r=>{const packets=[];return {client:r.connect(p=>packets.push(p)),packets};};
test('defence three seats, late join cap and difficulty survive resume',()=>{
 const r=new Rooms(),h=attach(r);r.message(h.client,{type:'host',version:17,mode:'defense',seats:8,ai_difficulty:'hard',public:true});
 const p=attach(r);r.message(p.client,{type:'join',version:17,code:h.client.room});
 r.message(h.client,{type:'room_update',started:true});
 const q=attach(r);r.message(q.client,{type:'join_request',version:17,code:h.client.room});r.message(h.client,{type:'join_reply',id:q.client.id,accept:true});assert.ok(q.client.room);
 const extra=attach(r);r.message(extra.client,{type:'join_request',version:17,code:h.client.room});assert.match(extra.packets.at(-1).message,/full/);assert.equal(extra.client.room,'');
 const token=h.client.token;r.disconnect(h.client);const resumed=attach(r);r.message(resumed.client,{type:'resume',token});assert.equal(resumed.packets.at(-1).config.seats,3);assert.equal(resumed.packets.at(-1).config.ai_difficulty,'hard');
});
test('difficulty defaults, room isolation and other mode limits unchanged',()=>{
 const r=new Rooms();assert.equal(r.config({version:17,mode:'arena',ai_difficulty:'oops'}).ai_difficulty,'medium');
 for(const [mode,realm,seats] of [['arena','grove',8],['descent','grove',4],['coop','grove',4],['coop','wayfarer',2]])assert.equal(r.config({version:17,mode,realm,seats:8}).seats,seats);
 const h=attach(r);r.message(h.client,{type:'host',version:17,mode:'defense',public:true});
 const p=attach(r);r.message(p.client,{type:'list_rooms',version:17});assert.equal(p.packets.at(-1).rooms[0].seats,3);
 r.message(p.client,{type:'join',version:16,code:h.client.room});assert.equal(p.client.room,'');
});
