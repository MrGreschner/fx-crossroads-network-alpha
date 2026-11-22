extends RefCounted
## One offline-prepared winter atlas, shared with the original residential UVs.
## Loading is lazy and cached; doors, windows, navigation and collisions stay put.
const HOMES=["cliff_cottage","artists_duplex","orchard_home","guard_townhouse","river_home","tidekeeper"]
static var atlas:Texture2D
static func texture(id:String,season:String)->Texture2D:
 if season!="Winter" or id not in HOMES:return null
 if atlas==null:
  var image=Image.new()
  if image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/town_winter382/homes.png"))!=OK:return null
  atlas=ImageTexture.create_from_image(image)
 return atlas
