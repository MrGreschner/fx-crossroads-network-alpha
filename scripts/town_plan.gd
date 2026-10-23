extends RefCounted
## One street graph: civic square, service street, creative campus and southern walk.
## Each building has a short doorstep spur; no roads cross a river except the bridge.
const ROADS=[
 [Vector2(1240,2152),Vector2(1130,2152),Vector2(1130,2380),Vector2(1580,2380),Vector2(1610,2300),Vector2(1650,2300)],
 [Vector2(1405,2660),Vector2(1580,2660),Vector2(1580,2380)],
 [Vector2(2000,2080),Vector2(2160,2080),Vector2(2160,2236)],
 [Vector2(1600,1740),Vector2(1700,1740),Vector2(1700,2080),Vector2(2000,2080),Vector2(2000,2020)],
 [Vector2(-1030,540),Vector2(-1030,900)],
 [Vector2(-580,490),Vector2(-580,775),Vector2(-180,775)],
 [Vector2(-100,1680),Vector2(-100,1740)],
 [Vector2(900,300),Vector2(900,640)],
 [Vector2(900,640),Vector2(1040,640),Vector2(1040,850)],
 [Vector2(450,850),Vector2(2110,850)],
 [Vector2(600,570),Vector2(600,850)],
 [Vector2(1290,635),Vector2(1290,850)],
 [Vector2(1960,740),Vector2(1960,850)],
 [Vector2(1580,790),Vector2(1580,850)],
 [Vector2(760,850),Vector2(760,1180)],
 [Vector2(-1080,1200),Vector2(-1000,1200),Vector2(-1000,900),Vector2(760,900)],
 [Vector2(-180,775),Vector2(-180,900)],
 [Vector2(130,900),Vector2(-125,900),Vector2(-125,1280),Vector2(130,1280)],
 [Vector2(1150,1150),Vector2(1150,1180)],
 [Vector2(420,530),Vector2(420,850)],
 [Vector2(760,1180),Vector2(2220,1180),Vector2(2220,1150),Vector2(2510,1150)],
 [Vector2(1470,850),Vector2(1470,1180)],
 [Vector2(1650,1050),Vector2(1650,1180)],
 [Vector2(2090,1135),Vector2(2090,1180)],
 [Vector2(600,1155),Vector2(600,1180),Vector2(760,1180)],
 [Vector2(550,1560),Vector2(550,1740)],
 [Vector2(-530,1375),Vector2(-530,1380),Vector2(-420,1380),Vector2(-420,1740),Vector2(1600,1740)],
 [Vector2(-1000,1200),Vector2(-850,1200),Vector2(-850,1375),Vector2(-530,1375)],
 [Vector2(-210,900),Vector2(-210,1350),Vector2(-530,1350),Vector2(-530,1375)],
 [Vector2(-210,1350),Vector2(130,1350),Vector2(130,1280)],
 [Vector2(-1080,800),Vector2(-850,800),Vector2(-850,900)],
 [Vector2(-1000,2080),Vector2(-560,2080),Vector2(-560,1740),Vector2(-420,1740)],
 [Vector2(325,2030),Vector2(325,2120),Vector2(100,2120),Vector2(100,1740)],
 [Vector2(900,1615),Vector2(900,1740)],
 [Vector2(1375,1520),Vector2(1375,1740)],
 [Vector2(1800,1550),Vector2(1800,1645),Vector2(1600,1645),Vector2(1600,1740)],
 [Vector2(1600,1180),Vector2(1600,1645)],
 [Vector2(2175,1580),Vector2(2175,1645),Vector2(1800,1645)]
]
const LOTS=[Rect2(1820,1720,360,310),Rect2(-1300,205,540,365),Rect2(-750,200,340,300),Rect2(2530,300,450,410),Rect2(-255,1390,310,320),Rect2(-550,430,770,380),Rect2(490,885,230,250),Rect2(-850,935,630,480),Rect2(-1240,1650,480,490),Rect2(-340,1740,320,310),Rect2(160,1740,330,320)]
static func reserved(p:Vector2)->bool:
 if Rect2(-500,1390,170,390).has_point(p):return true
 if Rect2(-125,905,510,420).has_point(p):return true
 if preload("res://scripts/town_neighborhood.gd").reserved(p):return true
 if Rect2(630,445,570,410).has_point(p):return true
 for lot in LOTS:
  if lot.has_point(p):return true
 for route in ROADS:
  for n in range(1,route.size()):
   if Geometry2D.get_closest_point_to_segment(p,route[n-1],route[n]).distance_to(p)<82:return true
 return false
