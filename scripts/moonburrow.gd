extends Node
## A surface expedition with four connected underground warrens.
var adventure:Node
var cave_texture:Texture2D=preload("res://assets/moonburrow_cave.png")
var active:=false
var clock:=0.0
var mines:Array=[]
var props:Array=[]
var prop_grid:Dictionary={}
var flashes:Array=[]
var travel:Dictionary={}
var grid:AStarGrid2D
const SIZE=Vector2(6400,7000)
const ENEMY_POINTS=[Vector2(1120, 1580),Vector2(1790, 2100),Vector2(2770, 1750),Vector2(980, 5300),Vector2(2640, 4900),Vector2(1560, 1100),Vector2(3180, 1900),Vector2(4900, 1740),Vector2(2140, 5450),Vector2(5290, 5300),Vector2(1800, 700),Vector2(3490, 1750),Vector2(4760, 2900),Vector2(5540, 2000),Vector2(3550, 5600),Vector2(1180, 2400),Vector2(2900, 2700),Vector2(5200, 1120),Vector2(4200, 5800),Vector2(5850, 5540),Vector2(3070, 700),Vector2(1220, 4600),Vector2(1940, 4700),Vector2(3430, 5300),Vector2(5150, 4520),Vector2(1610, 1900),Vector2(3340, 1250),Vector2(5680, 1750),Vector2(3800, 4950),Vector2(3000, 6370)]
const TYPES=["burrowfang","shardspitter","fusehare","rootwarden","echo_bat","sap_nurse","flintroot"]
const CAVES=[Rect2(200,4400,1300,1200),Rect2(1850,4450,1100,1150),Rect2(3300,4700,1250,1400),Rect2(5000,4350,1200,1650),Rect2(1400,4800,600,240),Rect2(2800,5200,600,240),Rect2(4420,5100,650,240),Rect2(2350,5950,1600,700),Rect2(2600,5480,220,600),Rect2(3800,5900,220,220)]
const SURFACE_GATES=[Vector2(750,1100),Vector2(2650,2550),Vector2(3750,900),Vector2(5650,2600)]
const CAVE_GATES=[Vector2(650,4900),Vector2(2350,5000),Vector2(4200,5250),Vector2(5700,5000)]
func setup(id:String)->void:
 active=id=="moonburrow";clock=0;mines.clear();props.clear();prop_grid.clear();flashes.clear();travel.clear();grid=null
 if not active:return
 var random:=RandomNumberGenerator.new();random.seed=4026
 # Protected trails make entrances and the arrival clearing readable and safe.
 for n in 160:
  var point:=Vector2(random.randf_range(450,6100),random.randf_range(180,3400))
  if absf(point.y-1750)<190 or absf(point.y-700)<120 or absf(point.y-2900)<130:continue
  var safe:=point.distance_to(Vector2(350,1750))<280
  for gate in SURFACE_GATES:
   if point.distance_to(gate)<200:safe=true
  for marker in ENEMY_POINTS:
   if point.distance_to(marker)<100:safe=true
  for landmark in [Vector2(950,1460),Vector2(3150,1440),Vector2(5350,1450)]:
   if point.distance_to(landmark)<155:safe=true
  if safe or not terrain_clear(point):continue
  props.append({"pos":point,"radius":26.0 if n%3 else 42.0,"kind":"tree" if n%3 else "stone"})
 for n in 26:
  var point:=Vector2(480+n%13*430,4530+n/13*1160)
  if not terrain_clear(point):continue
  var safe:=false
  for gate in CAVE_GATES:
   if point.distance_to(gate)<200:safe=true
  for marker in ENEMY_POINTS:
   if point.distance_to(marker)<90:safe=true
  if not safe:props.append({"pos":point,"radius":24.0,"kind":"crystal"})
 for prop in props:
  var point:Vector2=prop.pos;var radius:=float(prop.radius)+20
  for x in range(floori((point.x-radius)/128),floori((point.x+radius)/128)+1):
   for y in range(floori((point.y-radius)/128),floori((point.y+radius)/128)+1):
    var key:=Vector2i(x,y)
    if not prop_grid.has(key):prop_grid[key]=[]
    prop_grid[key].append(prop)
 for point in [Vector2(1300,1740),Vector2(1520,1570),Vector2(1710,1900),Vector2(1900,720),Vector2(2600,1800),Vector2(2860,1510),Vector2(3090,1960),Vector2(3450,1720),Vector2(3970,2860),Vector2(4690,1670),Vector2(4920,1900),Vector2(5250,1530),Vector2(5600,1760),Vector2(1120,5010),Vector2(1570,4910),Vector2(2180,5320),Vector2(2720,5390),Vector2(2980,5310),Vector2(3560,5280),Vector2(3880,5520),Vector2(4590,5210),Vector2(5390,5480),Vector2(5810,5600),Vector2(2670,5760),Vector2(3030,6250),Vector2(3660,6310)]:
  if can_stand(point):plant(point,false)
 rebuild_grid()
