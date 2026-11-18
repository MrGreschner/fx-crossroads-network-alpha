extends RefCounted
## Terrain and dock art are baked from the same shoreline and deck layout used for collision.
const ROOT="res://assets/tidecross360/"
const MARINA=preload("res://scripts/marina_art250.gd")
const NATURE=preload("res://scripts/town_nature243.gd")
const ICE=preload("res://scripts/town_winter358.gd")
const SCENE=Rect2(1170,2860,1650,1390)
static var layout:Dictionary={}
static var textures:Dictionary={}
static var ice_water:CanvasTexture
static var sea:CanvasTexture
static var river:CanvasTexture

static func prepare()->void:
 if not layout.is_empty():return
 layout=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"layout.json"))
 for i in layout.docks.size():
  var r:Array=layout.docks[i]
  layout.docks[i]=Rect2(r[0],r[1],r[2],r[3])

static func material(path:String)->CanvasTexture:
 var bitmap=Image.new()
 if bitmap.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK:return null
 var mat=CanvasTexture.new()
 mat.diffuse_texture=ImageTexture.create_from_image(bitmap)
 mat.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
 return mat

static func texture(id:String)->Texture2D:
 if textures.has(id):return textures[id]
 var im=Image.new()
 var error=im.load_webp_from_buffer(FileAccess.get_file_as_bytes(ROOT+id+".webp")) if id in ["summer","winter","spring","fall"] else im.load_png_from_buffer(FileAccess.get_file_as_bytes(ROOT+id+".png"))
 if error!=OK:return null
 textures[id]=ImageTexture.create_from_image(im)
 return textures[id]

static func coordinate(series:Array,at:float,axis:int)->float:
 var other=1-axis
 for i in range(1,series.size()):
  var end:Array=series[i]
  if at<=float(end[axis]):
   var start:Array=series[i-1]
   return lerpf(float(start[other]),float(end[other]),clampf(inverse_lerp(float(start[axis]),float(end[axis]),at),0,1))
 return float(series[-1][other])

static func west_bank(y:float)->float:
 prepare()
 return coordinate(layout.west_bank,y,1)

static func coast_at(x:float)->float:
 prepare()
 return coordinate(layout.coast,x,0)

static func ridge_at(y:float)->float:
 prepare()
 return coordinate(layout.ridge_foot,y,1)

static func on_dock(p:Vector2)->bool:
 prepare()
 for r in layout.docks:
  if r.has_point(p):return true
 return false

static func solid_land(p:Vector2)->bool:
 return p.x>ridge_at(p.y) and p.x<west_bank(p.y) and p.y<coast_at(p.x)

static func polygon(c:Node2D,points:Array,cam:Vector2,art:Texture2D,tint:Color,drift:Vector2,span:float,fade:bool=false)->void:
 var vertices=PackedVector2Array()
 var uv=PackedVector2Array()
 var shades=PackedColorArray()
 for a in points:
  var p=Vector2(a[0],a[1])
  vertices.append(p-cam)
  uv.append((p+drift)/span)
  var shade=tint
  if fade:shade.a*=1.0-smoothstep(3520.0,3822.0,p.y)
  shades.append(shade)
 c.draw_polygon(vertices,shades,uv,art)

