extends RefCounted
## V203: official hero combat, one shared lantern and fixed 100-floor milestones.
const Book=preload("res://scripts/descent203_book.gd")
const Art=preload("res://scripts/descent203_art.gd")
var game:Node
var battle=preload("res://scripts/descent_battle251.gd").new()
func bind_battle()->void:battle.d=self;battle.game=game
var boosts:Dictionary={}
var pending:Dictionary={}
var warnings:Array=[]
var hazards:Array=[]
var wheels:Array=[]
var fuel_drops:Array=[]
var corpses:Array=[]
var clock:=0.0
var floor_clock:=0.0
var lamp:Dictionary={}
var fall_time:=-1.0
var fall_swapped:=false
var completed:=0
var cataclysm:=-1.0
var navigation:AStarGrid2D
var darkness:Texture2D
var lamp_texture:Texture2D
var room_darkness:Texture2D
var room_darkness_floor:=-1
var room_darkness_field:=Rect2()
var light_uvs:=PackedVector2Array()
var light_indices:=PackedInt32Array()
const EDGE_PREVIEW_FLOORS=6.0
const LIGHT_GRID=8
var interact_at:Dictionary={}
static func scaling(floor:int)->Dictionary:
 var depth=maxi(0,mini(floor,120)-11)
 return {"health":1+.012*depth+.00013*depth*depth,"damage":1+.0085*depth,"speed":1+minf(.30,depth*.0032),"pace":1+minf(.55,depth*.006)}
static func boss_pressure(floor:int)->float:return 1.3+maxi(1,floor/10)*.10
static func fuel_rate(floor:int)->float:return 0.0 if floor<20 else .20+minf(.55,(floor-20)*.006)
static func milestone(floor:int)->String:return Book.guardian(floor)
func reset()->void:
 bind_battle();battle.reset()
 boosts.clear();pending.clear();warnings.clear();hazards.clear();wheels.clear();fuel_drops.clear();corpses.clear();interact_at.clear();clock=0;floor_clock=0;fall_time=-1;fall_swapped=false;completed=0;cataclysm=-1;lamp={"holder":"","thief":0,"pos":[1200,850],"fuel":100.0}
func state(id:String)->Dictionary:
 if not boosts.has(id):boosts[id]={"power":0,"health":0,"cooldown":0,"spent":0}
 return boosts[id]
func reward(id:String,level:int)->void:
 if game.mode=="descent" and level>10 and game.floor_number<=100:pending[id]=int(pending.get(id,0))+1
func choose(id:String,value:String)->void:
 if game.mode!="descent" or game.role!="host" or int(pending.get(id,0))<=0 or value not in ["depth_power","depth_health","depth_cooldown"]:return
 var s=state(id);var key=value.trim_prefix("depth_")
 if key=="cooldown" and int(s.cooldown)>=10:return
 pending[id]=int(pending[id])-1;s[key]=int(s[key])+1;s.spent=int(s.spent)+1
 if key=="health":game.health[id]=mini(game._max_hp(id),int(game.health.get(id,0))+18)
func power(id:String)->float:return 1+.025*int(state(id).power)
func hp(id:String)->int:return 18*int(state(id).health)
func cooldown(id:String)->float:return maxf(.8,1-.02*int(state(id).cooldown))
func combat_count()->int:return battle.active_count()
func falling()->bool:return game.mode=="descent" and fall_time>=0
func point(value)->Vector2:return Vector2(value[0],value[1])
func pack(p:Vector2)->Array:return [p.x,p.y]
func lamp_pos()->Vector2:
 var holder=str(lamp.get("holder",""))
 if not holder.is_empty() and game.positions.has(holder):return game.positions[holder]+Vector2(22,10)
 for e in game.opponents:
  if int(e.uid)==int(lamp.get("thief",0)):return e.pos+Vector2(18,4)
 return point(lamp.get("pos",[1200,850]))
func interact(id:String)->bool:
 if game.role!="host" or falling() or int(game.health.get(id,0))<=0 or not game.positions.has(id) or clock<float(interact_at.get(id,0)):return false
 if str(lamp.get("holder",""))==id:
  lamp.holder="";lamp.pos=pack(game.positions[id]);interact_at[id]=clock+.5;return true
 if str(lamp.get("holder","")).is_empty() and int(lamp.get("thief",0))==0 and (game.positions[id] as Vector2).distance_to(lamp_pos())<80:
  lamp.holder=id;interact_at[id]=clock+.5;return true
 return false
func drop_lamp(at:Vector2)->void:
 lamp.holder="";lamp.thief=0;lamp.pos=pack(safe(at));interact_at["protection"]=clock+1.8
func safe(at:Vector2)->Vector2:
 var desired=at.clamp(Vector2(90,90),game.FIELD.size-Vector2(90,90))
 if game._clear_path(desired,desired):return desired
 for ring in range(1,20):
  for n in 16:
   var p=desired+Vector2.from_angle(n*TAU/16)*ring*24
   if game.FIELD.grow(-70).has_point(p) and game._clear_path(p,p):return p
 return game.FIELD.size*.5
func segment_clear(start:Vector2,finish:Vector2)->bool:
 # Exact swept segment/circle tests replace hundreds of sampled grid probes.
 # Use the same radii as ordinary movement and include temporary hero ice walls.
 for obstacle in game.field_obstacles:
  var nearest=Geometry2D.get_closest_point_to_segment(obstacle.pos,start,finish)
  if nearest.distance_squared_to(obstacle.pos)<pow(float(obstacle.radius)+18,2):return false
 for wall in game.ice_walls:
  var nearest=Geometry2D.get_closest_point_to_segment(wall.pos,start,finish)
  if nearest.distance_squared_to(wall.pos)<48*48:return false
 return true
