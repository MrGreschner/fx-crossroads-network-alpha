extends Node
## Data-authored school adventures. Host chooses encounters and the one Final Exam.
var adventure:Node
var active:=false
var data:Dictionary={}
var region_id:=""
var stage:=0
var completed:Array=[]
var spawned:Dictionary={}
var boss_dead:Dictionary={}
var opened:Dictionary={}
var collected:Array=[]
var initialized:=false
var done:=false
var exam_choice:=""
var clock:=0.0
var hazards:Array=[]
var flashes:Array=[]
var debounce:Dictionary={}
var grid:AStarGrid2D
var nav_cache:Dictionary={}
var prop_cells:Dictionary={}
var textures:Dictionary={}
var room_bins:Dictionary={}
var room_geometry:Array=[]
var floor_chunks:Array=[]
var floor_tiles:Dictionary={}
var rng:=RandomNumberGenerator.new()
const TYPES=["lesson_warden","pencil_scrapper","paper_sprite","backpack_biter","hall_monitor","gravel_skater","chalkling","culture_blob","recess_ringleader","yellow_bus","lunchline_leviathan","bellwork_colossus","spotlight_sovereign","layercake_golem","iron_barbell","exam_math","exam_english","exam_history","exam_science"]
const EXAMS=["exam_math","exam_english","exam_history","exam_science"]
const COLOURS={"exam_math":"#f4a274","exam_english":"#abd7c7","exam_history":"#a8daef","exam_science":"#b9d68c"}
func v(a:Array)->Vector2:return Vector2(float(a[0]),float(a[1]))
func a(p:Vector2)->Array:return [p.x,p.y]
func rect(values:Array)->Rect2:return Rect2(float(values[0]),float(values[1]),float(values[2]),float(values[3]))
func definition(kind:String)->Dictionary:return (adventure.game.enemy_defs if adventure.arcade else adventure.game.enemy_types).get(kind,{})
func setup(id:String)->void:
 for chunk in floor_chunks:chunk.queue_free()
 floor_chunks.clear();floor_tiles.clear();room_bins.clear();room_geometry.clear()
 active=false;data={};region_id=id;stage=0;completed.clear();spawned.clear();boss_dead.clear();opened.clear();collected.clear();initialized=false;done=false;exam_choice="";clock=0;hazards.clear();flashes.clear();debounce.clear();nav_cache.clear();prop_cells.clear();grid=null;rng.randomize()
 var region:Dictionary=adventure.game.regions.get(id,{}) if adventure.arcade else adventure.game.region
 var path:=str(region.get("school_campaign",""))
 if path.is_empty():return
 data=JSON.parse_string(FileAccess.get_file_as_string(path));active=true
 for room in data.rooms:
  var geometry={"rect":rect(room.rect),"room":room};room_geometry.append(geometry)
  var bounds:Rect2=geometry.rect
  for x in range(floori(bounds.position.x/256),floori(bounds.end.x/256)+1):
   for y in range(floori(bounds.position.y/256),floori(bounds.end.y/256)+1):
    var key=Vector2i(x,y)
    if not room_bins.has(key):room_bins[key]=[]
    room_bins[key].append(geometry)
 for door in data.doors:opened[str(door.id)]=false
 for prop in data.props:
  if not prop.has("solid"):continue
  var bounds:=prop_rect(prop).grow(18)
  for x in range(floori(bounds.position.x/128),floori(bounds.end.x/128)+1):
   for y in range(floori(bounds.position.y/128),floori(bounds.end.y/128)+1):
    var cell:=Vector2i(x,y)
    if not prop_cells.has(cell):prop_cells[cell]=[]
    prop_cells[cell].append(bounds)
 if textures.is_empty():
  for key in ["school_tile","school_wood","school_street","school_yard","school_carpet","school_sand"]:textures[key]=load("res://assets/"+key+".png")
  for key in ["desk","board","locker","bookshelf","counter","oven","curtain","weightbench","hoop","clocktower","playframe","slide","bench"]:textures["school_"+key]=load("res://assets/school_"+key+".png")
 for key in ["school_tile","school_street","school_yard","school_sand","school_desk","school_board","school_locker","school_playframe","school_slide","school_bench"]:
  textures[key]=preload("res://scripts/firstbell_art256.gd").frame(key) if id=="elementary"else load("res://assets/"+key+".png")
 grid=AStarGrid2D.new();grid.region=Rect2i(0,0,ceili(float(region.size[0])/50),ceili(float(region.size[1])/50));grid.cell_size=Vector2(50,50);grid.offset=Vector2(25,25);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
 preload("res://scripts/navigation_cache.gd").populate(grid,"school_"+id,JSON.stringify(data),func(point):return not can_stand(point))
func prop_rect(prop:Dictionary)->Rect2:
 var size:=v(prop.solid);return Rect2(v(prop.pos)-size*.5,size)
func room_at(point:Vector2)->Dictionary:
 for geometry in room_bins.get(Vector2i(floori(point.x/256),floori(point.y/256)),[]):
  if (geometry.rect as Rect2).has_point(point):return geometry.room
 return {}
func terrain_speed(point:Vector2)->float:
 return .8 if str(room_at(point).get("theme",""))=="sand" else 1.0
func raw_floor(point:Vector2)->bool:return not room_at(point).is_empty()
func floor_at(point:Vector2)->bool:
 if not raw_floor(point):return false
 for offset in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
  if not raw_floor(point+offset*18):return false
 return true
func door_rect(door:Dictionary)->Rect2:return Rect2(v(door.pos)-v(door.size)*.5,v(door.size))
func can_stand(point:Vector2)->bool:
 if not floor_at(point):return false
 for bounds in prop_cells.get(Vector2i(floori(point.x/128),floori(point.y/128)),[]):
  if (bounds as Rect2).has_point(point):return false
 for door in data.get("doors",[]):
  if not bool(opened.get(str(door.id),false)) and door_rect(door).grow(16).has_point(point):return false
 return true
func open_door(door:Dictionary)->void:
 opened[str(door.id)]=true;nav_cache.clear()
 var bounds:=door_rect(door).grow(70)
 for x in range(floori(bounds.position.x/50),ceili(bounds.end.x/50)+1):
  for y in range(floori(bounds.position.y/50),ceili(bounds.end.y/50)+1):
   var cell:=Vector2i(x,y)
   if grid.is_in_boundsv(cell):grid.set_point_solid(cell,not can_stand(Vector2(x*50+25,y*50+25)))
