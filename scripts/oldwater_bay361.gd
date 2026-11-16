extends RefCounted
## The lake drains south into the same channel that crosses town.
const BOUNDS=Rect2(1900,-4080,3000,3550)
const ARRIVAL=Vector2(3260,-2010)
const FERRY=Vector2(3310,-1920)
const BERTH=Vector2(3150,-2072)
const DOCK=Rect2(2944,-2100,290,58)
const CABIN=Rect2(3370,-2260,182,166)
const CABIN_DOOR=Vector2(3460,-2080)
const LAMPS=[Vector2(3240,-2044),Vector2(3330,-1905),Vector2(3430,-2081),Vector2(2970,-2052),Vector2(2885,-1552)]
const BANKS_WEST=[Vector2(1900,-4080),Vector2(1900,-3240),Vector2(1960,-2800),Vector2(2020,-2540),Vector2(2118,-2320),Vector2(2190,-2070),Vector2(2230,-1830),Vector2(2180,-1590),Vector2(2224,-1330),Vector2(2250,-1080),Vector2(2240,-840),Vector2(2280,-530)]
const BANKS_EAST=[Vector2(4730,-4080),Vector2(4570,-3690),Vector2(4460,-3310),Vector2(4390,-3080),Vector2(4200,-2830),Vector2(4080,-2680),Vector2(3870,-2560),Vector2(3672,-2455),Vector2(3503,-2340),Vector2(3290,-2210),Vector2(3110,-2080),Vector2(2925,-1940),Vector2(2750,-1800),Vector2(2660,-1620),Vector2(2580,-1460),Vector2(2535,-1220),Vector2(2500,-960),Vector2(2475,-700),Vector2(2440,-530)]
const ICE_EDGE=[Vector2(2211,-1836),Vector2(2275,-1847),Vector2(2350,-1814),Vector2(2430,-1837),Vector2(2505,-1783),Vector2(2588,-1817),Vector2(2670,-1790),Vector2(2763,-1810)]
const SLOTS=[Vector2(2680,-1975),Vector2(2435,-2220),Vector2(3150,-2430),Vector2(2745,-2710),Vector2(3510,-2890)]
const POOLS=["oldwater_walk_ice_reeds","oldwater_walk_ice_mid","oldwater_walk_ice_edge"]
const SNOW=[
 [2587,-2043,132,62],[2427,-2189,93,62],[2930,-2216,154,86],[3140,-2439,135,70],
 [2300,-2490,122,90],[2750,-2730,110,74],[3235,-2668,128,76],[3525,-2890,180,73],
 [2380,-3010,160,94],[2835,-3150,179,90],[3345,-3180,146,83],[3730,-3320,215,93],
 [2190,-3510,176,81],[2810,-3630,192,93],[3420,-3600,242,137],[4130,-3720,193,103],
 [3935,-2840,139,69],[3690,-2620,83,54],[2210,-2230,64,37],[3120,-2900,77,45],
 [2595,-2880,105,62],[3740,-3030,99,57],[2490,-3340,133,62],[3090,-3410,105,70]
]
const ROAD=[Vector2(2760,-532),Vector2(2750,-755),Vector2(2700,-975),Vector2(2725,-1215),Vector2(2785,-1450),Vector2(2890,-1670),Vector2(3040,-1850),Vector2(3260,-2010),Vector2(3460,-2080)]
const NATURE=preload("res://scripts/town_nature243.gd")
const MARINA=preload("res://scripts/marina_art250.gd")
const COAST=preload("res://scripts/tidecross_coast360.gd")
const COLD=preload("res://scripts/town_winter358.gd")
const UI=preload("res://scripts/studio_ui.gd")
const ACTORS=preload("res://scripts/town_cast230.gd")
static var water_material:CanvasTexture
static var ice_material:CanvasTexture
static var snow_material:CanvasTexture
static var grasses:Dictionary={}
static var dirt:CanvasTexture
static var stones:CanvasTexture
static var water_shape=PackedVector2Array()
static var ice_shape=PackedVector2Array()
static var west_land=PackedVector2Array()
static var east_land=PackedVector2Array()
static var trees:Array=[]
static var rocks:Array=[]

