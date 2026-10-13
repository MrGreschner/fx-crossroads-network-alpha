extends RefCounted
const Brain=preload("res://scripts/combat_brain.gd")
## North Gate's host-authoritative campaign. Guests receive only bounded display state.
const BASE=Vector2(5300,7800)
const SIZE=Vector2(10600,9400)
const ROUTES=[
 [BASE,Vector2(5100,6100),Vector2(5550,4300),Vector2(4900,2600),Vector2(5300,500)],
 [BASE,Vector2(4400,7300),Vector2(3200,7700),Vector2(1800,7100),Vector2(300,7800)],
 [BASE,Vector2(6300,7300),Vector2(7400,7700),Vector2(9000,7100),Vector2(10300,7800)]
]
const NAMES=["BELLWOOD ROAD","OLD MILL ROAD","EMBERWATCH ROAD"]
const OUTPOST_DISTANCE=[2800.0,2400.0,2400.0]
const RIVALS=["gate_rival","gate_bastion","gate_cinder"]
const RIVAL_NAMES=["Sable Voss","Brass Bastion","Cinder Oracle"]
const TYPES=["gate_rival","gate_bastion","gate_cinder","tollbreaker"]
var rivals:Dictionary={}
var game:Node
var config:Dictionary={}
var party_size:=1
var shares:Dictionary={}
var xp_shares:Dictionary={}
var warnings:Array[Dictionary]=[]
var rival_level:int:
 get:return int(rival_state("gate_rival").level)
 set(value):rival_state("gate_rival").level=value
var rival_xp:int:
 get:return int(rival_state("gate_rival").xp)
 set(value):rival_state("gate_rival").xp=value
var rival_kills:int:
 get:return int(rival_state("gate_rival").kills)
 set(value):rival_state("gate_rival").kills=value
var rival_deaths:int:
 get:return int(rival_state("gate_rival").deaths)
 set(value):rival_state("gate_rival").deaths=value
var rival_respawn:float:
 get:return float(rival_state("gate_rival").respawn)
 set(value):rival_state("gate_rival").respawn=value
var rival_lane:=0
func rival_state(id:String)->Dictionary:
 if not rivals.has(id):rivals[id]={"level":1,"xp":0,"kills":0,"deaths":0,"respawn":0.0}
 return rivals[id]
var boss_defeated:=false
var clock:=0.0
var boss_spawned:=false
var received_at:=0
var outpost_hp:Array[float]=[1200.0,1200.0,1200.0]
var outpost_max:=1200.0
func setup(owner:Node)->void:
 game=owner;config=game._json("res://content/modes/north_gate.json")
 rivals.clear();party_size=clampi(game.positions.size(),1,3);shares.clear();xp_shares.clear();warnings.clear()
 outpost_max=1200.0*factor("party_health_scale");outpost_hp.assign([outpost_max,outpost_max,outpost_max])
 rival_level=1;rival_xp=0;rival_kills=0;rival_deaths=0;rival_respawn=0;rival_lane=0;boss_defeated=false;boss_spawned=false;clock=0
 game.enemy_defs.gate_rival={"name":"Sable Voss","health":260,"speed":235,"damage":15,"behaviour":"ranged","expansion_only":true}
 game.enemy_defs.tollbreaker={"name":"The Tollbreaker","health":2100,"speed":105,"damage":28,"behaviour":"chase","expansion_only":true}
 for n in 3:
  var id:String=RIVALS[n];rival_state(id)
  game.enemy_defs[id]={"name":RIVAL_NAMES[n],"health":260,"speed":235,"damage":15,"behaviour":"chase" if n==1 else "ranged","expansion_only":true}
  for pose in ["walk1","walk2"]:game.art[id+"_"+pose]=preload("res://scripts/source_art.gd").texture("res://assets/"+["npc_sable","npc_bastion","npc_cinder"][n]+"_"+pose+".svg")
 for pose in ["walk1","walk2"]:game.art["tollbreaker_"+pose]=preload("res://scripts/source_art.gd").texture("res://assets/tollbreaker_"+pose+".svg")
func factor(key:String)->float:return float(config.get(key,[1,1,1,1])[party_size-1])
func wave_count(number:int)->int:return roundi((18.0+minf(24,number*.8))*factor("party_count_scale"))
func creep_health(number:int)->float:return (0.95+number*.055)*factor("party_health_scale")
func creep_damage(number:int)->float:return (1.0+number*.018)*factor("party_damage_scale")
func boss_health()->float:return 2100.0*factor("party_health_scale")*factor("party_count_scale")
func pool(number:int)->Array[String]:
 var entries:Array[String]=["imp","bramble","archer"]
 if number>=5:entries.append_array(["rusher","frostling","ice_archer"])
 if number>=12:entries.append_array(["shambler","spore_thrower","snow_oracle"])
 if number>=20:entries.append_array(["star_mine","void_seeker","sun_sentinel"])
 return entries
func length_of(lane:int)->float:
 var length:=0.0
 for i in range(ROUTES[lane].size()-1):length+=(ROUTES[lane][i] as Vector2).distance_to(ROUTES[lane][i+1])
 return length
func point_at(lane:int,distance:float,lateral:float=0)->Vector2:
 var points:Array=ROUTES[lane]
 for i in range(points.size()-1):
  var start:Vector2=points[i];var end:Vector2=points[i+1];var segment:float=start.distance_to(end)
  if distance<=segment:return start.lerp(end,clampf(distance/segment,0,1))+(end-start).normalized().orthogonal()*lateral
  distance-=segment
 return points[-1]
