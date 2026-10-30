extends RefCounted
const RIVER=Rect2(2280,-560,160,3460)
const BRIDGE=Rect2(2250,1090,220,130)
const HOME_BRIDGE=Rect2(2250,2025,220,110)
const POST=Vector2(550,1490)
const GUIDE=Vector2(290,400)
const FOREST=Rect2(2490,940,650,780)
const CAMP_CLEARING=Rect2(2760,1330,300,230)
var forest_trees:Array[Vector2]=[]
func _init()->void:
 for y in range(1000,1670,95):
  for x in range(2500,3130,90):
   var point:=Vector2(x+sin(y*.08+x)*28,y+cos(x*.04)*22)
   if Rect2(2460,1040,680,275).has_point(point):continue
   if Rect2(2500,900,150,220).has_point(point):continue
   if CAMP_CLEARING.grow(50).has_point(point):continue
   forest_trees.append(point)
 forest_trees=forest_trees.filter(func(p:Vector2):return p.distance_to(Vector2(2495,1340))>115 and not preload("res://scripts/town_neighborhood.gd").reserved(p))
func blocked(p:Vector2)->bool:
 if preload("res://scripts/town_refresh46.gd").blocked(p):return true
 if preload("res://scripts/marina_life.gd").blocked(p):return true
 if preload("res://scripts/town_marina.gd").blocked(p):return true
 for row in 3:
  for col in 2:
   if Rect2(Vector2(805 if col==0 else 962,1840+row*85),Vector2(50 if col==0 else 90,42)).grow(5).has_point(p):return true
 if RIVER.has_point(p) and not BRIDGE.has_point(p) and not HOME_BRIDGE.has_point(p):return true
 if Rect2(-1370,560,120,740).has_point(p) and not Rect2(-1310,1025,160,95).has_point(p):return true
 if FOREST.grow(30).has_point(p):
  for tree in forest_trees:
   if p.distance_squared_to(tree)<625:return true
 return false
func draw_ground_source(c:Node2D,camera:Vector2)->void:
 var visible:=Rect2(camera-Vector2(100,150),c.VIEW+Vector2(200,300))
 if visible.intersects(FOREST):
  c.draw_rect(Rect2(FOREST.position-camera,FOREST.size),Color("#526d50"))
  for n in 25:
   var stone:=Vector2(2510+posmod(n*73,600),950+posmod(n*131,740))-camera
   c.draw_circle(stone,2+float(n%3),Color("#81956b"))
  var trail:=PackedVector2Array([Vector2(2450,1150)-camera,Vector2(2650,1150)-camera,Vector2(2780,1180)-camera,Vector2(2940,1160)-camera,Vector2(3120,1160)-camera])
  preload("res://scripts/commerce_town.gd").path(c,trail)
  var camp_trail:=PackedVector2Array([Vector2(2780,1180)-camera,Vector2(2790,1300)-camera,Vector2(2850,1390)-camera])
  preload("res://scripts/commerce_town.gd").path(c,camp_trail)
  c.draw_circle(Vector2(2880,1450)-camera,128,Color("#819069"));c.draw_circle(Vector2(2880,1450)-camera,92,Color("#b0a17b"))
 # A single physical river exists before the watermill project is earned.
 if visible.intersects(RIVER.grow(20)):
  for x in [2268,2440]:c.draw_rect(Rect2(Vector2(x,-560)-camera,Vector2(12,RIVER.size.y)),Color("#8b9a7c"))
 if visible.intersects(Rect2(2200,250,950,1950)):
  for bridge in [BRIDGE,HOME_BRIDGE]:
   if not visible.intersects(bridge.grow(45)):continue
   c.draw_rect(Rect2(bridge.position-camera,bridge.size),Color("#b79b6f"))
   for x in range(int(bridge.position.x),int(bridge.end.x),22):c.draw_line(Vector2(x,bridge.position.y)-camera,Vector2(x,bridge.end.y)-camera,Color("#77634d"),2)
   for y in [bridge.position.y,bridge.end.y]:
    c.draw_line(Vector2(bridge.position.x,y)-camera,Vector2(bridge.end.x,y)-camera,Color("#e2c995"),6)
    for x in range(int(bridge.position.x),int(bridge.end.x)+1,44):c.draw_line(Vector2(x,y)-camera,Vector2(x,y-24)-camera,Color("#745d46"),5)
  var chime_path:=PackedVector2Array([Vector2(2590,1150)-camera,Vector2(2590,825)-camera,Vector2(2800,825)-camera,Vector2(2800,655)-camera])
  preload("res://scripts/commerce_town.gd").path(c,chime_path)
  draw_east_details(c,camera)
 # Western civic district: a clear plaza and individual doorstep branches.
 if visible.intersects(Rect2(-800,420,1400,1780)):
  for n in 9:
   var p:=Vector2(-290+n*85,1798)-camera
   c.draw_circle(p,4,Color("#99b977"));c.draw_circle(p+Vector2(6,-3),3,Color("#e0c997"))
 # Continuous western massif; the cave mouths sit on its accessible eastern apron.
 preload("res://scripts/town_refresh46.gd").cliffs(c,camera)
 # A compact communal garden fits between the southern homes, leaving the central street clear.
 if visible.intersects(Rect2(800,1780,285,350)):
  for row in 3:
   for col in 2:
    var world=Vector2(805 if col==0 else 962,1840+row*85)
    var size=Vector2(50 if col==0 else 90,42);var p=world-camera
    c.draw_rect(Rect2(p,size),Color("#70543d"));c.draw_rect(Rect2(p,size),Color("#bba378"),false,3)
    for n in (2 if col==0 else 4):
     var plant=p+Vector2(13+n*19,27);c.draw_line(plant,plant-Vector2(0,16),Color("#83b574"),3);c.draw_circle(plant-Vector2(0,18),5,Color("#deb171") if row==1 else Color("#9ac084"))
  for x in [800,1080]:
   c.draw_line(Vector2(x,1790)-camera,Vector2(x,2110)-camera,Color("#a99068"),4)
   for y in range(1790,2111,64):c.draw_line(Vector2(x-10,y)-camera,Vector2(x+10,y)-camera,Color("#7f684c"),5)
