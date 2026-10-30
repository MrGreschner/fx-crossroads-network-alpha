extends Node
## Pippa's living ribbons and finite leaf doubles. Host owns damage, healing and collision.
var combat:Node
var decoys:Array=[]
var threads:Array=[]
var dances:Array=[]
var clock:=0.0
const STYLES=["ribbon_stitch","fern_double","maypole_waltz","dawn_circle"]
func reset()->void:decoys.clear();threads.clear();dances.clear();clock=0
func decoy_for(point:Vector2)->Dictionary:
 var chosen:Dictionary={};var distance:=330.0
 for decoy in decoys:
  var d:float=point.distance_to(combat.vec(decoy.pos))
  if str(decoy.get("phase","lure"))=="lure" and float(decoy.time)>0 and d<distance:distance=d;chosen=decoy
 return chosen
# Opposing AI can be distracted; friendly AI and human movement are never redirected.
func lure_for(point:Vector2,observer:String="enemy")->Dictionary:
 var chosen:Dictionary={};var distance:=330.0
 for leaf in decoys:
  if str(leaf.get("phase","lure"))!="lure" or float(leaf.time)<=0 or not combat.adventure.alive(str(leaf.owner)):continue
  if observer!="enemy" and (not combat.adventure.arcade or combat.adventure.game.mode not in ["arena","battlegrounds"] or not combat.adventure.game._rival(observer,str(leaf.owner))):continue
  var pos:Vector2=combat.vec(leaf.pos);var d:=point.distance_to(pos)
  if d<distance and combat.path_clear(point,pos):chosen=leaf;distance=d
 return chosen
func actor(id:String)->Dictionary:
 for leaf in decoys:
  if id=="fern:"+str(leaf.owner) and str(leaf.phase)=="lure" and float(leaf.time)>0 and combat.adventure.alive(str(leaf.owner)):
   return {"pos":combat.vec(leaf.pos),"alive":true,"player":id}
 return {}
func redirect(enemy:Dictionary,target:Vector2)->Vector2:
 if bool(enemy.get("boss",false)):return target
 var leaf:=lure_for(enemy.pos)
 if not leaf.is_empty() and combat.path_clear(enemy.pos,combat.vec(leaf.pos)):
  var key:String=combat.npc_key(enemy)
  if key not in leaf.get("attracted",[]):leaf.attracted.append(key)
  return combat.vec(leaf.pos)
 return target
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var origin:Vector2=combat.owner_pos(owner);aim=aim.normalized()
 if aim.is_zero_approx():aim=Vector2.RIGHT
 match style:
  "dawn_circle":
   var radius:float=float(stats.get("radius",115))
   for key in combat.hostile(owner):
    var actor:Dictionary=combat.actor(key)
    if not actor.is_empty() and bool(actor.get("alive",false)) and origin.distance_to(actor.pos)<=radius and combat.path_clear(origin,actor.pos):combat.damage(key,amount,owner)
   combat.visuals.append({"style":"dawn_circle","pos":combat.point_array(origin),"radius":radius,"time":.85,"color":"#ffe6b7"})
  "ribbon_stitch":
   if threads.size()<60:
    for side in [-1,1]:threads.append({"owner":owner,"origin":combat.point_array(origin),"pos":combat.point_array(origin),"aim":combat.point_array(aim),"side":side,"distance":0.0,"damage":amount,"hits":[],"trail":[]})
  "fern_double":
   var point:Vector2=combat.chain.clip(origin,aim,float(stats.get("range",160)))
   for decoy in decoys.duplicate():
    if str(decoy.owner)==owner:decoys.erase(decoy)
   if decoys.size()<12:decoys.append({"owner":owner,"pos":combat.point_array(point),"time":3.0,"phase":"lure","attracted":[],"stats":stats.duplicate(true),"damage":amount,"elapsed":0.0,"ticks":0})
  "maypole_waltz":
   if dances.size()<12:dances.append({"owner":owner,"pos":combat.point_array(combat.chain.clip(origin,aim,float(stats.get("range",180)))),"age":0.0,"damage":amount,"hits":[[],[],[]],"old":[]})
 return true