func terrain_clear(point:Vector2)->bool:
 if point.y<3600:
  if not Rect2(32,32,6336,3536).has_point(point):return false
  if point.x>2080 and point.x<2320 and absf(point.y-700)>115:return false
  if point.x>4100 and point.x<4340 and absf(point.y-2900)>115:return false
  return true
 for cave in CAVES:
  if cave.grow(-20).has_point(point):return true
 return false
func can_stand(point:Vector2)->bool:
 if not terrain_clear(point):return false
 for prop in prop_grid.get(Vector2i(floori(point.x/128),floori(point.y/128)),[]):
  if point.distance_to(prop.pos)<float(prop.radius)+18:return false
 return true
func rebuild_grid()->void:
 grid=AStarGrid2D.new();grid.region=Rect2i(0,0,160,175);grid.cell_size=Vector2(40,40);grid.offset=Vector2(20,20);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER;grid.update()
 for x in 160:
  for y in 175:grid.set_point_solid(Vector2i(x,y),not can_stand(Vector2(x*40+20,y*40+20)))
func routes()->Array:
 var result:Array=[]
 for n in 4:
  result.append({"pos":SURFACE_GATES[n],"end":CAVE_GATES[n]+Vector2(0,100),"label":["WEST WARREN","ROOTWELL CROSSING","CRYSTAL HOLLOW","EAST DEN"][n]})
  result.append({"pos":CAVE_GATES[n],"end":SURFACE_GATES[n]+Vector2(0,100),"label":"CLIMB TO SURFACE"})
 return result
func interact(id:String)->bool:
 if not active or not adventure.alive(id):return false
 for gate in routes():
  if (adventure.points().get(id,Vector2.ZERO) as Vector2).distance_to(gate.pos)>130:continue
  if clock<float(travel.get(id,-1)):return true
  adventure.teleport(id,gate.end);travel[id]=clock+1;return true
 return false
func direction(enemy:Dictionary,target:Vector2,delta:float)->Vector2:
 target=adventure.combat.fern.redirect(enemy,target)
 var origin:Vector2=enemy.pos
 if not active or adventure.combat.path_clear(origin,target):return (target-origin).normalized()
 enemy["dig_route_timer"]=float(enemy.get("dig_route_timer",0))-delta
 if float(enemy.dig_route_timer)<=0:
  enemy.dig_route_timer=.7
  var start:=Vector2i(floori(origin.x/40),floori(origin.y/40));var end:=Vector2i(floori(target.x/40),floori(target.y/40))
  if grid.is_in_boundsv(start) and grid.is_in_boundsv(end) and not grid.is_point_solid(start) and not grid.is_point_solid(end):enemy.dig_path=grid.get_point_path(start,end)
  else:enemy.dig_path=PackedVector2Array()
 var path:PackedVector2Array=enemy.get("dig_path",PackedVector2Array())
 while not path.is_empty() and origin.distance_to(path[0])<28:path.remove_at(0)
 enemy.dig_path=path
 return (path[0]-origin).normalized() if not path.is_empty() else Vector2.ZERO
