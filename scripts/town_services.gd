extends CanvasLayer
## Touch-friendly gardening and the local squirrel shipping desk.
var game:Node
var panel:PanelContainer
var body:VBoxContainer
var message:Label
var current:=""
var field_guide=preload("res://scripts/mistglass_book.gd").new()
var family:="orchard"
var post_art:Texture2D=preload("res://scripts/source_art.gd").texture("res://assets/squirrel_post_v93.svg")
func setup(owner:Node)->void:
 game=owner;layer=34;panel=PanelContainer.new();panel.size=Vector2(980,570);panel.visible=false;add_child(panel)
 var skin:=StyleBoxFlat.new();skin.bg_color=Color("#15363a");skin.border_color=Color("#d4b879");skin.set_border_width_all(2);skin.set_content_margin_all(20);skin.set_corner_radius_all(12);panel.add_theme_stylebox_override("panel",skin)
 body=VBoxContainer.new();body.add_theme_constant_override("separation",9);panel.add_child(body)
func text(parent:Node,value:String,size:int=17)->Label:
 var l:=Label.new();l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",size);l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l
func button(parent:Node,value:String,action:Callable)->Button:
 var b:=Button.new();b.text=value;b.custom_minimum_size.y=42;b.add_theme_font_size_override("font_size",17);b.pressed.connect(action);parent.add_child(b);return b
func close()->void:game.menu="";game.mobile.reset_controls();current="";panel.hide();game.queue_redraw()
func action(call:Callable)->void:call.call();render()
func render()->void:
 for child in body.get_children():body.remove_child(child);child.queue_free()
 var header:=HBoxContainer.new();body.add_child(header);text(header,"ROWAN'S SEEDHOUSE" if current=="seedhouse" else "TRAINING GUIDE" if current=="training_guide" else "MISTGLASS SPIRE" if current=="arcane_tower" else "RAMGUARD BARRACKS" if current=="barracks" else "SQUIRREL POST",27).size_flags_horizontal=Control.SIZE_EXPAND_FILL;button(header,"Close",close)
 if current=="arcane_tower":
  field_guide.build(game,body)
 elif current=="barracks":
  text(body,"Captain Hornby trains the ram foot soldiers and archers who defend the northern roads. Patrols keep the town safe; the battlefield guards take their orders from your upgrades.")
  text(body,"North Gate Defence: hold three roads, reinforce outposts and keep the gate standing. Battlegrounds: upgrade your own barracks and build an army with your team.",19)
  button(body,"View town defence projects",func():close();game.legacy.open_page("town"))
 elif current=="training_guide":
  text(body,"Welcome, traveller. This yard is safe: your health cannot fall below one. Dummies reset; two launchers let you practice projectile timing, and the rear target moves. The green target on the left is an ally: test healing and buffs on it. Press E nearby to reset its health and buffs.",18)
  var topics:Dictionary={"Attack styles":"Close attacks need reach and direction. Projectiles travel until collision; homing shots turn, bouncing shots seek another target. Beams, charged attacks, fields and summons each have different timing. Watch your hero's four ability cards.","Enemies and warnings":"Melee enemies close in. Ranged enemies try to keep distance. Boss circles and corridors mark where a hit is coming; step out or dodge. Training launchers fire real practice projectiles for blocks, catches and reflections.","Buffs and protection":"Orange means burn; red bleed; purple poison; blue slow; white stun. Grey pulsing shield and DR percentage mean damage reduction. Healing supports only help friendly players. Food is consumed automatically when its condition is met.","Levels and mastery":"Primary starts at level 1, secondary at 3, passive at 5 and special at 6. The yard unlocks attacks at level 10. Mastery techniques are optional alternatives, not upgrades you must equip."}
  var answers:=Label.new();answers.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;answers.custom_minimum_size.y=100;answers.text="Choose a topic, or replay the short introduction.";answers.add_theme_font_size_override("font_size",19)
  var grid:=GridContainer.new();grid.columns=2;body.add_child(grid)
  for title in topics:button(grid,str(title),func():answers.text=str(topics[title])).custom_minimum_size.x=450
  body.add_child(answers)
  button(body,"REPLAY FIRST STEPS • pick from the first nine heroes",func():close();game.enter_region("town");game.presentation.starter())
 elif current=="postoffice":
  text(body,"Pip and Acorn move supplies between Crossroads homes. Send a spare packed food for a small delivery payment, or carry your profile to another computer.")
  text(body,"Packed food: "+game.provisions.name_of(game.provisions.packed)+" • Parcels delivered: "+str(game.provisions.parcels),21)
  button(body,"Send packed food • receive 6 CC",func():action(game.provisions.ship)).disabled=game.provisions.packed.is_empty()
  button(body,"Download my player profile",func():close();game.legacy.open_page("profile");game.legacy.export_profile())
  button(body,"Upload a saved profile",func():close();game.legacy.open_page("profile");game.legacy.pick_import())
  text(body,"Profile files travel with you. This post office does not upload your data or share rankings online.",16)
 else:
  var pr=game.provisions
  button(header,"Fish bait recipes",func():close();game.fishing.open_workshop())
  text(body,"CC: "+str(game.gold)+" • Packed: "+pr.name_of(pr.packed)+" • One crop at a time. Clear an adventure to ripen it.",17)
  var crop_text:="No crop planted" if pr.crop=="empty" else str(pr.garden[pr.garden_id].name)+" • "+("Ready to harvest!" if pr.crop=="ready" else "Growing • needs an adventure clear")
  var row:=HBoxContainer.new();body.add_child(row);text(row,crop_text,18).size_flags_horizontal=Control.SIZE_EXPAND_FILL
  button(row,"Harvest",func():action(pr.harvest)).disabled=pr.crop!="ready"
  button(row,"Refund packed food",func():action(pr.refund)).disabled=pr.packed.is_empty()
  var tabs:=HBoxContainer.new();body.add_child(tabs)
  for key in ["orchard","river","roots","flowers"]:
   var b:=button(tabs,key.capitalize()+" • "+str(pr.harvests.get(key,0))+" harvests",func():family=key;render());b.toggle_mode=true;b.set_pressed_no_signal(family==key);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;body.add_child(scroll)
  var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(grid)
  for id in pr.garden:
   var spec:Dictionary=pr.garden[id]
   if str(spec.family)!=family:continue
   var card:=PanelContainer.new();card.custom_minimum_size=Vector2(445,245);grid.add_child(card)
   var skin:=StyleBoxFlat.new();skin.bg_color=Color("#24484a");skin.set_content_margin_all(12);skin.set_corner_radius_all(8);card.add_theme_stylebox_override("panel",skin)
   var col:=VBoxContainer.new();card.add_child(col);text(col,str(spec.name),20).modulate=Color("#e9cf94")
   growth_strip(col,str(id),(2 if pr.crop=="ready" else 1) if pr.crop!="empty" and str(pr.garden_id)==str(id) else -1)
   text(col,"Grows "+pr.name_of(str(spec.food))+" • "+str(pr.defs[spec.food].description),15)
   var unlocked:bool=pr.unlocked(str(id));var b:=button(col,"Plant • "+str(int(spec.cost))+" CC" if unlocked else "Find a rare seed at Gatherers’ Lodge" if bool(spec.get("rare",false)) else "Unlock at "+str(spec.need)+" family harvests",func():action(pr.plant.bind(str(id))));b.disabled=not unlocked or pr.crop!="empty"
  text(body,"Each family unlocks seeds after 1, 3 and 6 harvests. Rare gathering seeds unlock four extra garden-only crops.",15)
 message=text(body,game.message if game.message_time>0 else "",16);message.modulate=Color("#e7d79b")