static func bank_x(bank:Array,y:float)->float:
 for i in range(1,bank.size()):
  var a:Vector2=bank[i-1]
  var b:Vector2=bank[i]
  if y<=b.y:return lerpf(a.x,b.x,clampf(inverse_lerp(a.y,b.y,y),0,1))
 return bank[-1].x

static func prepare_geometry()->void:
 if not water_shape.is_empty():return
 water_shape=PackedVector2Array(BANKS_WEST)
 var east=BANKS_EAST.duplicate()
 east.reverse()
 water_shape.append_array(PackedVector2Array(east))
 west_land=PackedVector2Array(BANKS_WEST)
 west_land.append(Vector2(BOUNDS.position.x,BOUNDS.end.y))
 east_land=PackedVector2Array(BANKS_EAST)
 east_land.append(Vector2(BOUNDS.end.x,BOUNDS.end.y))
 east_land.append(Vector2(BOUNDS.end.x,BOUNDS.position.y))
 var ice: Array=[]
 for p in BANKS_WEST:
  if p.y<ICE_EDGE[0].y:ice.append(p)
 ice.append_array(ICE_EDGE)
 for p in east:
  if p.y<ICE_EDGE[-1].y:ice.append(p)
 ice_shape=PackedVector2Array(ice)

static func ice_at(p:Vector2)->bool:
 if p.y> -1760 or not BOUNDS.has_point(p):return false
 prepare_geometry()
 return Geometry2D.is_point_in_polygon(p,ice_shape)

static func snow_at(p:Vector2)->bool:
 for patch in SNOW:
  if ((p-Vector2(patch[0],patch[1]))/Vector2(patch[2],patch[3])).length_squared()<=1.0:return true
 return false

static func grounded(p:Vector2,frozen:bool)->bool:
 if DOCK.has_point(p):return true
 if Rect2(CABIN.position+Vector2(11,72),Vector2(CABIN.size.x-22,81)).has_point(p):return false
 if p.x<bank_x(BANKS_WEST,p.y) or p.x>bank_x(BANKS_EAST,p.y):return true
 return frozen and ice_at(p)

static func slippery(p:Vector2)->bool:
 return not DOCK.has_point(p) and ice_at(p) and not snow_at(p)

static func glide(current:Vector2,desired:Vector2,delta:float)->Vector2:
 return current.lerp(desired*1.08,1.0-exp(-delta*(5.8 if not desired.is_zero_approx() else 4.2)))

static func rotation(day:int)->int:return posmod(floori(float(day)/14.0),SLOTS.size())

static func spot(standard:Dictionary,day:int)->Dictionary:
 var id=str(standard.get("id",""))
 var index=POOLS.find(id)
 if index<0:return standard
 var p:Vector2=SLOTS[posmod(rotation(day)+index*2,SLOTS.size())]
 var result=standard.duplicate()
 result.bank=[p.x,p.y+24]
 result.water=[p.x,p.y]
 result.cove_rotation=rotation(day)
 return result

static func visitor(weekday:int,hour:float)->Vector2:
 if (weekday in [0,3] and hour>=6.0 and hour<10.25) or (weekday==5 and hour>=15.0 and hour<18.5):
  return Vector2(3010,-2078)
 return Vector2.INF

static func visitor_spot(weekday:int,hour:float,day:int,winter:bool)->Vector2:
 var spot=visitor(weekday,hour)
 if spot!=Vector2.INF and winter:
  return Vector2(SLOTS[rotation(day)])+Vector2(32,21)
 return spot

