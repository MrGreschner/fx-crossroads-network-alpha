extends CanvasLayer
## Account-authorised classroom tools; no testing flag or gameplay power is changed.
const S=preload("res://scripts/learning_store.gd")
const UI=preload("res://scripts/studio_ui.gd")
var shortcut:Button
var panel:PanelContainer
var content:VBoxContainer
var status:Label
var request:HTTPRequest
var busy=false
var op=""
var selected_module=""
var student_data:Dictionary={}
var assignment:OptionButton
var last_sync=""
var synced_account=""
var target_view="Overview"
var return_menu=""
func account()->Node:return get_tree().root.get_node("FXAccount")
func _ready()->void:
 layer=113;shortcut=Button.new();shortcut.text="Teacher menu";shortcut.custom_minimum_size=Vector2(140,34);shortcut.pressed.connect(open_teacher);add_child(shortcut);preload("res://scripts/top_button_style.gd").apply(shortcut);shortcut.hide()
 request=HTTPRequest.new();request.timeout=25;request.body_size_limit=12582912;add_child(request);request.request_completed.connect(completed)
func _process(_dt:float)->void:
 var a=account();var l=a.legacy()
 shortcut.visible=l!=null and not a.token.is_empty() and str(a.user.get("role",""))=="teacher" and not is_instance_valid(panel) and (not l.arcade and l.game.mode=="town" and l.game.menu in ["","town","main"])
 shortcut.position=Vector2(maxf(18,get_viewport().get_visible_rect().size.x-735),8)
 if is_instance_valid(panel):
  var size=get_viewport().get_visible_rect().size;panel.size=Vector2(minf(1050,size.x-24),minf(680,size.y-24));panel.position=(size-panel.size)*.5
func call_api(path:String,payload:Variant=null,operation:String="")->void:
 if busy:return
 if account().token.is_empty():return
 busy=true;op=operation if not operation.is_empty() else path
 var headers=PackedStringArray(["Content-Type: application/json","Authorization: Bearer "+account().token])
 var error=request.request(account().endpoint+"/education/"+path,headers,HTTPClient.METHOD_GET if payload==null else HTTPClient.METHOD_POST,"" if payload==null else JSON.stringify(payload))
 if error!=OK:busy=false;set_status("Could not connect. Your local work is retained.")
func shell(title:String)->void:
 close();var l=account().legacy()
 if l!=null:return_menu=l.game.menu;l.game.menu="class_pro"
 panel=PanelContainer.new();add_child(panel);UI.apply(panel)
 var margin=MarginContainer.new();margin.add_theme_constant_override("margin_left",22);margin.add_theme_constant_override("margin_right",22);margin.add_theme_constant_override("margin_top",18);margin.add_theme_constant_override("margin_bottom",18);panel.add_child(margin)
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",12);margin.add_child(col)
 var top=HBoxContainer.new();col.add_child(top);var heading=label(top,title,26);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button(top,"Close",close)
 var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(scroll);content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_theme_constant_override("separation",12);scroll.add_child(content)
 status=label(col,"",15)
func open_teacher()->void:
 if account().token.is_empty() or str(account().user.get("role",""))!="teacher":return
 shell("TEACHER WORKSPACE")
 UI.accent(button(content,"Manage Class Pro ↗",launch))
 label(content,"Open your professional class workspace in a separate browser tab. Your existing teacher workspace session is reused; otherwise sign in with your Crossroads teacher account. See students, classes, modules, submitted work and your gradebook.",18)
 button(content,"Learning Academy • course lessons & practice",func():close();account().legacy().game.open_business_academy())
 button(content,"Students & classes",func():launch("Students & classes"))
 button(content,"Submitted assignments • review & grade",func():launch("Submissions"))
 button(content,"Spotlight • harmless presentation marker",func():get_tree().root.get_node("FXEducationTools").spotlight=true;close())
 button(content,"Local class backups • legacy",func():
  if not preload("res://scripts/education_access.gd").review_allowed():set_status("Choose or load your cloud profile first to use local class records.");return
  close();load("res://scripts/teacher_dashboard.gd").open(account().legacy()))
 button(content,"Broadcast lesson",func():close();get_tree().root.get_node("FXClassroom").host())
 label(content,"Teacher and Student access do not switch on Game Dev, unlock realms, change combat, or stop normal progress. Close this menu to keep playing.",16)
const TEACHER_VIEWS=["Overview","Students & classes","Students","Modules","Assignments","Submissions","Gradebook","Learning Academy","Venture access & progress"]
func workspace_url(view:String="Overview")->String:
 var base=account().endpoint.trim_suffix("/")
 if not base.begins_with("https://") and not (OS.is_debug_build() and base.begins_with("http://127.0.0.1:")):return ""
 var selected=view if view in TEACHER_VIEWS else "Overview"
 return base+"/education/teacher?view="+selected.uri_encode()
func launch(view:String="Overview")->void:
 target_view=view if view in TEACHER_VIEWS else "Overview"
 if account().token.is_empty() or str(account().user.get("role",""))!="teacher":account().open();return
 var url=workspace_url(target_view)
 if url.is_empty():set_status("The teacher website address is unavailable. Reopen the cloud account menu and try again.");return
 # Open the actual destination during this click. The website already supports
 # its own secure teacher login and first-party session. No waiting blank tab,
 # deferred popup redirect, or one-use handoff is required for this action.
 open_workspace_url(url)
