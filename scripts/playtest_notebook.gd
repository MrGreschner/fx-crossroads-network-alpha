extends CanvasLayer
## Local student notes, separate from player saves and Game Dev progression.
const DRAFT="user://fx_playtest_notes.json"
var game:Node
var panel:PanelContainer
var tabs:TabContainer
var fields:Dictionary={}
var notes:Dictionary={}
var notice:Label
var dialog:FileDialog
var dirty:=false
var save_timer:=0.0
const SECTIONS={
 "Testing":{"areas":"Areas tested (hero, realm, mode, menus)","method":"How you tested: steps, trials, solo/co-op, device","results":"Results and evidence: expected vs observed; include tests that passed","limits":"What you did NOT test / limitations"},
 "Issue 1":{"title1":"Issue title & type (bug, usability, balance, performance)","steps1":"Exact steps to reproduce / how often it happened","evidence1":"Expected vs observed; player impact; screenshot filename if available","fix1":"Proposed improvement, trade-off and how to verify the fix"},
 "Issue 2":{"title2":"Issue title & type (bug, usability, balance, performance)","steps2":"Exact steps to reproduce / how often it happened","evidence2":"Expected vs observed; player impact; screenshot filename if available","fix2":"Proposed improvement, trade-off and how to verify the fix"},
 "Issue 3":{"title3":"Issue title & type (bug, usability, balance, performance)","steps3":"Exact steps to reproduce / how often it happened","evidence3":"Expected vs observed; player impact; screenshot filename if available","fix3":"Proposed improvement, trade-off and how to verify the fix"},
 "Reflection":{"learning":"What did you learn about design, testing or teamwork? Use an example.","priority":"Which improvement comes first, and why? What did a teammate notice?","design":"Describe a new idea, its trade-off and a test of whether it helps.","next":"What would you test next? What evidence would change your conclusion?"}}
func setup(owner:Node)->void:
 game=owner;layer=65;name="PlaytestNotebook"
 if FileAccess.file_exists(DRAFT):
  var parsed:Variant=JSON.parse_string(FileAccess.get_file_as_string(DRAFT))
  if parsed is Dictionary:
   for key in parsed:notes[str(key)]=str(parsed[key]).left(4000)
 var shade:=ColorRect.new();shade.color=Color(.015,.035,.05,.95);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();panel.size=Vector2(1080,650);add_child(panel)
 var skin:=StyleBoxFlat.new();skin.bg_color=Color("#142f38");skin.set_content_margin_all(20);skin.set_corner_radius_all(12);skin.border_color=Color("#d2bd82");skin.set_border_width_all(2);panel.add_theme_stylebox_override("panel",skin)
 var body:=VBoxContainer.new();body.add_theme_constant_override("separation",10);panel.add_child(body)
 label(body,"PLAYTEST NOTEBOOK",27)
 label(body,"Notes stay on this device, separate from your player profile. Download before leaving a shared computer. Game Dev tests do not earn progress. Live multiplayer keeps running.",16)
 tabs=TabContainer.new();tabs.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(tabs)
 for section in SECTIONS:
  var scroll:=ScrollContainer.new();scroll.name=section;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;tabs.add_child(scroll)
  var col:=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;col.add_theme_constant_override("separation",8);scroll.add_child(col)
  for key in SECTIONS[section]:
   label(col,str(SECTIONS[section][key]),18)
   var edit:=TextEdit.new();edit.custom_minimum_size.y=82;edit.size_flags_horizontal=Control.SIZE_EXPAND_FILL;edit.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY;edit.text=str(notes.get(key,""));edit.placeholder_text="Write your own observations here…";edit.add_theme_font_size_override("font_size",18);col.add_child(edit);fields[key]=edit
   edit.text_changed.connect(func():
    var value:=edit.text.left(4000)
    if str(notes.get(key,""))==value:return
    notes[key]=value;dirty=true;save_timer=.6
   )
 var help_scroll:=ScrollContainer.new();help_scroll.name="Play & learn";help_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;tabs.add_child(help_scroll)
 var help:=VBoxContainer.new();help.size_flags_horizontal=Control.SIZE_EXPAND_FILL;help_scroll.add_child(help)
 label(help,"WHAT CAN YOU EXPLORE?",23)
 label(help,"Realms: short adventures and boss fights.\nCave Descent: deeper survival floors, health gems and milestone bosses.\nNorth Gate Defence: defend three roads with allied guards.\nGladiator Arena: player battles, maps, host rules, spectators and practice AI.\nBattlegrounds: teams build armies and upgrade barracks.\nQuests: explore, speak with villagers and complete objectives.\nTraining Yard: safe attack, projectile and ally-healing tests.\nMistglass Spire: discover enemies and study their field-guide cards.\nChallenge Lodge: five quick trials and weekly medals.\nGatherers’ Lodge: timed ingredient trips and rare garden seeds.\nWillowglass Apothecary: brew and pack single-use potions.\nMastery and town projects: optional long-term character changes and town growth.",20)
 label(help,"TESTING TIP: change one thing at a time. Repeat a test and record attempts/results. A preference or design suggestion is different from a reproducible bug. Test working features too. Do not claim you tested an area you did not visit.",19)
 label(help,"Temporary testing: ask your teacher about Game Dev mode. It unlocks abilities without earning scores or saving progression. Notebook reports can still be downloaded. For profile-transfer tests use a teacher-approved disposable normal profile.",19)
 var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);body.add_child(row)
 for pair in [["Copy report",copy_report],["Download report",download_report],["Clear notes…",confirm_clear],["Close",queue_free]]:button(row,pair[0],pair[1])
 notice=label(body,"Report your observations; a diagnostic snapshot alone is not a test report. Nothing is uploaded automatically.",15)
