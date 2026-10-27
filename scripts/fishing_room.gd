extends Control
## Enterable aquarium and tackle shop, with five specimen tanks from the player's collection.
const UI=preload("res://scripts/studio_ui.gd")
const C=preload("res://scripts/fishing_catalog.gd")
var fishing:Node
var player=Vector2(490,480)
var clock=0.0
var moving=false
var hud:PanelContainer
var dialogue:PanelContainer
var sprite:Texture2D
var keeper=Vector2(860,510)
var keeper_art:Texture2D=preload("res://scripts/town_cast230.gd").texture("fishing_keeper")
func setup(owner:Node)->void:
 fishing=owner;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
 hud=PanelContainer.new();UI.apply(hud);add_child(hud)
 var col=VBoxContainer.new();hud.add_child(col);fishing.label(col,"RIPPLE & REEL • THE TOWN AQUARIUM",24)
 var row=HBoxContainer.new();col.add_child(row);UI.accent(fishing.button(row,"Talk to Bramble",talk));fishing.button(row,"Collection & cases",fishing.open_journal);fishing.button(row,"Gear & mastery",func():fishing.close_shop();fishing.open_workshop());fishing.button(row,"Storage & sales",fishing.open_sales);fishing.button(row,"Aquarium income",fishing.open_aquarium_income);fishing.button(row,"Return to town",fishing.close_shop)
func open_profile()->void:
 fishing.close_shop();fishing.game.legacy.open_page("fishing")
func talk_near()->void:
 if player.distance_to(keeper)<150:talk()
func talk()->void:
 if is_instance_valid(dialogue):dialogue.queue_free()
 dialogue=PanelContainer.new();UI.apply(dialogue);add_child(dialogue)
 var col=VBoxContainer.new();dialogue.add_child(col)
 var heading=HBoxContainer.new();col.add_child(heading)
 var portrait=TextureRect.new();portrait.texture=keeper_art;portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.custom_minimum_size=Vector2(60,72);heading.add_child(portrait)
 fishing.label(heading,"BRAMBLE • KEEPER OF RIPPLE & REEL",23)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.custom_minimum_size.y=240;col.add_child(scroll)
 var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
 var has_rod=bool(fishing.records().state().rod)
 fishing.label(body,"Every little ripple has a story. Here's a fishing rod for yours!" if not has_rod else "Welcome back, angler! Your rod and bare hook are ready. Sell catches for Glimmers, unlock the net at level 5 and baskets at level 10.",20)
 fishing.label(body,"Find bubbling water and stand at its shore marker. Press F or Cast. When the float dips and flashes, press F / Hook within the gold window. A full wait bar does not guarantee a fish. Moving or taking damage cancels a cast; combat keeps going in realms.",18)
 fishing.label(body,"Keep a fish for your collection or release it: both earn fishing XP, and immediate release grants at least 25% extra (upgradable with mastery). Use Sales to sell kept catches for Glimmers. Rare, large and trophy exhibits attract paying visitors. Open Aquarium income to see each case’s hourly rate and collect Glimmers, even after time away. Select any occupied tank to inspect its fish. Visit Fishing profile & mastery for your gear, fish bait, baskets and progression.",18)
 fishing.label(body,"Explore the town pond and river, realm waters, North Gate, and deep Descent springs. Hours, weekdays and weather change what bites. Rarity and weight are separate: even a familiar species can become a trophy.",17)
 if not has_rod:
  UI.accent(fishing.button(col,"Discover my fishing rod",func():fishing.records().unlock();dialogue.queue_free();dialogue=null))
 else:fishing.button(col,"Show my collection",func():dialogue.queue_free();dialogue=null;fishing.open_journal())
 fishing.button(col,"Back to the shop",func():dialogue.queue_free();dialogue=null)
