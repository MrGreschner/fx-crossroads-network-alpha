extends RefCounted
## Deterministic terrain, authority-owned doors/pickups, local fog presentation.
const MAZE_SIZE=Vector2(2880,2160)
const FOG_SIZE=Vector2(3000,2400)
var world_ref:WeakRef
var world:RefCounted:
 get:return world_ref.get_ref() if world_ref!=null else null
 set(value):world_ref=weakref(value) if value!=null else null
var walls:Array=[]
var cliffs:Array=[]
var doors:Array=[]
var torches:Array=[]
var light:Dictionary={}
var chambers:Dictionary={}
var nav=AStarGrid2D.new()
var routes:Dictionary={}
var revision=0
var nav_revision=-1
var last_seed=-1
var pulse_timer=0.0
var audio:AudioStreamPlayer
var sound_enabled=true
var sound_button:Button
var fog_radius=360.0
var fog_mesh:ArrayMesh
var stone_mesh:ArrayMesh
var last_pickup:Dictionary={}
var known_torches:Dictionary={}
var alive_before:Dictionary={}
func active()->bool:return world!=null and world.game.mode=="arena" and world.map_id in ["maze","lanternfall"]
func setup(w:RefCounted)->void:
 world=w;stone_mesh=null;walls.clear();cliffs.clear();doors.clear();torches.clear();light.clear();chambers.clear();routes.clear();revision=0;nav_revision=-1;last_seed=world.game.floor_seed;fog_radius=360;last_pickup.clear();known_torches.clear();alive_before.clear();pulse_timer=0
 if not active():return
 var g=world.game;g.FIELD=Rect2(Vector2.ZERO,MAZE_SIZE if world.map_id=="maze" else FOG_SIZE);g.field_obstacles.clear();g.world_buildings.clear();g.world_patches.clear();g.world_decorations.clear();g.world_fountains.clear();g.world_spawns.clear()
 g.world_terrain="clock_floor" if world.map_id=="maze" else "forest";g.art[g.world_terrain]=load("res://assets/"+g.world_terrain+".png")
 if world.map_id=="maze":build_maze()
 else:build_fog()
 if DisplayServer.get_name()!="headless" and world.map_id=="lanternfall" and not is_instance_valid(audio):
  audio=AudioStreamPlayer.new();g.add_child(audio);audio.volume_db=-20
  var stream=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=22050;var data=PackedByteArray();data.resize(2646)
  for n in 1323:data.encode_s16(n*2,int(sin(TAU*740*n/22050.0)*8000*pow(1-float(n)/1323,2)))
  stream.data=data;audio.stream=stream
  var layer=CanvasLayer.new();layer.layer=32;g.add_child(layer);sound_button=preload("res://scripts/arena_beacon_button.gd").new();sound_button.game=g;layer.add_child(sound_button);sound_button.text="Beacon sound: ON";sound_button.add_theme_font_size_override("font_size",13);sound_button.pressed.connect(func():sound_enabled=not sound_enabled;sound_button.text="Beacon sound: "+("ON" if sound_enabled else "OFF"))
func add_wall(r:Rect2)->void:walls.append(r)
func add_door(r:Rect2,a:int,b:int)->void:doors.append({"rect":r,"a":a,"b":b,"closed":false,"warning":false,"phase":doors.size()*2.3,"kind":"stone" if doors.size()%3==0 else "gate"})
func build_maze()->void:
 for x in range(1,4):
  for y in 3:
   var top=y*720.0;add_wall(Rect2(x*720-20,top,40,282));add_wall(Rect2(x*720-20,top+438,40,282));add_door(Rect2(x*720-20,top+282,40,156),y*4+x-1,y*4+x)
 for y in range(1,3):
  for x in 4:
   var left=x*720.0;add_wall(Rect2(left,y*720-20,282,40));add_wall(Rect2(left+438,y*720-20,282,40));add_door(Rect2(left+282,y*720-20,156,40),(y-1)*4+x,y*4+x)
 # Two stone elbows in every chamber create narrow bends and close-range cover.
 for room in 12:
  var origin=Vector2(room%4*720,room/4*720)
  for r in [Rect2(110,160,350,32),Rect2(428,160,32,140),Rect2(260,528,350,32),Rect2(260,420,32,140)]:add_wall(Rect2(origin+r.position,r.size))
 for room in [5,6]:chambers[str(room)]={"active":false,"until":0.0,"ready":12.0,"born":0.0,"spawned":false}
