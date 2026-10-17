/* Bounded asynchronous diagnostics. Never awaited by the game loop. */
(()=>{
 'use strict';
 let enabled=window.fxAnonymousActivityEnabled!==false;
 let session=null,samples=[],queue=[],busy=false,status='Not in a match',lastSend=0,lost=0;
 let device;try{device=localStorage.getItem('fx-test-device-v1');if(!device){device=crypto.randomUUID();localStorage.setItem('fx-test-device-v1',device);}}catch{device=crypto.randomUUID();}
 const badge=document.createElement('button');badge.id='fx-report-status';badge.style.cssText='position:fixed;top:3px;right:3px;z-index:10;background:#142b32dd;color:#cce4e8;border:1px solid #45616b;border-radius:4px;font:11px system-ui;padding:4px 7px;';badge.title='Send the current diagnostic batch. No names or account details are collected.';badge.textContent='Reports: not in a match';badge.onclick=()=>flush('manual');document.body.append(badge);badge.hidden=true;
 function show(s){status=s;badge.hidden=!session;badge.textContent='Reports: '+s+(session?' · '+session.room:'');}
 function batch(reason){if(!enabled||!session||session.enabled===false||!samples.length)return;const selected=samples.splice(0,15);let graphics={};try{const r=window.fxDiagnostics?.inspect()||{};graphics={...(r.graphics||r),hardwareConcurrency:navigator.hardwareConcurrency||0,deviceMemory:navigator.deviceMemory||0};}catch{}queue.push({session:{...session},body:{id:crypto.randomUUID(),match_id:session.match_id,device_id:device,build:'V176-preview',hero:selected.at(-1)?.hero||'',reason,samples:selected,graphics}});if(queue.length>6){queue.shift();lost++;}}
 async function send(){
  if(!enabled||busy||!queue.length||Date.now()-lastSend<1000)return;busy=true;lastSend=Date.now();const item=queue[0];
  try{const controller=new AbortController(),timer=setTimeout(()=>controller.abort(),5000);let r;try{r=await fetch(item.session.endpoint+'/reports/ingest',{method:'POST',headers:{'content-type':'application/json','authorization':'Bearer '+item.session.token},body:JSON.stringify(item.body),signal:controller.signal,keepalive:false});}finally{clearTimeout(timer);}if(r.ok){queue.shift();show(lost?'saved · '+lost+' batches dropped':'saved');}else if(r.status===401||r.status===400||r.status===413){queue.shift();show(r.status===401?'ticket expired · rejoin match':'batch rejected · download F8 report');}else show(r.status===503?'database unavailable · F8 still works':'waiting to retry');}catch{show('offline · waiting to retry');}finally{busy=false;}
 }
 function flush(reason='interval'){batch(reason);send();}
 window.fxReports={set_enabled(value){enabled=!!value;if(!enabled){samples=[];queue=[];show("disabled");}},start(config){if(session?.match_id===config.match_id){session={...config};return;}if(session)batch('new-match');session={...config,endpoint:config.endpoint.replace(/\/$/,'')};samples=[];show(config.enabled===false?'not configured · F8 still works':'collecting');},sample(sample){if(!enabled||!session||session.enabled===false||sample.match_id!==session.match_id||!sample.players)return;if(sample.active===false){if(!session.complete){session.complete=true;flush('match-complete');}return;}samples.push(sample);if(samples.length>45){samples.shift();lost++;}if(sample.graphics_context_lost)flush('graphics-loss');},flush,inspect(){return {status,pending_batches:queue.length,pending_samples:samples.length,dropped:lost,match_id:session?.match_id||''};}};
 setInterval(()=>flush(),15000);
 document.addEventListener('visibilitychange',()=>{if(document.visibilityState==='hidden')flush('hidden');});
 window.addEventListener('pagehide',()=>{batch('pagehide');const item=queue[0];if(!item)return;const body=JSON.stringify(item.body);if(new TextEncoder().encode(body).length<60000)fetch(item.session.endpoint+'/reports/ingest',{method:'POST',headers:{'content-type':'application/json','authorization':'Bearer '+item.session.token},body,keepalive:true}).catch(()=>{});});
 document.addEventListener('webglcontextlost',()=>flush('graphics-loss'),true);
})();
