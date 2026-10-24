extends CanvasLayer
const S=preload("res://scripts/learning_store.gd")
const UI=preload("res://scripts/studio_ui.gd")
var legacy:Node
var game:Node
var data:Dictionary
var module="DES1020"
var sample=false
var teacher=false
var remote=false
var panel:PanelContainer
var body:VBoxContainer
var content:VBoxContainer
var message:Label
var tabs:TabBar
var module_picker:OptionButton
var stage_picker:OptionButton
var writing:TextEdit
var selected_submission=""
var marked:Dictionary={}
var mark_drafts:Dictionary={}
var teacher_name="Teacher"
var link:Node
var options:Array=[]
var transfer:Node
var on_review_save:Callable
var previous_menu=""
var test_panel:PanelContainer
func setup(owner:Node,review:bool=false,received:Dictionary={})->void:
 if not (preload("res://scripts/education_access.gd").review_allowed() if review else preload("res://scripts/education_access.gd").student()):queue_free();return
 legacy=owner;game=legacy.game;teacher=review;remote=not received.is_empty();data=received.duplicate(true) if remote else S.load_data();module=data.active;layer=108
 if teacher and not sample:add_to_group("fx_private_assessment")
 previous_menu=game.menu;game.menu="learning"
 var shade=ColorRect.new();shade.color=Color(0.01,0.05,0.07,.88);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();panel.size=Vector2(1140,680);add_child(panel);UI.apply(panel)
 body=VBoxContainer.new();panel.add_child(body)
 var header=HBoxContainer.new();body.add_child(header);label(header,"TEACHER • OUTCOME REVIEW" if teacher else "STUDENT • LEARNING PORTFOLIO",26).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button(header,"Close",finish)
 if sample:label(body,"FICTIONAL EXAMPLE • illustrative scores • session-only marking practice",17).modulate=Color("#f1ce83")
 if teacher:
  var name_row=HBoxContainer.new();body.add_child(name_row);label(name_row,"Reviewer",16);var name=LineEdit.new();name.placeholder_text="Teacher display name (not verified)";name.text=teacher_name;name.max_length=80;name.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name_row.add_child(name);name.text_changed.connect(func(t:String):teacher_name=t)
 else:
  var row=HBoxContainer.new();body.add_child(row);label(row,"Student profile",16)
  var name=LineEdit.new();name.placeholder_text="Student display name / class alias";name.text=data.student;name.max_length=80;name.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(name);name.text_changed.connect(func(t:String):data.student=t);name.focus_exited.connect(func():S.save(data))
 var row=HBoxContainer.new();body.add_child(row);module_picker=OptionButton.new();module_picker.fit_to_longest_item=false;module_picker.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(module_picker)
 for code in S.catalog():
  if S.catalog()[code].get("archived",false):continue
  module_picker.add_item(str(code)+" • "+str(S.catalog()[code].name));module_picker.set_item_metadata(module_picker.item_count-1,code);if code==module:module_picker.select(module_picker.item_count-1)
 module_picker.item_selected.connect(func(i:int):module=str(module_picker.get_item_metadata(i));data.active=module;selected_submission="";if not remote:S.save(data)
 )
 module_picker.item_selected.connect(func(_i:int):render())
 tabs=TabBar.new();body.add_child(tabs)
 for title in (["Assignments","Evidence","Mark outcomes","Review code","Quick checks"] if teacher else ["Brief & outcomes","Journal","Attach work","Submit & feedback","Practice checks"]):tabs.add_tab(title)
 tabs.tab_changed.connect(func(_i:int):render())
 var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll).form_controls=true
 content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(content)
 message=label(body,"Evidence readiness is not a grade. Back up your profile on shared computers.",15)
 transfer=preload("res://scripts/studio_transfer.gd").new();transfer.max_bytes=S.MAX_BYTES;add_child(transfer);transfer.received.connect(import_portfolio);transfer.failed.connect(func(t:String):message.text=t)
 var footer=HBoxContainer.new();body.add_child(footer);button(footer,"Download portfolio",download);button(footer,"Download marking report",func():game.hero_workshop.write_download(S.report(data),"crossroads-learning-report.md"))
 if not sample:button(footer,"Open portfolio file" if teacher else "Import teacher feedback",func():transfer.choose())
 if not teacher:
  var actions=HBoxContainer.new();body.add_child(actions);button(actions,"Open Studio",func():finish();game.hero_workshop.open());button(actions,"Business Academy",func():finish();game.open_business_academy());button(actions,"Join teacher submission room",func():get_tree().root.get_node("FXEducationRoom").open())
 link=preload("res://scripts/learning_share.gd").new();add_child(link);link.setup(self)
 render();UI.enter(panel)