func distance_at(lane:int,point:Vector2)->float:
 var best:=INF;var answer:=0.0;var total:=0.0
 for i in range(ROUTES[lane].size()-1):
  var a:Vector2=ROUTES[lane][i];var b:Vector2=ROUTES[lane][i+1];var segment:Vector2=b-a
  var t:=clampf((point-a).dot(segment)/segment.length_squared(),0,1)
  var dist:=point.distance_squared_to(a+segment*t)
  if dist<best:best=dist;answer=total+t*segment.length()
  total+=segment.length()
 return answer
func lane_goal(lane:int,point:Vector2,outward:bool)->Vector2:
 return point_at(lane,distance_at(lane,point)+(160 if outward else -160))
func enemy_spawn(lane:int,_number:int,offset:int)->Vector2:
 return point_at(lane,length_of(lane)-90,float(offset%3-1)*48)
func spawn_wave(number:int)->void:
 game.status_label.text="Wave %d • Enemies are marching from the far road entrances. Meet them at the outposts!" % number
 var count:=wave_count(number)
 var rng:=RandomNumberGenerator.new();rng.seed=game.floor_seed+number*997
 var entries:Array[String]=pool(number)
 for n in count:
  var lane:int=(n+number)%3;var id:String=entries[rng.randi_range(0,entries.size()-1)]
  var hp:float=float(game.enemy_defs[id].get("health",65))*creep_health(number)
  game.opponents.append({"pos":enemy_spawn(lane,number,n),"hp":hp,"max_hp":hp,"type":id,"lane":lane,"boss":false,"attack_timer":.5,"uid":randi(),"defense_wave":number,"damage_scale":creep_damage(number),"opening_march":float(config.get("opening_march_seconds",8)) if number<=2 else 0.0})
 if number%5==0 and number!=30:
  var hp:float=(210+number*20)*factor("party_health_scale")
  game.opponents.append({"pos":enemy_spawn(number%3,number,0),"hp":hp,"max_hp":hp,"type":"shambler","lane":number%3,"boss":true,"attack_timer":1.0,"uid":randi(),"defense_wave":number,"damage_scale":creep_damage(number)*1.15})
 if number==30:
  boss_spawned=true
  var hp:float=boss_health()
  game.opponents.append({"pos":enemy_spawn(0,number,0),"hp":hp,"max_hp":hp,"type":"tollbreaker","lane":0,"boss":true,"hit_radius":55,"attack_timer":2.5,"skill":0,"gate_timer":1.0,"uid":randi(),"defense_wave":30})
  game.status_label.text="WAVE 30 • Defeat the Tollbreaker and clear its army to earn the town bastion!"
func next_wave_allowed()->bool:
 if game.wave>=30 and (not boss_defeated or game.defense_cleared_wave<30):return false
 return game.opponents.filter(func(foe:Dictionary):return not bool(foe.get("campaign_hero",false))).size()<int(config.get("max_active_creeps",90))-wave_count(game.wave+1)
func reinforce()->void:
 for lane in 3:
  var count:=0
  for guard in game.guards:
   if int(guard.get("lane",-1))==lane and str(guard.get("type",""))!="summoned":count+=1
  var cap:int=int(config.get("max_guards_per_lane",10))+int(game.upgrade_level.count)*2
  var kinds:Array[String]=[]
  for n in 2+int(game.upgrade_level.count):kinds.append("melee")
  if int(game.upgrade_level.ranged)>0:kinds.append("ranged")
  if int(game.upgrade_level.area)>0:kinds.append("area")
  if outpost_hp[lane]>0:kinds.append("outpost")
  for kind in kinds:
   if count>=cap:break
   var actual:String="melee" if kind=="outpost" else kind
   var hp:float=65+game.wave*1.8+20*int(game.upgrade_level.health)
   var damage:float=10+game.wave*.4+4*int(game.upgrade_level.attack)
   if actual=="ranged":damage+=int(game.upgrade_level.ranged)*3
   if actual=="area":damage=10+game.wave*.45+int(game.upgrade_level.area)*3+4*int(game.upgrade_level.attack)
   game._spawn_defense_guard(lane,actual,hp,damage)
   var guard:Dictionary=game.guards[-1];guard.owner="lane_guard";guard.speed=float(config.get("guard_speed",105));guard.origin="outpost" if kind=="outpost" else "base"
   if kind=="outpost":
    var start_distance:float=OUTPOST_DISTANCE[lane]
    for attempt in 12:
     var candidate:Vector2=point_at(lane,start_distance+attempt*55,float(count%2)*60-30)
     var clear:=true
     for other in game.guards:
      if other!=guard and candidate.distance_to(other.pos)<50:clear=false;break
     if clear:guard.pos=candidate;break
   count+=1
func grant_xp(id:String,amount:int)->void:
 if not game.xp.has(id) or amount<=0:return
 game.xp[id]=int(game.xp[id])+amount
 var threshold:int=5+int(game.levels.get(id,1))*3
 while int(game.xp[id])>=threshold:
  game.xp[id]-=threshold;game.levels[id]=int(game.levels.get(id,1))+1
  game.health[id]=mini(game._max_hp(id),int(game.health.get(id,0))+15) if int(game.health.get(id,0))>0 else 0
  threshold=5+int(game.levels[id])*3