func label(parent:Node,value:String,size:int)->Label:
 var l:=Label.new();l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",size);parent.add_child(l);return l
func button(parent:Node,value:String,action:Callable)->Button:
 var b:=Button.new();b.text=value;b.custom_minimum_size=Vector2(180,46);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.pressed.connect(action);preload("res://scripts/top_button_style.gd").apply(b);parent.add_child(b);return b
func save_draft()->void:
 dirty=false
 var f:=FileAccess.open(DRAFT,FileAccess.WRITE)
 if f!=null:f.store_string(JSON.stringify(notes));f.flush();f.close()
 elif is_instance_valid(notice):notice.text="Could not save a local draft. Copy or download your report before closing."
func report()->String:
 var lines:Array[String]=["CROSSROADS: REALMS BEYOND — STUDENT PLAYTEST REPORT","Context at export (record the actual test context in your notes):\n"+preload("res://scripts/release_support.gd").context(game),"Notes exported: "+Time.get_datetime_string_from_system(true)]
 for section in SECTIONS:
  lines.append("\n"+str(section).to_upper())
  for key in SECTIONS[section]:lines.append(str(SECTIONS[section][key])+"\n"+str(notes.get(key,"[Not completed]")))
 lines.append("\nThis is a student-authored local report. It does not automatically submit an assignment or verify that tests were performed.")
 return "\n\n".join(PackedStringArray(lines))
func copy_report()->void:
 preload("res://scripts/release_support.gd").copy_text(report());notice.text="Copy requested. Paste into your assignment; use Download if clipboard access is blocked."
func download_report()->void:
 var content:=report()
 if OS.has_feature("web"):JavaScriptBridge.download_buffer(content.to_utf8_buffer(),"crossroads-playtest-report.txt","text/plain");notice.text="Download requested — check Downloads before leaving.";return
 dialog=FileDialog.new();dialog.access=FileDialog.ACCESS_FILESYSTEM;dialog.file_mode=FileDialog.FILE_MODE_SAVE_FILE;dialog.current_file="crossroads-playtest-report.txt";add_child(dialog)
 dialog.file_selected.connect(func(path:String):var f:=FileAccess.open(path,FileAccess.WRITE);if f!=null:f.store_string(content);notice.text="Report saved.";dialog.queue_free())
 dialog.popup_centered(Vector2i(800,500))
func confirm_clear()->void:
 var confirm:=ConfirmationDialog.new();confirm.dialog_text="Clear the notes on this device? Downloaded reports are kept. This does not change your player profile.";add_child(confirm)
 confirm.confirmed.connect(func():clear_notes();confirm.queue_free())
 confirm.canceled.connect(confirm.queue_free);confirm.popup_centered(Vector2i(620,180))
func clear_notes()->void:
 notes.clear()
 for edit in fields.values():edit.text=""
 dirty=false
 if FileAccess.file_exists(DRAFT):DirAccess.remove_absolute(DRAFT)
 notice.text="Notes cleared."
func _exit_tree()->void:
 if dirty:save_draft()
func _process(delta:float)->void:
 if dirty:
  save_timer-=delta
  if save_timer<=0:save_draft()
 var view:=get_viewport().get_visible_rect().size;var fit:=minf(1,minf((view.x-20)/1080,(view.y-20)/650));panel.scale=Vector2.ONE*fit;panel.position=(view-panel.size*fit)*.5
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:queue_free();get_viewport().set_input_as_handled()
