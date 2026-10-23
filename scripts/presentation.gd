extends CanvasLayer
## Shared presentation; no combat authority or progression rewards live here.
var elder_guide=preload("res://scripts/elder_guidance.gd").new()
var game:Node
var arcade:=false
var panel:Control
var feedback:Control
var modal:PanelContainer
var content:VBoxContainer
var mute:Button
var skip:Button
var adventure_button:Button
var before_badges:Array=[]
var before_ready:Dictionary={}
var asked:=false
var page:=""
var clock:=0.0
var flash:=0.0
var rings:Array=[]
var before:Dictionary={}
var before_town:Dictionary={}
var last_result:=""
var pending_skill=""
var unlock_until=0.0
var unlock_buttons:Array=[]
var read_until=0.0
func setup(owner:Node,multi:bool)->void:
 game=owner;arcade=multi;layer=46;elder_guide.game=owner
 panel=Control.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(panel);panel.draw.connect(paint)
 feedback=Control.new();feedback.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);feedback.mouse_filter=Control.MOUSE_FILTER_IGNORE;feedback.z_index=10;panel.add_child(feedback);feedback.draw.connect(paint_feedback)
 var cfg:=ConfigFile.new();cfg.load("user://fx_sound.cfg");AudioServer.set_bus_mute(0,bool(cfg.get_value("sound","mute",false)))
 mute=Button.new();mute.custom_minimum_size=Vector2(126,44);mute.position=Vector2(1138,8);mute.size=Vector2(126,44);mute.pressed.connect(toggle_sound);panel.add_child(mute);style_button(mute);sound_label()
 if not arcade:
  adventure_button=Button.new();adventure_button.text="Adventures";adventure_button.tooltip_text="Combat adventures, Idle Mining, Crossroads Market, Studio and practice";adventure_button.position=Vector2(650,8);adventure_button.size=Vector2(155,44);adventure_button.pressed.connect(adventures);panel.add_child(adventure_button);style_button(adventure_button)
  skip=Button.new();skip.text="Skip tutorial • Esc";skip.position=Vector2(970,110);skip.size=Vector2(285,44);skip.pressed.connect(func():game.tutorial.finish(false,true));panel.add_child(skip);style_button(skip)
func sound_label()->void:mute.text="Sound: OFF" if AudioServer.is_bus_mute(0) else "Sound: ON";mute.tooltip_text="Mute or enable all sounds, including lodge challenges. Saved on this device."
func toggle_sound()->void:
 AudioServer.set_bus_mute(0,not AudioServer.is_bus_mute(0));sound_label()
 var cfg:=ConfigFile.new();cfg.set_value("sound","mute",AudioServer.is_bus_mute(0));cfg.save("user://fx_sound.cfg")
func label(parent:Node,value:String,size:int=19)->Label:
 var item:=Label.new();item.text=value;item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;item.add_theme_font_size_override("font_size",size);parent.add_child(item);return item
func style_button(b:Button)->void:preload("res://scripts/top_button_style.gd").apply(b)
func button(parent:Node,value:String,action:Callable)->Button:
 var b:=Button.new();b.text=value;b.custom_minimum_size.y=46;b.add_theme_font_size_override("font_size",18);b.pressed.connect(action);style_button(b);b.focus_mode=Control.FOCUS_ALL;parent.add_child(b);return b
func close()->void:
 pending_skill="";unlock_buttons.clear()
 if is_instance_valid(modal):modal.hide();modal.queue_free();modal=null
 if not arcade and game.menu=="presentation":game.menu=""
 page="";game.mobile.reset_controls()
