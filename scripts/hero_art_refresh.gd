extends RefCounted
## Explicit source rectangles: the generated sheet is not a uniform sprite grid.
## Every pose shares a centred face and a 60/64 foot baseline at roster scale.
static var poses:Dictionary={}
const FRAMES={
 "idle":{"region":Rect2(222,117,370,445),"centre":385.0},
 "walk1":{"region":Rect2(783,121,372,441),"centre":945.0},
 "walk2":{"region":Rect2(220,664,372,437),"centre":385.0},
 "attack":{"region":Rect2(771,664,420,435),"centre":949.0}}
static func texture(sprite:String,pose:String)->Texture2D:
 if sprite in ["ram","cat","book","elder_ram"]:return preload("res://scripts/core_hero_art.gd").texture(sprite,pose)
 if sprite in ["golfer","dawnblade","lumen","elara","echo_dancer","chronicle","hazel_hex"]:
  var pixel_pose="idle" if pose=="0" else "walk1" if pose=="1" else pose
  if pixel_pose in ["idle","walk1","walk2","attack","attack2","special"]:
   var pixel_key="pixel:"+sprite+":"+pixel_pose
   if not poses.has(pixel_key):
    var image=Image.new()
    if image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/pixel_198_7/"+sprite+"_"+pixel_pose+".png"))!=OK:return null
    poses[pixel_key]=ImageTexture.create_from_image(image)
   return poses[pixel_key]
 if sprite in ["golfer","welder","tempo","ferryman"]:
  var pixel_pose="idle" if pose=="0" else "walk1" if pose=="1" else pose
  if pixel_pose in ["idle","walk1","walk2","attack","attack2","special"]:
   var pixel_key="pixel:"+sprite+":"+pixel_pose
   if not poses.has(pixel_key):
    var image=Image.new()
    if image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/pixel_198_4/"+sprite+"_"+pixel_pose+".png"))!=OK:return null
    poses[pixel_key]=ImageTexture.create_from_image(image)
   return poses[pixel_key]
 if sprite in ["twisterspell","dustmarshal","dawnblade"]:
  var pixel_pose="idle" if pose=="0" else "walk1" if pose=="1" else pose
  if pixel_pose in ["idle","walk1","walk2","attack","attack2","special"]:
   var pixel_key="pixel:"+sprite+":"+pixel_pose
   if not poses.has(pixel_key):
    var image=Image.new()
    if image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/pixel_198_3/"+sprite+"_"+pixel_pose+".png"))!=OK:return null
    poses[pixel_key]=ImageTexture.create_from_image(image)
   return poses[pixel_key]
 if sprite in ["rune_duelist","dustdevil","merrymask"]:
  var pixel_pose="idle" if pose=="0" else "walk1" if pose=="1" else pose
  if pixel_pose in ["idle","walk1","walk2","attack","attack2","special"]:
   var pixel_key="pixel:"+sprite+":"+pixel_pose
   if not poses.has(pixel_key):
    var image=Image.new()
    if image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/pixel_198_2/"+sprite+"_"+pixel_pose+".png"))!=OK:return null
    poses[pixel_key]=ImageTexture.create_from_image(image)
   return poses[pixel_key]
 var pixel_heroes=["cairnheart","cloudloom","stormscribe","baseball","veyra","tova","votary","hearthwarden"]
 if sprite in pixel_heroes:
  var pixel_pose="idle" if pose=="0" else "walk1" if pose=="1" else pose
  if pixel_pose in ["idle","walk1","walk2","attack","attack2","special"]:
   var pixel_key="pixel:"+sprite+":"+pixel_pose
   if not poses.has(pixel_key):
    var image=Image.new()
    if image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/pixel_198_1/"+sprite+"_"+pixel_pose+".png"))!=OK:return null
    poses[pixel_key]=ImageTexture.create_from_image(image)
   return poses[pixel_key]
 var revised=["golfer", "baseball", "stormscribe", "veyra", "nera", "cloudloom", "cairnheart", "caelum", "wanderlight", "votary", "hearthwarden", "tova"]
 if sprite in revised:
  var mapped="idle" if pose=="0" else "walk1" if pose=="1" else pose
  var path="res://assets/v194_"+sprite+"_"+mapped+".svg"
  if FileAccess.file_exists(path):return preload("res://scripts/source_art.gd").texture(path)
 if sprite!="twisterspell":return null
 var key="idle" if pose=="0" else "walk1" if pose=="1" else pose
 if not FRAMES.has(key):return null
 if not poses.has(key):
  var spec:Dictionary=FRAMES[key];var region:Rect2=spec.region
  var canvas=Vector2.ONE*(region.size.y*64.0/58.0)
  var face=float(spec.centre)-region.position.x
  var frame=AtlasTexture.new();frame.atlas=load("res://assets/galeweaver_poses.png");frame.region=region
  frame.margin=Rect2(Vector2(canvas.x*.5-face,canvas.y*60.0/64.0-region.size.y),canvas-region.size)
  frame.filter_clip=true;poses[key]=frame
 return poses[key]
