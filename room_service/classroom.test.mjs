import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import {Rooms} from './rooms.mjs';
const frame=fs.readFileSync(new URL('../content/workshop/classroom-test.jpg',import.meta.url)).toString('base64');
function rig(){let clock=1000;const r=new Rooms({now:()=>clock});const attach=()=>{const messages=[];return {c:r.connect(p=>messages.push(p)),messages};};return {r,attach,tick:()=>clock+=500};}
test('teacher is outside all 31 class seats; seat 32 is rejected',()=>{
 const {r,attach}=rig();const h=attach();r.message(h.c,{type:'class_host',version:30,dev:true,name:'Teacher'});const room=r.classes.get(h.c.classCode);assert.equal(room.students.size,0);
 for(let n=0;n<31;n++){const s=attach();r.message(s.c,{type:'class_join',version:30,code:room.code,name:'Student '+n});assert.equal(s.messages.at(-1).type,'class_status');}
 const full=attach();r.message(full.c,{type:'class_join',version:30,code:room.code});assert.equal(full.messages.at(-1).type,'error');assert.equal(room.students.size,31);
});
test('class frames are teacher-only, rate limited, bounded, and kept only as latest',()=>{
 const {r,attach,tick}=rig();const h=attach(),s=attach();r.message(h.c,{type:'class_host',version:30,dev:true});r.message(s.c,{type:'class_join',version:30,code:h.c.classCode});
 r.message(s.c,{type:'class_start'});assert.equal(s.messages.at(-1).type,'error');r.message(h.c,{type:'class_start'});assert.ok(s.messages.some(p=>p.type==='class_start'));
 r.message(s.c,{type:'class_frame',image:frame,seq:1});assert.equal(s.messages.at(-1).type,'error');
 r.message(h.c,{type:'class_frame',image:frame,seq:1});assert.equal(s.messages.at(-1).seq,1);
 r.message(h.c,{type:'class_frame',image:frame,seq:2});assert.equal(s.messages.at(-1).seq,1);
 tick();r.message(h.c,{type:'class_frame',image:'A'.repeat(110001),seq:2});assert.equal(s.messages.at(-1).seq,1);
 r.message(h.c,{type:'class_frame',image:frame,seq:3});assert.equal(r.classes.get(h.c.classCode).frame.seq,3);
 const late=attach();r.message(late.c,{type:'class_join',version:30,code:h.c.classCode});assert.equal(late.messages.at(-1).seq,3);
});
test('disconnect restores seat capacity and teacher disconnect ends the class',()=>{
 const {r,attach}=rig();const h=attach(),s=attach();r.message(h.c,{type:'class_host',version:30,dev:true});r.message(s.c,{type:'class_join',version:30,code:h.c.classCode});const room=r.classes.get(h.c.classCode);
 r.disconnect(s.c);assert.equal(room.students.size,0);
 const s2=attach();r.message(s2.c,{type:'class_join',version:30,code:room.code});r.disconnect(h.c);assert.equal(s2.messages.at(-1).type,'class_closed');assert.equal(r.classes.size,0);
});
test('old versions and a non-dev teacher cannot host',()=>{
 const {r,attach}=rig();for(const data of [{version:29,dev:true},{version:30,dev:false}]){const c=attach();r.message(c.c,{type:'class_host',...data});assert.equal(c.messages.at(-1).type,'error');}assert.equal(r.classes.size,0);
});
