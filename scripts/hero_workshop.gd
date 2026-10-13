extends CanvasLayer
## Crossroads Studio: declarative project editor + independent test/report workspace.
const UI=preload("res://scripts/studio_ui.gd")
const Project=preload("res://scripts/workshop_project.gd")
var game:Node
var project:Dictionary={}
var backdrop:ColorRect
var panel:PanelContainer
var body:VBoxContainer
var content:VBoxContainer
var notice:Label
var tabs:TabBar
var preview:TextureRect
var arena:Control
var test_panel:PanelContainer
var test_stats:Label
var report_text:TextEdit
var native_dialog:FileDialog
var web_callback:JavaScriptObject
var transfer_kind:="project"
var active:=false
var previous_menu:=""
var world_visible:=true
var techniques=[false,false]
var scene:="Cluster"
var latest_report:Dictionary={}
var dirty:=false
var autosave:float=0
var last_metrics:float=0
var test_controls:Array=[]
var lab:Node
var hub:PanelContainer
var room:Node
var passive_preview:Control
func setup(owner:Node)->void:
 game=owner;layer=65
 backdrop=ColorRect.new();backdrop.color=Color("#071c27");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop);backdrop.hide()
 panel=PanelContainer.new();panel.size=Vector2(1140,680);add_child(panel);skin(panel);panel.hide()
 body=VBoxContainer.new();body.add_theme_constant_override("separation",12);panel.add_child(body)
 var title=HBoxContainer.new();body.add_child(title);label(title,"CROSSROADS STUDIO • HERO WORKSHOP",24).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button(title,"Journey",func():save_draft();load("res://scripts/studio_showcase.gd").open(self));button(title,"Partner up",func():get_tree().root.get_node("FXStudioPartner").open(self));button(title,"Close",close)
 var tools=HBoxContainer.new();body.add_child(tools)
 button(tools,"Clear / Start fresh",confirm_new);button(tools,"Open project",func():choose_file("project"));button(tools,"Download project",export_project);button(tools,"Save draft",save_draft)
 button(tools,"Playtest",start_test);button(tools,"Finalize & Play",play_draft)
 var examples=HBoxContainer.new();body.add_child(examples);preload("res://scripts/studio_examples.gd").picker(examples,"hero",func(value:Dictionary):project=value;latest_report={};techniques=[false,false];save_draft();render())
 tabs=TabBar.new();body.add_child(tabs)
 for tab in ["Hero","Artwork","Abilities","Passive","Mastery","Playtest","Tests & reports"]:tabs.add_tab(tab)
 tabs.tab_changed.connect(func(index:int):if index==5:start_test()
 else:render())
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;body.add_child(scroll)
 content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",10);scroll.add_child(content)
 var touch=preload("res://scripts/touch_list_scroll.gd").attach(scroll);touch.form_controls=true
 notice=label(body,"",15);notice.modulate=Color("#e7cf91")
 label(body,"Download project to share one hero. Download profile ZIP to back up your Custom Hall and saved abilities.",14)
 test_panel=PanelContainer.new();test_panel.size=Vector2(1180,680);add_child(test_panel);skin(test_panel);test_panel.hide()
 if OS.has_feature("web"):
  web_callback=JavaScriptBridge.create_callback(web_import);JavaScriptBridge.get_interface("window").fxWorkshopImport=web_callback
func skin(p:PanelContainer)->void:
 UI.apply(p)
func label(parent:Node,value:String,font_size:int=17)->Label:
 var l=Label.new();l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",font_size);parent.add_child(l);return l
func button(parent:Node,value:String,action:Callable)->Button:
 var b=Button.new();b.text=value;b.custom_minimum_size=Vector2(0,42);b.add_theme_font_size_override("font_size",17);b.pressed.connect(action);parent.add_child(b)
 b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 return b
func clear(node:Node)->void:
 for child in node.get_children():node.remove_child(child);child.queue_free()
func open(classroom:bool=false)->void:
 if active:
  if classroom:enter_classroom()
  return
 active=true;previous_menu=game.menu;world_visible=game.visible;game.hide();game.menu="workshop";game.mobile.reset_controls()
 if project.is_empty():
  var draft=preload("res://scripts/studio_examples.gd").random_example("hero")
  var stored=preload("res://scripts/profile_store.gd").read(Project.PATH,func(v:Dictionary)->bool:return Project.validate(v).is_empty())
  if not stored.is_empty():draft=stored
  project=draft
 backdrop.show();panel.show();game.queue_redraw();render()
 if classroom:enter_classroom()
 else:show_hub()
 notice.text="Local draft ready. Clear / Start fresh creates a blank project; use Load an example to explore five different designs."
func close()->void:
 for child in get_children():
  if child.get_script() in [preload("res://scripts/studio_enemy_lab.gd"),preload("res://scripts/studio_behavior_lab.gd")]:child.queue_free()
 if arena!=null and arena.time>0:finish_test()
 if is_instance_valid(hub):hub.hide()
 if is_instance_valid(lab):lab.queue_free()
 if is_instance_valid(room):room.queue_free()
 save_draft();active=false;backdrop.hide();panel.hide();test_panel.hide();game.menu=previous_menu;game.visible=world_visible;game.mobile.reset_controls();game.queue_redraw()
 if is_instance_valid(arena):arena.running=false;arena.cancel_holds()
func confirm_new()->void:
 var dialog=ConfirmationDialog.new();dialog.title="Start a new hero project?";dialog.dialog_text="Download this project first if you want to keep it. New replaces only the local workshop draft; your player profile is unchanged.";dialog.ok_button_text="Start new project";add_child(dialog)
 dialog.confirmed.connect(func():project=Project.fresh();latest_report={};techniques=[false,false];dirty=true;save_draft();render();dialog.queue_free())
 dialog.canceled.connect(dialog.queue_free);UI.apply(dialog);dialog.popup_centered(Vector2i(580,220))
func edited(build_change:bool=true)->void:
 preload("res://scripts/studio_balance.gd").enforce_hero(project)
 if content!=null:balance_values(content)
 if build_change:project.revision=int(project.revision)+1
 dirty=true;autosave=.5
