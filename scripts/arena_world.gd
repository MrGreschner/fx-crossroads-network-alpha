extends RefCounted
## Host-owned hazards, replicated compactly. All arenas are neutral to both teams.
const MAPS={"crossroads":"Crossroads Coliseum","sand":"Sinking Sands","storm":"Stormcoil Pit","forest":"Wildbloom Glade","clock":"Clockwork Crucible"}
var game:Node
var map_id="sand"
var clock=0.0
var drones:Array=[]
var flowers:Array=[]
var bolts:Array=[]
var warnings:Array=[]
var tick=0.0
var spawn_timer=0.0
func setup(owner:Node,id:String)->void:
 owner.world_tile_cache.clear()
 if owner.terrain_cache!=null:owner.terrain_cache.reset()
 game=owner;map_id=id if MAPS.has(id) else "sand";clock=0;tick=0;spawn_timer=0;drones.clear();flowers.clear();bolts.clear();warnings.clear()
 if map_id=="crossroads":return
 game.FIELD=Rect2(Vector2.ZERO,Vector2(3200,2300) if map_id=="forest" else Vector2(2400,1800));game.field_obstacles.clear();game.world_buildings.clear();game.world_patches.clear();game.world_decorations.clear();game.world_fountains.clear();game.world_spawns.clear()
 game.world_terrain="school_sand" if map_id=="sand" else "forest" if map_id=="forest" else "storm_floor" if map_id=="storm" else "clock_floor"
 game.art[game.world_terrain]=load("res://assets/"+game.world_terrain+".png")
 for n in 8:
  var angle=TAU*n/8;var point=game.FIELD.size*.5+Vector2(cos(angle)*game.FIELD.size.x*.42,sin(angle)*game.FIELD.size.y*.41)
  game.field_obstacles.append({"pos":point,"radius":36.0,"kind":"tree" if map_id=="forest" else "rock"})
 if map_id=="storm":
  for n in 3:drones.append({"pos":[650+n*500,600+n*180],"phase":n*12.0,"target":[0,0]})
 if map_id=="forest" and game.role=="host":
  var random=RandomNumberGenerator.new();random.seed=game.floor_seed
  for n in 3:game.adventure.spawn(["bramble","archer"].pick_random(),Vector2(random.randf_range(800,2400),random.randf_range(600,1700)),75,false)
  for n in 1:
   var p=Vector2(1150,1000) if n==0 else Vector2(2150,1350)
   game.adventure.spawn("bramble" if n==0 else "archer",p,450,true);game.opponents[-1].expansion_boss=false
func test_enemies(reset:bool=true)->void:
 if game.role!="host" or map_id!="crossroads":return
 if reset:game.opponents.clear()
 game.wave_timer=999999
 for n in range(game.opponents.size(),4):
  var anchor:Vector2=game.positions[game.positions.keys()[n%game.positions.size()]]
  var p=anchor+Vector2.from_angle(n*TAU/4)*220
  for attempt in 12:
   if game._clear_path(p,p):break
   p=anchor+Vector2.from_angle((n+attempt*.31)*TAU/4)*240
  game.adventure.spawn("archer" if n%2==0 else "bramble",p,95,false)
func point(a:Array)->Vector2:return Vector2(float(a[0]),float(a[1]))
func pits()->Array:return [Vector2(850,720),Vector2(1550,1080),Vector2(1230,1420)]
func slow(p:Vector2)->float:
 if not is_instance_valid(game) or game.mode!="arena":return 1.0
 if map_id=="sand":
  for pit in pits():
   if p.distance_to(pit)<150:return .55
 if map_id=="storm":
  for drone in drones:
   if fposmod(clock+float(drone.phase),44)>=36 and p.distance_to(point(drone.pos))<170:return .3
 return 1.0
func nearest(p:Vector2)->Vector2:
 var best=p;var distance=INF
 for id in game.positions:
  if int(game.health.get(id,0))<=0:continue
  var d=p.distance_squared_to(game.positions[id])
  if d<distance:distance=d;best=game.positions[id]
 return best
func harm(p:Vector2,radius:float,damage:float)->void:
 for id in game.positions:
  if int(game.health.get(id,0))>0 and p.distance_to(game.positions[id])<radius:game._hurt(str(id),damage,"environment","",preload("res://scripts/defeat_credit.gd").hazard("Arena hazard"))
