extends Node
## Local collection activity. Realm combat and host simulation never pause for a cast.
const C=preload("res://scripts/fishing_catalog.gd")
const UI=preload("res://scripts/studio_ui.gd")
const SHOP=Vector2(2000,2020)
const SHOP_SOLID=Rect2(1850,1760,300,215)
var game:Node
var multi=false
var rng=RandomNumberGenerator.new()
var clock=0.0
var cached_region=""
var spots:Array=[]
var phase=""
var cast_spot:Dictionary={}
var cast_pos=Vector2.ZERO
var cast_hp=0.0
var cast_region=""
const BITE_WINDOW=2.4
var bite_at=-1.0
var timer=0.0
var pending:Dictionary={}
var hud:CanvasLayer
var panel:PanelContainer
var title:Label
var detail:Label
var cast_button:Button
var meter:ProgressBar
var catch_frame:PanelContainer
var catch_text:Label
var journal:CanvasLayer
var journal_panel:PanelContainer
var room_layer:CanvasLayer
var room:Control
var journal_page=0
var status=""
var modal_previous=""
var seen_menu=""
func setup(owner:Node,is_multi:bool=false)->void:
 game=owner;multi=is_multi;rng.randomize()
 hud=CanvasLayer.new();hud.layer=58;add_child(hud)
 panel=PanelContainer.new();UI.apply(panel);panel.custom_minimum_size=Vector2(360,0);hud.add_child(panel)
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",6);panel.add_child(col)
 title=label(col,"",18);detail=label(col,"",14)
 meter=ProgressBar.new();meter.custom_minimum_size.y=10;meter.show_percentage=false;col.add_child(meter)
 cast_button=button(col,"F • Cast",activate);UI.accent(cast_button);panel.visible=false
func records():return game.legacy.fishing_records
func local_pos()->Vector2:return game.local_pos if multi else game.position_in_world
func local_hp()->float:return float(game.health.get(game.my_id,0)) if multi else float(game.health)
func region_key()->String:
 if multi:
  if not game.started or game.start_countdown>0 or game.spectating():return ""
  if game.mode=="descent" and game.floor_number in [38,56]:return "descent"+str(game.floor_number)
  if game.mode=="defense":return "defense"
  return "wayfarer" if game.mode=="quest" else str(game.realm_id) if game.mode=="coop" else ""
 if game.mode=="town":return "town"
 if game.mode!="run" or game.practice or game.tutorial.active:return ""
 return str(game.region_id)
func place_buried_spring()->void:
 if not multi or spots.is_empty():return
 # Both peers share floor geometry; use a deterministic scan for a clear bank.
 for n in 40:
  var bank=Vector2(450+(n%8)*140,450+int(n/8)*140)
  var water=bank+Vector2(110,0);var open=game._clear_path(bank,bank) and game._clear_path(bank+Vector2(0,30),bank+Vector2(0,30))
  for offset in [Vector2.ZERO,Vector2(62,0),Vector2(-62,0),Vector2(0,62),Vector2(0,-62)]:
   if not game._clear_path(water+offset,water+offset):open=false;break
  if open:
   spots[0].bank=[bank.x,bank.y];spots[0].water=[water.x,water.y];return
 spots.clear()
func menu_key()->String:return str(game.shop_open) if multi else str(game.menu)
func playable()->bool:
 if multi and (game.recovery!=null and game.recovery.frozen):return false
 return local_hp()>0 and menu_key().is_empty() and game.presentation.page.is_empty() and game.session_menu.page.is_empty() and not game.has_node("FXIntro")
func busy()->bool:return not phase.is_empty()
func blocked(point:Vector2)->bool:return SHOP_SOLID.has_point(point)
func interact()->bool:
 if local_pos().distance_to(SHOP)>85:return false
 game.hint="E • Enter Ripple & Reel"
 if Input.is_action_just_pressed("interact"):open_shop()
 return true
func nearest()->Dictionary:
 for spot in spots:
  var bank=Vector2(float(spot.bank[0]),float(spot.bank[1]))
  if local_pos().distance_to(bank)<100:return spot
 return {}