func window(title:String,kind:String)->void:
 close();page=kind
 if not arcade:game.menu="presentation"
 game.mobile.reset_controls()
 modal=PanelContainer.new();modal.position=Vector2(105,65);modal.size=Vector2(1070,590);panel.add_child(modal)
 var skin:=StyleBoxFlat.new();skin.bg_color=Color("#112b34");skin.border_color=Color("#c6af79");skin.set_border_width_all(2);skin.set_corner_radius_all(14);skin.content_margin_left=24;skin.content_margin_right=24;skin.content_margin_top=20;skin.content_margin_bottom=20;modal.add_theme_stylebox_override("panel",skin)
 var col:=VBoxContainer.new();col.add_theme_constant_override("separation",12);modal.add_child(col);label(col,title,30).modulate=Color("#ecd6a0")
 var scroll:=ScrollContainer.new();preload("res://scripts/touch_list_scroll.gd").attach(scroll);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(scroll)
 content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",14);scroll.add_child(content)
 if kind=="results":
  if game.get("expedition")!=null and not game.expedition.settlement.is_empty():label(content,game.expedition.settlement,20)
  var footer:=HBoxContainer.new();footer.add_theme_constant_override("separation",12);col.add_child(footer)
  if arcade and game.has_method("return_to_network_menu"):
   button(footer,"Back to multiplayer • Host / Join",game.return_to_network_menu)
  elif arcade:
   if game.role=="host":button(footer,"Replay with party",func():return_to_party();game._start_button())
   else:label(content,"The host can replay this match with the party.",16)
   button(footer,"Return to party",return_to_party)
  elif game.get("waylight")!=null and game.waylight.special():button(footer,"Choose next expedition",replay_realm)
  else:button(footer,"Play again",replay_realm)
  if game.get("continuation")!=null and game.continuation.available():
   var resume_button=button(footer,"Continue • practice",game.continuation.resume);resume_button.tooltip_text="Full health, same XP and battle. This entire attempt stops awarding mastery and completion; enemy discoveries remain."
  if not arcade or not game.spectating():button(footer,"View hero mastery",inspect_mastery)
  if not arcade or not game.has_method("return_to_network_menu"):button(footer,"Back to town",func():
   if arcade:game._town()
   else:return_to_town())
 elif kind=="skill_unlock":button(col,"Got it — continue training",close)
 elif kind not in ["unlock_celebration","elder_guidance"]:button(col,"Skip introduction" if kind=="starter" else "Close • Esc",skip_intro if kind=="starter" else close)
func _unhandled_input(event:InputEvent)->void:
 if not event is InputEventKey or not event.pressed or event.echo:return
 if page=="starter" and event.keycode>=KEY_1 and event.keycode<=KEY_9:
  var id:String=str(game.manifest.characters[event.keycode-KEY_1]);close();game.tutorial.start(id);get_viewport().set_input_as_handled();return
 if page=="unlock_celebration" or page=="skill_unlock" and clock<read_until:return
 if event.keycode==KEY_ESCAPE and not page.is_empty():
  if page=="starter":skip_intro()
  elif page=="results" and not arcade:return_to_town()
  elif page=="results" and arcade:
   if game.has_method("return_to_network_menu"):game.return_to_network_menu()
   else:return_to_party()
  else:close()
  get_viewport().set_input_as_handled()
func _process(delta:float)->void:
 if game==null:return
 if not arcade and game.get_tree().root.has_meta("fx_retry_realm"):
  var realm:String=str(game.get_tree().root.get_meta("fx_retry_realm"));game.get_tree().root.remove_meta("fx_retry_realm");asked=true;game.start_run(false,realm)
 if not arcade and game.get_tree().root.has_meta("fx_inspect_hero"):
  var hero_id:String=str(game.get_tree().root.get_meta("fx_inspect_hero"));game.get_tree().root.remove_meta("fx_inspect_hero");asked=true;game.legacy.open_hero(hero_id)
 clock+=delta
 if page=="unlock_celebration" and clock>=unlock_until and not pending_skill.is_empty():
  var kind=pending_skill;pending_skill="";show_skill_unlock(kind)
 if page=="skill_unlock" and clock>=read_until and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
  for item in unlock_buttons:
   if is_instance_valid(item):item.disabled=false
 flash=maxf(0,flash-delta);mute.position=Vector2(get_viewport().get_visible_rect().size.x*.5-10,get_viewport().get_visible_rect().size.y-58)
 mute.visible=false
 if is_instance_valid(skip):skip.visible=game.tutorial.active;skip.position.x=get_viewport().get_visible_rect().size.x-300
 if is_instance_valid(adventure_button):
  adventure_button.visible=game.mode=="town" and game.menu.is_empty();preload("res://scripts/town_top_bar.gd").place(adventure_button,"adventures",get_viewport().get_visible_rect().size)
 if is_instance_valid(modal):
  var view:=get_viewport().get_visible_rect().size
  var fit:=minf(1,minf((view.x-24)/1070,(view.y-24)/590))
  modal.scale=Vector2.ONE*fit;modal.position=(view-Vector2(1070,590)*fit)*.5
 if not arcade and not game.has_node("FXIntro") and not get_tree().root.has_meta("fx_show_main") and game.menu.is_empty() and game.session_menu.page.is_empty():
  asked=true
  if game.mode=="town" and get_tree().root.has_meta("fx_start_tutorial"):
   get_tree().root.remove_meta("fx_start_tutorial");starter()
 if page=="results" and not arcade and game.menu!="results" and game.menu!="presentation":close()
 for n in range(rings.size()-1,-1,-1):
  rings[n].age=float(rings[n].age)+delta
  if float(rings[n].age)>1.2:rings.remove_at(n)
 panel.queue_redraw();feedback.queue_redraw()
