extends Node
## Ripplejaw and Hearthwarden: bounded, serializable, host-authoritative effects.
var combat:Node
var effects:Array=[]
var combos:Dictionary={}
var scales:Dictionary={}
var clock:=0.0
const STYLES=["water_jet","fish_splash","tidal_maw","shoal_vortex","hearth_combo","rally_banner","shield_march","forgefall"]
func reset()->void:effects.clear();combos.clear();scales.clear();clock=0
func clip(start:Vector2,aim:Vector2,reach:float)->Vector2:
 for n in range(int(ceil(reach/8.0))):
  var next:Vector2=start+aim.normalized()*minf(8,reach-n*8)
  if not combat.path_clear(start,next):break
  start=next
 return start
func selected(owner:String,aim:Vector2,reach:float)->String:
 var origin:Vector2=combat.owner_pos(owner);var cursor:Vector2=clip(origin,aim,reach);var best:="";var score:=INF
 for key in combat.hostile(owner):
  var target:Dictionary=combat.actor(key)
  if target.is_empty() or not bool(target.alive) or origin.distance_to(target.pos)>reach or not combat.path_clear(origin,target.pos):continue
  var offset:Vector2=target.pos-origin
  if offset.length()>60 and offset.normalized().dot(aim.normalized())<.55:continue
  var distance:float=cursor.distance_to(target.pos)
  if distance<score:score=distance;best=key
 return best
func add(owner:String,style:String,point:Vector2,aim:Vector2,stats:Dictionary,amount:float,time:float)->Dictionary:
 if effects.size()>=40:return {}
 var e:Dictionary={"owner":owner,"style":style,"pos":combat.point_array(point),"origin":combat.point_array(point),"aim":combat.point_array(aim.normalized()),"stats":stats.duplicate(true),"damage":amount,"age":0.0,"time":time,"tick":0.0,"hits":[],"caught":0}
 effects.append(e);return e