func save_draft()->void:
 if project.is_empty():return
 var error=Project.validate(project)
 if not error.is_empty():notice.text="Draft not saved: "+error;autosave=2;return
 var result=preload("res://scripts/profile_store.gd").write(Project.PATH,project,"",func(v:Dictionary)->bool:return Project.validate(v).is_empty())
 dirty=result!=OK;autosave=2;notice.text="Draft saved on this device • revision "+str(int(project.revision)) if result==OK else "Draft save failed. Download your project."
 var warnings=Project.warnings(project)
 if result==OK:
  var library_issue=preload("res://scripts/studio_library.gd").add_hero(project)
  notice.text+=" • Ready in Custom heroes" if library_issue.is_empty() else " • "+library_issue
 if result==OK and not warnings.is_empty():notice.text+=" • "+warnings[0]
func line(parent:Node,caption:String,data:Dictionary,key:String,limit:int=60)->void:
 var row=HBoxContainer.new();parent.add_child(row);label(row,caption,16).custom_minimum_size.x=180
 var edit=LineEdit.new();edit.text=str(data.get(key,""));edit.max_length=limit;edit.size_flags_horizontal=Control.SIZE_EXPAND_FILL;edit.custom_minimum_size.y=40;row.add_child(edit)
 edit.text_changed.connect(func(value:String):data[key]=value;edited())
func note(parent:Node,caption:String,data:Dictionary,key:String,limit:int=1000)->void:
 label(parent,caption,17)
 var edit=TextEdit.new();edit.text=str(data.get(key,""));edit.custom_minimum_size.y=86;edit.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY;parent.add_child(edit)
 edit.text_changed.connect(func():
  if edit.text.length()>limit:edit.text=edit.text.left(limit)
  data[key]=edit.text;edited(key not in ["hypothesis","method","observations","next_change"]))
func choice(parent:Node,caption:String,data:Dictionary,key:String,options:Dictionary,rerender:bool=false)->OptionButton:
 var row=HBoxContainer.new();parent.add_child(row);label(row,caption,16).custom_minimum_size.x=180
 var option=OptionButton.new();option.fit_to_longest_item=false;option.size_flags_horizontal=Control.SIZE_EXPAND_FILL;option.custom_minimum_size.y=42;row.add_child(option)
 var keys=options.keys()
 for k in keys:option.add_item(str(options[k]))
 option.select(maxi(0,keys.find(data.get(key))))
 option.item_selected.connect(func(index:int):data[key]=keys[index];edited();if rerender:render())
 return option
func number(parent:Node,caption:String,data:Dictionary,key:String,lo:float,hi:float,step:float)->void:
 var row=HBoxContainer.new();parent.add_child(row);label(row,caption,16).custom_minimum_size.x=180
 var slider=HSlider.new();slider.min_value=lo;slider.max_value=hi;slider.step=step;slider.value=float(data[key]);slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;slider.custom_minimum_size.x=160;row.add_child(slider)
 var spin=SpinBox.new();spin.min_value=lo;spin.max_value=hi;spin.step=step;spin.value=float(data[key]);spin.custom_minimum_size.x=100;row.add_child(spin)
 slider.set_meta("balance_data",data);slider.set_meta("balance_key",key);spin.set_meta("balance_data",data);spin.set_meta("balance_key",key)
 slider.value_changed.connect(func(value:float):data[key]=value;spin.set_value_no_signal(value);edited())
 spin.value_changed.connect(func(value:float):data[key]=value;slider.set_value_no_signal(value);edited())
