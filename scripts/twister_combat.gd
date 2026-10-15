extends Node
## Bounded weather effects. Host owns charge timing, collision and damage.
var combat:Node
var effects:Array=[]
var charges:Dictionary={}
var held:Dictionary={}
var clock:=0.0
var links:Array=[]
var shock_ready:Dictionary={}
var link_clock:float=0
const STYLES=["twister_charge","twister_stride","twister_hail","twister_sleet"]
func reset()->void:effects.clear();charges.clear();held.clear();links.clear();shock_ready.clear();link_clock=0;clock=0
func playing()->bool:return combat.playing()
func transformed(id:String)->bool:return playing() and effects.any(func(e):return e.owner==id and e.kind=="stride")
func drawn_transformed(id:String)->bool:
 var game=combat.adventure.game
 if not game.has_method("network_twister_view"):return transformed(id)
 return playing() and game.network_twister_view().effects.any(func(e):return str(e.owner)==id and str(e.kind)=="stride")
func locked(id:String)->bool:return charges.has(id) or effects.any(func(e):return e.owner==id and e.kind=="chant")
func chanting(id:String)->bool:return effects.any(func(e):return e.owner==id and e.kind=="chant")
func speed(id:String)->float:
 if effects.any(func(e):return e.owner==id and e.kind=="stride"):return 1.2
 return 1.0
func sway(id:String,input:Vector2)->Vector2:
 if not transformed(id) or input.is_zero_approx():return input
 return input.rotated(sin(Time.get_ticks_msec()/1000.0*3.4)*.24)
func holding(id:String,pressed:bool,aim:Vector2)->void:
 if not combat.adventure.authoritative():return
 held[id]=.6 if pressed else 0.0
 if charges.has(id):
  charges[id].aim=combat.point_array(aim.normalized())
  if not pressed:release(id)
func add(id:String,kind:String,p:Vector2,seconds:float,damage:float)->Dictionary:
 var e:Dictionary={"owner":id,"kind":kind,"pos":combat.point_array(p),"time":seconds,"duration":seconds,"damage":damage,"tick":0.0,"age":0.0}
 if effects.size()<96:effects.append(e)
 return e
