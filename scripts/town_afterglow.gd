extends RefCounted
## Bounded, culled facade accents; emissive details render after the ambient tint.
const TORCHES=[Vector2(-1205,1210),Vector2(-955,1210),Vector2(-1105,430),Vector2(-955,430)]
const WINDOWS={
 "character_hall_v65":[Vector2(360,255),[Rect2(72,126,16,41),Rect2(283,126,16,41)]],
 "healer_shack":[Vector2(290,220),[Rect2(52,117,44,33),Rect2(212,117,25,33)]],
 "wayfinder_lodge":[Vector2(240,185),[Rect2(49,85,26,39),Rect2(172,85,20,39)]],
 "arena_hall":[Vector2(160,128),[Rect2(25,77,14,22),Rect2(121,77,14,22)]],
}
static func panes(g:Node2D)->Array:
 # V242 window masks exclude frames/mullions and are drawn after the ambient tint.
 return []
static func light_sources(g:Node2D)->Array:
 var lights:Array=[]
 for at in [Vector2(1245,1705),Vector2(1495,1705)]:lights.append({"at":at-Vector2(0,30),"radius":155.0,"strength":1.0})
 lights.append({"at":Vector2(1460,1860),"radius":125.0,"strength":.85})
 for at in TORCHES:lights.append({"at":at-Vector2(0,26),"radius":185.0,"strength":1.1})
 lights.append_array(preload("res://scripts/town_landmarks241.gd").light_sources())
 lights.append_array(preload("res://scripts/town_shops242.gd").light_sources(g))
 return lights
static func flame(g:Node2D,at:Vector2,t:float,night:float)->void:
 var p=at;g.draw_line(p+Vector2(-5,5),p+Vector2(5,5),Color("#52616a"),5)
 g.draw_line(p+Vector2(0,6),p+Vector2(5,22),Color("#66727a"),4)
 for n in 3:
  var sway=sin(t*5.3+n*2.1)*2;var h=12+sin(t*7+n)*3
  var points=PackedVector2Array([p+Vector2(-6+n*2,3),p+Vector2(-4+sway,-h*.5),p+Vector2(sway,-h-4+n*3),p+Vector2(5-n,2)])
  g.draw_colored_polygon(points,Color("#ff943c") if n==0 else Color("#ffd278") if n==1 else Color("#fff1b5"))
 if night>.05:
  for n in range(3,0,-1):g.draw_circle(p-Vector2(0,8),n*9,Color(1,.58,.19,night*.035))
static func draw_on(g:Node2D,camera:Vector2)->void:
 var night:float=g.town_life.calendar.night_amount();var t:float=g.town_life.clock;var view=Rect2(camera,g.VIEW).grow(80)
 if night>.01:
  for rect in panes(g):
   if not view.intersects(rect):continue
   var screen=Rect2(rect.position-camera,rect.size);var warm=Color(1,.76,.39,night*(.82+.03*sin(t*.7+rect.position.x)))
   g.draw_rect(screen,warm)
   g.draw_line(screen.position+Vector2(screen.size.x*.5,0),screen.position+Vector2(screen.size.x*.5,screen.size.y),Color(.38,.31,.21,night*.75),2)
   g.draw_line(screen.position+Vector2(0,screen.size.y*.48),screen.position+Vector2(screen.size.x,screen.size.y*.48),Color(.38,.31,.21,night*.65),2)
   g.draw_rect(screen.grow(3),Color(1,.75,.36,night*.06))
 preload("res://scripts/town_landmarks241.gd").draw_emission(g,camera,night)
 preload("res://scripts/town_shops242.gd").draw_emission(g,camera,night)
 preload("res://scripts/town_nature243.gd").draw_emission(g,camera,night)
 for at in [Vector2(1245,1705),Vector2(1495,1705)]:
  if view.has_point(at):preload("res://scripts/town_calendar.gd").draw_lantern(g,at-camera,night)
 var fountain=Vector2(1460,1880)
 if night>.01 and view.has_point(fountain):
  var p=fountain-camera;var glow=night*(.65+.2*sin(t*1.2))
  var rim=PackedVector2Array()
  for k in 33:rim.append(p+Vector2(cos(k*TAU/32)*32,2+sin(k*TAU/32)*13))
  g.draw_polyline(rim,Color(.4,.9,1,glow*.45),1.2,true)
  g.draw_circle(p-Vector2(0,48),7,Color(.6,.93,1,glow*.65))
  for n in 5:
   var a=t*.25+n*TAU/5;var star=p+Vector2(cos(a)*24,2+sin(a)*10)
   g.draw_line(star-Vector2(2,0),star+Vector2(2,0),Color(.9,1,1,glow),2)
 for at in TORCHES:
  if view.has_point(at):flame(g,at-camera,t+at.x,night)
 # Eyes open, blink, fade away, then reappear elsewhere INSIDE the dark tunnel.
 var center=Vector2(-1080,1186)-camera
 if view.has_point(Vector2(-1080,1186)):
  for n in 2:
   var cycle:float=floor((t+n*5.9)/9.7);var phase:float=fposmod(t+n*5.9,9.7)
   if phase>6.2:continue
   var pos=cave_eye_point(cycle,n)-camera
   var blink=1.0-smoothstep(.05,.14,absf(fposmod(phase,2.8)-1.4))
   var height:float=lerpf(2.0,.25,blink);var alpha:float=(.18+night*.78)*smoothstep(0,.7,phase)*(1-smoothstep(5.2,6.2,phase))
   for side in [-1,1]:
    var outline=PackedVector2Array();var eye=pos+Vector2(side*4.5,0)
    for k in 12:outline.append(eye+Vector2(cos(float(k)*TAU/12)*2,sin(float(k)*TAU/12)*height*2))
    g.draw_colored_polygon(outline,Color(.95,.76,.31,alpha))

static func cave_eye_point(cycle:float,index:int)->Vector2:
 return Vector2(-1080,1186)+Vector2(sin(cycle*2.37+index*3.1)*18,-3+sin(cycle*4.17+index)*6)
