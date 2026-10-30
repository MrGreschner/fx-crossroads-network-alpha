extends Node
## A connected sci-fi realm and a boss whose intelligence survives three uploads.
var adventure:Node
var active:=false
var data:Dictionary={}
var initialized:=false
var stage:=0
var boss_live:=false
var upload:=0.0
var done:=false
var clock:=0.0
var hazards:Array=[]
var wrecks:Array=[]
var towers:Dictionary={}
var used_pods:Dictionary={}
var grid:AStarGrid2D
var routes:Dictionary={}
var blockers:Dictionary={}
var tile:Texture2D
const TYPES=["hatch_sentinel","sweep_drone","magnet_hauler","repair_wisp","fork_runner","relay_weaver","continuum_forge","continuum_archive","continuum_reactor","continuum_crown"]
func v(a:Array)->Vector2:return Vector2(float(a[0]),float(a[1]))
func a(p:Vector2)->Array:return [p.x,p.y]
func rect(r:Array)->Rect2:return Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3]))
func body_size(kind:String)->Vector2:
 match kind:
  "continuum_forge":return Vector2(120,128)
  "continuum_archive":return Vector2(124,124)
  "continuum_reactor":return Vector2(154,142)
  "continuum_crown":return Vector2(128,160)
  "magnet_hauler":return Vector2(70,76)
  "hatch_sentinel":return Vector2(56,64)
 return Vector2(56,56)
func definitions()->Dictionary:return adventure.game.enemy_defs if adventure.arcade else adventure.game.enemy_types
func setup(id:String)->void:
 active=id=="neon_crucible";initialized=false;stage=0;boss_live=false;upload=0;done=false;clock=0;hazards.clear();wrecks.clear();towers.clear();used_pods.clear();routes.clear();blockers.clear();grid=null;data={}
 if not active:return
 data=JSON.parse_string(FileAccess.get_file_as_string("res://content/campaigns/neon_crucible.json"));tile=load("res://assets/neon_plate.png")
 for prop in data.props:
  if not prop.has("solid"):continue
  var bounds:=Rect2(v(prop.pos)-v(prop.solid)*.5,v(prop.solid)).grow(18)
  for x in range(floori(bounds.position.x/128),floori(bounds.end.x/128)+1):
   for y in range(floori(bounds.position.y/128),floori(bounds.end.y/128)+1):
    var cell:=Vector2i(x,y)
    if not blockers.has(cell):blockers[cell]=[]
    blockers[cell].append(bounds)
 var world_size:=v(data.get("size",[6400,4800]))
 grid=AStarGrid2D.new();grid.region=Rect2i(0,0,ceili(world_size.x/50),ceili(world_size.y/50));grid.cell_size=Vector2(50,50);grid.offset=Vector2(25,25);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
 preload("res://scripts/navigation_cache.gd").populate(grid,"tech_"+id,JSON.stringify(data),func(point):return not can_stand(point))
func floor_at(point:Vector2)->bool:
 for room in data.get("rooms",[]):
  if rect(room.rect).grow(-18).has_point(point):return true
 return false
func can_stand(point:Vector2)->bool:
 if not floor_at(point):return false
 for bounds in blockers.get(Vector2i(floori(point.x/128),floori(point.y/128)),[]):
  if (bounds as Rect2).has_point(point):return false
 return true
func advance(origin:Vector2,aim:Vector2,distance:float)->Vector2:
 var result:=origin
 for n in maxi(1,ceili(distance/10)):
  var next:=origin+aim.normalized()*minf(distance,(n+1)*10)
  if not can_stand(next):break
  result=next
 return result
func spawn(kind:String,point:Vector2,sector:int,boss:bool=false,hp:float=-1)->Dictionary:
 adventure.spawn(kind,point,float(definitions().get(kind,{}).get("health",80)) if hp<0 else hp,boss)
 var enemy:Dictionary=adventure.foes()[-1];enemy.tech_sector=sector;enemy.tech_anchor=a(point);enemy.tech_timer=1.1;enemy.tech_turn=0;enemy.hit_radius=62.0 if kind=="continuum_reactor" else 48.0 if boss else 28.0 if kind=="magnet_hauler" else 21.0
 if kind=="hatch_sentinel":enemy.buried=true;towers[str(enemy.uid)]={"pos":a(point),"rise":-1.0}
 return enemy