func render()->void:
 clear(content)
 preload("res://scripts/studio_balance.gd").toggle(content,project,func():edited();render())
 if preload("res://scripts/education_access.gd").student():button(content,"Student Mode • learning journal",func():game.legacy.learning_open())
 if preload("res://scripts/education_access.gd").student():button(content,"Finalize & submit to active module",func():notice.text=preload("res://scripts/studio_finalize.gd").submit("hero",project,str(project.hero.name)))
 if project.get("forced_balance",false):label(content,"CHECKED BUDGET • Raising damage or reach lengthens cooldown. More health / protection lowers movement. Re-test after each trade-off.",15)
 match tabs.current_tab:
  0:
   label(content,"1 • Hero details",24)
   line(content,"Project author",project,"author",100);line(content,"Hero name",project.hero,"name")
   choice(content,"Role",project.hero,"role",{"Melee":"Melee","Ranged":"Ranged","Support":"Support","Summoner":"Summoner","Control":"Control"})
   line(content,"Species / object",project.hero,"species",100);note(content,"Lore (optional)",project.hero,"lore")
   if preload("res://scripts/education_access.gd").student():note(content,"Design concept • what should make playing this hero interesting?",project,"concept")
   if not project.hero.has("defence"):project.hero.defence=0.0
   if not project.hero.has("balance_tradeoff"):project.hero.balance_tradeoff="speed"
   choice(content,"Health trade-off",project.hero,"balance_tradeoff",{"speed":"Pay with movement speed","defence":"Use defence first, then speed"})
   number(content,"Defence (0.1 = 10%)",project.hero,"defence",0,.25,.01)
   number(content,"Health",project.hero,"max_health",70,200,5);number(content,"Movement speed",project.hero,"speed",100,300,5)
  1:
   label(content,"2 • Bring your hero to life",24);label(content,"Upload four PNG poses. Maximum 256 × 256 pixels and 128 KB each. Transparent 64 × 64 pixel art works well. Artwork travels inside your project file.")
   var row=HBoxContainer.new();content.add_child(row)
   for pose in ["idle","walk1","walk2","attack"]:
    var frame=PanelContainer.new();frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL;frame.add_theme_stylebox_override("panel",UI.box("#183945","#355b68",10,12));row.add_child(frame);var box=VBoxContainer.new();frame.add_child(box);label(box,pose.capitalize())
    var pic=TextureRect.new();pic.custom_minimum_size=Vector2(128,128);pic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;pic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;pic.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;box.add_child(pic)
    if project.hero.art.has(pose):
     var image=Image.new();image.load_png_from_buffer(Marshalls.base64_to_raw(project.hero.art[pose]));pic.texture=ImageTexture.create_from_image(image)
    button(box,"Edit pixels",edit_pixels.bind(pose));button(box,"Upload PNG",choose_file.bind(pose));button(box,"Remove",func():project.hero.art.erase(pose);edited();render())
   var animated=preload("res://scripts/studio_animation.gd").new();content.add_child(animated);animated.setup([project.hero.art.get("walk1",project.hero.art.get("idle","")),project.hero.art.get("walk2",project.hero.art.get("idle",""))])
   label(content,"LIVE WALK • alternates Walk 1 / Walk 2. Keep the face and contact point aligned; change feet, wings or body tilt by a few pixels.")
   alternate_form_editor(content)
   button(content,"Design lesson • elements, principles & balance",design_lesson)
  2:
   label(content,"3 • Choose attacks, then tune their trade-offs",24);label(content,"All listed types work in this test arena. Saved Ability Lab programs appear in the Custom section below each behaviour selector.")
   for kind in Project.KINDS:
    var fold=UI.card(content,"")
    var detail=VBoxContainer.new();detail.visible=false
    button(fold,kind.capitalize()+" • "+str(project.hero[kind].name)+"  ▾",func():detail.visible=not detail.visible)
    fold.add_child(detail);attack_editor(detail,project.hero[kind])
  3:
   label(content,"4 • Passive",24);choice(content,"Always-on bonus",project.hero,"passive",Project.PASSIVES)
   var aura=CheckButton.new();aura.text="Aura • affect the area around this hero";aura.button_pressed=bool(project.hero.get("passive_aura",false));content.add_child(aura);aura.toggled.connect(func(value:bool):project.hero.passive_aura=value;edited())
   if not project.hero.has("passive_radius"):project.hero.passive_radius=100.0
   number(content,"Aura radius",project.hero,"passive_radius",40,180,5)
   label(content,"Aura works with Mending (heal nearby allies), Frost (slow nearby foes) and Shelter (protect nearby allies). Overload uses radius for its pulse. On-hit and personal passives stay personal. Status, defence and aura bonuses are deliberately bounded.")
  4:
   label(content,"5 • Two mastery alternatives",24);label(content,"Change two DIFFERENT ability slots. Alternatives replace the selected attack during playtesting; they should offer a new choice, rather than always being stronger.")
   for index in 2:
    var t:Dictionary=project.techniques[index];label(content,"Technique "+str(index+1),22);line(content,"Technique name",t,"name")
    choice(content,"Replaces",t,"slot",{"primary":"Primary","secondary":"Secondary","special":"Special"})
    var fold=VBoxContainer.new();content.add_child(fold);var detail=VBoxContainer.new();detail.hide();button(fold,"Edit alternative ability ▾",func():detail.visible=not detail.visible);fold.add_child(detail);attack_editor(detail,t.attack)
    var check=CheckButton.new();check.text="Use technique "+str(index+1)+" in next test";check.button_pressed=bool(techniques[index]);check.toggled.connect(func(value:bool):techniques[index]=value);content.add_child(check)
  6:
   label(content,"6 • Test & compare",24)
   var config={"scene":scene};var scene_option=choice(content,"Test scenario",config,"scene",{"Cluster":"Stationary target cluster","Moving targets":"Moving targets","Combat":"Slow attackers + projectiles"});scene_option.item_selected.connect(func(_index:int):scene=config.scene)
   if preload("res://scripts/education_access.gd").student():note(content,"Prediction • what are you trying to test?",project.notes,"hypothesis",3000)
   if preload("res://scripts/education_access.gd").student():note(content,"Method • what will you do, and what will you measure?",project.notes,"method",3000)
   if preload("res://scripts/education_access.gd").student():note(content,"Observations • what happened?",project.notes,"observations",3000)
   if preload("res://scripts/education_access.gd").student():note(content,"Next change • what would you improve, and why?",project.notes,"next_change",3000)
   var report_actions=HBoxContainer.new();content.add_child(report_actions)
   button(report_actions,"Start test",start_test);button(report_actions,"View latest report",view_report);button(report_actions,"Download report",export_readable_report);button(report_actions,"Download report data",export_report)
   button(content,"Compare my last two tests",compare_tests)
   label(content,"Stored tests: "+str(project.reports.size())+" / 20 (oldest removed when full).",16)
   for r in project.reports.duplicate():
    button(content,str(r.get("date_utc",""))+" • rev "+str(r.get("revision",0))+" • "+str(r.get("scenario",""))+" • damage "+str(r.get("damage",0))+" / healing "+str(r.get("healing",0)),func():latest_report=r.duplicate(true);view_report())
 var warnings=Project.warnings(project)
 if not warnings.is_empty():label(content,"Design checks • "+"\n".join(warnings),15).modulate=Color("#eac38f")
func attack_editor(parent:Node,a:Dictionary)->void:
 line(parent,"Ability name",a,"name")
 var forms={"":"Normal appearance"}
 for id in project.hero.get("alternate_forms",{}):forms[id]=project.hero.alternate_forms[id].name
 if not a.has("form_id"):a.form_id="";a.form_duration=3.0
 choice(parent,"Transform into",a,"form_id",forms)
 number(parent,"Form duration (s)",a,"form_duration",.2,8,.2)
 var fields=VBoxContainer.new()
 var source=CheckButton.new();source.text="Custom abilities • from your Ability Lab";source.button_pressed=a.style=="custom";parent.add_child(source)
 var builtin=VBoxContainer.new();parent.add_child(builtin)
 var builtin_styles=Project.STYLES.duplicate();builtin_styles.erase("custom")
 var type_menu=choice(builtin,"Built-in behaviour",a,"style",builtin_styles)
 builtin.visible=not source.button_pressed
 type_menu.item_selected.connect(func(_index:int):
  if a.style=="custom" and not a.has("program"):a.program=preload("res://scripts/studio_script.gd").template(a)
  attack_fields(fields,a)
 )
 var color_row=HBoxContainer.new();parent.add_child(color_row);label(color_row,"Effect colour",16).custom_minimum_size.x=180
 var color=ColorPickerButton.new();color.color=Color(a.color);color.custom_minimum_size=Vector2(150,40);color_row.add_child(color);color.color_changed.connect(func(value:Color):a.color="#"+value.to_html(false);edited())
 var custom=preload("res://scripts/studio_library.gd").load_data().abilities
 var saved=VBoxContainer.new();parent.add_child(saved);saved.visible=source.button_pressed
 source.toggled.connect(func(on:bool):
  builtin.visible=not on;saved.visible=on
  if not on and a.style=="custom":a.style="melee";edited();attack_fields(fields,a)
  fields.visible=not on or a.style=="custom"
 )
 if custom.is_empty():label(saved,"Save an ability in the Lab, then choose it here.",16)
 if not custom.is_empty():
  var menu=OptionButton.new();menu.add_item("Custom • choose a saved lab ability…");saved.add_child(menu)
  for key in custom:menu.add_item(str(key))
  menu.item_selected.connect(func(index:int):
   if index>0:
    a.clear();a.merge(custom[menu.get_item_text(index)].duplicate(true))
    if not project.hero.get("alternate_forms",{}).has(str(a.get("form_id",""))):a.form_id=""
    edited();render()
  )
 parent.add_child(fields);attack_fields(fields,a);fields.visible=not source.button_pressed or a.style=="custom"
