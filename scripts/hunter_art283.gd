extends RefCounted
## Shared front-facing pixel hunters: four authored poses, no body turning or mirroring.
const IDS=["veil_shear","veil_spindle","veil_mourner","veil_prism","veil_hound","veil_scribe","veil_maw","veil_null","veil_warden"]
const HOVER=["veil_spindle","veil_mourner","veil_scribe","veil_null"]
static var atlas:Texture2D
static var frames:Dictionary={}
static func texture(id:String,pose:String="idle")->Texture2D:
 if id not in IDS:return null
 if atlas==null:
  var im=Image.new();var err=im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/hunters283/actors.png"))
  if err!=OK:push_error("Hunter artwork unavailable");return null
  var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;atlas=t
 var p="walk1"if pose=="0"else"walk2"if pose=="1"else pose
 var col=["idle","walk1","walk2","attack"].find(p)
 if col<0:col=0
 var key=id+":"+str(col)
 if not frames.has(key):
  var t=AtlasTexture.new();t.atlas=atlas;t.region=Rect2(col*80,IDS.find(id)*80,80,80);frames[key]=t
 return frames[key]
static func draw(c:Node2D,id:String,pose:String,r:Rect2,clock:float,uid:int=0,tint:Color=Color.WHITE)->void:
 var p=pose;var target=r
 if id in HOVER:
  # Hover animates separate cloth pieces even at rest. Walkers use measured foot-travel poses.
  var phase=fposmod(clock*1.5+uid*.37,2.0)
  if p=="idle":p="walk1"if phase<.45 else"walk2"if phase>1.0 and phase<1.45 else"idle"
  target.position.y+=sin(clock*2.1+uid*.37)*1.6
 c.draw_texture_rect(texture(id,p),target,false,tint)
