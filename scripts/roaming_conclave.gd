extends RefCounted
## One bounded encounter controller shared by solo and dedicated authority.
const ROLES=["Aegis • Tank","Cantor • Healer","Ravager • Melee","Prism Seer • Ranged"]
const TYPES=["bramble","warlock","imp","archer"]
const COLORS=["#c6ae7c","#92dda9","#e7a38e","#afbbf0"]
var game:Node
var coop=false
var tier=1
var state={}
var paths={}
static func appears(seed_value:int)->bool:
 var rng=RandomNumberGenerator.new();rng.seed=seed_value^817631;return rng.randf()<.12
func setup(g:Node,is_coop:bool,seed_value:int,grade:int)->void:
 game=g;coop=is_coop;tier=grade;paths.clear()
 state={"phase":"waiting" if appears(seed_value) else "absent","seed":seed_value,"anchor":[0,0],"members":[],"dead":[],"clock":0.0,"warnings":[]}
func foes()->Array:return game.opponents if coop else game.enemies
func points()->Dictionary:return game.adventure.points()
func valid_point(p:Vector2)->bool:return game._clear_path(p,p) if coop else game.can_stand_at(p)
func anchor()->Vector2:return Vector2(float(state.anchor[0]),float(state.anchor[1]))
func completed()->bool:return state.get("members",[]).size()==4 and state.get("dead",[]).size()==4
func defeated(foe:Dictionary)->void:
 var uid=int(foe.get("uid",-1))
 if uid not in state.get("members",[]) or uid in state.get("dead",[]) or foe.get("converted",false):return
 state.dead.append(uid)
 if completed():
  state.phase="complete";announce("CONCLAVE CACHE SECURED • finish the realm for +3 Waydust and a 35% bonus Conclave-forged relic roll!")
func announce(text:String)->void:game.adventure.announce(text)
func spawn_pack(at:Vector2)->void:
 state.anchor=[at.x,at.y];state.phase="active"
 for n in 4:
  var p=at+Vector2.from_angle(n*TAU/4)*90
  if not valid_point(p):p=at
  var hp=(640 if n==0 else 330 if n==1 else 420)*(1+.25*(tier-1))*(1.55 if coop else 1)
  var foe={}
  if coop:
   game.adventure.spawn(TYPES[n],p,hp,false);foe=game.opponents[-1]
  else:
   foe=game.waylight.spawn(TYPES[n],p,1,false);foe.hp=hp;foe.max_hp=hp;game.enemies.append(foe)
  foe["roaming_actor"]=true;foe["conclave_role"]=n;foe["summoned"]=true;foe["waylight_scaled"]=true;foe["conclave_timer"]=2.0+n*.65;foe["conclave_melee"]=1.0
  state.members.append(int(foe.uid))
 announce("RARE ENCOUNTER • The Waylight Conclave is roaming nearby. Four champions guard a cache.")
func advance(p:Vector2,move:Vector2)->Vector2:
 var result=p
 for n in maxi(1,ceili(move.length()/12)):
  var step=move/maxi(1,ceili(move.length()/12))
  if valid_point(result+Vector2(step.x,0)):result.x+=step.x
  if valid_point(result+Vector2(0,step.y)):result.y+=step.y
 return result
func heading(foe:Dictionary,target:Vector2)->Vector2:
 if game.adventure.combat.path_clear(foe.pos,target):return (target-foe.pos).normalized()
 var world=game.adventure.immersive
 if not world.active:return (target-foe.pos).normalized()
 var uid=int(foe.uid);var entry=paths.get(uid,{})
 if float(state.clock)>=float(entry.get("until",0)):entry={"until":float(state.clock)+.7,"path":world.route(foe.pos,target)};paths[uid]=entry
 var path:PackedVector2Array=entry.get("path",PackedVector2Array());var closest=INF;var index=0
 for n in path.size():
  var d=foe.pos.distance_squared_to(path[n])
  if d<closest:closest=d;index=n
 for n in range(index,path.size()):
  if foe.pos.distance_to(path[n])>35:return (path[n]-foe.pos).normalized()
 return Vector2.ZERO
