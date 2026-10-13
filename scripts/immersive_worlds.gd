extends Node
## Authored walkable geometry, route-aware defenders, environmental overlays and a shared raft.
var grass_art:Array[Texture2D]=[preload("res://scripts/source_art.gd").texture("res://assets/tall_grass_v67_0.svg"),preload("res://scripts/source_art.gd").texture("res://assets/tall_grass_v67_1.svg"),preload("res://scripts/source_art.gd").texture("res://assets/tall_grass_v67_2.svg"),preload("res://scripts/source_art.gd").texture("res://assets/tall_grass_v67_3.svg")]
var grass_draws:=0
var floor_geometry:Array=[]
var solid_bins:Dictionary={}
var floor_layers:Array=[]
var adventure:Node
var active:=false
var data:Dictionary={}
var initialized:=false
var stage:=0
var boss_live:=false
var done:=false
var clock:=0.0
var grid:AStarGrid2D
var routes:Dictionary={}
var beams:Array=[]
var attacks:Array=[]
var used:Dictionary={}
var boat:Dictionary={}
var textures:Dictionary={}
var arrow_route:=PackedVector2Array()
var arrow_until:=0.0
const IDS=["honeyglass","sunfield","lantern_marsh","silverfall","petalbrook"]
const NEW_TYPES=["sunbeam_cantor","petal_ducker","briar_tail","nectar_keeper","bloomtail_regent","saffron_hopper","silk_spinner","dewcap_guard"]
func v(p:Array)->Vector2:return Vector2(float(p[0]),float(p[1]))
func a(p:Vector2)->Array:return [p.x,p.y]
func r(p:Array)->Rect2:return Rect2(float(p[0]),float(p[1]),float(p[2]),float(p[3]))
func polygon(p:Array)->PackedVector2Array:
 var points:=PackedVector2Array()
 for point in p:points.append(v(point))
 return points
func setup(id:String)->void:
 for layer in floor_layers:layer.queue_free()
 floor_layers.clear();floor_geometry.clear();solid_bins.clear()
 arrow_route.clear();arrow_until=0
 active=id in IDS;data={};initialized=false;stage=0;boss_live=false;done=false;clock=0;routes.clear();beams.clear();attacks.clear();used.clear();boat.clear();grid=null
 if not active:return
 data=JSON.parse_string(FileAccess.get_file_as_string("res://content/campaigns/"+id+"_paths.json"))
 for kind in ["grand_tree","moss_tree","giant_flower","treehouse"]:textures[kind]=load("res://assets/v50_"+kind+".png")
 textures.honey_lamp=load("res://assets/honey_lamp.png")
 textures.floor=load("res://assets/garden_grass.png")
 textures.path=load("res://assets/path.png")
 for floor in data.floors:
  floor_geometry.append({"bounds":floor_bounds(floor),"polygon":polygon(floor.poly) if floor.has("poly") else PackedVector2Array(),"rect":floor.has("rect")})
 for prop in data.get("props",[]):
  if float(prop.solid)<=0:continue
  var point:=v(prop.pos);var radius:=float(prop.solid)+16
  for x in range(floori((point.x-radius)/256),floori((point.x+radius)/256)+1):
   for y in range(floori((point.y-radius)/256),floori((point.y+radius)/256)+1):
    var key:=Vector2i(x,y)
    if not solid_bins.has(key):solid_bins[key]=[]
    solid_bins[key].append({"pos":point,"radius":radius})
 if not data.raft.is_empty():boat={"pos":data.raft.docks[0].duplicate(),"dock":0,"moving":false,"passengers":[],"progress":0.0,"boarding":0.0}
 grid=AStarGrid2D.new();grid.region=Rect2i(0,0,ceili(float(data.size[0])/60),ceili(float(data.size[1])/60));grid.cell_size=Vector2(60,60);grid.offset=Vector2(30,30);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
 rebuild_grid()
func rebuild_grid()->void:
 for x in grid.region.size.x:
  for y in grid.region.size.y:grid.set_point_solid(Vector2i(x,y),not can_stand(Vector2(x*60+30,y*60+30)))
 routes.clear()
func floor_at(point:Vector2)->bool:
 for floor in floor_geometry:
  if not floor.bounds.has_point(point):continue
  if floor.rect:
   if floor.bounds.grow(-16).has_point(point):return true
  elif Geometry2D.is_point_in_polygon(point,floor.polygon):return true
 return false
func can_stand(point:Vector2)->bool:
 if not floor_at(point):return false
 for fall in data.get("falls",[]):
  if r(fall).has_point(point):
   var bridge:=false
   for floor in data.floors:
    if floor.has("rect") and str(floor.kind)=="bridge" and r(floor.rect).has_point(point):bridge=true
   if not bridge:return false
 for prop in solid_bins.get(Vector2i(floori(point.x/256),floori(point.y/256)),[]):
  if point.distance_squared_to(prop.pos)<float(prop.radius)*float(prop.radius):return false
 for gate in data.get("gates",[]):
  if stage<int(gate.stage) and r(gate.rect).grow(16).has_point(point):return false
 return true
func moving(id:String)->bool:return active and bool(boat.get("moving",false)) and id in boat.get("passengers",[])
func aboard(id:String)->bool:return active and id in boat.get("passengers",[])
func terrain_speed(point:Vector2)->float:
 if not active:return 1.0
 for patch in data.mud:
  if r(patch).has_point(point):return .55
 return 1.0
func grass_at(point:Vector2)->bool:
 if not active:return false
 for patch in data.grass:
  if r(patch).has_point(point):return true
 return false
func defs()->Dictionary:return adventure.game.enemy_defs if adventure.arcade else adventure.game.enemy_types
func spawn(kind:String,point:Vector2,boss:bool=false)->Dictionary:
 var hp:float=float(defs().get(kind,{}).get("health",80))
 if boss:hp=float((adventure.game.regions[data.id] if adventure.arcade else adventure.game.region).get("boss_health",1000))
 adventure.spawn(kind,point,hp,boss)
 var enemy:Dictionary=adventure.foes()[-1];enemy.immersive=true;enemy.skill_timer=1.5;enemy.attack_timer=1.0;enemy.imm_turn=0;enemy.imm_home=a(point)
 return enemy