func plant(point:Vector2,temporary:bool,delay:float=-1)->void:
 if mines.size()>=64:return
 mines.append({"pos":[point.x,point.y],"time":delay,"spent":false,"temporary":temporary,"life":14.0 if temporary else 9999.0})
func nearest_target(enemy:Dictionary)->Dictionary:
 var target:=Vector2.ZERO;var nearest:=INF
 for id in adventure.points():
  if adventure.alive(str(id)) and (enemy.pos as Vector2).distance_to(adventure.points()[id])<nearest:target=adventure.points()[id];nearest=(enemy.pos as Vector2).distance_to(target)
 return {"pos":target,"distance":nearest}
func step(delta:float)->void:
 clock+=delta
 for i in range(flashes.size()-1,-1,-1):
  flashes[i].time-=delta
  if float(flashes[i].time)<=0:flashes.remove_at(i)
 for i in range(mines.size()-1,-1,-1):
  var mine:Dictionary=mines[i];mine.life-=delta
  if float(mine.life)<=0:mines.remove_at(i);continue
  if bool(mine.spent):continue
  var point:Vector2=adventure.vec(mine.pos)
  if float(mine.time)<0:
   for id in adventure.combat.v59.target_points():
    if adventure.alive(str(id)) and (adventure.combat.v59.target_position(str(id)) as Vector2).distance_to(point)<70:mine.time=.85;break
  elif float(mine.time)>0:
   mine.time=maxf(0,float(mine.time)-delta)
   if float(mine.time)<=0:
    mine.spent=true;flashes.append({"pos":mine.pos,"time":.45,"radius":100.0})
    for id in adventure.combat.v59.target_points():
     var target:Vector2=adventure.combat.v59.target_position(str(id))
     if point.distance_to(target)<100 and adventure.combat.path_clear(point,target):adventure.hit_player(str(id),18,"",preload("res://scripts/defeat_credit.gd").hazard("Buried mine"))
 for enemy in adventure.foes().duplicate():
  if str(enemy.type) not in TYPES:continue
  var target:Dictionary=nearest_target(enemy);var distance:=float(target.distance)
  if distance>800:continue
  var point:Vector2=target.pos
  var boss:=str(enemy.type)=="flintroot"
  var burrower:=str(enemy.type) in ["burrowfang","shardspitter"] or boss
  if burrower:
   enemy["phase_time"]=float(enemy.get("phase_time",2.4 if not boss else 5.0))-delta
   if not enemy.has("buried"):enemy.buried=not boss
   if float(enemy.phase_time)<=0:
    enemy.buried=not bool(enemy.buried);enemy.phase_time=2.4 if bool(enemy.buried) else 5.0 if boss else 3.6
    if not bool(enemy.buried):
     flashes.append({"pos":[enemy.pos.x,enemy.pos.y],"radius":52.0 if not boss else 120.0,"time":.4});enemy["dig_attack"]=.7
  if adventure.combat.stunned(adventure.combat.npc_key(enemy)):continue
  var aim:Vector2=(point-(enemy.pos as Vector2)).normalized()
  var move_direction:=direction(enemy,point,delta)
  var ranged:=str(enemy.type) in ["shardspitter","echo_bat","sap_nurse"]
  if ranged and not bool(enemy.get("buried",false)) and adventure.combat.path_clear(enemy.pos,point):move_direction=adventure.combat.ranged_direction(enemy,point)
  var speed:=115.0 if bool(enemy.get("buried",false)) else 105.0 if str(enemy.type)=="fusehare" else 42.0 if str(enemy.type)=="rootwarden" else 70.0 if boss else 65.0
  var movement:Vector2=move_direction*speed*adventure.combat.speed_factor(adventure.combat.npc_key(enemy))*delta
  if distance>(60 if str(enemy.type)=="burrowfang" and not bool(enemy.get("buried",false)) else 15) and adventure.combat.path_clear(enemy.pos,enemy.pos+movement):enemy.pos+=movement
  if bool(enemy.get("buried",false)):continue
  enemy["dig_attack"]=float(enemy.get("dig_attack",1.2))-delta
  if float(enemy.dig_attack)>0 or not adventure.combat.path_clear(enemy.pos,point):continue
  enemy.dig_attack=3.2
  var origin:Vector2=enemy.pos
  match str(enemy.type):
   "burrowfang":
    if distance<105:adventure.warn(origin,34,14,.65,origin+aim*110);enemy.dig_attack=1.8
    else:enemy.dig_attack=.3
   "shardspitter":
    for angle in [-.35,0,.35]:adventure.combat.launch_projectile("enemy",origin,aim.rotated(angle),{"speed":245,"range":540,"color":"#d0b4ef"},9)
   "fusehare":
    var endpoint:=origin+aim*120
    if can_stand(endpoint) and adventure.combat.path_clear(origin,endpoint):
     adventure.warn(origin,28,11,.7,endpoint);adventure.warnings[-1]["charge_uid"]=int(enemy.uid)
    plant(origin,true)
   "rootwarden":
    adventure.warn(origin,46,17,1.0,origin+aim*240);adventure.warnings[-1]["wave"]=[aim.x*230,aim.y*230];adventure.warnings[-1]["distance"]=440;adventure.warnings[-1]["colour"]="#a0c88b"
   "echo_bat":
    for angle in [-.22,.22]:adventure.combat.launch_projectile("enemy",origin,aim.rotated(angle),{"speed":225,"range":500,"return_at":240,"color":"#8dc9df"},9,"echo_bolt")
   "sap_nurse":
    for other in adventure.foes():
     if other==enemy or bool(other.get("boss",false)) or (other.pos as Vector2).distance_to(origin)>190 or not adventure.combat.path_clear(origin,other.pos):continue
     other.hp=minf(float(other.max_hp),float(other.hp)+8)
    flashes.append({"pos":[origin.x,origin.y],"radius":190.0,"time":.5,"heal":true})
    adventure.combat.launch_projectile("enemy",origin,aim,{"speed":200,"range":500,"poison_duration":3,"poison_damage":1,"color":"#be99db"},6)
    enemy.dig_attack=4.5
   "flintroot":
    enemy.dig_attack=3.5
    var turn:=int(enemy.get("dig_turn",0));enemy.dig_turn=turn+1
    if turn%3==0:
     for n in 4:
      var location:=point+Vector2.from_angle(TAU*n/4)*105
      if can_stand(location):plant(location,true,1.1+n*.16)
    elif turn%3==1:
     for angle in [-.4,-.2,0,.2,.4]:adventure.combat.launch_projectile("enemy",origin,aim.rotated(angle),{"speed":265,"range":640,"amplitude":24,"color":"#e7b887"},12,"weaving")
    else:
     adventure.warn(origin,115,23,1.0)
     var count:=0
     for other in adventure.foes():
      if str(other.type)=="burrowfang":count+=1
     if count<3:
      var spawn_point:=origin+Vector2(140,0)
      if can_stand(spawn_point):adventure.spawn("burrowfang",spawn_point,75,false)
