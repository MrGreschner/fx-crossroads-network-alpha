extends RefCounted
## Scoped Sunfield presentation. One prop atlas, one rotor and five small material images.
var world:Node
var bins:Dictionary={}
var nearby:Array=[]
var nearby_key=""
static var cache:Dictionary={}
static var frames:Dictionary={}
static var metadata:Dictionary={}
static var discovery_styles:Dictionary={}
static func texture(id:String)->Texture2D:
 if cache.has(id):return cache[id]
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/sunfield257/"+id+".png"))!=OK:return null
 var t=ImageTexture.create_from_image(im);cache[id]=t;return t
static func frame(id:String)->Texture2D:
 if frames.has(id):return frames[id]
 if metadata.is_empty():metadata=JSON.parse_string(FileAccess.get_file_as_string("res://assets/sunfield257/manifest.json"))
 if not metadata.frames.has(id):return null
 var a:Array=metadata.frames[id];var t=AtlasTexture.new();t.atlas=texture("props");t.region=Rect2(a[0],a[1],a[2],a[3]);frames[id]=t;return t
func reset()->void:bins.clear();nearby.clear();nearby_key=""
func setup()->void:
 reset()
 for p in world.data.props:
  var k=Vector2i(floori(float(p.pos[0])/512),floori(float(p.pos[1])/512))
  if not bins.has(k):bins[k]=[]
  bins[k].append(p)
func visible_props(camera:Vector2,view:Vector2)->Array:
 var cell=Vector2i(floori(camera.x/128),floori(camera.y/128));var key=str(cell)+str(view)
 if key==nearby_key:return nearby
 nearby_key=key;nearby=[];var area=Rect2(camera,view).grow(640);var a=Vector2i(floori(area.position.x/512),floori(area.position.y/512));var b=Vector2i(floori(area.end.x/512),floori(area.end.y/512))
 for x in range(a.x,b.x+1):
  for y in range(a.y,b.y+1):nearby.append_array(bins.get(Vector2i(x,y),[]))
 nearby.sort_custom(func(a,b):return float(a.pos[1])<float(b.pos[1]));return nearby
func rect(p:Dictionary,camera:Vector2)->Rect2:
 var t=frame(str(p.kind));var scale=float(p.scale);var size=t.get_size()*scale;var anchor=Vector2(.5,.98)if p.kind=="windmill"else Vector2(.5,.6)if p.kind=="sunwell"else Vector2(.5,.75)if p.kind=="rock"else Vector2(.5,.7)if p.kind=="wagon"else Vector2(.5,.95)
 return Rect2(world.v(p.pos)-camera-size*anchor,size)
func crown_alpha(p:Dictionary)->float:
 var center=world.v(p.pos)+Vector2(0,-180)*float(p.scale)
 for player in world.adventure.points().values():
  if (player as Vector2).distance_to(center)<140*float(p.scale):return .28
 return 1.0
