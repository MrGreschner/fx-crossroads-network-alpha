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
 preload("res://scripts/town_sprite_cache.gd").draw(g,"arena_grand" if grand else "arena",Rect2(p-Vector2(250,190),Vector2(500,420)))
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
 var p=CENTER-camera
 # Quiet shadow and layered marble plinth anchor the building.
 g.draw_colored_polygon(ellipse(p+Vector2(0,132),230,36),Color(0,0,0,.22))
 g.draw_rect(Rect2(p+Vector2(-225,90),Vector2(450,62)),Color("#7b817d"))
 for n in 4:
  g.draw_rect(Rect2(p+Vector2(-225+n*5,104-n*8),Vector2(450-n*10,8)),Color("#b7baa7"))
  g.draw_line(p+Vector2(-225+n*5,104-n*8),p+Vector2(225-n*5,104-n*8),Color("#e0d3b0"),2)
 # Upper seating bowl, a separate inner combat ring, individual bench rows.
 g.draw_colored_polygon(ellipse(p+Vector2(0,-10),204,90),Color("#435361"))
 for n in 5:
  var seat=PackedVector2Array()
  for j in 33:seat.append(p+Vector2(cos(PI+j*PI/32)*(193-n*13),-12+sin(PI+j*PI/32)*(79-n*10)))
  g.draw_polyline(seat,Color("#b4b7aa") if n%2==0 else Color("#7e8e90"),7,true)
 for j in 13:
  var a=PI+j*PI/12;g.draw_line(p+Vector2(cos(a)*140,-12+sin(a)*40),p+Vector2(cos(a)*199,-12+sin(a)*82),Color("#d5c9a9"),2,true)
 g.draw_colored_polygon(ellipse(p+Vector2(0,-4),135,44),Color("#bc915c"));g.draw_polyline(ellipse(p+Vector2(0,-4),135,44),Color("#e5c991"),3,true)
 g.draw_polyline(ellipse(p+Vector2(0,-4),92,29),Color("#d5b076"),2,true)
 # Ashen and storm gates promise distinct arenas; light pulses remain local.
 for side in [-1,1]:
  var q=p+Vector2(side*91,-27);var c=Color("#ef9c52") if side<0 else Color("#8acff3")
  g.draw_rect(Rect2(q-Vector2(24,25),Vector2(48,38)),Color("#253c4c"));g.draw_arc(q-Vector2(0,25),24,PI,TAU,20,Color("#c0b28f"),5,true)
  g.draw_circle(q-Vector2(0,13),13,Color(c,.12));pass
 # Tall side towers with recessed windows, caps, ribbons and animated braziers.
 for side in [-1,1]:
  var q=p+Vector2(side*185,0)
  g.draw_rect(Rect2(q-Vector2(32,102),Vector2(64,196)),Color("#74858b"));g.draw_rect(Rect2(q+Vector2(20,-102),Vector2(12,196)),Color("#526776"))
  for row in 8:g.draw_line(q+Vector2(-30,-87+row*23),q+Vector2(30,-87+row*23),Color("#91a1a0"),1)
  for row in 3:
   var window=q+Vector2(0,-68+row*46);g.draw_rect(Rect2(window-Vector2(10,15),Vector2(20,27)),Color("#223c51"));g.draw_arc(window-Vector2(0,15),10,PI,TAU,12,Color("#d3c8aa"),3,true)
   g.draw_rect(Rect2(window-Vector2(4,9),Vector2(8,14)),Color("#d9ae65") if row==2 else Color("#5c9caf"))
  g.draw_rect(Rect2(q-Vector2(38,111),Vector2(76,15)),Color("#c8c4a9"))
  for n in 5:g.draw_rect(Rect2(q+Vector2(-36+n*16,-122),Vector2(9,18)),Color("#c8c4a9"))
  var flag=q+Vector2(side*34,-104);g.draw_line(flag,flag+Vector2(0,97),Color("#aa956a"),3)
 # Multi-level front arcade, columns and a roofed entrance pavilion.
 for n in 11:
  var x=-145+n*29;var q=p+Vector2(x,51+sqrt(maxf(0,1-pow(x/160.0,2)))*22)
  g.draw_rect(Rect2(q-Vector2(13,29),Vector2(26,61)),Color("#b3b2a0"));g.draw_rect(Rect2(q-Vector2(8,22),Vector2(16,42)),Color("#314e61"));g.draw_arc(q-Vector2(0,22),8,PI,TAU,12,Color("#e8d6aa"),3,true)
  g.draw_rect(Rect2(q+Vector2(-14,24),Vector2(28,7)),Color("#dfd0ae"))
 g.draw_rect(Rect2(p+Vector2(-49,41),Vector2(98,73)),Color("#758a8c"))
 g.draw_colored_polygon(PackedVector2Array([p+Vector2(-62,43),p+Vector2(0,6),p+Vector2(62,43)]),Color("#c6b475"));g.draw_line(p+Vector2(-62,43),p+Vector2(62,43),Color("#ead7a1"),4)
 g.draw_rect(Rect2(p+Vector2(-25,67),Vector2(50,48)),Color("#1b3546"));g.draw_arc(p+Vector2(0,67),25,PI,TAU,24,Color("#e4cd9a"),5,true)
 for side in [-1,1]:g.draw_rect(Rect2(p+Vector2(side*41-5,46),Vector2(10,68)),Color("#d7cfad"))
 # Names stay within our lot, with space before the separate Squirrel Post.
 g.draw_rect(Rect2(p+Vector2(-158,153),Vector2(316,29)),Color("#233f50"));g.draw_rect(Rect2(p+Vector2(-158,153),Vector2(316,29)),Color("#c7ae72"),false,2)
 g.draw_string(font,p+Vector2(-152,173),"GRAND GLADIATOR ARENA" if grand else "GLADIATOR ARENA",HORIZONTAL_ALIGNMENT_CENTER,304,17,Color("#f0d8a0"))

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
