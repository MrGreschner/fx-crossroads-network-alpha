extends RefCounted
## Finalization installs a usable local artifact; submission freezes evidence separately.
static func submit(kind:String,value:Dictionary,title:String)->String:
 if load("res://scripts/profile_store.gd").testing():return "Exit Game Dev / Playtest before submitting assessed work."
 var library=load("res://scripts/studio_library.gd")
 var issue=""
 match kind:
  "hero":issue=library.add_hero(value)
  "enemy":issue=library.add_enemy(value)
  "ability":issue=library.add_ability(value)
  "behavior":issue=library.add_behavior(value)
  "object","realm":issue=library.add_world(kind,value)
 if not issue.is_empty():return issue
 var store=load("res://scripts/learning_store.gd");var data=store.load_data()
 issue=store.attach(data,data.active,kind,value,title,"Finalized in Studio")
 return "Frozen source saved. Open Learning Academy → My evidence to attach it to an assigned module, then submit when ready." if issue.is_empty() else issue
