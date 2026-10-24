extends Node
## Local collection activity. Realm combat and host simulation never pause for a cast.
const C=preload("res://scripts/fishing_catalog.gd")
const UI=preload("res://scripts/studio_ui.gd")
const SHOP=Vector2(2000,2020)
const SHOP_SOLID=Rect2(1850,1760,300,215)
const E=preload("res://scripts/fishing_ecology.gd")
var aquarium_panel:CanvasLayer
var aquarium_save_clock=0.0
var workshop:CanvasLayer
var method_picker:OptionButton
var bait_picker:OptionButton
var odds_button:Button
var bite_window=2.4
var mastery_window:CanvasLayer
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
var inspector:CanvasLayer
var journal:CanvasLayer
var journal_panel:PanelContainer
var room_layer:CanvasLayer
var room:Control
var journal_page=0
var kept_query=""
var kept_sort=4
var sales:CanvasLayer
var sales_focus_id=""
var collection_tab=0
var journal_rarity="all"
var journal_pool="all"
var journal_discovery="all"
var collection_tabs:TabContainer
var collection_scrolls:Array=[]
var collection_offsets:Array=[0,0]
var status=""
var basket_index=-1
var basket_note:Button
var modal_previous=""
var seen_menu=""
func setup(owner:Node,is_multi:bool=false)->void:
 game=owner;multi=is_multi;rng.randomize()
 hud=CanvasLayer.new();hud.layer=58;add_child(hud)
 panel=PanelContainer.new();UI.apply(panel);panel.custom_minimum_size=Vector2(360,0);hud.add_child(panel)
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",6);panel.add_child(col)
 title=label(col,"",18);detail=label(col,"",14)
 var controls=HBoxContainer.new();col.add_child(controls);method_picker=OptionButton.new()
 for method in ["Rod","Net","Basket"]:method_picker.add_item(method)
 controls.add_child(method_picker);method_picker.item_selected.connect(func(i):records().state().method=["rod","net","pot"][i];status="";records().save())
 bait_picker=OptionButton.new()
 for id in E.BAITS:bait_picker.add_item(str(E.BAITS[id].name))
 controls.add_child(bait_picker);bait_picker.item_selected.connect(func(i):records().state().selected_bait=E.BAITS.keys()[i];records().save())
 button(col,"Gear • fish bait • fishing mastery",open_workshop)
 odds_button=button(col,"Read this water • fish odds",open_odds);odds_button.visible=false
 meter=ProgressBar.new();meter.custom_minimum_size.y=10;meter.show_percentage=false;col.add_child(meter)
 cast_button=button(col,"F • Cast",activate);UI.accent(cast_button);panel.visible=false
 basket_note=button(hud,"",func():open_workshop();workshop.selected_tab=2;workshop.build());basket_note.visible=false;basket_note.clip_text=true;basket_note.custom_minimum_size.x=0
func records():return game.legacy.fishing_records
func local_pos()->Vector2:return game.local_pos if multi else game.position_in_world
func local_hp()->float:return float(game.health.get(game.my_id,0)) if multi else float(game.health)
func region_key()->String:
 if multi:
  if not game.started or game.start_countdown>0 or game.spectating():return ""
  if game.mode=="descent" and game.floor_number in [36,38,56,57]:return "descent"+str(game.floor_number)
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
func spot_available(spot:Dictionary)->bool:
 if str(spot.get("id",""))!="town_dawn":return true
 return not multi and game.mode=="town" and game.town_life.calendar.dawn_fishing_open()
func nearest()->Dictionary:
 if not multi and game.get("voyage")!=null and game.voyage.active:return game.voyage.fishing_spot()
 for spot in spots:
  if not spot_available(spot):continue
  var bank=Vector2(float(spot.bank[0]),float(spot.bank[1]))
  if local_pos().distance_to(bank)<100:return spot
 return {}
