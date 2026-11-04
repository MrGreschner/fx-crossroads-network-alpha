extends RefCounted
## Presentation for the four trials, Nexus and Usurper court. Existing adventure owns all mechanics.
static var manifest:Dictionary={}
static var placements:Array=[]
static var pages:Array=[]
static var geometry:Dictionary={}
static var textures:Dictionary={}
static var frames:Dictionary={}
static var page_budget:int=18
static var visible_pages:int=0
static var visible_props:int=0
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/oath297/manifest.json"))
 placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/oath297/placements.json"))
 pages=JSON.parse_string(FileAccess.get_file_as_string("res://assets/oath297/pages.json"))
 geometry=JSON.parse_string(FileAccess.get_file_as_string("res://assets/oath297/geometry.json"))
static func enabled(w:Node)->bool:
 if not w.active or w.finale.in_depth():return false
 prepare()
 if w.trials.size()!=4:return false
 for n in 4:
  if w.trials[n].origin!=geometry.origins[n]:return false
 return true
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/oath297/"+id+".png"))!=OK:return null
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
static func draw(w:Node,c:Node2D,cam:Vector2)->bool:
 if not enabled(w):return false
 var game:Node=w.game
 var size:Vector2=game.VIEW
 var view=Rect2(cam,size).grow(210)
 page_budget=pages.size() if w.arcade and game.spectating() else 18
 visible_pages=0;visible_props=0
 c.draw_rect(Rect2(Vector2.ZERO,size),Color("#171e2c"))
 # Slow, sparse dust marks in the void; no bright field competing with timed traps.
 for k in 16:
  var p=Vector2(fposmod(k*977.0+w.clock*4,14000),fposmod(k*653.0+sin(w.clock*.13+k)*14,8120))
  if view.has_point(p) and not w.can_stand(p):c.draw_line(p-cam,p-cam+Vector2(10,0),Color(.59,.60,.70,.12),1)
 for p in pages:
  var r=Rect2(p.x,p.y,p.w,p.h)
  if view.intersects(r):c.draw_texture_rect(texture(p.id),Rect2(r.position-cam,r.size),false);visible_pages+=1
 # Static floor inlays before raised scenery. All party members get occlusion fading.
 for flat in [true,false]:
  for p in placements:
   if (str(p.category)=="flat")!=flat:continue
   var r=bounds(p)
   if not view.intersects(r):continue
   visible_props+=1
   var alpha:float=1.0
   if bool(p.fade):
    for hero in w.points().values():
     if r.grow(30).has_point(hero):alpha=.22
   c.draw_texture_rect(frame(p.kind),Rect2(r.position-cam,r.size),false,Color(1,1,1,alpha))
   var at=Vector2(p.pos[0],p.pos[1])-cam-Vector2(0,p.size[1]*.5)
   if p.kind in ["briar_lantern","chime_lamp","oath_lantern","brazier"]:
    var tint=Color("#bdce9d") if p.kind=="briar_lantern" else Color("#b4d6df") if p.kind=="chime_lamp" else Color("#efc784")
    c.draw_circle(at,3+sin(w.clock*.9+float(p.pos[0])*.01),Color(tint,.18*alpha))
   elif p.kind in ["storm_coil","storm_globe","mirror_frame"]:
    c.draw_line(at-Vector2(3,0),at+Vector2(3,sin(w.clock*.7+float(p.pos[1]))*2),Color(.69,.80,.88,.25*alpha),1.5)
   elif p.kind=="oath_banner":
    c.draw_line(at,at+Vector2(sin(w.clock*.65+float(p.pos[0])*.01)*2,10),Color(.64,.55,.7,.25*alpha),1)
 var names=["BRIAR RELIQUARY","CINDER CAUSEWAY","MIRRORFROST GALLERY","STORMGLASS SPIRE","THE FRACTURED NEXUS","THE USURPER'S COURT"]
 for n in geometry.rooms.size():
  var r:Array=geometry.rooms[n];var p=Vector2(r[0]+r[2]*.5,r[1]+100)
  if not view.has_point(p):continue
  var font=ThemeDB.fallback_font;var label=font.get_string_size(names[n],HORIZONTAL_ALIGNMENT_LEFT,-1,18)
  c.draw_rect(Rect2(p-cam-Vector2(label.x*.5+12,22),Vector2(label.x+24,30)),Color(.08,.11,.16,.88))
  c.draw_string(font,p-cam-Vector2(label.x*.5,0),names[n],HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#e4d6bc"))
 return true
