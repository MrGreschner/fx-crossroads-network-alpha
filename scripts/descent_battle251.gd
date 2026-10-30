extends RefCounted
## Host-authoritative depth mechanics; all geometry and warnings use world coordinates.
var _journey:WeakRef
var d:RefCounted:
 get:return _journey.get_ref() if _journey!=null else null
 set(value):_journey=weakref(value)
var game:Node
var events:Array=[]
var bolts:Array=[]
var suspended:Dictionary={}
var minions:Array=[]
var return_left=-1.0
var return_at:Vector2=Vector2.ZERO
var motion:Dictionary={}
var previous:Dictionary={}
var call:Dictionary={}
const NEW=["ds_wickcaller","ds_gloamrunner","ds_craglobber","ds_riftskulk","ds_mirebound"]
const LOCALS=["shard_lances","echo_rings","pursuit_orbs"]
const FINAL=["shard_lances","echo_rings","pursuit_orbs","rift_mines","seismic_cross","crown_grid","shard_rain"]
const LAVA=["magma_lances","cinder_orbs","eruption_mines","basalt_cross","magma_tide","eruption_sweep"]
func reset()->void:
 events.clear();bolts.clear();suspended.clear();minions.clear();call.clear();motion.clear();previous.clear();return_left=-1
func full(e:Dictionary)->bool:return str(d.Book.profile(str(e.type)).get("rank","enemy")) in ["boss","beyond"]
static func stages(floor:int)->int:return floor/20 if floor in [20,40,60,80,100] else 0
func threshold(e:Dictionary)->float:
 var n=stages(game.floor_number);var done=int(e.get("intermissions",0))
 return float(e.max_hp)*(1-float(done+1)/(n+1)) if done<n else 0.0
func damage(e:Dictionary,amount:float)->float:
 if not full(e):return amount
 if bool(e.get("phase_pending",false)) or float(e.get("return_ward",0))>0:return 0.0
 var limit=threshold(e)
 if limit>0 and float(e.hp)-amount<=limit:
  e.phase_pending=true
  return maxf(0,float(e.hp)-limit)
 return amount
func clear_attacks()->void:
 events.clear();bolts.clear();d.warnings.clear();d.hazards.clear();d.wheels.clear();game.adventure.combat.projectiles.clear();game.missiles.clear()
func intermission(e:Dictionary)->void:
 suspended=e.duplicate(true);suspended.intermissions=int(e.get("intermissions",0))+1;suspended.phase_pending=false;suspended.action="";suspended.dash_left=0
 return_at=d.safe(game.FIELD.size*.5+Vector2(0,240));return_left=-1;clear_attacks()
 game.opponents.erase(e);minions.clear()
 var count=3+mini(4,game.floor_number/20)+mini(2,game.positions.size()-1)
 var pool=["ds_nibbler","ds_glimmerwing","ds_larva","ds_spider"] if game.floor_number<50 else ["ds_gloamrunner","ds_craglobber","ds_riftskulk","ds_mirebound"]
 for n in count:
  var angle=n*TAU/count;var at=d.safe(game.FIELD.size*.5+Vector2(cos(angle)*700,sin(angle)*470));var mob=d.spawn(pool[n%pool.size()],at);mob.phase_minion=true;minions.append(int(mob.uid))
 game.status_label.text="GUARDIAN VANISHED • Defeat the summoned guard • Phase %d / %d"%[suspended.intermissions,stages(game.floor_number)]
func active_count()->int:return game.opponents.size()+(1 if not suspended.is_empty() else 0)
func event(kind:String,shapes:Array,damage:float,owner:int=0,delay:float=2.1,life:float=.6)->void:
 if events.size()>=12:return
 events.append({"kind":kind,"shapes":shapes,"damage":damage,"owner":owner,"left":delay,"warning":delay,"life":life,"hits":[]})
