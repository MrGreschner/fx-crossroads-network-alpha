extends Node
## Shared hero constructs and expert enemies. Only host/solo simulates outcomes.
var adventure:Node
var active:=false
var clock:=0.0
var plants:Array=[]
var nets:Array=[]
var brands:Array=[]
var ledgers:Array=[]
var shares:Array=[]
var holes:Array=[]
var sharing:=false
var initialized:=false
var boss_started:=false
var pillars:Array=[]
var grid:AStarGrid2D
var routes:Dictionary={}
const STYLES=["bloom_seed","echo_brand","spell_snare","soul_ledger"]
const TYPES=["gravity_husk","singularity_oracle","ashen_revenant","mercy_cantor","brood_reliquary","chrysalis_knight","exalted_wraith","cinderling","last_creditor"]
const ROOMS=[Rect2(150,2000,1300,1500),Rect2(1800,900,1800,1800),Rect2(3950,700,1800,1800),Rect2(4000,3300,1800,2200),Rect2(6500,2400,2200,2200),Rect2(1300,2450,650,320),Rect2(3400,1400,720,320),Rect2(4650,2300,320,1150),Rect2(5650,4000,1000,320),Rect2(5550,1800,1100,300),Rect2(6500,1800,300,850)]
var floor_texture:Texture2D=preload("res://assets/city_cobble.png")
func vec(a:Array)->Vector2:return Vector2(float(a[0]),float(a[1]))
func packed(point:Vector2)->Array:return [point.x,point.y]
func setup(id:String)->void:
 active=id=="ebonwake";clock=0;plants.clear();nets.clear();brands.clear();ledgers.clear();shares.clear();holes.clear();routes.clear();pillars.clear();sharing=false;initialized=false;boss_started=false;grid=null
 if not active:return
 for point in [Vector2(2000,1100),Vector2(3350,2500),Vector2(4200,850),Vector2(5550,2200),Vector2(4200,3500),Vector2(5550,5300),Vector2(6750,2650),Vector2(8450,4250)]:pillars.append(point)
 grid=AStarGrid2D.new();grid.region=Rect2i(0,0,180,132);grid.cell_size=Vector2(50,50);grid.offset=Vector2(25,25);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;grid.update()
 for x in 180:
  for y in 132:grid.set_point_solid(Vector2i(x,y),not can_stand(Vector2(x*50+25,y*50+25)))
func floor_at(point:Vector2)->bool:
 for room in ROOMS:
  if room.grow(-22).has_point(point):return true
 return false
func can_stand(point:Vector2)->bool:
 if not floor_at(point):return false
 for pillar in pillars:
  if point.distance_to(pillar)<52:return false
 return true
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not adventure.authoritative() or not adventure.alive(owner):return true
 var combat=adventure.combat;var origin:Vector2=combat.owner_pos(owner)
 var location:Vector2=combat.variants.advance(origin,aim,float(stats.get("range",330)))
 if not adventure.arcade:location= combat.variants.advance(origin,aim,origin.distance_to(adventure.game.aimed_point(float(stats.get("range",330)))))
 elif owner==adventure.game.my_id and not adventure.game.mobile.enabled:location=combat.variants.advance(origin,aim,minf(float(stats.get("range",330)),origin.distance_to(adventure.game.media_mouse_world())))
 match style:
  "bloom_seed":
   var own:Array=[]
   for plant in plants:
    if str(plant.owner)==owner:own.append(plant)
   if own.size()>=2:plants.erase(own[0])
   plants.append({"owner":owner,"start":packed(origin),"pos":packed(location),"flight":.6,"age":0.0,"delay":float(stats.get("bloom_delay",3)),"life":float(stats.get("duration",8)),"tick":1.0,"shot":.2,"damage":amount,"radius":float(stats.get("radius",140)),"heal":float(stats.get("heal",3)),"interval":float(stats.get("shot_interval",1.2))})
  "echo_brand":combat.launch_projectile(owner,origin+aim*26,aim,{"range":float(stats.get("range",480)),"speed":float(stats.get("speed",410)),"color":"#c5a5f1","echo_brand":amount*.6},amount*.4)
  "spell_snare":
   for n in range(nets.size()-1,-1,-1):
    if str(nets[n].owner)==owner:nets.remove_at(n)
   nets.append({"owner":owner,"pos":packed(location),"time":float(stats.get("duration",2.5)),"total":float(stats.get("duration",2.5)),"radius":float(stats.get("radius",100)),"count":0,"damage":amount,"shots":[],"aim":packed(aim)})
  "soul_ledger":
   var ordered:Array=[]
   for key in combat.hostile(owner):
    var actor:Dictionary=combat.actor(key)
    if not actor.is_empty() and origin.distance_to(actor.pos)<float(stats.get("range",420)) and combat.path_clear(origin,actor.pos):ordered.append({"key":key,"distance":origin.distance_to(actor.pos)})
   ordered.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return float(a.distance)<float(b.distance))
   var keys:Array=[]
   for n in mini(4,ordered.size()):keys.append(str(ordered[n].key))
   ledgers.append({"owner":owner,"keys":keys,"time":float(stats.get("duration",5))})
   for key in keys:combat.damage(str(key),amount,owner)
 return true
