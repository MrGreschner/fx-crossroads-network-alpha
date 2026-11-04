extends RefCounted
## Lantern Glade: presentation uses the original First Steps scene and collision.
static var manifest:Dictionary={}
static var placements:Array=[]
static var pages:Array=[]
static var textures:Dictionary={}
static var frames:Dictionary={}
static func enabled(g:Node)->bool:return g.mode=="run" and g.region_id=="first_steps"
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/first299/manifest.json"))
 placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/first299/placements.json"))
 placements.sort_custom(func(a,b):return float(a.pos[1])<float(b.pos[1]))
 pages=JSON.parse_string(FileAccess.get_file_as_string("res://assets/first299/pages.json"))
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/first299/"+id+".png"))!=OK:return null
 var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;textures[id]=t;return t
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var m:Dictionary=manifest[id];var r:Array=m.region;var t=AtlasTexture.new();t.atlas=texture(str(m.get("texture","props")));t.region=Rect2(r[0],r[1],r[2],r[3]);frames[id]=t
 return frames[id]
static func draw(g:Node,c:CanvasItem,cam:Vector2)->void:
 if not enabled(g):return
 prepare()
 var view=Rect2(cam,g.VIEW).grow(220)
 c.draw_rect(Rect2(Vector2.ZERO,g.VIEW),Color("#253b37"))
 for page in pages:
  var r=Rect2(page.x,page.y,page.w,page.h)
  if view.intersects(r):c.draw_texture_rect(texture(page.id),Rect2(r.position-cam,r.size),false)
 for flat in [true,false]:
  for p in placements:
   if bool(p.flat)!=flat:continue
   var r=Rect2(Vector2(p.pos[0],p.pos[1])-Vector2(p.size[0]*p.anchor[0],p.size[1]*p.anchor[1]),Vector2(p.size[0],p.size[1]))
   if not view.intersects(r):continue
   var alpha:float=1.0
   if not flat and r.grow(25).has_point(g.position_in_world) and p.kind!="beacon_crystal":alpha=.24
   c.draw_texture_rect(frame(p.kind),Rect2(r.position-cam,r.size),false,Color(1,1,1,alpha))
 # Sparse moving leaves and warm dust add life without lighting or particle nodes.
 for n in 14:
  var p=Vector2(fposmod(n*173+g.visual_clock*8,1800),170+fposmod(n*139+sin(g.visual_clock*.4+n)*10,900))
  if view.has_point(p):c.draw_line(p-cam,p-cam+Vector2(4,2),Color(.93,.84,.54,.2),2)
 var title="LANTERN GLADE";var font=ThemeDB.fallback_font;var p=Vector2(950,304)-cam
 if view.has_point(Vector2(950,304)) and (not g.tutorial.active or g.tutorial.wave<4):
  var w=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x
  c.draw_style_box(preload("res://scripts/studio_ui.gd").box("#29443f","#b8b58a",6,2),Rect2(p-Vector2(w*.5+12,25),Vector2(w+24,33)))
  c.draw_string(font,p-Vector2(w*.5,2),title,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#f0dfaf"))
