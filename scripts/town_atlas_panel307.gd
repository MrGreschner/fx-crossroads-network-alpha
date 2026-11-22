extends VBoxContainer
## Uses the regular town modal, so its focus, close button and Escape behave as elsewhere.
const DATA=preload("res://scripts/atlas_data377.gd")
const ART=preload("res://scripts/atlas_art377.gd")
var base_rows:Array=[]
var area="town"
var area_menu:OptionButton
var local_button:Button
var game:Node
var rows:Array
var routes:Array
var groups:Dictionary
var player_position:Vector2
var canvas:Control
var town_tab:Button
var region_tab:Button
var search:LineEdit
var list:VBoxContainer
var directory:ScrollContainer
var detail_title:Label
var detail_body:Label
var active_tab=0
var selected=-1

func setup(owner:Node,locations:Array,regions:Array,categories:Dictionary)->void:
 game=owner;base_rows=locations;rows=locations;routes=regions;groups=categories;player_position=owner.position_in_world
 name="TownAtlas"
 game.presentation.content.add_child(self)
 add_theme_constant_override("separation",8)
 var tabs:=HBoxContainer.new();tabs.add_theme_constant_override("separation",8);add_child(tabs)
 town_tab=game.presentation.button(tabs,"Town map",show_tab.bind(0))
 region_tab=game.presentation.button(tabs,"Region map",show_tab.bind(1))
 area_menu=OptionButton.new();area_menu.name="AtlasArea";area_menu.custom_minimum_size=Vector2(190,42);tabs.add_child(area_menu)
 for title in DATA.TITLES:area_menu.add_item(title)
 area_menu.item_selected.connect(func(index:int):set_area(DATA.AREAS[index]))
 var instructions:Label=game.presentation.label(tabs,"Tap a pin or search the local directory.",14)
 instructions.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 instructions.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 instructions.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 instructions.modulate=Color("#b8ccbd")
 var split:=HBoxContainer.new();split.add_theme_constant_override("separation",16);add_child(split)
 canvas=MapCanvas.new()
 canvas.custom_minimum_size=Vector2(650,360)
 canvas.rows=rows;canvas.routes=routes;canvas.groups=groups;canvas.player=player_position;canvas.season=game.town_life.calendar.season()
 canvas.picked.connect(select)
 split.add_child(canvas)
 var sidebar:=VBoxContainer.new();sidebar.add_theme_constant_override("separation",6)
 sidebar.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 split.add_child(sidebar)
 search=LineEdit.new();search.name="SearchBuildings";search.placeholder_text="Find a building or landmark"
 search.custom_minimum_size.y=34
 search.text_changed.connect(refresh_list);sidebar.add_child(search)
 directory=ScrollContainer.new();directory.name="BuildingDirectory"
 directory.custom_minimum_size.y=194
 directory.size_flags_vertical=Control.SIZE_EXPAND_FILL
 directory.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 preload("res://scripts/touch_list_scroll.gd").attach(directory)
 sidebar.add_child(directory)
 list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 list.add_theme_constant_override("separation",3);directory.add_child(list)
 detail_title=game.presentation.label(sidebar,"",17)
 detail_title.modulate=Color("#f3db9f")
 detail_body=game.presentation.label(sidebar,"",14)
 detail_body.custom_minimum_size.y=70
 detail_body.modulate=Color("#d5e3da")
 local_button=game.presentation.button(sidebar,"View local map",view_local);local_button.custom_minimum_size.y=32;local_button.add_theme_font_size_override("font_size",14)
 show_tab(0)
 town_tab.grab_focus()

func show_tab(tab:int)->void:
 active_tab=tab;selected=-1
 for i in 2:
  var button:Button=town_tab if i==0 else region_tab
  var style=StyleBoxFlat.new();style.bg_color=Color("#365e69") if tab==i else Color("#172a2e")
  style.border_color=Color("#e5cc87") if tab==i else Color("#4e7077");style.set_border_width_all(2 if tab==i else 1);style.set_corner_radius_all(5)
  style.content_margin_left=12;style.content_margin_right=12
  button.add_theme_stylebox_override("normal",style);button.add_theme_stylebox_override("hover",style)
  button.add_theme_color_override("font_color",Color("#fff0c0") if tab==i else Color("#bdd0ce"))
 search.visible=tab==0;area_menu.visible=tab==0;local_button.visible=tab==1;canvas.regional=tab==1
 directory.scroll_vertical=0
 refresh_list("")
 select(0 if tab==1 else -1)

func set_area(value:String)->void:
 if value not in DATA.AREAS:return
 area=value;area_menu.select(DATA.AREAS.find(area));rows=DATA.locations(game,area,base_rows)
 canvas.area=area;canvas.rows=rows;canvas.rebuild()
 if is_instance_valid(search):search.text=""
 show_tab(0)
func view_local()->void:
 var index=selected
 set_area(DATA.route_area(maxi(0,index)))
 if index==3:
  for n in rows.size():
   if rows[n][0]=="Wayfarer Wilds trail":select(n);break

