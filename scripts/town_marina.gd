extends RefCounted
## A river-side inlet. Geometry is shared by visual rendering and town collision.
const WATER=[Vector2(2280,2290),Vector2(2170,2260),Vector2(1740,2260),Vector2(1660,2300),Vector2(1630,2390),Vector2(1640,2590),Vector2(1700,2680),Vector2(2140,2700),Vector2(2280,2660),Vector2(2440,2660),Vector2(2440,2290)]
const DECKS=[Rect2(1640,2275,570,53),Rect2(1810,2328,48,190),Rect2(2050,2328,48,190)]
const BERTHS=[{"at":Vector2(1740,2415),"crew":1,"angle":0.0,"hull":"#a16642","trim":"#e4bf83"},{"at":Vector2(1920,2430),"crew":3,"angle":0.0,"hull":"#365c70","trim":"#dfbb7e"},{"at":Vector2(2155,2430),"crew":3,"angle":0.0,"hull":"#766c46","trim":"#e8cc8a"},{"at":Vector2(1910,2610),"crew":1,"angle":PI/2,"hull":"#995d43","trim":"#d7b386"}]
static func wet(p:Vector2)->bool:return Geometry2D.is_point_in_polygon(p,PackedVector2Array(WATER))
static func on_deck(p:Vector2)->bool:
 for deck in DECKS:
  if deck.has_point(p):return true
 return false
static func blocked(p:Vector2)->bool:return wet(p) and not on_deck(p)
static func boat_size(crew:int)->Vector2:return Vector2(90,184) if crew==3 else Vector2(67,121)
static func hull_points(size:Vector2)->PackedVector2Array:
 var w=size.x*.5;var h=size.y*.5
 return PackedVector2Array([Vector2(0,-h),Vector2(w*.60,-h*.82),Vector2(w*.96,-h*.40),Vector2(w,h*.40),Vector2(w*.72,h*.88),Vector2(w*.36,h),Vector2(-w*.36,h),Vector2(-w*.72,h*.88),Vector2(-w,h*.40),Vector2(-w*.96,-h*.40),Vector2(-w*.60,-h*.82)])
static func transformed(points:PackedVector2Array,at:Vector2,angle:float)->PackedVector2Array:
 var result=PackedVector2Array()
 for p in points:result.append(p.rotated(angle)+at)
 return result
static func line(c:Node2D,at:Vector2,angle:float,a:Vector2,b:Vector2,color:Color,width:float)->void:c.draw_line(at+a.rotated(angle),at+b.rotated(angle),color,width,true)
static func boat(c:Node2D,at:Vector2,crew:int,angle:float,hull:Color,trim:Color,t:float)->void:
 var size=boat_size(crew);var h=size.y*.5;var w=size.x*.5;at.y+=sin(t*1.5+at.x*.01)*1.3
 var edge=transformed(hull_points(size),at,angle);var inner=transformed(hull_points(size-Vector2(15,18)),at,angle)
 c.draw_colored_polygon(transformed(hull_points(size+Vector2(8,2)),at+Vector2(4,7),angle),Color(.03,.12,.17,.35))
 c.draw_colored_polygon(edge,hull);c.draw_polyline(PackedVector2Array(Array(edge)+[edge[0]]),Color('#283e43'),3,true)
 c.draw_colored_polygon(inner,Color('#514e43'));c.draw_polyline(PackedVector2Array(Array(inner)+[inner[0]]),trim,4,true)
 # Long floor planks, thwarts, ribs and seat cushions.
 for x in [-16,-8,0,8,16]:line(c,at,angle,Vector2(x,-h*.62),Vector2(x,h*.72),Color('#877257'),2)
 for y in [-.55,-.22,.20,.56]:line(c,at,angle,Vector2(-w*.74,h*y),Vector2(w*.74,h*y),trim.darkened(.22),3)
 for y in ([-.32,.16,.63] if crew==3 else [.12]):
  var seat=PackedVector2Array([Vector2(-w*.79,h*y-7),Vector2(w*.79,h*y-7),Vector2(w*.79,h*y+7),Vector2(-w*.79,h*y+7)])
  c.draw_colored_polygon(transformed(seat,at,angle),trim);line(c,at,angle,Vector2(-w*.7,h*y-4),Vector2(w*.7,h*y-4),trim.lightened(.2),2)
 # Oarlocks, paired stowed oars, bow mooring eye, stern rudder/tiller.
 for side in [-1,1]:
  line(c,at,angle,Vector2(side*(w-6),-h*.25),Vector2(side*(w-10),h*.55),Color('#d4b27b'),3)
  line(c,at,angle,Vector2(side*(w-10),h*.34),Vector2(side*(w-10),h*.62),Color('#e0c494'),6)
  c.draw_circle(at+Vector2(side*w,0).rotated(angle),3,Color('#bfc6bc'))
 c.draw_arc(at+Vector2(0,-h*.80).rotated(angle),4,0,TAU,12,trim,2,true)
 if crew==3:
  line(c,at,angle,Vector2(0,h*.95),Vector2(0,h+13),Color('#352d2c'),7)
  line(c,at,angle,Vector2(0,h*.97),Vector2(13,h*.62),Color('#d1af7d'),4)
  line(c,at,angle,Vector2(-w*.55,h*.80),Vector2(w*.55,h*.80),trim,3)
