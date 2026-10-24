extends CanvasLayer
## Session navigation. Live multiplayer simulation remains running behind this menu.
var game:Node
var arcade:=false
var page:=""
var backdrop:ColorRect
var panel:PanelContainer
var body:VBoxContainer
var message:Label
var menu_button:Button
var previous_menu:=""
var previous_shop:=""
var last_escape:=-1000
var options_return:="main"
var gallery:Control
var GAME_DOWNLOAD_URL=preload("res://scripts/brand.gd").download_url()
var display_font:Font=preload("res://assets/fonts/CrossroadsDisplay.ttf")
var ui_font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
func setup(owner:Node,multi:bool)->void:
 game=owner;arcade=multi;layer=55
 backdrop=ColorRect.new();backdrop.color=Color(.015,.04,.06,.88);backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.visible=false;add_child(backdrop)
 gallery=preload("res://scripts/menu_gallery.gd").new();gallery.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.add_child(gallery);gallery.setup(game,arcade);gallery.visible=false
 panel=PanelContainer.new();panel.size=Vector2(760,660);backdrop.add_child(panel)
 var skin:=StyleBoxFlat.new();skin.bg_color=Color("#112e37");skin.border_color=Color("#d7bc80");skin.set_border_width_all(2);skin.set_corner_radius_all(16);skin.set_content_margin_all(26);panel.add_theme_stylebox_override("panel",skin)
 body=VBoxContainer.new();body.add_theme_constant_override("separation",10);panel.add_child(body)
 menu_button=Button.new();menu_button.text="Menu";menu_button.size=Vector2(90,44);menu_button.position=Vector2(18,598);menu_button.pressed.connect(func():open("pause"));add_child(menu_button);preload("res://scripts/top_button_style.gd").apply(menu_button);menu_button.custom_minimum_size=Vector2(90,44)
func style(b:Button,tint:String)->void:
 b.add_theme_font_override("font",ui_font);b.add_theme_font_size_override("font_size",18);b.custom_minimum_size.y=64
 for state in ["normal","hover","pressed"]:
  var skin:=StyleBoxFlat.new();skin.bg_color=Color(tint).lightened(.12 if state=="hover" else -.08 if state=="pressed" else 0);skin.set_corner_radius_all(8);skin.set_content_margin_all(18);b.add_theme_stylebox_override(state,skin)
func text(value:String,size:int=18)->Label:
 var l:=Label.new();l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_override("font",ui_font);l.add_theme_font_size_override("font_size",size);l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;l.custom_minimum_size.y=size+18
 var margin=MarginContainer.new();margin.add_theme_constant_override("margin_top",5);margin.add_theme_constant_override("margin_bottom",5);body.add_child(margin);margin.add_child(l);return l
func button(value:String,action:Callable,tint:String="#345866")->Button:
 var b:=Button.new();b.text=value;b.pressed.connect(action);style(b,tint);body.add_child(b);return b
