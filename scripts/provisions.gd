extends RefCounted
## One persistent food slot, separate from the three equipment slots.
const SAVE="user://fx_provisions.json"
var game:Node
var arcade:=false
var defs:Dictionary={}
var paid:=0
var packed:=""
var crop:="empty"
var garden:Dictionary={}
var harvests:Dictionary={}
var garden_id:="flowers0"
var parcels:=0
func setup(owner:Node,multi:bool=false)->void:
 game=owner;arcade=multi
 garden=JSON.parse_string(FileAccess.get_file_as_string("res://content/foods/garden.json"))
 defs=JSON.parse_string(FileAccess.get_file_as_string("res://content/foods/catalog.json"))
 var data:Variant=preload("res://scripts/profile_store.gd").read(SAVE)
 if data is Dictionary:packed=str(data.get("food",""));crop=str(data.get("crop","empty"));paid=int(data.get("paid",defs.get(packed,{}).get("cost",0)))
 if data is Dictionary:
  garden_id=str(data.get("garden_id","flowers0"));parcels=clampi(int(data.get("parcels",0)),0,1000000)
  var old:Variant=data.get("harvests",{})
  if old is Dictionary:
   for family in ["orchard","river","roots","flowers"]:harvests[family]=clampi(int(old.get(family,0)),0,1000000)
 if not garden.has(garden_id):garden_id="flowers0"
 if not defs.has(packed):packed=""
 if crop not in ["empty","growing","ready"]:crop="empty"
func save()->void:
 preload("res://scripts/profile_store.gd").write(SAVE,{"food":packed,"crop":crop,"paid":paid,"garden_id":garden_id,"harvests":harvests,"parcels":parcels})
func name_of(id:String)->String:return str(defs.get(id,{}).get("name","Empty"))
func buy(id:String)->bool:
 if arcade or not defs.has(id) or not bool(defs[id].get("shop",true)):return false
 if not packed.is_empty():game.message="Your food slot is full. Refund it before choosing another.";game.message_time=4;return false
 var cost:int=game.legacy.discount(int(defs[id].cost)) if game.get("legacy")!=null else int(defs[id].cost)
 if game.gold<cost:game.message="Not enough CC for "+name_of(id)+".";game.message_time=3;return false
 game.gold-=cost;paid=cost;packed=id;save();game.message="Packed "+name_of(id)+" • it will be used automatically.";game.message_time=4;return true
func refund()->void:
 if arcade or packed.is_empty():return
 game.gold+=paid;paid=0;packed="";save()
func complete_adventure()->void:
 if crop=="growing":crop="ready";save()
func unlocked(id:String)->bool:
 if garden.get(id,{}).get("rare",false):return bool(game.legacy.data.get("teacher",false)) or id in game.legacy.data.get("lodges",{}).get("seeds",[])
 return garden.has(id) and (bool(game.legacy.data.get("teacher",false)) or int(harvests.get(str(garden[id].family),0))>=int(garden[id].need))
func garden_notice(text:String)->void:game.message=text;game.message_time=5
func plant(id:String)->bool:
 if arcade or not garden.has(id):return false
 if crop!="empty":garden_notice("Harvest your current crop before planting another.");return false
 if not unlocked(id):garden_notice("Find this rare seed on a gathering trip first." if bool(garden[id].get("rare",false)) else "Harvest this plant family "+str(garden[id].need)+" times to unlock this seed.");return false
 var cost:=int(garden[id].cost)
 if game.gold<cost:garden_notice("Not enough CC for this seed.");return false
 game.gold-=cost;garden_id=id;crop="growing";save();garden_notice("Planted "+str(garden[id].name)+". Clear an adventure to ripen it.");return true
func harvest()->bool:
 if arcade or crop!="ready":garden_notice("Clear an adventure to ripen your crop first.");return false
 if not packed.is_empty():garden_notice("Empty your food slot before harvesting. Your crop will wait.");return false
 packed=str(garden[garden_id].food);paid=0;crop="empty";var family:=str(garden[garden_id].family);harvests[family]=int(harvests.get(family,0))+1;save();garden_notice("Harvested "+name_of(packed)+"! "+family.capitalize()+" harvests: "+str(harvests[family]));return true
func garden_action()->void:
 if crop=="empty":plant("flowers0")
 elif crop=="ready":harvest()
 else:garden_notice("Clear an adventure to ripen your crop.")
func ship()->bool:
 if arcade or packed.is_empty():garden_notice("Pack one food item to send a parcel.");return false
 packed="";paid=0;parcels+=1;game.gold+=6;save();garden_notice("The squirrels delivered your food parcel. Earned 6 CC. Parcels sent: "+str(parcels));return true
func ready_for(id:String)->bool:
 if arcade:return game.role=="host" and game.started and int(game.health.get(id,0))>0
 return game.mode=="run" and not game.practice and game.menu!="results" and game.health>0
func check_auto(id:String="solo",status_event:bool=false)->bool:
 if not ready_for(id):return false
 var piece:String=str(game.food_slots.get(id,"")) if arcade else packed
 if not defs.has(piece):return false
 var food:Dictionary=defs[piece];var combat:Node=game.adventure.combat
 var key:String=combat.player_key(id);var hp:float=float(game.health.get(id,0)) if arcade else float(game.health)
 var maximum:float=float(game._max_hp(id)) if arcade else game.max_health()
 var trigger:=false
 if status_event and str(food.effect)=="heal":return false
 if str(food.effect)=="heal":trigger=hp<=maximum*float(food.threshold) and hp<maximum
 else:
  for kind in food.statuses:
   if combat.effect_time(key,str(kind))>0:trigger=true
 if not trigger:return false
 # Clear slot first: never recurse into eating it twice through healing/status hooks.
 if arcade:
  game.food_slots[id]="";game.food_loadouts[id]=""
  if id==game.my_id:packed="";save()
 else:packed="";save()
 if str(food.effect)=="heal":
  if arcade:game._heal(id,id,int(food.amount),false)
  else:game.health=minf(maximum,game.health+float(food.amount)*combat.v98.heal_factor(id))
 else:
  for kind in food.statuses:
   if combat.statuses.has(key):combat.statuses[key].erase(str(kind))
  if combat.statuses.has(key) and combat.statuses[key].is_empty():combat.statuses.erase(key)
 if arcade:
  game._emit_effect({"pos":game.positions[id],"radius":40.0,"time":.5,"color":str(food.colour)})
  if id==game.my_id:game.status_label.text="Auto-used "+name_of(piece)
 else:
  game.add_float_text(game.position_in_world+Vector2(-35,-75),"ATE "+name_of(piece),Color(str(food.colour)))
  game.message="Auto-used "+name_of(piece);game.message_time=3
 return true
func sync_local(piece:String)->void:
 var valid:String=piece if defs.has(piece) else ""
 if packed!=valid:packed=valid;save()
func summary(piece:String)->String:
 if not defs.has(piece):return "FOOD: empty • visit the Food Stand"
 var food:Dictionary=defs[piece]
 return "FOOD: "+str(food.name)+" • auto at "+str(int(float(food.threshold)*100))+"% HP" if str(food.effect)=="heal" else "FOOD: "+str(food.name)+" • automatic cleanse"