func initialize()->void:
 if initialized:return
 initialized=true
 for entry in data.spawns:spawn(str(entry.type),v(entry.pos),int(entry.sector))
 adventure.announce("Neon Crucible: clear the foundry defenders. Continuum's backup bodies wait across the complex.")
func remaining(sector:int)->int:
 var count:=0
 for enemy in adventure.foes():
  if int(enemy.get("tech_sector",-1))==sector and not bool(enemy.boss) and not bool(enemy.get("summoned",false)):count+=1
 return count
func spawn_body()->void:
 if stage>=data.bodies.size() or boss_live or done:return
 var body:Dictionary=data.bodies[stage];spawn(str(body.type),v(body.pos),stage,true,float(body.hp));boss_live=true
 if adventure.arcade:
  for id in adventure.points():adventure.game.levels[id]=maxi(int(adventure.game.levels.get(id,1)),mini(10,6+stage))
 adventure.announce("Continuum • "+str(body.name)+" • body "+str(stage+1)+"/"+str(data.bodies.size()))
func on_defeat(enemy:Dictionary)->bool:
 if not active:return false
 routes.erase(int(enemy.uid));towers.erase(str(enemy.uid))
 for n in range(hazards.size()-1,-1,-1):
  if int(hazards[n].uid)==int(enemy.uid) and float(hazards[n].warn)>0 and str(hazards[n].style)!="fence":hazards.remove_at(n)
 if not str(enemy.type).begins_with("continuum_"):return false
 wrecks.append({"pos":a(enemy.pos),"type":str(enemy.type)})
 for n in range(hazards.size()-1,-1,-1):
  if int(hazards[n].uid)==int(enemy.uid):hazards.remove_at(n)
 boss_live=false;stage+=1
 if stage>=data.bodies.size():
  done=true;upload=0;hazards.clear()
  if not adventure.arcade:adventure.game.boss_spawned=true;adventure.game.boss_defeated=true
  adventure.announce("Continuum's last backup is erased. Use the glowing uplink exit: E / Interact.")
 else:
  upload=2.5
  adventure.announce("BODY DESTROYED • upload detected at "+str(data.bodies[stage].name)+". Follow the cyan signal!")
 return true
func interact(id:String)->bool:
 if not active or not adventure.authoritative() or not adventure.alive(id):return false
 var point:Vector2=adventure.points().get(id,Vector2.ZERO)
 if done and point.distance_to(v(data.exit))<150:
  if adventure.arcade:adventure.game.end_match("Neon Crucible restored • all four Continuum bodies defeated")
  else:adventure.game.finish_run(true)
  return true
 for pod in data.pods:
  if point.distance_to(v(pod.pos))>110:continue
  var token:=str(pod.id)+":"+id
  if used_pods.has(token):adventure.announce("This maintenance pod has already repaired you.");return true
  if remaining(int(pod.sector))>0:adventure.announce("Clear this sector before using its maintenance pod.");return true
  used_pods[token]=true
  if adventure.arcade:adventure.game.health[id]=mini(adventure.game._max_hp(id),int(adventure.game.health[id])+30)
  else:adventure.game.health=minf(adventure.game.max_health(),adventure.game.health+30)
  adventure.announce("Maintenance complete • +30 HP. One repair per explorer per pod.");return true
 return false
func direction(enemy:Dictionary,target:Vector2,ranged:bool)->Vector2:
 target=adventure.combat.fern.redirect(enemy,target)
 var origin:Vector2=enemy.pos
 if adventure.combat.path_clear(origin,target):return adventure.combat.ranged_direction(enemy,target) if ranged else (target-origin).normalized()
 var key:=int(enemy.uid);var entry:Dictionary=routes.get(key,{})
 if clock>float(entry.get("until",0)):
  var start:=Vector2i(floori(origin.x/50),floori(origin.y/50));var end:=Vector2i(floori(target.x/50),floori(target.y/50));var path:=PackedVector2Array()
  if grid.is_in_boundsv(start) and grid.is_in_boundsv(end) and not grid.is_point_solid(start) and not grid.is_point_solid(end):path=grid.get_point_path(start,end)
  entry={"path":path,"until":clock+.7};routes[key]=entry
 for waypoint in entry.get("path",[]):
  if origin.distance_to(waypoint)>35:return (waypoint-origin).normalized()
 return Vector2.ZERO
