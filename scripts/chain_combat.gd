extends Node
## Rook's swept flail, smooth grapple and returning dragline; host-only hits.
var combat:Node
var sweeps:Array=[]
var rushes:Array=[]
var hauls:Array=[]
var follow_through:Dictionary={}
var turns:Dictionary={}
const STYLES=["chain_sweep","grapnel_rush","iron_haul"]
func reset()->void:
 sweeps.clear();rushes.clear();hauls.clear();follow_through.clear();turns.clear()
func clip(origin:Vector2,aim:Vector2,distance:float)->Vector2:
 var point:=origin
 for n in int(ceil(distance/8)):
  var next:=origin+aim*minf(distance,(n+1)*8)
  if not combat.path_clear(point,next):break
  point=next
 return point
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var origin:Vector2=combat.owner_pos(owner)
 aim=aim.normalized()
 if aim.is_zero_approx():aim=Vector2.RIGHT
 match style:
  "chain_sweep":
   if sweeps.size()>=16:return true
   if float(follow_through.get(owner,0))>0 and combat.passive(owner,"follow_through"):
    amount+=float(stats.get("follow_bonus",8));follow_through.erase(owner)
   turns[owner]=int(turns.get(owner,0))+1
   sweeps.append({"owner":owner,"origin":combat.point_array(origin),"aim":combat.point_array(aim),"elapsed":0.0,"duration":.65,"range":clampf(float(stats.get("range",210)),60,300),"arc":deg_to_rad(clampf(float(stats.get("arc_degrees",120)),30,180)),"sign":1 if int(turns[owner])%2 else -1,"damage":amount,"slowed":[],"hits":[]})
  "grapnel_rush":
   for rush in rushes:
    if str(rush.owner)==owner:return true
   if rushes.size()>=8:return true
   var end:=clip(origin,aim,clampf(float(stats.get("range",260)),40,360))
   rushes.append({"owner":owner,"start":combat.point_array(origin),"end":combat.point_array(end),"elapsed":0.0,"duration":.65,"damage":amount,"stun":clampf(float(stats.get("stun_duration",.6)),0,1),"hits":[]})
  "iron_haul":
   if hauls.size()>=8:return true
   var end:=clip(origin,aim,clampf(float(stats.get("range",430)),80,550))
   hauls.append({"owner":owner,"start":combat.point_array(origin),"end":combat.point_array(end),"elapsed":0.0,"duration":1.4,"damage":amount,"catch_damage":float(stats.get("catch_damage",12)),"width":clampf(float(stats.get("width",42)),20,80),"cap":clampi(int(stats.get("max_targets",4)),1,6),"caught":[],"finished":false})
 return true
func moving(owner:String)->bool:
 for rush in rushes:
  if str(rush.owner)==owner:return true
 return false
func move_owner(owner:String,point:Vector2)->void:
 if combat.adventure.arcade:
  var game:Node=combat.adventure.game
  game.positions[owner]=point
  game.charges.erase(owner)
  if owner==game.my_id:game.local_pos=point;game.dodge_time=0
 else:combat.adventure.teleport(owner,point)
func sweep_tip(sweep:Dictionary,elapsed:float)->Vector2:
 var t:=clampf(elapsed/float(sweep.duration),0,1)
 var extension:=minf(1,t/.22) if t<.78 else (1-t)/.22
 var angle:float=combat.vec(sweep.aim).angle()+float(sweep.sign)*float(sweep.arc)*(clampf((t-.22)/.56,0,1)-.5)
 return combat.vec(sweep.origin)+Vector2.from_angle(angle)*float(sweep.range)*extension
func haul_tip(haul:Dictionary,elapsed:float)->Vector2:
 var t:=clampf(elapsed/float(haul.duration),0,1)
 return combat.vec(haul.start).lerp(combat.vec(haul.end),t*2 if t<.5 else (1-t)*2)
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 for owner in follow_through.keys():
  follow_through[owner]=maxf(0,float(follow_through[owner])-delta)
  if float(follow_through[owner])<=0 or not combat.adventure.alive(str(owner)):follow_through.erase(owner)
 # Substeps preserve curved hits and smooth travel even during a slow frame.
 var pieces:=maxi(1,ceili(minf(delta,1)/.025))
 for n in pieces:advance(minf(delta,1)/pieces)
