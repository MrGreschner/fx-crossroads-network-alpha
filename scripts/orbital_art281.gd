extends RefCounted
## Orbital Breach environment only: immutable scene geometry, no actor drawing or simulation.
static var textures:Dictionary={}
static var frames:Dictionary={}
static var manifest:Dictionary={}
static var placements:Array=[]
static var visible_props=0
static var visible_pages=0
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new();var err=im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/orbital281/"+id+".png"))
 if err!=OK:push_error("Orbital environment unavailable: "+id);return null
 var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;textures[id]=t;return t
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/orbital281/manifest.json"));placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/orbital281/placements.json"))
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var a=manifest[id].region;var t=AtlasTexture.new();t.atlas=texture("props");t.region=Rect2(a[0],a[1],a[2],a[3]);frames[id]=t
 return frames[id]
static func bounds(p:Dictionary)->Rect2:return Rect2(Vector2(p.pos[0],p.pos[1])-Vector2(p.size[0]*.5,p.size[1]*.9375),Vector2(p.size[0],p.size[1]))
static func draw(c:Node2D,cam:Vector2)->void:
 prepare();var view=Rect2(cam,c.VIEW).grow(180);visible_props=0;visible_pages=0
 c.draw_rect(Rect2(-cam,Vector2(8200,1450)),Color("#273f50"))
 for n in 5:
  var r=Rect2(n*1640,0,1640,1450)
  if view.intersects(r):c.draw_texture_rect(texture("ground"+str(n)),Rect2(r.position-cam,r.size),false);visible_pages+=1
 # All raised machinery sits at original solid anchors. Floor insets are baked, never false obstacles.
 var people:Array=[]
 if c.get("adventure")!=null:people=c.adventure.points().values()
 var clock=float(c.get("visual_clock")) if c.get("visual_clock")!=null else float(c.get("visual_time")) if c.get("visual_time")!=null else 0.0
 for p in placements:
  if p.layer!="hardware":continue
  var r=bounds(p)
  if not view.intersects(r):continue
  visible_props+=1;var tint=Color.WHITE
  for hero in people:
   if r.grow(-12).has_point(hero):tint.a=.42
  c.draw_texture_rect(frame(p.kind),Rect2(r.position-cam,r.size),false,tint)
  var q=Vector2(p.pos[0],p.pos[1])-cam-Vector2(0,p.size[1]*.48)
  if p.kind in ["navigation_beacon","relay_terminal","power_cabinet","survey_console","emergency_supply_pod"]:
   c.draw_circle(q,1.8+sin(clock*1.7+float(p.pos[0])*.002)*.4,Color(.78,.72,.43,.6*tint.a))
  elif p.kind in ["reactor_coil","plasma_condenser","gyro_ring","gravity_stabilizer"]:
   c.draw_arc(q,10,clock*.55,clock*.55+1.2,12,Color(.46,.72,.71,.35*tint.a),1.5,true)
 # Slow, contained window glints and cable pulses stay outside the central combat route.
 for n in 26:
  var at=Vector2(310+n*299,120 if n%2==0 else 1330)
  if not view.has_point(at):continue
  var fade=.12+.08*sin(clock*.65+n)
  c.draw_line(at-cam,at-cam+Vector2(8,0),Color(.7,.86,.84,fade),1.0,true)
 for n in 10:
  var at=Vector2(450+n*780+fposmod(clock*18,140),208 if n%2==0 else 1244)
  if view.has_point(at):c.draw_line(at-cam,at-cam+Vector2(9,0),Color(.48,.73,.72,.25),1.5,true)
 var labels=[[Vector2(330,490),"ARRIVAL LOCK"],[Vector2(1880,490),"OBSERVATION ARRAY"],[Vector2(3500,490),"LIFE SUPPORT"],[Vector2(5140,490),"SALVAGE WORKS"],[Vector2(7050,490),"SIGNAL CHAMBER"]]
 for entry in labels:
  if view.has_point(entry[0]):c.draw_string_outline(ThemeDB.fallback_font,entry[0]-cam,entry[1],HORIZONTAL_ALIGNMENT_LEFT,-1,15,2,Color("#223b49"));c.draw_string(ThemeDB.fallback_font,entry[0]-cam,entry[1],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#bfc6ac"))
