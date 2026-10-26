extends Node
var combat:Node
var intakes:Dictionary={}
var held:Dictionary={}
var faults:Array=[]
var hoists:Array=[]
var ramps:Array=[]
var clouds:Array=[]
var lanes:Array=[]
var storms:Array=[]
var draws:Array=[]
var clock:float=0
const STYLES=["vacuum_intake","brush_crush","grand_draw","pocket_rain","tailwind_seam","thunder_procession","fault_steps","stone_hoist","rolling_rampart"]
func reset()->void:
 intakes.clear();held.clear();faults.clear();hoists.clear();ramps.clear();clouds.clear();lanes.clear();storms.clear();draws.clear();clock=0
func holding(owner:String,pressed:bool,aim:Vector2)->void:
 combat.polish.aim(owner,aim)
 combat.twister.holding(owner,pressed,aim)
 if not combat.adventure.authoritative():return
 held[owner]=.45 if pressed else 0.0
 if intakes.has(owner):
  intakes[owner].aim=combat.point_array(aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT)
  if not pressed:release(owner)
func release(owner:String)->void:
 if not intakes.has(owner):return
 var entry:Dictionary=intakes[owner]
 if entry.has("captured") and combat.adventure.alive(owner):
  var amount:float=clampf(float(entry.captured.damage)*2,36,60)+(8 if combat.passive(owner,"deep_filter") else 0)
  combat.launch_projectile(owner,combat.owner_pos(owner)+combat.vec(entry.aim)*35,combat.vec(entry.aim),{"range":500,"speed":570,"color":entry.captured.color},amount,"vacuum_return")
 intakes.erase(owner)
func catch_shot(start:Vector2,finish:Vector2,shot_owner:String,amount:float,colour:String,moving:bool=true,appearance:Dictionary={})->bool:
 if combat.v112.catch_shot(start,finish,shot_owner):return true
 if combat.v98.catch_shot(start,finish,shot_owner):return true
 if combat.party_heroes.catch_shot(start,finish,shot_owner):return true
 if not combat.adventure.authoritative():return false
 if combat.adventure.immersive.marsh_encounters.catch_shot(start,finish,shot_owner,moving):return true
 if moving and combat.adventure.expansion.catch_shot(start,finish,shot_owner,amount,colour,appearance):return true
 if combat.release_heroes.catch_shot(start,finish,shot_owner):return true
 if moving and combat.v75.catch_shot(start,finish,shot_owner,amount,colour):return true
 if moving and combat.chronicle.catch_shot(start,finish,shot_owner):return true
 for lane in lanes:
  var owner:String=str(lane.owner)
  if not combat.passive(owner,"stormcatcher") or int(lane.get("caught",0))>=3 or not combat.adventure.alive(owner):continue
  if shot_owner!="enemy" and not (combat.adventure.arcade and combat.adventure.game.mode=="arena" and combat.adventure.game._rival(owner,shot_owner)):continue
  var a:Vector2=combat.vec(lane.start);var b:Vector2=combat.vec(lane.end)
  var crossing:Variant=Geometry2D.segment_intersects_segment(start,finish,a,b)
  var near:Vector2=Geometry2D.get_closest_point_to_segment(finish,a,b)
  if crossing==null and near.distance_squared_to(finish)>1600:continue
  var p:Vector2=crossing if crossing!=null else near
  if not combat.path_clear(start,p):continue
  lane["caught"]=int(lane.get("caught",0))+1
  combat.launch_projectile(owner,p,(b-a).normalized(),{"range":450,"speed":500,"color":"#dbebff"},10,"homing")
  combat.visuals.append({"pos":combat.point_array(p),"radius":30,"time":.4,"color":"#d6edff"})
  return true
 return catch_intake(start,finish,shot_owner,amount,colour)