static func river_surface_visible(point:Vector2)->bool:
 # Decks are already baked into the ground layer; live water must stay beneath them.
 return not BRIDGE.grow(4).has_point(point) and not HOME_BRIDGE.grow(4).has_point(point)
func draw_ground(c:Node2D,camera:Vector2)->void:
 # The existing northern approach belongs below the gate artwork, never across its roof.
 if Rect2(camera,c.VIEW).grow(50).intersects(Rect2(850,-210,100,400)):
  c.draw_line(Vector2(900,-210)-camera,Vector2(900,190)-camera,Color("#9b916d"),100)
 preload("res://scripts/town_art39.gd").draw(c,"chapter_ground",camera)
 preload("res://scripts/marina_art250.gd").shore(c,camera)
 preload("res://scripts/town_nature243.gd").garden(c,camera);preload("res://scripts/town_nature243.gd").river_reeds(c,camera)
 var t:=Time.get_ticks_msec()/1000.0
 var visible:=Rect2(camera-Vector2(100,150),c.VIEW+Vector2(200,300))
 if visible.intersects(Rect2(800,1780,285,350)):
  var phase=fposmod(t*.006,1);var travel=phase*2 if phase<.5 else 2-phase*2
  var farmer=Vector2(1030,1890+travel*200)-camera
  c.draw_circle(farmer+Vector2(0,1),19,Color(0,0,0,.18))
  preload("res://scripts/town_cast230.gd").draw(c,"ox_farmer",farmer,t,true)
 for spot in [Vector2(2540,980),Vector2(2850,1080)]:
  if visible.has_point(spot):preload("res://scripts/town_calendar.gd").draw_lantern(c,spot-camera,c.town_life.calendar.night_amount())
