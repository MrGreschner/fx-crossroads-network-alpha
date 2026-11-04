extends RefCounted
## Presentation only. lantern_city retains every wall, working door, rift and combat rule.
static var textures:Dictionary={}
static var frames:Dictionary={}
static var manifest:Dictionary={}
static var placements:Array=[]
const TITLES=["KEYWORKS • enchanted locks","COURIER HOUSE • Nera’s route","CLOCKMAKER • the last bell","ARCHIVES • every lost address","TEA HOUSE • a warm return","LATCHWORKS • hinges and chains","PARCEL OFFICE • impossible deliveries","WATCH REPAIR • borrowed hours","LEDGER HALL • keys remembered","BAKERY • before the last tram","LOCKSMITH’S GARDEN","NIGHT COURIERS • lanterns ready","TRAM DEPOT • last service","BOROUGH LIBRARY","COURTHOUSE • Keeper of Every Lock"]
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/brasslock286/manifest.json"))
 placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/brasslock286/placements.json"))
static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/brasslock286/"+id+".png"))!=OK:return null
 var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;t.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
 textures[id]=t;return t
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var r=manifest[id].region;var t=AtlasTexture.new();t.atlas=texture("props");t.region=Rect2(r[0],r[1],r[2],r[3]);frames[id]=t
 return frames[id]
static func bounds(city:Node,c:Node2D,cam:Vector2)->Rect2:
 var game=city.adventure.game
 var factor=float(game.broadcast_scale) if city.adventure.arcade and game.spectating() else float(game.media.factor())
 return Rect2(cam,c.get_viewport_rect().size/maxf(.01,factor)).grow(220)
static func piece(c:Node2D,id:String,at:Vector2,size:Vector2,cam:Vector2,alpha:float=1)->void:
 c.draw_texture_rect(frame(id),Rect2(at-cam-Vector2(size.x*.5,size.y*.94),size),false,Color(1,1,1,alpha))
static func draw_base(city:Node,c:Node2D,cam:Vector2)->void:
 prepare();var visible=bounds(city,c,cam)
 # Street, pavements and decorative rails share the original uninterrupted walkable ground.
 var ground=Rect2(Vector2.ZERO,city.SIZE)
 c.draw_texture_rect(texture("cobble"),Rect2(ground.position-cam,ground.size),true)
 for building in city.buildings:
  var world:Rect2=building.rect
  if not visible.intersects(world.grow(35)):continue
  var rect=Rect2(world.position-cam,world.size);var index=int(building.index)
  c.draw_texture_rect(texture("sidewalk"),rect.grow(25),true)
  c.draw_texture_rect(texture("parquet" if index%5 in [0,1,2] else "tea_tile" if index%5==4 else "civic_tile"),rect,true)
  c.draw_rect(rect.grow(-43),Color("#ddbe87"),false,2)
  # Thin rugs flank circulation instead of masking either entrance or the partition door.
  for x in [82,371]:
   var rug=Rect2(rect.position+Vector2(x,160),Vector2(95,38))
   c.draw_rect(rug,Color(.24,.39,.40,.35));c.draw_rect(rug,Color(.73,.64,.43,.55),false,2)
 for wall in city.walls:
  if not visible.intersects(wall):continue
  var r=Rect2(wall.position-cam,wall.size)
  c.draw_texture_rect(texture("masonry"),r,true)
  c.draw_rect(Rect2(r.position,Vector2(r.size.x,6)),Color("#b0a48c"))
  c.draw_line(r.position+Vector2(0,r.size.y-3),r.end-Vector2(0,3),Color("#35434d"),3)
  if r.size.x>100:
   var at=r.get_center();c.draw_rect(Rect2(at-Vector2(15,8),Vector2(30,18)),Color("#bda16a"));c.draw_rect(Rect2(at-Vector2(10,6),Vector2(20,12)),Color("#e5c77e"));c.draw_line(at-Vector2(0,6),at+Vector2(0,6),Color("#5a655b"),2)
 # A modest nighttime tram route gives Nera’s lore a presence without introducing transport.
 for y in [2450,2474]:
  c.draw_line(Vector2(140,y)-cam,Vector2(3700,y)-cam,Color("#a58c61"),3)
  for x in range(150,3700,45):
   if visible.has_point(Vector2(x,y)):c.draw_line(Vector2(x,2442)-cam,Vector2(x,2482)-cam,Color(.36,.39,.38,.6),3)
 var people:Array=city.adventure.points().values()
 for p in placements:
  var at=Vector2(p.pos[0],p.pos[1]);var size=Vector2(p.size[0],p.size[1]);var r=Rect2(at-Vector2(size.x*.5,size.y*.94),size)
  if not visible.intersects(r):continue
  var alpha=1.0
  for hero in people:
   if r.grow(10).has_point(hero):alpha=.32
  piece(c,p.kind,at,size,cam,alpha)
 for building in city.buildings:
  var world:Rect2=building.rect;var at=world.position+Vector2(45,434)
  if not visible.has_point(at):continue
  c.draw_string_outline(ThemeDB.fallback_font,at-cam,TITLES[int(building.index)],HORIZONTAL_ALIGNMENT_LEFT,480,12,2,Color("#35434d"))
  c.draw_string(ThemeDB.fallback_font,at-cam,TITLES[int(building.index)],HORIZONTAL_ALIGNMENT_LEFT,480,12,Color("#edd6a0"))
 var tram_at=Vector2(180+fposmod(city.clock*64,3380),2490)
 if visible.grow(150).has_point(tram_at):piece(c,"ghost_tram",tram_at,Vector2(210,126),cam,.42)
static func draw_life(city:Node,c:Node2D,cam:Vector2)->void:
 prepare();var visible=bounds(city,c,cam)
 for p in placements:
  var at=Vector2(p.pos[0],p.pos[1]);var size=Vector2(p.size[0],p.size[1])
  if not visible.has_point(at):continue
  if p.kind in ["street_lantern","tram_shelter","ticket_kiosk","stove"]:
   var lamp=at-cam-Vector2(0,size.y*.62);var pulse=sin(city.clock*1.7+at.x)*.006
   c.draw_circle(lamp,39,Color(1,.76,.39,.035+pulse));c.draw_circle(lamp,19,Color(1,.8,.5,.045+pulse))
  if p.kind in ["boiler","stove"]:
   for n in 3:
    var age=fposmod(city.clock*.32+n*.33+at.x*.001,1.0)
    var q=at-cam+Vector2(sin(age*5+n)*5,-size.y*.75-age*30)
    c.draw_circle(q,2+age*4,Color(.73,.79,.76,(1-age)*.13))
  if p.kind in ["street_clock","pendulum_clock"]:
   var center=at-cam-Vector2(0,size.y*.69)
   c.draw_line(center,center+Vector2.from_angle(city.clock*.09)*size.x*.08,Color("#6d624b"),2)
