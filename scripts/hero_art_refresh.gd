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