func unlocked(requirement:String)->bool:return requirement.is_empty() or completed.has(requirement)
func floor_id(point:Vector2)->int:return 1 if region_id=="high_school" and point.x>8500 or region_id=="middle_school" and point.x>5500 and point.y<4000 else 0
func interact(id:String)->bool:
 if not active or not adventure.alive(id) or not adventure.authoritative():return false
 var point:Vector2=adventure.points().get(id,Vector2.ZERO)
 if done and point.distance_to(v(data.exit))<150:
  if adventure.arcade:adventure.game.end_match(str(data.name)+" cleared • "+str(int(adventure.game.run_time))+" seconds")
  else:adventure.game.finish_run(true)
  return true
 if clock<float(debounce.get(id,-1)):return true
 for route in data.routes:
  if point.distance_to(v(route.pos))<115:
   debounce[id]=clock+.5
   if not unlocked(str(route.requires)):adventure.announce("The stairs are sealed. Finish the current school objectives first.");return true
   adventure.teleport(id,v(route.end));return true
 for gear in data.gears:
  if point.distance_to(v(gear.pos))>110 or collected.has(str(gear.id)):continue
  if not spawned.has(str(gear.id)) or remaining(str(gear.id))>0:adventure.announce("Clear this wing before taking its bell gear.");return true
  collected.append(str(gear.id));flashes.append({"pos":gear.pos,"time":.7,"radius":70,"colour":"#e4ce83"});adventure.announce(str(gear.name)+" recovered • "+str(collected.size())+"/3");debounce[id]=clock+.35;return true
 var near:Dictionary={};var distance:=125.0
 for door in data.doors:
  var d:float=door_rect(door).grow(16).get_center().distance_to(point)
  var edge:Vector2=point.clamp(door_rect(door).position,door_rect(door).end)
  d=edge.distance_to(point)
  if not bool(opened.get(str(door.id),false)) and d<distance:near=door;distance=d
 if not near.is_empty():
  debounce[id]=clock+.3
  if not unlocked(str(near.requires)):adventure.announce(str(near.label));return true
  open_door(near);adventure.announce("Door opened • "+str(data.name));return true
 return false
func spawn_foe(kind:String,point:Vector2,group:String,boss:bool=false,hp:float=-1)->Dictionary:
 adventure.spawn(kind,point,float(definition(kind).get("health",60)) if hp<0 else hp,boss)
 var enemy:Dictionary=adventure.foes()[-1];enemy["school_group"]=group;enemy["hit_radius"]=32.0 if kind=="lesson_warden" else 85.0 if kind=="yellow_bus" else 50.0 if boss else 22.0;enemy["school_anchor"]=a(point);enemy["school_timer"]=1.0;enemy["school_turn"]=0
 return enemy
func spawn_group(key:String)->void:
 if spawned.has(key):return
 spawned[key]=true
 for entry in data.groups.get(key,[]):
  var foe=spawn_foe(str(entry.type),v(entry.pos),key,false,float(entry.hp));foe["volley_patrol"]=bool(entry.get("volley_patrol",false))
func remaining(group:String)->int:
 var count:=0
 for enemy in adventure.foes():
  if str(enemy.get("school_group",""))==group and not bool(enemy.get("summoned",false)):count+=1
 return count
func boss_for(group:String,kind:String,point:Vector2)->void:
 var token:="boss:"+group
 if spawned.has(token):return
 spawned[token]=true;spawn_foe(kind,point,token,true);adventure.announce(str(definition(kind).get("name",kind))+" awakens!")
func on_defeat(enemy:Dictionary)->bool:
 if not active or not bool(enemy.get("boss",false)) or not str(enemy.get("school_group","")).begins_with("boss:"):return false
 var key:=str(enemy.school_group).trim_prefix("boss:");boss_dead[key]=true
 # Cancel attacks owned by a defeated boss; minion bodies remain valid enemies.
 for n in range(hazards.size()-1,-1,-1):
  if int(hazards[n].get("uid",-1))==int(enemy.uid):hazards.remove_at(n)
 if not completed.has(key):completed.append(key)
 return true
func choose_exam(index:int=-1)->String:
 if exam_choice.is_empty():exam_choice=EXAMS[rng.randi_range(0,3) if index<0 else clampi(index,0,3)]
 return exam_choice
func initialize()->void:
 if initialized:return
 initialized=true
 if region_id=="high_school":spawn_group("arrival")
 else:start_stage()
func milestone(level:int)->void:
 # Shared school checkpoints unlock kits even when another teammate lands kills.
 if not adventure.arcade:return
 for id in adventure.points():adventure.game.levels[id]=maxi(int(adventure.game.levels.get(id,1)),level)
func start_stage()->void:
 if stage>=data.stages.size():complete_school();return
 var current:Dictionary=data.stages[stage]
 for group in current.get("groups",[]):spawn_group(str(group))
 adventure.announce(str(current.text))
func complete_school()->void:
 if done:return
 done=true;hazards.clear();completed.append("complete")
 if not adventure.arcade:adventure.game.boss_defeated=true;adventure.game.boss_spawned=true
 adventure.announce("School cleared! Return to the glowing street exit and press Interact.")
func advance_progress()->void:
 if done:return
 if region_id=="high_school":
  if not completed.has("arrival") and remaining("arrival")==0:
   completed.append("arrival");milestone(3)
   for wing in data.departments:spawn_group(str(wing.id))
   adventure.announce("Department doors unlocked. Defeat the Drama, Foods and Athletics guardians.")
  if completed.has("arrival"):
   for wing in data.departments:
    if remaining(str(wing.id))==0 and not boss_dead.has(str(wing.id)):boss_for(str(wing.id),str(wing.boss),v(wing.pos))
   milestone(3+int(boss_dead.has("drama"))+int(boss_dead.has("kitchen"))+int(boss_dead.has("gym")))
   if boss_dead.has("drama") and boss_dead.has("kitchen") and boss_dead.has("gym") and not completed.has("departments"):
    completed.append("departments");spawn_group("upper");adventure.announce("Three department seals claimed. Take the marked stairs upstairs.")
  if completed.has("departments") and remaining("upper")==0 and not completed.has("upper"):
   completed.append("upper");milestone(8);adventure.announce("The Final Exam classroom is unlocked. Enter to draw your exam.")
  if completed.has("upper") and exam_choice.is_empty():
   var bounds:Rect2=rect(data.rooms.filter(func(room:Dictionary)->bool:return str(room.id)=="exam")[0].rect).grow(-80)
   for id in adventure.points():
    if adventure.alive(str(id)) and bounds.has_point(adventure.points()[id]):boss_for("final",choose_exam(),Vector2(12050,1450));break
  if boss_dead.has("final"):complete_school()
  return
 var current:Dictionary=data.stages[stage]
 if current.has("boss"):
  if boss_dead.has(str(current.id)):
   milestone(5 if region_id=="elementary" else 6);stage+=1;start_stage();return
  var bounds:=rect(current.trigger)
  for id in adventure.points():
   if adventure.alive(str(id)) and bounds.has_point(adventure.points()[id]):boss_for(str(current.id),str(current.boss),v(current.pos));break
 else:
  var clear:=true
  for group in current.get("groups",[]):
   if remaining(str(group))>0:clear=false
  if current.has("reach"):
   clear=false
   for id in adventure.points():
    if adventure.alive(str(id)) and rect(current.reach).has_point(adventure.points()[id]):clear=true;break
  if bool(current.get("collect",false)) and collected.size()<data.gears.size():clear=false
  if clear:
   milestone([3,5,6,8][mini(stage,3)] if region_id=="middle_school" else 3 if stage==0 else 6)
   completed.append(str(current.id));stage+=1;start_stage()