static func meet(g:Node)->bool:
 var p:Vector2=g.position_in_world
 var clock=g.town_life.calendar
 var winter=COLD.SEASON.active(g)
 if p.distance_to(BERTH)<70:
  g.hint="Lake voyages resume at thaw" if winter else "E • Begin an Oldwater Lake adventure"
  if not winter and Input.is_action_just_pressed("interact"):g.voyage.open_menu("pier")
  return true
 if p.distance_to(CABIN_DOOR)<66:
  g.hint="E • Read the Outback Cabin log"
  if Input.is_action_just_pressed("interact"):
   var ui=g.presentation
   ui.window("Outback Cabin","town_conversation")
   ui.label(ui.content,"Outback Cabin",24)
   ui.label(ui.content,"The cabin log tracks the bay. Ice fishing holes rotate every two Crossroads weeks. Snow gives you firm footing on the lake.",17)
  return true
 if p.distance_to(visitor_spot(clock.weekday,clock.hour,clock.day_number,winter))<50:
  g.hint="E • Talk to the angler"
  if Input.is_action_just_pressed("interact"):
   var ui=g.presentation
   ui.window("Outback angler","town_conversation")
   ui.label(ui.content,"Outback angler",24)
   ui.label(ui.content,"Early is best. On a quiet morning you can hear the river before you see it.",17)
  return true
 return false

static func decorated_ground(season:String)->Texture2D:
 if grasses.has(season):return grasses[season]
 var terrain=preload("res://scripts/town_terrain247.gd").png("ground")
 if season=="Winter":terrain=COLD.SEASON.ground()
 elif season=="Spring":terrain=preload("res://scripts/spring_art357.gd").texture("town_ground")
 elif season=="Fall":terrain=preload("res://scripts/fall_art356.gd").texture("town_ground")
 var bitmap:Image=terrain.get_image().get_region(Rect2i(0,0,256,256))
 var mat=CanvasTexture.new()
 mat.diffuse_texture=ImageTexture.create_from_image(bitmap)
 mat.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
 grasses[season]=mat
 return mat

static func fill(c:Node2D,shape:PackedVector2Array,cam:Vector2,mat:Texture2D,tint:Color,scale:float,drift:Vector2=Vector2.ZERO)->void:
 var screen=PackedVector2Array()
 var uv=PackedVector2Array()
 for p in shape:
  screen.append(p-cam)
  uv.append((p+drift)/scale)
 c.draw_polygon(screen,PackedColorArray([tint]),uv,mat)

static func shore(c:Node2D,cam:Vector2,view:Rect2,bank:Array,side:float,winter:bool)->void:
 for i in range(1,bank.size()):
  var a:Vector2=bank[i-1]
  var b:Vector2=bank[i]
  if maxf(a.y,b.y)<view.position.y or minf(a.y,b.y)>view.end.y:continue
  for strip in [[30,Color("#70a29b")],[18,Color("#9da68d")],[7,Color("#b9b4a1")]]:
   var offset=Vector2(side*float(strip[0]),0)
   var contour=PackedVector2Array([a,b,b+offset,a+offset])
   var tint:Color=strip[1]
   if winter:tint=tint.lerp(Color("#b0c4cb"),.58)
   fill(c,contour,cam,stones,tint,224)
 for n in range(ceili(view.position.y/34),floori(view.end.y/34)+1):
  var y=clampf(n*34+posmod(n*53,21),BOUNDS.position.y+20,BOUNDS.end.y-22)
  var x=bank_x(bank,y)+side*(15+posmod(n*17,20))
  var p=Vector2(x,y)
  if not view.has_point(p) or DOCK.grow(15).has_point(p):continue
  if posmod(n,5)==0:
   COAST.draw_shore_rocks(c,p-cam,Vector2(38,25))
  else:
   var height=26+posmod(n*41,26)
   NATURE.draw(c,"reeds",Rect2(p-cam-Vector2(12,height-7),Vector2(24,height)),Color("#bacacf") if winter else Color.WHITE)

static func draw_trail(c:Node2D,cam:Vector2,view:Rect2,winter:bool)->void:
 var border=Color("#a4a89d") if winter else Color("#be9d76")
 var tread=Color("#c2c4b5") if winter else Color("#ddc5a2")
 var offset=Vector2(25,0)
 var route=PackedVector2Array()
 for p in ROAD:route.append(p-cam)
 c.draw_polyline(route,border,58,true)
 for i in range(1,ROAD.size()):
  var a:Vector2=ROAD[i-1]
  var b:Vector2=ROAD[i]
  if maxf(a.y,b.y)<view.position.y or minf(a.y,b.y)>view.end.y:continue
  fill(c,PackedVector2Array([a-offset,b-offset,b+offset,a+offset]),cam,dirt,tread,256)
 fill(c,PackedVector2Array([ARRIVAL+Vector2(-33,-7),BERTH+Vector2(0,-21),BERTH+Vector2(0,19),ARRIVAL+Vector2(9,32)]),cam,dirt,tread,256)

