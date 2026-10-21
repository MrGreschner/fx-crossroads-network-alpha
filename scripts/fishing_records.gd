extends RefCounted
const C=preload("res://scripts/fishing_catalog.gd")
const CAPACITY=100
var legacy:Node
var dev_ready=false
var progress=preload("res://scripts/fishing_progress.gd").new()
func defaults()->Dictionary:return {"rod":true,"journal":{},"kept":[],"display":["","","","",""],"favorite":"","total":0}
func state()->Dictionary:
 if not legacy.data.has("fishing"):legacy.data.fishing=defaults()
 legacy.data.fishing.rod=true
 progress.records=self
 progress.migrate(legacy.data.fishing)
 if not legacy.data.fishing.has("visited_pools"):
  legacy.data.fishing.visited_pools={}
  for catch in legacy.data.fishing.kept:
   if C.pools().has(str(catch.get("pool",""))):legacy.data.fishing.visited_pools[str(catch.pool)]=true
  for pot in legacy.data.fishing.get("pots",[]):
   if C.pools().has(str(pot.get("pool",""))):legacy.data.fishing.visited_pools[str(pot.pool)]=true
 for key in progress.extras():
  if not legacy.data.fishing.has(key):legacy.data.fishing[key]=progress.extras()[key]
 var dev=preload("res://scripts/profile_store.gd").dev_session()
 if bool(legacy.data.get("teacher",false)) and dev!=null and dev.active and not dev_ready:
  dev_ready=true
  var s=legacy.data.fishing;s.rod=true;s.xp=maxi(int(s.xp),progress.threshold(progress.MAX_LEVEL));s.gear={"net":true,"pot":true}
  for id in s.bait:s.bait[id]=1000
  for id in C.fish():
   if not s.journal.has(id):s.journal[id]={"count":0,"kg":0.0,"cm":0.0}
 return legacy.data.fishing
func dev_preview()->bool:
 var dev=preload("res://scripts/profile_store.gd").dev_session()
 return bool(legacy.data.get("teacher",false)) and dev!=null and dev.active
func discover_pool(id:String)->bool:
 if not C.pools().has(id) or state().visited_pools.has(id):return false
 if dev_preview() or preload("res://scripts/profile_store.gd").progression_blocked():return false
 state().visited_pools[id]=true;save();return true
func known_pools()->Array:
 return C.pools().keys() if dev_preview() else state().visited_pools.keys()
func capacity()->int:return mini(CAPACITY,10+10*mini(4,progress.level()/5)+int(progress.perk_bonus("capacity")))
func save()->void:legacy.save()
func unlock()->void:state().rod=true;save()
func specimen(id:String)->Dictionary:
 for catch in state().kept:
  if str(catch.id)==id:return catch
 return {}
func favorite()->Dictionary:return specimen(str(state().favorite))
func complete(catch:Dictionary,keep:bool)->bool:
 if not valid_catch(catch):return false
 if preload("res://scripts/profile_store.gd").progression_blocked() and not bool(legacy.data.get("teacher",false)):return false
 if keep and state().kept.size()>=capacity():return false
 if not specimen(str(catch.id)).is_empty():return false
 if str(catch.id) in state().recent:return false
 var s=state();var id=str(catch.species);var first=not s.journal.has(id);var better=first or float(catch.kg)>float(s.journal.get(id,{}).get("kg",0));var rec:Dictionary=s.journal.get(id,{"count":0,"kg":0.0,"cm":0.0})
 rec.count=int(rec.count)+1;rec.kg=maxf(float(rec.kg),float(catch.kg));rec.cm=maxf(float(rec.cm),float(catch.cm));s.journal[id]=rec;s.total=int(s.total)+1
 s.visited_pools[str(catch.pool)]=true
 if keep:s.kept.append(catch.duplicate(true))
 s.recent.append(str(catch.id))
 if s.recent.size()>100:s.recent.pop_front()
 if better:preload("res://scripts/record_toast.gd").show(legacy.game,"NEW PERSONAL BEST • "+str(C.fish()[catch.species].name)+" • %.2f kg" % float(catch.kg))
 progress.award(catch,first,better,keep)
 if legacy.game.has_method("add_float_text"):
  var point:Vector2=legacy.game.local_pos if legacy.arcade else legacy.game.position_in_world
  legacy.game.add_float_text(point-Vector2(36,62),"+%d Fishing XP" % progress.last_xp,Color("#90e9df"))
 elif legacy.game.get("fishing")!=null:legacy.game.fishing.xp_popup(progress.last_xp)
 legacy.gardening.find_seed("fishing")
 legacy.weekly.catch_fish(catch)
 legacy.cosmetics.rankings.catch_fish(catch)
 legacy.community.note_fish(catch)
 save();return true