func catch_travelling(start:Vector2,finish:Vector2,source:String,amount:float,colour:String,appearance:Dictionary={}) -> bool:
 if not combat.adventure.authoritative():return false
 if combat.adventure.immersive.marsh_encounters.catch_shot(start,finish,source):return true
 if combat.adventure.expansion.catch_shot(start,finish,source,amount,colour,appearance):return true
 return catch_intake(start,finish,source,amount,colour)
func catch_intake(start:Vector2,finish:Vector2,shot_owner:String,amount:float,colour:String)->bool:
 # Shared by bespoke travelling projectiles as well as the standard shot pool.
 if not combat.adventure.authoritative():return false
 for owner in intakes.keys():
  var entry:Dictionary=intakes[owner]
  if entry.has("captured") or float(entry.age)>.4 or not combat.adventure.alive(str(owner)) or combat.stunned(combat.player_key(str(owner))):continue
  if shot_owner!="enemy" and not (combat.adventure.arcade and combat.adventure.game.mode in ["arena","battlegrounds"] and combat.adventure.game._rival(str(owner),shot_owner)):continue
  var origin:Vector2=combat.owner_pos(str(owner))
  var aim:Vector2=combat.vec(entry.aim)
  var nozzle:Vector2=origin+aim*45
  var tip:Vector2=origin+aim*maxf(45,float(entry.get("range",94))-28)
  var closest:Vector2=Geometry2D.get_closest_point_to_segment(nozzle,start,finish)
  var distance:float=closest.distance_to(nozzle)
  var crossing:Variant=Geometry2D.segment_intersects_segment(start,finish,nozzle,tip)
  if crossing!=null:closest=crossing;distance=0
  else:
   for point in [start,finish,Geometry2D.get_closest_point_to_segment(tip,start,finish)]:
    var d:float=point.distance_to(Geometry2D.get_closest_point_to_segment(point,nozzle,tip))
    if d<distance:distance=d;closest=point
  if distance>28 or not combat.path_clear(start,closest) or not combat.path_clear(origin,closest):continue
  entry.captured={"damage":amount,"color":colour}
  return true
 return false
func cone(origin:Vector2,aim:Vector2,point:Vector2,reach:float,cosine:float)->bool:
 var offset:Vector2=point-origin
 return offset.length()<=reach and (offset.length()<1 or aim.dot(offset.normalized())>=cosine) and combat.path_clear(origin,point)
