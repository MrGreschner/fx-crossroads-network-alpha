extends RefCounted
const ELDER=Vector2(535,810)
const WILLOW=Vector2(220,1510)
const LIGHTS=[Vector2(-1164,726),Vector2(-1097,726),Vector2(-1150,742),Vector2(-1114,745),Vector2(-359,662),Vector2(0,662),Vector2(-304,628),Vector2(-58,628),Vector2(535,705)]
const TRACK=[Vector2(-1130,790),Vector2(-1090,830),Vector2(-570,830),Vector2(-570,740),Vector2(-360,740),Vector2(-360,700),Vector2(-341,700)]
static var rails:PackedVector2Array=PackedVector2Array()
static func route()->PackedVector2Array:
 if not rails.is_empty():return rails
 rails.append(TRACK[0])
 for n in range(1,TRACK.size()-1):
  var at:Vector2=TRACK[n];var before:Vector2=TRACK[n-1];var after:Vector2=TRACK[n+1];var radius=minf(26,minf(at.distance_to(before),at.distance_to(after))*.4)
  var a=at+(before-at).normalized()*radius;var b=at+(after-at).normalized()*radius
  rails.append(a)
  for k in range(1,9):
   var t=float(k)/8;rails.append(a.lerp(at,t).lerp(at.lerp(b,t),t))
 rails.append(TRACK[-1]);return rails
static func blocked(p:Vector2)->bool:return p.distance_to(ELDER)<23 or p.distance_to(WILLOW)<23
static func draw_tracks_source(g:Node2D,camera:Vector2)->void:
 var visible=Rect2(camera,g.VIEW).grow(45)
 var points=route()
 for n in range(1,points.size()):
  var a:Vector2=points[n-1];var b:Vector2=points[n]
  if not Rect2(a.min(b),a.max(b)-a.min(b)).grow(25).intersects(visible):continue
  var direction=(b-a).normalized();var side=direction.orthogonal()
  g.draw_line(a-camera,b-camera,Color("#797970"),30,true)
  if a.distance_to(b)>10:
   var count=maxi(1,ceili(a.distance_to(b)/17))
   for k in count:
    var point=a.lerp(b,(float(k)+.5)/count)-camera
    g.draw_line(point-side*17,point+side*17,Color("#695641"),5,true)
  elif n%4==0:
   var point=a.lerp(b,.5)-camera;g.draw_line(point-side*17,point+side*17,Color("#695641"),5,true)
  for sign in [-1,1]:
   g.draw_line(a+side*10-camera,b+side*10-camera,Color("#39454a"),4,true)
   g.draw_line(a+side*10-camera,b+side*10-camera,Color("#bac1ad"),1.5,true)
static func draw_trees(g:Node2D,camera:Vector2)->void:
 var visible=Rect2(camera,g.VIEW).grow(270);var t=g.town_life.clock
 for entry in [[ELDER,"res://assets/town_elder_starlace.svg",Vector2(225,250)],[WILLOW,"res://assets/town_willow_amber.svg",Vector2(185,225)]]:
  var at:Vector2=entry[0];var size:Vector2=entry[2]
  if not visible.has_point(at):continue
  var p=at-camera
  g.draw_texture_rect(preload("res://scripts/source_art.gd").texture(entry[1]),Rect2(p-Vector2(size.x*.5,size.y-15),size),false)
  if at!=ELDER:continue
  var night=g.town_life.calendar.night_amount()
  if night<.03:continue
  for n in 18:
   var angle=n*2.399;var radius=21+sqrt(float(n)/18)*58
   var leaf=p+Vector2(cos(angle)*radius,-143+sin(angle)*radius*.6)
   var pulse=night*(.4+.6*pow((sin(t*1.7+n*2.3)+1)*.5,3))
   var shade=Color("#84e5e0") if n%3 else Color("#b5a0ff")
   g.draw_circle(leaf,6,Color(shade,pulse*.11));g.draw_line(leaf-Vector2(2,0),leaf+Vector2(2,0),Color(shade,pulse*.9),2,true)
   if pulse>.8:g.draw_line(leaf-Vector2(0,3),leaf+Vector2(0,3),Color(shade,pulse*.75),1,true)

static func draw_tracks(g:Node2D,camera:Vector2)->void:
 preload("res://scripts/town_art39.gd").draw(g,"rails",camera)
