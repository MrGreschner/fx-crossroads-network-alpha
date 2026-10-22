extends RefCounted
## One coastline drives drawing, landing, navigation and boat collisions.
static func radius(isle:Dictionary,angle:float)->float:
 var phase=float(posmod(str(isle.name).hash(),628))/100.0
 var coast=.86+.075*sin(angle*3+phase)+.045*sin(angle*5-phase)
 var bay=absf(wrapf(angle-phase,-PI,PI));coast-=.15*exp(-bay*bay/.13)
 return float(isle.r)*clampf((.88+.12*cos(angle*2+phase))*coast,.56,.99)
static func polygon(isle:Dictionary,inset:float=0)->PackedVector2Array:
 var result=PackedVector2Array()
 for n in 80:
  var a=n*TAU/80;result.append(isle.p+Vector2.from_angle(a)*maxf(20,radius(isle,a)-inset))
 return result
static func distance_to_shore(isle:Dictionary,p:Vector2)->float:
 var d=p-Vector2(isle.p);return d.length()-radius(isle,d.angle())
static func contains(isle:Dictionary,p:Vector2,inset:float=0)->bool:return distance_to_shore(isle,p)<-inset
static func draw_details(c:Node2D,isle:Dictionary,cam:Vector2)->void:
 var center:Vector2=isle.p-cam
 match str(isle.name):
  "Birch Landing":
   for n in 5:
    var p=center+Vector2(-100+n*49,-40+sin(n*2)*75);c.draw_line(p,p-Vector2(8,75),Color("#d9d7b9"),9)
    for mark in 5:c.draw_line(p-Vector2(4+mark,mark*14),p+Vector2(4-mark,-mark*14),Color("#56615a"),2)
    c.draw_circle(p-Vector2(8,81),28,Color("#87a372"));c.draw_circle(p-Vector2(28,65),23,Color("#a1af78"))
  "Oldwater Isle":
   var p=center+Vector2(-30,-80);c.draw_polyline(PackedVector2Array([p+Vector2(-90,45),p+Vector2(-90,-30),p+Vector2(65,-30)]),Color("#a4aa94"),13)
   for offset in [-85,60]:
    c.draw_rect(Rect2(p+Vector2(offset,-69),Vector2(19,72)),Color("#8f998d"));c.draw_rect(Rect2(p+Vector2(offset-5,-73),Vector2(29,9)),Color("#c3c4a5"))
  "Reedwatch Island":
   for n in 26:
    var a=n*.39;var p=center+Vector2.from_angle(a)*(radius(isle,a)-62)
    c.draw_line(p,p+Vector2(sin(n)*12,-35-n%4*7),Color("#8d9b61"),3);c.draw_line(p+Vector2(4,-24),p+Vector2(4,-44),Color("#b7a06e"),5)
  "Shore Refuge":
   var p=center+Vector2(30,-40);c.draw_polyline(PackedVector2Array([p+Vector2(-95,18),p+Vector2(-30,46),p+Vector2(55,8),p+Vector2(88,-20)]),Color("#776f5c"),13)
   for n in 6:c.draw_line(p+Vector2(-70+n*28,22),p+Vector2(-80+n*30,-20-n%2*18),Color("#a18a65"),7)
   c.draw_line(p+Vector2(-12,20),p+Vector2(8,-65),Color("#ada080"),8)
  "Kelp Rest":
   for n in 8:
    var p=center+Vector2(-100+n*27,sin(n*2)*55);c.draw_line(p,p+Vector2(24,-20-n%3*14),Color("#547b5c"),7);c.draw_line(p+Vector2(12,-14),p+Vector2(-4,-22),Color("#76946a"),5)
   for x in [-75,75]:c.draw_line(center+Vector2(x,40),center+Vector2(x,5),Color("#8d7754"),9);c.draw_arc(center+Vector2(x,5),15,0,TAU,18,Color("#b5a078"),3,true)
  "Night Island":
   for n in 6:
    var p=center+Vector2.from_angle(n*TAU/6)*270;c.draw_colored_polygon(PackedVector2Array([p+Vector2(-13,12),p+Vector2(-9,-18),p+Vector2(8,-23),p+Vector2(15,10)]),Color("#868e89"));c.draw_line(p+Vector2(-4,-4),p+Vector2(4,-12),Color("#bac4b4"),2)
