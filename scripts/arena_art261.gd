extends RefCounted
## Arena-only presentation. Never owns collision, hazards, scoring or transport.
const ROOT="res://assets/arena261/"
const MATERIALS=["sand","storm","clock","maze","lanternfall","colour_clash","crown_chase","deck","wall"]
const PROPS=["pit","drone","fireflower","crown","beacon","barricade","pillar","cliff","torch","banner","gear","medallion"]
static var pages:Dictionary={}
static var regions:Dictionary={}
static func png(id:String)->Texture2D:
 if not pages.has(id):
  var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT+id+".png"));pages[id]=ImageTexture.create_from_image(im)
 return pages[id]
static func region(page:String,key:String,r:Rect2)->Texture2D:
 if not regions.has(key):
  var t=AtlasTexture.new();t.atlas=png(page);t.region=r;t.filter_clip=true;regions[key]=t
 return regions[key]
static func prop(id:String)->Texture2D:
 var n=PROPS.find(id)
 return region("props","p:"+id,Rect2(n%4*256,n/4*256,256,256)) if n>=0 else null
static func tile(id:String,x:int,y:int)->Texture2D:
 var n=MATERIALS.find(id);var q=Vector2i(posmod(x,4),posmod(y,4))
 return region("materials","t:"+id+str(q),Rect2(Vector2(n%3*256,n/3*256)+Vector2(q)*64,Vector2(64,64)))
static func layers(x:int,y:int,old:String,g:Node)->Array:
 var result=[]
 var map=str(g.arena_world.map_id);var t:Texture2D
 if map=="crossroads":
  var n=preload("res://scripts/north_art260.gd")
  t=n.material("grass"+str(posmod(y,4)*4+posmod(x,4)))
  if old=="path":
   result.append(t);t=n.material("path"+str(n.mask_at(g,x,y)))
 elif map=="forest":t=tile("lanternfall",x,y)
 elif map=="shatterfloor":t=tile("storm",x,y)
 else:t=tile(map,x,y)
 result.append(t);return result
static func append(chunk:Node,x:int,y:int,at:Vector2,old:String,g:Node)->void:
 chunk.compact=false
 var cell_layers=layers(x,y,old,g)
 for layer in cell_layers.size():chunk.tiles.append([cell_layers[layer],Rect2(at,Vector2(64,64)),layer])
static func draw(g:CanvasItem,id:String,r:Rect2,tint:Color=Color.WHITE)->void:
 g.draw_texture_rect(prop(id),r,false,tint)
static func obstacle(g:Node,b:Dictionary,camera:Vector2)->void:
 var p:Vector2=b.pos-camera;var kind=str(b.get("kind","tree"))
 if kind=="tree":
  var scale_value=float(b.get("grove_scale",1));g.draw_texture_rect(preload("res://scripts/quarry_art254.gd").grove_tree(b.pos),Rect2(p-Vector2(44,65)*scale_value,Vector2(88,112)*scale_value),false)
 elif kind=="barricade":draw(g,"barricade",Rect2(p-Vector2(44,65),Vector2(88,112)))
 else:
  var d=float(b.get("radius",38))*2+8
  g.draw_texture_rect(preload("res://scripts/quarry_art254.gd").texture("rock"),Rect2(p-Vector2.ONE*d*.5,Vector2.ONE*d),false)
static func building(g:Node,b:Dictionary,camera:Vector2)->void:
 # Original supplies artwork envelope and E interaction anchor.
 preload("res://scripts/north_art260.gd").draw(g,"supplies",Rect2(b.pos-Vector2(85,105)-camera,Vector2(170,150)))
static func tiled(g:CanvasItem,r:Rect2,id:String,camera:Vector2)->void:
 # Bounded visible pieces, clipped by destination coordinates. No Image generation.
 for x in range(floori(r.position.x/64),ceili(r.end.x/64)):
  for y in range(floori(r.position.y/64),ceili(r.end.y/64)):
   var a=Rect2(Vector2(x,y)*64,Vector2(64,64)).intersection(r)
   var uv=Rect2(a.position-Vector2(x,y)*64,a.size)
   g.draw_texture_rect_region(tile(id,x,y),Rect2(a.position-camera,a.size),uv)
