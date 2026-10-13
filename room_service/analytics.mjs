import { DatabaseSync } from 'node:sqlite';
import { createHmac, timingSafeEqual } from 'node:crypto';
import { mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
export const CATEGORIES=['town','realm','descent','defense','arena','battlegrounds','quest','studio','mine','market','fishing','menu'];
const id=/^[a-f0-9]{32}$/;
export function validReport(p){
 return p && Object.keys(p).every(k=>['event','session','profile','device','category','hero','realm','build','platform','seconds','active','disconnects','graphics'].includes(k)) &&
 ['event','session','profile','device'].every(k=>typeof p[k]==='string'&&id.test(p[k])) && CATEGORIES.includes(p.category) &&
 typeof p.hero==='string'&&/^[a-z0-9_-]{0,64}$/.test(p.hero)&&typeof p.realm==='string'&&/^[a-z0-9_-]{0,64}$/.test(p.realm)&&
 ['web','desktop','mobile'].includes(p.platform)&&Number.isInteger(p.build)&&p.build>0&&p.build<100000&&
 ['seconds','active'].every(k=>Number.isInteger(p[k])&&p[k]>=0&&p[k]<=90)&&p.active<=p.seconds&&
 ['disconnects','graphics'].every(k=>p[k]===0||p[k]===1);
}
export class Analytics {
 constructor({file,key,hashKey,now=()=>Date.now(),timezone='America/Edmonton'}={}){
  this.now=now;this.key=key||'';this.timezone=timezone;this.limits=new Map();this.db=null;
  this.date=new Intl.DateTimeFormat('en-CA',{timeZone:timezone,year:'numeric',month:'2-digit',day:'2-digit'});
  if(!file||this.key.length<24||!hashKey||hashKey.length<24)return;
  this.hashKey=hashKey;
  if(file!==':memory:')mkdirSync(dirname(file),{recursive:true});
  this.db=new DatabaseSync(file);this.db.exec(`PRAGMA journal_mode=WAL; PRAGMA busy_timeout=3000;
   CREATE TABLE IF NOT EXISTS activity(event TEXT PRIMARY KEY,session TEXT,profile TEXT,device TEXT,day TEXT,at INTEGER,category TEXT,hero TEXT,realm TEXT,build INTEGER,platform TEXT,seconds INTEGER,active INTEGER,disconnects INTEGER,graphics INTEGER);
   CREATE INDEX IF NOT EXISTS activity_day ON activity(day); CREATE INDEX IF NOT EXISTS activity_at ON activity(at); CREATE INDEX IF NOT EXISTS activity_session_at ON activity(session,at);`);
  this.insert=this.db.prepare('INSERT OR IGNORE INTO activity VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)');
  this.prune();
 }
 hash(s){return createHmac('sha256',this.hashKey).update(s).digest('hex');}
 authorized(header){const a=Buffer.from(header||''),b=Buffer.from('Bearer '+this.key);return this.db!==null&&a.length===b.length&&timingSafeEqual(a,b);}
 prune(){this.lastPrune=this.now();this.db?.prepare('DELETE FROM activity WHERE at < ?').run(this.now()-90*86400000);}
 ingest(p,source='local'){
  if(!this.db)return {status:503,error:'Activity history needs a persistent database and private server keys.'};
  if(!validReport(p))return {status:400,error:'Invalid activity report.'};
  const now=this.now();if(now-this.lastPrune>3600000)this.prune();const bucket=Math.floor(now/60000);const address=this.hash(source);
  const old=this.limits.get(address);const limit=old?.bucket===bucket?old:{bucket,count:0};
  if(limit.count++>=600)return {status:429,error:'Too many reports.'};this.limits.set(address,limit);
  if(this.limits.size>4096)for(const [k,v]of this.limits)if(v.bucket<bucket)this.limits.delete(k);
  if(this.limits.size>8192)return {status:429,error:'Activity intake busy.'};
  // Duplicate IDs never count twice. A session is capped at 12 reports/minute.
  const session=this.hash(p.session);
  if(this.db.prepare('SELECT COUNT(*) AS n FROM activity WHERE session=? AND at>?').get(session,now-60000).n>=12)return {status:429,error:'Report too frequent.'};
  const result=this.insert.run(this.hash(p.session+':'+p.event),session,this.hash(p.profile),this.hash(p.device),this.date.format(now),now,p.category,p.hero,p.realm,p.build,p.platform,p.seconds,p.active,p.disconnects,p.graphics);
  return {status:202,accepted:Number(result.changes)>0};
 }
 dashboard(days=30){
  days=Math.max(1,Math.min(90,Number(days)||30));this.prune();const cutoff=this.now()-days*86400000;
  const daily=this.db.prepare(`SELECT day,COUNT(DISTINCT CASE WHEN active>0 THEN profile END) profiles,COUNT(DISTINCT device) devices,COUNT(DISTINCT session) sessions,SUM(active) active_seconds,SUM(disconnects) disconnects,SUM(graphics) graphics_losses FROM activity WHERE at>=? GROUP BY day ORDER BY day`).all(cutoff);
  const activities=this.db.prepare('SELECT category,SUM(active) seconds FROM activity WHERE at>=? GROUP BY category ORDER BY seconds DESC').all(cutoff);
  const heroes=this.db.prepare("SELECT hero,SUM(active) seconds FROM activity WHERE at>=? AND hero<>'' AND category IN ('realm','descent','defense','arena','battlegrounds','quest') GROUP BY hero ORDER BY seconds DESC LIMIT 12").all(cutoff);
  const realms=this.db.prepare("SELECT realm,SUM(active) seconds FROM activity WHERE at>=? AND realm<>'' AND category='realm' GROUP BY realm ORDER BY seconds DESC LIMIT 12").all(cutoff);
  const online=this.db.prepare('SELECT COUNT(DISTINCT device) devices FROM activity WHERE at>?').get(this.now()-180000).devices;
  // Peak recently reporting installations in each three-minute bucket; excludes idle-only incident packets.
  const peak=this.db.prepare('SELECT MAX(n) n FROM (SELECT CAST(at/180000 AS INTEGER) bucket,COUNT(DISTINCT device) n FROM activity WHERE at>=? AND seconds>0 GROUP BY bucket)').get(cutoff).n||0;
  return {timezone:this.timezone,retention_days:90,days,online_devices:online,peak_reporting_devices:peak,daily,activities,heroes,realms};
 }
 async handle(req,res){
  const pathname=req.url?.split('?')[0];if(!['/analytics/event','/analytics/dashboard'].includes(pathname))return false;
  const headers={'Content-Type':'application/json','Cache-Control':'no-store','Access-Control-Allow-Origin':'*','Access-Control-Allow-Headers':'Authorization, Content-Type','Access-Control-Allow-Methods':'POST, GET, OPTIONS'};
  const send=(status,p)=>{res.writeHead(status,headers);res.end(JSON.stringify(p));};
  if(req.method==='OPTIONS'){send(204,{});return true;}
  if(pathname==='/analytics/dashboard'){
   if(req.method!=='GET'){send(405,{error:'GET required.'});return true;}
   if(!this.db){send(503,{error:'Analytics not configured. Follow DEPLOY_V161.md.'});return true;}
   if(!this.authorized(req.headers.authorization)){send(401,{error:'Private dashboard key required.'});return true;}
   send(200,this.dashboard(new URL(req.url,'http://local').searchParams.get('days')));return true;
  }
  if(req.method!=='POST'){send(405,{error:'POST required.'});return true;}
  let bytes=0;const chunks=[];
  try{for await(const chunk of req){bytes+=chunk.length;if(bytes>4096){send(413,{error:'Report too large.'});return true;}chunks.push(chunk);}
   const result=this.ingest(JSON.parse(Buffer.concat(chunks).toString()),req.socket.remoteAddress||'unknown');send(result.status,result);
  }catch{send(400,{error:'Invalid report.'});}
  return true;
 }
 close(){this.db?.close();}
}