func apply(g:Node)->void:
 g.ground_patches.clear();g.ground_tile_cache.clear();g.ground_index.invalidate()
 # Soft corners come from octagonal junctions using the same path tile.
 for route in ROADS+preload("res://scripts/town_neighborhood.gd").ROADS:
  for n in range(1,route.size()):
   var a:Vector2=route[n-1];var b:Vector2=route[n];var side:Vector2=(b-a).normalized().orthogonal()*38
   g.ground_patches.append({"polygon":PackedVector2Array([a-side,b-side,b+side,a+side]),"tile":"path"})
  for point in route:
   var polygon=PackedVector2Array()
   for n in 12:polygon.append(point+Vector2.from_angle(n*TAU/12)*38)
   g.ground_patches.append({"polygon":polygon,"tile":"path"})
 # Compact central gathering square leaves room for the well and hall entrance.
 var civic=PackedVector2Array([Vector2(680,565),Vector2(1100,565),Vector2(1100,625),Vector2(1200,625),Vector2(1200,810),Vector2(1165,845),Vector2(680,845),Vector2(640,810),Vector2(640,625),Vector2(680,625)])
 g.ground_patches.append({"polygon":civic,"tile":"path"})
 for court in [preload("res://scripts/town_neighborhood.gd").COURT,Rect2(-745,1350,430,70),Rect2(-1170,2015,340,82),Rect2(200,1985,250,62)]:
  g.ground_patches.append({"polygon":PackedVector2Array([court.position,Vector2(court.end.x,court.position.y),court.end,Vector2(court.position.x,court.end.y)]),"tile":"path"})
 if g.terrain_cache!=null:g.terrain_cache.reset()
func draw_ground(g:Node2D,camera:Vector2)->void:
 var view:=Rect2(camera,g.VIEW).grow(180)
 # Use the same textured paths as the streets; only a quiet curb outlines the square.
 var border=PackedVector2Array([Vector2(680,565),Vector2(1100,565),Vector2(1100,625),Vector2(1200,625),Vector2(1200,810),Vector2(1165,845),Vector2(680,845),Vector2(640,810),Vector2(640,625),Vector2(680,625),Vector2(680,565)])
 if view.intersects(Rect2(640,565,560,280)):
  var screen=PackedVector2Array()
  for point in border:screen.append(point-camera)
  g.draw_polyline(screen,Color("#ccba8b"),2,true)
 # Deliberate garden islands and seats, set away from doors and the continuous walks.
 for spot in [Vector2(-730,1880),Vector2(220,1640),Vector2(1780,1250)]:
  if not view.has_point(spot):continue
  var p:Vector2=spot-camera
  g.draw_rect(Rect2(p-Vector2(42,18),Vector2(84,40)),Color("#6a684e"));g.draw_rect(Rect2(p-Vector2(42,18),Vector2(84,40)),Color("#b7a379"),false,2)
  for n in 7:
   var flower:Vector2=p+Vector2(-31+n*10,-4+sin(n*2)*4)
   g.draw_line(flower,flower+Vector2(0,13),Color("#7bac76"),2);g.draw_circle(flower,4,Color("#e3c1d3") if n%2 else Color("#ead498"))
  var bench:Vector2=p+Vector2(0,48)
  g.draw_rect(Rect2(bench-Vector2(32,10),Vector2(64,12)),Color("#aa825b"));g.draw_line(bench-Vector2(32,18),bench+Vector2(32,-18),Color("#cfaa7a"),5)
  for x in [-25,25]:g.draw_line(bench+Vector2(x,2),bench+Vector2(x,13),Color("#5b6153"),4)

