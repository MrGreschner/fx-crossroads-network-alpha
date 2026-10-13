extends RefCounted
## Arcane architect: layered orbit, hovering crystal, moving sigil; no particle nodes.
static func draw_on(c:CanvasItem,p:Vector2,t:float,scale_factor:float=1.0)->void:
 var s=scale_factor
 var blue=Color("#90f1f2");var gold=Color("#ffe1a0");var violet=Color("#b6a0ff")
 var ground=p+Vector2(0,7)*s
 var ring=PackedVector2Array()
 for n in 33:
  var a=n*TAU/32;ring.append(ground+Vector2(cos(a)*29,sin(a)*10)*s)
 c.draw_polyline(ring,Color(blue,.33),1.3*s,true)
 for n in 6:
  var a=t*.7+n*TAU/6
  var q=ground+Vector2(cos(a)*29,sin(a)*10)*s
  c.draw_circle(q,2*s,Color(gold,.75))
  c.draw_line(q,q+Vector2(0,-6-sin(t*2+n)*3)*s,Color(blue,.25),1*s,true)
 # Four drifting crystal fragments orbit outside the sprite silhouette.
 for n in 4:
  var a=t*.55+n*TAU/4;var q=p+Vector2(cos(a)*36,-28+sin(a)*23)*s
  var shard=PackedVector2Array([q-Vector2(0,5)*s,q+Vector2(3,0)*s,q+Vector2(0,5)*s,q-Vector2(3,0)*s])
  c.draw_colored_polygon(shard,Color(violet,.24));c.draw_line(shard[0],shard[2],Color(blue,.55),1*s,true)
 var crown=p+Vector2(0,-61+sin(t*2)*3)*s
 c.draw_circle(crown,10*s,Color(violet,.10))
 var diamond=PackedVector2Array([crown+Vector2(0,-8)*s,crown+Vector2(5,0)*s,crown+Vector2(0,7)*s,crown+Vector2(-5,0)*s,crown+Vector2(0,-8)*s])
 c.draw_colored_polygon(PackedVector2Array([diamond[0],diamond[1],diamond[2],diamond[3]]),Color(blue,.3));c.draw_polyline(diamond,Color(gold,.85),1.3*s,true)
 for side in [-1,1]:
  var arc=PackedVector2Array()
  for n in 13:
   var a=-PI*.65+n*PI*1.3/12;arc.append(crown+Vector2(side*(12+cos(a)*5),sin(a)*12)*s)
  c.draw_polyline(arc,Color(violet,.6),1.2*s,true)
 for n in 3:
  var a=t*1.1+n*TAU/3;var q=p+Vector2(cos(a)*25,-27+sin(a)*18)*s
  c.draw_line(q-Vector2(0,3)*s,q+Vector2(0,3)*s,Color(blue,.45),1*s,true)
  c.draw_line(q-Vector2(2,0)*s,q+Vector2(2,0)*s,Color(gold,.6),1*s,true)
