import test from 'node:test';
import assert from 'node:assert/strict';
import {Rooms} from './rooms.mjs';
const attach=r=>{const packets=[];return {client:r.connect(p=>packets.push(p)),packets};};
test('eight fighters plus one spectator, public count, ninth fighter rejected, resume preserved',()=>{
 const r=new Rooms();const h=attach(r);r.message(h.client,{type:'host',version:15,mode:'arena',seats:8,spectator:true,public:true});const code=h.client.room;
 const players=Array.from({length:8},()=>attach(r));
 for(const p of players)r.message(p.client,{type:'join',version:15,code});
 assert.equal(r.rooms.get(code).members.size,9);
 const extra=attach(r);r.message(extra.client,{type:'join',version:15,code});assert.equal(extra.client.room,'');
 r.message(extra.client,{type:'list_rooms',version:15});assert.equal(extra.packets.at(-1).rooms.length,0);
 r.leave(players[7].client);r.message(extra.client,{type:'list_rooms',version:15});assert.equal(extra.packets.at(-1).rooms[0].players,7);assert.equal(extra.packets.at(-1).rooms[0].seats,8);
 const token=h.client.token;r.disconnect(h.client);const temp=attach(r);r.message(temp.client,{type:'resume',token});assert.equal(temp.packets.at(-1).config.spectator,true);
});
test('mode caps, version isolation and format locked after hosting',()=>{
 for(const [mode,realm,limit] of [['arena','grove',3],['defense','grove',4],['descent','grove',4],['coop','grove',4],['coop','wayfarer',2]]){
  const r=new Rooms();const h=attach(r);r.message(h.client,{type:'host',version:15,mode,realm,seats:3});
  for(let n=1;n<=limit;n++){const p=attach(r);r.message(p.client,{type:'join',version:15,code:h.client.room});assert.equal(Boolean(p.client.room),n<limit);}
  const old=attach(r);r.message(old.client,{type:'join',version:14,code:h.client.room});assert.equal(old.client.room,'');
  r.message(h.client,{type:'room_update',settings:{seats:8,spectator:true}});assert.equal(r.rooms.get(h.client.room).config.seats,limit);assert.equal(r.rooms.get(h.client.room).config.spectator,false);
 }
});
