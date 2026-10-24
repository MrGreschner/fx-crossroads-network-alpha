extends CanvasLayer
const UI=preload("res://scripts/studio_ui.gd")
const A=preload("res://scripts/business_district/art.gd")
const C=preload("res://scripts/business_district/catalog.gd")
const Board=preload("res://scripts/business_academy/board.gd")
var actor_id=""
var game:Node
var account:Node
var root:Control
var body:VBoxContainer
var nav:HBoxContainer
var status:Label
var heading:Label
var request:HTTPRequest
var hidden_layers:Array=[]
var old_mode=Node.PROCESS_MODE_INHERIT
var old_process=true
var old_visible=true
var old_menu=""
var catalog:Dictionary={}
var pending_business_restart=""
var pending_resets:Array=[]
var student:Dictionary={}
var attempt:Dictionary={}
var definition:Dictionary={}
var work:Dictionary={"responses":{},"models":{},"sandbox":null,"evidence":[]}
var feedback:Array=[]
var code=""
var task_id=""
var tab="Brief"
var screen="home"
var busy=false
var operation=""
var dirty=false
var conflicted=false
var editing_clock=0.0
var cache_clock=0.0
var sent_hash=""
var synced_work:Dictionary={}
var sent_work:Dictionary={}
var pending_submit=false
var pending_enter=false
var cache:Dictionary={}
var nonce=""
var board:Control
var board_clock=0.0
var subject="All subjects"
var creator_open=false
var creator_mode=Node.PROCESS_MODE_INHERIT
func authorized()->bool:return account!=null and not account.token.is_empty() and str(account.user.get("role","")) in ["student","teacher"]
func teacher()->bool:return str(account.user.get("role",""))=="teacher"
func setup(owner:Node)->void:
 game=owner;account=get_tree().root.get_node("FXAccount");actor_id=str(account.user.get("id",""));layer=116;process_mode=Node.PROCESS_MODE_ALWAYS
 old_mode=game.process_mode;old_process=game.is_processing();old_visible=game.visible;old_menu=game.menu;game.menu="business_academy";game.process_mode=Node.PROCESS_MODE_DISABLED;game.hide()
 for child in game.find_children("*","CanvasLayer",true,false):
  if child!=self:hidden_layers.append({"node":child,"visible":child.visible});child.hide()
 root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(root)
 var background=ColorRect.new();background.color=Color("#122e35");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);background.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(background)
 var margin=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 for key in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+key,16)
 root.add_child(margin);var column=VBoxContainer.new();margin.add_child(column)
 var top=HBoxContainer.new();column.add_child(top);heading=label(top,"LEARNING ACADEMY",27);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button(top,"My modules",home);button(top,"Glossary",glossary);button(top,"Close",leave)
 nav=HBoxContainer.new();column.add_child(nav)
 var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;column.add_child(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll).form_controls=true
 body=VBoxContainer.new();body.add_theme_constant_override("separation",12);body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
 status=label(column,"",16);status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 request=HTTPRequest.new();request.timeout=25;request.body_size_limit=6000000;add_child(request);request.request_completed.connect(received)
 if not authorized():
  label(body,"Your classroom workspace",25);para(body,"Sign in with a student or teacher account. Lessons, assessed attempts and grading are checked by the classroom server. Your public businesses remain available separately.")
  button(body,"Cloud account • sign in",func():leave();account.open());return
 cache=read_cache();call_api("catalog",null,"catalog")
func label(parent:Node,text:String,size:int=18)->Label:
 var n=Label.new();n.text=text;n.add_theme_font_override("font",A.FONT);n.add_theme_font_size_override("font_size",size);n.add_theme_color_override("font_color",Color("#efe7d3"));parent.add_child(n);return n
func para(parent:Node,text:String,size:int=17)->Label:
 var n=label(parent,text,size);n.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;n.size_flags_horizontal=Control.SIZE_EXPAND_FILL;return n
func button(parent:Node,text:String,action:Callable)->Button:
 var n=Button.new();n.text=text;n.custom_minimum_size.y=40;n.add_theme_font_override("font",A.FONT);n.add_theme_font_size_override("font_size",16);n.pressed.connect(action);parent.add_child(n);return n
func clear()->void:
 board=null
 for parent in [body,nav]:
  for n in parent.get_children():parent.remove_child(n);n.queue_free()
func message(text:String)->void:status.text=text
func call_api(path:String,payload:Variant=null,op:String="")->void:
 if busy:return
 if not authorized():message("Sign in again to continue. Your local draft is retained.");return
 if preload("res://scripts/profile_store.gd").testing() and payload!=null:message("Exit Game Dev / Playtest before changing assessed work.");return
 busy=true;operation=op if not op.is_empty() else path
 var result=request.request(account.endpoint+"/education/business/"+path,PackedStringArray(["Content-Type: application/json","Authorization: Bearer "+account.token]),HTTPClient.METHOD_GET if payload==null else HTTPClient.METHOD_POST,"" if payload==null else JSON.stringify(payload))
 if result!=OK:busy=false;message("Connection unavailable. Your on-device draft is retained.")
