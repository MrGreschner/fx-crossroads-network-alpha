/* Diagnostic timing only. No GPU queries, readback, player data or game-loop waits. */
(()=>{
 'use strict';
 if(window.fxFrameTiming)return;
 let previous=0,rafMax=0,rafSlow=0,longMax=0,longTotal=0,longCount=0,visibilityChanges=0,hiddenSince=document.hidden?performance.now():null,hiddenTotal=0;
 const frame=now=>{if(previous){const gap=now-previous;rafMax=Math.max(rafMax,gap);if(gap>50)rafSlow++;}previous=now;requestAnimationFrame(frame);};
 requestAnimationFrame(frame);
 let longTasksSupported=false;
 if(typeof PerformanceObserver==='function')try{const observer=new PerformanceObserver(list=>{for(const e of list.getEntries()){longMax=Math.max(longMax,e.duration);longTotal+=e.duration;longCount++;}});observer.observe({type:'longtask',buffered:false});longTasksSupported=true;}catch{}
 document.addEventListener('visibilitychange',()=>{visibilityChanges++;const now=performance.now();if(document.hidden){hiddenSince=now;}else if(hiddenSince!==null){hiddenTotal+=now-hiddenSince;hiddenSince=null;}});
 window.fxFrameTiming={sample(){const now=performance.now(),value={hidden:document.hidden,visibility_changes:visibilityChanges,hidden_total_ms:Math.round(hiddenTotal+(hiddenSince===null?0:now-hiddenSince)),raf_gap_max_ms:Math.round(rafMax),raf_over_50ms:rafSlow,long_tasks_supported:longTasksSupported,long_task_max_ms:Math.round(longMax),long_task_total_ms:Math.round(longTotal),long_task_count:longCount};rafMax=0;rafSlow=0;longMax=0;longTotal=0;longCount=0;return value;}};
})();