func skip_intro()->void:
 game.profile["tutorial_seen"]=true;game.save_profile();game.journey.data.skipped=true;game.journey.save();close();elder_guide.welcome()
func starter()->void:
 get_tree().root.set_meta("fx_tutorial_offered",true)
 window("FIRST STEPS • choose your first hero","starter")
 label(content,"A short battle to learn movement, dodge and abilities. Three waves and a mini-boss. You can leave at any time.",18)
 var grid:=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);content.add_child(grid)
 for id in game.manifest.characters.slice(0,9):
  var b:=button(grid,str(game.characters[id].name)+"\n"+starter_role(str(id)),func():close();game.tutorial.start(str(id)))
  b.custom_minimum_size=Vector2(325,88);b.icon=game.art.get(str(game.characters[id].get("sprite",id))+"_idle");b.expand_icon=true;b.add_theme_constant_override("icon_max_width",50);b.tooltip_text=str(game.characters[id].primary.get("description",game.characters[id].primary.get("name","Primary attack")))
func starter_role(id:String)->String:
 var roles={"book":"Melee / Ranged","soccer":"Ranged / Support","basketball":"Melee / Summoner","baseball":"Ranged / Melee","goalie":"Melee / Defender","welder":"Melee / Ranged"}
 if roles.has(id):return roles[id]
 var tags:Array=game.hero_hall.library.entry(id,game.characters.get(id,{})).get("tags",["Melee"])
 return " / ".join(PackedStringArray(tags))
func skill_unlock(kind:String)->void:
 if not page.is_empty() and page in ["unlock_celebration","skill_unlock"]:return
 window("NEW ABILITY AWAKENED", "unlock_celebration")
 pending_skill=kind;unlock_until=clock+1.0
 label(content,"LEVEL "+str(game.level)+" • "+kind.to_upper(),32).modulate=Color("#ffdc84")
 label(content,"A new way to play is ready. Take a breath — the battle is paused.",23)
 burst(get_viewport().get_visible_rect().size*.5,false);game.journey.cue("level")
 disable_modal_buttons()
func disable_modal_buttons()->void:
 unlock_buttons.clear()
 for node in modal.find_children("*","Button",true,false):node.disabled=true;unlock_buttons.append(node)
func show_skill_unlock(kind:String)->void:
 var touch:bool=game.mobile.enabled
 var title:String="SECONDARY UNLOCKED • Level 3" if kind=="secondary" else "SPECIAL UNLOCKED • Level 6" if kind=="special" else "PASSIVE ACTIVE • Level 5"
 window(title,"skill_unlock")
 var spec:Dictionary=game.hero.get(kind,{}) if kind!="passive" else {}
 label(content,str(spec.get("name",game.hero.get("passive","Passive"))),28)
 var instruction:String="Tap or hold the circular SECONDARY button." if touch else "Click or hold RIGHT MOUSE to use your secondary attack."
 if kind=="special":instruction="Tap the circular SPECIAL button to cast." if touch else "Press or hold SPACE to use your special attack."
 if kind=="passive":instruction="Your passive works automatically — no extra button needed."
 label(content,instruction,24).modulate=Color("#ffda82")
 label(content,str(spec.get("description",game.ability_info(spec,kind))) if kind!="passive" else str(game.hero.get("passive_description","")),20)
 label(content,"Aim with the right stick, then tap your ability. Hold the movement stick with your other thumb." if touch and kind!="passive" else "Aim toward an enemy, watch the attack effect and try it in the next wave." if kind!="passive" else "Watch for its effect while you fight.",18)
 read_until=clock+.65;disable_modal_buttons()
func tutorial_end(won:bool,skipped:bool)->void:
 close()
 if won or skipped:elder_guide.welcome();return
 window("FIRST STEPS COMPLETE" if won else "DEFEATED • FIRST STEPS", "tutorial_end")
 if not won:
  label(content,"You were defeated. Try the battle again with what you learned.",23)
  preload("res://scripts/defeat_credit.gd").card(content,game,game.last_defeat)
  var retry=button(content,"Retry tutorial • "+str(game.characters[game.selected_character].name),func():close();game.tutorial.start(game.selected_character))
  preload("res://scripts/studio_ui.gd").accent(retry)
 else:label(content,"You mastered First Steps! Town is your home between adventures.",23)
 button(content,"Choose a different starter hero",starter)
 label(content,"Try a realm when you are ready, or explore your new home.",18)
 var first=button(content,"Start first adventure • Whispering Grove",func():close();game.start_run(false,"grove"))
 preload("res://scripts/studio_ui.gd").accent(first)
 button(content,"Explore town",close)

