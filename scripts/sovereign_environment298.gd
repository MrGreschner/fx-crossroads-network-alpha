extends RefCounted
## Visual layer only. The original finale retains collision, illumination and combat.
static var manifest:Dictionary={}
static var placements:Array=[]
static var pages:Array=[]
static var geometry:Dictionary={}
static var textures:Dictionary={}
static var frames:Dictionary={}
static var page_budget:int=12
static var visible_pages:int=0
static var visible_props:int=0
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/sovereign298/manifest.json"))
 placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/sovereign298/placements.json"))
 pages=JSON.parse_string(FileAccess.get_file_as_string("res://assets/sovereign298/pages.json"))
 geometry=JSON.parse_string(FileAccess.get_file_as_string("res://assets/sovereign298/geometry.json"))
static func enabled(f:RefCounted)->bool:
 if not f.in_depth():return false
 prepare()
 if f.FLOORS.size()!=geometry.floors.size():return false
 for n in f.FLOORS.size():
  var a:Array=geometry.floors[n]
  if f.FLOORS[n]!=Rect2(a[0],a[1],a[2],a[3]):return false
 var a:Array=geometry.arena
 return f.ARENA==Rect2(a[0],a[1],a[2],a[3])
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/sovereign298/"+id+".png"))!=OK:return null
 if id.begins_with("ground_"):
  var keys:Array=[]
  for key in textures:
   if str(key).begins_with("ground_"):keys.append(key)
  if keys.size()>=page_budget:textures.erase(keys[0])
 var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;textures[id]=t;return t
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var m:Dictionary=manifest[id];var r:Array=m.region;var t=AtlasTexture.new();t.atlas=texture(str(m.get("texture","props")));t.region=Rect2(r[0],r[1],r[2],r[3]);frames[id]=t
 return frames[id]
static func bounds(p:Dictionary)->Rect2:
 return Rect2(Vector2(p.pos[0],p.pos[1])-Vector2(p.size[0]*p.anchor[0],p.size[1]*p.anchor[1]),Vector2(p.size[0],p.size[1]))
static func draw(f:RefCounted,c:CanvasItem,cam:Vector2)->bool:
 if not enabled(f):return false
 var game:Node=f.adventure.game
 var view=Rect2(cam,game.VIEW).grow(190)
 page_budget=pages.size() if f.adventure.arcade and game.spectating() else 12
 visible_pages=0;visible_props=0
 c.draw_rect(Rect2(Vector2.ZERO,game.VIEW),Color("#020308"))
 # The void remains dark. No new light sources reveal or obscure hazard positions.
 for page in pages:
  var r=Rect2(page.x,page.y,page.w,page.h)
  if view.intersects(r):c.draw_texture_rect(texture(page.id),Rect2(r.position-cam,r.size),false);visible_pages+=1
 for flat in [true,false]:
  for p in placements:
   if (str(p.category)=="flat")!=flat:continue
   var r=bounds(p)
   if not view.intersects(r):continue
   visible_props+=1
   var alpha:float=.22 if flat else 1.0
   if bool(p.fade):
    for hero in f.adventure.points().values():
     if r.grow(35).has_point(hero):alpha=.2
   c.draw_texture_rect(frame(p.kind),Rect2(r.position-cam,r.size),false,Color(1,1,1,alpha))
   var at=Vector2(p.pos[0],p.pos[1])-cam-Vector2(0,p.size[1]*.54)
   # Small animated accents stay within prop silhouettes and under the retained fog.
   if p.kind in ["depth_lantern","coal_brazier","memorial_candles"]:
    c.draw_circle(at,2.5+sin(f.visual_clock()*.9+float(p.pos[0])*.01)*.6,Color(.94,.68,.35,.22*alpha))
   elif p.kind=="bronze_chimes":
    c.draw_line(at,at+Vector2(sin(f.visual_clock()*.6)*2,7),Color(.82,.72,.49,.18*alpha),1)
 if f.mode=="won":
  var r=Rect2(f.EXIT-cam-Vector2(46,80),Vector2(92,92))
  c.draw_texture_rect(frame("victory_beacon"),r,false,Color(1,1,1,.65))
 return true
