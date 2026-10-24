extends RefCounted
const OFFICE=Rect2(-720,280,280,170)
const OFFICE_DOOR=Vector2(-580,490)
const DOOR=Vector2(-180,775)
const WALL=Rect2(-350,530,340,195)
const YARD=Rect2(-530,490,735,305)
const STOCK=[Rect2(-505,574,120,105),Rect2(65,560,120,145)]
const CONSTRUCTION=Rect2(-290,1850,255,180)
const FENCE=Rect2(-1420,168,1425,35)
var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
func blocked(p:Vector2)->bool:
 for r in STOCK:
  if r.grow(6).has_point(p):return true
 return OFFICE.grow(8).has_point(p) or WALL.grow(8).has_point(p) or CONSTRUCTION.grow(8).has_point(p) or FENCE.grow(8).has_point(p)
func interact(g:Node)->bool:
 if g.position_in_world.distance_to(OFFICE_DOOR)<80:
  g.hint="E • Crossroads Market Office"
  if Input.is_action_just_pressed("interact"):
   g.presentation.window("MARKET OFFICE","market_office")
   g.presentation.label(g.presentation.content,"Reserved for future business services.",20)
   g.presentation.button(g.presentation.content,"Back to town",g.presentation.close)
  return true
 if g.position_in_world.distance_to(DOOR)>85:return false
 g.hint="E • Crossroads Market • business district"
 if Input.is_action_just_pressed("interact"):g.open_business_district()
 return true
static func path(g:Node2D,points:PackedVector2Array)->void:
 g.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
 var texture=g.art.get("path")
 for n in range(1,points.size()):
  var a=points[n-1];var b=points[n];var side=(b-a).normalized().orthogonal()*38
  var polygon=PackedVector2Array([a-side,b-side,b+side,a+side]);var uv=PackedVector2Array()
  for p in polygon:uv.append((p+g.camera)/64.0)
  if texture!=null:g.draw_polygon(polygon,PackedColorArray([Color.WHITE]),uv,texture)
  else:g.draw_colored_polygon(polygon,Color("#b6a074"))
