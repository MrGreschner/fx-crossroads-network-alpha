extends Control
var variant=0
var muted=false
var time=0.0
var tick=0.0
func _ready()->void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(dt:float)->void:
 if muted or not is_visible_in_tree():return
 time+=dt;tick+=dt
 if tick>=1.0/12:tick=0;queue_redraw()
func _draw()->void:
 var image=preload("res://scripts/town_portal247.gd").texture(variant,time,muted)
 var dimensions=Vector2(144,184)*minf(size.x/144,size.y/184)
 draw_texture_rect(image,Rect2((size-dimensions)*.5,dimensions),false,Color("#8d9c9e") if muted else Color.WHITE)
