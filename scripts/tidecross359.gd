extends RefCounted
## Walkable extensions of the town map share the Crossroads calendar and profile.
const COAST=preload("res://scripts/tidecross_coast360.gd")
const BAY=preload("res://scripts/oldwater_bay361.gd")
const UI=preload("res://scripts/studio_ui.gd")
const CAST=preload("res://scripts/town_cast230.gd")
const NATURE=preload("res://scripts/town_nature243.gd")
const SKIFF=preload("res://scripts/marina_art250.gd")
const ICE=preload("res://scripts/town_winter358.gd")
const STREETS=preload("res://scripts/town_plan.gd")
const MIN=Vector2(-1370,-4050)
const TOWN_PIER=Vector2(1860,2300)
const PORT=Rect2(1170,2860,1650,1390)
const COVE=BAY.BOUNDS
const NORTH_ENTRY=STREETS.BAY_TRAILHEAD
const SOUTH_ENTRY=STREETS.HARBOUR_TRAILHEAD
const HARBOUR_TRAIL_EXIT=Vector2(1490,3010)
const TRAIL_STOPS=[NORTH_ENTRY,SOUTH_ENTRY,BAY.TRAIL_EXIT,HARBOUR_TRAIL_EXIT]
const TRAIL_LANDINGS=[BAY.TRAIL_ARRIVAL,HARBOUR_TRAIL_EXIT+Vector2(0,68),NORTH_ENTRY+Vector2(0,82),SOUTH_ENTRY-Vector2(0,65)]
const TRAIL_LABELS=["To Oldwater Bay","To Tidecross Harbour","To Crossroads","To Crossroads"]
const FERRY=Vector2(2220,3575)
const PORT_ARRIVAL=Vector2(2160,3582)
const SEA_PIER=Vector2(1845,3882)
const SEA_OFFICE=Vector2(1745,3740)
const OFFICE_FRAME=Rect2(1695,3651,100,88)
const WEST_RIDGE_HIGHLANDS=Rect2(0,2860,1260,1020)
const BAIT=Vector2(1983,3825)
const PORT_LAMPS=[Vector2(2118,3990),Vector2(2054,3743),Vector2(1510,3370),Vector2(1930,3630),Vector2(2180,3560),Vector2(1845,3881)]
const TRADER=Vector2(1732,3530)
const SAILOR=Vector2(1380,3760)
const COVE_ARRIVAL=BAY.ARRIVAL
const COVE_RETURN=BAY.FERRY
const BUILDINGS=[
 ["cliff_cottage",Rect2(1280,3095,158,146),"Nera’s cottage"],
 ["river_home",Rect2(1530,3070,162,146),"Oren’s cottage"],
 ["orchard_home",Rect2(1790,3115,156,146),"Mara’s cottage"],
 ["artists_duplex",Rect2(1630,3330,214,195),"Tidecross Trading Post"],
 ["tidekeeper",Rect2(1290,3550,178,194),"Old Sailor’s Hut"]
]
const GARDEN_STOCK=[
 ["orchard0","river0","roots0","honey_pea","marsh_lotus"],
 ["flowers0","roots1","river1","silverfall_cress","astral_orchid"],
 ["orchard1","flowers1","roots0","ember_ginger","moonveil_grape"],
 ["river0","orchard2","flowers0","honeyglass_melon","oath_olive"],
 ["roots1","river2","orchard0","copper_carrot","sunfield_corn"],
 ["flowers2","orchard1","roots1","grove_fern","wayfarer_thyme"],
 ["river1","flowers1","orchard0","velvet_sage","frost_turnip"]
]
const GOODS=["mint","willow","sunleaf","mooncap","petal","worm","firefly"]
const RESIDENTS=[
 ["Nera","Tess",Vector2(1360,3248),[Vector2(1490,3345),Vector2(1732,3538),Vector2(2010,3720)],"I buy what the boats bring in before sunrise. The trading post changes its stock each morning."],
 ["Oren","Bram",Vector2(1610,3226),[Vector2(1960,3345),Vector2(2175,3570),Vector2(1910,3740)],"The merchant ships sit lower when they carry wet timber. You can tell what came in by how much hull is showing."],
 ["Mara","Lark",Vector2(1870,3268),[Vector2(1900,3460),Vector2(2050,3750),Vector2(1985,3784)],"Salt gets into every hinge here. My garden beds are inland, where the wind drops."]
]
static var shore_ice:CanvasTexture

