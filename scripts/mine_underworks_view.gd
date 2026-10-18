extends Control
var mine:RefCounted
var clock=0.0
var timer=0.0
func _process(delta:float)->void:
 if not is_visible_in_tree():return
 clock+=delta;timer+=delta
 if timer>.067:timer=0;queue_redraw()
func _draw()->void:
 var scale_factor=minf(size.x/980,size.y/300);draw_set_transform(Vector2((size.x-980*scale_factor)*.5,0),0,Vector2.ONE*scale_factor)
 draw_rect(Rect2(0,0,980,290),Color("#182632"))
 for n in 24:
  var p=Vector2(18+fmod(n*137,940),20+fmod(n*61,180));draw_line(p,p+Vector2(16,-8),Color("#38495b"),3)
 for y in [223,238]:draw_line(Vector2(30,y),Vector2(950,y),Color("#879ea6"),3)
 for n in 40:draw_line(Vector2(30+n*24,222),Vector2(30+n*24,241),Color("#766650"),3)
 for n in 4:
  var id=["relay","habitat","sorter","core"][n];var spec=mine.CATALOG.data().services[id];var live=int(mine.state().levels.get(id,0))>0;var p=Vector2(38+n*238,70);var ink=Color("#8dbfc0") if live else Color("#54616b")
  draw_rect(Rect2(p,Vector2(190,140)),Color("#2d4855") if live else Color("#26333e"));draw_rect(Rect2(p+Vector2(-7,-9),Vector2(204,19)),ink);draw_rect(Rect2(p+Vector2(74,62),Vector2(44,78)),Color("#162632"))
  for x in [20,134]:draw_rect(Rect2(p+Vector2(x,30),Vector2(35,35)),Color("#e4cd87") if live else Color("#3a4753"))
  if id=="relay":
   for x in [25,164]:
    draw_line(p+Vector2(x,-8),p+Vector2(x,-37),ink,4);draw_circle(p+Vector2(x,-37),5,Color("#e2c586") if live else ink)
   draw_line(p+Vector2(25,-30),p+Vector2(164,-30),ink,2)
   for y in [83,97]:draw_line(p+Vector2(12,y),p+Vector2(61,y),ink,2)
   for x in range(15,60,9):draw_line(p+Vector2(x,82),p+Vector2(x,99),ink,2)
  elif id=="habitat":
   draw_rect(Rect2(p+Vector2(62,-8),Vector2(64,18)),Color("#bd9974") if live else ink)
   for side in [12,128]:
    for y in [84,107]:
     draw_rect(Rect2(p+Vector2(side,y),Vector2(48,13)),Color("#89aa9b") if live else ink);draw_circle(p+Vector2(side+7,y+5),4,Color("#d1c3a3") if live else ink)
  elif id=="sorter":
   for j in 3:
    var q=p+Vector2(30+j*65,105)
    draw_colored_polygon(PackedVector2Array([q-Vector2(0,20+j*3),q+Vector2(10,0),q+Vector2(0,13),q-Vector2(10,0)]),Color("#a5c4e3") if live else ink)
   draw_rect(Rect2(p+Vector2(10,123),Vector2(170,10)),Color("#172d37"))
   for j in 10:draw_line(p+Vector2(12+j*17,127),p+Vector2(16+j*17,127),ink,2)
  elif id=="core":
   for x in [15,155]:draw_rect(Rect2(p+Vector2(x,-37),Vector2(20,37)),Color("#697784") if live else ink)
   var center=p+Vector2(95,48);draw_arc(center,23,0,TAU,24,ink,5)
   for j in 8:
    var dir=Vector2.from_angle(clock*.4+j*TAU/8);draw_line(center+dir*22,center+dir*30,ink,5)
   draw_circle(center,9,Color("#d9b780") if live else ink)
   if live:
    for j in 3:draw_circle(p+Vector2(25+sin(clock+j)*5,-38-fposmod(clock*9+j*11,28)),5,Color(.7,.8,.85,.16))
  if live:
   draw_circle(p+Vector2(95,12),9,Color("#e6cf8a"));draw_circle(p+Vector2(95,12),21,Color(1,.85,.5,.08))
   var ram=preload("res://assets/ram_walk1.png");var at=p+Vector2(50+sin(clock*.6+n)*24,134);draw_texture_rect(ram,Rect2(at-Vector2(14,34),Vector2(28,34)),false)
  draw_rect(Rect2(p+Vector2(-6,-45),Vector2(202,29)),Color("#182632"))
  draw_string(ThemeDB.fallback_font,p+Vector2(5,-23),["RAIL DEPOT","DEEPCREW REFUGE","SORTING HALL","ENGINEHOUSE"][n],HORIZONTAL_ALIGNMENT_LEFT,-1,17,ink)
  draw_string(ThemeDB.fallback_font,p+Vector2(25,193),"LEVEL "+str(mine.state().levels.get(id,0)) if live else "SHAFT "+str(spec.depth),HORIZONTAL_ALIGNMENT_LEFT,-1,15,ink)
 var cart=Vector2(35+fposmod(clock*48,890),220);draw_rect(Rect2(cart-Vector2(18,16),Vector2(36,18)),Color("#89aeb4"))
 for x in [-12,12]:draw_circle(cart+Vector2(x,7),5,Color("#202c36"))
 draw_set_transform(Vector2.ZERO)
