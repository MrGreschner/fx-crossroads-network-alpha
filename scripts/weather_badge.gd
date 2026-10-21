extends RefCounted
static func draw_on(c:Node2D,sky:String)->void:
 var p=Vector2(24,132 if c.VIEW.x<1100 else 118);var color=Color("#c7e6e5")
 c.draw_style_box(preload("res://scripts/studio_ui.gd").box("#19333f","#799da3",5,0),Rect2(p,Vector2(36,30)))
 if sky=="Clear":
  c.draw_circle(p+Vector2(18,14),6,Color("#ffe39b"))
  for n in 8:
   var d=Vector2.from_angle(n*TAU/8);c.draw_line(p+Vector2(18,14)+d*9,p+Vector2(18,14)+d*12,Color("#ffe39b"),1.5)
 elif sky=="Mist":
  for n in 3:c.draw_line(p+Vector2(6+n%2*3,8+n*6),p+Vector2(30-n%2*3,8+n*6),color,2.5,true)
 else:
  for q in [Vector2(11,13),Vector2(18,10),Vector2(25,14)]:c.draw_circle(p+q,6,color)
  c.draw_rect(Rect2(p+Vector2(8,14),Vector2(22,5)),color)
  if sky=="Rain":
   for n in 3:c.draw_line(p+Vector2(12+n*7,21),p+Vector2(10+n*7,26),Color("#89caff"),2,true)
 c.draw_string(c.font,p+Vector2(43,21),sky,HORIZONTAL_ALIGNMENT_LEFT,110,12,color)
