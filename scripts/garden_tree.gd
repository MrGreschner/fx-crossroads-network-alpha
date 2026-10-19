extends Control
signal picked(id:String)
var gardening:RefCounted
func setup(owner:RefCounted)->void:
 gardening=owner;custom_minimum_size=Vector2(3220,1800);mouse_filter=Control.MOUSE_FILTER_PASS
 for id in gardening.perks():
  var p=gardening.perks()[id];var button=Button.new();button.position=Vector2(p.position[0],p.position[1])-Vector2(88,34);button.size=Vector2(176,68);button.text=str(p.name)+"\nLv %d • 1 point" % int(p.level);button.add_theme_font_size_override("font_size",15)
  button.add_theme_stylebox_override("normal",preload("res://scripts/studio_ui.gd").box("#45684c" if gardening.state().perks.has(id) else "#1a363b","#e4c17c" if gardening.state().perks.has(id) else "#5f938c",10,2));button.tooltip_text=str(p.text);add_child(button);button.pressed.connect(func():picked.emit(str(id)))
func _draw()->void:
 if gardening==null:return
 for id in gardening.perks():
  var spec=gardening.perks()[id];var b=Vector2(spec.position[0],spec.position[1])
  for parent in spec.requires:
   var a=Vector2(gardening.perks()[parent].position[0],gardening.perks()[parent].position[1]);var middle=(a.y+b.y)*.5
   draw_polyline(PackedVector2Array([a,a+Vector2(0,35),Vector2(a.x,middle),Vector2(b.x,middle),b-Vector2(0,35)]),Color("#b5a47a") if gardening.state().perks.has(id) else Color("#4c7165"),4,true)
 # Leaf silhouettes branch off the main limbs; they are decoration, not hidden nodes.
 for x in [500,1580,2660]:
  for side in [-1,1]:
   var at=Vector2(x+side*80,735);draw_colored_polygon(PackedVector2Array([at,at+Vector2(side*26,-22),at+Vector2(side*34,-7),at+Vector2(side*16,2)]),Color("#557f66"))
