extends RefCounted
## Cached art only; gameplay dimensions and authority remain unchanged.
static var sheet:Texture2D
static var props_sheet:Texture2D
static var metadata:Dictionary={}
static var prop_metadata:Dictionary={}
static var frames:Dictionary={}
static var prop_frames:Dictionary={}
static func prepare()->void:
 if sheet!=null:return
 metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art232/cast.json"));prop_metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art232/mine.json"))
 var image=Image.new();image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/art232/cast.png"));sheet=ImageTexture.create_from_image(image)
 image=Image.new();image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/art232/mine.png"));props_sheet=ImageTexture.create_from_image(image)
static func pose_index(pose:String)->int:return 3 if pose in ["attack","attack2","special","talk","work"] else 1 if pose in ["walk1","1"] else 2 if pose in ["walk2","2"] else 0
static func texture(id:String,pose:Variant=0)->Texture2D:
 if preload("res://scripts/descent_detail259.gd").has(id):return preload("res://scripts/descent_detail259.gd").texture(id,pose_index(pose) if pose is String else int(pose))
 prepare()
 if not metadata.has(id):return null
 var n:int=pose_index(pose) if pose is String else clampi(int(pose),0,3);var key=id+":"+str(n)
 if not frames.has(key):
  var index=int(metadata[id].index);var tex=AtlasTexture.new();tex.atlas=sheet;tex.region=Rect2((index%2*4+n)*80,int(index/2)*80,80,80);frames[key]=tex
 return frames[key]
static func prop(id:String)->Texture2D:
 prepare()
 if not prop_metadata.has(id):return null
 if not prop_frames.has(id):
  var index=int(prop_metadata[id].index);var tex=AtlasTexture.new();tex.atlas=props_sheet;tex.region=Rect2(index%4*128,int(index/4)*128,128,128);prop_frames[id]=tex
 return prop_frames[id]
static func draw_prop(c:CanvasItem,id:String,rect:Rect2,tint:Color=Color.WHITE)->void:
 var tex=prop(id)
 if tex==null:return
 var b:Array=prop_metadata[id].box;var used=Vector2(float(b[2])-b[0],float(b[3])-b[1]);var scale=minf(rect.size.x/used.x,rect.size.y/used.y);var size=Vector2.ONE*128*scale
 c.draw_texture_rect(tex,Rect2(Vector2(rect.get_center().x-size.x*.5,rect.end.y-float(b[3])*scale),size),false,tint)
static func draw(c:CanvasItem,id:String,p:Vector2,pose:Variant=0,height:float=0,tint:Color=Color.WHITE)->void:
 var tex=texture(id,pose)
 if tex==null:return
 var m:Dictionary=metadata[id];var scale=(float(m.world_height) if height<=0 else height)/float(m.visible_height);var size=Vector2.ONE*80*scale
 c.draw_texture_rect(tex,Rect2(p-size*Vector2(.5,.925),size),false,tint)
static func draw_in_rect(c:CanvasItem,id:String,pose:Variant,rect:Rect2,tint:Color=Color.WHITE)->void:
 prepare()
 if not metadata.has(id):return
 var b:Array=metadata[id].old_normalized;var height=rect.size.y*(float(b[3])-float(b[1]));var foot=rect.position+rect.size*Vector2((float(b[0])+float(b[2]))*.5,float(b[3]))
 draw(c,id,foot,pose,height,tint)
static func quest_key(key:String)->Array:
 for suffix in ["_idle","_walk1","_walk2","_attack","_hurt","_0","_1"]:
  if key.ends_with(suffix):
   var id=key.trim_suffix(suffix)
   if id in ["briar_bandit","glowcap_slinger","rootbound_keeper","rootwarden","frostling","ice_archer","summit_golem","sluice_beetle","tidebinder","inkfin"]:return [id,suffix.trim_prefix("_")]
 return []
static func cave_pose(e:Dictionary)->int:
 if float(e.get("collapse",0))>0:return 0
 if float(e.get("strike",0))>0:return 3
 if not str(e.get("action","")).is_empty():return 3 if 1-float(e.get("left",0))/maxf(.01,float(e.get("total",1)))>.35 else 0
 if float(e.get("moving",0))>.05:return 1 if posmod(int(float(e.get("gait",0))/TAU*2),2)==0 else 2
 return 0
static func draw_cave(c:CanvasItem,e:Dictionary,alpha:float)->bool:
 prepare();var id=str(e.get("kind",""))
 if not metadata.has(id):return false
 var m:Dictionary=metadata[id];var offset=Vector2(m.offset[0],m.offset[1]);var tint=Color(1,1,1,alpha)
 if float(e.get("hurt",0))>0:tint=Color(1,.65,.57,alpha)
 elif bool(e.get("enraged",false)):tint=Color(1,.76,.59,alpha)
 draw(c,id,e.pos+offset,cave_pose(e),0,tint);return true
