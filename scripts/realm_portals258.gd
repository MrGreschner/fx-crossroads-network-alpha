extends RefCounted
## One immutable 72-frame atlas: three identities, shared by every realm and menu.
const FPS=12.0
const COUNT=24
const SIZE=Vector2(80,120)
static var atlas:Texture2D
static var frames:Dictionary={}
static func prepare()->void:
 if atlas!=null:return
 var image=Image.new();image.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/portals258/portals.png"));atlas=ImageTexture.create_from_image(image)
 var specs=JSON.parse_string(FileAccess.get_file_as_string("res://assets/portals258/frames.json"))
 for key in specs:
  var r=specs[key];var frame=AtlasTexture.new();frame.atlas=atlas;frame.region=Rect2(r[0],r[1],r[2],r[3]);frames[key]=frame
static func phase(time:float)->int:return posmod(floori(time*FPS),COUNT)
static func texture(variant:int,time:float,muted:bool=false)->Texture2D:
 prepare();return frames[str(clampi(variant,0,2))+":"+str(0 if muted else phase(time))]
static func variant(game:Node)->int:
 var coop=game.get("realm_id")!=null
 if str(game.get("mode")) not in ["run","coop"]:return 0
 var manager=game.get("expedition") if coop else game.get("waylight")
 if manager!=null:
  if manager.between():return 1
  if str(manager.kind)=="overcharge":return 2
 return 1 if str(game.get("realm_id")if coop else game.get("region_id"))=="between"else 0
static func clock(game:Node)->float:
 return float(game.get("visual_time"))if game.get("visual_time")!=null else float(game.get("visual_clock"))
static func rect(point:Vector2,camera:Vector2,size:Vector2=SIZE)->Rect2:
 # Preserve the established return/exit anchor: old portal was 80x120 at (-40,-76).
 return Rect2(point-camera-Vector2(size.x*.5,size.y*76.0/120.0),size)
static func is_training(game:Node)->bool:
 return str(game.get("region_id"))=="practice" or str(game.get("realm_id"))=="practice"
static func draw_at(canvas:CanvasItem,game:Node,point:Vector2,camera:Vector2,size:Vector2=SIZE,muted:bool=false)->void:
 if is_training(game):return
 var target=rect(point,camera,size)
 var view:Vector2=game.get("VIEW")
 if not target.intersects(Rect2(Vector2.ZERO,view).grow(8)):return
 canvas.draw_texture_rect(texture(variant(game),clock(game),muted),target,false,Color("#88939b")if muted else Color.WHITE)
static func entry(canvas:CanvasItem,game:Node,point:Vector2,camera:Vector2)->void:
 if is_training(game):
  preload("res://scripts/training_exit258.gd").draw(canvas,point-camera);return
 # The Between has one shared entrance/extraction crossing, drawn by its ground pass.
 if variant(game)==1:return
 draw_at(canvas,game,point,camera)
static func custom_exit(game:Node)->bool:
 var a=game.adventure
 return a.school.active or a.tech.active or a.cinder.active or a.foundry.active or a.vault.active or a.active or a.finale.enabled and a.finale.mode!="dormant"
static func draw_coop(canvas:CanvasItem,game:Node,camera:Vector2)->void:
 if game.mode!="coop" or variant(game)==1:return
 draw_late_exits(canvas,game,camera)
 if game.portal_points258.has("ReturnGate"):entry(canvas,game,game.portal_points258.ReturnGate,camera)
 if custom_exit(game):return
 var a=game.adventure;var ready=a.immersive.done if a.immersive.active else game.wave>=3 and game.opponents.is_empty()
 if ready and game.portal_points258.has("Boss"):draw_at(canvas,game,game.portal_points258.Boss,camera)

static func duplicate_exit(game:Node)->bool:
 var a=game.adventure;var point=game.pair(game.region.boss)
 for owner in [a.school,a.tech,a.cinder]:
  if owner.active and owner.done and point.distance_to(Vector2(owner.data.exit[0],owner.data.exit[1]))<1:return true
 return a.foundry.active and a.foundry.done and point.distance_to(a.foundry.EXIT)<1
static func draw_late_exits(canvas:CanvasItem,game:Node,camera:Vector2)->void:
 # Oath and Chimevault labels live in the overlay pass; paint frames beneath actors.
 var a=game.adventure
 if a.vault.active:draw_at(canvas,game,a.vault.gates[2],camera,SIZE,a.vault.stage!=2 or not a.foes().is_empty())
 if a.active:
  for portal in a.portals():draw_at(canvas,game,portal.pos,camera)
  if a.complete:draw_at(canvas,game,a.OATH_EXIT,camera)
 var f=a.finale
 if f.enabled and f.mode!="dormant":
  if f.mode=="gate" or not f.owns(f.local_point()):draw_at(canvas,game,f.OLD_EXIT,camera)
  if f.mode=="won":draw_at(canvas,game,f.EXIT,camera)
