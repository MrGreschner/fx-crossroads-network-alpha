extends RefCounted
## A shared, inexpensive warning language; draw only what is on screen.
static func visible(c:Node2D,p:Vector2,radius:float=50)->bool:
 var view:Vector2=c.VIEW if c.has_method("spectating") and c.spectating() else c.get_viewport_rect().size
 return Rect2(Vector2.ZERO,view).grow(radius+20).has_point(p)
static func danger(c:Node2D,p:Vector2,radius:float,left:float,total:float=1,colour:Color=Color("#ffc075"))->void:
 if not visible(c,p,radius):return
 radius=maxf(8,radius)
 c.draw_circle(p,radius,Color(colour,.065));c.draw_arc(p,radius,0,TAU,40,Color(colour,.75),2,true)
 var progress:=clampf(1-left/maxf(.01,total),0,1)
 c.draw_arc(p,radius*.94,-PI/2,-PI/2+TAU*maxf(.01,progress),40,Color("#ffe7ae"),4,true)
 for n in 4:
  var d:=Vector2.from_angle(PI*n*.5)
  c.draw_line(p+d*(radius+7),p+d*(radius-8),Color("#ffc075"),2,true)
 badge(c,p+Vector2(0,radius*.55),"!",Color("#ffc075"))
static func rectangle(c:Node2D,r:Rect2,left:float,total:float)->void:
 if not r.intersects(c.get_viewport_rect()):return
 c.draw_rect(r,Color(1,.68,.3,.07));c.draw_rect(r,Color("#ffc075"),false,2)
 c.draw_line(r.position,r.position+Vector2(r.size.x*clampf(1-left/maxf(.01,total),0,1),0),Color("#ffe7ae"),4,true)
 badge(c,r.get_center(),"!",Color("#ffc075"))
static func corridor(c:Node2D,a:Vector2,b:Vector2,width:float)->void:
 if not Rect2(a.min(b),a.max(b)-a.min(b)).grow(width).intersects(c.get_viewport_rect()):return
 var normal:Vector2=(b-a).normalized().orthogonal()*width
 c.draw_line(a,b,Color(1,.65,.32,.08),maxf(1,width*2),true)
 c.draw_line(a+normal,b+normal,Color("#ffc075"),2,true);c.draw_line(a-normal,b-normal,Color("#ffc075"),2,true)
 var d:Vector2=(b-a).normalized()
 c.draw_line(b,b-d.rotated(.5)*18,Color("#ffe7ae"),3,true);c.draw_line(b,b-d.rotated(-.5)*18,Color("#ffe7ae"),3,true)
 badge(c,a.lerp(b,.5),"!",Color("#ffc075"))
static func badge(c:Node2D,p:Vector2,text:String,colour:Color)->void:
 c.draw_circle(p,12,Color("#172e39"));c.draw_arc(p,12,0,TAU,16,colour,1.5,true)
 c.draw_string(ThemeDB.fallback_font,p+Vector2(-5,6),text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,colour)
static func healing(c:Node2D,p:Vector2,radius:float)->void:
 if not visible(c,p,radius):return
 c.draw_arc(p,radius,0,TAU,40,Color(.55,1,.7,.65),2,true);badge(c,p,"+",Color("#96edb5"))
static func enemy_healing(c:Node2D,p:Vector2,radius:float)->void:
 if not visible(c,p,radius):return
 c.draw_arc(p,radius,0,TAU,40,Color("#cb95ec"),2,true);badge(c,p,"+",Color("#cb95ec"));badge(c,p+Vector2(0,radius*.55),"!",Color("#ffc075"))
static func status(c:Node2D,p:Vector2,kind:String,clock:float)->void:
 if not visible(c,p,15):return
 var colours:Dictionary={"burn":"#ff9b35","bleed":"#ee5864","slow":"#62c8ff","stun":"#ffffff","poison":"#bc80ee"}
 var col:=Color(str(colours.get(kind,"#ffffff")))
 c.draw_circle(p,7,Color("#172833"));c.draw_arc(p,7,0,TAU,12,Color(col,.6),1,true)
 match kind:
  "burn":c.draw_colored_polygon(PackedVector2Array([p+Vector2(-4,3),p+Vector2(-3,-1),p+Vector2(0,-6-sin(clock*10)),p+Vector2(4,1),p+Vector2(2,4)]),col)
  "bleed":c.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-5),p+Vector2(4,2),p+Vector2(0,5),p+Vector2(-4,2)]),col)
  "slow":
   c.draw_line(p+Vector2(-4,-3),p+Vector2(0,1),col,2,true);c.draw_line(p+Vector2(0,1),p+Vector2(4,-3),col,2,true)
   c.draw_line(p+Vector2(-4,1),p+Vector2(0,5),col,2,true);c.draw_line(p+Vector2(0,5),p+Vector2(4,1),col,2,true)
  "stun":
   for n in 4:c.draw_line(p,p+Vector2.from_angle(n*PI*.5+clock)*5,col,2,true)
  "poison":
   c.draw_circle(p+Vector2(-2,-2),2,col);c.draw_circle(p+Vector2(3,0),2,col);c.draw_circle(p+Vector2(0,4),2,col)