func launch(mode:String,realm:String="grove")->void:
 close();game.save_profile();game.get_tree().root.set_meta("fx_hero",game.selected_character);game.get_tree().root.set_meta("fx_mode",mode);game.get_tree().root.set_meta("fx_realm",realm);game.get_tree().change_scene_to_file("res://network/client.tscn")
func daily_challenge()->void:
 window("DAILY MISSION","daily")
 game.legacy.daily.ui(content)
 button(content,"Choose an adventure",adventures)
 button(content,"Back to game",close)
var adventures_tab:=0
func showcase_allowed()->bool:
 return preload("res://scripts/education_access.gd").student() or preload("res://scripts/education_access.gd").review_allowed()
func adventures()->void:
 window("CHOOSE YOUR ADVENTURE","adventures")
 game.legacy.daily.ui(content,true)
 label(content,"BROWSE DESTINATIONS",15).modulate=Color("#b8d5d8")
 var sections=TabBar.new();sections.name="AdventureCategories";sections.add_tab("Combat & exploration");sections.add_tab("Build, trade & create");sections.current_tab=adventures_tab;sections.tab_alignment=TabBar.ALIGNMENT_CENTER;sections.custom_minimum_size.y=52;content.add_child(sections)
 var selected=StyleBoxFlat.new();selected.bg_color=Color("#294d59");selected.border_color=Color("#eccb86");selected.border_width_bottom=4;selected.set_content_margin_all(15);sections.add_theme_stylebox_override("tab_selected",selected)
 var idle=StyleBoxFlat.new();idle.bg_color=Color("#132a33");idle.set_content_margin_all(15);sections.add_theme_stylebox_override("tab_unselected",idle);sections.add_theme_font_size_override("font_size",19)
 sections.tab_changed.connect(func(index:int):adventures_tab=index;adventures())
 label(content,"BATTLE • EXPLORE • PRACTISE" if adventures_tab==0 else "GATHER • GROW • CREATE",14).modulate=Color("#eccb86")
 var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",14);grid.add_theme_constant_override("v_separation",12);content.add_child(grid)
 var destinations:Array=[
  ["CHALLENGE LODGE","Fresh trials and weekly rewards","challenge"],
  ["REALMS","Themed adventures and bosses • solo or co-op","realms"],
  ["QUESTS","Meet residents and explore a larger story world","quests"],
  ["RAM DESCENT","Fight your way through deeper dungeon floors","descent"],
  ["NORTH GATE DEFENCE","Protect three roads • solo or with friends","defense"],
  ["GLADIATOR ARENA","Battle friends or practise against AI opponents","arena"],
  ["BATTLEGROUNDS","Build armies and fight for control • team battles","battlegrounds"],
  ["TRAINING YARD","Try your current hero in a safe practice area","training"],
  ["MISTGLASS SPIRE","Discover enemies and build your own rift battle","spire"],
  ["FIRST STEPS","Replay the short starter tutorial","starter"]
 ] if adventures_tab==0 else [
  ["GATHERERS’ LODGE","Send crews for herbs, mushrooms and garden seeds","gather"],
  ["WILLOWGLASS APOTHECARY","Brew gathered ingredients into useful potions","apothecary"],
  ["FISHING & AQUARIUM","Catch fish, compare records and display favourites","fishing"],
  ["IDLE MINING","Dig deeper, discover metals and forge bars","mine"],
  ["CROSSROADS MARKET","Sell your goods and grow a trading venture","market"],
  ["CROSSROADS STUDIO","Build heroes, abilities, enemies, objects and realms","studio"]
 ]
 if adventures_tab==1:
  destinations.append(["LEARNING ACADEMY","Design, graphics, coding and business modules","business_academy"])
  if showcase_allowed():destinations.append(["COMMUNITY SHOWCASE","Play selected creations and share useful feedback","showcase"])
  if preload("res://scripts/education_access.gd").student() or preload("res://scripts/education_access.gd").review_allowed():destinations.append(["CROSSROADS ACADEMY","Assignments, project ideas and your progress","academy"])
 for entry in destinations:adventure_tile(grid,entry)
 var extras=HBoxContainer.new();extras.add_theme_constant_override("separation",12);content.add_child(extras)
 button(extras,"Combat visual guide",combat_guide).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button(extras,"Profile & mastery",func():close();game.legacy.open_hero(game.selected_character)).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button(extras,"Cosmetics",func():close();game.menu="journey_cosmetics").size_flags_horizontal=Control.SIZE_EXPAND_FILL
