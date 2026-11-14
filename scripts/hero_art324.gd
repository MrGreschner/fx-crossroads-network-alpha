extends RefCounted
## Batch one: independently redrawn two-frame walks; no deformation or mirroring.
const IDS=["vesper","hearthwarden","cantor"]
static var sheets:Dictionary={}
static var frames:Dictionary={}
static func pose(sprite:String,index:int)->Texture2D:
 if sprite not in IDS:return null
 if index==120:index=1
 elif index==121:index=2
 if sprite!="caelum" and index not in [1,2]:return null
 if index<0 or index>5:return null
 if not sheets.has(sprite):
  var raster:=Image.new()
  if raster.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/hero324/"+sprite+".png"))!=OK:return null
  sheets[sprite]=ImageTexture.create_from_image(raster)
 var key:=sprite+"/"+str(index)
 if not frames.has(key):
  var frame:=AtlasTexture.new()
  frame.atlas=sheets[sprite]
  var column:=index%3 if sprite=="caelum" else index-1
  var row:=int(index/3) if sprite=="caelum" else 0
  frame.region=Rect2(column*80,row*80,80,80)
  frame.filter_clip=true
  frames[key]=frame
 return frames[key]
