extends RefCounted
const IDS=["sluice_crab","coil_singer","glass_mender","confluence_heart"]
static var sheet:Texture2D
static var metadata:Dictionary={}
static var frames:Dictionary={}
static func has(id:String)->bool:return id in IDS
static func prepare()->void:
 if sheet!=null:return
 metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/foundry265/actors.json"));var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/foundry265/actors.png"));sheet=ImageTexture.create_from_image(im)
static func texture(id:String,pose:String="idle")->Texture2D:
 if preload("res://scripts/enemy_animation275.gd").has(id):return preload("res://scripts/enemy_animation275.gd").texture(id,pose)
 prepare();var n=0;var key=id+":"+str(n)
 if not frames.has(key):
  var t=AtlasTexture.new();t.atlas=sheet;t.region=Rect2(IDS.find(id)*128,n*128,128,128);frames[key]=t
 return frames[key]
static func fitted(id:String,rect:Rect2)->Rect2:
 if preload("res://scripts/enemy_animation275.gd").has(id):return preload("res://scripts/enemy_animation275.gd").fitted(id,rect)
 prepare();var m:Dictionary=metadata[id];var growth:Vector2=rect.size*(float(m.factor)-1.0);rect=Rect2(rect.position-growth*Vector2(.5,.9375),rect.size*float(m.factor));var b:Array=m.old_normalized;var h:float=rect.size.y*(float(b[3])-float(b[1]));var foot:Vector2=rect.position+rect.size*Vector2((float(b[0])+float(b[2]))*.5,float(b[3]));var size=Vector2.ONE*128*(h/float(m.visible_height));return Rect2(foot-size*Vector2(.5,.9375),size)
