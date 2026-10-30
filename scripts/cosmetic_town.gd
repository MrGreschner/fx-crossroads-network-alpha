extends RefCounted
const WALL=Rect2(510,950,180,155)
const ENTRY=Vector2(600,1155)
var texture:Texture2D=preload("res://scripts/town_shops242.gd").texture("atelier")
var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
func blocked(p:Vector2)->bool:return WALL.grow(5).has_point(p)
func interact(g:Node)->bool:
 if g.position_in_world.distance_to(ENTRY)>80:return false
 g.hint="E • Gleam Atelier • cosmetics and titles"
 if Input.is_action_just_pressed("interact"):g.legacy.cosmetics.open_picker()
 return true
func draw_on(c:Node2D,camera:Vector2)->void:
 if not Rect2(camera,c.VIEW).grow(150).intersects(WALL):return
 var p=WALL.position-camera
 preload("res://scripts/town_shops242.gd").draw(c,"atelier",camera)
 c.draw_string(font,ENTRY-camera+Vector2(-74,14),"GLEAM ATELIER",HORIZONTAL_ALIGNMENT_CENTER,148,15,Color("#eed79f"))
 var t=Time.get_ticks_msec()*.001
 for n in 3:
  var q=p+Vector2(35+n*65,87+sin(t*1.4+n)*4);c.draw_arc(q,8,t+n,t+n+PI,12,Color("#d5c0ed"),1.5,true);c.draw_circle(q+Vector2(0,-12),2,Color("#f0d7a3"))
