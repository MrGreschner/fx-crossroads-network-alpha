extends CanvasLayer
const S=preload("res://scripts/learning_store.gd")
const T=preload("res://scripts/teacher_store.gd")
const UI=preload("res://scripts/studio_ui.gd")
var socket:WebSocketPeer
var role=""
var room_code=""
var panel:PanelContainer
var status:Label
var code_field:LineEdit
var title:LineEdit
var pending={}
var incoming={}
var outgoing:Array=[]
var portfolio={}
var hello={}
var retry=0.0
var connecting=0.0
var timer=0.0
var heartbeat=0.0
var feedback={}
var peers={}
var dashboard:Node
func _ready()->void:
 layer=118;process_mode=Node.PROCESS_MODE_ALWAYS;panel=PanelContainer.new();panel.size=Vector2(920,510);add_child(panel);UI.apply(panel);panel.hide()
 var col=VBoxContainer.new();panel.add_child(col);label(col,"SUBMIT ASSIGNMENT ROOM",25)
 label(col,"Joining sends your current educational journal, linked work and submissions to this teacher. Use a class alias. It does not send your full player profile or grant control of your game. Join only a code given by your teacher.",16)
 title=LineEdit.new();title.text="My class";title.max_length=80;col.add_child(title);code_field=LineEdit.new();code_field.placeholder_text="ED classroom code";code_field.max_length=8;col.add_child(code_field)
 var row=HBoxContainer.new();col.add_child(row);button(row,"Host submission room",host);button(row,"Join & send my progress",join_room);button(row,"Send latest progress",upload);button(row,"Close room / leave",stop)
 status=label(col,"31 student seats • teacher retains received records locally • explicit joins only",16)
 button(col,"Accept returned feedback",accept);button(col,"Hide window",func():panel.hide())
func label(n:Node,t:String,size:int)->Label:
 var l=Label.new();l.text=t;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",size);n.add_child(l);return l
func button(n:Node,t:String,action:Callable)->Button:
 var b=Button.new();b.text=t;b.custom_minimum_size.y=44;n.add_child(b);b.pressed.connect(action);return b
func open()->void:panel.show()
func host()->void:
 if not preload("res://scripts/education_access.gd").teacher():status.text="Teacher Mode is required.";return
 if socket!=null:status.text="A room is already connected. Leave it first.";return
 role="host";connect_room({"type":"edu_host","teacher":true,"name":title.text.left(80),"version":1})
func join_room()->void:
 if not preload("res://scripts/education_access.gd").student():status.text="Student Mode is required.";return
 if socket!=null:status.text="Leave your existing room first.";return
 if preload("res://scripts/profile_store.gd").testing():status.text="Exit Game Dev / Playtest before submitting assessed work.";return
 var data=S.load_data()
 if data.student.strip_edges().is_empty():status.text="Set a class alias in your learning portfolio first.";return
 role="student";connect_room({"type":"edu_join","code":code_field.text.strip_edges().to_upper(),"name":data.student,"version":1})
func connect_room(packet:Dictionary)->void:
 socket=WebSocketPeer.new();socket.inbound_buffer_size=33554432;socket.outbound_buffer_size=8388608;socket.max_queued_packets=4096;pending=packet;connecting=0
 if socket.connect_to_url(get_tree().root.get_node("FXStudioPartner").service_url)!=OK:socket=null;status.text="Could not connect to the room service.";return
 status.text="Connecting…"
func send(packet:Dictionary)->void:
 if socket!=null and socket.get_ready_state()==WebSocketPeer.STATE_OPEN:socket.send_text(JSON.stringify(packet))
func upload()->void:
 if role!="student" or room_code.is_empty():status.text="Join your teacher's room first.";return
 if not outgoing.is_empty():status.text="Upload already in progress.";return
 if preload("res://scripts/profile_store.gd").testing():status.text="Exit Game Dev / Playtest before submitting assessed work.";return
 portfolio=S.load_data()
 var text=preload("res://scripts/education_wire.gd").text(portfolio)
 if text.to_utf8_buffer().size()>S.MAX_REVIEW:status.text="Portfolio exceeds 4 MB. Share by file or review locally.";return
 hello={"type":"edu_begin","length":text.length(),"token":text.sha256_text(),"student_id":portfolio.get("learner_id","")}
 outgoing=[]
 for i in range(0,text.length(),10000):outgoing.append({"type":"edu_chunk","index":int(i/10000),"text":text.substr(i,10000)})
 send(hello);retry=0;status.text="Waiting for an upload slot…"