static func circle(at:Vector2,radius:float)->Dictionary:return {"shape":"circle","pos":[at.x,at.y],"radius":radius}
static func rect(r:Rect2)->Dictionary:return {"shape":"rect","rect":[r.position.x,r.position.y,r.size.x,r.size.y]}
static func ring(at:Vector2,inner:float,outer:float)->Dictionary:return {"shape":"ring","pos":[at.x,at.y],"inner":inner,"radius":outer}
static func contains(shape:Dictionary,p:Vector2)->bool:
 if str(shape.shape)=="rect":return Rect2(shape.rect[0],shape.rect[1],shape.rect[2],shape.rect[3]).grow(12).has_point(p)
 var dist=p.distance_to(Vector2(shape.pos[0],shape.pos[1]));return dist<float(shape.radius)+12 and (str(shape.shape)!="ring" or dist>float(shape.inner)-12)
func arena(e:Dictionary,index:int)->void:
 var shapes:Array=[];var f:Rect2=game.FIELD;var damage=float(d.Book.profile(e.type).damage)*1.35
 var pattern=posmod(index+game.floor_number/10,5)
 match pattern:
  0:
   for x in range(120,int(f.size.x)-100,480):shapes.append(rect(Rect2(x+posmod(index,2)*240,70,170,f.size.y-140)))
  1:
   for y in range(120,int(f.size.y)-100,420):shapes.append(rect(Rect2(70,y+posmod(index,2)*210,f.size.x-140,150)))
  2:
   shapes=[rect(Rect2(f.size.x*.5-85,70,170,f.size.y-140)),rect(Rect2(70,f.size.y*.5-75,f.size.x-140,150))]
  3:
   for x in [420,1200,1980]:
    for y in [340,850,1360]:shapes.append(circle(Vector2(x,y),140+mini(30,game.floor_number/4)))
  4:
   shapes=[rect(Rect2(70,70,f.size.x-140,155)),rect(Rect2(70,f.size.y-225,f.size.x-140,155)),rect(Rect2(70,225,155,f.size.y-450)),rect(Rect2(f.size.x-225,225,155,f.size.y-450))]
 var names=["FAULT LANES • Leave the marked strips","SHELF COLLAPSE • Find an open lane","CAVERN CROSS • Move off the seams","CEILING FALL • Dodge the marked circles","RIM COLLAPSE • Leave the outer rim"]
 event(names[pattern],shapes,damage,int(e.uid),maxf(1.65,2.5-game.floor_number*.005),.65)
 game.status_label.text=names[pattern]
func predict(id:String,lead:float)->Vector2:
 return d.safe(game.positions.get(id,game.FIELD.size*.5)+(motion.get(id,Vector2.ZERO) as Vector2).limit_length(330)*lead)
func shoot(e:Dictionary,at:Vector2,dir:Vector2,damage:float,kind:String,target:String="")->void:
 if bolts.size()>=36:return
 bolts.append({"pos":d.pack(at),"dir":d.pack(dir.normalized()),"speed":300.0 if kind in ["homing","cinder"] else 370.0 if kind=="boulder" else 480.0,"left":4.2 if kind in ["homing","cinder"] else 3.0,"age":0.0,"kind":kind,"damage":damage,"target":target,"boss":full(e),"owner":int(e.uid),"radius":18 if kind=="boulder" else 9})