func advance(origin:Vector2,direction:Vector2,distance:float,padding:float=0)->Vector2:
 var result:=origin
 for n in maxi(1,ceili(distance/10)):
  var next:=origin+direction*minf(distance,(n+1)*10)
  if not can_stand(next):break
  var clear:=true
  for side in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
   if padding>0 and not can_stand(next+side*padding):clear=false
  if not clear:break
  result=next
 return result
func direction(enemy:Dictionary,target:Vector2,ranged:bool)->Vector2:
 target=adventure.combat.fern.redirect(enemy,target)
 var origin:Vector2=enemy.pos
 if floor_id(origin)!=floor_id(target):return Vector2.ZERO
 if adventure.combat.path_clear(origin,target):return adventure.combat.ranged_direction(enemy,target) if ranged else (target-origin).normalized()
 var key:=int(enemy.uid);var cached:Dictionary=nav_cache.get(key,{})
 if clock>float(cached.get("until",0)):
  var start:=Vector2i(floori(origin.x/50),floori(origin.y/50));var finish:=Vector2i(floori(target.x/50),floori(target.y/50));var path:=PackedVector2Array()
  if grid.is_in_boundsv(start) and grid.is_in_boundsv(finish) and not grid.is_point_solid(start) and not grid.is_point_solid(finish):path=grid.get_point_path(start,finish)
  cached={"path":path,"until":clock+.65};nav_cache[key]=cached
 for p in cached.get("path",[]):
  if origin.distance_to(p)>38:return (p-origin).normalized()
 return Vector2.ZERO
func damage_player(id:String,amount:float,stats:Dictionary={},source:String="",credit_source:String="")->void:
 if not adventure.alive(id):return
 var protected:bool=Time.get_ticks_msec()<int(adventure.game.invincible_until.get(id,0)) if adventure.arcade else adventure.game.invulnerable_time>0
 var credit:Dictionary=preload("res://scripts/defeat_credit.gd").resolve(adventure.game,credit_source if not credit_source.is_empty() else source,str(stats.get("name","School attack")))
 if adventure.arcade:adventure.game._hurt(id,amount,"enemy",source,credit)
 else:adventure.hit_player(id,amount,source,credit)
 if not protected and adventure.alive(id):adventure.combat.apply_hit_status("p:"+id,stats,"enemy",credit)
 if not protected and adventure.alive(id) and float(stats.get("slow_duration",0))>0:adventure.combat.apply_status("p:"+id,"slow",float(stats.slow_duration),"enemy",float(stats.get("slow_factor",.65)))
func telegraph(enemy:Dictionary,point:Vector2,radius:float,damage:float,delay:float=.85,stats:Dictionary={},end:Vector2=Vector2.ZERO,life:float=.15,shape:String="circle",size:Vector2=Vector2.ZERO,velocity:Vector2=Vector2.ZERO)->void:
 if hazards.size()>=70:return
 preload("res://scripts/enemy_visual227.gd").mark(adventure,enemy,minf(delay,.8))
 hazards.append({"uid":int(enemy.uid),"pos":a(point),"end":a(end),"radius":radius,"damage":damage,"warn":delay,"total":delay,"life":life,"tick":0.0,"stats":stats,"shape":shape,"size":a(size),"velocity":a(velocity),"hits":[]})
func dash(enemy:Dictionary,aim:Vector2,length:float,damage:float,width:float,speed:float=700)->void:
 var start:Vector2=enemy.pos;var end:=advance(start,aim,length,70 if str(enemy.type)=="yellow_bus" else 0)
 telegraph(enemy,start,width,damage,1.1 if str(enemy.type)=="yellow_bus" else .65,{"melee":true},end,2,"dash",Vector2(speed,0))
 enemy["school_busy"]=1.1 if str(enemy.type)=="yellow_bus" else .65
func shoot(enemy:Dictionary,target:Vector2,count:int,damage:float,spread:float,speed:float=280,stats:Dictionary={},style:String="projectile")->void:
 var origin:Vector2=enemy.pos;var aim:Vector2=(target-origin).normalized();var args:Dictionary=stats.duplicate();args["range"]=850;args["speed"]=speed
 if not args.has("color"):args["color"]="#b0c9d4"
 for n in count:adventure.combat.launch_projectile("enemy",origin+aim*30,aim.rotated((n-(count-1)*.5)*spread),args,damage,style)
func summon(enemy:Dictionary,kind:String,count:int,cap:int)->void:
 var living:=0
 for child in adventure.foes():
  if int(child.get("school_parent",-1))==int(enemy.uid):living+=1
 for n in mini(count,maxi(0,cap-living)):
  if adventure.foes().size()>=65:break
  var point:Vector2=enemy.pos+Vector2.from_angle(TAU*(n+.3)/maxi(1,count))*130
  if not can_stand(point):continue
  var child:=spawn_foe(kind,point,str(enemy.school_group));child["summoned"]=true;child["school_parent"]=int(enemy.uid)
func radial(enemy:Dictionary,count:int,damage:float,speed:float,stats:Dictionary={})->void:
 var args:=stats.duplicate();args["range"]=850;args["speed"]=speed
 for n in count:adventure.combat.launch_projectile("enemy",enemy.pos+Vector2.from_angle(TAU*n/count)*55,Vector2.from_angle(TAU*n/count+clock*.12),args,damage)