static func winter(g:Node)->bool:return ICE.SEASON.active(g)
static func is_extension(p:Vector2)->bool:return p.y>=2800 or p.y< -430 or p.x>=3070
static func is_port(p:Vector2)->bool:return PORT.has_point(p) and p.y>=2940
static func is_cove(p:Vector2)->bool:return COVE.has_point(p) and p.y< -1125
static func on_ice(p:Vector2)->bool:return BAY.ice_at(p)
static func deck(p:Vector2)->bool:
 return COAST.on_dock(p)
static func land(p:Vector2,frozen:bool)->bool:
 if is_cove(p):
  return BAY.grounded(p,frozen)
 if not is_port(p):return false
 if OFFICE_FRAME.has_point(p) and p.y<SEA_OFFICE.y-17:return false
 if deck(p):return true
 if not COAST.solid_land(p):return false
 for b in BUILDINGS:
  var r:Rect2=b[1]
  if Rect2(r.position+Vector2(7,r.size.y*.54),Vector2(r.size.x-14,r.size.y*.45)).has_point(p):return false
 return true

static func ice_texture()->CanvasTexture:
 if shore_ice==null:
  shore_ice=CanvasTexture.new()
  shore_ice.diffuse_texture=ICE.texture("ice")
  shore_ice.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
 return shore_ice

static func stock(day:int)->Array:return GARDEN_STOCK[posmod(day,GARDEN_STOCK.size())]
static func price_for(seed:Dictionary,exotic:bool)->int:
 return maxi(4,int(seed.seed_price)) if not exotic else maxi(35,26+int(seed.level)*4)
static func buy_seed(g:Node,id:String)->bool:
 if g.mode!="town" or g.position_in_world.distance_to(TRADER)>=78:return false
 var goods=stock(g.town_life.calendar.day_number)
 if id not in goods:return false
 var garden=g.legacy.gardening
 if not garden.allowed() or garden.seed_count(id)>=1000000:return false
 var cost=price_for(garden.crops()[id],goods.find(id)>=3)
 if not g.legacy.glimmers.debit(cost):return false
 garden.grant(id)
 garden.save()
 return true

static func buy_ingredients(g:Node,id:String)->bool:
 if g.mode!="town" or g.position_in_world.distance_to(TRADER)>=78:return false
 if id!=GOODS[posmod(g.town_life.calendar.day_number,GOODS.size())]:return false
 if not g.legacy.gardening.allowed():return false
 var supplies:Dictionary=g.legacy.lodge_economy.state().ingredients
 if int(supplies.get(id,0))>99997 or not g.legacy.glimmers.debit(15):return false
 supplies[id]=int(supplies.get(id,0))+3
 g.legacy.save()
 return true

static func move_to(g:Node,point:Vector2)->void:
 g.fishing.cancel("")
 g.presentation.close()
 g.menu=""
 g.mobile.reset_controls()
 g.position_in_world=point
 g.oldwater_glide=Vector2.ZERO
 g.update_camera()

static func at_town_marina(point:Vector2)->bool:
 return point.distance_to(TOWN_PIER)<=150 or preload("res://scripts/town_marina.gd").on_deck(point)

static func at_sea_departure(point:Vector2)->bool:
 return point.distance_to(SEA_OFFICE)<59 or point.distance_to(SEA_PIER)<=90

