extends Node
## Position records and bounded bullet stasis. Damage is host-authoritative.
var combat:Node
var marks:Dictionary={}
var fields:Array=[]
var traces:Array=[]
var clock:=0.0
const STYLES=["time_dart","rewind_chime","time_bubble"]
func reset()->void:marks.clear();fields.clear();traces.clear();clock=0
func mark(key:String,owner:String)->void:
 var target:Dictionary=combat.actor(key)
 if target.is_empty() or not bool(target.alive) or not combat.adventure.authoritative():return
 if not marks.has(owner):marks[owner]=[]
 var entries:Array=marks[owner]
 var duration:=6.0 if combat.passive(owner,"patient_hands") else 4.0
 for entry in entries:
  if str(entry.key)==key:entry.time=duration;return
 if entries.size()>=3:entries.pop_front()
 entries.append({"key":key,"pos":combat.point_array(target.pos),"time":duration})
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var origin:Vector2=combat.owner_pos(owner)
 aim=aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
 match style:
  "time_dart":combat.launch_projectile(owner,origin+aim*24,aim,stats,amount,"time_dart")
  "rewind_chime":
   var count:=0
   for entry in marks.get(owner,[]).duplicate(true):
    var key:=str(entry.key);var target:Dictionary=combat.actor(key)
    if target.is_empty() or not bool(target.alive) or not combat.hostile(owner).has(key):continue
    var point:Vector2=target.pos
    if point.distance_to(origin)>float(stats.get("range",550)) or not combat.path_clear(origin,point):continue
    var goal:Vector2=combat.vec(entry.pos)
    if not bool(target.get("npc",{}).get("boss",false)):combat.knock(key,(goal-point).normalized(),minf(500,goal.distance_to(point)))
    var end:Vector2=combat.actor(key).get("pos",point)
    traces.append({"start":combat.point_array(point),"end":combat.point_array(end),"time":.55})
    combat.damage(key,amount,owner);combat.apply_hit_status(key,stats,owner);count+=1
   marks.erase(owner)
   if count>0 and float(stats.get("rewind_heal",0))>0:combat.mastery_combat.heal(owner,owner,minf(6,count*float(stats.rewind_heal)))
   traces.append({"start":combat.point_array(origin),"end":combat.point_array(origin),"time":.55})
  "time_bubble":
   # Only one field per owner; replacing it cannot multiply capture or burst damage.
   for n in range(fields.size()-1,-1,-1):
    if str(fields[n].owner)==owner:fields.remove_at(n)
   var point:Vector2=combat.chain.clip(origin,aim,float(stats.get("range",250)))
   fields.append({"owner":owner,"pos":combat.point_array(point),"time":clampf(float(stats.get("duration",2)),.5,3),"radius":clampf(float(stats.get("radius",130)),40,180),"damage":amount,"slow":clampf(float(stats.get("slow",.7)),.4,1),"held":[]})
 return true
