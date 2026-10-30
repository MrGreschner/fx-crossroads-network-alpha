extends RefCounted
## Embedded SVG text bypasses both editor import order and export remaps.
## Original SVG sources remain editable; refresh content/source-art.json after edits.
static var cache:Dictionary={}
static var sources:Dictionary={}
static func texture(path:String)->Texture2D:
 var fish=preload("res://scripts/fish_art252.gd").legacy_path(path)
 if fish!=null:return fish
 var training={"res://assets/training_dummy.svg":"training_dummy","res://assets/training_outpost.svg":"training_outpost","res://assets/training_hero_book.svg":"training_book"}
 if training.has(path):return preload("res://scripts/studio_art249.gd").prop(training[path])
 var item=preload("res://scripts/item_art245.gd").legacy_path(path)
 if item!=null:return item
 var crop=preload("res://scripts/town_art246.gd").legacy_path(path)
 if crop!=null:return crop
 var updated=preload("res://scripts/enemy_art235.gd").legacy_path(path)
 if updated!=null:return updated
 if cache.has(path):return cache[path]
 if sources.is_empty():
  var parsed=JSON.parse_string(FileAccess.get_file_as_string("res://content/source-art.json"))
  if parsed is Dictionary:sources=parsed
 var image=Image.new()
 if image.load_svg_from_string(str(sources.get(path,"")))!=OK:return null
 cache[path]=ImageTexture.create_from_image(image)
 return cache[path]