func _process(delta:float)->void:
 if game==null:return
 clock+=delta
 aquarium_save_clock+=delta
 if aquarium_save_clock>=60:
  aquarium_save_clock=0
  if records().income.allowed() and records().income.hourly()>0:records().income.advance();records().save()
 var prog=records().progress
 odds_button.visible=prog.has("fieldguide")
 if not prog.method_unlocked(str(prog.state().method)):prog.state().method="rod"
 for i in 3:method_picker.set_item_disabled(i,not prog.method_unlocked(["rod","net","pot"][i]))
 for i in E.BAITS.size():bait_picker.set_item_disabled(i,not prog.bait_unlocked(str(E.BAITS.keys()[i])))
 var baskets=prog.state().pots
 basket_note.visible=not baskets.is_empty() and playable() and not busy() and nearest().is_empty()
 basket_note.text=prog.basket_summary(E.context(game).utc)
 var notice=basket_notice_rect(game.get_viewport_rect().size,not multi and game.mode=="town")
 basket_note.position=notice.position;basket_note.size=notice.size
 var locations:Array[String]=[]
 for pot in baskets:locations.append(basket_location(str(pot.get("pool",""))))
 basket_note.tooltip_text="Basket locations:\n"+"\n".join(locations)+"\nClick to inspect baskets and collect ready catches."
 var region=region_key()
 if region!=cached_region:
  cancel("");cached_region=region;spots=C.spots(region)
  if region in ["descent36","descent38","descent56","descent57"]:place_buried_spring()
 if not multi and region=="between" and game.waylight.between():spots=game.waylight.expedition.fishing_spots()
 if multi and game.get("expedition")!=null and game.expedition.between():spots=game.expedition.expedition.fishing_spots()
 if is_instance_valid(journal_panel):fit_panel(journal_panel,Vector2(1000,610))
 if is_instance_valid(catch_frame):fit_catch_frame()
 if is_instance_valid(room):panel.visible=false;return
 if busy() and not spot_available(cast_spot):cancel("The dawn shoal has vanished. Return between 4 and 6 am.")
 if busy() and (not playable() or local_pos().distance_to(cast_pos)>18 or local_hp()<cast_hp or region!=cast_region):cancel("Cast cancelled — moving, damage or a menu interrupted it.")
 var spot=nearest()
 if playable() and not spot.is_empty() and not (not multi and game.get("voyage")!=null and game.voyage.active):records().discover_pool(str(spot.id))
 panel.visible=playable() and (not spot.is_empty() or busy()) and not is_instance_valid(journal)
 var view=game.get_viewport_rect().size;var dims=panel.get_combined_minimum_size().max(Vector2(360,0));var fit=minf(1,minf((view.x-24)/dims.x,(view.y-24)/maxf(1,dims.y)));panel.size=dims;panel.scale=Vector2.ONE*fit;panel.position=Vector2((view.x-dims.x*fit)*.5,view.y-dims.y*fit-12)
 if not panel.visible:return
 var unlocked=bool(records().state().rod)
 method_picker.select(["rod","net","pot"].find(str(records().state().method)))
 bait_picker.select(E.BAITS.keys().find(prog.bait()))
 for i in E.BAITS.size():
  var id=str(E.BAITS.keys()[i]);bait_picker.set_item_text(i,str(E.BAITS[id].name)+(" · "+str(prog.state().bait.get(id,0)) if id!="basic" else ""))
 method_picker.disabled=busy();bait_picker.disabled=busy()
 title.text=str(cast_spot.get("name",spot.get("name","Fishing")))+" • Lv %d • Bag %d/%d" % [prog.level(),records().bag_count(),records().capacity()]
 if phase=="waiting":
  timer-=delta;detail.text="Watch the float. Press F / Hook when it dips!";cast_button.text="Waiting… • click to cancel";meter.visible=true;meter.value=clampf(100*(1-timer/float(cast_spot.wait)),0,100)
  var age=float(cast_spot.wait)-timer
  if bite_at>=0 and age>=bite_at:start_bite()
  elif timer<=0:cancel(["Not even a nibble. Try another cast.","Quiet water… no bite this time.","The fish ignored that cast. Try again."][rng.randi_range(0,2)])
 elif phase=="bite":
  timer-=delta;detail.text="BITE! Three flashes — hook now • F";cast_button.text="F • HOOK!";cast_button.modulate=Color("#ffde8f") if bite_flash() else Color("#b89b79");meter.visible=true;meter.value=timer/bite_window*100
  if timer<=0:cancel("The fish slipped away. Cast again.")
 elif phase=="landed":
  panel.visible=false
 else:
  detail.text=prog.basket_summary(E.context(game).utc) if records().state().method=="pot" and has_basket(str(spot.get("id",""))) else status if not status.is_empty() else "Stand by the water. A patient cast can uncover a trophy."
  cast_button.text=("F • Cast a line" if records().state().method=="rod" else "F • Scoop with net" if records().state().method=="net" else ("F • Check placed basket" if has_basket(str(spot.get("id",""))) else "F • Set baited basket")) if unlocked else "Visit Ripple & Reel to discover your fishing rod"
  cast_button.disabled=not unlocked;cast_button.modulate=Color.WHITE;meter.visible=false
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and not event.echo:
  if (event.keycode in [KEY_R,KEY_F] or event.physical_keycode in [KEY_R,KEY_F]) and phase=="landed" and not pending.is_empty():
   var focus=get_viewport().gui_get_focus_owner()
   if not (focus is LineEdit or focus is TextEdit):
    finish_catch(event.keycode==KEY_F or event.physical_keycode==KEY_F);get_viewport().set_input_as_handled();return
  if event.keycode==KEY_ESCAPE and is_instance_valid(inspector):inspector.close();get_viewport().set_input_as_handled();return
  if event.keycode==KEY_ESCAPE and is_instance_valid(aquarium_panel):aquarium_panel.close();get_viewport().set_input_as_handled();return
  if event.keycode==KEY_ESCAPE and is_instance_valid(journal):close_journal();get_viewport().set_input_as_handled();return
  if event.keycode==KEY_ESCAPE and busy():cancel("Cast cancelled.");get_viewport().set_input_as_handled();return
  if event.keycode==KEY_F and playable() and not is_instance_valid(room):
   if busy() or not nearest().is_empty():activate();get_viewport().set_input_as_handled()