func execute(e:Dictionary,style:String,aim_at:Vector2,target:String)->bool:
 var spec=d.Book.profile(str(e.type));var damage=float(spec.damage);var at:Vector2=e.pos
 if style in ["shard_lances","magma_lances"]:
  for n in 5:shoot(e,at,(aim_at-at).normalized().rotated((n-2)*.16),damage,"shard",target)
 elif style=="echo_rings":
  event("ECHO RINGS",[ring(at,120,205)],damage,int(e.uid),1.25)
  event("OUTER ECHO",[ring(at,310,395)],damage,int(e.uid),2.35)
 elif style in ["pursuit_orbs","cinder_orbs","homing"]:
  for n in (1 if style=="homing" else 3):shoot(e,at,(aim_at-at).normalized().rotated((n-1)*.55),damage,"cinder" if style=="cinder_orbs" else "homing",target)
 elif style in ["rift_mines","eruption_mines","shard_rain"]:
  var shapes:Array=[]
  for id in game.positions:
   if int(game.health.get(id,0))>0:shapes.append(circle(predict(str(id),.45),100))
  for n in (5 if style=="shard_rain" else 3):shapes.append(circle(d.safe(game.FIELD.size*.5+Vector2(cos(n*2.4+e.phase)*700,sin(n*2.4+e.phase)*480)),110))
  event("CEILING MARKS • Move before impact",shapes,damage*1.2,int(e.uid),1.7)
 elif style in ["seismic_cross","basalt_cross"]:
  event("BREAKING CROSS",[rect(Rect2(aim_at.x-70,70,140,game.FIELD.size.y-140)),rect(Rect2(70,aim_at.y-70,game.FIELD.size.x-140,140))],damage*1.3,int(e.uid),1.8)
 elif style in ["crown_grid","magma_tide","eruption_sweep"]:
  for n in 3:
   var shapes:Array=[]
   for lane in 5:
    if posmod(lane+n,2)==0:shapes.append(rect(Rect2(100+lane*440,70,180,game.FIELD.size.y-140)))
   event("SHIFTING FAULTS • Follow the open lanes",shapes,damage*1.3,int(e.uid),2+n*1.3,.5)
 elif style=="boulder":shoot(e,at,(aim_at-at).normalized(),damage,"boulder",target)
 elif style=="snipe":shoot(e,at,(aim_at-at).normalized(),damage,"shard",target)
 elif style=="leap":
  e.pos=d.safe(aim_at)
  event("LEAP LANDING",[circle(e.pos,95)],damage,int(e.uid),.12,.35)
  game._emit_effect({"pos":e.pos,"radius":95,"time":.4,"color":"#c6b1d0"})
 else:return false
 return true
func remove_owner(uid:int)->void:
 events=events.filter(func(x):return int(x.owner)!=uid);bolts=bolts.filter(func(x):return int(x.owner)!=uid)
 if int(call.get("owner",0))==uid:cancel_call("Lantern ritual broken")
func cancel_call(reason:String)->void:
 if not call.is_empty():
  d.interact_at.summon_lock=d.clock+12;game.status_label.text=reason
 call.clear()
func summoner(e:Dictionary,dt:float)->bool:
 if int(d.lamp.get("thief",0))==int(e.uid):return false
 e.moving=0;e.attack_timer=float(e.attack_timer)-dt
 if int(call.get("owner",0))==int(e.uid):return true
 if not call.is_empty() or e.attack_timer>0 or d.clock<float(d.interact_at.get("summon_lock",0)) or d.clock<float(d.interact_at.get("protection",0)):return true
 var holder=str(d.lamp.get("holder",""));var distance=(e.pos as Vector2).distance_to(d.lamp_pos())
 if holder.is_empty() or distance<220 or distance>1250 or not d.segment_clear(e.pos,d.lamp_pos()):e.attack_timer=1;return true
 call={"owner":int(e.uid),"holder":holder,"left":2.8,"total":2.8,"phase":"channel","from":d.pack(d.lamp_pos()),"pos":d.pack(d.lamp_pos())};e.attack_timer=16
 game.status_label.text="LANTERN RITUAL • Hit or stun the Wickcaller, break sight, or place the lantern (E)!"
 return true
