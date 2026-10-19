(()=>{
 if(window.fxFreezeWatch)return;
 let worker=null,visible=document.visibilityState==='visible';
 try{
  const source=`let last=0,packet=null,endpoint='',visible=true,reported=false;onmessage=e=>{const m=e.data;if(m.visible!==undefined)visible=m.visible;if(m.packet){last=Date.now();packet=m.packet;endpoint=m.endpoint;reported=false;}if(m.stop){packet=null;last=0;reported=false;}};setInterval(()=>{if(!visible||!last||!packet||reported||Date.now()-last<20000)return;reported=true;const p=structuredClone(packet);p.event=Array.from(crypto.getRandomValues(new Uint8Array(16)),v=>v.toString(16).padStart(2,'0')).join('');p.kind='client_stall';p.result='interrupted';p.seconds=0;p.active=0;p.duration=0;p.metrics.stall_seconds=Math.floor((Date.now()-last)/1000);fetch(endpoint+'/activity/ingest',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(p)}).catch(()=>{});},5000);`;
  const url=URL.createObjectURL(new Blob([source],{type:'text/javascript'}));worker=new Worker(url);URL.revokeObjectURL(url);
 }catch{}
 window.fxFreezeWatch={pulse(endpoint,packet){worker?.postMessage({endpoint,packet,visible});},stop(){worker?.postMessage({stop:true});}};
 document.addEventListener('visibilitychange',()=>{visible=document.visibilityState==='visible';worker?.postMessage({visible});});
 window.addEventListener('pagehide',()=>worker?.postMessage({stop:true}));
})();
