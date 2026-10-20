extends Node
## One bounded mark per target. Authority resolves deaths; snapshots carry visual marks.
var combat:Node
var marks:Dictionary={}
func reset()->void:marks.clear()
func mark_area(owner:String,center:Vector2,radius:float)->void:
 for key in combat.hostile(owner):
  var target:Dictionary=combat.actor(key)
  if not target.is_empty() and bool(target.alive) and center.distance_to(target.pos)<=radius and combat.path_clear(center,target.pos):
   if marks.size()<64 or marks.has(key):marks[key]={"owner":owner,"time":5.0,"pos":combat.point_array(target.pos)}
func step(delta:float)->void:
 var bursts:Array=[]
 for key in marks.keys():
  var entry:Dictionary=marks[key];var target:Dictionary=combat.actor(key)
  if target.is_empty() or not bool(target.get("alive",false)):
   if float(entry.time)>0:bursts.append(entry.duplicate(true))
   marks.erase(key);continue
  entry.pos=combat.point_array(target.pos);entry.time=float(entry.time)-delta
  if float(entry.time)<=0:marks.erase(key)
 for entry in bursts:
  var center:Vector2=combat.vec(entry.pos)
  for key in combat.hostile(str(entry.owner)):
   var target:Dictionary=combat.actor(key)
   if not target.is_empty() and bool(target.alive) and center.distance_to(target.pos)<=95 and combat.path_clear(center,target.pos):combat.damage(key,20,str(entry.owner),"Starfall Echo")
  combat.visuals.append({"pos":entry.pos,"radius":95,"time":.4,"color":"#a4e4f8"})
static func star(c:Node2D,p:Vector2,size:float,tint:Color,angle:float=0)->void:
 var shape=PackedVector2Array()
 for n in 10:shape.append(p+Vector2.UP.rotated(angle+TAU*n/10)*(size if n%2==0 else size*.42))
 c.draw_colored_polygon(shape,tint)
func draw_on(c:Node2D,camera:Vector2)->void:
 var t=Time.get_ticks_msec()/1000.0
 for key in marks:
  var entry:Dictionary=marks[key];var target:Dictionary=combat.actor(key)
  var p:Vector2=(target.get("pos",combat.vec(entry.pos)) as Vector2)-camera-Vector2(0,54)
  star(c,p,10,Color("#fbe1a0"),sin(t*2)*.1)
  c.draw_arc(p,14,-PI*.5,-PI*.5+TAU*clampf(float(entry.time)/5,0,1),20,Color("#8dddeb"),2,true)
 for owner in combat.adventure.points():
  if combat.passive(str(owner),"telescope_aura") and combat.adventure.alive(str(owner)):
   var p:Vector2=combat.owner_pos(str(owner))-camera
   c.draw_arc(p,160,t*.15,t*.15+TAU,48,Color(.45,.78,.94,.18),1.5,true)
   for n in 4:star(c,p+Vector2.from_angle(t*.15+n*TAU/4)*160,4,Color(.65,.87,1,.5))
func draw_shot(c:Node2D,shot:Dictionary,p:Vector2,t:float)->void:
 var direction:Vector2=combat.vec(shot.aim)
 c.draw_line(p-direction*25,p,Color(.36,.72,.95,.45),5,true)
 c.draw_line(p-direction*16,p,Color(.72,.91,1,.8),2,true)
 star(c,p,float(shot.radius)*.95,Color("#8dd9f0"),t*2)
 star(c,p,float(shot.radius)*.48,Color("#fff2c9"),t*2)
