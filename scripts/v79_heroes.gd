extends Node
## Molten Pilgrim and Kite Corsair. All hits, landing points and pools are host-owned.
var combat:Node
var effects:Array=[]
var pools:Array=[]
var darts:Array=[]
var targets:Dictionary={}
var velocities:Dictionary={}
var observed:Dictionary={}
var holds:Dictionary={}
var clock:=0.0
var pool_tick:=0.0
const STYLES=["magma_breath","shell_lob","back_volcano","caldera_ring","sail_needle","windlass_swing","storm_delivery","headwind_harpoon"]
func reset()->void:
 effects.clear();pools.clear();darts.clear();targets.clear();velocities.clear();observed.clear();holds.clear();clock=0;pool_tick=0
func holding(owner:String,pressed:bool,aim:Vector2)->void:
 if is_finite(aim.x) and is_finite(aim.y):holds[owner]={"held":pressed,"aim":combat.point_array(aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT)}
func hero(owner:String)->String:return combat.v78.hero(owner)
func moving(owner:String)->bool:
 for e in effects:
  if str(e.owner)==owner and str(e.style) in ["shell_lob","windlass_swing"]:return true
 return false
func sample(owner:String,point:Vector2,delta:float,enabled:bool)->void:
 if hero(owner)!="kite" or not enabled:observed.erase(owner);velocities.erase(owner);return
 var rec:Dictionary=observed.get(owner,{"pos":combat.point_array(point),"speed":0.0})
 var distance:float=point.distance_to(combat.vec(rec.pos))
 rec.speed=lerpf(float(rec.speed),minf(340,distance/maxf(delta,.001)),minf(1,delta*8)) if distance<180 and not moving(owner) else 0.0
 rec.pos=combat.point_array(point);observed[owner]=rec
func displacement(owner:String,direction:Vector2,speed:float,delta:float)->Vector2:
 if hero(owner)!="kite":return direction*speed*delta
 if moving(owner):return Vector2.ZERO
 if speed<=0:velocities[owner]=Vector2.ZERO;return Vector2.ZERO
 var velocity:Vector2=velocities.get(owner,Vector2.ZERO)
 velocity=velocity.move_toward(direction*speed,(620 if direction.is_zero_approx() else 420)*delta)
 velocities[owner]=velocity;return velocity*delta
func dodge_factor(owner:String)->float:return .28 if hero(owner)=="snail" else 1.0
func momentum(owner:String)->float:return clampf(float(observed.get(owner,{}).get("speed",0))/280,0,1)
func prepare(owner:String,stats:Dictionary,aim:Vector2,target:Vector2)->bool:
 if str(stats.get("style","")) not in STYLES+combat.v112.STYLES+combat.halloween.STYLES+combat.v90.STYLES+combat.stance_heroes.STYLES+combat.party_heroes.STYLES+combat.release_heroes.STYLES+combat.morrow.STYLES+combat.mantis.STYLES+combat.confluence.STYLES+["rift_triangle","rift_pin"]:return true
 var p:Vector2=combat.owner_pos(owner);var range_limit:float=float(stats.get("range",300))
 var delta:Vector2=target-p
 if target==Vector2.ZERO or not is_finite(target.x) or not is_finite(target.y):delta=aim.normalized()*range_limit
 targets[owner]=combat.point_array(combat.v75.clip(p,delta,minf(range_limit,delta.length())))
 return true
func destination(owner:String,aim:Vector2,range_limit:float)->Vector2:
 var p:Vector2=combat.owner_pos(owner)
 return combat.vec(targets[owner]) if targets.has(owner) else combat.v75.clip(p,aim,range_limit)
func add(owner:String,style:String,p:Vector2,stats:Dictionary,damage:float,time:float)->Dictionary:
 if effects.size()>=48:return {}
 var e:Dictionary={"owner":owner,"style":style,"pos":combat.point_array(p),"stats":stats.duplicate(true),"damage":damage,"time":time,"age":0.0,"hits":[],"tick":0.0}
 effects.append(e);return e