func brand(owner:String,key:String,amount:float)->void:
 if not adventure.authoritative():return
 var target:Dictionary=adventure.combat.actor(key)
 if target.is_empty():return
 for entry in brands:
  if str(entry.owner)==owner and str(entry.key)==key:entry.damage=maxf(float(entry.damage),amount);return
 if brands.size()<96:brands.append({"owner":owner,"key":key,"origin":packed(target.pos),"time":1.2,"damage":amount})
func linked_hit(key:String,amount:float)->void:
 if sharing or amount<=0 or not adventure.authoritative():return
 for ledger in ledgers:
  if not ledger.keys.has(key) or float(ledger.time)<=0:continue
  for other in ledger.keys:
   if str(other)!=key and shares.size()<64:shares.append({"key":str(other),"owner":str(ledger.owner),"damage":minf(12,amount*.25)})
func revive_intercept(enemy:Dictionary)->bool:
 if bool(enemy.get("converted",false)):return false
 if str(enemy.type)!="ashen_revenant" or int(enemy.get("revivals",0))>0:return false
 enemy["revivals"]=1;enemy["down_time"]=3.0;enemy["hp"]=25.0
 return true
func nearest(point:Vector2,owner:String,max_distance:float)->String:
 var result:="";var distance:=max_distance
 for key in adventure.combat.hostile(owner):
  var actor:Dictionary=adventure.combat.actor(key)
  if not actor.is_empty() and bool(actor.alive) and point.distance_to(actor.pos)<distance and adventure.combat.path_clear(point,actor.pos):distance=point.distance_to(actor.pos);result=str(key)
 return result
func ally(owner:String,id:String)->bool:return not adventure.arcade or adventure.game.mode!="arena" or id==owner or not adventure.game._rival(owner,id)
func heal(owner:String,id:String,amount:float)->void:
 if not adventure.alive(id):return
 if adventure.arcade:adventure.game._heal(owner,id,int(amount))
 else:
  var actual:=minf(amount,adventure.game.max_health()-adventure.game.health);adventure.game.health+=actual
  if actual>0:adventure.game.add_float_text(adventure.game.position_in_world+Vector2(-15,-58),"+"+str(int(actual))+" HP",Color("#b4e4ac"))
func hostile_shot(owner:String,source:String)->bool:
 return source=="enemy" or (adventure.arcade and adventure.game.mode in ["arena","battlegrounds"] and source!=owner and adventure.game._rival(owner,source))
func spell_record(amount:float,colour:String,appearance:Dictionary={}) -> Dictionary:
 # Keep art separately: borrowed visuals must never copy splash damage, summons,
 # brands, bleed, item procs or an enemy's ownership onto a returned bolt.
 var original:Dictionary=appearance.get("stats",appearance)
 var art_stats:Dictionary={}
 for key in ["ice_visual","prism_glass","golf_ball","river_stone","pistol","mirror_shard","lantern_comet","navigator_star","thorn_arrow","tea_drop","rune_hammer","flying_page","chalk_shard","flame_orb","ball_lightning","released_hold","element","amplitude","wavelength"]:
  if original.has(key):art_stats[key]=original[key]
  elif appearance.has(key):art_stats[key]=appearance[key]
 if bool(appearance.get("fireball",false)):art_stats["flame_orb"]=true
 var style:String=str(appearance.get("style","pellet"))
 if style=="rolling_snow":amount+=clampf(float(appearance.get("distance",0))/maxf(1,float(appearance.get("range",480))),0,1)*36
 return {"damage":maxf(0,amount),"appearance":{"stats":art_stats,"style":style,"custom":str(appearance.get("stolen_visual",original.get("stolen_visual",""))),"radius":clampf(float(appearance.get("radius",original.get("projectile_radius",5))),3,46),"color":colour}}
func store_spell(net:Dictionary,amount:float,colour:String,appearance:Dictionary={}) -> bool:
 if int(net.count)>=6:return false
 if not net.has("shots"):net.shots=[]
 net.shots.append(spell_record(amount,colour,appearance));net.count=int(net.count)+1
 return true
