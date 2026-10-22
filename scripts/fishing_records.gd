extends RefCounted
const C=preload("res://scripts/fishing_catalog.gd")
const CAPACITY=100
var legacy:Node
var dev_ready=false
var income=preload("res://scripts/aquarium_income.gd").new()
var progress=preload("res://scripts/fishing_progress.gd").new()
func defaults()->Dictionary:return {"rod":true,"journal":{},"kept":[],"display":["","","","",""],"favorite":"","total":0}
func state()->Dictionary:
 if not legacy.data.has("fishing"):legacy.data.fishing=defaults()
 income.records=self;income.migrate(legacy.data.fishing)
 legacy.data.fishing.rod=true
 progress.records=self
 progress.migrate(legacy.data.fishing)
 if not legacy.data.fishing.has("visited_pools"):
  legacy.data.fishing.visited_pools={}
  for catch in legacy.data.fishing.kept:
   if C.pools().has(str(catch.get("pool",""))):legacy.data.fishing.visited_pools[str(catch.pool)]=true
  for pot in legacy.data.fishing.get("pots",[]):
   if C.pools().has(str(pot.get("pool",""))):legacy.data.fishing.visited_pools[str(pot.pool)]=true
 if not legacy.data.fishing.has("caught_pools"):
  legacy.data.fishing.caught_pools={}
  for catch in legacy.data.fishing.kept:
   if C.pools().has(str(catch.get("pool",""))):legacy.data.fishing.caught_pools[str(catch.pool)]=true
 if legacy.data.fishing.get("bait",{}).size()<preload("res://scripts/fishing_ecology.gd").BAITS.size()-1:
  for bait in preload("res://scripts/fishing_ecology.gd").BAITS:
   if bait!="basic" and not legacy.data.fishing.get("bait",{}).has(bait):
    if not legacy.data.fishing.has("bait"):legacy.data.fishing.bait={}
    legacy.data.fishing.bait[bait]=0
 for key in progress.extras():
  if not legacy.data.fishing.has(key):legacy.data.fishing[key]=progress.extras()[key]
 var dev=preload("res://scripts/profile_store.gd").dev_session()
 if bool(legacy.data.get("teacher",false)) and dev!=null and dev.active and not dev_ready:
  dev_ready=true
  var s=legacy.data.fishing;s.rod=true;s.deep_sea_rod=true;s.xp=maxi(int(s.xp),progress.threshold(progress.MAX_LEVEL));s.gear={"net":true,"pot":true}
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
func caught_in_realm(realm:String)->bool:
 var s=state()
 for pool in s.caught_pools:
  if str(C.pools().get(pool,{}).get("region",""))==realm:return true
 # Legacy journals can prove a catch where every historical/current home is in this realm.
 for species in s.journal:
  if int(s.journal[species].get("count",0))<=0:continue
  var regions:Array=[]
  for pool in C.pools():
   if species in C.pools()[pool].fish or species in C.data().get("legacy_pool_fish",{}).get(pool,[]):
    var region=str(C.pools()[pool].region)
    if region not in regions:regions.append(region)
  if regions.size()==1 and regions[0]==realm:return true
 return false
func capacity()->int:return mini(CAPACITY,20+10*mini(4,progress.level()/5)+int(progress.perk_bonus("capacity")))
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
 s.visited_pools[str(catch.pool)]=true;s.caught_pools[str(catch.pool)]=true
 if keep:s.kept.append(catch.duplicate(true))
 s.recent.append(str(catch.id))
 if s.recent.size()>100:s.recent.pop_front()
 if better:preload("res://scripts/record_toast.gd").show(legacy.game,("NEW SPECIES • " if first else "NEW PERSONAL BEST • ")+str(C.fish()[catch.species].name)+" • %.2f kg" % float(catch.kg))
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
 income.advance()
 for n in state().kept.size():
  if str(state().kept[n].id)!=id:continue
  state().kept.remove_at(n)
  if state().favorite==id:state().favorite=""
  for slot in 5:
   if state().display[slot]==id:state().display[slot]=""
  save();return
func showcase(id:String,slot:int)->bool:
 if slot<0 or slot>4 or specimen(id).is_empty():return false
 income.advance()
 for n in 5:
  if state().display[n]==id:state().display[n]=""
 state().display[slot]=id;save();return true
func clear_display(slot:int)->bool:
 if slot<0 or slot>=5:return false
 income.advance();state().display[slot]="";save();return true
func set_favorite(id:String)->void:
 if id.is_empty() or not specimen(id).is_empty():state().favorite=id;save()
static func number(v:Variant,maximum:float)->bool:return (v is float or v is int) and is_finite(float(v)) and float(v)>=0 and float(v)<=maximum
static func valid_catch(v:Variant)->bool:
 if not v is Dictionary:return false
 if not v.get("id",null) is String or v.id.is_empty() or v.id.length()>64:return false
 if not v.get("species",null) is String or not C.fish().has(v.species):return false
 if C.fish()[v.species].has("required_bait") and v.get("bait","")!=C.fish()[v.species].required_bait:return false
 if not v.get("pool",null) is String or not C.pools().has(v.pool) or (v.species not in C.pools()[v.pool].fish and v.species not in C.data().get("legacy_pool_fish",{}).get(v.pool,[])):return false
 if not v.get("date",null) is String or v.date.length()>32 or not v.get("trophy",null) is bool:return false
 if v.has("caught_at") and not number(v.caught_at,1e12):return false
 if v.has("size_version"):
  if not number(v.size_version,2) or int(v.size_version)!=2 or float(v.size_version)!=2:return false
  if not number(v.get("trophy_rate",null),1):return false
  if bool(v.trophy)!=C.is_trophy(v):return false
 return number(v.get("kg",null),float(C.fish()[v.species].max_kg)*4+.01) and number(v.get("cm",null),900)