func pool(owner:String,p:Vector2,radius:float=58,duration:float=5,wind:bool=false)->void:
 # Reuse nearby patches; cap both per-owner and global density.
 for e in pools:
  if str(e.owner)==owner and bool(e.wind)==wind and combat.vec(e.pos).distance_to(p)<32:e.time=maxf(float(e.time),duration);return
 var owned:Array=pools.filter(func(e):return str(e.owner)==owner)
 if owned.size()>=16:pools.erase(owned[0])
 if pools.size()>=48:pools.pop_front()
 pools.append({"owner":owner,"pos":combat.point_array(p),"radius":radius,"time":duration,"wind":wind})
func position_owner(owner:String,p:Vector2)->void:
 var g:Node=combat.adventure.game
 if combat.adventure.arcade:
  g.positions[owner]=p
  if owner==g.my_id:g.local_pos=p;g.dodge_time=0
 else:g.position_in_world=p;g.dodge_time=0;g.charge_time=0;g.update_camera()
func begin_flight(owner:String,style:String,p:Vector2,end:Vector2,stats:Dictionary,damage:float,time:float)->void:
 var e:=add(owner,style,p,stats,damage,time)
 if e.is_empty():return
 e["origin"]=combat.point_array(p);e["end"]=combat.point_array(end)
 e["control"]=combat.point_array((p+end)*.5+(end-p).normalized().orthogonal()*110)
 if combat.adventure.arcade:combat.adventure.game.charges.erase(owner)
 if style=="windlass_swing":
  var radial:Vector2=p-end
  if radial.length()<55:end=p+Vector2(0,-85);radial=p-end
  e["control"]=combat.point_array(end)
  e["radial"]=combat.point_array(radial)
  var incoming:Vector2=velocities.get(owner,Vector2.RIGHT*220)
  e["turn"]=1.0 if radial.cross(incoming)>=0 else -1.0
  e["speed"]=maxf(260,incoming.length())
  e["angle"]=0.0
  if not holds.has(owner):holding(owner,true,(end-p).normalized())
 else:velocities[owner]=Vector2.ZERO
 position_owner(owner,p)
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var p:Vector2=combat.owner_pos(owner);aim=aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
 match style:
  "magma_breath":
   for key in combat.hostile(owner):
    var target:Dictionary=combat.actor(key)
    if target.is_empty() or not bool(target.alive):continue
    if combat.v56.cone(p,aim,target.pos,130,cos(deg_to_rad(32))) and combat.path_clear(p,target.pos):
     combat.apply_status(key,"burn",3,owner,1);combat.damage(key,amount,owner)
   for n in 2:pool(owner,combat.v75.clip(p,aim,55+n*50),43,4.5)
   var e:=add(owner,style,p,stats,amount,.38)
   if not e.is_empty():e["aim"]=combat.point_array(aim)
  "shell_lob","windlass_swing":
   begin_flight(owner,style,p,destination(owner,aim,float(stats.get("range",460 if style=="shell_lob" else 360))),stats,amount,.8 if style=="shell_lob" else float(stats.get("duration",1.65)))
  "back_volcano":
   for i in range(effects.size()-1,-1,-1):
    if effects[i].owner==owner and effects[i].style==style:effects.remove_at(i)
   add(owner,style,p,stats,amount,6)
  "caldera_ring":add(owner,style,p,stats,amount,1.25)
  "sail_needle","headwind_harpoon":
   if darts.size()<64:
    darts.append({"owner":owner,"pos":combat.point_array(p+aim*20),"aim":combat.point_array(aim),"damage":amount+(12*momentum(owner) if style=="sail_needle" else 0),"distance":0.0,"style":style,"range":float(stats.get("range",520))})
  "storm_delivery":
   var center:=destination(owner,aim,float(stats.get("range",430)))
   for n in 3:
    var end:Vector2=combat.v75.clip(center,aim.rotated(TAU*n/3),85)
    var e:=add(owner,"cargo_drop",end,stats,amount,1.15+n*.3)
    if not e.is_empty():e["delay"]=.7+n*.3
 return true
