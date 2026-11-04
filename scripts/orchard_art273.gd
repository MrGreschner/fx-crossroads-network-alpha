extends RefCounted
## Environment only. Timers, collision and combat remain authoritative.
static var textures:Dictionary={}
static var frames:Dictionary={}
static var manifest:Dictionary={}
static var placements:Array=[]
static var visible_props=0
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new();var err=im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/orchard273/"+id+".png"))
 if err!=OK:push_error("Orchard art unavailable: "+id);return null
 var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;textures[id]=t;return t
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/orchard273/manifest.json"));placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/orchard273/placements.json"))
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var a=manifest[id].region;var t=AtlasTexture.new();t.atlas=texture("props");t.region=Rect2(a[0],a[1],a[2],a[3]);frames[id]=t
 return frames[id]
static func bounds(p:Dictionary)->Rect2:return Rect2(Vector2(p.pos[0],p.pos[1])-Vector2(p.size[0]*.5,p.size[1]*.9375),Vector2(p.size[0],p.size[1]))
static func viewport(c:Node2D,cam:Vector2)->Rect2:return Rect2(cam,c.get_viewport_rect().size).grow(180)
static func draw(w:Node,c:Node2D,cam:Vector2)->void:
 prepare();var view=viewport(c,cam);visible_props=0;c.draw_rect(Rect2(-cam,Vector2(4320,2520)),Color("#5b6549"))
 for n in 4:
  var r=Rect2(Vector2(n%2*2160,int(n/2)*1260),Vector2(2160,1260))
  if view.intersects(r):c.draw_texture_rect(texture("ground"+str(n)),Rect2(r.position-cam,r.size),false)
 var people:Array=w.adventure.points().values()
 for p in placements:
  var r=bounds(p);var id=str(p.kind)
  if not view.intersects(r):continue
  visible_props+=1
  if p.layer=="tree":
   c.draw_texture_rect_region(frame(id),Rect2(r.position+Vector2(0,r.size.y*.6)-cam,Vector2(r.size.x,r.size.y*.4)),Rect2(0,192,320,128));continue
  if p.layer=="gear":
   var center=r.get_center()-cam;c.draw_set_transform(center,w.clock*(.32 if id=="cog"else-.22));c.draw_texture_rect(frame(id),Rect2(-r.size*.5,r.size),false);c.draw_set_transform(Vector2.ZERO);continue
  var tint=Color.WHITE
  if id in ["greenhouse","shed","arch","tank","boiler","hourglass"]:
   for hero in people:
    if r.grow(-16).has_point(hero):tint.a=.38
  c.draw_texture_rect(frame(id),Rect2(r.position-cam,r.size),false,tint)
 for p in [[Vector2(370,1540),"COPPERROOT NURSERY"],[Vector2(1760,1550),"HARVEST WORKS"],[Vector2(3260,1580),"THE HOURGLASS GROVE"]]:
  if view.has_point(p[0]):c.draw_string_outline(ThemeDB.fallback_font,p[0]-cam,p[1],HORIZONTAL_ALIGNMENT_LEFT,-1,16,3,Color("#38463d"));c.draw_string(ThemeDB.fallback_font,p[0]-cam,p[1],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#eadbb3"))
static func wall(c:Node2D,r:Rect2,cam:Vector2)->void:
 var view=viewport(c,cam)
 for y in range(int(r.position.y),int(r.end.y),128):
  var piece=Rect2(r.position.x,y,r.size.x,minf(128,r.end.y-y))
  if view.intersects(piece):c.draw_texture_rect(texture("wall"),Rect2(piece.position-cam,piece.size),false)
static func overlay(w:Node,c:Node2D,cam:Vector2)->void:
 prepare();var view=viewport(c,cam);var people:Array=w.adventure.points().values()
 for p in placements:
  var r=bounds(p);var id=str(p.kind)
  if not view.intersects(r):continue
  if p.layer=="tree":
   var alpha=.96
   for hero in people:
    if r.grow(15).has_point(hero):alpha=.23
   c.draw_texture_rect_region(frame(id),Rect2(r.position-cam+Vector2(sin(w.clock*.55+r.position.x)*.5,0),Vector2(r.size.x,r.size.y*.6)),Rect2(0,0,320,192),Color(1,1,1,alpha))
  elif id=="boiler":
   for n in 3:
    var t=fposmod(w.clock*.27+n*.33,1);var q=r.position+Vector2(r.size.x*.7,r.size.y*.1)-cam+Vector2(sin(t*4+n)*6,-t*55);c.draw_circle(q,3+t*6,Color(.9,.89,.76,(1-t)*.18))
  elif id=="lantern":c.draw_circle(r.position+Vector2(r.size.x*.65,r.size.y*.4)-cam,3+sin(w.clock*2)*.4,Color(1,.83,.46,.32))
  elif id=="trough":
   var q=r.position+r.size*Vector2(.48,.48)-cam;c.draw_arc(q,8+fposmod(w.clock*9,18),0,PI,18,Color(.65,.84,.79,.28),1.5,true)
 for n in 16:
  var at=Vector2(fposmod(n*353+w.clock*8,4320),fposmod(n*197+w.clock*4,2520))
  if view.has_point(at):c.draw_line(at-cam,at-cam+Vector2(3,1),Color(.75,.56,.29,.35),2,true)
