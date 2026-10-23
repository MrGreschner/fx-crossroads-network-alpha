extends CanvasLayer
## Temporary testing and presentation tools. Never writes profile state.
var session:Node
var desk:Button
var panel:PanelContainer
var body:VBoxContainer
var status:Label
var caption:LineEdit
var banner:Label
var opened:=false
var held_game:Node
var previous_menu=""
var menu_field=""
func setup(owner:Node)->void:
 session=owner;layer=91;visible=false
 desk=Button.new();desk.text="DEV DESK  `";desk.size=Vector2(140,34);add_child(desk);desk.pressed.connect(toggle)
 panel=PanelContainer.new();panel.size=Vector2(620,460);add_child(panel)
 var skin:=StyleBoxFlat.new();skin.bg_color=Color("#172d36");skin.border_color=Color("#edc775");skin.set_border_width_all(2);skin.set_corner_radius_all(14);skin.set_content_margin_all(22);preload("res://scripts/studio_ui.gd").apply(panel);panel.add_theme_stylebox_override("panel",skin)
 body=VBoxContainer.new();body.add_theme_constant_override("separation",12);panel.add_child(body)
 text("GAME DEV • TESTING DESK",24)
 text("Try ideas, explain your experiment, record what happens. Nothing here earns player progress.",17)
 var row:=HBoxContainer.new();body.add_child(row)
 action(row,"Restore health",func():experiment("health"))
 action(row,"Reset cooldowns",func():experiment("cooldowns"))
 action(body,"Training • all attacks ready",func():experiment("training"))
 action(body,"Town • time, weather & almanac",town_time_preview)
 build_powers()
 action(body,"Activity dashboard • private trends",func():close_desk();get_tree().root.get_node("FXActivity").open_dashboard())
 action(body,"Host • Demo Broadcast (31 viewers)",func():close_desk();get_tree().root.get_node("FXClassroom").host())
 caption=LineEdit.new();caption.placeholder_text="Presentation caption • e.g. Testing projectile counters";caption.max_length=80;body.add_child(caption)
 action(body,"Show / hide presentation caption",present)
 action(body,"Open playtest notebook",notebook)
 status=text("An animated arcane insignia identifies Game Dev. Powers make the entire match a test: no player progress.",15)
 var bottom:=HBoxContainer.new();body.add_child(bottom)
 action(bottom,"Back to game",toggle)
 action(bottom,"Exit Dev • restore profile",func():session.finish())
 banner=Label.new();banner.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;banner.add_theme_color_override("font_color",Color("#ffe3a0"));banner.add_theme_color_override("font_shadow_color",Color.BLACK);banner.add_theme_constant_override("shadow_offset_x",2);banner.add_theme_constant_override("shadow_offset_y",2);banner.add_theme_font_size_override("font_size",18);banner.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(banner);banner.hide();panel.hide()
func text(value:String,size:int)->Label:
 var label:=Label.new();label.text=value;label.add_theme_font_size_override("font_size",size);label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(label);return label
func action(where:Node,title:String,callback:Callable)->void:
 var b:=Button.new();b.text=title;b.custom_minimum_size.y=42;where.add_child(b);b.pressed.connect(callback)
func game()->Node:return get_tree().current_scene
func allowed()->bool:
 var g:Node=game()
 return session.active and g!=null and g.get_script()==load("res://scripts/game.gd")
func experiment(kind:String)->bool:
 if not allowed():status.text="Solo testing only. Return to town to try these tools.";return false
 var g:Node=game()
 if kind=="training":
  if g.mode!="town":status.text="Return to town before opening the training yard.";return false
  close_desk();g.presentation.close();g.legacy.close();g.session_menu.resume();g.menu="";g.start_training()
 elif kind=="health":
  if g.health<=0 or g.menu=="results":status.text="Restart the adventure before restoring health.";return false
  g.health=g.max_health()
 elif kind=="cooldowns":
  for key in g.cooldowns:g.cooldowns[key]=0.0
 else:return false
 status.text="Experiment ready • temporary, no progress saved.";close_desk();g.mobile.reset_controls();return true
func close_desk()->void:
 if is_instance_valid(held_game) and held_game.get(menu_field)=="dev_desk":held_game.set(menu_field,previous_menu)
 held_game=null;opened=false;panel.hide()
