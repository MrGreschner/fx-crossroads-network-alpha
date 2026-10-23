extends Node
## Collision, doors, city enemy tactics and camera-culled native world art.
var adventure:Node
var active:=false
var buildings:Array=[]
var walls:Array[Rect2]=[]
var doors:Array=[]
var eruptions:Array=[]
var rifts:Array=[]
var next_rift=0
var clock:=0.0
var last_door:=0.0
var grid:AStarGrid2D
var blockers:Dictionary={}
const SIZE=Vector2(3840,2560)
const TYPES=["copper_constable","grate_witch","lockmaster_regent","amber_hornet","brass_sapper","keywing_courier","hinge_conjurer","latch_hound"]
func setup(id:String)->void:
 active=id=="brasslock";rifts.clear();next_rift=0;clock=0;last_door=-1;buildings.clear();walls.clear();doors.clear();eruptions.clear();blockers.clear();grid=null
 if not active:return
 for row in 3:
  for col in 5:
   var origin:=Vector2(170+col*720,170+row*740)
   var rect:=Rect2(origin,Vector2(560,480));buildings.append({"rect":rect,"index":row*5+col})
   # Wide doorway gaps connect a two-room interior to both streets.
   for y in [0,442]:
    walls.append(Rect2(origin+Vector2(0,y),Vector2(100,38)))
    walls.append(Rect2(origin+Vector2(260,y),Vector2(300,38)))
    doors.append({"rect":[origin.x+100,origin.y+y,160.0,38.0],"open":row==1 and col==0,"anim":0.0})
   walls.append(Rect2(origin,Vector2(38,480)));walls.append(Rect2(origin+Vector2(522,0),Vector2(38,480)))
   walls.append(Rect2(origin+Vector2(260,38),Vector2(38,110)))
   walls.append(Rect2(origin+Vector2(260,310),Vector2(38,132)))
   doors.append({"rect":[origin.x+260,origin.y+148,38.0,162.0],"open":false,"anim":0.0})
 build_blockers()
 rebuild_grid()
func door_rect(door:Dictionary)->Rect2:
 var r:Array=door.rect
 return Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3]))
func build_blockers()->void:
 blockers.clear()
 var entries:Array=[]
 for wall in walls:entries.append({"rect":wall.grow(18),"door":-1})
 for n in doors.size():entries.append({"rect":door_rect(doors[n]).grow(18),"door":n})
 for entry in entries:
  var rect:Rect2=entry.rect
  for x in range(floori(rect.position.x/128),floori(rect.end.x/128)+1):
   for y in range(floori(rect.position.y/128),floori(rect.end.y/128)+1):
    var cell:=Vector2i(x,y)
    if not blockers.has(cell):blockers[cell]=[]
    blockers[cell].append(entry)
func can_stand(point:Vector2)->bool:
 if not Rect2(Vector2(32,32),SIZE-Vector2(64,64)).has_point(point):return false
 for entry in blockers.get(Vector2i(floori(point.x/128),floori(point.y/128)),[]):
  if int(entry.door)>=0 and bool(doors[int(entry.door)].open):continue
  if (entry.rect as Rect2).has_point(point):
   var passage=false
   for portal in rifts:
    if bool(portal.open) and rift_rect(portal).has_point(point):passage=true;break
   if not passage:return false
 return true
func rebuild_grid()->void:
 grid=AStarGrid2D.new();grid.region=Rect2i(0,0,96,64);grid.cell_size=Vector2(40,40);grid.offset=Vector2(20,20);grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER;grid.update()
 for x in 96:
  for y in 64:grid.set_point_solid(Vector2i(x,y),not can_stand(Vector2(x*40+20,y*40+20)))
 for enemy in adventure.foes():enemy.erase("city_path");enemy["route_timer"]=0.0
func interact(id:String)->bool:
 if not active or not adventure.alive(id):return false
 var point:Vector2=adventure.points().get(id,Vector2.ZERO)
 for door in doors:
  if point.distance_to(door_rect(door).get_center())>120:continue
  if clock-last_door<.35:return true
  if bool(door.open):
   var occupied:=false
   for position in adventure.points().values():
    if door_rect(door).grow(36).has_point(position):occupied=true
   for enemy in adventure.foes():
    if door_rect(door).grow(36).has_point(enemy.pos):occupied=true
   if occupied:return true
  door.open=not bool(door.open);last_door=clock;rebuild_grid();return true
 return false
