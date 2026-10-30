extends RefCounted
## One cached sprite. Service position and 96x80 world rectangle are unchanged.
static var cached:Texture2D
static func texture()->Texture2D:
 if cached==null:
  var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/detail259/merchant.png"));cached=ImageTexture.create_from_image(im)
 return cached