func snapshot()->Dictionary:return {"mines":mines,"flashes":flashes,"clock":clock}
func receive(data:Dictionary)->void:mines=data.get("mines",[]);flashes=data.get("flashes",[]);clock=float(data.get("clock",clock))
func draw_world(canvas:Node2D,camera:Vector2)->void:
 var visible:=Rect2(camera-Vector2(160,160),canvas.VIEW+Vector2(320,320))
 if camera.y+canvas.VIEW.y>4100:
  canvas.draw_rect(Rect2(Vector2(0,4000)-camera,Vector2(6400,3000)),Color("#151e2b"))
  # Draw the union of cavern floors so connector joins never look like blocking walls.
  for x in range(maxi(0,floori(camera.x/32)-1),mini(200,ceili((camera.x+canvas.VIEW.x)/32)+1)):
   for y in range(maxi(128,floori(camera.y/32)-1),mini(219,ceili((camera.y+canvas.VIEW.y)/32)+1)):
    var world:=Vector2(x*32+16,y*32+16)
    if not terrain_clear(world):continue
    var point:=world-camera-Vector2(16,16)
    canvas.draw_texture_rect(cave_texture,Rect2(point,Vector2(32,32)),false)
    for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
     if not terrain_clear(world+direction*32):
      var start:=point+(Vector2(0,0) if direction==Vector2.UP or direction==Vector2.LEFT else Vector2(0,32) if direction==Vector2.DOWN else Vector2(32,0))
      var finish:=start+(Vector2(32,0) if direction.y!=0 else Vector2(0,32))
      canvas.draw_line(start,finish,Color("#748077"),10)
      canvas.draw_circle(start,7,Color("#4d5b61"))
    if (x*17+y*23)%41==0:
     canvas.draw_circle(point+Vector2(12,17),4,Color("#789baa"));canvas.draw_circle(point+Vector2(19,22),3,Color("#b7b797"))
  for n in 4:
   var center:Vector2=CAVE_GATES[n]-camera
   canvas.draw_string(ThemeDB.fallback_font,center+Vector2(-120,-250),["FOXTAIL DEN","THE FUSEWORKS","GLITTERVEIN","ANCIENT WARREN"][n],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#b6cbd3"))
   if n==0:
    for k in 5:canvas.draw_line(center+Vector2(-220+k*100,-370),center+Vector2(-210+k*100,-280+k%2*35),Color("#776d54"),5,true)
   elif n==1:
    for offset in [-30,30]:canvas.draw_line(center+Vector2(offset,150),center+Vector2(offset,500),Color("#9b9b90"),4)
    for k in 10:canvas.draw_line(center+Vector2(-40,160+k*33),center+Vector2(40,160+k*33),Color("#877965"),5)
    canvas.draw_rect(Rect2(center+Vector2(-50,200),Vector2(100,65)),Color("#69655c"));canvas.draw_rect(Rect2(center+Vector2(-45,205),Vector2(90,25)),Color("#a8b4b2"))
   elif n==2:
    canvas.draw_circle(center+Vector2(-200,180),80,Color(.3,.5,.6,.2));canvas.draw_arc(center+Vector2(-200,180),80,0,TAU,36,Color(.6,.8,.8,.3),3)
   else:
    for k in 5:canvas.draw_arc(center+Vector2(-160+k*70,250),45,PI,TAU,20,Color("#a8a68d"),6,true)
  var throne:=Vector2(3400,6300)-camera
  canvas.draw_arc(throne,185,0,TAU,48,Color(.6,.8,.9,.2),4,true)
  for n in 8:
   var p:=throne+Vector2.from_angle(TAU*n/8)*190
   canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-50),p+Vector2(16,0),p+Vector2(0,18),p+Vector2(-16,0)]),Color("#8299ac"))
 if camera.y<3700:
  var paths:Array=[ [Vector2(350,1750),Vector2(1750,1750)], [Vector2(750,1750),Vector2(750,1100)], [Vector2(1750,1750),Vector2(1750,700),Vector2(2650,700),Vector2(2650,2550)], [Vector2(2650,1750),Vector2(3750,1750),Vector2(3750,900)], [Vector2(3750,1750),Vector2(3750,2900),Vector2(4650,2900),Vector2(4650,1750),Vector2(5650,1750),Vector2(5650,2600)] ]
  for path in paths:
   for k in range(1,path.size()):
    var start:Vector2=path[k-1];var end:Vector2=path[k]
    var steps:=maxi(1,ceili(start.distance_to(end)/42))
    for n in steps+1:
     var world:=start.lerp(end,float(n)/steps)
     if not visible.has_point(world) or not terrain_clear(world):continue
     var point:=world-camera
     canvas.draw_circle(point,56,Color(.6,.54,.34,.14));canvas.draw_circle(point,44,Color(.6,.5,.3,.16))
     canvas.draw_line(point-Vector2(7,4),point+Vector2(6,1),Color(.7,.65,.48,.45),3)
     if n%3==0:canvas.draw_circle(point+Vector2(19,-28),3,Color("#a9a781"))
  for x in [2080,4100]:
   canvas.draw_rect(Rect2(Vector2(x,0)-camera,Vector2(240,3600)),Color("#233643"))
   canvas.draw_rect(Rect2(Vector2(x,0)-camera,Vector2(15,3600)),Color("#779181"))
   var y:=700 if x==2080 else 2900
   var bridge:=Rect2(Vector2(x-30,y-115)-camera,Vector2(300,230));canvas.draw_rect(bridge,Color("#95826a"))
   for n in 11:canvas.draw_line(bridge.position+Vector2(n*27,0),bridge.position+Vector2(n*27,230),Color("#574c43"),3)
  var camp:=Vector2(950,1460)-camera
  canvas.draw_colored_polygon(PackedVector2Array([camp+Vector2(-65,35),camp+Vector2(0,-55),camp+Vector2(65,35)]),Color("#647d6c"));canvas.draw_colored_polygon(PackedVector2Array([camp+Vector2(-25,35),camp+Vector2(0,-25),camp+Vector2(25,35)]),Color("#293b3e"))
  for offset in [-100,100]:
   canvas.draw_rect(Rect2(camp+Vector2(offset-25,45),Vector2(50,12)),Color("#8d7658"));canvas.draw_rect(Rect2(camp+Vector2(offset-15,60),Vector2(30,22)),Color("#655b47"))
  var well:=Vector2(3150,1440)-camera
  canvas.draw_circle(well,54,Color("#586968"));canvas.draw_circle(well,39,Color("#253745"));canvas.draw_arc(well,48,0,TAU,32,Color("#a6b8a0"),7,true)
  for offset in [-45,45]:canvas.draw_line(well+Vector2(offset,10),well+Vector2(offset,-100),Color("#8b8065"),8)
  canvas.draw_line(well+Vector2(-64,-100),well+Vector2(64,-100),Color("#b8a887"),8);canvas.draw_line(well+Vector2(0,-100),well+Vector2(0,10),Color("#d4c2a1"),2)
  var ruin:=Vector2(5350,1450)-camera
  for offset in [-74,74]:
   canvas.draw_rect(Rect2(ruin+Vector2(offset-18,-75),Vector2(36,115)),Color("#74837d"));canvas.draw_rect(Rect2(ruin+Vector2(offset-23,-75),Vector2(46,13)),Color("#a2b5a4"))
  canvas.draw_arc(ruin-Vector2(0,72),74,PI,TAU,32,Color("#8d9e91"),17,true)
  canvas.draw_colored_polygon(PackedVector2Array([ruin+Vector2(0,-50),ruin+Vector2(22,10),ruin+Vector2(0,44),ruin+Vector2(-22,10)]),Color("#9eb9c5"))
  for n in 3:
   var landmark:=Vector2(950+n*2200,1750)-camera
   canvas.draw_string(ThemeDB.fallback_font,landmark+Vector2(-150,-155),["FOXTAIL COMMON","ROOTWELL RIDGE","MOONSTONE GARDEN"][n],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#cbd7ac"))
   canvas.draw_arc(landmark,95,0,TAU,40,Color(.7,.8,.5,.17),2,true)
   for k in 12:
    var point:=landmark+Vector2.from_angle(TAU*k/12)*110
    canvas.draw_circle(point,6,Color("#b7ce9b"));canvas.draw_circle(point-Vector2(0,5),3,Color("#ebd5ad"))
 for prop in props:
  var world:Vector2=prop.pos
  if not visible.has_point(world):continue
  var p:=world-camera;var r:=float(prop.radius)
  canvas.draw_circle(p+Vector2(6,9),r,Color(0,0,0,.16))
  if str(prop.kind)=="tree":
   canvas.draw_rect(Rect2(p-Vector2(7,12),Vector2(14,30)),Color("#715844"))
   canvas.draw_circle(p-Vector2(0,32),r+12,Color("#355749"));canvas.draw_circle(p-Vector2(12,46),r,Color("#4b6b52"));canvas.draw_circle(p+Vector2(13,-41),r-3,Color("#657a55"))
   canvas.draw_circle(p+Vector2(7,-53),5,Color("#c2b178"))
  elif str(prop.kind)=="stone":
   canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(-r,7),p+Vector2(-r*.5,-r),p+Vector2(r*.4,-r*.7),p+Vector2(r,10)]),Color("#6e7c7c"))
   canvas.draw_line(p-Vector2(13,15),p+Vector2(4,-23),Color("#b6cdd0"),3)
  else:
   for k in 3:
    var q:=p+Vector2((k-1)*12,0)
    canvas.draw_colored_polygon(PackedVector2Array([q+Vector2(0,-42+k*7),q+Vector2(9,0),q+Vector2(0,10),q+Vector2(-8,0)]),Color(["#9cbdd2","#90a8bc","#b2a3d0"][k]))
 for gate in routes():
  if not visible.has_point(gate.pos):continue
  var p:Vector2=gate.pos-camera
  canvas.draw_circle(p,58,Color("#465252"));canvas.draw_circle(p+Vector2(0,7),43,Color("#142129"));canvas.draw_arc(p,52,PI,TAU,30,Color("#a7b5a0"),13,true)
  canvas.draw_line(p+Vector2(42,-20),p+Vector2(58,17),Color("#809870"),6,true)
  canvas.draw_circle(p+Vector2(-45,-15),7,Color("#c4dbad"))
  canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-90,-78),str(gate.label),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#d7e3bd"))
  for point in adventure.points().values():
   if (point as Vector2).distance_to(gate.pos)<140:canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-76,80),"E / INTERACT: TRAVEL",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#f0d39a"));break