func step_enemies(delta:float)->void:
 var combat=adventure.combat
 for enemy in adventure.foes().duplicate():
  var kind:=str(enemy.type)
  if kind not in TYPES:continue
  if float(enemy.get("ghost",0))>0:
   enemy.ghost=maxf(0,float(enemy.ghost)-delta);enemy.buried=float(enemy.ghost)>0
   if float(enemy.ghost)<=0:telegraph(enemy,enemy.pos,175,23,.6,{"push":100})
  if combat.stunned(combat.npc_key(enemy)):continue
  var target:Vector2=enemy.pos;var distance:=INF
  for id in adventure.points():
   var hidden:bool=Time.get_ticks_msec()<int(adventure.game.stealth_until.get(id,0)) if adventure.arcade else adventure.game.stealth_time>0
   var p:Vector2=adventure.points()[id]
   if adventure.alive(str(id)) and not hidden and floor_id(p)==floor_id(enemy.pos) and (enemy.pos as Vector2).distance_to(p)<distance:distance=(enemy.pos as Vector2).distance_to(p);target=p
  if distance>1000:continue
  var busy:=false
  for hazard in hazards:
   if int(hazard.uid)==int(enemy.uid) and str(hazard.shape)=="dash":busy=true;break
  var anchor:Vector2=v(enemy.get("school_anchor",a(enemy.pos)))
  var ranged:=kind in ["paper_sprite","hall_monitor","gravel_skater","culture_blob"] or kind.begins_with("exam_") or kind=="spotlight_sovereign"
  var move:Vector2=direction(enemy,target,ranged)*float(definition(kind).get("speed",100))*combat.speed_factor(combat.npc_key(enemy))*delta
  if bool(enemy.boss) and kind!="yellow_bus" and distance<700:
   var orbit:Vector2=anchor+Vector2.from_angle(clock*.7)*150
   move=(orbit-(enemy.pos as Vector2)).normalized()*float(definition(kind).get("speed",100))*combat.speed_factor(combat.npc_key(enemy))*delta
  var destination:Vector2=enemy.pos+move
  var arena:Dictionary=room_at(anchor)
  if bool(enemy.boss) and not arena.is_empty() and not rect(arena.rect).grow(-75).has_point(destination):destination=enemy.pos
  if not busy and (distance>55 or ranged) and combat.path_clear(enemy.pos,destination):enemy.pos=destination
  if bool(enemy.get("buried",false)) or busy:continue
  enemy["school_timer"]=float(enemy.get("school_timer",1))-delta
  if float(enemy.school_timer)>0 or not combat.path_clear(enemy.pos,target):continue
  var aim:Vector2=(target-(enemy.pos as Vector2)).normalized();var turn:=int(enemy.get("school_turn",0));enemy.school_turn=turn+1
  enemy.school_timer=3.0
  match kind:
   "lesson_warden":
    enemy.school_timer=3.6
    if turn%2==0:telegraph(enemy,target,95,15,1.1)
    else:shoot(enemy,target,3,9,.25,235,{"color":"#e2c47d"})
   "pencil_scrapper","backpack_biter","chalkling":
    enemy.school_timer=.2
    if distance<90:enemy.school_timer=1.3;telegraph(enemy,enemy.pos,30,float(definition(kind).damage),.45,{"melee":true},advance(enemy.pos,aim,90),.15,"line")
   "paper_sprite":
    if enemy.get("volley_patrol",false):enemy.school_timer=3.7;radial(enemy,8,8,200,{"color":"#eed09a"})
    else:enemy.school_timer=2.1;shoot(enemy,target,2,7,.16,230,{"amplitude":20,"wavelength":160,"color":"#ece8ca"},"weaving")
   "hall_monitor":
    enemy.school_timer=3.4
    if turn%2==0:shoot(enemy,target,3,12,.19,265)
    else:telegraph(enemy,target,100,10,.9,{"slow_duration":1.7,"slow_factor":.7},Vector2.ZERO,1.7)
   "gravel_skater":
    enemy.school_timer=2.7
    if turn%3==2 and distance<470:dash(enemy,aim,distance*2,16,30,760)
    else:shoot(enemy,target,1,13,0,330,{"color":"#abb2b5"})
   "culture_blob":enemy.school_timer=2.8;shoot(enemy,target,1,10,0,225,{"poison_duration":3,"poison_damage":1,"color":"#bddb8b"})
   "yellow_bus":
    enemy.school_timer=5.2
    if turn%3==0:dash(enemy,aim,minf(1200,maxf(650,distance+300)),18,80,580)
    elif turn%3==2:telegraph(enemy,enemy.pos,380,6,.7,{"stun_duration":1.5,"color":"#ffe296"},Vector2.ZERO,1.3,"horn")
    else:summon(enemy,"chalkling",5,8);flashes.append({"pos":a(enemy.pos),"time":.8,"radius":100,"colour":"#e8ce7c"})
   "recess_ringleader":
    enemy.school_timer=3.2
    if turn%3==0:telegraph(enemy,target,95,12,.9)
    elif turn%3==1:shoot(enemy,target,3,9,.25,230,{"color":"#d8c182"})
    else:
     for n in 3:telegraph(enemy,target+aim.orthogonal()*(n-1)*120,60,10,.8+n*.3)
   "lunchline_leviathan":
    enemy.school_timer=3.1
    if turn%3==0:
     for n in 3:telegraph(enemy,target+aim.orthogonal()*(n-1)*90,65,18,1+n*.2,{"slow_duration":1.5,"slow_factor":.65},Vector2.ZERO,2)
    elif turn%3==1:shoot(enemy,target,5,15,.24,260,{"color":"#d4c49d"})
    else:dash(enemy,aim,350,20,50,450)
   "bellwork_colossus":
    enemy.school_timer=3.0
    if turn%3==0:radial(enemy,10,17,230,{"color":"#d9c995"})
    elif turn%3==1:
     for n in 3:telegraph(enemy,enemy.pos,35,21,.8+n*.25,{},advance(enemy.pos,Vector2.from_angle(clock+n*TAU/3),700),.2,"line")
    else:telegraph(enemy,target,150,24,1.2,{"slow_duration":1.3,"slow_factor":.75})
   "spotlight_sovereign":
    enemy.school_timer=2.8
    if turn%3==0:
     for n in 4:telegraph(enemy,enemy.pos,45,22,.8+n*.22,{},advance(enemy.pos,aim.rotated((n-1.5)*.28),700),.15,"line")
    elif turn%3==1:shoot(enemy,target,5,16,.22,330,{"color":"#f0d49a"})
    else:telegraph(enemy,target,110,25,.8)
   "layercake_golem":
    enemy.school_timer=3.0
    if turn%3==0:
     for n in 3:telegraph(enemy,target+Vector2.from_angle(n*TAU/3)*80,85,22,1+n*.15,{"slow_duration":2,"slow_factor":.65},Vector2.ZERO,2.0)
    elif turn%3==1:radial(enemy,10,16,230,{"color":"#e1b3b1"})
    else:summon(enemy,"culture_blob",3,5);dash(enemy,aim,320,22,60,430)
   "iron_barbell":
    enemy.school_timer=2.8
    if turn%3==0:telegraph(enemy,target,155,30,1.0);dash(enemy,aim,minf(450,distance),20,45,620)
    elif turn%3==1:shoot(enemy,target,3,23,.28,320,{"color":"#9cabb5"})
    else:
     for n in [-1,1]:telegraph(enemy,enemy.pos,52,26,.8,{},advance(enemy.pos,aim.orthogonal()*n,600),.2,"line")
   "exam_math","exam_english","exam_history","exam_science":exam_attack(enemy,target,turn%4)
