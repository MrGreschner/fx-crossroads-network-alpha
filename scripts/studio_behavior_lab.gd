extends CanvasLayer
const UI=preload("res://scripts/studio_ui.gd")
const Behavior=preload("res://scripts/studio_behavior.gd")
var workshop:Node
var panel:PanelContainer
var behavior:Dictionary
var enemy:Dictionary=preload("res://scripts/studio_enemy_project.gd").fresh()
var code:CodeEdit
var source:CodeEdit
var preview:Node
var preview_box:VBoxContainer
var status:Label
var name_field:LineEdit
var kind_choice:OptionButton
var timer=0.0
var dirty=false
var replay=0.0
var callback:Callable
var transfer:Node
signal selected(value:Dictionary)
func setup(owner:Node,initial:Dictionary={},use:Callable=Callable())->void:
 workshop=owner;layer=73;callback=use;behavior=initial.duplicate(true) if not initial.is_empty() else preload("res://scripts/studio_examples.gd").random_example("behavior")
 if initial.is_empty():
  var restored=preload("res://scripts/profile_store.gd").read("user://fx_behavior_lab.json",func(v:Dictionary)->bool:return Behavior.validate(v).is_empty())
  if not restored.is_empty():behavior=restored
 var shade=ColorRect.new();shade.color=Color("#071b26");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();panel.size=Vector2(1140,680);add_child(panel);UI.apply(panel);UI.enter(panel)
 var body=VBoxContainer.new();panel.add_child(body);var row=HBoxContainer.new();body.add_child(row);workshop.label(row,"BEHAVIOUR LAB",26).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 workshop.button(row,"Save & use" if callback.is_valid() else "Finalize behaviour",save_behavior);workshop.button(row,"Download",download);workshop.button(row,"Import",func():transfer.choose());workshop.button(row,"Back",close)
 workshop.button(row,"Journey",func():save_behavior();load("res://scripts/studio_showcase.gd").open(workshop))
 var examples=HBoxContainer.new();body.add_child(examples);preload("res://scripts/studio_examples.gd").picker(examples,"behavior",load_example);UI.accent(workshop.button(examples,"Clear / Start fresh",func():preload("res://scripts/studio_examples.gd").confirm(self,func():load_example({"format":Behavior.FORMAT,"version":1,"name":"My new behaviour","kind":behavior.kind,"program":"move hold" if behavior.kind=="enemy" else "flight straight\naim direction\nimpact direct"}))))
 preload("res://scripts/studio_balance.gd").toggle(body,behavior,func():persist();status.text="Bounded decisions. The receiving Hero / Enemy Lab checks its combat budget.")
 if preload("res://scripts/education_access.gd").student():
  var learning_row=HBoxContainer.new();body.add_child(learning_row)
  workshop.button(learning_row,"Learning journal • record this design",func():workshop.game.legacy.learning_open())
  workshop.button(learning_row,"Finalize & submit to active module",func():status.text=preload("res://scripts/studio_finalize.gd").submit("behavior",behavior,str(behavior.name)))
 var split=HBoxContainer.new();split.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(split)
 var left=VBoxContainer.new();left.custom_minimum_size.x=285;split.add_child(left);var form=UI.card(left,"YOUR DECISION MODEL")
 name_field=LineEdit.new();name_field.text=behavior.name;form.add_child(name_field);name_field.text_changed.connect(func(value:String):behavior.name=value;persist())
 kind_choice=OptionButton.new();kind_choice.add_item("Enemy decisions");kind_choice.add_item("Ability flight decisions");kind_choice.select(0 if behavior.kind=="enemy" else 1);form.add_child(kind_choice)
 kind_choice.disabled=callback.is_valid();kind_choice.item_selected.connect(func(index:int):behavior=Behavior.fresh("enemy" if index==0 else "ability");code.text=behavior.program;apply_code())
 workshop.button(form,"Reset example code",func():code.text=Behavior.template(behavior.kind);apply_code())
 var saved=OptionButton.new();saved.fit_to_longest_item=false;saved.add_item("Open a saved behaviour…");form.add_child(saved)
 var library=preload("res://scripts/studio_library.gd").load_data().get("behaviors",{})
 for key in library:
  if not callback.is_valid() or library[key].kind==behavior.kind:saved.add_item(key)
 saved.item_selected.connect(func(index:int):if index>0:behavior=library[saved.get_item_text(index)].duplicate(true);name_field.text=behavior.name;kind_choice.select(0 if behavior.kind=="enemy" else 1);code.text=behavior.program;apply_code())
 var notes=UI.card(left,"AVAILABLE ACTIONS")
 workshop.label(notes,"Enemy: move chase / retreat / orbit / hold / patrol; use primary / secondary / special; guard on.\n\nAbility: flight straight / wave / homing / return / lob; aim direction / cursor / nearest; impact burst / direct.",15)
 workshop.label(notes,"Context: distance, health (%), time, cycle (0–6 seconds), charged (0/1), targets (0/1).\n\nUse if, elif, else and end. Loops use for step in 1–5. Code runs with fixed limits.",15)
 var right=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;split.add_child(right)
 var levels=OptionButton.new();for text in ["Level 1 • editable decisions","Level 2 • methods & vectors","Level 3 • classes & references"]:levels.add_item(text)
 right.add_child(levels)
 code=CodeEdit.new();code.text=behavior.program;code.custom_minimum_size.y=230;code.size_flags_vertical=Control.SIZE_EXPAND_FILL;code.gutters_draw_line_numbers=true;right.add_child(code)
 source=CodeEdit.new();source.editable=false;source.custom_minimum_size.y=230;source.size_flags_vertical=Control.SIZE_EXPAND_FILL;right.add_child(source);source.hide()
 levels.item_selected.connect(func(index:int):code.visible=index==0;source.visible=index>0;source.text=preload("res://scripts/studio_code_levels.gd").behavior(index+1,code.text))
 code.text_changed.connect(func():dirty=true;timer=.5)
 preview_box=VBoxContainer.new();preview_box.custom_minimum_size.y=260;right.add_child(preview_box)
 workshop.button(right,"Open full battle test",full_test)
 status=workshop.label(body,"",15)
 transfer=preload("res://scripts/studio_transfer.gd").new();add_child(transfer);transfer.received.connect(import_text);transfer.failed.connect(func(value:String):status.text=value)
 apply_code()