static func ferry(g:Node,point:Vector2)->bool:
 if g.mode!="town" or winter(g):return false
 if point==PORT_ARRIVAL or point==COVE_ARRIVAL:
  if not at_town_marina(g.position_in_world):return false
 elif point==TOWN_PIER:
  if g.position_in_world.distance_to(FERRY)>86 and g.position_in_world.distance_to(COVE_RETURN)>86:return false
 else:return false
 move_to(g,BAY.FERRY_ARRIVAL if point==COVE_ARRIVAL else point)
 return true

static func thaw(g:Node)->void:
 if is_cove(g.position_in_world) and not winter(g) and not land(g.position_in_world,false):move_to(g,COVE_ARRIVAL)

static func resident_state(index:int,hour:float,weekday:int)->Dictionary:
 var r=RESIDENTS[index]
 var start=7.0+index*.7
 var end=19.0-index*.55
 if hour<start or hour>=end:return {}
 var stops:Array=r[3]
 var shift=floori(hour-start)
 var a:Vector2=r[2] if shift==0 else stops[posmod(shift+weekday+index-1,stops.size())]
 var b:Vector2=stops[posmod(shift+weekday+index,stops.size())]
 if hour>=end-.5:
  var go_home=clampf((hour-(end-.5))/.33,0,1)
  if go_home>=1:return {}
  return {"pos":via_quay(b,r[2],go_home),"moving":true}
 var factor=clampf(fposmod(hour-start,1.0)*4.0,0,1)
 return {"pos":via_quay(a,b,factor),"moving":factor<1.0}

static func via_quay(a:Vector2,b:Vector2,ratio:float)->Vector2:
 var exit=Vector2(a.x,maxf(3300,a.y))
 var enter=Vector2(b.x,maxf(3300,b.y))
 var points=[a,exit,Vector2(1910,exit.y),Vector2(1910,enter.y),enter,b]
 var remaining=0.0
 for n in range(1,points.size()):remaining+=points[n-1].distance_to(points[n])
 remaining*=ratio
 for n in range(1,points.size()):
  var distance:float=points[n-1].distance_to(points[n])
  if distance>0 and remaining<=distance:return points[n-1].lerp(points[n],remaining/distance)
  remaining-=distance
 return b

static func camera_span(p:Vector2)->Vector2:
 if is_cove(p):return Vector2(COVE.position.y,COVE.end.y)
 if is_port(p):return Vector2(PORT.position.y,PORT.end.y)
 return Vector2(-530,3120)

static func use_trail(g:Node,index:int)->bool:
 if index<0 or index>=TRAIL_STOPS.size() or g.mode!="town" or g.position_in_world.distance_to(TRAIL_STOPS[index])>=57:return false
 move_to(g,TRAIL_LANDINGS[index])
 g.message="Arrived at "+["Oldwater Bay","Tidecross Harbour","Crossroads","Crossroads"][index]
 g.message_time=2.5
 return true

static func interact(g:Node)->bool:
 var p:Vector2=g.position_in_world
 for index in TRAIL_STOPS.size():
  if p.distance_to(TRAIL_STOPS[index])>=57:continue
  g.hint="E • "+TRAIL_LABELS[index]
  if Input.is_action_just_pressed("interact"):use_trail(g,index)
  return true
 if not is_extension(p):return false
 if is_cove(p) and BAY.meet(g):return true
 if p.distance_to(SEA_OFFICE)<59:
  g.hint="E • Talk to the Sea Expeditions harbourmaster"
  if Input.is_action_just_pressed("interact"):g.voyage.open_menu("pier")
 elif p.distance_to(BAIT)<62:
  g.hint="E • Dockside Bait"
  if Input.is_action_just_pressed("interact"):bait_shop(g)
 elif p.distance_to(TRADER)<78:
  g.hint="E • Tidecross Trading Post"
  if Input.is_action_just_pressed("interact"):trade_shop(g)
 elif p.distance_to(SAILOR)<73 and g.town_life.calendar.hour>=8 and g.town_life.calendar.hour<20:
  g.hint="E • Talk to Captain Ives"
  if Input.is_action_just_pressed("interact"):sailor_dialogue(g)
 elif p.distance_to(FERRY)<86 or p.distance_to(COVE_RETURN)<86:
  g.hint="Ferries paused • use the trail waypoint" if winter(g) else "E • Ferry to Crossroads Marina"
  if Input.is_action_just_pressed("interact"):ferry(g,TOWN_PIER)
 else:
  var cal=g.town_life.calendar
  for n in RESIDENTS.size():
   var s=resident_state(n,cal.hour,cal.weekday)
   if s.is_empty() or p.distance_to(s.pos)>=44:continue
   g.hint="E • Talk to "+RESIDENTS[n][0]
   if Input.is_action_just_pressed("interact"):
    g.presentation.window(RESIDENTS[n][0],"town_conversation")
    g.presentation.label(g.presentation.content,RESIDENTS[n][0],24)
    g.presentation.label(g.presentation.content,RESIDENTS[n][4],18)
   break
 return true