func label(parent:Node,t:String,n:int=17)->Label:
 var l=Label.new();l.text=t;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;l.add_theme_font_size_override("font_size",n);parent.add_child(l);return l
func button(parent:Node,t:String,action:Callable)->Button:
 var b=Button.new();b.text=t;b.custom_minimum_size.y=44;b.pressed.connect(action);parent.add_child(b);return b
func clear()->void:
 for child in content.get_children():content.remove_child(child);child.queue_free()
func latest()->Dictionary:
 var result={}
 for s in data.submissions:
  if s.module==module and (selected_submission.is_empty() or s.id==selected_submission):result=s
 return result
func review_work()->Dictionary:
 var submitted=latest()
 if not submitted.is_empty():return submitted
 if data.work.has(module):return data.work[module]
 return {}
func render()->void:
 clear();var m:Dictionary=S.catalog()[module]
 for i in module_picker.item_count:
  if module_picker.get_item_metadata(i)==module:module_picker.select(i)
 label(content,module+" • "+str(m.name),23)
 if m.draft:label(content,"DRAFT • Learning targets only. Exact CTS outcomes have not been supplied; do not award course credit from this brief.",17).modulate=Color("#f0c880")
 if teacher:
  match tabs.current_tab:
   0:review_home()
   1:evidence(review_work())
   2:mark_page()
   3:share_page()
   4:practice()
 else:
  if not data.enabled:label(content,"Student access is required to record assignment evidence.",17)
  match tabs.current_tab:
   0:brief()
   1:journal()
   2:attach_page()
   3:submit_page()
   4:practice()
func brief()->void:
 var m:Dictionary=S.catalog()[module];label(content,m.brief,18);label(content,"Prerequisite: "+str(m.prerequisite)+" • "+str(m.source),15)
 if module in preload("res://scripts/education_business.gd").MODULES:UI.accent(button(content,"Continue in Business Academy",func():finish();game.open_business_academy()))
 var w=S.work(data,module);var ready=S.readiness(data,module,w)
 for o in m.outcomes:
  if o.get("observation",false):continue
  var r=ready[o.id];var card=UI.card(content,"Outcome "+o.id+" • "+str(o.title))
  label(card,("Evidence ready for review" if r.ready else "Evidence in progress")+" • "+str(r.count)+" / "+str(r.need)+" short responses",16)
  if not r.get("sequence_ok",true):label(card,"Record the initial vision before attaching production work.",15)
  if not r.missing.is_empty():label(card,"Attach: "+", ".join(r.missing),15)
  if not o.stages.is_empty():button(card,"Add short response",func():tabs.current_tab=1;stage_picker.select(stage_index(o.stages[0]));update_prompt())
  else:button(card,"Show / attach practical work",func():tabs.current_tab=2;render())
func stage_index(id:String)->int:
 var stages:Array=S.stages(module)
 for i in stages.size():
  if stages[i].id==id:return i
 return 0