func draw_pads(c:Node2D,camera:Vector2)->void:
 var visible:=Rect2(camera-Vector2(100,150),c.VIEW+Vector2(200,300))
 if visible.intersects(Rect2(600,-500,600,720)):
  var battle:=Vector2(900,-250)-camera;var clock:=Time.get_ticks_msec()/1000.0
  c.draw_rect(Rect2(Vector2(650,-450)-camera,Vector2(500,420)),Color("#59685a"))
  for x in [-92,92]:
   c.draw_line(battle+Vector2(x,-52),battle+Vector2(x,35),Color("#8f7760"),5)
   c.draw_colored_polygon(PackedVector2Array([battle+Vector2(x,-52),battle+Vector2(x+25,-42),battle+Vector2(x,-28)]),Color("#6db8ce") if x<0 else Color("#cd8773"))

  for n in 6:
   var p:=Vector2(680+(n%2)*440,-380+int(n/2)*100)-camera
   c.draw_circle(p,27,Color("#3d4741"));c.draw_circle(p,17,Color("#292e2d"))
  for n in 4:
   var p:=Vector2(750+n*100,-380)-camera;c.draw_line(p-Vector2(15,15),p+Vector2(15,15),Color("#817c69"),6);c.draw_line(p+Vector2(-15,15),p+Vector2(15,-15),Color("#817c69"),6)
  c.draw_circle(battle,32,Color(.36,.8,.85,.22+.08*sin(clock*3)))
  c.draw_arc(battle,35,0,TAU,32,Color("#a4e9de"),3)
  c.draw_string(ThemeDB.fallback_font,battle+Vector2(-105,52),"BATTLEGROUNDS • E",HORIZONTAL_ALIGNMENT_CENTER,210,16,Color("#ffe6a3"))
 for entry in [[Vector2(600,570),"CHARACTER HALL"],[Vector2(1290,650),"SUPPLY VENDOR"],[Vector2(260,1165),"GLADIATOR ARENA"]]:
  if not visible.has_point(entry[0]):continue
  var p:Vector2=entry[0]-camera;var near:bool=c.position_in_world.distance_to(entry[0])<95
  c.draw_rect(Rect2(p-Vector2(57,24),Vector2(114,48)),Color(.72,.88,.74,.27 if near else .08))
  c.draw_rect(Rect2(p-Vector2(57,24),Vector2(114,48)),Color("#e8d49e") if near else Color(.7,.8,.69,.35),false,2)
  if near:c.draw_string(ThemeDB.fallback_font,p+Vector2(-38,7),"E • ENTER",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#fff2c7"))
func draw_guide(c:Node2D,camera:Vector2)->void:
 c.training_yard.draw_outpost(c,camera)
 var p:Vector2=GUIDE-camera;c.town_upgrade.npc(c,p,Color("#63879a"),"ram")

func draw_east_details(c:Node2D,camera:Vector2)->void:
 if not Rect2(camera,c.VIEW).grow(170).intersects(Rect2(2200,300,900,1840)):return
 # Fork plaza: east continues into the woods; the narrower branch serves the bell house.
 var plaza:=Vector2(2590,1150)-camera
 c.draw_circle(plaza,53,Color("#b6a27b"))
 for n in 7:
  var p:=plaza+Vector2(-42+n*14,-4);c.draw_line(p,p+Vector2(0,10),Color("#c7b58b"),2)
 for n in 14:
  var p:=Vector2(2620+n*27,1080)-camera
  c.draw_circle(p,4+float(n%2),Color("#9d967c"))
  c.draw_circle(p+Vector2(0,152),4,Color("#9d967c"))
 for n in 11:
  var p:=Vector2(2590+sin(n*2)*9,860+n*23)-camera;c.draw_circle(p,4,Color("#c7b58b"));c.draw_line(p+Vector2(-20,2),p+Vector2(-13,3),Color("#a1906d"),2)
 for n in 6:
  var p:=Vector2(2640+n*26,825+sin(n)*5)-camera;c.draw_circle(p,4,Color("#c7b58b"))
 # Reeds and small stones hug the banks without spilling across the crossing.
 for y in range(310,2140,145):
  if y>1020 and y<1290:continue
  for x in [2250,2470]:
   var p:=Vector2(x,y)-camera
   c.draw_circle(p+Vector2(0,5),8,Color("#929e86"))
   for n in 3:c.draw_line(p+Vector2(n*5-5,0),p+Vector2(n*8-8,-15-n*3),Color("#9cbb86"),2)
 var pier:=Vector2(2261,190)-camera
 c.draw_rect(Rect2(pier-Vector2(13,44),Vector2(26,66)),Color("#7c8879"))
 c.draw_rect(Rect2(pier-Vector2(17,48),Vector2(34,10)),Color("#bbc1a1"))
 for y in [-32,-15,2]:c.draw_line(pier+Vector2(-11,y),pier+Vector2(11,y),Color("#acb096"),2)
 # Trail-side lanterns mark the two destinations without obstructing either lane.
 for spot in [Vector2(2510,1010)]:
  var p:Vector2=spot-camera;c.draw_rect(Rect2(p,Vector2(52,10)),Color("#a28662"));c.draw_line(p-Vector2(0,8),p+Vector2(52,-8),Color("#ba9e75"),4)
  for x in [7,45]:c.draw_line(p+Vector2(x,10),p+Vector2(x,19),Color("#6b6150"),3)
func draw_forest(c:Node2D,camera:Vector2)->void:
 var visible:=Rect2(camera-Vector2(80,160),c.VIEW+Vector2(160,320))
 if not visible.intersects(FOREST):return
 for point in forest_trees:
  if visible.has_point(point):c.draw_sprite("tree",point-Vector2(55,115),Vector2(110,145))
 var p:=Vector2(2940,1160)-camera;var clock:=Time.get_ticks_msec()/1000.0
 c.draw_circle(p,28,Color(.58,.8,.55,.08+.03*sin(clock*2)))
 c.draw_arc(p,30,.15,TAU-.15,32,Color(.69,.85,.57,.48),2,true)
 # Labels live beside the route, with no canopy, seat or fire under their lettering.
 var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
 c.draw_string(font,Vector2(2760,1090)-camera,"WAYFARER WOODS",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#f1ddb0"))
 c.draw_string(font,Vector2(2960,1260)-camera,"QUESTS · E",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#f1ddb0"))