func toggle()->void:
 if opened:close_desk();return
 var g:Node=game()
 if g==null:return
 held_game=g;menu_field="menu" if g.get_script()==load("res://scripts/game.gd") else "shop_open";previous_menu=str(g.get(menu_field));g.set(menu_field,"dev_desk")
 opened=true;panel.show()
 if g.get("mobile")!=null:g.mobile.reset_controls()
func present()->void:
 if banner.visible:banner.hide();return
 banner.text="DEV DEMO • "+(caption.text.strip_edges() if not caption.text.strip_edges().is_empty() else "Experiment in progress");banner.show();close_desk()
func notebook()->void:
 var g:Node=game()
 if g==null or g.get("session_menu")==null:return
 close_desk();g.session_menu.open("options");g.session_menu.open_notebook()
func _process(_delta:float)->void:
 visible=session!=null and session.active
 if not visible:return
 var view:=get_viewport().get_visible_rect().size
 desk.position=Vector2(view.x-200,250)
 panel.size=Vector2(620,maxf(460,body.get_combined_minimum_size().y+44))
 var fit:=minf(1,minf((view.x-24)/panel.size.x,(view.y-100)/panel.size.y));panel.scale=Vector2.ONE*fit;panel.position=(view-panel.size*fit)*.5
 banner.size=Vector2(view.x-40,30);banner.position=Vector2(20,view.y-38)
 if opened and held_game!=game():close_desk()

func _input(event:InputEvent)->void:
 if session.active and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_QUOTELEFT:
  toggle();get_viewport().set_input_as_handled();return
 if session.active and opened and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  close_desk();get_viewport().set_input_as_handled()

func build_powers()->void:
 var grid=GridContainer.new();grid.columns=2;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",8);body.add_child(grid)
 for entry in [["Random heroes","random","Other players change hero; health percentage stays the same."],["Time Slow • 16s","slow","Slow the battlefield; Game Dev movement and cooldowns stay normal."],["Summon enemies","summon","Choose any registered enemy type and 1–9 copies."],["Arcane Volley","volley","Click a location: 40 staggered missiles: each bursts for 3 area damage and a brief stun."],["Blink","blink","Click a clear location to teleport."],["Rally","rally","Restore and revive every hero for another test."],["Projectile Sweep","sweep","Remove projectiles to examine a mechanic safely."],["Spotlight","spotlight","Click to place a harmless eight-second presentation marker."]]:
  var b=Button.new();b.text=entry[0];b.tooltip_text=entry[2];b.custom_minimum_size=Vector2(270,40);grid.add_child(b)
  var kind=str(entry[1]);b.pressed.connect(func():power(kind))
func power(kind:String)->void:
 var g=game()
 if g==null or g.get("dev_magic")==null:return
 if kind=="summon":summon_menu();return
 close_desk()
 if kind in ["volley","blink","spotlight"]:g.dev_magic.aiming=kind;banner.text="GAME DEV • click your target • Esc cancels";banner.show()
 elif not g.dev_magic.request(kind):status.text="Start an adventure or match first; powers have a one-second safety interval."
func summon_menu()->void:
 var g=game();var dialog=ConfirmationDialog.new();dialog.title="Summon • choose enemy and count";dialog.ok_button_text="Place summon";dialog.min_size=Vector2i(500,160);add_child(dialog)
 var box=VBoxContainer.new();dialog.add_child(box)
 var enemy=OptionButton.new();enemy.custom_minimum_size=Vector2(460,44);box.add_child(enemy)
 var catalogue=g.dev_magic.catalogue();var keys=catalogue.keys();keys.sort()
 for key in keys:enemy.add_item(str(catalogue[key].get("name",key)))
 var number=SpinBox.new();number.min_value=1;number.max_value=9;number.value=1;number.prefix="Copies: ";box.add_child(number)
 dialog.confirmed.connect(func():g.dev_magic.summon_kind=str(keys[enemy.selected]);g.dev_magic.summon_count=int(number.value);close_desk();g.dev_magic.aiming="summon";dialog.queue_free())
 dialog.canceled.connect(func():dialog.queue_free());dialog.popup_centered()

func town_time_preview()->void:
 if not allowed() or game().mode!="town":status.text="Return to the main town to preview time.";return
 close_desk();game().town_life.calendar.almanac.open()
