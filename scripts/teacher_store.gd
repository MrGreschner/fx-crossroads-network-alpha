extends RefCounted
const PATH="user://fx_teacher_classes.json"
const MAX_BYTES=33554432
static func fresh()->Dictionary:return {"version":1,"classes":{},"students":{}}
static func valid(v:Variant)->bool:
 if not v is Dictionary or v.get("version")!=1 or not v.get("classes") is Dictionary or v.classes.size()>8 or not v.get("students") is Dictionary or v.students.size()>93 or JSON.stringify(v).to_utf8_buffer().size()>MAX_BYTES:return false
 for code in v.classes:
  var c=v.classes[code]
  if not code is String or code.length()!=8 or not c is Dictionary or not c.get("title") is String or c.title.length()>80 or not c.get("time") is String or c.time.length()>50:return false
 for key in v.students:
  var s=v.students[key]
  if not key is String or key.length()>80 or not s is Dictionary or not s.has_all(["id","name","class_code","portfolio","time"]) or not s.id is String or s.id.length()>40 or not s.name is String or s.name.length()>80 or not s.time is String or s.time.length()>50 or not v.classes.has(s.class_code) or not preload("res://scripts/learning_store.gd").valid(s.portfolio):return false
 return true
static func state()->Dictionary:
 var v=preload("res://scripts/profile_store.gd").read(PATH,valid);return v if not v.is_empty() else fresh()
static func save(v:Dictionary)->String:
 if preload("res://scripts/profile_store.gd").testing():return "Exit testing mode before saving class records."
 if not valid(v):return "Class records exceed the supported limits. Export then clear an older class."
 return "" if preload("res://scripts/profile_store.gd").write(PATH,v)==OK else "Class records could not be saved. Download a backup."
static func ingest(code:String,title:String,id:String,portfolio:Dictionary,preserve:bool=true)->String:
 if not preload("res://scripts/learning_store.gd").valid(portfolio):return "Invalid student portfolio."
 var v=state();var key=code+"-"+id
 if not v.classes.has(code):v.classes[code]={"title":title.left(80),"time":preload("res://scripts/learning_store.gd").stamp()}
 # A fresh student upload must not erase matching ratings stored by the teacher.
 if preserve and v.students.has(key):
  for assessed in v.students[key].portfolio.submissions:
   for submitted in portfolio.submissions:
    if assessed.id==submitted.id and assessed.digest==submitted.digest and not assessed.marks.is_empty():submitted.marks=assessed.marks.duplicate(true);submitted.teacher=assessed.teacher;submitted.reviewed=assessed.reviewed
 v.students[key]={"id":id,"name":portfolio.student,"class_code":code,"portfolio":portfolio.duplicate(true),"time":preload("res://scripts/learning_store.gd").stamp()}
 return save(v)