func step_call(dt:float)->void:
 if call.is_empty():return
 var enemy:Dictionary={}
 for e in game.opponents:
  if int(e.uid)==int(call.owner):enemy=e;break
 if enemy.is_empty():cancel_call("Lantern ritual broken");return
 if str(call.phase)=="channel":
  if float(enemy.hurt)>0 or game.adventure.combat.stunned(game.adventure.combat.npc_key(enemy)) or str(d.lamp.get("holder",""))!=str(call.holder) or not d.segment_clear(enemy.pos,d.lamp_pos()) or (enemy.pos as Vector2).distance_to(d.lamp_pos())>1250:
   cancel_call("Lantern ritual interrupted");return
  call.pos=d.pack(d.lamp_pos());call.left=float(call.left)-dt
  if float(call.left)<=0:
   call.phase="travel";call.pos=d.pack(d.lamp_pos());call.left=2.2;d.lamp.holder="";d.lamp.pos=call.pos;d.interact_at.protection=d.clock+.4
 else:
  var before=d.point(call.pos);var after=before.move_toward(enemy.pos,560*dt);call.pos=d.pack(after);d.lamp.pos=call.pos;call.left=float(call.left)-dt
  # Anyone can intercept a travelling lantern. The normal E pickup remains authoritative.
  if not str(d.lamp.get("holder","")).is_empty():cancel_call("Lantern intercepted!");return
  if after.distance_to(enemy.pos)<28:
   d.lamp.thief=int(enemy.uid);enemy.erase("lantern_retreat");cancel_call("Wickcaller stole the lantern • Defeat it to recover it")
  elif call.left<=0:cancel_call("The lantern fell short • E to retrieve it")
func edge_anchor(e:Dictionary)->Vector2:
 var slot=posmod(int(e.get("edge_slot",e.uid)),8);var size:Vector2=game.FIELD.size
 var points=[Vector2(160,220),Vector2(size.x*.5,160),Vector2(size.x-160,220),Vector2(size.x-160,size.y*.5),Vector2(size.x-160,size.y-220),Vector2(size.x*.5,size.y-160),Vector2(160,size.y-220),Vector2(160,size.y*.5)]
 return d.safe(points[slot])
func enemy_step(e:Dictionary,target:String,goal:Vector2,dt:float)->bool:
 var kind=str(e.type);var spec=d.Book.profile(kind)
 if kind=="ds_wickcaller":return summoner(e,dt)
 if kind=="ds_riftskulk":
  e.edge_time=float(e.get("edge_time",0))+dt;e.edge_slot=int(e.get("edge_slot",posmod(int(e.uid),8)))
  if float(e.edge_time)>8:
   e.edge_time=0;e.edge_slot=posmod(int(e.edge_slot)+3,8);e.pos=edge_anchor(e);e.hidden_until=d.clock+.7;game._emit_effect({"pos":e.pos,"radius":45,"time":.5,"color":"#c4a6dc"})
  var anchor=edge_anchor(e)
  if (e.pos as Vector2).distance_to(anchor)>25:d.walk_to(e,anchor,dt,float(spec.speed))
  else:e.moving=0
  e.attack_timer=float(e.attack_timer)-dt
  if e.attack_timer<=0 and d.segment_clear(e.pos,goal):
   var tell=1.05;e.action="snipe";e.aim=d.pack(predict(target,.35));e.total=tell;e.left=tell;e.attack_timer=3.4;e.hidden_until=0
   d.warnings.append({"kind":"beam","from":d.pack(e.pos),"pos":e.aim,"left":tell,"total":tell,"owner":e.uid,"color":"#dbc0e4"})
  elif e.attack_timer<2.2:e.hidden_until=d.clock+.1
  return true
 if kind=="ds_mirebound":
  for id in game.positions:
   if int(game.health.get(id,0))>0 and (game.positions[id] as Vector2).distance_to(e.pos)<175:game.adventure.combat.apply_status(game.adventure.combat.player_key(str(id)),"slow",.3,"enemy",.8)
  e.hop_timer=float(e.get("hop_timer",2.0))-dt
  if float(e.hop_timer)<=0:
   var landing=d.safe(e.pos+(predict(target,.85)-e.pos).limit_length(620));e.action="leap";e.aim=d.pack(landing);e.total=1.4;e.left=1.4;e.hop_timer=6.5
   event("MIREBOUND LEAP",[circle(landing,95)],0,int(e.uid),1.4,.01);return true
 return false
