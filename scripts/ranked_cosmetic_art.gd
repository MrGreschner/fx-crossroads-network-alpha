extends RefCounted
const R=preload("res://scripts/cosmetic_rankings.gd")
static func active(cosmetic:Dictionary)->Array:
 var now=Time.get_unix_time_from_system()
 if float(cosmetic.get("rank_until",0))<=now or float(cosmetic.get("rank_until",0))>now+95:return []
 return cosmetic.get("rank_badges",[]).filter(func(id):return id in R.IDS)
static func draw_lobby(c:CanvasItem,p:Vector2,t:float,cosmetic:Dictionary,body:Rect2=Rect2())->void:
 for id in active(cosmetic):draw_single(c,p,t,str(id),int(cosmetic.get("rank_pennant",0)),body)
static func anchor(id:String)->Vector2:
 return {"rank_week_damage":Vector2(34,-32),"rank_week_fish":Vector2(-35,-8),"rank_all_damage":Vector2(-37,-43),"week_arena_1":Vector2(27,-65),"week_arena_2":Vector2(-20,-71),"week_arena_3":Vector2(0,-117),"week_gate":Vector2(-25,-48),"week_descent":Vector2(20,-31),"week_market":Vector2(-23,-22)}.get(id,Vector2.ZERO)
static func draw_icon(c:CanvasItem,at:Vector2,t:float,id:String)->void:draw_single(c,at-anchor(id),t,id,3)
static func draw_single(c:CanvasItem,p:Vector2,t:float,id:String,pennant:int=3,body:Rect2=Rect2())->void:
 if body.has_area():
  var positions={"rank_week_damage":Vector2(body.end.x+32,body.position.y-56),"rank_all_damage":Vector2(body.position.x-32,body.position.y-56),"rank_week_fish":Vector2(body.position.x-32,body.position.y-22),"week_arena_1":Vector2(body.end.x+32,body.position.y-22),"week_arena_2":Vector2(body.position.x-32,body.position.y+12),"week_arena_3":Vector2(body.get_center().x,body.position.y-48),"week_gate":Vector2(body.end.x+32,body.position.y+12),"week_descent":Vector2(body.position.x-32,body.position.y+46),"week_market":Vector2(body.end.x+32,body.position.y+46)}
  p=positions.get(id,body.position)-anchor(id)
 var q=p+anchor(id)
 match id:
  "rank_week_damage":
   for n in 3:
    var a=t*1.8+n*TAU/3;var v=q+Vector2(sin(a)*9,cos(a)*22);c.draw_circle(v,6,Color(1,.64,.27,.12));c.draw_circle(v,2.4,Color("#ffc97e"));c.draw_line(v,v+Vector2(-7,-5),Color("#e6786f"),2,true)
  "rank_week_fish":
   q+=Vector2(sin(t)*4,cos(t)*3);c.draw_arc(p+anchor(id),15,t*.4,t*.4+PI*1.5,32,Color(.4,.85,.95,.5),1.6,true)
   c.draw_colored_polygon(PackedVector2Array([q+Vector2(-9,0),q+Vector2(1,-5),q+Vector2(9,0),q+Vector2(1,5)]),Color("#9debe8"));c.draw_colored_polygon(PackedVector2Array([q+Vector2(-7,0),q+Vector2(-14,-5),q+Vector2(-14,5)]),Color("#74aecb"));c.draw_circle(q+Vector2(5,-1),1,Color("#203a52"))
  "rank_all_damage":
   var points=PackedVector2Array()
   for n in 5:
    var a=-PI*.5+n*TAU/5;var v=q+Vector2(cos(a)*17,sin(a)*19);points.append(v);c.draw_circle(v,5,Color(.75,.63,1,.10));c.draw_circle(v,2.2,Color("#d8c1ff"));c.draw_line(v-Vector2(4,0),v+Vector2(4,0),Color("#ffe0a1"),1,true)
   points.append(points[0]);c.draw_polyline(points,Color(.75,.63,1,.6),1.3,true)
  "week_arena_1":
   var ink=[Color("#bc9065"),Color("#c5d6df"),Color("#e7cc7f")][clampi(pennant,1,3)-1];q.y+=sin(t*1.7)*1
   c.draw_line(q+Vector2(-4,-8),q+Vector2(-4,8),Color("#cbb995"),1.3,true);c.draw_circle(q+Vector2(-4,-9),1.3,ink)
   var shape=PackedVector2Array([q+Vector2(-3,-8),q+Vector2(9,-7+sin(t*2.7)),q+Vector2(5,-2),q+Vector2(8,1),q+Vector2(-3,0)])
   c.draw_colored_polygon(shape,ink);c.draw_line(q+Vector2(-2,-7),q+Vector2(5,-6),ink.lightened(.3),.7,true);c.draw_circle(q+Vector2(1,-4),1,Color("#4c5c62"))
  "week_arena_2":
   for side in [-1,1]:
    c.draw_line(q+Vector2(side*6,-8),q+Vector2(-side*6,8),Color("#c4deeb"),2,true);c.draw_line(q+Vector2(-side*8,4),q+Vector2(-side*2,8),Color("#d6b882"),1.5,true)
  "week_arena_3":
   c.draw_colored_polygon(PackedVector2Array([q+Vector2(-9,4),q+Vector2(-10,-5),q+Vector2(-4,-1),q+Vector2(0,-9),q+Vector2(4,-1),q+Vector2(10,-5),q+Vector2(9,4)]),Color("#ebcf82"));c.draw_circle(q,1.5,Color("#aa7395"));c.draw_line(q+Vector2(-7,6),q+Vector2(7,6),Color("#fff0bb"),1,true)
  "week_gate":
   q.y+=sin(t)*2;c.draw_arc(q+Vector2(0,-6),4,PI,TAU,14,Color("#bedac8"),1,true);c.draw_rect(Rect2(q-Vector2(5,6),Vector2(10,14)),Color("#92c6b3"),false,1.3);c.draw_circle(q,2.4,Color("#dcf1bf"));c.draw_arc(q,10,t*.6,t*.6+PI*.5,12,Color(.6,.85,.75,.4),1,true)
  "week_descent":
   q.y+=sin(t*1.4);var diamond=PackedVector2Array([q+Vector2(0,-7),q+Vector2(4,-2),q+Vector2(3,4),q+Vector2(0,7),q+Vector2(-3,4),q+Vector2(-4,-2)])
   c.draw_colored_polygon(diamond,Color("#a99cdb"));c.draw_colored_polygon(PackedVector2Array([q+Vector2(0,-7),q+Vector2(1,-1),q+Vector2(0,7),q+Vector2(-3,4),q+Vector2(-4,-2)]),Color("#d7d4f4"));c.draw_line(q+Vector2(-4,-2),q+Vector2(4,-2),Color("#e9e2ff"),.7,true);c.draw_line(q+Vector2(0,-7),q+Vector2(1,1),Color.WHITE,.8,true)
  "week_market":
   for n in 3:
    var v=q+Vector2((n-1)*5,sin(t*1.5+n)*2);c.draw_circle(v,2.5,Color("#d8bc74"));c.draw_arc(v,2,0,TAU,12,Color("#f4dba0"),.6,true);c.draw_line(v-Vector2(0,1.3),v+Vector2(0,1.3),Color("#927a4f"),.7,true)