func hazard(enemy:Dictionary,point:Vector2,end:Vector2,style:String,radius:float,damage:float,delay:float,life:float=.25)->void:
 if hazards.size()>=64:return
 hazards.append({"uid":int(enemy.uid),"pos":a(point),"end":a(end),"style":style,"radius":radius,"damage":damage,"warn":delay,"total":delay,"life":life,"hits":[],"tick":0.0})
func beam(enemy:Dictionary,target:Vector2,count:int=3)->void:
 var origin:Vector2=enemy.pos;var aim:Vector2=(target-origin).normalized()
 for n in count:
  var end:=advance(origin,aim.rotated((n-(count-1)*.5)*.23),650)
  hazard(enemy,origin,end,"beam",18,20 if enemy.boss else 12,.7+n*.23,.3)
func missiles(enemy:Dictionary,target:Vector2,count:int,damage:float)->void:
 var aim:Vector2=(target-enemy.pos).normalized()
 for n in count:adventure.combat.robot.launch("enemy",enemy.pos+aim*28,aim.rotated((n-(count-1)*.5)*.25),damage,"p:"+nearest_player(enemy.pos))
func nearest_player(point:Vector2)->String:
 var chosen:="";var distance:=INF
 for id in adventure.points():
  if not adventure.alive(str(id)):continue
  var d:float=point.distance_to(adventure.points()[id])
  if d<distance:distance=d;chosen=str(id)
 return chosen
func skill(enemy:Dictionary,target:Vector2)->void:
 preload("res://scripts/enemy_visual227.gd").mark(adventure,enemy,.65)
 var kind:=str(enemy.type);var origin:Vector2=enemy.pos;var aim:Vector2=(target-origin).normalized();var turn:=int(enemy.tech_turn);enemy.tech_turn=turn+1
 match kind:
  "hatch_sentinel":
   var end:=advance(origin,aim,570);hazard(enemy,origin,end,"turret",10,0,.5)
  "sweep_drone":beam(enemy,target)
  "magnet_hauler":hazard(enemy,origin,advance(origin,aim,360),"tether",23,18,.8)
  "repair_wisp":
   for n in [-1,0,1]:adventure.combat.launch_projectile("enemy",origin+aim*22,aim.rotated(n*.2),{"range":520,"speed":220,"curve":.45,"color":"#a2e8a4"},8,"spiral_shot")
  "fork_runner":hazard(enemy,origin,advance(origin,aim,330),"dash",27,17,.65,1.0)
  "relay_weaver":
   var side:=aim.rotated(PI*.5);var left:=advance(target,-side,160);var right:=advance(target,side,160)
   hazard(enemy,left,right,"fence",22,14,.9,2.7)
  "continuum_forge":
   if turn%3==0:missiles(enemy,target,3,16)
   elif turn%3==1:hazard(enemy,origin,advance(origin,aim,450),"tether",32,26,.8)
   else:
    for n in 3:hazard(enemy,advance(target,aim,(n-1)*95),Vector2.ZERO,"pulse",75,22,.9+n*.2)
  "continuum_archive":
   if turn%3==0:beam(enemy,target,5)
   elif turn%3==1:missiles(enemy,target,4,15)
   else:
    var children:=0
    for foe in adventure.foes():
     if bool(foe.get("summoned",false)):children+=1
    for n in mini(2,maxi(0,4-children)):
     var p:=advance(origin,Vector2.from_angle(clock+n*PI),150)
     var child:=spawn("fork_runner",p,stage);child.summoned=true
  "continuum_reactor":
   if turn%3==0:
    for n in 12:adventure.combat.launch_projectile("enemy",origin,Vector2.from_angle(TAU*n/12+clock*.2),{"range":800,"speed":205,"curve":.65,"slow_duration":1.2,"slow":.65,"color":"#8ce8ef"},17,"spiral_shot")
   elif turn%3==1:missiles(enemy,target,4,18)
   else:hazard(enemy,target,Vector2.ZERO,"coolant",150,12,1.0,3.5)
  "continuum_crown":
   if turn%4==0:missiles(enemy,target,5,19)
   elif turn%4==1:beam(enemy,target,5)
   elif turn%4==2:hazard(enemy,origin,advance(origin,aim,420),"dash",40,28,.7,1.2)
   else:
    for n in 5:
     var p:=advance(target,Vector2.from_angle(TAU*n/5),170)
     hazard(enemy,p,Vector2.ZERO,"pulse",85,25,.95+n*.18)
