extends RefCounted
## Presentation only. Authored floor geometry and all collision remain in realm_trials.
static var textures:Dictionary={}
static var frames:Dictionary={}
static var manifest:Dictionary={}
static var placements:Array=[]
static var pages:Array=[]
static var visible_props:int=0
static var visible_pages:int=0
static var page_budget:int=18
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/astral294/manifest.json"))
 placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/astral294/placements.json"))
 pages=JSON.parse_string(FileAccess.get_file_as_string("res://assets/astral294/pages.json"))
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/astral294/"+id+".png"))!=OK:return null
 if id.begins_with("ground_"):
  var keys:Array=[]
  for key in textures:
   if str(key).begins_with("ground_"):keys.append(key)
  if keys.size()>=page_budget:textures.erase(keys[0])
 var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;textures[id]=t;return t
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var r=manifest[id].region;var t=AtlasTexture.new();t.atlas=texture("props");t.region=Rect2(r[0],r[1],r[2],r[3]);frames[id]=t
 return frames[id]
static func bounds(p:Dictionary)->Rect2:
 return Rect2(Vector2(p.pos[0],p.pos[1])-Vector2(p.size[0]*.5,p.size[1]*.94),Vector2(p.size[0],p.size[1]))
static func draw(c:Node2D,cam:Vector2)->void:
 if c.adventure.between_guardians():return
 prepare();visible_props=0;visible_pages=0
 var view=Rect2(cam,c.VIEW).grow(200)
 page_budget=pages.size() if c.has_method("spectating") and c.spectating() else 18
 var clock:float=float(c.adventure.clock)
 c.draw_texture_rect(texture("void"),Rect2(-cam,Vector2(8000,3200)),true,Color.WHITE)
 # Distant stars are drawn below every floor and cannot mask combat cues.
 for n in 72:
  var at=Vector2(100+posmod(n*1379,7800),90+posmod(n*877,3000))
  if not view.has_point(at):continue
  c.draw_circle(at-cam,1.5,Color(.68,.72,.88,.25+.13*sin(clock*.6+n)))
 for p in pages:
  var r=Rect2(p.x,p.y,p.w,p.h)
  if view.intersects(r):c.draw_texture_rect(texture(p.id),Rect2(r.position-cam,r.size),false);visible_pages+=1
 for p in placements:
  var r=bounds(p)
  if not view.intersects(r):continue
  visible_props+=1
  var alpha:float=1.0
  if p.get("fade",true):
   for hero in c.adventure.points().values():
    if r.grow(24).has_point(hero):alpha=.28
  var bob=Vector2.ZERO
  if p.kind=="island":bob.y=sin(clock*.4+float(p.pos[0])*.002)*5
  c.draw_texture_rect(frame(p.kind),Rect2(r.position-cam+bob,r.size),false,Color(1,1,1,alpha))
  var q=Vector2(p.pos[0],p.pos[1])-cam-Vector2(0,p.size[1]*.58)+bob
  if p.kind in ["lantern","bollard","brazier","prism"]:
   c.draw_circle(q,6+sin(clock+nint(p.pos[0]))*.8,Color(.64,.84,.88,.12*alpha))
  elif p.kind in ["armillary","orrery","astrolabe"]:
   c.draw_arc(q,13,clock*.25,clock*.25+PI*.6,12,Color(.78,.70,.5,.38*alpha),1.5)
 # Cosmetic courier stars travel only along the void margins.
 for n in 6:
  var at=Vector2(900+fposmod(clock*22+n*1150,6100),n*410+340)
  if at.y>1000 and at.y<2600:continue
  if view.has_point(at):
   c.draw_line(at-cam-Vector2(10,2),at-cam,Color(.65,.8,.9,.3),2)
   c.draw_circle(at-cam,2,Color(.8,.88,.92,.7))
static func nint(value:Variant)->int:return int(value)%7
