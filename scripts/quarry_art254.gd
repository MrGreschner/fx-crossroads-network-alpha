extends RefCounted
## Realm-specific cached textures. No encounter, hitbox, damage or movement changes.
static var cache:Dictionary={}
static var frames:Dictionary={}
static var metadata:Dictionary={}
static func texture(id:String)->Texture2D:
 if cache.has(id):return cache[id]
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/quarry254/"+id+".png"))!=OK:return null
 var result=ImageTexture.create_from_image(im);cache[id]=result;return result
static func grove_tree(p:Vector2)->Texture2D:
 var n=1 if posmod(int(p.x*7+p.y*11),3)==0 else 0;var key="grove"+str(n)
 if not frames.has(key):
  var t=AtlasTexture.new();t.atlas=texture("trees");t.region=Rect2(n*192,0,192,252);frames[key]=t
 return frames[key]
static func pose_index(pose:String)->int:return 3 if pose in ["attack","attack2","special"] else 1 if pose in ["walk1","1"] else 2 if pose in ["walk2","2"] else 0
static func boss(pose:String)->Texture2D:
 var n=pose_index(pose)
 if not frames.has(n):
  var t=AtlasTexture.new();t.atlas=texture("boss");t.region=Rect2(n*80,0,80,80);frames[n]=t
 return frames[n]
static func boss_rect(rect:Rect2)->Rect2:
 if metadata.is_empty():metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/quarry254/manifest.json"))
 var b:Array=metadata.boss_original_bounds
 var adjusted=preload("res://scripts/enemy_visual227.gd").adjusted("bramble_boss",rect)
 var height=adjusted.size.y*(b[3]-b[1]);var foot=adjusted.position+adjusted.size*Vector2((b[0]+b[2])*.5,b[3]);var size=Vector2.ONE*80*height/float(metadata.boss_visible_height)
 return Rect2(foot-size*Vector2(.5,.925),size)
static func draw_boss(c:CanvasItem,pose:String,rect:Rect2,tint:Color=Color.WHITE)->void:c.draw_texture_rect(boss(pose),boss_rect(rect),false,tint)