func hit_cone(owner:String,aim:Vector2,reach:float,angle:float,amount:float,slow:bool=false)->void:
 var origin:Vector2=combat.owner_pos(owner)
 for key in combat.hostile(owner):
  var actor:Dictionary=combat.actor(key)
  if actor.is_empty() or not bool(actor.alive) or not cone(origin,aim,actor.pos,reach,cos(deg_to_rad(angle*.5))):continue
  combat.damage(key,amount,owner)
  if slow:combat.apply_status(key,"slow",1,owner,.6)
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:String=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 aim=aim.normalized()
 if aim.is_zero_approx():aim=Vector2.RIGHT
 var origin:Vector2=combat.owner_pos(owner)
 match style:
  "vacuum_intake":
   if not intakes.has(owner):
    intakes[owner]={"owner":owner,"aim":combat.point_array(aim),"age":0.0,"tick":.7,"damage":amount,"range":float(stats.get("range",94))}
    held[owner]=.45
  "brush_crush":
   hit_cone(owner,aim,100,110,amount)
   combat.visuals.append({"style":"brush_crush","owner":owner,"pos":combat.point_array(origin),"aim":combat.point_array(aim),"radius":100,"time":.35,"color":"#e0ba78"})
  "grand_draw":
   if draws.size()<8:draws.append({"owner":owner,"aim":combat.point_array(aim),"time":2.5})
  "pocket_rain":
   if clouds.size()<32:clouds.append({"owner":owner,"start":combat.point_array(origin),"aim":combat.point_array(aim),"age":0.0,"damage":amount})
  "tailwind_seam":
   for lane in lanes.duplicate():
    if lane.owner==owner:lanes.erase(lane)
   if lanes.size()<8:lanes.append({"owner":owner,"start":combat.point_array(origin),"end":combat.point_array(combat.chain.clip(origin,aim,400)),"time":4.0,"tick":0.0,"damage":amount})
  "thunder_procession":
   if storms.size()<8:storms.append({"owner":owner,"start":combat.point_array(origin),"aim":combat.point_array(aim),"age":0.0,"damage":amount,"hits":[[],[],[]]})
  "fault_steps":
   if faults.size()<24:
    var entry={"owner":owner,"start":combat.point_array(origin),"aim":combat.point_array(aim),"age":0.0,"damage":amount,"hits":[],"next":0,"segments":[]}
    faults.append(entry)
    erupt_fault(entry)
  "stone_hoist":
   var key:String=combat.classics.nearest(owner,origin,220,[],aim)
   if not key.is_empty() and hoists.size()<24:
    var target:Dictionary=combat.actor(key)
    combat.apply_status(key,"stun",.4 if bool(target.get("npc",{}).get("boss",false)) else 1.2,owner)
    hoists.append({"owner":owner,"pos":combat.point_array(target.pos),"age":0.0,"damage":amount})
  "rolling_rampart":
   if ramps.size()<8:ramps.append({"owner":owner,"pos":combat.point_array(origin),"aim":combat.point_array(aim),"distance":0.0,"damage":amount,"hits":[]})
 return true
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 for owner in held.keys():held[owner]=maxf(0,float(held[owner])-delta)
 for owner in intakes.keys():
  if not combat.adventure.alive(str(owner)) or combat.stunned(combat.player_key(str(owner))):intakes.erase(owner);continue
  var entry:Dictionary=intakes[owner]
  entry.age+=delta
  if float(held.get(owner,0))<=0 or float(entry.age)>=6:release(str(owner));continue
  if not entry.has("captured"):
   entry.tick+=delta
   if float(entry.tick)>=.7:
    entry.tick=fposmod(float(entry.tick),.7)
    hit_cone(str(owner),combat.vec(entry.aim),float(entry.get("range",94)),70,float(entry.damage),true)
 for n in range(draws.size()-1,-1,-1):
  var entry:Dictionary=draws[n]
  if not combat.adventure.alive(entry.owner):draws.remove_at(n);continue
  var used:float=minf(delta,float(entry.time));entry.time-=delta
  entry.aim=combat.point_array(combat.polish.steer(str(entry.owner),combat.vec(entry.aim),2.8,used))
  var origin:Vector2=combat.owner_pos(entry.owner);var aim:Vector2=combat.vec(entry.aim)
  for key in combat.hostile(entry.owner):
   var actor:Dictionary=combat.actor(key)
   if actor.is_empty() or not bool(actor.alive) or not cone(origin,aim,actor.pos,320,.5):continue
   var nozzle:Vector2=origin+aim*52
   var distance:float=actor.pos.distance_to(nozzle)
   var strength:float=.3 if bool(actor.get("npc",{}).get("boss",false)) else 1
   if distance>8:combat.knock(key,(nozzle-actor.pos).normalized(),minf(distance-8,used*150*strength))
  if float(entry.time)<=0:draws.remove_at(n)
 for n in range(clouds.size()-1,-1,-1):
  var entry:Dictionary=clouds[n];entry.age+=delta
  var origin:Vector2=combat.vec(entry.start);var aim:Vector2=combat.vec(entry.aim)
  var point:Vector2=combat.chain.clip(origin,aim,140*minf(1,float(entry.age)/.3))
  if float(entry.age)>=.55:
   for angle in [-.16,0,.16]:combat.launch_projectile(entry.owner,point,aim.rotated(angle),{"range":260,"speed":430,"color":"#b5e3f0"},float(entry.damage),"rain_drop")
   clouds.remove_at(n)
 for n in range(lanes.size()-1,-1,-1):
  var entry:Dictionary=lanes[n];var used:float=minf(delta,float(entry.time));entry.time-=delta;entry.tick+=used
  var start:Vector2=combat.vec(entry.start);var finish:Vector2=combat.vec(entry.end)
  for id in combat.adventure.points():
   var point:Vector2=combat.adventure.points()[id]
   if not combat.adventure.alive(str(id)) or (combat.adventure.arcade and combat.adventure.game.mode in ["arena","battlegrounds"] and combat.adventure.game._rival(entry.owner,str(id))):continue
   if Geometry2D.get_closest_point_to_segment(point,start,finish).distance_to(point)<40 and combat.path_clear(start,point):combat.apply_status(combat.player_key(str(id)),"rune_stride",.3,entry.owner,.3)
  while float(entry.tick)>=1:
   entry.tick-=1
   for key in combat.hostile(entry.owner):
    var actor:Dictionary=combat.actor(key)
    if not actor.is_empty() and Geometry2D.get_closest_point_to_segment(actor.pos,start,finish).distance_to(actor.pos)<40 and combat.path_clear(start,actor.pos):combat.damage(key,float(entry.damage),entry.owner)
 for n in range(storms.size()-1,-1,-1):
  var entry:Dictionary=storms[n];entry.age+=delta
  for cloud in 3:
   var age:float=float(entry.age)-cloud*.45
   if age<0 or age>2.7:continue
   var point:Vector2=combat.chain.clip(combat.vec(entry.start),combat.vec(entry.aim),age*180)
   for key in combat.hostile(entry.owner):
    var actor:Dictionary=combat.actor(key)
    if actor.is_empty() or key in entry.hits[cloud] or point.distance_to(actor.pos)>75 or not combat.path_clear(point,actor.pos):continue
    entry.hits[cloud].append(key);combat.damage(key,float(entry.damage),entry.owner)
    combat.visuals.append({"start":combat.point_array(actor.pos-Vector2(0,65)),"end":combat.point_array(actor.pos),"width":3,"time":.25,"color":"#d8edff"})
  if float(entry.age)>3.6:storms.remove_at(n)
 for n in range(faults.size()-1,-1,-1):
  var entry:Dictionary=faults[n];entry.age+=delta
  if combat.adventure.alive(str(entry.owner)):
   while int(entry.next)<3 and float(entry.age)>=int(entry.next)*.14:erupt_fault(entry)
  if float(entry.age)>.7:faults.remove_at(n)
 for n in range(hoists.size()-1,-1,-1):
  var entry:Dictionary=hoists[n];entry.age+=delta
  if float(entry.age)>=1.2:
   for key in combat.hostile(entry.owner):
    var actor:Dictionary=combat.actor(key)
    if not actor.is_empty() and combat.vec(entry.pos).distance_to(actor.pos)<=85 and combat.path_clear(combat.vec(entry.pos),actor.pos):combat.damage(key,float(entry.damage),entry.owner)
   combat.visuals.append({"pos":entry.pos,"radius":85,"time":.4,"color":"#d9d4b7"});hoists.remove_at(n)
 for n in range(ramps.size()-1,-1,-1):
  var entry:Dictionary=ramps[n];var start:Vector2=combat.vec(entry.pos);var aim:Vector2=combat.vec(entry.aim);var finish:Vector2=start+aim*minf(180*delta,340-float(entry.distance))
  if not combat.path_clear(start,finish):ramps.remove_at(n);continue
  entry.pos=combat.point_array(finish);entry.distance+=start.distance_to(finish)
  for key in combat.hostile(entry.owner):
   var actor:Dictionary=combat.actor(key)
   if actor.is_empty() or key in entry.hits:continue
   var closest:Vector2=Geometry2D.get_closest_point_to_segment(actor.pos,start,finish)
   var offset:Vector2=actor.pos-closest
   if absf(offset.dot(aim))<28 and absf(offset.dot(aim.orthogonal()))<120 and combat.path_clear(closest,actor.pos):
    entry.hits.append(key);combat.damage(key,float(entry.damage),entry.owner);combat.knock(key,aim,80)
  if float(entry.distance)>=340:ramps.remove_at(n)
