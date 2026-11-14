extends RefCounted
## Existing walk-out exit, with Training Grounds material artwork.
static func reached(position:Vector2,gate:Vector2)->bool:
 return position.x<=42.0 and absf(position.y-gate.y)<=65.0
static func draw(c:CanvasItem,p:Vector2)->void:
 preload("res://scripts/training_environment303.gd").exit_art(c,p)
