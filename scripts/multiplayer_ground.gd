extends Node2D
## Merge identical terrain into repeated rectangles; retain commands between frames.
const EDGE=512
const LIMIT=48
var game:Node2D
var chunks:Dictionary={}
var age:=0
var battleground_layout=""
class Chunk extends Node2D:
 var tiles:Array=[]
 var cells:Dictionary={}
 var spans:Array=[]
 var flowers:Array=[]
 var compact=true
 var atlas_batches:Array=[]
 var used:=0
 func compile()->void:
  texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
  spans.clear()
  if not compact:return
  var consumed={}
  for y in 8:
   for x in 8:
    var key=Vector2i(x,y)
    if consumed.has(key) or not cells.has(key):continue
    var texture:Texture2D=cells[key]
    var width=1
    while x+width<8 and not consumed.has(Vector2i(x+width,y)) and cells.get(Vector2i(x+width,y))==texture:width+=1
    var height=1
    while y+height<8:
     var same=true
     for dx in width:
      if consumed.has(Vector2i(x+dx,y+height)) or cells.get(Vector2i(x+dx,y+height))!=texture:same=false;break
     if not same:break
     height+=1
    for dy in height:
     for dx in width:consumed[Vector2i(x+dx,y+dy)]=true
    spans.append([texture,Rect2(x*64,y*64,width*64,height*64)])
 func compile_arena_atlas()->void:
  var layers:Dictionary={}
  for tile in tiles:
   var frame=tile[0] as AtlasTexture
   if frame==null or frame.atlas==null or frame.margin!=Rect2():
    return
   var layer:int=tile[2]
   if not layers.has(layer):layers[layer]={}
   var groups:Dictionary=layers[layer]
   if not groups.has(frame.atlas):groups[frame.atlas]=[]
   groups[frame.atlas].append(tile)
  var order=layers.keys()
  order.sort()
  # Tiles in a layer do not overlap. Preserve the order of ground and path layers.
  for layer in order:
   for atlas in layers[layer]:
    var vertices=PackedVector2Array()
    var uvs=PackedVector2Array()
    var indices=PackedInt32Array()
    for tile in layers[layer][atlas]:
     var rect:Rect2=tile[1]
     var region:Rect2=tile[0].region
     var i=vertices.size()
     vertices.append_array(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
     var uv=Rect2(region.position/atlas.get_size(),region.size/atlas.get_size())
     uvs.append_array(PackedVector2Array([uv.position,Vector2(uv.end.x,uv.position.y),uv.end,Vector2(uv.position.x,uv.end.y)]))
     indices.append_array(PackedInt32Array([i,i+1,i+2,i,i+2,i+3]))
    var arrays=[]
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX]=vertices
    arrays[Mesh.ARRAY_TEX_UV]=uvs
    arrays[Mesh.ARRAY_INDEX]=indices
    var mesh=ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
    atlas_batches.append([mesh,atlas])
 func _draw()->void:
  if not atlas_batches.is_empty():
   for batch in atlas_batches:draw_mesh(batch[0],batch[1])
   return
  if not compact:
   for tile in tiles:draw_texture_rect(tile[0],tile[1],false)
   return
  for span in spans:
   var texture:Texture2D=span[0]
   var rect:Rect2=span[1]
   # Source coordinates preserve exactly one artwork tile per 64 world pixels,
   # including 32px forest/grass textures. No stretch or runtime render targets.
   draw_texture_rect_region(texture,rect,Rect2(Vector2.ZERO,rect.size*texture.get_size()/64.0),Color.WHITE,false,false)
  for flower in flowers:draw_texture_rect(flower[0],flower[1],false)
func reset()->void:
 for chunk in chunks.values():chunk.queue_free()
 chunks.clear()
