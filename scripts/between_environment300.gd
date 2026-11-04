extends RefCounted
## Reuses21realm libraries;expert/extreme environments excluded. Visual selection never consumes the gameplay RNG.
const BASE=["grove","quarry","silverfall","ice","lantern_marsh","astral_rift"]
const CACHE_LIMIT=21
static var profiles:Array=[]
static var cache:Dictionary={}
static var order:Array=[]
static var visible_cells:int=0
static var visible_props:int=0
static func prepare()->void:
 if profiles.is_empty():profiles=JSON.parse_string(FileAccess.get_file_as_string("res://assets/between300/manifest.json")).environments
static func profile(exp:RefCounted,d:Dictionary)->Dictionary:
 prepare()
 var family=int(d.theme);var options=[]
 for p in profiles:
  if int(p.family)==family:options.append(p)
 var cell=Vector2i(d.cell[0],d.cell[1])
 if exp.trial() and cell in exp.SEAL_CELLS:
  for p in options:
   if str(p.id)==BASE[family]:return p
 var cluster=Vector2i(floori(cell.x/2.0),floori(cell.y/2.0))
 var rng=RandomNumberGenerator.new();rng.seed=abs(int(exp.manager.ticket().seed)^int(cluster.x*73856093)^int(cluster.y*19349663)^390033)
 return options[rng.randi_range(0,options.size()-1)]
static func name_for(exp:RefCounted,d:Dictionary)->String:return str(profile(exp,d).name)
static func texture(path:String)->Texture2D:
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK:return null
 var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;return t
static func bundle(p:Dictionary)->Dictionary:
 var id=str(p.id)
 if cache.has(id):order.erase(id);order.append(id);return cache[id]
 if order.size()>=CACHE_LIMIT:cache.erase(order.pop_front())
 var base="res://assets/between300/"+id;var value={"floor":texture(base+"_floor.png"),"route":texture(base+"_route.png"),"water":texture(base+"_water.png"),"pond":texture(base+"_pond.png"),"props":[]}
 var atlas=texture(base+"_props.png")
 for entry in p.props:
  var r=entry.region;var frame=AtlasTexture.new();frame.atlas=atlas;frame.region=Rect2(r[0],r[1],r[2],r[3]);value.props.append(frame)
 cache[id]=value;order.append(id);return value
static func draw(exp:RefCounted,g:Node2D,cam:Vector2,points:Array)->void:
 var view=Rect2(cam,g.VIEW).grow(160);var cells=[];var props=[];visible_cells=0;visible_props=0
 for d in exp.chunks.values():
  var box=Rect2(d.center-Vector2.ONE*384,Vector2.ONE*768)
  if not view.intersects(box):continue
  cells.append(d)
 # Floors first: adjacent chunks cannot paint over each other's raised scenery.
 for d in cells:
  visible_cells+=1
  var p=profile(exp,d);var b=bundle(p);var at:Vector2=d.center-cam;var color=Color(p.color)
  g.draw_texture_rect(b.floor,Rect2(at-Vector2.ONE*384,Vector2.ONE*768),true)
  g.draw_texture_rect(b.route,Rect2(at-Vector2(98,384),Vector2(196,768)),true,Color(.96,.97,.97))
  g.draw_texture_rect(b.route,Rect2(at-Vector2(384,98),Vector2(768,196)),true,Color(.96,.97,.97))
  if int(d.form)==1:
   g.draw_arc(at,165,0,TAU,48,Color(color,.32),5,true)
   for n in 6:g.draw_circle(at+Vector2.from_angle(n*TAU/6)*170,5,Color(color,.55))
  elif int(d.form)==2:
   for side in [-1,1]:g.draw_texture_rect(b.route,Rect2(at+Vector2(side*205-38,-65),Vector2(76,130)),true,Color(color,.65))
  elif int(d.form)==3 and int(d.theme)==2:
   g.draw_texture_rect(b.water,Rect2(at+Vector2(-384,100),Vector2(768,110)),true)
   g.draw_texture_rect(b.route,Rect2(at+Vector2(-125,90),Vector2(250,130)),true)
   for side in [-1,1]:g.draw_line(at+Vector2(side*123,92),at+Vector2(side*123,218),Color(color,.9),5,true)
  for dir in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   if bool(d.exits[exp.key(dir)]):continue
   var edge:Vector2=d.center+Vector2(dir)*384
   var r=Rect2(edge-(Vector2(42,384) if dir.x!=0 else Vector2(384,42)),Vector2(84,768) if dir.x!=0 else Vector2(768,84))
   g.draw_rect(Rect2(r.position-cam+Vector2(0,14),r.size),Color(.025,.045,.065,.55))
   g.draw_texture_rect(b.route,Rect2(r.position-cam,r.size),true,Color(.43,.50,.53))
   g.draw_line(edge-cam+(Vector2(-28,-384) if dir.x!=0 else Vector2(-384,-28)),edge-cam+(Vector2(-28,384) if dir.x!=0 else Vector2(384,-28)),Color(color,.5),3,true)
   for n in 4:
    var foot=edge+(Vector2(0,-280+n*184) if dir.x!=0 else Vector2(-280+n*184,0))
    props.append({"at":foot,"size":Vector2(112,146),"profile":p,"index":4+n%4,"landmark":true})
  for n in d.props.size():
   var v=d.props[n];props.append({"at":Vector2(v[0],v[1])+Vector2(0,35),"size":Vector2(112,132),"profile":p,"index":n%4,"landmark":false})
  var water:Dictionary=d.get("fishing",{})
  if not water.is_empty():
   var wet=Vector2(water.water[0],water.water[1])-cam
   g.draw_texture_rect(b.pond,Rect2(wet-Vector2.ONE*72,Vector2.ONE*144),false)
   g.draw_arc(wet,68,0,TAU,32,Color(color,.8),3,true)
   g.draw_line(wet+Vector2(-27,12),wet+Vector2(25,12),Color(.76,.89,.9,.4),1.5,true)
 props.sort_custom(func(a,b):return a.at.y<b.at.y)
 for v in props:
  var r=Rect2(v.at-v.size*Vector2(.5,.945),v.size)
  if not view.intersects(r):continue
  var alpha=1.0
  for point in points:
   if r.grow(22).has_point(point):alpha=.3
  var b=bundle(v.profile);visible_props+=1
  g.draw_texture_rect(b.props[v.index],Rect2(r.position-cam,r.size),false,Color(1,1,1,alpha))
