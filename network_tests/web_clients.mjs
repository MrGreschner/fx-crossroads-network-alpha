import {chromium} from 'playwright';
import http from 'node:http';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';
import {readFileSync,existsSync,writeFileSync} from 'node:fs';
import {spawn} from 'node:child_process';
const root=fileURLToPath(new URL('../',import.meta.url)),web=resolve(process.env.FX_WEB_BUILD||'../T4_Web');
const delay=ms=>new Promise(r=>setTimeout(r,ms));let output='';
const gateway=spawn('node',['network_service/gateway.mjs'],{cwd:root,env:{...process.env,GODOT_BIN:process.env.GODOT_BIN||'godot',FX_PROJECT_ROOT:root,PORT:'9580',FX_GAME_PORT:'9581',XDG_DATA_HOME:'/tmp/t4web-profile'},detached:true});
gateway.stdout.on('data',b=>output+=b);gateway.stderr.on('data',b=>output+=b);
const mime={html:'text/html',js:'text/javascript',wasm:'application/wasm',png:'image/png',pck:'application/octet-stream'};
const server=http.createServer((req,res)=>{const name=(req.url==='/'?'index.html':req.url.slice(1));if(name.includes('..')||!existsSync(web+'/'+name)){res.writeHead(404);res.end();return;}res.writeHead(200,{'Content-Type':mime[name.split('.').at(-1)]||'application/octet-stream'});res.end(readFileSync(web+'/'+name));});
await new Promise(r=>server.listen(9582,'127.0.0.1',r));
let browser;
try{
 for(let n=0;n<200&&!output.includes('authority listening');n++)await delay(100);
 browser=await chromium.launch({headless:true,args:['--no-sandbox','--disable-dev-shm-usage','--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-background-timer-throttling','--disable-renderer-backgrounding','--disable-backgrounding-occluded-windows']});
 const context=await browser.newContext({viewport:{width:1280,height:720}});
 const errors=[];
 const hook=`(() => {const Native=window.WebSocket;window.__fxStates=0;window.__fxAcks=0;window.__fxAccepted=0;window.__fxClosed=0;window.__fxDamage=0;window.WebSocket=class extends Native {constructor(...args){super(...args);this.addEventListener('close',()=>window.__fxClosed++);this.addEventListener('message',async event=>{try{let text;if(typeof event.data==='string')text=event.data;else{const blob=new Blob([event.data]);text=await new Response(blob.stream().pipeThrough(new DecompressionStream('gzip'))).text();}const packet=JSON.parse(text);if(packet.type==='welcome')window.__fxWelcome=packet;if(packet.type==='state'){window.__fxStates++;window.__fxLastState=packet;if(Object.values(packet.contributions||{}).some(v=>v.damage>0))window.__fxDamage++;}if(packet.type==='action_ack'){window.__fxAcks++;if(packet.accepted)window.__fxAccepted++;}}catch{}});}};})();`;
 await context.addInitScript(hook);
 async function newPlayer(){const own=await browser.newContext({viewport:{width:1280,height:720}});await own.addInitScript(hook);const page=await own.newPage();page.on('pageerror',e=>errors.push(String(e)));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});await page.goto('http://127.0.0.1:9582');await delay(12000);await page.mouse.click(570,162);await page.keyboard.press('Control+A');await page.keyboard.type('ws://127.0.0.1:9580',{delay:90});await delay(500);return page;}
 const host=await newPlayer();await host.mouse.click(620,446);await host.waitForFunction(()=>window.__fxWelcome?.room,{timeout:15000});const room=await host.evaluate(()=>window.__fxWelcome.room);
 const guest=await newPlayer();await guest.mouse.click(600,274);await guest.keyboard.type(room,{delay:100});await delay(500);await guest.mouse.click(620,502);await guest.waitForFunction(()=>window.__fxWelcome?.room,{timeout:15000});
 await host.mouse.click(620,558);await host.waitForFunction(()=>window.__fxStates>0,{timeout:15000});await guest.waitForFunction(()=>window.__fxStates>0,{timeout:15000});
 const positions=await host.evaluate(()=>window.__fxLastState.players);
 const hi=await host.evaluate(()=>window.__fxWelcome.id),gi=await guest.evaluate(()=>window.__fxWelcome.id);
 const dx=positions[gi].pos[0]-positions[hi].pos[0];const hk=dx>0?'KeyD':'KeyA',gk=dx>0?'KeyA':'KeyD';
 await host.keyboard.down(hk);await guest.keyboard.down(gk);await delay(Math.max(0,(Math.abs(dx)-55)/490*1000));await host.keyboard.up(hk);await guest.keyboard.up(gk);
 await host.mouse.move(dx>0?710:570,360);await host.mouse.down();await guest.mouse.move(dx>0?570:710,360);await guest.mouse.down();await delay(8000);await host.mouse.up();await guest.mouse.up();
 await host.screenshot({path:'/tmp/t4-web-host.png'});await guest.screenshot({path:'/tmp/t4-web-guest.png'});
 const reports=[];for(const page of [host,guest])reports.push(await page.evaluate(()=>({states:window.__fxStates,acks:window.__fxAcks,accepted:window.__fxAccepted,closed:window.__fxClosed,damageSnapshots:window.__fxDamage,welcome:{id:window.__fxWelcome.id,build:window.__fxWelcome.build,protocol:window.__fxWelcome.protocol},latest:JSON.parse(localStorage.getItem('fx-crossroads-diagnostics-v72')||'{}').latest,players:window.__fxLastState?.players})));
 console.log('TWO_EXPORTED_WEB_CLIENTS '+JSON.stringify({errors,reports}));
 writeFileSync(root+'/network_tests/t4-web-clients.json',JSON.stringify({errors,reports},null,2));
 if(errors.length||reports.some(r=>r.states<30||r.accepted<1||r.closed))throw Error('Web clients failed');
 console.log('TWO EXPORTED WEB CLIENTS PASSED');

}finally{if(browser)await browser.close();server.close();try{process.kill(-gateway.pid,'SIGTERM');}catch{}}