static func draw(c:Node2D,cam:Vector2)->void:
 var view=Rect2(cam,c.VIEW).grow(100)
 if not view.intersects(Rect2(1540,2150,930,620)):return
 var t=Time.get_ticks_msec()/1000.0;var bank=PackedVector2Array(WATER.slice(0,9));var shifted=PackedVector2Array()
 for p in WATER:shifted.append(p-cam)
 # Cover the former grass and the old river bank at the inlet mouth.
 c.draw_colored_polygon(shifted,Color('#347889'))
 var shore=PackedVector2Array()
 for p in bank:shore.append(p-cam)
 c.draw_polyline(shore,Color('#6c8171'),19,true);c.draw_polyline(shore,Color('#b4ad83'),7,true)
 # Shallows follow the bank while the centre remains an open navigable channel.
 var shallow=PackedVector2Array()
 for p in bank:shallow.append(p.lerp(Vector2(1980,2460),.04)-cam)
 c.draw_polyline(shallow,Color('#509594',.7),14,true)
 for n in 53:
  var at=Vector2(1660+posmod(n*113,760),2305+posmod(n*67,355));at.x+=sin(t*.55+n)*5
  if wet(at) and not on_deck(at):c.draw_line(at-cam,at-cam+Vector2(12+posmod(n,3)*6,0),Color(.66,.87,.85,.28),1.5,true)
 # Mooring ropes lead to the fingers, away from the river channel.
 for ends in [[Vector2(1740,2360),Vector2(1815,2350)],[Vector2(1920,2340),Vector2(1855,2345)],[Vector2(2155,2340),Vector2(2095,2345)],[Vector2(1850,2610),Vector2(1834,2510)]]:
  var rope=PackedVector2Array([ends[0]-cam,(ends[0]+ends[1])*.5-cam+Vector2(0,5),ends[1]-cam]);c.draw_polyline(rope,Color('#c6b186'),2,true)
 for deck in DECKS:
  var rect=Rect2(deck.position-cam,deck.size);c.draw_rect(rect.grow(4),Color('#3a413b'));c.draw_rect(rect,Color('#a88a62'))
  for y in range(int(deck.position.y)+3,int(deck.end.y),13):
   c.draw_line(Vector2(deck.position.x,y)-cam,Vector2(deck.end.x,y)-cam,Color('#675943'),2)
   for x in [deck.position.x+6,deck.end.x-6]:c.draw_circle(Vector2(x,y+5)-cam,1.2,Color('#493f36'))
  c.draw_rect(rect,Color('#d4b782'),false,3)
  for p in [deck.position,deck.position+Vector2(deck.size.x,0),deck.end,deck.position+Vector2(0,deck.size.y)]:
   c.draw_circle(p-cam+Vector2(0,3),7,Color('#4e5044'));c.draw_circle(p-cam,5,Color('#dbc291'))
 for spec in BERTHS:boat(c,spec.at-cam,int(spec.crew),float(spec.angle),Color(spec.hull),Color(spec.trim),t)
 # Bank-side fittings keep the water and embarkation walk clear.
 for at in [Vector2(1654,2236),Vector2(2188,2236)]:
  c.draw_rect(Rect2(at-cam-Vector2(4,26),Vector2(8,35)),Color('#645343'));c.draw_circle(at-cam-Vector2(0,27),9,Color('#e6c184'));c.draw_circle(at-cam-Vector2(0,27),5,Color('#ffe7a9'))
 for at in [Vector2(1680,2243),Vector2(2165,2225)]:
  c.draw_rect(Rect2(at-cam-Vector2(15,12),Vector2(30,24)),Color('#98794f'));c.draw_rect(Rect2(at-cam-Vector2(15,12),Vector2(30,24)),Color('#d3b47e'),false,2);c.draw_line(at-cam-Vector2(13,10),at-cam+Vector2(13,10),Color('#594d3d'),2)
 for n in 8:
  var at=Vector2(1665+n*68,2690+sin(n)*12)-cam
  for k in 3:c.draw_line(at+Vector2(k*4,0),at+Vector2(k*6-4,-12-k*3),Color('#8ea77b'),2)
 c.draw_string(ThemeDB.fallback_font,Vector2(1690,2298)-cam,"RIPPLE & REEL • MARINA",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color('#f4dfb6'))
 c.draw_string(ThemeDB.fallback_font,Vector2(1750,2317)-cam,"E • Lake & coastal voyages",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color('#d4dcca'))