func area(owner:String,point:Vector2,radius:float,amount:float,stats:Dictionary)->void:
 for key in combat.hostile(owner):
  var target:Dictionary=combat.actor(key)
  if target.is_empty() or not bool(target.alive) or point.distance_to(target.pos)>radius or not combat.path_clear(point,target.pos):continue
  combat.apply_hit_status(key,stats,owner)
  if float(stats.get("slow_duration",0))>0:combat.apply_status(key,"slow",float(stats.slow_duration),owner,float(stats.get("slow",.65)))
  if float(stats.get("pull",0))>0 and not bool(target.get("npc",{}).get("boss",false)):combat.knock(key,(point-target.pos).normalized(),minf(float(stats.pull),point.distance_to(target.pos)))
  combat.damage(key,amount,owner)
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var origin:Vector2=combat.owner_pos(owner)
 if aim.is_zero_approx():aim=Vector2.RIGHT
 aim=aim.normalized()
 match style:
  "water_jet":add(owner,style,origin,aim,stats,amount,.26)
  "fish_splash":
   area(owner,origin,float(stats.get("radius",110)),amount,stats)
   add(owner,"splash_flash",origin,aim,stats,0,.5)
   # Exactly three puddles; replacing an old cast cannot build an unlimited carpet.
   for i in range(effects.size()-1,-1,-1):
    if str(effects[i].owner)==owner and str(effects[i].style)=="puddle":effects.remove_at(i)
   for n in 3:
    var p:Vector2=clip(origin,aim.rotated(n*TAU/3),80)
    add(owner,"puddle",p,aim,stats,0,float(stats.get("puddle_duration",4)))
  "tidal_maw","shoal_vortex":
   var key:=selected(owner,aim,float(stats.get("range",480)))
   var point:Vector2=combat.actor(key).get("pos",clip(origin,aim,float(stats.get("range",480))))
   var e:=add(owner,style,point,aim,stats,amount,2.65 if style=="tidal_maw" else 4.2)
   if not e.is_empty():e["target"]=key
  "hearth_combo":
   var rec:Dictionary=combos.get(owner,{"step":0,"left":0.0});var step:int=int(rec.step)+1
   if float(rec.left)<=0:step=1
   var strike_stats:Dictionary=stats.duplicate(true)
   if step==3:
    strike_stats.knockback=40
    if combat.passive(owner,"steadfast_forge"):combat.apply_status(combat.player_key(owner),"guard",2,owner,.15)
   combos[owner]={"step":0 if step==3 else step,"left":1.8}
   var e:=add(owner,"hammer_arc",origin,aim,strike_stats,amount*(1.5 if step==3 else 1),.35)
   if not e.is_empty():
    e["combo"]=step
    hammer_hit(e)
  "rally_banner":
   for i in range(effects.size()-1,-1,-1):
    if str(effects[i].owner)==owner and str(effects[i].style)==style:effects.remove_at(i)
   add(owner,style,clip(origin,aim,120),aim,stats,0,float(stats.get("duration",5)))
  "shield_march":
   for i in range(effects.size()-1,-1,-1):
    if str(effects[i].owner)==owner and str(effects[i].style)==style:effects.remove_at(i)
   add(owner,style,clip(origin,aim,32),aim,stats,amount,2.4)
  "forgefall":add(owner,style,clip(origin,aim,100),aim,stats,amount,1.9)
 return true
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 for id in combos:combos[id].left=maxf(0,float(combos[id].left)-delta)
 for i in range(effects.size()-1,-1,-1):
  var e:Dictionary=effects[i];var owner:=str(e.owner)
  if not combat.adventure.alive(owner):effects.remove_at(i);continue
  var old:float=float(e.age);e.age=old+delta
  var age:=float(e.age);var p:Vector2=combat.vec(e.pos);var aim:Vector2=combat.vec(e.aim);var stats:Dictionary=e.stats
  match str(e.style):
   "hammer_arc":
    e.pos=combat.point_array(combat.owner_pos(owner))
    # Damage only during the short swing, once per target across the whole cast.
    if age<=.18:hammer_hit(e)
   "water_jet":
    # Three short water pulses, total listed damage, stopped by the first target or wall.
    for pulse in 3:
     if age<pulse*.08 or old>pulse*.08 and pulse>0 or (e.hits as Array).has("pulse"+str(pulse)):continue
     e.hits.append("pulse"+str(pulse))
     var origin:Vector2=combat.owner_pos(owner);var end:=clip(origin,aim,float(stats.get("range",300)))
     var first:="";var nearest:float=origin.distance_to(end)+1
     for key in combat.hostile(owner):
      var target:Dictionary=combat.actor(key)
      if target.is_empty() or not bool(target.alive):continue
      var q:Vector2=Geometry2D.get_closest_point_to_segment(target.pos,origin,end)
      if q.distance_to(target.pos)<24 and origin.distance_to(q)<nearest and combat.path_clear(origin,target.pos):first=key;nearest=origin.distance_to(q)
     e.origin=combat.point_array(origin);e.pos=combat.point_array(origin+aim*minf(origin.distance_to(end),nearest))
     if not first.is_empty():combat.damage(first,float(e.damage)/3,owner)
   "puddle":
    for key in combat.hostile(owner):
     var target:Dictionary=combat.actor(key)
     if not target.is_empty() and bool(target.alive) and p.distance_to(target.pos)<=float(stats.get("puddle_radius",55)) and combat.path_clear(p,target.pos):combat.apply_status(key,"slow",.35,owner,.6)
   "tidal_maw":
    if age<1.6:
     var target:Dictionary=combat.actor(str(e.get("target","")))
     if not target.is_empty() and bool(target.alive):
      var shift:Vector2=target.pos-p
      e.pos=combat.point_array(clip(p,shift,minf(shift.length(),75*delta)));p=combat.vec(e.pos)
    if age>=2 and not (e.hits as Array).has("bite"):
     e.hits.append("bite");area(owner,p,float(stats.get("radius",100)),float(e.damage),stats)
   "shoal_vortex":
    if age>=.8:
     e.tick=float(e.tick)+minf(delta,maxf(0,age-maxf(old,.8)))
     while float(e.tick)>=.49999 and int(e.get("pulses",0))<6:
      e.tick=maxf(0,float(e.tick)-.5);e["pulses"]=int(e.get("pulses",0))+1
      area(owner,p,125,float(e.damage)/6,{"slow_duration":.6,"slow":.6,"pull":18})
   "rally_banner":
    if bool(stats.get("mobile_banner",false)):e.pos=combat.point_array(combat.owner_pos(owner));p=combat.vec(e.pos)
    for ally in combat.adventure.points():
     if not combat.adventure.alive(str(ally)) or not friendly(owner,str(ally)):continue
     var point:Vector2=combat.adventure.points()[ally]
     if p.distance_to(point)<=float(stats.get("radius",130)) and combat.path_clear(p,point):combat.apply_status(combat.player_key(str(ally)),"guard",.3,owner,float(stats.get("reduction",.18)))
   "shield_march":
    var move:Vector2=clip(p,aim,90*delta);e.pos=combat.point_array(move);p=move
    var side:=aim.orthogonal()*float(stats.get("width",220))*.5
    for key in combat.hostile(owner):
     var target:Dictionary=combat.actor(key)
     if target.is_empty() or not bool(target.alive) or (e.hits as Array).has(key):continue
     if Geometry2D.get_closest_point_to_segment(target.pos,p-side,p+side).distance_to(target.pos)<=32 and combat.path_clear(p,target.pos):
      e.hits.append(key);combat.apply_status(key,"slow",2,owner,.65);combat.apply_status(key,"stun",.4,owner);combat.knock(key,aim,45);combat.damage(key,float(e.damage),owner)
   "forgefall":
    for n in 3:
     if age<1+n*.2 or (e.hits as Array).has(n):continue
     e.hits.append(n);area(owner,clip(p,aim,n*90),65,float(e.damage),stats)
  if age>=float(e.time):effects.remove_at(i)
