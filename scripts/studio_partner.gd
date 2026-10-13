extends CanvasLayer
## Invite-only shared project. Both creators edit concurrently; the session owner keeps the main copy; no executable code is received.
const UI=preload("res://scripts/studio_ui.gd")
const Project=preload("res://scripts/workshop_project.gd")
const Merge=preload("res://scripts/studio_merge.gd")
var last_local:Dictionary={}
var edit_parts:Array=[]
var packet_tick=0.0
var refresh_pending=false
var service_url="wss://fx-crossroads-rooms.onrender.com"
var workshop:Node
var socket:WebSocketPeer
var panel:PanelContainer
var status:Label
var code_field:LineEdit
var name_field:LineEdit
var strip:PanelContainer
var caption:Label
var blocker:Control
var identity=""
var writer=""
var code=""
var revision=0
var roster:Array=[]
var pending:Dictionary={}
var outgoing:Array=[]
var incoming:Array=[]
var shared:Dictionary={}
var sent_hash=""
var clock=0.0
var heartbeat=0.0
var age=0.0
var waiting=false
var pass_pending=false
var requested=""
func _ready()->void:
 layer=96;process_mode=Node.PROCESS_MODE_ALWAYS
 blocker=Control.new();blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);blocker.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(blocker);blocker.hide()
 strip=PanelContainer.new();add_child(strip);UI.apply(strip);strip.hide()
 var row=HBoxContainer.new();strip.add_child(row);caption=Label.new();row.add_child(caption)
 button(row,"Download shared",download)
 button(row,"Leave",leave)
 panel=PanelContainer.new();panel.size=Vector2(620,360);add_child(panel);UI.apply(panel);panel.hide()
 var body=VBoxContainer.new();panel.add_child(body)
 var title=Label.new();title.text="PARTNER UP • two creators, two pencils";title.add_theme_font_size_override("font_size",22);body.add_child(title)
 var info=Label.new();info.text="Invite one partner. Both of you edit and draw live.\nBoth students can download the shared creation.\nJoining replaces your open draft; saved library files stay intact.\nA backup of your open draft is kept on this device.";body.add_child(info)
 name_field=LineEdit.new();name_field.placeholder_text="Display name";name_field.max_length=18;body.add_child(name_field)
 code_field=LineEdit.new();code_field.placeholder_text="Invite code • SP…";code_field.max_length=8;body.add_child(code_field)
 var actions=HBoxContainer.new();body.add_child(actions);button(actions,"Create session",func():connect_session(true));button(actions,"Join partner",func():connect_session(false));button(actions,"Close",func():panel.hide())
 status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.text="The session creator owns the main project and chooses the lab. Both students can edit it. Same pixel or setting: latest received edit wins.";body.add_child(status)
func button(parent:Node,text:String,action:Callable)->void:
 var b=Button.new();b.text=text;b.custom_minimum_size.y=44;b.pressed.connect(action);parent.add_child(b)
func open(owner:Node)->void:
 workshop=owner;panel.show()
 if not code.is_empty():status.text="Invite code: "+code+" • use the shared bar below."
func connect_session(host:bool)->void:
 if socket!=null:status.text="Leave the current session first.";return
 var previous=capture()
 if not previous.is_empty():var f=FileAccess.open("user://fx_partner_previous.json",FileAccess.WRITE);if f:f.store_string(JSON.stringify(previous))
 identity="";writer="";revision=0;sent_hash="";shared={};age=0
 pending={"type":"partner_host" if host else "partner_join","version":31,"name":name_field.text,"code":code_field.text}
 socket=WebSocketPeer.new();socket.inbound_buffer_size=4194304;socket.outbound_buffer_size=4194304
 if socket.connect_to_url(service_url)!=OK:socket=null;status.text="Could not connect. Check your connection.";return
 status.text="Connecting to Studio…"
func send(value:Dictionary)->void:
 if socket!=null and socket.get_ready_state()==WebSocketPeer.STATE_OPEN:socket.send_text(JSON.stringify(value))
func leave()->void:
 send({"type":"partner_leave"})
 if socket!=null:socket.close()
 socket=null;code="";writer="";outgoing.clear();waiting=false;pass_pending=false;blocker.hide();strip.hide();status.text="Session ended. Your shared draft is still here; download or save it."
