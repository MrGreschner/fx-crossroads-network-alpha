extends RefCounted
const IDS=["burrowfang","shardspitter","fusehare","rootwarden","echo_bat","sap_nurse","flintroot","dig_fx"]
static var sheet:Texture2D
static var metadata:Dictionary={}
static var frames:Dictionary={}
static func has(id:String)->bool:return id in IDS
static func prepare()->void:
 if sheet!=null:return
 metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/hollow268/actors.json"));var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/hollow268/actors.png"));sheet=ImageTexture.create_from_image(im)
static func texture(id:String,pose:String="idle")->Texture2D:
 if preload("res://scripts/enemy_animation275.gd").has(id):return preload("res://scripts/enemy_animation275.gd").texture(id,pose)
 if preload("res://scripts/neutral_art270.gd").has(id):
  var neutral=preload("res://scripts/neutral_art270.gd");neutral.prepare();metadata[id]=neutral.metadata[id];return neutral.texture(id)
 prepare();var n=3 if pose in ["attack","attack2","special","open"] else 1 if pose in ["walk1","1"] else 2 if pose in ["walk2","2"] else 0;var key=id+":"+str(n)
 if not frames.has(key):
  var t=AtlasTexture.new();t.atlas=sheet;t.region=Rect2(IDS.find(id)*256,n*256,256,256);frames[key]=t
 return frames[key]
static func fitted(id:String,rect:Rect2)->Rect2:
 if preload("res://scripts/enemy_animation275.gd").has(id):return preload("res://scripts/enemy_animation275.gd").fitted(id,rect)
 if preload("res://scripts/neutral_art270.gd").has(id):
  var neutral=preload("res://scripts/neutral_art270.gd");neutral.prepare();metadata[id]=neutral.metadata[id];return neutral.fitted(id,rect)
 prepare();var m:Dictionary=metadata[id];var growth:Vector2=rect.size*(float(m.factor)-1.0);rect=Rect2(rect.position-growth*Vector2(.5,.9375),rect.size*float(m.factor));var b:Array=m.old_normalized;var h:float=rect.size.y*(float(b[3])-float(b[1]));var foot:Vector2=rect.position+rect.size*Vector2((float(b[0])+float(b[2]))*.5,float(b[3]));var size=Vector2.ONE*256*(h/float(m.visible_height));return Rect2(foot-size*Vector2(.5,.9375),size)