func received(result:int,http:int,_headers:PackedStringArray,bytes:PackedByteArray)->void:
 busy=false;var parser=JSON.new();var parsed=parser.parse(bytes.get_string_from_utf8());var data=parser.data if parsed==OK else {}
 if result!=HTTPRequest.RESULT_SUCCESS or not data is Dictionary or http<200 or http>=300:
  if operation=="save":pending_submit=false
  if http==409 and operation=="save":conflicted=true
  if operation=="save" and http in [403,409] and is_instance_valid(game) and is_instance_valid(game.business_district) and game.business_district.classroom:
   game.business_district.pause_for_access("Classroom access or a newer district save needs attention. Trading paused. Return to your module; your device draft is retained.")
  message(str(data.get("error","Classroom connection unavailable. Your on-device draft is retained.")) if data is Dictionary else "Classroom connection unavailable. Your on-device draft is retained.");return
 match operation:
  "catalog":catalog=data.catalog;home()
  "student":student=data;render_home()
  "venture_access":
   attempt.venture_policy=data.venture_access
   pending_resets=data.get("restart_requests",[]).map(func(r):return r.business)
   if data.get("district")!=null:work.sandbox=data.district.duplicate(true)
   work.district_revision=int(data.get("district_revision",0));enter_simulation()
  "start":call_api("attempt?id="+str(data.id),null,"attempt")
  "attempt":
   attempt=data.attempt;definition=preload("res://scripts/assessment_scope.gd").definition(attempt.get("assessment_definition",attempt.definition));code=attempt.module;work=attempt.work.duplicate(true);synced_work=work.duplicate(true);feedback=data.feedback;dirty=false;conflicted=false;nonce=""
   if cache.has(attempt.id) and cache[attempt.id].get("dirty",false):
    var local=cache[attempt.id]
    if int(local.get("revision",-1))==int(attempt.revision):work=local.work.duplicate(true);dirty=true;message("Recovered your unsynced on-device draft.")
    else:conflicted=true;message("A newer server draft exists. Download your retained device draft before choosing Use server version.")
   if not work.has("evidence"):work.evidence=[]
   if not work.has("artifacts"):work.artifacts=[]
   task_id=definition.tasks[0].id;screen="module";tab="Brief";render_module()
  "save":
   if data.has("district_revision"):
    work.district_revision=int(data.district_revision);sent_work.district_revision=int(data.district_revision);sent_hash=JSON.stringify(sent_work).sha256_text()
   synced_work=sent_work.duplicate(true);attempt.revision=int(data.revision);dirty=JSON.stringify(work).sha256_text()!=sent_hash;write_cache();message("Draft synced • revision "+str(attempt.revision))
   if not pending_business_restart.is_empty() and not dirty:var key=pending_business_restart;pending_business_restart="";request_business_restart(key)
   elif pending_submit and not dirty:pending_submit=false;submit_work()
   elif pending_enter and not dirty:pending_enter=false;open_simulation()
  "restart_requested":
   message("Restart request sent. Your teacher can review your business statistics in Manage Class Pro. This business is paused until reviewed.");call_api("student",null,"student")
  "submit":
   attempt.status="submitted";attempt.latest_submission=data.submission;dirty=false;nonce="";write_cache();render_module();message("Frozen submission sent. Your teacher can return feedback or complete this module.")
func home()->void:
 if dirty:write_cache()
 if busy:message("Please wait for the current request.");return
 screen="home";clear();heading.text="LEARNING ACADEMY • "+("TEACHER PREVIEW" if teacher() else "MY MODULES")
 if catalog.is_empty():call_api("catalog",null,"catalog");return
 if teacher():render_home()
 else:call_api("student",null,"student")
func module_by_code(value:String)->Dictionary:
 for m in catalog.get("modules",[]):
  if m.code==value:return m
 return {}
func render_home()->void:
 clear()
 para(body,"Design • Graphics & Animation • Computer Science • Business • each module is submitted, revised and completed independently. School credit reporting remains with your teacher.")
 if teacher():
  UI.accent(button(body,"Manage Class Pro (opens browser) • assign modules, review work & record completion",func():get_tree().root.get_node("FXClassPro").launch("Learning Academy")))
  para(body,"This is a lesson and scenario preview. It never creates a student attempt or grants a grade.")
 else:
  var active_count=0
  for b in student.get("attempts",[]):
   if b.status in ["active","submitted","revision"] and b.get("link_active",true) and not b.get("assignment_archived",false):active_count+=1
  var p=student.get("policy",{"slots":1,"placement":10})
  label(body,"%d / %d active slots • starting level %d" % [active_count,int(p.slots),int(p.placement)],21)
  para(body,"Submitted and revision work still uses a slot. A teacher can allow a second module or pause unfinished work. Completed modules remain recorded.")
  if student.get("assignments",[]).is_empty():para(body,"No modules have been assigned yet. Your teacher can assign one to your class or whole student bin in Manage Class Pro. Only modules assigned by your teacher appear here. You can still create freely in the public Studio.")
 for restart in student.get("restart_requests",[]):para(body,"Business restart • "+str(C.spec(restart.business).get("name",restart.business))+" • "+str(restart.status).to_upper()+". Reopen the classroom district to load the latest state.",16)
 var subjects=HBoxContainer.new();body.add_child(subjects)
 for name in ["All subjects","Business","Design","Graphics & Animation","Computer Science"]:
  var value:String=name;var b=button(subjects,name,func():subject=value;render_home())
  if subject==name:UI.accent(b)
 para(body,"Choose an assigned module below. One module has several outcome parts; submit the parts together for teacher review. You can save and submit partial progress for feedback.",16)
 for level in [10,20,30]:
  label(body,"LEVEL "+str(level),24)
  for m in catalog.modules:
   if (not teacher() and not student.get("assignments",[]).any(func(a):return a.module==m.code)) or int(m.level)!=level or (subject!="All subjects" and m.get("subject","Business")!=subject):continue
   var card=UI.card(body,m.code+" • "+m.name,str(m.get("subject","Business"))+" • "+("BUSINESS CORE" if m.core else "AVAILABLE MODULE")+" • "+m.scenario)
   var row=HBoxContainer.new();card.add_child(row)
   var picture=TextureRect.new();picture.texture=A.actor(posmod(m.code.hash(),8),0);picture.custom_minimum_size=Vector2(72,92);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(picture)
   var info=para(row,m.brief);info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   if not m.get("requires",[]).is_empty():para(card,"Prerequisite: "+", ".join(m.requires)+" • teacher can confirm equivalent prior learning",15)
   var code_value:String=m.code
   if teacher():button(card,"Teacher lesson preview",func():preview(code_value))
   if teacher():continue
   for done in student.get("completions",[]):
    if done.module==m.code:para(card,("COMPLETED" if done.status=="completed" else "REOPENED FOR CORRECTION")+" • "+str(done.score)+"% • "+str(done.completed_at),16)
   for b in student.get("attempts",[]):
    if b.module==m.code:
     var id:String=b.id;button(card,b.status.to_upper()+" • "+b.title,func():load_attempt(id))
   for assignment in student.get("assignments",[]):
    if assignment.module!=m.code:continue
    var id:String=assignment.id;button(card,"Start / open assigned module • "+assignment.title,func():call_api("start",{"assignment_id":id},"start"))
