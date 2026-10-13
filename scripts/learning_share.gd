extends CanvasLayer
## Explicit private review sharing. No profile control and no automatic submission.
const S=preload("res://scripts/learning_store.gd")
const UI=preload("res://scripts/studio_ui.gd")
var page:Node
var panel:PanelContainer
var status:Label
var code_field:LineEdit
var approval:Button
var rejection:Button
var current_only:CheckButton
var socket:WebSocketPeer
var pending:Dictionary={}
var outgoing:Array=[]
var incoming={}
var result:Dictionary={}
var mode=""
var code=""
var clock=0.0
var heartbeat=0.0
var age=0.0
var client_id=""
func setup(owner:Node)->void:
 page=owner;layer=116;panel=PanelContainer.new();panel.size=Vector2(650,450);add_child(panel);UI.apply(panel);panel.hide()
 var col=VBoxContainer.new();panel.add_child(col);page.label(col,"PRIVATE TEACHER REVIEW",24);page.label(col,"Only submitted snapshots are shared. Approve the reviewer before sending work. Keep this window open. Codes expire after 30 minutes; nothing is published publicly.",16)
 code_field=LineEdit.new();code_field.placeholder_text="Student review code • RV…";code_field.max_length=8;col.add_child(code_field)
 var row=HBoxContainer.new();col.add_child(row);page.button(row,"Create review code",func():connect_review(false));page.button(row,"Join review",func():connect_review(true));page.button(row,"Stop sharing",stop)
 current_only=CheckButton.new();current_only.text="Share current module only";col.add_child(current_only)
 approval=page.button(col,"Approve reviewer",approve);approval.hide();rejection=page.button(col,"Decline reviewer",func():send({"type":"assessment_reject"});approval.hide();rejection.hide());rejection.hide();status=page.label(col,"No connection. Teacher unlocks Teacher Mode through Elder Ram first.",16)
 page.button(col,"Accept returned teacher feedback",accept_feedback);page.button(col,"Hide window",func():panel.hide())
func open(as_teacher:bool)->void:
 panel.show();mode="teacher" if as_teacher else "student"
func connect_review(as_teacher:bool)->void:
 if socket!=null:status.text="Stop the existing review first.";return
 if as_teacher and not page.teacher:status.text="Unlock teacher review through Elder Ram first.";return
 if not as_teacher and page.teacher:status.text="Only the student can host their submitted portfolio.";return
 var bundle=S.review_bundle(page.data)
 if not as_teacher and bundle.submissions.is_empty():status.text="Submit a module before creating a review code.";return
 if current_only.button_pressed:
  bundle.submissions=bundle.submissions.filter(func(item):return item.module==page.module)
  var used={}
  for item in bundle.submissions:
   for ref in item.refs:used[ref]=bundle.artifacts[ref]
  bundle.artifacts=used;bundle.active=page.module
  if bundle.submissions.is_empty():status.text="Submit the current module first.";return
 var text=wire_text(bundle)
 if not as_teacher and text.to_utf8_buffer().size()>S.MAX_REVIEW:status.text="Review exceeds 4 MB. Download the portfolio or review fewer module snapshots locally.";return
 mode="teacher" if as_teacher else "student";pending={"type":"assessment_join" if as_teacher else "assessment_host","code":code_field.text.strip_edges().to_upper(),"name":page.teacher_name if as_teacher else page.data.student,"version":1}
 if not as_teacher:pending.length=text.length();pending.token=text.sha256_text();queue_text(text,"assessment_chunk")
 socket=WebSocketPeer.new();socket.inbound_buffer_size=8388608;socket.outbound_buffer_size=8388608;age=0
 var url=page.get_tree().root.get_node("FXStudioPartner").service_url
 if socket.connect_to_url(url)!=OK:socket=null;status.text="Could not connect to the room service.";return
 status.text="Connecting to review service…"
func wire_text(value:Dictionary)->String:
 # ASCII JSON prevents UTF-16/server vs Unicode/Godot chunk-length mismatches.
 var text=JSON.stringify(value);var parts=PackedStringArray();var begin=0
 for index in text.length():
  var point=text.unicode_at(index)
  if point<128:continue
  parts.append(text.substr(begin,index-begin))
  if point<=65535:parts.append("\\u%04x" % point)
  else:
   point-=65536;parts.append("\\u%04x\\u%04x" % [55296+(point>>10),56320+(point&1023)])
  begin=index+1
 parts.append(text.substr(begin));return "".join(parts)
func queue_text(text:String,type:String)->void:
 outgoing.clear()
 for i in range(0,text.length(),10000):outgoing.append({"type":type,"index":int(i/10000),"text":text.substr(i,10000)})
func send(packet:Dictionary)->void:
 if socket!=null and socket.get_ready_state()==WebSocketPeer.STATE_OPEN:socket.send_text(JSON.stringify(packet))
