extends RefCounted
## Bounded, culled facade accents; emissive details render after the ambient tint.
const TORCHES=[Vector2(-1205,1210),Vector2(-955,1210),Vector2(-948,430),Vector2(-612,430)]
const WINDOWS={
 "character_hall_v65":[Vector2(360,255),[Rect2(72,126,16,41),Rect2(283,126,16,41)]],
 "healer_shack":[Vector2(290,220),[Rect2(52,117,44,33),Rect2(212,117,25,33)]],
 "wayfinder_lodge":[Vector2(240,185),[Rect2(49,85,26,39),Rect2(172,85,20,39)]],
 "arena_hall":[Vector2(160,128),[Rect2(25,77,14,22),Rect2(121,77,14,22)]],
}
static func panes(g:Node2D)->Array:
 var result:Array=[]
 for landmark in g.town_art:
  var key=str(landmark.sprite)
  if not WINDOWS.has(key):continue
  var spec=WINDOWS[key];var scale:Vector2=landmark.size/spec[0];var origin:Vector2=landmark.pos-landmark.size*.5
  for rect in spec[1]:result.append(Rect2(origin+rect.position*scale,rect.size*scale))
 # Atelier display windows, academy studio and lodge windows follow their real facade coordinates.
 for rect in [Rect2(529,1018,39,37),Rect2(630,1018,39,37)]:result.append(rect)
 var studio=preload("res://scripts/studio_town.gd").WALL.position
 for y in [52,134]:
  for x in [28,110,374,456]:result.append(Rect2(studio+Vector2(x,y),Vector2(36,48)))
 for n in 3:result.append(Rect2(studio+Vector2(204+n*44,118),Vector2(24,42)))
 for x in [48,90,132,346,388,430]:result.append(Rect2(Vector2(-1030,215)+Vector2(x+2,169),Vector2(18,42)))
 # Squirrel Post and the aquarium welcome passing anglers after sunset.
 return result
static func light_sources(g:Node2D)->Array:
 var lights:Array=[]
 for landmark in g.town_art:
  if WINDOWS.has(str(landmark.sprite)) or str(landmark.sprite)=="pond_food_stand":
   lights.append({"at":landmark.pos+Vector2(0,landmark.size.y*.2),"radius":165.0,"strength":.95})
 for at in [Vector2(600,1035),Vector2(-820,1200),Vector2(-360,1200),Vector2(-780,425),Vector2(1290,560),Vector2(1150,1095),Vector2(550,1440),Vector2(2000,1880),Vector2(1375,1430),Vector2(2800,520)]:lights.append({"at":at,"radius":160.0,"strength":1.0})
 for at in [Vector2(550,1310),Vector2(790,1565)]:lights.append({"at":at,"radius":165.0,"strength":1.0})
 for at in TORCHES:lights.append({"at":at-Vector2(0,26),"radius":185.0,"strength":1.1})
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
 # The acorn itself casts light; the greenhouse uses one small front lantern.
 if night>.01:
  var acorn=Vector2(550,1310)-camera
  for n in range(3,0,-1):g.draw_circle(acorn,n*9,Color(1,.74,.35,night*.04))
  g.draw_arc(acorn,9,0,PI,16,Color(1,.84,.48,night),3,true)
 var lantern_at=Vector2(790,1620)
 if view.has_point(lantern_at):preload("res://scripts/town_calendar.gd").draw_lantern(g,lantern_at-camera,night)
 # Shop awnings carry their own small lantern strings, never more street poles.
 for shop in [[Vector2(1150,1040),138.0],[Vector2(1290,485),180.0]]:
  var at:Vector2=shop[0];var width:float=shop[1]
  if not view.has_point(at):continue
  var y:float=at.y-26 if width<150 else at.y-55
  g.draw_line(Vector2(at.x-width*.42,y)-camera,Vector2(at.x+width*.42,y)-camera,Color("#7d6b49"),1.5)
  for n in 5:
   var q=Vector2(at.x-width*.4+width*.2*n,y+5+sin(float(n)*PI/4)*3)-camera
   g.draw_line(q-Vector2(0,5),q,Color("#8c7752"),1)
   g.draw_circle(q,3.5,Color(1,.83,.47,.45+night*.55))
   if night>.1:g.draw_circle(q,11,Color(1,.70,.29,night*.08))
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