func preview(value:String)->void:
 if busy or not teacher():return
 if dirty:write_cache()
 definition=preload("res://scripts/assessment_scope.gd").definition(module_by_code(value));code=value;attempt={};feedback=[];work={"responses":{},"models":{},"sandbox":null,"evidence":[]};dirty=false;conflicted=false;task_id=definition.tasks[0].id;screen="module";tab="Brief";render_module()
func load_attempt(id:String)->void:
 if dirty:write_cache()
 call_api("attempt?id="+id,null,"attempt")
func editable()->bool:return attempt.is_empty() or (str(attempt.get("status","")) in ["active","revision"] and not attempt.get("assignment_archived",false) and attempt.get("link_active",true) and not conflicted)
func task()->Dictionary:
 for t in definition.tasks:
  if t.id==task_id:return t
 return definition.tasks[0]
func render_module()->void:
 clear();heading.text=code+" • "+definition.name
 var tabs=ScrollContainer.new();tabs.custom_minimum_size.y=45;tabs.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;nav.add_child(tabs);tabs.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var choices=HBoxContainer.new();tabs.add_child(choices)
 for name in ["Brief","Learn","Studio","My evidence","Feedback"]:
  var selected:String=name;var b=button(choices,("● " if tab==name else "")+name,func():tab=selected;render_module())
  if tab==name:UI.accent(b)
 para(body,"UNGRADED PRACTICE • separate from public progress" if attempt.is_empty() else "CLASSROOM ATTEMPT • "+str(attempt.status).to_upper()+" • revision "+str(attempt.revision),16)
 if conflicted:
  para(body,"Your retained device draft conflicts with a newer server revision. Download it before discarding or comparing it.")
  button(body,"Download retained device draft",func():download(cache.get(attempt.id,{"work":work})))
  button(body,"Use server version • keep a downloaded copy first",func():confirm("Use the server version?","The retained device copy will be replaced. Download it first if you need it.",func():cache.erase(attempt.id);dirty=false;write_cache();load_attempt(attempt.id)))
 if not attempt.is_empty() and not attempt.get("link_active",true):para(body,"Your work is retained, but its previous teacher link is inactive. You can read or download it; ask your current teacher about a new assignment.")
 var t=task()
 var creative=definition.get("subject","Business")!="Business"
 para(body,str(definition.get("submission_structure","One module submission; complete each outcome part below.")),17)
 if tab in ["Learn","My evidence"]:
  label(body,"CHOOSE AN OUTCOME PART • these are parts of this module",18)
  var parts=HFlowContainer.new();body.add_child(parts)
  for index in definition.tasks.size():
   var each=definition.tasks[index];var target:String=each.id;var part_button=button(parts,"Part %d/%d • %s%s" % [index+1,definition.tasks.size(),each.title," ✓ draft" if not str(work.responses.get(each.id,"")).strip_edges().is_empty() else ""],func():task_id=target;render_module())
   if target==task_id:UI.accent(part_button)
 if tab=="Brief":
  visual();para(body,definition.brief,21)
  if definition.has("workflow"):workflow_strip()
  label(body,"What you will demonstrate",23)
  for o in definition.outcomes:para(body,o.id+" • "+o.title+"\nEvidence: "+o.evidence)
  para(body,"Work through the outcome parts of this module. Use the relevant creation tools or classroom business, then explain your reasoning where it adds evidence. Record sources and limitations. Class discussions, presentations and observed role-play can provide evidence when your teacher confirms it. Profit and play time do not award marks.")
  button(body,"Start learning",func():tab="Learn";render_module())
 elif tab=="Learn":
  visual();label(body,t.title,25);para(body,t.lesson,19);var example=UI.card(body,"Worked example",t.worked_example);para(example,"Think about it: "+t.check)
  para(body,"Try: "+t.activity);sources();button(body,"Open the visual studio",func():tab="Studio";render_module())
 elif tab=="Studio":
  if creative:creator_controls()
  else:
   var actions=HBoxContainer.new();body.add_child(actions)
   var play_button=button(actions,"▶ Enter classroom business",open_simulation);UI.accent(play_button);play_button.disabled=not editable()
   button(actions,"Attach image of this board",capture_image).disabled=not editable();button(actions,"Record evidence",func():tab="My evidence";render_module())
   if definition.tool in ["opportunity","comparison"]:opportunity_controls()
   else:visual();studio_controls()
   para(body,"This is a teaching model, not a market prediction. Other school subjects and adventure resources are optional.")
 elif tab=="My evidence":
  label(body,t.title,24);para(body,"Alberta main outcome "+", ".join(t.outcomes),16)
  var guide=t.get("guidance",{})
  if not guide.is_empty():
   UI.card(body,"1 • What to do",guide.steps)
   UI.card(body,"2 • Where to find the tools/evidence",guide.where)
   UI.card(body,"3 • What to hand in",guide.deliverable)
   UI.card(body,"Example • a model of detail, not an answer to copy",guide.example)
  else:para(body,t.prompt)
  if creative:artifact_picker()
  else:button(body,"Open classroom to collect evidence",open_simulation).disabled=not editable();button(body,"Go to Studio board",func():tab="Studio";render_module())
  var answer=TextEdit.new();answer.custom_minimum_size.y=220;answer.text=work.responses.get(t.id,"");answer.editable=editable();answer.placeholder_text=str(t.get("guidance",{}).get("response_starter","Write your response to the task above."));body.add_child(answer)
  answer.text_changed.connect(func():work.responses[t.id]=answer.text.left(8000);mark_dirty())
  if work.sandbox!=null:
   para(body,"Saved classroom business • %d completed trading periods • %d visitors" % [work.sandbox.periods,work.sandbox.visitors])
   for id in work.sandbox.businesses:
    var b=work.sandbox.businesses[id]
    if not b.last_result.is_empty():para(body,b.name+" • %d sold • operating profit %.2f • %d lost customers" % [b.last_result.sold,b.last_result.profit,b.last_result.lost])
  for n in work.get("artifacts",[]).size():
   var artifact=work.artifacts[n];var box=UI.card(body,str(artifact.title),str(artifact.kind)+" • frozen editable source")
   show_artifact(box,artifact)
   if editable():
    var index:int=n;button(box,"Remove this copy",func():work.artifacts.remove_at(index);mark_dirty();render_module())
  for image_index in work.get("evidence",[]).size():
   var image=work.evidence[image_index]
   para(body,"Attached image %d • %s" % [image_index+1,image.title],16)
   var im=Image.new()
   if im.load_png_from_buffer(Marshalls.base64_to_raw(image.png))==OK:
    var picture=TextureRect.new();picture.texture=ImageTexture.create_from_image(im);picture.custom_minimum_size=Vector2(240,160);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;body.add_child(picture)
   if editable():
    var index:int=image_index;button(body,"Remove this screenshot",func():work.evidence.remove_at(index);mark_dirty();render_module())
  var actions=HBoxContainer.new();body.add_child(actions);button(actions,"Save draft now",save_draft).disabled=attempt.is_empty() or not editable();button(actions,"Download my work",func():download({"module":definition,"attempt":attempt.get("id","practice"),"work":work}))
  if not attempt.is_empty():button(actions,"Submit module for review • all parts",submit_work).disabled=not editable()
  para(body,"Submissions freeze the current answers, visual models, screenshots and business records. Later revisions keep earlier submissions intact. Partial work may be submitted for feedback; your teacher decides whether each main outcome is demonstrated.")
 elif tab=="Feedback":
  if feedback.is_empty():para(body,"No returned feedback yet. Draft grades are private. Your teacher can return comments for revision or record completion after assessing every main outcome.")
  for f in feedback:
   var card=UI.card(body,"Returned review • "+("not yet graded" if f.get("score")==null else str(f.score)+"%"),str(f.get("feedback","")))
   for id in f.get("ratings",{}):
    var rating=f.ratings[id];para(card,id+" • "+str(rating.get("rating","Not assessed"))+"\n"+str(rating.get("feedback",""))+"\nEvidence / observation: "+str(rating.get("evidence","")))
  if not attempt.is_empty():button(body,"Refresh feedback",func():load_attempt(attempt.id))