func pass_pencil()->void:
 if writer!=identity or roster.size()<2:return
 pass_pending=true;clock=0;sync_draft()
 if not waiting and outgoing.is_empty():send({"type":"partner_pass"});pass_pending=false
func valid(envelope:Dictionary)->bool:
 var value:Variant=envelope.get("value")
 match str(envelope.get("kind","")):
  "hero":return Project.validate(value).is_empty()
  "ability":return Project.validate_attack(value).is_empty()
  "enemy":return preload("res://scripts/studio_enemy_project.gd").validate(value).is_empty()
  "behavior":return preload("res://scripts/studio_behavior.gd").validate(value).is_empty()
 return false
func capture()->Dictionary:
 if not is_instance_valid(workshop) or not workshop.active:return {}
 for child in workshop.get_children():
  if not child is CanvasLayer or child.get("panel")==null or not child.panel.visible:continue
  if child.get_script()==preload("res://scripts/studio_behavior_lab.gd"):return {"kind":"behavior","value":child.behavior.duplicate(true)}
  if child.get_script()==preload("res://scripts/studio_enemy_lab.gd"):return {"kind":"enemy","value":child.enemy.duplicate(true)}
  if child.get_script()==preload("res://scripts/studio_lab.gd"):return {"kind":"ability","value":child.attack.duplicate(true)}
 if workshop.panel.visible:return {"kind":"hero","value":workshop.project.duplicate(true)}
 return shared
func active_editor()->Node:
 if not is_instance_valid(workshop):return null
 for child in workshop.get_children():
  if child.get_script() in [preload("res://scripts/studio_lab.gd"),preload("res://scripts/studio_enemy_lab.gd"),preload("res://scripts/studio_behavior_lab.gd")] and child.panel.visible:return child
 return workshop
func update_model(envelope:Dictionary)->void:
 var editor=active_editor()
 if editor==null:return
 var target:Dictionary=workshop.project if envelope.kind=="hero" else editor.attack if envelope.kind=="ability" else editor.enemy if envelope.kind=="enemy" else editor.behavior
 Merge.merge_into(target,envelope.value)
func set_image(path:Array,encoded:String)->void:
 var current=capture()
 if current.is_empty():return
 Merge.set_at(current,path,encoded);update_model(current)
func apply_shared(envelope:Dictionary)->void:
 if not valid(envelope):status.text="Partner draft failed validation. The last valid draft remains.";return
 var current=capture()
 shared=envelope.duplicate(true)
 if not is_instance_valid(workshop):return
 var value:Dictionary=envelope.value.duplicate(true)
 if current.get("kind")==envelope.kind:
  var editor=active_editor()
  var target:Dictionary=workshop.project if envelope.kind=="hero" else editor.attack if envelope.kind=="ability" else editor.enemy if envelope.kind=="enemy" else editor.behavior
  Merge.merge_into(target,value);refresh_pending=true
 else:
  for pixels in get_tree().get_nodes_in_group("studio_live_pixels"):pixels.queue_free()
  for child in workshop.get_children():
   if child.get_script() in [preload("res://scripts/studio_lab.gd"),preload("res://scripts/studio_enemy_lab.gd"),preload("res://scripts/studio_behavior_lab.gd")]:workshop.remove_child(child);child.queue_free()
  workshop.lab=null;workshop.panel.hide();workshop.test_panel.hide()
  if is_instance_valid(workshop.hub):workshop.hub.hide()
  match str(envelope.kind):
   "hero":workshop.project=value;workshop.panel.show();workshop.render()
   "ability":workshop.open_lab();workshop.lab.load_example(value)
   "enemy":workshop.open_enemy();for child in workshop.get_children():
    if child.get_script()==preload("res://scripts/studio_enemy_lab.gd"):child.enemy=value;child.render()
   "behavior":workshop.open_behavior(value)
 last_local=capture().duplicate(true)
func refresh_editor()->void:
 var focused=get_viewport().gui_get_focus_owner()
 if focused is LineEdit or focused is TextEdit or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):return
 var editor=active_editor()
 if editor==null:return
 if shared.get("kind")=="hero":workshop.render();workshop.edited(false)
 elif shared.get("kind")=="ability":editor.code.text=editor.attack.get("program",editor.code.text);editor.render_gui();editor.apply_code()
 elif shared.get("kind")=="enemy":editor.render();editor.persist()
 elif shared.get("kind")=="behavior":editor.name_field.text=editor.behavior.name;editor.code.text=editor.behavior.program;editor.apply_code()
 refresh_pending=false
