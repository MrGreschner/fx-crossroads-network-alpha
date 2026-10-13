extends Node2D
## Retain terrain commands, never create render textures or redraw static tiles per frame.
const EDGE=512
const LIMIT=48
var game:Node2D
var chunks:Dictionary={}
var age:=0
class Chunk extends Node2D:
 var tiles:Array=[]
 var used:=0
 func _draw()->void:
  for tile in tiles:draw_texture_rect(tile[0],tile[1],false)
func reset()->void:
 for chunk in chunks.values():chunk.queue_free()
 chunks.clear()
func sync()->void:
 visible=game.started and not game.spectating() and not (game.session_menu!=null and game.session_menu.page in ["main","clear","options"])
 if not visible:return
 position=game.media.offset()-game.camera*game.media.factor();scale=Vector2.ONE*game.media.factor();age+=1
 var bounds:=Rect2(game.camera,game.VIEW)
 for chunk in chunks.values():chunk.visible=bounds.intersects(Rect2(chunk.position,Vector2(EDGE,EDGE)))
 for x in range(int(floor(bounds.position.x/EDGE)),int(floor(bounds.end.x/EDGE))+1):
  for y in range(int(floor(bounds.position.y/EDGE)),int(floor(bounds.end.y/EDGE))+1):
   var key:=Vector2i(x,y)
   if not chunks.has(key):
    var chunk:=Chunk.new();chunk.position=Vector2(key)*EDGE
    for tx in range(x*8,x*8+8):
     for ty in range(y*8,y*8+8):
      var tile:String=game.cached_world_tile(tx,ty,64);var local:=Vector2(tx*64,ty*64)-chunk.position
      if game.art.get(tile)!=null:chunk.tiles.append([game.art[tile],Rect2(local,Vector2(64,64))])
      if tile in ["grass","forest"] and (tx*37+ty*71)%23==3 and game.art.get("flower")!=null:chunk.tiles.append([game.art.flower,Rect2(local+Vector2(16,12),Vector2(32,32))])
    chunks[key]=chunk;add_child(chunk);chunk.queue_redraw()
   chunks[key].visible=true;chunks[key].used=age
 while chunks.size()>LIMIT:
  var oldest:Variant=null;var stamp:=age
  for key in chunks:
   if not chunks[key].visible and chunks[key].used<stamp:oldest=key;stamp=chunks[key].used
  if oldest==null:break
  chunks[oldest].queue_free();chunks.erase(oldest)