var prompt:Label
func journal()->void:
 label(content,"Save your brief before attaching a prototype. Entries are kept as versions; add a new entry to revise an idea. Local timestamps show recording order, not independently verified authorship.",16)
 stage_picker=OptionButton.new();stage_picker.fit_to_longest_item=false;content.add_child(stage_picker)
 for stage in S.stages(module):stage_picker.add_item(stage.title)
 prompt=label(content,"",17);writing=TextEdit.new();writing.custom_minimum_size.y=170;writing.placeholder_text="Explain your intention, decisions and evidence…";content.add_child(writing);stage_picker.item_selected.connect(func(_i:int):update_prompt());update_prompt()
 UI.accent(button(content,"Save evidence entry",func():
  if not data.enabled:message.text="Student access is required.";return
  var issue=S.note(data,module,S.stages(module)[stage_picker.selected].id,writing.text);message.text="Entry saved. Earlier entries remain available." if issue.is_empty() else issue
  if issue.is_empty():render()))
 var entries:Array=S.work(data,module).entries
 for i in range(entries.size()-1,-1,-1):
  var e:Dictionary=entries[i]
  if not S.stages(module).any(func(st):return st.id==e.stage):continue
  var card=UI.card(content,str(e.stage)+" • entry "+str(e.order),e.time);label(card,e.text,16)
func update_prompt()->void:prompt.text=S.stages(module)[stage_picker.selected].prompt
func attach_page()->void:
 label(content,"Attach frozen copies, not live links. Later edits in the Lab will not silently change a submission. Attach another snapshot to show a revision.",16)
 var row=HBoxContainer.new();content.add_child(row);button(row,"Current hero draft",attach_draft);button(row,"Vector card",func():var p=preload("res://scripts/learning_graphic.gd").new();add_child(p);p.setup(self));button(row,"Business Academy",func():finish();game.open_business_academy())
 var library=preload("res://scripts/studio_library.gd").load_data();options=[]
 for collection in ["heroes","abilities","enemies","behaviors","objects","realms"]:
  for id in library[collection]:
   var value:Dictionary=library[collection][id];options.append({"kind":{"heroes":"hero","abilities":"ability","enemies":"enemy","behaviors":"behavior","objects":"object","realms":"realm"}[collection],"value":value,"title":str(value.hero.name) if collection=="heroes" else str(value.get("name",id))})
 for photo in legacy.data.get("media_portfolio",[]):options.append({"kind":"photo","value":photo,"title":photo.title})
 var pick=OptionButton.new();pick.fit_to_longest_item=false;content.add_child(pick)
 for item in options:pick.add_item(str(item.kind).capitalize()+" • "+item.title)
 var take=button(content,"Attach selected saved work",func():if not options.is_empty():var item=options[pick.selected];attach(item.kind,item.value,item.title,"Saved local library / portfolio"));take.disabled=options.is_empty()
 label(content,"External art: import a PNG through Hero Workshop, or capture it through Media. External research, OBS/video links and file conventions belong in journal entries; links are displayed as text and never opened automatically.",15)
 evidence(S.work(data,module))
func attach_draft()->void:
 var p=game.hero_workshop.project
 if p.is_empty():message.text="Open and save a hero first.";return
 attach("hero",p,str(p.hero.name),"Current draft • may be imported or collaborative")
func attach(kind:String,value:Dictionary,title:String,origin:String)->void:
 if not data.enabled:message.text="Student access is required.";return
 var issue=S.attach(data,module,kind,value,title,origin);message.text="Snapshot attached." if issue.is_empty() else issue;render()
func picture(parent:Node,encoded:String)->void:
 var bytes=Marshalls.base64_to_raw(encoded)
 if not S.P.png_error(bytes).is_empty():return
 var im=Image.new()
 if im.load_png_from_buffer(bytes)!=OK:return
 var p=TextureRect.new();p.texture=ImageTexture.create_from_image(im);p.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;p.custom_minimum_size=Vector2(96,96);p.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;p.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;parent.add_child(p)