func hammer_hit(e:Dictionary)->void:
 var owner:=str(e.owner);var origin:Vector2=combat.owner_pos(owner);var aim:Vector2=combat.vec(e.aim)
 var third:=int(e.combo)==3;var reach:=105.0 if third else 85.0;var arc:=120.0 if third else 80.0
 for key in combat.hostile(owner):
  var target:Dictionary=combat.actor(key)
  if target.is_empty() or not bool(target.alive) or key in e.hits:continue
  if not combat.v56.cone(origin,aim,target.pos,reach,cos(deg_to_rad(arc*.5))) or not combat.path_clear(origin,target.pos):continue
  e.hits.append(key)
  if third:combat.knock(key,aim,40)
  combat.damage(key,float(e.damage),owner)
func friendly(owner:String,other:String)->bool:
 return not (combat.adventure.arcade and combat.adventure.game.mode in ["arena","battlegrounds"] and combat.adventure.game._rival(owner,other))
func catch_shot(start:Vector2,finish:Vector2,source:String,amount:float,colour:String)->bool:
 if not combat.adventure.authoritative():return false
 for e in effects:
  if str(e.style)!="shield_march" or int(e.caught)>=6 or not combat.adventure.alive(str(e.owner)) or friendly(str(e.owner),source) and source!="enemy":continue
  var p:Vector2=combat.vec(e.pos);var side:Vector2=combat.vec(e.aim).orthogonal()*float(e.stats.get("width",220))*.5
  if Geometry2D.segment_intersects_segment(start,finish,p-side,p+side)!=null:e.caught=int(e.caught)+1;return true
 for id in combat.adventure.points():
  var owner:=str(id)
  if not combat.adventure.alive(owner) or not combat.passive(owner,"slippery_scales") or source!="enemy" and friendly(owner,source):continue
  var p:Vector2=combat.owner_pos(owner)
  if Geometry2D.get_closest_point_to_segment(p,start,finish).distance_to(p)>24 or not combat.path_clear(start,p):continue
  scales[owner]=int(scales.get(owner,0))+1
  if int(scales[owner])%3!=0:return false
  combat.launch_projectile(owner,p,(start-finish).normalized(),{"range":330,"speed":430,"color":colour},minf(30,amount*.8))
  add(owner,"scale_flash",p,Vector2.RIGHT,{},0,.4)
  return true
 return false
