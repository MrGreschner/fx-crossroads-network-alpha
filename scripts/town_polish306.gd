extends RefCounted
## Small local scenery textures decoded lazily, once each.
static var textures:Dictionary={}
static func texture(id:String)->Texture2D:
 if not textures.has(id):
  var image=Image.new()
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/town306/"+id+".png"))!=OK:return null
  textures[id]=ImageTexture.create_from_image(image)
 return textures[id]

static func draw(c:Node2D,id:String,world:Rect2,camera:Vector2)->void:
 if not Rect2(camera,c.VIEW).intersects(world):return
 var art=texture(id)
 if art!=null:c.draw_texture_rect(art,Rect2(world.position-camera,world.size),false)
