extends RefCounted
const BREAD=Vector2(1360,1140)
static func draw_bakery(g:Node2D,camera:Vector2)->void:
 var p=BREAD-camera
 if not Rect2(Vector2.ZERO,g.VIEW).grow(160).has_point(p):return
 preload("res://scripts/town_shops242.gd").draw(g,"bakery",camera)
 g.draw_string(g.font,p+Vector2(-72,43),"FREE ADVENTURE BREAD",HORIZONTAL_ALIGNMENT_CENTER,144,11,Color("#f5dfa6"))
# Bounded geometry with a single aligned aperture and stone frame.
static func ellipse(g:Node2D,center:Vector2,radii:Vector2,color:Color)->void:
 var points=PackedVector2Array()
 for n in 64:points.append(center+Vector2(cos(float(n)*TAU/64)*radii.x,sin(float(n)*TAU/64)*radii.y))
 g.draw_colored_polygon(points,color)
static func draw_portal(g:Node2D,camera:Vector2)->void:
 preload("res://scripts/town_portal247.gd").world(g,camera)
