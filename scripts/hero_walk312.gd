extends RefCounted

const ROOT="res://assets/walk312/"
const FIRST_FRAME=120
const IDS=[
 "medic","ferryman","vesper","caelum","kage","hearthwarden","cantor",
 "votary","lumen","mosaic","quill","dustmarshal","twisterspell",
 "hazel_hex","echo_dancer","little_menace","hearth_herald"
]
static var cycles:Dictionary={}
static var frames:Dictionary={}
static var sheet:Texture2D

static func image(name:String)->Texture2D:
 var raster:=Image.new()
 if raster.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT+name+".png"))!=OK:return null
 return ImageTexture.create_from_image(raster)

static func prepare()->void:
 if not cycles.is_empty():return
 cycles=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"cycles.json"))

static func movement(sprite:String,clock:float)->int:
 prepare()
 var durations:Array=cycles[sprite].durations
 var period:int=0
 for duration in durations:period+=int(duration)
 var remainder:=posmod(floori(clock*1000),period)
 for n in durations.size():
  remainder-=int(durations[n])
  if remainder<0:return FIRST_FRAME+n
 return FIRST_FRAME

static func texture(sprite:String,index:int)->Texture2D:
 if sprite not in IDS:return null
 if index==0 and sprite in ["hazel_hex","echo_dancer"]:
  var key:=sprite+"_idle"
  if not frames.has(key):frames[key]=image(key)
  return frames[key]
 if index==1:index=FIRST_FRAME
 if index==2:index=FIRST_FRAME+1
 if index<FIRST_FRAME or index>=FIRST_FRAME+2:return null
 var key:="%s/%d" % [sprite,index]
 if not frames.has(key):
  prepare()
  if sheet==null:sheet=image("walks")
  var t:=AtlasTexture.new()
  t.atlas=sheet
  t.region=Rect2((index-FIRST_FRAME)*80,int(cycles[sprite].row)*80,80,80)
  t.filter_clip=true
  frames[key]=t
 return frames[key]

static var lyra_wind_sheet:Texture2D

static func animated_texture(sprite:String,index:int,clock:float)->Texture2D:
 if sprite!="twisterspell" or index<FIRST_FRAME or index>=FIRST_FRAME+2:
  return texture(sprite,index)
 var wind_frame:=posmod(floori(clock*1000.0/30.0),12)
 var key:="lyra_wind/%d/%d" % [index,wind_frame]
 if not frames.has(key):
  if lyra_wind_sheet==null:lyra_wind_sheet=image("lyra_walk_wind")
  if lyra_wind_sheet==null:return texture(sprite,index)
  var tile:=AtlasTexture.new()
  tile.atlas=lyra_wind_sheet
  tile.region=Rect2(wind_frame*80,(index-FIRST_FRAME)*80,80,80)
  tile.filter_clip=true
  frames[key]=tile
 return frames[key]
