extends Node2D
## Retained 512px terrain chunks: draw commands are built once, not each frame.
## No render textures, physics changes or reduced attack-warning detail.
const EDGE=512
const LIMIT=48
var game:Node2D
var chunks:Dictionary={}
var age:=0
static var atlas:Texture2D
static var regions:Dictionary={}
static func prepare_atlas()->void:
 if atlas!=null:return
 var file="res://assets/town_cache/terrain39.json"
 if not FileAccess.file_exists(file):return
 regions=JSON.parse_string(FileAccess.get_file_as_string(file))
 atlas=preload("res://scripts/town_sprite_cache.gd").texture("terrain39")
func append_tile(chunk:Chunk,id:String,rect:Rect2)->void:
 if atlas!=null and regions.has(id):
  var uv=regions[id];chunk.tiles.append([atlas,rect,Rect2(uv[0],uv[1],uv[2],uv[3])])
 elif game.art.get(id)!=null:chunk.tiles.append([game.art[id],rect])
func _ready()->void:z_index=-3
class Chunk extends Node2D:
 var tiles:Array=[]
 var used:=0
 func _draw()->void:
  for tile in tiles:
   if tile.size()==3:draw_texture_rect_region(tile[0],tile[1],tile[2])
   else:draw_texture_rect(tile[0],tile[1],false)
func reset()->void:
 for chunk in chunks.values():chunk.queue_free()
 chunks.clear()
func sync()->void:
 visible=not game.region.is_empty() and not (game.session_menu!=null and game.session_menu.page in ["main","clear","options"])
 if not visible:return
 position=game.media.offset()-game.camera*game.media.factor();scale=Vector2.ONE*game.media.factor()
 prepare_atlas();age+=1
 var bounds:=Rect2(game.camera,game.VIEW)
 for chunk in chunks.values():chunk.visible=false
 var base:String="grass" if game.mode=="town" else str(game.region.get("terrain","forest"))
 for x in range(int(floor(bounds.position.x/EDGE)),int(floor(bounds.end.x/EDGE))+1):
  for y in range(int(floor(bounds.position.y/EDGE)),int(floor(bounds.end.y/EDGE))+1):
   var key:=Vector2i(x,y)
   if not chunks.has(key):
    var chunk:=Chunk.new();chunk.position=Vector2(key)*EDGE
    for tx in range(x*8,x*8+8):
     for ty in range(y*8,y*8+8):
      if tx<(floori(float(game.region.get("west_extent",-800))/64.0) if game.mode=="town" else 0) or ty<(-9 if game.mode=="town" else 0) or tx>int(game.region_size().x/64) or ty>int(game.region_size().y/64):continue
      var tile:String=game.ground_tile_at(tx,ty,base)
      var local:=Vector2(tx*64,ty*64)-chunk.position
      append_tile(chunk,tile,Rect2(local,Vector2(64,64)))
      var seed:int=(tx*37+ty*71+tx*ty*11)%19
      if tile!="path" and seed==3 and base not in ["ash","moonburrow_grass"] and game.art.get("flower")!=null and (game.mode!="town" or not preload("res://scripts/town_plan.gd").reserved(Vector2(tx*64+32,ty*64+26))):
       append_tile(chunk,"flower",Rect2(local+Vector2(12,6),Vector2(40,40)))
    chunks[key]=chunk;add_child(chunk);chunk.queue_redraw()
   chunks[key].visible=true;chunks[key].used=age
 while chunks.size()>LIMIT:
  var oldest:Variant=null;var stamp:=age
  for key in chunks:
   if not chunks[key].visible and chunks[key].used<stamp:oldest=key;stamp=chunks[key].used
  if oldest==null:break
  chunks[oldest].queue_free();chunks.erase(oldest)
