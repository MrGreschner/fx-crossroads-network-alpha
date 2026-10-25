extends RefCounted
## Cohesive river masonry and willow architecture. Static terrain is retained once.
var world:Node
var art:Dictionary={}
var stamps:Dictionary={}
var terrain_manifest:Dictionary={}
var terrain_keys:Dictionary={}
var terrain_cache:Dictionary={}
var terrain_order:Array=[]
var ground_validated:=false
var ground_matches:=true
var ground_draws:=0
var drawn_props:=0
var drawn_water:=0
func reset()->void:stamps.clear();terrain_cache.clear();terrain_order.clear();ground_validated=false
func texture(name:String)->Texture2D:
 if not art.has(name):art[name]=preload("res://scripts/source_art.gd").texture("res://assets/"+name+".svg")
 return art[name]
func near(bounds:Rect2)->bool:return bounds.intersects(Rect2(world.adventure.game.camera,world.adventure.game.get_viewport_rect().size).grow(300))
func shape(f:Dictionary)->PackedVector2Array:return world.polygon(f.poly) if f.has("poly") else PackedVector2Array([world.r(f.rect).position,Vector2(world.r(f.rect).end.x,world.r(f.rect).position.y),world.r(f.rect).end,Vector2(world.r(f.rect).position.x,world.r(f.rect).end.y)])
func close(points:PackedVector2Array)->PackedVector2Array:
 var line=points.duplicate();line.append(points[0]);return line
func shifted(points:PackedVector2Array,offset:Vector2)->PackedVector2Array:
 var result=points.duplicate()
 for n in result.size():result[n]+=offset
 return result
func ground(c:Node2D,f:Dictionary)->void:
 var kind=str(f.kind);var bounds=world.floor_bounds(f);var points=shape(f)
 if kind=="silver_room":room(c,f,bounds);return
 if f.has("route"):bridge(c,f,points);return
 var center_shore=bounds.get_center();var shallow=points.duplicate()
 for n in shallow.size():shallow[n]=center_shore+(shallow[n]-center_shore)*1.065
 c.draw_colored_polygon(shallow,Color("#2f6872"))
 c.draw_colored_polygon(shifted(points,Vector2(8,36)),Color("#11394a"))
 c.draw_colored_polygon(shifted(points,Vector2(0,20)),Color("#497783"));c.draw_polyline(close(shifted(points,Vector2(0,17))),Color("#90afa5"),9,true)
 var colors=PackedColorArray();var seed=int(f.get("seed",1))
 for n in points.size():colors.append(Color(["#719d83","#679782","#7da48a","#8aae90"][(n/5+seed)%4]))
 c.draw_polygon(points,colors);c.draw_polyline(close(points),Color("#aac6ad"),8,true)
 # Irregular shaded shore margin gives depth without a non-walkable graphic over the route.
 var center=bounds.get_center();var inner=points.duplicate()
 for n in inner.size():inner[n]=center+(inner[n]-center)*.964
 c.draw_polyline(close(inner),Color(.29,.47,.39,.3),13,true)
 var key=str(f.name)
 if not stamps.has(key):
  var rng=RandomNumberGenerator.new();rng.seed=seed*7919;var positions=[]
  for n in int(bounds.get_area()/10000):
   var p=bounds.position+Vector2(rng.randf()*bounds.size.x,rng.randf()*bounds.size.y)
   if Geometry2D.is_point_in_polygon(p,inner):positions.append(p)
  var batch=MultiMesh.new();batch.transform_format=MultiMesh.TRANSFORM_2D;batch.use_colors=true;var mesh=QuadMesh.new();mesh.size=Vector2(32,36);batch.mesh=mesh;batch.instance_count=positions.size()
  for n in positions.size():
   batch.set_instance_transform_2d(n,Transform2D(rng.randf_range(-.7,.7),Vector2.ONE*rng.randf_range(.6,1.5),0,positions[n]));batch.set_instance_color(n,Color(1,1,1,rng.randf_range(.2,.4)))
  stamps[key]=batch
 c.draw_multimesh(stamps[key],texture("sf_flora"))
 for n in range(2,points.size(),7):
  var p=points[n].lerp(bounds.get_center(),.19);c.draw_texture_rect(texture("sf_flowerbed"),Rect2(p-Vector2(90,50),Vector2(180,110)),false,Color(1,1,1,.8))
 # Hand-set river-stone inlays, kept near the island edges, not a busy arena carpet.
 for n in range(1,points.size(),4):
  var a=points[n].lerp(center,.12);var b=points[(n+1)%points.size()].lerp(center,.13)
  c.draw_line(a,b,Color(.83,.85,.66,.22),7,true)