func spawn_point(slot:int)->Vector2:
 var rooms=[0,11,3,8,1,10,2,9];var room=int(rooms[posmod(slot,rooms.size())]);return Vector2(room%4*720+360,room/4*720+360)
func build_fog()->void:
 var rng=RandomNumberGenerator.new();rng.seed=last_seed
 # Islands leave a guaranteed connected 160-pixel corridor between every grid cell.
 var slots=[]
 for n in 20:slots.append(n)
 for n in 20:
  var j=rng.randi_range(n,19);var swap=slots[n];slots[n]=slots[j];slots[j]=swap
 for n in 14:
  var slot=int(slots[n]);var center=Vector2(300+slot%5*600,300+slot/5*600)+Vector2(rng.randf_range(-50,50),rng.randf_range(-40,40));var size=Vector2(rng.randf_range(140,270),rng.randf_range(110,210));cliffs.append(Rect2(center-size*.5,size))
 # Shared contested pickups; anyone can collect by walking through them.
 for n in 14:
  var p=Vector2(150+rng.randf()*2700,150+rng.randf()*2100)
  for tries in 40:
   if movement_clear(p,p):break
   p=Vector2(150+rng.randf()*2700,150+rng.randf()*2100)
  torches.append({"pos":[p.x,p.y],"ready":0.0})
func rects(include_cliffs:bool=true)->Array:
 var result=walls.duplicate()
 if include_cliffs:result.append_array(cliffs)
 for door in doors:
  if door.closed:result.append(door.rect)
 return result
static func segment_rect(a:Vector2,b:Vector2,r:Rect2)->bool:
 if r.has_point(a) or r.has_point(b):return true
 var corners=[r.position,r.position+Vector2(r.size.x,0),r.end,r.position+Vector2(0,r.size.y)]
 for n in 4:
  if Geometry2D.segment_intersects_segment(a,b,corners[n],corners[(n+1)%4])!=null:return true
 return false
func movement_clear(a:Vector2,b:Vector2)->bool:
 if not active():return true
 for r in rects():
  if segment_rect(a,b,r.grow(18)):return false
 return true
func shot_clear(a:Vector2,b:Vector2)->bool:
 if not active() or world.map_id=="lanternfall":return true
 for r in rects(false):
  if segment_rect(a,b,r.grow(3)):return false
 return true
func occupied(r:Rect2)->bool:
 for id in world.game.positions:
  if int(world.game.health.get(id,0))>0 and r.grow(40).has_point(world.game.positions[id]):return true
 for foe in world.game.opponents:
  if float(foe.hp)>0 and r.grow(30).has_point(foe.pos):return true
 return false
