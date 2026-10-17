extends Control
## Enterable aquarium and tackle shop, with five specimen tanks from the player's collection.
const UI=preload("res://scripts/studio_ui.gd")
const C=preload("res://scripts/fishing_catalog.gd")
var fishing:Node
var player=Vector2(490,480)
var touch_move=Vector2.ZERO
var clock=0.0
var moving=false
var hud:PanelContainer
var dialogue:PanelContainer
var touch:HBoxContainer
var interact:Button
var sprite:Texture2D
var keeper=Vector2(860,510)
var keeper_art:Texture2D=preload("res://assets/ram_idle.png")
func setup(owner:Node)->void:
 fishing=owner;set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_STOP
 hud=PanelContainer.new();UI.apply(hud);add_child(hud)
 var col=VBoxContainer.new();hud.add_child(col);fishing.label(col,"RIPPLE & REEL • THE TOWN AQUARIUM",24)
 var row=HBoxContainer.new();col.add_child(row);UI.accent(fishing.button(row,"Talk to Marina",talk));fishing.button(row,"Catches & display tanks",fishing.open_journal);fishing.button(row,"Return to town",fishing.close_shop)
 touch=HBoxContainer.new();UI.apply(touch);add_child(touch)
 for pair in [["←",Vector2.LEFT],["↑",Vector2.UP],["↓",Vector2.DOWN],["→",Vector2.RIGHT]]:
  var b=fishing.button(touch,pair[0],func():pass);b.custom_minimum_size=Vector2(58,52);b.button_down.connect(func():touch_move=pair[1]);b.button_up.connect(func():touch_move=Vector2.ZERO)
 interact=fishing.button(touch,"Talk / E",talk_near);interact.custom_minimum_size=Vector2(120,52)
func talk_near()->void:
 if player.distance_to(keeper)<150:talk()
func talk()->void:
 if is_instance_valid(dialogue):dialogue.queue_free()
 dialogue=PanelContainer.new();UI.apply(dialogue);add_child(dialogue)
 var col=VBoxContainer.new();dialogue.add_child(col);fishing.label(col,"MARINA • KEEPER OF RIPPLE & REEL",23)
 var has_rod=bool(fishing.records().state().rod)
 fishing.label(col,"Every little ripple has a story. Here's a fishing rod for yours!" if not has_rod else "Welcome, angler! Your rod and bare hook are ready. Sell catches for Glimmers; unlock a net at level 5 and baskets at level 10.",20)
 fishing.label(col,"Find bubbling water. Stand near the shore marker and press F or the Cast button. A bite can happen early or late, or not at all. When the float dips and flashes three times, press F / Hook within 2.4 seconds. A full wait bar is not a guaranteed fish. Moving or taking damage cancels a cast — combat keeps going in realms. Keep a fish for a tank, or release it; both reveal it in your journal. Choose a favourite catch for your player card.",17)
 fishing.label(col,"The pond has eight species, and the river has sixteen. Explore Wayfarer, Silverfall Reach, Folded Coast, Lantern Marsh and Moonveil Masquerade for other waters. North Gate has a riverbank fishing spot; buried springs appear on Descent floors 38 and 56. Combat continues while you fish. Rarity and weight are separate: even a familiar fish can grow into a trophy.",16)
 if not has_rod:
  UI.accent(fishing.button(col,"Discover my fishing rod",func():fishing.records().unlock();dialogue.queue_free();dialogue=null))
 else:fishing.button(col,"Show my collection",func():dialogue.queue_free();dialogue=null;fishing.open_journal())
 fishing.button(col,"Back to the shop",func():dialogue.queue_free();dialogue=null)
