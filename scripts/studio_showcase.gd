extends CanvasLayer
const C=preload("res://scripts/studio_cycle.gd")
const L=preload("res://scripts/studio_library.gd")
const UI=preload("res://scripts/studio_ui.gd")
var workshop:Node
var panel:PanelContainer
var content:VBoxContainer
var status:Label
var page=0
var transfer:Node
var test_layer:CanvasLayer
var arena:Control
var test_kind=""
var test_value:Dictionary={}
var detail_entry:Dictionary={}
var author:LineEdit
var description:TextEdit
var changes:TextEdit
var hidden_panels:Array=[]
var suspended:Array=[]
var opened_copy=false
static func open(owner:Node)->void:
 var view=load("res://scripts/studio_showcase.gd").new();owner.add_child(view);view.setup(owner)
func setup(owner:Node)->void:
 workshop=owner;layer=85
 for node in [workshop.panel,workshop.hub,workshop.test_panel]:
  if is_instance_valid(node) and node.visible:hidden_panels.append(weakref(node));node.hide()
 for child in workshop.get_children():
  if child==self:continue
  if child is CanvasLayer and child.get("panel")!=null and child.panel.visible:
   hidden_panels.append(weakref(child.panel));child.panel.hide()
   if child.get("preview")!=null and is_instance_valid(child.preview):suspended.append([weakref(child.preview),child.preview.is_processing()]);child.preview.set_process(false)
 tree_exiting.connect(func():
  if not opened_copy:
   for ref in hidden_panels:
    if ref.get_ref()!=null:ref.get_ref().show()
   for pair in suspended:
    if pair[0].get_ref()!=null:pair[0].get_ref().set_process(pair[1])
 )
 panel=PanelContainer.new();panel.size=Vector2(1100,700);add_child(panel);UI.apply(panel)
 var body=VBoxContainer.new();panel.add_child(body)
 var top=HBoxContainer.new();body.add_child(top);text(top,"CROSSROADS • CREATE & SHARE",25).size_flags_horizontal=Control.SIZE_EXPAND_FILL;button(top,"Back",queue_free)
 var tabs=HBoxContainer.new();body.add_child(tabs)
 for pair in [["My projects",0],["Submissions & feedback",1],["Community Showcase",2]]:
  var n:int=pair[1];button(tabs,pair[0],func():page=n;render())
 if preload("res://scripts/education_access.gd").review_allowed():button(tabs,"Teacher curation",func():page=3;render())
 var sc=ScrollContainer.new();sc.size_flags_vertical=Control.SIZE_EXPAND_FILL;sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;body.add_child(sc);preload("res://scripts/touch_list_scroll.gd").attach(sc).form_controls=true
 content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;sc.add_child(content)
 status=text(body,"Projects and feedback save on this device. Download Profile to back up everything.",15)
 transfer=preload("res://scripts/studio_transfer.gd").new();transfer.max_bytes=12582912;add_child(transfer);transfer.failed.connect(func(t:String):status.text=t);transfer.received.connect(import_file)
 var tools=HBoxContainer.new();body.add_child(tools);button(tools,"Import submission / feedback / Showcase",func():transfer.choose())
 button(tools,"How this works",guide)
 render();UI.enter(panel)
