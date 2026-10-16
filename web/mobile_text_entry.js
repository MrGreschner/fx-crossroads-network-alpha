(() => {
  if (window.fxMobileText) return;
  // Each Godot field owns a native input. Tapping the input directly preserves
  // the browser user gesture needed to open Android/iOS software keyboards.
  window.fxMobileText = {create() {
    const input = document.createElement('input');
    input.type = 'text'; input.autocomplete = 'off'; input.spellcheck = false;
    input.setAttribute('autocorrect', 'off'); input.setAttribute('autocapitalize', 'off');
    input.dataset.fxMobileInput = '';
    input.style.cssText = 'display:none;position:fixed;z-index:10000;box-sizing:border-box;margin:0;padding:4px 10px;border:1px solid #749da7;border-radius:4px;background:#173038;color:#f3f6f7;font:16px sans-serif;touch-action:manipulation;';
    document.body.appendChild(input);
    let disposed = false, composing = false;
    const api = {
      changed:null, submitted:null,
      configure(text, placeholder, secret, maxLength, hint) {
        input.type = secret ? 'password' : 'text';
        input.value = String(text); input.placeholder = String(placeholder);
        input.setAttribute('aria-label', String(placeholder) || 'Text entry');
        input.maxLength = maxLength; input.enterKeyHint = hint;
      },
      value(text) {
        // Do not overwrite an in-progress native edit with last frame's value.
        if (document.activeElement !== input && input.value !== String(text)) input.value = String(text);
      },
      place(x, y, width, height, viewWidth, viewHeight, shown) {
        if (disposed) return;
        const canvas = document.getElementById('canvas');
        if (!shown || !canvas || viewWidth <= 0 || viewHeight <= 0 || width <= 0 || height <= 0) {
          if (document.activeElement === input) input.blur();
          input.style.display = 'none'; return;
        }
        const rect = canvas.getBoundingClientRect();
        Object.assign(input.style, {display:'block', left:`${rect.left+x*rect.width/viewWidth}px`, top:`${rect.top+y*rect.height/viewHeight}px`, width:`${width*rect.width/viewWidth}px`, height:`${height*rect.height/viewHeight}px`});
      },
      dispose() {
        disposed = true; api.changed = null; api.submitted = null; input.remove();
      }
    };
    const changed = () => {if (!disposed && !composing && api.changed) api.changed(input.value);};
    input.addEventListener('input', changed);
    input.addEventListener('compositionstart', () => {composing = true;});
    input.addEventListener('compositionend', () => {composing = false; changed();});
    input.addEventListener('blur', changed);
    input.addEventListener('keydown', e => {
      if (e.key === 'Enter' && !e.isComposing) {
        e.preventDefault(); changed(); if (api.submitted) api.submitted(input.value); input.blur();
      }
    });
    // Native text entry must not also trigger arena controls or Godot's canvas focus.
    for (const type of ['pointerdown','pointerup','touchstart','touchend','mousedown','mouseup','click','keydown','keyup']) input.addEventListener(type, e => e.stopPropagation());
    return api;
  }};
})();
