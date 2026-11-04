extends RefCounted
## Host-owned hazards, replicated compactly. All arenas are neutral to both teams.
const MAPS={"crossroads":"Crossroads Coliseum","sand":"Sinking Sands","storm":"Stormcoil Pit","forest":"Wildbloom Glade","clock":"Clockwork Crucible","maze":"Shifting Labyrinth","lanternfall":"Lanternfall","colour_clash":"Colour Clash","crown_chase":"Crown Chase","shatterfloor":"Shatterfloor"}
var extra=preload("res://scripts/arena_variants.gd").new()
var shatter=preload("res://scripts/arena_shatterfloor.gd").new()
var objective=preload("res://scripts/arena_objectives.gd").new()
var game:Node
var map_id="sand"
var clock=0.0
var drones:Array=[]
var flowers:Array=[]
var bolts:Array=[]
var warnings:Array=[]
var tick=0.0
var spawn_timer=0.0
var gear_cycle:=0
const GEARS=[Vector2(240,240),Vector2(2160,240),Vector2(240,1560),Vector2(2160,1560),Vector2(1200,900)]
func setup(owner:Node,id:String)->void:
 owner.world_tile_cache.clear()
 if owner.terrain_cache!=null:owner.terrain_cache.reset()
 game=owner;map_id=id if MAPS.has(id) else "sand";clock=0;tick=0;spawn_timer=0;gear_cycle=0;drones.clear();flowers.clear();bolts.clear();warnings.clear()
 extra.setup(self)
 objective.setup(self)
 shatter.setup(self)
 if map_id in ["maze","lanternfall","crossroads","colour_clash","crown_chase","shatterfloor"]:return
 game.FIELD=Rect2(Vector2.ZERO,Vector2(3200,2300) if map_id=="forest" else Vector2(2400,1800));game.field_obstacles.clear();game.world_buildings.clear();game.world_patches.clear();game.world_decorations.clear();game.world_fountains.clear();game.world_spawns.clear()
 game.world_terrain="school_sand" if map_id=="sand" else "forest" if map_id=="forest" else "storm_floor" if map_id=="storm" else "clock_floor"
 game.art[game.world_terrain]=load("res://assets/"+game.world_terrain+".png")
 for n in 8:
  var angle=TAU*n/8;var point=game.FIELD.size*.5+Vector2(cos(angle)*game.FIELD.size.x*.42,sin(angle)*game.FIELD.size.y*.41)
  if map_id=="forest":
   if absf(point.x-1600)<155:point.x+=230*(1 if n<4 else -1)
   if absf(point.y-1150)<145:point.y+=230*(1 if n<4 else -1)
  game.field_obstacles.append({"pos":point,"radius":36.0,"kind":"tree" if map_id=="forest" else "rock"})
 if map_id=="forest":forest_groves()
 game._rebuild_grid()
 if map_id=="storm":
  for n in 3:drones.append({"pos":[650+n*500,600+n*180],"phase":n*12.0,"target":[0,0]})
 if map_id=="forest" and game.role=="host":
  var random=RandomNumberGenerator.new();random.seed=game.floor_seed
  for n in 3:game.adventure.spawn(["bramble","archer"].pick_random(),open_floor(Vector2(random.randf_range(800,2400),random.randf_range(600,1700))),75,false)
  for n in 1:
   var p=Vector2(1150,1000) if n==0 else Vector2(2150,1350)
   game.adventure.spawn("bramble" if n==0 else "archer",open_floor(p),450,true);game.opponents[-1].expansion_boss=false
func forest_groves()->void:
 var rng=RandomNumberGenerator.new();rng.seed=game.floor_seed+289
 # The two broad crossing clearings and all eight respawn pockets stay open.
 for row in 8:
  for column in 12:
   var p=Vector2(160+column*260,180+row*280)+Vector2(rng.randf_range(-52,52),rng.randf_range(-50,50))
   if absf(p.x-1600)<155 or absf(p.y-1150)<145:continue
   if game.field_obstacles.any(func(o):return (o.pos as Vector2).distance_to(p)<145):continue
   var reserved=false
   for n in 8:
    var angle=TAU*n/8;var anchor=game.FIELD.size*.5+Vector2(cos(angle)*game.FIELD.size.x*.30,sin(angle)*game.FIELD.size.y*.30)
    if p.distance_to(anchor)<165:reserved=true;break
   if not reserved:game.field_obstacles.append({"pos":p,"radius":32.0,"kind":"tree","grove_scale":rng.randf_range(1.15,1.65)})
func open_floor(p:Vector2)->Vector2:
 for ring in range(0,16):
  for n in (1 if ring==0 else 16):
   var q=p+Vector2.from_angle(n*TAU/16)*ring*25
   if game.FIELD.grow(-65).has_point(q) and game._clear_path(q,q):return q
 return game.FIELD.size*.5
