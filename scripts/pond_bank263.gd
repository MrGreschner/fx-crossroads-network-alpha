extends RefCounted
static var bank:Texture2D
static func texture()->Texture2D:
 if bank==null:
  var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/rest263/pond_bank.png"));bank=ImageTexture.create_from_image(im)
 return bank
static func draw(c:Node2D,cam:Vector2)->void:
 var r=Rect2(-45,195,495,345)
 if Rect2(cam,c.VIEW).intersects(r):c.draw_texture_rect(texture(),Rect2(r.position-cam,r.size),false)