func _process(delta:float)->void:
 if game==null:return
 clock+=delta
 var region=region_key()
 if region!=cached_region:
  cancel("");cached_region=region;spots=C.spots(region)
  if region in ["descent38","descent56"]:place_buried_spring()
 if is_instance_valid(journal_panel):fit_panel(journal_panel,Vector2(1000,610))
 if is_instance_valid(room):panel.visible=false;return
 if busy() and (not playable() or local_pos().distance_to(cast_pos)>18 or local_hp()<cast_hp or region!=cast_region):cancel("Cast cancelled — moving, damage or a menu interrupted it.")
 var spot=nearest()
 panel.visible=playable() and (not spot.is_empty() or busy()) and not is_instance_valid(journal)
 panel.size=Vector2(360,0);var view=game.get_viewport_rect().size;var fit=minf(1,(view.x-24)/360);panel.scale=Vector2.ONE*fit;panel.position=Vector2((view.x-360*fit)*.5,view.y-155*fit)
 if not panel.visible:return
 var unlocked=bool(records().state().rod)
 title.text=str(cast_spot.get("name",spot.get("name","Fishing")))
 if phase=="waiting":
  timer-=delta;detail.text="Watch the float. Press F / Hook when it dips!";cast_button.text="Waiting… • click to cancel";meter.visible=true;meter.value=clampf(100*(1-timer/float(cast_spot.wait)),0,100)
  var age=float(cast_spot.wait)-timer
  if bite_at>=0 and age>=bite_at:start_bite()
  elif timer<=0:cancel(["Not even a nibble. Try another cast.","Quiet water… no bite this time.","The fish ignored that cast. Try again."][rng.randi_range(0,2)])
 elif phase=="bite":
  timer-=delta;detail.text="BITE! Three flashes — hook now • F";cast_button.text="F • HOOK!";cast_button.modulate=Color("#ffde8f") if bite_flash() else Color("#b89b79");meter.visible=true;meter.value=timer/BITE_WINDOW*100
  if timer<=0:cancel("The fish slipped away. Cast again.")
 elif phase=="landed":
  panel.visible=false
 else:
  detail.text=status if not status.is_empty() else "Stand by the water. A patient cast can uncover a trophy."
  cast_button.text="F • Cast a line" if unlocked else "Visit Ripple & Reel to discover your fishing rod"
  cast_button.disabled=not unlocked;cast_button.modulate=Color.WHITE;meter.visible=false
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_ESCAPE and is_instance_valid(journal):close_journal();get_viewport().set_input_as_handled();return
  if event.keycode==KEY_ESCAPE and busy():cancel("Cast cancelled.");get_viewport().set_input_as_handled();return
  if event.keycode==KEY_F and playable() and not is_instance_valid(room):
   if busy() or not nearest().is_empty():activate();get_viewport().set_input_as_handled()
func start_bite()->void:
 phase="bite";timer=BITE_WINDOW
func bite_flash()->bool:
 return phase=="bite" and fposmod(BITE_WINDOW-timer,.8)<.4
func activate()->void:
 if not playable():return
 if phase=="bite":land();return
 if busy():cancel("Cast cancelled.");return
 if not bool(records().state().rod):status="Talk to Marina inside Ripple & Reel first.";return
 var spot=nearest()
 if spot.is_empty():return
 cast_spot=spot.duplicate();cast_spot.wait=rng.randf_range(8.0,14.0);timer=float(cast_spot.wait);bite_at=rng.randf_range(.6,timer-.3) if rng.randf()<.70 else -1.0;cast_pos=local_pos();cast_hp=local_hp();cast_region=region_key();pending=C.roll(str(spot.id),rng);phase="waiting";status="";cast_button.disabled=false
 if not multi:game.mobile.reset_controls()
func cancel(message:String)->void:
 phase="";pending={};cast_spot={};status=message
 if is_instance_valid(catch_frame):catch_frame.queue_free()
 catch_frame=null