func erode(key:String,raw:float,reduced:float)->float:
 if raw<=0 or reduced>=raw:return reduced
 var target:Dictionary=combat.actor(key)
 if target.is_empty():return reduced
 for owner in combat.adventure.points():
  if not combat.adventure.alive(str(owner)) or not combat.passive(str(owner),"melting_presence"):continue
  if key not in combat.hostile(str(owner)):continue
  var origin:Vector2=combat.owner_pos(str(owner))
  if origin.distance_to(target.pos)<=155 and combat.path_clear(origin,target.pos):return minf(raw,reduced+raw*.4)
 return reduced
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta;pool_tick+=delta
 for i in range(pools.size()-1,-1,-1):
  pools[i].time=float(pools[i].time)-delta
  if float(pools[i].time)<=0 or not combat.adventure.alive(str(pools[i].owner)):pools.remove_at(i)
 if pool_tick>=1:
  pool_tick=fmod(pool_tick,1);var struck:Dictionary={}
  for patch in pools:
   var owner:=str(patch.owner);var p:Vector2=combat.vec(patch.pos)
   if bool(patch.wind):
    for ally in combat.adventure.points():
     if combat.adventure.alive(str(ally)) and combat.v75.friendly(owner,str(ally)) and p.distance_to(combat.owner_pos(str(ally)))<float(patch.radius):combat.apply_status(combat.player_key(str(ally)),"tailwind",1.5,owner)
    continue
   for key in combat.hostile(owner):
    var token:String=owner+":"+key;var target:Dictionary=combat.actor(key)
    if target.is_empty() or not bool(target.alive) or struck.has(token):continue
    if p.distance_to(target.pos)<=float(patch.radius) and combat.path_clear(p,target.pos):
     struck[token]=true;combat.damage(key,3,owner)
 for i in range(darts.size()-1,-1,-1):
  var d:Dictionary=darts[i];var start:Vector2=combat.vec(d.pos);var end:Vector2=start+combat.vec(d.aim)*560*delta;var hit:=false
  var clipped:Vector2=combat.v75.clip(start,combat.vec(d.aim),560*delta)
  if clipped.distance_to(end)>1:hit=true;end=clipped
  var first:="";var nearest:=INF
  for key in combat.hostile(str(d.owner)):
   var target:Dictionary=combat.actor(key)
   if target.is_empty() or not bool(target.alive):continue
   var q:Vector2=Geometry2D.get_closest_point_to_segment(target.pos,start,end)
   if q.distance_to(target.pos)<23 and q.distance_to(start)<nearest and combat.path_clear(start,target.pos):first=key;nearest=q.distance_to(start)
  if not first.is_empty():
   hit=true
   if str(d.style)=="headwind_harpoon":combat.apply_status(first,"slow",1.5,str(d.owner),.6);combat.knock(first,(combat.owner_pos(str(d.owner))-combat.actor(first).pos).normalized(),35)
   combat.damage(first,float(d.damage),str(d.owner))
  d.distance=float(d.distance)+start.distance_to(end);d.pos=combat.point_array(end)
  if hit or float(d.distance)>float(d.range) or not combat.adventure.alive(str(d.owner)):darts.remove_at(i)
 for i in range(effects.size()-1,-1,-1):
  var e:Dictionary=effects[i];var owner:=str(e.owner);e.age=float(e.age)+delta;var age:=float(e.age);var p:Vector2=combat.vec(e.pos)
  if not combat.adventure.alive(owner):effects.remove_at(i);continue
  match str(e.style):
   "shell_lob","windlass_swing":
    var t:=clampf(age/float(e.time),0,1);var start:Vector2=combat.vec(e.origin);var end:Vector2=combat.vec(e.end)
    var next:Vector2=start.lerp(end,t)
    if e.style=="windlass_swing":
     e.speed=minf(480,float(e.speed)+280*delta)
     e.angle=float(e.angle)+float(e.turn)*float(e.speed)/maxf(55,combat.vec(e.radial).length())*delta
     var radial:Vector2=combat.vec(e.radial).rotated(float(e.angle))
     next=combat.vec(e.control)+radial
     velocities[owner]=radial.normalized().orthogonal()*float(e.turn)*float(e.speed)
    var before:Vector2=combat.owner_pos(owner);var shift:Vector2=next-before
    next=combat.v75.clip(before,shift,shift.length());position_owner(owner,next);e.pos=combat.point_array(next)
    if str(e.style)=="windlass_swing":combat.v78.line_hit(owner,before,next,34,float(e.damage),{},e.hits)
    var released:bool=e.style=="windlass_swing" and age>.08 and not bool(holds.get(owner,{}).get("held",true))
    if t>=1 or released or next.distance_to(before)<.01 and shift.length()>1:
     e.age=e.time
     if str(e.style)=="shell_lob":combat.v75.area(owner,next,100,float(e.damage),{"burn_duration":3,"burn_damage":1});pool(owner,next,80,5)
     elif combat.passive(owner,"updraft_reserve"):combat.apply_status(combat.player_key(owner),"guard",2,owner,.15)
     combat.adventure.teleport(owner,next)
     if str(e.style)=="windlass_swing":
      var launch:Vector2=combat.vec(holds.get(owner,{"aim":[1,0]}).aim)*float(e.speed)
      velocities[owner]=launch
      if combat.adventure.arcade and owner!=combat.adventure.game.my_id:combat.adventure.game._send_channel(owner,{"type":"kite_release","velocity":combat.point_array(launch)})
   "back_volcano":
    e.pos=combat.point_array(combat.owner_pos(owner));e.tick=float(e.tick)+delta
    while float(e.tick)+.00001>=.5 and int(e.get("volleys",0))<12:
     e.tick=maxf(0,float(e.tick)-.5);e["volleys"]=int(e.get("volleys",0))+1
     for n in 2:
      var direction:=Vector2.from_angle(randf()*TAU);var end:Vector2=combat.v75.clip(combat.owner_pos(owner),direction,randf_range(90,260))
      var ball:=add(owner,"lava_ball",end,e.stats,float(e.damage),.85)
      if not ball.is_empty():ball["origin"]=combat.point_array(combat.owner_pos(owner));ball["height"]=visual_offset(owner).y-35
   "lava_ball":
    if age>=.65 and not e.hits.has("done"):
     e.hits.append("done");combat.v75.area(owner,p,52,float(e.damage),{});pool(owner,p,52,4)
   "caldera_ring":
    if age>=.75 and not e.hits.has("done"):
     e.hits.append("done")
     var hit:Array=[]
     for n in 8:
      var end:Vector2=combat.v75.clip(p,Vector2.from_angle(TAU*n/8),120)
      pool(owner,end,42,6)
      combat.v78.line_hit(owner,end,end,42,float(e.damage),{},hit)
   "cargo_drop":
    if age>=float(e.delay) and not e.hits.has("done"):
     e.hits.append("done");combat.v75.area(owner,p,70,float(e.damage),{})
     for key in combat.hostile(owner):
      var target:Dictionary=combat.actor(key)
      if not target.is_empty() and bool(target.alive) and p.distance_to(target.pos)<70:combat.knock(key,(target.pos-p).normalized(),40)
     pool(owner,p,65,4,true)
  if float(e.age)+.00001>=float(e.time):effects.remove_at(i)