func adventure_tile(parent:Node,entry:Array)->void:
 var destination=str(entry[2])
 var b=button(parent,"",choose_adventure.bind(destination));b.custom_minimum_size=Vector2(490,112);b.tooltip_text="Open "+str(entry[0])
 var inset=MarginContainer.new();inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:inset.add_theme_constant_override("margin_"+side,12)
 b.add_child(inset)
 var row=HBoxContainer.new();row.add_theme_constant_override("separation",14);inset.add_child(row)
 var icon=TextureRect.new();icon.custom_minimum_size=Vector2(72,76);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;row.add_child(icon)
 var paths={"realms":"portal.png","quests":"ram_idle.png","descent":"bramble_idle.png","defense":"guard_melee.svg","arena":"arena_stadium.svg","battlegrounds":"guard_area.svg","training":"training_dummy.svg","spire":"mistglass_v109.svg","starter":"ram_idle.png","gather":"lodges/gather.svg","apothecary":"lodges/apothecary.svg","challenge":"lodges/challenge.svg","daily":"portal.png","fishing":"fishing/shop.svg","mine":"star_mine_idle.png","market":"studio_cart_v148.svg","studio":"studio_archway_v148.svg","showcase":"training_hero_book.svg","academy":"studio_bookshelf_v148.svg"}
 var path="res://assets/"+str(paths.get(destination,"portal.png"))
 if ResourceLoader.exists(path):icon.texture=load(path)
 var copy=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;copy.add_theme_constant_override("separation",7);row.add_child(copy)
 label(copy,str(entry[0]),18).modulate=Color("#f0dbac")
 label(copy,str(entry[1]),15).modulate=Color("#c1d9de")
 var arrow=label(row,"›",28);arrow.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;arrow.modulate=Color("#ebca82")
 ignore_adventure_mouse(inset)
func ignore_adventure_mouse(control:Control)->void:
 control.mouse_filter=Control.MOUSE_FILTER_IGNORE
 for child in control.get_children():
  if child is Control:ignore_adventure_mouse(child)
func choose_adventure(value:String)->void:
 if value=="daily":game.legacy.daily.quick_play()
 elif value=="challenge":close();game.lodges.open("challenge")
 elif value in ["gather","apothecary"]:close();game.lodges.open(value)
 elif value=="spire":
  close();game.enter_region("town");game.position_in_world=game.town_v109.TOWER+Vector2(0,70);game.update_camera();game.menu="arcane_tower"
 elif value=="realms":close();game.waylight.open(0)
 elif value=="quests":quests()
 elif value=="starter":starter()
 elif value=="fishing":
  close();game.enter_region("town");game.position_in_world=game.fishing.SHOP+Vector2(0,45);game.update_camera();game.fishing.open_shop()
 elif value=="mine":close();game.legacy.mine.open()
 elif value=="market":close();game.open_business_district()
 elif value=="studio":close();game.hero_workshop.open()
 elif value=="showcase":
  if not showcase_allowed():return
  close();game.hero_workshop.open();var view=load("res://scripts/studio_showcase.gd").new();game.hero_workshop.add_child(view);view.setup(game.hero_workshop);view.page=2;view.render()
 elif value=="business_academy":close();game.open_business_academy()
 elif value=="academy":close();game.hero_workshop.open(true)
 elif value=="training":close();game.start_training()
 else:launch(value)
func quests()->void:
 window("WAYFARER EXPEDITION","adventures");label(content,"Speak to villagers, explore dungeons and mountain trails, and follow your quest journal. Bring food for a longer journey.",21)
 button(content,"Explore solo",func():close();game.start_run(false,"wayfarer"));button(content,"Explore with friends",func():launch("coop","wayfarer"))
func realms()->void:
 window("REALMS • choose your challenge","adventures")
 var grid:=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);content.add_child(grid)
 for id in game.manifest.regions:
  if not game.realms.has(id) or id in ["town","practice"]:continue
  var data:Dictionary=game.realms[id];var box:=VBoxContainer.new();box.custom_minimum_size.x=485;grid.add_child(box)
  if game.legacy.realm_mastered(str(id)):preload("res://scripts/ui_reward_icons.gd").row(box,str(data.get("name",id)),"star",21)
  else:label(box,str(data.get("name",id)),21)
  label(box,str(data.get("difficulty_label",data.get("difficulty","Adventure")))+" • "+str(game.legacy.realm_clears(str(id)))+" clears",15)
  var row:=HBoxContainer.new();box.add_child(row);var play=button(row,"Play solo",func():close();game.start_run(false,str(id)));var invite=button(row,"Invite friends",func():launch("coop",str(id)))
  var access=preload("res://scripts/realm_access.gd").hint(game.legacy,str(id));play.disabled=not access.is_empty();invite.disabled=play.disabled
  if play.disabled:label(box,access,16).modulate=Color("#efc982")