static func trade_shop(g:Node)->void:
 var ui=g.presentation
 ui.window("Tidecross Trading Post","tidecross_goods")
 var garden=g.legacy.gardening
 ui.label(ui.content,"Today’s shipment • %d Glimmers" % g.legacy.glimmers.balance(),19)
 ui.label(ui.content,"New stock at midnight. The Seedhouse can grow imported seeds once you reach their Gardening level.",16)
 var goods=stock(g.town_life.calendar.day_number)
 for id in goods:
  var seed:Dictionary=garden.crops()[id]
  var cost=price_for(seed,goods.find(id)>=3)
  var button:Button=ui.button(ui.content,"%s  •  %d Glimmers  •  Grow at Lv %d" % [seed.name,cost,int(seed.level)],func():
   buy_seed(g,id)
   trade_shop(g))
  button.disabled=g.legacy.glimmers.balance()<cost or not garden.allowed() or garden.seed_count(id)>=1000000
 var ingredient=GOODS[posmod(g.town_life.calendar.day_number,GOODS.size())]
 var name=preload("res://scripts/lodge_catalog.gd").INGREDIENTS[ingredient].name
 var supply:Button=ui.button(ui.content,"%s ×3  •  15 Glimmers" % name,func():
  buy_ingredients(g,ingredient)
  trade_shop(g))
 supply.disabled=g.legacy.glimmers.balance()<15 or not garden.allowed() or int(g.legacy.lodge_economy.state().ingredients.get(ingredient,0))>99997

static func bait_shop(g:Node,result:String="")->void:
 var ui=g.presentation
 var prog=g.fishing.records().progress
 var baits=preload("res://scripts/fishing_ecology.gd").BAITS
 ui.window("Dockside Bait","tidecross_bait")
 ui.label(ui.content,"Baits are sold in packs of three • %d Glimmers" % g.legacy.glimmers.balance(),18)
 ui.label(ui.content,result,15)
 for id in ["worms","dough","scraps","saltflash","kelp_crumble"]:
  var bait:Dictionary=baits[id]
  var button:Button=ui.button(ui.content,"%s  •  %d Glimmers" % [bait.name,int(bait.cost)],func():bait_shop(g,prog.buy(id,g)))
  button.disabled=not prog.bait_unlocked(id)
  button.tooltip_text=str(bait.description)

static func sailor_dialogue(g:Node)->void:
 var ui=g.presentation
 ui.window("Captain Ives","town_conversation")
 ui.label(ui.content,"Captain Ives",24)
 var stories=[
  "There’s an island the chart refuses to hold. Find it after dark, and have your anchor up before dawn.",
  "Three lanterns have crossed the horizon in a dead calm. Ships rock out there. Those lights didn’t.",
  "Some nights the shoals shine blue. Come back with a catch and I might tell you what made them shine."
 ]
 ui.label(ui.content,stories[posmod(g.town_life.calendar.day_number,stories.size())],19)

