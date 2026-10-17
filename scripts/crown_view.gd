extends Control
var rank=0
var clock=0.0
func _ready()->void:
 custom_minimum_size=Vector2(116,124);mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta:float)->void:
 if is_visible_in_tree():clock+=delta;queue_redraw()
func _draw()->void:
 draw_circle(Vector2(58,60),50,Color("#16313e"))
 draw_set_transform(Vector2(58,98),0,Vector2(1.25,1.25))
 preload("res://scripts/rolling_crowns.gd").draw_on(self,Vector2.ZERO,clock,rank)
 draw_set_transform(Vector2.ZERO)
 if rank==0:draw_arc(Vector2(58,45),18,0,TAU,32,Color("#577780"),2,true)
