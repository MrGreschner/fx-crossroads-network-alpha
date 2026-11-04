extends RefCounted
## Presentation only. North Gate keeps ownership of paths, collisions and services.
static var textures:Dictionary={}
static var frames:Dictionary={}
static var specs:Dictionary={}
static var material_specs:Dictionary={}
static var draws=0
static var actors:Dictionary={}
const ROOT="res://assets/north260/"
static func actor(id:String,pose:Variant=0)->Texture2D:
 if actors.is_empty():actors=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"actors.json"))
 if not actors.has(id):return null
 var n=preload("res://scripts/unit_art231.gd").pose_index(pose) if pose is String else clampi(int(pose),0,3);var key="actor:"+id+":"+str(n)
 if not frames.has(key):
  var a:Array=actors[id].regions[n];var t=AtlasTexture.new();t.atlas=png(str(actors[id].sheet));t.region=Rect2(a[0],a[1],a[2],a[3]);frames[key]=t
 return frames[key]
static func unit(g:CanvasItem,id:String,p:Vector2,pose:int=0,height:float=0)->void:
 var t=actor(id,pose)
 if t==null:return
 var m:Dictionary=actors[id];var scale=(float(m.world_height)if height<=0 else height)/float(m.visible_height);var size=Vector2.ONE*80*scale
 g.draw_texture_rect(t,Rect2(p-size*Vector2(.5,.925),size),false)
static func png(id:String)->Texture2D:
 if not textures.has(id):
  var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT+id+".png"));textures[id]=ImageTexture.create_from_image(im)
 return textures[id]
static func frame(id:String)->Texture2D:
 if specs.is_empty():specs=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"fort.json"))
 if not frames.has(id):
  var a:Array=specs[id].region;var t=AtlasTexture.new();t.atlas=png("fort");t.region=Rect2(a[0],a[1],a[2],a[3]);frames[id]=t
 return frames[id]
static func material(id:String)->Texture2D:
 var key="material:"+id
 if id.begins_with("stone") and id!="stone":
  if not frames.has(key):
   var n=int(id.trim_prefix("stone"));var t=AtlasTexture.new();t.atlas=png("stone");t.region=Rect2(n%4*64,int(n/4)*64,64,64);frames[key]=t
  return frames[key]
 if material_specs.is_empty():material_specs=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"materials.json"))
 if not frames.has(key):
  var a:Array=material_specs[id];var t=AtlasTexture.new();t.atlas=png("materials");t.region=Rect2(a[0],a[1],a[2],a[3]);frames[key]=t
 return frames[key]
static func bank(mask:int)->Texture2D:
 var key="bank:"+str(mask)
 if not frames.has(key):
  var t=AtlasTexture.new();t.atlas=png("banks");t.region=Rect2(mask%8*64,int(mask/8)*64,64,64);frames[key]=t
 return frames[key]
static func mask_at(g:Node,x:int,y:int,water:bool=false)->int:
 var mask=0;var offsets=[Vector2i(0,-1),Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0)]
 for n in 4:
  var p=Vector2i(x,y)+offsets[n];var tile=g.cached_world_tile(p.x,p.y,64)
  if tile=="river_water" if water else tile in ["path","river_bridge","city_cobble"]:mask|=1<<n
 return mask
static func append(chunk:Node,x:int,y:int,at:Vector2,tile:String,g:Node)->void:
 # Atlas subregions cannot repeat across a merged rectangle. Retain tiled quads;
 # their shared atlases still batch, and commands rebuild only when a chunk loads.
 chunk.compact=false
 var base=material("grass"+str(posmod(y,4)*4+posmod(x,4)))
 if tile=="city_cobble":base=material("stone"+str(posmod(y,4)*4+posmod(x,4)))
 elif tile=="oath_stone":base=material("ruins")
 elif tile=="river_bridge":base=material("deck")
 elif tile=="river_water":base=bank(mask_at(g,x,y,true))
 var rect=Rect2(at,Vector2(64,64));chunk.cells[Vector2i(posmod(x,8),posmod(y,8))]=base;chunk.tiles.append([base,rect])
 if tile=="path":
  var overlay=[material("path"+str(mask_at(g,x,y))),rect];chunk.flowers.append(overlay);chunk.tiles.append(overlay)
static func draw(g:CanvasItem,id:String,r:Rect2,tint:Color=Color.WHITE)->void:
 if not Rect2(Vector2.ZERO,g.get_viewport_rect().size).grow(3).intersects(r):return
 g.draw_texture_rect(frame(id),r,false,tint);draws+=1
static func building(g:Node2D,b:Dictionary,camera:Vector2)->void:
 var id=str(b.name).to_lower();var size=Vector2(260,210) if id=="gate" else Vector2(170,150)
 draw(g,id,Rect2(b.pos-size*Vector2(.5,.7)-camera,size))
static func obstacle(g:Node2D,b:Dictionary,camera:Vector2)->void:
 if str(b.get("kind","tree"))=="rock":
  var d=float(b.get("radius",38))*2+8;g.draw_texture_rect(preload("res://scripts/quarry_art254.gd").texture("rock"),Rect2(b.pos-Vector2.ONE*d*.5-camera,Vector2.ONE*d),false)
 else:g.draw_texture_rect(preload("res://scripts/quarry_art254.gd").grove_tree(b.pos),Rect2(b.pos-Vector2(44,65)-camera,Vector2(88,112)),false)