func open_basket(index:int)->void:
 if not multi and game.get("voyage")!=null and game.voyage.active:status="Recover voyage cages at their water markers. Town baskets wait safely in town.";return
 if index<0 or index>=records().state().pots.size():return
 var pot=records().state().pots[index]
 if E.context(game).utc<float(pot.ready):return
 if is_instance_valid(workshop):workshop.close()
 # A shop/journal may have opened the workshop; leave those menus for collection.
 close_journal()
 if is_instance_valid(room):close_shop()
 if not multi:game.legacy.close();game.menu=""
 basket_index=index;pending=pot.catch;cast_pos=local_pos();cast_hp=local_hp();cast_region=region_key();phase="bite";land()
func has_basket(pool:String)->bool:
 for pot in records().progress.state().pots:
  if str(pot.pool)==pool:return true
 return false
func start_bite()->void:
 phase="bite";timer=bite_window
func bite_flash()->bool:
 return phase=="bite" and fposmod(bite_window-timer,.8)<.4
func activate()->void:
 if not playable():return
 if phase=="bite":land();return
 if busy():cancel("Cast cancelled.");return
 if not bool(records().state().rod):status="Talk to Bramble inside Ripple & Reel first.";return
 var spot=nearest()
 if spot.is_empty():return
 var prog=records().progress;var method=str(records().state().method)
 if not prog.method_unlocked(method):status="This equipment is not unlocked. Visit the workshop.";return
 if method=="pot" and region_key()=="between":status="These waters are unstable. Use a rod or net; set baskets in permanent realm waters.";return
 if method=="pot" and not multi and game.get("voyage")!=null and game.voyage.active:game.voyage.cage_action();return
 if method=="pot":
  var now=E.context(game).utc
  for i in prog.state().pots.size():
   if str(prog.state().pots[i].pool)!=str(spot.id):continue
   if now<float(prog.state().pots[i].ready):status=prog.basket_summary(now);return
   basket_index=i;pending=prog.state().pots[i].catch;cast_pos=local_pos();cast_hp=local_hp();cast_region=region_key();phase="bite";land();return
  status=prog.place(str(spot.id),now,rng);game.message=status;game.message_time=5;return
 if not E.bait_usable(prog.bait(),method,str(spot.region)):status="This bait is for "+("cages/baskets only." if prog.bait()=="roe" else "ocean water only.");return
 pending=C.roll(str(spot.id),rng,E.context(game),method,prog.bait(),prog.level(),prog.trophy_bonus(),prog.rarity_bonus(method))
 if pending.is_empty():status="No suitable catches for this method and conditions. Try a different method, water or time.";return
 cast_spot=spot.duplicate();cast_spot.wait=(rng.randf_range(.7,1.4) if method=="net" else rng.randf_range(8.0,14.0))*prog.wait_scale(method)
 if not multi and game.get("voyage")!=null and game.voyage.active:cast_spot.wait*=float(spot.get("wait",3))/3.5
 timer=float(cast_spot.wait);bite_at=rng.randf_range(.3 if method=="net" else .6,maxf(.61,timer-.2)) if rng.randf()<prog.bite_chance(method) else -1.0
 bite_window=BITE_WINDOW+prog.hook_bonus(method);cast_pos=local_pos();cast_hp=local_hp();cast_region=region_key();phase="waiting";status="";cast_button.disabled=false
 if not multi:game.mobile.reset_controls()