func route_point(points:Array,distance:float)->Dictionary:
 for n in range(1,points.size()):
  var a=world.v(points[n-1]);var b=world.v(points[n]);var length=a.distance_to(b)
  if distance<=length:return {"pos":a.lerp(b,distance/maxf(1,length)),"dir":(b-a).normalized()}
  distance-=length
 return {"pos":world.v(points[-1]),"dir":(world.v(points[-1])-world.v(points[-2])).normalized()}
func bridge(c:Node2D,f:Dictionary,points:PackedVector2Array)->void:
 var kind=str(f.kind);var width=float(f.width);var route:Array=f.route
 c.draw_colored_polygon(shifted(points,Vector2(6,27)),Color("#113947"))
 c.draw_colored_polygon(shifted(points,Vector2(0,14)),Color("#406978"));c.draw_polyline(close(shifted(points,Vector2(0,12))),Color("#476c74"),10,true)
 c.draw_colored_polygon(points,Color("#839d8d") if kind!="silver_root" else Color("#a3aa82"));c.draw_polyline(close(points),Color("#b8c5a2"),5,true)
 var length=0.0
 for n in range(1,route.size()):length+=world.v(route[n-1]).distance_to(world.v(route[n]))
 for d in range(22,int(length),48):
  var part=route_point(route,d);var p:Vector2=part.pos;var heading:Vector2=part.dir;var side=heading.orthogonal()
  c.draw_line(p-side*(width*.43),p+side*(width*.43),Color("#5e827c"),2,true)
  if kind=="silver_root":
   c.draw_line(p-side*(width*.38)-heading*8,p+side*(width*.38)+heading*5,Color("#c0bc90"),3,true)
  if d%240<48 and kind!="silver_trail":
   for sign_value in [-1,1]:
    var post=p+side*(width*.44)*sign_value;c.draw_line(post,post-Vector2(0,23),Color("#53787a"),7,true);c.draw_circle(post-Vector2(0,24),5,Color("#d5ce9e"))
 for sign_value in [-1,1]:
  var edge=PackedVector2Array()
  for n in route.size():
   var part=route_point(route,0) if n==0 else {"dir":(world.v(route[n])-world.v(route[n-1])).normalized()}
   edge.append(world.v(route[n])+part.dir.orthogonal()*width*.45*sign_value-Vector2(0,12))
  c.draw_polyline(edge,Color("#c8c69b") if kind!="silver_root" else Color("#738c6b"),3,true)
