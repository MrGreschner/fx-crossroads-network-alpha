extends RefCounted
static var sheet:Texture2D
static var metadata:Dictionary={}
static var frames:Dictionary={}
static func prepare()->void:
 if sheet!=null:return
 metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/unit231/manifest231.json"))
 var image=Image.new();image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/unit231/units.png"));sheet=ImageTexture.create_from_image(image)
static func pose_index(pose:String)->int:return 3 if pose in ["attack","attack2","special"] else 1 if pose in ["walk1","1"] else 2 if pose in ["walk2","2"] else 0
static func texture(id:String,pose:Variant=0)->Texture2D:
 prepare();var n=pose_index(pose) if pose is String else clampi(int(pose),0,3);var key=id+":"+str(n)
 if not metadata.has(id):return null
 if not frames.has(key):
  var tex=AtlasTexture.new();tex.atlas=sheet;tex.region=Rect2(n*80,int(metadata[id].index)*80,80,80);frames[key]=tex
 return frames[key]
static func world_height(id:String)->float:
 prepare();return float(metadata.get(id,{}).get("world_height",52))
static func draw(c:CanvasItem,id:String,p:Vector2,pose:int=0,height:float=0)->void:
 var tex=texture(id,pose)
 if tex==null:return
 var scale=(world_height(id) if height<=0 else height)/float(metadata[id].visible_height)
 var size=Vector2.ONE*80*scale
 c.draw_texture_rect(tex,Rect2(p-size*Vector2(.5,.925),size),false)
static func npc_rect(id:String,rect:Rect2)->Rect2:
 if not id.begins_with("npc_") and id!="tollbreaker":return rect
 prepare();var factor=float(metadata.get(id,{}).get("npc_factor",1));var growth=rect.size*(factor-1)
 return Rect2(rect.position-growth*Vector2(.5,.925),rect.size*factor)
