extends RefCounted
const ROOT="res://assets/town247/"
const CIVIC=Rect2(640,565,560,280)
static var textures:Dictionary={}
static var regions:Dictionary={}
static var water_pages:Dictionary={}
static func png(name:String)->Texture2D:
 if not textures.has(name):
  var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT+name+".png"));textures[name]=ImageTexture.create_from_image(im)
 return textures[name]
static func prepare()->void:
 if regions.is_empty():regions=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"ground.json"))
static func append(chunk:Node,tx:int,ty:int,local:Vector2,tile:String,g:Node)->void:
 prepare();var image=png("ground");var gx=posmod(tx,4)*64;var gy=posmod(ty,4)*64
 chunk.tiles.append([image,Rect2(local,Vector2(64,64)),Rect2(gx,gy,64,64)])
 if tile!="path":return
 var mask=0;var offsets=[Vector2i(0,-1),Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0)]
 for n in 4:
  var d:Vector2i=offsets[n]
  if g.ground_tile_at(tx+d.x,ty+d.y,"grass")=="path":mask|=1<<n
 var uv=regions["path"+str(mask)]
 chunk.tiles.append([image,Rect2(local,Vector2(64,64)),Rect2(uv[0],uv[1],uv[2],uv[3])])
static func civic(g:Node2D,camera:Vector2)->void:
 if Rect2(camera,g.VIEW).intersects(CIVIC):g.draw_texture_rect(png("civic"),Rect2(CIVIC.position-camera,CIVIC.size),false)
static func cached_page(name:String)->Texture2D:
 if water_pages.is_empty():water_pages=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"water_cache.json")).pages
 if water_pages.has(name):return png(str(water_pages[name]))
 return null
static func sync_water(g:Node2D)->void:
 var surface=g.get_node_or_null("TownWater247")
 if surface==null and g.mode!="town":return
 if surface==null:
  surface=load("res://scripts/town_water247.gd").new();surface.name="TownWater247";surface.game=g;g.add_child(surface)
 surface.sync()
