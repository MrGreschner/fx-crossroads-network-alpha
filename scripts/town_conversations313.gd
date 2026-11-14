extends RefCounted

const KEY="town_friendships"
const MAX_POINTS=12
const DATA="res://content/town_conversations313.json"
const HEIGHTS={
 "gate_0":1.10,"gate_1":.98,"gate_2":.93,"gate_3":1.07,"gate_4":.94,
 "gate_5":1.03,"gate_6":.97,"partner_5":.92,"partner_6":1.06,
 "arena_0":.94,"arena_1":1.10,"harbour_0":1.06,"harbour_1":.93,
 "barracks_0":1.07,"barracks_1":.92,"barracks_2":1.01,"north_west":1.08,"north_east":.94
}
const POSTS=[Vector2(-70,1335),Vector2(330,1335)]
const NORTH=[Vector2(715,250),Vector2(1085,250)]
const SERVICES=[
 ["elder",Vector2(740,680),75,"Guidance and town services"],
 ["bartle",Vector2(1290,635),75,"Browse supplies"],
 ["Moss",Vector2(1150,1150),70,"Browse food"],
 ["Tessa",Vector2(1960,740),70,"Healer services"],
 ["Scout_Alden",Vector2(1580,790),70,"Plan a route"],
 ["Rowan",Vector2(900,1615),70,"Seedhouse services"],
 ["reel",Vector2(2000,2020),70,"Enter Ripple & Reel"],
 ["exchange",Vector2(-815,825),64,"Open Deepwell Exchange"],
 ["mine",Vector2(-1080,800),68,"Open the mine"],
 ["market",Vector2(-180,775),68,"Enter the market"],
 ["atelier",Vector2(600,1155),68,"Browse cosmetics"],
 ["challenge",Vector2(-1030,540),68,"Open Challenge Lodge"],
 ["gather",Vector2(2800,655),68,"Open Gatherers’ Lodge"],
 ["apothecary",Vector2(-100,1680),68,"Browse brews"],
 ["tower",Vector2(2090,1165),68,"Enter Mistglass Spire"],
 ["harbour_bait",Vector2(1515,2362),61,"Browse bait"],
]
static var people:Dictionary
const TOPICS="res://content/town_topics344.json"
const CAST=preload("res://scripts/town_cast230.gd")
const UI=preload("res://scripts/studio_ui.gd")
const SHOPS=["bartle","Moss","Rowan","reel","exchange","market","atelier","apothecary","Brin","Lio"]
const PORTRAITS={"bartle":"supply_keeper","reel":"fishing_keeper","exchange":"exchange_worker","mine":"exchange_worker","market":"exchange_worker","atelier":"Tess","challenge":"guide","gather":"Hazel","apothecary":"Tessa","tower":"guide","farmer":"ox_farmer"}
const PERIODS=["morning","day","evening","night"]
static var authored:Dictionary={}
var answer:Label
var topic_list:VBoxContainer
var status:Label
var meter:ProgressBar

static func catalog()->Dictionary:
 if people.is_empty():people=JSON.parse_string(FileAccess.get_file_as_string(DATA))
 return people

static func valid(value:Variant)->bool:
 if not value is Dictionary or value.size()>catalog().size():return false
 for id in value:
  var row:Variant=value[id]
  if not catalog().has(id) or not row is Dictionary:return false
  for key in ["points","day","topics"]:
   var n:Variant=row.get(key)
   if not (n is int or n is float) or not is_finite(float(n)) or float(n)!=floorf(float(n)):return false
  if row.points<0 or row.points>MAX_POINTS or row.topics<0 or row.topics>3 or row.day<0 or row.day>10000000:return false
 return true

static func tier(points:int)->int:
 return 2 if points>=7 else (1 if points>=3 else 0)

static func record(data:Dictionary,id:String)->Dictionary:
 return data.get(KEY,{}).get(id,{"points":0,"day":0,"topics":0})

static func credit(data:Dictionary,id:String,topic:int,day:int)->bool:
 if not catalog().has(id) or topic<0 or topic>1:return false
 var row:=record(data,id).duplicate()
 if day<int(row.day):return false
 if day>int(row.day):
  row.day=day
  row.topics=0
 var mask:=1<<topic
 if (int(row.topics)&mask)!=0:return false
 row.topics=int(row.topics)|mask
 row.points=mini(MAX_POINTS,int(row.points)+1)
 if not data.has(KEY):data[KEY]={}
 data[KEY][id]=row
 return true