func in_town()->bool:return not arcade and game.mode=="town"
func open(kind:String)->void:
 if kind=="main" and not arcade and game.get("voyage")!=null and game.voyage.active:
  game.voyage.abandon(func():open("main"));return
 if page.is_empty():
  if arcade:previous_shop=game.shop_open;game.shop_open="Session"
  else:previous_menu=game.menu;game.menu="session"
 game.mobile.reset_controls();page=kind;backdrop.visible=true
 gallery.visible=kind in ["main","clear","options","download"];backdrop.color=Color("#081b27") if gallery.visible else Color(.015,.04,.06,.88)
 for child in body.get_children():body.remove_child(child);child.queue_free()
 var heading:=text("DOWNLOAD GAME" if kind=="download" else "OPTIONS" if kind=="options" else "CROSSROADS" if kind=="main" else "NEW ADVENTURE" if kind=="clear" else "KEEP YOUR ADVENTURE SAFE" if kind=="cloud_advice" else "YOUR ADVENTURE",30);heading.modulate=Color("#f2d699");heading.add_theme_font_override("font",display_font)
 if kind=="main":
  heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  var sub:=text("REALMS BEYOND",15);sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;sub.modulate=Color("#b1d5d3")
  var rule:=HSeparator.new();body.add_child(rule)
  text("Find your path. Create what’s next.",17).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 elif kind not in ["options","download","clear","cloud_advice"]:
  text("Live multiplayer continues while this menu is open." if arcade else "Take a moment. Your current adventure is paused.",18)
  button("Sound: OFF" if AudioServer.is_bus_mute(0) else "Sound: ON",func():game.presentation.toggle_sound();open(page))
 if kind=="download":
  text("PLAY THE WINDOWS EDITION",25).modulate=Color("#f2d699")
  text("Run Crossroads: Realms Beyond outside Chrome. This avoids the browser WebGL layer; graphics drivers and network access are still required.",18)
  text("1. Open the itch.io downloads below and choose the Windows ZIP.\n2. Extract the whole ZIP.\n3. Open Crossroads_Realms_Beyond.exe inside the extracted folder.",18)
  text("Keep the PCK and DLL folders with the EXE. Windows only — this is not an iPhone or Android download.",16)
  text("Keep your progress: Download profile in town, then Upload profile in the Windows game. Browser and Windows profiles are separate. Use the same game version for multiplayer.",16)
  var download_button=button("Open itch.io downloads" if not GAME_DOWNLOAD_URL.is_empty() else "Downloads • use the game’s itch.io page",open_game_download,"#3e7968");download_button.disabled=GAME_DOWNLOAD_URL.is_empty()
  button("Back to main menu",func():open("main"))
 elif kind=="options":
  build_options()
 elif kind=="clear":
  text("Welcome, new adventurer!",25)
  text("Start with every hero available and a short, skippable tutorial. This replaces the profile on this device, including mastery, town progress, photo portfolio, custom music, your entire mine and ALL custom heroes, enemies, abilities and behaviours built on this device. Download the current profile first if it belongs to you; your downloaded files stay safe.")
  button("START • enter tutorial",clear_profile,"#3e7968").grab_focus()
  button("Back • keep this profile",func():open("main"))
 elif kind=="cloud_advice":
  var account=game.get_node("/root/FXAccount")
  text("Take your adventure with you",26).modulate=Color("#f2d699")
  text("We recommend creating a cloud account so you can save your progress and return on another device. You can also keep playing with the profile on this device.",18)
  if not account.token.is_empty():text("You are signed in, but your cloud profile is not loaded yet. Choose Cloud account to load it, or continue with this device’s profile.",16)
  button("Continue without cloud account" if account.token.is_empty() else "Continue with this device’s profile",resume,"#345866")
  button("Create a cloud account" if account.token.is_empty() else "Open my cloud account",func():resume(false);account.open();account.mode="register" if account.token.is_empty() else "login";account.message="Welcome! Let’s make a home for your progress.";account.refresh(),"#416f91")
  button("Back to main menu",func():open("main"))
 elif kind=="main":
  var continue_button=button("CONTINUE • current profile",continue_with_profile,"#345866");continue_button.grab_focus()
  for state in ["normal","hover","pressed"]:
   var border=continue_button.get_theme_stylebox(state).duplicate();border.border_color=Color("#f2d699");border.set_border_width_all(2);continue_button.add_theme_stylebox_override(state,border)
  if not arcade:button("CLOUD ACCOUNT • sign in / save",func():resume(false);game.get_node("/root/FXAccount").open(),"#416f91")
  button("NEW GAME • start your adventure",func():request_clear(),"#3e7968")
  if not arcade:button("CROSSROADS STUDIO • create & test",func():resume(false);game.hero_workshop.open(),"#665e81")
  button("DOWNLOAD GAME • WINDOWS",func():open("download"),"#496681")
  text("YOUR PLAYER PROFILE",13).modulate=Color("#cbb98b")
  var transfers:=HBoxContainer.new();transfers.add_theme_constant_override("separation",12);body.add_child(transfers)
  for upload in [true,false]:
   var action:=Button.new();action.text="Upload profile" if upload else "Back up profile • new mastery" if preload("res://scripts/release_support.gd").backup_due(game.legacy) else "Download profile";action.size_flags_horizontal=Control.SIZE_EXPAND_FILL;style(action,"#345866");action.pressed.connect(func():profile_action(upload));transfers.add_child(action)
  var daily_button:=button("DAILY MISSION\n"+str(game.legacy.daily.task().title),func():resume(false);game.legacy.daily.quick_play(),"#665e41");daily_button.add_theme_font_size_override("font_size",16);daily_button.custom_minimum_size.y=62
  text("Returning? Upload your profile. Before leaving a shared computer, download it; the next player can choose New game.",14).modulate=Color("#b3c7c5")
  var settings_row:=HBoxContainer.new();settings_row.add_theme_constant_override("separation",12);body.add_child(settings_row)
  var sound:=Button.new();sound.text="Sound: OFF" if AudioServer.is_bus_mute(0) else "Sound: ON";sound.size_flags_horizontal=Control.SIZE_EXPAND_FILL;style(sound,"#345866");sound.pressed.connect(func():game.presentation.toggle_sound();open(page));settings_row.add_child(sound)
  var settings:=Button.new();settings.text="Options";settings.size_flags_horizontal=Control.SIZE_EXPAND_FILL;style(settings,"#567269");settings.pressed.connect(show_options);settings_row.add_child(settings)
  var classroom:=Button.new();classroom.text="Demo Broadcast";classroom.size_flags_horizontal=Control.SIZE_EXPAND_FILL;style(classroom,"#665e81");classroom.pressed.connect(func():get_tree().root.get_node("FXClassroom").open_join());settings_row.add_child(classroom)

 else:
  button("Back to voyage" if not arcade and game.get("voyage")!=null and game.voyage.active else "Resume adventure",resume,"#3e7968")
  button("End voyage…" if not arcade and game.get("voyage")!=null and game.voyage.active else "Exit to town",town,"#6b587a")
  button("Options",show_options)
  if preload("res://scripts/education_access.gd").student() or preload("res://scripts/education_access.gd").review_allowed():button("Education Guide",func():resume();load("res://scripts/education_guide.gd").open(game.legacy))
  if preload("res://scripts/education_access.gd").review_allowed():button("Teacher • class view",func():resume();load("res://scripts/teacher_dashboard.gd").open(game.legacy))
  button("Main menu",func():open("main"))
  text("Leaving ends this voyage. All unbanked fish, release XP and deployed cages are lost. Sail home to bank them instead." if not arcade and game.get("voyage")!=null and game.voyage.active else "Exiting to town ends this attempt. If you host a live room, leaving disconnects your party.",16)
 if kind=="options":make_options_scroll()
 message=text("",17);message.modulate=Color("#f4cf8b");menu_button.visible=false;layout_panel()