func exam_attack(enemy:Dictionary,target:Vector2,turn:int)->void:
 var kind:=str(enemy.type);var distance:float=(target-(enemy.pos as Vector2)).length();var aim:Vector2=(target-(enemy.pos as Vector2)).normalized();enemy.school_timer=2.6 if float(enemy.hp)<float(enemy.max_hp)*.5 else 3.15
 var tint:=str(COLOURS.get(kind,"#e8d8bb"))
 match kind:
  "exam_math":
   var burn:Dictionary={"burn_duration":5,"burn_damage":2,"color":tint}
   match turn:
    0:shoot(enemy,target,7,19,.16,320,burn)
    1:
     for direction in [Vector2.RIGHT,Vector2.UP]:
      var start:=advance(target,-direction,330);var end:=advance(target,direction,330);telegraph(enemy,start,48,30,.95,burn,end,.25,"line")
    2:
     for n in 5:telegraph(enemy,target+Vector2.from_angle(TAU*n/5)*135,85,22,1+n*.16,burn,Vector2.ZERO,2.3)
    3:radial(enemy,14,18,280,burn)
  "exam_english":
   match turn:
    0:shoot(enemy,target,5,18,.18,390,{"color":tint,"amplitude":32,"wavelength":220},"weaving")
    1:enemy["ghost"]=2.6;enemy["buried"]=true;flashes.append({"pos":a(enemy.pos),"time":.7,"radius":90,"colour":tint})
    2:dash(enemy,aim,minf(900,distance*2),28,48,900)
    3:
     for n in 3:telegraph(enemy,enemy.pos+aim.orthogonal()*(n-1)*80,70,22,.85,{"push":100,"color":tint},Vector2.ZERO,2.2,"wave",Vector2.ZERO,aim.rotated((n-1)*.22)*270)
  "exam_history":
   var slow:Dictionary={"slow_duration":3,"slow_factor":.5,"color":tint}
   match turn:
    0:shoot(enemy,target,7,18,.17,300,slow)
    1:telegraph(enemy,target,0,27,1.05,slow,Vector2.ZERO,1.3,"rect",Vector2(540,230))
    2:
     for n in 3:telegraph(enemy,enemy.pos+aim.orthogonal()*(n-1)*75,85,24,.9+n*.25,slow,Vector2.ZERO,2.8,"wave",Vector2.ZERO,aim*240)
    3:telegraph(enemy,enemy.pos,300,12,1.1,{"slow_duration":2.6,"slow_factor":.4,"color":tint},Vector2.ZERO,4.2)
  "exam_science":
   var poison:Dictionary={"poison_duration":5,"poison_damage":2,"color":tint}
   match turn:
    0:
     for n in 3:telegraph(enemy,target+aim.orthogonal()*(n-1)*110,100,21,1+n*.2,poison,Vector2.ZERO,3)
    1:
     for n in 5:telegraph(enemy,advance(enemy.pos,aim,120+n*110),80,24,.8+n*.24,poison)
    2:radial(enemy,12,17,290,poison)
    3:summon(enemy,"culture_blob",4,6);shoot(enemy,target,3,18,.25,280,poison)
func step_hazards(delta:float)->void:
 var combat=adventure.combat
 for n in range(hazards.size()-1,-1,-1):
  var h:Dictionary=hazards[n];h.warn-=delta
  if float(h.warn)>0:continue
  h.life-=delta;h.tick-=delta
  var center:=v(h.pos);var end:=v(h.end);var kind:=str(h.shape)
  if kind=="dash":
   var actor:Dictionary={}
   for enemy in adventure.foes():
    if int(enemy.uid)==int(h.uid):actor=enemy;break
   if actor.is_empty():hazards.remove_at(n);continue
   var old:Vector2=actor.pos;var aim:Vector2=(end-old).normalized();var travel:=minf(old.distance_to(end),float(h.size[0])*delta)
   var next:=advance(old,aim,travel,70 if str(actor.type)=="yellow_bus" else 0)
   actor.pos=next
   for id in adventure.combat.v59.target_points():
    var p:Vector2=adventure.combat.v59.target_position(str(id))
    if not h.hits.has(str(id)) and Geometry2D.get_closest_point_to_segment(p,old,next).distance_to(p)<float(h.radius)+18 and combat.path_clear(next,p):h.hits.append(str(id));damage_player(str(id),float(h.damage),{},"e:"+str(h.uid))
   if next.distance_to(end)<12 or next.distance_to(old)<.1 or float(h.life)<=0:hazards.remove_at(n)
   continue
  if kind=="horn":
   var previous:=float(h.get("ring_radius",0))
   var radius:=minf(float(h.radius),previous+float(h.radius)*delta/1.3)
   h["ring_radius"]=radius
   for id in adventure.combat.v59.target_points():
    if not adventure.alive(str(id)) or h.hits.has(str(id)):continue
    var p:Vector2=adventure.combat.v59.target_position(str(id));var distance:=p.distance_to(center)
    if distance>=previous-22 and distance<=radius+22 and combat.path_clear(center,p):
     h.hits.append(str(id));damage_player(str(id),float(h.damage),h.stats,"e:"+str(h.uid) if bool(h.stats.get("melee",false)) else "","e:"+str(h.uid))
   if float(h.life)<=0:hazards.remove_at(n)
   continue
  if kind=="wave":
   var next:Vector2=center+v(h.velocity)*delta
   if not combat.path_clear(center,next):hazards.remove_at(n);continue
   h.pos=a(next);center=next
  if float(h.tick)<=0:
   h.tick=.8
   for id in adventure.combat.v59.target_points():
    if not adventure.alive(str(id)):continue
    var p:Vector2=adventure.combat.v59.target_position(str(id));var source:=center;var hit:=p.distance_to(center)<float(h.radius)
    if kind=="line":source=Geometry2D.get_closest_point_to_segment(p,center,end);hit=source.distance_to(p)<float(h.radius)
    elif kind=="rect":var bounds:=Rect2(center-v(h.size)*.5,v(h.size));hit=bounds.has_point(p)
    if not hit or not combat.path_clear(source,p):continue
    if kind in ["line","wave"] and h.hits.has(str(id)):continue
    h.hits.append(str(id));damage_player(str(id),float(h.damage),h.stats,"e:"+str(h.uid) if bool(h.stats.get("melee",false)) else "","e:"+str(h.uid))
    if float(h.stats.get("push",0))>0:combat.knock("p:"+str(id),(p-source).normalized(),float(h.stats.push))
  if float(h.life)<=0:hazards.remove_at(n)
