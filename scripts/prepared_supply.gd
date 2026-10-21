extends RefCounted
## Separate from profiles/DB keys. A packed bottle survives travel until a real match accepts it.
const STORE="user://fx_prepared_supply.json"
static func read()->Dictionary:
 var value=preload("res://scripts/profile_store.gd").read(STORE)
 return value if value is Dictionary and valid(value) else {}
static func ready(items:Dictionary)->String:
 var id=str(read().get("id",""))
 return id if items.has(id) and preload("res://scripts/supply_slots.gd").consumable(items[id]) else ""
static func set_ready(id:String,paid:int)->void:preload("res://scripts/profile_store.gd").write(STORE,{"id":id,"paid":maxi(0,paid)})
static func restore(game:Node)->void:
 var id=ready(game.items)
 if not id.is_empty() and not game.loadout.has(id) and preload("res://scripts/supply_slots.gd").can_add(game.loadout,id,game.items):game.loadout.append(id);game.loadout_paid[id]=int(read().get("paid",0))
static func commit(id:String)->void:
 if not id.is_empty() and str(read().get("id",""))==id:set_ready("",0)
static func valid(value:Dictionary,items:Dictionary={})->bool:
 var id=value.get("id","");var paid=value.get("paid",0)
 if not id is String or id.length()>64 or not (paid is int or paid is float) or not is_finite(float(paid)) or float(paid)<0 or float(paid)>1000000:return false
 return id.is_empty() or items.is_empty() or items.has(id) and preload("res://scripts/supply_slots.gd").consumable(items[id])
