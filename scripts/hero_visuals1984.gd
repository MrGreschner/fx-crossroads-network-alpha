extends RefCounted
static func ball(c:Node2D,p:Vector2,aim:Vector2)->void:
 c.draw_line(p-aim*19,p-aim*5,Color(.9,1,.85,.5),2,true)
 c.draw_circle(p,4.8,Color("#535e61"));c.draw_circle(p-Vector2(.5,.5),4,Color("#fffef2"))
 for offset in [Vector2(-1,-2),Vector2(2,0),Vector2(-1,2)]:c.draw_circle(p+offset,.6,Color("#aab3b1"))
static func stone(c:Node2D,p:Vector2,aim:Vector2)->void:
 var side:=aim.orthogonal()
 c.draw_arc(p-aim*10,8,0,TAU,16,Color(.55,.88,.94,.4),1.5,true)
 c.draw_colored_polygon(PackedVector2Array([p+aim*7,p+side*4,p-aim*6,p-side*4]),Color("#a3c8cd"))
 c.draw_line(p-aim*3-side,p+aim*3-side,Color("#e0f6ec"),2,true)
static func hammer(c:Node2D,p:Vector2,direction:Vector2,reach:float,t:float)->void:
 var aim:=direction.rotated(lerpf(-.65,.65,clampf(t,0,1)));var side:=aim.orthogonal();var tip:=p+aim*(reach-9)
 c.draw_arc(p,reach-4,aim.angle()-.35,aim.angle(),14,Color(1,.66,.25,.35),4,true)
 c.draw_line(p+aim*16,tip,Color("#93643f"),5,true)
 c.draw_colored_polygon(PackedVector2Array([tip-aim*8-side*13,tip+aim*8-side*13,tip+aim*8+side*13,tip-aim*8+side*13]),Color("#657c80"))
 c.draw_line(tip+aim*8-side*12,tip+aim*8+side*12,Color("#ffd07a"),3,true)
 for n in 3:c.draw_line(tip+side*(n-1)*9+aim*13,tip+side*(n-1)*15+aim*22,Color("#efb46c",.7),2,true)