func step(dt:float)->void:
 if not active() or world.game.start_countdown>0:return
 var g=world.game
 if world.map_id=="maze":
  for key in chambers:
   var event:Dictionary=chambers[key];var room=int(key);var area=Rect2(Vector2(room%4*720,room/4*720),Vector2(720,720)).grow(-90)
   if not event.active and world.clock>=float(event.ready):
    for id in g.positions:
     if int(g.health.get(id,0))>0 and area.has_point(g.positions[id]):event.active=true;event.born=world.clock;event.until=world.clock+14;event.spawned=false;break
   if event.active:
    if not event.spawned and world.clock>=float(event.born)+2:
     event.spawned=true
     for n in 3:
      if g.opponents.size()>=12:break
      var p=area.get_center()+[Vector2(160,0),Vector2(-180,0),Vector2(0,250)][n];g.adventure.spawn("archer" if n==2 else "bramble",p,70+g.positions.size()*5,false);g.opponents[-1].arena_chamber=room
    var living=g.opponents.any(func(e):return int(e.get("arena_chamber",-1))==room and float(e.hp)>0)
    if world.clock>=float(event.until) or event.spawned and not living:event.active=false;event.ready=world.clock+30
  var changed=false
  for door in doors:
   var phase=fposmod(world.clock+float(door.phase),14.0);var wanted=phase>=9;var warning=phase>=7.5 and phase<9
   for key in chambers:
    var e:Dictionary=chambers[key]
    if e.active and int(key) in [int(door.a),int(door.b)]:wanted=world.clock>=float(e.born)+2;warning=not wanted
   # Never materialize a gate inside a hero or creature. It waits until clear.
   var closed=wanted and not occupied(door.rect)
   if closed!=door.closed:changed=true
   door.closed=closed;door.warning=warning or wanted and not closed
  if changed:revision+=1;routes.clear()
 else:
  for id in g.positions:
   if int(g.health.get(id,0))<=0:alive_before[id]=false;continue
   if alive_before.has(id) and not bool(alive_before[id]):light[id]=360
   alive_before[id]=true
   light[id]=maxf(170,float(light.get(id,360))-dt*3.2)
   for torch in torches:
    if world.clock>=float(torch.ready) and (g.positions[id] as Vector2).distance_to(world.point(torch.pos))<52:
     torch.ready=world.clock+24;light[id]=minf(520,float(light[id])+145);last_pickup[id]=world.clock
func receive(data:Dictionary)->void:
 for n in mini(doors.size(),data.get("doors",[]).size()):doors[n].closed=bool(data.doors[n][0]);doors[n].warning=bool(data.doors[n][1])
 if revision!=int(data.get("revision",revision)):routes.clear()
 revision=int(data.get("revision",revision));light=data.get("light",{});last_pickup=data.get("pickup",{});chambers=data.get("chambers",chambers)
 for n in mini(torches.size(),data.get("torches",[]).size()):torches[n].ready=float(data.torches[n])
func snapshot()->Dictionary:
 return {"seed":last_seed,"revision":revision,"doors":doors.map(func(d):return [d.closed,d.warning]),"light":light,"pickup":last_pickup,"torches":torches.map(func(t):return t.ready),"chambers":chambers}
func radius(id:String)->float:return float(light.get(id,360))
func can_see(id:String,p:Vector2)->bool:return not active() or world.map_id!="lanternfall" or (world.game.positions.get(id,Vector2.ZERO) as Vector2).distance_to(p)<=radius(id)
func nearest_enemy(id:String,p:Vector2)->Vector2:
 var best=Vector2.INF;var distance=INF
 for other in world.game.positions:
  if not world.game._rival(id,str(other)) or Time.get_ticks_msec()<int(world.game.stealth_until.get(other,0)):continue
  var q:Vector2=world.game.positions[other];var d=p.distance_squared_to(q)
  if d<distance:distance=d;best=q
 for foe in world.game.opponents:
  var d=p.distance_squared_to(foe.pos)
  if float(foe.hp)>0 and d<distance:distance=d;best=foe.pos
 return best
