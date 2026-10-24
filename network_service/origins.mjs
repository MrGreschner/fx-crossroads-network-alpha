// Explicit browser origins only. The service's own site must be able to sign in.
export function sameOrigin(req){
 const value=req.headers.origin;if(!value)return true;
 try{const u=new URL(value);if(u.origin!==value||!['https:','http:'].includes(u.protocol))return false;
  if(u.host.toLowerCase()===String(req.headers.host||'').toLowerCase())return true;
  const external=process.env.RENDER_EXTERNAL_URL;
  return !!external&&u.origin===new URL(external).origin;
 }catch{return false;}
}
export function allowedOrigin(req,{admin=false}={}){
 if(sameOrigin(req))return true;if(admin)return false;
 const value=req.headers.origin||'';
 return /^https:\/\/([a-z0-9-]+\.)*(itch\.zone|itch\.io)$/.test(value)||(process.env.REPORT_ALLOWED_ORIGIN||'').split(',').map(s=>s.trim()).filter(Boolean).includes(value)||(process.env.FX_LOCAL_TEST==='1'&&/^http:\/\/127\.0\.0\.1:\d+$/.test(value));
}