func evidence(w:Dictionary)->void:
 if w.is_empty():label(content,"No submission yet. Students use Submit & feedback after recording work.");return
 if teacher and latest().is_empty():label(content,"UNFINISHED WORK • preview only. Outcome ratings require a submitted snapshot.",17).modulate=Color("#f1ce83")
 for event in w.get("activity",[]):label(content,event.action+" • "+event.title+" • "+event.time,14)
 for id in w.refs:
  var a:Dictionary=data.artifacts[id];var card=UI.card(content,a.title,a.kind+" • "+a.time+" • "+a.origin);var row=HBoxContainer.new();card.add_child(row)
  for e in w.entries:
   if e.stage=="brief":
    label(card,"Original vision • "+e.time+"\n"+e.text,16)
    if a.has("order"):label(card,"Brief recorded "+("before" if e.order<a.order else "after")+" this snapshot • local order",14)
    break
  if a.kind in ["hero","enemy"]:
   var poses:Dictionary=a.value.hero.art if a.kind=="hero" else a.value.art
   for pose in poses:var col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(col);label(col,str(pose),14);picture(col,poses[pose])
  elif a.kind in ["photo","graphic","object"]:picture(card,a.value.image)
  if a.kind=="object":
   label(card,"Editable layers: "+str(a.value.layers.size())+" • "+str(a.value.settings)+"\nOperations: "+", ".join(a.value.operations),15)
   for layer in a.value.layers:picture(row,layer.image)
  if a.kind=="realm":
   var map=preload("res://scripts/studio_world_canvas.gd").new();card.add_child(map);map.setup(a.value);map.mouse_filter=Control.MOUSE_FILTER_IGNORE
   label(card,str(a.value.width)+" × "+str(a.value.height)+" • "+str(a.value.placements.size())+" placements • "+str(a.value.tests.size())+" tests\nVision: "+a.value.vision,16)
  if a.kind in ["hero","ability","enemy","behavior","realm"]:button(card,"Inspect / test snapshot",func():test_snapshot(a))
  if a.kind=="program":
   label(card,"Sequential source • "+str(a.value.cases.size())+" saved predictions",18);var source=CodeEdit.new();source.editable=false;source.text=a.value.code;source.custom_minimum_size.y=180;card.add_child(source)
  if a.kind=="quiz":label(card,"Concept check: "+str(preload("res://scripts/learning_auto.gd").quiz_score(a.value))+" / "+str(preload("res://scripts/learning_auto.gd").questions(a.value.module).size()),18)
  if a.kind=="business":label(card,preload("res://scripts/education_business.gd").summary(a.value)+"\nReflection: "+a.value.reflection,17)
  if a.kind=="ability":
   for frame in a.value.get("animation",[]):picture(row,frame)
  if a.kind=="district":
   var district=a.value
   label(card,"Market Quarter • "+str(district.periods)+" completed periods • "+str(district.visitors)+" visitors",19)
   for venture_id in district.businesses:
    var venture=district.businesses[venture_id]
    label(card,venture.name+" • cash %.2f • inventory %.2f • loan %.2f" % [venture.cash,venture.input_book+venture.stock_book,venture.loan],17)
    if not venture.note.is_empty():label(card,"Reasoning: "+venture.note,16)
    if not venture.last_result.is_empty():label(card,"Last period: %d sold • sales %.2f • operating profit %.2f • lost customers %d" % [venture.last_result.sold,venture.last_result.revenue,venture.last_result.profit,venture.last_result.lost],16)
  if a.kind=="market":label(card,"Day "+str(a.value.day)+" • revenue "+str(a.value.revenue)+" • profit "+str(a.value.profit)+" • "+str(a.value.history.size())+" reports\nForecast: "+str(a.value.forecast)+"\nReflection: "+str(a.value.reflection),16)
  var expand=button(card,"Show source / decisions",func():
   var code=TextEdit.new();code.editable=false;code.text=JSON.stringify(source_summary(a.value),"  ").left(18000);code.custom_minimum_size.y=220;card.add_child(code))
  expand.tooltip_text="Portable source is displayed as text; it is never executed as GDScript."
 for e in w.entries:
  var stage_prompt=""
  for stage in S.stages(module):
   if stage.id==e.stage:stage_prompt=stage.prompt
  var card=UI.card(content,str(e.stage)+" • entry "+str(e.order),e.time);label(card,"Prompt: "+stage_prompt,15).modulate=Color("#8bc9d2");label(card,e.text,16)
