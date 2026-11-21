extends RefCounted
## Portable, bounded activity goals. Only completed, eligible play can advance them.
const KEY="hero_goals"
const IDS=["aurel","ripplejaw","mosaic","teacher","hearth_herald","navigator","cindervane"]
const TITLES={"aurel":"A reputation earned","ripplejaw":"Seventy different waters","mosaic":"A garden of many colours","teacher":"Build, predict, test","hearth_herald":"A light in the depths","navigator":"Night charts","cindervane":"An unbroken flame"}
const REQUIREMENTS={"aurel":"Deal 100,000 total combat damage. Training, AI practice and unofficial play do not count.","ripplejaw":"Discover 70 different fish species. Kept and released catches both count; repeats count once.","mosaic":"Harvest three different crops in the Seedhouse greenhouse. Starting seeds do not count.","teacher":"Complete the guided Hero Workshop lesson: name and describe a hero, change its primary, then run a successful 10-second test with three hits.","hearth_herald":"Clear Cave Descent floor 50, including its boss. Reaching the floor is not enough.","navigator":"Clear two different realms that you started at night, and catch 20 fish at night. Progress is cumulative.","cindervane":"Clear six realm adventures in a row, including four different realms, without dying. Death, defeat, abandonment or practice continuation resets the streak."}
static var time_for_test:float=-1
static func number(v:Variant,cap:float)->bool:
 return (v is int or v is float) and is_finite(float(v)) and float(v)>=0 and float(v)<=cap
static func realms()->Array:return JSON.parse_string(FileAccess.get_file_as_string("res://content/manifest.json")).regions
static func normal_realm(id:String)->bool:
 return id in realms() and id not in ["town","practice","wayfarer","descent","defense","arena"]
static func now()->float:return time_for_test if time_for_test>=0 else Time.get_unix_time_from_system()
static func night_at(timestamp:float)->bool:
 var clock=load("res://scripts/town_calendar.gd").new();clock.test_time=timestamp;clock.refresh()
 return clock.hour>=21 or clock.hour<6
static func allowed(l:Node)->bool:
 if not is_instance_valid(l) or not l.is_inside_tree() or not is_instance_valid(l.game) or not l.game.is_inside_tree():return false
 return not bool(l.data.get("teacher",false)) and not load("res://scripts/profile_store.gd").progression_blocked() and not l.get_tree().root.has_meta("fx_dedicated_server") and not l.game.has_meta("fx_champion_duel") and not l.game.has_meta("fx_hero_quest")
static func historical_damage(l:Node)->float:
 # tasks.damage excludes dummy and AI-practice damage, unlike old mastery totals.
 return minf(100000,minf(float(l.data.get("tasks",{}).get("damage",0)),load("res://scripts/record_eligibility.gd").eligible_damage(l)))
static func state(l:Node)->Dictionary:
 if not l.data.has(KEY):
  var harvested=[]
  for id in l.data.get("gardening",{}).get("produce",{}):
   if int(l.data.gardening.produce[id])>0 and load("res://scripts/gardening.gd").crops().has(id):harvested.append(id)
  l.data[KEY]={"version":1,"damage":historical_damage(l),"harvested":harvested,"night_realms":[],"night_fish":0,"studio":false,"streak":[],"run":{},"lesson":{}}
 return l.data[KEY]
static func valid(v:Variant)->bool:
 if not v is Dictionary or v.get("version")!=1:return false
 if not number(v.get("damage"),100000) or not number(v.get("night_fish"),20) or floorf(float(v.night_fish))!=float(v.night_fish) or not v.get("studio") is bool:return false
 for pair in [["night_realms",128],["streak",6],["harvested",512]]:
  if not v.get(pair[0]) is Array or v[pair[0]].size()>int(pair[1]):return false
  var seen=[]
  for id in v[pair[0]]:
   if not id is String:return false
   if pair[0]=="harvested":
    if not load("res://scripts/gardening.gd").crops().has(id):return false
   elif not normal_realm(id):return false
   if pair[0]!="streak" and id in seen:return false
   seen.append(id)
 if not v.get("run") is Dictionary:return false
 if not v.run.is_empty():
  if not v.run.has_all(["id","realm","night","failed","settled"]) or not v.run.id is String or v.run.id.length()>80 or v.run.id.is_empty() or not normal_realm(str(v.run.realm)):return false
  for key in ["night","failed","settled"]:
   if not v.run[key] is bool:return false
 if not v.get("lesson") is Dictionary:return false
 if not v.lesson.is_empty():
  if not v.lesson.get("project") is String or v.lesson.project.length()>100 or not v.lesson.get("base") is String or v.lesson.base.length()!=64:return false
 return true
static func species(l:Node)->int:
 var count=0;var fish=load("res://scripts/fishing_catalog.gd").fish()
 for id in l.data.get("fishing",{}).get("journal",{}):
  if fish.has(id) and int(l.data.fishing.journal[id].get("count",0))>0:count+=1
 return count