func attack_fields(parent:Node,a:Dictionary)->void:
 clear(parent)
 var style=str(a.style)
 if style=="custom":
  label(parent,"Ability Lab program • "+str(a.get("program","")).split("\n")[0],15)
  button(parent,"Open Ability Lab",func():open_lab(a))
  return
 var heal=style in ["heal_wave","heal_zone"]
 var keys:Array=["cooldown"]
 if style in ["burst","ring_shots","vortex","poison_zone","blink","siphon","burn_zone","stun_zone","buff_zone"]:keys=["cooldown","range","radius","speed","count","duration","charge"]
 if style!="block":keys.append("heal" if heal else "damage")
 if style in ["melee","projectile","spread","homing","boomerang","beam","chain","target_aoe","dash","trap","heal_zone","slow_aura","flame"]:keys.append("range")
 if style in ["spin","beam","target_aoe","trap","heal_wave","heal_zone","slow_aura"]:keys.append("radius")
 if style in ["projectile","spread","homing","boomerang","target_aoe"]:keys.append("speed")
 if style in ["spread","chain","summon"]:keys.append("count")
 if style in ["summon","trap","heal_zone","block","slow_aura","burn_zone","stun_zone","buff_zone"]:keys.append("duration")
 if style not in ["flame","block"]:keys.append("charge")
 if style=="buff_zone":
  if not a.has("buff"):a.buff="defence"
  choice(parent,"Aura bonus",a,"buff",preload("res://scripts/studio_options.gd").BUFFS)
 for key in keys:
  var bounds:Array=Project.LIMITS[key];number(parent,key.replace("_"," ").capitalize(),a,key,float(bounds[0]),float(bounds[1]),float(bounds[2]))
 if not heal and style not in ["block","slow_aura"]:
  var options={}
  for status in Project.STATUS:options[status]=status.capitalize()
  choice(parent,"On-hit effect",a,"status",options)
  for key in ["status_duration","status_damage"]:
   var bounds:Array=Project.LIMITS[key];number(parent,key.replace("_"," ").capitalize(),a,key,float(bounds[0]),float(bounds[1]),float(bounds[2]))
 var descriptions={
  "melee":"A directional sweep in front of the hero. Range sets its reach; each click hits each target once.",
  "projectile":"One visible projectile stops on the first target. Range limits travel; speed controls flight.",
  "spread":"A fan of projectiles. Damage is PER projectile, so count can greatly increase close-range damage.",
  "homing":"A projectile curves towards the closest living target. It stops on contact.",
  "boomerang":"A blade goes out and comes back; each target can be hit once on each leg.",
  "beam":"A straight beam passes through targets. Radius sets beam half-width at one quarter of this value.",
  "spin":"An expanding ring hits all nearby targets once. Radius is the attack reach.",
  "chain":"Jump to the nearest target, then to new targets. Count limits hits; range limits each jump.",
  "target_aoe":"Aim a landing spot within range. A visible shot travels there, then explodes within radius.",
  "flame":"Hold to sustain a directional cone. Damage is PER SECOND, applied every 0.2s. Release starts cooldown.",
  "dash":"Strike along the line to the aimed point, then move there. Range limits distance.",
  "trap":"Place a visible mine at your aim point. It detonates when a target enters its radius, or expires.",
  "summon":"Summon up to five allies total. Each has 40 HP, attacks once a second, and expires after duration. Combat targets can hurt them.",
  "heal_wave":"Heal self and the green allied target inside radius. Healing counts only health actually recovered.",
  "heal_zone":"Place a field that heals every 0.5 seconds. Duration and heal amount together control total recovery.",
  "block":"Reduce incoming damage by 60% for duration. Use Combat scenario to measure the protection.",
  "slow_aura":"Place a field that slows targets and deals one quarter of damage every 0.5 seconds."
 }
 label(parent,str(descriptions.get(style,"")),15)
 label(parent,"Charge 0 = instant. Hold/release a charged ability for up to 60% extra damage, 30% extra healing and 20% extra radius. Stun stops movement/attacks; slow reduces speed; burn, poison and bleed deal status damage per second. Unused settings are retained if you switch types.",14)
