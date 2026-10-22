extends RefCounted
static var cached:Texture2D
static func texture()->Texture2D:
 if cached==null:
  var image=Image.new();image.load_svg_from_string('<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><path d="M6 16 1 9v14z" fill="#8fdbd5"/><path d="M5 16Q15 1 29 16 15 31 5 16" fill="#8fdbd5"/><path d="m14 9 4-6 5 8" fill="#e5d399"/><circle cx="23" cy="14" r="2" fill="#16333d"/></svg>');cached=ImageTexture.create_from_image(image)
 return cached