func advance(delta:float)->void:
 for i in range(sweeps.size()-1,-1,-1):
  var sweep:Dictionary=sweeps[i];var owner:=str(sweep.owner)
  if not combat.adventure.alive(owner) or combat.stunned(combat.player_key(owner)):sweeps.remove_at(i);continue
  var old:=float(sweep.elapsed);var before:=sweep_tip(sweep,old)
  sweep.elapsed=minf(float(sweep.duration),old+delta);sweep.origin=combat.point_array(combat.owner_pos(owner))
  var after:=sweep_tip(sweep,float(sweep.elapsed));var origin:Vector2=combat.vec(sweep.origin)
  var tip:Vector2=clip(origin,(after-origin).normalized(),origin.distance_to(after))
  for key in combat.hostile(owner):
   if (sweep.get("slowed",[]) as Array).has(key):continue
   var target:Dictionary=combat.actor(key)
   if target.is_empty() or not target.get("alive",false):continue
   var radius:=float(target.get("npc",{}).get("hit_radius",18))
   if origin.distance_to(tip)>20 and Geometry2D.get_closest_point_to_segment(target.pos,origin,tip).distance_to(target.pos)<=8+radius and combat.path_clear(origin,target.pos):
    if not sweep.has("slowed"):sweep.slowed=[]
    sweep.slowed.append(key);combat.apply_status(key,"slow",1.5,owner,.7)
  if combat.path_clear(origin,after):
   for key in combat.hostile(owner):
    if (sweep.hits as Array).has(key):continue
    var target:Dictionary=combat.actor(key)
    if target.is_empty() or not bool(target.get("alive",false)):continue
    var radius:=float(target.get("npc",{}).get("hit_radius",18))
    if Geometry2D.get_closest_point_to_segment(target.pos,before,after).distance_to(target.pos)<=16+radius and combat.path_clear(origin,target.pos):
     sweep.hits.append(key);combat.damage(key,float(sweep.damage),owner)
  if float(sweep.elapsed)>=float(sweep.duration):sweeps.remove_at(i)
 for i in range(rushes.size()-1,-1,-1):
  var rush:Dictionary=rushes[i];var owner:=str(rush.owner)
  if not combat.adventure.alive(owner) or combat.stunned(combat.player_key(owner)):rushes.remove_at(i);continue
  rush.elapsed+=delta
  if float(rush.elapsed)<.2:continue
  var origin:Vector2=combat.owner_pos(owner)
  var end:Vector2=combat.vec(rush.end)
  var proposed:=origin.move_toward(end,680*delta)
  var next:=clip(origin,(proposed-origin).normalized(),origin.distance_to(proposed))
  move_owner(owner,next)
  for key in combat.hostile(owner):
   if (rush.hits as Array).has(key):continue
   var target:Dictionary=combat.actor(key)
   if target.is_empty() or not bool(target.get("alive",false)):continue
   var radius:=float(target.get("npc",{}).get("hit_radius",18))
   if Geometry2D.get_closest_point_to_segment(target.pos,origin,next).distance_to(target.pos)<=28+radius and combat.path_clear(next,target.pos):
    rush.hits.append(key)
    var before_hp:float=target_health(target)
    combat.damage(key,float(rush.damage)+2,owner)
    var stolen:int=int(minf(2,maxf(0,before_hp-target_health(target))))
    if stolen>0:combat.classics.heal(owner,stolen)
    combat.apply_status(key,"stun",float(rush.stun),owner)
  if float(rush.elapsed)>=float(rush.duration) or next.distance_to(end)<2 or (next==origin and proposed!=origin):
   if not (rush.hits as Array).is_empty() and combat.passive(owner,"follow_through"):follow_through[owner]=4.0
   rushes.remove_at(i)
 for i in range(hauls.size()-1,-1,-1):
  var haul:Dictionary=hauls[i];var owner:=str(haul.owner)
  if not combat.adventure.alive(owner):hauls.remove_at(i);continue
  var old:=float(haul.elapsed);haul.elapsed=minf(float(haul.duration),old+delta)
  var start:Vector2=combat.vec(haul.start);var before:=haul_tip(haul,old);var after:=haul_tip(haul,float(haul.elapsed))
  if old<float(haul.duration)*.5:
   for key in combat.hostile(owner):
    if (haul.caught as Array).has(key) or (haul.caught as Array).size()>=int(haul.cap):continue
    var target:Dictionary=combat.actor(key)
    if target.is_empty() or not bool(target.get("alive",false)):continue
    var radius:=float(target.get("npc",{}).get("hit_radius",18))
    if Geometry2D.get_closest_point_to_segment(target.pos,before,after).distance_to(target.pos)<=float(haul.width)*.5+radius and combat.path_clear(start,target.pos):
     haul.caught.append(key);combat.damage(key,float(haul.catch_damage),owner);combat.apply_status(key,"slow",1.3,owner,.6)
  if float(haul.elapsed)>=float(haul.duration)*.5:
   for key in haul.caught:
    var target:Dictionary=combat.actor(str(key))
    if target.is_empty():continue
    # Bosses take both hits but cannot be hauled; opponents are pulled at half speed.
    if bool(target.get("npc",{}).get("boss",false)):continue
    var speed:=200.0 if target.has("player") else 400.0
    var offset:Vector2=after-(target.pos as Vector2)
    if combat.path_clear(start,target.pos):combat.knock(str(key),offset.normalized(),minf(offset.length(),speed*delta))
  if float(haul.elapsed)>=float(haul.duration):
   for key in haul.caught:
    var target:Dictionary=combat.actor(str(key))
    if not target.is_empty() and combat.path_clear(start,target.pos):combat.damage(str(key),float(haul.damage),owner)
   hauls.remove_at(i)
