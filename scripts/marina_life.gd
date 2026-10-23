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
const CARGO=[Rect2(1540,2510,32,28),Rect2(1543,2550,38,31),Rect2(1520,2670,34,28),Rect2(1480,2705,42,30),Rect2(2015,2160,36,30)]
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
 for at in [Vector2(1475,2297),Vector2(1550,2297),Vector2(1340,2565),Vector2(1470,2565),TREE+Vector2(-45,-85),TREE+Vector2(49,-104),Vector2(1834,2500),Vector2(2074,2500)]:result.append({"at":at,"radius":100.0,"strength":.8})
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
 var bob=sin(t*7)*1.4 if walking else sin(t*1.6)*.5;at.y+=bob
 c.draw_circle(at+Vector2(0,5),13,Color(0,0,0,.18));c.draw_line(at+Vector2(-5,-1),at+Vector2(-5+sin(t*7)*(3 if walking else 0),10),Color('#4b433d'),5);c.draw_line(at+Vector2(5,-1),at+Vector2(5-sin(t*7)*(3 if walking else 0),10),Color('#4b433d'),5)
 c.draw_colored_polygon(PackedVector2Array([at+Vector2(-12,-23),at+Vector2(12,-23),at+Vector2(14,1),at+Vector2(-14,1)]),coat)
 c.draw_circle(at+Vector2(0,-31),10,Color('#d8bb8f'));c.draw_circle(at+Vector2(-3,-32),1.3,Color('#293b42'));c.draw_circle(at+Vector2(4,-32),1.3,Color('#293b42'))
 if guard:
  for side in [-1,1]:c.draw_arc(at+Vector2(side*10,-37),6,0,PI*1.8,10,Color('#d4ccaa'),3,true)
  c.draw_rect(Rect2(at+Vector2(-10,-43),Vector2(20,8)),Color('#82949b'));c.draw_line(at+Vector2(17,-42),at+Vector2(17,7),Color('#c4a87b'),3)
  c.draw_colored_polygon(PackedVector2Array([at+Vector2(-18,-22),at+Vector2(-5,-22),at+Vector2(-6,-6),at+Vector2(-12,0),at+Vector2(-19,-6)]),Color('#b6c5bd'));c.draw_line(at+Vector2(-12,-20),at+Vector2(-12,-3),coat,3)
 else:
  c.draw_arc(at+Vector2(0,-36),12,PI,TAU,16,coat.lightened(.2),7,true);c.draw_line(at+Vector2(-12,-35),at+Vector2(13,-35),coat.lightened(.3),4)
  c.draw_rect(Rect2(at+Vector2(-8,-18),Vector2(16,20)),Color('#d3bc88'));c.draw_line(at+Vector2(6,-20),at+Vector2(13,-12),Color('#d8bb8f'),5)
