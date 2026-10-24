extends RefCounted
const CLASSROOM=["demonstrate basic competencies","apply consistent and appropriate work station routines","make personal connections to the cluster content and processes to inform possible pathway choices"]
static var guides:Dictionary={}
static func definition(value:Dictionary)->Dictionary:
 var result=value.duplicate(true)
 if guides.is_empty():guides=JSON.parse_string(FileAccess.get_file_as_string("res://content/assessment-guides.json"))
 for task in result.get("tasks",[]):
  var guide=guides.get(str(result.get("code",""))+":"+str(task.id),{})
  if not guide.is_empty():task.guidance=guide;task.title=guide.title;task.prompt=guide.steps;task.required_evidence=guide.deliverable;task.worked_example=guide.example
 result.submission_structure="One module submission with %d outcome parts. Save each part as you go. Submit module for review sends every saved part together; partial work can receive feedback." % result.get("tasks",[]).size()
 if str(value.get("subject","Business"))=="Business":return result
 var kept=[];var ids=[]
 for o in result.get("outcomes",[]):
  if str(o.get("title","")).strip_edges().to_lower() in CLASSROOM:continue
  kept.append(o);ids.append(str(o.id))
 result.outcomes=kept;result.tasks=result.get("tasks",[]).filter(func(t):return t.get("outcomes",[]).any(func(id):return str(id) in ids))
 return result
