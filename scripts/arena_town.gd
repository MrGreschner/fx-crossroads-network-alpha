extends RefCounted
## Dedicated amphitheatre facade. All architectural effects use bounded cached draw work.
const CENTER=Vector2(130,1090)
const TORCHES=[Vector2(-55,955),Vector2(315,955),Vector2(-37,1128),Vector2(297,1128)]
const FOOTPRINT=Rect2(-105,940,470,340)
var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
func wins(g:Node)->int:
 var record=g.legacy.card.state().arena
 return int(record.standard.wins)+int(record.random.wins)
func blocked(p:Vector2)->bool:
 # Open forecourt and centre entrance; seats/towers are solid.
 return Rect2(-90,960,440,165).has_point(p) or (Rect2(-90,1125,160,80).has_point(p) or Rect2(190,1125,160,80).has_point(p))
func ellipse(center:Vector2,rx:float,ry:float)->PackedVector2Array:
 var points=PackedVector2Array()
 for n in 49:points.append(center+Vector2(cos(n*TAU/48)*rx,sin(n*TAU/48)*ry))
 return points
func draw_on(g:Node2D,camera:Vector2)->void:
 if not Rect2(camera,g.VIEW).intersects(Rect2(CENTER-Vector2(250,190),Vector2(500,420))):return
 var p=CENTER-camera;var t=g.town_life.clock;var grand=wins(g)>=10
 preload("res://scripts/town_landmarks241.gd").draw(g,"arena",camera,grand)
 for side in [-1,1]:
  if not Rect2(Vector2.ZERO,g.VIEW).grow(35).intersects(Rect2(p+Vector2(side*185-50,-175),Vector2(100,365))) and not Rect2(Vector2.ZERO,g.VIEW).grow(18).has_point(p+Vector2(side*91,-40)):continue
  var q=p+Vector2(side*91,-27);var color=Color("#ef9c52") if side<0 else Color("#8acff3")
  g.draw_arc(q-Vector2(0,13),13,t*.4,t*.4+PI*1.7,24,color,2,true)
  q=p+Vector2(side*185,0)
  brazier(g,q+Vector2(0,-135),t,side);brazier(g,q+Vector2(-side*18,38),t,-side)
  var flag=q+Vector2(side*34,-104)
  g.draw_colored_polygon(PackedVector2Array([flag,flag+Vector2(-side*26,4),flag+Vector2(-side*26,75+sin(t*2+side)*3),flag+Vector2(-side*13,85),flag+Vector2(0,75)]),Color("#b4894b") if grand else Color("#355b76"))
  g.draw_arc(flag+Vector2(-side*13,35),7,0,TAU,20,Color("#e7d49d"),2,true)
 g.draw_arc(p+Vector2(0,86),16,t*.6,t*.6+TAU*.8,28,Color("#87cfe0"),3,true)
 g.draw_string(font,p+Vector2(-160,202),"10 PvP wins • Grand honours" if grand else "%d / 10 PvP wins • Grand honours" % wins(g),HORIZONTAL_ALIGNMENT_CENTER,320,13,Color("#cbd8cc"))
 # Contained lightning between conductors on the storm tower (no fullscreen flash).
 var coil=p+Vector2(185,-143)
 if not Rect2(Vector2.ZERO,g.VIEW).grow(35).has_point(coil):return
 for side in [-1,1]:g.draw_line(coil+Vector2(side*20,20),coil+Vector2(side*20,-11),Color("#bcc6bb"),3,true)
 g.draw_circle(coil,20,Color(.45,.75,1,.08+.03*sin(t*4)))
 if fposmod(t,2.4)<.45:
  var arc=PackedVector2Array()
  for n in 7:arc.append(coil+Vector2(-20+n*40.0/6,sin(t*33+n*4)*7))
  g.draw_polyline(arc,Color(.4,.7,1,.2),7,true);g.draw_polyline(arc,Color("#d5efff"),2,true)

func draw_structure(g:Node2D,camera:Vector2,grand:bool)->void:
 preload("res://scripts/town_landmarks241.gd").draw(g,"arena",camera,grand)

func brazier(g:Node2D,p:Vector2,t:float,seed:int)->void:
 # A small fixed iron bowl and stone wall bracket belong to the tower itself.
 g.draw_rect(Rect2(p+Vector2(-9,16),Vector2(18,7)),Color("#b2ad92"))
 g.draw_line(p+Vector2(0,12),p+Vector2(0,18),Color("#384f56"),4)
 g.draw_colored_polygon(PackedVector2Array([p+Vector2(-12,7),p+Vector2(12,7),p+Vector2(8,15),p+Vector2(-8,15)]),Color("#344b53"))
 var flicker=sin(t*8+seed*3)*2
 g.draw_circle(p,18,Color(1,.6,.18,.06))
 g.draw_colored_polygon(PackedVector2Array([p+Vector2(-8,7),p+Vector2(-4,-9-flicker),p+Vector2(1,-3),p+Vector2(4,-15+flicker),p+Vector2(8,7)]),Color("#ee8a37"))
 g.draw_colored_polygon(PackedVector2Array([p+Vector2(-4,7),p+Vector2(1,-6-flicker),p+Vector2(5,7)]),Color("#ffe39b"))
 for n in 2:
  var age=fposmod(t*.55+n*.5,1);g.draw_circle(p+Vector2(sin(t*2+n)*4,-4-age*18),1,Color(1,.76,.35,1-age))
