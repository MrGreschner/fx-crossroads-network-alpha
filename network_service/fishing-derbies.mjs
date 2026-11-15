import {readFileSync} from 'node:fs';
import {readFile} from 'node:fs/promises';
import {randomUUID} from 'node:crypto';

const {fish,pools}=JSON.parse(readFileSync(new URL('../content/fishing.json',import.meta.url)));
const regions={town:'Crossroads Town',wayfarer:'Wayfarer Wilds',silverfall:'Silverfall',folded_coast:'Folded Coast',lantern_marsh:'Lantern Marsh',defense:'North Gate',moonveil:'Moonveil',between_remote:'Between',voyage_lake:'Oldwater Lake',voyage_coast:'Ocean voyages',descent36:'Cave Descent Floor 36',descent38:'Cave Descent Floor 38',descent56:'Cave Descent Floor 56',descent57:'Cave Descent Floor 57'};
const regionFor=pool=>pool==='voyage_night_crater'?'night_island':pools[pool]?.region;
const areaNames={...regions,night_island:'Night Island'};
const schema=`
CREATE TABLE IF NOT EXISTS crossroads_fishing_derbies (
 id text PRIMARY KEY, title text NOT NULL, location text NOT NULL, species text NOT NULL,
 starts timestamptz NOT NULL, ends timestamptz NOT NULL, published boolean NOT NULL,
 CHECK (ends > starts));
CREATE TABLE IF NOT EXISTS crossroads_fishing_derby_entries (
 derby text NOT NULL REFERENCES crossroads_fishing_derbies(id), owner text NOT NULL,
 username text NOT NULL, catch_id text NOT NULL, species text NOT NULL, kg float8 NOT NULL,
 landed timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(derby,owner));
`;
const options={locations:[
 ...Object.entries(areaNames).map(([id,name])=>({id:'area:'+id,name})),
 ...Object.entries(pools).map(([id,p])=>({id:'pool:'+id,name:p.name}))
],species:Object.entries(fish).map(([id,f])=>({id,name:f.name}))};
function send(res,status,data){
 res.writeHead(status,{'content-type':'application/json','cache-control':'no-store','x-content-type-options':'nosniff'});
 res.end(JSON.stringify(data));
}
async function body(req){
 let size=0;const chunks=[];
 const timer=setTimeout(()=>req.destroy(),5000);
 try{
  for await(const chunk of req){size+=chunk.length;if(size>8192)throw Error('Request too large');chunks.push(chunk);}
  const data=JSON.parse(Buffer.concat(chunks));if(!data||typeof data!=='object'||Array.isArray(data))throw Error('Invalid request');
  return data;
 }finally{clearTimeout(timer);}
}
function definition(input){
 const {title,location='',species='',starts,ends,published}=input;
 if(typeof title!=='string'||!title.trim()||title.length>80)throw Error('Enter a title of 1–80 characters.');
 if(location&&!options.locations.some(x=>x.id===location))throw Error('Choose a fishing location.');
 if(species&&!Object.hasOwn(fish,species))throw Error('Choose a fish species.');
 if(!location&&!species)throw Error('Choose a location, a species, or both.');
 if(typeof starts!=='string'||typeof ends!=='string'||!starts.endsWith('Z')||!ends.endsWith('Z')||
 !Number.isFinite(Date.parse(starts))||!Number.isFinite(Date.parse(ends))||Date.parse(ends)<=Date.parse(starts)||Date.parse(ends)<=Date.now())throw Error('Choose a start and a future end after it.');
 if(!Object.keys(pools).some(p=>(!location||location==='pool:'+p||location==='area:'+regionFor(p))&&(!species||pools[p].fish.includes(species))))throw Error('That species cannot be caught at that location.');
 return [title.trim(),location,species,starts,ends,published===true];
}
export function createFishingDerbies({pool,admin,accounts}){
 let ready=false;
 if(pool)pool.query(schema).then(()=>{ready=true;}).catch(()=>console.error('Fishing derby schema unavailable'));
 async function handle(req,res){
  const url=new URL(req.url,'http://localhost');
  const path=url.pathname;
  const privateRoute=path==='/admin/derbies'||path.startsWith('/admin/derbies/');
  if(!privateRoute&&path!=='/fishing-derbies'&&path!=='/fishing-derbies/entry')return false;
  const origin=req.headers.origin||'';
  if(privateRoute){
   if(!admin(req)){res.setHeader('www-authenticate','Basic realm="Crossroads administration"');send(res,401,{error:'Administrator sign-in required.'});req.resume();return true;}
   if(req.method==='POST'&&(!origin||new URL(origin).host!==req.headers.host||req.headers['sec-fetch-site']==='cross-site')){send(res,403,{error:'Open the derby editor from the admin dashboard.'});req.resume();return true;}
  }else{
   if(origin&&!/^https:\/\/([a-z0-9-]+\.)*(itch\.io|itch\.zone)$/.test(origin)&&!(process.env.REPORT_ALLOWED_ORIGIN||'').split(',').includes(origin)){send(res,403,{error:'Origin rejected.'});req.resume();return true;}
   if(origin){res.setHeader('access-control-allow-origin',origin);res.setHeader('vary','Origin');}
   if(req.method==='OPTIONS'){res.writeHead(204,{'access-control-allow-methods':'GET,POST','access-control-allow-headers':'content-type,authorization'});res.end();return true;}
  }
  try{
   if(privateRoute&&req.method==='GET'&&(path==='/admin/derbies'||path==='/admin/derbies/editor.js')){
    const js=path.endsWith('.js');
    res.writeHead(200,{'content-type':js?'text/javascript; charset=utf-8':'text/html; charset=utf-8','cache-control':'no-store','x-content-type-options':'nosniff','content-security-policy':"default-src 'none'; script-src 'self'; style-src 'self'; connect-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'"});
    res.end(await readFile(new URL(js?'./derbies-editor.js':'./derbies-editor.html',import.meta.url)));return true;
   }
   if(!ready){send(res,503,{error:'Fishing derby database unavailable.'});return true;}
   if(privateRoute&&path==='/admin/derbies/api'&&req.method==='GET'){
    const {rows}=await pool.query('SELECT * FROM crossroads_fishing_derbies ORDER BY starts DESC LIMIT 100');
    send(res,200,{...options,events:rows});return true;
   }
   if(privateRoute&&path==='/admin/derbies/api'&&req.method==='POST'){
    let input,values;try{input=await body(req);values=definition(input);}catch(e){send(res,400,{error:e.message});return true;}
    if(input.id){
     const result=await pool.query('UPDATE crossroads_fishing_derbies SET title=$2,location=$3,species=$4,starts=$5,ends=$6,published=$7 WHERE id=$1 AND NOT published RETURNING id',[input.id,...values]);
     if(!result.rowCount){send(res,409,{error:'Only drafts can be edited or published.'});return true;}
    }else await pool.query('INSERT INTO crossroads_fishing_derbies(id,title,location,species,starts,ends,published) VALUES($1,$2,$3,$4,$5,$6,$7)',[randomUUID(),...values]);
    send(res,200,{saved:true});return true;
   }
   if(path==='/fishing-derbies'&&req.method==='GET'){
    const {rows}=await pool.query(`SELECT d.id,d.title,d.location,d.species,d.starts,d.ends,
      CASE WHEN d.ends<=now() THEN 'Finished' WHEN d.starts>now() THEN 'Scheduled' ELSE 'Open' END state,
      COALESCE((SELECT jsonb_agg(t ORDER BY t.place) FROM
       (SELECT row_number() OVER (ORDER BY kg DESC,landed,owner)::int place,username,species,kg
        FROM crossroads_fishing_derby_entries WHERE derby=d.id ORDER BY kg DESC,landed,owner LIMIT 10) t),'[]') standings
      FROM crossroads_fishing_derbies d WHERE d.published ORDER BY (d.ends>now()) DESC,d.starts DESC LIMIT 25`);
    send(res,200,{events:rows.map(d=>({...d,location:options.locations.find(x=>x.id===d.location)?.name||'Any location'}))});return true;
   }
   if(path==='/fishing-derbies/entry'&&req.method==='POST'){
    if(!req.headers.authorization){send(res,401,{error:'Sign in to enter.'});req.resume();return true;}
    const account=await accounts.authenticate(req);
    if(!account){send(res,401,{error:'Sign in to enter.'});req.resume();return true;}
    let entry;try{entry=await body(req);}catch{send(res,400,{error:'Invalid catch.'});return true;}
    const {id,pool:spot,species,kg}=entry;
    if(typeof id!=='string'||!/^[0-9]+-[0-9]+$/.test(id)||id.length>60||!Object.hasOwn(pools,spot)||!pools[spot].fish.includes(species)||
    typeof kg!=='number'||!Number.isFinite(kg)||kg<=0||kg>fish[species].max_kg*4+.01){send(res,400,{error:'Invalid catch.'});return true;}
    const {rowCount}=await pool.query(`INSERT INTO crossroads_fishing_derby_entries(derby,owner,username,catch_id,species,kg)
     SELECT id,$1,$2,$3,$4,$5 FROM crossroads_fishing_derbies WHERE published AND starts<=now() AND ends>now()
      AND (species='' OR species=$4) AND (location='' OR location=$6 OR location=$7)
     ON CONFLICT(derby,owner) DO UPDATE SET username=EXCLUDED.username,catch_id=EXCLUDED.catch_id,
       species=EXCLUDED.species,kg=EXCLUDED.kg,landed=EXCLUDED.landed
      WHERE EXCLUDED.kg>crossroads_fishing_derby_entries.kg AND EXCLUDED.catch_id<>crossroads_fishing_derby_entries.catch_id`,
     [account.id,account.username,id,species,kg,'pool:'+spot,'area:'+regionFor(spot)]);
    send(res,200,{entries:rowCount});return true;
   }
   send(res,404,{error:'Not found.'});
  }catch(e){console.error('Fishing derby request failed:',e.message);if(!res.headersSent)send(res,503,{error:'Fishing derbies are temporarily unavailable.'});}
  return true;
 }
 return {handle};
}