static func variants(v:RefCounted)->void:
 var g=v.world.game;var camera:Vector2=g.camera;var visible=Rect2(camera,g.VIEW).grow(50)
 for r in v.walls:
  if not visible.intersects(r):continue
  var box=Rect2(r.position-camera,r.size)
  g.draw_rect(box.grow(3),Color("#334247"));tiled(g,r,"wall",camera);g.draw_rect(box,Color("#9ca6a0"),false,2)
 for r in v.cliffs:
  if visible.intersects(r):draw(g,"cliff",Rect2(r.position-camera,r.size))
 for door in v.doors:
  if not visible.intersects(door.rect):continue
  var box=Rect2(door.rect.position-camera,door.rect.size);var tint=Color("#e8b76a") if door.warning else Color("#d37f7b") if door.closed else Color("#78cdb6")
  g.draw_rect(box,Color(tint,.28 if door.closed else .13));g.draw_rect(box,tint,false,3)
  if door.closed:
   if str(door.get("kind","gate"))=="stone":tiled(g,door.rect.grow(-4),"wall",camera)
   else:
    for n in 5:
     var vertical=box.size.y>box.size.x
     var a=box.position+Vector2(0,(n+.5)*box.size.y/5) if vertical else box.position+Vector2((n+.5)*box.size.x/5,0)
     g.draw_line(a,a+Vector2(box.size.x,0) if vertical else a+Vector2(0,box.size.y),Color("#514641"),7)
     g.draw_line(a+Vector2(1,1),a+Vector2(box.size.x,0) if vertical else a+Vector2(0,box.size.y),Color("#c5ae7d"),3)
  if door.warning:g.draw_circle(box.get_center(),10+sin(v.world.clock*10)*3,tint)
  # Twin panels slide inward during the closing warning. Closed state and the
  # solid rectangle always come from the host's timer, never player proximity.
  if door.warning:
   var progress=clampf((fposmod(v.world.clock+float(door.phase),14.0)-7.5)/1.5,0,1)
   if box.size.y>box.size.x:
    g.draw_rect(Rect2(box.position,Vector2(box.size.x,box.size.y*.5*progress)),Color("#b5a582"));g.draw_rect(Rect2(box.position+Vector2(0,box.size.y*(1-progress*.5)),Vector2(box.size.x,box.size.y*.5*progress)),Color("#b5a582"))
   else:
    g.draw_rect(Rect2(box.position,Vector2(box.size.x*.5*progress,box.size.y)),Color("#b5a582"));g.draw_rect(Rect2(box.position+Vector2(box.size.x*(1-progress*.5),0),Vector2(box.size.x*.5*progress,box.size.y)),Color("#b5a582"))
 for torch in v.torches:
  if v.world.clock<float(torch.ready):continue
  var p=v.world.point(torch.pos)-camera
  if not visible.has_point(v.world.point(torch.pos)):continue
  g.draw_circle(p,36,Color(1,.65,.2,.12));draw(g,"torch",Rect2(p-Vector2(22,31),Vector2(44,54)))
static func clock_grid(w:RefCounted,hazard:Dictionary)->void:
 var g=w.game;var camera:Vector2=g.camera;var view=Rect2(camera,g.VIEW);var live=float(hazard.time)<=0;var color=Color("#98e3f1") if live else Color("#e6bb76")
 for r in w.clock_shapes(hazard):
  if not view.intersects(r):continue
  var box=Rect2(r.position-camera,r.size)
  g.draw_rect(box,Color(color,.28 if live else .12));g.draw_rect(box,color,false,4 if live else 2)
  var vertical=r.size.y>r.size.x;var clipped=r.intersection(view.grow(30));var points=PackedVector2Array()
  if vertical:
   for n in 17:points.append(Vector2(r.get_center().x+sin(n*2.7+w.clock*37)*(25 if live else 4),lerpf(clipped.position.y,clipped.end.y,n/16.0))-camera)
  else:
   for n in 17:points.append(Vector2(lerpf(clipped.position.x,clipped.end.x,n/16.0),r.get_center().y+sin(n*2.7+w.clock*37)*(25 if live else 4))-camera)
  g.draw_polyline(points,Color(color,.9),5 if live else 2,true)
  if live:g.draw_polyline(points,Color("#f1fcf4"),2,true)
  for n in 9:
   var t=fposmod(n/9.0+w.clock*(.9 if live else .3),1)
   var at=Vector2(r.get_center().x,lerpf(clipped.position.y,clipped.end.y,t)) if vertical else Vector2(lerpf(clipped.position.x,clipped.end.x,t),r.get_center().y)
   g.draw_rect(Rect2(at-camera-Vector2(7,7),Vector2(14,14)),color)