func make_options_scroll()->void:
 var children:=body.get_children()
 if children.size()<3:return
 var scroll:=ScrollContainer.new();scroll.custom_minimum_size.y=430;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 var col:=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.add_theme_constant_override("separation",10);scroll.add_child(col)
 for index in range(1,children.size()-1):body.remove_child(children[index]);col.add_child(children[index])
 body.add_child(scroll);body.move_child(scroll,1)
func open_game_download()->void:
 if GAME_DOWNLOAD_URL.is_empty():message.text="Open the game’s itch.io page and choose Download.";return
 var result:=OS.shell_open(GAME_DOWNLOAD_URL)
 message.text="Choose the Windows ZIP in itch.io’s Download section. If no Windows file is listed, it has not been published yet." if result==OK else "Could not open downloads. Open the game’s itch.io page in your browser and choose Download."
func show_options()->void:
 options_return=page if page in ["main","pause"] else "main";open("options")
func build_options()->void:
 var stability:Node=get_tree().root.get_node("FXStability")
 text("Tune performance and sound for this device.",18)
 text("FRAME RATE",16).modulate=Color("#f2d699")
 var fps:=OptionButton.new();fps.custom_minimum_size.y=48;fps.add_theme_font_override("font",ui_font);fps.add_theme_font_size_override("font_size",18);body.add_child(fps)
 var limits:Array=[30,60,120]
 for value in limits:fps.add_item(str(value)+" FPS"+(" • school / battery" if value==30 else " • smooth" if value==60 else " • high-end PCs"))
 fps.select(limits.find(stability.fps_limit));fps.item_selected.connect(func(index:int):stability.set_fps(limits[index]))
 button("School performance: ON" if stability.school_mode else "School performance: OFF",func():stability.toggle();open("options"),"#567269")
 text("School mode lowers resolution and cosmetic limits; resets to 30 or 60 FPS.",15)
 button("Sound: OFF" if AudioServer.is_bus_mute(0) else "Sound: ON",func():game.presentation.toggle_sound();open("options"))
 var recording:=CheckButton.new();recording.text="Record local crash diagnostics";recording.custom_minimum_size.y=44;recording.button_pressed=stability.diagnostics_enabled;recording.toggled.connect(func(value:bool):stability.set_diagnostics(value));body.add_child(recording)
 var activity=get_tree().root.get_node("FXActivity")
 var consent=CheckButton.new();consent.text="Share anonymous activity counts";consent.custom_minimum_size.y=44;consent.button_pressed=activity.enabled;consent.toggled.connect(activity.set_enabled);body.add_child(consent)
 text("Anonymous reports summarize playtime, completions and performance. No names, creations or schoolwork are uploaded. Optional crash downloads remain on this device.",15)
 button("Run diagnostics / speed test",func():
  var test=preload("res://scripts/device_test.gd").new();add_child(test);test.setup(game)
 )
 button("Download diagnostic report",func():stability.download())
 if game.get("version_check")!=null:
  text(game.version_check.status,16)
  button("Check for game updates",func():game.version_check.check();message.text="Checking latest release — reopen Options to see status.")
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);body.add_child(row)
 for pair in [["Copy bug-report details",copy_bug_report],["Student playtest notebook",open_notebook]]:
  var b:=Button.new();b.text=pair[0];b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.pressed.connect(pair[1]);style(b,"#345866");row.add_child(b)
 body.move_child(row,2)
 var guide:=CheckButton.new();guide.text="Optional melee reach guides";guide.custom_minimum_size.y=44;guide.button_pressed=game.adventure.combat.feedback.guides;guide.toggled.connect(game.adventure.combat.feedback.set_guides);body.add_child(guide)
 text("Bright contact sparks confirm damage. Green + confirms healing. Faint blue reach guides are optional; terrain can block hits. Give copied reports to your teacher — nothing is sent automatically.",15)
 button("Back",func():open(options_return),"#3e7968")