func guard_bounty(boss:bool)->void:
 for id in game.positions:
  if not game.gold.has(id):continue
  shares[id]=float(shares.get(id,0))+(20 if boss else 2)*float(config.get("guard_bounty_share",.2))
  var whole:=floori(float(shares[id])+.000001)
  game.gold[id]=int(game.gold[id])+whole;shares[id]=float(shares[id])-whole
  xp_shares[id]=float(xp_shares.get(id,0))+(12 if boss else 1)*float(config.get("guard_xp_share",.2))
  var whole_xp:=floori(float(xp_shares[id])+.000001);xp_shares[id]=float(xp_shares[id])-whole_xp;grant_xp(str(id),whole_xp)
func killed(foe:Dictionary)->void:
 var id:=str(foe.get("type",""))
 if id in RIVALS:
  var state:=rival_state(id);state.deaths+=1;state.respawn=float(config.get("rival_respawn_seconds",14))+float(state.level)*.6
  game.status_label.text=RIVAL_NAMES[RIVALS.find(id)]+" defeated • returns in %ds" % int(state.respawn)
 elif id=="tollbreaker":
  boss_defeated=true;game.status_label.text="The Tollbreaker has fallen! Clear remaining wave-30 attackers to fortify the town gate."
func rival_gain(amount:int,id:String="gate_rival")->void:
 var state:=rival_state(id);state.kills+=1;state.xp+=amount
 while int(state.xp)>=3+int(state.level)*2 and int(state.level)<int(config.get("rival_level_cap",12)):
  state.xp-=3+int(state.level)*2;state.level+=1
  var body:=rival_body(id)
  if not body.is_empty():body.max_hp=rival_hp(id);body.hp=minf(float(body.max_hp),float(body.hp)+40)
func rival_hp(id:String="gate_rival")->float:
 return (320 if id=="gate_bastion" else 240 if id=="gate_cinder" else 260)+int(rival_state(id).level)*36.0
func rival_body(id:String="gate_rival")->Dictionary:
 for foe in game.opponents:
  if str(foe.type)==id:return foe
 return {}
func spawn_rival(id:String="gate_rival")->void:
 if not rival_body(id).is_empty():return
 var lane:int=RIVALS.find(id);var hp:=rival_hp(id)
 game.opponents.append({"pos":enemy_spawn(lane,game.wave,0),"hp":hp,"max_hp":hp,"type":id,"lane":lane,"boss":true,"campaign_hero":true,"attack_timer":1.0,"secondary_cd":3.0,"special_cd":7.0,"dodge_cd":2.0,"dodge_left":0.0,"think":0.0,"target":"","uid":randi(),"hit_radius":24})
 game.status_label.text=RIVAL_NAMES[lane]+" has arrived • "+NAMES[lane]
func opening_speed(foe:Dictionary,delta:float)->float:
 var left:=float(foe.get("opening_march",0));foe.opening_march=maxf(0,left-delta)
 if left<=0:return 1.0
 # A marching advantage only: drop it near players, guards or the outpost.
 if distance_at(int(foe.lane),foe.pos)<=OUTPOST_DISTANCE[int(foe.lane)]+350:return 1.0
 for id in game.positions:
  if int(game.health.get(id,0))>0 and (foe.pos as Vector2).distance_to(game.positions[id])<500:return 1.0
 for guard in game.guards:
  if (foe.pos as Vector2).distance_to(guard.pos)<400:return 1.0
 return float(config.get("opening_march_multiplier",2))
func step(delta:float)->void:
 if game.mode!="defense" or game.role!="host" or not game.started:return
 clock+=delta
 party_size=clampi(game.positions.size(),1,3)
 for i in range(game.opponents.size()-1,-1,-1):
  var kind:=str(game.opponents[i].type)
  if kind in RIVALS and RIVALS.find(kind)>=party_size:game.opponents.remove_at(i)
 if game.wave>=3:
  for n in party_size:
   var id:String=RIVALS[n];var state:=rival_state(id)
   if rival_body(id).is_empty():
    state.respawn=float(state.respawn)-delta
    if float(state.respawn)<=0:spawn_rival(id)
 for i in range(warnings.size()-1,-1,-1):
  warnings[i].left=float(warnings[i].left)-delta
  if float(warnings[i].left)<=0:
   var warning:Dictionary=warnings[i];warnings.remove_at(i);detonate(warning)
 for foe in game.opponents.duplicate():
  if str(foe.type) in RIVALS:step_rival(foe,delta)
  elif str(foe.type)=="tollbreaker":step_boss(foe,delta)
func target_point(key:String)->Vector2:
 if key.begins_with("p:"):return game.positions.get(key.substr(2),BASE)
 for guard in game.guards:
  if int(guard.get("gate_uid",-1))==int(key.substr(2)):return guard.pos
 return BASE
func pick_target(foe:Dictionary)->String:
 var best:=INF;var answer:=""
 for id in game.positions:
  if int(game.health.get(id,0))<=0 or Time.get_ticks_msec()<int(game.stealth_until.get(id,0)):continue
  var distance:float=(foe.pos as Vector2).distance_to(game.positions[id])
  if distance>950 or not game._clear_path(foe.pos,game.positions[id]):continue
  # Prefer exposed low-health heroes, but do not see through cover or across the map.
  var score:float=distance+float(game.health[id])*1.3-(130 if str(foe.get("target",""))=="p:"+str(id) else 0)
  if score<best:best=score;answer="p:"+str(id)
 for guard in game.guards:
  if str(guard.type)=="summoned":continue
  var distance:float=(foe.pos as Vector2).distance_to(guard.pos)
  if distance>650:continue
  if not guard.has("gate_uid"):guard.gate_uid=randi()
  if distance+160<best:best=distance+160;answer="g:"+str(guard.gate_uid)
 return answer
