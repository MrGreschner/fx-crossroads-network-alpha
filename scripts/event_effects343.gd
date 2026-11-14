extends RefCounted

static func parcel(c:Node2D,p:Vector2,opened:=false)->void:
 c.draw_rect(Rect2(p-Vector2(12,9),Vector2(24,18)),Color("#542f36"))
 c.draw_rect(Rect2(p-Vector2(10,7),Vector2(20,14)),Color("#a75554"))
 c.draw_rect(Rect2(p-Vector2(2,7),Vector2(4,14)),Color("#f4cf87"))
 c.draw_rect(Rect2(p-Vector2(10,2),Vector2(20,4)),Color("#e9b875"))
 if opened:
  c.draw_line(p+Vector2(-10,-8),p+Vector2(-17,-15),Color("#e5b87e"),4)
  c.draw_line(p+Vector2(10,-8),p+Vector2(17,-15),Color("#e5b87e"),4)
  c.draw_line(p+Vector2(0,-24),p+Vector2(0,-12),Color("#c7f3a9"),3)
  c.draw_line(p+Vector2(-6,-18),p+Vector2(6,-18),Color("#c7f3a9"),3)

static func projectile(c:Node2D,p:Vector2,aim:Vector2,style:String)->bool:
 if style=="gift_toss":
  parcel(c,p)
  return true
 if style!="courtbow":return false
 var side:=aim.orthogonal()
 c.draw_line(p-aim*17,p+aim*8,Color("#5b382a"),4,true)
 c.draw_line(p-aim*14,p+aim*8,Color("#f2c980"),2,true)
 c.draw_colored_polygon(PackedVector2Array([p+aim*12,p+aim*4+side*4,p+aim*5,p+aim*4-side*4]),Color("#fff1c5"))
 c.draw_line(p-aim*11-side*3,p-aim*16,Color("#b6d5cf"),2,true)
 c.draw_line(p-aim*11+side*3,p-aim*16,Color("#b6d5cf"),2,true)
 return true

static func branch(c:Node2D,p:Vector2,remaining:float)->void:
 c.draw_circle(p,13,Color("#26433c"))
 c.draw_line(p,p+Vector2(3,-32),Color("#91634b"),5,true)
 c.draw_line(p+Vector2(1,-16),p+Vector2(-11,-24),Color("#b38158"),3,true)
 for at in [Vector2(-11,-25),Vector2(4,-33),Vector2(11,-21)]:
  c.draw_circle(p+at,5,Color("#f1adad"))
  c.draw_circle(p+at,2,Color("#fff0b6"))
 c.draw_arc(p,17,-PI/2,-PI/2+TAU*clampf(remaining/7,0,1),24,Color("#efc6a8"),2,true)

static func shield(c:Node2D,p:Vector2)->void:
 var shape:=PackedVector2Array([p+Vector2(-10,-12),p+Vector2(10,-12),p+Vector2(9,3),p+Vector2(0,12),p+Vector2(-9,3),p+Vector2(-10,-12)])
 c.draw_colored_polygon(shape.slice(0,5),Color("#466b74"))
 c.draw_polyline(shape,Color("#f4d28d"),2,true)
 c.draw_line(p+Vector2(0,-8),p+Vector2(0,6),Color("#b6e6dc"),2,true)

static func ring(c:Node2D,p:Vector2,r:float,tint:Color)->void:
 c.draw_circle(p,r,Color(tint,.09))
 c.draw_arc(p,r,0,TAU,32,Color(tint,.65),2,true)

static func effect(c:Node2D,p:Vector2,f:Dictionary,combat:Node,camera:Vector2)->void:
 var r:=float(f.radius)
 var tint:=Color("#abebff")
 match str(f.kind):
  "bite","antlers":
   var aim:Vector2=combat.vec(f.aim)
   var phase:=1.0-clampf(float(f.time)/.32,0,1)
   var a:=aim.angle()
   var shade:=Color("#f8cc88" if f.kind=="bite" else "#c7f2ff",1-phase)
   c.draw_arc(p,r,a-acos(.15),a+acos(.15),28,Color(shade,.55*(1-phase)),2,true)
   c.draw_arc(p,r*lerpf(.40,1.0,phase),a-1.28,a+1.28,24,shade,5,true)
   for sign_value in [-1,1]:
    var tip:Vector2=p+aim.rotated(sign_value*1.14)*r*lerpf(.55,1.0,phase)
    c.draw_line(tip,tip-aim*12,shade,3,true)
  "parcel_lob","parachute":
   var progress:=clampf(1.0-float(f.time)/float(f.total),0,1)
   var origin:Vector2=combat.vec(f.origin)-camera
   var airborne:=origin.lerp(p,progress)-Vector2(0,sin(progress*PI)*88) if f.kind=="parcel_lob" else p-Vector2(sin(progress*PI*2)*12,(1-progress)*155)
   c.draw_set_transform(p,0,Vector2(1,.35))
   c.draw_circle(Vector2.ZERO,18,Color("#121f2b",.60))
   c.draw_set_transform(Vector2.ZERO)
   ring(c,p,20,Color("#f5cf91"))
   if f.kind=="parachute":
    var canopy:=airborne-Vector2(0,28)
    var cloth:=PackedVector2Array([canopy+Vector2(-22,0),canopy+Vector2(-15,-9),canopy+Vector2(0,-14),canopy+Vector2(15,-9),canopy+Vector2(22,0)])
    c.draw_colored_polygon(cloth,Color("#bb665d"))
    c.draw_polyline(cloth,Color("#f6d6a1"),2,true)
    for x in [-20,0,20]:c.draw_line(canopy+Vector2(x,0),airborne-Vector2(0,7),Color("#edd1a2"),1.5,true)
   parcel(c,airborne)
  "parcel","healing_gift":
   ring(c,p,r,Color("#d9e7ac"));parcel(c,p,f.kind=="healing_gift")
  "blossom":
   ring(c,p,r,Color("#f5cd98"));shield(c,p-Vector2(0,6))
  "garden":
   ring(c,p,r,Color("#f1a9b2"));branch(c,p,7)
  _:
   ring(c,p,r,tint)

static func brace(c:Node2D,p:Vector2,remaining:float)->void:
 ring(c,p,95,Color("#f7bd70"))
 c.draw_arc(p,92,-PI/2,-PI/2+TAU*clampf(remaining/5,0,1),36,Color("#ffe0a4"),3,true)
 c.draw_string(ThemeDB.fallback_font,p+Vector2(-43,-68),"Jaws open  %.1f" % remaining,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#ffe0a4"))

static func flight(c:Node2D,p:Vector2,altitude:float,time:float,total:float,rise:float,land:float)->void:
 c.draw_set_transform(p,0,Vector2(1,.38))
 c.draw_circle(Vector2.ZERO,lerpf(21,12,altitude/72),Color("#142430",.60))
 c.draw_set_transform(Vector2.ZERO)
 for i in 7:
  var angle:=i*TAU/7+time*2
  var mote:=p+Vector2.from_angle(angle)*Vector2(28,11)-Vector2(0,altitude*float(i)/7)
  c.draw_circle(mote,2,Color("#caefff",.68))
 var text:="Taking off" if time>total-rise else "Landing" if time<=land else "%.1f" % maxf(0,time-land)
 c.draw_string(ThemeDB.fallback_font,p+Vector2(-28,-61-altitude),text,HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#edfbff"))
