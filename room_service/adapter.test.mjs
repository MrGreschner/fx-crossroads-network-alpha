import test from 'node:test';
import assert from 'node:assert/strict';
import {spawn} from 'node:child_process';
import net from 'node:net';
import {once} from 'node:events';
import WebSocket from 'ws';

async function connection(url){
 const socket=new WebSocket(url), inbox=[];
 socket.on('message', bytes=>inbox.push(JSON.parse(bytes.toString())));
 await once(socket,'open');
 return {socket,send:p=>socket.send(JSON.stringify({game_build:166,...p})),take:async type=>{
  const end=Date.now()+3000;
  while(Date.now()<end){const index=inbox.findIndex(p=>p.type===type);if(index>=0)return inbox.splice(index,1)[0];await new Promise(r=>setTimeout(r,10));}
  throw Error('No '+type+' response');
 }};
}
test('real WebSocket adapter resumes an active room and routes signals with the original identity',{timeout:10000},async()=>{
 const probe=net.createServer();probe.listen(0,'127.0.0.1');await once(probe,'listening');const port=probe.address().port;await new Promise(r=>probe.close(r));
 const service=spawn(process.execPath,['server.mjs'],{cwd:new URL('.',import.meta.url),env:{...process.env,PORT:String(port)}});
 const sockets=[];
 try{
  await Promise.race([once(service.stdout,'data'),new Promise((_,reject)=>setTimeout(()=>reject(Error('Service did not start')),3000))]);
  const url='ws://127.0.0.1:'+port;
  const release=await fetch('http://127.0.0.1:'+port+'/release');assert.equal(release.status,200);assert.equal(release.headers.get('cache-control'),'no-store');assert.equal((await release.json()).game_build,166);
  const old=await connection(url);sockets.push(old.socket);old.send({type:'host',version:32,game_build:146,mode:'descent'});assert.match((await old.take('error')).message,/Save\/download your player profile first/);
  const h=await connection(url);sockets.push(h.socket);assert.equal((await h.take('server_info')).version,30);
  h.send({type:'host',version:14,mode:'descent'});const room=await h.take('hosted');
  const g=await connection(url);sockets.push(g.socket);g.send({type:'join',version:14,code:room.code});const guest=await g.take('joined');await h.take('peer_joined');
  h.send({type:'room_update',started:true});await g.take('room_status');h.socket.close();await g.take('peer_reconnecting');
  const fresh=await connection(url);sockets.push(fresh.socket);fresh.send({type:'resume',token:room.resume_token});const resumed=await fresh.take('resumed');
  assert.equal(resumed.id,room.id);assert.equal(resumed.started,true);assert.equal((await g.take('peer_resumed')).id,room.id);
  g.send({type:'signal',to:room.id,signal:{kind:'repair'}});const signal=await fresh.take('signal');assert.equal(signal.from,guest.id);
  fresh.send({type:'signal',to:guest.id,signal:{kind:'description',epoch:1}});assert.equal((await g.take('signal')).from,room.id);
  fresh.send({type:'remove_peer',id:guest.id});await g.take('room_closed');assert.equal((await fresh.take('peer_left')).id,guest.id);
  fresh.send({type:'leave'});
 } finally {for(const socket of sockets)socket.terminate();service.kill('SIGTERM');await once(service,'exit');}
});

test('real WebSocket adapter admits eight fighters plus spectator and relays each connection',{timeout:15000},async()=>{
 const probe=net.createServer();probe.listen(0,'127.0.0.1');await once(probe,'listening');const port=probe.address().port;await new Promise(r=>probe.close(r));
 const service=spawn(process.execPath,['server.mjs'],{cwd:new URL('.',import.meta.url),env:{...process.env,PORT:String(port)}});const sockets=[];
 try{
  await Promise.race([once(service.stdout,'data'),new Promise((_,reject)=>setTimeout(()=>reject(Error('Service did not start')),3000))]);
  const url='ws://127.0.0.1:'+port;const h=await connection(url);sockets.push(h.socket);
  h.send({type:'host',version:15,mode:'arena',seats:8,spectator:true,public:true});const room=await h.take('hosted');
  for(let n=0;n<8;n++){
   const p=await connection(url);sockets.push(p.socket);p.send({type:'join',version:15,code:room.code});const joined=await p.take('joined');assert.equal(joined.roster.length,n+2);await h.take('peer_joined');
   p.send({type:'signal',to:room.id,signal:{kind:'test',number:n}});const signal=await h.take('signal');assert.equal(signal.from,joined.id);assert.equal(signal.signal.number,n);
  }
  const extra=await connection(url);sockets.push(extra.socket);extra.send({type:'join',version:15,code:room.code});assert.match((await extra.take('error')).message,/full/);
  h.send({type:'room_update',started:true});await h.take('room_status');
 } finally {for(const socket of sockets)socket.terminate();service.kill('SIGTERM');await once(service,'exit');}
});