func closest_lane(point:Vector2)->int:
 var lane:=0;var best:=INF
 for n in 3:
  var projected:Vector2=point_at(n,distance_at(n,point))
  if point.distance_to(projected)<best:best=point.distance_to(projected);lane=n
 return lane
func step_rival(foe:Dictionary,delta:float)->void:
 var combat=game.adventure.combat
 var source:=str(foe.type);var level:=int(rival_state(source).level)
 var melee:bool=source=="gate_bastion"
 var hard:bool=game.ai_difficulty=="hard"
 var reaction:float=.18 if hard else .36
 if combat.stunned(combat.npc_key(foe)):return
 for key in ["attack_timer","secondary_cd","special_cd","dodge_cd","dodge_left","think"]:foe[key]=maxf(0,float(foe.get(key,0))-delta)
 if float(foe.think)<=0:
  foe.think=reaction
  var next_target:String=pick_target(foe)
  var observed:Vector2=target_point(next_target) if not next_target.is_empty() else BASE
  foe.target_velocity=((observed-(foe.get("previous_target_point",observed) as Vector2))/reaction).limit_length(340) if next_target==str(foe.target) else Vector2.ZERO
  foe.previous_target_point=observed;foe.target=next_target
 var target:String=str(foe.target);var origin:Vector2=foe.pos
 var retreat:bool=float(foe.hp)<float(foe.max_hp)*.27
 var goal:Vector2=point_at(int(foe.lane),minf(length_of(int(foe.lane))-100,3400+game.wave*65)) if retreat else lane_goal(int(foe.lane),origin,false)
 if not target.is_empty() and not retreat:goal=target_point(target)
 var toward:Vector2=(goal-origin).normalized();var distance:float=origin.distance_to(goal)
 var wish:Vector2=toward
 if not target.is_empty() and not retreat:
  wish=Brain.spacing(origin,goal,65 if melee else 240,95 if melee else 380,float(foe.hp)/float(foe.max_hp),1 if int(foe.uid)%2 else -1)
 var neighbours:Array=[]
 for other in game.opponents:
  if other!=foe and (other.pos as Vector2).distance_to(origin)<75:neighbours.append(other.pos)
 wish=Brain.steer(origin,wish,game._clear_path,neighbours,1 if int(foe.uid)%2 else -1)
 var danger:=false
 for shot in game.missiles:
  if str(shot.owner)=="enemy":continue
  var offset:Vector2=origin-(shot.pos as Vector2)
  if offset.length()<220 and (shot.direction as Vector2).dot(offset.normalized())>.8:danger=true;break
 if not danger:
  for shot in combat.projectiles:
   if str(shot.owner)=="enemy":continue
   var offset:Vector2=origin-combat.vec(shot.pos)
   if offset.length()<220 and combat.vec(shot.aim).dot(offset.normalized())>.8:danger=true;break
 if float(foe.dodge_cd)<=0 and (danger or not melee and distance<145 or retreat):
  foe.dodge_cd=3.5 if hard else 6.0;foe.dodge_left=.22;foe.dodge_direction=toward if retreat else -toward if distance<145 else toward.orthogonal()*(1 if int(foe.uid)%2 else -1)
  game._emit_effect({"pos":origin,"end":origin+foe.dodge_direction*130,"style":"line","color":"#a7baf3","time":.25})
 if float(foe.dodge_left)>0:wish=foe.get("dodge_direction",wish)
 var speed:float=(570 if float(foe.dodge_left)>0 else 235)*combat.speed_factor(combat.npc_key(foe))
 var proposed:Vector2=game._guard_blocked_move(origin,wish*speed*delta,-1,44)
 foe.pos=game._move_actor(origin,proposed-origin)
 if hold_at_outpost(foe,delta):return
 # Recover slowly at the backline; never heal while actively dueling.
 if retreat and (target.is_empty() or origin.distance_to(target_point(target))>600):foe.hp=minf(float(foe.max_hp),float(foe.hp)+float(foe.max_hp)*.015*delta)
 if target.is_empty() or retreat or distance>580 or not game._clear_path(origin,goal):return
 if melee:
  if float(foe.attack_timer)<=0 and distance<125:
   foe.attack_timer=1.2;blast(origin+toward*45,85,20+level*1.4,source)
  if level>=3 and float(foe.secondary_cd)<=0 and distance<260:
   foe.secondary_cd=8;combat.apply_status(combat.npc_key(foe),"guard",1.5,"enemy",.45)
   game._emit_effect({"pos":foe.pos,"radius":40.0,"time":1.5,"color":"#ecc781"})
  if level>=6 and float(foe.special_cd)<=0 and distance>130 and distance<400:
   foe.special_cd=12;foe.dodge_left=.5;foe.dodge_direction=toward
   warn(goal,115,.65,30+level,"bastion_stomp",source)
  return
 if float(foe.attack_timer)<=0:
  foe.attack_timer=1.25
  var predicted:Vector2=Brain.lead(origin,goal,(foe.get("target_velocity",Vector2.ZERO) as Vector2)*(.95 if hard else .5),390)
  var aim:Vector2=(predicted-origin).normalized().rotated(sin(clock*2+int(foe.uid))*(.025 if hard else .11))
  fire(origin,aim,(14+level*1.4)*factor("party_damage_scale"),source,0)
  if level>=4 and source=="gate_rival":fire(origin,aim.rotated(.13),8+level,source,0)
 if level>=3 and float(foe.secondary_cd)<=0:
  foe.secondary_cd=8
  warn(goal,110,.95,16+level,"cinder_burst" if source=="gate_cinder" else "rival_snare",source)
 if level>=6 and float(foe.special_cd)<=0:
  foe.special_cd=17
  var aim:Vector2=(goal-origin).normalized()
  if source=="gate_cinder":
   for n in 3:warn(goal+Vector2.from_angle(n*TAU/3)*85,100,1.1+n*.3,22+level,"cinder_burst",source)
  else:
   for angle in [-.45,0,.45]:warn(origin+aim.rotated(angle)*250,80,1.1,24+level*1.5,"crossfire",source,origin+aim.rotated(angle)*250,aim)