func step(dt:float)->void:
 if state.is_empty() or state.phase in ["absent","complete"]:return
 state.clock+=dt
 if state.phase=="waiting":
  if foes().is_empty() or foes().size()>60 or points().is_empty():return
  var start:Vector2=points().values()[0];var candidate={};var best=0.0
  for foe in foes():
   if foe.pos.distance_to(start)>best and not foe.get("summoned",false) and not foe.boss:best=foe.pos.distance_to(start);candidate=foe
  if candidate.is_empty() or best<650:return
  spawn_pack(candidate.pos)
 var live=[]
 for foe in foes():
  if int(foe.get("uid",-1)) in state.members and float(foe.get("hp",0))>0:live.append(foe)
 for foe in live:
  if game.adventure.combat.stunned(game.adventure.combat.npc_key(foe)):continue
  var role=int(foe.conclave_role);var target=anchor();var distance=INF;var victim=""
  for id in points():
   if not game.adventure.alive(str(id)):continue
   if (Time.get_ticks_msec()<int(game.stealth_until.get(id,0)) if coop else game.stealth_time>0):continue
   var d=foe.pos.distance_to(points()[id])
   if d<distance:distance=d;target=points()[id];victim=str(id)
  var fighting=distance<680
  if not fighting:target=anchor()+Vector2.from_angle(float(state.clock)*.12+role*1.57)*145
  var movement=heading(foe,target)
  if fighting and role in [1,3] and distance<230:movement=-movement
  elif fighting and role in [1,3] and distance<350:movement=Vector2.ZERO
  foe.pos=advance(foe.pos,movement*(75 if role==0 else 115 if role==2 else 85)*dt*game.adventure.combat.speed_factor(game.adventure.combat.npc_key(foe)))
  foe.conclave_timer=float(foe.get("conclave_timer",1))-dt
  if not fighting or float(foe.conclave_timer)>0:continue
  foe.conclave_timer=5.5 if role==1 else 4.8 if role==3 else 1.8
  if role==1:
   for ally in live:
    if foe.pos.distance_to(ally.pos)<440:ally.hp=minf(float(ally.max_hp),float(ally.hp)+float(ally.max_hp)*.06)
   state.warnings.append({"at":[foe.pos.x,foe.pos.y],"time":.6,"kind":"heal","uid":int(foe.uid),"victim":""})
  elif role==3:state.warnings.append({"at":[foe.pos.x,foe.pos.y],"time":.85,"kind":"volley","uid":int(foe.uid),"victim":""})
  elif distance<110:state.warnings.append({"at":[foe.pos.x,foe.pos.y],"time":.65,"kind":"melee","uid":int(foe.uid),"victim":victim})
 for n in range(state.warnings.size()-1,-1,-1):
  var warning=state.warnings[n];warning.time-=dt
  if float(warning.time)>0:continue
  state.warnings.remove_at(n)
  if int(warning.uid) in state.dead:continue
  var at=Vector2(float(warning.at[0]),float(warning.at[1]))
  if warning.kind=="volley":
   for k in 8:game.adventure.combat.launch_projectile("enemy",at,Vector2.from_angle(k*TAU/8+float(state.clock)*.1),{"range":650,"speed":205,"color":"#bdb5ef","credit":preload("res://scripts/defeat_credit.gd").hazard("Conclave Prism Seer")},9)
  elif warning.kind=="melee":
   for id in points():
    if points()[id].distance_to(at)>100 or not game.adventure.combat.path_clear(at,points()[id]):continue
    if coop:game._hurt(str(id),17,"enemy","",preload("res://scripts/defeat_credit.gd").hazard("Conclave Ravager"))
    else:game.take_player_damage(17,"",preload("res://scripts/defeat_credit.gd").hazard("Conclave Ravager"))