static func valid(v:Variant)->bool:
 if v is Dictionary and v.has("aquarium") and not preload("res://scripts/aquarium_income.gd").valid(v.aquarium):return false
 if v is Dictionary and v.has("deep_sea_rod") and not v.deep_sea_rod is bool:return false
 if v is Dictionary and v.has("voyage") and not valid_voyage(v.voyage):return false
 if not v is Dictionary or not v.get("rod",null) is bool:return false
 if not preload("res://scripts/fishing_progress.gd").valid_extra(v):return false
 var pending_ids:Array=[]
 var basket_pools:Array=[]
 for pot in v.get("pots",[]):
  if str(pot.pool) in basket_pools:return false
  basket_pools.append(str(pot.pool))
  for catch in [pot.catch]+pot.get("reserves",[]):
   if not valid_catch(catch) or catch.id in pending_ids:return false
   pending_ids.append(catch.id)
 if not v.get("visited_pools",{}) is Dictionary or v.get("visited_pools",{}).size()>C.pools().size():return false
 for pool in v.get("visited_pools",{}):
  if not pool is String or not C.pools().has(pool) or v.visited_pools[pool]!=true:return false
 if not v.get("caught_pools",{}) is Dictionary or v.get("caught_pools",{}).size()>C.pools().size():return false
 for pool in v.get("caught_pools",{}):
  if not pool is String or not C.pools().has(pool) or not v.caught_pools[pool] is bool or not bool(v.caught_pools[pool]):return false
 if not v.get("journal",null) is Dictionary or v.journal.size()>C.fish().size():return false
 if not v.get("kept",null) is Array or v.kept.size()>CAPACITY:return false
 if not v.get("display",null) is Array or v.display.size()!=5:return false
 if not number(v.get("total",null),1000000000) or not v.get("favorite",null) is String:return false
 var ids:Array=[]
 for catch in v.kept:
  if not valid_catch(catch) or catch.id in ids:return false
  ids.append(catch.id)
 for id in pending_ids:
  if id in ids or id in v.get("recent",[]):return false
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

static func valid_voyage(v:Variant)->bool:
 if not v is Dictionary:return false
 if v.is_empty():return true
 if v.get("version",0)!=1 or v.get("route","") not in ["lake","coast"]:return false
 for key in ["night_seed","island_found_night"]:
  if v.has(key) and (not (v[key] is int or v[key] is float) or not is_finite(float(v[key])) or float(v[key])!=floor(float(v[key])) or float(v[key])<(-1 if key=="island_found_night" else 0) or float(v[key])>10000000):return false
 if not v.get("boat",null) is Array or v.boat.size()!=2:return false
 var bounds=[14000,10000] if v.route=="coast" else [9000,6800]
 for axis in 2:
  var n=v.boat[axis]
  if not (n is int or n is float) or not is_finite(float(n)) or n<0 or n>bounds[axis]:return false
 for key in ["hull","elapsed","start_hour"]:
  if not (v.get(key) is int or v.get(key) is float) or not is_finite(float(v[key])) or float(v[key])<0:return false
 if v.hull>100 or v.start_hour>=24 or v.elapsed>10000000:return false
 if not v.get("cargo",null) is Array or v.cargo.size()>60 or not v.get("cages",null) is Array or v.cages.size()>3:return false
 if not v.get("release_log",[]) is Array or v.get("release_log",[]).size()>1000:return false
 var ids:Array=[]
 for item in v.cargo+v.get("release_log",[]):
  if not item is Dictionary or not item.get("keep") is bool or not valid_catch(item.get("catch")):return false
  if item in v.get("release_log",[]) and bool(item.keep):return false
  if str(C.pools()[item.catch.pool].region)!="voyage_"+str(v.route):return false
  if item.catch.id in ids:return false
  ids.append(item.catch.id)
 for cage in v.cages:
  if not cage is Dictionary or not cage.get("pos") is Array or cage.pos.size()!=2 or not cage.get("fish") is Array or cage.fish.size()>10:return false
  if not (cage.get("ready") is float or cage.get("ready") is int) or not is_finite(float(cage.ready)) or cage.ready<0:return false
  for axis in 2:
   var n=cage.pos[axis]
   if not (n is int or n is float) or not is_finite(float(n)) or n<0 or n>bounds[axis]:return false
  if not C.pools().has(str(cage.get("pool",""))) or str(C.pools()[cage.pool].region)!="voyage_"+str(v.route):return false
  for catch in cage.fish:
   if not valid_catch(catch) or catch.id in ids or catch.pool!=cage.pool or str(catch.get("method",""))!="pot":return false
   ids.append(catch.id)
 for key in ["seen","repairs"]:
  if not v.get(key) is Array or v[key].size()>40:return false
  for entry in v[key]:
   if not entry is String or entry.length()>80:return false
 if v.has("hero_hp") and (not (v.hero_hp is int or v.hero_hp is float) or not is_finite(float(v.hero_hp)) or v.hero_hp<0 or v.hero_hp>100000):return false
 if not v.get("camp_hp",{}) is Dictionary or v.get("camp_hp",{}).size()>60:return false
 for id in v.get("camp_hp",{}):
  var hp=v.camp_hp[id]
  if not id is String or id.length()>24 or not (hp is int or hp is float) or not is_finite(float(hp)) or hp<0 or hp>100000:return false
 return v.get("banking",false) is bool
