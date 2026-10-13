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
const host=await client('host','','ram',{seats:2});const h=await host.take('welcome');
const guest=await client('join',h.room,'ram');await guest.take('welcome');
host.messages.length=0;host.send({type:'capacity',seats:4});
assert.equal((await host.take('lobby')).seats,4);
const third=await client('join',h.room,'ram');await third.take('welcome');
guest.messages.length=0;guest.send({type:'capacity',seats:8});assert.match((await guest.take('error')).message,/Only the host/);
host.messages.length=0;host.send({type:'capacity',seats:2});assert.match((await host.take('error')).message,/Cannot reduce/);assert.equal((await host.take('lobby')).seats,4);
host.send({type:'start'});await host.take('start');await guest.take('start');await third.take('start');
host.send({type:'capacity',seats:8});assert.match((await host.take('error')).message,/before the match/);
for(const c of [host,guest,third]){c.send({type:'leave'});c.ws.close();}
console.log('LIVE LOBBY CAPACITY CHECKS PASSED');