func snapshot()->Dictionary:return {"effects":effects,"combos":combos,"scales":scales,"clock":clock}
func receive(data:Dictionary)->void:effects=data.get("effects",[]);combos=data.get("combos",{});scales=data.get("scales",{});clock=float(data.get("clock",clock))
func draw_on(c:Node2D,camera:Vector2)->void:
 for id in combat.adventure.points():
  if combat.passive(str(id),"steadfast_forge") and combat.effect_time(combat.player_key(str(id)),"guard")>0:
   c.draw_arc(combat.owner_pos(str(id))-camera,35,0,TAU,32,Color(.95,.72,.4,.4),2,true)
 for e in combat.draw_effect_records("v75","effects",effects):
  var p:Vector2=combat.draw_effect_position("v75",e,combat.owner_pos(str(e.owner)) if str(e.style)=="hammer_arc" else combat.vec(e.pos))-camera;var origin:Vector2=combat.vec(e.origin)-camera;var aim:Vector2=combat.vec(e.aim);var age:=float(e.age);var stats:Dictionary=e.stats
  if not Rect2(Vector2(-650,-650),Vector2(2580,2020)).has_point(p):continue
  match str(e.style):
   "water_jet":
    c.draw_line(origin+aim*22,p,Color(.25,.65,.9,.35),14,true);c.draw_line(origin+aim*22,p,Color("#a0eeff"),5,true)
    for n in 5:c.draw_circle(origin.lerp(p,fposmod(clock*4+n*.2,1)),3,Color("#d0faff"))
   "puddle":
    c.draw_circle(p,float(stats.get("puddle_radius",55)),Color(.18,.6,.8,.23));c.draw_arc(p,40+sin(clock*4)*4,0,TAU,32,Color(.4,.8,1,.5),2,true)
   "splash_flash":
    for n in 12:
     var d:=Vector2.from_angle(n*TAU/12);c.draw_line(p+d*age*140,p+d*(age*140+14),Color(.5,.85,1,1-age*1.8),4,true)
   "tidal_maw":
    var r:=float(stats.get("radius",100))
    c.draw_circle(p,r,Color(.02,.08,.16,.35));c.draw_arc(p,r,0,TAU,40,Color(.3,.8,1,.8),2,true)
    if age<2:
     c.draw_arc(p,r*clampf(age/2,0,1),0,TAU,40,Color(.7,.9,1,.55),3,true)
     c.draw_line(p+Vector2(-16,-r-15),p+Vector2(16,-r-15),Color("#b0efff"),3)
    else:
     var open:float=maxf(.1,sin(clampf((age-2)/.65,0,1)*PI))
     # Broad fish jaws rise from the shadow; eyes and fins distinguish it from a gear.
     c.draw_colored_polygon(PackedVector2Array([p+Vector2(-r*.7,-r*.2),p+Vector2(-r*1.1,r*.25),p+Vector2(-r*.65,r*.55)]),Color("#348c9b"))
     c.draw_colored_polygon(PackedVector2Array([p+Vector2(r*.7,-r*.2),p+Vector2(r*1.1,r*.25),p+Vector2(r*.65,r*.55)]),Color("#348c9b"))
     c.draw_circle(p,r*.82,Color("#4aabba"));c.draw_circle(p,r*.65,Color("#102c48"))
     c.draw_arc(p,r*.75,0,PI,30,Color("#8cdbc7"),12,true)
     for side in [-1,1]:
      var eye:Vector2=p+Vector2(side*r*.48,-r*.68)
      c.draw_circle(eye,r*.2,Color("#337b90"));c.draw_circle(eye,r*.14,Color("#f3edce"));c.draw_circle(eye+Vector2(0,r*.03),r*.06,Color("#173048"))
     for n in 5:
      var x:float=(n-2)*r*.22
      for side in [-1,1]:
       var base:Vector2=p+Vector2(x,side*r*.48)
       c.draw_colored_polygon(PackedVector2Array([base+Vector2(-9,0),base+Vector2(9,0),base+Vector2(0,-side*r*(.19+.12*open))]),Color("#fff4d8"))
   "shoal_vortex":
    c.draw_circle(p,125,Color(.1,.5,.8,.15))
    for n in 3:c.draw_arc(p,35+n*30,clock*3+n,clock*3+n+PI,24,Color("#a0eeff"),4,true)
   "hammer_arc":
    var sweep:float=aim.angle()-1+age/.35*2
    c.draw_arc(p,75,aim.angle()-1,sweep,20,Color(.95,.65,.35,.6),5,true)
    var tip:=p+Vector2.from_angle(sweep)*75;c.draw_line(p,tip,Color("#ad7552"),6);c.draw_circle(tip,12,Color("#b6c9cc"))
   "rally_banner":
    var r:=float(stats.get("radius",130));c.draw_circle(p,r,Color(.9,.6,.2,.09));c.draw_arc(p,r,0,TAU,40,Color(.95,.72,.4,.5),2,true)
    c.draw_line(p,p+Vector2(0,-65),Color("#d5baa0"),4);c.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-65),p+Vector2(36,-58+sin(clock*4)*3),p+Vector2(0,-35)]),Color("#e5a74e"))
   "shield_march":
    var side:=aim.orthogonal()*float(stats.get("width",220))*.5
    c.draw_line(p-side,p+side,Color(.6,.85,1,.25),24,true);c.draw_line(p-side,p+side,Color("#a5deec"),5,true)
    for n in 5:
     var q:=p-side+side*2*n/4;c.draw_arc(q,17,aim.angle()-PI*.5,aim.angle()+PI*.5,16,Color("#ecc483"),4,true)
   "forgefall":
    for n in 3:
     var q:=p+aim*n*90;var start:float=1+n*.2
     c.draw_arc(q,65,0,TAU,32,Color(.9,.6,.2,.5),2,true)
     var lift:float=maxf(0,(start-age)*100)
     c.draw_rect(Rect2(q+Vector2(-20,-lift-25),Vector2(40,22)),Color("#91aab1"))
     if age>=start:c.draw_arc(q,clampf((age-start)*160,0,65),0,TAU,32,Color("#f0c174"),5,true)
   "scale_flash":c.draw_arc(p,34,0,TAU,32,Color(.5,.9,1,maxf(0,1-age/.4)),4,true)