func sync_draft()->void:
 if waiting or not outgoing.is_empty():return
 var envelope=capture()
 if envelope.is_empty() or not valid(envelope):return
 if not shared.is_empty() and envelope.kind==shared.kind:
  var ops=Merge.diff(last_local,envelope)
  if ops.is_empty():return
  for start in range(0,ops.size(),128):
   var packet={"type":"partner_patch","kind":envelope.kind,"ops":ops.slice(start,start+128)}
   var raw=JSON.stringify(packet)
   if raw.to_utf8_buffer().size()<90000:send(packet)
   else:
    var count=ceili(raw.length()/24000.0)
    for n in count:outgoing.append({"type":"partner_delta_chunk","index":n,"count":count,"text":raw.substr(n*24000,24000)})
  last_local=envelope.duplicate(true);return
 if writer!=identity:return
 var raw=JSON.stringify(envelope)
 if raw.to_utf8_buffer().size()>2200000:status.text="Draft too large to share.";return
 shared=envelope.duplicate(true);last_local=envelope.duplicate(true)
 var count=ceili(raw.length()/24000.0)
 for n in count:outgoing.append({"type":"partner_chunk","index":n,"count":count,"revision":revision,"text":raw.substr(n*24000,24000)})
 waiting=true;age=0
func local_pixels(path:Array,width:int,height:int,runs:Array,encoded:String)->void:
 if code.is_empty() or shared.is_empty():return
 var current=capture()
 if current.get("kind")!=shared.kind:return
 Merge.set_at(current,path,encoded);update_model(current)
 if current.kind=="hero":workshop.edited(false)
 # Pixel operations, not whole-image replacement, preserve the partner's other strokes.
 send({"type":"partner_pixels","kind":current.kind,"path":path,"width":width,"height":height,"runs":runs})
 Merge.set_at(last_local,path,encoded)
func apply_edit(data:Dictionary)->void:
 if data.get("kind")!=shared.get("kind") or not data.get("ops") is Array:return
 var candidate=shared.duplicate(true)
 for op in data.ops:
  if not op is Dictionary or not op.get("path") is Array:return
  Merge.set_at(candidate,op.path,op.get("value"),bool(op.get("erase",false)))
 if not valid(candidate):status.text="Invalid partner edit rejected. Your last valid project is retained.";return
 var current=capture()
 if current.is_empty() or current.get("kind")!=shared.kind:
  shared=candidate
  if shared.kind=="hero" and is_instance_valid(workshop):Merge.merge_into(workshop.project,shared.value);workshop.save_draft()
  revision=int(data.get("revision",revision));return
 for op in data.ops:
  if not op.get("path") is Array:continue
  Merge.set_at(shared,op.path,op.get("value"),bool(op.get("erase",false)))
  var local=Merge.get_at(current,op.path);var baseline=Merge.get_at(last_local,op.path)
  if local==baseline:
   Merge.set_at(current,op.path,op.get("value"),bool(op.get("erase",false)));Merge.set_at(last_local,op.path,op.get("value"),bool(op.get("erase",false)))
   for editor in get_tree().get_nodes_in_group("studio_live_pixels"):
    if editor.live_path==op.path and op.get("value") is String:editor.remote_image(op.value)
 update_model(current)
 if current.get("kind")=="hero":workshop.edited(false)
 refresh_pending=true;revision=int(data.get("revision",revision))
func download()->void:
 var envelope=capture()
 if envelope.is_empty() or not valid(envelope):status.text="Open a valid draft before downloading.";panel.show();return
 var value:Dictionary=envelope.value
 # Abilities use the lab's portable wrapper, so Hero Workshop imports them directly.
 var payload:Dictionary=value
 if envelope.kind=="ability":payload={"format":"fx-crossroads-ability","version":1,"attack":value}
 workshop.write_download(JSON.stringify(payload,"  "),"partner-"+str(envelope.kind)+".json")