func open_workspace_url(url:String)->void:
 if OS.has_feature("web"):
  JavaScriptBridge.eval("window.open("+JSON.stringify(url)+",'_blank','noopener'); void 0;",true)
 elif OS.shell_open(url)!=OK:
  set_status("Could not open your browser. Open "+account().endpoint+"/education/teacher and sign in with your Crossroads teacher account.");return
 set_status("Teacher website opened. If asked, use your Crossroads teacher account. If no tab appeared, allow pop-ups and click again.")
func open_student(module:String="")->void:
 selected_module=module
 shell("STUDENT • ASSIGNMENTS & FEEDBACK")
 if not account().loaded or account().school_role()!="student":label(content,"Sign in, load your student profile and ask your administrator to link you to your teacher.",18);return
 button(content,"Learning Academy • assigned modules",func():close();account().legacy().game.open_business_academy())
 label(content,"Only your learning journal and frozen submitted work are shared. Unrelated game saves and passwords are not sent.",16)
 call_api("student",null,"student")
func render_student()->void:
 if not is_instance_valid(content):return
 for node in content.get_children():content.remove_child(node);node.queue_free()
 var data=S.load_data();var latest:Dictionary={}
 for sub in data.submissions:
  if selected_module.is_empty() or sub.module==selected_module:latest=sub
 label(content,"YOUR ASSIGNMENTS",22)
 assignment=OptionButton.new();assignment.custom_minimum_size.y=44;content.add_child(assignment);assignment.add_item("Whole portfolio • no assignment selected");assignment.set_item_metadata(0,"")
 for entry in student_data.get("assignments",[]):
  var card=UI.card(content,str(entry.title),str(entry.module)+" • "+str(entry.teacher_name)+" • "+str(entry.points)+" points")
  label(card,str(entry.instructions),16)
  if not latest.is_empty() and entry.module==latest.module:assignment.add_item(str(entry.title));assignment.set_item_metadata(assignment.item_count-1,entry.id)
 if latest.is_empty():label(content,"Freeze a submission in your learning portfolio first. Then return here to send it to your teacher.",17)
 else:
  label(content,"Latest frozen submission: "+str(latest.module)+" • "+str(latest.time),17)
  button(content,"Submit frozen work to teacher",func():call_api("portfolio",{"portfolio":S.load_data(),"source_id":latest.id,"assignment_id":str(assignment.get_item_metadata(assignment.selected))},"submit"))
 label(content,"RETURNED FEEDBACK",22)
 var feedback:Array=student_data.get("feedback",[])
 if feedback.is_empty():label(content,"No returned feedback yet. Draft grades stay private until your teacher returns them.",16)
 for item in feedback:
  var card=UI.card(content,str(item.module)+" • mark "+str(item.score),"Teacher feedback")
  label(card,str(item.feedback),17)
  for outcome in item.get("ratings",{}):label(card,str(outcome)+" • "+str(item.ratings[outcome].get("rating","Not assessed")),15)
 button(content,"Refresh assignments & feedback",func():call_api("student",null,"student"))
func sync_portfolio()->void:
 if busy or not account().loaded or account().school_role()!="student" or preload("res://scripts/profile_store.gd").testing():return
 var data=S.load_data();var digest=JSON.stringify(data).sha256_text()
 if synced_account==str(account().user.get("id","")) and digest==last_sync:return
 synced_account=str(account().user.get("id",""));last_sync=digest;call_api("portfolio",{"portfolio":data},"sync")
func completed(result:int,code:int,_headers:PackedStringArray,bytes:PackedByteArray)->void:
 busy=false;var d=JSON.parse_string(bytes.get_string_from_utf8())
 if result!=HTTPRequest.RESULT_SUCCESS or not d is Dictionary or code<200 or code>=300:
  if op=="sync":last_sync=""
  set_status(str(d.get("error","Could not connect. Your local work is retained.")) if d is Dictionary else "Could not connect. Your local work is retained.");return
 match op:
  "student":student_data=d;render_student();set_status("Your assignments and returned feedback are up to date.")
  "submit":set_status("Frozen work submitted. Your teacher can now review it in Manage Class Pro.")
  "sync":pass
func label(parent:Node,text:String,size:int)->Label:
 var l=Label.new();l.text=text;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",size);parent.add_child(l);return l
func button(parent:Node,text:String,action:Callable)->Button:
 var b=Button.new();b.text=text;b.custom_minimum_size.y=44;parent.add_child(b);b.pressed.connect(action);return b
func set_status(text:String)->void:
 if is_instance_valid(status):status.text=text
func close()->void:
 if is_instance_valid(panel):panel.queue_free()
 panel=null;content=null;status=null
 var l=account().legacy()
 if l!=null and l.game.menu=="class_pro":l.game.menu=return_menu

func _unhandled_input(event:InputEvent)->void:
 if is_instance_valid(panel) and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:close();get_viewport().set_input_as_handled()