static func plaque(c:Node2D,p:Vector2,text:String,width:float=190)->void:
 var box=Rect2(p-Vector2(width*.5,23),Vector2(width,30))
 preload("res://scripts/town_streets244.gd").plaque(c,box)
 c.draw_string(UI.FONT,p-Vector2(width*.5,3),text,HORIZONTAL_ALIGNMENT_CENTER,width,14,Color("#f6deb0"))

static func draw(c:Node2D,cam:Vector2)->void:
 var view=Rect2(cam,c.VIEW).grow(100)
 var season:String=c.town_life.calendar.season()
 var here:Vector2=c.position_in_world
 var at_bay=is_cove(here)
 var at_harbour=is_port(here)
 if at_harbour:draw_port(c,cam,view,season)
 if at_bay:BAY.draw(c,cam,view,season)
 var signs=[2] if at_bay else [3] if at_harbour else [0,1]
 for index in signs:
  var stop:Vector2=TRAIL_STOPS[index]
  if not view.has_point(stop):continue
  var p=stop-cam
  c.draw_arc(p,24,0,TAU,32,Color("#b7decf"),2,true)
  if index==2:BAY.small_sign(c,p+Vector2(0,-19),"TO CROSSROADS",103)
  else:plaque(c,p+Vector2(0,-34),TRAIL_LABELS[index].to_upper(),202)

static func crate(c:Node2D,q:Vector2,s:Vector2)->void:
 c.draw_rect(Rect2(q+Vector2(2,3),s),Color("#494844"))
 c.draw_rect(Rect2(q,s),Color("#a58b65"))
 c.draw_rect(Rect2(q,s).grow(-2),Color("#695945"),false,1)
 c.draw_line(q+Vector2(2,s.y-2),q+Vector2(s.x-2,2),Color("#baa17b"),2)

static func cargo_ship(c:Node2D,cam:Vector2,at:Vector2,angle:float,scale:float,tint:Color)->void:
 var p=at-cam+Vector2(0,sin(c.town_life.clock*1.18+at.x)*1.2)
 var hull=Vector2(122,246)*scale
 SKIFF.boat(c,"launch_blue",p,hull,angle)
 for n in 3:
  crate(c,p+Vector2(-35+n*24,-8).rotated(angle)*scale,Vector2(19,17)*scale)
 # Raised wheelhouse, trim and rope give the working boats a distinct silhouette.
 var fore=Vector2(0,-33).rotated(angle)*scale+p
 var box=Rect2(fore-Vector2(19,22)*scale,Vector2(38,27)*scale)
 c.draw_rect(Rect2(box.position+Vector2(3,5),box.size),Color("#403b32"))
 c.draw_rect(box,Color("#b6a17b"))
 c.draw_rect(Rect2(box.position+Vector2(3,2),Vector2(box.size.x-6,8*scale)),Color("#636c62"))
 for n in 2:
  c.draw_rect(Rect2(box.position+Vector2(5+n*16,11)*scale,Vector2(10,8)*scale),Color("#33555c"))
  c.draw_rect(Rect2(box.position+Vector2(5+n*16,11)*scale,Vector2(10,2)*scale),Color("#83a59c"))
 var mast=p+Vector2(0,-49)*scale
 c.draw_line(p+Vector2(0,26)*scale,mast,Color("#64533e"),5*scale)
 c.draw_colored_polygon(PackedVector2Array([mast+Vector2(-2,5)*scale,mast+Vector2(42,31)*scale,mast+Vector2(-2,31)*scale]),tint)
 c.draw_line(mast,mast+Vector2(18,4)*scale,Color("#c39e64"),3)

static var woodland:Array=[]

static func tree_clear(rect:Rect2,p:Vector2)->bool:
 if COAST.near_road(p,16) or COAST.on_dock(p):return false
 for b in BUILDINGS:
  var building:Rect2=b[1]
  if building.grow(12).intersects(rect) or Rect2(Vector2(building.position.x-34,building.end.y-22),Vector2(building.size.x+68,59)).intersects(rect):return false
 if rect.grow(20).intersects(OFFICE_FRAME):return false
 for at in [FERRY,PORT_ARRIVAL,SEA_PIER,BAIT,TRADER,SAILOR]:
  if rect.grow(18).has_point(at):return false
 for at in PORT_LAMPS:
  if rect.grow(16).has_point(at):return false
 return true

