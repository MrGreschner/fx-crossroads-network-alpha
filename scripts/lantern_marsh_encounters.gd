extends RefCounted
## Bounded, authoritative marsh encounters. Shared projectile pool retains hero counters.
const TYPES=["bogpitch_newt","mireweaver","mirevein_collector"]
var world:Node
var zones:Array=[]
var bites:Array=[]
var tells:Array=[]
var drains:Array=[]
var bursts:Array=[]
var stun_until:Dictionary={}
var elite_view:Array=[]
var art:Dictionary={}
func reset()->void:
 zones.clear();bites.clear();tells.clear();drains.clear();stun_until.clear();elite_view.clear();bursts.clear()
func enabled()->bool:return is_instance_valid(world) and world.active and str(world.data.get("id",""))=="lantern_marsh"
func c()->Node:return world.adventure.combat
func foe(uid:int)->Dictionary:
 for e in world.adventure.foes():
  if int(e.uid)==uid and float(e.hp)>0:return e
 return {}
func protected(id:String)->bool:
 return Time.get_ticks_msec()<int(world.adventure.game.invincible_until.get(id,0)) if world.adventure.arcade else world.adventure.game.invulnerable_time>0
func health(id:String)->float:
 return float(world.adventure.game.health.get(id,0)) if world.adventure.arcade else float(world.adventure.game.health)
func slow(id:String,duration:float=1.2,factor:float=.65)->void:
 if world.adventure.alive(id) and not protected(id):c().apply_status(c().player_key(id),"slow",duration,"enemy",factor)
func tell(e:Dictionary,point:Vector2,radius:float,delay:float,kind:String,end:Vector2=Vector2.ZERO)->void:
 if tells.size()>=32:return
 tells.append({"uid":int(e.uid),"pos":world.a(point),"end":world.a(end),"radius":radius,"left":delay,"total":delay,"kind":kind})
 e.melee_warning=delay
func pool(point:Vector2,radius:float=45,life:float=3.4)->void:
 if zones.size()<72 and world.floor_at(point):zones.append({"pos":world.a(point),"radius":radius,"life":life,"total":life})
func shot(e:Dictionary,target:Vector2,kind:String,angle:float=0)->void:
 var stats={"name":"Mosquito brood" if kind=="mosquito" else "Rolling mire" if kind=="mud" else "Peat spit","credit":preload("res://scripts/defeat_credit.gd").resolve(world.adventure.game,c().npc_key(e),"Mosquito brood" if kind=="mosquito" else "Rolling mire" if kind=="mud" else "Peat spit"),"marsh_visual":kind,"marsh_uid":int(e.uid),"range":760 if kind=="mosquito" else 670,"speed":230 if kind=="mosquito" else 305 if kind=="mud" else 285,"projectile_radius":8 if kind=="mosquito" else 15,"color":"#d3c985" if kind=="mosquito" else "#8c7754","slow_duration":0 if kind=="mosquito" else 1.6,"slow_factor":.65}
 c().launch_projectile("enemy",e.pos,(target-e.pos).normalized().rotated(angle),stats,4 if kind=="mosquito" else 16 if kind=="mud" else 14,"homing" if kind=="mosquito" else "pellet")