func submit_page()->void:
 var w=S.work(data,module);var readiness=S.readiness(data,module,w);var count=0
 for o in S.assessed_outcomes(module):if readiness[o.id].ready:count+=1
 label(content,str(count)+" / "+str(S.assessed_outcomes(module).size())+" project outcomes have the requested evidence. A teacher decides achievement; partial evidence can still be submitted.",18)
 UI.accent(button(content,"Mark this module for teacher review",func():
  if not data.enabled:message.text="Student access is required.";return
  var issue=S.submit(data,module);message.text="Frozen submission saved. Raise your hand or share a review code." if issue.is_empty() else issue;render()))
 button(content,"Submit to teacher • cloud assignments & feedback",func():get_tree().root.get_node("FXClassPro").open_student(module))
 button(content,"Share submitted work by review code",func():link.open(false))
 var s=latest()
 if not s.is_empty():
  label(content,"Latest submission • "+s.id+" • "+s.time,18)
  for id in s.marks:label(content,"Outcome "+id+" • "+s.marks[id].rating+"\n"+s.marks[id].feedback,16)
  if s.marks.is_empty():label(content,"Waiting for teacher assessment.")
func review_home()->void:
 if not sample:UI.accent(button(content,"Example",func():
  var owner=legacy;finish();var dashboard=load("res://scripts/teacher_dashboard.gd").new();owner.add_child(dashboard);dashboard.setup(owner);dashboard.example_level=1;dashboard.show_examples()))
 label(content,"Student: "+data.student+" • "+str(data.submissions.size())+" saved submissions. Observed evidence = recorded actions or test data. Creator explanation = student intent. Teacher assessment = your outcome decision. Evaluate evidence, not time played or a readiness checkmark. General routines, competencies and pathway discussions are assessed in class outside this program.",17)
 for code in S.catalog():
  var latest_s={}
  for s in data.submissions:if s.module==code:latest_s=s
  if latest_s.is_empty():
   if data.work.has(code):
    var unfinished=UI.card(content,code+" • "+S.catalog()[code].name,"In progress • not submitted")
    button(unfinished,"Inspect unfinished evidence",func():module=code;data.active=code;selected_submission="";tabs.current_tab=1;render())
   continue
  var card=UI.card(content,code+" • "+S.catalog()[code].name,latest_s.time)
  label(card,str(latest_s.refs.size())+" work snapshots • "+str(latest_s.entries.size())+" entries • "+str(latest_s.marks.size())+" outcome ratings",16)
  button(card,"Review this module",func():
   module=code;data.active=code;selected_submission=latest_s.id
   for i in module_picker.item_count:
    if module_picker.get_item_metadata(i)==code:module_picker.select(i)
   tabs.current_tab=2;render())
 if not sample:button(content,"Review on another computer • enter code",func():link.open(true))
 if not remote:button(content,"Local creation / progress overview",func():finish();preload("res://scripts/teacher_review.gd").open_overview(legacy))
func mark_page()->void:
 var s=latest()
 if s.is_empty():label(content,"Choose a submitted module first.");return
 selected_submission=s.id
 if not mark_drafts.has(s.id):mark_drafts[s.id]=s.marks.duplicate(true)
 marked=mark_drafts[s.id]
 UI.accent(button(content,"Save all outcome ratings & feedback",save_marks))
 label(content,"Assess submission "+s.id+". Ratings stay separate from optional 0–100 scores. Blank score = −1; there is no automatic CTS credit award.",16)
 var ready=S.readiness(data,module,s)
 var suggestion=preload("res://scripts/assessment_advice.gd").module(data,module,s)
 label(content,"Suggested mark: "+str(suggestion.score)+" / 100 • PROVISIONAL",21).modulate=Color("#edcf91")
 label(content,suggestion.reason,16)
 for o in S.catalog()[module].outcomes:
  if not marked.has(o.id):marked[o.id]={"rating":"Not assessed","feedback":"","score":-1.0}
  var card=UI.card(content,"Outcome "+o.id+" • "+o.title,"Teacher observation • no journal needed" if o.get("observation",false) else ("Requested evidence present" if ready[o.id].ready else "Missing / partial evidence")+" • short responses "+str(ready[o.id].count)+" / "+str(ready[o.id].need))
  var advice=preload("res://scripts/assessment_advice.gd").outcome(data,module,s,o)
  label(card,("Suggested: "+str(advice.score)+" / 100 • " if advice.score>=0 else "")+advice.reason,15).modulate=Color("#9cd0ca")
  var row=HBoxContainer.new();card.add_child(row);var pick=OptionButton.new();pick.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(pick)
  for rating in S.RATINGS:pick.add_item(rating)
  pick.select(maxi(0,S.RATINGS.find(marked[o.id].rating)));pick.item_selected.connect(func(i:int):marked[o.id].rating=S.RATINGS[i])
  label(row,"Score / 100",15)
  var score=SpinBox.new();score.tooltip_text="Optional score: −1 leaves it unset.";score.min_value=-1;score.max_value=100;score.step=1;score.value=marked[o.id].score;score.custom_minimum_size.x=120;row.add_child(score);score.value_changed.connect(func(v:float):marked[o.id].score=v)
  var feedback=TextEdit.new();feedback.custom_minimum_size.y=85;feedback.text=marked[o.id].feedback;feedback.placeholder_text="Evidence observed, feedback and next step…";card.add_child(feedback);feedback.text_changed.connect(func():marked[o.id].feedback=feedback.text.left(1500))
  var notes=VBoxContainer.new();card.add_child(notes);notes.hide()
  button(card,"Show evidence for this outcome",func():notes.visible=not notes.visible)
  for e in s.entries:
   if e.stage in o.stages:label(notes,str(e.stage)+" • "+e.time+"\n"+e.text,16)
  if not s.refs.is_empty():button(notes,"View submitted work snapshots",func():tabs.current_tab=1;render())
 UI.accent(button(content,"Save all outcome ratings & feedback",save_marks))