func navigate(id:String,p:Vector2,destination:Vector2)->Vector2:
 if movement_clear(p,p+(destination-p).limit_length(120)):return (destination-p).normalized()
 if nav_revision!=revision:
  nav.region=Rect2i(0,0,ceili(world.game.FIELD.size.x/60),ceili(world.game.FIELD.size.y/60));nav.cell_size=Vector2(60,60);nav.offset=Vector2(30,30);nav.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES;nav.update()
  for shape in rects():
   var expanded:Rect2=shape.grow(22)
   for x in range(maxi(0,floori(expanded.position.x/60)),mini(nav.region.size.x,ceili(expanded.end.x/60))):
    for y in range(maxi(0,floori(expanded.position.y/60)),mini(nav.region.size.y,ceili(expanded.end.y/60))):
     if expanded.has_point(Vector2(x*60+30,y*60+30)):nav.set_point_solid(Vector2i(x,y))
  nav_revision=revision;routes.clear()
 var from=nav_cell(p,true);var to=nav_cell(destination,false)
 if nav.is_point_solid(from) or nav.is_point_solid(to):return Vector2.ZERO
 var route:Dictionary=routes.get(id,{})
 if route.is_empty() or route.goal!=to or world.clock>float(route.until):route={"goal":to,"until":world.clock+1.5,"points":nav.get_point_path(from,to,true),"index":0};routes[id]=route
 while int(route.index)<route.points.size() and p.distance_to(route.points[int(route.index)])<45:route.index+=1
 return (route.points[int(route.index)]-p).normalized() if int(route.index)<route.points.size() else Vector2.ZERO
func nav_cell(p:Vector2,connected:bool)->Vector2i:
 var origin=Vector2i(p/60).clamp(Vector2i.ZERO,nav.region.end-Vector2i.ONE)
 for ring in range(0,5):
  for x in range(maxi(0,origin.x-ring),mini(nav.region.end.x-1,origin.x+ring)+1):
   for y in range(maxi(0,origin.y-ring),mini(nav.region.end.y-1,origin.y+ring)+1):
    var cell=Vector2i(x,y)
    if not nav.is_point_solid(cell) and (not connected or movement_clear(p,Vector2(cell)*60+Vector2(30,30))):return cell
 return origin
func bot_wish(id:String,p:Vector2,wish:Vector2,target:Vector2)->Vector2:
 if not active():return wish
 var goal=target;var searching=p.distance_to(target)<1
 if world.map_id=="lanternfall":
  var best=INF
  if not known_torches.has(id):known_torches[id]={}
  for index in torches.size():
   if p.distance_to(world.point(torches[index].pos))<=radius(id):known_torches[id][index]=true
  if radius(id)<310:
   for index in known_torches[id]:
    var torch:Dictionary=torches[int(index)]
    var q=world.point(torch.pos);var distance=p.distance_squared_to(q)
    if world.clock>=float(torch.ready) and distance<best:best=distance;goal=q
  if best==INF and (not can_see(id,target) or searching):
   var enemy=nearest_enemy(id,p)
   goal=p+Vector2.from_angle(snappedf((enemy-p).angle(),PI/4))*250 if enemy.is_finite() else p+Vector2.from_angle(world.clock*.2)*200
 if not movement_clear(p,p+wish*100) or not shot_clear(p,target) or world.map_id=="lanternfall" and (not can_see(id,target) or searching):return navigate(id,p,goal)
 if world.map_id=="lanternfall" and radius(id)<310:return navigate(id,p,goal)
 return wish
func build_stone_mesh()->ArrayMesh:
 var vertices=PackedVector3Array();var colors=PackedColorArray();var indices=PackedInt32Array()
 var add=func(r:Rect2,color:Color):
  var n=vertices.size();vertices.append_array(PackedVector3Array([Vector3(r.position.x,r.position.y,0),Vector3(r.end.x,r.position.y,0),Vector3(r.end.x,r.end.y,0),Vector3(r.position.x,r.end.y,0)]));colors.append_array(PackedColorArray([color,color,color,color]));indices.append_array(PackedInt32Array([n,n+1,n+2,n,n+2,n+3]))
 for r in walls:
  add.call(r.grow(4),Color("#17252e"));add.call(r,Color("#64767c"));add.call(Rect2(r.position,Vector2(r.size.x,4)),Color("#a7b3b0"))
  for row in range(0,ceili(r.size.y/24)):
   var y=r.position.y+row*24
   if row>0:add.call(Rect2(r.position.x,y,r.size.x,2),Color("#3e505a"))
   for column in range(0,ceili(r.size.x/48)+1):
    var x=r.position.x+column*48+(24 if row%2 else 0)
    if x<r.end.x:add.call(Rect2(x,y,2,minf(24,r.end.y-y)),Color("#40525b"))
 for r in cliffs:
  add.call(Rect2(r.position+Vector2(3,12),r.size),Color("#10232c"));add.call(r,Color("#263d49"));add.call(r.grow(-6),Color("#617c84"));add.call(Rect2(r.position+Vector2(7,6),Vector2(r.size.x-14,4)),Color("#a3bcbb"));add.call(Rect2(r.position+Vector2(12,r.size.y-15),Vector2(r.size.x-24,5)),Color("#49646e"))
 var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices;var mesh=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);return mesh