func text(parent:Node,t:String,size:int=17)->Label:return workshop.label(parent,t,size)
func button(parent:Node,t:String,f:Callable)->Button:return workshop.button(parent,t,f)
func wipe()->void:workshop.clear(content)
func render()->void:
 wipe();detail_entry={}
 var data=L.load_data()
 match page:
  0:
   text(content,"Your next step, at a glance",23)
   text(content,"Save → Test this revision → Finalize → Share → Feedback → Improve. Checkmarks show actions recorded, not grades.",16)
   if not L.recovery_message().is_empty():text(content,L.recovery_message(),17).modulate=Color("#efd28a")
   var count=0
   for kind in C.COLLECTIONS:
    for id in data[C.COLLECTIONS[kind]]:
     var value:Dictionary=data[C.COLLECTIONS[kind]][id];count+=1
     var state=C.readiness(data,kind,value);var card=UI.card(content,C.title(kind,value),kind.capitalize()+" • "+state.next)
     thumbnail(card,kind,value)
     var bar=ProgressBar.new();bar.max_value=6;bar.value=1+int(state.tested)+int(state.finalized)+int(state.shared)+int(state.feedback)+int(state.revised);bar.custom_minimum_size.y=18;card.add_child(bar)
     text(card,"Saved  •  "+("Tested" if state.tested else "Test needed")+"  •  "+("Finalized" if state.finalized else "Finalize needed")+"  •  "+("Shared" if state.shared else "Share")+"  •  "+("Feedback received" if state.feedback else "Feedback")+"  •  "+("Revision tested" if state.revised else "Improve"),16)
     var row=HBoxContainer.new();card.add_child(row)
     button(row,"Open in Lab",func():edit(kind,value))
     button(row,"Play / Test",func():play(kind,value))
     button(row,"Finalize revision",func():status.text=C.stored(kind,value,true);render())
     var share=button(row,"Share submission",func():share_form(kind,value));share.disabled=not state.ready or state.shared
     if state.shared:UI.accent(button(row,"Check feedback",func():page=1;render()))
   if count==0:text(content,"Start in any Lab, then save or finalize your creation. It appears here automatically.",19)
  1,3:
   if page==3 and not preload("res://scripts/education_access.gd").review_allowed():text(content,"Teacher access required.");return
   text(content,"Teacher review queue" if page==3 else "Frozen submissions & returned feedback",23)
   text(content,"Share a submission JSON with a teacher or partner. Import returned feedback here. Creating a new revision never rewrites a submitted copy.",16)
   if data.cycle.submissions.is_empty():text(content,"No submissions yet. Test and finalize a project, then choose Share submission.",19)
   for e in data.cycle.submissions.values():entry_card(e,page==3)
  2:
   text(content,"Made by creators. Selected by teachers.",23)
   text(content,"Import a Showcase pack supplied by your teacher. Entries stay separate from your drafts; testing one does not overwrite your work or earn game progress.",16)
   var bundled=JSON.parse_string(FileAccess.get_file_as_string("res://content/workshop/showcase.json"))
   if bundled is Dictionary:
    for e in bundled.get("entries",[]):
     if C.valid_entry(e) and e.status=="approved":entry_card(e,false)
   for e in data.cycle.showcase.values():entry_card(e,false)
   if data.cycle.showcase.is_empty():text(content,"Your class can add its own featured creations. The examples above demonstrate the format; they are not student submissions.",17)
   if preload("res://scripts/education_access.gd").review_allowed():UI.accent(button(content,"Download approved Showcase pack",func():download(C.catalog(),"crossroads-showcase.json")))
func thumbnail(parent:Node,kind:String,value:Dictionary)->void:
 var encoded=""
 if kind=="hero":encoded=str(value.hero.art.get("idle",""))
 elif kind=="enemy":encoded=str(value.art.get("idle",""))
 elif kind=="object":encoded=str(value.get("image",""))
 elif kind=="ability" and not value.get("animation",[]).is_empty():encoded=str(value.animation[0])
 if encoded.is_empty():return
 var img=Image.new()
 if img.load_png_from_buffer(Marshalls.base64_to_raw(encoded))!=OK:return
 var pic=TextureRect.new();pic.texture=ImageTexture.create_from_image(img);pic.custom_minimum_size=Vector2(64,64);pic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;pic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;pic.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;parent.add_child(pic)