func damage_player(id:String,amount:float,style:String,origin:Vector2,source:String="",credit_source:String="")->void:
 if not adventure.alive(id):return
 var protected:bool=Time.get_ticks_msec()<int(adventure.game.invincible_until.get(id,0)) if adventure.arcade else adventure.game.invulnerable_time>0
 var credit:Dictionary=preload("res://scripts/defeat_credit.gd").resolve(adventure.game,credit_source if not credit_source.is_empty() else source,style.replace("_"," ").capitalize())
 if adventure.arcade:adventure.game._hurt(id,amount,"enemy",source,credit)
 else:adventure.hit_player(id,amount,source,credit)
 if protected or not adventure.alive(id):return
 if style in ["coolant","tether"]:adventure.combat.apply_status("p:"+id,"slow",1.5,"enemy",.6)
 if style=="tether":adventure.combat.knock("p:"+id,(origin-adventure.combat.v59.target_position(str(id))).normalized(),85)
func step_hazards(delta:float)->void:
 for n in range(hazards.size()-1,-1,-1):
  var entry:Dictionary=hazards[n];entry.warn-=delta
  if float(entry.warn)>0:continue
  var origin:=v(entry.pos);var end:=v(entry.end);var style:=str(entry.style)
  if style=="turret":
   var aim:Vector2=(end-origin).normalized()
   for angle in [-.12,0,.12]:adventure.combat.launch_projectile("enemy",origin+aim*24,aim.rotated(angle),{"range":650,"speed":340,"color":"#f7ba77"},11)
   hazards.remove_at(n);continue
  var start:=origin
  if style=="dash":
   var foe:Dictionary={}
   for candidate in adventure.foes():
    if int(candidate.uid)==int(entry.uid):foe=candidate;break
   if foe.is_empty():hazards.remove_at(n);continue
   start=foe.pos
   var distance:float=start.distance_to(end);var next:=advance(start,(end-start).normalized(),minf(distance,480*delta))
   foe.pos=next;origin=start;end=next
   if next.distance_to(v(entry.end))<12:entry.life=0
  entry.tick-=delta
  for id in adventure.combat.v59.target_points():
   if not adventure.alive(str(id)):continue
   if style not in ["fence","coolant"] and str(id) in entry.hits:continue
   if style in ["fence","coolant"] and float(entry.tick)>0:continue
   var point:Vector2=adventure.combat.v59.target_position(str(id));var inside:=point.distance_to(origin)<=float(entry.radius)
   if style in ["beam","tether","fence","dash"]:inside=Geometry2D.get_closest_point_to_segment(point,origin,end).distance_to(point)<float(entry.radius)+16
   if inside and adventure.combat.path_clear(origin,point):entry.hits.append(str(id));damage_player(str(id),float(entry.damage),style,origin,"","e:"+str(entry.uid))
  if float(entry.tick)<=0:entry.tick=.8
  entry.life-=delta
  if float(entry.life)<=0:hazards.remove_at(n)