func step_enemy(e:Dictionary,delta:float)->bool:
 if not enabled() or str(e.type) not in TYPES:return false
 if not world.adventure.authoritative():return true
 if c().stunned(c().npc_key(e)):
  e.marsh_catch=0.0;e.melee_warning=0.0
  tells=tells.filter(func(t):return int(t.uid)!=int(e.uid))
  return true
 e.melee_warning=maxf(0,float(e.get("melee_warning",0))-delta)
 var id=world.nearest(e.pos)
 if id.is_empty():return true
 var target:Vector2=world.target_for(e);var distance:float=e.pos.distance_to(target)
 var elite=str(e.type)=="mirevein_collector"
 if distance>950:
  # Patrol the connected main route instead of waiting motionless for aggro.
  if elite:
   var stops:Array=world.data.patrol;var index=int(e.get("marsh_patrol",0))%stops.size();var goal=world.v(stops[index])
   if e.pos.distance_to(goal)<75:e.marsh_patrol=(index+1)%stops.size()
   e.pos=world.advance(e.pos,world.direction(e,goal,false)*85*c().speed_factor(c().npc_key(e))*delta)
  e.marsh_catch=0.0
  return true
 if elite and not bool(e.get("marsh_seen",false)):
  e.marsh_seen=true;world.adventure.announce("ROAMING ELITE • Mirevein Collector: dodge its brood; stop shooting when its maw opens. Dodge again to shake off attached mosquitoes.")
 var winding=false
 for t in tells:
  if int(t.uid)==int(e.uid):winding=true;break
 var catching=float(e.get("marsh_catch",0))>0
 if catching:
  e.marsh_catch=maxf(0,float(e.marsh_catch)-delta);e.melee_warning=float(e.marsh_catch)
  if float(e.marsh_catch)==0:
   var count=int(e.get("marsh_caught",0));e.marsh_caught=0
   for n in count:shot(e,target,"mud",(n-(count-1)*.5)*.19)
  return true
 if not winding:
  var speed=float(world.defs()[e.type].speed)
  e.pos=world.advance(e.pos,world.direction(e,target,true)*speed*c().speed_factor(c().npc_key(e))*delta)
 e.attack_timer=float(e.get("attack_timer",1.2))-delta
 e.skill_timer=float(e.get("skill_timer",2.0))-delta
 if elite:
  e.marsh_stomp=maxf(0,float(e.get("marsh_stomp",4))-delta)
  if not winding and float(e.marsh_stomp)<=0 and distance<220:
   e.marsh_stomp=8.5;tell(e,e.pos,175,1.15,"stomp");return true
  if not winding and float(e.skill_timer)<=0:
   e.skill_timer=9.5;tell(e,e.pos,80,.75,"catch");return true
  if not winding and float(e.attack_timer)<=0 and c().path_clear(e.pos,target):
   e.attack_timer=2.8;e.melee_warning=.35
   for angle in [-.14,.14]:shot(e,target,"mosquito",angle)
 elif float(e.skill_timer)<=0 and not winding and c().path_clear(e.pos,target):
  e.skill_timer=4.3 if str(e.type)=="mireweaver" else 3.6
  if str(e.type)=="mireweaver":
   # Warn a cross-lane thread at a fixed location, leaving time to step out.
   var side:Vector2=(target-e.pos).normalized().orthogonal()*155
   tell(e,target-side,27,1.15,"silk",target+side)
  else:tell(e,target,50,.65,"spit")
 return true
func catch_shot(start:Vector2,end:Vector2,owner:String,moving:bool=true)->bool:
 if not enabled() or not moving or not world.adventure.authoritative() or owner=="enemy":return false
 for e in world.adventure.foes():
  if str(e.type)!="mirevein_collector" or float(e.hp)<=0 or float(e.get("marsh_catch",0))<=0 or int(e.get("marsh_caught",0))>=5 or c().stunned(c().npc_key(e)):continue
  var near=Geometry2D.get_closest_point_to_segment(e.pos,start,end)
  if near.distance_to(e.pos)>78 or not c().path_clear(start,near):continue
  # Only intercept shots from the hostile player/ally side, never other enemies.
  if not c().hostile(owner).has(c().npc_key(e)):continue
  e.marsh_caught=int(e.get("marsh_caught",0))+1;return true
 return false
func projectile_step(shot_data:Dictionary,start:Vector2,end:Vector2)->void:
 if not enabled() or str(shot_data.owner)!="enemy":return
 if str(shot_data.stats.get("marsh_visual",""))!="mud":return
 var spacing=float(shot_data.get("marsh_trail",0))+start.distance_to(end)
 if spacing>=48:
  pool(end,32,3.6);spacing=fmod(spacing,48)
 shot_data.marsh_trail=spacing
