import http from 'node:http';
import {spawn} from 'node:child_process';
import {resolve} from 'node:path';
import {createInterface} from 'node:readline';
import WebSocket,{WebSocketServer} from 'ws';
const root=resolve(process.env.FX_PROJECT_ROOT||'..');
const port=Number(process.env.PORT||9080);
const gamePort=Number(process.env.FX_GAME_PORT||9081);
let ready=false,metrics={};
const game=spawn(process.env.GODOT_BIN||'godot',['--headless','--path',root,'res://network/server.tscn'],{env:{...process.env,FX_PROXY:'1',FX_GAME_PORT:String(gamePort)}});
createInterface({input:game.stdout}).on('line',line=>{
 if(line.startsWith('FX authority listening'))ready=true;
 if(line.startsWith('FX_METRICS ')){try{metrics=JSON.parse(line.slice(11));}catch{}}
 console.log(line);
});game.stderr.on('data',b=>process.stderr.write(b));
const server=http.createServer((req,res)=>{
 if(req.url!=='/health'){res.writeHead(404);res.end('Not found');return;}
 res.writeHead(ready?200:503,{'content-type':'application/json','cache-control':'no-store'});
 res.end(JSON.stringify({ready,protocol:2,simulationHz:60,snapshotHz:20,build:"T3",...metrics}));
});
const wss=new WebSocketServer({noServer:true,maxPayload:16384,perMessageDeflate:false});
server.on('upgrade',(req,socket,head)=>{
 if(!ready || wss.clients.size>=64 || req.url!=='/'){socket.write('HTTP/1.1 503 Service Unavailable\r\nConnection: close\r\n\r\n');socket.destroy();return;}
 wss.handleUpgrade(req,socket,head,client=>wss.emit('connection',client));
});
wss.on('connection',client=>{
 const upstream=new WebSocket('ws://127.0.0.1:'+gamePort,{maxPayload:2097152,perMessageDeflate:false});
 const waiting=[];let queued=0;
 const close=()=>{client.close();upstream.close();};
 const forward=(destination,bytes,binary)=>{
  if(destination.readyState!==WebSocket.OPEN)return;
  if(destination.bufferedAmount>65536){destination.close(1013,'Slow connection');return;}
  destination.send(bytes,{binary});
 };
 client.on('message',(bytes,binary)=>{
  if(upstream.readyState===WebSocket.OPEN)forward(upstream,bytes,binary);
  else if(upstream.readyState===WebSocket.CONNECTING && (queued+=bytes.length)<=32768)waiting.push([bytes,binary]);
  else close();
 });
 upstream.on('open',()=>{for(const [bytes,binary] of waiting)forward(upstream,bytes,binary);waiting.length=0;});
 upstream.on('message',(bytes,binary)=>forward(client,bytes,binary));
 client.on('close',()=>upstream.close());upstream.on('close',()=>client.close());
 client.on('error',close);upstream.on('error',close);
});
server.listen(port,'0.0.0.0',()=>console.log('FX gateway port '+port));
game.on('exit',(code)=>{ready=false;console.error('Authority exited: '+code);for(const ws of wss.clients)ws.close(1012,'Server stopped');server.close(()=>process.exit(code||1));});
for(const signal of ['SIGINT','SIGTERM'])process.on(signal,()=>{game.kill('SIGTERM');server.close();});