func step(delta:float)->void:
 if not active or not adventure.authoritative():return
 clock+=delta;initialize()
 if not done:
  if stage==0 and not boss_live and upload<=0 and remaining(0)==0:spawn_body()
  elif upload>0:
   upload-=delta
   if upload<=0:spawn_body()
 step_hazards(delta)
 for enemy in adventure.foes().duplicate():
  if str(enemy.type) not in TYPES:continue
  var origin:Vector2=enemy.pos;var id:=nearest_player(origin)
  if id.is_empty():continue
  var target:Vector2=adventure.points()[id];var distance:float=origin.distance_to(target);var kind:=str(enemy.type)
  if kind=="hatch_sentinel":
   var tower:Dictionary=towers.get(str(enemy.uid),{"pos":a(origin),"rise":-1.0})
   if float(tower.rise)<0 and distance<620:tower.rise=0.0
   if float(tower.rise)>=0:tower.rise=minf(1,float(tower.rise)+delta/.75)
   towers[str(enemy.uid)]=tower;enemy.buried=float(tower.rise)<1
   if enemy.buried:continue
  if adventure.combat.stunned(adventure.combat.npc_key(enemy)):continue
  if distance>850:continue
  var busy:=false
  for h in hazards:
   if int(h.uid)==int(enemy.uid) and str(h.style)=="dash":busy=true
  if not busy and kind!="hatch_sentinel":
   var ranged:=kind in ["sweep_drone","repair_wisp","relay_weaver","continuum_archive","continuum_reactor","continuum_crown"]
   var heading:=direction(enemy,target,ranged)
   var speed:float=float(definitions().get(kind,{}).get("speed",80))*adventure.combat.speed_factor(adventure.combat.npc_key(enemy))
   var move:Vector2=heading*speed*delta;var next:=advance(origin,move,move.length())
   enemy.pos=next
  enemy.tech_timer=float(enemy.get("tech_timer",1))-delta
  if kind=="repair_wisp":
   enemy.tech_heal=float(enemy.get("tech_heal",.5))-delta
   if float(enemy.tech_heal)<=0:
    enemy.tech_heal=1.0
    for ally in adventure.foes():
     if str(ally.type) in TYPES and int(ally.uid)!=int(enemy.uid) and float(ally.hp)>0 and (ally.pos as Vector2).distance_to(enemy.pos)<190 and adventure.combat.path_clear(enemy.pos,ally.pos):ally.hp=minf(float(ally.max_hp),float(ally.hp)+6)
  if distance<65 and kind in ["magnet_hauler","fork_runner","continuum_forge"]:
   enemy.tech_melee=float(enemy.get("tech_melee",0))-delta
   if float(enemy.tech_melee)<=0:enemy.tech_melee=1.1;preload("res://scripts/enemy_visual227.gd").mark(adventure,enemy,.32);damage_player(id,20 if enemy.boss else 15,"melee",enemy.pos,adventure.combat.npc_key(enemy))
  if float(enemy.tech_timer)<=0 and not busy and adventure.combat.path_clear(enemy.pos,target):
   enemy.tech_timer=2.5 if enemy.boss else 3.8 if kind=="relay_weaver" else 3.1
   skill(enemy,target)
 # A hazard remains visible for the final frame, but erased bosses cannot keep firing.
func objective()->String:
 if done:return "All backups erased. E / Interact at the glowing Uplink exit."
 if stage==0 and not boss_live and upload<=0:return "Clear Foundry defenders: "+str(remaining(0))+" remaining. Find the maintenance bays off the main route."
 return ("UPLOAD IN PROGRESS • " if upload>0 else "Destroy ")+str(data.bodies[mini(stage,data.bodies.size()-1)].name)+" • body "+str(stage+1)+"/"+str(data.bodies.size())