func impact(shot_data:Dictionary,key:String,point:Vector2,landed:bool)->void:
 if not enabled() or str(shot_data.owner)!="enemy":return
 var kind=str(shot_data.stats.get("marsh_visual",""))
 if kind=="peat" or kind=="mud":pool(point,50 if kind=="peat" else 38,3.8)
 if kind!="mosquito" or not landed or not key.begins_with("p:"):return
 var id=key.substr(2);var source=foe(int(shot_data.stats.get("marsh_uid",-1)))
 if source.is_empty() or not world.adventure.points().has(id) or not world.adventure.alive(id) or protected(id):return
 var count=0
 for bite in bites:
  if str(bite.player)==id:count+=1
 if count>=2:return
 # Snapshot the dodge cooldown: a NEW dodge removes existing attached brood.
 var dodge=float(world.adventure.game.dodge_at.get(id,0)) if world.adventure.arcade else float(world.adventure.game.dodge_cooldown)
 bites.append({"uid":int(source.uid),"player":id,"left":4.0,"tick":1.0,"dodge":dodge})
func step(delta:float)->void:
 if not enabled() or not world.adventure.authoritative():return
 elite_view=[]
 for e in world.adventure.foes():
  if str(e.type)=="mirevein_collector" and float(e.hp)>0:elite_view.append({"uid":int(e.uid),"catch":float(e.get("marsh_catch",0)),"caught":int(e.get("marsh_caught",0))})
 for n in range(tells.size()-1,-1,-1):
  var t:Dictionary=tells[n];t.left-=delta
  var e=foe(int(t.uid))
  if e.is_empty() or c().stunned(c().npc_key(e)):tells.remove_at(n);continue
  if float(t.left)>0:continue
  tells.remove_at(n);var p=world.v(t.pos);var kind=str(t.kind)
  if kind=="catch":e.marsh_catch=1.8;e.marsh_caught=0;e.melee_warning=1.8;continue
  if kind=="spit":
   for angle in [-.24,0,.24]:shot(e,p,"peat",angle)
   continue
  if bursts.size()<12:bursts.append({"pos":t.pos,"end":t.end,"kind":kind,"left":.45,"radius":t.radius})
  for id in world.adventure.points():
   if not world.adventure.alive(str(id)):continue
   var target:Vector2=world.adventure.points()[id]
   var near=Geometry2D.get_closest_point_to_segment(target,p,world.v(t.end)).distance_to(target)<float(t.radius)+16 if kind=="silk" else target.distance_to(p)<float(t.radius)
   if not near or not c().path_clear(e.pos,target) or protected(str(id)):continue
   world.hurt_player(str(id),20 if kind=="stomp" else 17,c().npc_key(e))
   if kind=="stomp":
    if world.clock>=float(stun_until.get(id,0)):c().apply_status(c().player_key(str(id)),"stun",.65,"enemy");stun_until[id]=world.clock+4
   else:slow(str(id),2.0,.6)
 for n in range(zones.size()-1,-1,-1):
  var z:Dictionary=zones[n];z.life-=delta
  if float(z.life)<=0:zones.remove_at(n);continue
  for id in world.adventure.points():
   if (world.adventure.points()[id] as Vector2).distance_to(world.v(z.pos))<float(z.radius):slow(str(id),.3,.65)
 for n in range(bursts.size()-1,-1,-1):
  bursts[n].left-=delta
  if float(bursts[n].left)<=0:bursts.remove_at(n)
 for n in range(drains.size()-1,-1,-1):
  drains[n].left-=delta
  if float(drains[n].left)<=0:drains.remove_at(n)
 for n in range(bites.size()-1,-1,-1):
  var b:Dictionary=bites[n];var e=foe(int(b.uid));var id=str(b.player)
  var dodge=float(world.adventure.game.dodge_at.get(id,0)) if world.adventure.arcade else float(world.adventure.game.dodge_cooldown)
  if e.is_empty() or not world.adventure.alive(id) or dodge>float(b.dodge)+.05 or float(b.left)<=0:
   bites.remove_at(n);continue
  b.dodge=dodge;b.left=maxf(0,float(b.left)-delta);b.tick-=delta
  if float(b.tick)<=0:
   b.tick+=1;var before=health(id);world.hurt_player(id,3,c().npc_key(e));var stolen=maxf(0,before-health(id))
   e.hp=minf(float(e.max_hp),float(e.hp)+stolen)
   if stolen>0 and drains.size()<16:drains.append({"start":world.a(world.adventure.points()[id]),"end":world.a(e.pos),"left":.5})
