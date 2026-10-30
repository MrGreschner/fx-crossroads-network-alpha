extends RefCounted
## Cached atlas; previous visible heights and foot positions. No combat changes.
static var sheet:Texture2D
static var metadata:Dictionary={}
static var frames:Dictionary={}
static var keys:Dictionary={}
const SUFFIXES=["_attack2","_walk1","_walk2","_special","_attack","_idle","_open","_0","_1","_2"]
static func prepare()->void:
 if sheet!=null:return
 metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/enemy235/manifest.json"))
 var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/enemy235/creatures.png"));sheet=ImageTexture.create_from_image(im)
static func pose_index(pose:String)->int:return 3 if pose in ["attack","attack2","special","open"] else 1 if pose in ["walk1","1"] else 2 if pose in ["walk2","2"] else 0
static func texture(id:String,pose:String="idle")->Texture2D:
 if preload("res://scripts/actor_art248.gd").has(id):return preload("res://scripts/actor_art248.gd").texture(id,pose)
 prepare()
 if not metadata.has(id):return null
 var n=pose_index(pose);var key=id+":"+str(n)
 if not frames.has(key):
  var i=int(metadata[id].index);var tex=AtlasTexture.new();tex.atlas=sheet;tex.region=Rect2((i%2*4+n)*80,int(i/2)*80,80,80);frames[key]=tex
 return frames[key]
static func split_key(key:String)->Array:
 if keys.has(key):return keys[key]
 prepare();var id=key;var pose="idle"
 for suffix in SUFFIXES:
  if key.ends_with(suffix):id=key.trim_suffix(suffix);pose=suffix.trim_prefix("_");break
 var result=[id,pose] if metadata.has(id) or preload("res://scripts/actor_art248.gd").has(id) else []
 keys[key]=result;return result
static func legacy_path(path:String)->Texture2D:
 if not path.begins_with("res://assets/") or not path.ends_with(".svg"):return null
 var k=split_key(path.get_file().trim_suffix(".svg"))
 return texture(k[0],k[1]) if not k.is_empty() else null
static func fitted(id:String,rect:Rect2)->Rect2:
 if preload("res://scripts/actor_art248.gd").has(id):return preload("res://scripts/actor_art248.gd").fitted(id,rect)
 prepare();var m:Dictionary=metadata[id];var factor:float=m.old_factor;var growth:Vector2=rect.size*(factor-1.0)
 rect=Rect2(rect.position-growth*Vector2(.5,.9375),rect.size*factor)
 var b:Array=m.old_normalized;var h:float=rect.size.y*(float(b[3])-float(b[1]));var foot:Vector2=rect.position+rect.size*Vector2((float(b[0])+float(b[2]))*.5,float(b[3]))
 var scale:float=h/float(m.visible_height);var size=Vector2.ONE*80*scale
 return Rect2(foot-size*Vector2(.5,.925),size)
static func draw_key(c:CanvasItem,key:String,rect:Rect2,tint:Color=Color.WHITE)->bool:
 var k=split_key(key)
 if k.is_empty():return false
 c.draw_texture_rect(texture(k[0],k[1]),fitted(k[0],rect),false,tint);return true
