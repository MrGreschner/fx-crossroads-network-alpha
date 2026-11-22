extends RefCounted
const Polish=preload("res://scripts/visual_polish309.gd")
## Training-only presentation. Every original interaction/collider remains authoritative.
static var textures:Dictionary={}
static var frames:Dictionary={}
static var manifest:Dictionary={}
static var placements:Array=[]
static var pages:Array=[]
static var visible_pages=0
static var visible_props=0
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/training303/manifest.json"))
 placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/training303/placements.json"))

static func texture(id:String)->Texture2D:
 if not textures.has(id):
  var im=Image.new()
  if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/training303/"+id+".png"))!=OK:return null
  var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;t.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED;textures[id]=t
 return textures[id]
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var m=manifest[id];var b=m.region;var t=AtlasTexture.new();t.atlas=texture(str(m.get("texture","props")));t.region=Rect2(b[0],b[1],b[2],b[3]);frames[id]=t
 return frames[id]
static func bounds(p:Dictionary)->Rect2:
 return Polish.yard_rect(str(p.kind),Vector2(p.pos[0],p.pos[1]),Vector2(p.anchor[0],p.anchor[1]))
static func draw(g:Node2D,cam:Vector2)->void:
 prepare();visible_pages=0;visible_props=0
 var view=Rect2(cam,g.VIEW).grow(180)
 # Retained grass outskirts, connected earth paths and one small timber work deck.
 preload("res://scripts/training_floor376.gd").sync(g,cam,texture("grass"),texture("gravel"),texture("planks"))
 visible_pages=1
 for flat in [true,false]:
  for p in placements:
   if bool(p.flat)!=flat or bool(p.flat):continue
   var r=bounds(p)
   if not view.intersects(r):continue
   var alpha=.25 if not flat and r.grow(20).has_point(g.position_in_world) else 1.0
   g.draw_texture_rect(Polish.yard_texture(str(p.kind)),Rect2(r.position-cam,r.size),false,Color(1,1,1,alpha));visible_props+=1
static func exit_art(c:CanvasItem,p:Vector2)->void:
 # Keep the existing walk-out opening and text, without a portal or a new wall.
 for y in [-125,120]:
  c.draw_texture_rect(Polish.yard_texture("fence_end"),Polish.yard_rect("fence_end",p+Vector2(5,y+23)),false)
 c.draw_texture_rect(Polish.yard_texture("exit_sign"),Polish.yard_rect("exit_sign",p+Vector2(50,-42)),false)
 c.draw_string(ThemeDB.fallback_font,p+Vector2(26,-68),"TO TOWN",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("#f2e3bc"))
 c.draw_string_outline(ThemeDB.fallback_font,p+Vector2(-65,88),"TRAINING YARD EXIT",HORIZONTAL_ALIGNMENT_LEFT,-1,13,3,Color("#344b40"))
 c.draw_string(ThemeDB.fallback_font,p+Vector2(-65,88),"TRAINING YARD EXIT",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#f2e3bc"))