static func features(w:RefCounted)->void:
 var g=w.game;var camera:Vector2=g.camera
 if w.map_id=="crossroads":
  draw(g,"medallion",Rect2(Vector2(3100,2100)-camera-Vector2.ONE*110,Vector2.ONE*220),Color(1,1,1,.8))
 elif w.map_id=="sand":
  for p in w.pits():
   draw(g,"pit",Rect2(p-camera-Vector2.ONE*150,Vector2.ONE*300))
   g.draw_arc(p-camera,150,0,TAU,48,Color("#d4b178"),2)
   for n in 3:g.draw_arc(p-camera,40+n*32,w.clock*.15+n,w.clock*.15+n+PI*1.4,32,Color(.84,.66,.40,.20),2)
 elif w.map_id=="storm":
  for drone in w.drones:
   var p=w.point(drone.pos)-camera;var orb=fposmod(w.clock+float(drone.phase),44)>=36
   if orb:
    g.draw_circle(p,170,Color(.25,.65,.95,.15));g.draw_arc(p,170,w.clock*2,w.clock*2+TAU*.85,40,Color("#8fd8ff"),3)
   draw(g,"drone",Rect2(p-Vector2(65,60),Vector2(130,92)),Color("#b9e9ef")if orb else Color.WHITE)
   for side in [-1,1]:g.draw_arc(p+Vector2(side*41,-16),18,w.clock*20,w.clock*20+PI*1.5,16,Color(.8,.9,.92,.45),2)
 elif w.map_id=="forest":
  for flower in w.flowers:
   var p=w.point(flower.pos)-camera;var s=minf(1,(9-float(flower.time))*2)
   draw(g,"fireflower",Rect2(p-Vector2(38,42)*s,Vector2(76,74)*s))
 elif w.map_id=="clock":
  # Recessed floor mechanisms: decoration, without extra collision.
  for index in w.GEARS.size():
   var at:Vector2=w.GEARS[index];var active=false;var warning=false
   for hazard in w.warnings:
    if str(hazard.kind)=="gear_grid" and index in hazard.get("gears",[]):active=true;warning=float(hazard.time)>0
   var p=at-camera
   if Rect2(Vector2(-160,-160),g.VIEW+Vector2(320,320)).has_point(p):
    if active:g.draw_circle(p,100,Color("#e6bb76" if warning else "#98e3f1",.23));g.draw_arc(p,95,0,TAU,40,Color("#e6bb76" if warning else "#98e3f1"),4,true)
    g.world_transform(p,w.clock*(2.2 if active else .12));draw(g,"gear",Rect2(-Vector2.ONE*68,Vector2.ONE*136),Color("#e6bb76" if warning else "#b7eef2") if active else Color(.8,.8,.8,.7));g.world_transform()
static func beacon(g:Node,p:Vector2,tint:Color)->void:
 draw(g,"beacon",Rect2(p-Vector2(38,40),Vector2(76,76)))
 g.draw_arc(p,35,0,TAU,32,tint,4)
static func crown(g:Node,p:Vector2)->void:
 draw(g,"crown",Rect2(p-Vector2(24,24),Vector2(48,42)))
static func plinth(g:Node,p:Vector2)->void:
 draw(g,"medallion",Rect2(p-Vector2.ONE*76,Vector2.ONE*152))
static func deck(g:Node,rect:Rect2,layer:int,time:float)->void:
 var tint=[Color("#8ddbc9"),Color("#b2bfee"),Color("#ebc38f")][layer] if is_inf(time) else Color("#ffda92").lerp(Color("#fa8887"),1-clampf(time/.85,0,1))
 g.draw_rect(Rect2(rect.position+Vector2(0,6),rect.size),Color("#192e3e"))
 g.draw_texture_rect(png("deck"),rect,false,tint)
 if not is_inf(time):
  g.draw_rect(rect,Color(1,.6,.22,.32));g.draw_rect(rect,Color("#f9c37c"),false,2)