func copy_bug_report()->void:
 preload("res://scripts/release_support.gd").copy_text(preload("res://scripts/release_support.gd").bug_report(game));message.text="Copy requested. Paste into your report and add reproduction steps. Use the notebook's Download if clipboard access is blocked."
func open_notebook()->void:
 if not arcade and game.menu=="workshop":return
 if get_node_or_null("PlaytestNotebook")!=null:return
 var notebook=preload("res://scripts/playtest_notebook.gd").new();add_child(notebook);notebook.setup(game)
func resume(_offer_tutorial:bool=false)->void:
 get_tree().root.set_meta("fx_tutorial_offered",true)
 page="";backdrop.visible=false;game.mobile.reset_controls()
 if arcade:game.shop_open=previous_shop
 else:
  game.menu=previous_menu
  if previous_menu=="presentation" and game.presentation.page.is_empty():game.menu=""

func town()->void:
 if not arcade and game.get("voyage")!=null and game.voyage.active:
  game.voyage.abandon();return
 if arcade:game._town();return
 if game.tutorial.active:game.tutorial.finish(false,true)
 game.presentation.close();game.legacy.close();game.menu="";game.gold=100;game.character_id=game.selected_character;game.loadout.clear();game.enter_region("town");previous_menu="";resume()
func profile_action(upload:bool)->void:
 if preload("res://scripts/profile_store.gd").testing():message.text="Exit game Dev mode before changing or transferring profiles.";return
 if not in_town():message.text="Return to town before uploading or downloading a profile.";return
 resume(false);game.presentation.close();game.legacy.open_page("profile")
 if upload:game.legacy.pick_import()
 else:game.legacy.export_profile()
func request_clear()->void:
 if preload("res://scripts/profile_store.gd").testing():message.text="Exit game Dev mode before changing or transferring profiles.";return
 if not in_town():message.text="Return to town before starting a new player or clearing the profile.";return
 open("clear")