func _process(delta:float)->void:
 clock+=delta;moving=false
 var view=get_viewport_rect().size;var hud_width=maxf(1140,hud.get_combined_minimum_size().x);var hud_fit=minf(1,(view.x-24)/hud_width);hud.size=Vector2(hud_width,108);hud.scale=Vector2.ONE*hud_fit;hud.position=Vector2((view.x-hud_width*hud_fit)*.5,10)
 if is_instance_valid(dialogue):fishing.fit_panel(dialogue,Vector2(760,560))
 if not is_instance_valid(dialogue) and not is_instance_valid(fishing.journal) and not is_instance_valid(fishing.inspector) and fishing.game.menu=="fishing_shop" and not is_instance_valid(fishing.workshop) and not is_instance_valid(fishing.aquarium_panel):
  var direction=fishing.game.mobile.movement+Input.get_vector("move_left","move_right","move_up","move_down");moving=direction.length_squared()>.01
  var candidate=(player+direction.normalized()*180*delta).clamp(Vector2(75,240),Vector2(945,586))
  if Rect2(765,425,195,115).has_point(candidate):candidate=player
  for n in 5:
   if Rect2(90+n*183,175,150,146).grow(15).has_point(candidate):candidate=player
  player=candidate
  if player.y>562 and absf(player.x-510)<55:fishing.close_shop();return
  if Input.is_action_just_pressed("interact") and player.distance_to(keeper)<115:talk()
 var id=str(fishing.game.selected_character);var pose="walk1" if int(clock*6)%2==0 else "walk2"
 sprite=fishing.game.art.get(id+"_"+(pose if moving else "idle"),fishing.game.art.get(id+"_0"))
 # Most built-in art uses sprite names, not hero IDs; do not allocate textures every frame.
 if sprite==null:
  var key=str(fishing.game.characters.get(id,{}).get("sprite",id));sprite=fishing.game.art.get(key+"_"+(pose if moving else "idle"),fishing.game.art.get(key+"_0"))
 queue_redraw()
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  if is_instance_valid(fishing.inspector):fishing.inspector.close()
  elif is_instance_valid(fishing.journal):fishing.close_journal()
  elif is_instance_valid(dialogue):dialogue.queue_free();dialogue=null
  else:fishing.close_shop()
  get_viewport().set_input_as_handled()
