extends Node
## Velvetwing's silk: authority owns collisions; guests receive visual state.
var combat:Node
var lines:Array=[]
var looms:Array=[]
var flashes:Array=[]
var serial:int=0
const STYLES=["threaded_needles","silk_tripline","lunar_loom"]
func reset()->void:lines.clear();looms.clear();flashes.clear();serial=0
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:String=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 aim=aim.normalized()
 if aim.is_zero_approx():aim=Vector2.RIGHT
 var origin:Vector2=combat.owner_pos(owner);var side:=aim.orthogonal()
 match style:
  "threaded_needles":
   var focus:Vector2=origin+aim*190
   for sign in [-1,1]:
    var start:Vector2=origin+aim*28+side*sign*34
    if not combat.path_clear(origin,start):start=origin+aim*20
    combat.launch_projectile(owner,start,(focus-start).normalized(),stats,amount,"silk_needle")
    combat.projectiles[-1].radius=6.0
   flashes.append({"pos":combat.point_array(origin),"aim":combat.point_array(aim),"time":.3})
  "silk_tripline":
   serial+=1;var hits:Array=[]
   for n in 3:
    var center:Vector2=combat.chain.clip(origin,aim,100+n*80)
    if center.distance_to(origin)<65:continue
    var start:Vector2=combat.chain.clip(center,-side,75);var end:Vector2=combat.chain.clip(center,side,75)
    if lines.size()<24:lines.append({"owner":owner,"start":combat.point_array(start),"end":combat.point_array(end),"age":0.0,"time":float(stats.get("duration",4)),"damage":amount,"hits":hits,"serial":serial,"previous":{}})
   if combat.passive(owner,"soft_landing"):combat.apply_status(combat.player_key(owner),"silk_guard",2.5,owner,.15)
  "lunar_loom":
   if looms.size()<8:looms.append({"owner":owner,"pos":combat.point_array(origin),"aim":combat.point_array(aim),"age":0.0,"duration":3.4,"reach":float(stats.get("range",360)),"damage":amount,"hits":{},"counts":{},"pause_tick":0.0})
 return true
func wing(entry:Dictionary,sign:int,age:float)->Vector2:
 var origin:Vector2=combat.vec(entry.pos);var aim:Vector2=combat.vec(entry.aim)
 var reach:float=float(entry.get("reach",360));var summit:Vector2=origin+aim*reach
 if age<1.2:
  var t:float=clampf(age/1.2,0,1)
  return origin+aim*(30+t*(reach-30))+aim.orthogonal()*sign*sin(t*PI)*140
 if age<=2.2:return summit
 var t:float=clampf((age-2.2)/1.2,0,1)
 return summit.lerp(combat.owner_pos(str(entry.owner)),t)+aim.orthogonal()*sign*sin(t*PI)*140
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 for n in range(flashes.size()-1,-1,-1):
  flashes[n].time-=delta
  if float(flashes[n].time)<=0:flashes.remove_at(n)
 for n in range(lines.size()-1,-1,-1):
  var line:Dictionary=lines[n];line.age+=delta;line.time-=delta
  if not combat.adventure.alive(str(line.owner)) or float(line.time)<=0:lines.remove_at(n);continue
  var start:Vector2=combat.vec(line.start);var end:Vector2=combat.vec(line.end);var triggered:=false
  for key in combat.hostile(str(line.owner)):
   var actor:Dictionary=combat.actor(key)
   if actor.is_empty() or not actor.get("alive",false):continue
   var point:Vector2=actor.pos;var prior:Vector2=combat.vec(line.previous.get(key,combat.point_array(point)));line.previous[key]=combat.point_array(point)
   if float(line.age)<.6 or line.hits.has(key):continue
   var crossed:Variant=Geometry2D.segment_intersects_segment(prior,point,start,end)
   var near:bool=Geometry2D.get_closest_point_to_segment(point,start,end).distance_to(point)<16
   if (crossed!=null or near) and combat.path_clear(start,point):
    line.hits.append(key);combat.damage(key,float(line.damage),str(line.owner));combat.apply_status(key,"slow",2,str(line.owner),.5)
    combat.visuals.append({"pos":combat.point_array(point),"radius":35,"time":.4,"color":"#ddc7ed"});triggered=true;break
  if triggered:lines.remove_at(n)
 for n in range(looms.size()-1,-1,-1):
  var entry:Dictionary=looms[n];var old_age:float=entry.age;entry.age+=delta
  var owner:String=str(entry.owner)
  if not combat.adventure.alive(owner):looms.remove_at(n);continue
  var pause_time:float=maxf(0,minf(float(entry.age),2.2)-maxf(old_age,1.2))
  entry.pause_tick=float(entry.get("pause_tick",0))+pause_time
  while float(entry.pause_tick)>=.24999:
   entry.pause_tick-=.25
   var center:Vector2=wing(entry,1,1.5)
   for key in combat.hostile(owner):
    var target:Dictionary=combat.actor(key)
    if not target.is_empty() and target.alive and center.distance_squared_to(target.pos)<=3600 and combat.path_clear(center,target.pos):combat.damage(key,6,owner)
  if float(entry.age)<1.2 or float(entry.age)>2.2:
   var leg:int=0 if float(entry.age)<1.2 else 1
   for sign in [-1,1]:
    var start:Vector2=wing(entry,sign,old_age);var end:Vector2=wing(entry,sign,float(entry.age))
    for key in combat.hostile(owner):
     var token:String=str(key)+":"+str(leg)
     if entry.hits.has(token):continue
     var target:Dictionary=combat.actor(key)
     if target.is_empty() or not target.alive:continue
     if Geometry2D.get_closest_point_to_segment(target.pos,start,end).distance_squared_to(target.pos)<=2025 and combat.path_clear(combat.vec(entry.pos),target.pos):
      entry.hits[token]=true;combat.damage(key,float(entry.damage),owner)
  if float(entry.age)>=3.4-.00001:looms.remove_at(n)
