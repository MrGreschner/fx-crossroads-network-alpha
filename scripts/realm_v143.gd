extends Node
## Nine original actors, shared host/solo authority and bounded warning effects.
const TYPES=["rift_skitter","gearhorn_runner","brass_bailiff","velvet_dancer","moonlit_puppeteer","quarantine_hound","antiseptic_drone","spore_orderly","quarantine_warden"]
var adventure:Node
var warnings:Array=[]
var pools:Array=[]
var clock:=0.0
func setup()->void:warnings.clear();pools.clear();clock=0
func vec(a:Array)->Vector2:return Vector2(a[0],a[1])
func packed(p:Vector2)->Array:return [p.x,p.y]
func on_defeat(e:Dictionary)->bool:
 if str(e.get("type",""))!="quarantine_warden":return false
 adventure.announce("Isolation ward cleared! Continue east to confront the Plague Director.")
 return true
func move(e:Dictionary,direction:Vector2,speed:float,delta:float)->void:
 if direction.is_zero_approx():return
 var step:Vector2=direction.normalized()*speed*delta*adventure.combat.speed_factor(adventure.combat.npc_key(e))
 for angle in [0.0,.7,-.7,1.4,-1.4]:
  var end:Vector2=e.pos+step.rotated(angle)
  if adventure.can_stand(end) and adventure.combat.path_clear(e.pos,end):e.pos=end;return
func warn(e:Dictionary,p:Vector2,radius:float,damage:float,delay:float,style:String,end:Vector2=Vector2.ZERO)->void:
 if warnings.size()>=28:return
 var key:String=adventure.combat.npc_key(e)
 warnings.append({"pos":packed(p),"end":packed(end),"radius":radius,"damage":damage,"left":delay,"total":delay,"style":style,"source":key,"uid":int(e.uid),"credit":preload("res://scripts/defeat_credit.gd").resolve(adventure.game,key,style.replace("_"," ").capitalize())})
