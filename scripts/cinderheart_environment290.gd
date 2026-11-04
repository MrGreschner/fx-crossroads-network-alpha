extends RefCounted
## Presentation only; Cinderheart owns all collision, heat and encounter state.
static var textures:Dictionary={}
static var frames:Dictionary={}
static var manifest:Dictionary={}
static var placements:Array=[]
static var pages:Array=[]
static var signature=""
static var budget=22
const SOLIDS=["retort_bench","alchemist_rack","ashglass_terrarium","crucible_furnace","sealed_reliquary","shield_rack","archive_shelf"]
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/cinderheart290/manifest.json"))
 placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/cinderheart290/placements.json"))
 var ground=JSON.parse_string(FileAccess.get_file_as_string("res://assets/cinderheart290/pages.json"));pages=ground.pages;signature=str(ground.source_signature)
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/cinderheart290/"+id+".png"))!=OK:return null
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
static func view(world:Node,c:Node2D,cam:Vector2,margin:float=220)->Rect2:
 var game=world.adventure.game;var factor=float(game.broadcast_scale) if world.adventure.arcade and game.spectating() else float(game.media.factor())
 return Rect2(cam,c.get_viewport_rect().size/maxf(.01,factor)).grow(margin)
static func fitted(id:String,r:Rect2)->Rect2:
 prepare();var bb=manifest[id].bounds;var scale=r.size/Vector2(bb[2]-bb[0],bb[3]-bb[1])
 return Rect2(r.position-Vector2(bb[0],bb[1])*scale,Vector2(112,112)*scale)
static func prop(c:Node2D,id:String,r:Rect2,cam:Vector2,alpha:float=1)->void:
 c.draw_texture_rect(frame(id),fitted(id,Rect2(r.position-cam,r.size)),false,Color(1,1,1,alpha))
static func material(world:Node,c:Node2D,id:String,bounds:Rect2,cam:Vector2)->void:
 var visible=bounds.intersection(view(world,c,cam,128))
 var tile=texture(id)
 for x in range(floori(visible.position.x/192)*192,ceili(visible.end.x),192):
  for y in range(floori(visible.position.y/192)*192,ceili(visible.end.y),192):
   var full=Rect2(x,y,192,192);var cut=full.intersection(bounds)
   c.draw_texture_rect_region(tile,Rect2(cut.position-cam,cut.size),Rect2(cut.position-full.position,cut.size))
static func draw_ground(world:Node,c:Node2D,cam:Vector2)->bool:
 prepare()
 if JSON.stringify(world.data).sha256_text()!=signature:return false
 var visible=view(world,c,cam);var screen=view(world,c,cam,0)
 c.draw_rect(Rect2(screen.position-cam,screen.size),Color("#302b36"))
 budget=pages.size() if world.adventure.arcade and world.adventure.game.spectating() else 22
 for p in pages:
  var r=Rect2(p.x,p.y,p.w,p.h)
  if visible.intersects(r):c.draw_texture_rect(texture(p.id),Rect2(r.position-cam,r.size),false)
 for room in world.data.rooms:
  var r=world.rect(room.rect)
  if r.size.x>1000 and visible.intersects(r):
   var at=r.position+Vector2(68,64)-cam
   c.draw_string_outline(ThemeDB.fallback_font,at,str(room.name),HORIZONTAL_ALIGNMENT_LEFT,1600,22,3,Color("#302c39"))
   c.draw_string(ThemeDB.fallback_font,at,str(room.name),HORIZONTAL_ALIGNMENT_LEFT,1600,22,Color("#e1cba4"))
 return true
static func draw_details(world:Node,c:Node2D,cam:Vector2)->void:
 prepare();var visible=view(world,c,cam);var people:Array=world.adventure.points().values()
 for p in placements:
  var at=world.v(p.pos);var size=world.v(p.size);var r=Rect2(at-Vector2(size.x*.5,size.y*.94),size)
  if not visible.intersects(r):continue
  var alpha=1.0
  for hero in people:
   if r.grow(20).has_point(hero):alpha=.27
  prop(c,p.kind,r,cam,alpha)
  if p.kind in ["ember_lantern","iron_brazier","crucible_furnace"]:
   var light=at-cam-Vector2(0,size.y*.55)
   c.draw_circle(light,22+sin(world.clock*2.1+at.x)*2,Color(1,.6,.27,.045*alpha))
   for j in 2:
    var age=fposmod(world.clock*.31+float(j)*.5+at.x*.003,1)
    c.draw_rect(Rect2(light+Vector2(sin(age*5+at.x)*7,-age*38),Vector2(2,3)),Color(1,.71,.36,(1-age)*.35*alpha))
  elif p.kind=="glass_condenser":
   for j in 2:
    var age=fposmod(world.clock*.2+j*.5+at.x*.01,1)
    c.draw_circle(at-cam+Vector2(sin(age*4)*6,-size.y*(.35+age*.3)),2,Color(.65,.83,.77,(1-age)*.4*alpha))
