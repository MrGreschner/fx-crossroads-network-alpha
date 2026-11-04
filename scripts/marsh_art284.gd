extends RefCounted
## Lantern Marsh: retained night terrain and bounded cosmetic wayfinding; no combat units.
var world:Node
static var textures:Dictionary={}
static var manifest:Dictionary={}
static var placements:Array=[]
static var pages:Array=[]
static var frames:Dictionary={}
static var glow:Texture2D
static var ground_budget:=18
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/marsh284/"+id+".png"))!=OK:return null
 if id.begins_with("ground_"):
  var grounds:Array=[]
  for key in textures:
   if str(key).begins_with("ground_"):grounds.append(key)
  if grounds.size()>=ground_budget:textures.erase(grounds[0])
 var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;textures[id]=t;return t
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/marsh284/manifest.json"));placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/marsh284/placements.json"));pages=JSON.parse_string(FileAccess.get_file_as_string("res://assets/marsh284/pages.json"))
 var gradient=Gradient.new();gradient.set_color(0,Color(1,.83,.43,.28));gradient.set_color(1,Color(1,.74,.35,0));gradient.add_point(.35,Color(1,.80,.43,.15))
 var g=GradientTexture2D.new();g.gradient=gradient;g.width=128;g.height=128;g.fill=GradientTexture2D.FILL_RADIAL;g.fill_from=Vector2(.5,.5);g.fill_to=Vector2(1,.5);glow=g
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var r=manifest[id].region;var t=AtlasTexture.new();t.atlas=texture("props");t.region=Rect2(r[0],r[1],r[2],r[3]);frames[id]=t
 return frames[id]
func terrain_speed(point:Vector2)->float:
 for raw in world.data.get("marsh_slow_polygons",[]):
  if Geometry2D.is_point_in_polygon(point,world.polygon(raw)):return .55
 return 1.0
func lamp_point(lamp:Dictionary,index:int)->Vector2:
 var p=world.v(lamp.pos)
 if bool(lamp.moving):p+=Vector2(sin(world.clock*.55+index)*7,cos(world.clock*.7+index)*4)
 return p
func view_size(c:Node2D)->Vector2:
 var game=world.adventure.game
 var factor=float(game.broadcast_scale) if world.adventure.arcade and game.spectating() else float(game.media.factor())
 return c.get_viewport_rect().size/maxf(.01,factor)