func cancel(message:String)->void:
 phase="";pending={};cast_spot={};basket_index=-1;status=message
 if is_instance_valid(catch_frame):catch_frame.queue_free()
 catch_frame=null
func land()->void:
 if not spot_available(cast_spot):cancel("The dawn fishing window has closed.");return
 if phase!="bite" or pending.is_empty():return
 if basket_index<0 and not E.open(C.fish()[pending.species],E.context(game),str(pending.get("method","rod")),str(pending.get("bait","basic"))):cancel("This species stopped feeding as the conditions changed.");return
 phase="landed";catch_frame=PanelContainer.new();UI.apply(catch_frame);hud.add_child(catch_frame)
 catch_frame.position=Vector2(game.get_viewport_rect().size.x-365,205);catch_frame.custom_minimum_size=Vector2(340,0)
 var col=VBoxContainer.new();catch_frame.add_child(col);var spec:Dictionary=C.fish()[pending.species]
 var rarity_colour=Color({"Legendary":"#ffd36f","Mystical":"#c59aff","Fabled":"#ff91c9"}.get(str(spec.rarity),"#e9dfc5"))
 if str(spec.rarity) in ["Legendary","Mystical","Fabled"]:
  var ribbon=label(col,"✦ "+str(spec.rarity).to_upper()+" CATCH!",24);ribbon.modulate=rarity_colour
  label(col,"A remarkable find • "+str(spec.name),15).modulate=rarity_colour
  var skin=UI.box("#173641","#"+rarity_colour.to_html(false),10,14);catch_frame.add_theme_stylebox_override("panel",skin)
  ribbon.modulate.a=.2;var reveal=ribbon.create_tween();reveal.tween_property(ribbon,"modulate:a",1.0,.45)
 if C.is_trophy(pending):
  label(col,"★ TROPHY FISH! ★",25).modulate=Color("#ffdb7d")
  label(col,"250%+ of species average • +50% catch XP",15).modulate=Color("#ffdb7d")
 label(col,str(spec.name),23).modulate=Color(str(spec.color));picture(col,str(pending.species),Vector2(210,110))
 label(col,"%s • %.2f kg • %.1f cm%s" % [spec.rarity,pending.kg,pending.cm," • TROPHY SIZE" if C.is_trophy(pending) else ""],16).modulate=rarity_colour
 label(col,C.size_summary(pending),16).modulate=Color("#ffe1a7")
 var previous:Dictionary=records().state().journal.get(str(pending.species),{})
 var record_text="First of this species — your first size record!" if previous.is_empty() else "Your largest before this catch: %.2f kg / %.1f cm" % [previous.kg,previous.cm]
 label(col,record_text,16).modulate=Color("#ade0cd")
 if not previous.is_empty():
  label(col,"NEW WEIGHT RECORD! +%.2f kg" % (float(pending.kg)-float(previous.kg)) if float(pending.kg)>float(previous.kg) else "%.2f kg below your best" % (float(previous.kg)-float(pending.kg)),17).modulate=Color("#ffe19c")
 if basket_index>=0:label(col,"BASKET • %d fish remaining" % records().progress.basket_count(records().state().pots[basket_index]),17)
 catch_text=label(col,"Keep it for your aquarium, or release it. Keep: normal XP and a fish to sell for %d%% of its base Glimmer price. Release: +%d%% fishing XP. Both record discoveries!" % [roundi((1+records().progress.perk_bonus("sale"))*100),roundi(records().progress.release_bonus()*100)],15)
 var row=HBoxContainer.new();col.add_child(row);UI.accent(button(row,"F • Keep catch",finish_catch.bind(true)));button(row,"R • Release",finish_catch.bind(false))
 call_deferred("fit_catch_frame")