func sources()->void:
 for s in definition.get("sources",[]):
  var url:String=s.url;button(body,s.title+" (opens browser)",func():OS.shell_open(url));para(body,s.use,15)
func visual()->void:
 if definition.tool in ["opportunity","comparison"]:
  para(body,"INVESTIGATE  >  COMPARE  >  CONFIRM YOUR PLAN",22);return
 if definition.get("subject","Business")!="Business":
  creator_banner();return
 board=Board.new();board.custom_minimum_size.y=clampf((get_viewport().get_visible_rect().size.x-32)*300/860,150,420);body.add_child(board);board.set_data(definition.tool,work.models)
func model()->Dictionary:
 if not work.models.has(definition.tool):work.models[definition.tool]=Board.defaults(definition.tool)
 var m=work.models[definition.tool]
 if definition.tool in ["opportunity","comparison"] and m.get("confirmed",0)==1 and not m.has("planned_id"):
  var previous=["kitchen","workshop","clothier","fishery","garden","mine","store","courier","rental","blank1","blank2","blank3"]
  var index=int(m.get("planned",0));m.planned_id=previous[clampi(index,0,11)] if str(attempt.get("edition","academy-4"))!="academy-5" else C.ventures()[clampi(index,0,14)].id
  m.original_id=previous[clampi(int(m.get("original_planned",index)),0,11)]
 return m
func choice(parent:Node,title:String,key:String,options:Array)->void:
 var box=UI.card(parent,title,"");box.get_parent().size_flags_horizontal=Control.SIZE_EXPAND_FILL;box.get_parent().custom_minimum_size.x=360 if get_viewport().get_visible_rect().size.x>900 else 260;var pick=OptionButton.new();pick.custom_minimum_size.y=40;box.add_child(pick)
 for option in options:pick.add_item(str(option))
 pick.selected=int(model().get(key,0));pick.disabled=not editable();pick.item_selected.connect(func(index:int):
  model()[key]=index
  if key=="budget_index":model().budget=[0,10,25][index]
  mark_dirty();redraw_board())
func amount(parent:Node,title:String,key:String,low:float,high:float,step:float=1)->void:
 var row=HBoxContainer.new();row.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.custom_minimum_size.x=360 if get_viewport().get_visible_rect().size.x>900 else 260;parent.add_child(row);var l=para(row,title);l.custom_minimum_size.x=200 if get_viewport().get_visible_rect().size.x>900 else 120;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var input=SpinBox.new();input.min_value=low;input.max_value=high;input.step=step;input.value=float(model().get(key,low));input.custom_minimum_size.x=140;input.editable=editable();row.add_child(input);input.value_changed.connect(func(value:float):model()[key]=value;mark_dirty();redraw_board())
func redraw_board()->void:
 if is_instance_valid(board):board.set_data(definition.tool,work.models)