func draw_on(c:Node2D,cam:Vector2)->void:
 if not Rect2(cam,c.VIEW).grow(200).intersects(Rect2(1130,2130,1150,680)):return
 var t=shimmer;var hour=game.town_life.calendar.hour;var night=game.town_life.calendar.night_amount()
 # Streets are rendered by town_plan with the shared town path tiles.
 for at in TREES:
  if Rect2(cam,c.VIEW).grow(150).has_point(at):c.draw_sprite("tree",at-Vector2(55,115),Vector2(110,145))
 # Tidekeeper cottage: irregular shingles, chimney, window boxes, front porch.
 var h=HOME.position-cam;c.draw_rect(Rect2(h+Vector2(7,12),HOME.size),Color(0,0,0,.2));c.draw_rect(Rect2(h,HOME.size),Color('#c4b08b'));c.draw_rect(Rect2(h+Vector2(0,15),Vector2(210,14)),Color('#806b51'))
 for y in range(35,145,23):c.draw_line(h+Vector2(0,y),h+Vector2(210,y),Color('#9b8b6b'),2)
 c.draw_colored_polygon(PackedVector2Array([h+Vector2(-16,18),h+Vector2(38,-54),h+Vector2(157,-61),h+Vector2(226,18)]),Color('#6c655c'))
 for row in 4:
  var y=-37+row*14;c.draw_line(h+Vector2(30-row*12,y),h+Vector2(170+row*11,y),Color('#aaa08a'),3)
 c.draw_rect(Rect2(h+Vector2(157,-67),Vector2(25,58)),Color('#8c8174'))
 for n in 3:c.draw_circle(h+Vector2(169+sin(t+n)*6,-79-n*17-fposmod(t*8,17)),8+n*3,Color(.8,.8,.74,.17))
 for x in [28,158]:
  c.draw_rect(Rect2(h+Vector2(x,49),Vector2(29,38)),Color('#524d43'));c.draw_rect(Rect2(h+Vector2(x+3,52),Vector2(23,32)),Color('#efcb87') if night>.1 else Color('#7fadae'));c.draw_line(h+Vector2(x+14,50),h+Vector2(x+14,85),Color('#5e6558'),3);c.draw_line(h+Vector2(x,68),h+Vector2(x+29,68),Color('#5e6558'),3);c.draw_rect(Rect2(h+Vector2(x-4,87),Vector2(37,8)),Color('#766143'))
  for n in 4:c.draw_circle(h+Vector2(x+n*8,83),3,Color('#c3988e') if n%2 else Color('#92ab6c'))
 c.draw_rect(Rect2(h+Vector2(85,74),Vector2(40,71)),Color('#705944'));c.draw_circle(h+Vector2(116,112),2,Color('#e0c58b'));c.draw_rect(Rect2(h+Vector2(72,145),Vector2(66,20)),Color('#b19e7e'));c.draw_string(ThemeDB.fallback_font,h+Vector2(12,191),"TIDEKEEPER COTTAGE",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color('#e9dabb'))
 # Ancient knot willow: bent trunk, swaying limbs and hanging lanterns.
 var tree=TREE-cam;var sway=sin(t*.8)*4
 c.draw_line(tree,tree+Vector2(-15,-82),Color('#655847'),28);c.draw_line(tree+Vector2(-15,-74),tree+Vector2(12,-131),Color('#786b53'),20)
 for side in [-1,1]:c.draw_line(tree+Vector2(-8,-82),tree+Vector2(side*60+sway,-115),Color('#786b53'),10)
 for n in 7:
  var at=tree+Vector2(-83+n*27+sway*sin(n+1),-123-absf(sin(n*1.6))*32);c.draw_circle(at,35,Color('#547c63') if n%2 else Color('#6d906c'))
  c.draw_arc(at+Vector2(0,10),26,.1,2.8,14,Color('#9cb58a',.6),2,true)
  for k in 3:c.draw_line(at+Vector2(k*9-9,17),at+Vector2(k*9-9+sin(t+n)*4,44+k*7),Color('#82a17a'),2,true)
 c.draw_circle(tree+Vector2(-8,-37),11,Color('#473e36'));c.draw_arc(tree+Vector2(-8,-37),8,0,TAU,16,Color('#a08b64'),2,true)
 for pair in [[-45,-85],[49,-104]]:
  var x=pair[0];var y=pair[1];var at=tree+Vector2(x+sin(t)*2,y);c.draw_line(at-Vector2(0,27),at,Color('#b1ac88'),1.5);c.draw_rect(Rect2(at-Vector2(5,0),Vector2(10,15)),Color('#eacb82') if night>.1 else Color('#b7ae85'));c.draw_rect(Rect2(at-Vector2(7,2),Vector2(14,3)),Color('#736348'))
 # Export crates with rope handles, stencilled fish and a net drying on the bank.
 for box in CARGO:
  var at=box.position-cam;c.draw_rect(Rect2(at+Vector2(3,4),box.size),Color(0,0,0,.2));c.draw_rect(Rect2(at,box.size),Color('#a78358'));c.draw_rect(Rect2(at,box.size),Color('#d4b681'),false,2);c.draw_line(at+Vector2(3,3),at+box.size-Vector2(3,3),Color('#70593e'),3);c.draw_line(at+Vector2(box.size.x-3,3),at+Vector2(3,box.size.y-3),Color('#70593e'),3);c.draw_circle(at+box.size*.5,4,Color('#d7c093'))
 for x in range(1530,1590,9):c.draw_line(Vector2(x,2410)-cam,Vector2(x+6,2450)-cam,Color('#c9c2a0',.5),1)
 for y in range(2410,2455,9):c.draw_line(Vector2(1530,y)-cam,Vector2(1590,y)-cam,Color('#c9c2a0',.5),1)
 # Trade details stay on the bank, clear of the cottage and walking route.
 for at in [Vector2(1244,2590),Vector2(1244,2630)]:
  var q=at-cam;pass
  c.draw_rect(Rect2(q-Vector2(12,20),Vector2(24,29)),Color("#896b48"));c.draw_arc(q-Vector2(0,20),12,PI,TAU,12,Color("#bf9c6e"),4,true)
  for y in [-14,2]:c.draw_line(q+Vector2(-12,y),q+Vector2(12,y),Color("#506466"),3)
 var rope=Vector2(1615,2465)-cam
 for n in 4:c.draw_arc(rope,9+n*2,0,TAU,18,Color("#c4af7e"),1.5,true)
 var rack=Vector2(1270,2700)-cam
 for x in [0,78]:c.draw_line(rack+Vector2(x,0),rack+Vector2(x,-45),Color("#826d4f"),4)
 c.draw_line(rack-Vector2(3,40),rack+Vector2(81,-40),Color("#b4ad86"),2)
 for n in 4:
  var q=rack+Vector2(12+n*18,-37);c.draw_line(q,q+Vector2(sin(t*1.2+n)*2,12),Color("#b7aa83"),1);c.draw_colored_polygon(PackedVector2Array([q+Vector2(-4,12),q+Vector2(0,22),q+Vector2(4,12),q+Vector2(0,8)]),Color("#91aaa1"))
 # Striped awning, specimen jars and specialist bait trays.
 var s=STALL.position-cam;c.draw_rect(Rect2(s+Vector2(0,36),Vector2(130,49)),Color('#816348'));c.draw_rect(Rect2(s+Vector2(-8,-30),Vector2(146,54)),Color('#477c7a'))
 for n in 7:
  if n%2==0:c.draw_rect(Rect2(s+Vector2(-8+n*21,-30),Vector2(21,54)),Color('#d6bd8a'))
 for x in [-4,134]:c.draw_line(s+Vector2(x,-28),s+Vector2(x,90),Color('#80674c'),4)
 for n in 3:
  var at=s+Vector2(23+n*39,33);c.draw_rect(Rect2(at-Vector2(10,13),Vector2(20,24)),Color('#9dc4b9'));c.draw_rect(Rect2(at-Vector2(10,16),Vector2(20,4)),Color('#d7c096'));c.draw_arc(at,6,0,TAU,14,[Color('#cbb17a'),Color('#b8b0db'),Color('#d59d7c')][n],3,true)
 c.draw_string(ThemeDB.fallback_font,s+Vector2(-4,-42),"EXOTIC BAIT • DAILY DELIVERY",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color('#f4dfb5'))
 var night_shift=hour<7 or hour>=20;person(c,TRADER-cam,Color('#7d719d') if night_shift else Color('#4d8e92'),false,t,false)
 c.draw_string(ThemeDB.fallback_font,TRADER-cam+Vector2(-20,27),"Lio • night shift" if night_shift else "Brin • bait trader",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color('#ead9ba'))
 for n in 2:
  var guard=patrol(game.town_life.calendar.now,n*37);game.town_scenery.guard(c,guard.pos-cam,guard.walking)
 for at in LAMPS:preload("res://scripts/town_calendar.gd").draw_lantern_source(c,at-cam,night)
 for at in [Vector2(1834,2500),Vector2(2074,2500)]:
  c.draw_rect(Rect2(at-cam-Vector2(6,5),Vector2(12,12)),Color('#4f5f59'));c.draw_rect(Rect2(at-cam-Vector2(3,3),Vector2(6,8)),Color('#f8d88f') if night>.1 else Color('#a5ad91'))
  if night>.1:
   for n in 3:c.draw_line(at-cam+Vector2(-8-n*4,22+n*5),at-cam+Vector2(8+n*4,22+n*5),Color(1,.79,.39,.16-n*.04),2,true)
