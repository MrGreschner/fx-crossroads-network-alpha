import test from 'node:test';
import assert from 'node:assert/strict';
import {spawn} from 'node:child_process';
import net from 'node:net';
import {once} from 'node:events';
import fs from 'node:fs';
import WebSocket from 'ws';
const delay=ms=>new Promise(r=>setTimeout(r,ms));
async function client(url){const socket=new WebSocket(url),messages=[];socket.on('message',b=>messages.push(JSON.parse(b.toString())));await once(socket,'open');return {socket,send:p=>socket.send(JSON.stringify(p)),take:async type=>{for(let n=0;n<300;n++){const i=messages.findIndex(p=>p.type===type);if(i>=0)return messages.splice(i,1)[0];await delay(10);}throw Error('Missing '+type);}};}
test('real WebSocket teacher broadcasts the same bounded screen to 31 students',{timeout:20000},async()=>{
 const probe=net.createServer();probe.listen(0,'127.0.0.1');await once(probe,'listening');const port=probe.address().port;await new Promise(r=>probe.close(r));
 const service=spawn(process.execPath,['server.mjs'],{cwd:new URL('.',import.meta.url),env:{...process.env,PORT:String(port)}});const peers=[];
 try{
  await once(service.stdout,'data');const url='ws://127.0.0.1:'+port;const h=await client(url);peers.push(h);await h.take('server_info');h.send({type:'class_host',version:30,dev:true,name:'Teacher'});const info=await h.take('class_joined');
  const students=await Promise.all(Array.from({length:31},async(_,n)=>{const s=await client(url);peers.push(s);await s.take('server_info');s.send({type:'class_join',code:info.code,version:30,name:'Student '+n});await s.take('class_joined');return s;}));
  const extra=await client(url);peers.push(extra);await extra.take('server_info');extra.send({type:'class_join',code:info.code,version:30});assert.match((await extra.take('error')).message,/31/);
  h.send({type:'class_start'});await Promise.all(students.map(s=>s.take('class_start')));
  const image=fs.readFileSync(new URL('../content/workshop/classroom-test.jpg',import.meta.url)).toString('base64');h.send({type:'class_frame',seq:1,image});
  const frames=await Promise.all(students.map(s=>s.take('class_frame')));assert.equal(frames.length,31);assert.ok(frames.every(f=>f.image===image && f.seq===1));
  h.socket.close();await Promise.all(students.map(s=>s.take('class_closed')));
 } finally {for(const p of peers)p.socket.close();service.kill();await once(service,'exit');}
});