func visual_offset(owner:String)->Vector2:
 for e in effects:
  if str(e.owner)==owner and str(e.style)=="shell_lob":return Vector2(0,-sin(clampf(float(e.age)/float(e.time),0,1)*PI)*110)
 if hero(owner)=="kite":return Vector2(0,-8-5*momentum(owner)*sin(clock*6))
 return Vector2.ZERO
func follow_local(delta:float)->void:
 if not combat.adventure.arcade or combat.adventure.authoritative():return
 var g:Node=combat.adventure.game
 for e in effects:
  if str(e.owner)==g.my_id and str(e.style) in ["shell_lob","windlass_swing"]:g.local_pos=g.local_pos.lerp(combat.vec(e.pos),minf(1,delta*20))
func snapshot()->Dictionary:return {"effects":effects,"pools":pools,"darts":darts,"clock":clock,"observed":observed}
func receive(data:Dictionary)->void:
 effects=data.get("effects",[]);pools=data.get("pools",[]);darts=data.get("darts",[]);clock=float(data.get("clock",clock))
func draw_on(c:Node2D,camera:Vector2)->void:
 for patch in pools:
  var p:Vector2=combat.vec(patch.pos)-camera;var r:float=float(patch.radius);var fade:=minf(1,float(patch.time))
  if not bool(patch.wind) and c.has_method("draw_ground_patch") and c.draw_ground_patch(p,r,fade,clock,"magma"):continue
  if c.has_method("draw_ground_patch") and not Rect2(Vector2.ZERO,c.VIEW).grow(r+32).has_point(p):continue
  if bool(patch.wind):
   c.draw_circle(p,r,Color(.3,.8,.85,.14*fade))
   for n in 3:c.draw_arc(p,15+n*14,clock*2+n,clock*2+n+PI,18,Color(.65,.96,1,.55*fade),2,true)
  else:
   c.draw_circle(p,r,Color(.24,.12,.1,.55*fade));c.draw_circle(p,r*.85,Color(.95,.25,.04,.52*fade))
   for n in 5:
    var q:=p+Vector2.from_angle(n*TAU/5+clock*.2)*r*.5
    c.draw_arc(q,7+sin(clock*4+n)*2,0,TAU,12,Color(1,.68,.15,.65*fade),3,true)
 for owner in combat.adventure.points():
  if combat.passive(str(owner),"melting_presence") and combat.adventure.alive(str(owner)):
   var p:Vector2=combat.owner_pos(str(owner))-camera
   if c.has_method("draw_ground_patch") and not Rect2(Vector2.ZERO,c.VIEW).grow(190).has_point(p):continue
   c.draw_arc(p,155,0,TAU,48,Color(1,.5,.16,.22),2,true)
   for n in 8:c.draw_arc(p+Vector2.from_angle(clock*.2+n*TAU/8)*148,6,0,PI,8,Color(1,.72,.25,.4),2,true)
 for d in darts:
  var p:Vector2=combat.vec(d.pos)-camera;var aim:Vector2=combat.vec(d.aim)
  c.draw_line(p-aim*30,p,Color(.5,.9,1,.5),5,true);c.draw_line(p-aim*12,p+aim*9,Color("#e7fbff"),3,true)
 for e in combat.draw_effect_records("v79","effects",effects):
  var p:Vector2=combat.draw_effect_position("v79",e,combat.vec(e.pos))-camera;var age:float=float(e.age)
  match str(e.style):
   "magma_breath":
    var aim:Vector2=combat.vec(e.aim)
    for n in 16:
     var t:=fposmod(age*2+n/16.0,1);var q:=p+aim*(20+t*110)+aim.orthogonal()*sin(n*7.1)*t*30
     c.draw_circle(q,9-t*5,Color(1,.22+t*.5,.06,1-age/.4))
   "shell_lob":
    var end:Vector2=combat.vec(e.end)-camera;c.draw_arc(end,100,0,TAU,32,Color(1,.55,.2,.4),2,true)
    c.draw_circle(p+Vector2(0,16),18,Color(0,0,0,.2))
   "windlass_swing":
    var anchor:Vector2=combat.vec(e.control)-camera;c.draw_line(anchor,p+Vector2(0,-12),Color("#b8efea"),2,true);c.draw_arc(anchor,12,0,TAU,16,Color("#edcc83"),3,true)
   "back_volcano":
    var q:=p+Vector2(0,-35)+visual_offset(str(e.owner))
    c.draw_colored_polygon(PackedVector2Array([q+Vector2(-20,15),q+Vector2(-10,-8),q+Vector2(9,-8),q+Vector2(20,15)]),Color("#654741"))
    for n in 5:c.draw_circle(q+Vector2((n-2)*6,-fposmod(clock*50+n*8,32)),4,Color("#ffab32"))
   "lava_ball":
    var start:Vector2=combat.vec(e.origin)-camera+Vector2(0,float(e.get("height",-35)));var t:=clampf(age/.65,0,1)
    c.draw_arc(p,52,0,TAU,20,Color(1,.5,.2,.35),2,true)
    if age<.65:
     var q:=start.lerp(p,t)+Vector2(0,-sin(t*PI)*100);c.draw_circle(q,8,Color("#ff6022"));c.draw_circle(q+Vector2(-2,-2),4,Color("#ffe276"))
   "caldera_ring":
    c.draw_arc(p,120,0,TAU,48,Color(1,.45,.15,.6),4 if age<.75 else 12,true)
   "cargo_drop":
    var left:=maxf(0,float(e.delay)-age);c.draw_arc(p,70,0,TAU,28,Color(.55,.9,1,.5),2,true)
    if left>0:
     var q:=p+Vector2(0,-left*160);c.draw_rect(Rect2(q-Vector2(12,12),Vector2(24,24)),Color("#d6a05c"));c.draw_line(q+Vector2(-12,0),q+Vector2(12,0),Color("#654f3f"),3)
     c.draw_arc(q-Vector2(0,38),24,PI,TAU,20,Color("#e4f4ef"),8,true)
     for side in [-1,1]:c.draw_line(q+Vector2(side*24,-38),q+Vector2(side*10,-10),Color("#b5d5d3"),1)
    else:c.draw_arc(p,minf(70,(age-float(e.delay))*220),0,TAU,28,Color("#d4ffff"),5,true)
 draw_aim(c,camera)