func land()->void:
 if phase!="bite" or pending.is_empty():return
 phase="landed";catch_frame=PanelContainer.new();UI.apply(catch_frame);hud.add_child(catch_frame)
 catch_frame.position=Vector2(game.get_viewport_rect().size.x-365,205);catch_frame.custom_minimum_size=Vector2(340,0)
 var col=VBoxContainer.new();catch_frame.add_child(col);var spec:Dictionary=C.fish()[pending.species]
 label(col,str(spec.name),23).modulate=Color(str(spec.color));picture(col,str(pending.species),Vector2(210,110))
 label(col,"%s • %.2f kg • %.1f cm%s" % [spec.rarity,pending.kg,pending.cm," • TROPHY SIZE" if pending.trophy else ""],16)
 label(col,C.size_summary(pending),16).modulate=Color("#ffe1a7")
 var previous:Dictionary=records().state().journal.get(str(pending.species),{})
 var record_text="First of this species — your first size record!" if previous.is_empty() else "Your largest before this catch: %.2f kg / %.1f cm" % [previous.kg,previous.cm]
 label(col,record_text,16).modulate=Color("#ade0cd")
 if not previous.is_empty():
  label(col,"NEW WEIGHT RECORD! +%.2f kg" % (float(pending.kg)-float(previous.kg)) if float(pending.kg)>float(previous.kg) else "%.2f kg below your best" % (float(previous.kg)-float(pending.kg)),17).modulate=Color("#ffe19c")
 catch_text=label(col,"Keep it for your aquarium, or release it. Both record a discovery. Combat is still live!",15)
 var row=HBoxContainer.new();col.add_child(row);UI.accent(button(row,"Keep catch",finish_catch.bind(true)));button(row,"Release",finish_catch.bind(false))
 var view=game.get_viewport_rect().size;var fit=minf(1,minf((view.x-24)/340,(view.y-24)/560));catch_frame.scale=Vector2.ONE*fit;catch_frame.position=Vector2(view.x-340*fit-12,maxf(12,(view.y-560*fit)*.5))
func finish_catch(keep:bool)->void:
 if phase!="landed" or pending.is_empty():return
 if keep and records().state().kept.size()>=records().CAPACITY:catch_text.text="Your 100-catch collection is full. Release this fish, or make room at Ripple & Reel.";return
 var name=str(C.fish()[pending.species].name)
 var reward_before=game.legacy.weekly.earned("week_fish")
 var saved=records().complete(pending,keep)
 var weekly_reward=" • Moonlit Minnow earned! Equip it in Cosmetics." if saved and not reward_before and game.legacy.weekly.earned("week_fish") else ""
 cancel(("Kept " if keep else "Released ")+name+(" • temporary Game Dev collection; saved profile unchanged." if bool(game.legacy.data.get("teacher",false)) else " • journal updated." if saved else " • practice/test catch; no profile progress.")+weekly_reward)
func label(parent:Node,text:String,font_size:int=17)->Label:
 var l=Label.new();l.text=text;l.add_theme_font_size_override("font_size",font_size);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l
func button(parent:Node,text:String,action:Callable)->Button:
 var b=Button.new();b.text=text;b.custom_minimum_size.y=42;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(b);b.pressed.connect(action);return b
func picture(parent:Node,id:String,dimensions:Vector2)->void:
 var image=TextureRect.new();image.texture=C.texture(id);image.custom_minimum_size=dimensions;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;parent.add_child(image)
func fit_panel(p:Control,dimensions:Vector2)->void:
 var v=game.get_viewport_rect().size;var scale_factor=minf(1,minf((v.x-24)/dimensions.x,(v.y-24)/dimensions.y));p.size=dimensions;p.scale=Vector2.ONE*scale_factor;p.position=(v-dimensions*scale_factor)*.5
func open_shop()->void:
 if multi or game.mode!="town" or is_instance_valid(room):return
 cancel("");game.menu="fishing_shop";game.mobile.reset_controls()
 room_layer=CanvasLayer.new();room_layer.layer=65;game.add_child(room_layer)
 room=preload("res://scripts/fishing_room.gd").new();room_layer.add_child(room);room.setup(self)
func close_shop()->void:
 close_journal()
 if is_instance_valid(room_layer):room_layer.queue_free()
 room=null;room_layer=null;game.menu="";game.mobile.reset_controls()