func draw_ground()->void:
 if not active():return
 var g=world.game
 if stone_mesh==null:stone_mesh=build_stone_mesh()
 g.draw_mesh(stone_mesh,null,Transform2D(0.0,-g.camera))
 for door in doors:
  var box=Rect2(door.rect.position-g.camera,door.rect.size);var tint=Color("#e8b76a") if door.warning else Color("#b76266") if door.closed else Color("#78cdb6")
  g.draw_rect(box,Color(tint,.85 if door.closed else .15));g.draw_rect(box,tint,false,3)
  if door.closed:
   var vertical=box.size.y>box.size.x
   if str(door.get("kind","gate"))=="stone":
    g.draw_rect(box.grow(-3),Color("#73838b"));g.draw_line(box.position,box.end,Color("#b2b9ae"),3)
   for n in (0 if str(door.get("kind","gate"))=="stone" else 5):
    var a=box.position+Vector2(0,n*box.size.y/5) if vertical else box.position+Vector2(n*box.size.x/5,0);g.draw_line(a,a+Vector2(box.size.x,0) if vertical else a+Vector2(0,box.size.y),Color("#e5c092"),3)
  if door.warning:g.draw_circle(box.get_center(),10+sin(world.clock*10)*3,tint)
 for torch in torches:
  if world.clock<float(torch.ready):continue
  var p=world.point(torch.pos)-g.camera;var pulse=sin(world.clock*6+p.x)*2
  g.draw_circle(p,36,Color(1,.65,.2,.12));g.draw_line(p+Vector2(0,15),p-Vector2(0,7),Color("#9a6243"),6);g.draw_colored_polygon(PackedVector2Array([p+Vector2(-8,0),p+Vector2(0,-24-pulse),p+Vector2(9,-4),p+Vector2(3,7)]),Color("#ffbd5b"));g.draw_circle(p,4,Color("#fff1b0"))
func draw_fog()->void:
 if not active() or world.map_id!="lanternfall" or world.game.spectating():return
 var g=world.game;var center=g._player_draw_position(g.my_id,g.local_pos)-g.camera
 fog_radius=lerpf(fog_radius,radius(g.my_id),.12)
 g.draw_rect(Rect2(Vector2.ZERO,g.VIEW),Color(.015,.06,.1,.16))
 if fog_mesh==null:
  fog_mesh=ArrayMesh.new();var vertices=PackedVector3Array();var colors=PackedColorArray();var indices=PackedInt32Array();var rings=[.65,.78,.9,1.0,1.07,30.0];var opacity=[0.0,.08,.3,.75,1.0,1.0]
  for ring in 6:
   for n in 64:
    var p=Vector2.from_angle(TAU*n/64)*float(rings[ring]);vertices.append(Vector3(p.x,p.y,0));colors.append(Color(.015,.025,.045,float(opacity[ring])))
  for band in 5:
   for n in 64:
    var a=band*64+n;var b=band*64+(n+1)%64;var c=(band+1)*64+n;var d=(band+1)*64+(n+1)%64;indices.append_array(PackedInt32Array([a,c,b,b,c,d]))
  var arrays=[];arrays.resize(Mesh.ARRAY_MAX);arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_COLOR]=colors;arrays[Mesh.ARRAY_INDEX]=indices;fog_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 g.draw_mesh(fog_mesh,null,Transform2D(0.0,Vector2.ONE*fog_radius,0.0,center))
