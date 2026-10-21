import{spawn}from'node:child_process';import{writeFileSync,mkdirSync}from'node:fs';import{gunzipSync}from'node:zlib';import WebSocket from'ws';import assert from'node:assert/strict';
const project=process.cwd(),wait=ms=>new Promise(r=>setTimeout(r,ms));let log='';const server=spawn('node',['network_service/gateway.mjs'],{cwd:project,env:{...process.env,GODOT_BIN:process.env.GODOT_BIN,FX_PROJECT_ROOT:project,PORT:'9786',FX_GAME_PORT:'9787',XDG_DATA_HOME:'/tmp/v197-objective-wire'}});server.stdout.on('data',b=>log+=b);server.stderr.on('data',b=>log+=b);const results=[];let clients=[];
async function until(test,label,ms=15000){for(let t=0;t<ms&&!test();t+=50)await wait(50);assert(test(),label+'\n'+log.slice(-1800));}
async function connect(type,spec){const ws=new WebSocket('ws://127.0.0.1:9786'),c={ws,messages:[],states:[],seq:0};ws.on('message',(b,binary)=>{if(binary)c.states.push(JSON.parse(gunzipSync(b)));else c.messages.push(JSON.parse(b));});await new Promise((r,j)=>{ws.once('open',r);ws.once('error',j)});ws.send(JSON.stringify({type,protocol:11,hero:'ram',name:'QA player',unlocked_realms:['grove'],...spec}));await until(()=>c.messages.some(m=>['welcome','error'].includes(m.type)),'welcome');const reply=c.messages.find(m=>['welcome','error'].includes(m.type));assert(reply.type==='welcome',JSON.stringify(reply));c.welcome=reply;clients.push(c);return c;}
try{await until(()=>log.includes('authority listening'),'authority boot',60000);
for(const map of ['colour_clash','crown_chase'])for(const rule of ['ffa','teams']){
 const host=await connect('host',{mode:'arena',arena_map:map,seats:8,rule,team_size:4,team:0,public:true});for(let i=1;i<8;i++)await connect('join',{room:host.welcome.room,team:i%2});await wait(150);host.ws.send(JSON.stringify({type:'start'}));await until(()=>clients.every(c=>c.messages.some(m=>m.type==='start')&&c.states.length>=3),'start '+map+' '+rule);
 const start=host.messages.find(m=>m.type==='start');assert.equal(start.arena_map,map);assert.equal(start.rule,rule);await until(()=>host.states.at(-1)?.arena_world.objective.elapsed>.2,'active clock',12000);const o=host.states.at(-1).arena_world.objective;assert.equal(o.keys.length,rule==='teams'?2:8);
 if(map==='colour_clash'){
  assert(o.available>1100&&o.paint.length>0);assert(Object.values(o.scores).some(n=>n>0));assert(clients.every(c=>c.states.at(-1).arena_world.objective.keys.length===o.keys.length));
 }else{
  const id=host.welcome.id;let state=host.states.at(-1);const end=Date.now()+11000;
  while(Date.now()<end&&state.arena_world.objective.crown.holder!==id){
   const p=state.players[id].pos,delta=[1280-p[0],960-p[1]],distance=Math.hypot(...delta);const d=distance>12?delta.map(n=>n/distance):[0,0];const frames=[];for(let n=0;n<3;n++)frames.push({seq:++host.seq,d,a:Math.PI,ph:false,sh:false});host.ws.send(JSON.stringify({type:'input',match_id:start.match_id,frames,event_ack:0}));await wait(50);state=host.states.at(-1);
  }
  assert.equal(state.arena_world.objective.crown.holder,id,'host reaches and collects crown');await until(()=>host.states.at(-1).arena_world.objective.held[id]>.8,'carry time');const before=host.states.at(-1).arena_world.objective.held[id];assert(before>0);
  clients[1].ws.send(JSON.stringify({type:'crown_throw',match_id:start.match_id,seq:1,input_seq:0,angle:0,id}));await until(()=>clients[1].messages.some(m=>m.type==='interaction_ack'&&m.seq===1),'forged throw reply');assert.equal(clients[1].messages.find(m=>m.type==='interaction_ack'&&m.seq===1).accepted,false,'non-holder rejected despite forged id');
  host.ws.send(JSON.stringify({type:'crown_throw',match_id:start.match_id,seq:1,input_seq:host.seq,angle:0}));await until(()=>host.messages.some(m=>m.type==='interaction_ack'&&m.seq===1),'throw reply');assert.equal(host.messages.find(m=>m.type==='interaction_ack'&&m.seq===1).accepted,true);
  await until(()=>clients.every(c=>c.states.at(-1).arena_world.objective.passes[id]===1),'throw replicated');assert.equal(host.states.at(-1).arena_world.objective.crown.holder,'');
  host.ws.send(JSON.stringify({type:'crown_throw',match_id:start.match_id,seq:1,input_seq:host.seq,angle:0}));await wait(150);assert.equal(host.states.at(-1).arena_world.objective.passes[id],1,'duplicate action cannot throw twice');
 }
 results.push({map,rule,players:8,started:true,replicated:true});console.log('PASS',map,rule,'8 players');
 for(const c of clients)c.ws.send(JSON.stringify({type:'leave'}));await wait(150);for(const c of clients)c.ws.close();clients=[];await wait(200);
}
assert(!log.includes('SCRIPT ERROR:')&&!log.includes('ERROR:'),log);mkdirSync(project+'/validation/v197',{recursive:true});writeFileSync(project+'/validation/v197/network-objectives.json',JSON.stringify({build:'V197-objective-arenas',passed:true,results},null,2));
}finally{for(const c of clients)c.ws.close();server.kill();writeFileSync('/tmp/v197-objectives-server.log',log);}
