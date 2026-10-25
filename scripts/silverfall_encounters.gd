extends RefCounted
const TYPES=["mistglass_skater","undertow_weaver","sluicewarden"]
var world:Node
var warnings:Array=[]
var splashes:Array=[]
func enabled()->bool:return is_instance_valid(world) and world.active and str(world.data.get("id",""))=="silverfall"
func reset()->void:warnings.clear();splashes.clear()
func c()->Node:return world.adventure.combat
func foe(uid:int)->Dictionary:
 for e in world.adventure.foes():
  if int(e.uid)==uid and float(e.hp)>0:return e
 return {}
func warn(e:Dictionary,p:Vector2,radius:float,delay:float,kind:String)->void:
 if warnings.size()<36:warnings.append({"uid":int(e.uid),"pos":world.a(p),"radius":radius,"left":delay,"total":delay,"kind":kind});e.melee_warning=delay
func fire(e:Dictionary,target:Vector2,count:int,slate:bool=false)->void:
 for n in count:
  c().launch_projectile("enemy",e.pos,(target-e.pos).normalized().rotated((n-(count-1)*.5)*.21),{"name":"Rebounding slate" if slate else "Skipping mistglass","credit":preload("res://scripts/defeat_credit.gd").resolve(world.adventure.game,c().npc_key(e),"Rebounding slate" if slate else "Skipping mistglass"),"silver_visual":"slate" if slate else "disc","range":880 if slate else 730,"speed":295 if slate else 310,"projectile_radius":12,"wall_bounces":1,"slow_duration":.8,"slow_factor":.8,"color":"#b5dcd1"},20 if slate else 15,"bankshot")
func step_enemy(e:Dictionary,dt:float)->bool:
 if not enabled() or str(e.type) not in TYPES:return false
 if not world.adventure.authoritative():return true
 e.melee_warning=maxf(0,float(e.get("melee_warning",0))-dt)
 if c().stunned(c().npc_key(e)):
  warnings=warnings.filter(func(w):return int(w.uid)!=int(e.uid));return true
 var target:Vector2=world.target_for(e);var distance:float=e.pos.distance_to(target)
 if distance>1000:return true
 var waiting=false
 for w in warnings:
  if int(w.uid)==int(e.uid):waiting=true;break
 if not waiting:
  var speed=float(world.defs()[e.type].speed)
  e.pos=world.advance(e.pos,world.direction(e,target,true)*speed*c().speed_factor(c().npc_key(e))*dt)
 e.skill_timer=float(e.get("skill_timer",1.5))-dt
 if float(e.skill_timer)>0 or waiting or not c().path_clear(e.pos,target):return true
 var turn=int(e.get("sf_turn",0));e.sf_turn=turn+1
 match str(e.type):
  "mistglass_skater":e.skill_timer=2.9;warn(e,target,28,.55,"disc")
  "undertow_weaver":
   e.skill_timer=4.3
   var side:Vector2=(target-e.pos).normalized().orthogonal()
   for n in 3:warn(e,target+side*(n-1)*115,63,.9+n*.22,"upwell")
  "sluicewarden":
   e.skill_timer=3.7
   if distance<190 or turn%3==2:warn(e,e.pos,180,1.1,"slam")
   else:warn(e,target,35,.8,"slate")
 return true
func boss_skill(e:Dictionary,target:Vector2,turn:int)->void:
 match turn%4:
  0:
   for n in 3:world.warning(e,target+Vector2((n-1)*145,0),"water",83,27,.95+n*.2)
  1:
   for n in 12:world.shoot(e,e.pos+Vector2.from_angle(TAU*n/12),1,"weaving")
  2:world.warning(e,world.advance(e.pos,(target-e.pos).normalized()*370),"dash",65,32,1.1)
  3:
   for n in 4:world.warning(e,target+Vector2.from_angle(TAU*n/4)*125,"water",65,24,1.1+n*.12)
func step(dt:float)->void:
 if not enabled() or not world.adventure.authoritative():return
 for n in range(splashes.size()-1,-1,-1):
  splashes[n].left-=dt
  if float(splashes[n].left)<=0:splashes.remove_at(n)
 for n in range(warnings.size()-1,-1,-1):
  var w:Dictionary=warnings[n];w.left-=dt;var e=foe(int(w.uid))
  if e.is_empty() or c().stunned(c().npc_key(e)):warnings.remove_at(n);continue
  if float(w.left)>0:continue
  warnings.remove_at(n);var p=world.v(w.pos);var kind=str(w.kind)
  if kind in ["disc","slate"]:fire(e,p,5 if kind=="slate" else 2,kind=="slate");continue
  if splashes.size()<16:splashes.append({"pos":w.pos,"radius":w.radius,"left":.5})
  for id in world.adventure.points():
   var point:Vector2=world.adventure.points()[id]
   if not world.adventure.alive(str(id)) or p.distance_to(point)>float(w.radius) or not c().path_clear(p,point):continue
   var immune=Time.get_ticks_msec()<int(world.adventure.game.invincible_until.get(id,0)) if world.adventure.arcade else world.adventure.game.invulnerable_time>0
   if immune:continue
   world.hurt_player(str(id),24 if kind=="slam" else 18,c().npc_key(e))
   c().apply_status(c().player_key(str(id)),"slow",1.25,"enemy",.65)
   c().knock(c().player_key(str(id)),(point-e.pos).normalized() if kind=="slam" else (e.pos-point).normalized(),85 if kind=="slam" else 65)
func snapshot()->Dictionary:return {"warnings":warnings,"splashes":splashes}
func receive(s:Dictionary)->void:warnings=s.get("warnings",[]);splashes=s.get("splashes",[])
func draw(ca:Node2D,camera:Vector2)->void:
 if not enabled():return
 for w in warnings:
  var p=world.v(w.pos)-camera
  if str(w.kind) in ["disc","slate"]:
   var e=foe(int(w.uid))
   if not e.is_empty():preload("res://scripts/combat_cues.gd").corridor(ca,e.pos-camera,p,18)
  else:preload("res://scripts/combat_cues.gd").danger(ca,p,float(w.radius),float(w.left),float(w.total),Color("#abe6db"))
 for splash in splashes:
  var p=world.v(splash.pos)-camera;var progress=1-float(splash.left)/.5;var radius=float(splash.radius)
  if not preload("res://scripts/combat_cues.gd").visible(ca,p,radius):continue
  ca.draw_arc(p,radius*(.4+.6*progress),0,TAU,28,Color(.68,.92,.86,1-progress),5,true)
  for n in 7:
   var d=Vector2.from_angle(TAU*n/7);var tip=p+d*radius*progress-Vector2(0,sin(progress*PI)*25)
   ca.draw_line(tip-d*7,tip,Color(.8,.97,.91,1-progress),4,true)