func snapshot()->Dictionary:
 return {"sweeps":sweeps,"rushes":rushes,"hauls":hauls,"follow_through":follow_through}
func receive(data:Dictionary)->void:
 sweeps=data.get("sweeps",[]);rushes=data.get("rushes",[]);hauls=data.get("hauls",[]);follow_through=data.get("follow_through",{})
func draw_chain(canvas:Node2D,start:Vector2,end:Vector2,color:Color,width:float=3)->void:
 canvas.draw_line(start,end,Color("#263440"),width+3,true)
 canvas.draw_line(start,end,color,width,true)
 var count:=mini(32,int(start.distance_to(end)/14))
 for n in count:
  var point:Vector2=start.lerp(end,float(n+1)/(count+1))
  canvas.draw_arc(point,3,0,TAU,6,Color("#eee2bd"),1,true)
func draw_on(canvas:Node2D,camera:Vector2)->void:
 for sweep in sweeps:
  var origin:Vector2=combat.vec(sweep.origin);var raw:=sweep_tip(sweep,float(sweep.elapsed))
  var tip:=clip(origin,(raw-origin).normalized(),origin.distance_to(raw))
  draw_chain(canvas,origin-camera,tip-camera,Color("#d8ae73"))
  canvas.draw_circle(tip-camera,13,Color("#293745"));canvas.draw_circle(tip-camera,9,Color("#b5cbd0"))
  for n in 5:canvas.draw_line(tip-camera+Vector2.from_angle(TAU*n/5)*8,tip-camera+Vector2.from_angle(TAU*n/5)*16,Color("#e7d5ae"),3,true)
 for rush in rushes:
  var start:Vector2=combat.vec(rush.start);var end:Vector2=combat.vec(rush.end)
  var point:Vector2=start.lerp(end,minf(1,float(rush.elapsed)/.2)) if float(rush.elapsed)<.2 else end
  draw_chain(canvas,combat.owner_pos(str(rush.owner))-camera,point-camera,Color("#8ae0d7"),2)
  canvas.draw_arc(point-camera,11,-PI*.8,PI*.6,12,Color("#e6ddb7"),3,true)
 for haul in hauls:
  var start:Vector2=combat.vec(haul.start);var end:Vector2=combat.vec(haul.end);var tip:=haul_tip(haul,float(haul.elapsed))
  canvas.draw_line(start-camera,end-camera,Color(.9,.72,.38,.14),float(haul.width),true)
  draw_chain(canvas,start-camera,tip-camera,Color("#edc16d"),5)
  canvas.draw_arc(tip-camera,22,-PI*.8,PI*.8,16,Color("#edc16d"),4,true)
  for key in haul.caught:
   var target:Dictionary=combat.actor(str(key))
   if not target.is_empty():draw_chain(canvas,tip-camera,target.pos-camera,Color("#b1dbd4"),2)
 for owner in follow_through:
  if not combat.adventure.alive(str(owner)):continue
  var point:Vector2=combat.owner_pos(str(owner))-camera
  canvas.draw_arc(point,29,-PI*.8,-PI*.2,16,Color("#8ae0d7"),3,true)

func target_health(target:Dictionary)->float:
 if target.has("npc"):return maxf(0,float(target.npc.hp))
 var id:String=str(target.get("player",""))
 if id.begins_with("bond:"):return maxf(0,float(combat.pact.allies.get(id.trim_prefix("bond:"),{}).get("hp",0)))
 if combat.v59.is_mirror(id):return maxf(0,float(combat.v59.copies.get(id.trim_prefix("mirror:"),{}).get("hp",0)))
 return maxf(0,float(combat.adventure.game.health.get(id,0))) if combat.adventure.arcade else maxf(0,float(combat.adventure.game.health))