func setup_geometry()->void:
 bind_battle()
 for kind in Book.load_book().enemies:
  var spec=Book.profile(kind)
  game.enemy_defs[kind]={"name":spec.name,"sprite":kind,"health":spec.health,"damage":spec.damage,"speed":spec.speed,"expansion_only":true,"behaviour":"ranged" if spec.role in ["ranged","healer","summoner","shield"] else "melee"}
 game.field_obstacles.clear()
 # Broad corridors, rounded pillars, clear central landing. Visuals use these exact colliders.
 if game.floor_number<=100:
  for p in [Vector2(540,430),Vector2(1100,330),Vector2(1810,420),Vector2(680,1230),Vector2(1430,1290),Vector2(1990,1110)]:game.field_obstacles.append({"pos":p,"radius":52.0,"kind":"rock"})
 navigation=AStarGrid2D.new();navigation.region=Rect2i(0,0,40,29);navigation.cell_size=Vector2(60,60);navigation.offset=Vector2(30,30);navigation.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;navigation.update()
 for y in 29:
  for x in 40:
   var p=Vector2(x*60+30,y*60+30);var blocked=not game.FIELD.grow(-55).has_point(p)
   for ob in game.field_obstacles:
    if p.distance_to(ob.pos)<float(ob.radius)+51:blocked=true
   navigation.set_point_solid(Vector2i(x,y),blocked)
func floor_start()->void:
 bind_battle();battle.reset()
 warnings.clear();hazards.clear();wheels.clear();fuel_drops.clear();corpses.clear();floor_clock=0;cataclysm=-1
 # Evict the previous floor's sprite textures, keeping memory proportional to the active roster.
 Art.atlases.clear()
 var floor:int=game.floor_number
 if floor==1 or lamp.is_empty():lamp={"holder":"","thief":0,"pos":pack(game.FIELD.size*.5),"fuel":100.0}
 if floor>100:
  lamp.fuel=100;spawn("ds_lava_heart",Vector2(1200,1120));game.status_label.text="BEYOND THE WICK • Floor 100 completed • Defeat the ancient guardian";return
 if floor%5==0:
  var kind=Book.guardian(floor);spawn(kind,Vector2(1200,1120));game.status_label.text="DEPTH %d • %s"%[floor,Book.profile(kind).name]
 else:
  var pool=Book.pool(floor);var count=mini(22,5+floor/4+maxi(0,game.positions.size()-1)*2)
  var rng=RandomNumberGenerator.new();rng.seed=game.floor_seed+floor*157
  for n in count:
   # Deterministic species composition; recent discoveries receive more representation.
   var index=posmod(n+floor,pool.size());var angle=n*TAU/count+.3;var at=game.FIELD.size*.5+Vector2(cos(angle)*860,sin(angle)*580)
   var kind=str(pool[index])
   # Keep mixed original waves while guaranteeing the new late-game roles.
   if floor>=55 and n<mini(4,1+(floor-55)/12):kind=["ds_gloamrunner","ds_craglobber","ds_riftskulk","ds_mirebound"][posmod(n+floor,4)]
   if floor>=70 and n in [5,11]:kind="ds_gloamrunner"
   spawn(kind,safe(at))
  if floor>=50 and (floor-50)%3==0:
   for n in (2 if floor>=80 else 1):spawn("ds_wickcaller",safe(Vector2(300+n*1800,300)))
  game.status_label.text="DEPTH %d • %d cave species discovered • E: carry/place shared lantern"%[floor,pool.size()]
 if floor>=20:
  for n in 4:fuel_drops.append({"pos":pack(safe(Vector2(400+n*510,420+posmod(n,2)*830))),"fuel":28.0})
func spawn(kind:String,at:Vector2)->Dictionary:
 var spec=Book.profile(kind);var health=float(spec.health)*float(scaling(game.floor_number).health)*(1+.55*maxi(0,game.positions.size()-1))
 if spec.rank in ["boss","beyond"]:health*=boss_pressure(game.floor_number)
 if kind=="ds_lava_heart":health=21000*(1+.55*maxi(0,game.positions.size()-1))
 var e={"type":kind,"pos":safe(at),"hp":health,"max_hp":health,"boss":spec.rank!="enemy","uid":randi(),"lane":0,"hit_radius":spec.hit_radius,"depth_boss":true,"name":spec.name,"attack_timer":1.3,"phase":0,"action":"","left":0.0,"total":1.0,"strike":0.0,"gait":0.0,"moving":0.0,"facing":1.0,"hurt":0.0,"nav_at":0.0,"path":PackedVector2Array(),"summoned":0,"dash_left":0.0,"dash_hits":[],"ward":0.0}
 game.opponents.append(e);return e
func shatter(_enemy:Dictionary,_owner:String)->void:pass
func cleared(floor:int)->void:
 if floor<=0 or game.spectating():return
 var bank=mini(100,floor);completed=maxi(completed,bank)
 game.legacy.card.descent_cleared(bank,game.match_party_size);preload("res://scripts/named_records.gd").descent_cleared(game.legacy,bank);game.legacy.save()
func begin_fall()->void:
 if falling():return
 if game.floor_number>100:game.end_match("Floor 100 and the Unquenchable conquered • Ancient depths cleared");return
 cleared(game.floor_number);fall_time=0;fall_swapped=false
 if not preload("res://scripts/profile_store.gd").progression_blocked() and not game.spectating():
  game.best_floor=maxi(game.best_floor,mini(100,game.floor_number))
  var f=FileAccess.open(game.best_path,FileAccess.WRITE)
  if f!=null:f.store_string(JSON.stringify({"best":game.best_floor}));f.close()
 warnings.clear();hazards.clear();wheels.clear();game.missiles.clear();game.adventure.combat.projectiles.clear()
 if game.get("server_actions")!=null:
  for id in game.server_actions:game.server_actions[id]=[]
 if game.get("server_inputs")!=null:
  for id in game.server_inputs:game.server_inputs[id]=[]