func room(c:Node2D,f:Dictionary,b:Rect2)->void:
 var p=b.position;var seed=int(f.seed)
 c.draw_rect(b,Color("#203e48"));c.draw_rect(b.grow(-18),Color("#7e9580"));c.draw_rect(b.grow(-50),Color("#b5b48d"))
 for y in range(int(p.y+52),int(b.end.y-45),52):c.draw_line(Vector2(p.x+50,y),Vector2(b.end.x-50,y),Color("#929c7e"),2)
 c.draw_rect(Rect2(p+Vector2(40,35),Vector2(b.size.x-80,80)),Color("#527978"));c.draw_rect(Rect2(p+Vector2(90,50),Vector2(210,48)),Color("#c2ded0"));c.draw_rect(Rect2(p+Vector2(b.size.x-300,50),Vector2(210,48)),Color("#c2ded0"))
 c.draw_rect(Rect2(p+Vector2(180,220),b.size-Vector2(360,380)),Color("#6d9991"));c.draw_rect(Rect2(p+Vector2(180,220),b.size-Vector2(360,380)),Color("#d0c59a"),false,7)
 c.draw_string(ThemeDB.fallback_font,p+Vector2(75,165),str(f.name),HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("#eae3ba"))
 if seed==10:
  c.draw_rect(Rect2(p+Vector2(70,210),Vector2(95,165)),Color("#547a7d"));c.draw_circle(p+Vector2(118,285),35,Color("#d9bb77"));c.draw_circle(p+Vector2(118,285),22,Color("#efdda6"))
 elif seed==11:
  for n in 4:c.draw_rect(Rect2(p+Vector2(65+n*70,180),Vector2(45,30)),Color("#c0cb99"))
 else:
  var center=p+Vector2(b.size.x*.5,340);c.draw_arc(center,110,0,TAU,48,Color("#cedbb7"),4);c.draw_line(center-Vector2(130,0),center+Vector2(130,0),Color("#d7c894"),3);c.draw_line(center-Vector2(0,130),center+Vector2(0,130),Color("#d7c894"),3)
func water(c:Node2D,camera:Vector2)->void:
 c.draw_texture_rect(texture("sf_water"),Rect2(-camera,world.v(world.data.size)),true)
 var view=Rect2(world.adventure.game.camera,world.adventure.game.get_viewport_rect().size).grow(100);drawn_water=0
 # Only visible currents are animated. Land and bridge layers naturally cover them.
 for x in range(floori(view.position.x/160)*160,ceili(view.end.x/160)*160,160):
  for y in range(floori(view.position.y/130)*130,ceili(view.end.y/130)*130,130):
   var p=Vector2(x+sin(y*.03)*35,y+fmod(world.clock*12+x*.07,60))-camera
   c.draw_line(p,p+Vector2(22+sin(x*.03)*8,-3),Color(.45,.74,.76,.13),1.5);drawn_water+=1
 for fall in world.data.silverfalls:
  var b=world.r(fall)
  if not view.intersects(b.grow(180)):continue
  # Faceted cliff sides frame an actual cascade, instead of a rectangle of stripes.
  for sign_value in [-1,1]:
   var x=b.position.x if sign_value<0 else b.end.x
   for n in 7:
    var y=b.position.y+n*b.size.y/7;var height=b.size.y/7+15
    var pts=PackedVector2Array([Vector2(x+sign_value*48,y),Vector2(x,y+15),Vector2(x,y+height),Vector2(x+sign_value*70,y+height-20)])
    c.draw_colored_polygon(shifted(pts,-camera),Color("#486e7c") if n%2 else Color("#62868a"))
  c.draw_texture_rect(texture("sf_cascade"),Rect2(b.position-camera,b.size),false)
  for n in 9:
   var x=b.position.x+b.size.x*(.15+n*.085);var y=b.position.y+fmod(world.clock*210+n*139,b.size.y)
   c.draw_line(Vector2(x,y)-camera,Vector2(x+sin(n+world.clock)*5,minf(y+110,b.end.y))-camera,Color(.78,.96,.9,.22),3,true)
  var foot=Vector2(b.get_center().x,b.end.y)
  for n in 4:c.draw_arc(foot-camera+Vector2(sin(n*3.1)*b.size.x*.35,n*9),30+n*19+sin(world.clock*2+n)*8,0,PI,20,Color(.72,.9,.83,.3),4,true)
func body_size(kind:String)->Vector2:
 return {"sf_willow":Vector2(240,320),"sf_birch":Vector2(210,280),"sf_rock":Vector2(140,98),"sf_fern":Vector2(80,80),"sf_hearth":Vector2(280,350),"sf_tearoom":Vector2(280,350),"sf_observatory":Vector2(310,388)}.get(kind,Vector2(150,150))