static func draw_water(c:Node2D,cam:Vector2,view:Rect2,season:String)->void:
 prepare()
 if sea==null:
  sea=material("res://assets/lake301/deep_water.png")
  river=material("res://assets/town247/water.png")
  ice_water=CanvasTexture.new()
  ice_water.diffuse_texture=ICE.texture("ice")
  ice_water.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
 var clock:float=c.town_life.clock
 var liquid=SCENE.intersection(view)
 if not liquid.has_area():return
 var y0=liquid.position.y
 var y1=view.end.y
 var x0=SCENE.position.x
 var x1=SCENE.end.x
 var frame=[[x0,y0],[x1,y0],[x1,y1],[x0,y1]]
 polygon(c,frame,cam,sea,Color("#d1e3e4"),Vector2(clock*11,clock*7),295)
 if y1>3734:
  var y=maxf(y0,3734)
  for ends in [[view.position.x,x0],[x1,view.end.x]]:
   if ends[1]<=ends[0]:continue
   var fringe=[[ends[0],y],[ends[1],y],[ends[1],y1],[ends[0],y1]]
   polygon(c,fringe,cam,sea,Color("#d1e3e4"),Vector2(clock*11,clock*7),295)
 var outline:Array=layout.west_bank.duplicate()
 var right:Array=layout.east_bank.duplicate()
 if season=="Winter":
  # The tide breaks up the last shelf at the mouth, leaving jagged ice edges.
  outline.pop_back()
  right.pop_back()
  outline.append_array([[2145,3781],[2170,3798],[2206,3785],[2248,3809],[2290,3793],[2335,3811],[2366,3791],[2400,3807],[2444,3789],[2482,3802],[2510,3783],[2548,3798],[2590,3780],[2633,3795],[2663,3770]])
  right.reverse()
  outline.append_array(right)
  polygon(c,outline,cam,ice_water,Color("#bbd5df"),Vector2.ZERO,128)
  for n in 11:
   var x=2183+n*43
   var y=3812+posmod(n*27,43)+sin(clock*.37+n)*3
   var floe=[[x-4,y],[x+5,y-5],[x+17,y-1],[x+15,y+6],[x+1,y+7]]
   polygon(c,floe,cam,ice_water,Color("#9fbfcb"),Vector2.ZERO,128)
 else:
  right.reverse()
  outline.append_array(right)
  polygon(c,outline,cam,river,Color(.78,.93,.91,.67),Vector2(0,-clock*13.0),180,true)
 c.draw_texture_rect(texture("shallows"),Rect2(SCENE.position-cam,SCENE.size),false,Color(1,1,1,.58 if season=="Winter" else .91))
 # Offshore swells advance in curved crests and fade between passes.
 for row in 6:
  for col in 8:
   var x=1180+col*208+sin(float(row)*1.7+col)*38
   var phase=fposmod(clock*.20+float(row)*.18+float(col)*.11,1.0)
   var at=Vector2(x+phase*17,3919+float(row)*54+(1-phase)*38)
   if not view.has_point(at):continue
   var opacity=sin(phase*PI)*.19
   var curve=PackedVector2Array()
   for j in 13:
    var k=float(j)/12.0
    curve.append(at+Vector2(k*(63+posmod(col*43+row*14,65)),5*sin(k*PI)+1.8*sin(k*TAU+col))-cam)
   c.draw_polyline(curve,Color(.67,.88,.88,opacity),2.0)
   if row%3==0:c.draw_polyline(curve,Color(.88,.96,.92,opacity*.61),1.0)
 # Breakers track the irregular base of the cliff and reach it in successive bands.
 for row in 3:
  var phase=fposmod(clock*.24+float(row)/3.0,1.0)
  var dx=sin(clock*.9+row)*3
  for x in range(1180,2120,27):
   var coast=coast_at(float(x))
   var y=coast+51+phase*30+6*sin(x*.058+clock*2.0)
   var p=Vector2(x+dx,y)
   if not view.has_point(p):continue
   var length=float(12+posmod(x*37+row*19,24))
   var tip=Vector2(x+length,coast_at(x+length)+51+phase*30+6*sin((x+length)*.058+clock*2.0))
   c.draw_line(p-cam,tip-cam,Color(.78,.92,.91,pow(sin(phase*PI),2)*.38),2.0)
   if posmod(x+row,3)==0:c.draw_circle(p-cam+Vector2(8,3),1.5,Color(.79,.94,.91,.16))

static func draw_terrain(c:Node2D,cam:Vector2,season:String)->void:
 var frame=Rect2(SCENE.position-cam,SCENE.size)
 c.draw_texture_rect(texture(season.to_lower()),frame,false)
 c.draw_texture_rect(texture("piers"),frame,false)

static func near_road(p:Vector2,clearance:float)->bool:
 prepare()
 for road in layout.roads:
  var points:Array=road[1]
  for i in range(1,points.size()):
   var s:Vector2=Vector2(points[i-1][0],points[i-1][1])
   var e:Vector2=Vector2(points[i][0],points[i][1])
   if p.distance_to(Geometry2D.get_closest_point_to_segment(p,s,e))<float(road[0])*.5+clearance:return true
 return false

static func shore_plants(c:Node2D,cam:Vector2,view:Rect2,season:String)->void:
 for side in [-1,1]:
  for n in 34:
   var y=2878+n*27+posmod(n*53,16)
   var x=west_bank(y)-12 if side==-1 else coordinate(layout.east_bank,y,1)+13
   var p=Vector2(x+side*float(posmod(n*21,14)),y)
   if not view.has_point(p) or on_dock(p) or near_road(p,4):continue
   var h=25+posmod(n*17,25)
   var rect=Rect2(p-cam-Vector2(9,h-5),Vector2(22,h))
   NATURE.draw(c,"reeds",rect,Color("#b3c8cf") if season=="Winter" else Color("#d7dec5") if n%3==0 else Color.WHITE)

static var shoreline_rocks:AtlasTexture
static func draw_shore_rocks(c:CanvasItem,p:Vector2,size:Vector2)->void:
 if shoreline_rocks==null:
  var src=Image.new()
  if src.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/lake301/props.png"))!=OK:return
  shoreline_rocks=AtlasTexture.new()
  shoreline_rocks.atlas=ImageTexture.create_from_image(src)
  shoreline_rocks.region=Rect2(640,384,128,128)
 c.draw_texture_rect(shoreline_rocks,Rect2(p-Vector2(size.x*.5,size.y*.63),size),false)
