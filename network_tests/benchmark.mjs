import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
const project=fileURLToPath(new URL('../',import.meta.url));
const fixture=fileURLToPath(new URL('./client_runner.gd',import.meta.url));
import {gunzipSync} from 'node:zlib';
import {writeFileSync} from 'node:fs';
import WebSocket from '../network_service/node_modules/ws/wrapper.mjs';
const wait=ms=>new Promise(r=>setTimeout(r,ms));
async function connect(type,room='',seats=2){
 const ws=new WebSocket('ws://127.0.0.1:9081');const messages=[];let bytes=0;
 ws.on('message',(b,binary)=>{bytes+=b.length;messages.push(JSON.parse(binary?gunzipSync(b):b));});
 await new Promise((r,j)=>{ws.on('open',r);ws.on('error',j)});
 const send=data=>ws.send(JSON.stringify(data));
 send({type,room,seats,protocol:1,hero:'navigator',name:'Load test'});
 const take=async type=>{for(let i=0;i<300;i++){let n=messages.findIndex(v=>v.type===type);if(n>=0)return messages.splice(n,1)[0];await wait(10);}throw Error('Missing '+type);};
 const welcome=await take('welcome');return {ws,send,take,messages,id:welcome.id,room:welcome.room,bytes:()=>bytes};
}
const reports=[];
for(const count of [2,4,8]){
 const host=await connect('host','',count);const clients=[host];
 for(let n=1;n<count;n++)clients.push(await connect('join',host.room,count));
 host.send({type:'start'});let start=await host.take('start');await host.take('state');
 for(const c of clients)c.messages.length=0;
 const initial=clients.reduce((n,c)=>n+c.bytes(),0),begin=performance.now();let sequence=0;
 for(let batch=0;batch<120;batch++){
  const frames=[0,1].map(()=>({seq:++sequence,d:[Math.floor(batch/30)%2?-1:1,0],a:0,ph:false,sh:false}));
  for(const c of clients)c.send({type:'input',match_id:start.match_id,frames,event_ack:0});
  await wait(Math.max(0,begin+(batch+1)*1000/30-performance.now()));
 }
 await wait(300);
 const states=host.messages.filter(v=>v.type==='state');const cost=states.map(v=>v.tick_ms).sort((a,b)=>a-b);
 assert.ok(states.length>=65);assert.equal(states.at(-1).players[host.id].position_ack,sequence);
 const report={players:count,seconds:4.3,snapshots:states.length,tick_p50_ms:cost[Math.floor(cost.length*.5)],tick_p95_ms:cost[Math.floor(cost.length*.95)],tick_max_ms:cost.at(-1),total_download_bytes:clients.reduce((n,c)=>n+c.bytes(),0)-initial};
 report.download_kib_per_player_sec=Math.round(report.total_download_bytes/count/4.3/1024*10)/10;reports.push(report);console.log(JSON.stringify(report));
 for(const c of clients){c.send({type:'leave'});await wait(20);c.ws.close();}
 await wait(200);
}
writeFileSync('network_tests/benchmark-results.json',JSON.stringify(reports,null,2));console.log('2/4/8 PLAYER LOAD CHECKS PASSED');
