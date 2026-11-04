extends RefCounted
## Environment-only art. Original river routes, ferry, rooms, encounters and hero/enemy art stay authoritative.
static var textures:Dictionary={}
static var frames:Dictionary={}
static var manifest:Dictionary={}
static var placements:Array=[]
static var pages:Array=[]
static var signature:=""
static var checked_signature:=""
static var matches:=true
static var ground_budget:=40
const MAP={"sf_willow":"willow","sf_birch":"birch","sf_rock":"river_rock","sf_fern":"fern","sf_hearth":"hearth","sf_tearoom":"tearoom","sf_observatory":"observatory","sf_lantern":"lantern","sf_ruin":"ruin","sf_raft":"ferry","sf_flowerbed":"flowerbed","sf_keepsake":"keepsake","sf_flora":"flora","sf_water":"river_water","sf_cascade":"cascade"}
static func texture(id:String)->Texture2D:
 if textures.has(id):
  var cached=textures[id];textures.erase(id);textures[id]=cached;return cached
 var im=Image.new()
 if im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/silverfall285/"+id+".png"))!=OK:return null
 if id.begins_with("ground_"):
  var keys:Array=[]
  for key in textures:
   if str(key).begins_with("ground_"):keys.append(key)
  if keys.size()>=ground_budget:textures.erase(keys[0])
 var t=CanvasTexture.new();t.diffuse_texture=ImageTexture.create_from_image(im);t.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;textures[id]=t;return t
static func legacy_texture(id:String)->Texture2D:
 if not MAP.has(id):return null
 return texture("legacy_"+str(MAP[id]))
static func prepare()->void:
 if not manifest.is_empty():return
 manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/silverfall285/manifest.json"));placements=JSON.parse_string(FileAccess.get_file_as_string("res://assets/silverfall285/placements.json"));var ground=JSON.parse_string(FileAccess.get_file_as_string("res://assets/silverfall285/pages.json"));pages=ground.pages;signature=str(ground.source_signature)
static func frame(id:String)->Texture2D:
 prepare()
 if not frames.has(id):
  var r=manifest[id].region;var t=AtlasTexture.new();t.atlas=texture("props");t.region=Rect2(r[0],r[1],r[2],r[3]);frames[id]=t
 return frames[id]
static func view(world:Node,c:Node2D,cam:Vector2,margin:float=180)->Rect2:
 var game=world.adventure.game;var factor=float(game.broadcast_scale) if world.adventure.arcade and game.spectating() else float(game.media.factor())
 return Rect2(cam,c.get_viewport_rect().size/maxf(.01,factor)).grow(margin)
static func draw_ground(world:Node,c:Node2D,cam:Vector2)->bool:
 prepare()
 var current=JSON.stringify(world.data).sha256_text()
 if current!=checked_signature:checked_signature=current;matches=current==signature
 if not matches:return false
 ground_budget=pages.size() if world.adventure.arcade and world.adventure.game.spectating() else 40
 var bounds=view(world,c,cam,80)
 for p in pages:
  var r=Rect2(p.x,p.y,p.w,p.h)
  if bounds.intersects(r):c.draw_texture_rect(texture(p.id),Rect2(r.position,r.size),false)
 return true
static func draw_details(world:Node,c:Node2D,cam:Vector2)->void:
 prepare();var bounds=view(world,c,cam);var people:Array=world.adventure.points().values()
 var room=interior(world,c,cam)
 for p in placements:
  var size=world.v(p.size);var at=world.v(p.pos);var r=Rect2(at-Vector2(size.x*.5,size.y*(.5 if p.layer=="floor" else .9375)),size)
  if room.has_area() and not room.has_point(at):continue
  if not bounds.intersects(r):continue
  var alpha=1.0
  if p.layer!="floor":
   for hero in people:
    if r.grow(-8).has_point(hero):alpha=.35
  c.draw_texture_rect(frame(p.kind),Rect2(r.position-cam,r.size),false,Color(1,1,1,alpha))
 # Quiet context captions make each hero's craft visible without adding interaction prompts.
 for note in [[Vector2(3550,6625),"REED’S HEARTH • oars, river charts and a welcome fire"],[Vector2(500,2320),"CANOPY TEA ROOM • a pause between crossings"],[Vector2(8170,6415),"MISTKEEPER OBSERVATORY • reading the river and sky"],[Vector2(5330,2690),"COBBLECLAW • river stones, carefully kept"]]:
  if not bounds.has_point(note[0]):continue
  var close=false
  for hero in people:
   if (hero as Vector2).distance_to(note[0])<560:close=true
  if close:c.draw_string_outline(ThemeDB.fallback_font,note[0]-cam,note[1],HORIZONTAL_ALIGNMENT_LEFT,650,13,2,Color("#304c50"));c.draw_string(ThemeDB.fallback_font,note[0]-cam,note[1],HORIZONTAL_ALIGNMENT_LEFT,650,13,Color("#e6ddbb"))