func apply_code()->bool:
 var candidate=behavior.duplicate(true);candidate.program=code.text;var issue=Behavior.validate(candidate)
 if not issue.is_empty():status.text="Not applied • "+issue;return false
 behavior=candidate;persist()
 if is_instance_valid(preview):preview.queue_free()
 if behavior.kind=="enemy":
  enemy.behavior=behavior.duplicate(true);preview=preload("res://scripts/studio_battle.gd").new();preview_box.add_child(preview);preview.custom_minimum_size=Vector2(650,250);preview.setup(enemy,workshop.project,1)
 else:
  preview=preload("res://scripts/workshop_arena.gd").new();preview_box.add_child(preview);preview.custom_minimum_size=Vector2(650,250)
  var p=preload("res://scripts/workshop_project.gd").fresh();p.hero.primary=preload("res://scripts/workshop_project.gd").attack("projectile");p.hero.primary.range=500;p.hero.primary.behavior=behavior;preview.begin(p,[],"Cluster");preview.cast("primary")
 status.text="Applied • click the preview, move with WASD and try the decisions in play.";return true
func persist()->void:
 if not Behavior.validate(behavior).is_empty():return
 var issue=preload("res://scripts/profile_store.gd").write("user://fx_behavior_lab.json",behavior)
 if issue!=OK:status.text="Could not save draft; download this behaviour."
func save_behavior()->void:
 if not apply_code():return
 var issue=preload("res://scripts/studio_library.gd").add_behavior(behavior);status.text="Saved to the behaviour library." if issue.is_empty() else issue
 if issue.is_empty():preload("res://scripts/learning_store.gd").activity("Behaviour saved",str(behavior.name))
 if issue.is_empty() and callback.is_valid():callback.call(behavior.duplicate(true));queue_free()
func download()->void:
 if apply_code():workshop.write_download(JSON.stringify(behavior,"  "),behavior.name.validate_filename()+".behavior.json")
func import_text(text:String)->void:
 var value=JSON.parse_string(text);var issue=Behavior.validate(value)
 if not issue.is_empty():status.text=issue;return
 if callback.is_valid() and value.kind!=behavior.kind:status.text="This slot needs a "+behavior.kind+" behaviour.";return
 behavior=value;name_field.text=value.name;kind_choice.select(0 if value.kind=="enemy" else 1);code.text=value.program;apply_code()
func full_test()->void:
 if behavior.kind!="enemy":status.text="Ability behaviours test here or in Hero Workshop; full battle tests are for enemies.";return
 if not apply_code():return
 var page=preload("res://scripts/studio_battle_page.gd").new();add_child(page);page.setup(self)
func close()->void:
 if not callback.is_valid():workshop.show_hub()
 queue_free()
func _process(delta:float)->void:
 var view=get_tree().root.get_node("FXStudioPartner").editor_view();panel.size=Vector2(1140,680);var factor=minf(1,minf((view.x-20)/panel.size.x,(view.y-20)/panel.size.y));panel.scale=Vector2.ONE*factor;panel.position=(view-panel.size*factor)*.5
 if dirty:timer-=delta;if timer<=0:dirty=false;apply_code()
 replay+=delta
 if replay>3 and is_instance_valid(preview) and behavior.kind=="ability":replay=0;preview.cast("primary")

func load_example(value:Dictionary)->void:
 if callback.is_valid() and value.kind!=behavior.kind:status.text="This edit slot needs a "+behavior.kind+" example.";return
 behavior=value.duplicate(true);name_field.text=behavior.name;kind_choice.select(0 if behavior.kind=="enemy" else 1);code.text=behavior.program;apply_code()