func entry_card(e:Dictionary,review:bool)->void:
 var card=UI.card(content,C.title(e.kind,e.value),e.kind.capitalize()+" • "+e.author+" • version "+str(int(e.version))+" • "+e.status.replace("_"," "))
 thumbnail(card,e.kind,e.value);text(card,e.description,17)
 if not e.changes.is_empty():text(card,"What changed: "+e.changes,16)
 var row=HBoxContainer.new();card.add_child(row);UI.accent(button(row,"Play / Test",func():play(e.kind,e.value)))
 button(row,"View evidence & feedback",func():entry_detail(e,review))
 button(row,"Download this submission",func():download(C.envelope(e),C.title(e.kind,e.value).validate_filename()+".submission.json"))
 if page==1:
  button(row,"Edit a copy",func():edit(e.kind,e.value))
  button(row,"Remove saved snapshot…",func():remove_snapshot(e.id))
func share_form(kind:String,value:Dictionary)->void:
 wipe();text(content,"Share a frozen revision • "+C.title(kind,value),23)
 text(content,"A few words help other people test your idea. This is a creation submission; curriculum assignments remain in your learning portfolio.",16)
 author=line("Creator alias",str(value.get("author","")))
 description=note("What should people try?",str(value.get("concept","")))
 changes=note("What changed since the last version? (optional)","")
 UI.accent(button(content,"Freeze & download submission",func():
  var result=C.submit(kind,value,author.text,description.text,changes.text)
  if not result.error.is_empty():status.text=result.error;return
  download(C.envelope(result.entry),C.title(kind,value).validate_filename()+".submission.json");page=1;render();status.text="Frozen copy saved. Send its file to your reviewer."
 ))
 button(content,"Back to projects",func():page=0;render())
func line(title:String,value:String)->LineEdit:
 text(content,title,16);var input=LineEdit.new();input.text=value;input.max_length=40;content.add_child(input);return input
func note(title:String,value:String)->TextEdit:
 text(content,title,16);var input=TextEdit.new();input.text=value;input.custom_minimum_size.y=90;input.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY;content.add_child(input);return input
func entry_detail(e:Dictionary,review:bool)->void:
 wipe();detail_entry=e.duplicate(true);text(content,C.title(e.kind,e.value)+" • version "+str(int(e.version)),24)
 text(content,"Frozen "+e.date+" • fingerprint "+e.hash.left(12),15)
 var evidence=UI.card(content,"Evidence: what is known")
 text(evidence,"Observed / recorded: validated artwork and bounded project data. Local tests are measurements, not proof of balance or ownership.",16)
 for t in e.get("tests",[]):text(evidence,t.source+" • "+t.date+"\n"+JSON.stringify(t.metrics),16)
 var reports=e.value.get("reports",e.value.get("tests",[]))
 if not reports.is_empty():text(evidence,JSON.stringify(reports.back(),"  ").left(1500),15)
 else:text(evidence,"No embedded test report. Ask for a reproducible playtest and compare it with the design intent.",16)
 text(evidence,"Creator explanation: "+e.description,16)
 text(evidence,"Teacher assessment: only ratings in the outcome portfolio count as curriculum assessment. Showcase approval is a separate publishing decision.",16)
 for f in e.feedback:text(content,f.reviewer+" • "+f.date+"\nWorked: "+f.worked+"\nConfusing: "+f.confused+"\nNext step: "+f.improve,16)
 author=line("Reviewer alias","");var worked=note("What worked?","");var confused=note("What confused you?","");var improve=note("One useful next step","")
 var feedback=func()->Dictionary:return {"reviewer":author.text.left(40),"worked":worked.text.left(500),"confused":confused.text.left(500),"improve":improve.text.left(500),"date":Time.get_datetime_string_from_system(true)}
 button(content,"Download peer feedback",func():
  if author.text.strip_edges().is_empty() or improve.text.strip_edges().is_empty():status.text="Add your alias and a useful next step.";return
  var copy=e.duplicate(true);copy.feedback.append(feedback.call())
  if copy.feedback.size()>12:copy.feedback.pop_front()
  download(C.envelope(copy),"crossroads-peer-feedback.json")
 )
 if review:
  text(content,"Before featuring: test it, check credited artwork/audio and permissions, and confirm it is suitable for your class.",16)
  for pair in [["Approve for Showcase",true],["Return for revision",false]]:
   var approve:bool=pair[1];button(content,pair[0],func():var issue=C.review(e.id,approve,feedback.call());status.text=issue if not issue.is_empty() else "Review saved. Download this updated submission to return feedback.";if issue.is_empty():entry_detail(L.load_data().cycle.submissions[e.id],review))
 button(content,"Download current submission / feedback",func():download(C.envelope(detail_entry),"crossroads-reviewed-submission.json"))
 button(content,"Back",render)
