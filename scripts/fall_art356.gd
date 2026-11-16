extends RefCounted
## Fall-only palettes share the original UVs and world geometry.
const ROOT="res://assets/fall356/"
const TOWN_PLANTS=["ancient","starlace","amber_willow","apple","knot_willow","flowers","flowers_small","reeds","shrub"]
const LEAF_COLORS=[Color("#ab5738"),Color("#c9924b"),Color("#946242"),Color("#96713e")]
const ATLAS=preload("res://scripts/season_art_atlas.gd")
static var leaf_art:ImageTexture

static func active(game:Node)->bool:
 return game.town_life.calendar.season()=="Fall"

static func texture(id:String)->Texture2D:
 return ATLAS.texture(ROOT,id)

static func lake_plant(id:String)->Texture2D:
 return ATLAS.lake_plant(ROOT,id)

static func leaf()->Texture2D:
 if leaf_art==null:
  var im=Image.create(7,5,false,Image.FORMAT_RGBA8)
  var rows=["..xx...",".xxxx..","xxxxxx.","..xxx..","......x"]
  for y in rows.size():
   for x in rows[y].length():
    if rows[y][x]=="x":im.set_pixel(x,y,Color.WHITE if y<=1 else Color("#bdab98"))
  leaf_art=ImageTexture.create_from_image(im)
 return leaf_art

static func scatter(chunk:Node,tx:int,ty:int,local:Vector2)->void:
 var h=posmod(tx*73856093^ty*19349663,2147483647)
 if h%5>1:return
 for n in range(1+h%3):
  var p=local+Vector2(8+posmod(h/13+n*23,47),8+posmod(h/29+n*17,47))
  var size=Vector2(6+n,4)
  chunk.overlays.append([leaf(),Rect2(p,size),LEAF_COLORS[(h+n)%LEAF_COLORS.size()]])

static func gust(c:Node2D,camera:Vector2,seconds:float)->void:
 # World-space drift. A camera pan only reveals more of the field.
 var bounds=Rect2(camera,c.VIEW)
 var tile=Vector2(1360,920)
 for n in 15:
  var phase=seconds*(.8+float(n%3)*.13)+n
  var base=Vector2(fposmod(n*267.0-seconds*26+sin(phase)*17,tile.x),fposmod(n*179.0+seconds*14,tile.y))
  for ty in range(ceili((bounds.position.y-base.y)/tile.y),floori((bounds.end.y-base.y)/tile.y)+1):
   for tx in range(ceili((bounds.position.x-base.x)/tile.x),floori((bounds.end.x-base.x)/tile.x)+1):
    var p=(base+Vector2(tx,ty)*tile-camera).floor()
    c.draw_texture_rect(leaf(),Rect2(p,Vector2(7,2+absf(sin(phase))*3)),false,LEAF_COLORS[n%LEAF_COLORS.size()])

static func draw_shore(c:Node2D,camera:Vector2,view:Rect2,islands:Array)->void:
 var geo=preload("res://scripts/lake_geometry301.gd")
 if view.position.x<1120:
  for y in range(maxi(20,ceili(view.position.y/29)*29),mini(6780,ceili(view.end.y)),29):
   var coast=geo.coast_x(y)
   for n in range(2):
    var p=Vector2(coast-18-posmod(y*19+n*47,81),y+posmod(y*7+n*17,22))-camera
    c.draw_texture_rect(leaf(),Rect2(p,Vector2(8,5)),false,LEAF_COLORS[(y+n)%LEAF_COLORS.size()])
 for isle in islands:
  if not view.grow(float(isle.r)+24).has_point(isle.p):continue
  for n in 24:
   var angle=n*TAU/24+sin(n*4.7)*.10
   var p:Vector2=isle.p+Vector2.from_angle(angle)*maxf(0.0,geo.radius(isle,angle)-22-posmod(n*7,28))-camera
   c.draw_texture_rect(leaf(),Rect2(p,Vector2(9,6)),false,LEAF_COLORS[n%LEAF_COLORS.size()])
