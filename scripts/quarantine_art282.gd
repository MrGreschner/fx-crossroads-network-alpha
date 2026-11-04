extends RefCounted
## Hollow Quarantine scenery only. All raised props reuse original circular obstacle anchors.
static var textures:Dictionary={}
static var frames:Dictionary={}
static var manifest:Dictionary={}
static var placements:Array=[]
static var visible_props=0
static var visible_pages=0
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new();var err=im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/quarantine282/"+id+".png"))
 if err!=OK:push_error("Quarantine scenery unavailable: "+id);return null
 var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;textures[id]=t;return t
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/quarantine282/manifest.json"));placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/quarantine282/placements.json"))
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var a=manifest[id].region;var t=AtlasTexture.new();t.atlas=texture("props");t.region=Rect2(a[0],a[1],a[2],a[3]);frames[id]=t
 return frames[id]
static func bounds(p:Dictionary)->Rect2:return Rect2(Vector2(p.pos[0],p.pos[1])-Vector2(p.size[0]*.5,p.size[1]*.9375),Vector2(p.size[0],p.size[1]))
static func draw(c:Node2D,cam:Vector2)->void:
 if c.adventure.between_guardians():return
 prepare();var view=Rect2(cam,c.VIEW).grow(180);visible_props=0;visible_pages=0
 c.draw_rect(Rect2(-cam,Vector2(8500,1450)),Color("#68705a"))
 for n in 5:
  var r=Rect2(n*1700,0,1700,1450)
  if view.intersects(r):c.draw_texture_rect(texture("ground"+str(n)),Rect2(r.position-cam,r.size),false);visible_pages+=1
 var people:Array=c.adventure.points().values()
 var clock=float(c.get("visual_clock")) if c.get("visual_clock")!=null else float(c.get("visual_time")) if c.get("visual_time")!=null else 0.0
 for p in placements:
  if p.layer!="hardware":continue
  var r=bounds(p)
  if not view.intersects(r):continue
  visible_props+=1;var tint=Color.WHITE
  for hero in people:
   if r.grow(-10).has_point(hero):tint.a=.40
  c.draw_texture_rect(frame(p.kind),Rect2(r.position-cam,r.size),false,tint)
  var q=Vector2(p.pos[0],p.pos[1])-cam-Vector2(0,p.size[1]*.58)
  if p.kind in ["cordon_beacon","portable_generator","sample_incubator"]:
   var lit=.45+.2*sin(clock*1.4+float(p.pos[0])*.004)
   c.draw_rect(Rect2(q-Vector2(2,2),Vector2(4,4)),Color(.87,.70,.35,lit*tint.a))
  elif p.kind in ["filter_column","vent_stack"]:
   for n in 2:
    var rise=fposmod(clock*9+n*19,35);var at=q+Vector2(sin(clock*.7+n)*3,-rise)
    c.draw_line(at,at+Vector2(3,-3),Color(.75,.78,.64,(1-rise/35)*.20*tint.a),1.0,false)
 # Sparse local motes remain outside the central combat/telegraph lane. No full-screen fog.
 for n in 24:
  var at=Vector2(580+n*317+sin(clock*.35+n)*6,(120 if n%2==0 else 1320)+sin(clock*.5+n*1.3)*9)
  if view.has_point(at):c.draw_rect(Rect2(at-cam,Vector2(2,2)),Color(.79,.79,.48,.18+.1*sin(clock+n)))
 var labels=[[Vector2(320,520),"ARRIVAL CORDON"],[Vector2(1840,520),"TRIAGE WARD"],[Vector2(3550,520),"FILTERWORKS"],[Vector2(5330,520),"RECLAIMED WARD"],[Vector2(7130,520),"DIRECTOR CHECKPOINT"]]
 for entry in labels:
  if view.has_point(entry[0]):c.draw_string_outline(ThemeDB.fallback_font,entry[0]-cam,entry[1],HORIZONTAL_ALIGNMENT_LEFT,-1,15,2,Color("#35443c"));c.draw_string(ThemeDB.fallback_font,entry[0]-cam,entry[1],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e2d5ac"))
