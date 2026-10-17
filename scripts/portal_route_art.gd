extends Control
var variant=0
var muted=false
var time=0.0
var tick=0.0
var portal=preload("res://assets/portal.png")
func _ready()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(dt:float)->void:
 if muted or not is_visible_in_tree():return
 time+=dt;tick+=dt
 if tick>1.0/24:tick=0;queue_redraw()
func _draw()->void:
 var center=size*.5;var scale=minf(size.x/92,size.y/108)
 draw_set_transform(center,0,Vector2.ONE*scale)
 if not muted:
  var c=Color("#bca8f5") if variant==1 else Color("#ffe5a3") if variant==2 else Color("#83eee5")
  for n in range(3,0,-1):draw_circle(Vector2(0,-3),20+n*7,Color(c,.025+.012*sin(time*2)))
  for n in 4:
   var radius=12+fposmod(time*8+n*5,22)
   draw_arc(Vector2(0,-4),radius,time*.4+n,time*.4+n+PI*1.4,28,Color(c,.45*(1-radius/36)),1.5,true)
  for n in 9:
   var a=n*2.399+time*(.25 if n%2 else -.3);var p=Vector2(cos(a)*23,sin(a)*35-4)
   draw_circle(p,1.2+.5*sin(time*3+n),Color(c,.6))
 if variant==2:
  for n in 3:draw_arc(Vector2.ZERO,31+n*5,time*(.6+n*.2),time*(.6+n*.2)+TAU*.85,40,Color("#e5bc6f") if n%2 else Color("#92f0de"),2,true)
 if variant==1:
  # Render only separated pieces; the gaps are truly transparent, not painted over.
  var pieces=[Rect2(0,0,.41,.30),Rect2(.53,0,.47,.23),Rect2(0,.39,.36,.34),Rect2(.48,.32,.52,.29),Rect2(.12,.82,.37,.18),Rect2(.61,.73,.39,.27)]
  var offsets=[Vector2(-3,-3),Vector2(3,-2),Vector2(-4,0),Vector2(4,1),Vector2(-2,3),Vector2(4,4)]
  for n in pieces.size():
   var part:Rect2=pieces[n];var target=Rect2(Vector2(-27,-43)+part.position*Vector2(54,86)+offsets[n]+Vector2(sin(time*1.5+n),cos(time*1.2+n))*.9,part.size*Vector2(54,86))
   draw_texture_rect_region(portal,target,Rect2(part.position*portal.get_size(),part.size*portal.get_size()),Color("#a8babd") if muted else Color("#b6a8ee"))
  for n in 3:
   var p=Vector2(-34+n*33,20+sin(n*2)*18);draw_colored_polygon(PackedVector2Array([p,p+Vector2(4,-7),p+Vector2(8,2)]),Color("#8b9eaa") if muted else Color("#d0bdf8"))
 else:
  draw_texture_rect(portal,Rect2(-27,-43,54,86),false,Color("#a8babd") if muted else Color.WHITE if variant==0 else Color("#e9e2bc"))
 if not muted and variant!=1:
  # The inner sheen is drawn over the portal surface so it remains visible.
  for n in 3:
   var a=time*(.65+n*.1)+n*2.1
   var points=PackedVector2Array()
   for j in 23:
    var t=a+j*PI/20;points.append(Vector2(cos(t)*(7+n*3),sin(t)*(16+n*3)-5))
   draw_polyline(points,Color(.7,.99,.94,.22+.06*sin(time*2+n)),1.4,true)
 if variant>0:
  for n in (4 if variant==1 else 7):
   var a=n*TAU/(4 if variant==1 else 7);var dir=Vector2.from_angle(a)
   var line=PackedVector2Array([dir*26,dir.rotated(.12)*35,dir.rotated(-.09)*(43+sin(time*5+n)*3),dir*(52 if variant==2 else 48)])
   draw_polyline(line,Color("#aa9ce5") if variant==1 else Color("#fae5a2"),1.8,true)
 draw_set_transform(Vector2.ZERO)