func text(p:Vector2,s:String,size:int=16,color:Color=Color("#e2e6d6"))->void:draw_string(UI.FONT,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func _draw()->void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("#0b202c"))
 var factor=minf(size.x/1020,size.y/660);var offset=(size-Vector2(1020,660)*factor)*.5;draw_set_transform(offset,0,Vector2.ONE*factor)
 draw_style_box(UI.box("#315966","#b9ac83",14,0),Rect2(30,135,960,480))
 draw_rect(Rect2(45,240,930,355),Color("#927b5c"))
 for y in range(240,597,27):
  draw_line(Vector2(45,y),Vector2(975,y),Color("#705e4b"),2)
  for x in range(45+(y%54)*3,970,125):draw_line(Vector2(x,y),Vector2(x,y+27),Color("#77664e"),1)
 draw_rect(Rect2(45,140,930,100),Color("#274854"));draw_line(Vector2(45,240),Vector2(975,240),Color("#c4ab7b"),6)
 var displayed:Array=[]
 for id in fishing.records().state().display:displayed.append(fishing.records().specimen(str(id)))
 var shared_scale=C.tank_scale(displayed)
 for n in 5:
  var p=Vector2(90+n*183,175);var water=Rect2(p,Vector2(150,146))
  draw_style_box(UI.box("#15353f","#bdac7d",6,0),water.grow(6));draw_rect(water,Color("#397d92"))
  draw_rect(Rect2(p+Vector2(5,125),Vector2(140,17)),Color("#b0aa80"));draw_line(p+Vector2(0,14),p+Vector2(150,14),Color("#a9d9da"),3)
  for r in 3:
   var reed=p+Vector2(12+r*13,131);draw_line(reed,reed+Vector2(sin(clock+r)*6,-25-r*5),Color("#82be9c"),4)
  for bubble in 4:
   var b=p+Vector2(116+sin(bubble)*12,128-fposmod(clock*13+bubble*29,119));draw_arc(b,2+float(bubble%2),0,TAU,10,Color(.7,.93,.94,.55),1)
  var catch=fishing.records().specimen(str(fishing.records().state().display[n]))
  if not catch.is_empty():
   var dimensions:Vector2=C.display_size(catch,shared_scale);var pos=p+Vector2(75+sin(clock*.6+n)*6,77+sin(clock+n)*4)-dimensions*.5;draw_texture_rect_region(C.texture(str(catch.species)),Rect2(pos,dimensions),C.display_region(catch))
   var name=("★ " if C.is_trophy(catch) else "")+str(C.fish()[catch.species].name);text(p+Vector2(-2,174),name,13,Color("#fae4b4"));text(p+Vector2(20,195),"%.2f kg • %d G/h" % [catch.kg,fishing.records().income.rate(catch)],14)
  else:text(p+Vector2(28,80),"Empty tank",14);text(p+Vector2(35,174),"DISPLAY "+str(n+1),14,Color("#fae4b4"))
  draw_rect(Rect2(p+Vector2(8,6),Vector2(8,112)),Color(1,1,1,.09))
 # Carved tackle counter, inset drawers, brass handles and a welcoming bear keeper.
 draw_style_box(UI.box("#35585b","#c6ad7b",5,2),Rect2(765,435,195,106))
 for n in 6:draw_line(Vector2(770+n*31,439),Vector2(770+n*31,538),Color("#2c494d"),1)
 draw_style_box(UI.box("#b78c58","#edd2a1",3,2),Rect2(752,421,218,20))
 for n in 4:
  var q=Vector2(778+(n%2)*86,451+int(n/2)*35)
  draw_style_box(UI.box("#617e77","#a7b09a",3,1),Rect2(q,Vector2(72,28)))
  draw_arc(q+Vector2(36,14),7,0,PI,12,Color("#e3c686"),2)
 preload("res://scripts/town_cast230.gd").draw(self,"fishing_keeper",keeper-Vector2(0,5),clock,false)
 text(keeper+Vector2(-38,25),"BRAMBLE",15,Color("#ffe1a7"))
 # Desk lamp, reel display, tackle wall and freshwater plants.
 draw_line(Vector2(779,417),Vector2(779,388),Color("#c9ad75"),3)
 draw_colored_polygon(PackedVector2Array([Vector2(763,392),Vector2(769,377),Vector2(789,377),Vector2(795,392)]),Color("#e5c48b"))
 draw_circle(Vector2(779,394),4,Color("#fff0b8"))
 for n in 3:
  var q=Vector2(280+n*115,432)
  draw_style_box(UI.box("#2c4c56","#a6b6a0",4,2),Rect2(q,Vector2(92,58)))
  draw_line(q+Vector2(10,47),q+Vector2(76,12),Color("#d6bb83"),2)
  draw_arc(q+Vector2(35,33),8,0,TAU,14,Color("#a1d4cf"),2)
 for pos in [Vector2(75,555),Vector2(700,535)]:
  draw_colored_polygon(PackedVector2Array([pos+Vector2(-16,0),pos+Vector2(16,0),pos+Vector2(12,25),pos+Vector2(-12,25)]),Color("#b08053"))
  for n in 5:draw_line(pos,pos+Vector2((n-2)*8,-25-absf(n-2)*6),Color("#81b396"),4)
 # Stacked float boxes and a framed harbour picture create a deliberate shop interior.
 for n in 3:
  var p=Vector2(90+n*53,435);draw_rect(Rect2(p,Vector2(48,42)),Color("#7c654e"));draw_rect(Rect2(p,Vector2(48,42)),Color("#c5a782"),false,2);draw_line(p+Vector2(0,8),p+Vector2(48,8),Color("#c5a782"),3);draw_circle(p+Vector2(24,23),7,Color("#a8cfd1"))
 draw_rect(Rect2(440,573,140,32),Color("#345764"));text(Vector2(458,595),"EXIT TO TOWN",14,Color("#ffdf9e"))
 draw_circle(player+Vector2(0,3),15,Color(0,0,0,.24))
 if sprite!=null:draw_texture_rect(sprite,Rect2(player-Vector2(25,54),Vector2(50,58)),false)
 else:draw_texture_rect(keeper_art,Rect2(player-Vector2(25,54),Vector2(50,58)),false)
 if player.distance_to(keeper)<115:text(keeper+Vector2(-47,51),"Talk / E",15,Color("#ffe1a7"))

func tank_at(local_point:Vector2)->int:
 var factor=minf(size.x/1020,size.y/660)
 if factor<=0:return -1
 var point=(local_point-(size-Vector2(1020,660)*factor)*.5)/factor
 for n in 5:
  if Rect2(Vector2(90+n*183,175),Vector2(150,146)).has_point(point):return n
 return -1
func _gui_input(event:InputEvent)->void:
 if is_instance_valid(fishing.journal) or is_instance_valid(dialogue) or is_instance_valid(fishing.inspector):return
 var pressed=event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT or event is InputEventScreenTouch and event.pressed
 if not pressed:return
 var slot=tank_at(event.position)
 if slot<0:return
 var id=str(fishing.records().state().display[slot])
 if fishing.records().specimen(id).is_empty():return
 fishing.show_catch_details(id);accept_event()
func _get_tooltip(local_point:Vector2)->String:
 var slot=tank_at(local_point)
 if slot<0:return ""
 var catch=fishing.records().specimen(str(fishing.records().state().display[slot]))
 return "Select for full fish details" if not catch.is_empty() else "Choose a kept catch to fill this tank"
