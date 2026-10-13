import test from 'node:test';
import assert from 'node:assert/strict';
import {Rooms} from './rooms.mjs';
const attach=r=>{const packets=[];const client=r.connect(p=>packets.push(p));return {client,packets};};
test('browser lists compatible waiting public rooms and excludes active/private/full/offline',()=>{
 const r=new Rooms();const a=attach(r),b=attach(r),c=attach(r),v=attach(r);
 r.message(a.client,{type:'host',version:14,mode:'arena',public:true,name:'Duel'});
 r.message(b.client,{type:'host',version:14,mode:'descent',public:false});
 r.message(c.client,{type:'host',version:13,mode:'defense',public:true});
 r.message(v.client,{type:'list_rooms',version:14});assert.equal(v.packets.at(-1).rooms.length,1);assert.equal(v.packets.at(-1).rooms[0].host,'Duel');
 r.message(a.client,{type:'room_update',started:true});r.message(v.client,{type:'list_rooms',version:14});assert.equal(v.packets.at(-1).rooms.length,0);
});
test('late requests require host approval, preserve running match and enforce capacity/version',()=>{
 const r=new Rooms();const h=attach(r),g=attach(r),x=attach(r);
 r.message(h.client,{type:'host',version:14,mode:'defense'});const code=h.client.room;r.message(h.client,{type:'room_update',started:true});
 r.message(g.client,{type:'join_request',version:14,code,name:'Guest'});assert.equal(g.client.room,'');assert.equal(h.packets.at(-1).type,'join_requested');
 r.message(x.client,{type:'join_reply',id:g.client.id,accept:true});assert.equal(g.client.room,'');
 r.message(h.client,{type:'join_reply',id:g.client.id,accept:true});assert.equal(g.client.room,code);assert.equal(g.packets.at(-1).started,true);assert.equal(r.rooms.get(code).started,true);
 r.message(x.client,{type:'join_request',version:13,code});assert.equal(x.packets.at(-1).type,'error');
});
test('arena cannot be late joined and requests expire without admitting players',()=>{
 let now=0;const r=new Rooms({now:()=>now});const h=attach(r),g=attach(r);
 r.message(h.client,{type:'host',version:14,mode:'arena'});r.message(h.client,{type:'room_update',started:true});r.message(g.client,{type:'join_request',version:14,code:h.client.room});assert.equal(g.packets.at(-1).type,'error');
 r.rooms.get(h.client.room).config.mode='descent';r.message(g.client,{type:'join_request',version:14,code:h.client.room});now=31000;r.sweep();r.message(h.client,{type:'join_reply',id:g.client.id,accept:true});assert.equal(g.client.room,'');assert.match(g.packets.at(-1).message,/expired/);
});

test('accepting overlapping requests never admits a fifth player',()=>{
 const r=new Rooms();const h=attach(r);r.message(h.client,{type:'host',version:14,mode:'descent'});r.message(h.client,{type:'room_update',started:true});
 const guests=Array.from({length:4},()=>attach(r));for(const g of guests)r.message(g.client,{type:'join_request',version:14,code:h.client.room});
 for(const g of guests)r.message(h.client,{type:'join_reply',id:g.client.id,accept:true});
 assert.equal(r.rooms.get(h.client.room).members.size,4);assert.equal(guests[3].client.room,'');assert.equal(guests[3].packets.at(-1).type,'error');
});