func growth_strip(parent:Node,id:String,selected:int)->void:
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",8);parent.add_child(row)
 for stage in 3:
  var frame=PanelContainer.new();frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  frame.add_theme_stylebox_override("panel",preload("res://scripts/studio_ui.gd").box("#203d42","#e2c383" if selected==stage else "#4e7170",6,2 if selected==stage else 1));row.add_child(frame)
  var column=VBoxContainer.new();frame.add_child(column)
  var icon=TextureRect.new();icon.texture=preload("res://scripts/source_art.gd").texture("res://assets/seedhouse/"+id+"_"+str(stage)+".svg");icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.custom_minimum_size=Vector2(100,74);column.add_child(icon)
  var caption=text(column,["Seeds","Growing","Harvest"][stage]+(" • now" if selected==stage else ""),13);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
func _process(_delta:float)->void:
 if game.menu=="seedhouse":panel.hide();current="";game.legacy.gardening.open();return
 var wanted:String=game.menu if (game.mode=="town" and game.menu in ["seedhouse","postoffice","arcane_tower","barracks"] or game.practice and game.menu=="training_guide") else ""
 panel.visible=not wanted.is_empty()
 if wanted.is_empty():current="";return
 if wanted!=current:
  current=wanted
  if current=="training_guide":game.message_time=0
  render()
 message.text=game.message if game.message_time>0 else ""
 panel.size=Vector2(980,570);var view:=get_viewport().get_visible_rect().size;var f:=minf(1,minf((view.x-24)/980,(view.y-24)/570));panel.scale=Vector2.ONE*f;panel.position=(view-panel.size*panel.scale)*.5
