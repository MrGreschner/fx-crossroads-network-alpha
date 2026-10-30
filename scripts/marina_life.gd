extends Node
## Daily selection uses the existing bait economy; ambience adds no profile fields.
const E=preload("res://scripts/fishing_ecology.gd")
const UI=preload("res://scripts/studio_ui.gd")
const STALL=Rect2(1450,2260,130,85)
const TRADER=Vector2(1515,2362)
const HOME=Rect2(1300,2490,210,145)
const DOOR=Vector2(1405,2660)
const TREE=Vector2(1290,2350)
const TREES=[Vector2(1025,2310),Vector2(1035,2540),Vector2(1180,2715),Vector2(1450,2780),Vector2(1780,2140)]
const GOODS=["honeygrain","moonmoth","saltflash","kelp_crumble","roe"]
const CARGO=[Rect2(1490,2745,32,28),Rect2(1510,2400,38,31),Rect2(1520,2670,34,28),Rect2(1480,2705,42,30),Rect2(2015,2160,36,30)]
const ROUTE=[Vector2(1585,2355),Vector2(1605,2240),Vector2(2000,2220),Vector2(2220,2250),Vector2(2000,2220),Vector2(1605,2240),Vector2(1585,2355),Vector2(1565,2680),Vector2(1660,2740),Vector2(2140,2745),Vector2(2220,2705),Vector2(2140,2745),Vector2(1660,2740),Vector2(1565,2680)]
const LAMPS=[Vector2(1595,2255),Vector2(1660,2725),Vector2(2110,2725),Vector2(2195,2250)]
var game:Node
var layer:CanvasLayer
var panel:PanelContainer
var notice=""
var shown_day=-999999
var shimmer=0.0
func setup(g:Node)->void:game=g
static func daily_stock(day:int)->Array:
 var result=[]
 for n in [0,2,4]:result.append(GOODS[posmod(day+n,GOODS.size())])
 return result
static func blocked(p:Vector2)->bool:
 if STALL.grow(6).has_point(p) or HOME.grow(9).has_point(p) or p.distance_to(TREE)<23:return true
 for box in CARGO:
  if box.grow(5).has_point(p):return true
 for tree in TREES:
  if p.distance_squared_to(tree)<625:return true
 return false
static func reserved(p:Vector2)->bool:
 if Rect2(1150,2180,470,580).has_point(p):return true
 for n in ROUTE.size():
  if Geometry2D.get_closest_point_to_segment(p,ROUTE[n],ROUTE[(n+1)%ROUTE.size()]).distance_to(p)<80:return true
 return false
static func patrol(seconds:float,offset:float=0)->Dictionary:
 var total=0.0
 for n in ROUTE.size():total+=ROUTE[n].distance_to(ROUTE[(n+1)%ROUTE.size()])/50.0+2.0
 var time=fposmod(seconds+offset,total)
 for n in ROUTE.size():
  var a:Vector2=ROUTE[n];var b:Vector2=ROUTE[(n+1)%ROUTE.size()];var travel=a.distance_to(b)/50.0
  if time<travel+2:return {"pos":a.lerp(b,minf(1,time/maxf(.01,travel))),"walking":time<travel,"aim":(b-a).normalized()}
  time-=travel+2
 return {"pos":ROUTE[0],"walking":false,"aim":Vector2.DOWN}
static func light_sources(g:Node)->Array:
 var result=[]
 for at in LAMPS:result.append({"at":at-Vector2(0,57),"radius":135.0,"strength":.92})
 for at in [Vector2(1475,2297),Vector2(1550,2297),TREE+Vector2(-45,-85),TREE+Vector2(49,-104),Vector2(1834,2500),Vector2(2074,2500)]:result.append({"at":at,"radius":100.0,"strength":.8})
 for at in preload("res://scripts/town_nature243.gd").home_windows("tidekeeper"):result.append({"at":at,"radius":100.0,"strength":.8})
 # The original marina's shore posts now illuminate the actual night mesh too.
 for at in [Vector2(1654,2209),Vector2(2188,2209)]:result.append({"at":at,"radius":110.0,"strength":.8})
 return result
func step(dt:float)->void:
 shimmer+=minf(dt,.1)
 if is_instance_valid(layer):
  if game.mode!="town" or game.menu!="marina_market":close();return
  if shown_day!=game.town_life.calendar.day_number:notice="A fresh delivery has arrived. Today's selection is updated.";render()
  fit()
func buy(id:String,day:int)->String:
 game.town_life.calendar.refresh()
 if game.mode!="town" or game.menu!="marina_market":return "Visit the marina bait stand to trade."
 if day!=game.town_life.calendar.day_number or id not in daily_stock(day):return "Today's delivery changed. Browse the new selection."
 return game.legacy.fishing_records.progress.buy(id,game)
