extends CanvasLayer
var owner_node:Node
var secret:LineEdit
var period:OptionButton
var status:Label
var body:VBoxContainer
var request:HTTPRequest
func setup(source:Node)->void:
 owner_node=source;layer=110
 var shade=ColorRect.new();shade.color=Color(.015,.025,.04,1);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 var margin=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,24)
 shade.add_child(margin)
 var column=VBoxContainer.new();column.add_theme_constant_override("separation",12);margin.add_child(column)
 var title=Label.new();title.text="CROSSROADS • PRIVATE ACTIVITY DASHBOARD";title.add_theme_font_size_override("font_size",25);column.add_child(title)
 var note=Label.new();note.text="Anonymous estimates • no names, student work or profile contents uploaded. Game Dev sessions excluded. Shared computers are not a reliable count of individual students.";note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(note)
 var row=HBoxContainer.new();column.add_child(row)
 secret=LineEdit.new();secret.secret=true;secret.placeholder_text="Private server dashboard key";secret.max_length=128;secret.size_flags_horizontal=Control.SIZE_EXPAND_FILL;secret.custom_minimum_size.y=46;row.add_child(secret)
 period=OptionButton.new()
 for days in [7,30,90]:period.add_item(str(days)+" days",days)
 period.select(1);row.add_child(period)
 var refresh=Button.new();refresh.text="Refresh trends";refresh.pressed.connect(load_data);row.add_child(refresh)
 status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.text="Enter ANALYTICS_ADMIN_KEY from your Render environment. It is separate from the Game Dev password and is never saved.";column.add_child(status)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll)
 body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);scroll.add_child(body)
 var close=Button.new();close.text="Close dashboard";close.custom_minimum_size.y=46;close.pressed.connect(queue_free);column.add_child(close)
func _process(_dt:float)->void:
 if is_instance_valid(owner_node) and not owner_node.game_dev():queue_free()
func load_data()->void:
 if not owner_node.game_dev() or is_instance_valid(request):return
 if secret.text.length()<24:status.text="Enter your private server key (at least 24 characters).";return
 status.text="Loading aggregate trends…";request=HTTPRequest.new();request.timeout=12;request.body_size_limit=262144;add_child(request);request.request_completed.connect(completed)
 if request.request(owner_node.endpoint+"/analytics/dashboard?days="+str(period.get_selected_id()),["Authorization: Bearer "+secret.text,"Accept: application/json"])!=OK:request.queue_free();request=null;status.text="Could not connect. Gameplay remains available."
func line(text:String,color:Color=Color.WHITE)->void:
 var label=Label.new();label.text=text;label.modulate=color;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(label)
func completed(result:int,code:int,_headers:PackedStringArray,bytes:PackedByteArray)->void:
 request.queue_free();request=null
 if not owner_node.game_dev():queue_free();return
 if code==401:status.text="Private key rejected. Check ANALYTICS_ADMIN_KEY on Render.";return
 if code==503:status.text="Activity storage is not configured. Follow DEPLOY_V161.md: persistent disk, database path and both private keys.";return
 var data=JSON.parse_string(bytes.get_string_from_utf8()) if result==HTTPRequest.RESULT_SUCCESS and code==200 else null
 if not data is Dictionary:status.text="Unable to load trends. Try again when the server is available.";return
 for child in body.get_children():child.queue_free()
 status.text="Updated • "+str(data.timezone)+" • 90-day retention • missing/offline reports are not counted"
 var total=0;var sessions=0;var losses=0;var recoveries=0;var max_profiles=1
 for day in data.daily:
  total+=int(day.active_seconds);sessions+=int(day.sessions);losses+=int(day.graphics_losses);recoveries+=int(day.disconnects);max_profiles=maxi(max_profiles,int(day.profiles))
 line("Recently reporting devices: %d     Peak devices in a 3-minute window: %d" % [data.online_devices,data.peak_reporting_devices],Color("#efcd83"))
 line("Estimated active hours: %.1f     Daily session counts: %d     Recovery incidents: %d     Graphics losses: %d" % [total/3600.0,sessions,recoveries,losses])
 line("DAILY ACTIVITY • engaged profiles / devices / sessions",Color("#81d4df"))
 if data.daily.is_empty():line("No reports yet. Counts begin after v161 clients and the configured server are live.")
 for day in data.daily:
  var row=HBoxContainer.new();body.add_child(row)
  var label=Label.new();label.text="%s   %d / %d / %d   • %.0f active min" % [day.day,day.profiles,day.devices,day.sessions,int(day.active_seconds)/60.0];label.custom_minimum_size.x=430;row.add_child(label)
  var bar=ProgressBar.new();bar.max_value=max_profiles;bar.value=day.profiles;bar.show_percentage=false;bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bar.custom_minimum_size.y=22;row.add_child(bar)
  var fill=StyleBoxFlat.new();fill.bg_color=Color("#55b7c7");fill.set_corner_radius_all(5);bar.add_theme_stylebox_override("fill",fill)
 for spec in [["ACTIVITIES","activities","category"],["POPULAR HEROES • combat time","heroes","hero"],["POPULAR REALMS","realms","realm"]]:
  line(spec[0],Color("#81d4df"))
  for item in data[spec[1]]:line("%s   • %.1f active minutes" % [friendly(str(item[spec[2]])),int(item.seconds)/60.0])
 line("Sessions can span multiple dates; daily session counts are not unique people. Active time estimates stop after 2 minutes without input. Recovery counts are best effort, not a full crash census.",Color("#adb9c4"))
func friendly(key:String)->String:
 var game=get_tree().current_scene
 if game!=null:
  var characters=game.get("characters")
  if characters is Dictionary and characters.has(key):return str(characters[key].get("name",key))
 return key.replace("_"," ").capitalize()

func _input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  get_viewport().set_input_as_handled();queue_free()
