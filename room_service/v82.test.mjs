import test from 'node:test';
import assert from 'node:assert/strict';
import {Rooms} from './rooms.mjs';
const attach=r=>{const packets=[];return {client:r.connect(p=>packets.push(p)),packets};};
test('practice bots reserve fighter seats without network clients, spectator remains ninth seat',()=>{
 const r=new Rooms(),h=attach(r);r.message(h.client,{type:'host',version:16,mode:'arena',seats:8,spectator:true,bots:3,public:true});
 const browser=attach(r);r.message(browser.client,{type:'list_rooms',version:16});
 assert.equal(browser.packets.at(-1).rooms[0].players,3);assert.equal(browser.packets.at(-1).rooms[0].bots,3);
 for(let n=0;n<5;n++){const p=attach(r);r.message(p.client,{type:'join',version:16,code:h.client.room});assert.ok(p.client.room);}
 assert.equal(r.rooms.get(h.client.room).members.size,6);
 const full=attach(r);r.message(full.client,{type:'join',version:16,code:h.client.room});assert.equal(full.client.room,'');
 const token=h.client.token;r.disconnect(h.client);const temp=attach(r);r.message(temp.client,{type:'resume',token});assert.equal(temp.packets.at(-1).config.bots,3);
});
test('bots only arena, bounded, fixed until room closes, old clients isolated',()=>{
 const r=new Rooms();
 for(const mode of ['defense','descent','coop'])assert.equal(r.config({mode,version:16,bots:3}).bots,0);
 assert.equal(r.config({mode:'arena',version:16,seats:2,bots:99}).bots,1);
 assert.equal(r.config({mode:'arena',version:15,bots:3}).bots,0);
 const h=attach(r);r.message(h.client,{type:'host',mode:'arena',version:16,bots:2});
 r.message(h.client,{type:'room_update',settings:{bots:0}});assert.equal(r.rooms.get(h.client.room).config.bots,2);
 const old=attach(r);r.message(old.client,{type:'join',version:15,code:h.client.room});assert.equal(old.client.room,'');
});