func fire(origin:Vector2,aim:Vector2,amount:float,source:String,explode:float,cause:Dictionary={})->void:
 if game.missiles.size()>=128:return
 game.missiles.append({"credit":cause if not cause.is_empty() else preload("res://scripts/defeat_credit.gd").resolve(game,source,"Explosive projectile" if explode>0 else "Projectile"),"pos":origin,"direction":aim,"speed":390.0,"damage":amount,"owner":"enemy","npc_source":source,"distance":0.0,"range":820.0,"color":"#cc94ed" if source=="gate_rival" else "#ffc47d","explode":explode})
func warn(point:Vector2,radius:float,delay:float,amount:float,kind:String,source:String,start:Vector2=Vector2.ZERO,aim:Vector2=Vector2.RIGHT)->void:
 if warnings.size()>=24:return
 warnings.append({"credit":preload("res://scripts/defeat_credit.gd").resolve(game,source,kind.replace("_"," ").capitalize()),"pos":[point.x,point.y],"radius":radius,"left":delay,"duration":delay,"damage":amount,"kind":kind,"source":source,"start":[start.x,start.y],"aim":[aim.x,aim.y]})
func warning_point(warning:Dictionary)->Vector2:return Vector2(float(warning.pos[0]),float(warning.pos[1]))
func detonate(warning:Dictionary)->void:
 var center:Vector2=warning_point(warning)
 if str(warning.kind)=="crossfire":
  var aim:=Vector2(float(warning.aim[0]),float(warning.aim[1]))
  fire(center,aim,float(warning.damage),str(warning.source),75,warning.get("credit",{}))
  return
 blast(center,float(warning.radius),float(warning.damage),str(warning.source),1.8 if str(warning.kind)=="rival_snare" else 0,warning.get("credit",{}))
 if str(warning.kind) in ["cinder_burst","bastion_stomp"]:
  for id in game.positions:
   if center.distance_to(game.positions[id])<=float(warning.radius) and game._clear_path(center,game.positions[id]):
    game.adventure.combat.apply_status("p:"+str(id),"burn" if str(warning.kind)=="cinder_burst" else "stun",3.0 if str(warning.kind)=="cinder_burst" else .7,str(warning.source),2)
 if str(warning.kind)=="siege":
  for n in 8:fire(center,Vector2.from_angle(n*TAU/8),12*factor("party_damage_scale"),"tollbreaker",0)
func blast(center:Vector2,radius:float,amount:float,source:String,slow:float=0,cause:Dictionary={})->void:
 game._emit_effect({"pos":center,"radius":radius,"color":"#d99cf0" if source=="gate_rival" else "#ffb978","time":.45})
 for id in game.positions:
  if center.distance_to(game.positions[id])<=radius and game._clear_path(center,game.positions[id]):
   game._hurt(str(id),amount,source,"",cause if not cause.is_empty() else preload("res://scripts/defeat_credit.gd").resolve(game,source,"Area explosion"))
   if slow>0:game.adventure.combat.apply_status("p:"+str(id),"slow",slow,"enemy",.35)
 for i in range(game.guards.size()-1,-1,-1):
  if center.distance_to(game.guards[i].pos)<=radius:hurt_guard(i,amount,source)
func hurt_guard(index:int,amount:float,source:String)->void:
 if index<0 or index>=game.guards.size():return
 game.guards[index].hp=float(game.guards[index].hp)-maxf(1,amount-float(game.upgrade_level.armor)*2)
 if float(game.guards[index].hp)<=0:
  game.guards.remove_at(index)
  if source in RIVALS:rival_gain(1,source)
func step_boss(foe:Dictionary,delta:float)->void:
 if game.adventure.combat.stunned(game.adventure.combat.npc_key(foe)):return
 foe.attack_timer=maxf(0,float(foe.attack_timer)-delta);foe.gate_timer=maxf(0,float(foe.gate_timer)-delta)
 var target:String=pick_target(foe)
 var origin:Vector2=foe.pos;var goal:Vector2=target_point(target) if not target.is_empty() else lane_goal(0,origin,false)
 if origin.distance_to(goal)>120:
  var proposed:Vector2=game._guard_blocked_move(origin,(goal-origin).normalized()*105*game.adventure.combat.speed_factor(game.adventure.combat.npc_key(foe))*delta,-1,65)
  foe.pos=game._move_actor(origin,proposed-origin)
 if hold_at_outpost(foe,delta):return
 if origin.distance_to(BASE)<100 and float(foe.gate_timer)<=0:
  game.gate_hp-=30;foe.gate_timer=2.5
  if game.gate_hp<=0:game.end_match("The Tollbreaker shattered the north gate.")
 if float(foe.attack_timer)>0:return
 foe.attack_timer=3.7
 var skill:int=int(foe.skill)%3;foe.skill=int(foe.skill)+1
 if skill==0:
  # Triple delayed bellfall: distinct rings, not an instant invisible hit.
  for n in 3:warn(goal+Vector2.from_angle(clock+n*TAU/3)*95,155,.95+n*.18,30*factor("party_damage_scale"),"bellfall","tollbreaker")
 elif skill==1:
  var aim:Vector2=(goal-origin).normalized()
  for n in [-1,0,1]:fire(origin,aim.rotated(n*.23),24*factor("party_damage_scale"),"tollbreaker",100)
 else:
  warn(origin,320,1.25,36*factor("party_damage_scale"),"siege","tollbreaker")
