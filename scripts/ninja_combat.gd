extends Node
## Host-owned katana timing, returning stars and a swept inward star spiral.
var combat:Node
var cuts:Array=[]
var wheels:Array=[]
var eclipses:Array=[]
var marks:Dictionary={}
var flashes:Array=[]
var clock:=0.0
const STYLES=["twin_fang","windwheel","eightfold_eclipse"]
func reset()->void:cuts.clear();wheels.clear();eclipses.clear();marks.clear();flashes.clear();clock=0
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:String=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 aim=aim.normalized()
 if aim.is_zero_approx():aim=Vector2.RIGHT
 var origin:Vector2=combat.owner_pos(owner)
 match style:
  "twin_fang":
   if cuts.size()<24:cuts.append({"owner":owner,"aim":combat.point_array(aim),"time":0.0,"damage":amount,"reach":float(stats.get("range",95)),"strikes":0})
  "windwheel":
   if wheels.size()<24:wheels.append({"owner":owner,"pos":combat.point_array(origin+aim*24),"aim":combat.point_array(aim),"distance":0.0,"range":float(stats.get("range",420)),"age":0.0,"phase":0,"damage":amount,"return_damage":float(stats.get("return_damage",18)),"bleed_duration":float(stats.get("bleed_duration",0)),"bleed_damage":float(stats.get("bleed_damage",0)),"hits":[[],[]]})
  "eightfold_eclipse":
   if eclipses.size()>=12:return true
   var center:Vector2=combat.chain.clip(origin,aim,float(stats.get("range",200)))
   if not combat.adventure.can_stand(center):return true
   var stars:Array=[]
   for n in 8:
    var ray:Vector2=Vector2.from_angle(TAU*n/8)
    var point:Vector2=combat.chain.clip(center,ray,220)
    if point.distance_to(center)>35:stars.append({"angle":TAU*n/8,"radius":point.distance_to(center),"pos":combat.point_array(point),"active":true})
   eclipses.append({"owner":owner,"pos":combat.point_array(center),"age":0.0,"stars":stars,"hits":{},"damage":amount})
 return true
func flash(point:Vector2,aim:Vector2,kind:String,owner:String="",reach:float=75)->void:
 if flashes.size()<64:flashes.append({"owner":owner,"pos":combat.point_array(point),"aim":combat.point_array(aim),"kind":kind,"radius":reach,"time":.22})
func hit_cut(cut:Dictionary,index:int)->void:
 var owner:String=str(cut.owner);var origin:Vector2=combat.owner_pos(owner);var aim:Vector2=combat.vec(cut.aim)
 for key in combat.hostile(owner):
  var target:Dictionary=combat.actor(key)
  if target.is_empty() or not target.alive:continue
  var offset:Vector2=target.pos-origin
  if offset.length()>float(cut.reach)+float(target.get("npc",{}).get("hit_radius",0)) or offset.normalized().dot(aim)<cos(deg_to_rad(50)) or not combat.path_clear(origin,target.pos):continue
  var extra:=0.0
  if combat.passive(owner,"moon_thread") and marks.get(owner,{}).has(key):
   extra=8;marks[owner].erase(key);flash(target.pos,aim,"thread")
  combat.damage(key,float(cut.damage)+extra,owner)
 flash(origin,aim,"cut_left" if index==0 else "cut_right",owner,float(cut.reach))
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 for owner in marks.keys():
  if not combat.adventure.alive(str(owner)):marks.erase(owner);continue
  for key in (marks[owner] as Dictionary).keys():
   marks[owner][key]=float(marks[owner][key])-delta
   var target:Dictionary=combat.actor(str(key))
   if float(marks[owner][key])<=0 or target.is_empty() or not target.alive:marks[owner].erase(key)
  if (marks[owner] as Dictionary).is_empty():marks.erase(owner)
 for n in range(flashes.size()-1,-1,-1):
  flashes[n].time-=delta
  if float(flashes[n].time)<=0:flashes.remove_at(n)
 var elapsed:=minf(delta,.1);var pieces:=maxi(1,ceili(elapsed/.025))
 for n in pieces:advance(elapsed/pieces)
