extends Node
## Bounded, authoritative effects shared by solo, co-op and arena.
var combat:Node
var shots:Array=[]
var zones:Array=[]
var flashes:Array=[]
var echoes:Array=[]
var marks:Dictionary={}
var paths:Dictionary={}
var memories:Dictionary={}
var seams:Dictionary={}
var clock:=0.0
var sample_clock:=0.0
const STYLES=["tide_needle","sluice_pool","tidal_wheel","tide_fan","volt_note","relay_field","thunder_score","volt_lance","shuttle_stitch","seam_ride","loom_cage","loom_fan","paradox_split","history_rewind","royal_reprise","time_cage"]
func reset()->void:
 shots.clear();echoes.clear();zones.clear();flashes.clear();marks.clear();paths.clear();memories.clear();seams.clear();clock=0;sample_clock=0
func color(element:String)->Color:return Color("#6ce2d7") if element=="water" else Color("#ffdc7e") if element=="volt" else Color("#f1a1ca") if element=="thread" else Color("#bdb2ff")
func point(owner:String,aim:Vector2,reach:float)->Vector2:return combat.v79.destination(owner,aim,reach)
func flash(p:Vector2,r:float,element:String)->void:
 if flashes.size()>=60:flashes.pop_front()
 flashes.append({"pos":combat.point_array(p),"radius":r,"element":element,"time":.45})
func hit(owner:String,key:String,damage:float,element:String)->void:
 var target:Dictionary=combat.actor(key)
 if target.is_empty() or not bool(target.alive):return
 var p:Vector2=target.pos
 if element in ["water","volt"]:
  var old:Dictionary=marks.get(key,{})
  if not old.is_empty() and str(old.element)!=element and float(old.until)>clock and str(old.owner)!=owner and combat.v75.friendly(owner,str(old.owner)) and combat.adventure.alive(str(old.owner)):
   marks.erase(key);flash(p,85,"volt")
   # Consume before damage: reactions cannot recursively trigger other reactions.
   for other in combat.hostile(owner):
    var actor:Dictionary=combat.actor(other)
    if not actor.is_empty() and bool(actor.alive) and p.distance_to(actor.pos)<85 and combat.path_clear(p,actor.pos):combat.damage(other,10,owner)
  else:marks[key]={"owner":owner,"element":element,"until":clock+3.0,"pos":combat.point_array(p)}
  if element=="water":combat.apply_status(key,"slow",.9,owner,.8)
 combat.damage(key,damage,owner)
func area(owner:String,p:Vector2,r:float,damage:float,element:String)->void:
 for key in combat.hostile(owner):
  var target:Dictionary=combat.actor(key)
  if not target.is_empty() and bool(target.alive) and target.pos.distance_to(p)<=r and combat.path_clear(p,target.pos):hit(owner,key,damage,element)
func shot(owner:String,p:Vector2,aim:Vector2,damage:float,element:String,reach:float=450,split:bool=false)->void:
 if shots.size()>=96:return
 shots.append({"owner":owner,"pos":combat.point_array(p),"aim":combat.point_array(aim.normalized()),"damage":damage,"element":element,"left":reach,"split":split})