func sync()->void:
 var layout_key=str(game.battlegrounds.map_id)+str(game.battlegrounds.lanes) if game.mode=="battlegrounds" else ""
 if layout_key!=battleground_layout:reset();battleground_layout=layout_key
 if game.mode=="coop" and game.realm_id in ["sunfield","ice","confluence","folded_coast","moonburrow"]:hide();return
 if game.mode=="descent":hide();return
 if game.mode=="coop" and game.realm_id in ["moonveil","silverfall"]:hide();return
 visible=game.started and not game.spectating() and not (game.session_menu!=null and game.session_menu.page in ["main","clear","options"])
 if not visible:return
 position=game.media.offset()-game.camera*game.media.factor();scale=Vector2.ONE*game.media.factor();age+=1
 var bounds:=Rect2(game.camera,game.VIEW/game.media.factor())
 for chunk in chunks.values():chunk.visible=bounds.intersects(Rect2(chunk.position,Vector2(EDGE,EDGE)))
 for x in range(int(floor(bounds.position.x/EDGE)),int(floor(bounds.end.x/EDGE))+1):
  for y in range(int(floor(bounds.position.y/EDGE)),int(floor(bounds.end.y/EDGE))+1):
   var key:=Vector2i(x,y)
   if not chunks.has(key):
    var chunk:=Chunk.new();chunk.position=Vector2(key)*EDGE
    for tx in range(x*8,x*8+8):
     for ty in range(y*8,y*8+8):
      var tile:String=game.cached_world_tile(tx,ty,64);var local:=Vector2(tx*64,ty*64)-chunk.position
      if game.mode=="battlegrounds":
       preload("res://scripts/battleground_art262.gd").append(chunk,tx,ty,local,game);continue
      if game.mode=="defense":
       preload("res://scripts/north_art260.gd").append(chunk,tx,ty,local,tile,game);continue
      if game.mode=="arena":
       preload("res://scripts/arena_art261.gd").append(chunk,tx,ty,local,tile,game);continue
      var painted:Texture2D=preload("res://scripts/grove_art253.gd").texture(tile) if game.mode=="coop" and game.realm_id=="grove" and tile in ["forest","path"] else game.art.get(tile)
      if game.mode=="coop" and game.realm_id=="quarry" and tile in ["ash","path"]:
       var a=preload("res://scripts/quarry_art254.gd");painted=a.texture("ash")
       if tile=="path":chunk.flowers.append([a.texture("edge"+str(preload("res://scripts/grove_art253.gd").path_mask(game,tx,ty,true))),Rect2(local,Vector2(64,64))])
      if game.mode=="coop" and game.realm_id=="grove" and tile=="path":
       var a=preload("res://scripts/grove_art253.gd");painted=a.texture("forest");chunk.flowers.append([a.texture("edge"+str(a.path_mask(game,tx,ty,true))),Rect2(local,Vector2(64,64))])
      if painted!=null:
       chunk.tiles.append([painted,Rect2(local,Vector2(64,64))]);chunk.cells[Vector2i(tx-x*8,ty-y*8)]=painted
      if not (game.mode=="coop" and game.realm_id=="grove") and tile in ["grass","forest"] and (tx*37+ty*71)%23==3 and game.art.get("flower")!=null:
       var flower=[game.art.flower,Rect2(local+Vector2(16,12),Vector2(32,32))]
       chunk.tiles.append(flower);chunk.flowers.append(flower)
    chunk.compile()
    if game.mode=="arena":chunk.compile_arena_atlas()
    chunks[key]=chunk;add_child(chunk);chunk.queue_redraw()
   chunks[key].visible=true;chunks[key].used=age
 while chunks.size()>LIMIT:
  var oldest:Variant=null;var stamp:=age
  for key in chunks:
   if not chunks[key].visible and chunks[key].used<stamp:oldest=key;stamp=chunks[key].used
  if oldest==null:break
  chunks[oldest].queue_free();chunks.erase(oldest)
func counters()->Dictionary:
 var original=0;var merged=0;var active=0
 var submissions=0
 for chunk in chunks.values():
  if not chunk.visible:continue
  active+=1;original+=chunk.tiles.size();merged+=chunk.tiles.size() if not chunk.compact else chunk.spans.size()+chunk.flowers.size()
  submissions+=chunk.atlas_batches.size() if not chunk.atlas_batches.is_empty() else chunk.tiles.size() if not chunk.compact else chunk.spans.size()+chunk.flowers.size()
 return {"visible_chunks":active,"original_quads":original,"merged_quads":merged,"floor_submissions":submissions}