func step_transition(delta:float)->void:
 if not falling():return
 if game.role!="host":fall_time=minf(3.1,fall_time+delta);return
 fall_time+=delta
 if fall_time>=1.85 and not fall_swapped:
  var fallen=game.downed.duplicate(true)
  fall_swapped=true;game.floor_number+=1;game._make_floor();game.downed=fallen
  for id in game.positions:
   game.positions[id]=safe(game.FIELD.size*.5+Vector2((game._slot(str(id))-(game.positions.size()-1)*.5)*64,40))
   game.invincible_until[id]=Time.get_ticks_msec()+1500
   if game.get("player_epochs")!=null:game.player_epochs[id]=int(game.player_epochs.get(id,0))+1
  game.local_pos=game.positions.get(game.my_id,game.FIELD.size*.5)
  if game.get("dedicated")!=true:
   if game.get("local_view")!=null:game.local_view.reset(game.local_pos)
   if game.media!=null and game.media.game!=null:game.media.refresh_arcade()
   else:game.assign_base_camera()
   if game.terrain_cache!=null:game.terrain_cache.sync()
  if str(lamp.get("holder","")).is_empty() or int(game.health.get(str(lamp.holder),0))<=0:drop_lamp(game.FIELD.size*.5)
  lamp.fuel=maxf(35,float(lamp.fuel))
 if fall_time>=3.1:fall_time=-1;fall_swapped=false
func receive_damage(e:Dictionary,amount:float)->float:
 if falling():return 0.0
 return battle.damage(e,amount*(.4 if float(e.get("ward",0))>0 else 1.0))
func struck(e:Dictionary)->void:
 e.hurt=.13
 if int(battle.call.get("owner",0))==int(e.uid):battle.cancel_call("Lantern ritual interrupted by a hit")
func defeated(e:Dictionary)->void:
 battle.remove_owner(int(e.uid))
 if int(lamp.get("thief",0))==int(e.uid):drop_lamp(e.pos)
 warnings=warnings.filter(func(w):return int(w.owner)!=int(e.uid))
 var corpse=e.duplicate(true);corpse.collapse=0.01;corpses.append(corpse)
 if corpses.size()>12:corpses.pop_front()
 if game.floor_number>=60 and game.floor_number<=100 and str(e.type) in ["ds_mender","ds_larva","ds_caller","ds_totem"] and fuel_drops.size()<10:fuel_drops.append({"pos":pack(e.pos),"fuel":18.0})
func nearest(e:Dictionary)->String:
 var result="";var best=INF
 for id in game.positions:
  if int(game.health.get(id,0))<=0:continue
  var d=(game.positions[id] as Vector2).distance_squared_to(e.pos)
  if d<best:best=d;result=str(id)
 return result
func tile(p:Vector2)->Vector2i:return Vector2i(clampi(int(p.x/60),1,38),clampi(int(p.y/60),1,27))
func open_tile(p:Vector2)->Vector2i:
 var at=tile(p)
 if not navigation.is_point_solid(at):return at
 for ring in range(1,12):
  for y in range(-ring,ring+1):
   for x in range(-ring,ring+1):
    var candidate=at+Vector2i(x,y)
    if navigation.region.has_point(candidate) and not navigation.is_point_solid(candidate):return candidate
 return Vector2i(20,14)
func walk_to(e:Dictionary,goal:Vector2,delta:float,speed:float)->void:
 var origin:Vector2=e.pos;var dir=(goal-origin).normalized()
 if not game._clear_path(origin,goal):
  if clock>=float(e.nav_at) or (point(e.get("nav_goal",pack(goal)))).distance_to(goal)>150:
   e.nav_at=clock+.7+float(posmod(int(e.uid),7))*.07;e.nav_goal=pack(goal)
   var from=tile(origin);var dest=tile(safe(goal))
   if navigation.is_point_solid(from):from=open_tile(origin)
   if navigation.is_point_solid(dest):dest=open_tile(goal)
   e.path=navigation.get_point_path(from,dest)
  var route:PackedVector2Array=e.path
  while not route.is_empty() and origin.distance_to(route[0])<38:route.remove_at(0)
  e.path=route
  if not route.is_empty():dir=(route[0]-origin).normalized()
 else:e.path=PackedVector2Array()
 # Physical separation makes ranged firing positions remain distinct.
 var separate=Vector2.ZERO
 for other in game.opponents:
  if int(other.uid)==int(e.uid):continue
  var offset:Vector2=origin-other.pos;var distance=offset.length()
  if distance<65 and distance>0:separate+=offset.normalized()*(1-distance/65)*.65
 dir=(dir+separate).limit_length(1)
 e.pos=game._move_actor(origin,dir*speed*delta*game.adventure.combat.speed_factor(game.adventure.combat.npc_key(e)))
 var travelled=origin.distance_to(e.pos);e.moving=travelled/maxf(.001,delta);e.gait=float(e.gait)+travelled*.12
 if travelled>.1:e.facing=-1 if e.pos.x<origin.x else 1
 if travelled<.1:e.nav_at=0
