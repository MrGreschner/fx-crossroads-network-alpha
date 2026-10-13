(() => {
  if (window.fxDiagnostics) return;
  const key = 'fx-crossroads-diagnostics-v72';
  let enabled = window.fxDiagnosticsEnabled !== false;
  let previous = null;
  try { previous = JSON.parse(localStorage.getItem(key) || 'null'); } catch (_) {}
  const report = {version:'v165', started:new Date().toISOString(), browser:navigator.userAgent,
    previous: previous ? {started:previous.started, latest:previous.latest, events:Array.isArray(previous.events)?previous.events.slice(-12):[]} : null,
    latest:{}, graphics:{}, device:{cores:navigator.hardwareConcurrency || null, memoryGB:navigator.deviceMemory || null}, events:[]};
  function graphics() {
    if (Object.keys(report.graphics).length) return;
    const canvas=document.querySelector('canvas'); if(!canvas)return;
    try { const gl=canvas.getContext('webgl2'); if(!gl || gl.isContextLost())return;
      const ext=gl.getExtension('WEBGL_debug_renderer_info');
      report.graphics={version:gl.getParameter(gl.VERSION),renderer:ext?gl.getParameter(ext.UNMASKED_RENDERER_WEBGL):gl.getParameter(gl.RENDERER),maxTextureSize:gl.getParameter(gl.MAX_TEXTURE_SIZE),width:gl.drawingBufferWidth,height:gl.drawingBufferHeight};
    } catch (_) {}
  }
  function persist() { try { localStorage.setItem(key,JSON.stringify(report)); } catch (_) {} }
  function event(kind,message) { if (!enabled) return; report.events.push({time:new Date().toISOString(),kind,message:String(message).slice(0,1200)}); if(report.events.length>80)report.events.shift(); persist(); }
  function download() { const a=document.createElement('a');const u=URL.createObjectURL(new Blob([JSON.stringify(report,null,2)],{type:'application/json'}));a.href=u;a.download='crossroads-diagnostics.json';a.click();setTimeout(()=>URL.revokeObjectURL(u),2000); }
  window.fxDiagnostics={sample(value){if(!enabled)return;graphics();report.latest=value;if(performance.memory)report.latest.jsHeapBytes=performance.memory.usedJSHeapSize;persist();},set_enabled(value){enabled=!!value;},download,inspect(){graphics();return {browser:report.browser,graphics:report.graphics,device:report.device};}};
  window.addEventListener('error',e=>event('javascript-error',e.message));
  window.addEventListener('unhandledrejection',e=>event('promise-error',e.reason));
  const original=console.error.bind(console);
  console.error=(...args)=>{original(...args);event('engine-error',args.map(String).join(' '));};
  document.addEventListener('webglcontextlost', (e) => {
    const activity=window.fxAnonymousActivity;
    if(activity){
      try{const p={...activity.packet,event:Array.from(crypto.getRandomValues(new Uint8Array(16)),x=>x.toString(16).padStart(2,'0')).join(''),seconds:0,active:0,disconnects:0,graphics:1};
        fetch(activity.endpoint+'/analytics/event',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(p),keepalive:true}).catch(()=>{});
      }catch(_){}
    }
    event('webgl-context-lost',e.statusMessage || 'Browser graphics context lost. This does not prove the computer lacks WebGL2.');
    if(document.getElementById('fx-context-lost'))return;
    const p=document.createElement('div');p.id='fx-context-lost';p.style.cssText='position:fixed;inset:15% 8%;z-index:2147483647;background:#142b32;color:white;padding:24px;border:3px solid #e9c58b;font:18px sans-serif;';
    p.textContent='The browser lost its graphics connection. Save the diagnostic report below before restarting Chrome. If this repeats, try the Windows edition and give the report to your teacher. ';
    const b=document.createElement('button');b.textContent='Download diagnostic report';b.style.cssText='font:18px sans-serif;padding:14px;margin-top:20px;';b.onclick=download;p.append(b);document.body.append(p);
  },true);
  document.addEventListener('webglcontextrestored',()=>event('webgl-context-restored','Browser restored graphics context.'),true);
  window.addEventListener('pagehide',()=>event('page-hidden','Tab closed, reloaded or navigated away; not necessarily a crash.'));
  event('boot','Diagnostic reports stay on this device; anonymous activity counts are separate.');
})();
