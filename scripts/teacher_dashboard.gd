extends CanvasLayer
const S=preload("res://scripts/learning_store.gd")
const T=preload("res://scripts/teacher_store.gd")
const UI=preload("res://scripts/studio_ui.gd")
var previous_menu=""
var example_level=-1
var example_data:Dictionary={}
var legacy:Node
var panel:PanelContainer
var content:VBoxContainer
var status:Label
var transfer:Node
static func open(owner:Node)->void:
 if not preload("res://scripts/education_access.gd").review_allowed():return
 var p=load("res://scripts/teacher_dashboard.gd").new();owner.add_child(p);p.setup(owner)
func setup(owner:Node)->void:
 add_to_group("fx_private_assessment")
 legacy=owner;previous_menu=legacy.game.menu;legacy.game.menu="teacher_dashboard";layer=107;panel=PanelContainer.new();panel.size=Vector2(1100,650);add_child(panel);UI.apply(panel)
 var col=VBoxContainer.new();panel.add_child(col);text(col,"TEACHER • CLASS VIEW",27)
 var row=HBoxContainer.new();col.add_child(row);button(row,"Submission room • 31 seats",func():var r=get_tree().root.get_node("FXEducationRoom");r.dashboard=self;r.open());button(row,"Broadcast lesson",func():get_tree().root.get_node("FXClassroom").host());button(row,"Spotlight",func():get_tree().root.get_node("FXEducationTools").spotlight=true);button(row,"Local portfolio",func():preload("res://scripts/teacher_review.gd").open(legacy));UI.accent(button(row,"Example",func():example_level=1;show_examples()));button(row,"Close",finish)
 var sc=ScrollContainer.new();sc.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(sc);sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;preload("res://scripts/touch_list_scroll.gd").attach(sc).form_controls=true
 content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;sc.add_child(content);status=text(col,"Class records are local. Download your profile before leaving a shared computer.",16)
 var bottom=HBoxContainer.new();col.add_child(bottom);button(bottom,"Download class records",func():legacy.game.hero_workshop.write_download(JSON.stringify(T.state()),"crossroads-class-records.json"));button(bottom,"Refresh",render);button(bottom,"Creation review & Showcase",func():load("res://scripts/studio_showcase.gd").open(legacy.game.hero_workshop))
 transfer=preload("res://scripts/studio_transfer.gd").new();transfer.max_bytes=T.MAX_BYTES;add_child(transfer);transfer.failed.connect(func(t:String):status.text=t);transfer.received.connect(import_records)
 button(bottom,"Restore class backup",func():transfer.choose());button(bottom,"Download class summary",func():legacy.game.hero_workshop.write_download(summary(),"crossroads-class-summary.md"))
 render();UI.enter(panel)
func text(n:Node,t:String,size:int)->Label:
 var l=Label.new();l.text=t;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",size);n.add_child(l);return l
func button(n:Node,t:String,f:Callable)->Button:
 var b=Button.new();b.text=t;b.custom_minimum_size.y=44;n.add_child(b);b.pressed.connect(f);return b
func render()->void:
 if example_level>=0:show_examples();return
 content.add_theme_constant_override("separation",12)
 if not is_in_group("fx_private_assessment"):add_to_group("fx_private_assessment")
 for n in content.get_children():content.remove_child(n);n.queue_free()
 var state=T.state()
 if state.students.is_empty():text(content,"Host a Submit assignment room. Students join your code to send their current portfolio automatically.",20)
 for code in state.classes:
  text(content,state.classes[code].title+" • "+code,23)
  button(content,"Remove this saved class…",func():remove_class(code))
  for key in state.students:
   var entry=state.students[key]
   if entry.class_code!=code:continue
   var d=entry.portfolio;var ready=0;var total=0;var graded=0
   for m in d.work:
    var rs=S.readiness(d,m,d.work[m]);total+=S.assessed_outcomes(m).size()
    for o in S.assessed_outcomes(m):if rs[o.id].ready:ready+=1
   for sub in d.submissions:graded+=sub.marks.size()
   var card=UI.card(content,entry.name,"Updated "+entry.time+" • "+str(d.submissions.size())+" submissions • "+str(graded)+" outcome ratings")
   var bar=ProgressBar.new();bar.max_value=maxi(1,total);bar.value=ready;bar.custom_minimum_size.y=22;card.add_child(bar);text(card,str(ready)+" / "+str(total)+" outcomes have requested evidence • readiness is not a grade",16)
   for m in d.work:
    for check in preload("res://scripts/learning_auto.gd").checks(d,d.work[m]):text(card,str(check.passed)+" / "+str(check.total)+" • "+check.title,16)
   for sub in d.submissions:
    var advice=preload("res://scripts/assessment_advice.gd").module(d,sub.module,sub);text(card,sub.module+" • suggested "+str(advice.score)+" / 100 (provisional)",16)
   button(card,"Review work & mark outcomes",func():review(key));button(card,"Nominate a creation for Showcase",func():nominate_creation(key))
func review(key:String)->void:
 var entry=T.state().students[key];var page=load("res://scripts/learning_page.gd").new();add_child(page);page.setup(legacy,true,entry.portfolio)
 page.on_review_save=func(value:Dictionary):
  var issue=T.ingest(entry.class_code,T.state().classes[entry.class_code].title,entry.id,value,false);status.text="Ratings saved to this class record." if issue.is_empty() else issue
  var room=get_tree().root.get_node("FXEducationRoom")
  if room.peers.has(key):room.return_feedback(room.peers[key],value)
  render()
func _process(_dt:float)->void:
 panel.size=Vector2(1100,650)
 var v=get_viewport().get_visible_rect().size;var f=minf(1,minf((v.x-24)/1100,(v.y-24)/650));panel.scale=Vector2.ONE*f;panel.position=(v-panel.size*f)*.5