func step(dt:float)->void:
 for id in game.positions:
  var p:Vector2=game.positions[id];motion[id]=((p-(previous.get(id,p) as Vector2))/maxf(dt,.001)).limit_length(500);previous[id]=p
 step_call(dt)
 if not suspended.is_empty():
  minions=minions.filter(func(uid):return game.opponents.any(func(e):return int(e.uid)==int(uid)))
  if minions.is_empty():
   if return_left<0:return_left=1.5;game.status_label.text="GUARDIAN RETURNING • Recovering strength"
   return_left-=dt
   if return_left<=0:
    suspended.pos=return_at;suspended.hp=minf(float(suspended.max_hp),float(suspended.hp)+float(suspended.max_hp)*.06);suspended.return_ward=1.1+dt;suspended.attack_timer=2.0;suspended.arena_timer=5.0;game.opponents.append(suspended);suspended={};return_left=-1
 for e in game.opponents.duplicate():
  if not full(e):continue
  e.return_ward=maxf(0,float(e.get("return_ward",0))-dt)
  if bool(e.get("phase_pending",false)):intermission(e);break
  e.arena_timer=float(e.get("arena_timer",4.5))-dt
  if float(e.arena_timer)<=0 and events.is_empty() and str(e.action).is_empty():
   e.arena_index=int(e.get("arena_index",0))+1;arena(e,int(e.arena_index));e.arena_timer=maxf(6.8,12-game.floor_number*.04)
 step_events(dt);step_bolts(dt)
func step_events(dt:float)->void:
 for i in range(events.size()-1,-1,-1):
  var a:Dictionary=events[i];a.left=float(a.left)-dt
  if a.left>0:continue
  a.life=float(a.life)-dt
  for id in game.positions:
   if int(game.health.get(id,0))<=0 or id in a.hits:continue
   if a.shapes.any(func(s):return contains(s,game.positions[id])):
    a.hits.append(id)
    if float(a.damage)>0:d.hurt(str(id),float(a.damage),{},str(a.kind))
  if a.life<=0:events.remove_at(i)
func step_bolts(dt:float)->void:
 for i in range(bolts.size()-1,-1,-1):
  var b:Dictionary=bolts[i];b.left=float(b.left)-dt;b.age=float(b.age)+dt
  var old=d.point(b.pos);var dir=d.point(b.dir);var kind=str(b.kind)
  if kind in ["homing","cinder"] and b.age<2.4 and game.positions.has(str(b.target)) and int(game.health.get(str(b.target),0))>0:
   var goal=game.positions[str(b.target)]
   var source={"pos":old,"uid":int(b.owner),"boss":bool(b.get("boss",false))}
   goal=game.adventure.combat.fern.redirect(source,goal)
   dir=dir.rotated(clampf(dir.angle_to(goal-old),-1.15*dt,1.15*dt));b.dir=d.pack(dir)
  var next=old+dir*float(b.speed)*dt;var hit=not d.segment_clear(old,next) or not game.FIELD.grow(-45).has_point(next)
  for id in game.positions:
   if int(game.health.get(id,0))<=0:continue
   if Geometry2D.get_closest_point_to_segment(game.positions[id],old,next).distance_to(game.positions[id])<float(b.radius)+18:
    hit=true
    if kind!="boulder":d.hurt(str(id),float(b.damage),{},"Cave pursuit" if kind in ["homing","cinder"] else "Crystal lance")
    break
  if hit or b.left<=0:
   if kind=="boulder":
    for id in game.positions:
     if int(game.health.get(id,0))>0 and (game.positions[id] as Vector2).distance_to(next)<145:
      d.hurt(str(id),float(b.damage),{},"Boulder splash")
      if str(d.lamp.get("holder",""))==str(id) and d.clock>float(d.interact_at.get("protection",0)):
       d.drop_lamp(d.safe(game.positions[id]+dir*185));game.status_label.text="BOULDER IMPACT • Lantern knocked away"
    game._emit_effect({"pos":next,"radius":145,"time":.5,"color":"#c9b798"})
   bolts.remove_at(i)
  else:b.pos=d.pack(next)
func snapshot()->Dictionary:
 var hidden=suspended.duplicate(true)
 if not hidden.is_empty():hidden.pos=d.pack(hidden.pos);hidden.path=[]
 return {"events":events,"bolts":bolts,"hidden_boss":hidden,"minions":minions,"return_left":return_left,"return_at":d.pack(return_at),"call":call}
