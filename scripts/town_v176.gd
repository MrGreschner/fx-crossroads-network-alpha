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
static func draw_portal(g:Node2D,camera:Vector2)->void:
 var p=Vector2(900,670)-camera;var t=g.town_life.clock
 if not Rect2(Vector2.ZERO,g.VIEW).grow(160).has_point(p):return
 g.draw_set_transform(p-Vector2(0,28),0,Vector2(1,.7))
 for n in range(3,0,-1):g.draw_arc(Vector2.ZERO,38+n*7,t*.3+n,t*.3+n+TAU*.85,40,Color(.45,.94,.88,.08+n*.02),3,true)
 g.draw_set_transform(Vector2.ZERO)
 for n in 3:
  var points=PackedVector2Array()
  for k in 26:
   var a=t*(.5+n*.1)+k*TAU/25;points.append(p+Vector2(cos(a)*(12+n*4),sin(a)*(29+n*3)-33))
  g.draw_polyline(points,Color(.75,1,.92,.18+n*.04),1.5,true)
 for n in 12:
  var a=n*2.399+t*.35;var q=p+Vector2(cos(a)*48,sin(a)*64-30)
  g.draw_circle(q,1.5+sin(t*2+n)*.4,Color(.75,.95,.86,.45))
