extends RefCounted
const PATH="user://fx_education_access.json"
static func fresh()->Dictionary:return {"version":1,"student":false,"teacher":false,"student_on":false,"teacher_on":false}
static func valid(value:Variant)->bool:
 if not value is Dictionary or value.get("version")!=1:return false
 for key in ["student","teacher","student_on","teacher_on"]:
  if not value.get(key) is bool:return false
 return (not value.student_on or value.student) and (not value.teacher_on or value.teacher)
static func state()->Dictionary:
 var tree=Engine.get_main_loop() as SceneTree
 var account=tree.root.get_node_or_null("FXAccount") if tree!=null else null
 if account!=null and account.loaded:
  var role=account.school_role();return {"version":1,"student":role=="student","teacher":role=="teacher","student_on":role=="student","teacher_on":role=="teacher"}
 var v=preload("res://scripts/profile_store.gd").read(PATH,valid)
 return v if not v.is_empty() else fresh()
static func student()->bool:
 var s=state();return s.student
static func teacher()->bool:
 var s=state();return s.teacher
static func unlock(kind:String)->bool:
 var account=(Engine.get_main_loop() as SceneTree).root.get_node_or_null("FXAccount")
 if account!=null and account.loaded:return false
 if not kind in ["student","teacher"]:return false
 if preload("res://scripts/profile_store.gd").testing():return false
 var s=state();s[kind]=true;s[kind+"_on"]=true
 if preload("res://scripts/profile_store.gd").write(PATH,s)!=OK:return false
 if kind=="student":
  var data=preload("res://scripts/learning_store.gd").load_data();data.enabled=true;preload("res://scripts/learning_store.gd").save(data)
 return true
static func toggle(kind:String,on:bool)->void:
 if not kind in ["student","teacher"]:return
 var s=state()
 if not s[kind] or preload("res://scripts/profile_store.gd").testing():return
 s[kind+"_on"]=on;preload("res://scripts/profile_store.gd").write(PATH,s)
 if kind=="student":
  var data=preload("res://scripts/learning_store.gd").load_data();data.enabled=on;preload("res://scripts/learning_store.gd").save(data)

static func review_allowed()->bool:
 var session=preload("res://scripts/profile_store.gd").dev_session()
 return teacher() or (session!=null and session.active)

static func revoke(kind:String)->bool:
 var account=(Engine.get_main_loop() as SceneTree).root.get_node_or_null("FXAccount")
 if account!=null and account.loaded:return false
 if kind not in ["student","teacher"] or preload("res://scripts/profile_store.gd").testing():return false
 var s=state();s[kind]=false;s[kind+"_on"]=false
 if preload("res://scripts/profile_store.gd").write(PATH,s)!=OK:return false
 if kind=="student":
  var data=preload("res://scripts/learning_store.gd").load_data();data.enabled=false;preload("res://scripts/learning_store.gd").save(data)
 return true

static func role_label()->String:
 var s=state();return "Teacher" if s.teacher else "Student" if s.student else "Traveller"