static func draw_world(world:Node,c:Node2D,cam:Vector2)->bool:
 if not draw_ground(world,c,cam):return false
 var visible=view(world,c,cam)
 for pool in world.data.pools:
  if visible.intersects(world.rect(pool).grow(90)):world.draw_lava(c,cam,world.rect(pool),false)
 for river in world.data.rivers:
  if visible.intersects(world.rect(river).grow(90)):world.draw_lava(c,cam,world.rect(river),true)
 for bridge in world.data.bridges:
  var r=world.rect(bridge)
  if not visible.intersects(r):continue
  material(world,c,"bridge",r,cam)
  c.draw_rect(Rect2(r.position-cam,r.size),Color("#d0b58d"),false,5)
  c.draw_rect(Rect2(r.position-cam+Vector2(8,8),r.size-Vector2(16,16)),Color("#4c4854"),false,3)
 for fall in world.data.falls:
  var box=world.rect(fall)
  if not visible.intersects(box):continue
  c.draw_rect(Rect2(box.position-cam,box.size),Color("#a94c35"))
  for j in 7:
   var x=box.position.x+8+j*(box.size.x-16)/7;var y=box.position.y+fposmod(world.clock*125+j*37,box.size.y)
   c.draw_line(Vector2(x,box.position.y)-cam,Vector2(x,box.end.y)-cam,Color("#ec843c"),5)
   c.draw_line(Vector2(x,y)-cam,Vector2(x,minf(y+34,box.end.y))-cam,Color("#ffcf73"),4)
  c.draw_arc(box.get_center()+Vector2(0,box.size.y*.5)-cam,box.size.x*.55,PI,TAU,22,Color("#ffb25f"),5)
 for i in world.data.solids.size():
  var r=world.rect(world.data.solids[i])
  if not visible.intersects(r):continue
  var alpha=1.0
  for hero in world.adventure.points().values():
   if r.grow(12).has_point(hero):alpha=.3
  prop(c,SOLIDS[i],r,cam,alpha)
 draw_details(world,c,cam)
 for gate in world.data.gates:
  if world.stage>=int(gate.opens):continue
  var box=world.rect(gate.rect);var q=box.get_center()-cam
  if not visible.intersects(box):continue
  c.draw_rect(Rect2(box.position-cam,box.size),Color("#614b55"));c.draw_rect(Rect2(box.position-cam,box.size),Color("#d79c63"),false,4)
  c.draw_circle(q,34,Color("#352e40"));c.draw_arc(q,27,0,TAU,24,Color("#e6ac62"),3);c.draw_string(ThemeDB.fallback_font,q+Vector2(-8,8),str(int(gate.opens)),HORIZONTAL_ALIGNMENT_LEFT,-1,24,Color("#ffd185"))
 var throne=Vector2(7240,2540)-cam
 var throne_rect=Rect2(Vector2(7110,2350),Vector2(260,225))
 if visible.intersects(throne_rect):
  var alpha=1.0
  for hero in world.adventure.points().values():
   if throne_rect.grow(20).has_point(hero):alpha=.3
  if world.boss_live and world.stage==4:alpha=.3
  prop(c,"crown_throne",throne_rect,cam,alpha)
 if world.reveal>0:
  c.draw_circle(throne,80+(4.5-world.reveal)*35,Color(1,.45,.1,.12));c.draw_arc(throne,80+(4.5-world.reveal)*35,0,TAU,48,Color("#f6bb6d"),5)
 if world.done:
  var p=world.v(world.data.exit)-cam;preload("res://scripts/realm_portals258.gd").draw_at(c,world.adventure.game,world.v(world.data.exit),cam);c.draw_string(ThemeDB.fallback_font,p+Vector2(-85,76),"COOLED THRONE • E",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#b9eee7"))
 return true
