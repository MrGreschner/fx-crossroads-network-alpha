extends RefCounted
## Raster copies of authored static draw commands. Dynamic overlays and collisions stay live.
static var textures:Dictionary={}
static func texture(id:String)->Texture2D:
 if not textures.has(id):
  var path="res://assets/town_cache/"+id+".png"
  if FileAccess.file_exists(path+".import"):
   var imported=load(path)
   if imported is Texture2D:textures[id]=imported;return imported
  var image=Image.new()
  var error=image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
  if error!=OK:return null
  if image==null or image.is_empty():return null
  textures[id]=ImageTexture.create_from_image(image)
 return textures[id]
static func draw(c:CanvasItem,id:String,rect:Rect2)->void:
 var image=texture(id)
 if image!=null:c.draw_texture_rect(image,rect,false)