static func draw_ice(c:Node2D,cam:Vector2,view:Rect2)->void:
 fill(c,ice_shape,cam,ice_material,Color("#d1e3e8"),128)
 for i in range(1,ICE_EDGE.size()):
  c.draw_line(ICE_EDGE[i-1]-cam,ICE_EDGE[i]-cam,Color("#b6d8de"),2.0)
 for patch in SNOW:
  var center=Vector2(patch[0],patch[1])
  var extent=Vector2(patch[2],patch[3])
  if not view.intersects(Rect2(center-extent,extent*2)):continue
  var drift=PackedVector2Array()
  for n in 25:
   var a=n*TAU/24.0
   drift.append(center+Vector2.from_angle(a)*extent*(.90+.09*sin(n*2.31)))
  fill(c,drift,cam,snow_material,Color(.94,.97,1.0,.94),256)
 for y in range(ceili(view.position.y/158),floori(view.end.y/158)+1):
  for x in range(ceili(view.position.x/174),floori(view.end.x/174)+1):
   var p=Vector2(x*174+posmod(y*37,112),y*158+posmod(x*53,112))
   if not ice_at(p) or not ice_at(p+Vector2(45,-11)) or snow_at(p):continue
   c.draw_polyline(PackedVector2Array([p-cam,p-cam+Vector2(14,-7),p-cam+Vector2(29,-3),p-cam+Vector2(45,-11)]),Color("#83a8b8",.68),1.5)

static func ellipse_clear_tree(rect:Rect2,p:Vector2)->bool:
 if CABIN.grow(48).intersects(rect) or DOCK.grow(30).intersects(rect):return false
 if rect.grow(45).has_point(CABIN_DOOR) or rect.grow(45).has_point(FERRY):return false
 for i in range(1,ROAD.size()):
  if p.distance_to(Geometry2D.get_closest_point_to_segment(p,ROAD[i-1],ROAD[i]))<64:return false
 return true

static func forest(c:Node2D,cam:Vector2,view:Rect2)->void:
 if trees.is_empty():
  for row in 43:
   for col in 37:
    var n=row*37+col
    if posmod(n*17,13)<6:continue
    var p=Vector2(1910+col*81+posmod(n*71,55),-4040+row*82+posmod(n*83,53))
    if p.y>= -545 or not grounded(p,false):continue
    var size=Vector2(58+posmod(n*29,52),80+posmod(n*47,65))
    var rect=Rect2(p-Vector2(size.x*.5,size.y-10),size)
    if not ellipse_clear_tree(rect,p):continue
    if posmod(n,9)==0:rocks.append(p)
    else:trees.append([p,rect,["pine","ancient","pine","knot_willow","pine"][n%5]])
 for p in rocks:
  if view.has_point(p):COAST.draw_shore_rocks(c,p-cam,Vector2(65,42))
 for tree in trees:
  var r:Rect2=tree[1]
  if view.intersects(r):NATURE.tree(c,tree[2],Rect2(r.position-cam,r.size),tree[0])

static func pier(c:Node2D,cam:Vector2,winter:bool)->void:
 var screen=Rect2(DOCK.position-cam,DOCK.size)
 c.draw_rect(Rect2(screen.position+Vector2(3,9),screen.size).grow(2),Color("#263f49",.65))
 for p in [Vector2(2951,-2050),Vector2(3052,-2050),Vector2(3155,-2050),Vector2(3226,-2050)]:
  c.draw_rect(Rect2(p-cam-Vector2(4,12),Vector2(9,28)),Color("#554c3f"))
 var wood=MARINA.texture("dock_wood")
 for x in range(0,int(DOCK.size.x),128):
  var span=Vector2(minf(128,DOCK.size.x-x),DOCK.size.y)
  c.draw_texture_rect_region(wood,Rect2(screen.position+Vector2(x,0),span),Rect2(Vector2.ZERO,span),Color("#c6cccc") if winter else Color.WHITE)
 if not winter:
  var bow=Vector2(3035,-2158)-cam+Vector2(0,sin(c.town_life.clock*1.4)*3.0)
  c.draw_line(bow+Vector2(38,11),Vector2(3092,-2095)-cam,Color("#ad9270"),2)
  MARINA.boat(c,"launch_blue",bow,Vector2(77,139),1.36)

