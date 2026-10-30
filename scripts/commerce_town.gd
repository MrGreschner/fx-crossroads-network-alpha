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
  for n in 6:
   preload("res://scripts/town_streets244.gd").draw(g,"picket",Rect2(Vector2(-1432+n*240,134)-camera,Vector2(240,77)))
 if visible.intersects(OFFICE.grow(100)):draw_office(g,camera)
 if visible.intersects(YARD.grow(90)):draw_market(g,camera)
 if visible.intersects(CONSTRUCTION.grow(80)):
  var p=CONSTRUCTION.position-camera
  g.draw_rect(Rect2(p,CONSTRUCTION.size),Color("#8b856c"))
  preload("res://scripts/town_streets244.gd").draw(g,"scaffold",Rect2(p+Vector2(-16,-77),Vector2(330,266)))
  g.draw_rect(Rect2(p+Vector2(40,44),Vector2(175,47)),Color("#263f48"));g.draw_string(font,p+Vector2(52,64),"FUTURE DEVELOPMENT",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#e8cd88"));g.draw_string(font,p+Vector2(62,83),"UNDER CONSTRUCTION",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#cad7d0"))


func crate(g:Node2D,p:Vector2,size:Vector2)->void:
 preload("res://scripts/town_streets244.gd").draw(g,"cargo",Rect2(p,size))
func ram_worker(g:Node2D,p:Vector2,t:float,carrying:bool)->void:
 if not Rect2(Vector2.ZERO,g.VIEW).grow(65).has_point(p):return
 worker_body(g,p,t,carrying)
func worker_body(g:Node2D,p:Vector2,t:float,carrying:bool)->void:
 preload("res://scripts/town_cast230.gd").draw(g,"exchange_worker",p+Vector2(0,5),t,true)
 if carrying:crate(g,p-Vector2(12,27),Vector2(24,19))
func draw_market(g:Node2D,camera:Vector2)->void:
 g.draw_texture_rect(preload("res://scripts/town_terrain247.gd").png("market"),Rect2(Vector2(-535,455)-camera,Vector2(745,345)),false)
 var t=Time.get_ticks_msec()*.001
 ram_worker(g,Vector2(-430+sin(t*.45)*25,715)-camera,t,true)
 ram_worker(g,Vector2(33+sin(t*.35)*22,751)-camera,t+1,false)
 ram_worker(g,Vector2(-275+sin(t*.3)*55,776)-camera,t+2,true)
 # A loading cart follows a short safe loop; no simulation entities or particles.
 var cart=Vector2(-485+fposmod(t*12,80),758)-camera
 preload("res://scripts/town_streets244.gd").draw(g,"loading_cart",Rect2(cart-Vector2(10,22),Vector2(54,38)));crate(g,cart-Vector2(4,32),Vector2(28,24))
 g.draw_arc(DOOR-camera,28,0,TAU,32,Color("#efc77b") if g.position_in_world.distance_to(DOOR)<85 else Color(.9,.8,.5,.35),2,true)
 g.draw_string(font,DOOR-camera+Vector2(-105,36),"ENTER THE BUSINESS DISTRICT",HORIZONTAL_ALIGNMENT_CENTER,210,13,Color("#ecd39b"))

func draw_market_structure(g:Node2D,camera:Vector2)->void:
 var p=WALL.position-camera;var yard=YARD.position-camera
 g.draw_rect(Rect2(yard,YARD.size),Color("#a99870"))
 for n in 18:
  var q=yard+Vector2(14+n*40,15);g.draw_line(q,q+Vector2(0,YARD.size.y-30),Color(.85,.8,.63,.14),1)
 preload("res://scripts/town_shops242.gd").draw(g,"market",camera)
 # Both arcade booths retain their own product displays and exact stock footprints.
 for x in [-505,65]:
  var q=Vector2(x,570)-camera
  preload("res://scripts/town_shops242.gd").draw_rect(g,"arcade",Rect2(q-Vector2(5,0),Vector2(130,128)))
  for n in 3:
   var key=["sandwich","veggie_basket","coffee"][n] if x<0 else ["shirt","bread","soup"][n]
   var items=preload("res://scripts/business_district/catalog.gd").ops().products
   if not items.has(key):key="sandwich"
   var tex=preload("res://scripts/business_district/art.gd").item_texture(key,"product")
   g.draw_texture_rect(tex,Rect2(q+Vector2(4+n*37,34),Vector2(37,37)),false)
  g.draw_string(font,q+Vector2(6,105),"FRESH & LOCAL" if x<0 else "MAKERS & WARES",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#f4e3b6"))

func draw_office(g:Node2D,camera:Vector2)->void:
 preload("res://scripts/town_shops242.gd").draw(g,"office",camera)
func draw_office_source241(g:Node2D,camera:Vector2)->void:
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
