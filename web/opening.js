(()=>{
'use strict';
const root=document.getElementById('loading'),work=document.getElementById('worksite'),cinema=document.getElementById('cinematic');
const canvas=document.getElementById('canvas'),status=document.getElementById('load-status'),detail=document.getElementById('load-detail');
const stone=[...document.querySelectorAll('.arch-stone')],crew=[...document.querySelectorAll('.crew')],portal=document.getElementById('portal-energy');
const reduced=matchMedia('(prefers-reduced-motion: reduce)').matches;
const BUILD_SECONDS=3.4,HOLD_SECONDS=.35,OPEN_SECONDS=1.05,PULSE_SECONDS=.9,INTRO_SECONDS=22.5,JOURNEY_SECONDS=1.35;
let releaseEngine;const engineGate=new Promise(resolve=>{releaseEngine=resolve;});
let completedPulses=0;
let phase='building',phaseTime=0,age=0,buildProgress=0,introProgress=0,download=0,knownTotal=false;
let started=false,sceneReady=false,failed=false,finished=false,last=performance.now(),lastEvidence=last,raf,night=false,hidden=document.hidden;
const clamp=(x,a=0,b=1)=>Math.max(a,Math.min(b,x));
const ease=(a,b,x)=>{const u=clamp((x-a)/(b-a));return u*u*(3-2*u);};
const attr=(id,key,value)=>document.getElementById(id).setAttribute(key,String(value));
const pose=(id,time,strike=false)=>{const all=[...document.querySelectorAll('#'+id+' .pose')],walk=all.filter(el=>!el.classList.contains('attack')),hasAttack=all.some(el=>el.classList.contains('attack')),chosen=strike&&hasAttack?all.find(el=>el.classList.contains('attack')):walk[Math.floor(time*7)%walk.length];all.forEach(el=>el.style.opacity=el===chosen?'1':'0');};
try{const h=Number(new Intl.DateTimeFormat('en-CA',{timeZone:'America/Edmonton',hour:'numeric',hourCycle:'h23'}).format(new Date()));night=h>=21||h<6;}catch(_){}
if(night)root.classList.add('night');
function resize(){const narrow=innerWidth/innerHeight<.82,vw=narrow?840:1280;document.querySelectorAll('.scene').forEach(s=>s.setAttribute('viewBox',narrow?'220 0 840 720':'0 0 1280 720'));const scale=Math.min(innerWidth/vw,innerHeight/720),boot=document.getElementById('boot-compositor');boot.style.width=352*scale+'px';boot.style.height=408*scale+'px';boot.style.left=(innerWidth/2-176*scale)+'px';boot.style.top=((innerHeight-720*scale)/2+150*scale)+'px';work.style.transformOrigin=(innerWidth/2)+'px '+((innerHeight-720*scale)/2+379*scale)+'px';}
resize();addEventListener('resize',resize);
function construction(){
 buildProgress=clamp(phaseTime/BUILD_SECONDS);
 stone.forEach((el,i)=>{const u=ease(i*.82/stone.length,i*.82/stone.length+.16,buildProgress);el.style.opacity=String(u);el.setAttribute('transform',reduced?'':'translate(0 '+(-28*(1-u))+')');});
 document.getElementById('portal-art').style.clipPath='inset('+(100*(1-buildProgress))+'% 0 0 0)';
 attr('scaffold','opacity',1-.8*ease(.86,1,buildProgress));
 attr('keystone-rope','opacity',1-ease(.86,1,buildProgress));
 attr('foundation-rune','opacity',.1+.5*buildProgress);
 status.textContent=buildProgress<.28?'Laying the foundations…':buildProgress<.73?'Raising the stone arch…':'Setting the keystone…';
}
function workers(){
 if(reduced)return;
 const t=age;
 // Work animations use their own clock, never download progress.
 crew.forEach((el,i)=>{const bob=Math.sin(t*(i===1?6:3)+i)*1.4;const walk=i===1?Math.sin(t*.8)*34:0;el.setAttribute('transform','translate('+walk+' '+bob+')');});
 pose('hauler',t);pose('foreman',t*.7);
 attr('miner-tool','transform','rotate('+(-24+Math.sin(t*3.4)*28)+' 339 497)');
 attr('mason-tool','transform','rotate('+(Math.sin(t*4)*20)+' 821 454)');
 attr('pulley-wheel','transform','rotate('+(t*38)+' 804 185)');
 attr('cart-wheel-a','transform','rotate('+(Math.sin(t*.8)*90)+' 389 548)');
 attr('cart-wheel-b','transform','rotate('+(Math.sin(t*.8)*90)+' 436 548)');
 const dust=Math.max(0,Math.sin(t*3.4));attr('mining-dust','opacity',dust*.6);
}
function charge(){
 const t=age,opening=phase==='opening',pulsing=phase==='pulsing',u=opening?clamp(phaseTime/OPEN_SECONDS):0;
 const waiting=phase==='charging',active=opening||pulsing;
 const boot=.45+.25*Math.sin(t*2.6);
 // Two full, smooth brightening-and-settling cycles after the aperture is open.
 const beat=pulsing?Math.pow(Math.sin(Math.PI*clamp(phaseTime/PULSE_SECONDS,0,2)),2):0;
 if(pulsing)completedPulses=Math.min(2,Math.floor(phaseTime/PULSE_SECONDS));
 attr('portal-rim','opacity',active?1:waiting?.35+boot*.45:buildProgress*.18);
 attr('portal-rim','stroke-width',pulsing?3+beat*2:opening?2+u*2:3);
 attr('boot-light','opacity',pulsing?.4+beat*.6:opening?.3+.7*u:waiting?.12+boot*.15:0);
 attr('portal-energy','opacity',pulsing?.8+beat*.2:opening?ease(0,.65,u):0);
 const scale=pulsing?1+(reduced?0:beat*.025):opening?.07+.93*ease(0,.8,u):1;
 attr('portal-aperture','transform','translate(640 379) scale('+scale+') translate(-640 -379)');
 attr('portal-flow','transform','rotate('+(reduced?0:t*14)+' 640 379)');
 attr('boot-arcs','transform','rotate('+(reduced?0:t*47)+' 640 373)');
 attr('boot-arcs','opacity',opening?1-u:waiting?.45+boot*.3:0);
 attr('boot-seam','opacity',waiting?.12+.45*Math.pow((1+Math.sin(t*2.6))/2,3):0);
 attr('opening-wash','opacity',reduced?0:opening?Math.sin(Math.PI*u)*.24:0);
 if(phase==='built'){status.textContent='The arch is complete';detail.textContent='The crew steps back • preparing the way';}
 if(waiting){
  const stalled=performance.now()-lastEvidence>6500;
  status.textContent='Awakening the portal…';
  detail.textContent=stalled?'Still loading your adventure • the crew is keeping the way ready':'Preparing your adventure';
 }
 if(opening){status.textContent='Opening the way…';detail.textContent='Welcome to Crossroads';}
 if(pulsing){status.textContent='The way is open';detail.textContent='Your adventure awaits';}
}
function intro(){
 introProgress=clamp(phaseTime/INTRO_SECONDS);
 window.fxCinematic.draw(phaseTime,{night,reduced});
 document.getElementById('skip-intro').style.visibility=phaseTime>.75&&phaseTime<21.7?'visible':'hidden';
}

function enter(next){
 phase=next;phaseTime=0;root.dataset.phase=phase;
 if(next==='charging'){
  // Give the browser two paints to upload the animated layers before Godot can occupy JS.
  requestAnimationFrame(()=>requestAnimationFrame(()=>setTimeout(()=>{if(!failed)releaseEngine();},0)));
 }
 if(next==='intro'){
  document.getElementById('journey-wash').style.transition='opacity .45s ease-out';
  document.getElementById('journey-wash').style.opacity='0';
  work.style.opacity='0';work.style.visibility='hidden';document.getElementById('boot-compositor').style.display='none';cinema.style.visibility='visible';cinema.style.opacity='1';cinema.setAttribute('aria-hidden','false');
  root.setAttribute('role','status');root.setAttribute('aria-label','Crossroads opening cinematic');root.removeAttribute('aria-valuenow');
 }
}
function finish(){
 finished=true;window.fxCinematic.dispose();phase='done';root.dataset.phase='done';root.dataset.complete='true';
 root.classList.add('done');setTimeout(()=>{root.remove();canvas.removeAttribute('inert');canvas.focus();removeEventListener('resize',resize);document.removeEventListener('keydown',blockKeys,true);document.removeEventListener('keyup',blockKeys,true);},240);
}
function tick(now){
 // Never skip visible construction or pulses after a main-thread startup stall.
 const dt=hidden?0:Math.min(.05,Math.max(0,(now-last)/1000));last=now;
 if(failed||finished)return;
 age+=dt;phaseTime+=dt;
 if(phase==='building'){
  construction();if(phaseTime>=BUILD_SECONDS)enter('built');
 }else if(phase==='built'&&phaseTime>=HOLD_SECONDS){enter('charging');}
 else if(phase==='charging'&&started&&sceneReady&&window.fxCinematic.readyFlag)enter('opening');
 else if(phase==='opening'&&phaseTime>=OPEN_SECONDS)enter('pulsing');
 else if(phase==='pulsing'&&phaseTime>=PULSE_SECONDS*2){completedPulses=2;enter('journey');}
 else if(phase==='journey'&&phaseTime>=JOURNEY_SECONDS)enter('intro');
 else if(phase==='intro'&&phaseTime>=INTRO_SECONDS){introProgress=1;intro();finish();return;}
 if(phase!=='intro'){
  workers();charge();
  if(phase==='journey'){
   const u=ease(0,1,phaseTime/JOURNEY_SECONDS);
   work.style.transform='none';
   document.getElementById('journey-wash').style.opacity=String(ease(.65,1,u));
   status.textContent='Entering the Crossroads…';detail.textContent='';
   attr('portal-energy','opacity',1);attr('portal-rim','opacity',1);attr('boot-light','opacity',1);
  }
 }else intro();
 raf=requestAnimationFrame(tick);
}
function blockKeys(event){if(phase==='intro'&&event.key==='Escape'){event.preventDefault();finish();return;}if(event.target===document.getElementById('skip-intro'))return;if(failed&&event.target===document.getElementById('retry'))return;if(!finished&&!(failed&&event.key==='Tab')){event.stopImmediatePropagation();if([' ','Enter','Escape','ArrowUp','ArrowDown','ArrowLeft','ArrowRight','Tab'].includes(event.key))event.preventDefault();}}
document.addEventListener('keydown',blockKeys,true);document.addEventListener('keyup',blockKeys,true);
document.addEventListener('visibilitychange',()=>{hidden=document.hidden;last=performance.now();});
canvas.setAttribute('inert','');
window.fxSunLoading={
 engineGate,
 progress(current,total){if(failed||finished)return;if(total>0){knownTotal=true;const next=clamp(current/total);if(next>download){download=next;lastEvidence=performance.now();}root.setAttribute('aria-valuenow',String(Math.round(download*95)));}},
 started(){started=true;lastEvidence=performance.now();},
 ready(){sceneReady=true;lastEvidence=performance.now();},
 error(error){failed=true;cancelAnimationFrame(raf);root.classList.add('failed');status.textContent='The portal could not open';detail.textContent='Please try loading the game again';document.getElementById('error').textContent=String(error);document.getElementById('retry').style.display='block';},
 inspect(){return {phase,phaseTime,age,value:introProgress,buildProgress,introProgress,download,knownTotal,started,sceneReady,failed,finished,night,minimumSeconds:INTRO_SECONDS,buildSeconds:BUILD_SECONDS,openingSeconds:OPEN_SECONDS,holdSeconds:HOLD_SECONDS,pulseSeconds:PULSE_SECONDS,journeySeconds:JOURNEY_SECONDS,completedPulses};}
};
document.getElementById('skip-intro').addEventListener('click',()=>{if(phase==='intro')finish();});
window.fxCinematic.ready.catch(error=>window.fxSunLoading.error(error));
construction();charge();raf=requestAnimationFrame(tick);
})();