static func draw(c:Node2D,cam:Vector2,view:Rect2,season:String)->void:
 prepare_geometry()
 if water_material==null:
  water_material=COAST.material("res://assets/lake301/deep_water.png")
  stones=COAST.material("res://assets/lake301/granite.png")
  dirt=COAST.material("res://assets/lake301/gravel.png")
  ice_material=CanvasTexture.new()
  ice_material.diffuse_texture=COLD.texture("ice")
  ice_material.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
 var winter=season=="Winter"
 var grass=decorated_ground(season)
 fill(c,west_land,cam,grass,Color.WHITE,256)
 fill(c,east_land,cam,grass,Color.WHITE,256)
 fill(c,water_shape,cam,water_material,Color("#c3e2e2"),254,Vector2(c.town_life.clock*6.0,c.town_life.clock*6.0))
 shore(c,cam,view,BANKS_WEST,-1.0,winter)
 shore(c,cam,view,BANKS_EAST,1.0,winter)
 if winter:
  snow_material=decorated_ground("Winter")
  draw_ice(c,cam,view)
 else:
  for y in range(ceili(view.position.y/83),floori(view.end.y/83)+1):
   for x in range(ceili(view.position.x/137),floori(view.end.x/137)+1):
    var p=Vector2(x*137+sin(c.town_life.clock*.65+y)*13,y*83+posmod(x*42,57))
    if not Geometry2D.is_point_in_polygon(p,water_shape) or not Geometry2D.is_point_in_polygon(p+Vector2(42,0),water_shape):continue
    c.draw_line(p-cam,p-cam+Vector2(42,0),Color(.72,.89,.88,.17+.10*sin(c.town_life.clock+y+x)),1.2)
 draw_trail(c,cam,view,winter)
 forest(c,cam,view)
 if view.intersects(DOCK.grow(130)):pier(c,cam,winter)
 if view.intersects(CABIN.grow(36)):
  var art=NATURE.texture("cliff_cottage")
  var box=Rect2(CABIN.position-cam,CABIN.size)
  c.draw_texture_rect(art,box,false)
  if winter:c.draw_texture_rect(COLD.SEASON.roof("oldwater:outback",art),box,false)
  plaque(c,CABIN_DOOR-cam+Vector2(0,29),"OUTBACK CABIN",158)
 for p in LAMPS:
  if view.has_point(p):preload("res://scripts/town_props240.gd").lamp(c,p-cam,c.town_life.calendar.night_amount())
 for item in [[FERRY,"CROSSROADS  ↓"],[ARRIVAL+Vector2(-38,46),"OLDWATER BAY"],[BERTH+Vector2(-22,46),"LAKE ADVENTURES" if not winter else "WINTER LAKE"]]:
  if view.has_point(item[0]):plaque(c,item[0]-cam,item[1],170)
 var clock=c.town_life.calendar
 var fisher=visitor_spot(clock.weekday,clock.hour,clock.day_number,winter)
 if view.has_point(fisher):
  var p=fisher-cam
  ACTORS.draw(c,"guide",p,c.town_life.clock)
  c.draw_line(p+Vector2(-10,-19),p+Vector2(-27,-43),Color("#a2815f"),2.0)
  var bobber=p+Vector2(-32,-21) if winter else p+Vector2(-39,-39)
  c.draw_line(p+Vector2(-27,-43),bobber,Color("#bed2d1",.64),1.0)
  c.draw_circle(bobber,2,Color("#ce7c63"))

static func plaque(c:Node2D,p:Vector2,title:String,width:float)->void:
 var rect=Rect2(p-Vector2(width*.5,23),Vector2(width,30))
 preload("res://scripts/town_streets244.gd").plaque(c,rect)
 c.draw_string(UI.FONT,p-Vector2(width*.5,3),title,HORIZONTAL_ALIGNMENT_CENTER,width,14,Color("#f6deb0"))
