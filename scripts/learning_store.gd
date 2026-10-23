extends RefCounted
## Local, versioned classroom evidence. Activity is not an automatic outcome award.
const PATH="user://fx_learning.json"
const FORMAT="fx-crossroads-learning"
const MAX_BYTES=12582912
const MAX_REVIEW=4194304
const P=preload("res://scripts/workshop_project.gd")
const RATINGS=["Not assessed","More evidence needed","Developing","Meets","Extends"]
static func catalog()->Dictionary:return JSON.parse_string(FileAccess.get_file_as_string("res://content/studio/learning-modules.json")).modules
static func fresh()->Dictionary:return {"format":FORMAT,"version":1,"learner_id":Crypto.new().generate_random_bytes(16).hex_encode(),"enabled":false,"student":"","active":"DES1020","work":{},"artifacts":{},"submissions":[],"next":1}
static func stamp()->String:return Time.get_datetime_string_from_system(true)+"Z"
static func text_ok(value:Variant,cap:int)->bool:return value is String and value.length()<=cap
static func valid_artifact(a:Variant)->bool:
 if not a is Dictionary or not a.has_all(["kind","value","title","time","origin","hash"]):return false
 for pair in [["title",100],["time",50],["origin",120],["hash",64]]:
  if not text_ok(a[pair[0]],pair[1]):return false
 if a.has("order") and not P.number(a.order,1,1000000):return false
 if JSON.stringify(a.value).to_utf8_buffer().size()>P.MAX_BYTES or a.hash!=fingerprint(a.value):return false
 match str(a.kind):
  "object","realm":return preload("res://scripts/studio_world_project.gd").validate(a.kind,a.value).is_empty()
  "hero":return P.validate(a.value).is_empty()
  "ability":return P.validate_attack(a.value).is_empty()
  "enemy":return preload("res://scripts/studio_enemy_project.gd").validate(a.value).is_empty()
  "behavior":return preload("res://scripts/studio_behavior.gd").validate(a.value).is_empty()
  "photo":return preload("res://scripts/media_portfolio.gd").valid([a.value])
  "business":return load("res://scripts/education_business.gd").valid(a.value)
  "district":return preload("res://scripts/business_district/catalog.gd").valid(a.value)
  "market":return preload("res://scripts/commerce.gd").valid(a.value)
  "structured_program":return load("res://scripts/structured_program.gd").valid(a.value)
  "program":return load("res://scripts/education_ipo.gd").valid(a.value)
  "quiz":return load("res://scripts/learning_auto.gd").valid_quiz(a.value)
  "graphic":return a.value is Dictionary and a.value.has_all(["image","svg","settings"]) and text_ok(a.value.image,180000) and text_ok(a.value.svg,8000) and a.value.settings is Dictionary and JSON.stringify(a.value.settings).length()<4000 and safe_svg(a.value.svg) and P.png_error(Marshalls.base64_to_raw(a.value.image)).is_empty()
 return false
static func safe_svg(svg:String)->bool:
 var lower=svg.to_lower()
 for forbidden in ["script","href","url(","<!","foreignobject","onload","onclick","onerror","javascript:"]:
  if forbidden in lower:return false
 var event_pattern=RegEx.new();event_pattern.compile("\\bon[a-z]+\\s*=")
 return lower.begins_with("<svg") and lower.ends_with("</svg>") and event_pattern.search(lower)==null
static func valid_entries(entries:Variant,module:Dictionary)->bool:
 if not entries is Array or entries.size()>60:return false
 for e in entries:
  if not e is Dictionary or not e.has_all(["stage","text","time","order"]):return false
  if not text_ok(e.text,3000) or not text_ok(e.time,50) or not e.order is int and not e.order is float or not P.number(e.order,1,1000000):return false
  if not module.stages.any(func(s):return s.id==e.stage):return false
 return true
static func valid_refs(refs:Variant,artifacts:Dictionary)->bool:
 if not refs is Array or refs.size()>16:return false
 for id in refs:
  if not id is String or not artifacts.has(id):return false
 return true
static func valid_marks(marks:Variant,module:Dictionary)->bool:
 if not marks is Dictionary or marks.size()>module.outcomes.size():return false
 for id in marks:
  var m=marks[id]
  if not module.outcomes.any(func(o):return o.id==id) or not m is Dictionary or not m.has_all(["rating","feedback","score"]):return false
  if not m.rating in RATINGS or not text_ok(m.feedback,1500) or not P.number(m.score,-1,100):return false
 return true