func step(delta:float)->void:
 bind_battle()
 if game.mode!="descent" or not game.started:return
 clock+=delta
 if falling():return
 for i in range(corpses.size()-1,-1,-1):
  corpses[i].collapse=float(corpses[i].collapse)+delta*1.8
  if float(corpses[i].collapse)>=1:corpses.remove_at(i)
 if game.role!="host":return
 floor_clock+=delta
 var holder=str(lamp.get("holder",""))
 if not holder.is_empty() and (not game.positions.has(holder) or int(game.health.get(holder,0))<=0):drop_lamp(lamp_pos())
 if int(lamp.get("thief",0))!=0 and not game.opponents.any(func(e):return int(e.uid)==int(lamp.thief)):drop_lamp(lamp_pos())
 if game.floor_number>=20:
  lamp.fuel=maxf(0,float(lamp.fuel)-delta*fuel_rate(game.floor_number))
  for i in range(fuel_drops.size()-1,-1,-1):
   for id in game.positions:
    if int(game.health.get(id,0))>0 and (game.positions[id] as Vector2).distance_to(point(fuel_drops[i].pos))<48:
     lamp.fuel=minf(100,float(lamp.fuel)+float(fuel_drops[i].fuel));fuel_drops.remove_at(i);break
 battle.step(delta)
 for e in game.opponents.duplicate():
  var spec=Book.profile(str(e.type))
  if spec.is_empty():continue
  e.hurt=maxf(0,float(e.hurt)-delta);e.strike=maxf(0,float(e.strike)-delta);e.ward=maxf(0,float(e.ward)-delta)
  if game.adventure.combat.stunned(game.adventure.combat.npc_key(e)):e.moving=0;continue
  var target=nearest(e)
  if target.is_empty():continue
  var goal:Vector2=game.adventure.combat.fern.redirect(e,game.positions[target]);var distance=(e.pos as Vector2).distance_to(goal)
  if float(e.dash_left)>0:
   var before:Vector2=e.pos;e.dash_left=float(e.dash_left)-delta;e.pos=game._move_actor(e.pos,point(e.dash_dir)*580*delta)
   for id in game.positions:
    if int(game.health.get(id,0))<=0 or id in e.dash_hits:continue
    if Geometry2D.get_closest_point_to_segment(game.positions[id],before,e.pos).distance_to(game.positions[id])<48:
     e.dash_hits.append(id);hurt(str(id),float(spec.damage)*1.25,e,"Rush");knock(str(id))
   e.moving=200;e.gait=float(e.gait)+delta*15;continue
  if float(e.get("return_ward",0))>0:continue
  if battle.full(e) and not battle.events.is_empty():e.moving=0;continue
  if not str(e.action).is_empty():
   e.left=float(e.left)-delta;e.moving=0
   if float(e.left)<=0:
    execute(e,str(e.action),point(e.aim),target);e.action="";e.strike=.3
   continue
  var speed=float(spec.speed)*float(scaling(game.floor_number).speed)
  if battle.enemy_step(e,target,goal,delta):continue
  if spec.role=="berserker" and float(e.hp)<float(e.max_hp)*.45:speed*=1.4
  if int(lamp.get("thief",0))==int(e.uid):
   var retreat=point(e.get("lantern_retreat",pack(Vector2(230,230) if int(e.uid)%2==0 else game.FIELD.size-Vector2(230,230))))
   if (e.pos as Vector2).distance_to(retreat)<80:retreat=game.FIELD.size-retreat
   e.lantern_retreat=pack(retreat)
   walk_to(e,retreat,delta,speed*(.88 if str(e.type)=="ds_gloamrunner" else .95));lamp.pos=pack(e.pos);continue
  if spec.role=="thief" and int(lamp.get("thief",0))==0 and clock>float(interact_at.get("protection",0)):
   goal=lamp_pos();distance=(e.pos as Vector2).distance_to(goal)
   if distance<44 and segment_clear(e.pos,goal):
    lamp.holder="";lamp.thief=int(e.uid);lamp.pos=pack(e.pos);e.erase("lantern_retreat")
    game.status_label.text="A cave thief has your lantern! Defeat it, then E to retrieve it.";continue
   # A lantern grab is not a melee attack: close the old48–65px dead zone.
   walk_to(e,goal,delta,speed);continue
  var ranged=spec.role in ["ranged","healer","summoner","guardian","shield"]
  if ranged:
   var angle=float(posmod(int(e.uid),24))*TAU/24
   var anchor=goal+Vector2.from_angle(angle)*(260+posmod(int(e.uid),4)*35)
   if distance<170:anchor=e.pos+(e.pos-goal).normalized()*170
   if (e.pos as Vector2).distance_to(anchor)>40:walk_to(e,safe(anchor),delta,speed)
   else:e.moving=0
  elif distance>65:walk_to(e,goal,delta,speed)
  else:e.moving=0
  e.attack_timer=float(e.attack_timer)-delta
  if float(e.attack_timer)>0:continue
  var attacks:Array=spec.attacks
  if battle.full(e):
   var added=battle.LAVA if game.floor_number>100 else battle.FINAL if game.floor_number==100 else battle.LOCALS
   attacks=attacks+added
  elif float(spec.speed)<=67:attacks=attacks+["homing"]
  var style=str(attacks[int(e.phase)%attacks.size()]);e.phase=int(e.phase)+1
  if spec.rank=="enemy" and float(spec.speed)<=67 and style in ["bolt","fan","volley"]:style="homing"
  if str(e.type)=="ds_craglobber":style="boulder"
  if style in ["bite","slam","sweep","pincer","sting","steal"] and distance>150:e.attack_timer=.3;continue
  if not game._clear_path(e.pos,goal) and style in ["bolt","fan","volley","beam","drain","web","boomerang","chain"]:e.attack_timer=.4;continue
  var tell=1.1 if spec.rank!="enemy" else .65
  if style in ["boulder","homing","shard_lances","pursuit_orbs","magma_lances","cinder_orbs"]:tell=1.15
  if style=="boulder":goal=battle.predict(target,.4)
  if style in ["charge","slam","meteor","firewheel","beam"]:tell+=.3
  e.action=style;e.total=tell;e.left=tell;e.aim=pack(goal)
  e.attack_timer=(1.7 if battle.full(e) else 2.5 if spec.rank!="enemy" else 2.1)/float(scaling(game.floor_number).pace)
  if warnings.size()<35:warnings.append({"kind":style,"from":pack(e.pos),"pos":pack(goal),"left":tell,"total":tell,"owner":e.uid,"color":spec.color})
 for i in range(warnings.size()-1,-1,-1):
  warnings[i].left=float(warnings[i].left)-delta
  if float(warnings[i].left)<=0:warnings.remove_at(i)
 for i in range(hazards.size()-1,-1,-1):
  var h=hazards[i];h.left=float(h.left)-delta;h.tick=float(h.tick)-delta
  if h.left<=0:hazards.remove_at(i);continue
  if h.tick>0:continue
  h.tick=.8
  for id in game.positions:
   var pos:Vector2=game.positions[id]
   if int(game.health.get(id,0))<=0 or pos.distance_to(point(h.pos))>float(h.radius):continue
   hurt(str(id),float(h.damage),{},str(h.kind))
   if h.kind in ["web","spores","prison","trail"]:game.adventure.combat.apply_status(game.adventure.combat.player_key(str(id)),"slow",1.2,"enemy",.72)
   if h.kind=="pull":game.positions[id]=game._move_actor(pos,(point(h.pos)-pos).normalized()*60)
 for i in range(wheels.size()-1,-1,-1):
  var w=wheels[i];w.left=float(w.left)-delta;var old=point(w.pos);var dir=point(w.dir);var next=game._move_actor(old,dir*210*delta)
  if next.distance_to(old)<delta*60:dir=dir.rotated(PI*.7);w.dir=pack(dir)
  w.pos=pack(next)
  if w.left<=0:wheels.remove_at(i);continue
  for id in game.positions:
   if int(game.health.get(id,0))>0 and (game.positions[id] as Vector2).distance_to(next)<46 and clock>float(w.hits.get(id,0)):
    w.hits[id]=clock+.8;hurt(str(id),float(w.damage),{},"Fire wheel")