func bloom(decoy:Dictionary)->void:
 var owner:=str(decoy.owner);var point:Vector2=combat.vec(decoy.pos)
 var stats:Dictionary=decoy.get("stats",{})
 var radius:float=float(stats.get("radius",150))
 for key in combat.hostile(owner):
  var actor:Dictionary=combat.actor(key)
  if actor.is_empty() or not bool(actor.get("alive",false)) or not combat.path_clear(point,actor.pos):continue
  var nearby:bool=point.distance_to(actor.pos)<=radius
  if nearby or key in decoy.get("attracted",[]):combat.apply_status(key,"slow",float(stats.get("slow_duration",3)),owner,float(stats.get("slow_factor",.55)))
  if nearby:combat.damage(key,float(decoy.get("damage",24)),owner)
 combat.visuals.append({"style":"fern_bloom","pos":decoy.pos,"radius":radius,"time":.6,"color":"#b8e5c5"})
 decoy.phase="healing";decoy.time=float(stats.get("heal_duration",3));decoy.elapsed=0.0;decoy.ticks=0

func heal_tick(decoy:Dictionary)->void:
 var owner:=str(decoy.owner);var point:Vector2=combat.vec(decoy.pos)
 var stats:Dictionary=decoy.get("stats",{})
 for id in combat.adventure.points():
  if not combat.adventure.alive(str(id)) or (combat.adventure.arcade and combat.adventure.game.mode in ["arena","battlegrounds"] and combat.adventure.game._rival(owner,str(id))):continue
  if point.distance_to(combat.adventure.points()[id])>float(stats.get("radius",150)) or not combat.path_clear(point,combat.adventure.points()[id]):continue
  var amount:float=float(stats.get("heal",8))
  combat.release_heroes.heal(owner,str(id),int(amount))
  if combat.passive(owner,"fern_afterglow"):combat.apply_status(combat.player_key(str(id)),"fern_stride",2,owner,.2)

func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 for n in range(decoys.size()-1,-1,-1):
  var decoy:Dictionary=decoys[n]
  if not combat.adventure.alive(str(decoy.owner)):decoys.remove_at(n);continue
  var healing_delta:float=delta
  if str(decoy.get("phase","lure"))=="lure":
   decoy.time-=delta
   if float(decoy.time)>0:continue
   healing_delta=-float(decoy.time)
   bloom(decoy)
  var used:float=minf(healing_delta,float(decoy.time))
  decoy.time-=used;decoy.elapsed+=used
  var total_ticks:int=int(floor(float(decoy.elapsed)+.00001))
  while int(decoy.ticks)<total_ticks:
   heal_tick(decoy);decoy.ticks+=1
  if float(decoy.time)<=.00001:decoys.remove_at(n)
 for n in range(threads.size()-1,-1,-1):
  var thread:Dictionary=threads[n];var start:Vector2=combat.vec(thread.pos);var aim:Vector2=combat.vec(thread.aim)
  thread.distance+=delta*350
  var point:Vector2=combat.vec(thread.origin)+aim*float(thread.distance)+aim.orthogonal()*sin(float(thread.distance)*TAU/150)*22*int(thread.side)
  if not combat.path_clear(start,point) or float(thread.distance)>380:threads.remove_at(n);continue
  if combat.v56.catch_travelling(start,point,str(thread.owner),float(thread.damage),"#b8e5c5",{"stolen_visual":"ribbon"}):threads.remove_at(n);continue
  thread.pos=combat.point_array(point);thread.trail.append(thread.pos.duplicate())
  if thread.trail.size()>12:thread.trail.remove_at(0)
  for key in combat.hostile(str(thread.owner)):
   var actor:Dictionary=combat.actor(key)
   if actor.is_empty() or key in thread.hits or not bool(actor.get("alive",false)):continue
   if Geometry2D.get_closest_point_to_segment(actor.pos,start,point).distance_to(actor.pos)<24:
    thread.hits.append(key);combat.damage(key,float(thread.damage),str(thread.owner))
 for n in range(dances.size()-1,-1,-1):
  var dance:Dictionary=dances[n];dance.age+=delta
  if float(dance.age)>2.4:dances.remove_at(n);continue
  var center:Vector2=combat.vec(dance.pos);var radius:float=230*float(dance.age)/2.4
  for arm in 3:
   var point:Vector2=center+Vector2.from_angle(float(dance.age)*3.5+TAU*arm/3)*radius
   var previous:Vector2=combat.vec(dance.old[arm]) if dance.old.size()>arm else center
   for key in combat.hostile(str(dance.owner)):
    var actor:Dictionary=combat.actor(key)
    if actor.is_empty() or key in dance.hits[arm] or not bool(actor.get("alive",false)):continue
    if Geometry2D.get_closest_point_to_segment(actor.pos,previous,point).distance_to(actor.pos)<32 and combat.path_clear(center,actor.pos):
     dance.hits[arm].append(key);combat.damage(key,float(dance.damage),str(dance.owner));combat.apply_status(key,"slow",2,str(dance.owner),.65)
   if dance.old.size()>arm:dance.old[arm]=combat.point_array(point)
   else:dance.old.append(combat.point_array(point))