func hold_at_outpost(foe:Dictionary,delta:float)->bool:
 # A lane's checkpoint cannot be bypassed by chasing, strafing, flight or dodge.
 var lane:=clampi(int(foe.get("lane",0)),0,2)
 if outpost_hp[lane]<=0:return false
 var frontier:float=OUTPOST_DISTANCE[lane]+120.0
 var progress:float=distance_at(lane,foe.pos)
 if progress<frontier:
  foe.pos=point_at(lane,frontier,float(int(foe.get("uid",0))%3-1)*45)
 if progress>frontier+150:return false
 foe.siege_timer=maxf(0,float(foe.get("siege_timer",0))-delta)
 if game.adventure.combat.stunned(game.adventure.combat.npc_key(foe)):return true
 if float(foe.siege_timer)<=0:
  foe.siege_timer=1.5
  var damage:float=float(game.enemy_defs.get(str(foe.type),{}).get("damage",10))*float(foe.get("damage_scale",1))
  if str(foe.type)=="tollbreaker":damage=65.0
  outpost_hp[lane]=maxf(0,outpost_hp[lane]-damage)
  game._emit_effect({"pos":foe.pos,"end":point_at(lane,OUTPOST_DISTANCE[lane]),"style":"line","color":"#ffc47d","time":.2})
  if outpost_hp[lane]<=0:
   game.status_label.text=NAMES[lane]+" outpost destroyed! Defend the town gate."
   game._emit_effect({"pos":point_at(lane,OUTPOST_DISTANCE[lane]),"radius":150,"color":"#dca773","time":.7})
 return true
func snapshot()->Dictionary:
 return {"rivals":rivals.duplicate(true),"outpost_hp":outpost_hp.duplicate(),"outpost_max":outpost_max,"rival_level":rival_level,"rival_xp":rival_xp,"rival_kills":rival_kills,"rival_deaths":rival_deaths,"rival_respawn":rival_respawn,"boss_defeated":boss_defeated,"boss_spawned":boss_spawned,"warnings":warnings,"party_size":party_size}
func receive(data:Dictionary)->void:
 rivals=data.get("rivals",{}).duplicate(true)
 received_at=Time.get_ticks_msec()
 outpost_max=float(data.get("outpost_max",1200))
 var incoming:Array=data.get("outpost_hp",[1200,1200,1200])
 if incoming.size()==3:outpost_hp.assign(incoming)
 rival_level=int(data.get("rival_level",1));rival_xp=int(data.get("rival_xp",0));rival_kills=int(data.get("rival_kills",0));rival_deaths=int(data.get("rival_deaths",0));rival_respawn=float(data.get("rival_respawn",0));boss_defeated=bool(data.get("boss_defeated",false));boss_spawned=bool(data.get("boss_spawned",false));party_size=clampi(int(data.get("party_size",1)),1,3)
 warnings.assign(data.get("warnings",[]).slice(0,24))
