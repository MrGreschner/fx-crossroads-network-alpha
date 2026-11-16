extends RefCounted

const ENTRY=Vector2(818,5660)
const OUTLINE=[Vector2(402,5484),Vector2(552,5448),Vector2(715,5460),Vector2(839,5520),Vector2(887,5610),Vector2(884,5712),Vector2(799,5774),Vector2(638,5804),Vector2(461,5750),Vector2(421,5660)]
const HOLES={"voyage_lake_ice_reeds":Vector2(504,5573),"voyage_lake_ice_mid":Vector2(657,5538),"voyage_lake_ice_edge":Vector2(726,5709)}
const C=preload("res://scripts/fishing_catalog.gd")
static var shape:=PackedVector2Array(OUTLINE)

static func open_for(v:Node)->bool:
 return v.active and v.route=="lake" and v.game.town_life.calendar.season()=="Winter"

static func contains(point:Vector2)->bool:
 return Geometry2D.is_point_in_polygon(point,shape)

static func spot(point:Vector2)->Dictionary:
 for id in HOLES:
  var hole:Vector2=HOLES[id]
  if point.distance_to(hole)>65:continue
  var data:Dictionary=C.pools()[id].duplicate(true)
  data.id=id
  data.bank=[hole.x,hole.y]
  data.water=[hole.x,hole.y]
  return data
 return {}

static func draw(c:Node2D,cam:Vector2,view:Rect2)->void:
 if not view.intersects(Rect2(380,5430,535,400)):return
 var outline:=PackedVector2Array()
 for point in shape:outline.append(point-cam)
 c.draw_colored_polygon(outline,Color("#9abdc8"))
 outline.append(outline[0])
 c.draw_polyline(outline,Color("#5e929f"),10,true)
 c.draw_polyline(outline,Color("#e0ebeb"),3,true)
 for n in 310:
  var p:=Vector2(410+posmod(n*153,468),5453+posmod(n*91,334))
  if not contains(p) or not contains(p+Vector2(12,2)):continue
  var color:=Color("#c6dbe0") if n%4!=0 else Color("#7ca7b6")
  c.draw_rect(Rect2(p-cam,Vector2(5+posmod(n,8),2)),color)
 for p in [Vector2(473,5659),Vector2(596,5714),Vector2(713,5499),Vector2(803,5628)]:
  var a:Vector2=p-cam
  c.draw_polyline(PackedVector2Array([a,a+Vector2(19,-4),a+Vector2(37,8),a+Vector2(53,4)]),Color("#73a3b3"),2,true)
  c.draw_line(a+Vector2(19,-4),a+Vector2(24,-19),Color("#83afbd"),1,true)
 var dock:=Rect2(ENTRY-cam-Vector2(12,12),Vector2(66,24))
 c.draw_rect(dock,Color("#645847"));c.draw_rect(dock.grow(-3),Color("#b6a180"))
 for x in 6:c.draw_line(dock.position+Vector2(5+x*10,2),dock.position+Vector2(5+x*10,22),Color("#81735a"),1)
 for hole in HOLES.values():
  var p:Vector2=hole-cam
  for mark in [[20,Color("#e4edef")],[13,Color("#285360")],[8,Color("#478090")]]:
   var oval:=PackedVector2Array()
   for n in 16:oval.append(p+Vector2.from_angle(n*TAU/16)*Vector2(mark[0],mark[0]*.65))
   c.draw_colored_polygon(oval,mark[1])
  c.draw_circle(p-Vector2(22,8),4,Color("#c28557"))
 c.draw_string(ThemeDB.fallback_font,ENTRY-cam+Vector2(-89,-30),"COVE LANDING",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#fff0bc"))