func studio_controls()->void:
 var m=model();var grid=GridContainer.new();grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;grid.columns=2 if get_viewport().get_visible_rect().size.x>900 else 1;grid.add_theme_constant_override("h_separation",18);grid.add_theme_constant_override("v_separation",10);body.add_child(grid)
 match str(definition.tool):
  "finance":
   choice(grid,"Financing arrangement","funding",["Loan","Equity investor","Own savings only"]);choice(grid,"Customer cash collection","delay",["Immediate payment","One month later"])
   for data in [["Funding amount","principal",0,5000],["Annual loan rate (%)","rate",0,30],["Loan term (months)","months",1,36],["Selling price","price",1,100],["Variable cost per unit","unit_cost",0,100],["Monthly fixed costs","fixed",0,2000],["Units per month","units",0,200],["Starting own cash","start",0,5000],["Equity share given (%)","share",1,90]]:amount(grid,data[0],data[1],data[2],data[3])
   para(body,"The Funding Desk is a separate planning case; it does not borrow money in your classroom business. The district has a simpler 90/100 loan mechanic. This chart uses an amortizing monthly payment and annual rate/12. Operating profit excludes financing, tax and depreciation in this simplified case. A delayed first collection creates receivables. Equity control shown is the retained ownership percentage; investor returns are not modelled.")
  "distribution":
   choice(grid,"Distribution channel","channel",["Maker  >  customer","Maker  >  retailer  >  customer","Maker  >  wholesaler  >  retailer  >  customer"]);choice(grid,"Transport","transport",["Road","Rail","Water","Air"]);amount(grid,"Journey distance (model km)","distance",100,2000,100);choice(grid,"Product constraints","product",["Durable manufactured tools","Perishable produce"])
   para(body,"Compare accessibility and reliability in your explanation as well as the model cost/time. The product constraint is part of your plan; it does not make an unsuitable route safe. Research real transport and community retailers for the assigned task.")
  "marketing":
   choice(grid,"Target group","target",["Traveller","Town resident","Collector"]);choice(grid,"Promotion channel (plan)","channel",["Market poster","Local message","Personal service"]);amount(grid,"Selling price","price",1,80,.5);choice(grid,"Floor layout","layout",["Compact","Open aisle","Display led"])
   choice(grid,"Promotion budget selection","budget_index",["0","10","25"])
   m.budget=[0,10,25][int(m.get("budget_index",1))]
  "operations":
   choice(grid,"Organizational structure","structure",["Functional","Geographical","Matrix / project team"]);choice(grid,"Management case","incident",["Late delivery","Cash collected late","Staff conflict","Faulty product"]);choice(grid,"Response to investigate","response",["Listen, gather evidence and clarify","Compare options and assign responsibility","Communicate, act and review"])
   amount(grid,"Employees in sample payroll","employees",1,8);amount(grid,"Hours per employee","hours",1,40);amount(grid,"Fictional hourly rate","wage",1,40)
   para(body,"Sample gross payroll = employees × hours × rate. Explain deductions and employer obligations using current sources where assigned; the game does not calculate real payroll deductions.")
  "expansion":
   choice(grid,"Expansion option","strategy",["Improve / maintain current size","Add a supply-chain stage","Add another offering"]);amount(grid,"Proposed investment","investment",0,2000);amount(grid,"Forecast period sales","sales",0,3000);amount(grid,"Forecast period costs","costs",0,3000)
  "service":
   choice(grid,"Customer case","customer",["New buyer needs product advice","Customer reports a faulty item","Buyer and user have different needs"]);choice(grid,"Service step to demonstrate","response",["Listen and clarify","Check receipt and policy","Explain options and record"]);amount(grid,"Receipt quantity","quantity",1,10);amount(grid,"Unit price","price",1,100,.5)
   para(body,"Role-play the interaction, follow the supplied or teacher-approved policy, and ask the teacher to record observed evidence. The case choices are not automatic marks.")
  "agriculture":
   choice(grid,"Teaching market structure","system",["Open market","Quota-limited case"]);amount(grid,"Available harvest","supply",1,150);amount(grid,"Demand units","demand",1,150);amount(grid,"Quota in the closed case","quota",1,150)
   para(body,"Model price = 10 × demand / available supply, clamped to 1–30. This deliberately simplified relationship is not a real pricing rule, a prediction, or a description of current Canadian regulation.")
  "planning":
   choice(grid,"Milestone to review","milestone",["Goal","Resources","Opening","Review"]);amount(grid,"Risk likelihood (1–5)","likelihood",1,5);amount(grid,"Risk impact (1–5)","impact",1,5);choice(grid,"Response focus","response",["Prevent the event","Reduce its impact","Prepare a contingency"])
  _:para(body,"Explore the district, inspect opportunities and confirm your venture plan above.")
func mark_dirty()->void:
 if not editable():return
 dirty=true;editing_clock=0;cache_clock=0
func save_draft()->void:
 if attempt.is_empty():message("Practice work stays in this preview; start an assigned module to save assessed work.");return
 if not editable() or busy:return
 write_cache();sent_work=work.duplicate(true);sent_hash=JSON.stringify(sent_work).sha256_text()
 var patch={}
 for key in ["responses","models","sandbox","evidence","artifacts"]:
  if JSON.stringify(work.get(key))!=JSON.stringify(synced_work.get(key)):patch[key]=work.get(key)
 if patch.is_empty():
  dirty=false;write_cache()
  if pending_submit:pending_submit=false;call_deferred("submit_work")
  elif pending_enter:pending_enter=false;call_deferred("open_simulation")
  return
 call_api("save",{"id":attempt.id,"revision":int(attempt.revision),"patch":patch,"district_revision":int(work.get("district_revision",0))},"save")