static func floor_clear(l:Node)->int:return int(l.data.get("card",{}).get("descent_best",0))
static func distinct(values:Array)->int:
 var seen=[]
 for id in values:
  if id not in seen:seen.append(id)
 return seen.size()
static func complete(l:Node,id:String)->bool:
 var s=state(l)
 match id:
  "aurel":return float(s.damage)>=100000
  "ripplejaw":return species(l)>=70
  "mosaic":return s.harvested.size()>=3
  "teacher":return bool(s.studio)
  "hearth_herald":return floor_clear(l)>=50
  "navigator":return s.night_realms.size()>=2 and int(s.night_fish)>=20
  "cindervane":return s.streak.size()>=6 and distinct(s.streak)>=4
 return false
static func progress(l:Node,id:String)->Dictionary:
 var s=state(l);var ratio=0.0;var text=""
 match id:
  "aurel":ratio=float(s.damage)/100000;text="%s / 100,000 damage" % int(s.damage)
  "ripplejaw":ratio=float(species(l))/70;text="%d / 70 species discovered" % species(l)
  "mosaic":ratio=float(s.harvested.size())/3;text="%d / 3 different crops harvested" % s.harvested.size()
  "teacher":ratio=1.0 if s.studio else .25 if not s.lesson.is_empty() else 0.0;text="Lesson complete" if s.studio else "Lesson started • finish a qualifying test" if not s.lesson.is_empty() else "Begin the guided Studio lesson"
  "hearth_herald":ratio=float(floor_clear(l))/50;text="%d / 50 Descent floors cleared" % floor_clear(l)
  "navigator":ratio=(minf(1,float(s.night_realms.size())/2)+minf(1,float(s.night_fish)/20))*.5;text="%d / 2 night-start realm clears • %d / 20 night catches" % [s.night_realms.size(),s.night_fish]
  "cindervane":ratio=(float(s.streak.size())/6+minf(1,float(distinct(s.streak))/4))*.5;text="%d / 6 consecutive wins • %d / 4 different realms" % [s.streak.size(),distinct(s.streak)]
 return {"ratio":clampf(ratio,0,1),"text":text}
static func sync(l:Node,notify:bool=true)->bool:
 if not allowed(l):return false
 var s=state(l);s.damage=maxf(float(s.damage),historical_damage(l))
 var u=load("res://scripts/hero_unlocks371.gd");var owned=u.state(l).owned;var added=false
 for id in IDS:
  if id in owned or not l.game.characters.has(id) or not complete(l,id):continue
  owned.append(id);added=true
  if notify:load("res://scripts/record_toast.gd").show(l.game,"HERO UNLOCKED • "+str(l.game.characters[id].name))
 return added
static func damage_changed(l:Node,amount:float)->void:
 if not allowed(l) or amount<=0:return
 var initialized=l.data.has(KEY);var s=state(l);var before=float(s.damage)
 # This hook receives actual health damage, after the existing eligibility guard.
 if initialized:s.damage=minf(100000,before+amount)
 if before<100000 and float(s.damage)>=100000 and sync(l):l.save()
static func harvest(l:Node,id:String)->void:
 if not allowed(l) or not load("res://scripts/gardening.gd").crops().has(id):return
 var s=state(l)
 if id not in s.harvested:s.harvested.append(id)
 sync(l)
static func catch_fish(l:Node,catch:Dictionary)->void:
 if not allowed(l):return
 if night_at(float(catch.get("caught_at",now()))):state(l).night_fish=mini(20,int(state(l).night_fish)+1)
 sync(l)
static func begin(l:Node,realm:String,token:String="")->void:
 if not allowed(l) or not normal_realm(realm):return
 var s=state(l)
 if not token.is_empty() and not s.run.is_empty() and s.run.id==token:return
 if not s.run.is_empty() and not bool(s.run.settled):s.streak=[]
 s.run={"id":token if not token.is_empty() else Crypto.new().generate_random_bytes(16).hex_encode(),"realm":realm,"night":night_at(now()),"failed":false,"settled":false}
 l.save()
static func fail(l:Node)->void:
 if not allowed(l):return
 var s=state(l)
 if s.run.is_empty() or bool(s.run.settled) or bool(s.run.failed):return
 s.run.failed=true;s.streak=[];l.save()
static func abandon(l:Node)->void:
 if not allowed(l):return
 var s=state(l)
 if s.run.is_empty() or bool(s.run.settled):return
 s.run.failed=true;s.run.settled=true;s.streak=[];l.save()
static func forfeit(l:Node)->void:
 if not allowed(l):return
 var s=state(l);s.streak=[]
 if not s.run.is_empty():s.run.failed=true;s.run.settled=true
 l.save()
