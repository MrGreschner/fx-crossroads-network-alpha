extends RefCounted
## One neutral frontal body; never index by direction, mirror or rotate.
const IDS=["sun_sentinel","sun_sentinel_crown","sunbeam_cantor","saffron_hopper","cartographer","inkfin","foldwing","crease_sentry","burrowfang","shardspitter","fusehare","rootwarden","echo_bat","sap_nurse","flintroot"]
static var sheet:Texture2D
static var metadata:Dictionary={}
static var frames:Dictionary={}
static func has(id:String)->bool:return id in IDS
static func prepare()->void:
 if sheet!=null:return
 metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/neutral270/actors.json"));var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/neutral270/actors.png"));sheet=ImageTexture.create_from_image(im)
static func texture(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var n=int(metadata[id].index);var t=AtlasTexture.new();t.atlas=sheet;t.region=Rect2((n%4)*256,int(n/4)*256,256,256);frames[id]=t
 return frames[id]
static func fitted(id:String,rect:Rect2)->Rect2:
 prepare();var m:Dictionary=metadata[id];var growth:Vector2=rect.size*(float(m.factor)-1);rect=Rect2(rect.position-growth*Vector2(.5,.9375),rect.size*float(m.factor));var b:Array=m.old_normalized;var height=rect.size.y*(float(b[3])-float(b[1]));var foot=rect.position+rect.size*Vector2((float(b[0])+float(b[2]))*.5,float(b[3]));var size=Vector2.ONE*256*(height/float(m.visible_height));return Rect2(foot-size*Vector2(.5,.9375),size)
static func motion(rect:Rect2,pose:String)->Rect2:
 if pose in ["walk1","1"]:rect.position.y-=1.4
 elif pose in ["walk2","2"]:rect.position.y-=.25
 elif pose in ["attack","attack2","special","open"]:rect.position.y-=.65
 return rect