func initialize()->void:
 initialized=true
 for entry in data.spawns:spawn(str(entry.type),v(entry.pos))
 adventure.announce(str(data.name)+" • "+str(data.stages[0]))
func nearest(point:Vector2)->String:
 var id:="";var distance:=INF
 for player in adventure.points():
  if adventure.alive(str(player)) and point.distance_to(adventure.points()[player])<distance:distance=point.distance_to(adventure.points()[player]);id=str(player)
 return id
func target_for(enemy:Dictionary)->Vector2:
 var id:=nearest(enemy.pos)
 var target:Vector2=adventure.points().get(id,enemy.pos)
 var decoy:Dictionary=adventure.combat.fern.decoy_for(enemy.pos)
 if not decoy.is_empty() and not bool(enemy.boss) and adventure.combat.path_clear(enemy.pos,v(decoy.pos)):return v(decoy.pos)
 return target
func cell(point:Vector2)->Vector2i:return Vector2i(floori(point.x/60),floori(point.y/60))
func route(start:Vector2,end:Vector2)->PackedVector2Array:
 var first:=cell(start);var last:=cell(end)
 if not grid.is_in_boundsv(first) or not grid.is_in_boundsv(last):return PackedVector2Array()
 if grid.is_point_solid(first):first=nearest_cell(first)
 if grid.is_point_solid(last):last=nearest_cell(last)
 return grid.get_point_path(first,last)
func nearest_cell(c:Vector2i)->Vector2i:
 for radius in range(1,5):
  for x in range(-radius,radius+1):
   for y in range(-radius,radius+1):
    var p:=c+Vector2i(x,y)
    if grid.is_in_boundsv(p) and not grid.is_point_solid(p):return p
 return c
func direction(enemy:Dictionary,target:Vector2,ranged:bool)->Vector2:
 if adventure.combat.path_clear(enemy.pos,target):
  if ranged and bool(enemy.boss) and enemy.pos.distance_to(target)<480:
   var heading:Vector2=(target-(enemy.pos as Vector2)).normalized();return (heading.orthogonal()*(1 if int(enemy.uid)%2 else -1)+heading*.15).normalized()
  return adventure.combat.ranged_direction(enemy,target) if ranged else (target-enemy.pos).normalized()
 var key:=str(enemy.uid);var entry:Dictionary=routes.get(key,{})
 if clock>float(entry.get("until",0)):entry={"path":route(enemy.pos,target),"until":clock+1};routes[key]=entry
 for p in entry.get("path",[]):
  if enemy.pos.distance_to(p)>40:return (p-enemy.pos).normalized()
 return Vector2.ZERO
func advance(start:Vector2,move:Vector2)->Vector2:
 var result:=start
 for n in maxi(1,ceili(move.length()/10)):
  var step:=move/float(maxi(1,ceili(move.length()/10)))
  var x:=result+Vector2(step.x,0);var y:=result+Vector2(0,step.y)
  if can_stand(x):result=x
  y=result+Vector2(0,step.y)
  if can_stand(y):result=y
 return result
func add_beam(point:Vector2,radius:float=145,source:String="")->void:
 if beams.size()<18:beams.append({"credit":preload("res://scripts/defeat_credit.gd").resolve(adventure.game,source,"Sunbeam"),"pos":a(point),"warn":1.3,"life":4.0,"tick":1.0,"radius":radius})
func warning(enemy:Dictionary,target:Vector2,style:String,radius:float,damage:float,delay:float=.85)->void:
 if attacks.size()<40:attacks.append({"credit":preload("res://scripts/defeat_credit.gd").resolve(adventure.game,adventure.combat.npc_key(enemy),style.replace("_"," ").capitalize()),"uid":int(enemy.uid),"start":a(enemy.pos),"pos":a(target),"style":style,"radius":radius,"damage":damage,"time":delay,"total":delay})
func shoot(enemy:Dictionary,target:Vector2,count:int=1,style:String="pellet")->void:
 var aim:Vector2=(target-enemy.pos).normalized();var damage:float=float(defs().get(enemy.type,{}).get("damage",10))
 for n in count:adventure.combat.launch_projectile("enemy",enemy.pos,aim.rotated((n-(count-1)*.5)*.23),{"credit":preload("res://scripts/defeat_credit.gd").resolve(adventure.game,adventure.combat.npc_key(enemy),"Projectile"),"range":850,"speed":255,"amplitude":24,"wavelength":150,"color":"#efd49a" if data.id=="honeyglass" else "#afe5db" if data.id=="silverfall" else "#deaed0"},damage,style)
