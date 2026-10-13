import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
const project=fileURLToPath(new URL('../',import.meta.url));
const fixture=fileURLToPath(new URL('./client_runner.gd',import.meta.url));
import {gunzipSync} from 'node:zlib';
import WebSocket from '../network_service/node_modules/ws/wrapper.mjs';
const wait=ms=>new Promise(r=>setTimeout(r,ms));
async function client(kind,room='',hero='navigator',extra={}){
 const ws=new WebSocket('ws://127.0.0.1:9081');const messages=[];
 ws.on('message',(b,binary)=>messages.push(JSON.parse(binary?gunzipSync(b):b)));await new Promise((r,j)=>{ws.on('open',r);ws.on('error',j)});
 const send=d=>ws.send(JSON.stringify(d));send({type:kind,protocol:2,room,hero,name:'Tester',seats:8,...extra});
 const take=async type=>{for(let i=0;i<200;i++){const n=messages.findIndex(p=>p.type===type);if(n>=0)return messages.splice(n,1)[0];await wait(10);}throw new Error('Missing '+type+' '+JSON.stringify(messages.slice(-2)))};
 return {ws,messages,send,take};
}
const host=await client('host');const h=await host.take('welcome');console.log('Hosted',h.room);
const others=[];
for(let n=0;n<7;n++){let c=await client('join',h.room);c.id=(await c.take('welcome')).id;others.push(c)}
host.id=h.id;host.send({type:'start'});const start=await host.take('start');const first=await host.take('state');assert.equal(Object.keys(first.players).length,8);
console.log('Eight players started');
let seq=0;let latest=first;const origin=first.players[h.id].pos;
const startTime=performance.now();
for(let batch=0;batch<30;batch++){
 const frames=[0,1].map(()=>({seq:++seq,d:[1,0],a:0,ph:false,sh:false}));
 for(const c of [host,...others])c.send({type:'input',match_id:start.match_id,frames,event_ack:0});
 await wait(Math.max(0,startTime+(batch+1)*1000/30-performance.now()));
 const states=host.messages.filter(p=>p.type==='state');if(states.length)latest=states.at(-1);
}
await wait(250);latest=host.messages.filter(p=>p.type==='state').at(-1);
assert.equal(latest.players[h.id].position_ack,60);assert.ok(latest.players[h.id].pos[0]>origin[0]);
host.send({type:'pos',match_id:start.match_id,x:99999,y:99999,seq:61});
host.send({type:'attack',match_id:start.match_id,seq:1,input_seq:60,style:'primary',angle:Math.PI,target:[origin[0]-500,origin[1]]});
await wait(350);
const ack=await host.take('action_ack');assert.equal(ack.accepted,true);
const states=host.messages.filter(p=>p.type==='state');const shotStates=states.filter(p=>p.shots.some(s=>s.owner===h.id));
assert.ok(shotStates.length>=2,'projectile visible across snapshots');
const shot=shotStates[0].shots.find(s=>s.owner===h.id);assert.ok(shot.velocity[0]<0);assert.ok(shot.net_id>0);assert.equal(shot.action_seq,1);
const later=shotStates.at(-1).shots.find(s=>s.net_id===shot.net_id);assert.ok(later && later.pos[0]<shot.pos[0]);
assert.ok(states.at(-1).players[h.id].pos[0]<10000,'teleport packet rejected');
console.log('Input ACK 60, constrained movement, stable projectile identity and travel passed');
host.ws.close();await wait(100);const resumed=await client('resume',h.room,'navigator',{token:h.token});const welcome=await resumed.take('welcome');assert.equal(welcome.id,h.id);await resumed.take('start');await resumed.take('state');console.log('Reconnect identity and match restoration passed');
for(const c of [...others,resumed])c.ws.close();
console.log('REAL SERVER INTEGRATION PASSED');