func snapshot()->Dictionary:return {"initialized":initialized,"stage":stage,"boss_live":boss_live,"upload":upload,"done":done,"clock":clock,"hazards":hazards,"wrecks":wrecks,"towers":towers,"used_pods":used_pods}
func receive(packet:Dictionary)->void:initialized=bool(packet.get("initialized",false));stage=int(packet.get("stage",0));boss_live=bool(packet.get("boss_live",false));upload=float(packet.get("upload",0));done=bool(packet.get("done",false));clock=float(packet.get("clock",0));hazards=packet.get("hazards",[]);wrecks=packet.get("wrecks",[]);towers=packet.get("towers",{});used_pods=packet.get("used_pods",{})
func draw_world(canvas:Node2D,camera:Vector2)->void:
 if not active:return
 var visible:=Rect2(camera-Vector2(100,100),canvas.VIEW+Vector2(200,200))
 canvas.draw_rect(Rect2(Vector2.ZERO,canvas.VIEW),Color("#111a2b"))
 for x in range(floori(camera.x/128),ceili((camera.x+canvas.VIEW.x)/128)):
  for y in range(floori(camera.y/128),ceili((camera.y+canvas.VIEW.y)/128)):
   if (x*17+y*31)%7==0:canvas.draw_circle(Vector2(x*128+44,y*128+60)-camera,1.4,Color(.4,.65,.8,.45))
 for room in data.rooms:
  var world:=rect(room.rect)
  if not visible.intersects(world):continue
  var r:=Rect2(world.position-camera,world.size);var tint:=Color(str(room.colour))
  canvas.draw_rect(r.grow(11),Color("#253d4a"));canvas.draw_rect(r,Color("#334451"));canvas.draw_rect(r.grow(-8),Color("#202f3e"))
  for x in range(maxi(floori(world.position.x/64),floori(camera.x/64)),mini(ceili(world.end.x/64),ceili((camera.x+canvas.VIEW.x)/64))):
   for y in range(maxi(floori(world.position.y/64),floori(camera.y/64)),mini(ceili(world.end.y/64),ceili((camera.y+canvas.VIEW.y)/64))):
    var clipped:=Rect2(Vector2(x*64,y*64),Vector2(64,64)).intersection(world.grow(-12))
    if clipped.has_area():canvas.draw_texture_rect_region(tile,Rect2(clipped.position-camera,clipped.size),Rect2(clipped.position-Vector2(x*64,y*64),clipped.size))
  canvas.draw_rect(r.grow(-12),Color(tint.r,tint.g,tint.b,.045))
  canvas.draw_rect(r.grow(-5),Color(tint.r,tint.g,tint.b,.65),false,3)
  if not str(room.name).is_empty():
   var middle:=r.get_center();var inset:=r.grow(-115)
   canvas.draw_rect(inset,Color(tint.r,tint.g,tint.b,.1),false,2)
   for sign in [-1,1]:
    var p:=Vector2(middle.x+sign*90,inset.position.y)
    canvas.draw_line(p,Vector2(p.x,inset.end.y),Color(tint.r,tint.g,tint.b,.14),2,true)
   for n in range(0,int(inset.size.x),100):
    var p:=inset.position+Vector2(n,0);canvas.draw_line(p+Vector2(0,13),p+Vector2(13,0),Color(tint.r,tint.g,tint.b,.35),3)
  elif r.size.x>r.size.y:
   for n in range(50,int(r.size.x),160):
    var p:=r.position+Vector2(n,r.size.y*.5);canvas.draw_line(p-Vector2(10,10),p,Color(tint.r,tint.g,tint.b,.6),3);canvas.draw_line(p,p-Vector2(10,-10),Color(tint.r,tint.g,tint.b,.6),3)
  if not str(room.name).is_empty():
   canvas.draw_string(ThemeDB.fallback_font,r.position+Vector2(45,65),str(room.name),HORIZONTAL_ALIGNMENT_LEFT,-1,24,tint)
   for n in 3:canvas.draw_line(r.position+Vector2(44,85+n*6),r.position+Vector2(290-n*55,85+n*6),Color(tint.r,tint.g,tint.b,.25),2)
 for prop in data.props:
  var world:=v(prop.pos)
  if not visible.grow(80).has_point(world):continue
  var point:=world-camera;var size:=v(prop.get("size",[100,80]));var r:=Rect2(point-size*.5,size);var kind:=str(prop.kind)
  canvas.draw_rect(Rect2(r.position+Vector2(7,9),r.size),Color(0,0,0,.28))
  match kind:
   "server":
    canvas.draw_rect(r,Color("#172a38"));canvas.draw_rect(r.grow(-5),Color("#436773"))
    for n in 5:
     var p:=r.position+Vector2(10,12+n*18);canvas.draw_rect(Rect2(p,Vector2(size.x-20,12)),Color("#233e50"));canvas.draw_circle(p+Vector2(size.x-28,6),2,Color("#84dcde") if sin(clock*2+n)>0 else Color("#5b7c86"))
   "coolant":
    canvas.draw_rect(r,Color("#253a48"));canvas.draw_rect(r.grow(-8),Color("#307d8a"));canvas.draw_rect(r.grow(-8),Color("#7bd5d8"),false,2)
    for n in 5:canvas.draw_line(r.position+Vector2(14,18+n*25),r.position+Vector2(size.x-14,18+n*25),Color(.55,.9,.95,.2),2)
   "forge":
    canvas.draw_rect(r,Color("#523d3b"));canvas.draw_rect(r.grow(-8),Color("#e39752"));canvas.draw_rect(r.grow(-14),Color("#b85537"))
    for n in 5:canvas.draw_line(r.position+Vector2(12+n*25,14),r.position+Vector2(12+n*25,size.y-14),Color("#f8c97c"),3)
   "antenna":
    canvas.draw_circle(point+Vector2(0,12),38,Color("#253747"));canvas.draw_line(point+Vector2(0,20),point-Vector2(0,80),Color("#7798a4"),12)
    canvas.draw_arc(point-Vector2(0,80),30,0,PI,18,Color("#b5d3d7"),5,true);canvas.draw_circle(point-Vector2(0,77),5,Color("#bbabf0"));canvas.draw_arc(point-Vector2(0,80),45+sin(clock)*6,-PI*.8,-PI*.2,20,Color(.65,.8,.95,.25),2,true)
   "belt":
    canvas.draw_rect(r,Color("#1a2b39"));canvas.draw_rect(r,Color("#6e8078"),false,4)
    for n in range(0,int(size.x),50):
     var p:=r.position+Vector2(fmod(n+clock*28,size.x),size.y*.5);canvas.draw_line(p-Vector2(10,10),p,Color("#ceaf6a"),3,true);canvas.draw_line(p,p-Vector2(10,-10),Color("#ceaf6a"),3,true)
   _:
    canvas.draw_rect(r,Color("#415a65"));canvas.draw_rect(r.grow(-5),Color("#223b4c"));canvas.draw_rect(r.grow(-12),Color("#8bd7d5"),false,2)
 for body in data.bodies:
  var point:=v(body.pos)-camera
  if not visible.has_point(v(body.pos)):continue
  canvas.draw_arc(point,100,0,TAU,48,Color(.4,.75,.85,.35),3,true)
  for n in 8:canvas.draw_line(point+Vector2.from_angle(TAU*n/8)*85,point+Vector2.from_angle(TAU*n/8)*100,Color("#728a9e"),4,true)
 for wreck in wrecks:
  var point:=v(wreck.pos)-camera;canvas.draw_circle(point,52,Color("#18252e"))
  for n in 6:canvas.draw_rect(Rect2(point+Vector2.from_angle(n*TAU/6)*28-Vector2(9,7),Vector2(18,14)),Color("#637477"))
 for pod in data.pods:
  var point:=v(pod.pos)-camera
  canvas.draw_rect(Rect2(point-Vector2(36,40),Vector2(72,65)),Color("#3c6265"));canvas.draw_circle(point-Vector2(0,12),20,Color("#8be7b1"));canvas.draw_line(point-Vector2(0,24),point,Color("#ecffdf"),5);canvas.draw_line(point-Vector2(12,12),point+Vector2(12,-12),Color("#ecffdf"),5)
  canvas.draw_string(ThemeDB.fallback_font,point+Vector2(-64,44),"MAINTENANCE • E",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#b0e2b8"))
 if done:
  var point:=v(data.exit)-camera;preload("res://scripts/realm_portals258.gd").draw_at(canvas,adventure.game,v(data.exit),camera);canvas.draw_string(ThemeDB.fallback_font,point+Vector2(-70,-98),"EXIT • E / INTERACT",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#d2f8e5"))
func draw_on(canvas:Node2D,camera:Vector2)->void:
 if not active:return
 for key in towers:
  var tower:Dictionary=towers[key];var point:=v(tower.pos)-camera;var rise:=float(tower.rise)
  var living:=false
  for foe in adventure.foes():
   if str(foe.uid)==str(key):living=true;break
  if not living:continue
  canvas.draw_circle(point,27,Color("#15212a"));canvas.draw_arc(point,30,0,TAU,24,Color("#98a7a6"),4,true)
  if rise<1:
   for n in 4:
    var p:=point+Vector2.from_angle(TAU*n/4+PI*.25)*24;canvas.draw_line(point,p,Color("#576f76"),5,true)
   if rise>=0:
    var size=body_size("hatch_sentinel");var art=preload("res://scripts/actor_art248.gd");var full=art.fitted("hatch_sentinel",Rect2(point-size*Vector2(.5,.7),size));var amount=clampf(rise,0,1)
    if amount>0:canvas.draw_texture_rect_region(art.texture("hatch_sentinel"),Rect2(full.position+Vector2(0,full.size.y*(1-amount)),Vector2(full.size.x,full.size.y*amount)),Rect2(0,80*(1-amount),80,80*amount))
 for entry in hazards:
  var point:=v(entry.pos)-camera;var end:=v(entry.end)-camera;var warn:=float(entry.warn)>0;var style:=str(entry.style);var tint:=Color("#edb76b") if warn else Color("#9de4ee");tint.a=.45 if warn else .8
  if warn:
   if style in ["beam","tether","fence","dash","turret"]:preload("res://scripts/combat_cues.gd").corridor(canvas,point,end,float(entry.radius))
   else:preload("res://scripts/combat_cues.gd").danger(canvas,point,float(entry.radius),float(entry.warn),float(entry.total))
   continue
  if style in ["beam","tether","fence","dash","turret"]:
   canvas.draw_line(point,end,Color(tint.r,tint.g,tint.b,.10),float(entry.radius)*2,true);canvas.draw_line(point,end,tint,2 if warn else 7,true)
   if style=="fence":
    for n in 10:
     var p:=point.lerp(end,n/9.0);canvas.draw_line(p-Vector2(5,16),p+Vector2(5,16),tint,2,true)
   if style=="dash":canvas.draw_arc(end,30,0,TAU,20,tint,2,true)
  else:
   canvas.draw_circle(point,float(entry.radius),Color(tint.r,tint.g,tint.b,.08 if warn else .2));canvas.draw_arc(point,float(entry.radius),0,TAU,36,tint,2 if warn else 4,true)
 if upload>0 and not wrecks.is_empty():
  var source:=v(wrecks[-1].pos)-camera;var destination:=v(data.bodies[stage].pos)-camera
  canvas.draw_line(source,destination,Color(.5,.85,1,.12),4,true)
  for n in 8:canvas.draw_circle(source.lerp(destination,fmod(clock*.5+n/8.0,1)),5,Color("#9edced"))
func draw_hud(canvas:Node2D)->void:
 if not active:return
 var top=preload("res://scripts/hud_layout.gd").objective_top(canvas,adventure.arcade)
 canvas.draw_rect(Rect2(24,top,mini(920,canvas.VIEW.x-48),58),Color(.07,.13,.18,.93))
 canvas.draw_string(ThemeDB.fallback_font,Vector2(36,top+25),objective(),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#e2d392"))
 canvas.draw_string(ThemeDB.fallback_font,Vector2(36,top+46),"Rising turrets • guided rockets • signal fences • repairing drones",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#a7c9d5"))
 var target:=v(data.exit) if done else v(data.bodies[mini(stage,data.bodies.size()-1)].pos)
 var own:Vector2=adventure.game.local_pos if adventure.arcade else adventure.game.position_in_world
 if stage==0 and not boss_live and upload<=0 and not done:
  var best:=INF
  for enemy in adventure.foes():
   if int(enemy.get("tech_sector",-1))==0 and (enemy.pos as Vector2).distance_to(own)<best:best=(enemy.pos as Vector2).distance_to(own);target=enemy.pos
 var heading:Vector2=(target-own).normalized();var p:=Vector2(canvas.VIEW.x-85,top+82)
 canvas.draw_circle(p,28,Color(.08,.17,.24,.8));canvas.draw_line(p-heading*14,p+heading*18,Color("#b3edef"),4,true);canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-38,45),"UPLINK" if done else "CONTINUUM",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#b3edef"))
