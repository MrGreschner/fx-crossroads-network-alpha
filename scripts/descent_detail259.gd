extends RefCounted
## Original painted detail; prior normalized body bounds and anchors are retained.
const LIMIT=3
static var sheets:Dictionary={}
static var frames:Dictionary={}
static var recent:Array[String]=[]
static func has(id:String)->bool:
 return id.begins_with("ds_boss_") or id.begins_with("ds_mid_") or id=="ds_lava_heart"
static func texture(id:String,pose:int=0)->Texture2D:
 if not has(id):return null
 if not sheets.has(id):
  if recent.size()>=LIMIT:
   var old=recent.pop_front();sheets.erase(old)
   for n in 4:frames.erase(old+":"+str(n))
  var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/detail259/"+id+".png"));sheets[id]=ImageTexture.create_from_image(im)
 recent.erase(id);recent.append(id)
 var n=clampi(pose,0,3);var key=id+":"+str(n)
 if not frames.has(key):
  var t=AtlasTexture.new();t.atlas=sheets[id];t.region=Rect2(n*320,0,320,320);frames[key]=t
 return frames[key]
