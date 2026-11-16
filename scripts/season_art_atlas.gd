extends RefCounted
## Shared lazy loading for seasonal art.
static var textures:Dictionary={}
static var lake_frames:Dictionary={}

static func texture(folder:String,id:String)->Texture2D:
 var key=folder+id
 if not textures.has(key):
  var im=Image.new()
  if im.load_png_from_buffer(FileAccess.get_file_as_bytes(folder+id+".png"))!=OK:return null
  textures[key]=ImageTexture.create_from_image(im)
 return textures[key]

static func lake_plant(folder:String,id:String)->Texture2D:
 if not lake_frames.has(folder):
  var frames:Dictionary={}
  var box:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"lake_plants.json"))
  var atlas=texture(folder,"lake_plants")
  for key in box:
   var rect:Array=box[key]
   var frame=AtlasTexture.new()
   frame.atlas=atlas
   frame.region=Rect2(rect[0],rect[1],rect[2],rect[3])
   frames[key]=frame
  lake_frames[folder]=frames
 return lake_frames[folder].get(id)

