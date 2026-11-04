extends RefCounted
## Ebonwake scenery only. v43 owns the citadel's floors, pillars and every encounter.
static var manifest:Dictionary={}
static var textures:Dictionary={}
static var frames:Dictionary={}
static var placements:Array=[]
static var pages:Array=[]
static var geometry:Dictionary={}
static var checked_instance:int=0
static var compatible:bool=false
static var page_budget:int=18
static var visible_pages:int=0
static var visible_props:int=0
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ebon296/manifest.json"))
 placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ebon296/placements.json"))
 pages=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ebon296/pages.json"))
 geometry=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ebon296/geometry.json"))
static func matches(w:Node)->bool:
 prepare()
 if checked_instance==w.get_instance_id():return compatible
 checked_instance=w.get_instance_id();compatible=false
 if w.ROOMS.size()!=geometry.rooms.size() or w.pillars.size()!=geometry.pillars.size():return false
 for n in geometry.rooms.size():
  var r:Array=geometry.rooms[n]
  if w.ROOMS[n]!=Rect2(r[0],r[1],r[2],r[3]):return false
 for n in geometry.pillars.size():
  var p:Array=geometry.pillars[n]
  if w.pillars[n]!=Vector2(p[0],p[1]):return false
 compatible=true;return true
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/ebon296/"+id+".png"))!=OK:return null
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
 var anchor:Array=p.get("anchor",[.5,.94])
 return Rect2(Vector2(p.pos[0],p.pos[1])-Vector2(p.size[0]*anchor[0],p.size[1]*anchor[1]),Vector2(p.size[0],p.size[1]))
static func draw(w:Node,c:Node2D,cam:Vector2)->bool:
 if not matches(w):return false
 var game:Node=w.adventure.game
 var size:Vector2=game.VIEW
 var view=Rect2(cam,size).grow(210)
 page_budget=pages.size() if w.adventure.arcade and game.spectating() else 18
 visible_pages=0;visible_props=0
 var clock:float=w.clock
 c.draw_rect(Rect2(Vector2.ZERO,size),Color("#142630"))
 var sea=texture("black_sea")
 for x in range(floori(cam.x/384),ceili((cam.x+size.x)/384)):
  for y in range(floori(cam.y/384),ceili((cam.y+size.y)/384)):
   c.draw_texture_rect(sea,Rect2(Vector2(x*384,y*384)-cam,Vector2(384,384)),false)
 # Tiny sea glints sit only on non-walkable water and never cover combat warnings.
 for k in 18:
  var point=Vector2(fposmod(k*521.0+clock*5,9000),fposmod(k*337.0+sin(clock*.12+k)*12,6600))
  if view.has_point(point) and not w.floor_at(point):
   c.draw_line(point-cam,point-cam+Vector2(11,0),Color(.4,.62,.66,.10+.05*sin(clock*.6+k)),1)
 for p in pages:
  var r=Rect2(p.x,p.y,p.w,p.h)
  if view.intersects(r):c.draw_texture_rect(texture(p.id),Rect2(r.position-cam,r.size),false);visible_pages+=1
 # Flat inlays first, furnishings and walls next. Tall art fades over every party member.
 for category in [true,false]:
  for p in placements:
   if (str(p.category)=="flat")!=category:continue
   var r=bounds(p)
   if not view.intersects(r):continue
   visible_props+=1
   var alpha:float=1.0
   if bool(p.get("fade",true)):
    for hero in w.adventure.points().values():
     if r.grow(25).has_point(hero):alpha=.22
   c.draw_texture_rect(frame(p.kind),Rect2(r.position-cam,r.size),false,Color(1,1,1,alpha))
   var at=Vector2(p.pos[0],p.pos[1])-cam-Vector2(0,p.size[1]*.54)
   if p.kind in ["lantern","ward_lamp"]:
    c.draw_circle(at,4+sin(clock*.8+float(p.pos[0])*.01),Color(.65,.83,.7,.16*alpha))
   elif p.kind=="crucible":
    c.draw_line(at-Vector2(4,0),at+Vector2(4,sin(clock*1.4+float(p.pos[1]))),Color(.82,.53,.3,.22*alpha),1.5)
   elif p.kind=="banner":
    c.draw_line(at,at+Vector2(sin(clock*.65+float(p.pos[0])*.01)*2,12),Color(.68,.58,.50,.22*alpha),1)
 var names=["SEA GATE","THE UNQUIET INFIRMARY","BROOD RELIQUARIES","CHRYSALIS FORGE","THE LAST COURT"]
 for n in 5:
  var room:Rect2=w.ROOMS[n]
  var point=Vector2(room.position.x+room.size.x*.5,room.position.y+80)
  if not view.has_point(point):continue
  var font=ThemeDB.fallback_font
  var label_size=font.get_string_size(names[n],HORIZONTAL_ALIGNMENT_LEFT,-1,18)
  c.draw_rect(Rect2(point-cam-Vector2(label_size.x*.5+12,22),Vector2(label_size.x+24,30)),Color(.08,.12,.16,.85))
  c.draw_string(font,point-cam-Vector2(label_size.x*.5,0),names[n],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#e3d6b8"))
 return true
