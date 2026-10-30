extends RefCounted
## Shared practice sprites and lightweight effect presets; custom artwork stays embedded in portable abilities.
static func shot(c:CanvasItem,p:Vector2,d:Vector2,a:Dictionary,scale_value:float=1)->void:
 var color=Color(a.get("color","#7bd8de"));var side=Vector2(-d.y,d.x);var kind=str(a.get("projectile_graphic","bolt"));var s=scale_value
 match kind:
  "arrow":c.draw_line(p-d*16*s,p+d*12*s,color,3);c.draw_colored_polygon(PackedVector2Array([p+d*15*s,p+d*5*s+side*6*s,p+d*5*s-side*6*s]),color)
  "fire":c.draw_circle(p,8*s,Color(color,.3));c.draw_circle(p,5*s,color);c.draw_colored_polygon(PackedVector2Array([p+side*4*s,p-d*17*s,p-side*4*s]),Color("#f8c47f"))
  "ice":c.draw_colored_polygon(PackedVector2Array([p+d*13*s,p+side*5*s,p-d*8*s,p-side*5*s]),color);c.draw_line(p-d*5*s,p+d*8*s,Color.WHITE,1)
  "leaf":c.draw_colored_polygon(PackedVector2Array([p+d*11*s,p+side*7*s,p-d*10*s,p-side*3*s]),color);c.draw_line(p-d*9*s,p+d*7*s,Color("#eff2b6"),1)
  "star":
   for n in 4:c.draw_colored_polygon(PackedVector2Array([p,p+Vector2.from_angle(d.angle()+n*PI/2)*11*s,p+Vector2.from_angle(d.angle()+n*PI/2+.7)*4*s]),color)
  "lightning":c.draw_polyline(PackedVector2Array([p-d*14*s,p-d*5*s+side*4*s,p+d*3*s-side*5*s,p+d*12*s]),color,3,true)
  "water","bubble":c.draw_circle(p,7*s,Color(color,.35));c.draw_arc(p,7*s,0,TAU,16,color,2);c.draw_circle(p+Vector2(-2,-3)*s,2*s,Color.WHITE)
  "seed","stone":c.draw_circle(p,5*s,color);c.draw_line(p-d*4*s-side*2*s,p+d*3*s-side*2*s,Color(color.lightened(.3)),2)
  "heart":c.draw_circle(p+Vector2(-3,-2)*s,4*s,color);c.draw_circle(p+Vector2(3,-2)*s,4*s,color);c.draw_colored_polygon(PackedVector2Array([p+Vector2(-7,0)*s,p+Vector2(7,0)*s,p+Vector2(0,8)*s]),color)
  "skull":c.draw_circle(p,7*s,color);c.draw_circle(p+Vector2(-3,-1)*s,2*s,Color("#102c38"));c.draw_circle(p+Vector2(3,-1)*s,2*s,Color("#102c38"));c.draw_rect(Rect2(p+Vector2(-4,4)*s,Vector2(8,5)*s),color)
  "orb":c.draw_circle(p,10*s,Color(color,.2));c.draw_circle(p,6*s,color);c.draw_circle(p-Vector2.ONE*2*s,2*s,Color.WHITE)
  _:c.draw_line(p-d*12*s,p,color,4*s,true);c.draw_circle(p,5*s,color)
static func charge(c:CanvasItem,p:Vector2,d:Vector2,a:Dictionary,ratio:float,clock:float)->void:
 var color=Color(a.color);var kind=str(a.get("charge_visual","gauge"));c.draw_arc(p,34,-PI*.5,-PI*.5+TAU*ratio,32,color,3)
 if kind=="grow":shot(c,p+d*36,d,a,.5+ratio*1.5)
 elif kind in ["orbit","flame"]:
  for n in 5:
   var point=p+Vector2.from_angle(clock*2+n*TAU/5)*(38-ratio*12);c.draw_circle(point,2+ratio*2,color)
 elif kind=="runes":
  for n in 6:
   var point=p+Vector2.from_angle(clock*.4+n*TAU/6)*43;c.draw_rect(Rect2(point-Vector2.ONE*3,Vector2.ONE*6),Color(color,.3+ratio*.6),false,2)
static func minion_pose(m:Dictionary,clock:float)->String:
 return "attack" if float(m.get("flash",0))>0 else ["walk1","walk2"][int(clock*5)%2] if bool(m.get("moving",false)) else "idle"
static func minion(c:CanvasItem,p:Vector2,m:Dictionary,clock:float)->void:
 var kind=str(m.ability.get("minion_graphic","ram"))
 if kind not in ["ram","rabbit","cat","bee","wisp","golem"]:kind="ram"
 var pose=minion_pose(m,clock)
 var t=preload("res://scripts/studio_art249.gd").texture("summon_"+kind,pose)
 c.draw_circle(p+Vector2(0,9),12,Color(0,0,0,.20))
 c.draw_texture_rect(t,Rect2(p-Vector2(24,35),Vector2(48,48)),false)
static func strike(c:CanvasItem,v:Dictionary,camera:Vector2)->void:
 var a:Dictionary=v.ability;var p:Vector2=v.pos-camera;var d:Vector2=v.aim;var color=Color(a.color);var arc=deg_to_rad(float(a.get("melee_arc",100)));var reach=float(a.range);var angle=d.angle();var progress=1-float(v.life)/float(v.total);var kind=str(a.get("melee_visual","swing"))
 var points=PackedVector2Array([p])
 for n in 25:points.append(p+Vector2.from_angle(angle-arc*.5+arc*n/24)*reach)
 c.draw_colored_polygon(points,Color(color,.10));c.draw_arc(p,reach,angle-arc*.5,angle+arc*.5,32,Color(color,.25),1,true)
 if kind in ["swing","staff","scythe","slash","claw","custom"]:
  var sweep=angle-arc*.5+arc*progress
  c.draw_arc(p,reach*.95,sweep-.22,sweep+.22,12,Color(color,1-progress),5 if kind=="scythe" else 3,true)
  if kind in ["claw","slash"]:
   for offset in [-.12,.12]:c.draw_line(p+Vector2.from_angle(sweep+offset)*reach*.4,p+Vector2.from_angle(sweep+offset)*reach,color,3,true)
 elif kind=="jab":
  for n in 3:
   var phase=clampf(progress*3-n,0,1);var end=p+d*reach*sin(phase*PI*.5);c.draw_line(p+d*18,end,Color(color,1-progress),4,true)
 else:c.draw_arc(p,reach*(progress if kind=="pulse" else .9),angle-arc*.5,angle+arc*.5,32,Color(color,1-progress),4,true)
