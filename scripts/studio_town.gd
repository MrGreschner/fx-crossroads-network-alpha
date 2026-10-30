extends RefCounted
## A six-lab campus, with a central entrance and clear reserved lot.
const ENTRY=Vector2(-530,1375)
const WALL=Rect2(-790,1045,520,285)
var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
func blocked(point:Vector2)->bool:return WALL.grow(12).has_point(point)
func interact(g:Node)->bool:
 if g.position_in_world.distance_to(ENTRY)>80:return false
 g.hint="E • Crossroads Studio • six labs • create, test and share"
 if Input.is_action_just_pressed("interact"):g.hero_workshop.open()
 return true
func draw_structure_source(g:Node2D,camera:Vector2)->void:
 preload("res://scripts/town_landmarks241.gd").draw(g,"studio",camera)

func draw_on(g:Node2D,camera:Vector2)->void:
 if not Rect2(camera,g.VIEW).grow(150).intersects(WALL.grow(100)):return
 preload("res://scripts/town_art39.gd").draw(g,"studio",camera)
 var entry=ENTRY-camera;g.draw_rect(Rect2(entry-Vector2(52,20),Vector2(104,40)),Color(.5,.85,.9,.16))
 if g.position_in_world.distance_to(ENTRY)<80:g.draw_arc(entry,32,0,TAU,24,Color("#ffe39e"),2)