func open()->void:
 if game.mode!="town" or not game.menu.is_empty():return
 game.fishing.cancel("");game.menu="marina_market";game.mobile.reset_controls();notice="";render()
func render()->void:
 if is_instance_valid(layer):layer.queue_free()
 shown_day=game.town_life.calendar.day_number;layer=CanvasLayer.new();layer.layer=66;add_child(layer)
 panel=PanelContainer.new();UI.apply(panel);layer.add_child(panel)
 var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(scroll);var col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.add_theme_constant_override("separation",10);scroll.add_child(col)
 var head=HBoxContainer.new();col.add_child(head);game.fishing.label(head,"BRIN & LIO'S • EXOTIC BAIT",22);var close_button=game.fishing.button(head,"Close",close);close_button.size_flags_horizontal=0;close_button.custom_minimum_size.x=90
 game.fishing.label(col,"Three specialist supplies rotate at Edmonton midnight. Day and night shifts keep the stand open. Same prices and unlocks as the Angler's Workshop.",15)
 game.fishing.label(col,"Glimmers: %d • Fishing level %d" % [game.legacy.glimmers.balance(),game.legacy.fishing_records.progress.level()],17)
 if not notice.is_empty():game.fishing.label(col,notice,15)
 for id in daily_stock(shown_day):
  var spec:Dictionary=E.BAITS[id];var prog=game.legacy.fishing_records.progress;var card=UI.card(col,str(spec.name)+" • "+str(prog.state().bait.get(id,0))+" owned",str(spec.description));var row=HBoxContainer.new();card.add_child(row)
  var art=TextureRect.new();art.texture=preload("res://scripts/source_art.gd").texture("res://assets/fishing/bait_"+id+".svg");art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;art.custom_minimum_size=Vector2(65,46);row.add_child(art)
  var offer_day=shown_day;var button=game.fishing.button(row,"Buy 3 • %d Glimmers" % int(spec.cost),func():notice=buy(id,offer_day);render());button.disabled=not prog.bait_unlocked(id)
  if not prog.bait_unlocked(id):game.fishing.label(card,"Fishing level %d required" % int(prog.BAIT_LEVELS[id]),14)
 fit();UI.enter(panel)
func fit()->void:
 var view=game.get_viewport_rect().size;panel.scale=Vector2.ONE;panel.size=Vector2(minf(700,view.x-24),minf(590,view.y-24));panel.position=(view-panel.size)*.5
func close()->void:
 if is_instance_valid(layer):layer.queue_free()
 layer=null;panel=null
 if game.menu=="marina_market":game.menu=""
 game.mobile.reset_controls()
func _input(event:InputEvent)->void:
 if is_instance_valid(layer) and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()
func interact()->bool:
 if game.position_in_world.distance_to(TRADER)<67:
  game.hint="E • Exotic bait • new delivery every day"
  if Input.is_action_just_pressed("interact"):open()
  return true
 if game.position_in_world.distance_to(DOOR)<55:
  game.hint="E • Tidekeeper Cottage"
  if Input.is_action_just_pressed("interact"):game.message="Tidekeeper Cottage • Brin and Lio share this harbour home. One minds the stand while the other rests. The porch light welcomes the late shift.";game.message_time=6
  return true
 for n in 2:
  var at:Vector2=patrol(game.town_life.calendar.now,n*37).pos
  if game.position_in_world.distance_to(at)<42:
   game.hint="E • Harbour watch"
   if Input.is_action_just_pressed("interact"):game.message="Harbour Watch: Keep the river mouth clear. The night shift carries a light; bring your catches home safe.";game.message_time=5
   return true
 return false
static func person(c:Node2D,at:Vector2,coat:Color,guard:bool,t:float,walking:bool)->void:
 var id="guard_melee" if guard else "Lio" if coat==Color("#7d719d") else "Brin"
 preload("res://scripts/town_cast230.gd").draw(c,id,at+Vector2(0,8),t,walking)
