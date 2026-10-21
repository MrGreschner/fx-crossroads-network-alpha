import{spawn}from'node:child_process';import{writeFileSync,mkdirSync}from'node:fs';import{gunzipSync}from'node:zlib';import WebSocket from'ws';import assert from'node:assert/strict';
const project=process.cwd(),wait=ms=>new Promise(r=>setTimeout(r,ms));let log='';const server=spawn('node',['network_service/gateway.mjs'],{cwd:project,env:{...process.env,GODOT_BIN:process.env.GODOT_BIN,FX_PROJECT_ROOT:project,PORT:'9784',FX_GAME_PORT:'9785',XDG_DATA_HOME:'/tmp/v196-arenas'}});server.stdout.on('data',b=>log+=b);server.stderr.on('data',b=>log+=b);const results=[];let clients=[];
async function until(test,label,ms=15000){for(let t=0;t<ms&&!test();t+=50)await wait(50);assert(test(),label+'\n'+log.slice(-1500));}
async function connect(type,spec){const ws=new WebSocket('ws://127.0.0.1:9784'),c={ws,messages:[],states:[]};ws.on('message',(b,binary)=>{if(binary)c.states.push(JSON.parse(gunzipSync(b)));else c.messages.push(JSON.parse(b));});await new Promise((r,j)=>{ws.once('open',r);ws.once('error',j)});ws.send(JSON.stringify({type,protocol:11,hero:'ram',name:'QA player',unlocked_realms:['grove'],...spec}));await until(()=>c.messages.some(m=>['welcome','error'].includes(m.type)),'welcome');const reply=c.messages.find(m=>['welcome','error'].includes(m.type));assert(reply.type==='welcome',JSON.stringify(reply));c.welcome=reply;clients.push(c);return c;}
try{await until(()=>log.includes('authority listening'),'authority boot',60000);
for(const map of ['sand','crossroads','storm','forest','clock','maze','lanternfall']){
 const seats=['maze','lanternfall'].includes(map)?8:2;const host=await connect('host',{mode:'arena',arena_map:map,seats,public:true});for(let i=1;i<seats;i++)await connect('join',{room:host.welcome.room});await wait(150);assert(clients.every(c=>c.messages.filter(m=>m.type==='lobby').at(-1)?.arena_map===map),'lobby selection '+map);
 if(map==='maze'){
  clients[1].ws.send(JSON.stringify({type:'arena_choice',arena_map:'sand'}));await wait(100);assert(host.messages.filter(m=>m.type==='lobby').at(-1).arena_map==='maze');
  for(const choice of ['lanternfall','maze']){host.ws.send(JSON.stringify({type:'arena_choice',arena_map:choice}));await until(()=>clients.every(c=>c.messages.filter(m=>m.type==='lobby').at(-1)?.arena_map===choice),'host choice');}
 }
 host.ws.send(JSON.stringify({type:'start'}));await until(()=>clients.every(c=>c.messages.some(m=>m.type==='start')&&c.states.length>=3),'start '+map);
 for(const c of clients){assert.equal(c.messages.find(m=>m.type==='start').arena_map,map);assert.equal(c.states.at(-1).arena_world.map,map);}
 if(map==='maze'){await until(()=>host.states.some(s=>s.arena_world.variant.doors?.some(d=>d[0])),'authoritative gates',20000);assert.equal(host.states.at(-1).arena_world.variant.doors.length,17);}
 if(map==='lanternfall'){await until(()=>host.states.some(s=>Object.keys(s.arena_world.variant.light||{}).length===8),'light updates',12000);const v=host.states.at(-1).arena_world.variant;assert.equal(v.torches.length,14);assert(Object.values(v.light).every(n=>n>=170&&n<=520));}
 assert.equal(clients.at(-1).states.at(-1).arena_world.variant.seed,host.states.at(-1).arena_world.variant.seed);results.push({map,players:seats,started:true,snapshots:true});console.log('PASS',map,seats);
 for(const c of clients)c.ws.send(JSON.stringify({type:'leave'}));await wait(150);for(const c of clients)c.ws.close();clients=[];await wait(200);
}
assert(!log.includes('SCRIPT ERROR:')&&!log.includes('ERROR:'),log);mkdirSync(project+'/validation/v196',{recursive:true});writeFileSync(project+'/validation/v196/network-arenas.json',JSON.stringify({build:'V196-arena-lights',passed:true,results},null,2));
}finally{for(const c of clients)c.ws.close();server.kill();writeFileSync('/tmp/v196-arenas-server.log',log);}
