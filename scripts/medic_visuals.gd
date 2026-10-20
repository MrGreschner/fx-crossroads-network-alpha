extends RefCounted
static func boot(c:Node2D,p:Vector2,aim:Vector2,reach:float,t:float)->void:
 var side=aim.orthogonal();var knee=p+aim*30+side*11;var ankle=p+aim*reach*(.52+.16*sin(clampf(t,0,1)*PI))+side*4;var toe=ankle+aim*13
 c.draw_line(p+aim*12+side*4,knee,Color("#527c73"),8,true);c.draw_line(knee,ankle,Color("#73968a"),7,true)
 c.draw_colored_polygon(PackedVector2Array([ankle-aim*2-side*5,toe-side*4,toe+aim*3+side*7,ankle-aim*5+side*7]),Color("#263f49"))
 c.draw_line(ankle-aim*5+side*7,toe+aim*3+side*7,Color("#b7c5ad"),2,true)
 c.draw_arc(p,reach,aim.angle()-.32,aim.angle()+.32,14,Color(.6,.89,.75,.28*(1-t)),2,true)
static func pulse(c:Node2D,p:Vector2,radius:float,progress:float)->void:
 var t=clampf(progress,0,1);var r=radius*(.3+.7*t);var alpha=1-t
 c.draw_circle(p,r,Color(.42,.75,.63,.07*alpha));c.draw_arc(p,r,0,TAU,44,Color(.67,.94,.77,.7*alpha),3,true)
 for n in 6:
  var at=p+Vector2.from_angle(n*TAU/6+t*.3)*r*.85;var ink=Color(.81,.97,.84,alpha)
  c.draw_line(at-Vector2(0,6),at+Vector2(0,6),ink,3,true);c.draw_line(at-Vector2(6,0),at+Vector2(6,0),ink,3,true)
 c.draw_line(p-Vector2(0,13),p+Vector2(0,13),Color(.72,.94,.78,alpha),6,true);c.draw_line(p-Vector2(13,0),p+Vector2(13,0),Color(.72,.94,.78,alpha),6,true)
