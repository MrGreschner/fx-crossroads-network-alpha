extends VBoxContainer
## Uses the regular town modal, so its focus, close button and Escape behave as elsewhere.
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
 game=owner;rows=locations;routes=regions;groups=categories;player_position=owner.position_in_world
 name="TownAtlas"
 game.presentation.content.add_child(self)
 add_theme_constant_override("separation",8)
 var tabs:=HBoxContainer.new();tabs.add_theme_constant_override("separation",8);add_child(tabs)
 town_tab=game.presentation.button(tabs,"Town map",show_tab.bind(0))
 region_tab=game.presentation.button(tabs,"Region map",show_tab.bind(1))
 var instructions:Label=game.presentation.label(tabs,"Select a numbered pin or look up a place.",14)
 instructions.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 instructions.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
 instructions.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 instructions.modulate=Color("#b8ccbd")
 var split:=HBoxContainer.new();split.add_theme_constant_override("separation",16);add_child(split)
 canvas=MapCanvas.new()
 canvas.custom_minimum_size=Vector2(650,360)
 canvas.rows=rows;canvas.routes=routes;canvas.groups=groups;canvas.player=player_position
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
 show_tab(0)
 region_tab.grab_focus()

func show_tab(tab:int)->void:
 active_tab=tab;selected=-1
 town_tab.disabled=tab==0;region_tab.disabled=tab==1
 search.visible=tab==0;canvas.regional=tab==1
 directory.scroll_vertical=0
 refresh_list("")
 select(0 if tab==1 else -1)

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
  detail_title.text="You are here • Town Map Board"
  detail_body.text="Use the roads and numbered markers to find entrances. The bright marker shows your location."
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
 const FIELD=Rect2(-1450,-480,4690,3390)
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
  for row in rows:
   if not str(row[4]).is_empty():footprints[row[0]]=SHOPS.rect(row[4])
  var landmarks=preload("res://scripts/town_landmarks241.gd").RECTS
  for pair in [["Gladiator Arena","arena"],["Challenge Lodge","lodge"],["Crossroads Academy","academy"],["Crossroads Studio","studio"]]:
   footprints[pair[0]]=landmarks[pair[1]]
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

 func point(world:Vector2)->Vector2:
  return MAP.position+(world-FIELD.position)/FIELD.size*MAP.size

 func _gui_input(event:InputEvent)->void:
  var position_value:Vector2
  if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:position_value=event.position
  elif event is InputEventScreenTouch and event.pressed:position_value=event.position
  else:return
  var at:=position_value/size*DESIGN
  var best=-1;var distance=42.0 if regional else 18.0
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

 func pine(at:Vector2,s:float,color:Color)->void:
  polygon([at+Vector2(0,-12)*s,at+Vector2(7,3)*s,at+Vector2(-7,3)*s],color)
  draw_line(at+Vector2(0,1)*s,at+Vector2(0,6)*s,color,1)

 func compass(at:Vector2)->void:
  polygon([at+Vector2(0,-11),at+Vector2(5,8),at,at+Vector2(-5,8)],INK)
  caption(at+Vector2(-4,-15),"N",10)

 func draw_town()->void:
  caption(Vector2(19,24),"CROSSROADS  /  TOWN DIRECTORY",15)
  draw_rect(MAP,Color("#c8c7a0"))
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
  for i in rows.size():
   var row:Array=rows[i]
   var at:Vector2=pins[i]
   var anchor:=point(row[1])
   if at.distance_to(anchor)>2:draw_line(at,anchor,Color("#465b4b",.8),1,true)
   draw_circle(at,8.4,Color(groups[row[2]]),true,-1,true)
   draw_arc(at,8.4,0,TAU,18,LIGHT,1,true)
   caption(at-Vector2(5,-3),"%02d"%(i+1),9,LIGHT)
  if selected>=0:draw_arc(pins[selected],11.5,0,TAU,28,Color("#203e3b"),2,true)
  var here:=point(player)
  polygon([here+Vector2(0,-16),here+Vector2(8,-8),here,here+Vector2(-8,-8)],Color("#344d45"))
  polygon([here+Vector2(0,-13),here+Vector2(5,-8),here+Vector2(0,-3),here+Vector2(-5,-8)],Color("#fff0b6"))
  var x=20
  for category in groups:
   draw_circle(Vector2(x+4,337),4,Color(groups[category]))
   caption(Vector2(x+12,341),category,12)
   x+=103
  caption(Vector2(452,341),"◆  You are here",12)

 func draw_region()->void:
  caption(Vector2(19,24),"CROSSROADS  /  REGIONAL ROUTES",15)
  draw_rect(MAP,Color("#c5c8a0"))
  draw_rect(MAP,Color("#a79d76"),false,1)
  var sea=[Vector2(12,265),Vector2(63,259),Vector2(102,273),Vector2(151,254),Vector2(199,270),Vector2(258,274),Vector2(313,286),Vector2(376,273),Vector2(438,290),Vector2(494,280),Vector2(564,287),Vector2(638,272),Vector2(638,318),Vector2(12,318)]
  polygon(sea,Color("#7ba8a6"))
  var river=PackedVector2Array([Vector2(204,70),Vector2(215,101),Vector2(254,121),Vector2(271,145),Vector2(269,171),Vector2(247,196),Vector2(225,213),Vector2(201,232),Vector2(186,255),Vector2(203,291)])
  draw_polyline(river,Color("#678c8e"),22,true)
  draw_polyline(river,Color("#88b5b0"),16,true)
  polygon([Vector2(122,63),Vector2(145,49),Vector2(188,43),Vector2(230,48),Vector2(255,63),Vector2(263,80),Vector2(239,99),Vector2(192,108),Vector2(149,99),Vector2(126,83)],Color("#81adab"))
  for p in [Vector2(155,73),Vector2(226,63),Vector2(190,94)]:draw_circle(p,8,Color("#c7c79d"),true,-1,true)
  for i in 34:pine(Vector2(388+posmod(i*37,192),83+posmod(i*43,150)),.75+float(i%3)*.2,Color("#83966d"))
  var road=PackedVector2Array([Vector2(247,193),Vector2(276,177),Vector2(311,179),Vector2(348,165),Vector2(401,171),Vector2(461,177)])
  draw_polyline(road,Color("#a98e66"),5,true)
  draw_polyline(road,Color("#e6d4a6"),2,true)
  draw_line(Vector2(254,182),Vector2(279,176),Color("#b08557"),8,true)
  for i in 14:
   var x=22+i*42
   var y=298+posmod(i*29,13)
   draw_arc(Vector2(x,y),7,.5,2.65,8,Color("#a5cac0"),1,true)
  caption(Vector2(154,126),"UPRIVER",10)
  caption(Vector2(96,232),"DOWNRIVER",10)
  compass(Vector2(606,72))
  for i in routes.size():
   var at:Vector2=routes[i][1]
   draw_circle(at,12,Color("#425e55"),true,-1,true)
   draw_arc(at,12,0,TAU,24,LIGHT,1.5,true)
   if selected==i:draw_arc(at,16,0,TAU,24,INK,2,true)
   var title_at=at+Vector2(16,4)
   if i==3:title_at=at+Vector2(-60,31)
   if i==1:title_at=at+Vector2(59,1)
   caption(title_at,str(routes[i][0]),15)
  caption(Vector2(21,342),"Regional routes are schematic • Travel starts in town.",12)
