extends Control
signal picked(id:String)
var progress:RefCounted
var zoom:float=.2
var pan=Vector2.ZERO
var selected=""
var catalogue:Dictionary={}
const P=preload("res://scripts/fishing_progress.gd")
var dragging=false
var moved=false
var down=Vector2.ZERO
const WORLD=Vector2(3500,2670)
func setup(owner:RefCounted)->void:
 progress=owner
 for bi in P.BRANCHES.size():
  var branch=P.BRANCHES[bi]
  for n in branch.nodes.size():
   var id=branch.nodes[n];var p=P.TALENTS[id].duplicate(true);p.icon=0 if bi==0 else 2 if bi==1 else 5 if bi==2 else 3 if bi==3 else 6 if bi==4 else 4;p.rune=bi*10+n;catalogue[id]=p
 clip_contents=true;mouse_filter=Control.MOUSE_FILTER_STOP
 resized.connect(overview);call_deferred("overview")
func perks()->Dictionary:return catalogue
func overview()->void:
 zoom=clampf(minf(size.x/WORLD.x,size.y/WORLD.y)*.96,.06,1.8);pan=(size-WORLD*zoom)*.5;queue_redraw()
func zoom_at(factor:float,at:Vector2)->void:
 var before=(at-pan)/zoom;zoom=clampf(zoom*factor,.06,1.8);pan=at-before*zoom;queue_redraw()
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
 for id in perks():
  var p=perks()[id].position
  if world.distance_to(Vector2(p[0],p[1]))<52:selected=id;picked.emit(id);queue_redraw();return
func point(id:String)->Vector2:
 var p=perks()[id].position;return Vector2(p[0],p[1])*zoom+pan
func _draw()->void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("#102b31"));draw_rect(Rect2(Vector2.ONE,size-Vector2.ONE*2),Color("#658f88"),false,2)
 if progress==null:return
 var font=ThemeDB.fallback_font
 # A shared root joins the six styles without costing a point.
 var root=Vector2(1750,2570)*zoom+pan
 for bi in P.BRANCHES.size():draw_line(root,Vector2(P.TALENTS[P.BRANCHES[bi].nodes[0]].position[0],P.TALENTS[P.BRANCHES[bi].nodes[0]].position[1])*zoom+pan,Color("#3f6a68"),maxf(1,5*zoom),true)
 draw_circle(root,36*zoom,Color("#b7a776"));draw_arc(root,42*zoom,0,TAU,24,Color("#e3cf91"),1.5,true)
 for id in perks():
  var p=perks()[id];var b=point(id)
  for parent in p.requires:
   var a=point(parent);var curve=Curve2D.new();curve.add_point(a,Vector2.ZERO,Vector2(0,(b.y-a.y)*.5));curve.add_point(b,Vector2(0,(a.y-b.y)*.5));draw_polyline(curve.tessellate(),Color("#b6a779") if progress.has(id) else Color("#4b7566"),maxf(1.5,9*zoom),true)
 for id in perks():
  var p=perks()[id];var at=point(id);var owned=progress.has(id);var radius=48*zoom;var color=Color("#e4c27c") if owned else Color("#91c799") if progress.learn_reason(id).is_empty() else Color("#596d76") if progress.excluded(id) else Color("#698a91")
  draw_circle(at,radius,Color("#254849"));draw_arc(at,radius,0,TAU,24,color,maxf(1.5,4*zoom),true)
  draw_badge(at,radius,p,color)
  if progress.excluded(id):draw_line(at-Vector2(radius*.65,radius*.65),at+Vector2(radius*.65,radius*.65),Color("#a47c78"),maxf(1.5,3*zoom),true)
  if id==selected:draw_arc(at,radius+5,0,TAU,24,Color("#fff0b2"),2,true)
  if zoom>=.38:
   var label_size=clampi(int(22*zoom),12,22);var text=str(p.name);var width=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,label_size).x+12;var box=Rect2(at+Vector2(-width*.5,radius+5),Vector2(width,label_size+9));draw_rect(box,Color("#102b31"));draw_string(font,box.position+Vector2(6,label_size+2),text,HORIZONTAL_ALIGNMENT_LEFT,-1,label_size,color)
 for bi in P.BRANCHES.size():
  var at=Vector2((400+bi*800)*.7,160)*zoom+pan;var width=clampf(550*zoom,80,140);var fs=clampi(int(75*zoom),10,14)
  draw_rect(Rect2(at-Vector2(width*.5+2,fs+2),Vector2(width+4,fs+7)),Color("#102b31"));draw_string(font,at-Vector2(width*.5,0),str(P.BRANCHES[bi].name).to_upper(),HORIZONTAL_ALIGNMENT_CENTER,width,fs,Color(P.BRANCHES[bi].color))
  var hint=["Choose 1 of 2","Choose 1 of 3","Choose 1 of 4","Discover & craft","Pack & trade","Release OR sell"][bi]
  draw_string(font,at+Vector2(-width*.5,fs+6),hint,HORIZONTAL_ALIGNMENT_CENTER,width,clampi(fs-2,10,12),Color("#afc6c8"))
func draw_badge(at:Vector2,radius:float,p:Dictionary,ink:Color)->void:
 var r=radius*.54;var kind=int(p.icon)
 match kind:
  0:draw_line(at+Vector2(0,-r),at+Vector2(0,r*.3),ink,maxf(1,3*zoom),true);draw_arc(at+Vector2(-r*.35,r*.3),r*.35,0,PI,12,ink,maxf(1,3*zoom),true)
  2:
   draw_arc(at,r,0,TAU,20,ink,maxf(1,2*zoom),true)
   for side in [-.5,0,.5]:draw_line(at+Vector2(side*r,-r*.8),at+Vector2(side*r,r*.8),ink,maxf(.7,zoom),true);draw_line(at+Vector2(-r*.8,side*r),at+Vector2(r*.8,side*r),ink,maxf(.7,zoom),true)
  5:draw_rect(Rect2(at-Vector2(r,r*.5),Vector2(r*2,r*1.4)),ink,false,maxf(1,2*zoom));draw_arc(at-Vector2(0,r*.5),r*.7,PI,TAU,14,ink,maxf(1,2*zoom),true)
  3:draw_arc(at,r,.2,PI-.2,16,ink,maxf(1,2*zoom),true);draw_arc(at,r,PI+.2,TAU-.2,16,ink,maxf(1,2*zoom),true);draw_circle(at,r*.3,ink)
  6:draw_rect(Rect2(at-Vector2(r*.7,r),Vector2(r*1.4,r*2)),ink,false,maxf(1,2*zoom));draw_line(at-Vector2(r*.4,0),at+Vector2(r*.4,0),ink,maxf(1,2*zoom),true)
  4:
   var points=PackedVector2Array()
   for n in 10:points.append(at+Vector2.from_angle(-PI*.5+n*PI/5)*(r if n%2==0 else r*.45))
   draw_colored_polygon(points,ink)
 for n in 6:
  if int(p.rune)&(1<<n):var a=n*TAU/6;draw_circle(at+Vector2.from_angle(a)*radius*.83,maxf(1,2*zoom),ink)
