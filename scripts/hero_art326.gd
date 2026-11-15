extends RefCounted
## Batch one: independently redrawn two-frame walks; no deformation or mirroring.
const NEW_HEROES=["nutcracker","lockjaw","anjali","santa","reindeer"]
const IDS=["ferryman","hearthwarden","cantor","caelum","votary","lumen","mosaic","quill","dustmarshal","twisterspell","hazel_hex","echo_dancer","little_menace","hearth_herald","rook","iris","cairnheart","beaver","cat","elara","aurel"]
static var sheets:Dictionary={}
static var frames:Dictionary={}
static func pose(sprite:String,index:int)->Texture2D:
 if sprite not in IDS and sprite not in NEW_HEROES:return null
 if index==120:index=1
 elif index==121:index=2
 if index not in ([0] if sprite=="caelum" else ([0,1,2,3,4,5] if (sprite in ["hazel_hex","echo_dancer"] or sprite in NEW_HEROES) else [1,2])):return null
 if not sheets.has(sprite):
  var raster:=Image.new()
  if raster.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/hero326/"+sprite+".png"))!=OK:return null
  sheets[sprite]=ImageTexture.create_from_image(raster)
 var key:=sprite+"/"+str(index)
 if not frames.has(key):
  var frame:=AtlasTexture.new()
  frame.atlas=sheets[sprite]
  var column:=index%3 if (sprite in ["caelum","hazel_hex","echo_dancer"] or sprite in NEW_HEROES) else index-1
  var row:=index/3 if (sprite in ["hazel_hex","echo_dancer"] or sprite in NEW_HEROES) else 0
  frame.region=Rect2(column*80,row*80,80,80)
  frame.filter_clip=true
  frames[key]=frame
 return frames[key]
