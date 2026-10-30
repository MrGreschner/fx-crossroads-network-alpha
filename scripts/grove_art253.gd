extends RefCounted
## Grove-only presentation. Never modifies world or encounter data.
static var cache:Dictionary={}
static func texture(id:String)->Texture2D:
 if cache.has(id):return cache[id]
 var image=Image.new()
 if image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/grove253/"+id+".png"))!=OK:return null
 var result=ImageTexture.create_from_image(image);cache[id]=result;return result
static func path_mask(g:Node,x:int,y:int,coop:bool=false)->int:
 var mask=0;var d=[Vector2i(0,-1),Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0)]
 for n in 4:
  var q=Vector2i(x,y)+d[n]
  var tile=g.cached_world_tile(q.x,q.y,64) if coop else g.ground_tile_at(q.x,q.y,str(g.region.get("terrain","forest")))
  if tile=="path":mask|=1<<n
 return mask
