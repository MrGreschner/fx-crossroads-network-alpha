extends RefCounted
static var backdrop:Texture2D
static func background()->Texture2D:
 if backdrop==null:
  var image:=Image.new()
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/art215/menu215.png"))==OK:backdrop=ImageTexture.create_from_image(image)
 return backdrop
