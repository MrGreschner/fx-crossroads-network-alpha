import assert from 'node:assert/strict';
import {writeFileSync} from 'node:fs';
import {gunzipSync} from 'node:zlib';
import WebSocket from '../network_service/node_modules/ws/wrapper.mjs';
const duration=Number(process.env.FX_SOAK_SECONDS||60), roomCount=Number(process.env.FX_SOAK_ROOMS||4), seats=Number(process.env.FX_SOAK_SEATS||4);
const protocol=Number(process.env.FX_TEST_PROTOCOL||3),url=process.env.FX_TEST_URL||'ws://127.0.0.1:9080';
const wait=ms=>new Promise(r=>setTimeout(r,ms));
const rooms=[], clients=[], errors=[];
let stopping=false;
async function connect(kind,room='',hero='ram'){
 const c={id:'',room:'',hero,seq:0,action:0,states:0,bytes:0,last:null,lastAt:0,previousTick:-1,gaps:[],actionAck:0,accepted:0,damage:0,closed:0,ping:0,pings:[],queueMax:0,acks:[],eventAck:0};
 c.ws=new WebSocket(url,{perMessageDeflate:false});
 c.send=data=>{if(c.ws.readyState===WebSocket.OPEN)c.ws.send(JSON.stringify(data));};
 c.ws.on('message',(b,binary)=>{
  c.bytes+=b.length;
  let p;try{p=JSON.parse(binary?gunzipSync(b):b);}catch(e){errors.push(String(e));return;}
  if(p.type==='welcome'){c.id=p.id;c.room=p.room;c.token=p.token;}
  if(p.type==='events'){c.eventAck=p.events?.at(-1)?.id||c.eventAck;}
  if(p.type==='start'){c.eventAck=0;c.match=p.match_id;c.seq=0;c.last=null;c.previousTick=-1;}
  if(p.type==='state'){
   const now=performance.now();if(c.lastAt)c.gaps.push(now-c.lastAt);c.lastAt=now;c.states++;c.last=p;
   if(c.previousTick>=0)assert.ok(p.server_tick>=c.previousTick,'monotonic simulation ticks');c.previousTick=p.server_tick;
   const own=p.players[c.id];if(own){c.queueMax=Math.max(c.queueMax,c.seq-own.position_ack);c.damage=Math.max(c.damage,Number(p.contributions?.[c.id]?.damage||0));}
  }
  if(p.type==='action_ack'){c.actionAck++;if(p.accepted)c.accepted++;c.acks.push(Number(p.wait_ms||0));}
  if(p.type==='pong')c.pings.push(performance.now()-p.sent);
  if(p.type==='error')errors.push(p.message);
 });
 c.ws.on('close',(code,reason)=>{c.closed++;if(!stopping)errors.push(`unexpected close ${code} ${reason}`);});
 c.ws.on('error',e=>errors.push(String(e)));
 await new Promise((r,j)=>{c.ws.on('open',r);c.ws.on('error',j)});
 c.send({type:kind,protocol,room,seats,hero,name:'Sustained combat tester'});
 for(let n=0;n<1000&&!c.id;n++)await wait(10);
 assert.ok(c.id,'welcome');clients.push(c);return c;
}
const heroes=['ram','navigator','sunflower','snowman'];
for(let n=0;n<roomCount;n++){
 const host=await connect('host','',heroes[0]);const members=[host];
 for(let k=1;k<seats;k++)members.push(await connect('join',host.room,heroes[k%heroes.length]));
 rooms.push({host,members,restarts:0});host.send({type:'start'});
 for(let k=0;k<1000&&!members.every(c=>c.last);k++)await wait(10);
 assert.ok(members.every(c=>c.last),'first snapshots');
}
console.log(`SOAK START ${roomCount} rooms, ${clients.length} players, ${duration}s`);
const started=performance.now();let batches=0,nextReport=0;
while(performance.now()-started<duration*1000){
 const elapsed=performance.now()-started;
 for(const room of rooms){
  if(room.host.last && !room.host.last.active && elapsed>500){room.restarts++;room.host.send({type:'start'});for(const c of room.members)c.last=null;continue;}
  for(const c of room.members){
   if(!c.last?.active) {if(elapsed%2000<40)c.send({type:'ping',sent:performance.now()});continue;}
   const own=c.last.players[c.id];const targets=Object.entries(c.last.players).filter(([id,p])=>id!==c.id&&p.hp>0).sort((a,b)=>Math.hypot(a[1].pos[0]-own.pos[0],a[1].pos[1]-own.pos[1])-Math.hypot(b[1].pos[0]-own.pos[0],b[1].pos[1]-own.pos[1]));
   const target=targets[0]?.[1]?.pos||own.pos;
   let dx=target[0]-own.pos[0],dy=target[1]-own.pos[1],d=Math.hypot(dx,dy),angle=Math.atan2(dy,dx);
   const motion=d>45?[dx/d,dy/d]:[0,0];
   const frames=[0,1].map(()=>({seq:++c.seq,d:motion,a:angle,ph:false,sh:false}));
   c.send({type:'input',match_id:c.match,frames,event_ack:c.eventAck});
   if(batches%15===0)c.send({type:'attack',match_id:c.match,seq:++c.action,input_seq:c.seq,style:'primary',angle,target});
   if(batches%90===0)c.send({type:'attack',match_id:c.match,seq:++c.action,input_seq:c.seq,style:'special',angle,target});
   if(batches%60===0)c.send({type:'ping',sent:performance.now()});
  }
 }
 batches++;
 if(elapsed>=nextReport){nextReport=elapsed+10000;const health=await fetch(url.replace('ws:','http:').replace('wss:','https:')+'/health').then(r=>r.json());console.log(JSON.stringify({elapsed:Math.round(elapsed/1000),states:clients.reduce((s,c)=>s+c.states,0),closes:clients.reduce((s,c)=>s+c.closed,0),maxQueue:Math.max(...clients.map(c=>c.queueMax)),health}));}
 await wait(Math.max(0,started+batches*1000/30-performance.now()));
 if(errors.length)break;
}
stopping=true;
const percentile=(values,p)=>{if(!values.length)return 0;values.sort((a,b)=>a-b);return values[Math.min(values.length-1,Math.floor(values.length*p))];};
const report={protocol,rooms:roomCount,players:clients.length,seconds:(performance.now()-started)/1000,errors,restarts:rooms.map(r=>r.restarts),states:clients.map(c=>c.states),accepted:clients.map(c=>c.accepted),damage:clients.map(c=>c.damage),closed:clients.reduce((s,c)=>s+c.closed,0),maxQueue:Math.max(...clients.map(c=>c.queueMax)),snapshotGapP95:percentile(clients.flatMap(c=>c.gaps),.95),snapshotGapMax:clients.reduce((peak,c)=>c.gaps.reduce((m,value)=>Math.max(m,value),peak),0),rttP95:percentile(clients.flatMap(c=>c.pings),.95),actionWaitP95:percentile(clients.flatMap(c=>c.acks),.95),downloadBytes:clients.reduce((s,c)=>s+c.bytes,0)};
for(const c of clients){c.send({type:'leave'});c.ws.close();}
writeFileSync(process.env.FX_SOAK_REPORT||'network_tests/soak-results.json',JSON.stringify(report,null,2));console.log('SOAK RESULT '+JSON.stringify(report));
assert.equal(errors.length,0,'no network failures');assert.equal(report.closed,0,'no unexpected closes');assert.ok(report.accepted.every(n=>n>0),'every player has accepted combat');assert.ok(report.damage.some(n=>n>0),'authoritative damage occurs');
console.log('SUSTAINED MULTI-ROOM COMBAT PASSED');