func start_test()->void:
 var error=Project.validate(project)
 if not error.is_empty():notice.text="Fix before testing: "+error;return
 save_draft();latest_report={};panel.hide();test_panel.show();clear(test_panel)
 var column=VBoxContainer.new();test_panel.add_child(column)
 var top=HBoxContainer.new();column.add_child(top);label(top,str(project.hero.name)+" • "+scene,22).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button(top,"Reset test",restart_test);button(top,"Finish & report",finish_test)
 var info=label(column,"WASD move • aim with mouse • LMB primary • RMB secondary • Space special. Hold/release charged attacks. All abilities and passive are ready.",15)
 info.modulate=Color("#b6d6d9")
 arena=preload("res://scripts/workshop_arena.gd").new();arena.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(arena)
 var variants:Array=[]
 for index in 2:
  if techniques[index]:variants.append(index)
 arena.begin(project,variants,scene)
 arena.changed.connect(update_stats);test_stats=label(column,"",16)
 var controls=HBoxContainer.new();column.add_child(controls);test_controls.clear()
 for kind in Project.KINDS:
  var b=Button.new();b.text=kind.capitalize();b.custom_minimum_size=Vector2(130,46);controls.add_child(b);b.button_down.connect(func():arena.press(kind));b.button_up.connect(func():arena.release(kind));test_controls.append(b)
 for item in [["↑",Vector2.UP],["←",Vector2.LEFT],["↓",Vector2.DOWN],["→",Vector2.RIGHT]]:
  var b=Button.new();b.text=item[0];b.custom_minimum_size=Vector2(46,46);controls.add_child(b);b.button_down.connect(func():touch_direction=item[1]);b.button_up.connect(func():touch_direction=Vector2.ZERO)
 var touch_hint=label(controls,"Touch: tap arena to aim.",14);touch_hint.custom_minimum_size.x=170;touch_hint.size_flags_horizontal=Control.SIZE_EXPAND_FILL;update_stats()
var touch_direction=Vector2.ZERO
func restart_test()->void:
 arena.reset();latest_report={};update_stats()
func update_stats()->void:
 if test_stats==null or arena==null:return
 test_stats.text="Damage %s  •  Healing %s  •  Taken %s  •  Hits %s  •  %.1fs%s" % [int(arena.damage),int(arena.healing),int(arena.incoming),arena.hits,arena.time,"  •  Defeated — reset or finish" if arena.health<=0 else ""]
 for index in test_controls.size():
  var kind:String=Project.KINDS[index];var remaining:float=arena.cooldowns[kind]
  test_controls[index].text=kind.capitalize()+" • "+("%.1fs" % remaining if remaining>0 else "ready")
func finish_test()->void:
 if arena==null:return
 arena.running=false;arena.cancel_holds();touch_direction=Vector2.ZERO
 latest_report=arena.report(project.notes)
 if arena.time>0:
  project.reports.append(latest_report.duplicate(true))
  preload("res://scripts/learning_store.gd").activity("Hero test completed",str(project.hero.name))
  while project.reports.size()>20:project.reports.pop_front()
  dirty=true;save_draft()
  if arena.time>=2:preload("res://scripts/studio_cycle.gd").test("hero",project,{"seconds":latest_report.get("seconds",arena.time),"damage":latest_report.get("damage",0),"scenario":latest_report.get("scenario","")})
 test_panel.hide();panel.show();tabs.current_tab=6;render();notice.text="Test recorded. Download your report or try another revision."
 arena.queue_free();arena=null
func export_project()->void:
 var error=Project.validate(project)
 if not error.is_empty():notice.text="Cannot export: "+error;return
 save_draft();write_download(JSON.stringify(project,"  "),project_filename("project.json"))
func export_report()->void:
 if latest_report.is_empty() and not project.reports.is_empty():latest_report=project.reports.back().duplicate(true)
 if latest_report.is_empty():notice.text="Run and finish a test before downloading a report.";return
 var output=latest_report.duplicate(true);output.notes=project.notes.duplicate(true)
 if not preload("res://scripts/education_access.gd").student():output.erase("notes")
 write_download(JSON.stringify(output,"  "),project_filename("report.json",int(output.revision)))
func selected_report()->Dictionary:
 if latest_report.is_empty() and not project.reports.is_empty():latest_report=project.reports.back().duplicate(true)
 return latest_report
func report_summary(r:Dictionary)->String:
 var notes:Dictionary=r.get("notes",{})
 var output="# Crossroads Studio — Test report\n\nHero: %s\nAuthor: %s\nProject: %s\nTested revision: %s\nDate (UTC): %s\nScenario: %s\nMastery alternatives: %s\n\n## Measurements\n\nDuration: %s seconds\nDamage: %s\nHealing: %s\nDamage taken: %s\nDamage / second: %s\nHits: %s\nStatus applications: %s\nTargets defeated: %s / 5\nCasts: %s\n\n## Prediction\n%s\n\n## Method\n%s\n\n## Observations\n%s\n\n## Next change\n%s\n\nProject fingerprint: %s\n\nThese are local, student-editable test results from a synthetic arena. They do not prove multiplayer balance or award profile progress. Submit the matching project file so another student can reproduce the test.\n" % [r.get("hero",""),r.get("author",""),r.get("project_id",""),r.get("revision",0),r.get("date_utc",""),r.get("scenario",""),str(r.get("techniques",[])),r.get("seconds",0),r.get("damage",0),r.get("healing",0),r.get("damage_taken",0),r.get("dps",0),r.get("hits",0),r.get("status_applications",0),r.get("targets_defeated",0),JSON.stringify(r.get("casts",{})),notes.get("hypothesis",""),notes.get("method",""),notes.get("observations",""),notes.get("next_change",""),r.get("project_hash","")]
 if not preload("res://scripts/education_access.gd").student():
  var start=output.find("## Prediction")
  var end=output.find("Project fingerprint:")
  if start>=0 and end>start:output=output.substr(0,start)+output.substr(end)
  output=output.replace("student-editable","editable").replace("Submit the matching project file so another student can reproduce the test.","Share the matching project file to reproduce this test.")
 return output

func view_report()->void:
 var r=selected_report()
 if r.is_empty():notice.text="Run and finish a test first.";return
 var cards=[
 {"title":"Measurements","summary":str(r.get("hero",""))+" • "+str(r.get("scenario","")),"body":"Duration: "+str(r.get("seconds",0))+" s\nDamage: "+str(r.get("damage",0))+"   Healing: "+str(r.get("healing",0))+"\nDamage taken: "+str(r.get("damage_taken",0))+"   DPS: "+str(r.get("dps",0))+"\nHits: "+str(r.get("hits",0))+"   Targets defeated: "+str(r.get("targets_defeated",0)),"task":"Synthetic tests do not prove multiplayer balance. Share the matching project so someone else can reproduce your test."}]
 if preload("res://scripts/education_access.gd").student():cards.append_array([{"title":"Prediction & method","summary":str(r.get("notes",{}).get("hypothesis","No prediction recorded.")),"body":str(r.get("notes",{}).get("method","No method recorded."))},
 {"title":"Results & reflection","summary":str(r.get("notes",{}).get("observations","No observations recorded.")),"task":str(r.get("notes",{}).get("next_change","No next change recorded."))}])
 UI.lesson(self,"TEST REPORT","Compare damage, healing and timing from your test.",cards)
