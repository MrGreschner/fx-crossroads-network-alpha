import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
const project=fileURLToPath(new URL('../',import.meta.url));
const fixture=fileURLToPath(new URL('./two_views_runner.gd',import.meta.url));
import {gunzipSync} from 'node:zlib';
import WebSocket,{WebSocketServer} from '../network_service/node_modules/ws/wrapper.mjs';
const wait=ms=>new Promise(r=>setTimeout(r,ms));
async function client(kind,room='',hero='navigator',extra={}){
 const ws=new WebSocket('ws://127.0.0.1:9081');const messages=[];
 ws.on('message',(b,binary)=>messages.push(JSON.parse(binary?gunzipSync(b):b)));await new Promise((r,j)=>{ws.on('open',r);ws.on('error',j)});
 const send=d=>ws.send(JSON.stringify(d));send({type:kind,protocol:3,room,hero,name:'Tester',seats:8,...extra});
 const take=async type=>{for(let i=0;i<200;i++){const n=messages.findIndex(p=>p.type===type);if(n>=0)return messages.splice(n,1)[0];await wait(10);}throw new Error('Missing '+type+' '+JSON.stringify(messages.slice(-2)))};
 return {ws,messages,send,take};
}
import {spawn} from 'node:child_process';
// Deterministic ordered delay: 40ms each way, jitter, occasional 160ms TCP stalls.
let rand=17;const random=()=>((rand=(rand*1664525+1013904223)>>>0)/4294967296);
const proxy=new WebSocketServer({port:9082,perMessageDeflate:false});
proxy.on('connection',c=>{
 const up=new WebSocket('ws://127.0.0.1:9081');let inbound=[],dueUp=0,dueDown=0;const queues={up:[],down:[]};
 const drain=side=>{
  const q=queues[side];if(!q.length)return;
  setTimeout(()=>{const item=q.shift();if(item.dest.readyState===WebSocket.OPEN)item.dest.send(item.data,{binary:item.binary});drain(side);},Math.max(0,q[0].due-performance.now()));
 };
 const later=(dest,data,binary,side)=>{
  const now=performance.now();const delay=40+(random()-.5)*24+(random()<.02?160:0);
  const due=Math.max(side==='up'?dueUp:dueDown,now+delay);
  if(side==='up')dueUp=due;else dueDown=due;
  const q=queues[side];q.push({dest,data,binary,due});if(q.length===1)drain(side);
 };
 c.on('message',(d,b)=>{if(up.readyState===WebSocket.OPEN)later(up,d,b,'up');else inbound.push([d,b]);});
 up.on('open',()=>{for(const [d,b] of inbound)later(up,d,b,'up');inbound=[];});
 up.on('message',(d,b)=>later(c,d,b,'down'));c.on('close',()=>up.close());up.on('close',()=>c.close());
});

function run(kind,room='') {
 const g=spawn(process.env.GODOT_BIN||'godot',['--headless','--path',project,'--script',fixture],{env:{...process.env,FX_TEST_KIND:kind,FX_TEST_ROOM:room}});
 let output='';g.stdout.on('data',b=>output+=b);g.stderr.on('data',b=>output+=b);
 const done=new Promise(r=>g.on('exit',r));return {g,done,output:()=>output};
}
const host=run('host');let room='';
for(let i=0;i<1500;i++){room=host.output().match(/TEST_ROOM ([A-F0-9]+)/)?.[1]||'';if(room)break;await wait(10);}
assert.ok(room,host.output());const guest=run('join',room);
try {
 for(const c of [host,guest]){const code=await c.done;console.log(c.output());assert.equal(code,0);assert.ok(!c.output().includes('ERROR:'));}
} finally {host.g.kill();guest.g.kill();proxy.close();}
console.log('TWO ACTUAL GODOT VIEWS WITH LATENCY/JITTER PASSED');