static func draw_woodland(c:Node2D,cam:Vector2,view:Rect2)->void:
 if woodland.is_empty():
  # Cliff-side pines and thicker clumps between the cottages. Tree art bounds, not just its feet, stay clear of roofs.
  var sites=[Vector2(1224,3025),Vector2(1245,3150),Vector2(1222,3330),Vector2(1238,3500),Vector2(1210,3655)]
  for row in 11:
   for col in 17:
    var n=row*17+col
    if posmod(n*17+row*5,13)<5:continue
    var p=Vector2(1235+col*59+posmod(n*73,43),2970+row*74+posmod(n*61,31))
    if not COAST.solid_land(p) or p.y>COAST.coast_at(p.x)-30:continue
    sites.append(p)
  var footprints=[]
  for i in sites.size():
   var p:Vector2=sites[i]
   var width=54+posmod(i*31,44)
   var height=70+posmod(i*43,49)
   var rect=Rect2(p-Vector2(width*.5,height-9),Vector2(width,height))
   if not tree_clear(rect,p) or footprints.any(func(q):return p.distance_to(q)<43):continue
   footprints.append(p)
   woodland.append([p,rect,["pine","pine","ancient","apple","knot_willow"][i%5]])
 for tree in woodland:
  var p:Vector2=tree[0]
  var rect:Rect2=tree[1]
  if not view.intersects(rect):continue
  c.draw_circle(p-cam,rect.size.x*.22,Color(.11,.16,.16,.16))
  NATURE.tree(c,tree[2],Rect2(rect.position-cam,rect.size),p)

static func draw_west_ridge(c:Node2D,cam:Vector2,view:Rect2,season:String)->void:
 if not view.intersects(WEST_RIDGE_HIGHLANDS):return
 var ridge=preload("res://scripts/town_art246.gd").texture("ridge")
 for n in 11:
  var y=2812.0+n*83
  var x=830+45*sin(n*1.48)+28*sin(n*.71)
  var rect=Rect2(x,y,410,260)
  if view.intersects(rect):
   c.draw_texture_rect(ridge,Rect2(rect.position-cam,rect.size),false,Color("#aab8be") if season=="Winter" else Color("#a6ada5"))
 # Overlap the previous straight raster boundary with loose boulders and shoulder shelves.
 for n in 21:
  var p=Vector2(1130+posmod(n*37,93),2880+n*43)
  if view.has_point(p):COAST.draw_shore_rocks(c,p-cam,Vector2(124+posmod(n*17,49),81))
 for row in 10:
  for col in 12:
   var index=row*12+col
   if posmod(index*173,19)<5:continue
   var p=Vector2(20+col*85+posmod(index*247,60),2910+row*96+posmod(index*413,67))
   if p.x>1015 or not view.grow(104).has_point(p):continue
   var size=Vector2(92+posmod(index*41,34),120+posmod(index*71,30))
   if index%7==0:COAST.draw_shore_rocks(c,p-cam,Vector2(85,55))
   else:NATURE.tree(c,"ancient" if index%6==0 else "pine",Rect2(p-cam-Vector2(size.x*.5,size.y-10),size),p)

static func draw_sea_office(c:Node2D,cam:Vector2,view:Rect2,season:String)->void:
 if not view.intersects(OFFICE_FRAME.grow(32)):return
 var art=preload("res://scripts/winter_buildings383.gd").texture("marina","bait_stall",season,SKIFF.texture("bait_stall"))
 var box=Rect2(OFFICE_FRAME.position-cam,OFFICE_FRAME.size)
 c.draw_texture_rect(art,box,false,Color("#c8b69b"))
 var p=SEA_OFFICE-cam
 BAY.small_sign(c,p-Vector2(0,75),"SEA EXPEDITIONS",98)
 CAST.draw(c,"Tess",p+Vector2(22,15),c.town_life.clock)