func draw_cottage_source(c:Node2D,cam:Vector2)->void:
 preload("res://scripts/town_nature243.gd").home(c,"tidekeeper",cam)
 c.draw_string(ThemeDB.fallback_font,HOME.position-cam+Vector2(12,191),"TIDEKEEPER COTTAGE",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#e9dabb"))

func draw_fittings_source(c:Node2D,cam:Vector2)->void:
 # Export crates with rope handles, stencilled fish and a net drying on the bank.
 for box in CARGO:
  c.draw_texture_rect(preload("res://scripts/marina_art250.gd").texture("cargo"),Rect2(box.position-cam-Vector2(3,8),box.size+Vector2(6,8)),false)
 preload("res://scripts/town_streets244.gd").draw(c,"net",Rect2(Vector2(1530,2410)-cam,Vector2(60,45)))
 # Reuse accepted matte basket/rope art at the original decorative anchors.
 for at in [Vector2(1244,2590),Vector2(1244,2630)]:preload("res://scripts/town_streets244.gd").draw(c,"basket",Rect2(at-cam-Vector2(12,25),Vector2(24,34)))
 preload("res://scripts/town_streets244.gd").draw(c,"rope",Rect2(Vector2(1597,2451)-cam,Vector2(36,28)))
 var rack=Vector2(1270,2700)-cam
 for x in [0,78]:c.draw_line(rack+Vector2(x,0),rack+Vector2(x,-45),Color("#826d4f"),4)
 c.draw_line(rack-Vector2(3,40),rack+Vector2(81,-40),Color("#b4ad86"),2)
 c.draw_texture_rect(preload("res://scripts/marina_art250.gd").texture("bait_stall"),Rect2(Vector2(1440,2230)-cam,Vector2(150,125)),false)
 c.draw_string(ThemeDB.fallback_font,STALL.position-cam+Vector2(-4,-42),"EXOTIC BAIT • DAILY DELIVERY",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#f4dfb5"))

func draw_on(c:Node2D,cam:Vector2)->void:
 if not Rect2(cam,c.VIEW).grow(200).intersects(Rect2(1130,2130,1150,680)):return
 var t=shimmer;var hour=game.town_life.calendar.hour;var night=game.town_life.calendar.night_amount()
 # Streets are rendered by town_plan with the shared town path tiles.
 for at in TREES:
  if Rect2(cam,c.VIEW).grow(150).has_point(at):c.draw_sprite("tree",at-Vector2(55,115),Vector2(110,145))
 preload("res://scripts/town_art39.gd").draw(c,"marina_cottage_night" if night>.1 else "marina_cottage",cam)
 var chimney=preload("res://scripts/town_nature243.gd").chimney("tidekeeper")-cam
 for n in 3:c.draw_circle(chimney+Vector2(sin(t+n)*6,-12-n*17-fposmod(t*8,17)),8+n*3,Color(.8,.8,.74,.17))
 # Ancient knot willow: bent trunk, swaying limbs and hanging lanterns.
 var tree=TREE-cam
 preload("res://scripts/town_nature243.gd").tree(c,"knot_willow",Rect2(tree-Vector2(130,200),Vector2(260,220)),TREE)
 for pair in [[-45,-85],[49,-104]]:
  var x=pair[0];var y=pair[1];var at=tree+Vector2(x+sin(t)*2,y);c.draw_line(at-Vector2(0,27),at,Color('#b1ac88'),1.5);c.draw_rect(Rect2(at-Vector2(5,0),Vector2(10,15)),Color('#eacb82') if night>.1 else Color('#b7ae85'));c.draw_rect(Rect2(at-Vector2(7,2),Vector2(14,3)),Color('#736348'))
 preload("res://scripts/town_art39.gd").draw(c,"marina_fittings",cam)
 var rack=Vector2(1270,2700)-cam
 for n in 4:
  var q=rack+Vector2(12+n*18,-37);c.draw_line(q,q+Vector2(sin(t*1.2+n)*2,12),Color("#b7aa83"),1);c.draw_colored_polygon(PackedVector2Array([q+Vector2(-4,12),q+Vector2(0,22),q+Vector2(4,12),q+Vector2(0,8)]),Color("#91aaa1"))
 var night_shift=hour<7 or hour>=20;person(c,TRADER-cam,Color('#7d719d') if night_shift else Color('#4d8e92'),false,t,false)
 c.draw_string(ThemeDB.fallback_font,TRADER-cam+Vector2(-20,27),"Lio • night shift" if night_shift else "Brin • bait trader",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color('#ead9ba'))
 for n in 2:
  var guard=patrol(game.town_life.calendar.now,n*37);game.town_scenery.guard(c,guard.pos-cam,guard.walking)
 for at in LAMPS:preload("res://scripts/marina_art250.gd").lamp(c,at-cam,night>.1)
 for at in [Vector2(1834,2500),Vector2(2074,2500)]:
  c.draw_rect(Rect2(at-cam-Vector2(6,5),Vector2(12,12)),Color('#4f5f59'));c.draw_rect(Rect2(at-cam-Vector2(3,3),Vector2(6,8)),Color('#f8d88f') if night>.1 else Color('#a5ad91'))
  if night>.1:
   for n in 3:c.draw_line(at-cam+Vector2(-8-n*4,22+n*5),at-cam+Vector2(8+n*4,22+n*5),Color(1,.79,.39,.16-n*.04),2,true)
