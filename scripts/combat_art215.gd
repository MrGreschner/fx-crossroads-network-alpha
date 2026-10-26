extends RefCounted
## Bounded vector effects; no particles, full-screen shaders or per-frame textures.
static func ball(c:Node2D,p:Vector2,kind:String,angle:float=0)->void:
 if kind=="soccer":
  c.draw_circle(p,7,Color("#354b55"));c.draw_circle(p-Vector2(.4,.5),6,Color("#eaf0e4"))
  var patch:=PackedVector2Array()
  for n in 5:patch.append(p+Vector2.from_angle(angle+n*TAU/5)*2.7)
  c.draw_colored_polygon(patch,Color("#283e49"))
  for n in 5:
   var d:=Vector2.from_angle(angle+n*TAU/5);c.draw_line(p+d*2.5,p+d*5.4,Color("#8e9e9c"),.8,true);c.draw_circle(p+d*5.3,1.25,Color("#344b54"))
 elif kind=="snow":
  var edge:=PackedVector2Array()
  for n in 12:edge.append(p+Vector2.from_angle(n*TAU/12)*(7.5+sin(n*5.3)*.7))
  c.draw_colored_polygon(edge,Color("#b6d5e5"));c.draw_circle(p-Vector2(1.5,1.5),6,Color("#edf7f5"));c.draw_circle(p-Vector2(2.8,2.5),2.2,Color("#ffffff"))
  for q in [Vector2(2,3),Vector2(-3,2),Vector2(3,-2)]:c.draw_circle(p+q,1,Color("#b8d2e1"))
 else:
  c.draw_circle(p,5.5,Color("#eff5df"))
  for q in [Vector2(-2,0),Vector2(1,-2),Vector2(2,2),Vector2(-1,3)]:c.draw_circle(p+q,.8,Color("#99b5ad"))
static func bite(c:Node2D,p:Vector2,aim:Vector2,t:float)->void:
 var side:=aim.orthogonal();var tip:=p+aim*(38+25*sin(PI*t));var gap:=lerpf(15,4,clampf(t*2,0,1))
 for sign in [-1,1]:
  var centre:Vector2=tip+side*gap*sign;var tooth:=PackedVector2Array([centre-aim*13-side*5,centre+aim*8-side*5,centre+aim*13+side*4,centre-aim*12+side*5])
  c.draw_colored_polygon(tooth,Color("#f1e1b9"));tooth.append(tooth[0]);c.draw_polyline(tooth,Color("#9c805d"),1.5,true)
 c.draw_arc(p,83,aim.angle()-.45,aim.angle()+.45,20,Color(.85,.77,.56,(1-t)*.25),2,true)
static func brush(c:Node2D,p:Vector2,aim:Vector2,t:float)->void:
 var d:=aim.rotated(lerpf(-.96,.96,t));var s:=d.orthogonal();var tip:=p+d*86
 c.draw_arc(p,96,aim.angle()-.96,aim.angle()+.96,28,Color(.78,.83,.7,(1-t)*.18),3,true)
 c.draw_line(p+d*15,tip,Color("#657c78"),7,true);c.draw_line(p+d*18,tip,Color("#a7b7a5"),3,true)
 var head:=PackedVector2Array([tip-d*9-s*17,tip+d*9-s*17,tip+d*9+s*17,tip-d*9+s*17]);c.draw_colored_polygon(head,Color("#59716d"))
 for n in range(-3,4):c.draw_line(tip+d*8+s*n*4,tip+d*17+s*n*4,Color("#deca96"),2,true)
 for n in 5:
  var q:=tip-d*(n*6)+s*sin(n*2)*9;c.draw_circle(q,1.5,Color(.86,.8,.6,(1-t)*.5))
static func sunlight(c:Node2D,p:Vector2,aim:Vector2,t:float,clock:float)->void:
 c.draw_arc(p,28,-PI*.5,-PI*.5+TAU*t,36,Color("#f4cf73"),2.5,true)
 for n in 14:
  var phase:=fposmod(clock*.8+n/14.0,1);var d:=Vector2.from_angle(n*2.39996+clock*.12);var q:=p+d*lerpf(70,13,phase)
  c.draw_line(q-d*5,q,Color(1,.88,.45,.2+.5*phase),1.5,true)
 c.draw_circle(p,6+4*t,Color(1,.87,.4,.15+.18*t));c.draw_line(p+aim*25,p+aim*42,Color(1,.94,.63,.7),3,true)
