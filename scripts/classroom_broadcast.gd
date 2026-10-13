extends CanvasLayer
## View-only classroom mirroring. Two small JPEG frames/sec; no OS desktop or input capture.
const URL="wss://fx-crossroads-rooms.onrender.com"
var service_url=URL
const UI=preload("res://scripts/studio_ui.gd")
var socket:WebSocketPeer
var role=""
var code=""
var identity=""
var started=false
var roster:Array=[]
var panel:PanelContainer
var body:VBoxContainer
var status:Label
var join_code:LineEdit
var name_field:LineEdit
var seats:GridContainer
var teacher:Label
var start_button:Button
var connect_button:Button
var view:Control
var picture:TextureRect
var viewer_status:Label
var host_strip:HBoxContainer
var was_paused=false
var frame_timer=0.0
var heartbeat=0.0
var connecting_timer=0.0
var capturing=false
var sequence=0
var received_sequence=-1
var age=0.0
var pending:Dictionary={}
func _ready()->void:
 process_mode=Node.PROCESS_MODE_ALWAYS;layer=120
 panel=PanelContainer.new();add_child(panel);UI.apply(panel);panel.size=Vector2(1060,620);panel.hide()
 body=VBoxContainer.new();panel.add_child(body)
 heading(body,"CLASSROOM BROADCAST",25)
 heading(body,"One Teacher / Game Dev host • 31 student seats • view only",17)
 var row=HBoxContainer.new();body.add_child(row)
 name_field=LineEdit.new();name_field.placeholder_text="Your display name";name_field.max_length=18;name_field.custom_minimum_size=Vector2(230,42);row.add_child(name_field)
 join_code=LineEdit.new();join_code.placeholder_text="Classroom code • CL…";join_code.max_length=8;join_code.custom_minimum_size=Vector2(230,42);row.add_child(join_code)
 connect_button=button(row,"Join classroom",join_class)
 teacher=heading(body,"Teacher seat • waiting for connection",21)
 seats=GridContainer.new();seats.columns=8;seats.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(seats)
 for n in 31:
  var card=PanelContainer.new();card.add_theme_stylebox_override("panel",UI.box("#173640","#355763",8,6));seats.add_child(card)
  var seat=Label.new();seat.text=str(n+1)+"\nOpen seat";seat.custom_minimum_size=Vector2(100,48);seat.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;seat.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;seat.add_theme_font_size_override("font_size",14);card.add_child(seat)
 status=heading(body,"Enter the code your teacher gives you. Once started, the class sees the teacher's game and editors.",16)
 var bottom=HBoxContainer.new();body.add_child(bottom)
 start_button=button(bottom,"Start broadcast",func():send({"type":"class_start"}));start_button.hide()
 button(bottom,"Leave / close",leave)
 heading(body,"This shares ONLY FX Crossroads, including Studio panels. No microphone, webcam, desktop, player input or files are sent. Low-bandwidth 2 FPS view; use the projector for smooth action.",14)
 view=Control.new();view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);view.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(view);view.hide()
 var background=ColorRect.new();background.color=Color("#071b26");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);view.add_child(background)
 picture=TextureRect.new();picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);picture.mouse_filter=Control.MOUSE_FILTER_IGNORE;view.add_child(picture)
 var footer=PanelContainer.new();footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);footer.offset_top=-54;view.add_child(footer);UI.apply(footer)
 var bar=HBoxContainer.new();footer.add_child(bar);viewer_status=heading(bar,"Waiting for teacher…",16);viewer_status.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button(bar,"Leave class",leave)
 host_strip=HBoxContainer.new();add_child(host_strip);UI.apply(host_strip);host_strip.hide();heading(host_strip,"CLASSROOM • LIVE • 2 FPS",13);button(host_strip,"Class seats",func():panel.show();render());button(host_strip,"End",leave)
func heading(parent:Node,text:String,size:int)->Label:
 var label=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",size);parent.add_child(label);return label
