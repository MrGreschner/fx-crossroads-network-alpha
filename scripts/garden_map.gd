extends Control
signal picked(id:String)
var gardening:RefCounted
var zoom:float=.2
var pan=Vector2.ZERO
var selected=""
var icons:Dictionary={}
var dragging=false
var moved=false
var down=Vector2.ZERO
const WORLD=Vector2(4500,2920)
func setup(owner:RefCounted)->void:
 gardening=owner;clip_contents=true;mouse_filter=Control.MOUSE_FILTER_STOP
 for id in gardening.perks():icons[id]=preload("res://scripts/source_art.gd").texture("res://assets/garden_badges/"+id+".svg")
 resized.connect(overview);call_deferred("overview")
func overview()->void:
 zoom=clampf(minf(size.x/WORLD.x,size.y/WORLD.y)*.96,.1,1.8);pan=(size-WORLD*zoom)*.5;queue_redraw()
func zoom_at(factor:float,at:Vector2)->void:
 var before=(at-pan)/zoom;zoom=clampf(zoom*factor,.1,1.8);pan=at-before*zoom;queue_redraw()
func _gui_input(event:InputEvent)->void:
 if event is InputEventMouseButton:
  if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:zoom_at(1.18 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1/1.18,event.position);accept_event()
  if event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_MIDDLE]:
   if event.pressed:dragging=true;moved=false;down=event.position
   else:
    if dragging and not moved and event.button_index==MOUSE_BUTTON_LEFT:pick(event.position)
    dragging=false
   accept_event()
 elif event is InputEventMouseMotion and dragging:
  if event.position.distance_to(down)>4:moved=true
  if moved:pan+=event.relative;queue_redraw()
  accept_event()
 elif event is InputEventScreenDrag:pan+=event.relative;queue_redraw();accept_event()
 elif event is InputEventMagnifyGesture:zoom_at(event.factor,event.position);accept_event()
func pick(at:Vector2)->void:
 var world=(at-pan)/zoom
 for id in gardening.perks():
  var p=gardening.perks()[id].position
  if world.distance_to(Vector2(p[0],p[1]))<48:selected=id;picked.emit(id);queue_redraw();return
func point(id:String)->Vector2:
 var p=gardening.perks()[id].position;return Vector2(p[0],p[1])*zoom+pan
func _draw()->void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("#102b31"));draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color("#658f88"),false,2)
 if gardening==null:return
 var font=ThemeDB.fallback_font
 for id in gardening.perks():
  var p=gardening.perks()[id];var b=point(id)
  for parent in p.requires:
   var a=point(parent);var curve=Curve2D.new();var direction=(b-a).normalized();var reach=a.distance_to(b)*.42;curve.add_point(a,Vector2.ZERO,Vector2(direction.x*.5,-.75)*reach);curve.add_point(b,Vector2(-direction.x*.5,.5)*reach);draw_polyline(curve.tessellate(),Color("#b6a779") if gardening.state().perks.has(id) else Color("#69734f"),maxf(1.5,(18 if str(id).begins_with("root") else 12 if p.requires.size()==1 and str(p.requires[0]).begins_with("root") else 7)*zoom),true)
 for id in gardening.perks():
  var p=gardening.perks()[id];var at=point(id);var owned=gardening.state().perks.has(id);var radius=40*zoom;var color=Color("#e4c27c") if owned else Color("#91c799") if gardening.prerequisites(p,gardening.state().perks) and gardening.level()>=int(p.level) else Color("#698a91")
  draw_circle(at,radius,Color("#254849"));draw_arc(at,radius,0,TAU,24,color,maxf(1.5,4*zoom),true)
  if icons.get(id)!=null:draw_texture_rect(icons[id],Rect2(at-Vector2.ONE*radius*.78,Vector2.ONE*radius*1.56),false,Color.WHITE if owned else Color(.8,.86,.85))
  if id==selected:draw_arc(at,radius+5,0,TAU,24,Color("#fff0b2"),2,true)
  if zoom>=.38:
   var label_size=clampi(int(22*zoom),12,22);var text=str(p.name);var width=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,label_size).x+12;var box=Rect2(at+Vector2(-width*.5,radius+5),Vector2(width,label_size+9));draw_rect(box,Color("#102b31"));draw_string(font,box.position+Vector2(6,label_size+2),text,HORIZONTAL_ALIGNMENT_LEFT,-1,label_size,color)
 for item in [["CULTIVATION",1550,2200],["BOTANY",2420,1660],["STEWARDSHIP",3150,2220]]:
  var at=Vector2(item[1],item[2])*zoom+pan;draw_string(font,at-Vector2(56,0),item[0],HORIZONTAL_ALIGNMENT_CENTER,112,14,Color("#c6d5b8"))