func begin_run()->void:
 before.clear();before_town=game.legacy.data.town.duplicate(true);before_badges=game.legacy.card.badges().duplicate();before_ready.clear();last_result=""
 for key in game.legacy.PROJECTS:before_ready[key]=game.legacy.town_ready(str(key))
 var ids:Array=game.characters.keys() if arcade else game.manifest.characters
 for id in ids:before[id]={"first":game.legacy.eligible(str(id)),"final":game.legacy.final_eligible(str(id)),"title":game.legacy.eligible(str(id),true)}
func unlocks(id:String)->Array[String]:
 var found:Array[String]=[];var old:Dictionary=before.get(id,{"first":false,"final":false,"title":false})
 if game.legacy.eligible(id) and not bool(old.first):found.append("First technique + portrait unlocked")
 if game.legacy.final_eligible(id) and not bool(old.final):found.append("Final technique + gold portrait star unlocked")
 if game.legacy.eligible(id,true) and not bool(old.title):found.append("Master title unlocked")
 for key in game.legacy.data.town:
  if bool(game.legacy.data.town[key]) and not bool(before_town.get(key,false)):found.append(str(game.legacy.PROJECTS.get(key,{}).get("name",key))+" built")
 for badge_id in game.legacy.card.badges():
  if badge_id not in before_badges:found.append(str(game.legacy.card.BADGES[badge_id].name)+" • player-card badge")
 for key in game.legacy.PROJECTS:
  if not bool(game.legacy.data.town.get(key,false)) and game.legacy.town_ready(str(key)) and not bool(before_ready.get(key,false)):found.append(str(game.legacy.PROJECTS[key].name)+" • ready to build")
 return found
func results(won:bool,abandoned:bool=false)->void:
 var token:String=game.match_id if arcade else game.region_id+":"+str(game.run_time)
 if last_result==token:return
 var returned=(arcade and game.get("realm_result")=="returned") or (not arcade and abandoned)
 last_result=token;window(("EXPEDITION CHECKPOINT SAVED" if arcade else "RETURNED TO THE CROSSROADS") if returned else "VICTORY" if won else "ADVENTURE OVER • YOU WERE DEFEATED","results")
 var id:String=str(game.hero_ids.get(game.my_id,game.selected_hero)) if arcade else game.character_id
 var title:String=game.results_reason if arcade else str(game.region.get("name","Realm"))
 label(content,title,23)
 var hero_row:=HBoxContainer.new();hero_row.add_theme_constant_override("separation",20);content.add_child(hero_row)
 var portrait:=TextureRect.new();portrait.texture=game.art.get(id+"_idle");portrait.custom_minimum_size=Vector2(72,72);portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;hero_row.add_child(portrait)
 var stats:Dictionary=game.contributions.get(game.my_id,{}) if arcade else {"damage":game.dealt_damage,"healing":0,"revives":0}
 var summary:="%s • %d:%02d\nDamage %s" % [str(game.characters.get(id,{}).get("name",id)),int(game.run_time)/60,int(game.run_time)%60,str(int(stats.get("damage",0)))]
 if arcade:summary+=" • Ability healing %s • Revives %s" % [str(int(stats.get("healing",0))),str(int(stats.get("revives",0)))]
 else:summary+=" • Damage taken %s • Enemies defeated %d" % [str(int(game.damage_taken)),int(game.kills)]
 label(hero_row,summary,20).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 if not arcade and game.get("waylight")!=null and game.waylight.special():
  preload("res://scripts/studio_ui.gd").card(content,"WAYLIGHT EXPEDITION",game.waylight.last_result)
  if game.waylight.between():
   label(content,"Waylight banked here powers overcharged realms. Relics are found in overcharged realms after Portal Attunement.",16)
   button(content,"Return to town",return_to_town)
  else:button(content,"Return to town & open Inventory",func():return_to_town();game.legacy.open_page("inventory"))
 if not won and not returned:preload("res://scripts/defeat_credit.gd").card(content,game,game.defeat_causes.get(game.my_id,{}) if arcade else game.last_defeat)
 if not arcade and "NEW PERSONAL BEST!" in game.result_text:preload("res://scripts/ui_reward_icons.gd").row(content,"NEW PERSONAL BEST","trophy",23)
 if arcade and game.practice_match():label(content,"PRACTICE • Damage counts toward hero mastery. PvP records and trophies are unchanged.",17)
 if arcade:team_results()
 if game.get("continuation")!=null and game.continuation.active:label(content,"PRACTICE CONTINUE • no mastery or completion awards. Enemy discoveries saved.",18)
 else:mastery_progress(id)
 for reward in unlocks(id):preload("res://scripts/ui_reward_icons.gd").row(content,reward,"building" if "ready to build" in reward or reward.ends_with(" built") else "star",20)
 if arcade:label(content,"Every role counts. Thank you for adventuring together.",17)
 game.journey.cue("victory" if won else "reward")
 if won:burst(Vector2(get_viewport().get_visible_rect().size.x-190,125),false)