func draw_hud()->void:
 if is_instance_valid(sound_button):sound_button.visible=active() and world.map_id=="lanternfall" and world.game.started and world.game.presentation.page.is_empty();sound_button.position=Vector2(world.game.VIEW.x-220,252);sound_button.size=Vector2(200,26)
 if not active():return
 var g=world.game;var font=ThemeDB.fallback_font
 if world.map_id=="maze":
  g.draw_style_box(preload("res://scripts/studio_ui.gd").box("#162934","#7f9799",7,8),Rect2(20,165,310,55));g.draw_string(font,Vector2(30,187),"Teal: OPEN • Amber: CLOSING",HORIZONTAL_ALIGNMENT_LEFT,295,15,Color("#bce1d2"));g.draw_string(font,Vector2(30,207),"Red: LOCKED • ambush limit 14s.",HORIZONTAL_ALIGNMENT_LEFT,295,13,Color("#e4c596"));return
 var box=Rect2(g.VIEW.x-220,100,200,145);g.draw_style_box(preload("res://scripts/studio_ui.gd").box("#10232e","#6baab7",8,10),box)
 var p:Vector2=g.local_pos;var enemy=nearest_enemy(g.my_id,p);var center=box.position+Vector2(100,68)
 g.draw_string(font,box.position+Vector2(13,23),"ECHO BEACON",HORIZONTAL_ALIGNMENT_LEFT,180,15,Color("#b4d9df"));g.draw_arc(center,28,0,TAU,32,Color("#6b9caa"),2)
 if enemy.is_finite() and int(g.health.get(g.my_id,0))>0:
  var distance=p.distance_to(enemy);var beat=clampf(distance/800,.28,2.2);var pulse=1-fposmod(world.clock,beat)/beat;var angle=snappedf((enemy-p).angle(),PI/8);var direction=Vector2.from_angle(angle)
  g.draw_arc(center,29+pulse*13,angle-.6,angle+.6,16,Color(.6,.9,1,.3+pulse*.7),4);g.draw_colored_polygon(PackedVector2Array([center+direction*23,center+direction.orthogonal()*6-direction*5,center-direction.orthogonal()*6-direction*5]),Color("#aee6ee"))
  if world.clock>=pulse_timer:
   pulse_timer=world.clock+beat
   if sound_enabled and is_instance_valid(audio) and not g.get_tree().paused and g.presentation.page.is_empty():audio.play()
 else:g.draw_string(font,center+Vector2(-29,5),"QUIET",HORIZONTAL_ALIGNMENT_LEFT,70,13,Color("#a8bcc6"))
 g.draw_string(font,box.position+Vector2(12,113),"Faster pulses = closer",HORIZONTAL_ALIGNMENT_LEFT,176,11,Color("#b7cfd9"))
 g.draw_rect(Rect2(box.position+Vector2(12,122),Vector2(176,5)),Color("#33424b"));g.draw_rect(Rect2(box.position+Vector2(12,122),Vector2(176*clampf((radius(g.my_id)-170)/350,0,1),5)),Color("#efc278"))
 g.draw_string(font,box.position+Vector2(12,140),"TORCHES BRIGHTEN YOUR VIEW",HORIZONTAL_ALIGNMENT_LEFT,176,10,Color("#f4d39a"))
 if world.clock-float(last_pickup.get(g.my_id,-100))<2:g.draw_string(font,Vector2(g.VIEW.x*.5-100,g.VIEW.y-105),"TORCH FOUND • LIGHT +145",HORIZONTAL_ALIGNMENT_LEFT,260,17,Color("#ffdf97"))
