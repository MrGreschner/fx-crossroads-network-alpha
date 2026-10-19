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
 var full=Button.new();full.text="Open full dashboard • mode filters, devices & exports";full.custom_minimum_size.y=42;column.add_child(full);full.pressed.connect(func():OS.shell_open(owner_node.endpoint+"/reports"))
 var row=HBoxContainer.new();column.add_child(row)
 secret=LineEdit.new();secret.secret=true;secret.placeholder_text="Private server dashboard key";secret.max_length=128;secret.size_flags_horizontal=Control.SIZE_EXPAND_FILL;secret.custom_minimum_size.y=46;row.add_child(secret)
 period=OptionButton.new()
 for days in [1,7,30]:period.add_item(str(days)+" days",days)
 period.select(1);row.add_child(period)
 var refresh=Button.new();refresh.text="Refresh trends";refresh.pressed.connect(load_data);row.add_child(refresh)
 status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.text="Enter REPORT_ADMIN_PASSWORD from your Render service. Username: teacher. This password is never saved.";column.add_child(status)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;column.add_child(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll)
 body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);scroll.add_child(body)
 var close=Button.new();close.text="Close dashboard";close.custom_minimum_size.y=46;close.pressed.connect(queue_free);column.add_child(close)
func _process(_dt:float)->void:
 if is_instance_valid(owner_node) and not owner_node.game_dev():queue_free()
func load_data()->void:
 if not owner_node.game_dev() or is_instance_valid(request):return
 if secret.text.length()<24:status.text="Enter your private server key (at least 24 characters).";return
 status.text="Loading aggregate trends…";request=HTTPRequest.new();request.timeout=12;request.body_size_limit=262144;add_child(request);request.request_completed.connect(completed)
 if request.request(owner_node.endpoint+"/activity/api/summary?days="+str(period.get_selected_id()),["Authorization: Basic "+Marshalls.utf8_to_base64("teacher:"+secret.text),"Accept: application/json"])!=OK:request.queue_free();request=null;status.text="Could not connect. Gameplay remains available."
func line(text:String,color:Color=Color.WHITE)->void:
 var label=Label.new();label.text=text;label.modulate=color;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(label)
func completed(result:int,code:int,_headers:PackedStringArray,bytes:PackedByteArray)->void:
 request.queue_free();request=null
 if not owner_node.game_dev():queue_free();return
 if code==401:status.text="Private key rejected. Check REPORT_ADMIN_PASSWORD on Render.";return
 if code==503:status.text="Activity storage is not configured. Configure DATABASE_URL and a stable REPORT_SIGNING_SECRET on your Render service.";return
 var data=JSON.parse_string(bytes.get_string_from_utf8()) if result==HTTPRequest.RESULT_SUCCESS and code==200 else null
 if not data is Dictionary:status.text="Unable to load trends. Try again when the server is available.";return
 for child in body.get_children():child.queue_free()
 status.text="Updated • "+str(data.get("timezone","America/Edmonton"))+" • 30-day retention • offline reports are not counted"
 var totals:Dictionary=data.get("totals",{})
 line("Estimated active hours: %.1f • profiles: %d • devices: %d • sessions: %d" % [float(totals.get("active_seconds",0))/3600.0,int(totals.get("profiles",0)),int(totals.get("devices",0)),int(totals.get("sessions",0))],Color("#efcd83"))
 line("ACTIVITY • mode / realm / route • active minutes",Color("#81d4df"))
 for item in data.get("activities",[]):
  line("%s • %s / %s / %s • %.1f min • %.0f FPS" % [friendly(item.category),friendly(item.mode),friendly(item.realm),item.route,float(item.active_seconds)/60.0,float(item.fps_mean) if item.fps_mean!=null else 0])
 line("COMPLETIONS • median gameplay time",Color("#81d4df"))
 for item in data.get("completions",[]):
  line("%s • %s / %s • %s • %d results • %.1f min" % [friendly(item.kind),friendly(item.mode),friendly(item.realm),item.result,int(item.attempts),float(item.median_seconds)/60.0 if item.median_seconds!=null else 0])
 for note in data.get("notes",[]):line(str(note),Color("#adb9c4"))
func friendly(key:String)->String:
 var game=get_tree().current_scene
 if game!=null:
  var characters=game.get("characters")
  if characters is Dictionary and characters.has(key):return str(characters[key].get("name",key))
 return key.replace("_"," ").capitalize()

func _input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  get_viewport().set_input_as_handled();queue_free()