func step(delta:float)->void:
 clock+=delta
 if not adventure.authoritative():return
 var combat=adventure.combat
 var defs:Dictionary=adventure.game.enemy_defs if adventure.arcade else adventure.game.enemy_types
 for e in adventure.foes():
  var kind:String=str(e.type)
  if kind not in TYPES or bool(e.get("converted",false)):continue
  if kind=="quarantine_warden":e.boss=true;e.expansion_boss=true;e.hit_radius=30.0
  var key:String=combat.npc_key(e)
  if combat.stunned(key):continue
  var target:=Vector2.ZERO;var distance:=INF
  for id in adventure.points():
   if adventure.alive(str(id)) and combat.visible_owner(str(id)) and e.pos.distance_to(adventure.points()[id])<distance:target=adventure.points()[id];distance=e.pos.distance_to(target)
  if distance>850:continue
  target=combat.fern.redirect(e,target)
  var def:Dictionary=defs.get(kind,{})
  var speed:float=def.get("speed",90)
  var away:Vector2=(target-e.pos).normalized()
  var ready:float=e.get("v143_timer",1.6)
  var winding:=false
  for warning in warnings:
   if int(warning.uid)==int(e.uid):winding=true;break
  if not winding:
   if kind in ["antiseptic_drone","moonlit_puppeteer"]:move(e,combat.ranged_direction(e,target),speed,delta)
   elif kind in ["velvet_dancer","quarantine_warden"]:
    var orbit:Vector2=target+Vector2.from_angle(clock*(1.3 if kind=="velvet_dancer" else .8)+int(e.uid)%7)*165
    move(e,orbit-e.pos,speed,delta)
   elif distance>70:move(e,away,speed,delta)
  e.v143_timer=ready-delta
  if float(e.v143_timer)>0 or winding:continue
  e.v143_timer=3.0 if kind!="quarantine_warden" else 2.5
  e.v143_pose=clock+.55
  var origin:Vector2=e.pos;var amount:float=def.get("damage",12)
  match kind:
   "rift_skitter","quarantine_hound","velvet_dancer":
    var end:Vector2=origin+away*minf(230,distance+65)
    if not combat.path_clear(origin,end) or not adventure.can_stand(end):end=origin+away*minf(75,distance)
    warn(e,origin,28,amount,.7,"hound_leap" if kind=="quarantine_hound" else "dash",end)
   "gearhorn_runner":
    var end:Vector2=origin+away*minf(280,distance+55)
    if not combat.path_clear(origin,end) or not adventure.can_stand(end):end=origin
    warn(e,origin,38,amount,.95,"gear_charge",end)
   "brass_bailiff":
    warn(e,origin+away*55,75,amount,.75,"baton_sweep")
   "moonlit_puppeteer":
    for offset in [-90,90]:warn(e,target+away.orthogonal()*offset,32,amount,1.05,"ribbon",target-away*150+away.orthogonal()*offset)
   "antiseptic_drone":warn(e,target,78,amount,1.15,"disinfectant")
   "spore_orderly":
    for n in 3:warn(e,target+Vector2.from_angle(n*TAU/3)*85,53,amount,1+n*.25,"spore")
   "quarantine_warden":
    var turn:int=e.get("v143_turn",0);e.v143_turn=turn+1
    match turn%4:
     0:
      var end:Vector2=origin+away*minf(330,distance+80)
      if not combat.path_clear(origin,end) or not adventure.can_stand(end):end=origin
      warn(e,origin,48,amount+5,.9,"dash",end)
     1:
      for n in 5:combat.launch_projectile("enemy",origin,away.rotated((n-2)*.28),{"credit":preload("res://scripts/defeat_credit.gd").resolve(adventure.game,key,"Needle crossfire"),"range":650,"speed":270,"color":"#b8dda6"},12)
     2:
      for n in 3:warn(e,target+Vector2.from_angle(n*TAU/3)*100,68,16,1.1+n*.18,"disinfectant")
     3:warn(e,origin,195,20,1.2,"isolation_pulse")
 for n in range(warnings.size()-1,-1,-1):
  var w:Dictionary=warnings[n];w.left=float(w.left)-delta
  if float(w.left)>0:continue
  warnings.remove_at(n)
  var actor:Dictionary=combat.actor(str(w.source))
  if actor.is_empty() or combat.stunned(str(w.source)):continue
  var p:Vector2=vec(w.pos);var end:Vector2=vec(w.end)
  var line_attack:bool=w.style in ["dash","hound_leap","gear_charge","ribbon"] and not end.is_zero_approx()
  for key in combat.hostile("enemy"):
   var victim:Dictionary=combat.actor(str(key))
   if victim.is_empty():continue
   var near:Vector2=Geometry2D.get_closest_point_to_segment(victim.pos,p,end) if line_attack else p
   if near.distance_to(victim.pos)<float(w.radius):
    combat.damage(str(key),float(w.damage),"enemy",str(w.style),w.credit)
    if w.style in ["baton_sweep","isolation_pulse"]:combat.apply_status(str(key),"slow",1.5,"enemy",.65,w.credit)
  if w.style in ["dash","hound_leap","gear_charge"]:
   for e in adventure.foes():
    if int(e.uid)==int(w.uid) and adventure.can_stand(end) and combat.path_clear(e.pos,end):e.pos=end
  if w.style in ["disinfectant","hound_leap"] and pools.size()<12:pools.append({"pos":packed(end if w.style=="hound_leap" else p),"radius":55 if w.style=="hound_leap" else float(w.radius),"left":3.0,"tick":.6,"credit":w.credit})
  if w.style=="gear_charge":
   var aim:Vector2=(end-p).normalized()
   for angle in [-.4,0,.4]:combat.launch_projectile("enemy",end,aim.rotated(angle),{"credit":w.credit,"range":420,"speed":220,"return_distance":180,"color":"#dfbc78"},7,"echo_bolt")
 for n in range(pools.size()-1,-1,-1):
  var pool:Dictionary=pools[n];pool.left=float(pool.left)-delta;pool.tick=float(pool.tick)-delta
  if float(pool.left)<=0:pools.remove_at(n);continue
  if float(pool.tick)>0:continue
  pool.tick=.6
  for key in combat.hostile("enemy"):
   var victim:Dictionary=combat.actor(str(key))
   if not victim.is_empty() and vec(pool.pos).distance_to(victim.pos)<float(pool.radius):combat.damage(str(key),3,"enemy","Contaminated ground",pool.credit);combat.apply_status(str(key),"slow",.9,"enemy",.7,pool.credit)
func snapshot()->Dictionary:return {"warnings":warnings,"pools":pools,"clock":clock}
func receive(value:Dictionary)->void:warnings=value.get("warnings",[]);pools=value.get("pools",[]);clock=float(value.get("clock",clock))
func draw_on(c:Node2D,camera:Vector2)->void:
 if not adventure.combat.playing():return
 var visible:=Rect2(camera,c.VIEW).grow(220)
 for pool in pools:
  var p:Vector2=vec(pool.pos)
  if visible.has_point(p):c.draw_circle(p-camera,float(pool.radius),Color(.48,.7,.4,.18));c.draw_arc(p-camera,float(pool.radius),clock,clock+TAU,24,Color(.62,.82,.48,.45),2,true)
 for w in warnings:
  var p:Vector2=vec(w.pos);var end:Vector2=vec(w.end)
  if not visible.has_point(p) and not visible.has_point(end):continue
  var color:=Color("#be9ae5") if w.style in ["dash","ribbon"] else Color("#d4bc7a") if w.style in ["gear_charge","baton_sweep"] else Color("#b3d68b")
  if w.style in ["dash","hound_leap","gear_charge","ribbon"] and not end.is_zero_approx():
   c.draw_line(p-camera,end-camera,Color(color,.18),float(w.radius)*2,true);c.draw_line(p-camera,end-camera,Color(color,.7),2,true)
  else:preload("res://scripts/combat_cues.gd").danger(c,p-camera,float(w.radius),float(w.left),float(w.total),color)
