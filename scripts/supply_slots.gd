extends RefCounted
## Inventory stays a flat list on the wire; logical keys stay stable when a bottle is consumed.
const EFFECTS=["heal","cleanse","lodge_guard","invulnerable","haste","shockwave"]
static func consumable(spec:Dictionary)->bool:return str(spec.get("effect","")) in EFFECTS
static func indices(pack:Array,items:Dictionary,bottles:bool)->Array:
 var result=[]
 for n in pack.size():
  if consumable(items.get(str(pack[n]),{}))==bottles:result.append(n)
 return result
static func index(pack:Array,logical:int,items:Dictionary)->int:
 if logical<0 or logical>3:return -1
 var found=indices(pack,items,logical==3);var n=0 if logical==3 else logical
 return int(found[n]) if n<found.size() else -1
static func can_add(pack:Array,id:String,items:Dictionary)->bool:
 if not items.has(id):return false
 var bottle=consumable(items[id])
 return indices(pack,items,bottle).size()<(1 if bottle else 3) and (bottle or not pack.has(id) or str(items[id].get("effect","")) not in ["bonus_damage","bonus_speed","lifesteal","armor","bonus_health","cooldown"])
static func price(spec:Dictionary,legacy:Node=null)->int:
 var base=maxi(0,int(spec.get("cost",0)))
 return legacy.discount(base) if legacy!=null else base
static func refund(game:Node)->void:
 for id in game.loadout:
  if bool(game.items.get(id,{}).get("crafted",false)):
   var s=game.legacy.lodge_economy.state();s.potions[id]=mini(99,int(s.potions.get(id,0))+1)
  else:game.gold+=int(game.loadout_paid.get(id,game.items.get(id,{}).get("cost",0)))
 preload("res://scripts/prepared_supply.gd").set_ready("",0)
 game.loadout.clear();game.loadout_paid.clear();game.legacy.save();game.save_profile()