func skill(enemy:Dictionary,target:Vector2)->void:
 var turn:=int(enemy.imm_turn);enemy.imm_turn=turn+1
 match str(enemy.type):
  "saffron_hopper":warning(enemy,advance(enemy.pos,(target-enemy.pos).normalized()*160),"dash",28,11,.8)
  "silk_spinner":
   for angle in [-.18,0,.18]:adventure.combat.launch_projectile("enemy",enemy.pos,(target-enemy.pos).normalized().rotated(angle),{"range":620,"speed":230,"slow_duration":1.5,"slow_factor":.72,"color":"#ddc1ee"},7,"weaving")
  "dewcap_guard":warning(enemy,enemy.pos,"root",115,15,1.05)
  "sunbeam_cantor":add_beam(target,155,adventure.combat.npc_key(enemy))
  "nectar_keeper":
   for ally in adventure.foes():
    if ally.pos.distance_to(enemy.pos)<230 and adventure.combat.path_clear(enemy.pos,ally.pos):ally.hp=minf(float(ally.max_hp),float(ally.hp)+12)
   warning(enemy,enemy.pos,"heal",235,0,.4);shoot(enemy,target,2)
  "petal_ducker":
   var side:Vector2=(target-enemy.pos).normalized().orthogonal()*(1 if turn%2 else -1);enemy.pos=advance(enemy.pos,side*95);shoot(enemy,target,3,"weaving")
  "briar_tail":warning(enemy,advance(enemy.pos,(target-enemy.pos).normalized()*280),"dash",34,20)
  "bloomtail_regent":
   if turn%3==0:warning(enemy,advance(enemy.pos,(target-enemy.pos).normalized()*330),"dash",60,30,1.0)
   elif turn%3==1:
    for n in 3:warning(enemy,target+Vector2.from_angle(TAU*n/3)*110,"root",65,22,1.0+n*.15)
   else:
    for n in 12:shoot(enemy,enemy.pos+Vector2.from_angle(TAU*n/12),1,"weaving")
  "glass_queen":
   if turn%2==0:
    for n in 3:warning(enemy,target+Vector2((n-1)*100,0),"amber",75,17,1+n*.15)
   else:shoot(enemy,target,5)
  "bellroot":
   if turn%2==0:warning(enemy,target,"root",150,26,1.2)
   else:
    for n in 10:shoot(enemy,enemy.pos+Vector2.from_angle(TAU*n/10),1,"weaving")
  "crowned_torrent":
   if turn%3==0:warning(enemy,advance(enemy.pos,(target-enemy.pos).normalized()*380),"dash",72,30,1)
   elif turn%3==1:
    for n in 3:warning(enemy,target+Vector2((n-1)*140,0),"water",90,24,1+n*.2)
   else:shoot(enemy,target,7,"weaving")
  "sun_sentinel":
   if enemy.boss:add_beam(target,180,adventure.combat.npc_key(enemy));shoot(enemy,target,3)
   else:shoot(enemy,target,2)
  "bog_bellringer","tidebinder","sluice_beetle":warning(enemy,target,"water" if data.id=="silverfall" else "root",90,16,1.1)
  "amber_hornet","cascade_heron","wick_wisp":shoot(enemy,target,3,"weaving")
  _:
   if str(defs().get(enemy.type,{}).get("behaviour","")) in ["ranged","homing","dual_ranged","burst_ranged"]:shoot(enemy,target,2 if enemy.boss else 1)
func hurt_player(id:String,amount:float,source:String="",cause:Dictionary={})->void:
 if not adventure.alive(id):return
 if adventure.arcade:adventure.game._hurt(id,amount,"enemy",source,cause)
 else:adventure.hit_player(id,amount,source,cause)
func ensure_level(minimum:int)->void:
 if adventure.arcade:
  for id in adventure.points():adventure.game.levels[id]=maxi(minimum,int(adventure.game.levels.get(id,1)))
 else:adventure.game.level=maxi(minimum,int(adventure.game.level))
func step(delta:float)->void:
 if not active or not adventure.authoritative():return
 clock+=delta
 if not initialized:initialize()
 step_boat(delta)
 for checkpoint in data.get("checkpoints",[]):
  var token:="checkpoint:"+str(checkpoint.pos)
  if used.has(token):continue
  for id in adventure.points():
   if adventure.alive(str(id)) and (adventure.points()[id] as Vector2).distance_to(v(checkpoint.pos))<300:
    used[token]=true;ensure_level(int(checkpoint.level));adventure.announce("Trail milestone • party minimum level "+str(checkpoint.level)+". More abilities are available!");break
 var defenders:=0
 for enemy in adventure.foes().duplicate():
  if not bool(enemy.get("immersive",false)):continue
  if not bool(enemy.boss):defenders+=1
  if adventure.combat.stunned(adventure.combat.npc_key(enemy)):continue
  var target:=target_for(enemy);var distance:float=enemy.pos.distance_to(target)
  if distance>1000:continue
  var definition:Dictionary=defs().get(enemy.type,{})
  var ranged:bool=str(definition.get("behaviour","")) in ["ranged","homing","dual_ranged","burst_ranged"]
  var movement:Vector2=direction(enemy,target,ranged)*float(definition.get("speed",80))*adventure.combat.speed_factor(adventure.combat.npc_key(enemy))*delta
  if distance>45 or ranged:enemy.pos=advance(enemy.pos,movement)
  enemy.skill_timer=float(enemy.skill_timer)-delta;enemy.attack_timer=float(enemy.attack_timer)-delta
  if float(enemy.skill_timer)<=0 and adventure.combat.path_clear(enemy.pos,target):enemy.skill_timer=2.3 if enemy.boss else 3.8;skill(enemy,target)
  if not ranged and distance<65 and float(enemy.attack_timer)<=0:
   enemy.attack_timer=1.15
   var id:=nearest(enemy.pos)
   if not id.is_empty() and (adventure.points()[id] as Vector2).distance_to(enemy.pos)<65:hurt_player(id,float(definition.get("damage",12)),adventure.combat.npc_key(enemy))
 if defenders==0 and not boss_live and not done:
  stage=1;ensure_level(6);rebuild_grid();spawn(str(data.boss_type),v(data.exit),true);boss_live=true
  if not adventure.arcade:adventure.game.boss_spawned=true
  adventure.announce(str(data.stages[1]))
 step_beams(delta);step_attacks(delta)
 # Marsh thickets contain pulsing spore pools; warning is visible before every pulse.
 if data.id=="lantern_marsh" and fmod(clock,4)<1.2:
  for patch in data.mud:
   var p:=r(patch).get_center()
   for id in adventure.points():
    var token:="bog:"+str(id)
    if (adventure.points()[id] as Vector2).distance_to(p)<75 and clock-float(used.get(token,-2))>=1:used[token]=clock;hurt_player(str(id),7,"",preload("res://scripts/defeat_credit.gd").hazard("Hazardous ground"))