func import_file(raw:String)->void:
 var v=JSON.parse_string(raw);var issue=C.import_catalog(v) if v is Dictionary and v.get("format")=="fx-crossroads-showcase" else C.accept(v)
 status.text="Imported. Files supplied by teachers are trusted classroom material, not authenticated server publications." if issue.is_empty() else issue
 if issue.is_empty():render()
func download(value:Dictionary,name:String)->void:workshop.write_download(JSON.stringify(value,"  "),name)
func edit(kind:String,value:Dictionary)->void:
 var dialog=ConfirmationDialog.new();dialog.title="Open an editable copy?";dialog.dialog_text="Your current hero draft is saved before opening. Download other open Lab work first if you need a separate file.";dialog.ok_button_text="Save draft & open copy";add_child(dialog);UI.apply(dialog)
 dialog.confirmed.connect(func():workshop.save_draft();open_copy(kind,value);dialog.queue_free());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(610,210))
func open_copy(kind:String,value:Dictionary)->void:
 opened_copy=true
 if not workshop.active:workshop.open()
 for child in workshop.get_children():
  if child==self:continue
  if child is CanvasLayer and child.get("panel")!=null and child.get_script() in [load("res://scripts/studio_lab.gd"),load("res://scripts/studio_enemy_lab.gd"),load("res://scripts/studio_behavior_lab.gd"),load("res://scripts/studio_world_lab.gd")]:
   child.panel.hide();child.queue_free()
 var copy=value.duplicate(true)
 match kind:
  "hero":workshop.project=copy;workshop.latest_report={};workshop.panel.show();workshop.hub.hide();workshop.render()
  "ability":workshop.open_lab(copy)
  "enemy":
   workshop.open_enemy()
   var children=workshop.get_children();var lab=children.back();lab.enemy=copy;lab.render()
  "behavior":workshop.open_behavior(copy)
  "object","realm":workshop.open_world_lab(kind=="realm");workshop.lab.value=copy;workshop.lab.render()
 queue_free()
func play(kind:String,value:Dictionary)->void:
 if is_instance_valid(test_layer):return
 test_kind=kind;test_value=value.duplicate(true);test_layer=CanvasLayer.new();test_layer.layer=90;add_child(test_layer)
 var frame=PanelContainer.new();frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);test_layer.add_child(frame);UI.apply(frame)
 var col=VBoxContainer.new();frame.add_child(col);var row=HBoxContainer.new();col.add_child(row);text(row,C.title(kind,value)+" • SANDBOX",22).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 button(row,"Finish test & return",finish_test)
 text(col,"No profile rewards. WASD move • mouse aim • LMB / RMB / Space attacks. Test a specific change, then record useful feedback.",16)
 if kind=="behavior":text(col,"Executing bounded decisions:\n"+str(value.program),15)
 if kind=="object":thumbnail(col,kind,value);text(col,"Visual inspection: check silhouette, contrast, scale and the collision footprint in a realm.",19);return
 var P=preload("res://scripts/workshop_project.gd");var hero=P.fresh()
 if kind=="hero":hero=value.duplicate(true)
 if kind=="ability":hero.hero.primary=value.duplicate(true)
 if kind=="realm":arena=load("res://scripts/studio_realm_test.gd").new();col.add_child(arena);arena.setup(value,hero)
 elif kind in ["enemy","behavior"]:
  var enemy=value.duplicate(true) if kind=="enemy" else preload("res://scripts/studio_enemy_project.gd").fresh()
  if kind=="behavior" and value.kind=="enemy":enemy.behavior=value.duplicate(true)
  if kind=="behavior" and value.kind=="ability":hero.hero.primary.behavior=value.duplicate(true)
  arena=load("res://scripts/studio_battle.gd").new();col.add_child(arena);arena.setup(enemy,hero,1)
 else:arena=load("res://scripts/workshop_arena.gd").new();col.add_child(arena);arena.begin(hero,[],"Cluster")
 arena.size_flags_vertical=Control.SIZE_EXPAND_FILL;arena.size_flags_horizontal=Control.SIZE_EXPAND_FILL;arena.custom_minimum_size.y=340;arena.grab_focus()
 var controls=HBoxContainer.new();col.add_child(controls)
 for entry in [["Left",Vector2.LEFT],["Up",Vector2.UP],["Down",Vector2.DOWN],["Right",Vector2.RIGHT]]:
  var b=button(controls,entry[0],func():pass);var dir:Vector2=entry[1];b.button_down.connect(func():if is_instance_valid(arena):arena.touch_direction=dir);b.button_up.connect(func():if is_instance_valid(arena):arena.touch_direction=Vector2.ZERO)
 for slot in ["primary","secondary","special"]:
  var b=button(controls,slot.capitalize(),func():pass);var attack_slot:String=slot;b.button_down.connect(func():if is_instance_valid(arena):arena.press(attack_slot));b.button_up.connect(func():if is_instance_valid(arena):arena.release(attack_slot))
