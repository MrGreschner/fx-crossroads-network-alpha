(()=>{
 if(window.fxFreezeWatch)return;
 let worker=null,visible=document.visibilityState==='visible';
 try{
  worker=new Worker('web/browser/stall-worker.js');
 }catch{}
 window.fxFreezeWatch={pulse(endpoint,packet){worker?.postMessage({endpoint,packet,visible});},stop(){worker?.postMessage({stop:true});}};
 document.addEventListener('visibilitychange',()=>{visible=document.visibilityState==='visible';worker?.postMessage({visible});});
 window.addEventListener('pagehide',()=>worker?.postMessage({stop:true}));
})();