func _process(delta:float)->void:
 clock+=delta
 var view=get_viewport_rect().size;var hud_fit=minf(1,(view.x-24)/980);hud.size=Vector2(980,108);hud.scale=Vector2.ONE*hud_fit;hud.position=Vector2((view.x-980*hud_fit)*.5,10)
 interact.disabled=player.distance_to(keeper)>=150
 touch.position=Vector2(14,view.y-65);touch.visible=not is_instance_valid(dialogue) and not is_instance_valid(fishing.journal)
 if is_instance_valid(dialogue):fishing.fit_panel(dialogue,Vector2(720,430))
 if not is_instance_valid(dialogue) and not is_instance_valid(fishing.journal):
  var direction=touch_move+Input.get_vector("move_left","move_right","move_up","move_down");moving=direction.length_squared()>.01
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
  if is_instance_valid(fishing.journal):fishing.close_journal()
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
   var dimensions:Vector2=C.display_size(catch);var pos=p+Vector2(75+sin(clock*.6+n)*6,77+sin(clock+n)*4)-dimensions*.5;draw_texture_rect(C.texture(str(catch.species)),Rect2(pos,dimensions),false)
   var name=("★ " if C.is_trophy(catch) else "")+str(C.fish()[catch.species].name);text(p+Vector2(-2,174),name,13,Color("#fae4b4"));text(p+Vector2(20,195),"%.2f kg" % catch.kg,14)
  else:text(p+Vector2(28,80),"Empty tank",14);text(p+Vector2(35,174),"DISPLAY "+str(n+1),14,Color("#fae4b4"))
  draw_rect(Rect2(p+Vector2(8,6),Vector2(8,112)),Color(1,1,1,.09))
 # Nautical counter, tackle drawers and the keeper.
 draw_rect(Rect2(765,433,195,104),Color("#4e6769"));draw_rect(Rect2(752,421,218,20),Color("#cfb185"))
 for n in 4:draw_rect(Rect2(777+(n%2)*85,454+int(n/2)*33,70,26),Color("#849288"));draw_circle(Vector2(812+(n%2)*85,467+int(n/2)*33),3,Color("#e2c891"))
 draw_texture_rect(keeper_art,Rect2(keeper-Vector2(27,79),Vector2(54,70)),false)
 draw_rect(Rect2(keeper+Vector2(-13,-75),Vector2(26,8)),Color("#567b8a"));draw_line(keeper+Vector2(-18,-67),keeper+Vector2(18,-67),Color("#c5d2b7"),3)
 draw_rect(Rect2(keeper+Vector2(-10,-24),Vector2(20,15)),Color("#547a86"));draw_circle(keeper+Vector2(6,-20),2,Color("#edce89"))
 draw_line(keeper+Vector2(30,-18),keeper+Vector2(48,-82),Color("#c5ab80"),3);draw_line(keeper+Vector2(48,-82),keeper+Vector2(73,-4),Color("#a9d2ce"),1)
 text(keeper+Vector2(-33,23),"MARINA",15,Color("#ffe1a7"))
 # Stacked float boxes and a framed harbour picture create a deliberate shop interior.
 for n in 3:
  var p=Vector2(90+n*53,435);draw_rect(Rect2(p,Vector2(48,42)),Color("#7c654e"));draw_rect(Rect2(p,Vector2(48,42)),Color("#c5a782"),false,2);draw_line(p+Vector2(0,8),p+Vector2(48,8),Color("#c5a782"),3);draw_circle(p+Vector2(24,23),7,Color("#a8cfd1"))
 draw_rect(Rect2(440,573,140,32),Color("#345764"));text(Vector2(458,595),"EXIT TO TOWN",14,Color("#ffdf9e"))
 draw_circle(player+Vector2(0,3),15,Color(0,0,0,.24))
 if sprite!=null:draw_texture_rect(sprite,Rect2(player-Vector2(25,54),Vector2(50,58)),false)
 else:draw_texture_rect(keeper_art,Rect2(player-Vector2(25,54),Vector2(50,58)),false)
 if player.distance_to(keeper)<115:text(keeper+Vector2(-47,51),"Talk / E",15,Color("#ffe1a7"))