func clock_trigger()->void:
 var index=gear_cycle%5;var shapes:Array=[];var sources:Array=[]
 if index==4:
  shapes=[Rect2(1080,40,240,1720),Rect2(40,780,2320,240)];sources=[4]
 elif index%2==0:
  shapes=[Rect2(480,40,240,1720),Rect2(1680,40,240,1720)];sources=[index,(index+1)%4]
 else:
  shapes=[Rect2(40,330,2320,240),Rect2(40,1230,2320,240)];sources=[index,(index+2)%4]
 var packed:Array=[]
 for r in shapes:packed.append([r.position.x,r.position.y,r.size.x,r.size.y])
 warnings.append({"kind":"gear_grid","time":1.7,"total":1.7,"life":1.0,"damage":18.0,"shapes":packed,"gears":sources,"hits":[]});gear_cycle+=1
 game.status_label.text="GEAR OVERLOAD • Amber lanes charge; blue lanes strike • Find the open floor"
static func clock_shapes(w:Dictionary)->Array:
 var result:Array=[]
 for r in w.get("shapes",[]):result.append(Rect2(r[0],r[1],r[2],r[3]))
 return result
func clock_warning_step(w:Dictionary,dt:float)->bool:
 var old=float(w.time);w.time=old-dt
 if float(w.time)>0:return false
 w.life=float(w.life)-(dt if old<=0 else maxf(0,-float(w.time)))
 if float(w.life)<=0:return true
 var shapes=clock_shapes(w)
 for id in game.positions:
  if int(game.health.get(id,0))<=0 or id in w.hits or Time.get_ticks_msec()<int(game.invincible_until.get(id,0)):continue
  if shapes.any(func(r):return r.has_point(game.positions[id])):
   w.hits.append(id);game._hurt(str(id),float(w.damage),"environment","",preload("res://scripts/defeat_credit.gd").hazard("Clockwork gear overload"))
 return false
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
 extra.step(delta)
 objective.step(delta)
 shatter.step(delta)
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
   spawn_timer=4;var p=open_floor(Vector2(400+randf()*2400,350+randf()*1600));flowers.append({"pos":[p.x,p.y],"time":9.0,"fire":1.2})
   if flowers.size()>6:flowers.pop_front()
  for n in range(flowers.size()-1,-1,-1):
   var flower:Dictionary=flowers[n];flower.time-=delta;flower.fire-=delta
   if flower.time<=0:flowers.remove_at(n);continue
   if flower.fire<=0:
    flower.fire=2;var p=point(flower.pos);var direction:Vector2=(nearest(p)-p).normalized();game.missiles.append({"pos":p,"direction":direction,"speed":320.0,"damage":9.0,"owner":"enemy","distance":0.0,"range":960.0,"color":"#ff9650"})
 elif map_id=="clock" and spawn_timer<=0:
  spawn_timer=5;clock_trigger()
 for n in range(warnings.size()-1,-1,-1):
  var w:Dictionary=warnings[n];w.time-=delta
  if w.kind=="gear_grid":
   w.time+=delta
   if clock_warning_step(w,delta):warnings.remove_at(n)
   continue
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
func snapshot()->Dictionary:return {"map":map_id,"clock":clock,"gear_cycle":gear_cycle,"drones":drones,"flowers":flowers,"bolts":bolts,"warnings":warnings,"variant":extra.snapshot() if extra.active() else {},"shatter":shatter.snapshot() if shatter.active() else {},"objective":objective.snapshot() if objective.active() else {}}
func receive(data:Dictionary)->void:
 map_id=str(data.get("map",map_id));clock=float(data.get("clock",clock));gear_cycle=int(data.get("gear_cycle",gear_cycle));drones=data.get("drones",[]);flowers=data.get("flowers",[]);bolts=data.get("bolts",[]);warnings=data.get("warnings",[])
 if extra.active():extra.receive(data.get("variant",{}))
 if shatter.active():shatter.receive(data.get("shatter",{}))
 if objective.active():objective.receive(data.get("objective",{}))
func draw()->void:
 if not is_instance_valid(game) or game.mode!="arena":return
 extra.draw_ground()
 objective.draw_ground()
 shatter.draw_ground()
 var camera:Vector2=game.camera;var font:Font=ThemeDB.fallback_font
 preload("res://scripts/arena_art261.gd").features(self)
 for w in warnings:
  if w.kind=="gear_grid":preload("res://scripts/arena_art261.gd").clock_grid(self,w);continue
  var p=point(w.pos)-camera
  if w.kind=="stripe":
   var r=Rect2(p-Vector2(70,1800),Vector2(140,3600)) if bool(w.vertical) else Rect2(p-Vector2(2400,70),Vector2(4800,140));preload("res://scripts/combat_cues.gd").rectangle(game,r,float(w.time),float(w.total))
  else:preload("res://scripts/combat_cues.gd").danger(game,p,float(w.radius),float(w.time),float(w.total))
 for bolt in bolts:game.draw_circle(point(bolt.pos)-camera,9,Color("#ff9650"))
 if game.spectating():return