static func cleared(l:Node,realm:String)->void:
 if not allowed(l):return
 var s=state(l)
 if s.run.is_empty() or s.run.realm!=realm or bool(s.run.settled):return
 s.run.settled=true
 if s.run.night and realm not in s.night_realms:s.night_realms.append(realm)
 if not bool(s.run.failed):
  s.streak.append(realm)
  while s.streak.size()>6:s.streak.pop_front()
 else:s.streak=[]
 sync(l)
static func observe_deaths(l:Node,deaths:int)->void:
 if deaths>0 and l.arcade and l.game.mode=="coop":fail(l)
static func primary_signature(attack:Dictionary)->String:
 var mechanical={}
 for key in ["style","damage","heal","cooldown","range","speed","radius","duration","count","spread","charge","status","status_duration","status_power","program","behavior"]:
  if attack.has(key):mechanical[key]=attack[key]
 return JSON.stringify(mechanical).sha256_text()
static func lesson_status(l:Node,p:Dictionary)->String:
 var s=state(l)
 if s.lesson.is_empty() or str(s.lesson.project)!=str(p.project_id):return "Start the lesson with your current draft. Your work will be kept."
 var named=str(p.hero.name)!="My Crossroads Hero" and str(p.concept).strip_edges().length()>=12
 var changed=primary_signature(p.hero.primary)!=str(s.lesson.base)
 return ("✓" if named else "○")+" Name your hero and describe its concept (at least 12 characters).\n"+("✓" if changed else "○")+" Change the primary attack behaviour or tune one of its values.\n○ Playtest for at least 10 seconds, land three hits, use the primary, and finish alive."
static func begin_lesson(l:Node,p:Dictionary)->void:
 if not allowed(l) or not load("res://scripts/workshop_project.gd").validate(p).is_empty():return
 var s=state(l)
 if s.lesson.is_empty() or s.lesson.project!=str(p.project_id):s.lesson={"project":str(p.project_id),"base":primary_signature(p.hero.primary)}
 l.save()
static func report(l:Node,p:Dictionary,report:Dictionary,alive:bool)->void:
 if not allowed(l) or not alive or not load("res://scripts/workshop_project.gd").validate(p).is_empty():return
 var s=state(l)
 if s.lesson.is_empty() or s.lesson.project!=str(p.project_id) or str(p.hero.name)=="My Crossroads Hero" or str(p.concept).strip_edges().length()<12:return
 if primary_signature(p.hero.primary)==str(s.lesson.base):return
 if primary_signature(report.get("tested_build",{}).get("primary",{}))!=primary_signature(p.hero.primary):return
 if str(report.get("project_hash",""))!=load("res://scripts/workshop_project.gd").fingerprint(p) or float(report.get("seconds",0))<10 or int(report.get("hits",0))<3 or int(report.get("casts",{}).get("primary",0))<1:return
 s.studio=true;sync(l);l.save()
static func open(g:Node,id:String="")->void:
 g.get_tree().root.set_meta("fx_goal_focus",id)
 g.hero_hall.close(false);g.lodges.challenge_page=load("res://scripts/lodge_catalog.gd").TYPES.size()+2;g.lodges.open("challenge")
static func workshop(g:Node)->void:
 g.presentation.close();g.hero_workshop.open();g.hero_workshop.hub.hide();g.hero_workshop.panel.show();g.hero_workshop.show_unlock_lesson()
static func draw_menu(g:Node,body:Node)->void:
 var ui=g.lodges
 if sync(g.legacy):g.legacy.save()
 var u=load("res://scripts/hero_unlocks371.gd")
 ui.label(body,"HERO GOALS",23)
 ui.label(body,"Earn these heroes through adventures and town activities. Progress saves to your profile, and rewards unlock automatically.",16)
 var focus=str(g.get_tree().root.get_meta("fx_goal_focus",""));var ids=IDS.duplicate()
 if focus in ids:ids.erase(focus);ids.push_front(focus)
 for id in ids:
  var h:Dictionary=g.characters[id];var p=progress(g.legacy,id);var owned=u.owned(g.legacy,id)
  var box=ui.card(body,str(h.name)+(" • Owned" if owned else " • Locked"),str(TITLES[id]))
  ui.label(box,str(REQUIREMENTS[id]),15);ui.label(box,str(p.text),16).modulate=Color("#c4e2cf")
  var bar=ProgressBar.new();bar.show_percentage=false;bar.custom_minimum_size.y=9;bar.value=float(p.ratio)*100;box.add_child(bar)
  if id=="teacher":
   var b=ui.button(box,"Open guided Studio lesson",workshop.bind(g));load("res://scripts/studio_ui.gd").accent(b)
 ui.label(body,"Night follows the town clock: 21:00–06:00. Night-start clears and catches can be earned across different nights. Cindervane’s streak survives town visits and logging out; leaving an unfinished run does not count as a win.",15)