func erupt_fault(entry:Dictionary)->void:
 # Each NEW eruption starts from the moving badger; erupted ground stays planted.
 var origin:Vector2=combat.owner_pos(str(entry.owner))
 var point:Vector2=combat.chain.clip(origin,combat.vec(entry.aim),65+int(entry.next)*50)
 entry.segments.append({"pos":combat.point_array(point),"born":float(entry.age)})
 entry.next=int(entry.next)+1
 for key in combat.hostile(str(entry.owner)):
  var target:Dictionary=combat.actor(key)
  if target.is_empty() or not bool(target.alive) or key in entry.hits or point.distance_to(target.pos)>42 or not combat.path_clear(origin,target.pos):continue
  entry.hits.append(key);combat.damage(key,float(entry.damage),str(entry.owner))
 if combat.passive(str(entry.owner),"bedrock") and not entry.hits.is_empty():combat.apply_status(combat.player_key(str(entry.owner)),"guard",3,str(entry.owner),minf(.2,entry.hits.size()*.05))
func snapshot()->Dictionary:return {"intakes":intakes,"faults":faults,"hoists":hoists,"ramps":ramps,"clouds":clouds,"lanes":lanes,"storms":storms,"draws":draws,"clock":clock}
func receive(data:Dictionary)->void:
 intakes=data.get("intakes",{});faults=data.get("faults",[]);hoists=data.get("hoists",[]);ramps=data.get("ramps",[]);clouds=data.get("clouds",[]);lanes=data.get("lanes",[]);storms=data.get("storms",[]);draws=data.get("draws",[]);clock=float(data.get("clock",0))
