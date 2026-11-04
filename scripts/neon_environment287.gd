extends RefCounted
## Presentation only. Neon Crucible owns all floors, collision, pods, AI, hazards and uploads.
static var textures:Dictionary={}
static var frames:Dictionary={}
static var manifest:Dictionary={}
static var placements:Array=[]
static var pages:Array=[]
static var signature:=""
static var cached_signature:=""
static var matching:=true
static var budget:=26
const MACHINE={"forge":"forge_press","server":"server_rack","coolant":"coolant_tank","antenna":"uplink_dish","belt":"conveyor","console":"console"}
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/neon287/manifest.json"))
 placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/neon287/placements.json"))
 var ground=JSON.parse_string(FileAccess.get_file_as_string("res://assets/neon287/pages.json"));pages=ground.pages;signature=str(ground.source_signature)
static func texture(id:String)->Texture2D:
 if textures.has(id):
  var cached=textures[id];textures.erase(id);textures[id]=cached;return cached
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/neon287/"+id+".png"))!=OK:return null
 if id.begins_with("ground_"):
  var keys:Array=[]
  for key in textures:
   if str(key).begins_with("ground_"):keys.append(key)
  if keys.size()>=budget:textures.erase(keys[0])
 var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;textures[id]=t;return t
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var r=manifest[id].region;var t=AtlasTexture.new();t.atlas=texture("props");t.region=Rect2(r[0],r[1],r[2],r[3]);frames[id]=t
 return frames[id]
static func view(world:Node,c:Node2D,cam:Vector2,margin:float=180)->Rect2:
 var game=world.adventure.game;var factor=float(game.broadcast_scale) if world.adventure.arcade and game.spectating() else float(game.media.factor())
 return Rect2(cam,c.get_viewport_rect().size/maxf(.01,factor)).grow(margin)
static func fitted(id:String,r:Rect2)->Rect2:
 prepare();var bb=manifest[id].bounds;var extent=Vector2(bb[2]-bb[0],bb[3]-bb[1]);var scale=r.size/extent
 return Rect2(r.position-Vector2(bb[0],bb[1])*scale,Vector2(112,112)*scale)
static func prop(c:Node2D,id:String,r:Rect2,cam:Vector2,alpha:float=1)->void:
 c.draw_texture_rect(frame(id),fitted(id,Rect2(r.position-cam,r.size)),false,Color(1,1,1,alpha))
static func draw_world(world:Node,c:Node2D,cam:Vector2)->bool:
 prepare();var current=JSON.stringify(world.data).sha256_text()
 if cached_signature!=current:cached_signature=current;matching=current==signature
 if not matching:return false
 var visible=view(world,c,cam);var screen=view(world,c,cam,0)
 c.draw_rect(Rect2(screen.position-cam,screen.size),Color("#182336"))
 # Slow aether lines and iron fragments stay beneath the actual platform silhouettes.
 for n in 22:
  var at=Vector2(posmod(n*877,6400),posmod(n*431,4800))+Vector2(sin(world.clock*.12+n)*18,cos(world.clock*.1+n)*12)
  if not visible.has_point(at) or world.floor_at(at):continue
  c.draw_line(at-cam,at-cam+Vector2(32+n%3*12,8),Color(.36,.50,.62,.13),2)
 budget=pages.size() if world.adventure.arcade and world.adventure.game.spectating() else 26
 for p in pages:
  var r=Rect2(p.x,p.y,p.w,p.h)
  if visible.intersects(r):c.draw_texture_rect(texture(p.id),Rect2(r.position-cam,r.size),false)
 var people:Array=world.adventure.points().values()
 # Each visible original machine fills exactly the former painted rectangle/collision footprint.
 for p in world.data.props:
  var at=world.v(p.pos);var size=world.v(p.get("size",[100,80]));var r=Rect2(at-size*.5,size)
  if not visible.intersects(r.grow(40)):continue
  var alpha=1.0
  for hero in people:
   if r.grow(10).has_point(hero):alpha=.35
  prop(c,MACHINE.get(str(p.kind),"console"),r,cam,alpha)
 for p in placements:
  var at=world.v(p.pos);var size=world.v(p.size);var r=Rect2(at-Vector2(size.x*.5,size.y*.94),size)
  if not visible.intersects(r):continue
  var alpha=1.0
  if p.layer!="floor":
   for hero in people:
    if r.grow(8).has_point(hero):alpha=.30
  prop(c,p.kind,r,cam,alpha)
 for room in world.data.rooms:
  var r=world.rect(room.rect)
  if str(room.name).is_empty() or not visible.intersects(r):continue
  var at=r.position+Vector2(45,65)-cam;var color=Color(str(room.colour))
  c.draw_string_outline(ThemeDB.fallback_font,at,str(room.name),HORIZONTAL_ALIGNMENT_LEFT,1300,22,3,Color("#25333c"));c.draw_string(ThemeDB.fallback_font,at,str(room.name),HORIZONTAL_ALIGNMENT_LEFT,1300,22,color)
 # Quiet captions use existing room identities; they add no quest or interaction state.
 for note in [[Vector2(410,4250),"BOLT IRONCORE • bridgeworks, before the broken oath"],[Vector2(4750,4420),"REPAIR GARDEN • a little life, kept running"]]:
  if not visible.has_point(note[0]):continue
  c.draw_string(ThemeDB.fallback_font,note[0]-cam,note[1],HORIZONTAL_ALIGNMENT_LEFT,1400,13,Color("#b9cdc0"))
 return true
static func draw_pod(world:Node,c:Node2D,pod:Dictionary,cam:Vector2)->void:
 var at=world.v(pod.pos);prop(c,"repair_pod",Rect2(at-Vector2(36,40),Vector2(72,65)),cam)
static func draw_life(world:Node,c:Node2D,cam:Vector2)->void:
 prepare();var visible=view(world,c,cam,100)
 for p in world.data.props:
  var at=world.v(p.pos);var size=world.v(p.get("size",[100,80]))
  if not visible.has_point(at):continue
  if str(p.kind)=="belt":
   for n in range(0,int(size.x)-24,45):
    var x=fposmod(n+world.clock*28,maxf(1,size.x-24));var q=at-cam+Vector2(-size.x*.5+12+x,0)
    c.draw_line(q-Vector2(5,4),q+Vector2(3,0),Color(.75,.68,.43,.40),2)
  if str(p.kind)=="server":
   for n in 3:
    if sin(world.clock*1.6+n+at.x)>0:c.draw_rect(Rect2(at-cam+Vector2(size.x*.3,-size.y*.25+n*14),Vector2(3,3)),Color(.55,.77,.74,.6))
  if str(p.kind)=="coolant":
   var y=sin(world.clock*.8+at.x)*size.y*.12;c.draw_line(at-cam+Vector2(-size.x*.2,y),at-cam+Vector2(size.x*.2,y),Color(.55,.8,.78,.25),2)
 for p in placements:
  var at=world.v(p.pos);var size=world.v(p.size)
  if not visible.has_point(at):continue
  if p.kind in ["lamp_chain","aether_condenser","memory_terminal"]:
   c.draw_circle(at-cam-Vector2(0,size.y*.55),10,Color(.53,.73,.71,.04+sin(world.clock*1.2+at.x)*.008))
  if p.kind in ["smelter","pump","pipe_junction"]:
   for n in 2:
    var age=fposmod(world.clock*.3+n*.5+at.x*.001,1);var q=at-cam+Vector2(sin(age*4+n)*5,-size.y*.7-age*24)
    c.draw_circle(q,2+age*4,Color(.61,.68,.71,(1-age)*.11))