func export_readable_report()->void:
 var r=selected_report()
 if r.is_empty():notice.text="Run and finish a test first.";return
 var copy=r.duplicate(true);copy.notes=project.notes.duplicate(true)
 write_download(report_summary(copy),project_filename("report.md",int(copy.revision)))
func project_filename(suffix:String,revision:int=-1)->String:
 return str(project.hero.name).validate_filename().replace(" ","-").left(50)+"-r"+str(int(project.revision) if revision<0 else revision)+"-"+suffix
func write_download(text:String,filename:String)->void:
 if OS.has_feature("web"):
  JavaScriptBridge.download_buffer(text.to_utf8_buffer(),filename,"text/markdown" if filename.ends_with(".md") else "application/json");notice.text="Download requested • "+filename+". Check Downloads."
 else:
  native_dialog=FileDialog.new();native_dialog.access=FileDialog.ACCESS_FILESYSTEM;native_dialog.file_mode=FileDialog.FILE_MODE_SAVE_FILE;native_dialog.add_filter("*.md" if filename.ends_with(".md") else "*.json","Crossroads project / report");native_dialog.current_file=filename;add_child(native_dialog)
  var dialog=native_dialog
  dialog.file_selected.connect(func(path:String):
   var file=FileAccess.open(path,FileAccess.WRITE)
   if file!=null:file.store_string(text);notice.text="Saved "+path.get_file()
   else:notice.text="Could not write file. Choose another folder."
   dialog.queue_free())
  dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(850,500))
func choose_file(kind:String)->void:
 transfer_kind=kind
 if OS.has_feature("web"):
  var accept=".json,application/json" if kind=="project" else ".png,image/png"
  var limit=Project.MAX_BYTES if kind=="project" else 131072
  JavaScriptBridge.eval("(()=>{const p=document.createElement('input');p.type='file';p.accept="+JSON.stringify(accept)+";p.style.position='fixed';p.style.left='-9999px';document.body.appendChild(p);p.oncancel=()=>p.remove();p.onchange=async()=>{const f=p.files[0];if(!f){p.remove();return;}if(f.size>"+str(limit)+"){window.fxWorkshopImport('TOO_LARGE');p.remove();return;}try{if("+str(kind=="project").to_lower()+"){window.fxWorkshopImport(await f.text());}else{const r=new FileReader();r.onload=()=>window.fxWorkshopImport(String(r.result).split(',')[1]);r.onerror=()=>window.fxWorkshopImport('READ_FAILED');r.readAsDataURL(f);}}catch(e){window.fxWorkshopImport('READ_FAILED');}finally{p.remove();}};p.click();})()",true)
 else:
  native_dialog=FileDialog.new();native_dialog.access=FileDialog.ACCESS_FILESYSTEM;native_dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE;native_dialog.add_filter("*.json" if kind=="project" else "*.png","Hero project" if kind=="project" else "Hero artwork");add_child(native_dialog)
  var dialog=native_dialog
  dialog.file_selected.connect(func(path:String):
   var f=FileAccess.open(path,FileAccess.READ)
   if f==null:notice.text="Could not read file."
   elif f.get_length()>(Project.MAX_BYTES if kind=="project" else 131072):notice.text="File too large."
   elif kind=="project":request_import(f.get_as_text())
   else:read_art(Marshalls.raw_to_base64(f.get_buffer(f.get_length())),kind)
   dialog.queue_free())
  dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(850,500))
func web_import(args:Array)->void:
 if args.is_empty() or not active:return
 var value=str(args[0])
 if value in ["TOO_LARGE","READ_FAILED"]:notice.text="Cannot import: "+value;return
 if transfer_kind=="project":request_import(value)
 else:read_art(value,transfer_kind)
func request_import(text:String)->void:
 if text.to_utf8_buffer().size()>Project.MAX_BYTES:notice.text="Project exceeds 2 MB.";return
 var imported:Variant=JSON.parse_string(text)
 if imported is Dictionary and imported.get("format") in ["fx-crossroads-object","fx-crossroads-realm"]:
  var kind="object" if imported.format=="fx-crossroads-object" else "realm"
  var issue=preload("res://scripts/studio_library.gd").add_world(kind,imported);notice.text="Saved to "+kind+" library." if issue.is_empty() else issue;return
 if imported is Dictionary and imported.get("format")=="fx-crossroads-enemy":
  var issue=preload("res://scripts/studio_library.gd").add_enemy(imported);notice.text="Enemy added to Enemy Lab." if issue.is_empty() else issue;return
 if imported is Dictionary and imported.get("format")=="fx-crossroads-behavior":
  var issue=preload("res://scripts/studio_library.gd").add_behavior(imported);notice.text="Behaviour added to Behaviour Lab." if issue.is_empty() else issue;return
 if imported is Dictionary and imported.get("format")=="fx-crossroads-ability":
  var issue=preload("res://scripts/studio_library.gd").add_ability(imported.get("attack",{}));notice.text="Ability imported into Custom choices." if issue.is_empty() else issue;render();return
 var error=Project.validate(imported)
 if not error.is_empty():notice.text="Import rejected: "+error;return
 var dialog=ConfirmationDialog.new();dialog.title="Open hero project";dialog.dialog_text="Open "+str(imported.hero.name)+" by "+str(imported.author)+"?\nThis replaces the workshop draft on this device. Download the current project first if you need to keep it. Your player profile stays unchanged.";dialog.ok_button_text="Open project";add_child(dialog)
 dialog.confirmed.connect(func():read_project(text);dialog.queue_free());dialog.canceled.connect(dialog.queue_free);UI.apply(dialog);dialog.popup_centered(Vector2i(650,230))
