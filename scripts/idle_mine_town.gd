extends RefCounted
const ENTRY=Vector2(-1080,800)
var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
func interact(g:Node)->bool:
 if g.position_in_world.distance_to(ENTRY)>85:return false
 g.hint="E • Deepwell Mine • your idle mining operation"
 if Input.is_action_just_pressed("interact"):g.legacy.mine.open()
 return true
func draw_on(g:Node2D,camera:Vector2)->void:
 var mine=Vector2(-1130,750)-camera
 if not Rect2(Vector2.ZERO,g.VIEW).grow(150).has_point(mine):return
 var t=Time.get_ticks_msec()/1000.0
 g.draw_circle(mine,66,Color("#596260"));g.draw_circle(mine+Vector2(0,8),46,Color("#172c33"))
 for x in [-48,42]:g.draw_rect(Rect2(mine+Vector2(x,-43),Vector2(10,94)),Color("#957551"))
 g.draw_rect(Rect2(mine+Vector2(-53,-48),Vector2(107,11)),Color("#b19469"))
 var night:float=g.town_life.calendar.night_amount()
 for entry in [[Vector2(-34,-24),7.0],[Vector2(33,-24),7.0],[Vector2(-20,-8),4.0],[Vector2(16,-5),3.0],[Vector2(0,4),2.0]]:
  var q:Vector2=mine+entry[0];var r:float=entry[1]
  g.draw_circle(q,r+3,Color("#4e4b3e"));g.draw_circle(q,r,Color("#ffe1a0") if night>.1 else Color("#a4966c"))
  if night>.1:g.draw_circle(q,r*2.6,Color(1,.73,.32,night*.1))
 var pad=ENTRY-camera;g.draw_arc(pad,27,0,TAU,28,Color("#e0be76") if g.position_in_world.distance_to(ENTRY)<85 else Color(.75,.7,.53,.4),2,true)
 var cart=mine+Vector2(28,68);g.draw_rect(Rect2(cart+Vector2(-17,-12),Vector2(34,20)),Color("#66858b"))
 for x in [-12,12]:g.draw_circle(cart+Vector2(x,11),5,Color("#26363c"))
 for n in 4:g.draw_circle(cart+Vector2(-11+n*7,-11),4,Color("#c7b886"))
 var fan=mine+Vector2(-82,13);g.draw_circle(fan,16,Color("#547c81"))
 for n in 4:
  var a=t*1.3+n*PI*.5;g.draw_line(fan,fan+Vector2(cos(a),sin(a))*12,Color("#a5c6c5"),3,true)
 g.draw_string(font,mine+Vector2(-70,-68),"DEEPWELL MINE",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#edcf8e"))
 if g.legacy.mine.state().commissioned:g.draw_string(font,mine+Vector2(-65,138),str(g.legacy.mine.depth()*30)+"m • "+str(g.legacy.mine.workers())+" diggers",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#ccd6bc"))