func finish_test()->void:
 var metrics={"seconds":0.0,"damage":0.0,"result":"Visual inspection"};var source="Creator-reported visual inspection"
 if is_instance_valid(arena):
  metrics={"seconds":snappedf(arena.time,.1),"damage":snappedf(arena.damage,.1),"result":"Sandbox test"};source="Observed local sandbox test"
  if arena.time<2:status.text="Test for at least two seconds before recording evidence.";return
 var issue=C.test(test_kind,test_value,metrics,source);status.text="Test recorded for this exact revision. Finalize it when ready, then share." if issue.is_empty() else issue
 test_layer.queue_free();test_layer=null;arena=null;render()
func guide()->void:
 UI.lesson(self,"MAKE SOMETHING PEOPLE PLAY","Create → test → share → improve",[{"title":"Your project stays yours","body":"Saved projects remain editable. A submission freezes one revision. Editing afterwards asks for a new test; it never rewrites the submitted copy."},{"title":"Feedback with a purpose","body":"Try a creation, explain what worked and choose one useful next step. Import returned feedback and improve a copy. Class aliases are enough; avoid personal information."},{"title":"Teacher-curated Showcase","body":"A teacher reviews the work, tests it and checks permissions before approving it. Download the approved pack for classmates or place its entries in content/workshop/showcase.json for the next release. Local files are editable; this is a classroom publishing workflow, not secure online identity."},{"title":"Evidence is not a grade","body":"Recorded test: what the sandbox measured. Creator explanation: what the student intended. Teacher judgement: whether the curriculum outcome was achieved. Publication approval does not award a course mark."}])
func _process(_dt:float)->void:
 var view=get_viewport().get_visible_rect().size;panel.size=Vector2(1100,700);panel.scale=Vector2.ONE*minf(1,minf((view.x-24)/1100,(view.y-24)/700));panel.position=(view-panel.size*panel.scale)*.5
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
  if is_instance_valid(test_layer):finish_test()
  else:queue_free()
  get_viewport().set_input_as_handled()

func remove_snapshot(id:String)->void:
 var dialog=ConfirmationDialog.new();dialog.title="Remove this local snapshot?";dialog.dialog_text="Download it first if needed. Your editable project remains. This removes only this device's submission and matching local Showcase entry.";dialog.ok_button_text="Remove snapshot";add_child(dialog);UI.apply(dialog)
 dialog.confirmed.connect(func():var d=L.load_data();d.cycle.submissions.erase(id);d.cycle.showcase.erase(id);status.text=L.save_data(d);dialog.queue_free();render());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered(Vector2i(610,220))