func catch_shot(start:Vector2,finish:Vector2,source:String)->bool:
 if not combat.adventure.authoritative():return false
 for field in fields:
  var owner:=str(field.owner)
  if not combat.adventure.alive(owner) or (field.held as Array).size()>=6:continue
  if source!="enemy" and not (combat.adventure.arcade and combat.adventure.game.mode=="arena" and combat.adventure.game._rival(owner,source)):continue
  var center:Vector2=combat.vec(field.pos)
  var nearest:=Geometry2D.get_closest_point_to_segment(center,start,finish)
  if nearest.distance_to(center)>float(field.radius) or not combat.path_clear(start,nearest):continue
  field.held.append(combat.point_array(nearest));return true
 return false
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 for owner in marks.keys():
  var entries:Array=marks[owner]
  if not combat.adventure.alive(str(owner)):marks.erase(owner);continue
  for n in range(entries.size()-1,-1,-1):
   entries[n].time-=delta
   var target:Dictionary=combat.actor(str(entries[n].key))
   if float(entries[n].time)<=0 or target.is_empty() or not bool(target.alive):entries.remove_at(n)
  if entries.is_empty():marks.erase(owner)
 for n in range(fields.size()-1,-1,-1):
  var field:Dictionary=fields[n];var owner:=str(field.owner);var center:Vector2=combat.vec(field.pos)
  if not combat.adventure.alive(owner):fields.remove_at(n);continue
  field.time-=delta
  for key in combat.hostile(owner):
   var target:Dictionary=combat.actor(key)
   if target.is_empty() or not bool(target.alive) or center.distance_to(target.pos)>float(field.radius) or not combat.path_clear(center,target.pos):continue
   combat.apply_status(key,"slow",.3,owner,float(field.slow))
   if float(field.time)<=0:combat.damage(key,float(field.damage)+4*(field.held as Array).size(),owner)
  if float(field.time)<=0:
   combat.visuals.append({"pos":field.pos,"radius":field.radius,"time":.6,"color":"#a6dddd"});fields.remove_at(n)
 for n in range(traces.size()-1,-1,-1):
  traces[n].time-=delta
  if float(traces[n].time)<=0:traces.remove_at(n)
func snapshot()->Dictionary:return {"marks":marks,"fields":fields,"traces":traces,"clock":clock}
func receive(data:Dictionary)->void:marks=data.get("marks",{});fields=data.get("fields",[]);traces=data.get("traces",[]);clock=float(data.get("clock",clock))
func draw_on(c:Node2D,camera:Vector2)->void:
 for owner in marks:
  for entry in marks[owner]:
   var target:Dictionary=combat.actor(str(entry.key))
   if target.is_empty():continue
   var p:Vector2=target.pos-camera;var origin:Vector2=combat.vec(entry.pos)-camera
   c.draw_arc(origin,14,0,TAU,24,Color(.8,.7,.4,.4),2)
   c.draw_arc(p,26,clock,clock+TAU*.85,24,Color(.6,.9,.9,.75),2)
   c.draw_line(p+Vector2(0,-35),p+Vector2(0,-44),Color("#ead399"),2)
   c.draw_line(p+Vector2(0,-35),p+Vector2(7,-35),Color("#ead399"),2)
 for field in fields:
  var p:Vector2=combat.vec(field.pos)-camera;var radius:=float(field.radius)
  c.draw_circle(p,radius,Color(.3,.7,.8,.12));c.draw_arc(p,radius,0,TAU,64,Color(.6,.9,.9,.65),3,true)
  c.draw_arc(p,radius-8,-PI*.5,-PI*.5+TAU*clampf(float(field.time)/2,0,1),64,Color("#e7cf8d"),3,true)
  c.draw_line(p,p+Vector2.from_angle(clock*2)*radius*.65,Color(.9,.8,.5,.35),3,true)
  for held in field.held:
   var q:Vector2=combat.vec(held)-camera;c.draw_circle(q,5,Color("#e7cf8d"));c.draw_arc(q,9,0,TAU,12,Color(.6,.9,.9,.5),1)
 for trace in traces:
  var p:Vector2=combat.vec(trace.start)-camera;var end:Vector2=combat.vec(trace.end)-camera
  c.draw_line(p,end,Color(.6,.9,.9,float(trace.time)),5,true);c.draw_arc(end,35*(1-float(trace.time)),0,TAU,24,Color(.9,.8,.5,float(trace.time)),3)
 for shot in combat.projectiles:
  if str(shot.style)!="time_dart":continue
  var p:Vector2=combat.vec(shot.pos)-camera;var aim:Vector2=combat.vec(shot.aim)
  c.draw_line(p-aim*18,p+aim*9,Color("#e7cf8d"),3,true);c.draw_line(p+aim*9,p+aim*2+aim.orthogonal()*5,Color("#b4eff0"),2,true)