static func tram(c:Node2D,p:Vector2,d:Vector2)->void:
 var s:=d.orthogonal();var hull:=PackedVector2Array([p+d*52+s*37,p+d*61+s*23,p+d*61-s*23,p+d*52-s*37,p-d*63-s*37,p-d*63+s*37])
 c.draw_colored_polygon(hull,Color(.22,.52,.57,.83));hull.append(hull[0]);c.draw_polyline(hull,Color("#8ecac2"),2,true)
 for n in 3:
  var q:=p-d*(n*29)+d*25
  c.draw_line(q-s*26,q+s*26,Color("#b8e3d1"),15,true);c.draw_line(q-s*25-d*4,q+s*25-d*4,Color("#5e9fa5"),2,true)
 for sign in [-1,1]:
  c.draw_circle(p+d*46+s*sign*23,5,Color("#f7d18c"));c.draw_line(p-d*48+s*sign*34,p+d*36+s*sign*34,Color("#d7c58e"),3,true)
 c.draw_arc(p+d*61,14,d.angle()-PI*.5,d.angle()+PI*.5,16,Color("#d5efe0"),2,true)
static func court(c:Node2D,p:Vector2,r:float,t:float)->void:
 c.draw_circle(p,r,Color(.55,.4,.7,.055));c.draw_arc(p,r,0,TAU,64,Color(.77,.65,.9,.7),2,true)
 for n in 8:
  var d:=Vector2.from_angle(n*TAU/8);var q:=p+d*r;var s:=d.orthogonal()
  c.draw_line(q-d*13,q+d*7,Color("#ad98c8"),4,true);c.draw_circle(q-d*13,3,Color("#d9c996"));c.draw_arc(q,7,d.angle(),d.angle()+PI,10,Color("#d4bf8e"),2,true)
  if n%2==0:c.draw_line(q,q-s*12+Vector2(0,-17),Color(.7,.53,.8,.5),3,true)
 c.draw_arc(p,r*.72,-PI*.5,-PI*.5+TAU*t,48,Color("#ddc898"),2,true)
static func thread(c:Node2D,p:Vector2,aim:Vector2,clock:float)->void:
 var path:=PackedVector2Array()
 for n in 10:path.append(p-aim*n*3+aim.orthogonal()*sin(clock*17+n*.7)*2.2)
 c.draw_polyline(path,Color("#c7a3da"),2,true)
 var side:=aim.orthogonal();c.draw_colored_polygon(PackedVector2Array([p+aim*11,p+side*4,p-aim*5,p-side*4]),Color("#e2c99d"));c.draw_line(p-aim*4,p+aim*7,Color("#f3e8cd"),1,true)

static func tail(c:Node2D,p:Vector2,aim:Vector2,t:float)->void:
 var d:Vector2=aim.rotated(lerpf(-1.2,1.2,t));var side:Vector2=d.orthogonal();var base:Vector2=p+d*24;var tip:Vector2=p+d*90
 var paddle:=PackedVector2Array([base-side*11,tip-d*13-side*22,tip+side*20,base+side*11])
 c.draw_colored_polygon(paddle,Color("#835e42"));paddle.append(paddle[0]);c.draw_polyline(paddle,Color("#523f35"),2,true)
 for n in 5:
  var q:Vector2=base.lerp(tip,.2+n*.14);c.draw_line(q-side*13,q+side*13,Color("#ad8357"),1.5,true)
 c.draw_arc(p,116,aim.angle()-1.2,aim.angle()+1.2,28,Color(.78,.68,.47,(1-t)*.3),3,true)
static func falling_tree(c:Node2D,start:Vector2,tip:Vector2,t:float,fade:float)->void:
 var axis:Vector2=(tip-start).normalized();var side:Vector2=axis.orthogonal()
 c.draw_line(start,tip,Color(.30,.23,.18,fade),25,true);c.draw_line(start+side*2,tip+side*2,Color(.54,.39,.25,fade),17,true)
 for n in 7:
  var q:Vector2=start.lerp(tip,.1+n*.12);c.draw_line(q-side*5,q-side*3+axis*14,Color(.72,.53,.32,fade*.8),2,true)
 for n in 7:
  var q:Vector2=start.lerp(tip,.44+n*.075)+side*(12 if n%2==0 else -12)
  c.draw_line(q-axis*20,q,Color(.34,.28,.18,fade),5,true)
  for leaf in 3:
   var centre:Vector2=q+Vector2.from_angle(n*2+leaf*TAU/3)*10
   c.draw_colored_polygon(PackedVector2Array([centre-Vector2(16,3),centre-Vector2(7,17),centre+Vector2(14,-10),centre+Vector2(18,9),centre+Vector2(-5,15)]),Color(.28+leaf*.035,.46+leaf*.02,.27,fade))
 c.draw_circle(start,13,Color(.72,.55,.35,fade));c.draw_arc(start,8,0,TAU,16,Color(.41,.31,.22,fade),1.5,true)
 if t>.8:
  for n in 9:
   var q:Vector2=tip+Vector2.from_angle(n*2.4)*((t-.8)*100+7);c.draw_line(q,q+Vector2(3,4),Color(.68,.57,.35,fade),2,true)