func wheel_candidates(owner:String,start:Vector2,end:Vector2)->Array[String]:
 var result:Array[String]=[]
 var bounds:=Rect2(start,Vector2.ZERO).expand(end).grow(80)
 for foe in combat.adventure.foes():
  if float(foe.hp)<=0 or bool(foe.get("buried",false)) or not bounds.grow(maxf(0,float(foe.get("hit_radius",18))-66)).has_point(foe.pos):continue
  if Geometry2D.get_closest_point_to_segment(foe.pos,start,end).distance_squared_to(foe.pos)<=pow(14+float(foe.get("hit_radius",18)),2):result.append(combat.npc_key(foe))
 for key in combat.hostile(owner):
  if key.begins_with("e:"):continue
  var target:Dictionary=combat.actor(key)
  if not target.is_empty() and target.alive and bounds.has_point(target.pos):result.append(key)
 return result
func advance(delta:float)->void:
 for n in range(cuts.size()-1,-1,-1):
  var cut:Dictionary=cuts[n];var owner:String=str(cut.owner)
  if not combat.adventure.alive(owner) or combat.stunned(combat.player_key(owner)):cuts.remove_at(n);continue
  cut.time+=delta
  while int(cut.strikes)<2 and float(cut.time)>=int(cut.strikes)*.14:
   hit_cut(cut,int(cut.strikes));cut.strikes=int(cut.strikes)+1
  if float(cut.time)>=.3:cuts.remove_at(n)
 for n in range(wheels.size()-1,-1,-1):
  var shot:Dictionary=wheels[n];var owner:String=str(shot.owner)
  if not combat.adventure.alive(owner):wheels.remove_at(n);continue
  shot.age+=delta
  var start:Vector2=combat.vec(shot.pos);var aim:Vector2=combat.vec(shot.aim)
  if int(shot.phase)==1:
   var offset:Vector2=combat.owner_pos(owner)-start
   if offset.length()<24:flash(start,aim,"catch");wheels.remove_at(n);continue
   aim=Vector2.from_angle(rotate_toward(aim.angle(),offset.angle(),delta*12))
  var travel:float=minf(480*delta,maxf(0,float(shot.range)-float(shot.distance))) if int(shot.phase)==0 else 520*delta
  var end:Vector2=start+aim*travel
  if not combat.path_clear(start,end):flash(start,aim,"catch");wheels.remove_at(n);continue
  var leg:int=int(shot.phase)
  if combat.v56.catch_travelling(start,end,owner,float(shot.damage) if leg==0 else float(shot.return_damage),"#cfc8ee",{"stolen_visual":"windwheel"}):wheels.remove_at(n);continue
  for key in wheel_candidates(owner,start,end):
   if (shot.hits[leg] as Array).has(key):continue
   var target:Dictionary=combat.actor(key)
   if target.is_empty() or not target.alive:continue
   if Geometry2D.get_closest_point_to_segment(target.pos,start,end).distance_squared_to(target.pos)>pow(14+float(target.get("npc",{}).get("hit_radius",18)),2):continue
   if not combat.path_clear(start,target.pos):continue
   shot.hits[leg].append(key)
   combat.damage(key,float(shot.damage) if leg==0 else float(shot.return_damage),owner)
   if leg==0 and float(shot.get("bleed_duration",0))>0:combat.apply_status(key,"bleed",float(shot.bleed_duration),owner,float(shot.bleed_damage))
   if leg==1 and combat.passive(owner,"moon_thread") and not combat.actor(key).is_empty() and combat.actor(key).alive:
    if not marks.has(owner):marks[owner]={}
    marks[owner][key]=3.0
  shot.pos=combat.point_array(end);shot.aim=combat.point_array(aim);shot.distance+=travel
  if leg==0 and float(shot.distance)>=float(shot.range)-.01:shot.phase=1;shot.aim=combat.point_array(-aim)
  if float(shot.age)>3.2:wheels.remove_at(n)
 for n in range(eclipses.size()-1,-1,-1):
  var eclipse:Dictionary=eclipses[n];var owner:String=str(eclipse.owner)
  if not combat.adventure.alive(owner):eclipses.remove_at(n);continue
  eclipse.age+=delta
  if float(eclipse.age)<.3:continue
  var center:Vector2=combat.vec(eclipse.pos);var progress:float=clampf((float(eclipse.age)-.3)/1.2,0,1)
  for star in eclipse.stars:
   if not star.active:continue
   var before:Vector2=combat.vec(star.pos)
   var after:Vector2=center+Vector2.from_angle(float(star.angle)+TAU*progress)*float(star.radius)*(1-progress)
   if not combat.path_clear(before,after):star.active=false;continue
   if combat.v56.catch_travelling(before,after,owner,float(eclipse.damage),"#cfc8ee",{"stolen_visual":"windwheel"}):star.active=false;continue
   for key in combat.hostile(owner):
    if int(eclipse.hits.get(key,0))>=3:continue
    var target:Dictionary=combat.actor(key)
    if target.is_empty() or not target.alive or not combat.path_clear(before,target.pos):continue
    # One star can hit each target once; the total cast has a three-hit cap.
    if not star.has("hits"):star.hits=[]
    if (star.hits as Array).has(key):continue
    if Geometry2D.get_closest_point_to_segment(target.pos,before,after).distance_to(target.pos)>12+float(target.get("npc",{}).get("hit_radius",18)):continue
    star.hits.append(key);eclipse.hits[key]=int(eclipse.hits.get(key,0))+1;combat.damage(key,float(eclipse.damage),owner)
   star.pos=combat.point_array(after)
  if progress>=1:
   for key in combat.hostile(owner):
    var target:Dictionary=combat.actor(key)
    if not target.is_empty() and target.alive and center.distance_to(target.pos)<=90 and combat.path_clear(center,target.pos):combat.damage(key,18,owner)
   flash(center,Vector2.RIGHT,"eclipse");eclipses.remove_at(n)