func catch_shot(start:Vector2,finish:Vector2,source:String,amount:float,colour:String,appearance:Dictionary={}) -> bool:
 if not adventure.authoritative():return false
 for net in nets:
  if float(net.time)<=0 or int(net.count)>=6 or not adventure.alive(str(net.owner)) or not hostile_shot(str(net.owner),source):continue
  var center:Vector2=vec(net.pos);var point:Vector2=Geometry2D.get_closest_point_to_segment(center,start,finish)
  if center.distance_to(point)>float(net.radius) or not adventure.combat.path_clear(start,point) or not adventure.combat.path_clear(center,point):continue
  return store_spell(net,amount,colour,appearance)
 return false
func capture_projectiles(net:Dictionary)->void:
 if int(net.count)>=6 or not adventure.alive(str(net.owner)):return
 var combat=adventure.combat
 for n in range(combat.projectiles.size()-1,-1,-1):
  var shot:Dictionary=combat.projectiles[n]
  if hostile_shot(str(net.owner),str(shot.owner)) and vec(shot.pos).distance_to(vec(net.pos))<float(net.radius) and combat.path_clear(vec(net.pos),vec(shot.pos)):
   store_spell(net,float(shot.damage),str(shot.get("color","#aeead9")),shot);combat.projectiles.remove_at(n)
   if int(net.count)>=6:return
 var list:Array=adventure.game.missiles if adventure.arcade else adventure.game.enemy_shots
 for n in range(list.size()-1,-1,-1):
  var shot:Dictionary=list[n]
  if adventure.arcade and not hostile_shot(str(net.owner),str(shot.owner)):continue
  if (shot.pos as Vector2).distance_to(vec(net.pos))<float(net.radius) and combat.path_clear(vec(net.pos),shot.pos):
   store_spell(net,float(shot.damage),str(shot.get("color","#aeead9")),shot);list.remove_at(n)
   if int(net.count)>=6:return
func step(delta:float)->void:
 if not adventure.authoritative():return
 clock+=delta
 var combat=adventure.combat
 var queued:=shares.duplicate();shares.clear();sharing=true
 for hit in queued:combat.damage(str(hit.key),float(hit.damage),str(hit.owner))
 sharing=false
 for n in range(ledgers.size()-1,-1,-1):
  ledgers[n].time-=delta
  if float(ledgers[n].time)<=0:ledgers.remove_at(n)
 for n in range(brands.size()-1,-1,-1):
  var entry:Dictionary=brands[n];entry.time-=delta
  var target:Dictionary=combat.actor(str(entry.key))
  if target.is_empty():brands.remove_at(n);continue
  if float(entry.time)<=0:
   var amount:float=float(entry.damage)+minf(14,vec(entry.origin).distance_to(target.pos)*.065)
   combat.visuals.append({"pos":packed(target.pos),"radius":42,"time":.35,"color":"#ccb1ec"});brands.remove_at(n);combat.damage(str(entry.key),amount,str(entry.owner))
 for n in range(plants.size()-1,-1,-1):
  var plant:Dictionary=plants[n]
  if float(plant.flight)>0:plant.flight=maxf(0,float(plant.flight)-delta);continue
  plant.age+=delta
  if float(plant.age)<float(plant.delay):continue
  plant.life-=delta
  if float(plant.life)<=0:plants.remove_at(n);continue
  plant.tick-=delta;plant.shot-=delta
  if float(plant.tick)<=0:
   plant.tick=1
   for id in adventure.points():
    if ally(str(plant.owner),str(id)) and vec(plant.pos).distance_to(adventure.points()[id])<float(plant.radius) and combat.path_clear(vec(plant.pos),adventure.points()[id]):heal(str(plant.owner),str(id),float(plant.heal))
  if float(plant.shot)<=0:
   plant.shot=float(plant.interval);var key:=nearest(vec(plant.pos),str(plant.owner),440)
   if not key.is_empty():combat.launch_projectile(str(plant.owner),vec(plant.pos),(combat.actor(key).pos-vec(plant.pos)).normalized(),{"range":470,"speed":300,"color":"#ffa36c","flame_orb":true},float(plant.damage))
 for n in range(nets.size()-1,-1,-1):
  var net:Dictionary=nets[n];capture_projectiles(net);net.time-=delta
  if float(net.time)>0:continue
  nets.remove_at(n)
  var key:=nearest(vec(net.pos),str(net.owner),700)
  var aim:Vector2=vec(net.get("aim",[1,0])) if key.is_empty() else (combat.actor(key).pos-vec(net.pos)).normalized()
  var stored:Array=net.get("shots",[])
  for k in stored.size():
   var shot:Dictionary=stored[k]
   var stats:Dictionary={"name":"Stolen Spell","range":700,"speed":360,"color":str(shot.appearance.color),"projectile_radius":float(shot.appearance.radius),"stolen_appearance":shot.appearance.duplicate(true)}
   if combat.passive(str(net.owner),"stolen_slow"):stats["slow_duration"]=3;stats["slow_factor"]=.65
   combat.launch_projectile(str(net.owner),vec(net.pos),aim.rotated((k-(stored.size()-1)*.5)*.13),stats,float(shot.damage))
 if active and not initialized:
  initialized=true
  for enemy in adventure.foes():
   if not bool(enemy.get("summoned",false)):enemy["citadel_patrol"]=true
 step_holes(delta)
 step_enemies(delta)
 if active and initialized and not boss_started:
  var remaining:=0
  for enemy in adventure.foes():
   if bool(enemy.get("citadel_patrol",false)):remaining+=1
  if remaining==0:
   boss_started=true;adventure.spawn("last_creditor",Vector2(7750,3500),2400,true)
   if not adventure.arcade:adventure.game.boss_spawned=true
   adventure.announce("The last ward breaks. The Last Creditor awakens in the final court.")
 elif active and boss_started and adventure.arcade:
  var living:=false
  for enemy in adventure.foes():
   if str(enemy.type)=="last_creditor":living=true
  if not living:adventure.game.end_match("Ebonwake Citadel conquered • "+str(int(adventure.game.run_time))+" seconds")
