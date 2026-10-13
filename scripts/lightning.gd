extends RefCounted
## Shared jagged lightning visual, identical in solo and multiplayer.
static func draw_on(canvas: Node2D, start: Vector2, end: Vector2, colour: Color) -> void:
	var normal := (end-start).orthogonal().normalized()
	var points := PackedVector2Array([start])
	for n in range(1,7): points.append(start.lerp(end,n/7.0)+normal*(12 if n%2==0 else -12))
	points.append(end)
	canvas.draw_polyline(points,Color(colour,.35),9,true)
	canvas.draw_polyline(points,colour,4,true)