func fit_catch_frame()->void:
 if not is_instance_valid(catch_frame):return
 var view=game.get_viewport_rect().size;var dims=catch_frame.get_combined_minimum_size().max(Vector2(340,0))
 var fit=minf(1,minf((view.x-24)/dims.x,(view.y-24)/maxf(1,dims.y)))
 catch_frame.size=dims;catch_frame.scale=Vector2.ONE*fit;catch_frame.position=Vector2(view.x-dims.x*fit-12,(view.y-dims.y*fit)*.5)
func finish_catch(keep:bool)->void:
 if not multi and game.get("voyage")!=null and game.voyage.active:
  if phase!="landed" or pending.is_empty():return
  if game.voyage.stow(pending,keep):records().progress.spend_bait(rng);cancel("Catch kept aboard • return alive for XP and records." if keep else "Released • no cargo slot used. Bonus XP awaits a safe return.")
  else:catch_text.text="Cargo %d/%d. Release this fish to keep fishing, or return to harbour. If the release log is full, return to bank its XP." % [game.voyage.cargo.size(),game.voyage.capacity()]
  return
 if phase!="landed" or pending.is_empty():return
 if keep and records().bag_count()>=records().capacity():catch_text.text="Fish bag full (%d / %d). Release this catch for XP, or sell/release kept fish to make room." % [records().bag_count(),records().capacity()];return
 var name=str(C.fish()[pending.species].name)
 var reward_before=game.legacy.weekly.earned("week_fish")
 var saved=false;var next_pool=""
 if basket_index>=0:
  next_pool=str(records().state().pots[basket_index].pool);records().progress.claim(basket_index,E.context(game).utc,keep);saved=records().state().recent.has(str(pending.id))
 else:
  saved=records().complete(pending,keep)
  if saved:records().progress.spend_bait(rng)
 if saved and basket_index<0:game.get_tree().root.get_node("FXActivity").event(game,"fish_catch","completed",0,{"species_id":str(pending.species),"fish_level":records().progress.level(),"fish_weight":float(pending.kg),"fish_xp_gain":records().progress.last_xp,"fish_trophy":1 if C.is_trophy(pending) else 0,"fish_kept":1 if keep else 0})
 var weekly_reward=" • Moonlit Minnow earned! Equip it in Cosmetics." if saved and not reward_before and game.legacy.weekly.earned("week_fish") else ""
 cancel(("Kept " if keep else "Released ")+name+(" • temporary Game Dev collection; saved profile unchanged." if bool(game.legacy.data.get("teacher",false)) else " • journal updated." if saved else " • practice/test catch; no profile progress.")+(" • +%d fishing XP" % records().progress.last_xp if saved else "")+weekly_reward)
 if saved and not next_pool.is_empty():
  for index in records().state().pots.size():
   if str(records().state().pots[index].pool)==next_pool:call_deferred("open_basket",index);break
func label(parent:Node,text:String,font_size:int=17)->Label:
 var l=Label.new();l.text=text;l.add_theme_font_size_override("font_size",font_size);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l
func button(parent:Node,text:String,action:Callable)->Button:
 var b=Button.new();b.text=text;b.custom_minimum_size.y=42;b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(b);b.pressed.connect(action);return b
func picture(parent:Node,id:String,dimensions:Vector2)->void:
 var image=TextureRect.new();image.texture=C.texture(id);image.custom_minimum_size=dimensions;image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;parent.add_child(image)
func fit_panel(p:Control,dimensions:Vector2)->void:
 var v=game.get_viewport_rect().size;var scale_factor=minf(1,minf((v.x-24)/dimensions.x,(v.y-24)/dimensions.y));p.size=dimensions;p.scale=Vector2.ONE*scale_factor;p.position=(v-dimensions*scale_factor)*.5
