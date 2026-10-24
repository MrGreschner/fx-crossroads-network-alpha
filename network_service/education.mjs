import {allowedOrigin} from './origins.mjs';
import {createBusinessAcademy,businessCatalog} from './business-academy.mjs';
import {randomBytes,createHash} from 'node:crypto';
import {readFileSync} from 'node:fs';
const uid=()=>randomBytes(16).toString('hex'),hash=x=>createHash('sha256').update(x).digest('hex');
const modules=JSON.parse(readFileSync(new URL('../content/studio/learning-modules.json',import.meta.url))).modules;
const fail=(status,message)=>{throw Object.assign(Error(message),{status})};
const text=(v,max=120)=>typeof v==='string'?v.trim().slice(0,max):'';
const id=v=>typeof v==='string'&&/^[a-f0-9]{32}$/.test(v);
export const educationSchema=`
CREATE TABLE IF NOT EXISTS crossroads_schools(id text PRIMARY KEY,name text NOT NULL,created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS crossroads_teacher_students(teacher text NOT NULL REFERENCES crossroads_accounts(id),student text NOT NULL REFERENCES crossroads_accounts(id),PRIMARY KEY(teacher,student));
CREATE TABLE IF NOT EXISTS crossroads_classes(id text PRIMARY KEY,teacher text NOT NULL REFERENCES crossroads_accounts(id),name text NOT NULL,archived boolean NOT NULL DEFAULT false,created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS crossroads_class_students(class_id text NOT NULL REFERENCES crossroads_classes(id),student text NOT NULL REFERENCES crossroads_accounts(id),PRIMARY KEY(class_id,student));
CREATE TABLE IF NOT EXISTS crossroads_assignments(id text PRIMARY KEY,teacher text NOT NULL REFERENCES crossroads_accounts(id),class_id text REFERENCES crossroads_classes(id),module text NOT NULL,title text NOT NULL,instructions text NOT NULL DEFAULT '',points numeric NOT NULL DEFAULT 100,due_at timestamptz,archived boolean NOT NULL DEFAULT false,created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS crossroads_education_progress(student text PRIMARY KEY REFERENCES crossroads_accounts(id),summary jsonb NOT NULL DEFAULT '{}',updated_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS crossroads_submissions(id text PRIMARY KEY,student text NOT NULL REFERENCES crossroads_accounts(id),source_id text NOT NULL,assignment_id text REFERENCES crossroads_assignments(id),module text NOT NULL,payload jsonb NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),UNIQUE(student,source_id));
CREATE TABLE IF NOT EXISTS crossroads_grades(submission text NOT NULL REFERENCES crossroads_submissions(id),teacher text NOT NULL REFERENCES crossroads_accounts(id),score numeric,feedback text NOT NULL DEFAULT '',status text NOT NULL DEFAULT 'draft',ratings jsonb NOT NULL DEFAULT '{}',revision integer NOT NULL DEFAULT 1,updated_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(submission,teacher));
CREATE TABLE IF NOT EXISTS crossroads_grade_history(submission text NOT NULL REFERENCES crossroads_submissions(id),teacher text NOT NULL REFERENCES crossroads_accounts(id),revision integer NOT NULL,score numeric,feedback text NOT NULL,status text NOT NULL,ratings jsonb NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(submission,teacher,revision));
CREATE TABLE IF NOT EXISTS crossroads_education_sessions(token text PRIMARY KEY,account text NOT NULL REFERENCES crossroads_accounts(id),parent_token text NOT NULL,expires_at timestamptz NOT NULL);
CREATE INDEX IF NOT EXISTS crossroads_submissions_student ON crossroads_submissions(student,created_at);
CREATE INDEX IF NOT EXISTS crossroads_assignments_teacher ON crossroads_assignments(teacher);
CREATE INDEX IF NOT EXISTS crossroads_teacher_students_student ON crossroads_teacher_students(student);
`;
function send(res,status,data,headers={}){res.writeHead(status,{'content-type':'application/json','cache-control':'no-store','x-content-type-options':'nosniff',...headers});res.end(JSON.stringify(data));}
async function body(req){let size=0;const chunks=[],timer=setTimeout(()=>req.destroy(),15000);timer.unref();try{for await(const c of req){size+=c.length;if(size>12582912)fail(413,'Portfolio is too large. Export a backup and submit a smaller set of frozen work.');chunks.push(c);}try{return JSON.parse(Buffer.concat(chunks));}catch{fail(400,'Invalid request.')}}finally{clearTimeout(timer);}}
const cookie=(value,req,maxAge=14400)=>`crossroads_education=${value}; Path=/education; HttpOnly; SameSite=Strict; Max-Age=${maxAge}${process.env.FX_LOCAL_TEST==='1'?'':'; Secure'}`;
export function createEducation({pool,accounts,admin=()=>false,now=()=>Date.now()}={}){
 const business=createBusinessAcademy({pool,assignmentFor,ownClass,studentFor});
 let ready=false,retryAt=0;const handoffs=new Map(),rates=new Map();
 const initialize=async()=>{await accounts.initialized;if(!pool)return;try{await pool.query(educationSchema);await business.initialize();ready=true;}catch{ready=false;}retryAt=now()+30000;};const initialized=initialize();
 async function actor(req){
  let a=await accounts.authenticate(req);if(a)return a;
  const raw=/(?:^|;\s*)crossroads_education=([a-f0-9]{64})(?:;|$)/.exec(req.headers.cookie||'')?.[1];if(!raw)return null;
  const q=await pool.query(`SELECT a.* FROM crossroads_education_sessions e JOIN crossroads_accounts a ON a.id=e.account JOIN crossroads_sessions s ON s.token=e.parent_token AND s.account=a.id WHERE e.token=$1 AND e.expires_at>now() AND s.expires_at>now() AND NOT a.disabled`,[hash(raw)]);return q.rows[0]||null;
 }
 async function teacher(req){const a=await actor(req);if(!a)fail(401,'Sign in to your teacher account.');if(a.role!=='teacher')fail(403,'Teacher access required.');return a;}
 const linkedSQL=`EXISTS(SELECT 1 FROM crossroads_teacher_students l JOIN crossroads_accounts t ON t.id=l.teacher JOIN crossroads_accounts a ON a.id=l.student WHERE l.teacher=$1 AND l.student=s.student AND t.role='teacher' AND a.role='student' AND NOT a.disabled AND a.school_id IS NOT DISTINCT FROM t.school_id)`;
 async function studentFor(t,student){const q=await pool.query(`SELECT a.id FROM crossroads_teacher_students l JOIN crossroads_accounts a ON a.id=l.student WHERE l.teacher=$1 AND a.id=$2 AND a.role='student' AND NOT a.disabled AND a.school_id IS NOT DISTINCT FROM $3`,[t.id,student,t.school_id]);if(!q.rows.length)fail(403,'Student is not assigned to this teacher and school.');}
 async function ownClass(t,classID){if(!classID)return null;const q=await pool.query('SELECT * FROM crossroads_classes WHERE id=$1 AND teacher=$2',[classID,t.id]);if(!q.rows.length)fail(403,'Class not found in your workspace.');return q.rows[0];}
 async function assignmentFor(a,assignmentID){if(!assignmentID)return null;const q=await pool.query(`SELECT x.* FROM crossroads_assignments x JOIN crossroads_teacher_students l ON l.teacher=x.teacher AND l.student=$2 JOIN crossroads_accounts t ON t.id=x.teacher WHERE x.id=$1 AND NOT x.archived AND t.role='teacher' AND NOT t.disabled AND t.school_id IS NOT DISTINCT FROM $3 AND (x.class_id IS NULL OR EXISTS(SELECT 1 FROM crossroads_class_students m WHERE m.class_id=x.class_id AND m.student=$2))`,[assignmentID,a.id,a.school_id]);if(!q.rows.length)fail(403,'Assignment is not available to this student.');return q.rows[0];}
 async function handle(req,res){
  const url=new URL(req.url,'http://localhost'),path=url.pathname,isAdmin=path==='/accounts'||path.startsWith('/accounts/education-')||path.startsWith('/accounts/admin/education');
  if(!isAdmin&&!path.startsWith('/education/'))return false;
  try{
   const origin=req.headers.origin||'';
   if(isAdmin){if(!admin(req)){send(res,401,{error:'Private administrator controls.'},{'www-authenticate':'Basic realm="Crossroads private reports"'});return true;}}
   const allowed=allowedOrigin(req,{admin:isAdmin});
   if(!allowed)fail(403,'Origin rejected.');if(origin&&!isAdmin){res.setHeader('access-control-allow-origin',origin);res.setHeader('vary','Origin');}
   if(req.method==='OPTIONS'){send(res,204,{}, {'access-control-allow-methods':'GET,POST','access-control-allow-headers':'content-type,authorization'});return true;}
   if(['/accounts','/accounts/education-admin.js','/education/teacher','/education/teacher.js','/education/teacher.css'].includes(path)){
    const name=path==='/accounts'?'education-admin.html':path.endsWith('education-admin.js')?'education-admin.js':path==='/education/teacher'?'teacher.html':path.endsWith('teacher.css')?'teacher.css':'teacher.js';
    res.writeHead(200,{'content-type':name.endsWith('.html')?'text/html; charset=utf-8':name.endsWith('.css')?'text/css':'text/javascript','cache-control':'no-store','x-content-type-options':'nosniff','referrer-policy':'no-referrer','content-security-policy':"default-src 'none'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'"});res.end(readFileSync(new URL('./'+name,import.meta.url)));return true;
   }
   await initialized;if(!ready&&pool&&now()>retryAt)await initialize();if(!ready)fail(503,'Classroom database unavailable. Your saved game is unchanged.');
   const k=req.socket.remoteAddress||'local';let rate=rates.get(k);if(!rate||now()-rate.at>60000){rate={at:now(),count:0};rates.set(k,rate);}if(++rate.count>600)fail(429,'Please wait a moment before refreshing.');if(rates.size>4096)rates.delete(rates.keys().next().value);
   if(req.method==='POST'&&req.headers['sec-fetch-site']==='cross-site'&&!req.headers.authorization)fail(403,'Open the teacher workspace directly.');
   if(isAdmin){
    if(path==='/accounts/admin/education'&&req.method==='GET'){
     const search=text(url.searchParams.get('search'),80),after=text(url.searchParams.get('after'),32);
     const q=await pool.query(`SELECT id,username,role,student_number,school_id,username_warning,disabled FROM crossroads_accounts WHERE (position(lower($1) in username_key)>0 OR student_number=$1 OR id=$1) AND ($2='' OR id>$2) ORDER BY id LIMIT 201`,[search,after]);
     const rows=[];for(const a of q.rows.slice(0,200)){const {student_number,...safe}=a;rows.push({...safe,school_code:await accounts.ensureNumber(a)});}
     const schools=await pool.query('SELECT id,name FROM crossroads_schools ORDER BY name');const teachers=await pool.query("SELECT id,username,school_id FROM crossroads_accounts WHERE role='teacher' AND NOT disabled ORDER BY username");const links=await pool.query('SELECT teacher,student FROM crossroads_teacher_students');send(res,200,{accounts:rows,next:q.rows.length>200?rows.at(-1).id:null,schools:schools.rows,teachers:teachers.rows,links:links.rows});return true;
    }
    if(req.method!=='POST')fail(405,'POST required.');const p=await body(req);
    if(path==='/accounts/admin/education-school'){const name=text(p.name,100);if(!name)fail(400,'Enter a school name.');const school=uid();await pool.query('INSERT INTO crossroads_schools(id,name) VALUES($1,$2)',[school,name]);send(res,200,{id:school});return true;}
    if(!id(p.id))fail(400,'Invalid account.');
    if(path==='/accounts/admin/education-account'){
     if(!['player','student','teacher'].includes(p.role))fail(400,'Choose a valid role.');if(p.school_id&&!id(p.school_id))fail(400,'Choose a school.');if(p.school_id&&!(await pool.query('SELECT id FROM crossroads_schools WHERE id=$1',[p.school_id])).rows.length)fail(400,'School not found.');
     // One statement changes identity and removes links that would cross a role/school boundary.
     await pool.query(`WITH changed AS (UPDATE crossroads_accounts SET role=$1,school_id=$2,updated_at=now() WHERE id=$3 AND (role IS DISTINCT FROM $1 OR school_id IS DISTINCT FROM $2) RETURNING id), removed AS (DELETE FROM crossroads_teacher_students WHERE (teacher=$3 OR student=$3) AND EXISTS(SELECT 1 FROM changed) RETURNING student) DELETE FROM crossroads_class_students WHERE (student=$3 OR class_id IN(SELECT id FROM crossroads_classes WHERE teacher=$3)) AND EXISTS(SELECT 1 FROM changed)`,[p.role,p.school_id||null,p.id]);
    }else if(path==='/accounts/admin/education-link'){
     const t=(await pool.query("SELECT * FROM crossroads_accounts WHERE id=$1 AND role='teacher' AND NOT disabled",[p.teacher])).rows[0];const a=(await pool.query("SELECT * FROM crossroads_accounts WHERE id=$1 AND role='student' AND NOT disabled",[p.id])).rows[0];if(!t||!a||t.school_id!==a.school_id)fail(400,'Choose a student and teacher in the same school.');
     if(p.remove){await pool.query('DELETE FROM crossroads_teacher_students WHERE teacher=$1 AND student=$2',[t.id,a.id]);await pool.query('DELETE FROM crossroads_class_students WHERE student=$1 AND class_id IN(SELECT id FROM crossroads_classes WHERE teacher=$2)',[a.id,t.id]);}
     else await pool.query('INSERT INTO crossroads_teacher_students(teacher,student) VALUES($1,$2) ON CONFLICT DO NOTHING',[t.id,a.id]);
    }else if(path==='/accounts/admin/education-warning'){
     if(p.confirm!==true)fail(400,'Confirm this username warning.');await pool.query('UPDATE crossroads_accounts SET username_warning=true WHERE id=$1',[p.id]);
    }else fail(404,'Not found.');
    await pool.query('INSERT INTO crossroads_account_audit(account,action) VALUES($1,$2)',[p.id,path.split('/').at(-1)]);send(res,200,{saved:true});return true;
   }
   if(path==='/education/exchange'&&req.method==='POST'){
    const p=await body(req),entry=handoffs.get(hash(String(p.code||'')));handoffs.delete(hash(String(p.code||'')));if(!entry||entry.until<now())fail(401,'This link has expired. Reopen Manage Class Pro from the game.');
    const a=await accounts.authenticate({headers:{authorization:'Bearer '+entry.parent}});if(!a||a.role!=='teacher')fail(403,'Teacher access is no longer active.');const raw=randomBytes(32).toString('hex');await pool.query('INSERT INTO crossroads_education_sessions(token,account,parent_token,expires_at) VALUES($1,$2,$3,to_timestamp($4))',[hash(raw),a.id,hash(entry.parent),now()/1000+14400]);send(res,200,{signed_in:true},{'set-cookie':cookie(raw,req)});return true;
   }
   const a=await actor(req);if(!a)fail(401,'Sign in to continue.');
   if(path.startsWith('/education/business/')){const result=await business.response(path.slice('/education/business/'.length),req.method,a,req.method==='POST'?await body(req):{},url);send(res,200,result);return true;}
   if(path==='/education/logout'&&req.method==='POST'){const raw=/(?:^|;\s*)crossroads_education=([a-f0-9]{64})/.exec(req.headers.cookie||'')?.[1];if(raw)await pool.query('DELETE FROM crossroads_education_sessions WHERE token=$1',[hash(raw)]);send(res,200,{signed_out:true},{'set-cookie':cookie('',req,0)});return true;}
   if(path==='/education/handoff'&&req.method==='POST'){
    if(a.role!=='teacher')fail(403,'Teacher access required.');const payload=await body(req),view=['Overview','Students','Assignments','Submissions','Gradebook','Learning Academy'].includes(payload.view)?payload.view:'Overview';const code=randomBytes(32).toString('hex');for(const [k,v]of handoffs)if(v.until<now())handoffs.delete(k);if(handoffs.size>1000)fail(429,'Please retry shortly.');handoffs.set(hash(code),{parent:(req.headers.authorization||'').replace(/^Bearer /,''),until:now()+60000});send(res,200,{url:'/education/teacher?view='+view+'#'+code});return true;
   }
   if(path==='/education/student'&&req.method==='GET'){
    if(a.role!=='student')fail(403,'Student access required.');const q=await pool.query(`SELECT x.*,t.username teacher_name FROM crossroads_assignments x JOIN crossroads_teacher_students l ON l.teacher=x.teacher JOIN crossroads_accounts t ON t.id=x.teacher WHERE l.student=$1 AND t.role='teacher' AND NOT t.disabled AND t.school_id IS NOT DISTINCT FROM $2 AND NOT x.archived AND NOT EXISTS(SELECT 1 FROM crossroads_business_assignments ba WHERE ba.assignment_id=x.id) AND (x.class_id IS NULL OR EXISTS(SELECT 1 FROM crossroads_class_students m WHERE m.class_id=x.class_id AND m.student=$1)) ORDER BY x.due_at NULLS LAST,x.created_at DESC`,[a.id,a.school_id]);const g=await pool.query(`SELECT s.id,s.source_id,s.module,s.assignment_id,g.score,g.feedback,g.ratings,g.updated_at FROM crossroads_submissions s JOIN crossroads_grades g ON g.submission=s.id JOIN crossroads_teacher_students l ON l.teacher=g.teacher AND l.student=s.student JOIN crossroads_accounts t ON t.id=g.teacher WHERE s.student=$1 AND g.status='returned' AND t.role='teacher' AND NOT t.disabled AND t.school_id IS NOT DISTINCT FROM $2`,[a.id,a.school_id]);send(res,200,{assignments:q.rows,feedback:g.rows});return true;
   }
   if(path==='/education/portfolio'&&req.method==='POST'){
    if(a.role!=='student')fail(403,'Student access required.');const p=await body(req),d=p.portfolio;if(!d||d.format!=='fx-crossroads-learning'||d.version!==1||!d.work||!d.artifacts||!Array.isArray(d.submissions)||d.submissions.length>96)fail(400,'Invalid learning portfolio.');
    const links=(await pool.query(`SELECT t.id FROM crossroads_teacher_students l JOIN crossroads_accounts t ON t.id=l.teacher WHERE l.student=$1 AND t.role='teacher' AND NOT t.disabled AND t.school_id IS NOT DISTINCT FROM $2`,[a.id,a.school_id])).rows;if(!links.length)fail(409,'Your administrator has not assigned a teacher yet. Work remains saved on this device.');
    const summary={modules:Object.entries(d.work).slice(0,100).map(([module,w])=>({module,entries:Array.isArray(w.entries)?w.entries.length:0})).filter(x=>modules[x.module]),submissions:d.submissions.length};await pool.query('INSERT INTO crossroads_education_progress(student,summary) VALUES($1,$2::jsonb) ON CONFLICT(student) DO UPDATE SET summary=EXCLUDED.summary,updated_at=now()',[a.id,JSON.stringify(summary)]);
    let saved=0;for(const sub of d.submissions){if(!sub||typeof sub.id!=='string'||sub.id.length>100||!modules[sub.module]||!Array.isArray(sub.entries)||sub.entries.length>60||!Array.isArray(sub.refs)||sub.refs.length>16)fail(400,'Invalid frozen submission.');
     const sourceKey=(id(d.learner_id)?d.learner_id+':':'')+sub.id;const assignment=p.source_id===sub.id?p.assignment_id:null;const assigned=await assignmentFor(a,assignment);if(assigned&&(await pool.query('SELECT assignment_id FROM crossroads_business_assignments WHERE assignment_id=$1',[assigned.id])).rows.length)fail(400,'Use Learning Academy to submit this course assignment.');if(assigned&&assigned.module!==sub.module)fail(400,'Choose an assignment for this module.');
     const frozen={id:sub.id,module:sub.module,entries:sub.entries,refs:sub.refs,artifacts:{},digest:text(sub.digest,64),submitted:text(sub.time,50)};
     for(const ref of sub.refs){const artifact=d.artifacts[ref];if(!artifact||typeof ref!=='string')fail(400,'Missing frozen artifact.');frozen.artifacts[ref]=artifact;}
     const q=await pool.query('INSERT INTO crossroads_submissions(id,student,source_id,assignment_id,module,payload) VALUES($1,$2,$3,$4,$5,$6::jsonb) ON CONFLICT(student,source_id) DO NOTHING RETURNING id',[uid(),a.id,sourceKey,assignment||null,sub.module,JSON.stringify(frozen)]);saved+=q.rows.length;
     if(assignment)await pool.query('UPDATE crossroads_submissions SET assignment_id=$1 WHERE student=$2 AND source_id=$3 AND assignment_id IS NULL',[assignment,a.id,sourceKey]);
    }send(res,200,{saved,progress_saved:true});return true;
   }
   const t=await teacher(req);
   if(path==='/education/workspace'&&req.method==='GET'){
    const students=await pool.query(`SELECT a.id,a.username,a.student_number,p.summary,p.updated_at FROM crossroads_teacher_students l JOIN crossroads_accounts a ON a.id=l.student LEFT JOIN crossroads_education_progress p ON p.student=a.id WHERE l.teacher=$1 AND a.role='student' AND NOT a.disabled AND a.school_id IS NOT DISTINCT FROM $2 ORDER BY a.username`,[t.id,t.school_id]);
    const classes=await pool.query('SELECT * FROM crossroads_classes WHERE teacher=$1 ORDER BY archived,name',[t.id]);const memberships=await pool.query('SELECT m.* FROM crossroads_class_students m JOIN crossroads_classes c ON c.id=m.class_id WHERE c.teacher=$1',[t.id]);const assignments=await pool.query('SELECT * FROM crossroads_assignments WHERE teacher=$1 ORDER BY created_at DESC',[t.id]);
    const submissions=await pool.query(`SELECT s.id,s.student,s.source_id,s.assignment_id,s.module,s.created_at,a.username,g.score,g.feedback,g.status,g.revision,g.ratings FROM crossroads_submissions s JOIN crossroads_accounts a ON a.id=s.student LEFT JOIN crossroads_grades g ON g.submission=s.id AND g.teacher=$1 WHERE ${linkedSQL} AND (s.assignment_id IS NULL OR s.assignment_id IN(SELECT id FROM crossroads_assignments WHERE teacher=$1)) ORDER BY s.created_at DESC,s.id DESC LIMIT 2001`,[t.id]);
    send(res,200,{teacher:{id:t.id,username:t.username,school_id:t.school_id},students:students.rows,classes:classes.rows,memberships:memberships.rows,assignments:assignments.rows,submissions:submissions.rows.slice(0,2000),limited:submissions.rows.length>2000,next_cursor:submissions.rows.length>2000?Buffer.from(JSON.stringify([submissions.rows[1999].created_at,submissions.rows[1999].id])).toString('base64url'):null,modules:[...Object.entries(modules).map(([code,m])=>({code,name:m.name,outcomes:m.outcomes,legacy:!businessCatalog.modules.some(m=>m.code===code)})),...businessCatalog.modules.filter(m=>!modules[m.code]).map(m=>({code:m.code,name:m.name,outcomes:m.outcomes,legacy:false}))]});return true;
   }
   if(path==='/education/history'&&req.method==='GET'){
    let cursor;try{cursor=JSON.parse(Buffer.from(String(url.searchParams.get('cursor')||''),'base64url').toString());}catch{fail(400,'Invalid history page.');}
    if(!Array.isArray(cursor)||cursor.length!==2||!Number.isFinite(Date.parse(cursor[0]))||!id(cursor[1]))fail(400,'Invalid history page.');
    const q=await pool.query(`SELECT s.id,s.student,s.source_id,s.assignment_id,s.module,s.created_at,a.username,g.score,g.feedback,g.status,g.revision,g.ratings FROM crossroads_submissions s JOIN crossroads_accounts a ON a.id=s.student LEFT JOIN crossroads_grades g ON g.submission=s.id AND g.teacher=$1 WHERE ${linkedSQL} AND (s.assignment_id IS NULL OR s.assignment_id IN(SELECT id FROM crossroads_assignments WHERE teacher=$1)) AND (s.created_at,s.id)<($2::timestamptz,$3::text) ORDER BY s.created_at DESC,s.id DESC LIMIT 2001`,[t.id,cursor[0],cursor[1]]);
    const rows=q.rows.slice(0,2000);send(res,200,{submissions:rows,next_cursor:q.rows.length>2000?Buffer.from(JSON.stringify([rows.at(-1).created_at,rows.at(-1).id])).toString('base64url'):null});return true;
   }
   if(path==='/education/submission'&&req.method==='GET'){
    const q=await pool.query(`SELECT s.* FROM crossroads_submissions s WHERE s.id=$2 AND ${linkedSQL} AND (s.assignment_id IS NULL OR s.assignment_id IN(SELECT id FROM crossroads_assignments WHERE teacher=$1))`,[t.id,url.searchParams.get('id')]);if(!q.rows.length)fail(404,'Submission not available.');send(res,200,{submission:q.rows[0]});return true;
   }
   if(req.method!=='POST')fail(405,'POST required.');const p=await body(req);
   if(path==='/education/class'){
    const name=text(p.name,80);if(!name)fail(400,'Enter a class name.');if(p.id){await ownClass(t,p.id);await pool.query('UPDATE crossroads_classes SET name=$1,archived=$2 WHERE id=$3',[name,!!p.archived,p.id]);}else await pool.query('INSERT INTO crossroads_classes(id,teacher,name) VALUES($1,$2,$3)',[uid(),t.id,name]);
   }else if(path==='/education/membership'){
    await studentFor(t,p.student);const c=await ownClass(t,p.class_id);if(!c||c.archived)fail(400,'Choose an active class.');if(p.remove)await pool.query('DELETE FROM crossroads_class_students WHERE class_id=$1 AND student=$2',[c.id,p.student]);else await pool.query('INSERT INTO crossroads_class_students(class_id,student) VALUES($1,$2) ON CONFLICT DO NOTHING',[c.id,p.student]);
   }else if(path==='/education/assignment'){
    const title=text(p.title,140);const courseEdit=p.id&&(await pool.query('SELECT ba.assignment_id FROM crossroads_business_assignments ba JOIN crossroads_assignments x ON x.id=ba.assignment_id WHERE x.id=$1 AND x.teacher=$2 AND x.module=$3',[p.id,t.id,p.module])).rows.length;if(!title||(!modules[p.module]&&!courseEdit)||!Number.isFinite(p.points)||p.points<=0||p.points>1000)fail(400,'Enter a title, module and points between 1 and 1,000.');await ownClass(t,p.class_id);if(p.due_at&&!Number.isFinite(Date.parse(p.due_at)))fail(400,'Enter a valid due date.');
    if(p.id){const q=await pool.query('UPDATE crossroads_assignments SET title=$1,instructions=$2,due_at=$3,archived=$4 WHERE id=$5 AND teacher=$6 RETURNING id',[title,text(p.instructions,6000),p.due_at||null,!!p.archived,p.id,t.id]);if(!q.rows.length)fail(404,'Assignment not found.');}
    else await pool.query('INSERT INTO crossroads_assignments(id,teacher,class_id,module,title,instructions,points,due_at) VALUES($1,$2,$3,$4,$5,$6,$7,$8)',[uid(),t.id,p.class_id||null,p.module,title,text(p.instructions,6000),p.points,p.due_at||null]);
   }else if(path==='/education/grade'){
    const q=await pool.query(`SELECT s.*,x.points FROM crossroads_submissions s LEFT JOIN crossroads_assignments x ON x.id=s.assignment_id WHERE s.id=$2 AND ${linkedSQL} AND (s.assignment_id IS NULL OR s.assignment_id IN(SELECT id FROM crossroads_assignments WHERE teacher=$1))`,[t.id,p.submission]);if(!q.rows.length)fail(404,'Submission not available.');if(q.rows[0].payload?.business)fail(409,'Use the Learning Academy review controls for this submission.');const max=Number(q.rows[0].points||100);if(p.score!==null&&(!Number.isFinite(p.score)||p.score<0||p.score>max))fail(400,'Enter a valid mark within the assignment points.');if(!['draft','returned'].includes(p.status)||p.status==='returned'&&p.score===null)fail(400,'Add a mark before returning work.');if(!Number.isInteger(p.revision)||p.revision<0)fail(400,'Refresh this submission.');
    const ratings=p.ratings||{};if(typeof ratings!=='object'||Array.isArray(ratings)||Object.keys(ratings).length>40)fail(400,'Invalid outcome ratings.');
    for(const [key,value]of Object.entries(ratings)){if(!modules[q.rows[0].module].outcomes.some(o=>o.id===key)||!['Not assessed','More evidence needed','Developing','Meets','Extends'].includes(value?.rating))fail(400,'Invalid outcome rating.');ratings[key]={rating:value.rating,feedback:text(value.feedback,1500),score:-1};}
    const result=await pool.query(`WITH changed AS (INSERT INTO crossroads_grades(submission,teacher,score,feedback,status,ratings,revision) SELECT $1,$2,$3,$4,$5,$6::jsonb,1 WHERE $7=0 OR EXISTS(SELECT 1 FROM crossroads_grades WHERE submission=$1 AND teacher=$2) ON CONFLICT(submission,teacher) DO UPDATE SET score=EXCLUDED.score,feedback=EXCLUDED.feedback,status=EXCLUDED.status,ratings=EXCLUDED.ratings,revision=crossroads_grades.revision+1,updated_at=now() WHERE crossroads_grades.revision=$7 RETURNING *) INSERT INTO crossroads_grade_history(submission,teacher,revision,score,feedback,status,ratings) SELECT submission,teacher,revision,score,feedback,status,ratings FROM changed RETURNING revision`,[p.submission,t.id,p.score,text(p.feedback,6000),p.status,JSON.stringify(ratings),p.revision]);if(!result.rows.length)fail(409,'Another review changed this grade. Refresh before saving.');
    await pool.query('INSERT INTO crossroads_account_audit(account,action) VALUES($1,$2)',[t.id,'grade:'+p.submission+':'+p.status]);
   }else fail(404,'Not found.');send(res,200,{saved:true});return true;
  }catch(e){if(!res.headersSent)send(res,e.status||503,{error:e.status?e.message:'Classroom service unavailable. Please retry; existing work is retained.'});req.resume();return true;}
 }
 return {handle,initialized,status:()=>({configured:!!pool,ready,business_edition:businessCatalog.edition,core_modules:9,optional_modules:4,academy_modules:businessCatalog.modules.length,studio_modules:10})};
}
