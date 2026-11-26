extends RefCounted
## Authored, replayable journeys; eligibility never depends on an NPC's daily schedule.
const KEY="hero_journeys"
static var cache:Dictionary={}
static var focus_id=""
static func catalog()->Dictionary:
 if cache.is_empty():cache=JSON.parse_string(FileAccess.get_file_as_string("res://content/hero_journeys373.json"))
 return cache
static func ids()->Array:return catalog().keys()
static func state(l:Node)->Dictionary:
 if not l.data.has(KEY):l.data[KEY]={"version":1,"prepared":[]}
 return l.data[KEY]
static func valid(v:Variant)->bool:
 if not v is Dictionary or v.get("version")!=1 or not v.get("prepared") is Array or v.prepared.size()>catalog().size():return false
 var seen=[]
 for id in v.prepared:
  if not id is String or not catalog().has(id) or not bool(catalog()[id].get("duel",false)) or id in seen:return false
  seen.append(id)
 return true
static func realm_count(l:Node)->int:
 var a=load("res://scripts/hero_goals372.gd");var r=load("res://scripts/realm_access.gd");var count=0
 for id in a.realms():
  if a.normal_realm(str(id)) and r.cleared(l,str(id)):count+=1
 return count
static func active(g:Node,id:String)->bool:return bool(g.characters.get(id,{}).get("event_active",true))
static func requirement(id:String)->int:return int(catalog().get(id,{}).get("clear_requirement",13))
static func battle(id:String)->bool:return str(catalog().get(id,{}).get("trial_type","course"))=="duel"
static func eligible(l:Node,id:String)->bool:
 if not catalog().has(id) or id=="patch":return false
 var d:Dictionary=catalog()[id]
 if not active(l.game,id):return false
 if id in load("res://scripts/hero_unlocks371.gd").state(l).owned:return true
 if d.has("event"):return true
 if realm_count(l)<requirement(id):return false
 return not d.has("requires_realm") or load("res://scripts/realm_access.gd").unlocked(l,str(d.requires_realm))
static func duel_ready(l:Node,id:String)->bool:
 return catalog().has(id) and bool(catalog()[id].get("duel",false)) and eligible(l,id) and (battle(id) or id in state(l).prepared)
static func progress(l:Node,id:String)->String:
 var u=load("res://scripts/hero_unlocks371.gd")
 if u.owned(l,id):return "Owned • replay freely"
 if id=="patch":return "%d / 3 completed co-op realm adventures" % mini(3,int(l.data.get("tasks",{}).get("coop_clears",0)))
 var d:Dictionary=catalog()[id]
 if not active(l.game,id):return "Returns for Halloween • complete this journey when the event is active"
 if not eligible(l,id):
  if realm_count(l)<requirement(id):return "%d / %d different realms cleared • then begin %s" % [realm_count(l),requirement(id),str(d.title)]
  return "Unlock Astral Rift access • then begin this journey"
 if battle(id) and eligible(l,id):return "Personal duel available • learn this hero’s own kit"
 if duel_ready(l,id):return "Journey prepared • personal duel ready"
 return "Journey available • "+str(d.title)
static func legitimate(l:Node)->bool:
 return is_instance_valid(l) and l.is_inside_tree() and not bool(l.data.get("teacher",false)) and not load("res://scripts/profile_store.gd").progression_blocked() and not l.get_tree().root.has_meta("fx_dedicated_server")
static func award(l:Node,id:String)->bool:
 if not legitimate(l) or not catalog().has(id):return false
 var u=load("res://scripts/hero_unlocks371.gd");var s=u.state(l)
 if id in s.owned:return false
 s.owned.append(id);l.save();return true
static func sync(l:Node,notify:bool=true)->bool:
 if not legitimate(l) or l.game.has_meta("fx_hero_quest") or l.game.has_meta("fx_champion_duel"):return false
 if int(l.data.get("tasks",{}).get("coop_clears",0))<3:return false
 var u=load("res://scripts/hero_unlocks371.gd");var s=u.state(l)
 if "patch" in s.owned:return false
 s.owned.append("patch")
 if notify:load("res://scripts/record_toast.gd").show(l.game,"HERO UNLOCKED • Patch")
 return true
static func finish(l:Node,id:String)->bool:
 # The scene calls this only after every authored objective has been completed.
 if not legitimate(l) or not eligible(l,id):return false
 if bool(catalog()[id].duel):
  var s=state(l)
  if id not in s.prepared:s.prepared.append(id);l.save()
  return false
 return award(l,id)
static func open(g:Node,_id:String="")->void:
 focus_id=_id
 g.hero_hall.close(false);g.lodges.challenge_page=load("res://scripts/lodge_catalog.gd").TYPES.size()+3;g.lodges.open("challenge")
static func draw_menu(g:Node,body:Node)->void:
 var ui=g.lodges;var u=load("res://scripts/hero_unlocks371.gd")
 sync(g.legacy)
 ui.label(body,"HERO JOURNEYS • %d / %d earned" % [ids().filter(func(id):return u.owned(g.legacy,id)).size(),ids().size()],23)
 ui.label(body,"Four journeys open after four different realm clears; further batches open at seven and thirteen. Every lesson lends you its own hero. Some heroes have a personal duel instead. Free retries • level 10 • no supplies consumed. Event journeys are available while their event is active.",16)
 if not focus_id.is_empty():ui.button(body,"Show all hero journeys",func():focus_id="";open(g))
 for id in catalog():
  if not focus_id.is_empty() and focus_id!=id:continue
  var d:Dictionary=catalog()[id];var h:Dictionary=g.characters[id]
  var box=ui.card(body,str(h.name)+" • "+str(d.title),str(d.place)+"\n"+progress(g.legacy,id))
  if id=="patch":ui.label(box,"Play three co-op realm adventures with other people. AI practice and journeys do not count.",15);continue
  var steps=[]
  for st in d.stages:steps.append(str(st.text))
  ui.label(box,"Win a personal duel using a temporary version of this hero." if battle(id) else " → ".join(steps)+(" → Win the personal duel." if d.duel else ""),14)
  if bool(d.loan):ui.label(box,"A temporary level-10 version of this hero is provided inside the course.",14)
  var b=ui.button(box,"Replay duel" if battle(id) and u.owned(g.legacy,id) else "Begin personal duel" if battle(id) else "Replay journey" if u.owned(g.legacy,id) else "Begin journey",launch.bind(g,str(id)));b.disabled=not eligible(g.legacy,id)
  if not b.disabled:load("res://scripts/studio_ui.gd").accent(b)
  if not battle(id) and duel_ready(g.legacy,id):ui.button(box,"Personal duel / rematch",u.launch.bind(g,str(id)))
static func launch(g:Node,id:String)->void:
 if not eligible(g.legacy,id):return
 var u=load("res://scripts/hero_unlocks371.gd")
 if not u.owned(g.legacy,str(g.selected_character)) or not load("res://scripts/record_eligibility.gd").hero_allowed(g,str(g.selected_character)):return
 if battle(id):u.launch(g,id);return
 g.save_profile();g.legacy.save()
 g.get_tree().root.set_meta("fx_hero_journey",{"id":id,"hero":str(g.selected_character)})
 g.get_tree().change_scene_to_file("res://scenes/hero_journey373.tscn")