func release(id:String)->void:
 for n in state().kept.size():
  if str(state().kept[n].id)!=id:continue
  state().kept.remove_at(n)
  if state().favorite==id:state().favorite=""
  for slot in 5:
   if state().display[slot]==id:state().display[slot]=""
  save();return
func showcase(id:String,slot:int)->bool:
 if slot<0 or slot>4 or specimen(id).is_empty():return false
 for n in 5:
  if state().display[n]==id:state().display[n]=""
 state().display[slot]=id;save();return true
func set_favorite(id:String)->void:
 if id.is_empty() or not specimen(id).is_empty():state().favorite=id;save()
static func number(v:Variant,maximum:float)->bool:return (v is float or v is int) and is_finite(float(v)) and float(v)>=0 and float(v)<=maximum
static func valid_catch(v:Variant)->bool:
 if not v is Dictionary:return false
 if not v.get("id",null) is String or v.id.is_empty() or v.id.length()>64:return false
 if not v.get("species",null) is String or not C.fish().has(v.species):return false
 if not v.get("pool",null) is String or not C.pools().has(v.pool) or v.species not in C.pools()[v.pool].fish:return false
 if not v.get("date",null) is String or v.date.length()>32 or not v.get("trophy",null) is bool:return false
 if v.has("size_version"):
  if not number(v.size_version,2) or int(v.size_version)!=2 or float(v.size_version)!=2:return false
  if not number(v.get("trophy_rate",null),1):return false
  if bool(v.trophy)!=C.is_trophy(v):return false
 return number(v.get("kg",null),float(C.fish()[v.species].max_kg)*4+.01) and number(v.get("cm",null),900)
static func valid(v:Variant)->bool:
 if not v is Dictionary or not v.get("rod",null) is bool:return false
 if not preload("res://scripts/fishing_progress.gd").valid_extra(v):return false
 for pot in v.get("pots",[]):
  if not valid_catch(pot.catch):return false
 if not v.get("visited_pools",{}) is Dictionary or v.get("visited_pools",{}).size()>C.pools().size():return false
 for pool in v.get("visited_pools",{}):
  if not pool is String or not C.pools().has(pool) or v.visited_pools[pool]!=true:return false
 if not v.get("journal",null) is Dictionary or v.journal.size()>C.fish().size():return false
 if not v.get("kept",null) is Array or v.kept.size()>CAPACITY:return false
 if not v.get("display",null) is Array or v.display.size()!=5:return false
 if not number(v.get("total",null),1000000000) or not v.get("favorite",null) is String:return false
 var ids:Array=[]
 for catch in v.kept:
  if not valid_catch(catch) or catch.id in ids:return false
  ids.append(catch.id)
 if v.favorite!="" and v.favorite not in ids:return false
 var displayed:Array=[]
 for id in v.display:
  if not id is String:return false
  if id=="":continue
  if id not in ids or id in displayed:return false
  displayed.append(id)
 for id in v.journal:
  var rec:Variant=v.journal[id]
  if not id is String or not C.fish().has(id) or not rec is Dictionary:return false
  if not number(rec.get("count",null),1000000000) or not number(rec.get("kg",null),float(C.fish()[id].max_kg)*4+.01) or not number(rec.get("cm",null),900):return false
 return true