func button(parent:Node,text:String,callback:Callable)->Button:
 var b=Button.new();b.text=text;b.custom_minimum_size.y=40;parent.add_child(b);b.pressed.connect(callback);return b
func player_name()->String:
 var scene=get_tree().current_scene
 return str(scene.legacy.data.name) if scene!=null and scene.get("legacy")!=null else "Student"
func host()->void:
 var dev=get_tree().root.get_node_or_null("FXDevSession")
 if (dev==null or not dev.active) and not preload("res://scripts/education_access.gd").teacher():return
 if role=="host":panel.show();render();return
 if not role.is_empty():leave()
 panel.show();name_field.text=player_name();start_button.show();start_button.disabled=true;join_code.hide();connect_button.hide()
 open_socket({"type":"class_host","dev":true,"version":30,"name":name_field.text})
func open_join()->void:
 if role=="guest":panel.show();render();return
 if role=="host":panel.show();render();return
 panel.show();start_button.hide();join_code.show();connect_button.show();name_field.text=player_name();status.text="Enter your teacher's classroom code. Your own profile and creations stay unchanged."
func join_class()->void:
 if not role.is_empty():return
 var entry=join_code.text.strip_edges().to_upper()
 if entry.length()!=8 or not entry.begins_with("CL"):status.text="Classroom codes start with CL followed by six letters.";return
 open_socket({"type":"class_join","code":entry,"name":name_field.text,"version":30})
func open_socket(packet:Dictionary)->void:
 if socket!=null:socket.close()
 socket=WebSocketPeer.new();socket.outbound_buffer_size=262144;socket.inbound_buffer_size=262144;socket.max_queued_packets=16
 pending=packet;connecting_timer=0;status.text="Connecting to classroom service… first connection can take a moment."
 if socket.connect_to_url(service_url)!=OK:status.text="Could not connect. Check the school network and Render service.";socket=null
func send(packet:Dictionary)->void:
 if socket!=null and socket.get_ready_state()==WebSocketPeer.STATE_OPEN:socket.send_text(JSON.stringify(packet))
func leave()->void:
 send({"type":"class_leave"})
 if socket!=null:socket.close()
 socket=null;pending.clear();role="";started=false;code="";roster.clear();sequence=0;received_sequence=-1;capturing=false;picture.texture=null;panel.hide();view.hide();host_strip.hide();get_tree().paused=was_paused;was_paused=false
func render()->void:
 join_code.visible=role!="host";connect_button.visible=role!="host";name_field.editable=role.is_empty()
 teacher.text=("GAME DEV HOST • "+name_field.text if role=="host" else "Teacher's classroom")+" • code "+code+" • "+str(roster.size())+" / 31 students"
 for n in seats.get_child_count():
  var seat:Label=seats.get_child(n).get_child(0);seat.text=str(n+1)+"\n"+(str(roster[n].get("name","Student")) if n<roster.size() else "Open seat");seat.modulate=Color("#f2d387") if n<roster.size() else Color("#8cabb7")
 start_button.disabled=role!="host";start_button.text="Return to broadcast" if started else "Start broadcast"
 status.text="Students cannot control the teacher's game. Closing this room restores their own game."
func packet(data:Dictionary)->void:
 match str(data.get("type","")):
  "server_info":
   if int(data.get("version",0))<30 or not "classroom_broadcast" in data.get("features",[]):status.text="Update Render to the v130 room-service files for classroom broadcasts.";pending.clear()
   elif not pending.is_empty():send(pending);pending.clear()
  "class_joined":
   role="host" if bool(data.get("host",false)) else "guest";code=str(data.code);identity=str(data.id);render()
  "class_status":
   roster=data.get("roster",[]);started=bool(data.get("started",false));render()
   if started:
    if role=="host":panel.hide();host_strip.show();frame_timer=.5
    else:start_view()
  "class_start":started=true;start_view()
  "class_frame":
   if role!="guest" or not started:return
   var text=str(data.get("image",""));var seq=int(data.get("seq",0))
   if text.length()>110000 or seq<=received_sequence:return
   var image=Image.new()
   if image.load_jpg_from_buffer(Marshalls.base64_to_raw(text))!=OK:return
   if image.get_width()>1024 or image.get_height()>576:return
   picture.texture=ImageTexture.create_from_image(image);received_sequence=seq;age=0;viewer_status.text="WATCHING CLASS • "+code+" • view only • your profile is safe"
  "class_closed":
   leave();panel.show();status.text=str(data.get("message","The broadcast ended."));teacher.text="Classroom ended";start_button.hide();join_code.show();connect_button.show()
  "error":status.text=str(data.get("message","Connection error"))