func zone(owner:String,p:Vector2,r:float,damage:float,element:String,time:float,interval:float=1)->void:
 var mine:Array=zones.filter(func(z):return str(z.owner)==owner)
 if mine.size()>=3:zones.erase(mine[0])
 if zones.size()>=24:zones.pop_front()
 zones.append({"owner":owner,"pos":combat.point_array(p),"radius":r,"damage":damage,"element":element,"time":time,"tick":interval,"interval":interval,"angle":0.0})
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var p:Vector2=combat.owner_pos(owner);aim=aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
 var reach:=float(stats.get("range",420));var end:=point(owner,aim,reach)
 match style:
  "tide_needle","volt_note","volt_lance","shuttle_stitch":
   var element:="water" if style=="tide_needle" else "thread" if style=="shuttle_stitch" else "volt"
   shot(owner,p+aim*18,aim,amount,element,reach)
   if style=="shuttle_stitch":seams[owner]={"from":combat.point_array(p),"to":combat.point_array(combat.v75.clip(p,aim,reach)),"time":6.0}
   if style=="volt_lance":shot(owner,p-aim*15,aim,amount*.45,element,reach)
  "tide_fan","loom_fan":
   for n in 3:shot(owner,p,aim.rotated((n-1)*.22),amount,"water" if style=="tide_fan" else "thread",reach)
  "sluice_pool","relay_field":zone(owner,end,float(stats.get("radius",95)),amount,"water" if style=="sluice_pool" else "volt",float(stats.get("duration",4)))
  "tidal_wheel":
   zone(owner,end,145,amount,"water",4,.8);zones[-1]["drift"]=combat.point_array(aim*65)
  "thunder_score":
   var origins:Array=[]
   for existing in zones:
    if str(existing.owner)==owner and str(existing.element)=="volt" and combat.vec(existing.pos).distance_to(end)>=50 and combat.vec(existing.pos).distance_to(end)<600 and combat.path_clear(combat.vec(existing.pos),end):origins.append(existing.pos)
   if origins.is_empty():
    for n in 3:origins.append(combat.point_array(combat.v75.clip(end,Vector2.from_angle(n*TAU/3),120)))
   zone(owner,end,145,amount,"volt",4,.8);zones[-1]["chords"]=origins;zones[-1].tick=-.55
  "seam_ride":
   if seams.has(owner):
    var dest:Vector2=combat.vec(seams[owner].to);dest=combat.v75.clip(p,dest-p,minf(400,p.distance_to(dest)))
    var touched:Array=[];combat.v78.line_hit(owner,p,dest,26,amount,{},touched)
    combat.adventure.teleport(owner,dest);flash(dest,55,"thread");seams.erase(owner)
   else:
    var dest:Vector2=combat.v75.clip(p,aim,140);combat.adventure.teleport(owner,dest);flash(dest,40,"thread")
   if combat.passive(owner,"hem_guard"):combat.apply_status(combat.player_key(owner),"guard",1.5,owner,.1)
  "loom_cage":zone(owner,end,125,amount,"thread",5)
  "paradox_split":
   var distance:=clampf(p.distance_to(end),60,reach)
   shot(owner,p,aim,amount,"time",distance,true)
   var history:Array=memories.get(owner,[]);history.append({"pos":combat.point_array(p),"aim":combat.point_array(aim),"reach":distance})
   while history.size()>3:history.pop_front()
   memories[owner]=history
  "history_rewind":
   var history:Array=paths.get(owner,[]);var previous:=p;var touched:Array=[]
   for n in range(history.size()-1,-1,-1):
    var dest:Vector2=combat.vec(history[n]);var clipped:Vector2=combat.v75.clip(previous,dest-previous,previous.distance_to(dest))
    combat.v78.line_hit(owner,previous,clipped,32,amount,{},touched);flash(clipped,18,"time");previous=clipped
    if clipped.distance_to(dest)>2:break
   combat.adventure.teleport(owner,previous);paths[owner]=[]
   if combat.passive(owner,"borrowed_moment"):combat.apply_status(combat.player_key(owner),"guard",1,owner,.2)
  "royal_reprise":
   var history:Array=memories.get(owner,[])
   if history.is_empty():history=[{"pos":combat.point_array(p),"aim":combat.point_array(aim),"reach":300}]
   for memory in history:
    var origin:Vector2=combat.vec(memory.pos)
    if combat.path_clear(p,origin):
     shot(owner,origin,combat.vec(memory.aim),amount,"time",float(memory.reach),true);flash(origin,32,"time")
     if echoes.size()<18:echoes.append({"pos":combat.point_array(origin),"time":.8})
  "time_cage":zone(owner,end,150,amount,"time",4)
 return true
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta;sample_clock+=delta
 if sample_clock>=.15:
  sample_clock=0
  for owner in combat.adventure.points():
   if combat.v78.hero(str(owner))!="regent" or not combat.adventure.alive(str(owner)):continue
   var history:Array=paths.get(owner,[]);history.append(combat.point_array(combat.owner_pos(str(owner))))
   while history.size()>20:history.pop_front()
   paths[owner]=history
 for i in range(echoes.size()-1,-1,-1):
  echoes[i].time=float(echoes[i].time)-delta
  if float(echoes[i].time)<=0:echoes.remove_at(i)
 for key in marks.keys():
  if float(marks[key].until)<clock or combat.actor(str(key)).is_empty() or not combat.adventure.alive(str(marks[key].owner)):marks.erase(key)
 for owner in seams.keys():
  seams[owner].time=float(seams[owner].time)-delta
  if float(seams[owner].time)<=0 or not combat.adventure.alive(str(owner)):seams.erase(owner)
 for i in range(flashes.size()-1,-1,-1):
  flashes[i].time=float(flashes[i].time)-delta
  if float(flashes[i].time)<=0:flashes.remove_at(i)
 for i in range(shots.size()-1,-1,-1):
  var s:Dictionary=shots[i];var owner:=str(s.owner)
  if not combat.adventure.alive(owner):shots.remove_at(i);continue
  var start:Vector2=combat.vec(s.pos);var aim:Vector2=combat.vec(s.aim);var travel:=minf(510*delta,float(s.left));var end:Vector2=combat.v75.clip(start,aim,travel)
  if combat.v56.catch_shot(start,end,owner,float(s.damage),"#b9e8e1",true,{"stolen_visual":"dart"}):shots.remove_at(i);continue
  var blocked:=start.distance_to(end)<travel-.5;var nearest:=INF;var victim:=""
  for key in combat.hostile(owner):
   var target:Dictionary=combat.actor(key)
   if target.is_empty() or not bool(target.alive):continue
   var q:=Geometry2D.get_closest_point_to_segment(target.pos,start,end)
   if q.distance_to(target.pos)<23 and q.distance_to(start)<nearest and combat.path_clear(start,target.pos):nearest=q.distance_to(start);victim=key
  if not victim.is_empty():hit(owner,victim,float(s.damage),str(s.element));blocked=true
  s.left=float(s.left)-travel;s.pos=combat.point_array(end)
  if blocked or float(s.left)<=.01:
   if bool(s.split) and not blocked:
    for side in [-1,1]:shot(owner,end,aim.orthogonal()*side,float(s.damage)*.65,"time",160)
    flash(end,28,"time")
   shots.remove_at(i)
 for i in range(zones.size()-1,-1,-1):
  var z:Dictionary=zones[i];var owner:=str(z.owner);z.time=float(z.time)-delta;z.tick=float(z.tick)+delta;z.angle=float(z.angle)+delta*2
  if float(z.time)<=0 or not combat.adventure.alive(owner):zones.remove_at(i);continue
  if z.has("drift"):
   var origin:Vector2=combat.vec(z.pos);var drift:Vector2=combat.vec(z.drift)
   z.pos=combat.point_array(combat.v75.clip(origin,drift,drift.length()*delta))
  if float(z.tick)<float(z.interval):continue
  z.tick=0;var p:Vector2=combat.vec(z.pos);var r:=float(z.radius);var element:=str(z.element)
  if z.has("chords"):
   for key in combat.hostile(owner):
    var target:Dictionary=combat.actor(key)
    if target.is_empty() or not bool(target.alive):continue
    for start in z.chords:
     var origin:Vector2=combat.vec(start)
     if Geometry2D.get_closest_point_to_segment(target.pos,origin,p).distance_to(target.pos)<27 and combat.path_clear(origin,target.pos):hit(owner,key,float(z.damage),element);break
  else:area(owner,p,r,float(z.damage),element)
  if element in ["thread","time"]:
   for key in combat.hostile(owner):
    var target:Dictionary=combat.actor(key)
    if not target.is_empty() and p.distance_to(target.pos)<r and combat.path_clear(p,target.pos):combat.apply_status(key,"slow",1.2,owner,.6)
  if element=="water" and combat.passive(owner,"sluice_shelter"):
   for ally in combat.adventure.points():
    if combat.v75.friendly(owner,str(ally)) and p.distance_to(combat.owner_pos(str(ally)))<r:combat.apply_status(combat.player_key(str(ally)),"guard",1.2,owner,.08)
  if element=="volt" and combat.passive(owner,"conductors_step") and p.distance_to(combat.owner_pos(owner))<r:combat.apply_status(combat.player_key(owner),"tailwind",1.2,owner)
  # One overlap bonus per water zone per tick; never multiply by stacked relays.
  if element=="water":
   for other in zones:
    if str(other.element)=="volt" and str(other.owner)!=owner and combat.v75.friendly(owner,str(other.owner)) and p.distance_to(combat.vec(other.pos))<r+float(other.radius):
     var center:=p.lerp(combat.vec(other.pos),.5);area(owner,center,70,5,"water");flash(center,70,"volt");break