func snapshot()->Dictionary:return {"cuts":cuts,"wheels":wheels,"eclipses":eclipses,"marks":marks,"flashes":flashes,"clock":clock}
func receive(data:Dictionary)->void:cuts=data.get("cuts",[]);wheels=data.get("wheels",[]);eclipses=data.get("eclipses",[]);marks=data.get("marks",{});flashes=data.get("flashes",[]);clock=float(data.get("clock",clock))
func draw_star(c:Node2D,point:Vector2,angle:float,size:float,tint:Color)->void:
 var vertices:=PackedVector2Array()
 for n in 8:vertices.append(point+Vector2.from_angle(angle+TAU*n/8)*(size if n%2==0 else size*.3))
 c.draw_colored_polygon(vertices,tint);c.draw_circle(point,2.5,Color("#514c6a"))
func draw_on(c:Node2D,camera:Vector2)->void:
 for wheel in wheels:
  var point:Vector2=combat.vec(wheel.pos)-camera
  c.draw_line(point-combat.vec(wheel.aim)*27,point,Color(.68,.63,.92,.3),4,true)
  preload("res://scripts/hero_visuals1987.gd").windwheel(c,point,clock*20,int(wheel.phase)==1)
 for eclipse in eclipses:
  var point:Vector2=combat.vec(eclipse.pos)-camera
  c.draw_circle(point,220,Color(.33,.28,.58,.08));c.draw_arc(point,220,0,TAU,64,Color(.75,.7,1,.3),2,true)
  c.draw_arc(point+Vector2(-6,0),20,-PI*.7,PI*.7,24,Color("#e5ddfa"),4,true)
  for star in eclipse.stars:
   if star.active:draw_star(c,combat.vec(star.pos)-camera,clock*18,12,Color("#cfc8ee"))
 for owner in marks:
  for key in marks[owner]:
   var target:Dictionary=combat.actor(str(key))
   if not target.is_empty():draw_star(c,target.pos-camera+Vector2(0,-73),clock*3,7,Color("#af9be5"))
 for entry in combat.draw_effect_records("ninja","flashes",flashes):
  var point:Vector2=combat.draw_effect_position("ninja",entry,combat.vec(entry.pos))-camera;var aim:Vector2=combat.vec(entry.aim);var fade:float=clampf(float(entry.time)/.22,0,1)
  if str(entry.kind).begins_with("cut"):
   var side:float=1 if entry.kind=="cut_left" else -1
   preload("res://scripts/hero_visuals1987.gd").katana(c,point,aim,float(entry.get("radius",95)),1-fade,side)
  elif entry.kind=="eclipse":c.draw_circle(point,90,Color(.73,.68,1,fade*.2));c.draw_arc(point,90*(1-fade),0,TAU,32,Color(.85,.8,1,fade),4,true)
  else:c.draw_arc(point,24*(1-fade),0,TAU,24,Color(.7,.9,1,fade),2,true)