func draw_on(canvas:Node2D,camera:Vector2)->void:
 if not active:return
 for mine in mines:
  var point:Vector2=adventure.vec(mine.pos)-camera
  if not Rect2(Vector2(-110,-110),canvas.VIEW+Vector2(220,220)).has_point(point):continue
  if bool(mine.spent):canvas.draw_arc(point,12,0,TAU,12,Color(.5,.4,.3,.35),2);continue
  canvas.draw_circle(point,13,Color("#695548"));canvas.draw_circle(point,7,Color("#dbb98a"));canvas.draw_line(point-Vector2(10,0),point+Vector2(10,0),Color("#fae4b2"),2)
  canvas.draw_arc(point,70,0,TAU,32,Color(1,.64,.3,.12),1,true)
  if float(mine.time)>=0:canvas.draw_arc(point,100,0,TAU,36,Color(1,.5,.2,.5+.3*sin(clock*20)),3,true)
 for enemy in adventure.foes():
  if not bool(enemy.get("buried",false)):continue
  var point:Vector2=enemy.pos-camera
  if not Rect2(Vector2(-100,-100),canvas.VIEW+Vector2(200,200)).has_point(point):continue
  var size:=24.0 if not bool(enemy.get("boss",false)) else 58.0
  for n in 3:canvas.draw_arc(point+Vector2((n-1)*12,4),size+n*4,PI*.12,PI*.9,16,Color(.72,.61,.43,.5),3,true)
  for n in 5:canvas.draw_circle(point+Vector2((n-2)*11,sin(clock*9+n)*5),3,Color("#a69b79"))
 for flash in flashes:
  var point:Vector2=adventure.vec(flash.pos)-camera
  var tint:=Color(.6,.9,.5,.4) if bool(flash.get("heal",false)) else Color(.9,.7,.4,.4)
  canvas.draw_circle(point,float(flash.radius)*(1-float(flash.time)/.8),tint)
  canvas.draw_arc(point,float(flash.radius),0,TAU,32,Color(tint,.65),2,true)