func refresh_list(_query:String)->void:
 for item in list.get_children():
  list.remove_child(item);item.queue_free()
 var entries=routes if active_tab==1 else rows
 var query="" if active_tab==1 else search.text.strip_edges().to_lower()
 for i in entries.size():
  var row:Array=entries[i]
  if not query.is_empty() and query not in (str(row[0])+" "+str(row[2])).to_lower():continue
  var title=str(row[0]) if active_tab==1 else "%02d  %s" % [i+1,row[0]]
  var button:Button=game.presentation.button(list,title,select.bind(i))
  button.name="AtlasEntry%d"%i
  button.custom_minimum_size.y=29
  button.add_theme_font_size_override("font_size",14)
  button.alignment=HORIZONTAL_ALIGNMENT_LEFT
  button.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
  button.tooltip_text=row[0]
 if list.get_child_count()==0:game.presentation.label(list,"No places match that search.",14)

func select(index:int)->void:
 selected=index;canvas.selected=index;canvas.queue_redraw()
 if index<0:
  detail_title.text=DATA.TITLES[DATA.AREAS.find(area)]+" • Local directory"
  detail_body.text="Pins follow actual entrances, piers and paths. Choose a pin for directions. Your marker appears when you are in this area."
 elif active_tab==1:
  var route:Array=routes[index]
  detail_title.text=route[0]
  detail_body.text="%s\n%s" % [route[2],route[3]]
 else:
  var row:Array=rows[index]
  detail_title.text=row[0]
  detail_body.text="%s\n%s" % [row[2],row[3]]
 if index>=0:reveal_selection.call_deferred(active_tab,index)

func reveal_selection(tab:int,index:int)->void:
 if active_tab!=tab or selected!=index:return
 var item=list.get_node_or_null("AtlasEntry%d"%index)
 if item!=null:directory.ensure_control_visible(item)