func hurt(id:String,damage:float,e:Dictionary,label:String)->void:
 game._hurt(id,damage,"enemy","",preload("res://scripts/defeat_credit.gd").resolve(game,"e:"+str(e.get("uid",0)),label))
func knock(id:String)->void:
 if str(lamp.get("holder",""))==id and clock>float(interact_at.get("protection",0)):drop_lamp(game.positions[id])
func zone(at:Vector2,radius:float,damage:float,kind:String,color:String,duration:float=4)->void:
 if hazards.size()<24:hazards.append({"pos":pack(at),"radius":radius,"damage":damage,"kind":kind,"color":color,"left":duration,"tick":0.0})
func execute(e:Dictionary,style:String,aim_at:Vector2,target:String)->void:
 if battle.execute(e,style,aim_at,target):return
 var spec=Book.profile(str(e.type));var origin:Vector2=e.pos;var aim=(aim_at-origin).normalized();var damage=float(spec.damage);var color=str(spec.color)
 match style:
  "cataclysm":
   if game.floor_number>100 and cataclysm<0:
    e.hp=e.max_hp;cataclysm=3.8;game.status_label.text="THE UNQUENCHABLE REKINDLES • Floor 100 is already completed"
  "charge","burrow":
   e.dash_left=.8;e.dash_dir=pack(aim);e.dash_hits=[]
  "heal":
   for ally in game.opponents:
    if (ally.pos as Vector2).distance_to(origin)<340:ally.hp=minf(float(ally.max_hp),float(ally.hp)+float(ally.max_hp)*.09)
   game._emit_effect({"pos":origin,"radius":180,"time":.5,"color":"#98d9ad"})
  "ward":e.ward=2.8
  "summon":
   if game.opponents.size()<22 and int(e.summoned)<6:
    e.summoned=int(e.summoned)+2
    for side in [-1,1]:spawn("ds_nibbler" if game.floor_number<40 else "ds_spider",safe(origin+Vector2(side*85,50)))
  "firewheel":
   for n in (3 if game.floor_number<80 else 5):
    if wheels.size()>=8:break
    var dir=Vector2.from_angle(n*TAU/5+clock);wheels.append({"pos":pack(origin+dir*50),"dir":pack(dir),"left":7.0,"damage":damage,"hits":{}})
  "web","spores","trail","prison","pull":zone(aim_at if style!="pull" else origin,120 if style!="pull" else 290,damage*.4,style,color,4.5)
  "quake","meteor","pulse","ring":
   var p=aim_at if style=="meteor" else origin
   for id in game.positions:
    if int(game.health.get(id,0))<=0:continue
    var d=(game.positions[id] as Vector2).distance_to(p)
    if (d>150 and d<245) if style=="ring" else d<(110 if style=="meteor" else 240):hurt(str(id),damage,e,style.capitalize())
   game._emit_effect({"pos":p,"radius":240 if style!="meteor" else 110,"time":.5,"color":color})
  "bite","slam","sweep","pincer","sting","steal":
   for id in game.positions:
    if int(game.health.get(id,0))<=0:continue
    var offset:Vector2=game.positions[id]-origin
    if offset.length()<150 and offset.normalized().dot(aim)>.1 and game._clear_path(origin,game.positions[id]):
     hurt(str(id),damage,e,style.capitalize())
     if style=="sting":game.adventure.combat.apply_status(game.adventure.combat.player_key(str(id)),"poison",3,"enemy",2)
     if style=="slam":knock(str(id))
     if style=="steal" and str(lamp.get("holder",""))==str(id) and clock>float(interact_at.get("protection",0)):lamp.holder="";lamp.thief=int(e.uid);lamp.pos=pack(e.pos)
   game._emit_effect({"pos":origin+aim*60,"radius":65,"time":.25,"color":color})
  _:
   var count=12 if style=="burst" else 7 if style in ["fan","volley"] else 3 if style in ["boomerang","chain"] else 1
   for n in count:
    var dir=Vector2.from_angle(n*TAU/count+clock) if style=="burst" else aim.rotated((n-(count-1)*.5)*.18)
    var stats={"range":1000,"speed":280 if style!="beam" else 480,"projectile_radius":8 if style!="beam" else 14,"color":color}
    var projectile_style="echo_bolt" if style=="boomerang" else "ricochet_projectile" if style=="chain" else "pellet"
    stats["descent_visual"]=str(spec.form);stats["name"]=str(spec.name)+" • "+style.capitalize()
    if style=="boomerang":stats["return_at"]=240;stats["range"]=500
    if style=="chain":stats["bounces"]=2;stats["bounce_range"]=240
    if style=="drain":stats["slow_factor"]=.75;stats["slow_duration"]=2.0
    game.adventure.combat.launch_projectile("enemy",origin,dir,stats,damage,projectile_style)
