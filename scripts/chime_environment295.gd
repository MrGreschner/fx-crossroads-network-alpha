extends RefCounted
## The Buried Choir presentation. The original Chimevault remains the authority for every wall and lift.
static var manifest:Dictionary={}
static var textures:Dictionary={}
static var frames:Dictionary={}
static var placements:Array=[]
static var pages:Array=[]
static var geometry:Array=[]
static var checked_instance:int=0
static var compatible:bool=false
static var page_budget:int=18
static var visible_pages:int=0
static var visible_props:int=0
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/chime295/manifest.json"))
 placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/chime295/placements.json"))
 pages=JSON.parse_string(FileAccess.get_file_as_string("res://assets/chime295/pages.json"))
 geometry=JSON.parse_string(FileAccess.get_file_as_string("res://assets/chime295/geometry.json"))
static func matches(w:Node)->bool:
 prepare()
 if checked_instance==w.get_instance_id():return compatible
 checked_instance=w.get_instance_id();compatible=false
 if w.cells.size()!=geometry.size():return false
 for n in geometry.size():
  var d:Dictionary=geometry[n]
  if w.cells[n].size()!=d.open.size() or w.gates[n]!=Vector2(d.gate[0],d.gate[1]):return false
  for cell in d.open:
   if not w.cells[n].has(Vector2i(cell[0],cell[1])):return false
 compatible=true;return true
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/chime295/"+id+".png"))!=OK:return null
 if id.begins_with("ground_"):
  var keys:Array=[]
  for key in textures:
   if str(key).begins_with("ground_"):keys.append(key)
  if keys.size()>=page_budget:textures.erase(keys[0])
 var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;textures[id]=t;return t
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var m:Dictionary=manifest[id];var r=m.region;var t=AtlasTexture.new();t.atlas=texture(str(m.get("texture","props")));t.region=Rect2(r[0],r[1],r[2],r[3]);frames[id]=t
 return frames[id]
static func bounds(p:Dictionary)->Rect2:
 var anchor=p.get("anchor",[.5,.94])
 return Rect2(Vector2(p.pos[0],p.pos[1])-Vector2(p.size[0]*anchor[0],p.size[1]*anchor[1]),Vector2(p.size[0],p.size[1]))
static func draw(w:Node,c:Node2D,cam:Vector2)->bool:
 if not matches(w):return false
 var game:Node=w.adventure.game
 var size:Vector2=game.VIEW
 var view=Rect2(cam,size).grow(210)
 page_budget=pages.size() if w.adventure.arcade and game.spectating() else 18
 visible_pages=0;visible_props=0
 var clock:float=w.adventure.clock
 c.draw_rect(Rect2(-cam,Vector2(9000,2400)),Color("#111b24"))
 for p in pages:
  var r=Rect2(p.x,p.y,p.w,p.h)
  if view.intersects(r):c.draw_texture_rect(texture(p.id),Rect2(r.position-cam,r.size),false);visible_pages+=1
 for p in placements:
  var r=bounds(p)
  if not view.intersects(r):continue
  visible_props+=1
  var alpha:float=1.0
  if bool(p.get("fade",true)):
   for hero in w.adventure.points().values():
    if r.grow(25).has_point(hero):alpha=.24
  c.draw_texture_rect(frame(p.kind),Rect2(r.position-cam,r.size),false,Color(1,1,1,alpha))
  var at=Vector2(p.pos[0],p.pos[1])-cam-Vector2(0,p.size[1]*.52)
  if p.kind in ["lantern","crystal_bell","crystals"]:
   c.draw_circle(at,4+sin(clock*.9+float(p.pos[0])*.01),Color(.68,.8,.70,.16*alpha))
  elif p.kind in ["chimes","mobile"]:
   var swing=sin(clock*.65+float(p.pos[0])*.01)*2.5
   c.draw_line(at+Vector2(swing,-10),at+Vector2(swing,9),Color(.76,.69,.48,.35*alpha),1.5)
  elif p.kind in ["belfry","silent_bell","gong","resonator"]:
   # Small, contained echo glints stay on blocked wall cells; they cannot resemble attack waves.
   var phase=fposmod(clock*.2+float(p.pos[0])*.003,1)
   c.draw_arc(at,5+phase*7,PI*.15,PI*.85,12,Color(.73,.76,.65,(1-phase)*.18*alpha),1)
 # Lift platforms stay flat beneath actors. Existing E/clear-floor interaction cues draw afterward.
 for n in w.gates.size():
  if not view.has_point(w.gates[n]):continue
  if n!=w.stage:continue
  if w.adventure.foes().is_empty():
   var at:Vector2=w.gates[n]-cam
   c.draw_arc(at,41,clock*.6,clock*.6+PI*.8,24,Color(.56,.84,.77,.6),2)
 return true