func open_odds()->void:
 var prog=records().progress
 if not prog.has("fieldguide"):
  status="Learn Read the Water in the Watersense mastery branch to see fish odds."
  game.message=status;game.message_time=5;return
 var spot=nearest()
 if spot.is_empty():game.message="Stand at a fishing hole to read its water.";game.message_time=5;return
 var ctx=E.context(game);var method=str(prog.state().method);var bait=prog.bait()
 var entries=[];var total=0.0
 for id in C.pools()[spot.id].fish:
  var w=E.weight(C.fish()[id],ctx,method,bait,prog.level(),prog.rarity_bonus(method))
  if w>0:entries.append({"id":id,"weight":w});total+=w
 var lines=[str(spot.name),"%s • %s • %s • %02d:%02d" % [method.capitalize(),str(E.BAITS[bait].name),str(ctx.weather),int(ctx.hour),int(fposmod(float(ctx.hour)*60,60))],"Species odds below are conditional on a successful catch."]
 lines.append("Bite chance per attempt: %.0f%%" % (100*prog.bite_chance(method)) if method!="pot" else "Basket fills once in %d real minutes; odds use current conditions, actual catch uses conditions at ready time." % prog.basket_minutes())
 for entry in entries:lines.append("%s • %.2f%%" % [C.fish()[entry.id].name,100*float(entry.weight)/total])
 if entries.is_empty():lines.append("Nothing feeds here with this method and these conditions.")
 lines.append("Weather, weekday, feeding hours, fish bait and mastery all affect this list. Reopen to refresh. Trophy size is a separate %.2f%% roll." % (2.5+100*prog.trophy_bonus()))
 var dialog=AcceptDialog.new();dialog.name="FishOdds";dialog.title="Read the Water";hud.add_child(dialog)
 var scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(560,330);dialog.add_child(scroll)
 label(scroll,"\n\n".join(lines),16)
 preload("res://scripts/touch_list_scroll.gd").attach(scroll)
 dialog.confirmed.connect(dialog.queue_free);dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(600,410))
func open_workshop()->void:
 if is_instance_valid(workshop):return
 cancel("");workshop=preload("res://scripts/fishing_workshop.gd").new();game.add_child(workshop);workshop.setup(self)
func open_sales(id:String="")->void:
 if multi or game.mode!="town":status="Visit Ripple & Reel in town to sell fish.";return
 sales_focus_id=id
 if not id.is_empty():kept_query=""
 close_journal()
 if is_instance_valid(workshop):workshop.close()
 if not is_instance_valid(room):open_shop()
 if is_instance_valid(sales):sales.refresh();return
 sales=preload("res://scripts/fishing_sales.gd").new();game.add_child(sales);sales.setup(self)
func open_shop()->void:
 if multi or game.mode!="town" or is_instance_valid(room):return
 cancel("");game.menu="fishing_shop";game.mobile.reset_controls()
 room_layer=CanvasLayer.new();room_layer.layer=65;game.add_child(room_layer)
 room=preload("res://scripts/fishing_room.gd").new();room_layer.add_child(room);room.setup(self)
func close_shop()->void:
 if is_instance_valid(aquarium_panel):aquarium_panel.close()
 if is_instance_valid(sales):sales.close()
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
 preload("res://scripts/fish_collection_ui.gd").build(self,journal_panel)
 fit_panel(journal_panel,Vector2(1000,610));UI.enter(journal_panel)
func close_journal()->void:
 if is_instance_valid(collection_tabs):collection_tab=collection_tabs.current_tab
 for i in collection_scrolls.size():
  if is_instance_valid(collection_scrolls[i]):collection_offsets[i]=collection_scrolls[i].scroll_vertical
 collection_scrolls.clear();collection_tabs=null
 if is_instance_valid(inspector):inspector.close()
 if is_instance_valid(journal):journal.queue_free()
 journal=null;journal_panel=null
 if not multi and game.menu=="fishing_journal":
  game.menu=modal_previous
  if modal_previous=="legacy":game.legacy.render()
