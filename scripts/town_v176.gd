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
# Bounded geometry with a single aligned aperture and stone frame.
static func ellipse(g:Node2D,center:Vector2,radii:Vector2,color:Color)->void:
 var points=PackedVector2Array()
 for n in 64:points.append(center+Vector2(cos(float(n)*TAU/64)*radii.x,sin(float(n)*TAU/64)*radii.y))
 g.draw_colored_polygon(points,color)
static func draw_portal(g:Node2D,camera:Vector2)->void:
 var p=Vector2(900,670)-camera
 if not Rect2(Vector2.ZERO,g.VIEW).grow(110).has_point(p):return
 var t:float=g.town_life.clock;var c:Vector2=p+Vector2(0,-9);var pulse:float=.5+.5*sin(t*2.1)
 ellipse(g,c,Vector2(37,55.5),Color("#314b58"));ellipse(g,c,Vector2(34,51),Color("#83aaa8"));ellipse(g,c,Vector2(29,43.5),Color("#183e50"))
 for n in 12:
  var a:float=float(n)*TAU/12
  g.draw_line(c+Vector2(cos(a)*30,sin(a)*45),c+Vector2(cos(a)*36,sin(a)*54),Color("#395866"),1.5,true)
 ellipse(g,c,Vector2(25,41),Color("#093747"))
 for n in range(5,0,-1):ellipse(g,c,Vector2(float(n)*4.2,float(n)*7.22),Color(.08,.56+float(n)*.04,.65,.15))
 for n in 5:
  var points=PackedVector2Array()
  for k in 41:
   var u:float=float(k)/40;var a:float=t*(.8+float(n%2)*.15)+float(n)*TAU/5+u*4.6;var radius:float=2+u*19
   points.append(c+Vector2(cos(a)*radius,sin(a)*radius*1.72))
  g.draw_polyline(points,Color(.35+float(n)*.08,.94,1,.38),1.3,true)
 ellipse(g,c,Vector2(3+pulse,(3+pulse)*1.35),Color(.72,1,1,.72))
 for n in 8:
  var points=PackedVector2Array();var start:float=float(n)*TAU/8+t*(.48 if n%2==0 else -.32)
  for k in 9:
   var a:float=start+float(k)*.035;points.append(c+Vector2(cos(a)*32,sin(a)*48))
  g.draw_polyline(points,Color(.5,.98,1,.45+pulse*.22),1.5,true)
 for n in range(3,0,-1):ellipse(g,p+Vector2(0,54),Vector2(29+float(n)*7,6+float(n)),Color(.18,.85,.89,.035+pulse*.012))
 g.draw_rect(Rect2(p+Vector2(-39,45),Vector2(78,12)),Color("#4d686e"));g.draw_line(p+Vector2(-39,45),p+Vector2(39,45),Color("#a7bbb1"),3)
 for n in 12:
  var u:float=fposmod(t*.19+float(n)*.371,1);var side:float=-1 if n%2==0 else 1
  var q:Vector2=p+Vector2(side*(38+sin(t+float(n)*2)*7),38-u*112)
  g.draw_circle(q,1.3+float(n%3)*.35,Color(.6,1,.95,sin(u*PI)*.8))