static func base(g:Node2D,n:RefCounted,camera:Vector2)->void:
 var center:Vector2=n.BASE;var font=ThemeDB.fallback_font
 for side in [-1,1]:draw(g,"wall",Rect2(center+Vector2(side*350-190,-82)-camera,Vector2(380,84)))
 for offset in [Vector2(-250,260),Vector2(250,260),Vector2(-250,760),Vector2(250,760)]:
  var p=center+offset-camera;draw(g,"brazier",Rect2(p-Vector2(16,84),Vector2(32,96)))
  if Rect2(Vector2.ZERO,g.VIEW).has_point(p):
   for k in 2:g.draw_circle(p-Vector2(0,64),3+k*3,Color(1,.75,.32,.12+sin(n.clock*4+offset.x)*.025))
 for lane in 3:
  var p=center+Vector2(-140+lane*140,370)-camera
  if Rect2(Vector2.ZERO,g.VIEW).grow(55).has_point(p):
   g.draw_arc(p,45,0,TAU,24,Color("#a5b79d"),2,true);g.draw_string(font,p+Vector2(-30,4),["NORTH","WEST","EAST"][lane],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#e4cf9c"))
 for site in [Vector2(4710,8200),Vector2(5900,8200)]:preload("res://scripts/town_streets244.gd").draw(g,"cart",Rect2(site+Vector2(78,-14)-camera,Vector2(64,52)))
 var spring=center+Vector2(0,600);var p=spring-camera
 if Rect2(Vector2.ZERO,g.VIEW).grow(120).has_point(p):
  preload("res://scripts/town_props240.gd").fountain(g,p,n.clock)
  g.draw_string(font,p+Vector2(-70,88),"GATEWARD SPRING",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#def0d2"))
 for k in 2:
  var at=center+Vector2(-340+k*680,300+sin(n.clock*.2+k*PI)*170)
  if Rect2(camera-Vector2(60,90),g.VIEW+Vector2(120,180)).has_point(at):unit(g,"guard_melee",at+Vector2(0,4)-camera,1+int(n.clock*5.5)%2,48)
static func world(g:Node2D,n:RefCounted,camera:Vector2)->void:
 base(g,n,camera);var font=ThemeDB.fallback_font;var bounds=Rect2(camera-Vector2(300,300),g.VIEW+Vector2(600,600))
 for lane in 3:
  var checkpoint=n.point_at(lane,n.OUTPOST_DISTANCE[lane]);var at=checkpoint+(Vector2(-150,-50) if lane==0 else Vector2(0,-155));var p=at-camera
  if not bounds.has_point(at):continue
  if n.outpost_hp[lane]<=0:
   preload("res://scripts/town_streets244.gd").draw(g,"camp_ring",Rect2(p-Vector2(72,24),Vector2(144,50)))
   g.draw_string(font,p+Vector2(-65,58),"OUTPOST LOST",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e7a78e"));continue
  var side=(n.point_at(lane,n.OUTPOST_DISTANCE[lane]+10)-n.point_at(lane,n.OUTPOST_DISTANCE[lane]-10)).normalized().orthogonal()
  # Low checkpoint rail leaves the established walking lane and interaction logic intact.
  for sign in [-1,1]:
   var q=checkpoint+side*sign*160-camera;preload("res://scripts/town_streets244.gd").draw(g,"garden_rail",Rect2(q-Vector2(22,24),Vector2(44,30)))
  draw(g,"outpost"+str(lane),Rect2(p+Vector2(-90,-140),Vector2(180,165)))
  g.draw_rect(Rect2(p+Vector2(-70,-158),Vector2(140,10)),Color("#352b29"));g.draw_rect(Rect2(p+Vector2(-70,-158),Vector2(140*n.outpost_hp[lane]/n.outpost_max,10)),Color("#75d8a2"))
  g.draw_string(font,p+Vector2(-90,58),["BELLWOOD OUTPOST","MILLROAD OUTPOST","EMBERWATCH OUTPOST"][lane],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#f4dfb7"))
  g.draw_string(font,p+Vector2(-85,80),"1 soldier / 20 seconds",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#bedccb"))
 for lane in 3:
  for k in range(1,5):
   var at=n.point_at(lane,k*950,200)
   if absf(k*950-n.OUTPOST_DISTANCE[lane])<230 or not bounds.has_point(at):continue
   var p=at-camera;draw(g,"milestone",Rect2(p+Vector2(-14,-24),Vector2(28,40)));g.draw_string(font,p+Vector2(-4,-2),str(k),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#4c6059"))
   if k%2==0:draw(g,"brazier",Rect2(p+Vector2(17,-72),Vector2(24,80)))
 # Bridge rails follow the original rectangular crossing. No new blocked area.
 if bounds.intersects(Rect2(5200,4030,590,490)):
  for x in [5206,5784]:
   g.draw_line(Vector2(x,4040)-camera,Vector2(x,4510)-camera,Color("#6b5c43"),7)
   g.draw_line(Vector2(x-2,4040)-camera,Vector2(x-2,4510)-camera,Color("#bda47b"),2)
   for y in range(4040,4511,78):
    var p=Vector2(x,y)-camera;draw(g,"milestone",Rect2(p-Vector2(12,26),Vector2(24,36)))
 for lane in 3:
  var at=n.point_at(lane,600)
  if bounds.has_point(at):g.draw_arc(at-camera,85,0,TAU,32,Color(.74,.77,.58,.45),2,true)
static func sync_water(g:Node)->void:
 var water=g.get_node_or_null("NorthWater260")
 if water==null and g.mode!="defense":return
 if water==null:water=load("res://scripts/north_water260.gd").new();water.name="NorthWater260";water.game=g;g.add_child(water)
 water.sync()
