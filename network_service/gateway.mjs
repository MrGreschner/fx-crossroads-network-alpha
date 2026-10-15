import http from 'node:http';
import {spawn} from 'node:child_process';
import {resolve} from 'node:path';
import {createInterface} from 'node:readline';
import {readFileSync} from 'node:fs';
import {monitorEventLoopDelay} from 'node:perf_hooks';
import WebSocket,{WebSocketServer} from 'ws';
const root=resolve(process.env.FX_PROJECT_ROOT||'..');
const port=Number(process.env.PORT||9080),gamePort=Number(process.env.FX_GAME_PORT||9081);
const queueLimit=16384;let ready=false,metrics={},coalesced=0;
const reasons={};const delay=monitorEventLoopDelay({resolution:20});delay.enable();
const game=spawn(process.env.GODOT_BIN||'godot',['--headless','--path',root,'res://network/server.tscn'],{env:{...process.env,FX_PROXY:'1',FX_GAME_PORT:String(gamePort)}});
let lastCpu=0,lastCpuAt=performance.now(),lastNode=process.cpuUsage(),cpu={};
function updateCpu(){
 const now=performance.now(),elapsed=now-lastCpuAt,usage=process.cpuUsage(lastNode);
 cpu={gateway_cpu_percent:Math.round((usage.user+usage.system)/elapsed)/10,gateway_memory_bytes:process.memoryUsage().rss,gateway_loop_p95_ms:Math.round(delay.percentile(95)/1e4)/100};
 try{
  const stat=readFileSync(`/proc/${game.pid}/stat`,'utf8').split(' ');
  const ticks=Number(stat[13])+Number(stat[14]);
  cpu.authority_cpu_percent=Math.round((ticks-lastCpu)*1000/elapsed*100)/100;lastCpu=ticks;
 }catch{cpu.authority_cpu_percent=null;}
 lastCpuAt=now;lastNode=process.cpuUsage();delay.reset();
}
const cpuTimer=setInterval(updateCpu,5000);cpuTimer.unref();
createInterface({input:game.stdout}).on('line',line=>{
 if(line.startsWith('FX authority listening'))ready=true;
 if(line.startsWith('FX_METRICS ')){try{metrics=JSON.parse(line.slice(11));}catch{}}
 console.log(line);
});game.stderr.on('data',b=>process.stderr.write(b));
const server=http.createServer((req,res)=>{
 if(req.url!=='/health'){res.writeHead(404);res.end('Not found');return;}
 res.writeHead(ready?200:503,{'content-type':'application/json','cache-control':'no-store'});
 res.end(JSON.stringify({ready,protocol:3,simulationHz:60,snapshotHz:20,build:'T4.12',...metrics,...cpu,gateway_clients:wss.clients.size,gateway_coalesced_snapshots:coalesced,gateway_disconnects:reasons}));
});
const wss=new WebSocketServer({noServer:true,maxPayload:16384,perMessageDeflate:false});
server.on('upgrade',(req,socket,head)=>{
 if(!ready||wss.clients.size>=64||req.url!=='/'){socket.write('HTTP/1.1 503 Service Unavailable\r\nConnection: close\r\n\r\n');socket.destroy();return;}
 wss.handleUpgrade(req,socket,head,client=>wss.emit('connection',client));
});
wss.on('connection',client=>{
 const upstream=new WebSocket('ws://127.0.0.1:'+gamePort,{maxPayload:2097152,perMessageDeflate:false});
 const waiting=[];let queued=0,pendingState=null,lastProgress=performance.now(),lastBuffer=0,alive=true,lastProbe=-Infinity;
 const close=(reason='transport_error',code=1011)=>{
  reasons[reason]=(reasons[reason]||0)+1;console.log('FX_GATEWAY_CLOSE '+JSON.stringify({reason,buffer:client.bufferedAmount}));
  client.close(code,reason);upstream.close(code,reason);
 };
 const timer=setInterval(()=>{
  if(client.readyState!==WebSocket.OPEN)return;
  if(client.bufferedAmount<lastBuffer||client.bufferedAmount===0)lastProgress=performance.now();
  lastBuffer=client.bufferedAmount;
  if(pendingState&&client.bufferedAmount<queueLimit){client.send(pendingState,{binary:true});pendingState=null;}
  if(client.bufferedAmount>262144&&performance.now()-lastProgress>15000)close('downstream_stalled',1013);
 },20);timer.unref();
 client.on('pong',()=>{alive=true;});
 const heartbeat=setInterval(()=>{if(!alive){close('heartbeat_timeout',1001);return;}alive=false;if(client.readyState===WebSocket.OPEN)client.ping();},15000);heartbeat.unref();
 client.on('message',(bytes,binary)=>{
  // Lightweight route probe bypasses authority queues, bounded to one/second.
  if(!binary&&bytes.length<256){try{
   const data=JSON.parse(bytes.toString());
   if(data.type==='transport_ping'){
    const now=performance.now();
    if(now-lastProbe>=1000&&Number.isSafeInteger(data.sent)){
     lastProbe=now;client.send(JSON.stringify({type:'transport_pong',sent:data.sent}));
    }
    return;
   }
  }catch{}}

  if(upstream.readyState===WebSocket.OPEN){
   if(upstream.bufferedAmount>262144){close('upstream_flood',1008);return;}
   upstream.send(bytes,{binary});
  }else if(upstream.readyState===WebSocket.CONNECTING&&(queued+=bytes.length)<=32768)waiting.push([bytes,binary]);
  else close('upstream_not_ready');
 });
 upstream.on('open',()=>{for(const [bytes,binary] of waiting)upstream.send(bytes,{binary});waiting.length=0;});
 upstream.on('message',(bytes,binary)=>{
  if(client.readyState!==WebSocket.OPEN)return;
  if(binary){
   // Only the newest full state is useful after a congested connection recovers.
   if(client.bufferedAmount>queueLimit){if(pendingState)coalesced++;pendingState=bytes;return;}
   pendingState=null;
  }
  client.send(bytes,{binary});
 });
 const cleanup=()=>{clearInterval(timer);clearInterval(heartbeat);pendingState=null;};
 const closeCode=code=>code>=1000&&code<=4999&&![1004,1005,1006,1015].includes(code)?code:1000;
 client.on('close',(code,reason)=>{cleanup();if(upstream.readyState===WebSocket.OPEN)upstream.close(closeCode(code),reason.subarray(0,100));});
 upstream.on('close',(code,reason)=>{cleanup();if(client.readyState===WebSocket.OPEN)client.close(closeCode(code),reason.subarray(0,100));});
 client.on('error',()=>close());upstream.on('error',()=>close('authority_connection_error'));
});
server.listen(port,'0.0.0.0',()=>console.log('FX T4 gateway port '+port));
game.on('exit',code=>{ready=false;clearInterval(cpuTimer);console.error('Authority exited: '+code);for(const ws of wss.clients)ws.close(1012,'Server stopped');server.close(()=>process.exit(code||1));});
for(const signal of ['SIGINT','SIGTERM'])process.on(signal,()=>{game.kill('SIGTERM');server.close();});