func boss_skill(e:Dictionary,target:Vector2,turn:int)->void:
 if turn%3==0:
  world.warning(e,target,"root",140,30,1.05)
  for side in [-1,1]:world.warning(e,target+Vector2(side*160,80),"root",65,20,1.45)
 elif turn%3==1:
  for n in 12:world.shoot(e,e.pos+Vector2.from_angle(TAU*n/12),1,"weaving")
 else:
  for n in 3:world.warning(e,target+Vector2((n-1)*110,0),"root",68,24,.85+n*.2)
func snapshot()->Dictionary:return {"zones":zones,"bites":bites,"tells":tells,"drains":drains,"elite":elite_view,"bursts":bursts}
func receive(s:Dictionary)->void:
 zones=s.get("zones",[]);bites=s.get("bites",[]);tells=s.get("tells",[]);drains=s.get("drains",[]);elite_view=s.get("elite",[]);bursts=s.get("bursts",[])
func texture(kind:String)->Texture2D:
 if not art.has(kind):art[kind]=preload("res://scripts/source_art.gd").texture("res://assets/"+kind+".svg")
 return art[kind]
func draw_ground(canvas:Node2D,camera:Vector2)->void:
 if not enabled():return
 var view=Rect2(camera,canvas.get_viewport_rect().size).grow(160)
 for point in world.data.get("marsh_ruins",[]):
  var p=world.v(point)
  if view.has_point(p):canvas.draw_texture_rect(texture("marsh_ruin"),Rect2(p-camera-Vector2(68,95),Vector2(136,120)),false)
 for point in world.data.get("marsh_lamps",[]):
  var p=world.v(point)
  if not view.has_point(p):continue
  canvas.draw_circle(p-camera,46,Color(.8,.85,.46,.055));canvas.draw_texture_rect(texture("marsh_beacon"),Rect2(p-camera-Vector2(26,80),Vector2(52,88)),false)
  var light=p-camera-Vector2(0,48);canvas.draw_circle(light,8+sin(world.clock*2+p.x)*1.5,Color(1,.87,.52,.26))
 # Sparse deterministic fireflies, bounded to the visible screen instead of map size.
 for n in 18:
  var p=camera+Vector2(posmod(int(camera.x/700)*71+n*139,1400),posmod(int(camera.y/700)*53+n*97,950))
  if not world.floor_at(p):continue
  p+=Vector2(sin(world.clock*.7+n)*13,cos(world.clock*.5+n)*9)
  canvas.draw_circle(p-camera,2,Color(.87,.94,.57,.35+.2*sin(world.clock*2+n)))
