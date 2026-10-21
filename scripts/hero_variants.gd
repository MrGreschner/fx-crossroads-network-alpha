extends Node
var combat:Node
var spirals:Array=[]
var breaths:Array=[]
var bombs:Array=[]
var runes:Array=[]
var domains:Array=[]
var trails:Array=[]
var combo:Dictionary={}
const STYLES=["blink_bomb","spiral_shards","fire_breath","rune_slash","rune_step","rune_domain"]
func reset()->void:
 spirals.clear();breaths.clear();bombs.clear();runes.clear();domains.clear();trails.clear();combo.clear()
func advance(origin:Vector2,aim:Vector2,distance:float)->Vector2:
 var point:=origin
 var bounds:Rect2=combat.adventure.game.FIELD if combat.adventure.arcade else Rect2(Vector2.ZERO,combat.adventure.game.region_size())
 for n in int(ceil(distance/10)):
  var next:=origin+aim*minf(distance,(n+1)*10)
  if not bounds.grow(-30).has_point(next) or not combat.path_clear(point,next):break
  point=next
 return point
func owned(owner:String)->Array:
 var result:Array=[]
 for rune in runes:
  if str(rune.owner)==owner:result.append(rune)
 return result
func rune(owner:String,point:Vector2)->void:
 var marks:=owned(owner)
 if marks.size()>=3:runes.erase(marks[0])
 runes.append({"owner":owner,"pos":combat.point_array(point),"time":15.0 if combat.passive(owner,"long_runes") else 10.0})
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var origin:Vector2=combat.owner_pos(owner);aim=aim.normalized()
 match style:
  "blink_bomb":
   var destination:=advance(origin,aim,float(stats.get("range",280)))
   combat.adventure.teleport(owner,destination)
   bombs.append({"owner":owner,"pos":combat.point_array(origin),"time":float(stats.get("fuse",1)),"damage":amount,"radius":float(stats.get("radius",115))})
   trails.append({"start":combat.point_array(origin),"end":combat.point_array(destination),"time":.4})
  "spiral_shards":
   if spirals.size()<24:spirals.append({"owner":owner,"pos":combat.point_array(origin),"elapsed":0.0,"prism_glass":bool(stats.get("prism_glass",false)),"duration":float(stats.get("duration",2)),"radius":float(stats.get("radius",250))+(60 if combat.passive(owner,"far_refraction") else 0),"angle":aim.angle(),"damage":amount,"hits":[[],[],[]],"blocked":[false,false,false]})
  "fire_breath":
   if breaths.size()<24:breaths.append({"owner":owner,"time":float(stats.get("duration",.4)),"tick":0.0,"left":4,"aim":combat.point_array(aim),"stats":stats,"damage":amount})
  "rune_slash":
   combo[owner]=int(combo.get(owner,0))+1
   var damage:=amount+(10 if int(combo[owner])%3==0 else 0)
   for key in combat.hostile(owner):
    var target:Dictionary=combat.actor(key)
    if target.is_empty():continue
    var offset:Vector2=target.pos-origin
    if offset.length()<=float(stats.get("range",90))+18 and aim.dot(offset.normalized())>cos(deg_to_rad(float(stats.get("arc_degrees",75))*.5)) and combat.path_clear(origin,target.pos):combat.damage(key,damage,owner)
   rune(owner,origin);trails.append({"start":combat.point_array(origin+aim*25),"end":combat.point_array(origin+aim*90),"time":.2})
  "rune_step":
   var destination:=advance(origin,aim,220)
   var marks:=owned(owner)
   if not marks.is_empty():
    var candidate:Vector2=combat.vec(marks[0].pos)
    if origin.distance_to(candidate)>55 and origin.distance_to(candidate)<=float(stats.get("range",480)) and combat.path_clear(origin,candidate):destination=candidate
   for key in combat.hostile(owner):
    var target:Dictionary=combat.actor(key)
    if not target.is_empty() and Geometry2D.get_closest_point_to_segment(target.pos,origin,destination).distance_to(target.pos)<38 and combat.path_clear(origin,target.pos):combat.damage(key,amount,owner)
   combat.adventure.teleport(owner,destination);rune(owner,origin);trails.append({"start":combat.point_array(origin),"end":combat.point_array(destination),"time":.5})
  "rune_domain":
   var polygon:Array=[]
   for mark in owned(owner):
    if combat.vec(mark.pos).distance_to(origin)<=500:polygon.append(mark.pos)
   var area:=0.0
   if polygon.size()==3:area=absf((combat.vec(polygon[1])-combat.vec(polygon[0])).cross(combat.vec(polygon[2])-combat.vec(polygon[0])))
   if polygon.size()<3 or area<900:
    polygon.clear()
    for n in 3:polygon.append(combat.point_array(advance(origin,Vector2.from_angle(aim.angle()+TAU*n/3),155)))
   if domains.size()<16:domains.append({"owner":owner,"points":polygon,"time":float(stats.get("duration",2.5)),"tick":0.0,"damage":amount})
 return true
