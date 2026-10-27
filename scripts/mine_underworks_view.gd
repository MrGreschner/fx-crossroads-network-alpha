extends Control
const Art=preload("res://scripts/cast_art232.gd")
var mine:RefCounted
var clock=0.0
var timer=0.0
func _ready()->void:texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(delta:float)->void:
 if not is_visible_in_tree():return
 clock+=delta;timer+=delta
 if timer>.067:timer=0;queue_redraw()
func _draw()->void:
 var scale_factor=minf(size.x/980,size.y/300);draw_set_transform(Vector2((size.x-980*scale_factor)*.5,0),0,Vector2.ONE*scale_factor)
 draw_rect(Rect2(0,0,980,290),Color("#182632"))
 for n in 24:
  var p=Vector2(18+fmod(n*137,940),20+fmod(n*61,180));draw_rect(Rect2(p,Vector2(24,5)),Color("#2a3c49"))
 for y in [223,238]:draw_line(Vector2(30,y),Vector2(950,y),Color("#879ea6"),3)
 for n in 40:draw_line(Vector2(30+n*24,222),Vector2(30+n*24,241),Color("#766650"),3)
 var ids=["rail_depot","refuge","sorter","enginehouse"];var titles=["RAIL DEPOT","DEEPCREW REFUGE","SORTING HALL","ENGINEHOUSE"]
 for n in 4:
  var id=str(ids[n]);var service=["relay","habitat","sorter","core"][n];var spec:Dictionary=mine.CATALOG.data().services[service];var live=int(mine.state().levels.get(service,0))>0;var p=Vector2(30+n*240,50);var ink=Color("#c1ac86") if live else Color("#52636d")
  Art.draw_prop(self,id,Rect2(p+Vector2(-6,0),Vector2(202,170)),Color.WHITE if live else Color(.34,.4,.44,.7))
  if live:
   var at=p+Vector2(50+sin(clock*.6+n)*24,174);Art.draw(self,"miner",at,1 if int(clock*4+n)%2==0 else 2,34)
   if id=="enginehouse":
    for j in 2:draw_circle(p+Vector2(25+sin(clock+j)*5,-3-fposmod(clock*9+j*11,25)),4,Color(.7,.8,.85,.13))
  draw_rect(Rect2(p+Vector2(-6,-28),Vector2(202,26)),Color("#182632"));draw_string(ThemeDB.fallback_font,p+Vector2(5,-8),str(titles[n]),HORIZONTAL_ALIGNMENT_LEFT,-1,16,ink)
  draw_string(ThemeDB.fallback_font,p+Vector2(25,203),"LEVEL "+str(mine.state().levels.get(service,0)) if live else "SHAFT "+str(spec.depth),HORIZONTAL_ALIGNMENT_LEFT,-1,15,ink)
 var cart=Vector2(35+fposmod(clock*48,890),238);Art.draw_prop(self,"cart",Rect2(cart-Vector2(21,29),Vector2(42,29)))
 draw_set_transform(Vector2.ZERO)