func snapshot()->Dictionary:
 bind_battle()
 var sent_corpses:Array=[]
 for e in corpses:sent_corpses.append({"type":str(e.type),"pos":pack(e.pos),"collapse":float(e.collapse),"gait":float(e.gait),"facing":float(e.facing),"moving":0.0})
 return {"battle251":battle.snapshot(),"corpses":sent_corpses,"boosts":boosts,"pending":pending,"warnings":warnings,"hazards":hazards,"wheels":wheels,"fuel_drops":fuel_drops,"lamp":lamp,"clock":clock,"floor_clock":floor_clock,"fall_time":fall_time,"fall_swapped":fall_swapped,"completed":completed,"cataclysm":cataclysm}
func receive(value:Dictionary)->void:
 bind_battle();battle.receive(value.get("battle251",{}))
 if game.mode=="descent" and game.role=="guest" and int(value.get("completed",0))>completed:cleared(int(value.completed))
 corpses.clear()
 for e in value.get("corpses",[]):
  var copy=e.duplicate(true);copy.pos=point(e.pos);corpses.append(copy)
 boosts=value.get("boosts",{});pending=value.get("pending",{});warnings=value.get("warnings",[]);hazards=value.get("hazards",[]);wheels=value.get("wheels",[]);fuel_drops=value.get("fuel_drops",[]);lamp=value.get("lamp",{});clock=float(value.get("clock",clock));floor_clock=float(value.get("floor_clock",0));fall_time=float(value.get("fall_time",-1));fall_swapped=bool(value.get("fall_swapped",false));completed=int(value.get("completed",0));cataclysm=float(value.get("cataclysm",-1))
func draw(c:Node2D,camera:Vector2)->void:
 if game.mode!="descent" or not game.started:return
 if game.floor_number>100:
  # Incandescent rivers reveal a bright volcanic cavern beneath the dark strata.
  for n in 3:
   var centre=200+n*850
   for layer in 3:
    var width=[82,63,34][layer];var left=PackedVector2Array();var right=PackedVector2Array()
    for k in 20:
     var y=-120+k*105;var x=centre+sin(k*.55+n)*70;var bank=1+sin(k*1.9)*.1
     left.append(Vector2(x-width*bank,y)-camera);right.append(Vector2(x+width*bank,y)-camera)
    # Same banks and channel widths, textured in culled segment quads.
    var flow=preload("res://scripts/descent_map251.gd").texture("lava_flow")
    for k in range(left.size()-1):
     var quad=PackedVector2Array([left[k],right[k],right[k+1],left[k+1]])
     if not Rect2(Vector2.ZERO,game.VIEW).grow(180).has_point((left[k]+right[k])*.5):continue
     if layer==0:c.draw_colored_polygon(quad,Color("#493b40"))
     else:c.draw_polygon(quad,PackedColorArray([Color("#bd885a") if layer==1 else Color.WHITE]),PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,1)]),flow)
   for k in 15:
    var y=-120+k*135;var x=centre+sin(k*.7+n)*70
    var at=Vector2(x+sin(clock+k)*12,y)-camera
    c.draw_arc(at,9+sin(clock*2+k)*3,.3,PI*1.6,12,Color("#ffe8a4"),2,true)
    if k%2==0:c.draw_line(at-Vector2(10,3),at+Vector2(12,sin(clock+k)*5),Color("#e57432"),4,true)
 if falling():draw_fracture(c)
 for h in hazards:
  var p=point(h.pos)-camera;var tint=Color(str(h.color),.22)
  c.draw_circle(p,float(h.radius),tint)
  for n in 7:
   var dir=Vector2.from_angle(n*TAU/7+clock*.4);c.draw_line(p+dir*float(h.radius)*.2,p+dir*float(h.radius)*.8,Color(str(h.color),.5),2,true)
 for w in warnings:
  var p=point(w.pos)-camera;var start=point(w.from)-camera;var tint=Color(str(w.color),.6);var alpha=1-float(w.left)/maxf(.01,float(w.total))
  if w.kind in ["charge","burrow","beam","bolt","fan","volley","drain","boomerang","chain","homing","boulder","shard_lances","magma_lances","pursuit_orbs","cinder_orbs"]:
   var end=start+(p-start).normalized()*(500 if w.kind in ["charge","burrow","beam"] else 270)
   c.draw_line(start,end,Color(tint,.12+alpha*.15),28 if w.kind=="beam" else 50,true);c.draw_line(start,end,tint,2,true)
   if w.kind=="boulder":c.draw_arc(p,145,0,TAU,40,tint,2,true)
  else:
   var at=p if w.kind in ["web","spores","meteor","prison"] else start
   for n in 6:
    var dir=Vector2.from_angle(n*TAU/6+.3);var radius=110 if w.kind=="meteor" else 150
    c.draw_line(at+dir*25,at+dir*radius,tint,2+alpha*2,true)
 for w in wheels:
  var at=point(w.pos)-camera
  for n in 7:
   var dir=Vector2.from_angle(n*TAU/7+clock*6);c.draw_line(at+dir*10,at+dir*30,Color("#f8b45e"),7,true)
  c.draw_arc(at,22,0,TAU,24,Color("#f6d592"),3,true)
 for f in fuel_drops:
  var at=point(f.pos)-camera;c.draw_rect(Rect2(at-Vector2(8,10),Vector2(16,20)),Color("#bd9362"));c.draw_line(at-Vector2(0,8),at+Vector2(0,8),Color("#ffe19b"),4,true)
 for corpse in corpses:draw_boss(c,corpse,corpse.pos-camera)