func cloud_art(c:Node2D,point:Vector2,storm:bool=false)->void:
 for offset in [Vector2(-15,0),Vector2(0,-6),Vector2(15,0)]:c.draw_circle(point+offset,16,Color("#7899af") if storm else Color("#d9e9db"))
 c.draw_line(point+Vector2(-23,8),point+Vector2(23,8),Color("#b5d2dd"),5,true)
 if storm:c.draw_polyline(PackedVector2Array([point+Vector2(0,9),point+Vector2(-5,27),point+Vector2(5,26),point+Vector2(0,47)]),Color("#fff0b3"),3,true)
func draw_cone(c:Node2D,origin:Vector2,aim:Vector2,reach:float,half_angle:float)->void:
 var poly:PackedVector2Array=PackedVector2Array([origin])
 for n in 17:poly.append(origin+aim.rotated(-half_angle+n*half_angle*2/16)*reach)
 var nozzle:Vector2=origin+aim*35
 c.draw_polyline(PackedVector2Array([origin+Vector2(4,-13),origin+aim*21+Vector2(0,-8),nozzle]),Color("#6b7773"),5,true)
 c.draw_line(nozzle-aim.orthogonal()*8,nozzle+aim.orthogonal()*8,Color("#a1b4a3"),7,true)
 c.draw_colored_polygon(poly,Color(.65,.87,.84,.1))
 c.draw_arc(origin,reach,aim.angle()-half_angle,aim.angle()+half_angle,32,Color(.75,.92,.86,.5),2,true)
 for n in 12:
  var t:float=1-fposmod(clock*1.5+n*.083,1)
  var direction:Vector2=aim.rotated(sin(n*7)*half_angle)
  var point:Vector2=origin+direction*(35+t*(reach-35))
  c.draw_line(point,point-direction*14,Color(.87,.97,.84,.5),2,true)
