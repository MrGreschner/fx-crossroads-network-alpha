extends RefCounted
## V246: shared static atlases, visible-region draws, no effects/nodes per object.
const ROOT="res://assets/town246/"
const RIDGE=Rect2(-1650,550,430,900)
const COURT=Rect2(1200,1700,650,266)
const SEATS=[Vector2(1310,1824),Vector2(1610,1900)]
static var sheets:Dictionary={}
static var frames:Dictionary={}
static var crop_specs:Dictionary={}
static func prepare(kind:String)->void:
 if kind=="crops":
  if crop_specs.is_empty():crop_specs=JSON.parse_string(FileAccess.get_file_as_string("res://assets/garden246/frames.json"))
  return
 if sheets.has(kind):return
 var prefix="res://assets/garden246/" if kind=="crops" else ROOT
 var file="frames.json" if kind=="crops" else "scenery.json"
 var specs=JSON.parse_string(FileAccess.get_file_as_string(prefix+file))
 var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes(prefix+kind+".png"))
 var sheet=ImageTexture.create_from_image(im);sheets[kind]=sheet
 for id in specs:
  var a=specs[id];var at=AtlasTexture.new();at.atlas=sheet;at.region=Rect2(a[0],a[1],a[2],a[3]);frames[kind+":"+id]=at
static func texture(id:String,kind:String="scenery")->Texture2D:
 prepare(kind)
 var key=kind+":"+id
 if kind=="crops" and not frames.has(key) and crop_specs.has(id):
  var spec=crop_specs[id];var page="crops"+str(int(spec.page))
  if not sheets.has(page):
   var im=Image.new();im.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/garden246/"+page+".png"));sheets[page]=ImageTexture.create_from_image(im)
  var region=spec.region;var at=AtlasTexture.new();at.atlas=sheets[page];at.region=Rect2(region[0],region[1],region[2],region[3]);frames[key]=at
 return frames.get(key)
static func legacy_path(path:String)->Texture2D:
 if not path.begins_with("res://assets/seedhouse/"):return null
 return texture(path.get_file().get_basename(),"crops")
static func draw(g:CanvasItem,id:String,r:Rect2,tint:Color=Color.WHITE)->void:
 if not Rect2(Vector2.ZERO,g.get_viewport_rect().size).intersects(r):return
 var t=texture(id)
 if t!=null:g.draw_texture_rect(t,r,false,tint)
static func crop_stage(b:Dictionary,stamp:float)->int:
 if stamp>=float(b.end):return 2
 var duration=maxf(1,float(b.get("duration",float(b.end)-float(b.start))))
 return 1 if (stamp-float(b.start))/duration<.55 else 2
static func crop_tint(b:Dictionary,stamp:float)->Color:
 return Color.WHITE if stamp>=float(b.end) else Color(.86,.95,.83)
static func cliffs(g:Node2D,camera:Vector2)->void:
 draw(g,"ridge",Rect2(RIDGE.position-camera,RIDGE.size))
 # Two low shoulders physically link the existing entrance rockwork to the massif.
 # Neither covers an entrance, the Lodge, or the eastern approach lane.
 for spec in [Rect2(-1370,662,185,160),Rect2(-1334,1040,157,200)]:
  draw(g,"ridge_foot",Rect2(spec.position-camera,spec.size),Color(.87,.92,.88))
 for x in [-1205,-965]:draw(g,"descent_pillar",Rect2(Vector2(x-20,1057)-camera,Vector2(40,150)))
static func ground(g:Node2D,camera:Vector2)->void:
 preload("res://scripts/town_terrain247.gd").civic(g,camera)
 draw(g,"rest_court",Rect2(COURT.position-camera,COURT.size))
static func rest_details(g:Node2D,camera:Vector2)->void:
 var view=Rect2(camera,g.VIEW).grow(110)
 for p in SEATS:
  if view.has_point(p):preload("res://scripts/town_streets244.gd").bench(g,p-camera,76,-21,35)
 # Paired low planting beds hold the court edges; street entrances stay open.
 for p in [Vector2(1265,1785),Vector2(1790,1888)]:
  if view.has_point(p):
   preload("res://scripts/town_nature243.gd").draw(g,"garden_bed",Rect2(p-camera-Vector2(34,9),Vector2(68,26)))
   for n in 3:preload("res://scripts/town_nature243.gd").draw(g,"shrub",Rect2(p-camera+Vector2(-31+n*20,-25),Vector2(23,30)))
static func scatter(chunk:Node,tx:int,ty:int,local:Vector2,g:Node)->void:
 # Deterministic hashed jitter + sparse rejection. No straight flower rows, RNG or per-frame work.
 var h=posmod(tx*73856093^ty*19349663,2147483647)
 if h%13!=2:return
 var offset=Vector2(8+posmod(h/17,43),8+posmod(h/83,39))
 var world=Vector2(tx*64,ty*64)+offset
 if preload("res://scripts/town_plan.gd").reserved(world) or preload("res://scripts/town_refresh46.gd").reserved(world) or not g.can_stand_at(world):return
 var t=texture("wildflower"+str(h%6))
 chunk.overlays.append([t,Rect2(local+offset-Vector2(14,26),Vector2(28,28))])