func start_view()->void:
 if role!="guest":return
 if not view.visible:was_paused=get_tree().paused
 get_tree().paused=true;view.show();panel.hide()
func capture()->void:
 if capturing or role!="host" or not started:return
 if not get_tree().get_nodes_in_group("fx_private_assessment").is_empty():host_strip.get_child(0).text="CLASSROOM • PRIVATE REVIEW • HELD";return
 host_strip.get_child(0).text="CLASSROOM • LIVE • 2 FPS"
 capturing=true
 await RenderingServer.frame_post_draw
 if role!="host" or not started or not get_tree().get_nodes_in_group("fx_private_assessment").is_empty():capturing=false;return
 var image=get_viewport().get_texture().get_image()
 if image!=null:
  image.resize(1024,576,Image.INTERPOLATE_BILINEAR)
  var bytes=image.save_jpg_to_buffer(.7)
  if bytes.size()>80000:image.resize(800,450,Image.INTERPOLATE_BILINEAR);bytes=image.save_jpg_to_buffer(.35)
  if bytes.size()<=80000:sequence+=1;send({"type":"class_frame","image":Marshalls.raw_to_base64(bytes),"seq":sequence})
 capturing=false
func _process(delta:float)->void:
 var size=get_viewport().get_visible_rect().size;var factor=minf(1,minf((size.x-24)/1060,(size.y-24)/620));panel.size=Vector2(1060,620);panel.scale=Vector2.ONE*factor;panel.position=(size-panel.size*factor)*.5;host_strip.position=Vector2(18,size.y-48)
 if socket==null:return
 socket.poll();connecting_timer+=delta
 if socket.get_ready_state()==WebSocketPeer.STATE_CLOSED:
  var was_guest=role=="guest";leave();panel.show();status.text="Broadcast connection ended. Rejoin with the teacher's code." if was_guest else "Classroom connection ended. Reopen Host to create a new room.";return
 if socket.get_ready_state()!=WebSocketPeer.STATE_OPEN:
  if connecting_timer>50:leave();panel.show();status.text="Connection timed out. Retry after checking Render and school network access."
  return
 heartbeat+=delta
 if heartbeat>=10:heartbeat=0;send({"type":"heartbeat"})
 var latest:Dictionary={};var budget=8
 while socket.get_available_packet_count()>0 and budget>0:
  budget-=1;var data=JSON.parse_string(socket.get_packet().get_string_from_utf8())
  if not data is Dictionary:continue
  if data.get("type")=="class_frame":latest=data
  else:packet(data)
 if not latest.is_empty():packet(latest)
 if role=="host" and started:
  var dev=get_tree().root.get_node_or_null("FXDevSession")
  if (dev==null or not dev.active) and not preload("res://scripts/education_access.gd").teacher():leave();return
  frame_timer+=delta
  if frame_timer>=(1.0 if Engine.get_frames_per_second()>0 and Engine.get_frames_per_second()<20 else .5) and socket.get_current_outbound_buffered_amount()<131072:frame_timer=0;capture()
 if role=="guest" and started:
  age+=delta
  if age>5:viewer_status.text="Waiting for the next frame… • Leave class remains available"
func _unhandled_input(event:InputEvent)->void:
 if role=="guest" and started and not event is InputEventMouseButton and not event is InputEventMouseMotion and not event is InputEventScreenTouch and not event is InputEventScreenDrag:get_viewport().set_input_as_handled()
