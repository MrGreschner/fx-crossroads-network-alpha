import test from 'node:test';
import assert from 'node:assert/strict';
import {Rooms} from './rooms.mjs';
for (const [mode,size] of [['descent',4],['battlegrounds',8],['arena',8]]) {
 test(`v29 ${mode}: separate spectator plus ${size} fighter seats`,()=>{
  const r=new Rooms();const attach=()=>{const messages=[];return {c:r.connect(p=>messages.push(p)),messages};};const h=attach();
  assert.equal(h.messages[0].version,30);
  r.message(h.c,{type:'host',version:29,mode,spectator:true,seats:8,bg_team_size:4});
  const room=r.rooms.get(h.c.room);assert.equal(room.config.spectator,true);assert.equal(r.capacity(room),size+1);
  for(let i=0;i<size;i++){const g=attach();r.message(g.c,{type:'join',code:h.c.room,version:29});assert.equal(g.messages.at(-1).type,'joined');}
  const extra=attach();r.message(extra.c,{type:'join',code:h.c.room,version:29});assert.equal(extra.messages.at(-1).type,'error');
 });
}
test('v29 changing spectator setting keeps room members and updates capacity',()=>{
 const r=new Rooms();const h=r.connect(()=>{});r.message(h,{type:'host',version:29,mode:'descent'});const code=h.room;
 r.message(h,{type:'room_update',settings:{spectator:true}});assert.equal(r.capacity(r.rooms.get(code)),5);assert.equal(h.room,code);
 r.message(h,{type:'room_update',settings:{spectator:false}});assert.equal(r.capacity(r.rooms.get(code)),4);
});