func draw_world(canvas:Node2D,camera:Vector2)->void:
 if game.mode!="defense":return
 draw_base(canvas,camera)
 var font:Font=ThemeDB.fallback_font
 var bounds:=Rect2(camera-Vector2(300,300),game.VIEW+Vector2(600,600))
 for lane in 3:
  var pos:Vector2=point_at(lane,OUTPOST_DISTANCE[lane])+Vector2(-150,-50) if lane==0 else point_at(lane,OUTPOST_DISTANCE[lane])+Vector2(0,-155)
  if not bounds.has_point(pos):continue
  var p:Vector2=pos-camera
  var checkpoint:Vector2=point_at(lane,OUTPOST_DISTANCE[lane])-camera
  var tangent:Vector2=(point_at(lane,OUTPOST_DISTANCE[lane]+10)-point_at(lane,OUTPOST_DISTANCE[lane]-10)).normalized().orthogonal()
  if outpost_hp[lane]<=0:
   for n in 7:canvas.draw_rect(Rect2(p+Vector2(-65+n*18,-10+sin(n*2)*18),Vector2(22,18)),Color("#69716b"))
   canvas.draw_string(font,p+Vector2(-65,58),"OUTPOST LOST",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e7a78e"))
   continue
  canvas.draw_line(checkpoint-tangent*190,checkpoint+tangent*190,Color("#655039"),12)
  for n in range(-4,5):canvas.draw_circle(checkpoint+tangent*n*44,9,Color("#b49b71"))
  canvas.draw_rect(Rect2(p+Vector2(-70,-158),Vector2(140,10)),Color("#352b29"))
  canvas.draw_rect(Rect2(p+Vector2(-70,-158),Vector2(140*outpost_hp[lane]/outpost_max,10)),Color("#75d8a2"))
  canvas.draw_circle(p+Vector2(0,20),85,Color(0,0,0,.22))
  canvas.draw_rect(Rect2(p+Vector2(-65,-75),Vector2(130,100)),Color("#718685"))
  for row in 4:
   for col in 5:canvas.draw_rect(Rect2(p+Vector2(-62+col*26,-72+row*24),Vector2(23,21)),Color("#a4b0a0"))
  canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(-80,-76),p+Vector2(0,-135),p+Vector2(80,-76)]),Color(["#405f75","#587364","#856450"][lane]))
  canvas.draw_rect(Rect2(p+Vector2(-15,-15),Vector2(30,40)),Color("#3e4b4a"))
  for side in [-1,1]:
   canvas.draw_rect(Rect2(p+Vector2(side*57-10,-106),Vector2(20,36)),Color("#b0b9a7"))
   canvas.draw_line(p+Vector2(side*76,-35),p+Vector2(side*76,-125),Color("#b5a276"),4)
   canvas.draw_rect(Rect2(p+Vector2(side*76,-122),Vector2(25,37)),Color("#72adba"))
  canvas.draw_string(font,p+Vector2(-90,58),["BELLWOOD OUTPOST","MILLROAD OUTPOST","EMBERWATCH OUTPOST"][lane],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#f4dfb7"))
  canvas.draw_string(font,p+Vector2(-85,80),"1 soldier / 20 seconds",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#bedccb"))
 # Camp lamps, supply carts and milestone stones make each road a place.
 for lane in 3:
  for n in range(1,5):
   var pos:Vector2=point_at(lane,n*950,200)
   if absf(n*950-OUTPOST_DISTANCE[lane])<230:continue
   if not bounds.has_point(pos):continue
   var p:Vector2=pos-camera
   canvas.draw_rect(Rect2(p+Vector2(-12,-16),Vector2(24,32)),Color("#85958e"))
   canvas.draw_rect(Rect2(p+Vector2(-8,-12),Vector2(16,10)),Color("#c0b994"))
   canvas.draw_string(font,p+Vector2(-4,-3),str(n),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#4c6059"))
   if n%2==0:
    canvas.draw_line(p+Vector2(28,5),p+Vector2(28,-63),Color("#6f644d"),5)
    canvas.draw_rect(Rect2(p+Vector2(20,-67),Vector2(16,22)),Color("#dfc786"))
    canvas.draw_circle(p+Vector2(28,-56),20,Color(1,.83,.4,.08))
 # Small moving highlights make the river flow without a full-screen shader.
 for x in range(int(camera.x/140)*140,int((camera.x+game.VIEW.x)/140+1)*140,140):
  for y in [4180,4340]:
   var world:=Vector2(x+fposmod(clock*30,140),y)
   if bounds.has_point(world) and not Rect2(5200,4030,590,490).has_point(world):canvas.draw_line(world-camera,world+Vector2(44,0)-camera,Color(.62,.86,.88,.36),1,true)
 # Three marked meeting circles at the town side of the lanes.
 for lane in 3:
  var pos:=point_at(lane,600)
  if bounds.has_point(pos):canvas.draw_arc(pos-camera,85,0,TAU,32,Color(.74,.77,.58,.45),3,true)
func draw_attacks(canvas:Node2D,camera:Vector2)->void:
 if game.mode!="defense":return
 var font:Font=ThemeDB.fallback_font
 for warning in warnings:
  var pos:Vector2=warning_point(warning)-camera
  if not Rect2(Vector2(-400,-400),game.VIEW+Vector2(800,800)).has_point(pos):continue
  var color:=Color("#d2a3f4") if str(warning.source)=="gate_rival" else Color("#f7b46d")
  var radius:float=float(warning.radius)
  var left:float=float(warning.left)-(float(Time.get_ticks_msec()-received_at)/1000 if game.role=="guest" else 0)
  preload("res://scripts/combat_cues.gd").danger(canvas,pos,radius,left,float(warning.duration),color)
  if str(warning.kind)=="crossfire":canvas.draw_line(pos,pos+Vector2(float(warning.aim[0]),float(warning.aim[1]))*100,color,3,true)
 for foe in game.opponents:
  if str(foe.type) not in TYPES:continue
  var pos:Vector2=foe.pos-camera
  if not Rect2(Vector2(-100,-150),game.VIEW+Vector2(200,300)).has_point(pos):continue
  canvas.draw_string(font,pos+Vector2(-60,-128 if str(foe.type)=="tollbreaker" else -70),RIVAL_NAMES[RIVALS.find(str(foe.type))]+" • Lv "+str(rival_state(str(foe.type)).level) if str(foe.type) in RIVALS else "THE TOLLBREAKER",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e3c4f7") if str(foe.type)=="gate_rival" else Color("#ffdeab"))
func draw_hud(canvas:Node2D)->void:
 if game.mode!="defense":return
 var font:Font=ThemeDB.fallback_font
 var lines:Array[String]=[]
 for n in party_size:
  var id:String=RIVALS[n];var state:=rival_state(id)
  lines.append(["Sable","Bastion","Oracle"][n]+" Lv"+str(state.level))
 var notice:String=" • ".join(lines)
 canvas.draw_rect(Rect2(20,105,660,25),Color(.04,.09,.12,.82))
 canvas.draw_string(font,Vector2(34,123),notice+"   |   Guards share 20% bounty",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#d6c3ed"))
 if game.wave>=30:
  var text:String="Bastion earned • endless defence continues" if game.defense_cleared_wave>=30 and boss_defeated else "WAVE 30: defeat the Tollbreaker + clear remaining attackers"
  canvas.draw_string(font,Vector2(35,175),text,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#ffe0a2"))
func draw_minimap(canvas:Node2D,rect:Rect2)->void:
 for lane in 3:
  for n in range(ROUTES[lane].size()-1):canvas.draw_line(rect.position+ROUTES[lane][n]/SIZE*rect.size,rect.position+ROUTES[lane][n+1]/SIZE*rect.size,Color("#c3b17d"),2)
  var point:Vector2=rect.position+point_at(lane,OUTPOST_DISTANCE[lane])/SIZE*rect.size
  canvas.draw_rect(Rect2(point-Vector2(3,3),Vector2(6,6)),Color("#75d8c6") if outpost_hp[lane]>0 else Color("#ab685a"))
 for foe in game.opponents:
  if str(foe.type) in TYPES:
   var point:Vector2=rect.position+foe.pos/SIZE*rect.size
   canvas.draw_circle(point,4,Color("#db91f0") if str(foe.type)=="gate_rival" else Color("#ffcc68"))
func upgrade_price(id:String,stage:int)->int:
 var base:int=(85 if id=="ranged" else 130 if id=="area" else 45)+stage*35
 return maxi(1,roundi(base*([.8,.9,1.0,1.05][party_size-1])))

func terrain_open(point:Vector2)->bool:
 for building in game.world_buildings:
  if str(building.name)!="Gate" and Rect2(building.pos-Vector2(85,105),Vector2(170,120)).has_point(point):return false
 for lane in 3:
  if outpost_hp[lane]<=0:continue
  var pos:Vector2=point_at(lane,OUTPOST_DISTANCE[lane])+Vector2(-150,-50) if lane==0 else point_at(lane,OUTPOST_DISTANCE[lane])+Vector2(0,-155)
  if Rect2(pos+Vector2(-65,-75),Vector2(130,100)).has_point(point):return false
 if Rect2(900,4100,8700,330).has_point(point):return Rect2(5200,4030,590,490).grow(-25).has_point(point)
 if Rect2(2200,5400,650,450).has_point(point):return false
 return true
func draw_base(canvas:Node2D,camera:Vector2)->void:
 var bounds:=Rect2(camera-Vector2(200,200),game.VIEW+Vector2(400,400))
 var font:Font=ThemeDB.fallback_font
 # A fortified courtyard with torch posts, staging pads, carts and a resting spring.
 for side in [-1,1]:
  var wall:Vector2=BASE+Vector2(side*350,0)
  if bounds.has_point(wall):
   var p:Vector2=wall-camera
   canvas.draw_rect(Rect2(p+Vector2(-190,-66),Vector2(380,68)),Color("#718588"))
   for row in 3:
    for brick in 12:canvas.draw_rect(Rect2(p+Vector2(-186+brick*31+(15 if row%2 else 0),-63+row*21),Vector2(28,18)),Color("#a1aca1"))
   for n in 9:canvas.draw_rect(Rect2(p+Vector2(-184+n*44,-82),Vector2(24,22)),Color("#aeb5a3"))
 for offset in [Vector2(-250,260),Vector2(250,260),Vector2(-250,760),Vector2(250,760)]:
  var pos:Vector2=BASE+offset
  if not bounds.has_point(pos):continue
  var p:Vector2=pos-camera
  canvas.draw_circle(p+Vector2(0,12),20,Color(0,0,0,.18))
  canvas.draw_rect(Rect2(p+Vector2(-7,-55),Vector2(14,66)),Color("#788d8b"))
  canvas.draw_rect(Rect2(p+Vector2(-16,-60),Vector2(32,12)),Color("#a8b5a2"))
  for n in 3:
   var tip:Vector2=p+Vector2(-9+n*9+sin(clock*6+n)*3,-76-9*sin(clock*5+n))
   canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(-14+n*9,-60),tip,p+Vector2(-4+n*9,-60)]),Color("#eab064"))
 for lane in 3:
  var p:Vector2=BASE+Vector2(-140+lane*140,370)-camera
  canvas.draw_arc(p,45,0,TAU,24,Color("#a5b79d"),3)
  canvas.draw_string(font,p+Vector2(-30,4),["NORTH","WEST","EAST"][lane],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#e4cf9c"))
 for site in [Vector2(4710,8200),Vector2(5900,8200)]:
  var point:Vector2=site+Vector2(110,20)
  if not bounds.has_point(point):continue
  var p:Vector2=point-camera
  for n in 3:canvas.draw_rect(Rect2(p+Vector2(-24+n*16,-25),Vector2(14,24)),Color("#a58d62"))
  canvas.draw_rect(Rect2(p+Vector2(-28,0),Vector2(60,11)),Color("#705f48"))
  for side in [-1,1]:canvas.draw_circle(p+Vector2(side*20,15),9,Color("#394b50"));canvas.draw_circle(p+Vector2(side*20,15),4,Color("#b49864"))
 var spring:Vector2=BASE+Vector2(0,600)
 if bounds.has_point(spring):
  var p:Vector2=spring-camera
  canvas.draw_circle(p,61,Color("#92a69b"));canvas.draw_circle(p,48,Color("#477f8b"))
  canvas.draw_arc(p,32,clock*.4,clock*.4+TAU*.8,32,Color("#aedbd3"),2,true)
  canvas.draw_rect(Rect2(p+Vector2(-11,-38),Vector2(22,28)),Color("#b4c4b1"))
  canvas.draw_circle(p+Vector2(0,-45),14,Color("#d0d8be"))
  for n in 3:canvas.draw_line(p+Vector2(sin(clock*2+n)*20,-24),p+Vector2(sin(clock*2+n)*24,-8),Color("#c2e4d9"),2)
  canvas.draw_string(font,p+Vector2(-70,88),"GATEWARD SPRING",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#def0d2"))
 # Watch guards patrol rather than standing motionless beside shops.
 for n in 2:
  var pos:Vector2=BASE+Vector2(-340+n*680,300+sin(clock*.2+n*PI)*170)
  if bounds.has_point(pos):canvas._sprite("guard_melee",pos-Vector2(20,42),Vector2(40,48))