func route(enemy:Dictionary,target:Vector2,delta:float)->Vector2:
 var point:Vector2=enemy.pos
 if not active or adventure.combat.path_clear(point,target):return (target-point).normalized()
 enemy["route_timer"]=float(enemy.get("route_timer",0))-delta
 if float(enemy.route_timer)<=0:
  enemy.route_timer=.6
  var start:=Vector2i(floori(point.x/40),floori(point.y/40));var end:=Vector2i(floori(target.x/40),floori(target.y/40))
  if grid.is_in_boundsv(start) and grid.is_in_boundsv(end) and not grid.is_point_solid(end):enemy.city_path=grid.get_point_path(start,end)
  else:enemy.city_path=PackedVector2Array()
 var path:PackedVector2Array=enemy.get("city_path",PackedVector2Array())
 while not path.is_empty() and point.distance_to(path[0])<28:path.remove_at(0)
 enemy.city_path=path
 return (path[0]-point).normalized() if not path.is_empty() else Vector2.ZERO
func quake(point:Vector2,damage:float,delay:float,source:String="")->void:
 if eruptions.size()<48:eruptions.append({"credit":preload("res://scripts/defeat_credit.gd").resolve(adventure.game,source,"Ground eruption"),"pos":[point.x,point.y],"time":delay,"duration":delay,"damage":damage,"hit":false,"radius":55.0})
func step(delta:float)->void:
 if not active:return
 clock+=delta
 step_rifts(delta)
 for door in doors:door.anim=move_toward(float(door.anim),1.0 if bool(door.open) else 0.0,delta*4)
 for i in range(eruptions.size()-1,-1,-1):
  var blast:Dictionary=eruptions[i];blast.time-=delta
  if float(blast.time)<=0 and not bool(blast.hit):
   blast.hit=true
   for id in adventure.points():
    var target:Vector2=adventure.points()[id]
    if target.distance_to(adventure.vec(blast.pos))<float(blast.radius)+18 and adventure.combat.path_clear(adventure.vec(blast.pos),target):adventure.hit_player(str(id),float(blast.damage),"",blast.get("credit",{}))
  if float(blast.time)<-.35:eruptions.remove_at(i)
 for enemy in adventure.foes().duplicate():
  if str(enemy.type) not in TYPES or adventure.combat.stunned(adventure.combat.npc_key(enemy)):continue
  var target:=Vector2.ZERO;var nearest:=INF
  for id in adventure.points():
   if adventure.alive(str(id)) and (enemy.pos as Vector2).distance_to(adventure.points()[id])<nearest:target=adventure.points()[id];nearest=(enemy.pos as Vector2).distance_to(target)
  if nearest>1100:continue
  if str(enemy.type)=="hinge_conjurer":
   enemy["door_timer"]=float(enemy.get("door_timer",2.0))-delta
   if float(enemy.door_timer)<=0 and adventure.authoritative():
    enemy.door_timer=10.5;open_rift(target)
  if str(enemy.type)=="latch_hound":
   var move:Vector2=route(enemy,target,delta)*205*delta*adventure.combat.speed_factor(adventure.combat.npc_key(enemy))
   if adventure.combat.path_clear(enemy.pos,enemy.pos+move):enemy.pos+=move
   enemy["bite_timer"]=float(enemy.get("bite_timer",.8))-delta
   if nearest<65 and float(enemy.bite_timer)<=0:enemy.bite_timer=1.2;adventure.warn(enemy.pos+(target-enemy.pos).normalized()*20,42,8,.3)
   continue
  if nearest>760:continue
  var boss:=str(enemy.type)=="lockmaster_regent"
  var lure:Vector2=adventure.combat.fern.redirect(enemy,target)
  var direction:=route(enemy,lure,delta)
  if adventure.combat.path_clear(enemy.pos,lure) and not boss:direction=adventure.combat.ranged_direction(enemy,lure)
  var speed:=115.0 if boss else 145.0 if str(enemy.type)=="keywing_courier" else 90.0 if str(enemy.type)=="brass_sapper" else 78.0 if str(enemy.type)=="copper_constable" else 62.0
  var move:Vector2=direction*speed*adventure.combat.speed_factor(adventure.combat.npc_key(enemy))*delta
  if adventure.combat.path_clear(enemy.pos,enemy.pos+move):enemy.pos+=move
  enemy["city_timer"]=float(enemy.get("city_timer",1.1))-delta
  if float(enemy.city_timer)>0 or not adventure.combat.path_clear(enemy.pos,target):continue
  enemy.city_timer=2.6 if boss else 3.2 if str(enemy.type)=="copper_constable" else 4.0
  var origin:Vector2=enemy.pos;var aim:Vector2=(target-origin).normalized()
  var turn:=int(enemy.get("city_turn",0));enemy.city_turn=turn+1
  if str(enemy.type)=="brass_sapper":
   quake(target,13,1.25,adventure.combat.npc_key(enemy));enemy.city_timer=3.8
  elif str(enemy.type)=="keywing_courier":
   for angle in [-.14,.14]:adventure.combat.launch_projectile("enemy",origin,aim.rotated(angle),{"range":640,"speed":300,"return_distance":230,"color":"#e7d58f"},8,"echo_bolt")
   enemy.city_timer=2.8
  elif str(enemy.type)=="amber_hornet":
   for angle in [-.2,0,.2]:adventure.combat.launch_projectile("enemy",origin,aim.rotated(angle),{"range":580,"speed":215,"amplitude":20,"wavelength":155,"slow_duration":1.2,"slow_factor":.75,"color":"#efc36b"},8,"weaving")
   enemy.city_timer=3.5
  elif str(enemy.type) in ["copper_constable","hinge_conjurer"] or boss and turn%3==0:
   for angle in [-.28,0,.28]:adventure.combat.launch_projectile("enemy",origin,aim.rotated(angle),{"range":700,"speed":235,"wall_bounces":2,"color":"#ffcc87"},18 if boss else 10,"bankshot")
  elif str(enemy.type)=="grate_witch" or boss and turn%3==1:
   for n in 4 if boss else 3:
    var landing:=target+aim*(n-1)*90
    if adventure.combat.path_clear(target,landing):quake(landing,24 if boss else 13,.9+n*.22,adventure.combat.npc_key(enemy))
  else:
   # Telegraph a collision-aware lunge; the Regent never teleports through masonry.
   var end:=origin
   for n in 32:
    var next:=end+aim*10
    if not adventure.combat.path_clear(end,next):break
    end=next
   adventure.warn(origin,34,28,.8,end);adventure.warnings[-1]["charge_uid"]=int(enemy.uid)