func visual_size(e:Dictionary)->Vector2:
 var spec=Book.profile(str(e.type))
 if spec.is_empty():return Vector2(52,58)
 return Vector2(float(spec.cell[0]),float(spec.cell[1]))*float(spec.get("art_scale",1))
func health_bar_y(e:Dictionary)->float:
 var spec=Book.profile(str(e.type))
 return float(spec.get("bar_y",-56))
func draw_boss(c:Node2D,e:Dictionary,p:Vector2)->void:
 var spec=Book.profile(str(e.type))
 if spec.is_empty():return
 if str(e.type)=="ds_mirebound":c.draw_arc(p,175,0,TAU,40,Color("#baabd1",.45),2,true)
 var alpha=.35 if float(e.get("hidden_until",0))>clock else 1.0
 if str(e.action)=="leap":
  var t=smoothstep(.55,1,1-float(e.left)/maxf(.01,float(e.total)));p=p.lerp(p+point(e.aim)-e.pos,t)-Vector2(0,sin(t*PI)*110)
 if float(e.get("hidden_until",0))>clock:c.draw_arc(p,29,0,TAU,24,Color("#b9a2ca",.5),1,true)
 var art=e.duplicate();art.merge(spec,false);art.kind=str(e.type);art.pos=p;art.color=spec.color;art.cell=spec.cell
 Art.enemy(c,art,clock,alpha*(1-float(e.get("collapse",0))))
 if bool(e.get("boss",false)):
  c.draw_string(ThemeDB.fallback_font,p+Vector2(-150,health_bar_y(e)-12),str(spec.name),HORIZONTAL_ALIGNMENT_CENTER,300,15,Color("#eadbb9"))
func make_darkness()->void:
 var image=Image.create(256,256,false,Image.FORMAT_RGBA8)
 for y in 256:
  for x in 256:
   var d=Vector2(x-127.5,y-127.5).length()/127.5
   image.set_pixel(x,y,Color(.018,.023,.032,smoothstep(.28,1,d)))
 darkness=ImageTexture.create_from_image(image)
 lamp_texture=preload("res://scripts/cast_art232.gd").prop("lantern0")
static func edge_factor(world:Vector2,field:Rect2)->float:
 var normalized=(world-field.get_center())/(field.size*.5)
 return smoothstep(.3,1.2,normalized.length())
static func depth_opacity(floor:int,world:Vector2,field:Rect2)->float:
 if floor<1 or floor>100:return 0.0
 return clampf((floor-1+EDGE_PREVIEW_FLOORS*edge_factor(world,field))/26.0,0,1)*.97
func ensure_room_darkness()->void:
 if room_darkness!=null and room_darkness_floor==game.floor_number and room_darkness_field==game.FIELD:return
 room_darkness_floor=game.floor_number;room_darkness_field=game.FIELD
 var image=Image.create(128,96,false,Image.FORMAT_RGBA8)
 for y in 96:
  for x in 128:
   var world=game.FIELD.position+game.FIELD.size*Vector2(float(x)/127,float(y)/95)
   image.set_pixel(x,y,Color(.018,.023,.032,depth_opacity(game.floor_number,world,game.FIELD)))
 room_darkness=ImageTexture.create_from_image(image)
func draw_room_rect(c:Node2D,rect:Rect2,camera:Vector2)->void:
 if rect.size.x<=0 or rect.size.y<=0:return
 var tex_size=Vector2(room_darkness.get_size())
 var source=Rect2((rect.position+camera-game.FIELD.position)/game.FIELD.size*tex_size,rect.size/game.FIELD.size*tex_size)
 c.draw_texture_rect_region(room_darkness,rect,source,Color.WHITE,false,false)
func prepare_light_grid()->void:
 if not light_uvs.is_empty():return
 for y in range(LIGHT_GRID+1):
  for x in range(LIGHT_GRID+1):light_uvs.append(Vector2(float(x)/LIGHT_GRID,float(y)/LIGHT_GRID))
 for y in LIGHT_GRID:
  for x in LIGHT_GRID:
   var a=y*(LIGHT_GRID+1)+x;var b=a+1;var d=a+LIGHT_GRID+1;var e=d+1
   light_indices.append_array(PackedInt32Array([a,b,e,a,e,d]))
func draw_darkness(c:Node2D,camera:Vector2)->void:
 if game.mode!="descent" or not game.started:return
 if darkness==null:make_darkness()
 var world=lamp_pos();var at=world-camera;var fuel=float(lamp.get("fuel",100));var radius=(310.0 if str(lamp.get("holder","")).is_empty() and int(lamp.get("thief",0))==0 else 248.0)*(0.42+.58*minf(1,fuel/30))
 if game.floor_number<=100:
  ensure_room_darkness()
  var left=clampf(at.x-radius,0,game.VIEW.x);var right=clampf(at.x+radius,0,game.VIEW.x);var top=clampf(at.y-radius,0,game.VIEW.y);var bottom=clampf(at.y+radius,0,game.VIEW.y)
  draw_room_rect(c,Rect2(0,0,left,game.VIEW.y),camera);draw_room_rect(c,Rect2(right,0,maxf(0,game.VIEW.x-right),game.VIEW.y),camera)
  draw_room_rect(c,Rect2(left,0,maxf(0,right-left),top),camera);draw_room_rect(c,Rect2(left,bottom,maxf(0,right-left),maxf(0,game.VIEW.y-bottom)),camera)
  # One81-vertex batch modulates the original smooth lantern mask. No extra
  # viewport, dynamic lights or per-frame image creation; HUD draws afterwards.
  prepare_light_grid()
  var vertices=PackedVector2Array();var colors=PackedColorArray()
  for uv in light_uvs:
   var offset=(uv*2-Vector2.ONE)*radius
   vertices.append(at+offset);colors.append(Color(1,1,1,depth_opacity(game.floor_number,world+offset,game.FIELD)))
  RenderingServer.canvas_item_add_triangle_array(c.get_canvas_item(),light_indices,vertices,colors,light_uvs,PackedInt32Array(),PackedFloat32Array(),darkness.get_rid())
 if lamp_texture!=null:
  var lamp_frame=2 if fuel<30 else posmod(int(clock*5),2)
  preload("res://scripts/cast_art232.gd").draw_prop(c,"lantern"+str(lamp_frame),Rect2(at-Vector2(11,34+sin(clock*5)),Vector2(22,36)))