func prop_bounds(p:Dictionary)->Rect2:
 var size=body_size(str(p.kind))*float(p.scale)
 return Rect2(world.v(p.pos)-Vector2(size.x*.5,size.y*.94),size)
func draw_world(c:Node2D,camera:Vector2)->void:
 drawn_props=0
 var view=Rect2(camera,c.get_viewport_rect().size).grow(180)
 for p in world.data.props:
  var b=prop_bounds(p)
  if not b.intersects(view):continue
  var kind=str(p.kind);var tree=kind in ["sf_willow","sf_birch"]
  if tree:
   var split=400.0/640;c.draw_texture_rect_region(texture(kind),Rect2(b.position-camera+Vector2(0,b.size.y*split),Vector2(b.size.x,b.size.y*(1-split))),Rect2(0,400,480,240))
  else:c.draw_texture_rect(texture(kind),Rect2(b.position-camera,b.size),false)
  drawn_props+=1
 for point in world.data.lamps:
  var p=world.v(point)
  if not view.has_point(p):continue
  c.draw_texture_rect(texture("sf_lantern"),Rect2(p-camera-Vector2(35,110),Vector2(90,90)),false)
  c.draw_texture_rect(texture("sf_mist"),Rect2(p-camera-Vector2(85,125),Vector2(170,90)),false,Color(1,.88,.6,.8))
 for point in world.data.ruins:
  var p=world.v(point)
  if view.has_point(p):c.draw_texture_rect(texture("sf_ruin"),Rect2(p-camera-Vector2(110,145),Vector2(220,183)),false)
 for monument in world.data.get("hero_monuments",[]):
  var p=Vector2(monument[0],monument[1])
  if not view.has_point(p):continue
  var point=p-camera
  c.draw_texture_rect(texture("sf_ruin"),Rect2(point-Vector2(73,125),Vector2(146,150)),false)
  var hero=world.adventure.game.art.get(str(monument[2])+"_idle")
  if hero!=null:c.draw_texture_rect(hero,Rect2(point-Vector2(28,91),Vector2(56,64)),false,Color(.63,.82,.74,.9))
 for house in world.data.houses:
  for side in ["outside","inside"]:
   var p=world.v(house[side])
   if not view.has_point(p):continue
   c.draw_arc(p-camera,22,PI*.08,PI*.92,18,Color("#ded2a1"),2,true);c.draw_string(ThemeDB.fallback_font,p-camera+Vector2(-51,42),"E • enter / leave",HORIZONTAL_ALIGNMENT_LEFT,180,13,Color("#e3e5c7"))
 for secret in world.data.secrets:
  var p=world.v(secret.pos)
  if not view.has_point(p):continue
  c.draw_texture_rect(texture("sf_keepsake"),Rect2(p-camera-Vector2(20,30),Vector2(40,40)),false);c.draw_string(ThemeDB.fallback_font,p-camera+Vector2(-60,36),"E • discovery",HORIZONTAL_ALIGNMENT_LEFT,160,13,Color("#dce2bf"))
 for dock in world.data.raft.docks:
  var p=world.v(dock)
  if view.has_point(p):c.draw_string(ThemeDB.fallback_font,p-camera+Vector2(-85,92),"E • board / call ferry",HORIZONTAL_ALIGNMENT_LEFT,220,14,Color("#e5d9ab"))
 if not world.boat.is_empty():
  var p=world.v(world.boat.pos)
  if view.has_point(p):c.draw_texture_rect(texture("sf_raft"),Rect2(p-camera-Vector2(90,95),Vector2(180,127)),false)
