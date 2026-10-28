extends RefCounted
## Town equipment crosses the lobby once, and is committed only by an accepted Descent start.
const KEY="fx_prepared_equipment238"
static func owner(g:Node)->String:
 var account=g.get_tree().root.get_node_or_null("FXAccount")
 return str(account.user.get("id","offline")) if account!=null else "offline"
static func clean(value:Variant,items:Dictionary)->Array:
 var result:Array=[]
 if not value is Array:return result
 for raw in value.slice(0,16):
  if not raw is String or not items.has(raw):continue
  if preload("res://scripts/supply_slots.gd").consumable(items[raw]):continue
  if preload("res://scripts/supply_slots.gd").can_add(result,raw,items):result.append(raw)
 return result
static func capture(g:Node)->void:
 if g.mode!="town":return
 var pack=clean(g.loadout,g.items);var paid={}
 for id in pack:paid[id]=maxi(0,int(g.loadout_paid.get(id,g.items[id].get("cost",0))))
 g.get_tree().root.set_meta(KEY,{"items":pack,"paid":paid,"owner":str(g.get("prepared_equipment_owner"))})
static func ready(g:Node)->Array:
 var value:Variant=g.get_tree().root.get_meta(KEY,{})
 return clean(value.get("items",[]),g.items) if value is Dictionary and str(value.get("owner",""))==owner(g) else []
static func restore(g:Node)->void:
 var value:Variant=g.get_tree().root.get_meta(KEY,{})
 if not value is Dictionary:return
 for id in ready(g):
  if not g.loadout.has(id) and preload("res://scripts/supply_slots.gd").can_add(g.loadout,id,g.items):
   g.loadout.append(id);g.loadout_paid[id]=maxi(0,int(value.get("paid",{}).get(id,g.items[id].get("cost",0))))
 if g.get_tree().root.has_meta(KEY):g.get_tree().root.remove_meta(KEY)
static func commit(g:Node,accepted:Variant)->void:
 var packed=ready(g);var used=clean(accepted,g.items)
 if packed.is_empty() or used!=packed:return
 g.get_tree().root.remove_meta(KEY)
