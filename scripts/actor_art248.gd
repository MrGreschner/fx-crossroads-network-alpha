extends RefCounted
## V248 art-only adapter: one small shared atlas, original body heights and foot anchors.
const IDS=["hatch_sentinel","sweep_drone","magnet_hauler","repair_wisp","fork_runner","relay_weaver","continuum_forge","continuum_archive","continuum_reactor","continuum_crown","chalkling","mosaicling","hive_drone","stagelet","deputyling","quillling","lanternling","gravehorse","morrow_healer"]
const SUMMONS=["mosaicling","hive_drone","stagelet","deputyling","quillling","lanternling","gravehorse","morrow_healer"]
static var sheet:Texture2D
static var metadata:Dictionary={}
static var frames:Dictionary={}
static func has(id:String)->bool:return id in IDS
static func prepare()->void:
 if sheet!=null:return
 metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/actors248/manifest.json"))
 var image=Image.new()
 var error=image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/actors248/actors.png"))
 if error!=OK:push_error("V248 actor atlas unavailable");return
 sheet=ImageTexture.create_from_image(image)
static func pose_index(pose:String)->int:return 3 if pose in ["attack","attack2","special","open"] else 1 if pose in ["walk1","1"] else 2 if pose in ["walk2","2"] else 0
static func texture(id:String,pose:String="idle")->Texture2D:
 if not has(id):return null
 prepare();var n=pose_index(pose);var key=id+":"+str(n)
 if not frames.has(key):
  var index=int(metadata[id].index);var t=AtlasTexture.new();t.atlas=sheet;t.region=Rect2((index%2*4+n)*80,int(index/2)*80,80,80);frames[key]=t
 return frames[key]
static func fitted(id:String,rect:Rect2)->Rect2:
 prepare();var m:Dictionary=metadata[id];var b:Array=m.old_normalized
 var height=rect.size.y*(float(b[3])-float(b[1]));var foot=rect.position+rect.size*Vector2((float(b[0])+float(b[2]))*.5,float(b[3]))
 var size=Vector2.ONE*80*(height/float(m.visible_height))
 return Rect2(foot-size*Vector2(.5,.925),size)