func draw_on(g:Node2D,camera:Vector2)->void:
 var visible=Rect2(camera-Vector2(160,180),g.VIEW+Vector2(320,360))
 if visible.intersects(FENCE):
  for x in range(-1420,6,24):
   if x<camera.x-24 or x>camera.x+g.VIEW.x+24:continue
   var p=Vector2(x,190)-camera
   g.draw_rect(Rect2(p-Vector2(4,44),Vector2(8,52)),Color("#9e7953"));g.draw_colored_polygon(PackedVector2Array([p+Vector2(-4,-44),p+Vector2(0,-52),p+Vector2(4,-44)]),Color("#c2a078"))
   for y in [-30,-8]:g.draw_line(p+Vector2(-12,y),p+Vector2(12,y),Color("#c2a078"),4)
 if visible.intersects(OFFICE.grow(100)):draw_office(g,camera)
 if visible.intersects(YARD.grow(90)):draw_market(g,camera)
 if visible.intersects(CONSTRUCTION.grow(80)):
  var p=CONSTRUCTION.position-camera
  g.draw_rect(Rect2(p,CONSTRUCTION.size),Color("#8b856c"))
  for x in [0,80,170,255]:g.draw_line(p+Vector2(x,180),p+Vector2(x,-28),Color("#a48a61"),8)
  for y in [20,100,180]:g.draw_line(p+Vector2(-12,y),p+Vector2(267,y),Color("#bba278"),6)
  g.draw_line(p,p+Vector2(255,180),Color("#8e7755"),5);g.draw_line(p+Vector2(255,0),p+Vector2(0,180),Color("#8e7755"),5)
  for n in 5:g.draw_rect(Rect2(p+Vector2(15+n*39,145),Vector2(34,22)),Color("#c3ae88"))
  g.draw_rect(Rect2(p+Vector2(40,44),Vector2(175,47)),Color("#263f48"));g.draw_string(font,p+Vector2(52,64),"FUTURE DEVELOPMENT",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#e8cd88"));g.draw_string(font,p+Vector2(62,83),"UNDER CONSTRUCTION",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#cad7d0"))
  var crane=p+Vector2(300,170);g.draw_line(crane,crane-Vector2(0,240),Color("#c1a35e"),9);g.draw_line(crane-Vector2(0,240),crane-Vector2(110,240),Color("#c1a35e"),7);g.draw_line(crane-Vector2(80,240),crane-Vector2(80,190),Color("#6a7370"),2)

func crate(g:Node2D,p:Vector2,size:Vector2)->void:
 g.draw_rect(Rect2(p+Vector2(3,4),size),Color("#5e6250"))
 g.draw_rect(Rect2(p,size),Color("#ac8052"));g.draw_rect(Rect2(p,size),Color("#725436"),false,2)
 g.draw_line(p+Vector2(4,4),p+size-Vector2(4,4),Color("#d1ad74"),3)
 g.draw_line(p+Vector2(size.x-4,4),p+Vector2(4,size.y-4),Color("#d1ad74"),3)
func ram_worker(g:Node2D,p:Vector2,t:float,carrying:bool)->void:
 if not Rect2(Vector2.ZERO,g.VIEW).grow(65).has_point(p):return
 var bob=sin(t*6)*1.5
 worker_body(g,p+Vector2(0,bob),t,carrying)
func worker_body(g:Node2D,p:Vector2,t:float,carrying:bool)->void:
 g.draw_circle(p+Vector2(0,0),13,Color(.15,.23,.22,.2))
 for side in [-1,1]:
  var leg=p+Vector2(side*6,-3+sin(t*6+side)*3)
  g.draw_rect(Rect2(leg-Vector2(4,8),Vector2(8,12)),Color("#47565e"))
 g.draw_rect(Rect2(p-Vector2(12,30),Vector2(24,24)),Color("#719499"));g.draw_rect(Rect2(p-Vector2(8,27),Vector2(16,18)),Color("#b9aa7f"))
 var head=p-Vector2(0,40)
 g.draw_circle(head,12,Color("#e5dcc2"));g.draw_circle(head-Vector2(12,1),6,Color("#b7aa88"));g.draw_circle(head+Vector2(12,-1),6,Color("#b7aa88"))
 for side in [-1,1]:g.draw_circle(head+Vector2(side*4,-1),1.7,Color("#354b50"))
 g.draw_rect(Rect2(head+Vector2(-9,-15),Vector2(18,6)),Color("#536d79"));g.draw_circle(head+Vector2(0,5),3,Color("#c4b38d"))
 for side in [-1,1]:g.draw_line(p+Vector2(side*11,-26),p+Vector2(side*14,-17+sin(t*6+side)*3),Color("#c9c4ac"),5)
 if carrying:crate(g,p-Vector2(12,27),Vector2(24,19))
func draw_market(g:Node2D,camera:Vector2)->void:
 preload("res://scripts/town_art39.gd").draw(g,"merchants_night" if g.town_life.calendar.night_amount()>.1 else "merchants",camera)
 var t=Time.get_ticks_msec()*.001
 ram_worker(g,Vector2(-430+sin(t*.45)*25,715)-camera,t,true)
 ram_worker(g,Vector2(33+sin(t*.35)*22,751)-camera,t+1,false)
 ram_worker(g,Vector2(-275+sin(t*.3)*55,776)-camera,t+2,true)
 # A loading cart follows a short safe loop; no simulation entities or particles.
 var cart=Vector2(-485+fposmod(t*12,80),758)-camera
 g.draw_rect(Rect2(cart-Vector2(10,21),Vector2(54,27)),Color("#796448"));crate(g,cart-Vector2(4,32),Vector2(28,24))
 for x in [0,34]:g.draw_circle(cart+Vector2(x,8),7,Color("#465a5d"));g.draw_circle(cart+Vector2(x,8),3,Color("#b4a181"))
 g.draw_arc(DOOR-camera,28,0,TAU,32,Color("#efc77b") if g.position_in_world.distance_to(DOOR)<85 else Color(.9,.8,.5,.35),2,true)
 g.draw_string(font,DOOR-camera+Vector2(-105,36),"ENTER THE BUSINESS DISTRICT",HORIZONTAL_ALIGNMENT_CENTER,210,13,Color("#ecd39b"))

func draw_market_structure(g:Node2D,camera:Vector2)->void:
 var p=WALL.position-camera;var yard=YARD.position-camera
 g.draw_rect(Rect2(yard,YARD.size),Color("#a99870"))
 for n in 18:
  var q=yard+Vector2(14+n*40,15);g.draw_line(q,q+Vector2(0,YARD.size.y-30),Color(.85,.8,.63,.14),1)
 # Warehouse / exchange hall with a long pitched roof and shaded loading arcade.
 g.draw_rect(Rect2(p+Vector2(-12,180),Vector2(366,40)),Color("#80775e"))
 g.draw_rect(Rect2(p,WALL.size),Color("#b6ab89"))
 for y in 8:
  for x in 11:g.draw_rect(Rect2(p+Vector2(x*31+(15 if y%2 else 0),y*23),Vector2(28,20)),Color("#c9bc98"))
 var roof=PackedVector2Array([p+Vector2(-20,0),p+Vector2(55,-70),p+Vector2(288,-70),p+Vector2(365,0),p+Vector2(-20,0)])
 g.draw_colored_polygon(roof,Color("#345d6b"));g.draw_polyline(roof,Color("#d7c393"),4,true)
 for n in 8:g.draw_line(p+Vector2(8+n*45,-3),p+Vector2(64+n*29,-65),Color("#618795"),2)
 g.draw_rect(Rect2(p+Vector2(45,17),Vector2(250,32)),Color("#203e49"));g.draw_string(font,p+Vector2(52,40),"CROSSROADS MARKET",HORIZONTAL_ALIGNMENT_CENTER,236,18,Color("#ecd39b"))
 for x in [22,268]:
  g.draw_rect(Rect2(p+Vector2(x,64),Vector2(48,66)),Color("#466d76"));g.draw_rect(Rect2(p+Vector2(x+4,68),Vector2(40,58)),Color("#f4d998") if g.town_life.calendar.night_amount()>.1 else Color("#9cc8c1"));g.draw_line(p+Vector2(x+24,68),p+Vector2(x+24,126),Color("#ddcc9c"),3)
 for x in [-9,350]:
  var q=p+Vector2(x,132);g.draw_rect(Rect2(q-Vector2(5,9),Vector2(10,18)),Color("#43565b"));g.draw_rect(Rect2(q-Vector2(3,6),Vector2(6,12)),Color("#ffe4a2") if g.town_life.calendar.night_amount()>.1 else Color("#a6aa8a"))
 g.draw_rect(Rect2(p+Vector2(133,80),Vector2(74,115)),Color("#3e5056"))
 for n in 3:g.draw_line(p+Vector2(137+n*24,84),p+Vector2(137+n*24,191),Color("#9a8963"),4)
 # A welcoming mixed-goods arcade replaces the former mineral depot.
 for x in [-505,65]:
  var q=Vector2(x,570)-camera
  g.draw_rect(Rect2(q+Vector2(0,58),Vector2(120,67)),Color("#92704f"))
  for post in [0,120]:g.draw_line(q+Vector2(post,8),q+Vector2(post,125),Color("#67583e"),5)
  for n in 8:g.draw_rect(Rect2(q+Vector2(-5+n*16,0),Vector2(16,28)),Color("#658c78") if n%2 else Color("#ead9ae"))
  for n in 3:
   var key=["sandwich","veggie_basket","coffee"][n] if x<0 else ["shirt","bread","soup"][n]
   var items=preload("res://scripts/business_district/catalog.gd").ops().products
   if not items.has(key):key="sandwich"
   var tex=preload("res://scripts/business_district/art.gd").item_texture(key,"product")
   g.draw_texture_rect(tex,Rect2(q+Vector2(4+n*37,34),Vector2(37,37)),false)
  g.draw_string(font,q+Vector2(6,105),"FRESH & LOCAL" if x<0 else "MAKERS & WARES",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#f4e3b6"))
 # Fabric swags, planters and a double glass door invite visitors into the district.
 for x in [35,105,235,305]:
  var q=p+Vector2(x,51)
  g.draw_line(q,q+Vector2(0,65),Color("#d1b776"),3)
  g.draw_colored_polygon(PackedVector2Array([q,q+Vector2(20,0),q+Vector2(20,58),q+Vector2(10,68),q+Vector2(0,58)]),Color("#617b71") if x<170 else Color("#aa7459"))
 for x in [137,173]:
  g.draw_rect(Rect2(p+Vector2(x,84),Vector2(30,106)),Color("#8d7552"))
  g.draw_rect(Rect2(p+Vector2(x+4,90),Vector2(22,55)),Color("#b5d4c8"))
  g.draw_circle(p+Vector2(x+23,158),2,Color("#edd194"))
 for x in [80,246]:
  var q=p+Vector2(x,186);g.draw_rect(Rect2(q,Vector2(24,25)),Color("#9e7651"));g.draw_circle(q+Vector2(12,-2),17,Color("#658a62"))

func draw_office(g:Node2D,camera:Vector2)->void:
 var p=OFFICE.position-camera;var night=g.town_life.calendar.night_amount()
 g.draw_rect(Rect2(p+Vector2(7,12),OFFICE.size),Color(0,0,0,.22))
 g.draw_rect(Rect2(p,OFFICE.size),Color("#c9bd99"))
 for y in range(12,165,23):g.draw_line(p+Vector2(2,y),p+Vector2(278,y),Color("#b0a685"),2)
 g.draw_colored_polygon(PackedVector2Array([p+Vector2(-14,4),p+Vector2(26,-58),p+Vector2(254,-58),p+Vector2(294,4)]),Color("#48666b"))
 for x in range(35,260,30):g.draw_line(p+Vector2(x,-52),p+Vector2(x-10,0),Color("#739093"),2)
 g.draw_rect(Rect2(p+Vector2(13,10),Vector2(254,30)),Color("#25464b"));g.draw_string(font,p+Vector2(23,30),"CROSSROADS MARKET OFFICE",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#eed29b"))
 for x in [27,207]:
  g.draw_rect(Rect2(p+Vector2(x,58),Vector2(46,62)),Color("#4c6466"));g.draw_rect(Rect2(p+Vector2(x+4,62),Vector2(38,54)),Color("#f1ce84") if night>.1 else Color("#91bfc4"));g.draw_line(p+Vector2(x+23,60),p+Vector2(x+23,120),Color("#d4c5a0"),3)
 g.draw_rect(Rect2(p+Vector2(113,58),Vector2(54,112)),Color("#526769"));g.draw_rect(Rect2(p+Vector2(120,65),Vector2(40,48)),Color("#b5c8bc"));g.draw_circle(p+Vector2(156,139),3,Color("#e5c586"))
 for n in 3:g.draw_rect(Rect2(p+Vector2(98-n*7,170+n*8),Vector2(84+n*14,8)),Color("#b3ac93"))
 for x in [80,192]:
  g.draw_rect(Rect2(p+Vector2(x,130),Vector2(8,16)),Color("#efd493") if night>.1 else Color("#9a9b7c"))
 for x in [12,256]:
  g.draw_rect(Rect2(p+Vector2(x,150),Vector2(16,20)),Color("#96765c"));g.draw_circle(p+Vector2(x+8,145),13,Color("#678b69"))