func draw_on(c:Node2D,camera:Vector2)->void:
 for owner in intakes:
  var entry:Dictionary=intakes[owner];var origin:Vector2=combat.owner_pos(str(owner))-camera;var aim:Vector2=combat.vec(entry.aim)
  draw_cone(c,origin,aim,float(entry.get("range",94)),.61)
  if entry.has("captured"):
   var nozzle:Vector2=origin+aim*45
   c.draw_circle(nozzle,10,Color(str(entry.captured.color)))
   c.draw_arc(nozzle,14,clock*4,clock*4+PI*1.7,24,Color("#fff0b6"),2,true)
  elif float(entry.age)<=.4:
   # A short bright ring shows when intake can still catch a shot.
   var nozzle:Vector2=origin+aim*45
   c.draw_arc(nozzle,17,-PI/2,-PI/2+TAU*maxf(.02,1-float(entry.age)/.4),24,Color("#b9fff0"),2.5,true)
 for entry in draws:
  draw_cone(c,combat.owner_pos(entry.owner)-camera,combat.vec(entry.aim),320,PI/3)
 for entry in clouds:
  var point:Vector2=combat.chain.clip(combat.vec(entry.start),combat.vec(entry.aim),140*minf(1,float(entry.age)/.3))
  cloud_art(c,point-camera-Vector2(0,15))
 for entry in lanes:
  if combat.passive(str(entry.owner),"stormcatcher"):
   var a:Vector2=combat.vec(entry.start)-camera;var b:Vector2=combat.vec(entry.end)-camera
   c.draw_line(a,b,Color(.7,.86,1,.3),12,true)
   for n in 5:
    var p:Vector2=a.lerp(b,float(n)/4)
    c.draw_line(p+Vector2(-5,-9),p+Vector2(4,0),Color("#e5f5ff"),2,true);c.draw_line(p+Vector2(4,0),p+Vector2(-3,9),Color("#e5f5ff"),2,true)
  var start:Vector2=combat.vec(entry.start)-camera;var finish:Vector2=combat.vec(entry.end)-camera;var side:Vector2=(finish-start).normalized().orthogonal()*40
  c.draw_colored_polygon(PackedVector2Array([start-side,finish-side,finish+side,start+side]),Color(.6,.85,.94,.12))
  for n in 8:
   var point:Vector2=start.lerp(finish,fposmod(clock*.6+n/8.0,1))
   c.draw_arc(point,11,-.7,.7,12,Color("#aed8e5"),2,true)
 for entry in storms:
  for index in 3:
   var age:float=float(entry.age)-index*.45
   if age>=0 and age<=2.7:cloud_art(c,combat.chain.clip(combat.vec(entry.start),combat.vec(entry.aim),age*180)-camera-Vector2(0,55),true)
 for entry in faults:
  for segment in entry.get("segments",[]):
   var age:float=float(entry.age)-float(segment.born)
   if age<0 or age>.45:continue
   var point:Vector2=combat.vec(segment.pos)-camera
   var rise:float=sin(clampf(age/.45,0,1)*PI)*22
   c.draw_colored_polygon(PackedVector2Array([point+Vector2(-27,6),point+Vector2(-20,-rise),point+Vector2(10,-rise-8),point+Vector2(27,5)]),Color("#849a91"))
   c.draw_polyline(PackedVector2Array([point+Vector2(-20,-rise),point+Vector2(10,-rise-8),point+Vector2(27,5)]),Color("#c0ccb2"),3,true)
 for entry in hoists:
  var point:Vector2=combat.vec(entry.pos)-camera;var height:float=sin(float(entry.age)/1.2*PI)*55
  c.draw_arc(point,85,0,TAU,40,Color(.8,.85,.68,.5),2,true)
  for rock in 4:c.draw_rect(Rect2(point+Vector2(-15+rock*7,-height-rock*5),Vector2(15,12)),Color("#9daa9c"))
 for entry in ramps:
  var point:Vector2=combat.vec(entry.pos)-camera;var aim:Vector2=combat.vec(entry.aim)
  for rock in 9:
   var center:Vector2=point+aim.orthogonal()*(-108+rock*27)
   c.draw_colored_polygon(PackedVector2Array([center+Vector2(-13,7),center+Vector2(-11,-25),center+Vector2(4,-34),center+Vector2(13,-22),center+Vector2(14,8)]),Color("#8a9c8e"))
   c.draw_line(center+Vector2(-10,-25),center+Vector2(4,-34),Color("#cbd2b1"),3,true)