static func valid(data:Variant)->bool:
 if not data is Dictionary or not data.has_all(["format","version","enabled","student","active","work","artifacts","submissions","next"]):return false
 if data.has("learner_id") and (not text_ok(data.learner_id,32) or data.learner_id.length()!=32 or not data.learner_id.is_valid_hex_number(false)):return false
 if data.format!=FORMAT or data.version!=1 or not data.enabled is bool or not text_ok(data.student,80):return false
 if JSON.stringify(data).to_utf8_buffer().size()>MAX_BYTES or not P.number(data.next,1,1000000):return false
 var modules=catalog()
 if not modules.has(data.active) or not data.work is Dictionary or data.work.size()>modules.size() or not data.artifacts is Dictionary or data.artifacts.size()>32 or not data.submissions is Array or data.submissions.size()>96:return false
 for id in data.artifacts:
  if not text_ok(id,64) or not valid_artifact(data.artifacts[id]) or id!=data.artifacts[id].hash:return false
 for code in data.work:
  var w=data.work[code]
  if not modules.has(code) or not w is Dictionary or not w.has_all(["entries","refs"]):return false
  if not valid_activity(w.get("activity",[])):return false
  if not valid_entries(w.entries,modules[code]) or not valid_refs(w.refs,data.artifacts):return false
 var ids=[]
 for s in data.submissions:
  if not s is Dictionary or not s.has_all(["id","module","time","entries","refs","marks","teacher","reviewed","digest"]):return false
  if not modules.has(s.module) or not text_ok(s.id,80) or s.id in ids or not text_ok(s.time,50) or not text_ok(s.teacher,80) or not text_ok(s.reviewed,50) or not text_ok(s.digest,64):return false
  ids.append(s.id)
  if not valid_entries(s.entries,modules[s.module]) or not valid_refs(s.refs,data.artifacts) or not valid_marks(s.marks,modules[s.module]):return false
  if not valid_activity(s.get("activity",[])) or digest(s)!=s.digest:return false
 return true
static func load_data()->Dictionary:
 var store=preload("res://scripts/profile_store.gd");var data=store.read(PATH,valid)
 if data.is_empty():data=fresh()
 if not data.has("learner_id"):data.learner_id=Crypto.new().generate_random_bytes(16).hex_encode();save(data)
 data.enabled=load("res://scripts/education_access.gd").student()
 return data
static func save(data:Dictionary)->String:
 if preload("res://scripts/profile_store.gd").testing():return "Exit Game Dev / Playtest before recording assessed work."
 if not valid(data):return "Portfolio is invalid or full. Export a backup before changing it."
 return "" if preload("res://scripts/profile_store.gd").write(PATH,data)==OK else "Could not save. Download your work."
static func activity(action:String,title:String)->void:
 if preload("res://scripts/profile_store.gd").testing():return
 var data=load_data()
 if not load("res://scripts/education_access.gd").student():return
 var w=work(data,data.active)
 if not w.has("activity"):w.activity=[]
 w.activity.append({"action":action.left(60),"title":title.left(100),"time":stamp(),"order":int(data.next)});data.next+=1
 if w.activity.size()>60:w.activity.pop_front()
 save(data)
static func capture_current(kind:String,value:Dictionary,title:String)->String:
 var data=load_data()
 if not load("res://scripts/education_access.gd").student():return "Student access and a chosen portfolio module are required."
 var issue=attach(data,data.active,kind,value,title,"Captured directly from Lab")
 return "Evidence snapshot saved to "+data.active+". Your artifact demonstrates the practical work." if issue.is_empty() else issue
static func valid_activity(events:Variant)->bool:
 if not events is Array or events.size()>60:return false
 for e in events:
  if not e is Dictionary or not e.has_all(["action","title","time","order"]) or not text_ok(e.action,60) or not text_ok(e.title,100) or not text_ok(e.time,50) or not P.number(e.order,1,1000000):return false
 return true
static func work(data:Dictionary,code:String)->Dictionary:
 if not data.work.has(code):data.work[code]={"entries":[],"refs":[]}
 return data.work[code]
static func note(data:Dictionary,code:String,stage:String,text:String)->String:
 if not load("res://scripts/education_access.gd").student():return "Unlock Student access first."
 if text.strip_edges().is_empty():return "Write your evidence before saving."
 if work(data,code).entries.size()>=60:return "This module has 60 entries. Export the portfolio."
 var old=data.duplicate(true);work(data,code).entries.append({"stage":stage,"text":text.left(3000),"time":stamp(),"order":int(data.next)});data.next+=1
 var issue=save(data)
 if not issue.is_empty():data.clear();data.merge(old)
 return issue
