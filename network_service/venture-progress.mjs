// Account-linked, append-only classroom evidence. Simulation outcomes are client-reported,
// not an anti-cheat attestation and never automatic marks or public rewards.
export const progressSchema=`
CREATE TABLE IF NOT EXISTS crossroads_venture_days(student text NOT NULL,teacher text NOT NULL,business text NOT NULL,epoch integer NOT NULL,day integer NOT NULL,report jsonb NOT NULL,first_seen timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(student,teacher,business,epoch,day));
CREATE TABLE IF NOT EXISTS crossroads_venture_checkpoints(attempt text NOT NULL REFERENCES crossroads_business_attempts(id),phase text NOT NULL,snapshot jsonb NOT NULL,created_at timestamptz NOT NULL DEFAULT now(),PRIMARY KEY(attempt,phase));
CREATE INDEX IF NOT EXISTS crossroads_venture_days_owner ON crossroads_venture_days(teacher,student);`;
const number=v=>Number.isFinite(Number(v))?Number(v):0;
export function districtSummary(state){
 const businesses=Object.entries(state?.businesses||{}).map(([id,b])=>({id,name:b.name,cash:number(b.cash),day:number(b.day)+1,completed_days:number(b.summary?.full_days),profitable_days:number(b.summary?.profitable_days),streak:number(b.summary?.streak),profit:number(b.summary?.profit),spoilage:number(b.summary?.spoilage_cost),employees:b.employees?.length||0,loan:number(b.loan),open:!!b.open,failed:!!b.failed,reputation:number(b.reputation),decisions:(b.decisions||[]).slice(-20),history:(b.history||[]).slice(-24)}));
 return {reserve:number(state?.reserve),periods:number(state?.periods),businesses,owned:businesses.length,cash:businesses.reduce((s,b)=>s+b.cash,0),employees:businesses.reduce((s,b)=>s+b.employees,0),full_days:businesses.reduce((s,b)=>s+b.completed_days,0),profitable_days:businesses.reduce((s,b)=>s+b.profitable_days,0),profit:businesses.reduce((s,b)=>s+b.profit,0),spoilage:businesses.reduce((s,b)=>s+b.spoilage,0)};
}
export async function recordDays(tx,student,teacher,state){
 const rows=[];for(const [business,b]of Object.entries(state?.businesses||{}))for(const h of b.history||[]){
  if(h.full_day!==true||!Number.isInteger(h.day)||h.day<1||h.day>number(b.day)||number(h.seconds)<179.8)continue;
  const epoch=number(b.reset_epoch);if(!Number.isInteger(epoch)||epoch<0||epoch>1e6)continue;
  rows.push({business,epoch,day:h.day,report:h});
 }
 if(rows.length)await tx.query('INSERT INTO crossroads_venture_days(student,teacher,business,epoch,day,report) SELECT $1,$2,r.business,r.epoch,r.day,r.report FROM jsonb_to_recordset($3::jsonb) AS r(business text,epoch integer,day integer,report jsonb) ON CONFLICT DO NOTHING',[student,teacher,JSON.stringify(rows)]);
}
async function tallies(tx,b){return Object.fromEntries((await tx.query('SELECT business,count(*)::int total FROM crossroads_venture_days WHERE student=$1 AND teacher=$2 GROUP BY business',[b.student,b.teacher])).rows.map(r=>[r.business,Number(r.total)]));}
export async function beginProject(tx,b,state){
 await recordDays(tx,b.student,b.teacher,state);
 await tx.query("INSERT INTO crossroads_venture_checkpoints(attempt,phase,snapshot) VALUES($1,'begin',$2::jsonb) ON CONFLICT DO NOTHING",[b.id,JSON.stringify({totals:await tallies(tx,b),district:districtSummary(state),district_revision:0})]);
}
export async function projectProgress(tx,b){
 const checkpoints=(await tx.query('SELECT phase,snapshot,created_at FROM crossroads_venture_checkpoints WHERE attempt=$1 ORDER BY created_at,phase',[b.id])).rows;
 const start=checkpoints.find(x=>x.phase==='begin'),totals=await tallies(tx,b),baseline=checkpoints.find(c=>c.phase==='baseline');const focus=baseline?.snapshot.focus||Object.keys(totals).sort((a,b)=>(totals[b]-number(start?.snapshot.totals?.[b]))-(totals[a]-number(start?.snapshot.totals?.[a])))[0]||null;return {checkpoints,focus,completed_days:start&&focus?Math.max(0,number(totals[focus])-number(start.snapshot.totals?.[focus])):0,started:!!start,source:'Account-linked saves from the student device; teacher review required.'};
}
export async function checkpoint(tx,b,project,phase,state,revision){
 const fail=message=>{throw Object.assign(Error(message),{status:409})};
 const progress=await projectProgress(tx,b);
 if(phase==='begin'){if(progress.started)return progress;await beginProject(tx,b,state);return projectProgress(tx,b);}
 if(!progress.started)fail('Begin the gameplay investigation before collecting new workdays.');
 const index=project.stages.findIndex(s=>s.id===phase);if(index<0)fail('Choose a valid project checkpoint.');
 const exists=progress.checkpoints.find(c=>c.phase===phase);if(exists)return progress;
 if(index>0&&!progress.checkpoints.some(c=>c.phase===project.stages[index-1].id))fail('Record the earlier checkpoint first.');
 if(progress.completed_days<project.stages[index].days)fail('Complete '+project.stages[index].days+' new full venture workdays before this checkpoint. Partial openings do not count.');
 const district=districtSummary(state);if(!district.owned)fail('Save your classroom venture first.');
 const previous=progress.checkpoints.find(c=>c.phase===(index?project.stages[index-1].id:'begin'));
 const oldDecisions=new Set(previous.snapshot.district.businesses.flatMap(b=>b.decisions.map(d=>JSON.stringify(d))));
 const operatedDecision=district.businesses.filter(b=>b.id===progress.focus).some(b=>b.decisions.some(d=>!['Open','Close'].includes(d.action)&&!oldDecisions.has(JSON.stringify(d))&&b.history.some(h=>h.full_day===true&&h.day>=d.day)));
 if(index>0&&!operatedDecision)fail('Make and save an actual venture decision after the previous checkpoint, then operate and review its effects.');
 await tx.query('INSERT INTO crossroads_venture_checkpoints(attempt,phase,snapshot) VALUES($1,$2,$3::jsonb)',[b.id,phase,JSON.stringify({completed_days:progress.completed_days,focus:progress.focus,district,district_revision:revision})]);return projectProgress(tx,b);
}