func confirm(title:String,body:String,action:Callable)->void:
 var dialog=ConfirmationDialog.new();dialog.title=title;dialog.dialog_text=body;dialog.ok_button_text="Confirm";add_child(dialog);dialog.confirmed.connect(action);dialog.confirmed.connect(dialog.queue_free);dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(620,220))
func remove_class(code:String)->void:
 confirm("Remove saved class?","Download a backup first. This removes only this teacher's local class records, not student profiles.",func():
  var state=T.state();state.classes.erase(code)
  for key in state.students.keys():
   if state.students[key].class_code==code:state.students.erase(key)
  status.text=T.save(state);render()
 )
func import_records(text_value:String)->void:
 var value=JSON.parse_string(text_value)
 if not T.valid(value):status.text="Invalid class-record backup.";return
 confirm("Restore class backup?","This replaces your saved class records. Download the current records first if you need them.",func():status.text=T.save(value);render())
func summary()->String:
 var state=T.state();var out="# Crossroads class summary\n\nReadiness is evidence presence; teachers decide outcome achievement.\n"
 for key in state.students:
  var entry=state.students[key];out+="\n## "+entry.name+" • "+entry.class_code+"\nUpdated: "+entry.time+"\n"
  out+=S.report(entry.portfolio)+"\n"
 return out

func finish()->void:
 if legacy.game.menu in ["teacher_dashboard","learning"]:legacy.game.menu=previous_menu
 queue_free()
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:finish();get_viewport().set_input_as_handled()

func show_examples()->void:
 if is_in_group("fx_private_assessment"):remove_from_group("fx_private_assessment")
 for n in content.get_children():content.remove_child(n);n.queue_free()
 content.add_theme_constant_override("separation",8)
 var E=preload("res://scripts/teacher_examples.gd");var definitions=E.definitions()
 text(content,"EXAMPLE • "+definitions.levels[example_level].label+" • FICTIONAL WORK",23).modulate=Color("#f1ce83")
 text(content,"Two submitted modules / two in progress. Scores are illustrative; teachers decide achievement.",16)
 var levels=HBoxContainer.new();content.add_child(levels)
 for i in 3:
  var pick=button(levels,["1 • Fail","2 • Pass","3 • High grade"][i],func():example_level=i;show_examples())
  if i==example_level:UI.accent(pick)
 button(levels,"Return to real class",func():example_level=-1;render())
 if not example_data.has(example_level):example_data[example_level]=E.portfolio(example_level)
 var d:Dictionary=example_data[example_level]
 var grid=GridContainer.new();grid.columns=2;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_child(grid)
 for code in d.work:
  var w:Dictionary=d.work[code];var answered=[]
  for entry in w.entries:if not entry.text.strip_edges().is_empty() and not entry.stage in answered:answered.append(entry.stage)
  var done=false
  for sub in d.submissions:if sub.module==code:done=true
  var card=UI.card(grid,code+" • "+S.catalog()[code].name,"Submitted for review" if done else "Work in progress • not submitted");card.get_parent().size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.get_parent().custom_minimum_size.x=500;card.add_theme_constant_override("separation",6)
  var bar=ProgressBar.new();bar.max_value=S.stages(code).size();bar.value=answered.size();bar.custom_minimum_size.y=22;card.add_child(bar)
  var ready=S.readiness(d,code,w);var present=0
  for o in S.assessed_outcomes(code):if ready[o.id].ready:present+=1
  text(card,str(answered.size())+"/"+str(int(bar.max_value))+" prompts • "+str(present)+"/"+str(S.assessed_outcomes(code).size())+" project outcomes evidence-ready",15)
  button(card,"Review submitted work" if done else "Inspect unfinished work",func():review_example(code)).custom_minimum_size.y=36
 status.text="Fictional work & scores • click a module to inspect • practice edits are session-only."
func review_example(code:String)->void:
 var page=load("res://scripts/learning_page.gd").new();page.sample=true;add_child(page);page.setup(legacy,true,example_data[example_level]);page.module=code;page.data.active=code;page.tabs.current_tab=1;page.render()
 var selected=example_level
 page.on_review_save=func(value:Dictionary):example_data[selected]=value.duplicate(true);show_examples()

func nominate_creation(key:String)->void:
 var entry=T.state().students[key]
 var popup=ConfirmationDialog.new();popup.title="Choose a frozen student creation";popup.ok_button_text="Add to curation queue";add_child(popup);UI.apply(popup)
 var pick=OptionButton.new();pick.custom_minimum_size=Vector2(550,44);popup.add_child(pick);var items=[]
 for sub in entry.portfolio.submissions:
  for ref in sub.refs:
   if not entry.portfolio.artifacts.has(ref):continue
   var artifact:Dictionary=entry.portfolio.artifacts[ref]
   if artifact.kind in preload("res://scripts/studio_cycle.gd").COLLECTIONS:
    items.append(artifact);pick.add_item(sub.module+" • "+artifact.title)
 if items.is_empty():popup.queue_free();status.text="No frozen playable creations submitted yet. Review the student's artifacts first.";return
 popup.confirmed.connect(func():
  var a:Dictionary=items[pick.selected];var issue=preload("res://scripts/studio_cycle.gd").nominate(a.kind,a.value,entry.name,"Submitted class portfolio: "+a.title)
  status.text=issue if not issue.is_empty() else "Added to curation queue. Test and review before approving."
  popup.queue_free()
  if issue.is_empty():load("res://scripts/studio_showcase.gd").open(legacy.game.hero_workshop)
 );popup.canceled.connect(popup.queue_free);popup.popup_centered(Vector2i(620,190))