func snapshot()->Dictionary:return {"doors":doors,"eruptions":eruptions,"rifts":rifts,"clock":clock}
func receive(data:Dictionary)->void:
 var old_rifts=rifts.duplicate(true)
 var old:Array=[]
 for door in doors:old.append(bool(door.open))
 doors=data.get("doors",doors);eruptions=data.get("eruptions",[]);rifts=data.get("rifts",[]);clock=float(data.get("clock",clock))
 var changed:=old.size()!=doors.size()
 for i in mini(old.size(),doors.size()):
  if old[i]!=bool(doors[i].open):changed=true
 if active and changed:rebuild_grid()
 if old_rifts.map(func(v):return str(v.id)+str(v.open))!=rifts.map(func(v):return str(v.id)+str(v.open)):
  for portal in old_rifts+rifts:refresh_rift(rift_rect(portal))

func draw_world(canvas:Node2D,camera:Vector2)->void:
 var view:Vector2=canvas.VIEW;var visible:=Rect2(camera-Vector2(100,100),view+Vector2(200,200))
 for building in buildings:
  var world:Rect2=building.rect
  if not visible.intersects(world):continue
  var rect:=Rect2(world.position-camera,world.size)
  canvas.draw_rect(rect.grow(16),Color("#26353e"));canvas.draw_rect(rect,Color("#605748"))
  canvas.draw_rect(Rect2(rect.position+Vector2(38,38),rect.size-Vector2(76,76)),Color("#8c7c62"))
  for n in 9:canvas.draw_line(rect.position+Vector2(38,55+n*42),rect.position+Vector2(522,55+n*42),Color(.28,.23,.2,.2),1)
  var index:int=building.index
  for side in [0,1]:
   var p:=rect.position+Vector2(80+side*335,90)
   canvas.draw_rect(Rect2(p+Vector2(4,6),Vector2(64,40)),Color(0,0,0,.3))
   canvas.draw_rect(Rect2(p,Vector2(64,40)),Color("#604638"));canvas.draw_rect(Rect2(p+Vector2(3,3),Vector2(58,8)),Color("#9f7752"))
   for k in 3:canvas.draw_rect(Rect2(p+Vector2(8+k*17,4),Vector2(9,14)),Color(["#e2ab5a","#659c91","#a884a1"][(index+k)%3]))
  canvas.draw_rect(Rect2(rect.position+Vector2(85,320),Vector2(105,60)),Color("#586e73"))
  canvas.draw_rect(Rect2(rect.position+Vector2(365,305),Vector2(100,70)),Color("#8a5944"))
  canvas.draw_string(ThemeDB.fallback_font,rect.position+Vector2(72,265),["KEYWORKS","TEA HOUSE","CLOCK SHOP","ARCHIVES","WARDHOUSE"][index%5],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#dfcfaa"))
 for wall in walls:
  if not visible.intersects(wall):continue
  var rect:=Rect2(wall.position-camera,wall.size)
  canvas.draw_rect(rect,Color("#283540"));canvas.draw_rect(Rect2(rect.position,Vector2(rect.size.x,8)),Color("#b2a48e"))
  for x in range(0,int(rect.size.x),40):
   for y in range(8,int(rect.size.y),20):canvas.draw_line(rect.position+Vector2(x+(10 if y%40 else 0),y),rect.position+Vector2(x+(10 if y%40 else 0),minf(y+18,rect.size.y)),Color("#52616a"),1)
  if rect.size.x>100:
   var center:=rect.get_center();canvas.draw_rect(Rect2(center-Vector2(16,9),Vector2(32,20)),Color("#e8ba69"));canvas.draw_line(center-Vector2(0,9),center+Vector2(0,10),Color("#394954"),3)
 for door in doors:
  var world:=door_rect(door)
  if not visible.intersects(world.grow(70)):continue
  var rect:=Rect2(world.position-camera,world.size);var horizontal:=rect.size.x>rect.size.y
  var hinge:=rect.position+(Vector2(0,19) if horizontal else Vector2(19,0));var leaf:=Vector2(rect.size.x,0) if horizontal else Vector2(0,rect.size.y);var size:=leaf.rotated(float(door.anim)*PI*.5 if horizontal else -float(door.anim)*PI*.5)
  canvas.draw_line(hinge,hinge+size,Color("#372b29"),12,true);canvas.draw_line(hinge+Vector2(0,-3),hinge+size+Vector2(0,-3),Color("#ad7951"),5,true)
  canvas.draw_circle(hinge+size*.82,4,Color("#ffe3a0"))
  for id in adventure.points():
   if (adventure.points()[id] as Vector2).distance_to(world.get_center())<120:
    canvas.draw_string(ThemeDB.fallback_font,world.get_center()-camera+Vector2(-60,-42),"E / INTERACT: "+("CLOSE" if bool(door.open) else "OPEN")+" DOOR",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#ffe7b0"));break
 # Sidewalk lighting, drain grates, street signs and bunting anchor the streets.
 for row in 4:
  for col in 5:
   var p:=Vector2(120+col*720,100+row*740)
   if not visible.has_point(p):continue
   p-=camera
   canvas.draw_circle(p,45,Color(1,.7,.3,.06));canvas.draw_line(p,p-Vector2(0,65),Color("#273944"),7)
   canvas.draw_rect(Rect2(p-Vector2(12,70),Vector2(24,25)),Color("#f4ca80"));canvas.draw_rect(Rect2(p-Vector2(15,74),Vector2(30,5)),Color("#31404b"))
   canvas.draw_rect(Rect2(p+Vector2(35,22),Vector2(38,28)),Color("#27343b"))
   for k in 5:canvas.draw_line(p+Vector2(39+k*6,24),p+Vector2(39+k*6,47),Color("#798081"),2)
 for col in 5:
  var p:=Vector2(450+col*720,2280)-camera
  if not Rect2(-Vector2(100,100),view+Vector2(200,200)).has_point(p):continue
  canvas.draw_line(p-Vector2(90,0),p+Vector2(90,0),Color("#b7a47a"),2)
  for k in 5:canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(-80+k*35,0),p+Vector2(-60+k*35,0),p+Vector2(-70+k*35,24)]),Color("#7a879b"))
 for portal in rifts:
  var p=Vector2(portal.pos[0],portal.pos[1])-camera
  if not Rect2(Vector2.ZERO,canvas.get_viewport_rect().size).grow(150).has_point(p):continue
  var shape=rift_rect(portal);shape.position-=camera
  canvas.draw_rect(shape,Color("#1c263c"));canvas.draw_rect(shape,Color("#ecc16c"),false,5)
  for k in 4:canvas.draw_arc(p,27+k*8,clock*.8+k,clock*.8+k+PI*1.5,24,Color(.95,.76,.4,.65-k*.1),2,true)
  canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-110,-80),"SECRET DOOR • 2 HOUNDS" if not bool(portal.spawned) else "SECRET PASSAGE",HORIZONTAL_ALIGNMENT_CENTER,220,14,Color("#f8d68b"))