func read_project(text:String)->bool:
 if text.to_utf8_buffer().size()>Project.MAX_BYTES:notice.text="Project exceeds 2 MB.";return false
 var imported:Variant=JSON.parse_string(text);var error=Project.validate(imported)
 if not error.is_empty():notice.text="Import rejected: "+error;return false
 # Keep the current project until the replacement has passed every check.
 if FileAccess.file_exists(Project.PATH):DirAccess.copy_absolute(Project.PATH,Project.PATH+".previous")
 project=imported.duplicate(true);techniques=[false,false];latest_report={};dirty=true;save_draft();render();notice.text="Opened "+str(project.hero.name)+" • revision "+str(project.revision);return true
func read_art(encoded:String,pose:String)->bool:
 if encoded.length()>180000:notice.text="PNG exceeds 128 KB.";return false
 var bytes=Marshalls.base64_to_raw(encoded);var image=Image.new()
 var issue=Project.png_error(bytes)
 if not issue.is_empty():notice.text=issue;return false
 if bytes.size()>131072 or image.load_png_from_buffer(bytes)!=OK:notice.text="Choose a valid PNG under 128 KB.";return false
 if image.get_width()>256 or image.get_height()>256:notice.text="Use PNG dimensions up to 256 × 256.";return false
 if pose.begins_with("alt:"):
  var id=pose.substr(4)
  if not project.hero.get("alternate_forms",{}).has(id):return false
  project.hero.alternate_forms[id].image=encoded
 else:project.hero.art[pose]=encoded
 edited();render();notice.text="Artwork added • "+pose;return true
func _notification(what:int)->void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  touch_direction=Vector2.ZERO
  if is_instance_valid(arena):arena.cancel_holds()
func _input(event:InputEvent)->void:
 if not active:return
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  if test_panel.visible:finish_test()
  else:close()
  get_viewport().set_input_as_handled()
func _process(delta:float)->void:
 if visible and not preload("res://scripts/profile_store.gd").testing() and not get_tree().root.get_node_or_null("FXResearch").active:
  if not game.legacy.data.has("education"):game.legacy.data.education={"studio_seconds":0.0}
  if Input.is_anything_pressed():game.legacy.data.education.studio_seconds=minf(315360000,float(game.legacy.data.education.studio_seconds)+delta)
 if not active:return
 if is_instance_valid(hub):
  var view=get_tree().root.get_node("FXStudioPartner").editor_view();var scale_factor=minf(1,minf((view.x-20)/hub.size.x,(view.y-20)/hub.size.y));hub.scale=Vector2.ONE*scale_factor;hub.position=(view-hub.size*scale_factor)*.5
 for box in [panel,test_panel]:
  var viewport=get_tree().root.get_node("FXStudioPartner").editor_view();var base=Vector2(1140,680) if box==panel else Vector2(1180,680);box.size=base;var factor=minf(1.0,minf((viewport.x-16)/box.size.x,(viewport.y-16)/box.size.y));box.scale=Vector2.ONE*factor;box.position=(viewport-box.size*factor)*.5
 if arena!=null:
  if arena.running and not touch_direction.is_zero_approx():arena.player=(arena.player+touch_direction*float(arena.hero.speed)*delta).clamp(Vector2(25,25),Vector2(875,515))
  last_metrics+=delta
  if last_metrics>.2:last_metrics=0;update_stats()
 if dirty:
  autosave-=delta
  if autosave<=0:save_draft()

func play_draft()->void:
 var issue=preload("res://scripts/studio_library.gd").add_hero(project)
 if not issue.is_empty():notice.text=issue;return
 preload("res://scripts/studio_cycle.gd").stored("hero",project,true)
 preload("res://scripts/studio_library.gd").install(game)
 var id=preload("res://scripts/studio_library.gd").hero_id(project)
 close();game.selected_character=id;game.hero_preview=id;game.start_training()
func publish()->void:
 var issue=preload("res://scripts/studio_library.gd").add_hero(project)
 if not issue.is_empty():notice.text=issue;return
 preload("res://scripts/studio_library.gd").install(game);notice.text="Added to Character Hall → Custom. Download this project to share it."
func edit_pixels(pose:String)->void:
 var editor=preload("res://scripts/studio_pixel_editor.gd").new();add_child(editor);editor.setup(project.hero.art.get(pose,""),pose.capitalize(),project.hero.art);editor.bind_live(["value","hero","art",pose])
 editor.saved.connect(func(encoded:String):read_art(encoded,pose))
func design_lesson()->void:
 UI.lesson(self,"DESIGN FIELD NOTES","Small, thoughtful choices make a clear and memorable hero.",preload("res://scripts/studio_lessons.gd").design())
func show_hub()->void:
 panel.hide();test_panel.hide()
 if is_instance_valid(hub):hub.queue_free()
 hub=PanelContainer.new();hub.size=Vector2(880,680);add_child(hub);skin(hub)
 var col=VBoxContainer.new();hub.add_child(col);label(col,"CROSSROADS STUDIO",30).add_theme_color_override("font_color",Color("#edcf91"))
 if preload("res://scripts/education_access.gd").student():button(col,"Student Mode • module assignments",func():game.legacy.learning_open())
 label(col,"Your ideas belong in this world.",21)
 label(col,"Imagine → Build → Test → Share",16).add_theme_color_override("font_color",Color("#91d3d5"))
 var hub_scroll=ScrollContainer.new();hub_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;hub_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;col.add_child(hub_scroll)
 var cards=VBoxContainer.new();cards.size_flags_horizontal=Control.SIZE_EXPAND_FILL;hub_scroll.add_child(cards);preload("res://scripts/touch_list_scroll.gd").attach(hub_scroll).form_controls=true
 var hero_card=UI.card(cards,"01  HERO WORKSHOP","Create a role, draw four poses and tune a complete playable hero.")
 UI.accent(button(hero_card,"Build your hero",func():hub.hide();panel.show();render();UI.enter(panel)))
 var lab_card=UI.card(cards,"02  ABILITY LAB","Explore code and animation with a live attack replay.")
 button(lab_card,"Create an ability",func():hub.hide();open_lab())
 var enemy_card=UI.card(cards,"03  ENEMY LAB","Create a sparring opponent, draw its poses and battle its decisions.")
 button(enemy_card,"Build an enemy",open_enemy)
 var brain_card=UI.card(cards,"04  BEHAVIOUR LAB","Write bounded decision code for enemies or ability flight.")
 button(brain_card,"Design a behaviour",func():open_behavior())
 var object_card=UI.card(cards,"05  OBJECT LAB","Draw props, buildings and layered pixel artwork. Save them for your realms.")
 button(object_card,"Create objects",func():open_world_lab(false))
 var realm_card=UI.card(cards,"06  REALM BUILDER","Paint terrain, place objects and enemies, then explore your own world.")
 button(realm_card,"Build a realm",func():open_world_lab(true))
 var row=HBoxContainer.new();col.add_child(row);UI.accent(button(row,"Projects & Showcase",func():load("res://scripts/studio_showcase.gd").open(self)));button(row,"Music Studio",func():hub.hide();var page=preload("res://scripts/music_studio.gd").new();add_child(page);page.setup(game,self));button(row,"Partner up",func():get_tree().root.get_node("FXStudioPartner").open(self));
 if preload("res://scripts/academy_town.gd").allowed():button(row,"Visit Crossroads Academy",enter_classroom)
 button(row,"Return to game",close)
 UI.enter(hub)
 if not has_meta("studio_intro"):set_meta("studio_intro",true);var intro=preload("res://scripts/studio_intro.gd").new();add_child(intro)