func receive(s:Dictionary)->void:
 events=s.get("events",[]);bolts=s.get("bolts",[]);suspended=s.get("hidden_boss",{});minions=s.get("minions",[]);return_left=float(s.get("return_left",-1));return_at=d.point(s.get("return_at",[1200,1100]));call=s.get("call",{})
func draw(c:Node2D,camera:Vector2)->void:
 if d==null or game==null:return
 # Keep new ranged windups legible above the room's darkness mask.
 for w in d.warnings:
  if w.kind not in ["homing","boulder","shard_lances","magma_lances","pursuit_orbs","cinder_orbs","beam"]:continue
  var start=d.point(w.from)-camera;var aim_at=d.point(w.pos)-camera;var dir=(aim_at-start).normalized();var color=Color("#ead6a4",.85)
  c.draw_line(start,start+dir*600,color,2,true)
  if w.kind in ["shard_lances","magma_lances"]:
   for angle in [-.32,-.16,.16,.32]:c.draw_line(start,start+dir.rotated(angle)*480,Color(color,.48),1,true)
  if w.kind=="boulder":c.draw_arc(aim_at,145,0,TAU,40,color,2,true)
 for a in events:
  var warning=float(a.left)>0;var fill=Color("#b67b45",.20) if warning else Color("#f2c077",.48);var edge=Color("#f5d28c") if warning else Color("#fff1cb")
  for shape in a.shapes:
   if str(shape.shape)=="rect":
    var r=Rect2(shape.rect[0],shape.rect[1],shape.rect[2],shape.rect[3]);r.position-=camera
    if not Rect2(Vector2.ZERO,game.VIEW).intersects(r):continue
    c.draw_rect(r,fill);c.draw_rect(r,edge,false,2)
    for y in range(int(r.position.y)+12,int(r.end.y),48):c.draw_line(Vector2(r.position.x,y),Vector2(r.end.x,y+18),Color(edge,.24),1,true)
   else:
    var at=d.point(shape.pos)-camera;var radius=float(shape.radius)
    if not Rect2(Vector2.ZERO,game.VIEW).grow(radius).has_point(at):continue
    if str(shape.shape)=="ring":
     var inner=float(shape.inner);c.draw_arc(at,(radius+inner)*.5,0,TAU,64,fill,radius-inner,true);c.draw_arc(at,inner,0,TAU,64,edge,2,true)
    else:c.draw_circle(at,radius,fill)
    c.draw_arc(at,radius,0,TAU,48,edge,2,true)
    if warning:c.draw_arc(at,maxf(8,radius-7),-PI*.5,-PI*.5+TAU*clampf(1-float(a.left)/float(a.warning),0,1),40,Color("#fff1cf"),3,true)
 for b in bolts:
  var at=d.point(b.pos)-camera;var dir=d.point(b.dir);var color=Color("#ccbca0") if str(b.kind)=="boulder" else Color("#f5b976") if str(b.kind)=="cinder" else Color("#b7e0e1")
  c.draw_line(at-dir*24,at,color.darkened(.35),4,true);c.draw_circle(at,float(b.radius),color);c.draw_arc(at,float(b.radius)+2,0,TAU,12,Color("#eadbb9"),1,true)
 if not call.is_empty():
  var summoner:Dictionary={}
  for e in game.opponents:
   if int(e.uid)==int(call.owner):summoner=e;break
  if not summoner.is_empty():
   var at:Vector2=summoner.pos-camera;c.draw_line(d.point(call.pos)-camera,at,Color("#e6bd8e",.8),3,true);c.draw_arc(at,48,-PI*.5,-PI*.5+TAU*clampf(1-float(call.left)/float(call.total),0,1),40,Color("#fff0b9"),3,true)
 if not suspended.is_empty() and minions.is_empty():c.draw_arc(return_at-camera,110,0,TAU,48,Color("#f0d3a2"),3,true)