func add_hole(point:Vector2,damage:float)->void:
 if holes.size()<10:holes.append({"pos":packed(point),"age":0.0,"tick":0.0,"radius":190.0,"damage":damage})
func step_holes(delta:float)->void:
 for n in range(holes.size()-1,-1,-1):
  var hole:Dictionary=holes[n];hole.age+=delta;hole.tick-=delta
  if float(hole.age)<1:continue
  if float(hole.age)>=3:
   holes.remove_at(n)
   for k in 10:
    var aim:=Vector2.from_angle(TAU*k/10+clock*.2);adventure.combat.launch_projectile("enemy",vec(hole.pos)+aim*25,aim,{"range":700,"speed":265,"color":"#dbb4f2"},float(hole.damage))
   continue
  if float(hole.tick)>0:continue
  hole.tick=.12
  for id in adventure.combat.v59.target_points():
   if not adventure.alive(str(id)):continue
   var target:Vector2=adventure.combat.v59.target_position(str(id));var center:=vec(hole.pos)
   var protected:bool=Time.get_ticks_msec()<int(adventure.game.invincible_until.get(id,0)) if adventure.arcade else adventure.game.invulnerable_time>0
   if not protected and target.distance_to(center)<float(hole.radius) and adventure.combat.path_clear(center,target):adventure.combat.knock("p:"+str(id),(center-target).normalized(),minf(21,target.distance_to(center)))
func steering(enemy:Dictionary,target:Vector2,ranged:bool)->Vector2:
 target=adventure.combat.fern.redirect(enemy,target)
 var origin:Vector2=enemy.pos
 if not active or adventure.combat.path_clear(origin,target):return adventure.combat.ranged_direction(enemy,target) if ranged else (target-origin).normalized()
 var key:=int(enemy.uid);var route:Dictionary=routes.get(key,{})
 if clock>float(route.get("until",0)):
  var a:=Vector2i(floori(origin.x/50),floori(origin.y/50));var b:=Vector2i(floori(target.x/50),floori(target.y/50));var path:=PackedVector2Array()
  if grid.is_in_boundsv(a) and grid.is_in_boundsv(b) and not grid.is_point_solid(a) and not grid.is_point_solid(b):path=grid.get_point_path(a,b)
  route={"path":path,"until":clock+.5};routes[key]=route
 for point in route.get("path",[]):
  if origin.distance_to(point)>40:return (point-origin).normalized()
 return Vector2.ZERO