func step(delta:float)->void:
 for i in range(trails.size()-1,-1,-1):
  trails[i].time-=delta
  if float(trails[i].time)<=0:trails.remove_at(i)
 for i in range(runes.size()-1,-1,-1):
  runes[i].time-=delta
  if float(runes[i].time)<=0 or not combat.adventure.alive(str(runes[i].owner)):runes.remove_at(i)
 for i in range(bombs.size()-1,-1,-1):
  var bomb:Dictionary=bombs[i];bomb.time-=delta
  if float(bomb.time)>0:continue
  combat.add_ring(str(bomb.owner),combat.vec(bomb.pos),{"radius":bomb.radius,"wave_speed":700,"color":"#ffc18a"},float(bomb.damage));bombs.remove_at(i)
 for i in range(breaths.size()-1,-1,-1):
  var breath:Dictionary=breaths[i];var owner:=str(breath.owner)
  if not combat.adventure.alive(owner) or combat.stunned(combat.player_key(owner)):breaths.remove_at(i);continue
  var elapsed:=minf(delta,maxf(0,float(breath.time)));breath.time-=delta;breath.tick+=elapsed
  var aim:Vector2=combat.vec(breath.aim)
  if combat.adventure.arcade:aim=Vector2.from_angle(float(combat.adventure.game.aim_angles.get(owner,aim.angle()))) if owner!=combat.adventure.game.my_id else combat.adventure.game.last_aim
  else:aim=combat.adventure.game.aim_direction()
  breath.aim=combat.point_array(aim.normalized())
  while float(breath.tick)>=.09999 and int(breath.left)>0:
   breath.tick-=.1;breath.left-=1
   var origin:Vector2=combat.owner_pos(owner)
   for key in combat.hostile(owner):
    var target:Dictionary=combat.actor(key)
    if target.is_empty():continue
    var offset:Vector2=target.pos-origin
    if offset.length()<=float(breath.stats.get("range",170)) and aim.dot(offset.normalized())>cos(deg_to_rad(float(breath.stats.get("arc_degrees",24))*.5)) and combat.path_clear(origin,target.pos):
     combat.damage(key,float(breath.damage),owner);combat.apply_status(key,"burn",float(breath.stats.get("burn_duration",3)),owner,float(breath.stats.get("burn_damage",1)))
  if float(breath.time)<=0:breaths.remove_at(i)
 for i in range(spirals.size()-1,-1,-1):
  var spiral:Dictionary=spirals[i];var owner:=str(spiral.owner)
  if not combat.adventure.alive(owner):spirals.remove_at(i);continue
  var old:=float(spiral.elapsed);spiral.elapsed=minf(float(spiral.duration),old+delta)
  var origin:Vector2=combat.vec(spiral.pos)
  for n in 3:
   if bool(spiral.blocked[n]):continue
   var a:=float(spiral.angle)+TAU*n/3
   var start:=origin+Vector2.from_angle(a+old*4)*(25+(float(spiral.radius)-25)*old/float(spiral.duration))
   var end:=origin+Vector2.from_angle(a+float(spiral.elapsed)*4)*(25+(float(spiral.radius)-25)*float(spiral.elapsed)/float(spiral.duration))
   if not combat.path_clear(start,end):spiral.blocked[n]=true;continue
   if combat.v56.catch_travelling(start,end,owner,float(spiral.damage),"#bcdfff",{"prism_glass":true}):spiral.blocked[n]=true;continue
   for key in combat.hostile(owner):
    if (spiral.hits[n] as Array).has(key):continue
    var target:Dictionary=combat.actor(key)
    if not target.is_empty() and Geometry2D.get_closest_point_to_segment(target.pos,start,end).distance_to(target.pos)<27:
     spiral.hits[n].append(key);combat.damage(key,float(spiral.damage),owner)
  if float(spiral.elapsed)>=float(spiral.duration):spirals.remove_at(i)
 for i in range(domains.size()-1,-1,-1):
  var domain:Dictionary=domains[i];var elapsed:=minf(delta,maxf(0,float(domain.time)));domain.time-=delta;domain.tick+=elapsed
  var polygon:=PackedVector2Array()
  for point in domain.points:polygon.append(combat.vec(point))
  while float(domain.tick)>=.49999:
   domain.tick-=.5
   for key in combat.hostile(str(domain.owner)):
    var target:Dictionary=combat.actor(key)
    if not target.is_empty() and Geometry2D.is_point_in_polygon(target.pos,polygon):combat.damage(key,float(domain.damage),str(domain.owner))
  if float(domain.time)<=0:domains.remove_at(i)