func inspect_mastery()->void:
 var id:String=str(game.hero_ids.get(game.my_id,game.selected_hero)) if arcade else game.character_id
 if arcade:game.get_tree().root.set_meta("fx_inspect_hero",id);game._town()
 else:return_to_town();game.legacy.open_hero(id)
func return_to_party()->void:
 if game.get("continuation")!=null:game.continuation.end()
 close();game.results_reason="";game.recovery.frozen=false;game.recovery.failed=false
func team_results()->void:
 label(content,"ARENA SCOREBOARD" if game.mode=="arena" else "PARTY CONTRIBUTIONS",18).modulate=Color("#9ecfc8")
 var grid:=GridContainer.new();grid.columns=6;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",18);content.add_child(grid)
 var widths:Array=[220,112,145,103,145,105]
 var objective=game.arena_world.objective if arcade else null
 var objective_mode=objective!=null and objective.active()
 var headings:Array=["PLAYER","KOs","DEATHS","DAMAGE","ABILITY HEAL","BEST STREAK"] if game.mode=="arena" else ["PLAYER","DAMAGE","ABILITY HEAL","REVIVES","DEFENCE KILLS","UPGRADES"]
 if objective_mode:headings=["PLAYER","TEAM FLOOR %" if game.pvp_rule=="teams" else "FLOOR %","KOs","DEATHS","DAMAGE","TILES CLAIMED"] if game.arena_map=="colour_clash" else ["PLAYER","CARRY TIME","KOs","DEATHS","DAMAGE","THROWS"]
 if arcade and game.arena_world.shatter.active():headings=["PLAYER","POINTS","LAST ROUND","SHOVES","FALLS","STATUS"]
 for n in 6:
  var l:=label(grid,str(headings[n]),14);l.custom_minimum_size.x=float(widths[n]);l.autowrap_mode=TextServer.AUTOWRAP_OFF
 for member in game.fighters():
  var owner:String=str(member.get("id",""));var stats:Dictionary=game.contributions.get(owner,{})
  var l:=label(grid,str(member.get("name","Player")).left(18),17);l.custom_minimum_size.x=220;l.autowrap_mode=TextServer.AUTOWRAP_OFF
  var record:Dictionary=game.arena_records.get(owner,{})
  var values:Array=[game.pvp_scores.get(owner,0),record.get("deaths",0),stats.get("damage",0),stats.get("healing",0),record.get("best_kill_streak",0)] if game.mode=="arena" else [stats.get("damage",0),stats.get("healing",0),stats.get("revives",0),stats.get("defence",0),stats.get("upgrades",0)]
  if objective_mode:values=[objective.score_label(owner) if game.arena_map=="colour_clash" else "%.1fs" % float(objective.held.get(owner,0)),record.get("kills",0),record.get("deaths",0),stats.get("damage",0),objective.painted.get(owner,0) if game.arena_map=="colour_clash" else objective.passes.get(owner,0)]
  if arcade and game.arena_world.shatter.active():
   var shatter=game.arena_world.shatter;values=[shatter.points.get(owner,0),shatter.round_points.get(owner,0),shatter.shoves.get(owner,0),shatter.falls.get(owner,0),"OUT" if shatter.eliminated.has(owner) else "SURVIVED"]
  for n in 5:
   var value:=label(grid,str(values[n]) if objective_mode or arcade and game.arena_world.shatter.active() else str(int(values[n])),17);value.custom_minimum_size.x=float(widths[n+1]);value.autowrap_mode=TextServer.AUTOWRAP_OFF