func step_enemies(delta:float)->void:
 var combat=adventure.combat
 var definitions:Dictionary=adventure.game.enemy_defs if adventure.arcade else adventure.game.enemy_types
 for enemy in adventure.foes().duplicate():
  var kind:=str(enemy.type)
  if kind not in TYPES:continue
  if float(enemy.get("down_time",0))>0:
   enemy.down_time=maxf(0,float(enemy.down_time)-delta)
   if float(enemy.down_time)<=0:enemy.hp=float(enemy.max_hp)*.65
   continue
  if combat.stunned(combat.npc_key(enemy)):continue
  var target:=Vector2.ZERO;var distance:=INF
  for id in adventure.points():
   var hidden:bool=Time.get_ticks_msec()<int(adventure.game.stealth_until.get(id,0)) if adventure.arcade else adventure.game.stealth_time>0
   if adventure.alive(str(id)) and not hidden and (enemy.pos as Vector2).distance_to(adventure.points()[id])<distance:target=adventure.points()[id];distance=(enemy.pos as Vector2).distance_to(target)
  if distance>900:continue
  var aim:Vector2=(target-(enemy.pos as Vector2)).normalized();var stats:Dictionary=definitions.get(kind,{})
  if kind=="gravity_husk":
   for id in adventure.points():
    if adventure.alive(str(id)) and (enemy.pos as Vector2).distance_to(adventure.points()[id])<245 and combat.path_clear(enemy.pos,adventure.points()[id]):combat.apply_status("p:"+str(id),"slow",.25,"enemy",.55)
  if kind=="chrysalis_knight":
   enemy["growth"]=float(enemy.get("growth",0))+delta
   if float(enemy.growth)>=6:
    var fraction:float=maxf(0,float(enemy.hp)/float(enemy.max_hp));enemy.type="exalted_wraith";enemy.max_hp=float(enemy.max_hp)*1.25;enemy.hp=float(enemy.max_hp)*fraction;enemy["growth"]=0;continue
  var ranged:=kind in ["singularity_oracle","mercy_cantor","exalted_wraith"]
  var move:Vector2=steering(enemy,target,ranged)*float(stats.get("speed",90))*combat.speed_factor(combat.npc_key(enemy))*delta
  if kind=="chrysalis_knight":move=Vector2.ZERO
  if kind=="last_creditor":move=(target+Vector2.from_angle(clock*1.5)*250-(enemy.pos as Vector2)).normalized()*(125 if float(enemy.hp)<float(enemy.max_hp)*.5 else 90)*combat.speed_factor(combat.npc_key(enemy))*delta
  if (distance>55 or ranged or kind=="last_creditor") and combat.path_clear(enemy.pos,enemy.pos+move):enemy.pos+=move
  enemy["v43_attack"]=float(enemy.get("v43_attack",1.2))-delta
  if float(enemy.v43_attack)>0 or not combat.path_clear(enemy.pos,target):continue
  enemy.v43_attack=3.6
  match kind:
   "gravity_husk","ashen_revenant","cinderling","chrysalis_knight":
    enemy.v43_attack=.25
    if distance<68:
     enemy.v43_attack=1.4;adventure.warn(enemy.pos,33,float(stats.get("damage",18)),.45,enemy.pos+aim*75)
   "singularity_oracle":enemy.v43_attack=6.2;add_hole(target,14)
   "mercy_cantor":
    var healed:=0
    for ally_enemy in adventure.foes():
     if ally_enemy==enemy or float(ally_enemy.get("down_time",0))>0:continue
     if (ally_enemy.pos as Vector2).distance_to(enemy.pos)<290 and combat.path_clear(enemy.pos,ally_enemy.pos):ally_enemy.hp=minf(float(ally_enemy.max_hp),float(ally_enemy.hp)+(18 if str(ally_enemy.type)=="last_creditor" else 30));healed+=1
    enemy.v43_attack=2.5
    combat.launch_projectile("enemy",enemy.pos,aim,{"range":650,"speed":250,"color":"#b7edb7"},10)
   "brood_reliquary":
    enemy.v43_attack=5.5;var count:=0
    for child in adventure.foes():
     if int(child.get("nest_uid",-1))==int(enemy.uid):count+=1
    if count<3 and adventure.foes().size()<75:
     for n in 8:
      var point:Vector2=enemy.pos+Vector2.from_angle(TAU*n/8)*85
      if combat.path_clear(enemy.pos,point):adventure.spawn("cinderling",point,32,false);adventure.foes()[-1]["nest_uid"]=int(enemy.uid);adventure.foes()[-1]["summoned"]=true;break
    for angle in [-.15,.15]:combat.launch_projectile("enemy",enemy.pos,aim.rotated(angle),{"range":620,"speed":230,"color":"#e9ac8b"},12)
   "exalted_wraith":
    enemy.v43_attack=2.7
    for angle in [-.2,0,.2]:combat.launch_projectile("enemy",enemy.pos,aim.rotated(angle),{"range":700,"speed":330,"color":"#d8ecd2"},17)
   "last_creditor":
    enemy.v43_attack=2.7;var turn:=int(enemy.get("creditor_turn",0));enemy.creditor_turn=turn+1
    if turn%3==0:
     for n in 3:adventure.warn(target+Vector2.from_angle(TAU*n/3+clock)*100,75,34,.95)
    elif turn%3==1:
     for n in 5:combat.launch_projectile("enemy",enemy.pos,aim.rotated((n-2)*.24),{"range":900,"speed":300,"color":"#e2c191"},22)
    else:add_hole(target,18)
    if float(enemy.hp)<float(enemy.max_hp)*.5 and turn%3==0:
     var count:=0
     for child in adventure.foes():
      if int(child.get("creditor_add",-1))==int(enemy.uid):count+=1
     if count<2:
      var point:Vector2=enemy.pos+aim.orthogonal()*90
      if combat.path_clear(enemy.pos,point):adventure.spawn("ashen_revenant",point,135,false);adventure.foes()[-1]["creditor_add"]=int(enemy.uid);adventure.foes()[-1]["summoned"]=true