func open_journal()->void:
 if is_instance_valid(journal):close_journal()
 modal_previous=menu_key()
 if not multi:game.menu="fishing_journal"
 journal=CanvasLayer.new();journal.layer=90;game.add_child(journal)
 var backdrop=ColorRect.new();backdrop.color=Color(0.025,.065,.085,.96);backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);journal.add_child(backdrop)
 journal_panel=PanelContainer.new();UI.apply(journal_panel);journal.add_child(journal_panel)
 var col=VBoxContainer.new();journal_panel.add_child(col)
 var header=HBoxContainer.new();col.add_child(header);label(header,"RIPPLE & REEL • YOUR CATCHES",25);button(header,"Close",close_journal)
 label(col,"%d / %d species discovered • %d catches • %d / 100 kept. Display five in the shop, and one favourite on your player card." % [records().state().journal.size(),C.fish().size(),records().state().total,records().state().kept.size()],16)
 button(col,"Weekly fishing challenge & rewards",game.legacy.weekly.open_board)
 var task=game.legacy.weekly.fishing_task();label(col,"This week: "+str(C.fish()[task.species].name)+" • at least %.2f kg • %s" % [task.kg,C.pools()[task.pool].name],16)
 var tabs=TabContainer.new();tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(tabs)
 for kind in ["Kept catches","Species journal"]:
  var scroll=ScrollContainer.new();scroll.name=kind;scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tabs.add_child(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll)
  var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
  if kind=="Kept catches":kept_ui(body)
  else:species_ui(body)
 fit_panel(journal_panel,Vector2(1000,610));UI.enter(journal_panel)
func close_journal()->void:
 if is_instance_valid(journal):journal.queue_free()
 journal=null;journal_panel=null
 if not multi and game.menu=="fishing_journal":
  game.menu=modal_previous
  if modal_previous=="legacy":game.legacy.render()
func refresh_journal()->void:
 var original=modal_previous;open_journal();modal_previous=original
func kept_ui(body:Node)->void:
 if records().state().kept.is_empty():label(body,"No fish kept yet. Talk to Marina, find bubbles at the pond or river, and press F to cast.",19)
 var all_catches:Array=records().state().kept
 journal_page=clampi(journal_page,0,maxi(0,(all_catches.size()-1)/10))
 if all_catches.size()>10:
  var navigation=HBoxContainer.new();body.add_child(navigation)
  var back=button(navigation,"Previous 10",func():journal_page-=1;refresh_journal());back.disabled=journal_page==0
  label(navigation,"Page %d / %d" % [journal_page+1,ceili(all_catches.size()/10.0)],16)
  var next=button(navigation,"Next 10",func():journal_page+=1;refresh_journal());next.disabled=(journal_page+1)*10>=all_catches.size()
 for catch in all_catches.slice(journal_page*10,journal_page*10+10):
  var id=str(catch.id);var spec:Dictionary=C.fish()[catch.species];var box=UI.card(body,str(spec.name)+(" • Favourite" if records().state().favorite==id else ""),"%s • %.2f kg • %.1f cm • %s" % [spec.rarity,catch.kg,catch.cm,C.pools()[catch.pool].name]);var row=HBoxContainer.new();box.add_child(row);picture(row,str(catch.species),Vector2(160,88))
  var actions=VBoxContainer.new();actions.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(actions)
  button(actions,"Feature on player card",func():records().set_favorite(id);refresh_journal())
  var tank=HBoxContainer.new();actions.add_child(tank)
  for n in 5:
   button(tank,"Tank "+str(n+1)+( " ✓" if records().state().display[n]==id else ""),func():records().showcase(id,n);refresh_journal())
  button(actions,"Release this kept fish…",func():
   var dialog=ConfirmationDialog.new();dialog.title="Release "+str(spec.name)+"?";dialog.dialog_text="This removes the kept fish and any display/favourite using it. Your journal record remains.";journal.add_child(dialog);dialog.confirmed.connect(func():records().release(id);dialog.queue_free();refresh_journal());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(460,180)))
 if not records().state().favorite.is_empty():button(body,"Clear player-card favourite",func():records().set_favorite("");refresh_journal())
func species_ui(body:Node)->void:
 for id in C.fish():
  var seen=records().state().journal.has(id);var spec:Dictionary=C.fish()[id]
  var box=UI.card(body,str(spec.name) if seen else "? • Undiscovered fish",str(spec.habitat))
  var row=HBoxContainer.new();box.add_child(row)
  if seen:
   picture(row,id,Vector2(145,80));var rec:Dictionary=records().state().journal[id]
   label(row,"%s • %d caught • Best %.2f kg / %.1f cm\n%s" % [spec.rarity,rec.count,rec.kg,rec.cm,spec.note],17)
  else:label(row,"Explore fishing waters to discover this species. Size varies even within the same species.",16)
