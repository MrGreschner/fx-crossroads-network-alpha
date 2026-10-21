import{spawn}from'node:child_process';import{writeFileSync}from'node:fs';import WebSocket from'ws';import assert from'node:assert/strict';
const project=process.cwd(),wait=ms=>new Promise(r=>setTimeout(r,ms));let log='';const server=spawn('node',['network_service/gateway.mjs'],{cwd:project,env:{...process.env,GODOT_BIN:process.env.GODOT_BIN||'godot',FX_PROJECT_ROOT:project,PORT:'9780',FX_GAME_PORT:'9781',XDG_DATA_HOME:'/tmp/v178-modes'}});server.stdout.on('data',b=>log+=b);server.stderr.on('data',b=>log+=b);const results=[];let clients=[];
async function connect(type,spec){const ws=new WebSocket('ws://127.0.0.1:9780'),c={ws,messages:[],states:0};ws.on('message',(b,binary)=>{if(binary)c.states++;else c.messages.push(JSON.parse(b));});await new Promise((r,j)=>{ws.once('open',r);ws.once('error',j)});ws.send(JSON.stringify({type,protocol:11,hero:'ram',name:'QA player',unlocked_realms:['grove'],...spec}));for(let n=0;n<120&&!c.messages.some(m=>['welcome','error'].includes(m.type));n++)await wait(50);const reply=c.messages.find(m=>['welcome','error'].includes(m.type));assert(reply?.type==='welcome',JSON.stringify(c.messages));c.welcome=reply;clients.push(c);return c;}
try{for(let n=0;n<600&&!log.includes('authority listening');n++)await wait(100);assert(log.includes('authority listening'),log);
for(const [mode,seats]of[['arena',8],['defense',4],['descent',4],['coop',2],['battlegrounds',8]]){
 const host=await connect('host',{mode,realm:'grove',seats,public:true});for(let i=1;i<seats;i++)await connect('join',{room:host.welcome.room});await wait(150);host.ws.send(JSON.stringify({type:'start'}));
 for(let n=0;n<240&&!clients.every(c=>c.messages.some(m=>m.type==='start')&&c.states>=3);n++)await wait(50);
 for(const c of clients)assert(c.messages.some(m=>m.type==='start')&&c.states>=3,JSON.stringify({mode,messages:c.messages,states:c.states}));results.push({mode,players:seats,started:true,snapshots:true});console.log('PASS',mode,seats,'players');
 for(const c of clients)c.ws.send(JSON.stringify({type:'leave'}));await wait(250);for(const c of clients)c.ws.close();clients=[];await wait(350);
}
assert(!log.includes('ERROR:'),log);writeFileSync(project+'/validation/v195/network-modes.json',JSON.stringify({build:'V195',passed:true,results},null,2));
}finally{for(const c of clients)c.ws.close();server.kill();writeFileSync('/tmp/v195-modes-server.log',log);}