func step(delta:float)->void:
 if not active or not adventure.authoritative():return
 clock+=delta;initialize();advance_progress()
 for door in data.doors:
  if not str(door.requires).is_empty() and unlocked(str(door.requires)) and not bool(opened.get(str(door.id),false)):open_door(door)
 step_enemies(delta);step_hazards(delta)
 for n in range(flashes.size()-1,-1,-1):
  flashes[n].time-=delta
  if float(flashes[n].time)<=0:flashes.remove_at(n)
func objective()->String:
 if done:return "School cleared! Return to the glowing street exit and Interact."
 if region_id=="high_school":
  if not completed.has("arrival"):return "Enter the school and clear the first hallway. Watch the Gravel Skater’s charge."
  if not completed.has("departments"):return "Defeat Drama, Foods and Athletics: "+str(boss_dead.size())+"/3 department seals."
  if not completed.has("upper"):return "Take the marked stairs upstairs. Clear the upstairs corridor and classrooms."
  if exam_choice.is_empty():return "Open the Final Exam classroom and enter. One of four exams awaits."
  return str(definition(exam_choice).name)+" • defeat it, then return to the street."
 return str(data.stages[mini(stage,data.stages.size()-1)].text)+( "  Gears: "+str(collected.size())+"/3" if region_id=="middle_school" and stage==1 else "")
func guidance(point:Vector2)->Vector2:
 var target:=v(data.exit);var distance:=INF
 if not done and region_id=="elementary" and str(data.stages[mini(stage,data.stages.size()-1)].id) in ["return","bus"]:
  return v(data.exit) if str(data.stages[stage].id)=="return" else v(data.stages[stage].pos)
 if not done:
  for enemy in adventure.foes():
   if bool(enemy.get("summoned",false)):continue
   var d:float=point.distance_to(enemy.pos)
   if d<distance:distance=d;target=enemy.pos
  if distance==INF:
   if region_id=="high_school":target=Vector2(12050,2400) if not completed.has("upper") else Vector2(11950,2250) if not bool(opened.get("exam",false)) else Vector2(12050,1450)
   else:
    var current:Dictionary=data.stages[mini(stage,data.stages.size()-1)]
    if current.has("pos"):target=v(current.pos)
    if bool(current.get("collect",false)):
     for gear in data.gears:
      if not collected.has(str(gear.id)):target=v(gear.pos);break
 if floor_id(point)!=floor_id(target):
  for route in data.routes:
   if floor_id(v(route.pos))==floor_id(point) and unlocked(str(route.requires)):return v(route.pos)
 for door in data.doors:
  if bool(opened.get(str(door.id),false)) or not unlocked(str(door.requires)):continue
  if door_rect(door).get_center().distance_to(point)<300:return v(door.pos)
 return target
func body_size(kind:String)->Vector2:
 if kind=="lesson_warden":return Vector2(82,94)
 if kind=="yellow_bus":return Vector2(300,180)
 if kind=="iron_barbell":return Vector2(190,125)
 if kind in EXAMS:return Vector2(150,150)
 if kind in ["recess_ringleader","lunchline_leviathan","bellwork_colossus","spotlight_sovereign","layercake_golem"]:return Vector2(140,145)
 return Vector2(60,64)
func snapshot()->Dictionary:return {"stage":stage,"completed":completed,"spawned":spawned,"boss_dead":boss_dead,"opened":opened,"collected":collected,"initialized":initialized,"done":done,"exam_choice":exam_choice,"clock":clock,"hazards":hazards,"flashes":flashes}
func receive(packet:Dictionary)->void:
 if not active:return
 stage=int(packet.get("stage",0));completed=packet.get("completed",[]);spawned=packet.get("spawned",{});boss_dead=packet.get("boss_dead",{});collected=packet.get("collected",[]);initialized=bool(packet.get("initialized",false));done=bool(packet.get("done",false));exam_choice=str(packet.get("exam_choice",""));clock=float(packet.get("clock",clock));hazards=packet.get("hazards",[]);flashes=packet.get("flashes",[])
 for door in data.doors:
  if bool(packet.get("opened",{}).get(str(door.id),false)) and not bool(opened.get(str(door.id),false)):open_door(door)
