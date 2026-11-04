extends RefCounted
## Decorative Crossbell environment only. Authoritative school JSON is unchanged.
static var textures:Dictionary={}
static var frames:Dictionary={}
static var manifest:Dictionary={}
static var placements:Array=[]
static var visible_props=0
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new();var code=im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/crossbell274/"+id+".png"))
 if code!=OK:push_error("Crossbell art unavailable: "+id);return null
 var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;textures[id]=t;return t
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/crossbell274/manifest.json"));placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/crossbell274/placements.json"))
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var a=manifest[id].region;var t=AtlasTexture.new();t.atlas=texture("props");t.region=Rect2(a[0],a[1],a[2],a[3]);frames[id]=t
 return frames[id]
static func bounds(p:Dictionary)->Rect2:return Rect2(Vector2(p.pos[0],p.pos[1])-Vector2(p.size[0]*.5,p.size[1]*.9375),Vector2(p.size[0],p.size[1]))
static func view(c:Node2D,cam:Vector2)->Rect2:return Rect2(cam,c.get_viewport_rect().size).grow(180)
static func draw(w:Node,c:Node2D,cam:Vector2)->void:
 prepare();var viewport=view(c,cam);visible_props=0;c.draw_rect(Rect2(-cam,Vector2(8600,7000)),Color("#263947"))
 for n in 4:
  var r=Rect2(Vector2(n%2*4300,int(n/2)*3500),Vector2(4300,3500))
  if viewport.intersects(r):c.draw_texture_rect(texture("ground"+str(n)),Rect2(r.position-cam,r.size),false)
 var people:Array=w.adventure.points().values()
 for p in placements:
  var r=bounds(p);var id=str(p.kind)
  if not viewport.intersects(r):continue
  visible_props+=1;var tint=Color.WHITE
  if id in ["entrance","bell_tower","bookshelf","locker","trophies","noticeboard","terrarium","aquarium"]:
   for hero in people:
    if r.grow(-12).has_point(hero):tint.a=.35
  c.draw_texture_rect(frame(id),Rect2(r.position-cam,r.size),false,tint)
 # School identity and wing labels sit above the routes, with no opaque banner over fighting.
 for room in w.data.rooms:
  if str(room.name).is_empty():continue
  var r:Rect2=w.rect(room.rect);var at=r.position+Vector2(35,80)
  if viewport.has_point(at):c.draw_string_outline(ThemeDB.fallback_font,at-cam,str(room.name),HORIZONTAL_ALIGNMENT_LEFT,-1,20,3,Color("#263943"));c.draw_string(ThemeDB.fallback_font,at-cam,str(room.name),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#e6d5ae"))
 var sign_at=Vector2(2750,4100)-cam
 if viewport.has_point(Vector2(2750,4100)):c.draw_string_outline(ThemeDB.fallback_font,sign_at-Vector2(180,0),"CROSSBELL MIDDLE SCHOOL",HORIZONTAL_ALIGNMENT_CENTER,360,21,3,Color("#263943"));c.draw_string(ThemeDB.fallback_font,sign_at-Vector2(180,0),"CROSSBELL MIDDLE SCHOOL",HORIZONTAL_ALIGNMENT_CENTER,360,21,Color("#e6d5ae"))
static func overlay(w:Node,c:Node2D,cam:Vector2)->void:
 var viewport=view(c,cam)
 for p in placements:
  var id=str(p.kind);var r=bounds(p)
  if not viewport.intersects(r):continue
  if id=="chemistry":
   for n in 3:
    var q=r.position+r.size*Vector2(.35+n*.16,.35)-cam-Vector2(0,fposmod(w.clock*7+n*13,26));c.draw_circle(q,1.6,Color(.62,.86,.76,.35))
  elif id=="aquarium":
   for n in 3:
    var q=r.position+r.size*Vector2(.35+n*.14,.40)-cam+Vector2(sin(w.clock*.8+n)*7,sin(w.clock+n)*3);c.draw_line(q,q+Vector2(3,0),Color(1,.72,.31,.55),2,true)
  elif id=="orrery":
   var q=r.position+r.size*Vector2(.5,.37)-cam;c.draw_arc(q,17,w.clock*.2,w.clock*.2+PI*.65,16,Color(.89,.75,.39,.45),1.4,true)
  elif id=="clock":
   var q=r.position+r.size*Vector2(.5,.44)-cam;c.draw_line(q,q+Vector2.from_angle(w.clock*.1-PI*.5)*8,Color("#7c6854"),1.4,true)
  elif id=="bell_winch":
   var q=r.position+r.size*Vector2(.52,.46)-cam;c.draw_line(q,q+Vector2(sin(w.clock*.8)*1.5,30),Color(.75,.65,.44,.6),2,true)
  elif id=="planter" and r.position.x>5500:
   var q=r.position+r.size*Vector2(.47,.4)-cam;c.draw_line(q,q+Vector2(sin(w.clock*.7+r.position.x)*2,-4),Color(.55,.66,.45,.45),2,true)