func refresh_journal(reset_tab:int=-1)->void:
 var original=modal_previous;close_journal()
 if reset_tab in [0,1]:collection_offsets[reset_tab]=0
 open_journal();modal_previous=original
func kept_ui(body:Node)->void:preload("res://scripts/fish_collection_ui.gd").kept(self,body)
func show_catch_details(id:String)->void:
 if records().specimen(id).is_empty():return
 if is_instance_valid(inspector):
  if inspector.catch_id==id:return
  inspector.close()
 inspector=preload("res://scripts/fish_details.gd").new();game.add_child(inspector);inspector.setup(self,id)
func species_ui(body:Node)->void:preload("res://scripts/fish_collection_ui.gd").species(self,body)
func draw_on(canvas:Node2D,camera:Vector2)->void:
 draw_baskets(canvas,camera)
 var region=region_key();var active_spots=spots if region==cached_region else C.spots(region)
 if not multi and game.get("voyage")!=null and game.voyage.active:
  active_spots=[]
  var spot=game.voyage.fishing_spot()
  if not spot.is_empty() and game.voyage.ashore:active_spots=[spot]
 var bounds=Rect2(camera,game.VIEW).grow(160)
 if region=="town" and bounds.intersects(SHOP_SOLID.grow(80)):
  canvas.draw_texture_rect(C.texture("shop"),Rect2(SHOP-Vector2(180,288)-camera,Vector2(360,288)),false)
  var p=SHOP-camera
  # Dedicated fascia sits below the roof, above the door and both windows.
  var sign=Rect2(p+Vector2(-111,-169),Vector2(222,22))
  canvas.draw_rect(sign,Color("#264753"));canvas.draw_rect(sign,Color("#c6af7d"),false,1)
  canvas.draw_string(UI.FONT,p+Vector2(-108,-153),"RIPPLE & REEL",HORIZONTAL_ALIGNMENT_CENTER,216,16,Color("#fae2a8"))
  canvas.draw_rect(Rect2(p-Vector2(55,2),Vector2(110,38)),Color(.6,.9,.87,.17 if local_pos().distance_to(SHOP)<100 else .07))
 for spot in active_spots:
  if not spot_available(spot):continue
  var water=Vector2(float(spot.water[0]),float(spot.water[1]));var bank=Vector2(float(spot.bank[0]),float(spot.bank[1]))
  if not bounds.has_point(water):continue
  var p=water-camera
  if region in ["descent36","descent38","descent56","descent57"]:
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
  var bob=water+Vector2(0,sin(clock*5)*2+(8 if phase=="bite" else 0))
  if str(records().state().method)=="net":
   var scoop=bob+Vector2(0,-5-absf(sin(clock*4))*10)
   canvas.draw_line(hero+Vector2(15,-28),scoop+Vector2(-19,0),records().progress.tint(),4,true)
   canvas.draw_set_transform(scoop,0,Vector2(1,.55))
   canvas.draw_circle(Vector2.ZERO,22,Color(.6,.86,.88,.18))
   for n in range(-2,3):
    var edge=sqrt(22*22-n*n*49)
    canvas.draw_line(Vector2(n*7,-edge),Vector2(n*7,edge),Color(.73,.9,.87,.6),1,true)
    canvas.draw_line(Vector2(-edge,n*7),Vector2(edge,n*7),Color(.73,.9,.87,.6),1,true)
   canvas.draw_arc(Vector2.ZERO,22,0,TAU,32,records().progress.tint(),3,true);canvas.draw_set_transform(Vector2.ZERO)
  else:
   canvas.draw_line(hero+Vector2(15,-36),hero+Vector2(38,-60),records().progress.tint(),3);canvas.draw_line(hero+Vector2(38,-60),water,Color(.8,.88,.86,.8),1)
   canvas.draw_circle(bob,4,records().progress.tint());canvas.draw_line(bob-Vector2(0,7),bob,Color("#e26560"),3)
  if str(records().state().cosmetic) in ["moon","star","aurora","crown"] and records().progress.level()>=15:
   for n in 3:
    var glint=bob+Vector2(sin(clock*.8+n*2)*24,cos(clock+n)*10)
    var length=2+sin(clock*3+n)*1.5
    canvas.draw_line(glint-Vector2(length,0),glint+Vector2(length,0),records().progress.tint(),1,true)
    canvas.draw_line(glint-Vector2(0,length),glint+Vector2(0,length),records().progress.tint(),1,true)
  if bite_flash():
   canvas.draw_arc(bob,15,0,TAU,24,Color("#ffe291"),3,true);canvas.draw_line(bob+Vector2(0,-30),bob+Vector2(0,-19),Color("#ffe291"),4,true);canvas.draw_circle(bob+Vector2(0,-14),2,Color("#ffe291"))

