import test from 'node:test';
import assert from 'node:assert/strict';
import {Rooms} from './rooms.mjs';
test('easy arena difficulty survives hosting, updates and reconnect',()=>{
 const r=new Rooms();const messages=[];const h=r.connect(p=>messages.push(p));
 r.message(h,{type:'host',version:32,mode:'arena',ai_difficulty:'easy'});
 assert.equal(r.rooms.get(h.room).config.ai_difficulty,'easy');
 assert.equal(r.rooms.get(h.room).config.arena_map,'sand');
 r.message(h,{type:'room_update',settings:{ai_difficulty:'hard'}});
 assert.equal(r.rooms.get(h.room).config.ai_difficulty,'hard');
 r.message(h,{type:'room_update',settings:{ai_difficulty:'easy'}});
 const token=h.token;r.disconnect(h);const resumed=r.connect(p=>messages.push(p));
 r.message(resumed,{type:'resume',token});assert.equal(messages.at(-1).config.ai_difficulty,'easy');
 assert.equal(r.config({}).ai_difficulty,'medium');
});