func receive(data:Dictionary)->void:
 match str(data.get("type","")):
  "server_info":
   if not "studio_live" in data.get("features",[]):status.text="Partner sessions need the updated Render room service.";leave();panel.show();status.text="Redeploy the v139 room service to enable Partner Up."
   else:send(pending);pending={}
  "partner_identity":identity=str(data.id)
  "partner_status":
   code=str(data.code);revision=int(data.revision);writer=str(data.writer);roster=data.roster;requested="";panel.hide();strip.show();get_viewport().gui_release_focus()
  "partner_cursor":
   for editor in get_tree().get_nodes_in_group("studio_live_pixels"):
    if editor.live_path==data.get("path"):editor.canvas.remote_cell=Vector2i(int(data.get("x",-1)),int(data.get("y",-1)));editor.canvas.remote_stamp=Time.get_ticks_msec();editor.canvas.queue_redraw()
  "partner_edit":apply_edit(data)
  "partner_edit_chunk":
   if int(data.get("index",-1))==0:edit_parts=[]
   if int(data.get("index",-1))!=edit_parts.size() or int(data.get("count",0))>96:return
   edit_parts.append(str(data.get("text","")))
   if edit_parts.size()==int(data.count):
    var value=JSON.parse_string("".join(edit_parts));edit_parts=[]
    if value is Dictionary:apply_edit(value)
  "partner_requested":requested=str(data.name)+" requests control";status.text=requested
  "partner_saved":
   revision=int(data.revision);waiting=false
   if pass_pending:
    sync_draft()
    if not waiting:send({"type":"partner_pass"});pass_pending=false
  "partner_chunk":
   if int(data.index)==0:incoming=[]
   if int(data.index)!=incoming.size() or int(data.count)>96:return
   incoming.append(str(data.text))
   if incoming.size()==int(data.count):
    var parsed:Variant=JSON.parse_string("".join(incoming));incoming=[]
    if parsed is Dictionary:apply_shared(parsed);revision=int(data.revision)
  "error":status.text=str(data.get("message","Session error"));panel.show();waiting=false;outgoing.clear();sent_hash="";pass_pending=false
func editor_view()->Vector2:
 return get_viewport().get_visible_rect().size-Vector2(0,108 if not code.is_empty() else 0)
func _input(event:InputEvent)->void:
 if blocker.visible and not panel.visible and event is InputEventKey:
  if is_instance_valid(workshop) and is_instance_valid(workshop.native_dialog) and workshop.native_dialog.visible:return
  get_viewport().set_input_as_handled()
func _unhandled_input(event:InputEvent)->void:
 if blocker.visible:get_viewport().set_input_as_handled()
func _process(delta:float)->void:
 var view=get_viewport().get_visible_rect().size
 panel.size=Vector2(620,430)
 var fit=minf(1,minf((view.x-24)/maxf(panel.size.x,620),(view.y-24)/maxf(panel.size.y,360)));panel.scale=Vector2.ONE*fit;panel.position=(view-panel.size*fit)*.5
 strip.position=Vector2(12,view.y-strip.size.y-12);strip.scale=Vector2.ONE*minf(1,(view.x-24)/maxf(strip.size.x,1))
 blocker.visible=panel.visible
 if socket==null:return
 socket.poll();age+=delta;heartbeat+=delta;clock+=delta
 if socket.get_ready_state()==WebSocketPeer.STATE_CLOSED or age>20 and code.is_empty():leave();panel.show();status.text="Connection closed. Your draft is retained. Reconnect when ready.";return
 while socket.get_available_packet_count()>0:
  var value:Variant=JSON.parse_string(socket.get_packet().get_string_from_utf8());if value is Dictionary:receive(value)
 if heartbeat>10:heartbeat=0;send({"type":"heartbeat"})
 packet_tick+=delta
 if not outgoing.is_empty() and packet_tick>=.05:packet_tick=0;send(outgoing.pop_front())
 if waiting and age>20:waiting=false;outgoing.clear();sent_hash="";status.text="Transfer timed out; retrying the current draft.";age=0
 if refresh_pending and get_tree().get_nodes_in_group("studio_live_pixels").is_empty():refresh_editor()
 if clock>.2:clock=0;sync_draft()
 if not code.is_empty():
  caption.text=code+" • "+str(roster.size())+"/2 • Both editing • "+("Main owner" if writer==identity else "Partner")