func open_lab(a:Dictionary={})->void:
 panel.hide()
 if is_instance_valid(hub):hub.hide()
 lab=preload("res://scripts/studio_lab.gd").new();add_child(lab);lab.setup(self)
 if not a.is_empty() and a.style=="custom":lab.attack=a.duplicate(true);preload("res://scripts/studio_options.gd").complete(lab.attack);lab.category=lab.attack.category;lab.build_type=lab.attack.get("build_pattern","projectile");lab.code.text=a.program;lab.render_gui();lab.apply_code()
func enter_classroom()->void:
 if not preload("res://scripts/academy_town.gd").allowed():
  game.message="Crossroads Academy is locked. Ask the Elder Ram about Student Mode.";game.message_time=5;return
 panel.hide()
 if is_instance_valid(hub):hub.hide()
 room=preload("res://scripts/studio_classroom.gd").new();add_child(room);room.setup(self)

func open_enemy()->void:
 panel.hide()
 if is_instance_valid(hub):hub.hide()
 var page=preload("res://scripts/studio_enemy_lab.gd").new();add_child(page);page.setup(self)
func open_behavior(initial:Dictionary={},use:Callable=Callable())->void:
 if not use.is_valid():
  panel.hide()
  if is_instance_valid(hub):hub.hide()
 var page=preload("res://scripts/studio_behavior_lab.gd").new();add_child(page);page.setup(self,initial,use)

func compare_tests()->void:
 if project.reports.size()<2:notice.text="Run and save two playtests first. Change one thing, then repeat the same scenario.";return
 var before:Dictionary=project.reports[-2];var after:Dictionary=project.reports[-1]
 var lines=PackedStringArray()
 for pair in [["damage","Damage"],["healing","Healing"],["damage_taken","Damage taken"],["dps","Damage / second"],["targets_defeated","Targets defeated"]]:
  var first=float(before.get(pair[0],0));var second=float(after.get(pair[0],0));lines.append(str(pair[1])+": %.1f → %.1f (%+.1f)" % [first,second,second-first])
 var same=before.get("scenario")==after.get("scenario")
 UI.lesson(self,"DESIGN DETECTIVE • before & after","Change one variable. Test. Explain the result.",[{"title":"Measured changes","body":"\n".join(lines)},{"title":"A fair comparison?","body":"Same scenario: "+str(same)+". Before: "+str(before.get("seconds",0))+" seconds. After: "+str(after.get("seconds",0))+" seconds. Keep test duration, targets and mastery choices consistent before claiming a balance improvement."},{"title":"Your next experiment","body":"What did you change? What did you predict? Which measurement supports your conclusion? Pick one next adjustment and ask a partner to reproduce it."}])

func balance_values(node:Node)->void:
 if node is Range and node.has_meta("balance_data"):
  var data:Dictionary=node.get_meta("balance_data");node.set_value_no_signal(float(data.get(node.get_meta("balance_key"),0)))
 for child in node.get_children():balance_values(child)

func open_world_lab(realm:bool)->void:
 panel.hide()
 if is_instance_valid(hub):hub.hide()
 lab=load("res://scripts/studio_world_lab.gd").new();add_child(lab);lab.setup(self,realm)
func alternate_form_editor(parent:Node)->void:
 if not project.hero.has("alternate_forms"):project.hero.alternate_forms={}
 var forms:Dictionary=project.hero.alternate_forms
 var card=UI.card(parent,"ALTERNATE FORMS","Draw up to four extra appearances. Attach one to an ability below; it replaces the normal pose for the chosen duration, then returns.")
 button(card,"Add alternate form",func():
  if forms.size()>=4:notice.text="Four forms maximum.";return
  var id="form_"+str(Time.get_ticks_usec());var image=Image.create(32,32,false,Image.FORMAT_RGBA8);image.fill(Color.TRANSPARENT)
  forms[id]={"name":"New form","image":Marshalls.raw_to_base64(image.save_png_to_buffer())};edited();render()
 )
 for id in forms:
  var row=HBoxContainer.new();card.add_child(row);line(row,"Form name",forms[id],"name",60)
  button(row,"Draw / edit",func():
   var editor=preload("res://scripts/studio_pixel_editor.gd").new();add_child(editor);editor.setup(forms[id].image,forms[id].name);editor.bind_live(["value","hero","alternate_forms",id,"image"]);editor.saved.connect(func(encoded:String):forms[id].image=encoded;edited();render())
  )
  button(row,"Upload PNG",choose_file.bind("alt:"+id))
  button(row,"Remove",func():
   forms.erase(id)
   for slot in Project.KINDS:
    if project.hero[slot].get("form_id","")==id:project.hero[slot].form_id=""
   for t in project.techniques:
    if t.attack.get("form_id","")==id:t.attack.form_id=""
   edited();render()
  )
