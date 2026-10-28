extends RefCounted
## Flat KO healing is separate from damage-based lifesteal and cannot stack duplicate charms.
static func amount(pack:Array,items:Dictionary)->float:
 var value=0.0;var seen={}
 for id in pack:
  if seen.has(id):continue
  seen[id]=true
  var item:Dictionary=items.get(id,{})
  if str(item.get("effect",""))=="heal_on_ko":value+=maxf(0,float(item.get("amount",0)))
 return value
static func solo(game:Node,enemy:Dictionary)->void:
 if bool(enemy.get("converted",false)) or game.health<=0:return
 var heal=amount(game.inventory,game.items)*game.adventure.combat.v98.heal_factor("solo")
 if heal>0:game.health=minf(game.max_health(),game.health+heal)
static func party(game:Node,id:String)->void:
 if game.role!="host" or int(game.health.get(id,0))<=0:return
 var heal=amount(game.inventory.get(id,[]),game.items)*game.adventure.combat.v98.heal_factor(id)
 if heal>0:game.health[id]=mini(game._max_hp(id),int(game.health[id])+int(ceil(heal)))