func draw(canvas:Node2D,camera:Vector2)->void:
 if not enabled():return
 var view=Rect2(camera,canvas.get_viewport_rect().size).grow(200)
 for z in zones:
  var p=world.v(z.pos)
  if not view.has_point(p):continue
  var radius=float(z.radius);var alpha=minf(1,float(z.life))
  canvas.draw_circle(p-camera,radius,Color(.36,.31,.22,.7*alpha));canvas.draw_arc(p-camera,radius,0,TAU,20,Color(.69,.64,.4,.8*alpha),2)
  for n in 3:canvas.draw_arc(p-camera+Vector2((n-1)*radius*.35,0),8,0,PI,8,Color(.69,.65,.43,.5*alpha),2)
 for t in tells:
  var p=world.v(t.pos)-camera
  if str(t.kind)=="silk":preload("res://scripts/combat_cues.gd").corridor(canvas,p,world.v(t.end)-camera,float(t.radius))
  else:preload("res://scripts/combat_cues.gd").danger(canvas,p,float(t.radius),float(t.left),float(t.total),Color("#dfbe81") if str(t.kind)=="stomp" else Color("#b9d2a3"))
 for b in bursts:
  var point=world.v(b.pos)-camera;var fade=float(b.left)/.45
  if str(b.kind)=="silk":canvas.draw_line(point,world.v(b.end)-camera,Color(.83,.87,.65,fade),4,true)
  else:
   var radius=float(b.radius)*(1-fade*.7);canvas.draw_arc(point,radius,0,TAU,28,Color(.76,.65,.39,fade),5,true)
   for n in 8:canvas.draw_circle(point+Vector2.from_angle(TAU*n/8)*radius,4,Color(.5,.45,.3,fade))
 for info in elite_view:
  var e=foe(int(info.uid))
  if e.is_empty() or not view.has_point(e.pos):continue
  var p:Vector2=e.pos-camera
  if float(info.catch)>0:
   canvas.draw_arc(p,78,0,TAU,32,Color("#e0c788"),3)
   for n in int(info.caught):canvas.draw_circle(p+Vector2.from_angle(-PI*.8+n*.4)*59,6,Color("#b6c78b"))
   canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-72,-83),"MAW OPEN • "+str(info.caught)+"/5",HORIZONTAL_ALIGNMENT_LEFT,190,13,Color("#ffe1a0"))
  else:canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-66,-82),"MIREVEIN • ELITE",HORIZONTAL_ALIGNMENT_LEFT,190,12,Color("#dec493"))
 for b in bites:
  var id=str(b.player)
  if not world.adventure.points().has(id):continue
  var p:Vector2=world.adventure.points()[id]-camera+Vector2(sin(world.clock*14+int(b.uid))*15,-25)
  draw_projectile(canvas,{"stats":{"marsh_visual":"mosquito"},"aim":[1,0]},p,world.clock)
  canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-35,-18),"DODGE TO SHED",HORIZONTAL_ALIGNMENT_LEFT,130,10,Color("#f6c1a5"))
 for d in drains:
  var progress=1-float(d.left)/.5;var p=world.v(d.start).lerp(world.v(d.end),progress)-camera
  canvas.draw_circle(p,4,Color("#d78875"));canvas.draw_line(p,p-(world.v(d.end)-world.v(d.start)).normalized()*18,Color(.84,.43,.35,.5),2)
static func draw_projectile(canvas:Node2D,s:Dictionary,p:Vector2,time:float)->bool:
 var kind=str(s.get("stats",{}).get("marsh_visual",""))
 if kind.is_empty():return false
 var aim=Vector2(s.aim[0],s.aim[1]);var side=aim.orthogonal()
 if kind=="mosquito":
  var wing=8+sin(time*40)*3
  for sign_value in [-1,1]:
   canvas.draw_line(p,p-aim*7+side*sign_value*wing,Color(.86,.92,.77,.8),4,true)
   canvas.draw_line(p-aim*3,p-aim*11+side*sign_value*6,Color("#797b59"),1,true)
  canvas.draw_line(p-aim*8,p+aim*6,Color("#c4aa69"),5,true);canvas.draw_line(p+aim*5,p+aim*15,Color("#e9d895"),2,true);canvas.draw_circle(p+aim*5,2,Color("#e7b185"))
 else:
  canvas.draw_circle(p,14 if kind=="mud" else 9,Color("#756443"));canvas.draw_arc(p,9 if kind=="mud" else 5,time*9,time*9+PI,12,Color("#b0a16a"),3)
  for n in 3:canvas.draw_circle(p-aim*(16+n*6)+side*sin(time*9+n)*5,3-n*.6,Color(.49,.43,.28,.5))
 return true
