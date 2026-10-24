extends RefCounted
const CLASSROOM=["demonstrate basic competencies","apply consistent and appropriate work station routines","make personal connections to the cluster content and processes to inform possible pathway choices"]
static func definition(value:Dictionary)->Dictionary:
 if str(value.get("subject","Business"))=="Business":return value
 var result=value.duplicate(true);var kept=[];var ids=[]
 for o in result.get("outcomes",[]):
  if str(o.get("title","")).strip_edges().to_lower() in CLASSROOM:continue
  kept.append(o);ids.append(str(o.id))
 result.outcomes=kept;result.tasks=result.get("tasks",[]).filter(func(t):return t.get("outcomes",[]).any(func(id):return str(id) in ids))
 return result