func snapshot()->Dictionary:return {"decoys":decoys,"threads":threads,"dances":dances,"clock":clock}
func receive(s:Dictionary)->void:decoys=s.get("decoys",[]);threads=s.get("threads",[]);dances=s.get("dances",[]);clock=float(s.get("clock",0))
func draw_on(canvas:Node2D,camera:Vector2)->void:
 for thread in threads:
  var trail:=PackedVector2Array()
  for point in thread.trail:trail.append(combat.vec(point)-camera)
  if trail.size()>1:canvas.draw_polyline(trail,Color("#f1b9d3") if int(thread.side)>0 else Color("#b3e3b8"),4,true)
  canvas.draw_circle(combat.vec(thread.pos)-camera,6,Color("#fae4bd"))
 for decoy in decoys:
  var point:Vector2=combat.vec(decoy.pos)-camera
  if str(decoy.get("phase","lure"))=="healing":
   var pulse:float=.35+.3*sin(clock*TAU)
   var radius:float=float(decoy.get("stats",{}).get("radius",150))
   canvas.draw_circle(point,radius,Color(1,.88,.3,pulse*.13))
   canvas.draw_arc(point,radius,0,TAU,64,Color(1,.88,.3,pulse),3,true)
   canvas.draw_circle(point+Vector2(0,-20),19,Color(1,.88,.3,pulse))
   canvas.draw_line(point+Vector2(-7,-20),point+Vector2(7,-20),Color("#fff5c5"),3,true)
   canvas.draw_line(point+Vector2(0,-27),point+Vector2(0,-13),Color("#fff5c5"),3,true)
  else:
   canvas.draw_circle(point,32,Color(.5,.76,.56,.22));canvas.draw_colored_polygon(PackedVector2Array([point+Vector2(-18,0),point+Vector2(0,-57),point+Vector2(18,0)]),Color("#9bce9e"));canvas.draw_circle(point+Vector2(0,-40),13,Color("#d8dfb3"));canvas.draw_arc(point,38,0,TAU*float(decoy.time)/3,28,Color("#e4b7d1"),3)
 for dance in dances:
  var center:Vector2=combat.vec(dance.pos)-camera;var radius:float=230*float(dance.age)/2.4
  canvas.draw_line(center,center-Vector2(0,80),Color("#cab180"),7);canvas.draw_circle(center-Vector2(0,80),12,Color("#efb9d1"))
  for arm in 3:
   var tip:Vector2=center+Vector2.from_angle(float(dance.age)*3.5+TAU*arm/3)*radius;var line:=PackedVector2Array()
   for n in 12:
    var t:=n/11.0;line.append((center-Vector2(0,80)).lerp(tip,t)+Vector2(0,sin(t*PI)*25))
   canvas.draw_polyline(line,[Color("#eab8d0"),Color("#b4ddbe"),Color("#ead39b")][arm],5,true);canvas.draw_circle(tip,12,Color("#e8c3cf"))