func draw_on(canvas:Node2D,camera:Vector2)->void:
 var region=region_key();var active_spots=spots if region==cached_region else C.spots(region)
 var bounds=Rect2(camera,game.VIEW).grow(160)
 if region=="town" and bounds.intersects(SHOP_SOLID.grow(80)):
  canvas.draw_texture_rect(C.texture("shop"),Rect2(SHOP-Vector2(180,288)-camera,Vector2(360,288)),false)
  var p=SHOP-camera;canvas.draw_string(UI.FONT,p+Vector2(-106,-95),"RIPPLE & REEL",HORIZONTAL_ALIGNMENT_CENTER,212,17,Color("#fae2a8"))
  canvas.draw_rect(Rect2(p-Vector2(55,2),Vector2(110,38)),Color(.6,.9,.87,.17 if local_pos().distance_to(SHOP)<100 else .07))
 for spot in active_spots:
  var water=Vector2(float(spot.water[0]),float(spot.water[1]));var bank=Vector2(float(spot.bank[0]),float(spot.bank[1]))
  if not bounds.has_point(water):continue
  var p=water-camera
  if region in ["descent38","descent56"]:
   canvas.draw_circle(p,67,Color("#233f50"));canvas.draw_circle(p,54,Color("#478398"));canvas.draw_arc(p,57,0,TAU,40,Color("#9cbec2"),4)
  for n in 3:
   var r=fposmod(clock*8+n*10,30.0);canvas.draw_arc(p+Vector2(n*11-11,sin(n)*5),r,0,TAU,20,Color(.66,.93,.94,.55*(1-r/30)),1.5)
  for n in 4:
   var b=p+Vector2(sin(clock*.8+n*2)*18,cos(clock+n)*7);canvas.draw_circle(b,2,Color(.78,.95,.97,.65))
  var jump=fposmod(clock+float(spot.id.hash()%41),45)
  if jump<1.4:
   var arc=sin(jump/1.4*PI);var t=C.texture(str(spot.fish[0]));canvas.draw_texture_rect(t,Rect2(p+Vector2((jump/.7-1)*35,-arc*52)-Vector2(24,13),Vector2(48,27)),false)
  # Small shore marker makes the interaction readable without covering the water.
  var shore=bank-camera
  if region=="town":
   canvas.draw_rect(Rect2(shore-Vector2(36,20),Vector2(72,42)),Color("#a08b68"))
   canvas.draw_rect(Rect2(shore-Vector2(36,20),Vector2(72,42)),Color("#d2b78a"),false,2)
   for plank in 5:canvas.draw_line(shore+Vector2(-34+plank*14,-18),shore+Vector2(-34+plank*14,20),Color("#75614f"),1)
  canvas.draw_line(shore+Vector2(-12,6),shore+Vector2(-12,-24),Color("#baa177"),3);canvas.draw_circle(shore+Vector2(-12,-27),6,Color("#96cbd4"));canvas.draw_arc(shore,23,0,PI,18,Color(.7,.88,.85,.35),2)
 if busy() and not cast_spot.is_empty() and region==cast_region:
  var water=Vector2(float(cast_spot.water[0]),float(cast_spot.water[1]))-camera;var hero=local_pos()-camera
  canvas.draw_line(hero+Vector2(15,-36),hero+Vector2(38,-60),Color("#c5a579"),3);canvas.draw_line(hero+Vector2(38,-60),water,Color(.8,.88,.86,.8),1)
  var bob=water+Vector2(0,sin(clock*5)*2+(8 if phase=="bite" else 0));canvas.draw_circle(bob,4,Color("#edc49a"));canvas.draw_line(bob-Vector2(0,7),bob,Color("#e26560"),3)
  if bite_flash():
   canvas.draw_arc(bob,15,0,TAU,24,Color("#ffe291"),3,true);canvas.draw_line(bob+Vector2(0,-30),bob+Vector2(0,-19),Color("#ffe291"),4,true);canvas.draw_circle(bob+Vector2(0,-14),2,Color("#ffe291"))
