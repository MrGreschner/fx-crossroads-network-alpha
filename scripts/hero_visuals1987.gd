extends RefCounted
## Lightweight vector cues; authoritative hitboxes and timing remain in combat modules.
static func katana(c:Node2D,p:Vector2,aim:Vector2,reach:float,t:float,side:float)->void:
 var age:=clampf(t,0,1);var fade:=1-age;var angle:=aim.angle()+side*lerpf(-.72,.72,age)
 var ribbon:=PackedVector2Array()
 for n in 13:ribbon.append(p+Vector2.from_angle(angle-side*n*.055)*(reach-4))
 for n in range(12,-1,-1):ribbon.append(p+Vector2.from_angle(angle-side*n*.055)*(reach-12-n*.65))
 c.draw_colored_polygon(ribbon,Color(.72,.77,1,fade*.55))
 c.draw_arc(p,reach-3,minf(angle,angle-side*.64),maxf(angle,angle-side*.64),20,Color(.92,.94,1,fade),2,true)
 var dir:=Vector2.from_angle(angle);var tangent:=dir.orthogonal()
 c.draw_line(p+dir*24,p+dir*(reach-7),Color(.88,.94,.98,fade),3,true)
 c.draw_line(p+dir*23-tangent*6,p+dir*23+tangent*6,Color(.66,.55,.84,fade),3,true)
 for n in 3:c.draw_line(p+dir*(reach-4)+tangent*(n-1)*6,p+dir*(reach+4)+tangent*(n-1)*10,Color(.72,.83,1,fade*.6),1,true)
static func windwheel(c:Node2D,p:Vector2,angle:float,returning:bool)->void:
 var tint:=Color("#bca9ea") if returning else Color("#dce6f0")
 for n in 4:
  var d:=Vector2.from_angle(angle+n*PI*.5);var s:=d.orthogonal()
  c.draw_colored_polygon(PackedVector2Array([p+d*3-s*3,p+d*18-s*5,p+d*11+s*5,p+s*4]),tint)
  c.draw_line(p+d*7-s*3,p+d*17-s*4,Color("#f3f6e1"),1,true)
 c.draw_circle(p,4,Color("#4c4866"));c.draw_circle(p,1.5,Color("#b6c6e0"))
 c.draw_arc(p,21,angle,angle+PI*.75,16,Color(.7,.7,1,.35),1.5,true)
static func kindred(c:Node2D,p:Vector2,aim:Vector2)->void:
 var s:=aim.orthogonal()
 c.draw_line(p-aim*24,p-aim*6,Color(.51,.86,.75,.4),3,true)
 c.draw_colored_polygon(PackedVector2Array([p+aim*10,p+s*5,p-aim*7,p-s*5]),Color("#e9cd86"))
 c.draw_colored_polygon(PackedVector2Array([p+aim*7,p+s*2,p-aim*4,p-s*2]),Color("#fbf1c8"))
 c.draw_line(p-aim*9+s*5,p-aim*15,Color("#9edcc2"),1,true)
static func lantern(c:Node2D,p:Vector2,t:float)->void:
 var bob:=sin(t*3)*3;var q:=p+Vector2(0,bob-10)
 c.draw_circle(q,20,Color(.9,.82,.4,.12));c.draw_arc(q-Vector2(0,15),6,PI,TAU,12,Color("#d7bf7b"),2,true)
 c.draw_rect(Rect2(q-Vector2(10,13),Vector2(20,27)),Color("#a88a56"));c.draw_rect(Rect2(q-Vector2(6,9),Vector2(12,18)),Color("#d5edc0"));c.draw_line(q-Vector2(0,8),q+Vector2(0,8),Color("#fff3b9"),3,true)
 c.draw_line(q-Vector2(12,13),q+Vector2(12,-13),Color("#e7cb83"),3,true)
 for n in 4:
  var d:=Vector2.from_angle(t*.4+n*PI*.5);c.draw_line(p+d*29,p+d*36,Color(.68,.9,.68,.6),2,true)
static func prism(c:Node2D,p:Vector2,aim:Vector2,size:float=12)->void:
 var s:=aim.orthogonal();var front:=p+aim*size;var back:=p-aim*size*.8
 c.draw_line(p-aim*size*2.5,p,Color(.68,.75,1,.3),3,true)
 c.draw_colored_polygon(PackedVector2Array([front,p+s*size*.4,back,p-s*size*.4]),Color("#acd7ee"))
 c.draw_colored_polygon(PackedVector2Array([front,back,p-s*size*.4]),Color("#e5e7ec"))
 c.draw_line(front,p+s*size*.4,Color("#c4acd9"),2,true);c.draw_line(back,p+s*size*.4,Color("#8bbecf"),1,true)
static func bloom(c:Node2D,p:Vector2,r:float,clock:float)->void:
 for n in 6:
  var aim:=Vector2.from_angle(TAU*n/6+clock*.4);var q:=p+aim*r*.6
  prism(c,q,aim,maxf(3,r*.18))
 c.draw_arc(p,r,0,TAU,40,Color(.76,.71,.95,.35),1,true)
static func ribbon(c:Node2D,p:Vector2,aim:Vector2,reach:float,t:float,echo:bool,ready:bool)->void:
 var age:=clampf(t,0,1);var tint:=Color(.62,.85,.9,.75) if not echo else Color(.79,.77,.95,.6 if ready else .18)
 var strip:=PackedVector2Array()
 for n in 17:
  var a:=aim.angle()-.6+age*1.2-n*.045;strip.append(p+Vector2.from_angle(a)*(reach-5-sin(n*.35)*4))
 for n in range(16,-1,-1):
  var a:=aim.angle()-.6+age*1.2-n*.045;strip.append(p+Vector2.from_angle(a)*(reach-14-n*.3))
 c.draw_colored_polygon(strip,tint)
 var d:=aim.rotated(-.6+age*1.2);c.draw_line(p+d*24,p+d*(reach-6),Color(.84,.94,.9,tint.a),2,true)
 if echo:
  # A quiet translucent dancer outline anchors each replay to its remembered location.
  c.draw_circle(p-Vector2(0,26),5,Color(tint,.25));c.draw_line(p-Vector2(0,20),p-Vector2(0,5),Color(tint,.25),6,true)
  c.draw_line(p-Vector2(0,6),p+Vector2(-6,3),Color(tint,.25),3,true);c.draw_line(p-Vector2(0,6),p+Vector2(6,3),Color(tint,.25),3,true)