func snapshot()->Dictionary:return {"echoes":echoes,"shots":shots,"zones":zones,"flashes":flashes,"marks":marks,"seams":seams,"clock":clock}
func receive(d:Dictionary)->void:
 echoes=d.get("echoes",[]);shots=d.get("shots",[]);zones=d.get("zones",[]);flashes=d.get("flashes",[]);marks=d.get("marks",{});seams=d.get("seams",{});clock=float(d.get("clock",clock))
func draw_on(c:Node2D,camera:Vector2)->void:
 draw_aim(c,camera)
 for e in echoes:
  var p:Vector2=combat.vec(e.pos)-camera;var tint:=Color(.75,.65,1,float(e.time)*.7)
  c.draw_colored_polygon(PackedVector2Array([p+Vector2(-13,-15),p+Vector2(13,-15),p+Vector2(24,22),p+Vector2(0,14),p+Vector2(-24,22)]),tint)
  c.draw_circle(p+Vector2(0,-24),9,tint);c.draw_arc(p,30,-PI,0,16,tint,2,true)
 for owner in seams:
  var seam:Dictionary=seams[owner];c.draw_dashed_line(combat.vec(seam.from)-camera,combat.vec(seam.to)-camera,Color(.95,.65,.8,.55),2,9,true)
 for key in marks:
  var target:Dictionary=combat.actor(str(key))
  if not target.is_empty():c.draw_arc(target.pos-camera+Vector2(0,-35),7,0,TAU,12,color(str(marks[key].element)),2,true)
 for s in shots:
  var p:Vector2=combat.vec(s.pos)-camera;var aim:Vector2=combat.vec(s.aim);var tint:=color(str(s.element))
  c.draw_line(p-aim*24,p,tint.darkened(.3),6,true);c.draw_circle(p,5,tint);c.draw_line(p-aim*10,p+aim*4,Color.WHITE,2,true)
 for z in zones:
  var p:Vector2=combat.vec(z.pos)-camera;var r:=float(z.radius);var tint:=color(str(z.element));tint.a=.14
  if z.has("chords"):
   for origin in z.chords:
    var a:Vector2=combat.vec(origin)-camera
    c.draw_circle(a,12,Color(.9,.8,.4,.25));c.draw_dashed_line(a,p,Color(1,.8,.4,.4),2,10,true)
    if float(z.tick)>=0 and float(z.tick)<.25:c.draw_line(a,p,Color(1,.95,.7,.8),5,true)
   c.draw_arc(p,18,0,TAU,16,Color("#ffdf91"),2,true)
   continue
  c.draw_circle(p,r,tint);tint.a=.75;c.draw_arc(p,r,0,TAU,40,tint,2,true)
  for n in 4:
   var q:=p+Vector2.from_angle(float(z.angle)+n*TAU/4)*r*.7
   if str(z.element)=="water":c.draw_arc(q,r*.23,clock,clock+PI,14,tint,3,true)
   elif str(z.element)=="volt":c.draw_polyline(PackedVector2Array([q,q+Vector2(-9,12),q+Vector2(7,16),q+Vector2(-3,30)]),tint,2,true)
   else:c.draw_line(q,p+Vector2.from_angle(float(z.angle)+(n+1)*TAU/4)*r*.7,tint,2,true)
 for e in flashes:
  var tint:=color(str(e.element));tint.a=float(e.time)/.45
  c.draw_arc(combat.vec(e.pos)-camera,float(e.radius)*(1-float(e.time)/.5),0,TAU,26,tint,3,true)