func submit_work()->void:
 if busy:return
 if dirty:pending_submit=true;save_draft();message("Saving your latest draft before preparing the submission…");return
 confirm("Submit frozen work?","This sends the current answers, models, screenshots and classroom business to your teacher. Earlier submissions stay intact. You can revise after your teacher returns it.",func():
  if nonce.is_empty():nonce=Crypto.new().generate_random_bytes(16).hex_encode()
  call_api("submit",{"id":attempt.id,"revision":int(attempt.revision),"nonce":nonce},"submit"))
func confirm(title:String,text:String,action:Callable)->void:
 var dialog=ConfirmationDialog.new();dialog.title=title;dialog.dialog_text=text;add_child(dialog);dialog.confirmed.connect(action);dialog.confirmed.connect(dialog.queue_free);dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(620,210))
func open_simulation()->void:
 if not editable():return
 if dirty and not attempt.is_empty():pending_enter=true;save_draft();return
 if not attempt.is_empty():call_api("access?id="+str(attempt.id),null,"venture_access");return
 enter_simulation()
func enter_simulation()->void:
 var state=C.fresh() if work.sandbox==null else work.sandbox.duplicate(true)
 if state.businesses.is_empty() and definition.tool in ["opportunity","comparison"]:
  var m=model()
  if m.get("confirmed",0)==1:
   var selected_id=str(m.get("planned_id","kitchen"))
   if not C.spec(selected_id).is_empty() and not C.spec(selected_id).get("archived",false):state.selected=selected_id
 root.hide();var view=preload("res://scripts/business_district/view.gd").new();game.business_district=view;game.add_child(view);view.setup(game,{"classroom":true,"state":state,"academy":self,"access":attempt.get("venture_policy",["kitchen"]),"pending_resets":pending_resets})
func capture_simulation(state:Dictionary)->void:
 if not editable() or not C.valid(state):return
 work.sandbox=state.duplicate(true);mark_dirty();write_cache()
func return_from_scene()->void:root.show();if_ready_render()
func if_ready_render()->void:
 if screen=="module":render_module()
func capture_image()->void:
 if not editable():return
 if work.get("evidence",[]).size()>=12:message("Twelve screenshots are attached. Remove an unnecessary image before adding another.");return
 await RenderingServer.frame_post_draw
 var image=get_viewport().get_texture().get_image()
 if image==null:return
 var factor=minf(1,minf(960.0/image.get_width(),720.0/image.get_height()));image.resize(maxi(1,int(image.get_width()*factor)),maxi(1,int(image.get_height()*factor)),Image.INTERPOLATE_LANCZOS)
 var bytes=image.save_png_to_buffer()
 if bytes.size()>650000:message("This image is too large. Use a simpler view.");return
 if JSON.stringify(work).length()+ceili(bytes.size()*4.0/3)>5000000:message("Your evidence is near the upload limit. Remove unnecessary images or download a copy first.");return
 if not work.has("evidence"):work.evidence=[]
 work.evidence.append({"title":code+" • "+task_id+" • "+tab,"png":Marshalls.raw_to_base64(bytes)});mark_dirty();write_cache();message("Screenshot attached to your current module draft.")
func cache_path()->String:
 var id=actor_id;var regex=RegEx.new();regex.compile("^[a-f0-9]{32}$")
 return "user://fx_business_draft_"+id+".json" if regex.search(id)!=null else ""
func read_cache()->Dictionary:
 var path=cache_path()
 if path.is_empty():return {}
 return preload("res://scripts/profile_store.gd").read(path,func(value:Dictionary):return JSON.stringify(value).length()<16000000)
func write_cache()->void:
 if attempt.is_empty() or cache_path().is_empty():return
 if dirty:cache[attempt.id]={"revision":int(attempt.revision),"dirty":dirty,"work":work.duplicate(true)}
 else:cache.erase(attempt.id)
 while cache.size()>4:
  var key=cache.keys()[0]
  if key==attempt.id:key=cache.keys()[1]
  cache.erase(key)
 var error=preload("res://scripts/profile_store.gd").write(cache_path(),cache)
 if error!=OK:message("Could not save this device draft. Keep this screen open, sync or download your work.")

func download(value:Dictionary)->void:game.hero_workshop.write_download(JSON.stringify(value,"  "),"crossroads-business-"+code+".json")
func glossary()->void:
 if catalog.is_empty():return
 clear();screen="glossary";heading.text="BUSINESS GLOSSARY"
 for term in catalog.terms:
  var card=UI.card(body,term,str(catalog.terms[term]));card.add_theme_constant_override("separation",6)
func _process(dt:float)->void:
 if creator_open and not game.hero_workshop.active:
  creator_open=false;game.hero_workshop.process_mode=creator_mode;game.hero_workshop.hide();root.show();render_module()
 if account==null:return
 if str(account.user.get("id",""))!=actor_id:leave();return
 if not authorized() and not catalog.is_empty():write_cache();leave();return
 if dirty and not attempt.is_empty():
  editing_clock+=dt;cache_clock+=dt
  if cache_clock>1:cache_clock=0;write_cache()
  if editing_clock>2 and not busy and editable():editing_clock=0;save_draft()
func leave()->void:
 if is_instance_valid(game.business_district) and game.business_district.classroom and game.business_district.academy==self:game.business_district.leave()
 write_cache();game.process_mode=old_mode;game.set_process(old_process);game.visible=old_visible;game.menu=old_menu
 for entry in hidden_layers:
  if is_instance_valid(entry.node):entry.node.visible=entry.visible
 queue_free()
func _input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE and root.visible:leave();get_viewport().set_input_as_handled()