func snapshot()->Dictionary:return {"plants":plants,"nets":nets,"brands":brands,"ledgers":ledgers,"holes":holes,"clock":clock,"boss_started":boss_started}
func receive(packet:Dictionary)->void:plants=packet.get("plants",[]);nets=packet.get("nets",[]);brands=packet.get("brands",[]);ledgers=packet.get("ledgers",[]);holes=packet.get("holes",[]);clock=float(packet.get("clock",clock));boss_started=bool(packet.get("boss_started",false))
func draw_world(canvas:Node2D,camera:Vector2)->void:
 if not active:return
 var view:Vector2=adventure.game.VIEW
 canvas.draw_rect(Rect2(Vector2.ZERO,view),Color("#131d30"))
 for x in range(floori(camera.x/64),ceili((camera.x+view.x)/64)+1):
  for y in range(floori(camera.y/64),ceili((camera.y+view.y)/64)+1):
   var point:=Vector2(x*64+32,y*64+32);var top:=point-Vector2(32,32)-camera
   if not floor_at(point):
    if (x*13+y*7)%11==0:canvas.draw_arc(point-camera,19,clock*.3,clock*.3+PI,16,Color(.55,.42,.68,.13),3)
    continue
   canvas.draw_texture_rect(floor_texture,Rect2(top,Vector2(64,64)),false,Color("#81929b") if point.x<3950 else Color("#b29cbd") if point.y<2500 else Color("#b89b8b") if point.x<6200 else Color("#b4a57f"))
   if (x*17+y*11)%9==0:canvas.draw_line(top+Vector2(7,18),top+Vector2(35,27),Color(.16,.18,.22,.35),2)
   for side in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
    if not floor_at(point+side*64):canvas.draw_line(top+Vector2(32,32)+side*32-side.orthogonal()*32,top+Vector2(32,32)+side*32+side.orthogonal()*32,Color("#5a6c7d"),10)
 var bounds:=Rect2(camera-Vector2(180,180),view+Vector2(360,360))
 # Non-blocking murals, rugs and broken masonry keep the combat floor readable.
 for room_index in 5:
  var room:Rect2=ROOMS[room_index]
  for n in range(1,5):
   var window:=Vector2(room.position.x+room.size.x*n/5,room.position.y+75)
   if not bounds.has_point(window):continue
   var p:Vector2=window-camera
   canvas.draw_rect(Rect2(p-Vector2(36,12),Vector2(72,88)),Color("#253140"));canvas.draw_arc(p+Vector2(0,-12),36,PI,TAU,20,Color("#78828b"),8)
   var glass:=Color("#789eac") if room_index<2 else Color("#9b79ac") if room_index==2 else Color("#b77660") if room_index==3 else Color("#b7a271")
   canvas.draw_rect(Rect2(p+Vector2(-27,-8),Vector2(54,76)),glass.darkened(.35));canvas.draw_line(p+Vector2(0,-8),p+Vector2(0,69),Color("#adb0a5"),4);canvas.draw_line(p+Vector2(-28,27),p+Vector2(28,27),Color("#adb0a5"),4)
   canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(-27,68),p+Vector2(27,68),p+Vector2(125,220),p+Vector2(10,220)]),Color(glass.r,glass.g,glass.b,.09))
  for n in 4:
   var rubble:=room.position+Vector2(130+n*330,room.size.y-110)
   if not bounds.has_point(rubble):continue
   var p:Vector2=rubble-camera
   for k in 6:canvas.draw_rect(Rect2(p+Vector2(k*13-30,(k*17)%31-12),Vector2(17,9)),Color("#66717b").darkened(k*.05))
 for base in [Vector2(4400,1200),Vector2(5250,1500),Vector2(4500,4500),Vector2(7100,4050)]:
  if not bounds.has_point(base):continue
  var p:Vector2=base-camera
  canvas.draw_circle(p,80,Color(.18,.12,.22,.6))
  for n in 8:
   var aim:=Vector2.from_angle(TAU*n/8)
   canvas.draw_line(p+aim*22,p+aim*100+aim.orthogonal()*20,Color("#685174"),5);canvas.draw_line(p+aim*65,p+aim*92-aim.orthogonal()*30,Color("#7b6085"),3)
  for n in 5:canvas.draw_circle(p+Vector2(n*24-45,(n%2)*20),11,Color("#9c879f"));canvas.draw_circle(p+Vector2(n*24-46,(n%2)*20-3),4,Color("#c4b3bd"))
 for center in [Vector2(800,2650),Vector2(2700,2200),Vector2(4800,4500),Vector2(7750,3500)]:
  if not bounds.grow(180).has_point(center):continue
  var p:Vector2=center-camera
  var diamond:=PackedVector2Array([p+Vector2(0,-230),p+Vector2(200,0),p+Vector2(0,230),p+Vector2(-200,0),p+Vector2(0,-230)])
  canvas.draw_colored_polygon(diamond,Color(.18,.15,.24,.3));canvas.draw_polyline(diamond,Color("#927f9b"),4)
  for n in 4:
   var point:Vector2=p+Vector2.from_angle(PI*.5*n)*160
   canvas.draw_rect(Rect2(point-Vector2(10,10),Vector2(20,20)),Color("#bdab8c"));canvas.draw_rect(Rect2(point-Vector2(5,5),Vector2(10,10)),Color("#64596e"))
 for pillar in pillars:
  if not bounds.has_point(pillar):continue
  var point:Vector2=pillar-camera
  canvas.draw_circle(point,38,Color("#303e4a"));canvas.draw_rect(Rect2(point+Vector2(-27,-90),Vector2(54,100)),Color("#77858e"));canvas.draw_rect(Rect2(point+Vector2(-35,-95),Vector2(70,15)),Color("#acb5b2"));canvas.draw_rect(Rect2(point+Vector2(-34,0),Vector2(68,16)),Color("#a2aaa7"))
  for x in [-12,4,17]:canvas.draw_line(point+Vector2(x,-82),point+Vector2(x,-6),Color("#506270"),3)
 for entry in [{"pos":Vector2(2450,1500),"name":"THE UNQUIET INFIRMARY"},{"pos":Vector2(4850,1050),"name":"BROOD RELIQUARIES"},{"pos":Vector2(4800,3900),"name":"CHRYSALIS FORGE"},{"pos":Vector2(7750,3500),"name":"THE LAST COURT"}]:
  if not bounds.has_point(entry.pos):continue
  var point:Vector2=entry.pos-camera
  canvas.draw_arc(point,170,0,TAU,64,Color(.8,.7,.5,.22),8)
  for n in 8:
   var p:Vector2=point+Vector2.from_angle(TAU*n/8)*170;canvas.draw_circle(p,5,Color("#c1bb99"))
  canvas.draw_string(ThemeDB.fallback_font,point+Vector2(-140,-210),str(entry.name),HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("#dbd1bb"))
 for n in 16:
  var point:=Vector2(2010+n%4*380,1080+n/4*340)
  if not bounds.has_point(point):continue
  var p:Vector2=point-camera
  canvas.draw_rect(Rect2(p+Vector2(-5,5),Vector2(96,37)),Color(.08,.12,.17,.4));canvas.draw_rect(Rect2(p,Vector2(80,32)),Color("#556979"));canvas.draw_rect(Rect2(p+Vector2(3,3),Vector2(65,24)),Color("#b9beb0"));canvas.draw_rect(Rect2(p+Vector2(6,5),Vector2(13,20)),Color("#d5d1bf"));canvas.draw_line(p+Vector2(0,32),p+Vector2(0,46),Color("#465569"),4)
  canvas.draw_rect(Rect2(p+Vector2(87,5),Vector2(22,27)),Color("#6c776e"));canvas.draw_circle(p+Vector2(98,15),5,Color("#9dcba4"))
 for n in 12:
  var point:=Vector2(4150+n%4*350,3500+n/4*650)
  if not bounds.has_point(point):continue
  canvas.draw_arc(point-camera,45,0,TAU,32,Color("#8c645e"),8);canvas.draw_circle(point-camera,32,Color(.9,.45,.3,.14));canvas.draw_circle(point-camera,12,Color(.9,.7,.4,.3))
