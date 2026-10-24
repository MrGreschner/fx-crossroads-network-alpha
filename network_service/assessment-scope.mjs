export const classroomTitles=new Set(['demonstrate basic competencies','apply consistent and appropriate work station routines','make personal connections to the cluster content and processes to inform possible pathway choices']);
const normalized=o=>String(o?.title||'').trim().toLowerCase().replace(/\s+/g,' ');
export const classroomOutcome=o=>classroomTitles.has(normalized(o));
export function assessmentDefinition(def){
 if(!def||!Array.isArray(def.outcomes)||!(/^(DES|COM|CSE)/.test(def.code||'')||def.subject&&def.subject!=='Business'))return def;
 const removed=def.outcomes.filter(classroomOutcome),outcomes=def.outcomes.filter(o=>!classroomOutcome(o)),ids=new Set(outcomes.map(o=>o.id));
 return {...def,outcomes,tasks:(def.tasks||[]).filter(t=>(t.outcomes||[]).some(id=>ids.has(id))).map(t=>({...t,outcomes:t.outcomes.filter(id=>ids.has(id))})),classroom_outcomes:[...(def.classroom_outcomes||[]),...removed],assessment_scope:'Course-specific main outcomes are assessed here. General classroom routines, competencies and pathway connections are handled by the teacher outside this program.'};
}