func save_marks()->void:
 var s=latest()
 if s.is_empty():return
 s.marks=marked.duplicate(true);mark_drafts[s.id]=marked.duplicate(true);s.teacher=teacher_name.left(80);s.reviewed=S.stamp()
 if on_review_save.is_valid():on_review_save.call(data)
 if sample:message.text="Example ratings changed for this session only. No student or class record was saved."
 elif remote:message.text="Review saved in this session. Send feedback using Review code; download your copy too."
 else:message.text="Teacher ratings saved in this profile." if S.save(data).is_empty() else "Could not save ratings. Download a backup."
func share_page()->void:
 if sample:label(content,"Example portfolios are fictional and cannot be sent to real students or submission rooms.");return
 label(content,"Private review codes transfer only frozen submitted work and feedback. They do not open the student's account, control the game or expose unsubmitted drafts.",17)
 button(content,"Connect using a student review code",func():link.open(true))
 if remote:button(content,"Return ratings to student for acceptance",func():link.return_feedback(data))
 label(content,"The student approves the connection and accepts returned feedback. Codes and local passcodes are classroom conveniences, not secure school accounts. Sessions expire after 30 minutes and close when the student stops sharing.",15)
func download()->void:
 var text=JSON.stringify(data,"  ");game.hero_workshop.write_download(text,"crossroads-example-portfolio.json" if sample else "crossroads-learning-portfolio.json")
func import_portfolio(text:String)->void:
 var value=JSON.parse_string(text)
 if not S.valid(value):message.text="Invalid learning portfolio. This account was not changed.";return
 if not teacher:
  var issue=S.apply_feedback(data,value);message.text="Teacher feedback imported into matching submissions." if issue.is_empty() else issue;render();return
 data=value;remote=true;module=data.active;selected_submission="";sync_picker();render();message.text="Review copy opened. Download assessed feedback or return it through a review code."
func sync_picker()->void:
 for i in module_picker.item_count:
  if module_picker.get_item_metadata(i)==module:module_picker.select(i)
func source_summary(value:Variant)->Variant:
 if value is Dictionary:
  var copy={}
  for key in value:
   if key in ["art","image","audio","data"] and value[key] is Dictionary or key in ["image","data"] and value[key] is String and value[key].length()>2000:copy[key]="[embedded asset — shown in preview / retained in download]"
   else:copy[key]=source_summary(value[key])
  return copy
 if value is Array:
  var copy=[]
  for item in value:copy.append(source_summary(item))
  return copy
 return value