func draw_on(canvas:Node2D,camera:Vector2)->void:
 for blast in eruptions:
  var point:Vector2=adventure.vec(blast.pos)-camera;var radius:=float(blast.radius)
  canvas.draw_arc(point,radius,0,TAU,28,Color(1,.55,.3,.8),3,true)
  if not bool(blast.hit):
   preload("res://scripts/combat_cues.gd").danger(canvas,point,radius,float(blast.time),float(blast.get("duration",1)))
  else:
   for n in 7:canvas.draw_line(point+Vector2((n-3)*12,12),point+Vector2((n-3)*16,-50),Color(1,.65,.3,.65),6,true)

func rift_rect(portal:Dictionary)->Rect2:
 var r=portal.rect;return Rect2(r[0],r[1],r[2],r[3])
func open_rift(target:Vector2)->bool:
 if rifts.size()>=3:return false
 var hounds=0
 for foe in adventure.foes():
  if str(foe.type)=="latch_hound":hounds+=1
 if hounds>=6:return false
 var choice={};var closest=INF
 for wall in walls:
  if wall.size.x<100 and wall.size.y<100:continue
  var horizontal=wall.size.x>wall.size.y;var center=wall.get_center()
  if horizontal:center.x=clampf(target.x,wall.position.x+45,wall.end.x-45)
  else:center.y=clampf(target.y,wall.position.y+65,wall.end.y-65)
  var normal=Vector2.DOWN if horizontal else Vector2.RIGHT;var p=center+normal*85;var q=center-normal*85
  if not can_stand(p) or not can_stand(q):continue
  var distance=center.distance_to(target)
  if distance>420 or distance<70 or distance>=closest:continue
  var overlaps=false
  for portal in rifts:
   if center.distance_to(Vector2(portal.pos[0],portal.pos[1]))<180:overlaps=true
  if overlaps:continue
  var near=p if p.distance_to(target)<q.distance_to(target) else q
  var rect=Rect2(center-Vector2(62,60),Vector2(124,120)) if horizontal else Rect2(center-Vector2(60,62),Vector2(120,124))
  choice={"id":next_rift,"pos":[center.x,center.y],"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"exit":[near.x,near.y],"side":[normal.y,-normal.x],"time":0.0,"open":false,"spawned":false};closest=distance
 if choice.is_empty():return false
 next_rift+=1;rifts.append(choice);return true
func refresh_rift(rect:Rect2)->void:
 if grid==null:return
 for x in range(maxi(0,floori((rect.position.x-40)/40)),mini(96,ceili((rect.end.x+40)/40))):
  for y in range(maxi(0,floori((rect.position.y-40)/40)),mini(64,ceili((rect.end.y+40)/40))):grid.set_point_solid(Vector2i(x,y),not can_stand(Vector2(x*40+20,y*40+20)))
 for enemy in adventure.foes():enemy.erase("city_path");enemy.route_timer=0.0
func step_rifts(dt:float)->void:
 if not adventure.authoritative():return
 for i in range(rifts.size()-1,-1,-1):
  var portal=rifts[i];portal.time=float(portal.time)+dt
  if float(portal.time)>=1.2 and not bool(portal.spawned):
   portal.open=true;portal.spawned=true;refresh_rift(rift_rect(portal))
   for side in [-1,1]:
    var p=Vector2(portal.exit[0],portal.exit[1])+Vector2(portal.side[0],portal.side[1])*side*28
    if can_stand(p):adventure.spawn("latch_hound",p,42,false);adventure.foes()[-1].summoned=true
  if float(portal.time)<9.2:continue
  var occupied=false
  for point in adventure.points().values():
   if rift_rect(portal).grow(32).has_point(point):occupied=true
  for foe in adventure.foes():
   if float(foe.hp)>0 and rift_rect(portal).grow(32).has_point(foe.pos):occupied=true
  if occupied:continue
  var rect=rift_rect(portal);rifts.remove_at(i);refresh_rift(rect)