static func attach(data:Dictionary,code:String,kind:String,value:Dictionary,title:String,origin:String)->String:
 if not load("res://scripts/education_access.gd").student():return "Unlock Student access first."
 var hash=fingerprint(value);var id=hash
 var a={"kind":kind,"value":value.duplicate(true),"title":title.left(100),"time":stamp(),"origin":origin.left(120),"hash":hash}
 if not valid_artifact(a):return "Choose a valid saved project or image."
 if not data.artifacts.has(id) and data.artifacts.size()>=32:return "32 snapshots stored. Export this portfolio before starting another."
 if work(data,code).refs.size()>=16 and not id in work(data,code).refs:return "A module can link up to 16 snapshots."
 var old=data.duplicate(true)
 if not data.artifacts.has(id):
  a.order=int(data.next);data.next+=1;data.artifacts[id]=a
 if not id in work(data,code).refs:work(data,code).refs.append(id)
 var issue=save(data)
 if not issue.is_empty():data.clear();data.merge(old)
 return issue
static func fingerprint(value:Variant)->String:return JSON.stringify(JSON.parse_string(JSON.stringify(value))).sha256_text()
static func digest(s:Dictionary)->String:return fingerprint({"module":s.module,"time":s.time,"entries":s.entries,"refs":s.refs,"activity":s.get("activity",[])})
static func submit(data:Dictionary,code:String)->String:
 if not load("res://scripts/education_access.gd").student():return "Unlock Student access first."
 var w=work(data,code)
 if w.entries.is_empty() and w.refs.is_empty():return "Add some evidence before submitting."
 if data.submissions.size()>=96:return "Submission limit reached; download a portfolio backup."
 var s={"id":code+"-"+str(int(data.next)),"module":code,"time":stamp(),"entries":w.entries.duplicate(true),"refs":w.refs.duplicate(),"activity":w.get("activity",[]).duplicate(true),"marks":{},"teacher":"","reviewed":"","digest":""};s.digest=digest(s)
 var old=data.duplicate(true);data.submissions.append(s);data.next+=1
 var issue=save(data)
 if not issue.is_empty():data.clear();data.merge(old)
 return issue
static func readiness(data:Dictionary,code:String,w:Dictionary)->Dictionary:
 var result={};var module=catalog()[code]
 for o in module.outcomes:
  var present=[]
  for e in w.entries:
   if e.stage in o.stages and not e.text.strip_edges().is_empty() and not e.stage in present:present.append(e.stage)
  var missing=[]
  for needed in o.get("assets",[]):
   var found=practical_evidence(data,w,str(needed))
   for ref in w.refs:
    var a:Dictionary=data.artifacts[ref]
    if a.kind==needed or needed=="market" and a.kind=="business" and a.value.module==code or needed=="code" and a.kind in ["ability","behavior"]:found=true
    if code=="MAM1010" and needed=="market" and a.kind=="district" and district_comparison(a.value):found=true
    if needed=="animation" and a.kind=="hero":
     var poses:Dictionary=a.value.hero.art
     if poses.get("walk1","")!=poses.get("walk2",""):found=true
    if needed=="animation" and a.kind=="ability":
     var distinct=[]
     for frame in a.value.get("animation",[]):
      if not frame in distinct:distinct.append(frame)
     if distinct.size()>=2:found=true
   if not found:missing.append(needed)
  var sequence_ok=true
  if not o.get("before_production",[]).is_empty():
   var first=1000001
   for ref in w.refs:
    if data.artifacts[ref].kind in ["object","realm"]:first=mini(first,int(data.artifacts[ref].get("order",1000001)))
   for stage in o.before_production:
    if not w.entries.any(func(e):return e.stage==stage and int(e.order)<first):sequence_ok=false
  result[o.id]={"sequence_ok":sequence_ok,"count":present.size(),"need":o.stages.size(),"ready":present.size()==o.stages.size() and (not o.stages.is_empty() or not o.get("assets",[]).is_empty()) and missing.is_empty() and sequence_ok,"stages":present,"missing":missing}
 return result