func draw_on(canvas:Node2D,camera:Vector2)->void:
 if state.is_empty():return
 var view=Rect2(camera,canvas.VIEW).grow(100)
 for foe in foes():
  if int(foe.get("uid",-1)) not in state.get("members",[]) or not view.has_point(foe.pos):continue
  var role=int(foe.get("conclave_role",state.members.find(int(foe.uid))));var p:Vector2=foe.pos-camera;var tint=Color(COLORS[role])
  if role==0:
   canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(23,-33),p+Vector2(44,-28),p+Vector2(42,-3),p+Vector2(32,8),p+Vector2(23,-7)]),Color("#557a87"));canvas.draw_line(p+Vector2(33,-30),p+Vector2(33,1),tint,3,true)
  elif role==1:
   canvas.draw_line(p+Vector2(-30,7),p+Vector2(-30,-48),Color("#a6bc87"),4,true);canvas.draw_circle(p+Vector2(-30,-51),7,tint);canvas.draw_line(p+Vector2(-34,-51),p+Vector2(-26,-51),Color("#e7f4c6"),2,true)
  elif role==2:
   for sign in [-1,1]:canvas.draw_line(p+Vector2(sign*27,-5),p+Vector2(sign*38,-32),tint,4,true);canvas.draw_arc(p+Vector2(sign*38,-32),10,0,PI,8,Color("#eee0c5"),4,true)
  else:
   for n in 4:
    var q=p+Vector2.from_angle(n*TAU/4)*32-Vector2(0,15);canvas.draw_colored_polygon(PackedVector2Array([q-Vector2(0,7),q+Vector2(4,0),q+Vector2(0,7),q-Vector2(4,0)]),tint)
  canvas.draw_arc(p,37,float(state.clock)*.4,float(state.clock)*.4+TAU*.9,24,tint,2,true)
  canvas.draw_rect(Rect2(p+Vector2(-43,-57),Vector2(86,5)),Color("#293c40"));canvas.draw_rect(Rect2(p+Vector2(-43,-57),Vector2(86*clampf(float(foe.hp)/float(foe.max_hp),0,1),5)),tint)
  canvas.draw_string(canvas.font,p+Vector2(-82,-64),ROLES[role],HORIZONTAL_ALIGNMENT_CENTER,164,12,tint)
 for warning in state.get("warnings",[]):
  var at=Vector2(float(warning.at[0]),float(warning.at[1]));var p=at-camera
  if not view.has_point(at):continue
  if warning.kind=="heal":canvas.draw_arc(p,65,0,TAU,24,Color("#95deb1"),3,true)
  else:preload("res://scripts/combat_cues.gd").danger(canvas,p,95 if warning.kind=="melee" else 70,float(warning.time),.85,Color("#bdb5ef"))
static func valid(v:Variant)->bool:
 if not v is Dictionary:return false
 if v.is_empty():return true
 if v.get("phase","") not in ["absent","waiting","active","complete"]:return false
 var C=preload("res://scripts/waylight_catalog.gd")
 if not C.number(v.get("seed"),2147483647) or not C.number(v.get("clock"),1e9):return false
 if not v.get("anchor") is Array or v.anchor.size()!=2:return false
 for n in v.anchor:
  if not (n is int or n is float) or not is_finite(n) or absf(n)>40000:return false
 for key in ["members","dead"]:
  if not v.get(key) is Array or v[key].size()>4:return false
  var unique=[]
  for uid in v[key]:
   if not C.number(uid,1e12) or uid in unique:return false
   unique.append(uid)
 for uid in v.dead:
  if uid not in v.members:return false
 if not v.get("warnings") is Array or v.warnings.size()>16:return false
 for warning in v.warnings:
  if not warning is Dictionary or warning.get("kind","") not in ["heal","volley","melee"] or not C.number(warning.get("time"),2) or not C.number(warning.get("uid"),1e12):return false
  if not warning.get("victim") is String or warning.victim.length()>80 or not warning.get("at") is Array or warning.at.size()!=2:return false
  for n in warning.at:
   if not (n is int or n is float) or not is_finite(n) or absf(n)>40000:return false
 return true

func restore(data:Dictionary)->void:
 state=data.duplicate(true);paths.clear()
 for key in ["members","dead"]:
  if state.has(key):
   for n in state[key].size():state[key][n]=int(state[key][n])
 for warning in state.get("warnings",[]):warning.uid=int(warning.uid)