func _unhandled_input(event:InputEvent)->void:
 if panel.visible and event is InputEventKey and event.pressed and event.keycode in [KEY_ESCAPE,KEY_ENTER]:close();get_viewport().set_input_as_handled()
func draw_post(c:Node2D,camera:Vector2,font:Font)->void:
 if not Rect2(camera,c.VIEW).intersects(Rect2(350,1220,420,390)):return
 var origin:Vector2=Vector2(550,1490)-camera;var t=Time.get_ticks_msec()/1000.0
 preload("res://scripts/town_sprite_cache.gd").draw(c,"post",Rect2(Vector2(350,1220)-camera,Vector2(420,390)))
 for n in 2:
  var phase:=fposmod(t*.12+n*.5,1);var p:=origin+Vector2(-70+140*phase,52+sin(phase*PI)*10)
  c.draw_circle(p+Vector2(-12,-15),13,Color("#9a6548"));c.draw_circle(p+Vector2(-10,-20),8,Color("#ba8555"));c.draw_rect(Rect2(p+Vector2(-7,-20),Vector2(16,24)),Color("#618687"));c.draw_circle(p+Vector2(1,-28),10,Color("#ba8555"));c.draw_circle(p+Vector2(-4,-38),4,Color("#ba8555"));c.draw_circle(p+Vector2(8,-38),4,Color("#ba8555"));c.draw_circle(p+Vector2(6,-30),2,Color("#28323a"))
  for side in [-1,1]:c.draw_rect(Rect2(p+Vector2(side*5-2,2+sin(t*6+n)*2),Vector2(5,6)),Color("#473e38"))
  c.draw_rect(Rect2(p+Vector2(5,-15),Vector2(15,14)),Color("#c69d68"));c.draw_line(p+Vector2(12,-15),p+Vector2(12,-1),Color("#e2cc9c"),2)

func draw_post_structure(c:Node2D,camera:Vector2,font:Font)->void:
 var origin:Vector2=Vector2(550,1490)-camera
 # Sorting courtyard stays beneath the architecture and moving postal workers.
 c.draw_rect(Rect2(origin+Vector2(-138,-5),Vector2(290,76)),Color("#9f926e"))
 for row in 3:
  for col in 10:
   c.draw_rect(Rect2(origin+Vector2(-133+col*28+(10 if row%2 else 0),row*20),Vector2(25,17)),Color("#b5a786") if (row+col)%3 else Color("#a19578"))
 c.draw_texture_rect(post_art,Rect2(origin+Vector2(-180,-242),Vector2(360,285)),false)
 c.draw_string(font,origin+Vector2(-75,-119),"SQUIRREL POST",HORIZONTAL_ALIGNMENT_CENTER,150,13,Color("#f1d497"))
 # Two dispatch rails and a small parcel cart, clear of the entrance.
 for side in [-1,1]:
  var rail:=origin+Vector2(side*142,64)
  c.draw_line(rail+Vector2(-27,0),rail+Vector2(27,0),Color("#8b7250"),5)
  for x in [-27,27]:c.draw_line(rail+Vector2(x,-13),rail+Vector2(x,13),Color("#715c43"),5)
 var cart:=origin+Vector2(-111,38)
 c.draw_rect(Rect2(cart,Vector2(38,18)),Color("#92704c"));c.draw_line(cart+Vector2(38,6),cart+Vector2(54,-3),Color("#685740"),3)
 for x in [7,30]:c.draw_circle(cart+Vector2(x,21),6,Color("#354849"));c.draw_circle(cart+Vector2(x,21),2,Color("#b59b6a"))

func draw_garden(c:Node2D,camera:Vector2)->void:
 if not Rect2(camera,c.get_viewport_rect().size).grow(70).has_point(Vector2(1040,1620)):return
 var gardening=game.legacy.gardening;var beds=gardening.state().beds
 for i in mini(2,gardening.capacity()):
  var at=Vector2(1040+(i%2)*100,1620+int(i/2)*74)-camera
  c.draw_style_box(preload("res://scripts/studio_ui.gd").box("#5a4938","#c3aa78",5,2),Rect2(at-Vector2(38,13),Vector2(76,31)))
  if beds[i].is_empty():continue
  var b=beds[i];var stage=2 if gardening.now()>=float(b.end) else 1
  var art=preload("res://scripts/source_art.gd").texture("res://assets/seedhouse/"+str(b.seed)+"_"+str(stage)+".svg")
  if art!=null:c.draw_texture_rect(art,Rect2(at-Vector2(56,99),Vector2(112,105)),false)
