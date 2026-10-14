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
 const send=d=>ws.send(JSON.stringify(d));send({type:kind,protocol:3,room,hero,name:'Tester',seats:8,...extra});
 const take=async type=>{for(let i=0;i<200;i++){const n=messages.findIndex(p=>p.type===type);if(n>=0)return messages.splice(n,1)[0];await wait(10);}throw new Error('Missing '+type+' '+JSON.stringify(messages.slice(-2)))};
 return {ws,messages,send,take};
}
import {spawn} from 'node:child_process';
const host=await client('host');const h=await host.take('welcome');
const g=spawn(process.env.GODOT_BIN||'godot',['--headless','--path',project,'--script',fixture],{env:{...process.env,FX_TEST_ROOM:h.room,XDG_DATA_HOME:process.env.XDG_DATA_HOME}});
let output='';g.stdout.on('data',b=>output+=b);g.stderr.on('data',b=>output+=b);
let lobby;
for(let i=0;i<1500;i++){lobby=host.messages.filter(p=>p.type==='lobby').at(-1);if(lobby?.members.length===2)break;await wait(10)}
assert.equal(lobby?.members.length,2,output);
const heartbeat=setInterval(()=>host.send({type:'ping',sent:Date.now()}),2000);
await wait(12500);
assert.ok(!output.includes('ERROR:'));host.send({type:'start'});clearInterval(heartbeat);
const exit=await new Promise(r=>g.on('exit',r));console.log(output);assert.equal(exit,0);assert.ok(!output.includes('ERROR:'));host.ws.close();
console.log('ACTUAL GODOT CLIENT PASSED');
