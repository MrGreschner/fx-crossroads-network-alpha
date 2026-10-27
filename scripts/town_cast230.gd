extends RefCounted
## One shared atlas, three poses per person. No per-frame image manipulation.
static var metadata:Dictionary={}
static var sheet:Texture2D
static var frames:Dictionary={}
static func prepare()->void:
 if sheet!=null:return
 metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/town230/manifest230.json"))
 var path="res://assets/town230/citizens.png"
 if ResourceLoader.exists(path):sheet=load(path)
 if sheet==null:
  var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes(path));sheet=ImageTexture.create_from_image(im)
static func phase(moving:bool,time:float)->int:return 1+posmod(int(time*5.5),2) if moving else 0
static func texture(id:String,pose:int=0)->Texture2D:
 prepare();var key=id+":"+str(clampi(pose,0,2))
 if not metadata.has(id):return null
 if not frames.has(key):
  var atlas=AtlasTexture.new();atlas.atlas=sheet;atlas.region=Rect2(clampi(pose,0,2)*80,int(metadata[id].index)*80,80,80);frames[key]=atlas
 return frames[key]
static func draw(c:CanvasItem,id:String,point:Vector2,time:float=0,moving:bool=false,scale:float=1)->void:
 prepare()
 if not metadata.has(id) or not Rect2(Vector2.ZERO,c.get_viewport_rect().size).grow(130).has_point(point):return
 var size=Vector2.ONE*80*float(metadata[id].scale)*scale
 c.draw_texture_rect(texture(id,phase(moving,time)),Rect2(point-size*Vector2(.5,.925),size),false)