func hero_rect(rect:Rect2)->Rect2:
 if not falling():return rect
 var t=clampf((fall_time-.65)/1.05,0,1) if not fall_swapped else 1-clampf((fall_time-2.1)/.65,0,1)
 var centre=rect.get_center();rect.size*=1-.78*t;rect.position=centre-rect.size*.5+Vector2(0,t*t*160);return rect
func draw_overlay(c:Node2D)->void:
 if game.mode!="descent" or not game.started:return
 var text="Shared lantern • E: carry / place • wider light when placed"
 if game.floor_number>=20:text+=" • Fuel %d%%"%int(lamp.get("fuel",100))
 if game.floor_number>100:text="FLOOR 100 COMPLETE • Bonus battle: The Unquenchable"
 c.draw_string(ThemeDB.fallback_font,Vector2(25,164 if game.opponents.any(func(e):return bool(e.get("boss",false))) else 112),text,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e7cd94"))
 var direction=lamp_pos()-game.local_pos
 if direction.length()>220 and game.floor_number>10:
  var at=game.VIEW*.5+direction.normalized()*minf(game.VIEW.x,game.VIEW.y)*.32
  c.draw_line(at-direction.normalized()*12,at+direction.normalized()*10,Color("#f9d48c"),3,true)
  c.draw_circle(at+direction.normalized()*12,4,Color("#ffe6a0"))
 if cataclysm>0:c.draw_string(ThemeDB.fallback_font,game.VIEW*.5-Vector2(275,150),"THE UNQUENCHABLE REKINDLES",HORIZONTAL_ALIGNMENT_CENTER,550,27,Color("#ffe0a5"))
 if not falling():return
 var centre=game.VIEW*.5;var t=clampf(fall_time/.8,0,1)
 var fade=clampf((fall_time-1.1)/.65,0,1) if not fall_swapped else 1-clampf((fall_time-2.05)/1.05,0,1)
 c.draw_rect(Rect2(Vector2.ZERO,game.VIEW),Color(.02,.024,.031,fade))
 if fade>.55:c.draw_string(ThemeDB.fallback_font,centre-Vector2(180,0),"DESCENDING • "+str(game.floor_number+ (0 if fall_swapped else 1)),HORIZONTAL_ALIGNMENT_CENTER,360,28,Color(1,.85,.61,fade))

func draw_fracture(c:Node2D)->void:
 if fall_swapped:return
 var centre=game.local_pos-game.camera
 var crack=clampf(fall_time/.85,0,1);var fall=clampf((fall_time-.45)/1.25,0,1)
 var hole=PackedVector2Array()
 for n in 28:
  var angle=n*TAU/28;var radius=(18+fall*fall*game.VIEW.length()*.65)*(1+.13*sin(n*4.3))
  hole.append(centre+Vector2.from_angle(angle)*radius)
 c.draw_colored_polygon(hole,Color("#101116"))
 for n in 9:
  var angle=n*TAU/9+.17;var dir=Vector2.from_angle(angle);var side=dir.orthogonal()
  var reach=(200+float(posmod(n*83,250)))*crack
  var base=centre+dir*(25+fall*110)
  var points=PackedVector2Array([base,base+dir*reach*.23+side*(8+sin(n)*11),base+dir*reach*.49-side*12,base+dir*reach*.73+side*17,base+dir*reach])
  c.draw_polyline(points,Color(.08,.07,.065,.9),1+crack*3,true)
  c.draw_polyline(points,Color(.33,.27,.20,.6),1,true)
  c.draw_line(points[2],points[2]+dir.rotated(.65)*reach*.24,Color(.08,.07,.065,.85),1.8,true)
  if fall>.05:
   # Angular pieces have individual offsets, widths, depth faces and gravity.
   var delay=float(posmod(n*7,5))*.025;var amount=maxf(0,fall-delay)
   var at=centre+dir*(95+amount*230+sin(n*3.1)*24)+Vector2(0,amount*amount*270)
   var size=(1-amount)*(31+float(posmod(n*19,31)))
   var local=PackedVector2Array([Vector2(-size,-size*.35),Vector2(-size*.2,-size*.8),Vector2(size*.7,-size*.4),Vector2(size,size*.45),Vector2(-size*.65,size*.6)])
   var top=PackedVector2Array();var face=PackedVector2Array()
   for vertex in local:
    top.append(at+vertex.rotated(amount*(.5 if n%2 else -.7)));face.append(top[-1]+Vector2(0,8*(1-amount)))
   c.draw_colored_polygon(face,Color(.18,.15,.13,1-amount));c.draw_colored_polygon(top,Color(.53,.46,.35,1-amount))
   c.draw_line(top[0],top[1],Color(.78,.67,.49,1-amount),1.2,true)
   for mote in 3:
    var dust=at+Vector2(sin(n+mote*3.1)*size,cos(n*2+mote)*size)+Vector2(0,-amount*70)
    c.draw_circle(dust,2+amount*8,Color(.65,.56,.41,(1-amount)*.2))