class MapCanvas extends Control:
 signal picked(index:int)
 const DATA=preload("res://scripts/atlas_data377.gd")
 const ART=preload("res://scripts/atlas_art377.gd")
 var area="town"
 var season="Summer"
 const DESIGN=Vector2(650,360)
 const MAP=Rect2(12,32,626,286)
 const INK=Color("#344d45")
 const LIGHT=Color("#fff4cf")
 const SHOPS=preload("res://scripts/town_shops242.gd")
 var rows:Array=[]
 var routes:Array=[]
 var groups:Dictionary={}
 var player:Vector2
 var regional=false
 var selected=-1
 var pins:Array[Vector2]=[]
 var footprints:Dictionary={}

 func _ready()->void:
  mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
  clip_contents=true;rebuild()

 func rebuild()->void:
  pins.clear();footprints=DATA.footprints(area)
  for row in rows:
   if area=="town" and not str(row[4]).is_empty():footprints[row[0]]=SHOPS.rect(row[4])
  var landmarks=preload("res://scripts/town_landmarks241.gd").RECTS
  for pair in ([] if area!="town" else [["Gladiator Arena","arena"],["Challenge Lodge","lodge"],["Crossroads Academy","academy"],["Crossroads Studio","studio"]]):
   footprints[pair[0]]=landmarks[pair[1]]
  if area=="town":
   for home in preload("res://scripts/town_neighborhood.gd").HOMES:footprints[home.name]=home.wall
  for row in rows:
   var anchor:=point(row[1])
   var chosen:=anchor
   for ring in 6:
    for angle in (1 if ring==0 else 12):
     var candidate:=anchor+Vector2.from_angle(angle*TAU/12+ring*.2)*ring*8
     if not MAP.grow(-11).has_point(candidate):continue
     if pins.any(func(other):return candidate.distance_to(other)<19):continue
     chosen=candidate
     break
    if not pins.any(func(other):return chosen.distance_to(other)<19):break
   pins.append(chosen)

 func field()->Rect2:return DATA.FIELDS[area]
 func point(at:Vector2)->Vector2:
  var f=field();return MAP.position+(at-f.position)/f.size*MAP.size
 func world(at:Vector2)->Vector2:
  var f=field();return f.position+(at-MAP.position)/MAP.size*f.size

 func _gui_input(event:InputEvent)->void:
  var position_value:Vector2
  if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:position_value=event.position
  elif event is InputEventScreenTouch and event.pressed:position_value=event.position
  else:return
  var at:=position_value/size*DESIGN
  var best=-1;var distance=28.0 if regional else 18.0
  for i in (routes.size() if regional else pins.size()):
   var marker:Vector2=routes[i][1] if regional else pins[i]
   if at.distance_to(marker)<distance:best=i;distance=at.distance_to(marker)
  if best>=0:picked.emit(best);accept_event()

 func _draw()->void:
  draw_set_transform(Vector2.ZERO,0,size/DESIGN)
  var frame:=StyleBoxFlat.new()
  frame.bg_color=Color("#e5d8ae");frame.border_color=Color("#b7a16e")
  frame.set_border_width_all(2);frame.set_corner_radius_all(8)
  draw_style_box(frame,Rect2(Vector2.ZERO,DESIGN))
  if regional:draw_region()
  else:draw_town()

 func caption(at:Vector2,value:String,font_size:int=13,color:Color=INK)->void:
  draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

 func polygon(points:Array,color:Color)->void:
  draw_colored_polygon(PackedVector2Array(points),color)

 func pine(at:Vector2,s:float,_color:Color)->void:ART.tree(self,at,s*.85)

 func compass(at:Vector2)->void:
  polygon([at+Vector2(0,-11),at+Vector2(5,8),at,at+Vector2(-5,8)],INK)
  caption(at+Vector2(-4,-15),"N",10)

 func draw_town()->void:
  caption(Vector2(19,24),DATA.TITLES[DATA.AREAS.find(area)].to_upper()+"  /  LOCAL MAP",14)
  if area!="town":
   ART.local(self);draw_pins();return
  ART.land(self)
  draw_rect(MAP,Color("#a79d76"),false,1)
  var river:=Rect2(point(Vector2(2280,-480)),point(Vector2(2440,2910))-point(Vector2(2280,-480)))
  draw_rect(river,Color("#6b9da0"))
  for y in range(45,310,22):
   draw_line(Vector2(river.position.x+4,y),Vector2(river.end.x-6,y+4),Color("#9bc1b5"),1,true)
  var pond:=point(Vector2(200,365))
  polygon([pond+Vector2(-29,2),pond+Vector2(-17,-9),pond+Vector2(6,-11),pond+Vector2(27,-4),pond+Vector2(24,7),pond+Vector2(-4,11)],Color("#739da0"))
  for i in 33:
   var t:=Vector2(524+posmod(i*43,97),97+posmod(i*59,195))
   pine(t,.65+float(i%4)*.13,Color("#829468"))
  for i in 11:
   var t:=point(Vector2(-1370+i*6,580+i*64))
   polygon([t+Vector2(-6,6),t+Vector2(4,-9),t+Vector2(20,6)],Color("#8f9080"))
  var marina=preload("res://scripts/town_marina.gd")
  var inlet:=PackedVector2Array()
  for p in marina.WATER:inlet.append(point(p))
  draw_colored_polygon(inlet,Color("#719fa1"))
  for route in preload("res://scripts/town_plan.gd").ROADS+preload("res://scripts/town_neighborhood.gd").ROADS:
   var road:=PackedVector2Array()
   for p in route:road.append(point(p))
   draw_polyline(road,Color("#b2a580"),5,true)
   draw_polyline(road,Color("#e5d5ac"),2.5,true)
  for world in marina.DECKS:
   draw_rect(Rect2(point(world.position),point(world.end)-point(world.position)),Color("#a5865f"))
  for row in rows:
   if not footprints.has(row[0]):continue
   var world:Rect2=footprints[row[0]]
   var box:=Rect2(point(world.position),point(world.end)-point(world.position))
   var roof=Color("#758778") if row[2]=="Homes" else Color("#788c83")
   if row.size()>5 and str(row[3]).ends_with("Planned site."):roof=Color("#a99878")
   draw_rect(box,roof);draw_rect(box,Color("#686d5e"),false,1)
   draw_line(box.position+Vector2(2,box.size.y*.45),box.position+Vector2(box.size.x-2,box.size.y*.45),roof.lightened(.28),1)
  compass(Vector2(608,71))
  draw_pins()

 func draw_pins()->void:
  for i in rows.size():
   var row:Array=rows[i]
   var at:Vector2=pins[i]
   var anchor:=point(row[1])
   if at.distance_to(anchor)>2:draw_line(at,anchor,Color("#465b4b",.8),1,true)
   draw_circle(at,8.4,Color(groups[row[2]]),true,-1,true)
   draw_arc(at,8.4,0,TAU,18,LIGHT,1,true)
   caption(at-Vector2(5,-3),"%02d"%(i+1),9,LIGHT)
  if selected>=0 and selected<pins.size():draw_arc(pins[selected],11.5,0,TAU,28,Color("#203e3b"),2,true)
  var here:=point(player) if field().has_point(player) else Vector2(-100,-100)
  polygon([here+Vector2(0,-16),here+Vector2(8,-8),here,here+Vector2(-8,-8)],Color("#344d45"))
  polygon([here+Vector2(0,-13),here+Vector2(5,-8),here+Vector2(0,-3),here+Vector2(-5,-8)],Color("#fff0b6"))
  var x=20
  var present=[]
  for row in rows:
   if row[2] not in present:present.append(row[2])
  for category in present:
   draw_circle(Vector2(x+4,337),4,Color(groups[category]))
   caption(Vector2(x+12,341),category,11)
   x+=94
  caption(Vector2(514,341),"◆ You",11)

 func draw_region()->void:
  caption(Vector2(19,24),"CROSSROADS  /  WATERWAYS & TRAILS",14)
  ART.region(self)
  caption(Vector2(20,337),"Solid: walking trail   •   Gold dashes: waypoint connection   •   Blue dashes: ferry",10)
  caption(Vector2(20,351),"Regional chart • not to scale. "+("River ferries and lake boats pause in winter." if season=="Winter" else "Walking routes remain available throughout the year."),10)