func nearby(g:Node)->bool:
 for entry in SERVICES:
  if g.position_in_world.distance_to(entry[1])>=float(entry[2]):continue
  if entry[0]=="reel" and g.fishing==null:continue
  if entry[0] in ["challenge","gather","apothecary"] and g.lodges==null:continue
  var id:=str(entry[0])
  if id=="harbour_bait":
   if g.marina_life==null:continue
   var hour:float=g.town_life.calendar.hour
   id="Lio" if hour<7 or hour>=20 else "Brin"
  return interact_actor(g,id,str(entry[3]))
 var best:=""
 var distance:=42.0
 var actors:=guard_positions(g)
 var time:=Time.get_ticks_msec()*.001
 var calendar:Variant=g.town_life.calendar
 var workers=preload("res://scripts/town_workers314.gd")
 if g.position_in_world.distance_squared_to(Vector2(-230,740))<300.0*300.0:
  for worker in workers.active("market",calendar.hour,calendar.weekday):actors.append([worker.id,worker.pos])
 if g.position_in_world.distance_squared_to(Vector2(550,1550))<170.0*170.0:
  for worker in workers.active("post",calendar.hour,calendar.weekday):actors.append([worker.id,worker.pos])
 if g.position_in_world.distance_squared_to(Vector2(1030,1990))<160.0*160.0:
  actors.append(["farmer",g.town_chapter.farmer_position(time)])
 actors.append(["carpenter",Vector2(1510,1710)])
 for row in actors:
  var d:float=g.position_in_world.distance_to(row[1])
  if d<distance:
   best=row[0]
   distance=d
 if best.is_empty():return false
 return interact_actor(g,best,"Ramguard Barracks" if best.begins_with("barracks_") and g.position_in_world.distance_to(g.town_v109.BARRACKS)<80 else "")

static func guard_positions(g:Node)->Array:
 var entries:Array=[]
 var scenery:Variant=g.town_scenery
 for index in scenery.routes.size():
  entries.append(["gate_"+str(index),scenery.guard_position(index)])
  if index>=5:entries.append(["partner_"+str(index),scenery._guard_at_time(index,scenery.clock-.85)+Vector2(0,18)])
 for n in 2:
  entries.append(["arena_"+str(n),POSTS[n]])
  entries.append([["north_west","north_east"][n],NORTH[n]+Vector2(0,18)])
  if g.marina_life!=null:entries.append(["harbour_"+str(n),g.marina_life.patrol(g.town_life.calendar.now,n*37).pos])
 for n in 3:entries.append(["barracks_"+str(n),g.town_v109.guard_position(n)])
 return entries

func interact_actor(g:Node,id:String,service:String="")->bool:
 if not catalog().has(id):return false
 g.hint="E • Talk to "+str(catalog()[id].name)
 if Input.is_action_just_pressed("interact"):open(g,id,service)
 return true

static func period(hour:float)->int:
 if hour>=6 and hour<11:return 0
 if hour>=11 and hour<17:return 1
 if hour>=17 and hour<22:return 2
 return 3

static func offers(id:String,day:int,weekday:int,hour:float,weather:String,points:int)->Array:
 if authored.is_empty():authored=JSON.parse_string(FileAccess.get_file_as_string(TOPICS))
 var now:=period(hour)
 var seed:=int(id.hash())+day
 # Every resident has different daily windows in each half of the schedule.
 # Working residents keep one opportunity during the hours they're on shift.
 var window:=posmod(seed,2) if now<2 else 2+posmod(seed/2,2)
 if id.begins_with("post_") or id.begins_with("market_"):window=1
 if id=="Lio":window=3 if now==3 or now==2 else 0
 if id=="Brin":window=1
 if window!=now:return []
 var date_tag:="weekend" if weekday>=5 else "midweek" if weekday in [2,3] else ""
 var time_tag:String=PERIODS[now]
 var candidates:Array=[]
 var personal_topics:Array=[]
 for entry in authored.get(id,[]):
  var tag:String=entry[0]
  if (points>=3 and tag=="friend_"+time_tag) or (points>=7 and tag=="close"):
   personal_topics.append([entry[1],entry[2]])
  elif tag==date_tag or tag==weather or tag==time_tag:
   candidates.append([entry[1],entry[2]])
 if candidates.is_empty() and personal_topics.is_empty():
  var person:Dictionary=catalog()[id]
  var personal:bool=points>=3 or posmod(seed/2+now,2)==1
  var text:String=person.personal[tier(points)] if personal else person.local
  return [[person.questions[1 if personal else 0],text]]
 var result:Array=[]
 if not candidates.is_empty():result.append(candidates[posmod(seed+now+weekday,candidates.size())])
 if not personal_topics.is_empty():result.append(personal_topics[posmod(seed+weekday,personal_topics.size())])
 elif candidates.size()>1 and posmod(seed+now,3)==0:result.append(candidates[posmod(seed+now+weekday+1,candidates.size())])
 return result