func return_feedback(peer:String,value:Dictionary)->void:
 if role!="host":return
 var text=preload("res://scripts/education_wire.gd").text(S.review_bundle(value))
 if text.length()>S.MAX_REVIEW:status.text="Feedback exceeds 4 MB.";return
 send({"type":"edu_feedback_begin","peer":peer,"length":text.length(),"token":text.sha256_text()})
 outgoing.clear()
 for i in range(0,text.length(),10000):outgoing.append({"type":"edu_feedback_chunk","index":int(i/10000),"text":text.substr(i,10000)})
func accept()->void:
 if feedback.is_empty():status.text="No returned feedback yet.";return
 var data=S.load_data();var issue=S.apply_feedback(data,feedback);status.text="Feedback saved to matching submissions." if issue.is_empty() else issue
 if issue.is_empty():feedback={}
func stop()->void:
 send({"type":"edu_leave"})
 if socket!=null:socket.close()
 socket=null;role="";room_code="";outgoing.clear();incoming.clear();hello={};panel.hide()
func packet(p:Dictionary)->void:
 match str(p.get("type","")):
  "server_info":
   if not "education_rooms" in p.get("features",[]):status.text="Redeploy the v141 Render service for class submission rooms.";pending={};return
   send(pending);pending={}
  "edu_joined":
   room_code=str(p.code);code_field.text=room_code;status.text="Room "+room_code+" connected."
   if role=="student":upload()
  "edu_status":
   if role=="host":status.text="Code "+room_code+" • "+str(p.count)+" / 31 students • received work stays in your profile"
  "edu_wait":retry=2;status.text="Waiting for an upload slot; your game remains playable."
  "edu_upload":hello={};status.text="Uploading educational progress…"
  "edu_stored":status.text="Teacher received your progress. Use Send latest progress after more work."
  "edu_transfer":
   var key=str(p.peer)
   if int(p.get("length",0))<1 or int(p.length)>S.MAX_REVIEW or str(p.get("token","")).length()!=64:return
   incoming[key]={"length":int(p.length),"token":str(p.token),"index":0,"parts":[],"student_id":str(p.get("student_id","")),"direction":str(p.get("direction","work"))}
  "edu_data":
   var key=str(p.peer)
   if not incoming.has(key):return
   var d=incoming[key]
   if int(p.get("index",-1))!=d.index or not p.get("text") is String or p.text.length()>10000:return
   d.parts.append(p.text);d.index+=1
   if d.index*10000<d.length:return
   var text="".join(d.parts);incoming.erase(key)
   if text.length()!=d.length or text.sha256_text()!=d.token:status.text="Transfer integrity check failed.";return
   var value=JSON.parse_string(text)
   if not S.valid(value) or (role=="host" and value.get("learner_id","")!=d.student_id):status.text="Invalid portfolio rejected.";return
   if role=="host" and d.direction=="work":
    var issue=T.ingest(room_code,title.text,d.student_id,value);status.text="Received "+str(value.student)+" • saved to class view" if issue.is_empty() else issue
    if issue.is_empty():
     peers[room_code+"-"+d.student_id]=key;send({"type":"edu_ack","peer":key})
     if is_instance_valid(dashboard):dashboard.render()
   elif role=="student":feedback=value;status.text="Teacher feedback arrived. Accept it to update your matching submissions."
  "edu_closed":stop();panel.show();status.text="Submission room ended. Saved teacher records remain available."
  "error":status.text=str(p.get("message","Connection error"));outgoing.clear();hello={}
func _process(dt:float)->void:
 panel.size=Vector2(920,510)
 var view=get_viewport().get_visible_rect().size;var fit=minf(1,minf((view.x-24)/panel.size.x,(view.y-24)/panel.size.y));panel.scale=Vector2.ONE*fit;panel.position=(view-panel.size*fit)*.5
 if socket==null:return
 socket.poll();timer+=dt;heartbeat+=dt
 if socket.get_ready_state()==WebSocketPeer.STATE_CLOSED:socket=null;role="";room_code="";outgoing.clear();status.text="Disconnected. Saved teacher records remain available.";return
 if socket.get_ready_state()!=WebSocketPeer.STATE_OPEN:
  connecting+=dt
  if connecting>45:stop();panel.show();status.text="Connection timed out. Check your teacher code and network."
  return
 while socket.get_available_packet_count()>0:
  var p=JSON.parse_string(socket.get_packet().get_string_from_utf8())
  if p is Dictionary:packet(p)
  if socket==null:return
 if retry>0:
  retry-=dt
  if retry<=0:send(hello)
 if timer>.06 and not outgoing.is_empty() and hello.is_empty():timer=0;send(outgoing.pop_front())
 if heartbeat>10:heartbeat=0;send({"type":"heartbeat"})