func snapshot()->Dictionary:return {"spirals":spirals,"breaths":breaths,"bombs":bombs,"runes":runes,"domains":domains,"trails":trails}
func receive(data:Dictionary)->void:
 spirals=data.get("spirals",[]);breaths=data.get("breaths",[]);bombs=data.get("bombs",[]);runes=data.get("runes",[]);domains=data.get("domains",[]);trails=data.get("trails",[])
func draw_on(canvas:Node2D,camera:Vector2)->void:
 for trail in trails:canvas.draw_line(combat.vec(trail.start)-camera,combat.vec(trail.end)-camera,Color(.6,.95,.85,float(trail.time)),6,true)
 for mark in runes:
  var point:Vector2=combat.vec(mark.pos)-camera
  canvas.draw_arc(point,18,0,TAU,20,Color(.5,.95,.8,.7),2,true);canvas.draw_line(point-Vector2(10,0),point+Vector2(10,0),Color("#b5f5df"),2,true);canvas.draw_line(point-Vector2(0,10),point+Vector2(0,10),Color("#b5f5df"),2,true)
 for bomb in bombs:
  var point:Vector2=combat.vec(bomb.pos)-camera
  canvas.draw_circle(point,15,Color("#b08759"));canvas.draw_circle(point-Vector2(0,5),5,Color("#ffd58a"));canvas.draw_arc(point,float(bomb.radius),0,TAU,32,Color(1,.7,.3,.4),2,true)
 for breath in breaths:
  var origin:Vector2=combat.owner_pos(str(breath.owner))-camera;var aim:Vector2=combat.vec(breath.aim);var width:=deg_to_rad(float(breath.stats.get("arc_degrees",24))*.5);var reach:=float(breath.stats.get("range",170));var clock:=Time.get_ticks_msec()/1000.0
  for n in 7:
   var direction:=aim.rotated((n-3)*width/3)
   var length:=reach*(.74+.17*sin(clock*19+n*1.4))
   var start:=origin+direction*22;var end:=origin+direction*length
   canvas.draw_line(start,end,Color(1,.42+.035*n,.1,.72),7,true)
   canvas.draw_line(start,origin+direction*(length*.75),Color(1,.8,.35,.8),2.5,true)
   canvas.draw_circle(end,3+sin(clock*23+n),Color(1,.58,.15,.5))
 for spiral in spirals:
  var origin:Vector2=combat.vec(spiral.pos)-camera;var radius:=25+(float(spiral.radius)-25)*float(spiral.elapsed)/float(spiral.duration)
  canvas.draw_arc(origin,radius,0,TAU,48,Color(.6,.8,1,.08),1,true)
  for n in 3:
   if bool(spiral.blocked[n]):continue
   var angle:=float(spiral.angle)+TAU*n/3+float(spiral.elapsed)*4;var point:=origin+Vector2.from_angle(angle)*radius
   if bool(spiral.get("prism_glass",false)):preload("res://scripts/hero_visuals1987.gd").prism(canvas,point,Vector2.from_angle(angle+PI*.5),14)
   else:canvas.draw_colored_polygon(PackedVector2Array([point+Vector2(0,-11),point+Vector2(7,0),point+Vector2(0,11),point+Vector2(-7,0)]),Color("#d3eafa"))
   canvas.draw_arc(origin,radius,angle-.3,angle,12,Color(.7,.9,1,.5),3,true)
 for domain in domains:
  var polygon:=PackedVector2Array()
  for point in domain.points:polygon.append(combat.vec(point)-camera)
  canvas.draw_colored_polygon(polygon,Color(.3,.85,.65,.12));polygon.append(polygon[0]);canvas.draw_polyline(polygon,Color(.65,1,.85,.7),4,true)
