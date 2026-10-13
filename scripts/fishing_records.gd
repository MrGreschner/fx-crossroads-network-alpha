extends RefCounted
const C=preload("res://scripts/fishing_catalog.gd")
const CAPACITY=100
var legacy:Node
func defaults()->Dictionary:return {"rod":false,"journal":{},"kept":[],"display":["","","","",""],"favorite":"","total":0}
func state()->Dictionary:
 if not legacy.data.has("fishing"):legacy.data.fishing=defaults()
 if bool(legacy.data.get("teacher",false)):legacy.data.fishing.rod=true
 return legacy.data.fishing
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
 if keep and state().kept.size()>=CAPACITY:return false
 if not specimen(str(catch.id)).is_empty():return false
 var s=state();var id=str(catch.species);var rec:Dictionary=s.journal.get(id,{"count":0,"kg":0.0,"cm":0.0})
 rec.count=int(rec.count)+1;rec.kg=maxf(float(rec.kg),float(catch.kg));rec.cm=maxf(float(rec.cm),float(catch.cm));s.journal[id]=rec;s.total=int(s.total)+1
 if keep:s.kept.append(catch.duplicate(true))
 legacy.weekly.catch_fish(catch)
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
 return number(v.get("kg",null),float(C.fish()[v.species].max_kg)*4+.01) and number(v.get("cm",null),900)
static func valid(v:Variant)->bool:
 if not v is Dictionary or not v.get("rod",null) is bool:return false
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