func draw_world(c:Node2D,camera:Vector2)->void:
 var view=Rect2(Vector2.ZERO,world.adventure.game.VIEW).grow(300)
 # A few world-anchored current strokes keep the creek alive without shaders/particles.
 for stream in world.data.streams:
  var shape=world.polygon(stream)
  for x in range(floori(camera.x/190)*190,int(camera.x+1400),190):
   for y in range(floori(camera.y/190)*190,int(camera.y+900),190):
    var at=Vector2(x+fposmod(world.clock*10,80),y+sin(world.clock*.4+x)*6)
    if Geometry2D.is_point_in_polygon(at,shape)and not world.floor_at(at):c.draw_line(at-camera,at-camera+Vector2(22,5),Color(.76,.9,.8,.35),2,true)
 for fall in world.data.waterfalls:
  var p=world.v(fall.pos)-camera
  if not view.has_point(p):continue
  var width=float(fall.width);var height=float(fall.height)
  c.draw_colored_polygon(PackedVector2Array([p+Vector2(-width*.48,0),p+Vector2(width*.48,0),p+Vector2(width*.41,height*.55),p+Vector2(width*.52,height),p+Vector2(-width*.46,height+4),p+Vector2(-width*.4,height*.42)]),Color(.33,.64,.62,.8))
  for n in 6:c.draw_circle(p+Vector2((n-2.5)*width/6,height+sin(n*2.1)*4),7+sin(world.clock+n)*2,Color(.8,.9,.78,.5))
  for n in 8:
   var q=p+Vector2((n-3.5)*float(fall.width)/9,fposmod(world.clock*70+n*23,float(fall.height)))
   c.draw_line(q,q+Vector2(0,minf(28,float(fall.height)-q.y+p.y)),Color(.81,.92,.8,.55),2,true)
 for p in visible_props(camera,world.adventure.game.VIEW):
  if p.kind=="support":continue
  var r=rect(p,camera)
  if not r.intersects(view):continue
  var t=frame(str(p.kind))
  if p.kind=="tree":
   # Lower trunk stays behind actors; canopy is drawn/faded after them.
   var fraction=218.0/320.0;c.draw_texture_rect_region(t,Rect2(r.position+Vector2(0,r.size.y*fraction),Vector2(r.size.x,r.size.y*(1-fraction))),Rect2(0,218,256,102));continue
  var sway=float(p.scale)*sin(world.clock*1.25+float(p.pos[0])*.01)*.025 if p.kind in ["sunflower","wheat"]else 0.0
  if sway!=0:
   var root=world.v(p.pos)-camera;c.world_transform(root,sway);c.draw_texture_rect(t,Rect2(r.position-root,r.size),false);c.world_transform()
  else:c.draw_texture_rect(t,r,false)
 # Discoveries remain visible and readable after the terrain replacement.
 for secret in world.data.secrets:
  var at=world.v(secret.pos)-camera
  if not view.has_point(at):continue
  var available=false;var near=false
  for id in world.adventure.points():
   if not world.used.has(str(secret.id)+":"+str(id)):
    available=true
    if (world.adventure.points()[id] as Vector2).distance_to(world.v(secret.pos))<150:near=true
  if not available:continue
  var healing=str(secret.kind)=="heal"
  c.draw_circle(at+Vector2(0,7),25,Color(.2,.3,.22,.25))
  if healing:
   c.draw_circle(at,23,Color("#456f65"));c.draw_arc(at,21,0,TAU,20,Color("#b2cba4"),3,true);c.draw_circle(at,12,Color("#6a9a86"))
   c.draw_line(at+Vector2(-7,0),at+Vector2(7,0),Color("#edf0be"),4,true);c.draw_line(at+Vector2(0,-7),at+Vector2(0,7),Color("#edf0be"),4,true)
  else:
   c.draw_style_box(discovery_box(Color("#9c754b")),Rect2(at-Vector2(23,16),Vector2(46,34)));c.draw_style_box(discovery_box(Color("#bba16b")),Rect2(at-Vector2(24,18),Vector2(48,13)));c.draw_rect(Rect2(at-Vector2(4,7),Vector2(8,13)),Color("#ead99d"))
  if near:
   var font=ThemeDB.fallback_font;var title="E / Interact • "+str(secret.name);var size=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,16);var pos=at+Vector2(-size.x*.5,50)
   c.draw_style_box(discovery_box(Color("#344b42")),Rect2(pos-Vector2(10,20),Vector2(size.x+20,29)));c.draw_string(font,pos,title,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#f3dfac"))
 for landmark in world.data.landmarks:
  var at=world.v(landmark.pos)-camera
  if not view.has_point(at):continue
  var title=str(landmark.name);var font=ThemeDB.fallback_font;var size=font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,20);var pos=at-Vector2(size.x*.5,0)
  c.draw_string_outline(font,pos,title,HORIZONTAL_ALIGNMENT_LEFT,-1,20,4,Color("#435448"));c.draw_string(font,pos,title,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#f3dfac"));c.draw_line(at+Vector2(-40,10),at+Vector2(40,10),Color("#c5b277"),2,true)
func draw_on(c:Node2D,camera:Vector2)->void:
 var view=Rect2(Vector2.ZERO,world.adventure.game.VIEW).grow(320)
 for p in visible_props(camera,world.adventure.game.VIEW):
  if p.kind=="tree":
   var r=rect(p,camera)
   if r.intersects(view):c.draw_texture_rect_region(frame("tree"),Rect2(r.position,Vector2(r.size.x,r.size.y*218.0/320.0)),Rect2(0,0,256,218),Color(1,1,1,crown_alpha(p)))
  elif p.kind=="windmill":
   var hub=world.v(p.pos)+Vector2(48,-338)-camera
   if view.grow(256).has_point(hub):
    var alpha=1.0
    for player in world.adventure.points().values():
     if (player as Vector2).distance_to(hub+camera)<270:alpha=.28
    c.world_transform(hub,world.clock*.18);c.draw_texture_rect(texture("rotor"),Rect2(-256,-256,512,512),false,Color(1,1,1,alpha));c.world_transform()
 # Sparse warm seed motes, limited to 12 visible points and no separate nodes.
 for n in 12:
  var at=Vector2(fposmod(n*277+world.clock*12,1200),fposmod(n*149+sin(world.clock*.6+n)*18,700))
  if world.floor_at(at+camera):c.draw_circle(at,1.2,Color(.98,.91,.65,.3))

static func discovery_box(color:Color)->StyleBoxFlat:
 if discovery_styles.has(color):return discovery_styles[color]
 var style=StyleBoxFlat.new();style.bg_color=color;style.border_color=Color("#c4ba8a");style.set_border_width_all(2);style.set_corner_radius_all(5);discovery_styles[color]=style;return style