func draw_world(canvas:Node2D,camera:Vector2)->void:
 if not active:return
 var view:Vector2=adventure.game.VIEW;var bounds:=Rect2(camera-Vector2(280,280),view+Vector2(560,560))
 if floor_chunks.is_empty():build_floor_chunks(canvas)
 for chunk in floor_chunks:
  chunk.position=-camera
  chunk.visible=chunk.world_bounds.intersects(Rect2(camera,view).grow(80))
 for room in data.rooms:
  var r:=rect(room.rect)
  if not bounds.intersects(r) or str(room.name).is_empty():continue
  var center:=r.get_center()-camera
  if str(room.id)=="street":
   canvas.draw_rect(Rect2(r.position+Vector2(0,22)-camera,Vector2(r.size.x,64)),Color("#9badae"));canvas.draw_rect(Rect2(r.position+Vector2(0,r.size.y-72)-camera,Vector2(r.size.x,50)),Color("#9badae"))
   for n in range(1,int(r.size.x/450)):
    var p:Vector2=r.position+Vector2(n*450,75)-camera
    if region_id=="elementary":preload("res://scripts/firstbell_art256.gd").lamp(canvas,p)
    else:canvas.draw_rect(Rect2(p+Vector2(-9,-58),Vector2(18,77)),Color("#536776"));canvas.draw_rect(Rect2(p+Vector2(-16,-73),Vector2(32,28)),Color("#d5d8aa"));canvas.draw_rect(Rect2(p+Vector2(-12,-68),Vector2(24,17)),Color("#ece6bb"))
  if str(room.id)=="entry":
   var p:Vector2=v(data.doors[0].pos)-Vector2(0,45)-camera
   if region_id=="elementary":preload("res://scripts/firstbell_art256.gd").entrance(canvas,p,str(data.name).to_upper())
   else:
    canvas.draw_rect(Rect2(p+Vector2(-260,-115),Vector2(520,68)),Color("#6a7e8a"));canvas.draw_rect(Rect2(p+Vector2(-268,-125),Vector2(536,12)),Color("#c9b993"))
    var title:=str(data.name).to_upper();var title_width:=ThemeDB.fallback_font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,24).x
    canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-title_width*.5,-70),title,HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("#f1e2b9"))
    for sign in [-1,1]:
     canvas.draw_rect(Rect2(p+Vector2(sign*270-30,-115),Vector2(60,170)),Color("#819296"));canvas.draw_rect(Rect2(p+Vector2(sign*270-40,-122),Vector2(80,16)),Color("#c7cabc"))
   for n in 5:canvas.draw_rect(Rect2(Vector2(p.x-155+n*70,r.end.y-camera.y-50),Vector2(40,100)),Color("#d8d5b9"))
  if str(room.theme)=="wood":
   canvas.draw_rect(Rect2(r.position+Vector2(100,170)-camera,r.size-Vector2(200,260)),Color("#e0d0a6"),false,3);canvas.draw_arc(center,140,0,TAU,64,Color("#e0d0a6"),3);canvas.draw_line(center-Vector2(r.size.x*.4,0),center+Vector2(r.size.x*.4,0),Color("#e0d0a6"),3)
  elif str(room.theme)=="stage":
   canvas.draw_rect(Rect2(r.position+Vector2(150,160)-camera,Vector2(r.size.x-300,330)),Color("#4b4656"));canvas.draw_line(r.position+Vector2(150,490)-camera,r.position+Vector2(r.size.x-150,490)-camera,Color("#bc9569"),6)
  elif str(room.id)=="playground":
   for n in 4:canvas.draw_rect(Rect2(center+Vector2((n%2)*75-75,(n/2)*75),Vector2(60,60)),Color("#d4ceb0"),false,3)
  if str(room.theme) not in ["street","yard","sand","roof"]:
   for n in range(1,maxi(2,int(r.size.x/340))):
    var p:Vector2=r.position+Vector2(n*320,38)-camera
    canvas.draw_rect(Rect2(p-Vector2(55,0),Vector2(110,45)),Color("#405665"));canvas.draw_rect(Rect2(p-Vector2(47,-5),Vector2(94,30)),Color("#91bbc9"));canvas.draw_line(p+Vector2(0,5),p+Vector2(0,35),Color("#c4d5cf"),3)
   if str(room.id) in ["hall","upper_hall","foyer"]:
    for n in range(1,int(r.size.x/600)):
     var p:Vector2=r.position+Vector2(n*600,r.size.y-70)-camera
     if region_id=="elementary" and str(room.id)=="foyer":p.y=minf(p.y,3740-camera.y)
     canvas.draw_rect(Rect2(p-Vector2(42,35),Vector2(84,58)),Color("#bbab88"));canvas.draw_rect(Rect2(p-Vector2(36,29),Vector2(72,46)),Color("#8a9eae"));canvas.draw_circle(p-Vector2(16,12),10,Color("#e3cc8d"));canvas.draw_line(p+Vector2(1,4),p+Vector2(27,-15),Color("#9acaac"),5)
  if region_id=="elementary" and str(room.id)=="entry":continue
  var label_offset=240 if region_id=="elementary" and str(room.id)=="street"else 100
  var label:=str(room.name);var length:=ThemeDB.fallback_font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,21).x
  canvas.draw_rect(Rect2(Vector2(center.x-length*.5-12,r.position.y+label_offset-camera.y),Vector2(length+24,35)),Color(.1,.17,.22,.85));canvas.draw_string(ThemeDB.fallback_font,Vector2(center.x-length*.5,r.position.y+label_offset+25-camera.y),label,HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("#f0dfb4"))
 for prop in data.props:
  if bounds.has_point(v(prop.pos)):canvas.draw_texture_rect(textures[str(prop.kind)],Rect2(v(prop.pos)-v(prop.size)*Vector2(.5,.7)-camera,v(prop.size)),false)
 for door in data.doors:
  var r:=door_rect(door);var p:=v(door.pos)-camera
  if not bounds.intersects(r):continue
  var ready:=unlocked(str(door.requires));var colour:=Color("#91b7a0") if ready else Color("#ba917b")
  if bool(opened.get(str(door.id),false)):
   for sign in [-1,1]:
    var post:Vector2=p+Vector2(sign*r.size.x*.5,0)
    canvas.draw_rect(Rect2(post-Vector2(5,15),Vector2(10,30)),Color("#7d725f"))
    canvas.draw_circle(post,4,Color("#91b7a0"))
   continue
  if region_id=="elementary":preload("res://scripts/firstbell_art256.gd").door(canvas,Rect2(r.position-camera,r.size),ready)
  else:
   canvas.draw_rect(Rect2(r.position-camera,r.size),Color("#7d725f"))
   canvas.draw_line(p-Vector2(r.size.x*.5,0),p+Vector2(r.size.x*.5,0),colour,4 if bool(opened.get(str(door.id),false)) else 10)
  if not bool(opened.get(str(door.id),false)):
   canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-53,-20),"INTERACT" if ready else "SEALED",HORIZONTAL_ALIGNMENT_LEFT,-1,17,colour)
 for route in data.routes:
  var p:=v(route.pos)-camera
  if not bounds.has_point(v(route.pos)):continue
  canvas.draw_rect(Rect2(p-Vector2(55,55),Vector2(110,100)),Color("#506472"))
  for n in 5:canvas.draw_rect(Rect2(p+Vector2(-48,-45+n*17),Vector2(95,14)),Color("#c0bda8").darkened(n*.07))
  canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-95,-75),str(route.name),HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("#e6d3a0"));canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-35,75),"INTERACT" if unlocked(str(route.requires)) else "SEALED",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#c4e5d7"))
 for gear in data.gears:
  if collected.has(str(gear.id)) or not bounds.has_point(v(gear.pos)):continue
  var p:=v(gear.pos)-camera
  canvas.draw_arc(p,24,clock,clock+TAU*.9,20,Color("#e5ca82"),5);canvas.draw_circle(p,8,Color("#b59764"));canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-45,-40),str(gear.name),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#eaddaa"))
 if done:
  var p:=v(data.exit)-camera;preload("res://scripts/realm_portals258.gd").draw_at(canvas,adventure.game,v(data.exit),camera);canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-65,-98),"STREET EXIT",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("#c1f2d3"))