func draw_on(canvas:Node2D,camera:Vector2)->void:
 var combat=adventure.combat
 for plant in plants:
  var point:=vec(plant.pos)-camera
  if float(plant.flight)>0:
   var progress:=1-float(plant.flight)/.6;point=vec(plant.start).lerp(vec(plant.pos),progress)-camera-Vector2(0,sin(progress*PI)*95)
   canvas.draw_circle(point,7,Color("#d4b46d"));canvas.draw_arc(vec(plant.pos)-camera,18,0,TAU,20,Color(.8,.9,.5,.4),2);continue
  if float(plant.age)<float(plant.delay):
   canvas.draw_circle(point,10,Color("#6e7754"));canvas.draw_line(point,point-Vector2(0,12+float(plant.age)*4),Color("#91b968"),4)
   canvas.draw_arc(point,20,-PI*.5,-PI*.5+TAU*float(plant.age)/float(plant.delay),24,Color("#e6d793"),3);continue
  canvas.draw_circle(point,float(plant.radius),Color(.6,.8,.4,.09));canvas.draw_arc(point,float(plant.radius),clock,clock+PI,48,Color(.7,.9,.5,.3),2)
  canvas.draw_line(point,point-Vector2(0,36),Color("#6aab65"),5);canvas.draw_line(point-Vector2(0,12),point+Vector2(15,-22),Color("#87c779"),5)
  var flower:=point-Vector2(0,42)
  for n in 8:canvas.draw_circle(flower+Vector2.from_angle(TAU*n/8+sin(clock)*.07)*14,9,Color("#edb95c"))
  canvas.draw_circle(flower,11,Color("#6d6341"));canvas.draw_circle(flower+Vector2(3,-2),3,Color("#ffe1a1"))
 for net in nets:
  var point:=vec(net.pos)-camera;var radius:=float(net.radius)
  canvas.draw_circle(point,radius,Color(.5,.7,.75,.08));canvas.draw_arc(point,radius,clock,clock+TAU*.9,48,Color("#acd7d8"),3)
  for n in 4:
   var direction:=Vector2.from_angle(n*PI/4);canvas.draw_line(point-direction*radius,point+direction*radius,Color(.6,.8,.85,.2),1)
  for n in int(net.count):canvas.draw_circle(point+Vector2.from_angle(TAU*n/6+clock*2)*35,5,Color("#edc998"))
 for entry in brands:
  var actor:Dictionary=combat.actor(str(entry.key))
  if actor.is_empty():continue
  var point:Vector2=actor.pos-camera;canvas.draw_arc(point,30,-PI*.5,-PI*.5+TAU*float(entry.time)/1.2,24,Color("#d9b5f0"),3)
  canvas.draw_line(point-Vector2(7,11),point+Vector2(7,11),Color("#e9cbf7"),2);canvas.draw_line(point-Vector2(-7,11),point+Vector2(-7,11),Color("#e9cbf7"),2)
 for ledger in ledgers:
  var previous:=Vector2.ZERO
  for key in ledger.keys:
   var actor:Dictionary=combat.actor(str(key))
   if actor.is_empty():continue
   var point:Vector2=actor.pos-camera;canvas.draw_arc(point,38,clock,clock+PI*1.7,32,Color("#edd6a4"),3)
   if previous!=Vector2.ZERO:canvas.draw_line(previous,point,Color(.9,.75,.45,.5),2,true)
   previous=point
 for hole in holes:
  var point:=vec(hole.pos)-camera;var radius:=float(hole.radius)
  canvas.draw_circle(point,radius,Color(.45,.25,.6,.12 if float(hole.age)<1 else .22));canvas.draw_arc(point,radius,0,TAU,48,Color("#bd9edb"),3)
  if float(hole.age)>=1:canvas.draw_circle(point,20,Color("#222038"))
  for n in 6:
   var angle:float=TAU*n/6-clock*2;var r:float=fmod(clock*80+n*31,radius)
   canvas.draw_arc(point,r,angle,angle+.9,20,Color(.7,.6,.9,.55),3,true)
  canvas.draw_arc(point,26,-PI*.5,-PI*.5+TAU*minf(1,float(hole.age)/3),24,Color("#f0dcab"),3)
 for enemy in adventure.foes():
  var point:Vector2=enemy.pos-camera
  if str(enemy.type)=="gravity_husk":canvas.draw_circle(point,245,Color(.45,.6,.9,.08));canvas.draw_arc(point,245,clock*.4,clock*.4+TAU*.8,64,Color(.5,.65,.95,.32),3)
  if float(enemy.get("down_time",0))>0:
   canvas.draw_circle(point,36,Color(.5,.9,.7,.17));canvas.draw_arc(point,38,-PI*.5,-PI*.5+TAU*float(enemy.down_time)/3,32,Color("#b4ecd6"),4);canvas.draw_string(ThemeDB.fallback_font,point+Vector2(-40,-65),"FINISH IT",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#d5f7df"))
  if str(enemy.type)=="chrysalis_knight":canvas.draw_arc(point,40,-PI*.5,-PI*.5+TAU*float(enemy.get("growth",0))/6,32,Color("#edc193"),4)
  if str(enemy.type)=="mercy_cantor" and float(enemy.get("v43_attack",0))>2:
   for other in adventure.foes():
    if other!=enemy and (other.pos as Vector2).distance_to(enemy.pos)<290:canvas.draw_line(point,other.pos-camera,Color(.65,.85,.65,.25),2,true)