func step_beams(delta:float)->void:
 for n in range(beams.size()-1,-1,-1):
  var beam:Dictionary=beams[n]
  if float(beam.warn)>0:beam.warn=maxf(0,float(beam.warn)-delta);continue
  beam.life-=delta;beam.tick-=delta
  if float(beam.tick)<=0:
   beam.tick+=1
   for id in adventure.combat.v59.target_points():
    if (adventure.combat.v59.target_position(str(id)) as Vector2).distance_to(v(beam.pos))<float(beam.radius):hurt_player(str(id),16,"",beam.get("credit",{}))
   for enemy in adventure.foes():
    if enemy.pos.distance_to(v(beam.pos))<float(beam.radius):enemy.hp=minf(float(enemy.max_hp),float(enemy.hp)+9)
  if float(beam.life)<=0:beams.remove_at(n)
func step_attacks(delta:float)->void:
 for n in range(attacks.size()-1,-1,-1):
  var hit:Dictionary=attacks[n];hit.time-=delta
  if float(hit.time)>0:continue
  var point:=v(hit.pos);var start:=v(hit.start)
  if str(hit.style)!="heal":
   for id in adventure.combat.v59.target_points():
    var target:Vector2=adventure.combat.v59.target_position(str(id))
    var near:bool=Geometry2D.get_closest_point_to_segment(target,start,point).distance_to(target)<float(hit.radius) if str(hit.style)=="dash" else point.distance_to(target)<float(hit.radius)
    if near and adventure.combat.path_clear(point,target):
     var protected:bool=Time.get_ticks_msec()<int(adventure.game.invincible_until.get(id,0)) if adventure.arcade else adventure.game.invulnerable_time>0
     hurt_player(str(id),float(hit.damage),"",hit.get("credit",{}))
     if not protected and str(hit.style) in ["root","water"]:adventure.combat.apply_status(adventure.combat.player_key(str(id)),"slow",2,"enemy",.55)
  if str(hit.style)=="dash":
   for enemy in adventure.foes():
    if int(enemy.uid)==int(hit.uid):enemy.pos=point
  attacks.remove_at(n)
func on_defeat(enemy:Dictionary)->bool:
 if not active or not bool(enemy.get("immersive",false)):return false
 routes.erase(str(enemy.uid))
 if not bool(enemy.boss):return false
 done=true;boss_live=false;attacks.clear();beams.clear()
 if not adventure.arcade:adventure.game.boss_defeated=true
 adventure.announce("Guardian defeated • E / Interact at the glowing exit. Optional treasures can still be explored.")
 return true
func interact(id:String)->bool:
 if not active or not adventure.authoritative() or not adventure.alive(id):return false
 var point:Vector2=adventure.points().get(id,Vector2.ZERO)
 if done and point.distance_to(v(data.exit))<145:
  if adventure.arcade:adventure.game.end_match(str(data.name)+" restored")
  else:adventure.game.finish_run(true)
  return true
 for house in data.get("houses",[]):
  for side in ["outside","inside"]:
   if point.distance_to(v(house[side]))<105:
    adventure.teleport(id,v(house.inside if side=="outside" else house.outside)+Vector2(0,70));adventure.announce(str(house.name)+" • E / Interact at the door to return.");return true
 for secret in data.secrets:
  if point.distance_to(v(secret.pos))>90:continue
  var key:=str(secret.id)+":"+id
  if used.has(key):adventure.announce("You have already collected this discovery.");return true
  used[key]=true
  if str(secret.kind)=="heal":
   if adventure.arcade:adventure.game.health[id]=mini(adventure.game._max_hp(id),int(adventure.game.health[id])+int(secret.amount))
   else:adventure.game.health=minf(adventure.game.max_health(),adventure.game.health+float(secret.amount))
  else:
   if adventure.arcade:adventure.game.gold[id]=int(adventure.game.gold.get(id,0))+int(secret.amount)
   else:adventure.game.gold+=int(secret.amount)
  adventure.announce(str(secret.name)+" • +"+str(secret.amount)+(" HP" if str(secret.kind)=="heal" else " gold"));return true
 if not boat.is_empty():
  if not bool(boat.moving) and point.distance_to(v(boat.pos))<130:
   if id not in boat.passengers:boat.passengers.append(id);boat.boarding=1.2;adventure.combat.chain.move_owner(id,v(boat.pos))
   return true
  if not bool(boat.moving):
   for dock in data.raft.docks:
    if point.distance_to(v(dock))<130:
     if int(boat.dock)!=data.raft.docks.find(dock):boat.passengers=[];boat.boarding=.1;return true
 return false
func step_boat(delta:float)->void:
 if boat.is_empty():return
 for id in boat.passengers.duplicate():
  if not adventure.alive(str(id)):boat.passengers.erase(id)
 if not bool(boat.moving):
  if float(boat.boarding)>0:
   boat.boarding-=delta
   if float(boat.boarding)<=0:boat.moving=true;boat.progress=0.0
  return
 var start:=v(data.raft.docks[int(boat.dock)]);var end:=v(data.raft.docks[1-int(boat.dock)]);var distance:=start.distance_to(end)
 boat.progress=minf(1,float(boat.progress)+float(data.raft.speed)*delta/distance);boat.pos=a(start.lerp(end,float(boat.progress)))
 for i in boat.passengers.size():adventure.combat.chain.move_owner(str(boat.passengers[i]),v(boat.pos)+Vector2((i%2)*35-17,(i/2)*30-15))
 if float(boat.progress)>=1:
  boat.dock=1-int(boat.dock);boat.moving=false
  for i in boat.passengers.size():adventure.combat.chain.move_owner(str(boat.passengers[i]),end+Vector2((i%2)*35-17,45+(i/2)*30))
  boat.passengers=[];adventure.announce("Silverfall crossing complete • explore the shore paths or call the raft from either jetty.")
func snapshot()->Dictionary:return {"initialized":initialized,"stage":stage,"boss_live":boss_live,"done":done,"clock":clock,"beams":beams,"attacks":attacks,"used":used,"boat":boat}
func receive(s:Dictionary)->void:
 var old:=stage;initialized=bool(s.get("initialized",false));stage=int(s.get("stage",0));boss_live=bool(s.get("boss_live",false));done=bool(s.get("done",false));clock=float(s.get("clock",0));beams=s.get("beams",[]);attacks=s.get("attacks",[]);used=s.get("used",{});boat=s.get("boat",{})
 if active and stage!=old:rebuild_grid()
