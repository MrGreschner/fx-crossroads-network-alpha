extends RefCounted
const R=preload("res://scripts/cosmetic_rankings.gd")
static func active(cosmetic:Dictionary)->Array:
 var now=Time.get_unix_time_from_system()
 if float(cosmetic.get("rank_until",0))<=now or float(cosmetic.get("rank_until",0))>now+95:return []
 return cosmetic.get("rank_badges",[]).filter(func(id):return id in R.IDS)
static func draw_lobby(c:CanvasItem,p:Vector2,t:float,cosmetic:Dictionary)->void:
 for id in active(cosmetic):draw_single(c,p,t,str(id))
static func draw_single(c:CanvasItem,p:Vector2,t:float,id:String)->void:
 if id=="rank_week_damage":
  for n in 3:
   var a=t*1.8+n*TAU/3;var q=p+Vector2(34+sin(a)*9,-32+cos(a)*22)
   c.draw_circle(q,6,Color(1,.64,.27,.12));c.draw_circle(q,2.4,Color("#ffc97e"));c.draw_line(q,q+Vector2(-7,-5),Color("#e6786f"),2,true)
 elif id=="rank_week_fish":
  var q=p+Vector2(-35+sin(t)*4,-8+cos(t)*3)
  c.draw_arc(p+Vector2(-35,-8),15,t*.4,t*.4+PI*1.5,32,Color(.4,.85,.95,.5),1.6,true)
  c.draw_colored_polygon(PackedVector2Array([q+Vector2(-9,0),q+Vector2(1,-5),q+Vector2(9,0),q+Vector2(1,5)]),Color("#9debe8"))
  c.draw_colored_polygon(PackedVector2Array([q+Vector2(-7,0),q+Vector2(-14,-5),q+Vector2(-14,5)]),Color("#74aecb"));c.draw_circle(q+Vector2(5,-1),1,Color("#203a52"))
 elif id=="rank_all_damage":
  var points=PackedVector2Array()
  for n in 5:
   var a=-PI*.5+n*TAU/5;var q=p+Vector2(-37,-43)+Vector2(cos(a)*17,sin(a)*19)
   points.append(q);c.draw_circle(q,5,Color(.75,.63,1,.10));c.draw_circle(q,2.2,Color("#d8c1ff"));c.draw_line(q-Vector2(4,0),q+Vector2(4,0),Color("#ffe0a1"),1,true)
  points.append(points[0]);c.draw_polyline(points,Color(.75,.63,1,.6),1.3,true)