func portrait(g:Node,id:String)->Texture2D:
 if id=="elder":return g.art.get("elder_ram")
 if HEIGHTS.has(id):return CAST.texture("guard_ranged" if id=="barracks_1" else "guard_melee")
 if id.begins_with("post_"):return CAST.texture("postal_worker")
 if id.begins_with("market_"):return CAST.texture("exchange_worker")
 return CAST.texture(str(PORTRAITS.get(id,id)))

func open(g:Node,id:String,service:String="")->void:
 var person:Dictionary=catalog()[id]
 var ui:Variant=g.presentation
 ui.window(person.name,"town_conversation")
 ui.content.add_theme_constant_override("separation",9)
 var header:=HBoxContainer.new()
 header.add_theme_constant_override("separation",12)
 ui.content.add_child(header)
 var frame:=PanelContainer.new()
 frame.custom_minimum_size=Vector2(72,72)
 frame.add_theme_stylebox_override("panel",UI.box("#21404b","#52727b",8,2))
 header.add_child(frame)
 var face:=TextureRect.new()
 face.texture=portrait(g,id)
 face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 face.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 face.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 frame.add_child(face)
 var identity:=VBoxContainer.new()
 identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 identity.add_theme_constant_override("separation",1)
 header.add_child(identity)
 ui.label(identity,person.name,23).modulate=Color("#f3dda3")
 ui.label(identity,person.role,14).modulate=Color("#bbd5d5")
 status=ui.label(identity,"",13)
 meter=ProgressBar.new()
 meter.max_value=MAX_POINTS
 meter.show_percentage=false
 meter.custom_minimum_size.y=5
 meter.add_theme_stylebox_override("background",UI.box("#13262d","#13262d",2,0))
 meter.add_theme_stylebox_override("fill",UI.box("#88c2a4","#88c2a4",2,0))
 identity.add_child(meter)
 update_meter(g,id)
 if not service.is_empty():
  var action:Button=ui.button(ui.content,service,open_service.bind(g,id))
  if id in SHOPS:
   UI.accent(action)
   action.tooltip_text="Open the shop"
  action.custom_minimum_size.y=40
 answer=ui.label(ui.content,"",17)
 topic_list=VBoxContainer.new()
 topic_list.add_theme_constant_override("separation",6)
 ui.content.add_child(topic_list)
 var clock:Variant=g.town_life.calendar
 var points:=int(record(g.profile,id).points)
 var choices:=offers(id,clock.day_number,clock.weekday,clock.hour,clock.weather(),points)
 var slot:=0 if period(clock.hour)<2 else 1
 var row:=record(g.profile,id)
 var spent:=int(row.day)==int(clock.day_number) and (int(row.topics)&(1<<slot))!=0
 if choices.is_empty():
  answer.text="“I’m tied up just now. Catch me another time.”"
 elif spent:
  answer.text="“Good to see you again. We can catch up later.”"
 else:
  answer.text="What would you like to ask?"
  for choice in choices:
   var button:Button=ui.button(topic_list,choice[0],respond.bind(g,id,slot,clock.day_number,choice[1]))
   button.custom_minimum_size.y=38
   button.add_theme_font_size_override("font_size",16)
   button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
   button.tooltip_text=choice[0]

func respond(g:Node,id:String,slot:int,day:int,text:String)->void:
 if g.presentation.page!="town_conversation" or not is_instance_valid(answer):return
 if not preload("res://scripts/profile_store.gd").progression_blocked() and credit(g.profile,id,slot,day):g.save_profile()
 answer.text="“"+text+"”"
 for item in topic_list.get_children():item.hide()
 update_meter(g,id)

func update_meter(g:Node,id:String)->void:
 var points:=int(record(g.profile,id).points)
 meter.value=points
 var label:=str(["Acquaintance","Familiar face","Friend"][tier(points)])
 status.text="%s  •  %d / %d" % [label,points,MAX_POINTS]

func open_service(g:Node,id:String)->void:
 g.presentation.close()
 match id:
  "elder":g.menu="elder"
  "bartle":g.menu="supplies"
  "Moss":g.menu="food"
  "Tessa":g.menu="healer"
  "Scout_Alden":g.menu="wayfinder"
  "Rowan":g.menu="seedhouse"
  "reel":g.fishing.open_shop()
  "exchange":g.legacy.commerce.open()
  "mine":g.legacy.mine.open()
  "market":g.open_business_district()
  "atelier":g.legacy.cosmetics.open_picker()
  "challenge","gather","apothecary":g.lodges.open(id)
  "Brin","Lio":g.marina_life.open()
  "tower":g.menu="arcane_tower"
  _:g.menu="barracks"