func mastery_progress(id:String)->void:
 var rec:Dictionary=game.legacy.record(id)
 var spec:Dictionary=game.characters.get(id,{}).get("mastery",{})
 if game.legacy.final_eligible(id) and game.legacy.eligible(id):preload("res://scripts/ui_reward_icons.gd").row(content,"Both mastery techniques are available for this hero.","star",18);return
 var final:bool=game.legacy.eligible(id)
 var req:Dictionary=spec.get("final_requirements" if final else "technique_requirements",{})
 label(content,"NEXT: "+str(spec.get("final_technique" if final else "technique",{}).get("name","Mastery technique")),18)
 if req.has("duet_realm"):
  label(content,game.legacy.requirement_text(req),18);return
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",15);content.add_child(row)
 for item in [["Clears",int(rec.clears),int(req.get("clears",12 if final else 3))],["Different realms",rec.realms.size(),int(req.get("distinct_realms",6 if final else 2))],["Damage",int(rec.damage),int(req.get("damage",60000 if final else 5000))]]:
  var box:=VBoxContainer.new();box.custom_minimum_size.x=320;row.add_child(box)
  label(box,str(item[0])+" • "+str(item[1])+" / "+str(item[2]),15)
  var bar:=ProgressBar.new();bar.max_value=maxi(1,int(item[2]));bar.value=int(item[1]);bar.show_percentage=false;bar.custom_minimum_size.y=9;box.add_child(bar)
func replay_realm()->void:
 if arcade or page!="results":return
 if game.get("waylight")!=null and game.waylight.special():
  var tab=1 if game.waylight.between() else 2
  return_to_town();game.waylight.open(tab);return
 var realm:String=game.active_realm
 var was_trial:bool=game.trial
 close();game.respawn_clinic=false;game.gold=100;game.loadout.clear()
 game.start_run(was_trial,realm)

func return_to_town()->void:
 close();game.menu="";game.gold=100;game.character_id=game.selected_character;game.loadout.clear();game.enter_region("town")
func impact(player:bool,amount:float)->void:
 if amount>0:flash=maxf(flash,.16 if not player else .07)
func burst(point:Vector2,world:bool=true)->void:
 if rings.size()<16:rings.append({"pos":[point.x,point.y],"world":world,"age":0.0})
func paint()->void:
 var size:=get_viewport().get_visible_rect().size
 if not page.is_empty():panel.draw_rect(Rect2(Vector2.ZERO,size),Color(.02,.045,.055,.65))
func paint_feedback()->void:
 var size:=get_viewport().get_visible_rect().size
 if flash>0:
  var colour:=Color(1,.3,.22,flash*.4)
  feedback.draw_rect(Rect2(0,0,size.x,5),colour);feedback.draw_rect(Rect2(0,size.y-5,size.x,5),colour);feedback.draw_rect(Rect2(0,0,5,size.y),colour);feedback.draw_rect(Rect2(size.x-5,0,5,size.y),colour)
 for ring in rings:
  var p:Vector2=Vector2(float(ring.pos[0]),float(ring.pos[1]))-(game.camera if bool(ring.world) else Vector2.ZERO);var age:=float(ring.age)
  feedback.draw_arc(p,25+age*160,0,TAU,48,Color(.95,.77,.4,maxf(0,1-age)),4,true)
  for n in 12:
   var d:=Vector2.from_angle(n*TAU/12);feedback.draw_line(p+d*(20+age*90),p+d*(32+age*120),Color(.65,.9,.9,maxf(0,1-age)),3,true)

func sound_for(style:String)->String:
 if style in ["water_jet","fish_splash","tidal_maw","waterfall_wave","ricochet_projectile"]:return "water"
 if style in ["heal_wave","heal_zone","bloom_seed"]:return "heal"
 if style in ["block","shield_march","rally_banner","ice_wall"]:return "shield"
 if style in ["flame","fire_breath"]:return "flame"
 if style in ["hearth_combo","chain_sweep","rune_hammer","piston_jab","timber_fall"]:return "metal"
 if style in ["projectile","homing","burst_projectile","missile_volley","scatterlight"]:return "bow"
 if style in ["identity_strike","melee","slash","kick","scratch","charge","cat_sweep"]:return "swing"
 return "magic"
func combat_guide()->void:
 window("READ THE BATTLEFIELD","adventures")
 for line in ["! • Outlined danger / charge arc: an attack is preparing. Step out before impact.","+ • Green healing zone: allies can recover. It does not heal opposing players.","Purple + with ! • Enemy healing: interrupt the caster. It does not heal you.","Blue chevrons: slowed movement. White stars: stunned.","Orange flicker: burning. Red: bleeding. Purple: poison.","Shots have visible travel and direction. Solid walls stop ordinary projectiles.","Warnings show danger; they do not mean damage has already landed."]:label(content,line,21)
 button(content,"Back to adventures",adventures)