func step(delta:float)->void:
 if not is_instance_valid(game) or game.mode!="arena" or game.role!="host":return
 clock+=delta;tick+=delta;spawn_timer-=delta
 if map_id=="crossroads" and game.get("dedicated")==true and spawn_timer<=0:
  spawn_timer=15
  if game.opponents.size()<2:test_enemies(false)
 if map_id=="storm":
  for drone in drones:
   var previous=float(drone.get("elapsed",float(drone.phase)));var elapsed=clock+float(drone.phase);drone.elapsed=elapsed
   var p=point(drone.pos);p=p.move_toward(nearest(p),delta*(80 if fposmod(elapsed,44)>=36 else 45));p=p.clamp(Vector2(200,200),game.FIELD.end-Vector2(200,200));drone.pos=[p.x,p.y]
   var phase=fposmod(elapsed,44)
   var previous_phase=fposmod(previous,44)
   if phase<36 and floori(phase/6)>floori(previous_phase/6) or phase>=36 and previous_phase<36:warnings.append({"pos":[p.x,p.y],"time":.7,"total":.7,"damage":16.0,"radius":105.0,"kind":"bolt"})
   if phase>=36 and tick>=.2:harm(p,170,1)
 elif map_id=="forest":
  if spawn_timer<=0:
   spawn_timer=4;var p=Vector2(400+randf()*2400,350+randf()*1600);flowers.append({"pos":[p.x,p.y],"time":9.0,"fire":1.2})
   if flowers.size()>6:flowers.pop_front()
  for n in range(flowers.size()-1,-1,-1):
   var flower:Dictionary=flowers[n];flower.time-=delta;flower.fire-=delta
   if flower.time<=0:flowers.remove_at(n);continue
   if flower.fire<=0:
    flower.fire=2;var p=point(flower.pos);var direction:Vector2=(nearest(p)-p).normalized();game.missiles.append({"pos":p,"direction":direction,"speed":320.0,"damage":9.0,"owner":"enemy","distance":0.0,"range":960.0,"color":"#ff9650"})
 elif map_id=="clock" and spawn_timer<=0:
  spawn_timer=5;var vertical=int(clock/5)%2==0;var center=Vector2(500+fposmod(clock*97,1400),900) if vertical else Vector2(1200,450+fposmod(clock*61,900))
  warnings.append({"pos":[center.x,center.y],"time":1.2,"total":1.2,"damage":18.0,"radius":0.0,"kind":"stripe","vertical":vertical})
 for n in range(warnings.size()-1,-1,-1):
  var w:Dictionary=warnings[n];w.time-=delta
  if w.time<=0:
   var p=point(w.pos)
   if w.kind=="stripe":
    for id in game.positions:
     var offset:Vector2=game.positions[id]-p
     if absf(offset.x if bool(w.vertical) else offset.y)<70:game._hurt(str(id),float(w.damage),"environment","",preload("res://scripts/defeat_credit.gd").hazard("Arena lightning"))
   else:harm(p,float(w.radius),float(w.damage))
   game._emit_effect({"pos":p,"radius":100.0,"time":.3,"color":"#b8eafa"});warnings.remove_at(n)
 for n in range(bolts.size()-1,-1,-1):
  var bolt:Dictionary=bolts[n];bolt.time-=delta;var start=point(bolt.pos);var end=start+point(bolt.dir)*320*delta;bolt.pos=[end.x,end.y];var hit=false
  if not game._clear_path(start,end):hit=true
  for id in game.positions:
   if int(game.health.get(id,0))>0 and game._segment_near(start,end,game.positions[id],25):game._hurt(str(id),9,"environment","",preload("res://scripts/defeat_credit.gd").hazard("Forest fireball"));hit=true;break
  if hit or bolt.time<=0:bolts.remove_at(n)
 if tick>=.2:tick=fposmod(tick,.2)
func snapshot()->Dictionary:return {"map":map_id,"clock":clock,"drones":drones,"flowers":flowers,"bolts":bolts,"warnings":warnings}
func receive(data:Dictionary)->void:
 map_id=str(data.get("map",map_id));clock=float(data.get("clock",clock));drones=data.get("drones",[]);flowers=data.get("flowers",[]);bolts=data.get("bolts",[]);warnings=data.get("warnings",[])
func draw()->void:
 if not is_instance_valid(game) or game.mode!="arena":return
 var camera:Vector2=game.camera;var font:Font=ThemeDB.fallback_font
 if map_id=="sand":
  for p in pits():
   game.draw_circle(p-camera,150,Color(.35,.22,.12,.4));game.draw_arc(p-camera,150,0,TAU,40,Color("#d4b178"),3)
   for n in 4:game.draw_arc(p-camera,30+n*28,clock*.15,clock*.15+PI*1.5,32,Color(.75,.56,.3,.35),2)
 elif map_id=="storm":
  for drone in drones:
   var p=point(drone.pos)-camera;var orb=fposmod(clock+float(drone.phase),44)>=36
   if orb:
    game.draw_circle(p,170,Color(.25,.65,.95,.15));game.draw_arc(p,170,clock*2,clock*2+TAU*.85,40,Color("#8fd8ff"),3);game.draw_circle(p,42,Color("#b8eafa"))
   else:
    game.draw_circle(p+Vector2(0,18),35,Color(0,0,0,.25));game.draw_rect(Rect2(p-Vector2(35,40),Vector2(70,28)),Color("#8bafc5"));game.draw_circle(p-Vector2(0,26),12,Color("#aeeeff"))
    for x in [-1,1]:game.draw_line(p+Vector2(x*22,-32),p+Vector2(x*60,-32),Color("#e0f5f7"),4)
 elif map_id=="forest":
  for flower in flowers:
   var p=point(flower.pos)-camera;var scale=minf(1,(9-float(flower.time))*2)
   for n in 6:game.draw_circle(p+Vector2.from_angle(n*TAU/6)*18*scale,15*scale,Color("#edaa85"))
   game.draw_circle(p,10*scale,Color("#ffd173"))
 for w in warnings:
  var p=point(w.pos)-camera
  if w.kind=="stripe":
   var r=Rect2(p-Vector2(70,1800),Vector2(140,3600)) if bool(w.vertical) else Rect2(p-Vector2(2400,70),Vector2(4800,140));preload("res://scripts/combat_cues.gd").rectangle(game,r,float(w.time),float(w.total))
  else:preload("res://scripts/combat_cues.gd").danger(game,p,float(w.radius),float(w.time),float(w.total))
 for bolt in bolts:game.draw_circle(point(bolt.pos)-camera,9,Color("#ff9650"))
 if game.spectating():return