func draw_on(canvas:Node2D,camera:Vector2)->void:
 if not active:return
 for h in hazards:
  var p:=v(h.pos)-camera;var end:=v(h.end)-camera;var waiting:=float(h.warn)>0;var tint:=Color(str(h.stats.get("color","#ecbe83")));var alpha:=.12 if waiting else .28;tint.a=.85
  if waiting:
   var cues=preload("res://scripts/combat_cues.gd")
   if str(h.shape) in ["line","dash"]:cues.corridor(canvas,p,end,float(h.radius))
   elif str(h.shape)=="rect":cues.rectangle(canvas,Rect2(p-v(h.size)*.5,v(h.size)),float(h.warn),float(h.total))
   else:cues.danger(canvas,p,float(h.radius),float(h.warn),float(h.total),tint)
   if str(h.shape)=="horn":canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-24,-95),"HORN",HORIZONTAL_ALIGNMENT_LEFT,-1,18,tint)
   continue
  match str(h.shape):
   "line","dash":canvas.draw_line(p,end,Color(tint,alpha),float(h.radius)*2,true);canvas.draw_line(p,end,tint,3,true);canvas.draw_circle(end,8,tint)
   "horn":
    var radius:=float(h.radius) if waiting else float(h.get("ring_radius",0))
    canvas.draw_arc(p,radius,0,TAU,64,Color(tint,.3 if waiting else .9),3 if waiting else 7,true)
    if waiting:canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-24,-95),"HORN",HORIZONTAL_ALIGNMENT_LEFT,-1,18,tint)
    else:canvas.draw_arc(p,maxf(0,radius-16),0,TAU,64,Color(tint,.3),3,true)
   "rect":canvas.draw_rect(Rect2(p-v(h.size)*.5,v(h.size)),Color(tint,alpha));canvas.draw_rect(Rect2(p-v(h.size)*.5,v(h.size)),tint,false,3)
   _:
    canvas.draw_circle(p,float(h.radius),Color(tint,alpha));canvas.draw_arc(p,float(h.radius),0,TAU,48,tint,3)
    if waiting:canvas.draw_arc(p,20,-PI*.5,-PI*.5+TAU*(1-float(h.warn)/maxf(.1,float(h.total))),24,tint,3)
    if str(h.shape)=="wave":canvas.draw_arc(p,float(h.radius)*.55,clock*3,clock*3+PI,24,tint,3)
 for enemy in adventure.foes():
  if float(enemy.get("ghost",0))>0:
   var p:Vector2=enemy.pos-camera;canvas.draw_arc(p,38,clock*2,clock*2+TAU*.8,32,Color(.7,.9,.82,.35),4);canvas.draw_line(p+Vector2(-15,-35),p+Vector2(15,25),Color(.7,.9,.82,.25),3);canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-28,-52),"GHOST",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#b0dacc"))
  if bool(enemy.boss):
   var p:Vector2=enemy.pos-camera;var size:=body_size(str(enemy.type));canvas.draw_rect(Rect2(p+Vector2(-75,-size.y*.7-20),Vector2(150,7)),Color("#263641"));canvas.draw_rect(Rect2(p+Vector2(-75,-size.y*.7-20),Vector2(150*clampf(float(enemy.hp)/float(enemy.max_hp),0,1),7)),Color("#e8b880"))
 for flash in flashes:canvas.draw_arc(v(flash.pos)-camera,float(flash.radius)*(1.6-float(flash.time)),0,TAU,32,Color(str(flash.colour),minf(.6,float(flash.time))),4)
func draw_hud(canvas:Node2D)->void:
 if not active:return
 var view:Vector2=adventure.game.VIEW;var width:=minf(880,view.x-210);var point:Vector2=adventure.points().get(adventure.game.my_id,adventure.game.local_pos) if adventure.arcade else adventure.game.position_in_world
 var top=preload("res://scripts/hud_layout.gd").objective_top(canvas,adventure.arcade)
 canvas.draw_rect(Rect2(18,top,width+20,65),Color(.07,.14,.18,.9));canvas.draw_multiline_string(ThemeDB.fallback_font,Vector2(28,top+25),objective(),HORIZONTAL_ALIGNMENT_LEFT,width,18,2,Color("#f2dfb4"))
 var center:=Vector2(view.x-90,top+20);var aim:Vector2=(guidance(point)-point).normalized();canvas.draw_arc(center,24,0,TAU,32,Color("#c9e2d7"),2);canvas.draw_line(center,center+aim*20,Color("#c9e2d7"),5)
 canvas.draw_string(ThemeDB.fallback_font,center+Vector2(-33,45),"OBJECTIVE",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#e5e8d4"))

func build_floor_chunks(canvas:Node2D)->void:
 # Immutable floors are drawn once per chunk. Doors, actors and objectives stay live.
 var chunks:Dictionary={}
 var backdrop=preload("res://scripts/school_floor_chunk.gd").new();backdrop.source=self;backdrop.background=true;backdrop.world_bounds=Rect2(-Vector2.ONE*32768,Vector2.ONE*65536);canvas.add_child(backdrop);floor_chunks.append(backdrop)
 for geometry in room_geometry:
  var room:Dictionary=geometry.room;var bounds:Rect2=geometry.rect
  for x in range(floori(bounds.position.x/64),ceili(bounds.end.x/64)):
   for y in range(floori(bounds.position.y/64),ceili(bounds.end.y/64)):
    var cell=Vector2i(x,y);var point=Vector2(x*64+32,y*64+32)
    if floor_tiles.has(cell) or not bounds.has_point(point):continue
    var edges=[]
    for side in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
     if not floor_at(point+side*64):edges.append(side)
    var tile={"cell":cell,"room":room,"edges":edges};floor_tiles[cell]=tile
    var key=Vector2i(floori(float(x)/8),floori(float(y)/8))
    if not chunks.has(key):chunks[key]=[]
    chunks[key].append(tile)
 for key in chunks:
  var chunk=preload("res://scripts/school_floor_chunk.gd").new();chunk.source=self;chunk.tiles=chunks[key];chunk.world_bounds=Rect2(Vector2(key)*512,Vector2(512,512));canvas.add_child(chunk);floor_chunks.append(chunk)