func snapshot()->Dictionary:return {"lines":lines,"looms":looms,"flashes":flashes}
func receive(data:Dictionary)->void:lines=data.get("lines",[]);looms=data.get("looms",[]);flashes=data.get("flashes",[])
func draw_on(c:Node2D,camera:Vector2)->void:
 for owner in combat.adventure.points():
  if not combat.visible_owner(str(owner)):continue
  if combat.effect_time(combat.player_key(str(owner)),"silk_guard")<=0:continue
  var p:Vector2=combat.adventure.points()[owner]-camera
  c.draw_circle(p,39,Color(.82,.74,.98,.09));c.draw_arc(p,39,0,TAU,32,Color(.86,.81,1,.32),2,true)
 for line in lines:
  var start:Vector2=combat.vec(line.start)-camera;var end:Vector2=combat.vec(line.end)-camera
  var ready:bool=float(line.age)>=.6
  c.draw_line(start,end,Color(.83,.75,.93,.65 if ready else .25),3,true)
  for point in [start,end]:c.draw_circle(point,5,Color("#e7cfaf"))
  for n in 7:
   var point:Vector2=start.lerp(end,float(n)/6)
   c.draw_circle(point+Vector2(0,sin(Time.get_ticks_msec()*.008+n)*2),2,Color("#f6e6fc"))
 for entry in looms:
  var origin:Vector2=combat.vec(entry.pos)-camera
  if float(entry.age)>=1.2 and float(entry.age)<=2.2:
   var center:Vector2=wing(entry,1,1.5)-camera
   c.draw_circle(center,60,Color(1,.88,.55,.13));c.draw_arc(center,60,0,TAU,32,Color(1,.9,.65,.55),3,true)
  for sign in [-1,1]:
   var last:Vector2=wing(entry,sign,maxf(0,float(entry.age)-.55))-camera
   for n in 18:
    var age:float=maxf(0,float(entry.age)-.55+n*.55/17)
    var point:Vector2=wing(entry,sign,age)-camera
    c.draw_line(last,point,Color(1,.86,.65,.18+float(n)/18*.55),3+float(n)/18*5,true);last=point
   var head:Vector2=wing(entry,sign,float(entry.age))-camera
   c.draw_arc(head,45,0,TAU,24,Color("#f4dea6"),2,true)
   c.draw_colored_polygon(PackedVector2Array([head+Vector2(0,-14),head+Vector2(10,0),head+Vector2(0,14),head+Vector2(-10,0)]),Color("#fff1c9"))
 for flash in flashes:
  var origin:Vector2=combat.vec(flash.pos)-camera;var aim:Vector2=combat.vec(flash.aim)
  for sign in [-1,1]:c.draw_line(origin+aim.orthogonal()*sign*27,origin+aim*40,Color("#e5cef3"),2,true)
