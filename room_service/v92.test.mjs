import test from 'node:test';
import assert from 'node:assert/strict';
import {Rooms} from './rooms.mjs';
const attach=r=>{let packets=[];return {client:r.connect(p=>packets.push(p)),packets};};
test('Battlegrounds has exact 3v3/4v4 capacities and isolated version',()=>{
 const r=new Rooms(),h=attach(r);r.message(h.client,{type:'host',version:26,mode:'battlegrounds',bg_team_size:3,bg_map:'warzone',public:true,bots:3,spectator:true});
 const room=r.rooms.get(h.client.room);assert.equal(r.capacity(room),6);assert.equal(room.config.rule,'teams');assert.equal(room.config.bots,0);assert.equal(room.config.spectator,false);assert.equal(room.config.bg_map,'warzone');
 for(let i=0;i<5;i++){const p=attach(r);r.message(p.client,{type:'join',code:room.code,version:26});assert.equal(p.client.room,room.code);}
 const extra=attach(r);r.message(extra.client,{type:'join',code:room.code,version:26});assert.equal(extra.client.room,'');assert.match(extra.packets.at(-1).message,/full/);
 assert.equal(r.config({mode:'battlegrounds',bg_team_size:4,version:26}).seats,8);assert.equal(r.config({mode:'battlegrounds',bg_team_size:100,bg_map:'invalid',version:26}).bg_map,'woodland');
});
test('public listing exposes BG settings; active matches reject new joins',()=>{
 const r=new Rooms(),h=attach(r);r.message(h.client,{type:'host',version:26,mode:'battlegrounds',bg_team_size:4,bg_map:'woodland',public:true});
 const p=attach(r);r.message(p.client,{type:'list_rooms',version:26});assert.equal(p.packets.at(-1).rooms[0].bg_team_size,4);
 r.message(p.client,{type:'list_rooms',version:25});assert.equal(p.packets.at(-1).rooms.length,0);
 r.message(h.client,{type:'room_update',started:true});r.message(p.client,{type:'join',version:26,code:h.client.room});assert.match(p.packets.at(-1).message,/already started/);
});
