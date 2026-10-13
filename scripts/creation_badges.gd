extends RefCounted
## Low-cost identity cosmetics. No particles or gameplay modifiers.
static func draw_on(c:CanvasItem,p:Vector2,t:float,flags:Dictionary)->void:
 if flags.get("custom",false):
  var ground=p+Vector2(0,16);var poly=PackedVector2Array()
  for n in 7:var a=n*TAU/6+t*.25;poly.append(ground+Vector2(cos(a)*25,sin(a)*9))
  c.draw_polyline(poly,Color(.3,.95,.9,.6),1.7,true)
  var q=p+Vector2(0,-63+sin(t*2)*2)
  c.draw_colored_polygon(PackedVector2Array([q+Vector2(0,-5),q+Vector2(5,0),q+Vector2(0,5),q+Vector2(-5,0)]),Color("#79ede0"))
  if not flags.get("balanced",false):
   for n in 3:
    var a=t*.9+n*TAU/3;var s=p+Vector2(cos(a)*31,-22+sin(a)*16)
    c.draw_line(s-Vector2(3,0),s+Vector2(3,0),Color("#eaaaed"),2,true);c.draw_line(s-Vector2(0,3),s+Vector2(0,3),Color("#eaaaed"),2,true)
 if flags.get("playtest",false):
  for n in 4:c.draw_arc(p+Vector2(0,14),29,t*.4+n*PI/2,t*.4+n*PI/2+.5,8,Color(.45,.7,1,.65),2,true)
 if flags.get("media",false):
  var q=p+Vector2(20,-58);var hue=Color("#8beba0")
  c.draw_rect(Rect2(q-Vector2(6,4),Vector2(12,8)),hue,false,1.5);c.draw_circle(q,2,hue)
