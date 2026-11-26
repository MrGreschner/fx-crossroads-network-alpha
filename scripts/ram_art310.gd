extends RefCounted

# Canonical game poses: idle, steps A/B, headbutt or greeting, charge or talk, special.
const YOUNG = [0, 1, 1, 2, 2, 4, 3, 4, 5, 5, 3, 4]
const ELDER = [0, 1, 2, 3, 4, 5]
const INTRO = [0, 1, 2, 4, 3, 5]
static var frames: Dictionary

static func pose(sprite: String, index: int) -> Texture2D:
 if sprite == "ram":
  return load_frame(sprite, YOUNG[index]) if index >= 0 and index < YOUNG.size() else null
 if sprite == "elder_ram":
  return load_frame(sprite, ELDER[index]) if index >= 0 and index < ELDER.size() else null
 return null

static func cinematic(index: int) -> Texture2D:
 return load_frame("ram", INTRO[index])

static func load_frame(sprite: String, index: int) -> Texture2D:
 var key := "%s_%d" % [sprite, index]
 if not frames.has(key):
  var image := Image.new()
  var folder="res://assets/ram385/" if sprite=="ram" and index in [1,2] else "res://assets/ram310/"
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes(folder + key + ".png")) != OK:
   return null
  frames[key] = ImageTexture.create_from_image(image)
 return frames[key]
