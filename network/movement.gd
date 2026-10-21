extends RefCounted
## Shared 60 Hz movement: clients predict; the server owns the accepted position.
const DT=1.0/60.0
static func movable(g:Node,id:String)->bool:
 if g.arena_world.shatter.active():return g.arena_world.shatter.playable(id)
 var c=g.adventure.combat
 return int(g.health.get(id,0))>0 and not c.stunned(c.player_key(id)) and not c.twister.chanting(id) and not g.charges.has(id) and not c.stance_heroes.moving(id) and not c.v90.moving(id) and not c.v98.moving(id) and not c.chain.moving(id) and not c.classics.locked(id) and not c.v78.locked(id) and not c.v79.moving(id) and not c.v110.charging(id) and not c.halloween.moving(id) and not c.release_heroes.locked(id) and not g.adventure.immersive.aboard(id) and not c.v48.moving(id)
static func advance(g:Node,id:String,p:Vector2,direction:Vector2)->Vector2:
 if g.arena_world.shatter.active():return p+direction.limit_length(1)*g.arena_world.shatter.SPEED*DT if g.arena_world.shatter.playable(id) and not g.arena_world.shatter.airborne(id) else p
 if not movable(g,id):
  if g.adventure.combat.stunned(g.adventure.combat.player_key(id)):g.adventure.polish.momentum.erase(id)
  return p
 var c=g.adventure.combat
 var speed:float=float(g.characters.get(str(g.hero_ids.get(id,g.selected_hero)),{}).get("speed",230))*c.speed_factor(c.player_key(id))*g.legacy.speed_factor(id)*terrain_factor(g,p,id)
 if c.classics.channeling(id):speed*=g.legacy.channel_speed(id)
 for item in g.inventory.get(id,[]):
  if str(g.items.get(str(item),{}).get("effect",""))=="bonus_speed":speed+=float(g.items[item].get("amount",0))
 for item in g.inventory.get(id,[]):
  if str(g.items.get(str(item),{}).get("effect",""))=="bonus_speed":speed*=float(g.items[item].get("speed_multiplier",1.0))
 if Time.get_ticks_msec()<int(g.haste_until.get(id,0)):speed*=float(g.item_haste_scale.get(id,1.35))
 if Time.get_ticks_msec()<int(g.stealth_until.get(id,0)):speed*=1.45
 var dash:Dictionary=g.net_dash.get(id,{})
 if not dash.is_empty() and float(dash.time)>0:
  var remaining=float(dash.time);dash.time=maxf(0,remaining-DT)
  return g._move_actor(p,dash.direction*(330.0+370.0*sin(PI*remaining/.26))*g.arena_world.objective.carrier_factor(id)*DT)
 return g._move_actor(p,g.adventure.polish.motion(id,p,direction.limit_length(1)*speed*DT,DT))

static func prepare(g:Node,id:String)->Dictionary:
 if not movable(g,id):
  if g.adventure.combat.stunned(g.adventure.combat.player_key(id)):g.adventure.polish.momentum.erase(id)
  return {"movable":false}
 var c=g.adventure.combat
 var speed:float=float(g.characters.get(str(g.hero_ids.get(id,g.selected_hero)),{}).get("speed",230))*c.speed_factor(c.player_key(id))*g.legacy.speed_factor(id)
 if c.classics.channeling(id):speed*=g.legacy.channel_speed(id)
 # Preserve the original operation order: terrain slow applies before additive items.
 var bonus=0.0
 for item in g.inventory.get(id,[]):
  if str(g.items.get(str(item),{}).get("effect",""))=="bonus_speed":bonus+=float(g.items[item].get("amount",0))
 var multiplier=1.0
 for item in g.inventory.get(id,[]):
  if str(g.items.get(str(item),{}).get("effect",""))=="bonus_speed":multiplier*=float(g.items[item].get("speed_multiplier",1.0))
 if Time.get_ticks_msec()<int(g.haste_until.get(id,0)):multiplier*=float(g.item_haste_scale.get(id,1.35))
 if Time.get_ticks_msec()<int(g.stealth_until.get(id,0)):multiplier*=1.45
 return {"movable":true,"speed":speed,"bonus":bonus,"multiplier":multiplier}
static func advance_prepared(g:Node,id:String,p:Vector2,direction:Vector2,context:Dictionary)->Vector2:
 if g.arena_world.shatter.active():return advance(g,id,p,direction)
 if not bool(context.movable):return p
 var speed=(float(context.speed)*terrain_factor(g,p,id)+float(context.bonus))*float(context.multiplier)
 var dash:Dictionary=g.net_dash.get(id,{})
 if not dash.is_empty() and float(dash.time)>0:
  var remaining=float(dash.time);dash.time=maxf(0,remaining-DT)
  return g._move_actor(p,dash.direction*(330.0+370.0*sin(PI*remaining/.26))*g.arena_world.objective.carrier_factor(id)*DT)
 return g._move_actor(p,g.adventure.polish.motion(id,p,direction.limit_length(1)*speed*DT,DT))

static func terrain_factor(g:Node,p:Vector2,id:String="")->float:
 var factor:float=g.arena_world.slow(p)*g.arena_world.objective.carrier_factor(id)
 if g.mode=="coop":
  if g.adventure.immersive.active:factor*=g.adventure.immersive.terrain_speed(p)
  elif g.adventure.school.active:factor*=g.adventure.school.terrain_speed(p)
 return factor
