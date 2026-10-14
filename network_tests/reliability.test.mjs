import assert from 'node:assert/strict';
import {gunzipSync} from 'node:zlib';
import WebSocket,{WebSocketServer} from '../network_service/node_modules/ws/wrapper.mjs';
const wait=ms=>new Promise(r=>setTimeout(r,ms));
const proxyPort=9282;let stalled=false;const relays=[];
const proxy=new WebSocketServer({port:proxyPort,perMessageDeflate:false});
proxy.on('connection',client=>{
 const upstream=new WebSocket('ws://127.0.0.1:9080');const held=[];relays.push({upstream,held});
 client.on('message',(bytes,binary)=>{if(stalled||upstream.readyState!==WebSocket.OPEN)held.push([bytes,binary]);else upstream.send(bytes,{binary});});
 upstream.on('open',()=>{if(!stalled)while(held.length){const [b,bin]=held.shift();upstream.send(b,{binary:bin});}});
 upstream.on('message',(bytes,binary)=>{if(client.readyState===WebSocket.OPEN)client.send(bytes,{binary});});
 client.on('close',()=>upstream.close());upstream.on('close',()=>client.close());
});
async function connect(type,room='',extra={}){
 const c={states:[],acks:[],errors:[],closes:0,id:'',seq:0,action:0};c.ws=new WebSocket('ws://127.0.0.1:'+proxyPort);
 c.send=d=>c.ws.send(JSON.stringify(d));
 c.ws.on('message',(bytes,binary)=>{const p=JSON.parse(binary?gunzipSync(bytes):bytes);if(p.type==='welcome')Object.assign(c,p);if(p.type==='state')c.states.push(p);if(p.type==='start'){c.match=p.match_id;c.seq=0;}if(p.type==='action_ack')c.acks.push(p);if(p.type==='error')c.errors.push(p.message);if(p.type==='input_resync')c.resync=p;});
 c.ws.on('close',()=>c.closes++);await new Promise((r,j)=>{c.ws.on('open',r);c.ws.on('error',j)});
 c.send({type,room,protocol:3,hero:'ram',seats:2,name:'Recovery tester',...extra});
 for(let n=0;n<500&&!c.id;n++)await wait(10);assert.ok(c.id);return c;
}
const host=await connect('host'),guest=await connect('join',host.room);
// A real idle lobby must remain connected longer than the old 10-second cutoff.
for(let n=0;n<16;n++){for(const c of [host,guest])c.send({type:'ping',sent:performance.now()});await wait(1000);}
assert.equal(host.closes+guest.closes,0,'idle lobby survives');
host.send({type:'start'});for(let n=0;n<500&&!host.states.length;n++)await wait(10);
const initial=host.states.at(-1),origin=initial.players[host.id].pos;
// Accumulate 1.5 seconds of ordered TCP input and release it as a burst.
stalled=true;
for(let n=0;n<45;n++){
 for(const c of [host,guest])c.send({type:'input',match_id:c.match,frames:[0,1].map(()=>({seq:++c.seq,d:[.2,0],a:0,ph:false,sh:false})),event_ack:c.states.at(-1)?.events?.at(-1)?.id||0});
 await wait(1000/30);
}
stalled=false;
for(const relay of relays)while(relay.held.length){const [b,bin]=relay.held.shift();relay.upstream.send(b,{binary:bin});}
for(let n=0;n<90;n++){
 for(const c of [host,guest])c.send({type:'input',match_id:c.match,frames:[0,1].map(()=>({seq:++c.seq,d:[0,0],a:0,ph:false,sh:false})),event_ack:c.states.at(-1)?.events?.at(-1)?.id||0});
 await wait(1000/30);
}
await wait(350);
assert.equal(host.closes+guest.closes,0,'burst backlog cannot trigger reconnect loop');
assert.equal(host.states.at(-1).players[host.id].position_ack,host.seq,'authority catches up after dropped stale frames');
const health=await fetch('http://127.0.0.1:9080/health').then(r=>r.json());
assert.equal(health.build,'T4');
assert.ok(host.states.at(-1).players[host.id].pos[0]-origin[0]<100,'burst cannot buy unearned movement');
// An explicit reset acknowledges missing prediction without moving the player.
const before=host.states.at(-1).players[host.id].pos;
host.seq+=200;host.send({type:'input_reset',match_id:host.match,seq:host.seq});await wait(150);
assert.equal(host.states.at(-1).players[host.id].position_ack,host.seq);
assert.deepEqual(host.states.at(-1).players[host.id].pos,before,'resync cannot teleport');
host.ws.terminate();await wait(100);
const resumed=await connect('resume',host.room,{token:host.token});assert.equal(resumed.id,host.id,'resume keeps identity');
for(let n=0;n<500&&!resumed.states.length;n++)await wait(10);assert.ok(resumed.states.at(-1).active,'resume keeps match');
for(const c of [guest,resumed]){c.send({type:'leave'});c.ws.close();}
await wait(150);proxy.close();
console.log('T4 RELIABILITY PASSED: idle lobby, 1.5-second TCP burst, bounded movement, explicit resync, abrupt reconnect');