func draw_aim(c:Node2D,camera:Vector2)->void:
 var g:Node=combat.adventure.game;var owner:String=str(g.my_id) if combat.adventure.arcade else "solo"
 if combat.adventure.arcade:
  if not g.started or not g.shop_open.is_empty():return
 elif g.mode!="run" or not g.menu.is_empty():return
 if hero(owner) not in ["snail","kite"] or not combat.adventure.alive(owner) or moving(owner):return
 var h:Dictionary=g.characters.get(hero(owner),{});var stats:Dictionary=combat.effective_stats(owner,"secondary",h.secondary)
 var origin:Vector2=combat.owner_pos(owner);var target:Vector2=origin+g.mobile.aim*float(stats.range) if g.mobile.enabled else g.media_mouse_world()
 var offset:Vector2=target-origin;var end:Vector2=combat.v75.clip(origin,offset,minf(offset.length(),float(stats.range)))-camera
 c.draw_arc(end,100 if hero(owner)=="snail" else 25,0,TAU,28,Color(1,.75,.4,.4) if hero(owner)=="snail" else Color(.6,.9,1,.4),2,true)
 c.draw_dashed_line(origin-camera,end,Color(.8,.8,.7,.25),1,12,true)
 if hero(owner)=="kite":
  var p:=origin-camera+Vector2(-22,32);c.draw_rect(Rect2(p,Vector2(44,4)),Color(.1,.2,.3,.7));c.draw_rect(Rect2(p,Vector2(44*momentum(owner),4)),Color("#9be1ee"))

func draw_shell(c:CanvasItem,owner:String,point:Vector2,texture:Texture2D,tint:Color)->void:
 if texture==null:return
 var angle:=0.0
 for e in effects:
  if str(e.owner)==owner and str(e.style)=="shell_lob":angle=TAU*clampf(float(e.age)/float(e.time),0,1);break
 if combat.adventure.arcade:c.world_transform(point+visual_offset(owner)+Vector2(0,-10),angle)
 else:c.world_transform(point+visual_offset(owner)+Vector2(0,-10),angle)
 c.draw_texture_rect(texture,Rect2(-28,-32,56,64),false,tint)
 if combat.adventure.arcade:c.world_transform()
 else:c.world_transform(Vector2.ZERO)