func test_snapshot(a:Dictionary)->void:
 var shell=CanvasLayer.new();shell.layer=114;add_child(shell);var p=PanelContainer.new();p.size=Vector2(960,650);shell.add_child(p);UI.apply(p);p.position=(get_viewport().get_visible_rect().size-p.size)*.5
 test_panel=p
 var col=VBoxContainer.new();p.add_child(col);label(col,"SNAPSHOT TEST • no profile rewards",21)
 if a.kind=="realm":
  var arena=preload("res://scripts/studio_realm_test.gd").new();arena.custom_minimum_size=Vector2(900,500);col.add_child(arena);arena.setup(a.value,S.P.fresh());arena.preview_has_focus=true
 elif a.kind=="enemy" or a.kind=="behavior" and a.value.kind=="enemy":
  var arena=preload("res://scripts/studio_battle.gd").new();arena.custom_minimum_size=Vector2(900,540);col.add_child(arena)
  var enemy=preload("res://scripts/studio_enemy_project.gd").fresh()
  if a.kind=="enemy":enemy=a.value.duplicate(true)
  else:enemy.behavior=a.value.duplicate(true)
  arena.setup(enemy,S.P.fresh(),1);arena.preview_has_focus=true
 elif a.kind=="behavior":
  var code=TextEdit.new();code.text=a.value.program;code.editable=false;code.custom_minimum_size.y=450;col.add_child(code)
 else:
  var arena=preload("res://scripts/workshop_arena.gd").new();arena.custom_minimum_size=Vector2(900,540);col.add_child(arena)
  var hero=a.value.duplicate(true) if a.kind=="hero" else S.P.fresh()
  if a.kind=="ability":hero.hero.primary=a.value.duplicate(true)
  arena.begin(hero,[],"Cluster");arena.preview_has_focus=true
 button(col,"Close test",func():test_panel=null;shell.queue_free())
func finish()->void:
 if not teacher and not remote:S.save(data)
 if is_instance_valid(link):link.stop()
 if game.menu=="learning":game.menu=previous_menu
 queue_free()
func _process(_dt:float)->void:
 panel.size=Vector2(1140,680)
 var view=get_viewport().get_visible_rect().size;var fit=minf(1,minf((view.x-24)/1140,(view.y-24)/680));panel.scale=Vector2.ONE*fit;panel.position=(view-panel.size*fit)*.5
 if is_instance_valid(test_panel):
  var factor=minf(1,minf((view.x-24)/960,(view.y-24)/650));test_panel.scale=Vector2.ONE*factor;test_panel.position=(view-test_panel.size*factor)*.5
func _unhandled_input(event:InputEvent)->void:
 if game.menu=="education_business":return
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:finish();get_viewport().set_input_as_handled()

func practice()->void:
 label(content,"Technical checks give evidence, not automatic course credit.",17)
 var w=review_work() if teacher else S.work(data,module)
 for check in preload("res://scripts/learning_auto.gd").checks(data,w):
  label(content,str(check.passed)+" / "+str(check.total)+" • "+check.title,20)
  var bar=ProgressBar.new();bar.max_value=maxi(1,check.total);bar.value=check.passed;bar.custom_minimum_size.y=20;content.add_child(bar);label(content,check.detail,16)
 if teacher:return
 if module=="CSE1110":UI.accent(button(content,"Open IPO coding workbench",func():var p=load("res://scripts/education_ipo.gd").new();add_child(p);p.setup(self)))
 var qs=preload("res://scripts/learning_auto.gd").questions(module)
 if qs.is_empty():label(content,"Attach work to see its technical checks. This module uses teacher-reviewed project evidence.");return
 var answers=[]
 for q in qs:
  label(content,q.text,18);var pick=OptionButton.new();pick.fit_to_longest_item=false;pick.size_flags_horizontal=Control.SIZE_EXPAND_FILL;content.add_child(pick)
  for choice in q.choices:pick.add_item(choice)
  answers.append(pick)
 UI.accent(button(content,"Check & save concept exercise",func():
  var choices=[]
  for pick in answers:choices.append(pick.selected)
  var value={"module":module,"answers":choices};attach("quiz",value,module+" concept exercise","Student-selected answers");message.text="Concept check: "+str(preload("res://scripts/learning_auto.gd").quiz_score(value))+" / "+str(qs.size())
 ))