func creator_banner()->void:
 var row=HBoxContainer.new();body.add_child(row)
 for value in work.get("artifacts",[]).slice(0,3):show_artifact(row,value)
 if work.get("artifacts",[]).is_empty():
  var picture=TextureRect.new();picture.texture=preload("res://assets/ram_idle.png");picture.custom_minimum_size=Vector2(100,120);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(picture)
  para(row,"CREATE  >  TEST  >  REVISE  >  SHOW
Your artwork, animation, realm or code is the main evidence. Use the short response to explain what the work cannot show on its own.",21)
func creator_controls()->void:
 creator_banner()
 var row=HFlowContainer.new();body.add_child(row)
 if definition.tool=="programming":
  UI.accent(button(row,"▶ Code Playground • run & test",open_programming))
  para(body,"Write source and predict outputs. The interpreter executes the instructions, the visual stage shows spell selections, and saved test cases rerun against the source when attached. Passing tests is evidence, not an automatic grade.")
 else:
  UI.accent(button(row,"▶ Open public Studio",launch_creator))
  button(row,"Open relevant creation tool",func():launch_creator(str(definition.get("creator","hero"))))
  button(row,"Vector Studio • editable SVG + PNG",open_vector)
  para(body,"The same creation tools are open to public players. Save your hero, spell, object or realm in the Studio, return here, then attach a frozen copy. Sources and layers remain available for review. Use external tools where the assignment requires an unsupported workflow.")
 button(row,"Record evidence",func():tab="My evidence";render_module())
 para(body,"One practical project can support several main outcomes. Smaller curriculum examples are teaching suggestions, not a mandatory task checklist. Teachers can confirm the course-specific demonstrations and presentations. General routines, competencies and pathway discussions are handled in class outside this program.")
func launch_creator(kind:String="")->void:
 if not editable():return
 write_cache();root.hide();creator_open=true;var studio=game.hero_workshop;creator_mode=studio.process_mode;studio.process_mode=Node.PROCESS_MODE_ALWAYS;studio.show();studio.open()
 if kind=="realm":studio.open_world_lab(true)
 elif kind=="object":studio.open_world_lab(false)
 elif kind=="animation":studio.open_lab()
func open_programming()->void:
 root.hide();var lab=preload("res://scripts/structured_lab.gd").new();add_child(lab);lab.setup(game,func(value:Dictionary):attach_artifact("structured_program",value,str(value.name)),Callable(),definition.code=="CSE1110");lab.tree_exited.connect(func():root.show();render_module())
func attach_artifact(kind:String,value:Dictionary,title:String)->void:
 if not editable():return
 var check={"kind":kind,"value":value,"title":title.left(100),"time":"","origin":"Studio","hash":preload("res://scripts/learning_store.gd").fingerprint(value)}
 if not preload("res://scripts/learning_store.gd").valid_artifact(check):message("This source is not ready. Check it in its creation tool first.");return
 if not work.has("artifacts"):work.artifacts=[]
 if work.artifacts.size()>=6:message("Six sources attached. Remove an old copy before adding another.");return
 var next=work.artifacts.duplicate(true);next.append({"kind":kind,"title":title.left(150),"value":value.duplicate(true)})
 if JSON.stringify(next).length()>2100000:message("These sources are too large together. Attach fewer source copies in this submission.");return
 work.artifacts=next;mark_dirty();message("Frozen source attached. Later Studio edits do not alter this copy.")
func artifact_picker()->void:
 var box=UI.card(body,"ATTACH PRACTICAL WORK","Choose a saved Studio source. Multiple outcomes may reference the same work; you do not need to attach it repeatedly.")
 var lib=preload("res://scripts/studio_library.gd").load_data();var options=[]
 for pair in [["heroes","hero"],["abilities","ability"],["objects","object"],["realms","realm"],["enemies","enemy"],["behaviors","behavior"]]:
  for id in lib[pair[0]]:
   var value:Dictionary=lib[pair[0]][id];options.append({"kind":pair[1],"value":value,"title":str(value.get("name",value.get("hero",{}).get("name",id)))})
 var program=preload("res://scripts/profile_store.gd").read(preload("res://scripts/structured_lab.gd").PATH,preload("res://scripts/structured_program.gd").valid)
 if not program.is_empty():options.append({"kind":"structured_program","value":program,"title":program.name})
 var vector=preload("res://scripts/profile_store.gd").read(preload("res://scripts/vector_studio.gd").PATH,preload("res://scripts/vector_studio.gd").valid)
 if not vector.is_empty():options.append({"kind":"graphic","value":vector,"title":vector.settings.title})
 var old=preload("res://scripts/learning_store.gd").load_data()
 if not old.work.is_empty() or not old.submissions.is_empty():
  button(box,"Download earlier portfolio • notes, sources & reviews",func():game.hero_workshop.write_download(JSON.stringify(old,"  "),"crossroads-earlier-portfolio.json"))
  var entries=old.work.get(code,{}).get("entries",[])
  if not entries.is_empty():
   var archive=VBoxContainer.new();archive.visible=false;box.add_child(archive)
   button(box,"Show / hide earlier notes for this module",func():archive.visible=not archive.visible)
   para(archive,"Earlier device notes are preserved below. They have not been graded or automatically copied into this new attempt.")
   for entry in entries:para(archive,str(entry.stage)+" • "+str(entry.time)+"\n"+str(entry.text),15)
 for artifact in old.artifacts.values():
  if artifact.kind not in ["market","business","quiz"]:options.append({"kind":artifact.kind,"value":artifact.value,"title":"Earlier portfolio • "+artifact.title})
 var pick=OptionButton.new();pick.custom_minimum_size.y=44;box.add_child(pick)
 for item in options:pick.add_item(str(item.kind)+" • "+item.title)
 var b=button(box,"Attach selected source",func():if not options.is_empty():var item=options[pick.selected];attach_artifact(item.kind,item.value,item.title);render_module());b.disabled=options.is_empty() or not editable()
 if definition.tool=="programming":button(box,"Create / revise a program",open_programming)
func show_artifact(parent:Node,artifact:Dictionary)->void:
 var value:Dictionary=artifact.get("value",{});var art:Dictionary=value.get("hero",{}).get("art",{})
 if art.is_empty():
  for key in ["image","png"]:
   if value.get(key) is String and value[key].begins_with("iVBOR"):art={"image":value[key]};break
 for data in art.values().slice(0,2):
  var im=Image.new()
  if im.load_png_from_buffer(Marshalls.base64_to_raw(str(data)))==OK:
   var pic=TextureRect.new();pic.texture=ImageTexture.create_from_image(im);pic.custom_minimum_size=Vector2(160,120);pic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;pic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;parent.add_child(pic)
 if value.get("code") is String:
  para(parent,str(value.code).left(500),15)
  for row in value.get("cases",[]):para(parent,"Predicted "+JSON.stringify(row.expected)+"  >  "+JSON.stringify(row.get("actual",[]))+" • "+str(row.get("actual_error","")),15)
 elif artifact.kind=="realm":para(parent,"Editable realm • "+str(value.keys().size())+" source sections • test and critique evidence can reference this source.")
 else:para(parent,"Editable "+str(artifact.kind)+" source retained • "+str(JSON.stringify(value).length())+" characters. Your teacher can download the frozen source.",15)

func open_vector()->void:
 root.hide();var vector=preload("res://scripts/vector_studio.gd").new();add_child(vector);vector.setup(game,func(value:Dictionary):attach_artifact("graphic",value,str(value.settings.title)));vector.tree_exited.connect(func():root.show();render_module())

func workflow_strip()->void:
 var steps:Array=definition.get("workflow",[])
 if steps.is_empty():return
 label(body,"YOUR PROJECT ROUTE",21)
 var route=HFlowContainer.new();route.name="CourseProjectRoute";route.add_theme_constant_override("h_separation",10);route.add_theme_constant_override("v_separation",10);body.add_child(route)
 for n in steps.size():
  var step:Dictionary=steps[n];var frame=PanelContainer.new();frame.custom_minimum_size=Vector2(230,130);frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL;frame.add_theme_stylebox_override("panel",UI.box("#163c47" if n%2==0 else "#243c50","#76b9b3",9,12));route.add_child(frame)
  var col=VBoxContainer.new();frame.add_child(col);label(col,str(n+1)+"  "+str(step.title),21);para(col,str(step.action),16)
  var target="Studio" if n>0 and n<steps.size()-1 else "Learn" if n==0 else "My evidence"
  button(col,"Open tools" if target=="Studio" else "Learning support" if target=="Learn" else "Attach & explain",func():tab=target;render_module())
 para(body,("Your business decisions and records support the main outcomes. Explain what caused the results; profit alone does not earn a mark." if definition.get("subject","Business")=="Business" else "Your creation is the main evidence. Use Learn for support, test and improve the work, then attach the source once. Classroom routines, basic competencies and career-pathway discussions do not add program assessment tasks."),16)

func opportunity_controls()->void:
 var m=model();var research={} if work.sandbox==null else work.sandbox.get("research",{})
 para(body,"1 • Investigate. Enter the district and inspect at least two premises. Record their customer needs, equipment and costs. This is a comparison activity; there are no preset scores or hidden correct choice.",19)
 button(body,"Explore & inspect premises",open_simulation).disabled=not editable()
 para(body,"2 • Compare. These are the opportunities you inspected. Compare their assets, startup costs and trade-offs; use your own criteria in your explanation.",19)
 for id in research:
  var v=C.spec(id)
  if v.is_empty():continue
  var card=UI.card(body,v.name,"Customer need: "+v.need+"\nTrade-off: "+v.tradeoff+"\nAcquisition for an additional venture: %.0f. The first venture uses startup support." % float(research[id].acquisition))
  if not v.starter_products.is_empty():
   var art=TextureRect.new();art.texture=A.item_texture(v.starter_products[0],"product");art.custom_minimum_size=Vector2(88,88);art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;card.add_child(art)
 if research.is_empty():para(body,"Your inspection cards appear here after you visit the district and click Record premises inspection.")
 para(body,"3 • Confirm your planned venture. This records your decision as evidence; it does not buy a business or change sales. When ready, enter the district and acquire the premises.",19)
 var pick=OptionButton.new();pick.add_item("Choose an inspected opportunity");pick.set_item_metadata(0,-1)
 for i in C.ventures().size():
  var v=C.ventures()[i]
  if research.has(v.id):pick.add_item(v.name);pick.set_item_metadata(pick.item_count-1,i)
 body.add_child(pick);var reason=TextEdit.new();reason.custom_minimum_size.y=110;reason.placeholder_text="Which customer need will you meet? Compare costs, assets, risks and at least one alternative. Explain your choice.";reason.text=str(m.get("reason",""));body.add_child(reason)
 var commit=button(body,"Confirm planned venture",func():
  if research.size()<2 or pick.selected==0 or reason.text.strip_edges().length()<20:message("Inspect two premises, select one and explain your choice in at least 20 characters.");return
  m.planned=int(pick.get_item_metadata(pick.selected));m.planned_id=C.ventures()[m.planned].id;m.reason=reason.text.left(2000);m.confirmed=1
  if not m.has("original_planned"):m.original_planned=m.planned;m.original_id=m.planned_id;m.original_reason=m.reason
  mark_dirty();write_cache();message("Venture plan confirmed. It is saved as evidence; enter the district when you are ready to buy.")
  if not attempt.is_empty():save_draft())
 commit.disabled=not editable() or research.size()<2;reason.editable=editable();pick.disabled=not editable()
 if m.get("confirmed",0)==1:para(body,"Confirmed plan: "+C.spec(str(m.get("planned_id","kitchen"))).get("name","Earlier venture")+"\n"+str(m.reason))

func request_business_restart(id:String)->void:
 if attempt.is_empty() or not editable():message("Open an active assigned module to request a restart.");return
 if busy:pending_business_restart=id;return
 if dirty:pending_business_restart=id;save_draft();return
 call_api("restart-request",{"id":attempt.id,"business":id,"district_revision":int(work.get("district_revision",0))},"restart_requested")
