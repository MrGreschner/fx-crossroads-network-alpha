extends CanvasLayer
const UI=preload("res://scripts/studio_ui.gd")
const EVENTS=preload("res://scripts/town_events.gd")
var game:Node
var calendar:RefCounted
var button:Button
var panel:PanelContainer
var column:VBoxContainer
var clock_label:Label
var previous_menu=""
var preview_box:VBoxContainer
func setup(g:Node,cal:RefCounted)->void:
 game=g;calendar=cal;layer=94
 button=Button.new();button.text="DEV • Time & weather";button.custom_minimum_size=Vector2(180,34);add_child(button);button.pressed.connect(open)
 button.hide()
func add_text(value:String,size:int)->Label:
 var t=Label.new();t.text=value;t.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;t.add_theme_font_size_override("font_size",size);column.add_child(t);return t
func open()->void:
 if is_instance_valid(panel):return
 previous_menu=game.menu;game.menu="town_almanac";game.mobile.reset_controls()
 panel=PanelContainer.new();UI.apply(panel);add_child(panel)
 column=VBoxContainer.new();panel.add_child(column)
 var heading=HBoxContainer.new();column.add_child(heading)
 var title=Label.new();title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title.text="TOWN ALMANAC • YOUR DISCOVERIES";title.add_theme_font_size_override("font_size",23);heading.add_child(title)
 var close_button=Button.new();close_button.text="Close";heading.add_child(close_button);close_button.pressed.connect(close)
 clock_label=add_text(calendar.label(),18)
 add_text("The town follows a real 24-hour clock. Discover events by being there; this journal records what you have encountered.",16)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll)
 var entries=VBoxContainer.new();entries.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(entries)
 var discovered=game.legacy.fishing_records.state().discoveries
 var dev=preload("res://scripts/profile_store.gd").dev_session();var is_dev=dev!=null and dev.active
 for id in EVENTS.EVENTS:
  if not discovered.has(id) and not is_dev:continue
  var event=EVENTS.EVENTS[id];UI.card(entries,str(event.name)+(" • Dev preview" if not discovered.has(id) else ""),event.text)
 if discovered.is_empty() and not is_dev:UI.card(entries,"Your story starts with a walk","No town events discovered yet. Explore different streets at different times and return on other weekdays.")
 preview_box=VBoxContainer.new();column.add_child(preview_box);preview_box.visible=is_dev
 if is_dev:
  var row=HBoxContainer.new();preview_box.add_child(row);var day=OptionButton.new()
  for name in calendar.DAYS:day.add_item(name)
  day.select(calendar.weekday);row.add_child(day)
  var hour=SpinBox.new();hour.custom_minimum_size.x=130;hour.min_value=0;hour.max_value=23;hour.value=floori(calendar.hour);hour.prefix="Hour ";row.add_child(hour)
  var minute=SpinBox.new();minute.min_value=0;minute.max_value=59;minute.value=floori(calendar.hour*60)%60;row.add_child(minute)
  var weather_row=HBoxContainer.new();preview_box.add_child(weather_row)
  var weather_label=Label.new();weather_label.text="Weather ";weather_row.add_child(weather_label)
  var weather=OptionButton.new();weather.name="DevWeather";weather_row.add_child(weather);weather.add_item("Automatic • live forecast")
  for kind in preload("res://scripts/town_weather.gd").TYPES:weather.add_item(kind)
  weather.select(0 if calendar.preview_weather.is_empty() else 1+preload("res://scripts/town_weather.gd").TYPES.find(calendar.preview_weather))
  weather.item_selected.connect(func(index:int):calendar.preview_weather="" if index==0 else preload("res://scripts/town_weather.gd").TYPES[index-1];clock_label.text=calendar.label())
  var apply=Button.new();apply.text="Preview • temporary test session";preview_box.add_child(apply)
  apply.pressed.connect(func():
   if not dev.active:return
   var civil=Time.get_unix_time_from_datetime_dict(calendar.local_date);var monday=floori(civil/86400.0)*86400-calendar.weekday*86400
   var chosen=monday+day.selected*86400+int(hour.value)*3600+int(minute.value)*60
   calendar.preview_time=chosen-calendar.edmonton_offset(chosen+21600);calendar.refresh();game.town_life.step(.01);close())
  var reset=Button.new();reset.text="Return to live time & weather";preview_box.add_child(reset);reset.pressed.connect(func():calendar.preview_time=-1;calendar.preview_weather="";calendar.refresh();close())
 fit()
func close()->void:
 if not is_instance_valid(panel):return
 panel.queue_free();panel=null
 if game.menu=="town_almanac":game.menu=previous_menu
 if previous_menu=="legacy":game.legacy.render()
func fit()->void:
 if not is_instance_valid(panel):return
 var v=game.get_viewport_rect().size;var dim=Vector2(700,620);panel.size=dim;panel.scale=Vector2.ONE*minf(1,minf((v.x-24)/dim.x,(v.y-24)/dim.y));panel.position=(v-dim*panel.scale)*.5
func _process(_delta:float)->void:
 if game==null:return
 var dev=preload("res://scripts/profile_store.gd").dev_session()
 button.visible=dev!=null and dev.active and game.mode=="town" and game.menu.is_empty() and not game.has_node("FXIntro")
 button.position=Vector2(game.get_viewport_rect().size.x-200,292)
 fit()
func _unhandled_input(event:InputEvent)->void:
 if is_instance_valid(panel) and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()
