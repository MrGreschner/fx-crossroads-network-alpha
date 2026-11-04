extends RefCounted
## One shared simple broadside wagon; the service window is perpendicular to the rightward shafts.
## Presentation only. Shop anchors, collision and purchase logic remain owned by existing systems.
static var cached:Texture2D
static func texture()->Texture2D:
 if cached==null:
  var im=Image.new();var err=im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/merchant282/cart.png"))
  if err!=OK:push_error("Merchant cart artwork unavailable");return null
  var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;cached=t
 return cached
static func draw(c:Node2D,at:Vector2,cam:Vector2,show_label:bool=true)->void:
 var size=Vector2(240,144);var r=Rect2(at-cam-size*Vector2(.41,.92),size)
 if not Rect2(Vector2.ZERO,c.VIEW).grow(80).intersects(r):return
 c.draw_texture_rect(texture(),r,false)
 if show_label:
  var p=at-cam+Vector2(-110,-133);var f=ThemeDB.fallback_font
  c.draw_string_outline(f,p,"MERCHANT",HORIZONTAL_ALIGNMENT_CENTER,220,15,3,Color("#31484a"));c.draw_string(f,p,"MERCHANT",HORIZONTAL_ALIGNMENT_CENTER,220,15,Color("#f3e6ba"))
