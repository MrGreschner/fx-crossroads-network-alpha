extends RefCounted
var manager:Node
var conclave=preload("res://scripts/roaming_conclave.gd").new()
var events=[]
var warnings=[]
var clock=0.0
var boss_timer=6.0
var modifier=0
var events_planned=false
func start()->void:
 conclave.setup(manager.game,false,int(manager.ticket().seed),int(manager.ticket().tier))
 events.clear();warnings.clear();clock=0;boss_timer=6;modifier=posmod(int(manager.ticket().seed),3)
 events_planned=false;plan_events()
 scale_foes()
func plan_events()->void:
 if events_planned or manager.game.enemies.is_empty():return
 events_planned=true
 var g=manager.game;var original=g.enemies.duplicate();var used=[]
 for n in 2:
  if original.is_empty():break
  var candidate=original[mini(original.size()-1,int(original.size()*(.35+n*.35)))].pos
  if candidate.distance_to(g.position_in_world)<350:continue
  if used.size()>0 and candidate.distance_to(used[0])<300:continue
  used.append(candidate);events.append({"at":candidate,"type":posmod(int(manager.ticket().seed)+n,3),"state":"waiting","progress":0.0,"spawned":false,"id":n})
func scale_foes()->void:
 var tier=int(manager.ticket().tier)
 for foe in manager.game.enemies:
  if foe.get("waylight_scaled",false):continue
  var factor=[1.25,1.6,2.0][tier-1]+(.10 if modifier==2 else 0)
  foe.hp=float(foe.hp)*factor;foe.max_hp=float(foe.max_hp)*factor;foe["waylight_scaled"]=true
func completed()->int:
 var total=0
 for e in events:
  if e.state=="complete":total+=1
 return total
func event_name(e:Dictionary)->String:return ["Hunt the charged pack","Defend the Waylight spring","Break the guardian ritual"][int(e.type)]
func spawn_event(e:Dictionary)->void:
 e.spawned=true;e.state="active";var g=manager.game
 for n in range(3 if int(e.type)!=2 else 4):
  var point:Vector2=e.at+Vector2.from_angle(n*TAU/4)*100
  if not g.can_stand_at(point):point=e.at
  var foe=manager.spawn("bramble" if manager.realm=="grove" else "imp" if manager.realm=="quarry" else "frostling",point,1.3,false)
  foe["waylight_event"]=int(e.id);foe["summoned"]=true
  g.enemies.append(foe)
 g.message=event_name(e)+" • optional encounter";g.message_time=4
func step(delta:float)->void:
 plan_events();conclave.step(delta)
 clock+=delta;boss_timer-=delta;var g=manager.game;scale_foes()
 for e in events:
  var distance=g.position_in_world.distance_to(e.at)
  if e.state=="waiting" and distance<350:spawn_event(e)
  if e.state!="active":continue
  var remaining=0
  for foe in g.enemies:
   if int(foe.get("waylight_event",-1))==int(e.id):remaining+=1
  if int(e.type)==1:
   if distance<160 and remaining==0:e.progress=float(e.progress)+delta
   if remaining==0 and float(e.progress)<12:g.hint="Hold the spring • %.0f / 12s" % float(e.progress)
  if remaining==0 and (int(e.type)!=1 or float(e.progress)>=12):
   e.state="complete";g.message="Optional encounter complete • +1 Waydust on successful extraction.";g.message_time=5;manager.checkpoint()
 if boss_timer<=0:
  boss_timer=9
  var boss=false
  for foe in g.enemies:
   if bool(foe.boss) and foe.pos.distance_to(g.position_in_world)<650:boss=true;break
  if boss or (modifier==0 and not g.enemies.is_empty()):warnings.append({"at":g.position_in_world,"time":1.2,"radius":72.0})
 for i in range(warnings.size()-1,-1,-1):
  var warning=warnings[i];warning.time-=delta
  if warning.time<=0:
   warnings.remove_at(i)
   if g.position_in_world.distance_to(warning.at)<float(warning.radius):g.take_player_damage(10+int(manager.ticket().tier)*3,"",{"name":"Overcharge surge"})
   if g.menu!="":return
 if modifier==1:
  for foe in g.enemies:foe.attack_timer=maxf(0,float(foe.get("attack_timer",0))-delta*.12)
func snapshot()->Dictionary:return {"events_planned":events_planned,"conclave":conclave.state,"events":events,"clock":clock,"boss_timer":boss_timer,"modifier":modifier}
func restore(v:Dictionary)->void:
 events_planned=bool(v.get("events_planned",true));conclave.restore(v.get("conclave",conclave.state));events=v.get("events",[]);clock=float(v.get("clock",0));boss_timer=maxf(3,float(v.get("boss_timer",6)));modifier=clampi(int(v.get("modifier",0)),0,2);warnings.clear()
func description()->String:return ["Unstable ground • dodge the marked energy surges","Quickened foes • attacks recover 12% faster","Brittle aegis • enemies gain 10% additional base health"][modifier]
func draw_on(g:Node2D,camera:Vector2)->void:
 conclave.draw_on(g,camera)
 for foe in g.enemies:
  var point:Vector2=foe.pos-camera
  if not Rect2(Vector2.ZERO,g.VIEW).grow(50).has_point(point):continue
  g.draw_arc(point+Vector2(0,15),24 if not foe.boss else 46,0,TAU,24,Color(.76,.60,.93,.45),2,true)
  if foe.boss:
   for n in 3:g.draw_circle(point+Vector2.from_angle(clock*.6+n*TAU/3)*55,3,Color("#d8b4f2"))
 for e in events:
  var p:Vector2=e.at-camera
  if not Rect2(Vector2.ZERO,g.VIEW).grow(100).has_point(p):continue
  var tint=Color("#9ae0bf") if e.state=="complete" else Color("#cca4e9")
  g.draw_arc(p,65,0,TAU,32,Color(tint,.65),3,true)
  for n in 5:
   var q=p+Vector2.from_angle(n*TAU/5)*65;g.draw_colored_polygon(PackedVector2Array([q-Vector2(0,13),q+Vector2(7,0),q+Vector2(0,9),q-Vector2(7,0)]),tint)
  g.draw_string(g.font,p+Vector2(-105,95),"COMPLETE" if e.state=="complete" else event_name(e),HORIZONTAL_ALIGNMENT_LEFT,-1,14,tint)
 for warning in warnings:
  var p:Vector2=warning.at-camera
  g.draw_circle(p,warning.radius,Color(1,.5,.25,.13));g.draw_arc(p,warning.radius,0,TAU,40,Color("#ffd397"),3,true)
  g.draw_arc(p,warning.radius*.7,-PI*.5,-PI*.5+TAU*(1-warning.time/1.2),32,Color("#ff906d"),4,true)
