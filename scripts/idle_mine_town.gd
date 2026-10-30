extends RefCounted
const EXCHANGE=Rect2(-930,650,230,145)
const EXCHANGE_DOOR=Vector2(-815,825)
const ENTRY=Vector2(-1080,800)
var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
func interact(g:Node)->bool:
 if g.position_in_world.distance_to(EXCHANGE_DOOR)<72:
  g.hint="E • Deepwell Exchange • ore, gems & mining business"
  if Input.is_action_just_pressed("interact"):g.legacy.commerce.open()
  return true
 if g.position_in_world.distance_to(ENTRY)>85:return false
 g.hint="E • Deepwell Mine • your idle mining operation"
 if Input.is_action_just_pressed("interact"):g.legacy.mine.open()
 return true
func draw_on(g:Node2D,camera:Vector2)->void:
 draw_exchange(g,camera)
 if Rect2(camera,g.VIEW).grow(80).has_point(Vector2(-967,764)):
  var bay=Vector2(-967,725)-camera
  g.draw_rect(Rect2(bay,Vector2(30,65)),Color("#6f7362"));g.draw_line(bay,bay+Vector2(30,0),Color("#d0b57c"),5)
 var mine=Vector2(-1130,750)-camera
 if not Rect2(Vector2.ZERO,g.VIEW).grow(150).has_point(mine):return
 var t=Time.get_ticks_msec()/1000.0
 var Art=preload("res://scripts/cast_art232.gd")
 Art.draw_prop(g,"entrance",Rect2(mine+Vector2(-70,-65),Vector2(140,120)))
 var night:float=g.town_life.calendar.night_amount()
 if night>.1:
  for q in [mine+Vector2(-40,-4),mine+Vector2(39,-4)]:g.draw_circle(q,14,Color(1,.73,.32,night*.08))
 var pad=ENTRY-camera;g.draw_arc(pad,27,0,TAU,28,Color("#e0be76") if g.position_in_world.distance_to(ENTRY)<85 else Color(.75,.7,.53,.4),2,true)
 Art.draw_prop(g,"cart",Rect2(mine+Vector2(6,47),Vector2(47,33)))
 Art.draw_prop(g,"vent",Rect2(mine+Vector2(-112,4),Vector2(55,49)))
 g.draw_string(font,mine+Vector2(-70,-68),"DEEPWELL MINE",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#edcf8e"))
 if g.legacy.mine.state().commissioned:g.draw_string(font,mine+Vector2(-65,138),str(g.legacy.mine.depth()*30)+"m • "+str(g.legacy.mine.workers())+" diggers",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#ccd6bc"))

func blocked(p:Vector2)->bool:return EXCHANGE.grow(5).has_point(p)
func draw_exchange(g:Node2D,camera:Vector2)->void:
 if not Rect2(camera-Vector2(90,90),g.VIEW+Vector2(180,180)).intersects(EXCHANGE.grow(100)):return
 var p=EXCHANGE.position-camera;var night=g.town_life.calendar.night_amount();var A=preload("res://scripts/business_district/art.gd")
 preload("res://scripts/town_props240.gd").exchange(g,camera,night)
 g.draw_arc(EXCHANGE_DOOR-camera,25,0,TAU,24,Color("#e0c283"),1.5,true)
 A.ink(g,p+Vector2(25,198),"ORE • GEMS • TRADE",13,Color("#d9cc9d"))