func stop()->void:
 send({"type":"assessment_leave"})
 if socket!=null:socket.close()
 socket=null;outgoing.clear();incoming={};client_id="";approval.hide();rejection.hide();status.text="Review stopped. Downloaded/local copies remain with their holders.";code=""
func approve()->void:
 if client_id.is_empty():return
 send({"type":"assessment_approve","id":client_id});approval.hide();rejection.hide();status.text="Reviewer approved. Sharing submitted evidence…"
func return_feedback(data:Dictionary)->void:
 if mode!="teacher" or socket==null:page.message.text="Connect through the student's review code first.";return
 var text=wire_text(data)
 if not S.valid(data) or text.to_utf8_buffer().size()>S.MAX_REVIEW:page.message.text="Feedback packet is invalid or exceeds 4 MB.";return
 send({"type":"assessment_feedback_begin","length":text.length(),"token":text.sha256_text()});queue_text(text,"assessment_feedback_chunk");page.message.text="Sending ratings for student acceptance…"
func accept_feedback()->void:
 if mode!="student" or result.is_empty():status.text="No returned feedback available.";return
 var current=S.load_data();var issue=S.apply_feedback(current,result)
 if issue.is_empty():page.data=current;page.render();result={};status.text="Teacher feedback accepted into matching frozen submissions."
 else:status.text=issue
func packet(data:Dictionary)->void:
 match str(data.get("type","")):
  "server_info":
   if not "assessment_review" in data.get("features",[]):status.text="Update the Render room service to v141 for review codes.";pending={};outgoing.clear();return
   send(pending);pending={}
  "assessment_created":code=str(data.code);code_field.text=code;status.text="Review code: "+code+" • uploading submitted snapshots…"
  "assessment_ready":status.text="Ready. Give "+code+" to your teacher; approve their request here."
  "assessment_requested":client_id=str(data.id);approval.text="Approve "+str(data.name).left(80);approval.show();rejection.show();status.text="A reviewer requested access. Approve only your teacher."
  "assessment_waiting":status.text="Waiting for the student to approve your review request."
  "assessment_transfer":
   if not data.get("length") is float and not data.get("length") is int or int(data.get("length",0))<1 or int(data.get("length",0))>S.MAX_REVIEW or str(data.get("token","")).length()!=64:status.text="Invalid transfer header.";return
   incoming={"length":int(data.length),"token":str(data.token),"index":0,"parts":[],"direction":str(data.direction)};status.text="Receiving evidence…"
  "assessment_data":
   if incoming.is_empty() or data.get("index")!=incoming.index or not data.get("text") is String or data.text.length()>10000:return
   incoming.parts.append(data.text);incoming.index+=1
   if incoming.index>420 or incoming.index*10000>S.MAX_REVIEW+10000:incoming={};status.text="Transfer exceeds limit.";return
   if incoming.index*10000<incoming.length:return
   var text="".join(incoming.parts)
   if text.length()!=incoming.length or text.sha256_text()!=incoming.token or text.to_utf8_buffer().size()>S.MAX_REVIEW:incoming={};status.text="Transfer failed integrity checks.";return
   var value=JSON.parse_string(text);var direction=incoming.direction;incoming={}
   if not S.valid(value):status.text="Portfolio failed validation. No local account changed.";return
   if direction=="work" and page.teacher:
    page.data=value;page.remote=true;page.module=value.active;page.selected_submission="";page.sync_picker();page.render();status.text="Submitted work received. Mark outcomes; return ratings through Review code."
   elif direction=="feedback":result=value;status.text="Feedback received. Press Accept returned teacher feedback to save it."
  "assessment_reviewer_left":client_id="";approval.hide();rejection.hide();status.text="Reviewer left. The same code can be used again."
  "assessment_closed":socket.close();socket=null;outgoing.clear();status.text="Review closed or expired. Download your review copy before leaving."
  "error":status.text=str(data.message);outgoing.clear()
func _process(delta:float)->void:
 var view=get_viewport().get_visible_rect().size;var fit=minf(1,minf((view.x-24)/650,(view.y-24)/450));panel.scale=Vector2.ONE*fit;panel.position=(view-panel.size*fit)*.5
 if socket==null:return
 socket.poll();clock+=delta;heartbeat+=delta;age+=delta
 if age>1800:stop();return
 if socket.get_ready_state()==WebSocketPeer.STATE_OPEN:
  while socket.get_available_packet_count()>0:
   var value=JSON.parse_string(socket.get_packet().get_string_from_utf8())
   if value is Dictionary:packet(value)
   if socket==null:return
  if clock>=.06 and not outgoing.is_empty() and pending.is_empty():clock=0;send(outgoing.pop_front())
  if heartbeat>=10:heartbeat=0;send({"type":"heartbeat"})
 elif socket.get_ready_state()==WebSocketPeer.STATE_CLOSED:socket=null;outgoing.clear();status.text="Disconnected. Re-create a code; local submissions are intact."
