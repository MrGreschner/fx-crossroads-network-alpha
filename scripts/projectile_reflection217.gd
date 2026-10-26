extends Node
## One shared physical-projectile interception path; authority owns return damage.
var combat:Node
var pending:Array=[]
func reset()->void:pending.clear()
func flush()->void:
 while not pending.is_empty() and combat.projectiles.size()<96:
  var shot:Dictionary=pending.pop_front()
  if combat.adventure.alive(str(shot.owner)):combat.launch_projectile(str(shot.owner),shot.pos,shot.aim,shot.stats,float(shot.damage),"pellet")
func active(owner:String)->String:
 if not combat.adventure.alive(owner):return ""
 if float(combat.mantis.guards.get(owner,0))>combat.mantis.clock:return "mantis"
 var g:Node=combat.adventure.game
 if combat.adventure.arcade:
  if Time.get_ticks_msec()>=int(g.shield_until.get(owner,0)):return ""
  var hero:Dictionary=g.characters.get(str(g.hero_ids.get(owner,"")),{})
  if bool(hero.get("secondary",{}).get("reflect",false)) or (g.inventory.get(owner,[]) as Array).has("mirror_shard"):return "block"
 elif owner=="solo" and g.block_time>0 and g.block_reflect:return "block"
 return ""
func catch_shot(start:Vector2,finish:Vector2,source:String,amount:float,colour:String,appearance:Dictionary={})->bool:
 if not combat.adventure.authoritative() or not start.is_finite() or not finish.is_finite() or start.is_equal_approx(finish):return false
 var candidates:Array=[]
 for id in combat.adventure.points():
  var owner:String=str(id);var mode:String=active(owner)
  if mode.is_empty() or source==owner or source!="enemy" and not source.begins_with("e:") and combat.v75.friendly(owner,source):continue
  var p:Vector2=combat.owner_pos(owner);var q:Vector2=Geometry2D.get_closest_point_to_segment(p,start,finish)
  var stats:Dictionary=appearance.get("stats",appearance)
  var radius:float=clampf(float(appearance.get("radius",stats.get("projectile_radius",7))),0,46)
  if p.distance_to(q)>34+radius or not combat.path_clear(start,q) or not combat.path_clear(p,q):continue
  candidates.append({"owner":owner,"mode":mode,"point":q,"distance":start.distance_squared_to(q)})
 if candidates.is_empty():return false
 candidates.sort_custom(func(a,b):return float(a.distance)<float(b.distance))
 var chosen:Dictionary=candidates[0];var owner:String=str(chosen.owner)
 if str(chosen.mode)=="mantis":combat.mantis.on_damage(owner,maxf(5,amount))
 var direction:Vector2=(start-finish).normalized()
 var borrowed:Dictionary=combat.adventure.expansion.spell_record(amount,colour,appearance).appearance
 # Flatten prior borrowed art; reflection must not grow nested recipes or copy procs.
 var original:Dictionary=appearance.get("stats",{})
 if not original.get("stolen_appearance",{}).is_empty():borrowed=original.stolen_appearance.duplicate(true)
 var speed:float=clampf(float(appearance.get("speed",420)),100,1200)
 var stats:Dictionary={"name":"Reflected projectile","range":clampf(float(appearance.get("range",700)),300,1200),"speed":speed,"color":colour,"projectile_radius":clampf(float(borrowed.get("radius",7)),3,46),"stolen_appearance":borrowed,"reflected217":true}
 if pending.size()<96:pending.append({"owner":owner,"pos":chosen.point+direction*6,"aim":direction,"stats":stats,"damage":maxf(0,amount)})
 if combat.visuals.size()<64:combat.visuals.append({"owner":owner,"pos":combat.point_array(chosen.point),"radius":27,"time":.2,"color":"#d9f3ef"})
 return true
