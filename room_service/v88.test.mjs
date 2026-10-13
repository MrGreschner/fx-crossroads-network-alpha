import test from 'node:test';
import assert from 'node:assert/strict';
import {Rooms} from './rooms.mjs';
const attach=r=>{const packets=[];return {client:r.connect(p=>packets.push(p)),packets};};
test('v88 rooms are isolated from v87 and retain foundry selection',()=>{
 const r=new Rooms(),h=attach(r);r.message(h.client,{type:'host',version:22,mode:'coop',realm:'confluence',public:true});
 assert.equal(r.rooms.get(h.client.room).config.realm,'confluence');
 const old=attach(r);r.message(old.client,{type:'join',version:21,code:h.client.room});assert.equal(old.client.room,'');
 const guest=attach(r);r.message(guest.client,{type:'join',version:22,code:h.client.room});assert.equal(guest.client.room,h.client.room);
 const browser=attach(r);r.message(browser.client,{type:'list_rooms',version:22});assert.equal(browser.packets.at(-1).rooms[0].realm,'confluence');
 assert.equal(r.config({version:22,mode:'defense',seats:8}).seats,3);
});