func floor_bounds(floor:Dictionary)->Rect2:
 if floor.has("rect"):return r(floor.rect)
 var lo:=v(floor.poly[0]);var hi:=lo
 for point in floor.poly:lo=lo.min(v(point));hi=hi.max(v(point))
 return Rect2(lo,hi-lo)
func visible(bounds:Rect2,camera:Vector2)->bool:return bounds.intersects(Rect2(camera-Vector2(300,400),Vector2(1900,1250)))
func draw_world(canvas:Node2D,camera:Vector2)->void:
 if not active:return
 var font:Font=ThemeDB.fallback_font
 if adventure.arcade and adventure.game.spectating():draw_water(canvas,camera)
 if floor_layers.is_empty():
  var background=preload("res://scripts/retained_floor.gd").new();background.source=self;background.background=true;canvas.add_child(background);floor_layers.append(background)
  for floor in data.floors:
   var layer=preload("res://scripts/retained_floor.gd").new();layer.source=self;layer.floor=floor;canvas.add_child(layer);floor_layers.append(layer)
 for layer in floor_layers:
  layer.position=-camera;layer.visible=not (adventure.arcade and adventure.game.spectating()) and (layer.background or visible(floor_bounds(layer.floor),camera))
 if adventure.arcade and adventure.game.spectating():
  for floor in data.floors:draw_floor(canvas,floor)
 for patch in data.mud:
  var bounds:=r(patch)
  if not visible(bounds,camera):continue
  canvas.draw_rect(Rect2(bounds.position-camera,bounds.size),Color("#4b5445"))
  for n in 12:canvas.draw_arc(bounds.get_center()-camera+Vector2.from_angle(n*2.4)*Vector2(bounds.size.x*.3,bounds.size.y*.3),14,0,TAU,12,Color("#7c8565"),2)
  var p:=bounds.get_center()-camera;var on:=fmod(clock,4)<1.2
  canvas.draw_circle(p,75,Color(.65,.43,.8,.23 if on else .09));canvas.draw_arc(p,75,0,TAU,36,Color("#b590b7"),2)
 for patch in data.grass:
  var bounds:=r(patch)
  if visible(bounds,camera):canvas.draw_rect(Rect2(bounds.position-camera,bounds.size),Color("#739356"))
 for fall in data.falls:
  var bounds:=r(fall)
  if not visible(bounds,camera):continue
  canvas.draw_rect(Rect2(bounds.position-camera,bounds.size),Color("#76bac6"))
  for x in range(int(bounds.position.x+8),int(bounds.end.x),19):
   for y in range(int(bounds.position.y),int(bounds.end.y),90):
    var yy:=bounds.position.y+fmod(y-bounds.position.y+clock*160,bounds.size.y);canvas.draw_line(Vector2(x,yy)-camera,Vector2(x,minf(yy+50,bounds.end.y))-camera,Color("#d7f5e9"),5)
  for n in 10:canvas.draw_circle(Vector2(bounds.position.x+n*bounds.size.x/10,bounds.end.y)-camera,22+sin(clock*3+n)*5,Color(.83,.96,.94,.35))
 if data.id=="lantern_marsh":
  for floor in data.floors:
   if not floor.has("rect") or str(floor.kind)!="marsh":continue
   var bounds:=r(floor.rect)
   if not visible(bounds,camera):continue
   for x in range(int(bounds.position.x)+15,int(bounds.end.x),42):
    for y in [bounds.position.y+14,bounds.end.y-14]:
     var p:=Vector2(x,y)-camera
     for n in 3:canvas.draw_line(p+Vector2(n*5,0),p+Vector2(n*5+sin(clock+x)*5,-30-n*7),Color("#95a67b"),3);canvas.draw_circle(p+Vector2(n*5,-30-n*7),4,Color("#c3b38e"))
 if data.id=="petalbrook":
  for floor in data.floors:
   if not floor.has("rect") or str(floor.name).is_empty():continue
   var bounds:=r(floor.rect)
   if not visible(bounds,camera):continue
   var left:=bounds.position+Vector2(40,110)-camera;var right:=left+Vector2(bounds.size.x-80,0)
   canvas.draw_line(left,right,Color("#d8c6a6"),2)
   for n in int(bounds.size.x/70):
    var p:=left+Vector2(n*70+20,0);canvas.draw_colored_polygon(PackedVector2Array([p,p+Vector2(25,0),p+Vector2(12,28)]),[Color("#e5b6ce"),Color("#bdd3aa"),Color("#e7d697")][n%3])
   for n in 25:
    var p:=bounds.position+Vector2(80+posmod(n*199,int(bounds.size.x)-160),160+posmod(n*157,int(bounds.size.y)-210))-camera
    canvas.draw_circle(p,3,Color("#edc4d8"));canvas.draw_circle(p+Vector2(4,3),2,Color("#f0deb6"))
 # Repaint bridge surfaces crossing the waterfall so their real walkable route stays visible.
 for fall in data.falls:
  for floor in data.floors:
   if str(floor.kind)!="bridge" or not floor.has("rect"):continue
   var bounds:=r(floor.rect);var clipped:=bounds.intersection(r(fall))
   if not clipped.has_area() or not visible(clipped,camera):continue
   canvas.draw_rect(Rect2(clipped.position-camera,clipped.size),Color("#ab946e"))
   if bounds.size.y>bounds.size.x:
    for y in range(int(clipped.position.y),int(clipped.end.y),36):canvas.draw_line(Vector2(clipped.position.x,y)-camera,Vector2(clipped.end.x,y)-camera,Color("#685c4d"),2)
    for x in [bounds.position.x+8,bounds.end.x-8]:canvas.draw_line(Vector2(x,clipped.position.y)-camera,Vector2(x,clipped.end.y)-camera,Color("#d7b388"),6)
   else:
    for x in range(int(clipped.position.x),int(clipped.end.x),36):canvas.draw_line(Vector2(x,clipped.position.y)-camera,Vector2(x,clipped.end.y)-camera,Color("#685c4d"),2)
    for y in [bounds.position.y+8,bounds.end.y-8]:canvas.draw_line(Vector2(clipped.position.x,y)-camera,Vector2(clipped.end.x,y)-camera,Color("#d7b388"),6)
 # Draw trunks here, canopies later above actors.
 for prop in data.props:
  var p:=v(prop.pos)-camera;var scale:float=float(prop.scale)
  if not visible(Rect2(v(prop.pos)-Vector2(120,230)*scale,Vector2(240,280)*scale),camera):continue
  if str(prop.kind) in ["grand_tree","moss_tree"]:canvas.draw_texture_rect(textures[prop.kind],Rect2(p-Vector2(80,207)*scale,Vector2(160,220)*scale),false)
  else:
   var alpha:=1.0
   if data.id=="honeyglass" and str(prop.kind)=="giant_flower":
    var crown:Vector2=v(prop.pos)-Vector2(0,135)*scale
    for player in adventure.points().values():
     if (player as Vector2).distance_to(crown)<130:alpha=.32
    canvas.draw_circle(p,float(prop.solid),Color("#778a61"));canvas.draw_arc(p,float(prop.solid),0,TAU,24,Color("#c6b995"),2,true)
   canvas.draw_texture_rect(textures[prop.kind] if textures.has(prop.kind) else textures.honey_lamp,Rect2(p-Vector2(80,207)*scale,Vector2(160,220)*scale),false,Color(1,1,1,alpha))
 for gate in data.gates:
  if stage>=int(gate.stage):continue
  var bounds:=r(gate.rect);canvas.draw_rect(Rect2(bounds.position-camera,bounds.size),Color("#d5ac7a"));canvas.draw_string(font,bounds.position-camera+Vector2(-160,-25),str(gate.name),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#fff0c7"))
 for secret in data.secrets:
  var point:=v(secret.pos)-camera
  if not visible(Rect2(v(secret.pos)-Vector2(100,100),Vector2(200,200)),camera):continue
  canvas.draw_circle(point,25,Color("#9addc3") if str(secret.kind)=="heal" else Color("#b99366"));canvas.draw_rect(Rect2(point-Vector2(17,13),Vector2(34,26)),Color("#e9d89b"),false,3);canvas.draw_string(font,point+Vector2(-70,45),"E / Interact • discovery",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#f1dfb4"))
 for house in data.get("houses",[]):
  for side in ["inside","outside"]:
   var point:=v(house[side])-camera;canvas.draw_arc(point,32,0,TAU,20,Color("#dbd6a3"),3);canvas.draw_string(font,point+Vector2(-65,48),"E • enter / leave",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#f3e6bc"))
 if not boat.is_empty():
  for dock in data.raft.docks:
   var point:=v(dock)-camera;canvas.draw_string(font,point+Vector2(-70,75),"E • board / call raft",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#e9e9bf"))
  var point:=v(boat.pos)-camera;canvas.draw_rect(Rect2(point-Vector2(60,42),Vector2(120,84)),Color("#bda276"));canvas.draw_rect(Rect2(point-Vector2(60,42),Vector2(120,84)),Color("#625b49"),false,5)
  for x in range(-45,60,18):canvas.draw_line(point+Vector2(x,-36),point+Vector2(x,36),Color("#655f4d"),3)
  canvas.draw_line(point+Vector2(36,-35),point+Vector2(36,-110),Color("#755e45"),5);canvas.draw_colored_polygon(PackedVector2Array([point+Vector2(37,-110),point+Vector2(-10,-90),point+Vector2(37,-65)]),Color("#e9e3bf"))
func draw_on(canvas:Node2D,camera:Vector2)->void:
 if not active:return
 # Texture batches preserve concealment with a readable gap near players.
 grass_draws=0
 var players:Array=adventure.points().values()
 var view:Rect2=Rect2(camera,canvas.get_viewport_rect().size).grow(80)
 var frame:int=int(clock*4)%4
 for patch in data.grass:
  var bounds:Rect2=r(patch).intersection(view)
  if not bounds.has_area():continue
  for x in range(floori(bounds.position.x/64)*64,ceili(bounds.end.x/64)*64,64):
   for y in range(floori(bounds.position.y/64)*64,ceili(bounds.end.y/64)*64,64):
    var point:=Vector2(x+32,y+32);var alpha:=.93
    for player in players:
     if point.distance_squared_to(player)<10000:alpha=.35;break
    var cell:=Rect2(x,y,64,64).intersection(r(patch))
    if not cell.has_area():continue
    var target:=Rect2(cell.position-camera,cell.size)
    canvas.draw_texture_rect_region(grass_art[(frame+posmod(x/64+y/64,4))%4],target,Rect2(cell.position-Vector2(x,y)+Vector2(0,12),cell.size),Color(1,1,1,alpha))
    grass_draws+=1
 for beam in beams:
  var point:=v(beam.pos)-camera;var radius:=float(beam.radius);var warned:=float(beam.warn)>0
  if warned:preload("res://scripts/combat_cues.gd").danger(canvas,point,radius,float(beam.warn),1.3)
  else:canvas.draw_circle(point,radius,Color(1,.81,.34,.21));canvas.draw_arc(point,radius,0,TAU,48,Color("#fff1a9"),3)
  if not warned:
   canvas.draw_rect(Rect2(point-Vector2(radius,-0)+Vector2(0,-600),Vector2(radius*2,600)),Color(1,.9,.52,.13))
   for n in 7:canvas.draw_line(point+Vector2((n-3)*radius/4,-600),point+Vector2((n-3)*radius/4,0),Color(1,.96,.69,.23),4)
 for attack in attacks:
  var point:=v(attack.pos)-camera;var tint:=Color("#d6efbd") if str(attack.style)=="heal" else Color("#edb198")
  if str(attack.style)=="heal":preload("res://scripts/combat_cues.gd").enemy_healing(canvas,point,float(attack.radius))
  elif str(attack.style)=="dash":preload("res://scripts/combat_cues.gd").corridor(canvas,v(attack.start)-camera,point,float(attack.radius))
  else:preload("res://scripts/combat_cues.gd").danger(canvas,point,float(attack.radius),float(attack.time),float(attack.total),tint)
 # Tree canopies fade near players so navigation remains readable under giant trees.
 for prop in data.props:
  if str(prop.kind) not in ["grand_tree","moss_tree"]:continue
  var scale:float=float(prop.scale);var center:=v(prop.pos)-Vector2(0,140)*scale
  if not visible(Rect2(center-Vector2(90,90)*scale,Vector2(180,180)*scale),camera):continue
  var alpha:=.95
  for id in adventure.points():
   if (adventure.points()[id] as Vector2).distance_to(center)<115*scale:alpha=.3
  canvas.draw_texture_rect_region(textures[prop.kind],Rect2(v(prop.pos)-camera-Vector2(80,207)*scale,Vector2(160,140)*scale),Rect2(0,0,160,140),Color(1,1,1,alpha))
func draw_hud(canvas:Node2D)->void:
 if not active:return
 var font:Font=ThemeDB.fallback_font
 canvas.draw_rect(Rect2(20,147,850,53),Color(.06,.16,.18,.9))
 var count:=0
 for enemy in adventure.foes():
  if bool(enemy.get("immersive",false)) and not bool(enemy.boss):count+=1
 var text:= "Guardian defeated • interact at the exit" if done else str(data.stages[mini(stage,data.stages.size()-1)])+ (" • "+str(count)+" defenders left" if stage==0 else "")
 canvas.draw_string(font,Vector2(33,169),text,HORIZONTAL_ALIGNMENT_LEFT,820,16,Color("#f5e4b3"));var tips:Dictionary={"honeyglass":"Follow the glass corridors; the Crown Chamber opens after its defenders fall.","sunfield":"Orchard canopies conceal patrols. Golden meadows are open; move out of warning sunbeams!","lantern_marsh":"Black water blocks travel. Mud slows you; glowing spore pools pulse. E / Interact: discoveries.","silverfall":"E / Interact: treehouse doors, discoveries, board or call the raft. Both shore routes connect.","petalbrook":"Explore ribbon paths, hollow logs, cottages and tea gardens. E / Interact: doors and discoveries."}
 canvas.draw_string(font,Vector2(33,190),str(tips.get(data.id,"Explore")),HORIZONTAL_ALIGNMENT_LEFT,820,14,Color("#b9dccc"))
 # Route arrow follows navigable waypoints rather than pointing through maze walls.
 var origin:Vector2=adventure.points().get(adventure.game.my_id if adventure.arcade else "solo",Vector2.ZERO)
 var destination:=v(data.exit);var distance:=INF
 if stage==0:
  for enemy in adventure.foes():
   if bool(enemy.get("immersive",false)) and enemy.pos.distance_to(origin)<distance:distance=enemy.pos.distance_to(origin);destination=enemy.pos
 if clock>=arrow_until:
  arrow_route=route(origin,destination);arrow_until=clock+.5
 var path:=arrow_route;var aim:=destination-origin
 for p in path:
  if origin.distance_to(p)>70:aim=p-origin;break
 var point:=Vector2(1160,238);var tip:=point+aim.normalized()*26
 canvas.draw_circle(point,37,Color(.08,.2,.23,.9));canvas.draw_line(point,tip,Color("#efdf9c"),5);canvas.draw_line(tip,tip-aim.normalized().rotated(.6)*12,Color("#efdf9c"),4);canvas.draw_line(tip,tip-aim.normalized().rotated(-.6)*12,Color("#efdf9c"),4)

func draw_floor(canvas:Node2D,floor:Dictionary)->void:
 var camera:=Vector2.ZERO
 var font:=ThemeDB.fallback_font
 var bounds:Rect2=floor_bounds(floor)
 var kind:=str(floor.kind);var tint:=Color("#baab77") if kind=="glass" else Color("#598568") if kind in ["river","petal"] else Color("#658359") if kind=="meadow" else Color("#82795f") if kind=="marsh" else Color("#ab946e")
 if data.id=="sunfield" and kind=="meadow":tint=Color("#a2a45c")
 if data.id=="petalbrook" and kind=="petal":tint=Color("#72937b")
 if floor.has("poly"):
  var points:=polygon(floor.poly)
  for i in points.size():points[i]-=camera
  canvas.draw_colored_polygon(points,tint);var closed:=points.duplicate();closed.append(points[0])
  if kind=="glass":
   canvas.draw_polyline(closed,Color("#e8ca83"),16,true);canvas.draw_polyline(closed,Color("#b1e1d8"),5,true)
   for i in points.size():canvas.draw_line(points[i]+Vector2(5,3),points[(i+1)%points.size()]+Vector2(5,3),Color("#f8efd0"),2,true)
  else:canvas.draw_polyline(closed,Color("#c4b489"),3,true)
 else:
  if data.id in ["sunfield","petalbrook"] and kind in ["meadow","petal","trail"]:
   var skin=StyleBoxFlat.new();skin.bg_color=tint;skin.border_color=Color("#b8b194");skin.set_border_width_all(3);skin.set_corner_radius_all(26 if kind=="trail" else 60);canvas.draw_style_box(skin,Rect2(bounds.position-camera,bounds.size))
  else:canvas.draw_rect(Rect2(bounds.position-camera,bounds.size),tint);canvas.draw_rect(Rect2(bounds.position-camera,bounds.size),Color("#b8b194"),false,4)
  if kind in ["bridge","boardwalk","log","house"]:
   if bounds.size.y>bounds.size.x:
    for y in range(int(bounds.position.y),int(bounds.end.y),36):canvas.draw_line(Vector2(bounds.position.x,y)-camera,Vector2(bounds.end.x,y)-camera,Color("#685c4d"),2)
   else:
    for x in range(int(bounds.position.x),int(bounds.end.x),36):canvas.draw_line(Vector2(x,bounds.position.y)-camera,Vector2(x,bounds.end.y)-camera,Color("#685c4d"),2)
   canvas.draw_rect(Rect2(bounds.position-camera+Vector2(8,8),bounds.size-Vector2(16,16)),Color("#d7b388"),false,6)
 if kind in ["meadow","river","petal","marsh","trail"]:
  var left:=maxi(int(bounds.position.x),floori(bounds.position.x/64)*64);var top:=maxi(int(bounds.position.y),floori(bounds.position.y/64)*64)
  for x in range(left,mini(int(bounds.end.x),int(bounds.end.x)),128):
   for y in range(top,mini(int(bounds.end.y),int(bounds.end.y)),128):
    var clipped:=bounds.intersection(Rect2(x,y,128,128))
    if clipped.has_area():canvas.draw_texture_rect_region(textures.floor,Rect2(clipped.position-camera,clipped.size),Rect2(Vector2.ZERO,Vector2(64,64)),Color(tint,.23))
 if kind=="log":
  var p:=bounds.position-camera
  var wide:=bounds.size.x
  canvas.draw_rect(Rect2(p,Vector2(15,bounds.size.y)),Color("#66523f"));canvas.draw_rect(Rect2(p+Vector2(wide-15,0),Vector2(15,bounds.size.y)),Color("#66523f"))
  for y in [0,bounds.size.y-40]:
   var shape:=PackedVector2Array()
   for n in 25:shape.append(p+Vector2(wide*.5,y+20)+Vector2(cos(n*TAU/24)*wide*.52,sin(n*TAU/24)*32))
   canvas.draw_colored_polygon(shape,Color("#61513c"));canvas.draw_polyline(shape,Color("#c2a16f"),7,true)
 if kind=="glass":
  for x in range(maxi(int(bounds.position.x),floori(bounds.position.x/95)*95),mini(int(bounds.end.x),int(bounds.end.x)),95):
   for y in range(maxi(int(bounds.position.y),floori(bounds.position.y/95)*95),mini(int(bounds.end.y),int(bounds.end.y)),95):
    if (not floor.has("poly") or Geometry2D.is_point_in_polygon(Vector2(x,y),polygon(floor.poly))):
     var p:=Vector2(x,y)-camera;canvas.draw_arc(p,17,0,TAU,6,Color(.87,.76,.51,.2),2)
 if kind=="house":
  var p:=bounds.position-camera
  canvas.draw_rect(Rect2(p+Vector2(160,160),bounds.size-Vector2(320,320)),Color("#7f8e73"));canvas.draw_rect(Rect2(p+Vector2(160,160),bounds.size-Vector2(320,320)),Color("#e4c2a1"),false,8)
  canvas.draw_rect(Rect2(p+Vector2(45,90),Vector2(100,190)),Color("#dfc3b2"));canvas.draw_rect(Rect2(p+Vector2(45,90),Vector2(100,45)),Color("#f0e9d0"));canvas.draw_circle(p+Vector2(bounds.size.x*.7,bounds.size.y*.55),60,Color("#af9068"))
  for n in 3:canvas.draw_circle(p+Vector2(bounds.size.x*.7,bounds.size.y*.55)+Vector2.from_angle(n*TAU/3)*28,9,Color("#d9e8d6"))
  canvas.draw_rect(Rect2(p+Vector2(200,55),Vector2(150,60)),Color("#b9e9da"));canvas.draw_rect(Rect2(p+Vector2(200,55),Vector2(150,60)),Color("#735f4a"),false,5)
 if not str(floor.name).is_empty():canvas.draw_string(font,bounds.position-camera+Vector2(28,40),str(floor.name),HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("#f8e8b8"))
 # Sparse ground detail gives rooms texture without hiding attack warnings.
 var x0:=maxi(int(bounds.position.x+35),floori(bounds.position.x/85)*85);var y0:=maxi(int(bounds.position.y+50),floori(bounds.position.y/85)*85)
 for x in range(x0,mini(int(bounds.end.x),int(bounds.end.x)),85):
  for y in range(y0,mini(int(bounds.end.y),int(bounds.end.y)),85):
   if not floor.has("poly") or Geometry2D.is_point_in_polygon(Vector2(x,y),polygon(floor.poly)):canvas.draw_circle(Vector2(x,y)-camera,2,Color(tint.lightened(.18),.6))

func draw_water(canvas:Node2D,camera:Vector2)->void:
 canvas.draw_rect(Rect2(-camera,v(data.size)),Color(data.background))
 # Flowing water underneath the connected route network.
 if data.id in ["silverfall","lantern_marsh"]:
  var left:=floori(camera.x/90)*90;var top:=floori(camera.y/90)*90
  for x in range(left,left+1500,90):
   for y in range(top,top+1000,90):canvas.draw_line(Vector2(x,y)-camera+Vector2(fmod(clock*18,45),0),Vector2(x+28,y+sin(clock+x)*4)-camera+Vector2(fmod(clock*18,45),0),Color("#467b79"),2)
 if not data.lake.is_empty():
  var bounds:=r(data.lake);canvas.draw_rect(Rect2(bounds.position-camera,bounds.size),Color("#478e9c"));canvas.draw_rect(Rect2(bounds.position-camera,bounds.size),Color("#a7d8ce"),false,8)
  for x in range(maxi(int(bounds.position.x+35),int(camera.x)),mini(int(bounds.end.x),int(camera.x+1400)),100):
   for y in range(maxi(int(bounds.position.y+35),int(camera.y)),mini(int(bounds.end.y),int(camera.y+850)),90):
    var p:=Vector2(x+sin(clock+x*.03)*10,y)-camera;canvas.draw_arc(p,16+sin(clock+y*.03)*3,0,PI,12,Color(.7,.9,.88,.35),2)