func draw_world(c:Node2D,cam:Vector2)->void:
 prepare();var extents=view_size(c);var view=Rect2(cam,extents).grow(180)
 ground_budget=54 if world.adventure.arcade and world.adventure.game.spectating() else 18
 c.draw_rect(Rect2(Vector2.ZERO,extents),Color("#182f35"))
 for page in pages:
  var r=Rect2(page.x,page.y,page.w,page.h)
  if view.intersects(r):c.draw_texture_rect(texture(page.id),Rect2(r.position-cam,r.size),false)
 for p in placements:
  if p.layer!="floor":continue
  var r=Rect2(world.v(p.pos)-world.v(p.size)*.5,world.v(p.size))
  if view.intersects(r):c.draw_texture_rect(frame(p.kind),Rect2(r.position-cam,r.size),false)
 # Soft pools supplement the baked night palette; actors/hostile warnings retain their own contrast.
 for i in world.data.lantern_refuges.size():
  var lamp:Dictionary=world.data.lantern_refuges[i];var p=lamp_point(lamp,i)-Vector2(0,42)
  if view.has_point(p):c.draw_texture_rect(glow,Rect2(p-cam-Vector2(205,145),Vector2(410,290)),false)
 for p in placements:
  if p.layer!="raised":continue
  var size=world.v(p.size);var at=world.v(p.pos);var r=Rect2(at-Vector2(size.x*.5,size.y*.9375),size)
  if not view.intersects(r):continue
  var alpha=1.0
  for hero in world.adventure.points().values():
   if r.grow(-12).has_point(hero):alpha=.40
  c.draw_texture_rect(frame(p.kind),Rect2(r.position-cam,size),false,Color(1,1,1,alpha))
 for i in world.data.lantern_refuges.size():
  var lamp:Dictionary=world.data.lantern_refuges[i];var p=lamp_point(lamp,i)
  if not view.has_point(p):continue
  c.draw_texture_rect(frame(lamp.kind),Rect2(p-cam-Vector2(35,100),Vector2(70,108)),false)
  var q=p-cam-Vector2(0,52);c.draw_rect(Rect2(q-Vector2(2,3),Vector2(4,6)),Color(1,.86,.49,.65+.12*sin(world.clock*2+i)))
 for secret in world.data.secrets:
  var p=world.v(secret.pos)
  if view.has_point(p):c.draw_arc(p-cam,25,0,TAU,24,Color("#b5d4ae"),2);c.draw_string(ThemeDB.fallback_font,p-cam+Vector2(-65,46),"E • discovery",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#e2d8ad"))
 for floor in world.data.floors:
  if str(floor.name).is_empty():continue
  var p=world.floor_bounds(floor).position+Vector2(75,95)
  if view.has_point(p):c.draw_string_outline(ThemeDB.fallback_font,p-cam,str(floor.name),HORIZONTAL_ALIGNMENT_LEFT,-1,17,3,Color("#172b31"));c.draw_string(ThemeDB.fallback_font,p-cam,str(floor.name),HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#cbbf94"))
func fly(c:Node2D,p:Vector2,phase:float)->void:
 var pulse=.6+.25*sin(world.clock*2.7+phase)
 c.draw_circle(p,7,Color(.60,.90,.68,.06*pulse));c.draw_rect(Rect2(p-Vector2.ONE*2,Vector2.ONE*4),Color(.80,.97,.66,pulse))
 var wing=3+sin(world.clock*22+phase)*1.5
 c.draw_line(p+Vector2(-wing,-2),p+Vector2(wing,-2),Color(.80,.92,.72,.28),1)
func draw_on(c:Node2D,cam:Vector2)->void:
 var view=Rect2(cam,view_size(c)).grow(80)
 # Every path interpolation stays on the authored walkable causeway. Cosmetics have no network state.
 for ri in world.data.lantern_routes.size():
  var route:Array=world.data.lantern_routes[ri]
  for i in range(route.size()-1):
   var a=world.v(route[i]);var b=world.v(route[i+1]);var count=maxi(1,ceili(a.distance_to(b)/300))
   for n in count:
    var t=fposmod(world.clock*.035+float(n)/count+ri*.2,1.0);var p=a.lerp(b,t)+Vector2(sin(world.clock+i+n)*12,cos(world.clock*.8+n)*9)
    if view.has_point(p):fly(c,p-cam,float(i+n))
 # A small local cluster points from each hero toward the next connected route stop.
 for hero in world.adventure.points().values():
  var closest=INF;var next:Vector2=hero
  for route in world.data.lantern_routes:
   for i in range(route.size()-1):
    var a=world.v(route[i]);var b=world.v(route[i+1]);var near=Geometry2D.get_closest_point_to_segment(hero,a,b);var dist=near.distance_squared_to(hero)
    if dist<closest:closest=dist;next=near.move_toward(b,90)
  if closest<90000:
   for n in 3:
    var p=(hero as Vector2).lerp(next,.35+n*.18)+Vector2(sin(world.clock*1.4+n*2)*6,-22+cos(world.clock+n)*5)
    if view.has_point(p):fly(c,p-cam,float(n+4))
 # Retain every original spore hazard warning at the same position/timing, above the textured fen.
 for patch in world.data.mud:
  var p=world.r(patch).get_center()-cam;var on=fmod(world.clock,4)<1.2
  c.draw_circle(p,75,Color(.65,.43,.8,.23 if on else .09));c.draw_arc(p,75,0,TAU,36,Color("#b590b7"),2)
 # Sparse water ripples and drifting lights stay visible without a full-screen darkness mask.
 for n in 18:
  var p=Vector2(300+n*431,690+posmod(n*977,4700))
  if view.has_point(p):c.draw_arc(p-cam,12+fposmod(world.clock*7+n*3,28),0,PI*1.6,16,Color(.39,.59,.57,.13),1)
