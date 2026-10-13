extends RefCounted
## Embedded SVG text bypasses both editor import order and export remaps.
## Original SVG sources remain editable; refresh content/source-art.json after edits.
static var cache:Dictionary={}
static var sources:Dictionary={}
static func texture(path:String)->Texture2D:
 if cache.has(path):return cache[path]
 if sources.is_empty():
  var parsed=JSON.parse_string(FileAccess.get_file_as_string("res://content/source-art.json"))
  if parsed is Dictionary:sources=parsed
 var image=Image.new()
 if image.load_svg_from_string(str(sources.get(path,"")))!=OK:return null
 cache[path]=ImageTexture.create_from_image(image)
 return cache[path]
