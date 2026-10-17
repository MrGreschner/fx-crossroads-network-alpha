extends RefCounted
const BREAD=Vector2(1360,1140)
static func draw_bakery(g:Node2D,camera:Vector2)->void:
 var p=BREAD-camera
 if not Rect2(Vector2.ZERO,g.VIEW).grow(160).has_point(p):return
 var ink=Color("#59483d")
 for x in [-54,54]:g.draw_circle(p+Vector2(x,15),17,ink);g.draw_arc(p+Vector2(x,15),12,0,TAU,12,Color("#d0ad76"),3,true)
 g.draw_style_box(preload("res://scripts/studio_ui.gd").box("#aa7950","#e0bb83",7,2),Rect2(p+Vector2(-75,-57),Vector2(150,70)))
 for n in 6:g.draw_line(p+Vector2(-69+n*26,-52),p+Vector2(-69+n*26,7),Color("#8a603e"),2)
 for x in [-72,72]:g.draw_line(p+Vector2(x,5),p+Vector2(x,-126),ink,5)
 for n in 10:g.draw_rect(Rect2(p+Vector2(-82+n*16.4,-132),Vector2(16.4,29)),Color("#d9b982") if n%2 else Color("#698b87"))
 g.draw_line(p+Vector2(-83,-133),p+Vector2(83,-133),Color("#f0d5a0"),4)
 g.draw_style_box(preload("res://scripts/studio_ui.gd").box("#304b4e","#d4b77d",4,1),Rect2(p+Vector2(-63,-91),Vector2(126,28)))
 g.draw_string(g.font,p+Vector2(-58,-72),"HEARTH & CRUMB",HORIZONTAL_ALIGNMENT_CENTER,116,12,Color("#ffe1a8"))
 for n in 5:
  var q=p+Vector2(-53+n*26,-35+sin(n)*4)
  g.draw_arc(q+Vector2(0,6),13,0,PI,12,Color("#6f4e32"),4)
  g.draw_style_box(preload("res://scripts/studio_ui.gd").box("#d6a65e","#f5cf8c",8,1),Rect2(q-Vector2(10,7),Vector2(22,15)))
  for k in 3:g.draw_line(q+Vector2(-6+k*5,-3),q+Vector2(-3+k*5,2),Color("#9e6f38"),1.5,true)
 g.draw_string(g.font,p+Vector2(-72,43),"FREE ADVENTURE BREAD",HORIZONTAL_ALIGNMENT_CENTER,144,11,Color("#f5dfa6"))
# Bounded native geometry: no lights, particles, textures or shader allocations.
static func draw_portal(g:Node2D,camera:Vector2)->void:
 var p=Vector2(900,670)-camera
 if not Rect2(Vector2.ZERO,g.VIEW).grow(110).has_point(p):return
 var t:float=g.town_life.clock
 var c:Vector2=p+Vector2(0,-9)
 var pulse:float=.5+.5*sin(t*2.1)
 # The aperture covers only the inside of the existing stone frame.
 g.draw_set_transform(c,0,Vector2(1,1.72))
 g.draw_circle(Vector2.ZERO,23,Color(.035,.20,.30,.95))
 for n in range(5,0,-1):
  g.draw_circle(Vector2(sin(t*.65+n*.4)*2,cos(t*.5+n)*2),float(n)*4.2,Color(.08,.56+float(n)*.04,.65,.15))
 for n in 5:
  var points=PackedVector2Array()
  for k in 41:
   var u:float=float(k)/40
   var a:float=t*(.8+float(n%2)*.15)+float(n)*TAU/5+u*4.6
   var radius:float=2+u*19
   points.append(Vector2(cos(a),sin(a))*radius)
  g.draw_polyline(points,Color(.35+float(n)*.08,.94,1,.38),1.3,true)
 g.draw_circle(Vector2.ZERO,3+pulse,Color(.72,1,1,.72))
 g.draw_set_transform(Vector2.ZERO)
 # Segmented currents travel in opposite directions around the rim.
 for n in 8:
  var points=PackedVector2Array()
  var start:float=float(n)*TAU/8+t*(.48 if n%2==0 else -.32)
  for k in 9:
   var a:float=start+float(k)*.035
   points.append(c+Vector2(cos(a)*32,sin(a)*48))
  g.draw_polyline(points,Color(.5,.98,1,.45+pulse*.22),2.0,true)
 # A soft ground reflection anchors the energy to the pedestal.
 g.draw_set_transform(p+Vector2(0,49),0,Vector2(1,.22))
 for n in range(3,0,-1):g.draw_circle(Vector2.ZERO,29+float(n)*7,Color(.18,.85,.89,.035+pulse*.012))
 g.draw_set_transform(Vector2.ZERO)
 # Sparks rise, fade, then wrap; their count never grows over time.
 for n in 14:
  var u:float=fposmod(t*.19+float(n)*.371,1)
  var side:float=-1 if n%2==0 else 1
  var q:Vector2=p+Vector2(side*(34+sin(t+float(n)*2)*9),38-u*112)
  var alpha:float=sin(u*PI)*.8
  g.draw_circle(q,1.3+float(n%3)*.35,Color(.6,1,.95,alpha))