func cast(id:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:String=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(id):return true
 if style=="twister_charge":
  if not charges.has(id):charges[id]={"age":0.0,"aim":combat.point_array(aim),"damage":amount,"stats":stats.duplicate(true)}
 elif style=="twister_stride":
  var e:Dictionary=add(id,"stride",combat.owner_pos(id),float(stats.get("duration",3)),amount);e.radius=48.0;e.tick=.5
 else:
  var e:Dictionary=add(id,"chant",combat.owner_pos(id),float(stats.get("charge_time",2)),amount);e.aim=combat.point_array(aim);e.sleet=style=="twister_sleet"
 return true
func release(id:String)->void:
 if not charges.has(id):return
 var q:Dictionary=charges[id];charges.erase(id)
 if not playing() or not combat.adventure.alive(id) or combat.stunned(combat.player_key(id)):return
 var owned:Array=effects.filter(func(e):return e.owner==id and e.kind=="funnel")
 var cap:int=int(q.stats.get("max_funnels",4))
 while owned.size()>=cap:effects.erase(owned.pop_front())
 var strength:float=clampf(float(q.age)/1.6,0,1)
 var aim:Vector2=combat.vec(q.aim)
 var e:Dictionary=add(id,"funnel",combat.owner_pos(id)+aim*24,4.2,float(q.damage)*lerpf(1,2.4,strength))
 e.aim=q.aim;e.radius=lerpf(float(q.stats.get("radius",36)),float(q.stats.get("radius",36))*1.7,strength);e.pull=strength>=.99;e.curve=randf_range(-.65,.65);e.tick=.5;e.travel=0.0;e.pull_tick=0.0;e.zap=1.2
func area(e:Dictionary,p:Vector2)->void:
 for key in combat.hostile(str(e.owner)):
  var f:Dictionary=combat.actor(key)
  if f.is_empty() or not bool(f.alive) or p.distance_to(f.pos)>float(e.radius) or not combat.path_clear(p,f.pos):continue
  combat.damage(key,float(e.damage),str(e.owner));combat.apply_status(key,"slow",.65,str(e.owner),.7)
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 for n in range(links.size()-1,-1,-1):
  links[n].time=float(links[n].time)-delta
  if links[n].time<=0:links.remove_at(n)
 for token in shock_ready.keys():
  if clock>float(shock_ready[token])+1:shock_ready.erase(token)
 for id in held.keys():held[id]=maxf(0,float(held[id])-delta)
 for id in charges.keys():
  if not playing() or not combat.adventure.alive(str(id)) or combat.stunned(combat.player_key(str(id))):charges.erase(id);continue
  charges[id].age=float(charges[id].age)+delta
  if float(held.get(id,0))<=0 or float(charges[id].age)>=6:release(str(id))
 for i in range(effects.size()-1,-1,-1):
  var e:Dictionary=effects[i];var id:String=str(e.owner)
  if not playing() or not combat.adventure.alive(id):effects.remove_at(i);continue
  e.time=float(e.time)-delta;e.age=float(e.age)+delta
  var p:Vector2=combat.vec(e.pos)
  if e.kind=="funnel":
   var aim:Vector2=combat.vec(e.aim).rotated(float(e.curve)*delta)
   var next:Vector2=p+aim*70*delta
   if combat.path_clear(p,next) and combat.adventure.can_stand(next):e.pos=combat.point_array(next);e.aim=combat.point_array(aim)
   else:e.aim=combat.point_array(aim.rotated(PI*.6));e.curve=-float(e.curve)
   p=combat.vec(e.pos)
   e.pull_tick=float(e.pull_tick)+delta
   if bool(e.pull) and float(e.pull_tick)>=.1:
    var pull_step:float=minf(.15,float(e.pull_tick));e.pull_tick=0.0
    for key in combat.hostile(id):
     var f:Dictionary=combat.actor(key)
     if f.is_empty() or not bool(f.alive) or p.distance_to(f.pos)>float(e.radius)+65 or not combat.path_clear(p,f.pos):continue
     var next_pos:Vector2=(f.pos as Vector2).move_toward(p,100*pull_step)
     if combat.adventure.can_stand(next_pos) and combat.path_clear(f.pos,next_pos):combat.knock(str(key),(p-f.pos).normalized(),minf(100*pull_step,p.distance_to(f.pos)))
  elif e.kind=="stride":
   p=combat.owner_pos(id);e.pos=combat.point_array(p)
   combat.clear_projectiles(id,p,52)
  elif e.kind=="chant" and float(e.time)<=0:
   var storm:Dictionary=add(id,"storm",p,3.6,float(e.damage));storm.aim=e.aim;storm.sleet=e.sleet;storm.next=0.0;storm.count=0
  elif e.kind=="storm":
   e.next=float(e.next)-delta
   if float(e.next)<=0 and int(e.count)<12:
    e.next=.3;e.count=int(e.count)+1
    var aim:Vector2=combat.vec(e.aim)
    var target:Vector2=p+Vector2.from_angle(randf()*TAU)*sqrt(randf())*210
    if bool(e.sleet):target=p+aim*(40+int(e.count)*21)+aim.orthogonal()*randf_range(-42,42)
    if combat.adventure.can_stand(target) and combat.path_clear(p,target):
     var ice:Dictionary=add(id,"ice",target,.7,float(e.damage));ice.radius=38.0;ice.sleet=e.sleet
  elif e.kind=="ice" and float(e.time)<=0:
   area(e,p)
   for key in combat.hostile(id):
    var f:Dictionary=combat.actor(key)
    if not f.is_empty() and bool(f.alive) and p.distance_to(f.pos)<=float(e.radius) and combat.path_clear(p,f.pos):combat.apply_status(key,"slow" if bool(e.sleet) else "stun",3 if bool(e.sleet) else .6,id,.55)
   var splash:Dictionary=add(id,"shatter",p,.35,0);splash.radius=e.radius
  if e.kind in ["funnel","stride"]:
   e.tick=float(e.tick)+delta
   if float(e.tick)>=.5:e.tick=float(e.tick)-.5;area(e,p)
  if float(e.time)<=0:effects.remove_at(i)
 lightning(delta)
func lightning(delta:float)->void:
 if not playing():links.clear();return
 link_clock-=delta
 var pulse:bool=link_clock<=0
 if pulse:link_clock=1.25
 var grouped:Dictionary={}
 for e in effects:
  if e.kind!="funnel" or not combat.adventure.alive(str(e.owner)) or not combat.passive(str(e.owner),"weather_circuit"):continue
  var owner:String=str(e.owner)
  if not grouped.has(owner):grouped[owner]=[]
  grouped[owner].append(e)
  e.zap=float(e.get("zap",1.2))-delta
  if bool(e.pull) and float(e.zap)<=0:
   e.zap=1.5
   var target:String="";var distance:float=float(e.radius)+90
   for key in combat.hostile(owner):
    var f:Dictionary=combat.actor(key)
    if not f.is_empty() and bool(f.alive) and combat.vec(e.pos).distance_to(f.pos)<distance and combat.path_clear(combat.vec(e.pos),f.pos) and clock>=float(shock_ready.get(owner+"|"+str(key),0)):
     target=str(key);distance=combat.vec(e.pos).distance_to(f.pos)
   if not target.is_empty():shock(owner,target,combat.vec(e.pos),combat.actor(target).pos,10)
 if not pulse:return
 for owner in grouped:
  var funnels:Array=grouped[owner]
  if funnels.size()<3:continue
  for i in funnels.size():
   for j in range(i+1,funnels.size()):
    var a:Vector2=combat.vec(funnels[i].pos);var b:Vector2=combat.vec(funnels[j].pos)
    if a.distance_to(b)>260 or a.distance_to(b)<15 or not combat.path_clear(a,b):continue
    bolt(a,b)
    for key in combat.hostile(str(owner)):
     var f:Dictionary=combat.actor(key)
     if not f.is_empty() and bool(f.alive) and Geometry2D.get_closest_point_to_segment(f.pos,a,b).distance_to(f.pos)<=18 and combat.path_clear(a,f.pos) and clock>=float(shock_ready.get(str(owner)+"|"+str(key),0)):
      shock(str(owner),str(key),a,b,8,false)
func bolt(a:Vector2,b:Vector2)->void:
 if links.size()<24:links.append({"start":combat.point_array(a),"end":combat.point_array(b),"time":.28})
func shock(owner:String,key:String,a:Vector2,b:Vector2,amount:float,visual:bool=true)->void:
 shock_ready[owner+"|"+key]=clock+1.0
 combat.damage(key,amount,owner);combat.apply_status(key,"stun",.35,owner)
 if visual:bolt(a,b)
func snapshot()->Dictionary:return {"effects":effects,"charges":charges,"links":links,"clock":clock}
func receive(data:Dictionary)->void:effects=data.get("effects",[]);charges=data.get("charges",{});links=data.get("links",[]);clock=float(data.get("clock",clock))
func funnel(c:Node2D,p:Vector2,r:float,age:float,tint:Color)->void:
 for n in 5:
  var radius:float=r*(.3+n*.16);var y:float=-float(n)*10
  var pts:=PackedVector2Array()
  for k in 17:
   var a:float=TAU*k/16+age*1.6+n*.5;pts.append(p+Vector2(cos(a)*radius,y+sin(a)*radius*.25))
  c.draw_polyline(pts,tint,2.5,true)
 for n in 3:
  var a:float=age*1.8+n*TAU/3;c.draw_circle(p+Vector2(cos(a)*r,-25+sin(a)*r*.3),2,Color("#d6edf1"))
func draw_on(c:Node2D,camera:Vector2)->void:
 if not playing():return
 var game=combat.adventure.game
 var view:Dictionary=game.network_twister_view() if game.has_method("network_twister_view") else {"effects":effects,"charges":charges,"links":links,"clock":clock}
 var draw_effects:Array=view.effects;var draw_charges:Dictionary=view.charges;var draw_links:Array=view.links;var draw_clock:float=view.clock
 var visible:=Rect2(camera-Vector2(260,260),c.get_viewport_rect().size+Vector2(520,520))
 for link in draw_links:
  var a:Vector2=combat.vec(link.start);var b:Vector2=combat.vec(link.end)
  if not visible.intersects(Rect2(a,b-a).abs().grow(20)):continue
  var points:=PackedVector2Array();var side:Vector2=(b-a).normalized().orthogonal()
  for n in 9:points.append(a.lerp(b,n/8.0)-camera+side*(0 if n in [0,8] else sin(n*7+draw_clock*31)*7))
  c.draw_polyline(points,Color(.45,.74,1,.8),5,true);c.draw_polyline(points,Color(.9,.97,1,.95),2,true)
 for id in draw_charges:
  var pos:Vector2=game.melee_visual_position(str(id),combat.owner_pos(str(id))) if game.has_method("melee_visual_position") else combat.owner_pos(str(id));var q:Dictionary=draw_charges[id];var power:float=clampf(float(q.age)/1.6,0,1)
  funnel(c,pos+combat.vec(q.aim)*34-camera,20+power*28,draw_clock,Color("#eed0ff"))
  c.draw_arc(pos-camera,34,-PI/2,-PI/2+TAU*maxf(.02,power),24,Color("#ffd488") if power>=.99 else Color("#b4ddfa"),3,true)
 for e in draw_effects:
  var world:Vector2=combat.vec(e.pos)
  if e.kind=="stride" and game.has_method("melee_visual_position"):world=game.melee_visual_position(str(e.owner),world)
  if not visible.has_point(world):continue
  var p:Vector2=world-camera
  match str(e.kind):
   "funnel","stride":
    c.draw_circle(p,float(e.radius),Color(.55,.77,.94,.12));funnel(c,p,float(e.radius),draw_clock,Color(.67,.86,.96,.9))
    if e.kind=="funnel" and bool(e.pull):c.draw_arc(p,float(e.radius)+65,draw_clock,draw_clock+PI*1.5,24,Color(.8,.65,1,.5),1.5,true)
   "chant":
    c.draw_arc(p,52,draw_clock,-draw_clock+TAU,32,Color("#b6dcf6"),3,true)
    for n in 6:c.draw_circle(p+Vector2.from_angle(draw_clock+n*TAU/6)*48,3,Color("#f0dbff"))
   "ice":
    c.draw_circle(p,float(e.radius),Color(.46,.7,.97,.16));c.draw_arc(p,float(e.radius),0,TAU,20,Color("#a7dffe"),2,true)
    var h:float=maxf(0,float(e.time))/.7*110
    c.draw_colored_polygon(PackedVector2Array([p+Vector2(-9,-h-19),p+Vector2(5,-h-30),p+Vector2(15,-h-16),p+Vector2(1,-h-5)]),Color("#c3efff"))
   "shatter":
    for n in 6:
     var a:float=n*TAU/6;var b:Vector2=p+Vector2.from_angle(a)*float(e.age)*90;c.draw_line(b,b+Vector2.from_angle(a)*7,Color(.67,.89,1,float(e.time)/.35),3,true)