static func review_bundle(data:Dictionary)->Dictionary:
 var copy=fresh();copy.student=data.student;copy.active=data.active;copy.learner_id=data.get("learner_id",copy.learner_id)
 var latest={}
 for s in data.submissions:latest[s.module]=s
 for s in latest.values():
  copy.submissions.append(s.duplicate(true))
  for id in s.refs:copy.artifacts[id]=data.artifacts[id].duplicate(true)
 return copy
static func apply_feedback(data:Dictionary,returned:Dictionary)->String:
 if not valid(returned):return "Teacher feedback failed validation."
 var old=data.duplicate(true);var found=0
 for s in returned.submissions:
  for local in data.submissions:
   if local.id==s.id and local.digest==s.digest:
    local.marks=s.marks.duplicate(true);local.teacher=s.teacher;local.reviewed=s.reviewed;found+=1
 var issue=save(data) if found>0 else "This feedback belongs to a different submission."
 if not issue.is_empty():data.clear();data.merge(old)
 return issue
static func report(data:Dictionary)->String:
 var out="# Crossroads learning portfolio\nStudent: "+str(data.student)+"\n\nEvidence readiness is not achievement. Teacher confirms outcomes. Local times/order can be edited and are not secure provenance.\n"
 for s in data.submissions:
  out+="\n## "+s.module+" • "+str(catalog()[s.module].name)+"\nSubmission "+s.id+" • "+s.time+"\n"
  for e in s.entries:out+="\n### "+e.stage+" • "+e.time+"\n"+e.text+"\n"
  for id in s.refs:out+="\nArtifact: "+str(data.artifacts[id].title)+" • "+str(data.artifacts[id].kind)+" • "+str(data.artifacts[id].time)+"\n"
  for id in s.marks:out+="\nOutcome "+id+": "+s.marks[id].rating+" • score "+str(s.marks[id].score)+" / 100 (−1 unset) • "+s.marks[id].feedback+"\n"
  out+="\nReviewer: "+s.teacher+" • "+s.reviewed+"\n"
  for event in s.get("activity",[]):out+="\nActivity: "+event.action+" • "+event.title+" • "+event.time+"\n"
 return out

static func stages(code:String)->Array:
 return catalog()[code].stages.filter(func(s):return not bool(s.get("hidden",false)))
static func assessed_outcomes(code:String)->Array:
 return catalog()[code].outcomes.filter(func(o):return not bool(o.get("observation",false)))

static func practical_evidence(data:Dictionary,w:Dictionary,needed:String)->bool:
 var objects={};var visual=false;var realms=[];var programs=[]
 for ref in w.get("refs",[]):
  var a:Dictionary=data.artifacts[ref]
  if a.kind=="hero":visual=visual or not a.value.hero.art.is_empty()
  elif a.kind in ["photo","graphic"]:visual=true
  elif a.kind=="object":objects[a.value.id]=a.value;visual=true
  elif a.kind=="realm":realms.append(a.value)
  elif a.kind=="program":programs.append(a.value)
 if needed=="visual":return visual
 if needed=="realm":return not realms.is_empty()
 if needed=="tested_realm":return realms.any(func(r):return not r.tests.is_empty() and preload("res://scripts/studio_world_project.gd").checks(r).is_empty())
 if needed=="object_pack":return objects.size()>=3
 if needed=="tested_program":return programs.any(func(p):return p.get("cases",[]).size()>=3)
 if needed in ["raster_pack","advanced_raster_pack"]:
  var layered=0;var operations=[];var settings=0
  for obj in objects.values():
   if obj.layers.size()>=2:layered+=1
   if obj.settings.has("dimensions") and obj.settings.has("filename"):settings+=1
   for op in obj.operations:
    if not op in operations:operations.append(op)
  if needed=="raster_pack":return objects.size()>=3 and layered>=1 and settings>=1 and operations.any(func(op):return "Select" in op) and ("Gradient" in operations or "Pattern" in operations) and "Mask" in operations
  var versions={}
  for ref in w.get("refs",[]):
   var a=data.artifacts[ref]
   if a.kind=="object":versions[a.value.id]=int(versions.get(a.value.id,0))+1
  return objects.size()>=4 and layered>=2 and settings>=2 and "Create custom brush" in operations and "Stamp custom brush" in operations and "Tone" in operations and "Mask" in operations and versions.values().any(func(n):return n>=2)
 return false

static func district_comparison(value:Dictionary)->bool:
 if not preload("res://scripts/business_district/catalog.gd").valid(value):return false
 for b in value.businesses.values():
  if b.history.size()>=2 and not b.note.strip_edges().is_empty():return true
 return false
