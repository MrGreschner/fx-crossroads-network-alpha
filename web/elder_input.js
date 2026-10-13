// A real HTML input receives the touch gesture directly, so mobile browsers
// can open their keyboard even when canvas focus does not trigger it.
(() => {
  const input = document.createElement('input');
  input.style.cssText = 'position:fixed;z-index:2147483000;box-sizing:border-box;display:none;background:#0b222d;color:#eff8f5;border:2px solid #86d1d6;border-radius:8px;padding:8px 12px;font:16px sans-serif;';
  input.autocomplete = 'off'; input.spellcheck = false;
  input.setAttribute('autocapitalize','off');
  document.body.appendChild(input);
  const api = {
    changed:null, submitted:null,
    configure(value, placeholder, secret, limit, hint='send') {
      input.type = secret ? 'password' : 'text';
      input.value=value; input.placeholder=placeholder; input.maxLength=limit;
      input.setAttribute('aria-label',placeholder || (secret ? 'Password' : 'Text entry'));
      input.enterKeyHint=hint;
    },
    place(x,y,w,h,vw,vh,visible) {
      const canvas=document.querySelector('canvas');
      if (!visible || !canvas || vw<=0 || vh<=0) {
        if(document.activeElement===input)input.blur();
        input.style.display='none'; return;
      }
      const rect=canvas.getBoundingClientRect();
      input.style.left=(rect.left+x*rect.width/vw)+'px';
      input.style.top=(rect.top+y*rect.height/vh)+'px';
      input.style.width=(w*rect.width/vw)+'px';
      input.style.height=(h*rect.height/vh)+'px';
      input.style.display='block';
    },
    value(text) { if(input.value!==text)input.value=text; },
    dispose() { input.blur();input.remove();api.changed=null;api.submitted=null; }
  };
  input.addEventListener('input',()=>{if(api.changed)api.changed(input.value);});
  input.addEventListener('keydown',e=>{
    e.stopPropagation();
    if(e.key==='Enter' && !e.isComposing){e.preventDefault();if(api.submitted)api.submitted(input.value);}
  });
  for(const name of ['keyup','pointerdown','pointerup','touchstart','touchend'])
    input.addEventListener(name,e=>e.stopPropagation());
  window.fxElderTyping=api;
})();