func draw_aim(c:Node2D,camera:Vector2)->void:
 var g:Node=combat.adventure.game;var owner:String=str(g.my_id) if combat.adventure.arcade else "solo"
 if combat.adventure.arcade:
  if not g.started or not g.shop_open.is_empty():return
 elif g.mode!="run" or not g.menu.is_empty():return
 var id:String=combat.v78.hero(owner)
 if id not in ["regent","tidewright","cantor"] or not combat.adventure.alive(owner):return
 var ability:="primary" if id=="regent" else "secondary"
 var stats:Dictionary=combat.effective_stats(owner,ability,g.characters[id][ability])
 var origin:Vector2=combat.owner_pos(owner);var raw:Vector2=origin+g.mobile.aim*float(stats.range) if g.mobile.enabled else g.media_mouse_world()
 var offset:=raw-origin;var aim:=offset.normalized();var end:Vector2=combat.v75.clip(origin,aim,minf(offset.length(),float(stats.range)))-camera
 if id=="regent":
  c.draw_dashed_line(origin-camera,end,Color(.7,.65,1,.22),1,12,true)
  c.draw_line(end-aim.orthogonal()*28,end+aim.orthogonal()*28,Color(.8,.75,1,.5),2,true)
  c.draw_arc(end,7,0,TAU,12,Color(.8,.75,1,.6),1,true)
 else:c.draw_arc(end,float(stats.get("radius",95)),0,TAU,28,Color(.45,.85,.85,.25) if id=="tidewright" else Color(1,.83,.4,.25),1,true)
