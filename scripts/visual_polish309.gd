extends RefCounted

const ROOT = "res://assets/v309/"
const FIRST_WALK_FRAME = 100
const WALK_HEROES = [
 "medic", "ferryman", "vesper", "drum", "garrick", "caelum", "kage",
 "hearthwarden", "cantor", "regent", "votary", "lumen", "mosaic",
 "quill", "dustmarshal", "twisterspell", "hazel_hex", "echo_dancer",
 "little_menace", "hearth_herald"
]
const REFINED_IDLE = ["hazel_hex", "echo_dancer"]

static var manifest: Dictionary
static var images: Dictionary
static var frames: Dictionary

static func prepare() -> void:
 if manifest.is_empty():
  manifest = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "manifest.json"))

static func texture(key: String) -> Texture2D:
 if not images.has(key):
  var image := Image.new()
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT + key + ".png")) != OK:
   return null
  images[key] = ImageTexture.create_from_image(image)
 return images[key]

static func hero(sprite: String, index: int) -> Texture2D:
 if index == 0 and sprite in REFINED_IDLE:
  return texture(sprite + "_idle")
 if sprite not in WALK_HEROES:
  return null
 if index == 1: index = FIRST_WALK_FRAME
 if index == 2: index = FIRST_WALK_FRAME + 2
 if index < FIRST_WALK_FRAME or index >= FIRST_WALK_FRAME + 4:
  return null
 var key := "%s/%d" % [sprite, index]
 if not frames.has(key):
  prepare()
  var frame := AtlasTexture.new()
  frame.atlas = texture("walks")
  frame.region = Rect2((index - FIRST_WALK_FRAME) * 80, int(manifest.walk_rows[sprite]) * 80, 80, 80)
  frame.filter_clip = true
  frames[key] = frame
 return frames[key]

static func yard_size(key: String) -> Vector2:
 prepare()
 var dimensions: Array = manifest.yard[key]
 return Vector2(dimensions[0], dimensions[1])

static func yard_rect(key: String, base: Vector2, anchor := Vector2(.5, .94)) -> Rect2:
 var dimensions := yard_size(key)
 return Rect2(base - dimensions * anchor, dimensions)

static func yard_texture(key: String) -> Texture2D:
 return texture("yard_" + key)