func clear_profile()->void:
 var account=game.get_node_or_null("/root/FXAccount")
 if account!=null and account.loaded:message.text="Sign out of your cloud account before starting a new local profile.";return
 if preload("res://scripts/profile_store.gd").testing():message.text="Exit game Dev mode before changing or transferring profiles.";return
 if not in_town():return
 if get_tree().root.has_meta("fx_local_recovery"):get_tree().root.remove_meta("fx_local_recovery")
 var store=preload("res://scripts/profile_store.gd")
 for file in game.legacy.save_names():store.erase("user://"+str(file))
 store.erase(game.legacy.PATH)
 store.erase("user://fx_playtest_notes.json")
 store.erase(preload("res://scripts/music_library.gd").PATH)
 for studio_file in ["fx_studio_library.json","fx_workshop_project.json","fx_workshop_project.json.previous","fx_ability_lab.json","fx_enemy_lab.json","fx_behavior_lab.json","fx_object_lab.json","fx_realm_lab.json"]:DirAccess.remove_absolute("user://"+studio_file)
 for key in ["fx_hero","fx_inspect_hero","fx_retry_realm","fx_clinic","fx_tutorial_offered"]:
  if get_tree().root.has_meta(key):get_tree().root.remove_meta(key)
 if get_tree().root.has_meta("fx_show_main"):get_tree().root.remove_meta("fx_show_main")
 get_tree().root.set_meta("fx_start_tutorial",true)
 # Do not save stale in-memory progress after the reset.
 game.set_process(false);game.legacy.set_process(false);game.presentation.set_process(false)
 get_tree().reload_current_scene()
func _input(event:InputEvent)->void:
 var dev:Node=get_tree().root.get_node_or_null("FXDevSession")
 if dev!=null and dev.active and dev.tools.opened:return
 if get_node_or_null("PlaytestNotebook")!=null:return
 if game==null or not event is InputEventKey or not event.pressed or event.echo or event.keycode!=KEY_ESCAPE or game.has_node("FXIntro"):return
 var now:=Time.get_ticks_msec()
 if not page.is_empty():
  if page=="options":open(options_return)
  else:resume()
  last_escape=-1000;get_viewport().set_input_as_handled();return
 if now-last_escape<=450:open("pause");last_escape=-1000;get_viewport().set_input_as_handled()
 else:last_escape=now
func _process(_delta:float)->void:
 if game==null:return
 menu_button.custom_minimum_size.y=44
 menu_button.size.y=menu_button.custom_minimum_size.y
 menu_button.position=Vector2(get_viewport().get_visible_rect().size.x-585,8) if not arcade else Vector2(get_viewport().get_visible_rect().size.x*.5-menu_button.size.x*.5,51-menu_button.size.y*.5) if not game.started else Vector2(get_viewport().get_visible_rect().size.x-(415 if game.spectating() else 330),8)
 if not arcade and game.mode=="town":preload("res://scripts/town_top_bar.gd").place(menu_button,"menu",get_viewport().get_visible_rect().size)
 if (arcade and game.started and not game.spectating()) or (not arcade and game.mode=="run"):
  menu_button.scale=Vector2.ONE;menu_button.custom_minimum_size=Vector2(78,34);menu_button.size=Vector2(78,34);menu_button.position=Vector2(get_viewport().get_visible_rect().size.x-365,8)
 menu_button.visible=page.is_empty() and not game.has_node("FXIntro") and game.presentation.page.is_empty() and (arcade or game.menu.is_empty())
 if not arcade and not game.has_node("FXIntro") and get_tree().root.has_meta("fx_show_main"):
  get_tree().root.remove_meta("fx_show_main");game.presentation.asked=true;open("main")
 if not page.is_empty():layout_panel()
func layout_panel()->void:
 if page=="clear":
  panel.size=Vector2(680,maxf(330,body.get_combined_minimum_size().y+52))
 else:
  panel.size=Vector2(520,maxf(640,body.get_combined_minimum_size().y+52)) if page=="main" else Vector2(760,maxf(660,body.get_combined_minimum_size().y+52))
 var view:=get_viewport().get_visible_rect().size;var scale_factor:=minf(1,minf((view.x-24)/panel.size.x,(view.y-24)/panel.size.y));panel.scale=Vector2.ONE*scale_factor;panel.position=(view-panel.size*panel.scale)*.5
 panel.position.y=maxf(12,panel.position.y)

func continue_with_profile()->void:
 if arcade:resume();return
 var account=game.get_node("/root/FXAccount")
 if account.loaded and not account.token.is_empty():resume()
 else:open("cloud_advice")