static func draw_port(c:Node2D,cam:Vector2,view:Rect2,season:String)->void:
 COAST.draw_water(c,cam,view,season)
 COAST.draw_terrain(c,cam,season)
 draw_west_ridge(c,cam,view,season)
 COAST.shore_plants(c,cam,view,season)
 draw_woodland(c,cam,view)
 for building in BUILDINGS:
  var r:Rect2=building[1]
  if not view.intersects(r):continue
  var art=NATURE.seasonal_texture(building[0],season)
  var frame=Rect2(r.position-cam,r.size)
  c.draw_texture_rect(art,frame,false)
  plaque(c,Vector2(r.get_center().x,r.end.y-10)-cam,building[2],176 if r.size.x<200 else 204)
 for p in [Vector2(1942,3726),Vector2(1968,3735),Vector2(1959,3750),Vector2(2045,3772),Vector2(1920,3668),Vector2(2090,3569),Vector2(2154,3596),Vector2(2182,3556)]:
  if view.has_point(p):
   var size=Vector2(23+posmod(int(p.x),11),27+posmod(int(p.y),9))
   c.draw_texture_rect(SKIFF.texture("cargo"),Rect2(p-cam-size*.5,size),false)
 if view.has_point(BAIT):
  var p=BAIT-cam
  var stall_rect=Rect2(p-Vector2(55,99),Vector2(110,100))
  var art=preload("res://scripts/winter_buildings383.gd").texture("marina","bait_stall",season,SKIFF.texture("bait_stall"))
  c.draw_texture_rect(art,stall_rect,false)
  plaque(c,p+Vector2(0,-88),"DOCKSIDE BAIT",135)
 for p in PORT_LAMPS:
  if view.has_point(p):preload("res://scripts/town_props240.gd").lamp(c,p-cam,c.town_life.calendar.night_amount())
 for line in [[Vector2(1602,4001),Vector2(1819,4002)],[Vector2(2210,4010),Vector2(2046,4004)]]:
  if not view.grow(25).has_point(line[1]):continue
  var a:Vector2=line[0]-cam
  var b:Vector2=line[1]-cam
  c.draw_polyline(PackedVector2Array([a,a.lerp(b,.52)+Vector2(0,9),b]),Color("#a9956f"),2.0)
 if view.has_point(Vector2(1602,4001)):cargo_ship(c,cam,Vector2(1602,4001),1.30,1.4,Color("#bfab86"))
 if view.has_point(Vector2(2210,4010)):cargo_ship(c,cam,Vector2(2210,4010),-1.34,1.22,Color("#b48b72"))
 if season!="Winter" and view.has_point(Vector2(2336,3626)):SKIFF.boat(c,"skiff_amber",Vector2(2336,3626)-cam,Vector2(62,115),1.22)
 if view.has_point(FERRY):plaque(c,FERRY-cam+Vector2(10,-31),"FERRY CLOSED" if season=="Winter" else "RIVER FERRY",146)
 draw_sea_office(c,cam,view,season)
 var cal=c.town_life.calendar
 for n in RESIDENTS.size():
  var state=resident_state(n,cal.hour,cal.weekday)
  if not state.is_empty() and view.has_point(state.pos):
   CAST.draw(c,RESIDENTS[n][1],state.pos-cam,c.town_life.clock,state.moving)
 if view.has_point(SAILOR) and cal.hour>=8 and cal.hour<20:CAST.draw(c,"guide",SAILOR-cam+Vector2(-23,1),c.town_life.clock)
 if view.has_point(BAIT) and cal.hour>=6 and cal.hour<20:CAST.draw(c,"Lio",BAIT-cam+Vector2(26,2),c.town_life.clock)
 if view.has_point(TRADER) and cal.hour>=7 and cal.hour<19:CAST.draw(c,"exchange_worker",TRADER-cam+Vector2(30,0),c.town_life.clock)