static func draw_life(world:Node,c:Node2D,cam:Vector2)->void:
 var bounds=view(world,c,cam,80)
 var room=interior(world,c,cam)
 for p in placements:
  var at=world.v(p.pos)
  if room.has_area() and not room.has_point(at):continue
  if not bounds.has_point(at):continue
  if p.kind in ["hearth_stove","river_bell","ferry_lodge"]:
   var q=at-cam-Vector2(0,float(p.size[1])*.6)
   c.draw_circle(q,5+sin(world.clock*2.2+at.x)*1.2,Color(1,.76,.39,.08))
  if p.kind=="waterwheel":
   var center=at-cam-Vector2(0,float(p.size[1])*.45);var radius=float(p.size[0])*.17
   for n in 6:
    var q=center+Vector2.from_angle(world.clock*.35+TAU*n/6)*radius;c.draw_line(center,q,Color(.52,.42,.28,.35),2)
 # Drifting petals follow the banks; sparse and view-culled, never covering warning circles.
 for n in 32:
  var at=Vector2(640+n*291,1700+posmod(n*593,4700))+Vector2(sin(world.clock*.35+n)*16,cos(world.clock*.4+n)*8)
  if not room.has_area() and bounds.has_point(at) and world.floor_at(at):c.draw_line(at-cam,at-cam+Vector2(3,-1),Color(.88,.86,.65,.32),2)
static func interior(world:Node,c:Node2D,cam:Vector2)->Rect2:
 var center=view(world,c,cam,0).get_center()
 for f in world.data.floors:
  if str(f.kind)=="silver_room" and world.r(f.rect).has_point(center):return world.r(f.rect)
 return Rect2()
static func draw_interior(world:Node,c:Node2D,cam:Vector2)->bool:
 var room=interior(world,c,cam)
 if not room.has_area():return false
 var bounds=view(world,c,cam,0)
 for r in [Rect2(bounds.position,Vector2(bounds.size.x,maxf(0,room.position.y-bounds.position.y))),Rect2(Vector2(bounds.position.x,room.end.y),Vector2(bounds.size.x,maxf(0,bounds.end.y-room.end.y))),Rect2(Vector2(bounds.position.x,maxf(bounds.position.y,room.position.y)),Vector2(maxf(0,room.position.x-bounds.position.x),room.size.y)),Rect2(Vector2(room.end.x,maxf(bounds.position.y,room.position.y)),Vector2(maxf(0,bounds.end.x-room.end.x),room.size.y))]:
  if r.has_area():c.draw_rect(Rect2(r.position-cam,r.size),Color("#263b3c"))
 draw_details(world,c,cam)
 for house in world.data.houses:
  var p=world.v(house.inside)
  if room.has_point(p):c.draw_arc(p-cam,22,PI*.08,PI*.92,18,Color("#ded2a1"),2,true);c.draw_string(ThemeDB.fallback_font,p-cam+Vector2(-51,42),"E • leave",HORIZONTAL_ALIGNMENT_LEFT,180,13,Color("#e3e5c7"))
 for secret in world.data.secrets:
  var p=world.v(secret.pos)
  if room.has_point(p):c.draw_texture_rect(legacy_texture("sf_keepsake"),Rect2(p-cam-Vector2(20,30),Vector2(40,40)),false);c.draw_string(ThemeDB.fallback_font,p-cam+Vector2(-60,36),"E • discovery",HORIZONTAL_ALIGNMENT_LEFT,160,13,Color("#dce2bf"))
 return true