func draw_on(c:Node2D,camera:Vector2)->void:
 var view=Rect2(camera,c.get_viewport_rect().size).grow(250)
 for p in world.data.props:
  if str(p.kind) not in ["sf_willow","sf_birch"]:continue
  var b=prop_bounds(p)
  if not b.intersects(view):continue
  var alpha=1.0
  for player in world.adventure.points().values():
   if b.grow(15).has_point(player):alpha=.27;break
  var sway=sin(world.clock*.65+float(p.pos[0])*.002)*1.8
  c.draw_texture_rect_region(texture(str(p.kind)),Rect2(b.position-camera+Vector2(sway,0),Vector2(b.size.x,b.size.y*400/640)),Rect2(0,0,480,400),Color(1,1,1,alpha))
 for fall in world.data.silverfalls:
  var b=world.r(fall);var p=Vector2(b.get_center().x,b.end.y)
  if not view.has_point(p):continue
  for n in 2:
   var drift=Vector2(sin(world.clock*.3+n)*45,cos(world.clock*.2+n)*10)
   c.draw_texture_rect(texture("sf_mist"),Rect2(p-camera-Vector2(280,65)+drift+Vector2(n*45,-n*40),Vector2(560,180)),false,Color(1,1,1,.55))
static func draw_bolt(c:Node2D,shot:Dictionary,p:Vector2,time:float)->bool:
 var kind=str(shot.get("stats",{}).get("silver_visual",""))
 if kind.is_empty():return false
 var aim=Vector2(shot.aim[0],shot.aim[1]);var side=aim.orthogonal()
 if kind=="slate":
  var turn=Vector2.from_angle(time*9);c.draw_colored_polygon(PackedVector2Array([p+turn*13,p+turn.orthogonal()*10,p-turn*13,p-turn.orthogonal()*10]),Color("#9ec6bf"));c.draw_line(p-turn*8,p+turn*8,Color("#dcdfb7"),2,true)
 else:
  c.draw_arc(p,12,0,TAU,18,Color("#bde7d7"),4,true);c.draw_arc(p,7,time*8,time*8+PI,12,Color("#71bec4"),3,true)
 c.draw_line(p-aim*28+side*3,p-aim*10,Color(.67,.91,.87,.4),3,true)
 return true

func draw_baked(canvas:Node2D,camera:Vector2)->void:
 if terrain_manifest.is_empty():
  var text=FileAccess.get_file_as_string("res://assets/silverfall_ground/manifest.json");var parsed=JSON.parse_string(text)
  if not parsed is Dictionary:return
  terrain_manifest=parsed
  for point in terrain_manifest.tiles:terrain_keys[str(int(point[0]))+"_"+str(int(point[1]))]=point
 if not ground_validated:
  ground_matches=str(terrain_manifest.get("source_signature",""))==JSON.stringify(world.data).sha256_text();ground_validated=true
 if not ground_matches:
  for f in world.data.floors:
   if world.floor_bounds(f).grow(45).intersects(Rect2(camera,canvas.get_viewport_rect().size)):ground(canvas,f)
  return
 ground_draws=0
 var view=Rect2(camera,canvas.get_viewport_rect().size).grow(512)
 for y in range(floori(view.position.y/512),ceili(view.end.y/512)):
  for x in range(floori(view.position.x/512),ceili(view.end.x/512)):
   var key=str(x)+"_"+str(y)
   if not terrain_keys.has(key):continue
   if not terrain_cache.has(key):
    var path="res://assets/silverfall_ground/"+key+".png"
    if FileAccess.file_exists(path):
     var image=Image.new();var bytes=FileAccess.get_file_as_bytes(path)
     if image.load_png_from_buffer(bytes)!=OK:continue
     terrain_cache[key]=ImageTexture.create_from_image(image)
    elif ResourceLoader.exists(path):terrain_cache[key]=ResourceLoader.load(path,"Texture2D",ResourceLoader.CACHE_MODE_IGNORE)
    else:continue
   terrain_order.erase(key);terrain_order.append(key)
   var entry:Array=terrain_keys[key];var offset=Vector2(entry[2],entry[3]) if entry.size()>2 else Vector2.ZERO
   canvas.draw_texture_rect(terrain_cache[key],Rect2(Vector2(x*512,y*512)+offset,terrain_cache[key].get_size()),false);ground_draws+=1
 while terrain_order.size()>40:
  var key=terrain_order.pop_front();terrain_cache.erase(key)