func draw_baskets(canvas:Node2D,camera:Vector2)->void:
 for pot in records().state().pots:
  if str(C.pools()[pot.pool].region)!=region_key():continue
  var water=C.pools()[pot.pool].water;var p=Vector2(water[0],water[1])-camera+Vector2(26,14)
  if not Rect2(Vector2.ZERO,game.VIEW).grow(40).has_point(p):continue
  canvas.draw_rect(Rect2(p-Vector2(14,9),Vector2(28,18)),Color("#b59160"));canvas.draw_arc(p-Vector2(0,8),10,PI,TAU,16,Color("#ead2a1"),2,true)
  for n in 5:canvas.draw_line(p+Vector2(-12+n*6,-8),p+Vector2(-12+n*6,8),Color("#705d47"),1)
  var ready=E.context(game).utc>=float(pot.ready)
  canvas.draw_circle(p+Vector2(0,-17),5 if ready else 3,Color("#a8e0b8") if ready else Color("#ddbd7c"))
  if ready:
   canvas.draw_arc(p+Vector2(0,-17),10+sin(clock*3)*2,0,TAU,24,Color(.65,.95,.75,.6),2,true)
   canvas.draw_string(UI.FONT,p+Vector2(-27,-35),"READY!",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#c5f7c9"))

func xp_popup(amount:int)->void:
 if amount<=0:return
 var layer=CanvasLayer.new();layer.layer=65;layer.name="FishingXP";add_child(layer)
 var label=Label.new();label.text="+%d Fishing XP" % amount;label.add_theme_font_size_override("font_size",19);label.add_theme_color_override("font_color",Color("#90e9df"));label.add_theme_color_override("font_shadow_color",Color("#153a3e"));label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",2);label.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(label)
 var at:Vector2=game._local_draw_position() if game.has_method("_local_draw_position") else game.local_pos
 label.position=at-game.camera-Vector2(40,70)
 var tween=create_tween();tween.set_parallel(true);tween.tween_property(label,"position:y",label.position.y-36,.95);tween.tween_property(label,"modulate:a",0.0,.95);tween.chain().tween_callback(layer.queue_free)

func open_mastery()->void:
 if is_instance_valid(mastery_window):return
 mastery_window=preload("res://scripts/fishing_mastery_view.gd").new();game.add_child(mastery_window);mastery_window.setup(self)

static func basket_notice_rect(view:Vector2,in_town:bool)->Rect2:
 var x=190.0 if in_town else 20.0
 return Rect2(x,132 if in_town and view.x<1100 else 118 if in_town else 102,maxf(80,minf(340,view.x-x-12)),40)
static func basket_location(pool:String)->String:
 var water:Dictionary=C.pools().get(pool,{})
 var region=str(water.get("region",""))
 var realm={"town":"Crossroads Town","wayfarer":"Wayfarer Quest","between_remote":"The Between","descent36":"The Descent · Floor 36","descent57":"The Descent · Floor 57","descent38":"The Descent · Floor 38","descent56":"The Descent · Floor 56","defense":"North Gate Defense"}.get(region,region.replace("_"," ").capitalize())
 var path="res://content/regions/"+region+".json"
 if FileAccess.file_exists(path):
  var data=JSON.parse_string(FileAccess.get_file_as_string(path))
  if data is Dictionary:realm=str(data.get("name",realm))
 return str(realm)+" · "+str(water.get("name","Unknown water"))

func open_aquarium_income()->void:
 if not is_instance_valid(room):return
 if is_instance_valid(aquarium_panel):return
 aquarium_panel=preload("res://scripts/aquarium_income_ui.gd").new();game.add_child(aquarium_panel);aquarium_panel.setup(self)
