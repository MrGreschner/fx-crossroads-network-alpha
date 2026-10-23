extends CanvasLayer
const Options=preload("res://scripts/studio_options.gd")
const UI=preload("res://scripts/studio_ui.gd")
const Project=preload("res://scripts/workshop_project.gd")
const Language=preload("res://scripts/studio_script.gd")
var audio=preload("res://scripts/studio_audio.gd").new()
var baseline:Dictionary={}
var after_preview:Control
var compare_preview:Control
var compare_panel:PanelContainer
var compare_clock=0.0
var compare_status:Label
var workshop:Node
var panel:PanelContainer
var gui:VBoxContainer
var code:CodeEdit
var advanced_source:CodeEdit
var preview:Control
var status:Label
var attack:Dictionary
var dirty=false
var timer=0.0
var replay_clock=0.0
var updating=false
var value_inputs:Dictionary={}
var build_type="spread"
var section=0
var category="ranged"
var auto_replay=true
var on_use:Callable
var generated=true
var section_tabs:TabBar
var draft_path="user://fx_ability_lab.json"
func setup(owner:Node,initial:Dictionary={},use:Callable=Callable())->void:
 add_child(audio)
 workshop=owner;on_use=use;layer=74 if use.is_valid() else 70;attack=Project.attack("custom");attack.name="Prism fan";attack.charge=1;Options.complete(attack);attack.category="ranged";attack.build_pattern="spread";attack.program=Options.program(attack,"spread")
 if not FileAccess.file_exists(draft_path) and initial.is_empty():attack=preload("res://scripts/studio_examples.gd").random_example("ability")
 var restored=preload("res://scripts/profile_store.gd").read(draft_path,func(v:Dictionary)->bool:return Project.validate_attack(v).is_empty())
 if not restored.is_empty():attack=restored
 if not initial.is_empty():
  attack=initial.duplicate(true)
  if attack.style!="custom":
   var pattern=str(attack.style);attack.style="custom";Options.complete(attack)
   attack.category="melee" if pattern in ["melee","spin","dash","chain"] else "summon" if pattern=="summon" else "control" if pattern in ["heal_wave","block","buff_zone","trap"] else "ranged"
   attack.build_pattern=pattern;attack.program=Options.program(attack,pattern)
 Options.complete(attack);category=attack.category;build_type=attack.build_pattern;generated=attack.program==Options.program(attack,build_type)
 baseline=attack.duplicate(true)
 var shade=ColorRect.new();shade.color=Color("#071c27");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();panel.size=Vector2(1140,680);add_child(panel);workshop.skin(panel);UI.enter(panel)
 var body=VBoxContainer.new();panel.add_child(body)
 var header=HBoxContainer.new();body.add_child(header);workshop.label(header,"ABILITY / ATTACK LAB",24).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 UI.accent(workshop.button(header,"Apply attack" if on_use.is_valid() else "Finalize ability",save_ability));workshop.button(header,"Download ability",download);workshop.button(header,"Back to Studio",func():
  if not on_use.is_valid():workshop.show_hub()
  queue_free())
 workshop.button(header,"Journey",func():save_ability();load("res://scripts/studio_showcase.gd").open(workshop))
 var examples=HBoxContainer.new();body.add_child(examples);preload("res://scripts/studio_examples.gd").picker(examples,"ability",load_example);UI.accent(workshop.button(examples,"Clear / Start fresh",func():preload("res://scripts/studio_examples.gd").confirm(self,clear_draft)))
 preload("res://scripts/studio_balance.gd").toggle(body,attack,func():apply_code();render_gui())
 if preload("res://scripts/education_access.gd").student():
  var learning_row=HBoxContainer.new();body.add_child(learning_row)
  workshop.button(learning_row,"Learning journal • record this design",func():workshop.game.legacy.learning_open())
  workshop.button(learning_row,"Freeze source for module",func():if apply_code():status.text=preload("res://scripts/studio_finalize.gd").submit("ability",attack,str(attack.name)))
 workshop.button(body,"Code playground • loops, targets & tests",func():var lab=preload("res://scripts/structured_lab.gd").new();add_child(lab);lab.setup(workshop,Callable(),func(source:String):attack.forced_balance=false;updating=true;code.text=source;updating=false;attack.style="custom";apply_code()))
 var split=HSplitContainer.new();split.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(split)
 var scroll=ScrollContainer.new();scroll.custom_minimum_size.x=375;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;split.add_child(scroll)
 gui=VBoxContainer.new();gui.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(gui);preload("res://scripts/touch_list_scroll.gd").attach(scroll).form_controls=true
 var right=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;split.add_child(right)
 var levels=OptionButton.new();right.add_child(levels)
 for title in ["Advanced code • Level 1: decisions","Level 2: methods & physics","Level 3: classes & references"]:levels.add_item(title)
 levels.item_selected.connect(func(index:int):code.visible=index==0;advanced_source.visible=index>0;advanced_source.text=preload("res://scripts/studio_code_levels.gd").ability(index+1,code.text))
 workshop.label(right,"LIVE CODE",21).add_theme_color_override("font_color",Color("#edcf91"))
 workshop.label(right,"Edit an instruction. Watch the idea become an attack.",14)
 code=CodeEdit.new();code.custom_minimum_size.y=170;code.size_flags_vertical=Control.SIZE_EXPAND_FILL;code.text=attack.program;code.gutters_draw_line_numbers=true;
 var highlighter=CodeHighlighter.new();highlighter.number_color=Color("#f3c889");highlighter.symbol_color=Color("#b8bfd6")
 for keyword in ["let","repeat","for","in","if","elif","else","end","emit","charged","targets"]:highlighter.add_keyword_color(keyword,Color("#95d9e3"))
 highlighter.add_color_region("#","",Color("#92a994"),true);code.syntax_highlighter=highlighter
 code.add_theme_font_size_override("font_size",15);right.add_child(code)
 advanced_source=CodeEdit.new();advanced_source.editable=false;advanced_source.custom_minimum_size.y=170;advanced_source.size_flags_vertical=Control.SIZE_EXPAND_FILL;right.add_child(advanced_source);advanced_source.hide()
 code.text_changed.connect(func():if not updating:dirty=true;timer=.45;generated=false)
 preview=preload("res://scripts/workshop_arena.gd").new();preview.custom_minimum_size=Vector2(610,300);preview.size_flags_vertical=Control.SIZE_EXPAND_FILL;preview.size_flags_stretch_ratio=2;right.add_child(preview);preview.custom_minimum_size=Vector2(610,300)
 var actions=HBoxContainer.new();right.add_child(actions);workshop.button(actions,"Replay",replay);workshop.button(actions,"Before / after",open_compare);workshop.button(actions,"Code notes",lesson);workshop.button(actions,"Attack frames",animation_editor)
 var controls=HBoxContainer.new();right.add_child(controls)
 var toggle=CheckButton.new();toggle.text="Interactive test";controls.add_child(toggle);toggle.toggled.connect(func(value:bool):auto_replay=not value;preview.locked_player=not value;preview.touch_direction=Vector2.ZERO;preview.cancel_holds();if not value:replay())
 for pair in [["←",Vector2.LEFT],["↑",Vector2.UP],["↓",Vector2.DOWN],["→",Vector2.RIGHT]]:
  var b=workshop.button(controls,pair[0],func():pass);b.button_down.connect(func():auto_replay=false;toggle.set_pressed_no_signal(true);preview.locked_player=false;preview.touch_direction=pair[1]);b.button_up.connect(func():preview.touch_direction=Vector2.ZERO)
 workshop.label(right,"Interactive: WASD / arrows to move • mouse or touch to aim • hold LMB to charge.",13)
 status=workshop.label(body,"",15);section_tabs=TabBar.new();gui.add_child(section_tabs);render_gui();apply_code();baseline=attack.duplicate(true)
func render_gui()->void:
 workshop.clear(gui);value_inputs.clear()
 workshop.label(gui,"BUILD YOUR ATTACK",21).add_theme_color_override("font_color",Color("#edcf91"))
 section_tabs=TabBar.new();gui.add_child(section_tabs)
 for title in ["Build","Shape","Power","Effects","Sound"]:section_tabs.add_tab(title)
 section_tabs.current_tab=section;section_tabs.tab_changed.connect(func(index:int):section=index;render_gui())
 if section==0:
  var name_edit=LineEdit.new();name_edit.text=attack.name;name_edit.placeholder_text="Ability name";name_edit.max_length=60;gui.add_child(name_edit);name_edit.text_changed.connect(func(value:String):attack.name=value;dirty=true;timer=.45)
  var brains=OptionButton.new();brains.fit_to_longest_item=false;brains.add_item("Flight behaviour • standard");gui.add_child(brains)
  var library=preload("res://scripts/studio_library.gd").load_data().behaviors
  for key in library:
   if library[key].kind=="ability":brains.add_item(key)
  brains.item_selected.connect(func(index:int):
   if index==0:attack.erase("behavior")
   else:attack.behavior=library[brains.get_item_text(index)].duplicate(true)
   apply_code())
  workshop.button(gui,"Create flight behaviour",func():workshop.open_behavior(preload("res://scripts/studio_behavior.gd").fresh("ability"),func(value:Dictionary):attack.behavior=value;apply_code();render_gui()))
  select("Attack family","category",Options.CATEGORIES,func():category=attack.category;build_type=Options.PATTERNS[category].keys()[0];rebuild();render_gui())
  var picker=choice("Behaviour",build_type,Options.PATTERNS[category]);picker.item_selected.connect(func(i:int):build_type=str(Options.PATTERNS[category].keys()[i]);rebuild();render_gui())
  var charged=CheckButton.new();charged.text="Hold to charge • release to cast";charged.button_pressed=float(attack.charge)>0;gui.add_child(charged);charged.toggled.connect(func(value:bool):attack.charge=1.0 if value else 0.0;replace_variable("charge",attack.charge);render_gui())
  if float(attack.charge)>0:
   numeric("Charge time (seconds)","charge",Project.LIMITS.charge)
   select("Charge animation","charge_visual",Options.CHARGES)
   select("What charging improves","charge_effect",preload("res://scripts/studio_charge.gd").EFFECTS)
   var effects={}
   for key in Project.STATUS:effects[key]="No extra status" if key=="none" else key.capitalize()
   select("Extra effect at full charge","max_charge_status",effects)
   if attack.charge_visual=="custom":workshop.button(gui,"Draw charge-up frames",func():animation_editor("charge_animation"))
  var tint=ColorPickerButton.new();tint.color=Color(attack.color);tint.custom_minimum_size.y=44;gui.add_child(tint);tint.color_changed.connect(func(value:Color):attack.color="#"+value.to_html(false);apply_code())
  workshop.button(gui,"Rebuild code from these choices",rebuild)
  workshop.label(gui,"This resets hand-edited instructions. Shape and power controls keep their values; code edits remain until you rebuild.",14)
 elif section==1:
  if category=="melee":
   numeric("Reach from hero","range",Project.LIMITS.range);numeric("Arc (360° = full circle)","melee_arc",Options.NUMBERS.melee_arc)
   select("Strike animation","melee_visual",Options.MELEE)
   if attack.melee_visual=="custom":workshop.button(gui,"Draw strike frames",animation_editor)
  elif category=="ranged":
   select("Projectile artwork","projectile_graphic",Options.PROJECTILES)
   if attack.projectile_graphic=="custom":workshop.button(gui,"Draw projectile frames",animation_editor)
   select("Flight path","projectile_motion",Options.MOTIONS);select("Destination","target_mode",Options.AIM);select("Aim guide","aim_guide",Options.AIM_GUIDES)
   numeric("Travel range","range",Project.LIMITS.range);numeric("Flight speed","speed",Project.LIMITS.speed);numeric("Projectile count","count",Project.LIMITS.count);numeric("Spread (degrees)","spread",Options.NUMBERS.spread)
   if attack.projectile_motion=="lob":numeric("Landing radius","radius",Project.LIMITS.radius)
   var burst=CheckButton.new();burst.text="Burst on impact / destination";burst.button_pressed=attack.impact_burst;gui.add_child(burst);burst.toggled.connect(func(value:bool):attack.impact_burst=value;apply_code())
  elif category=="summon":
   select("Minion look","minion_graphic",Options.MINIONS)
   if attack.minion_graphic=="custom":workshop.button(gui,"Draw minion image",edit_minion)
   select("Minion attack","minion_attack",Options.MINION_ATTACKS)
   numeric("Maximum summoned","count",Project.LIMITS.count);numeric("Minion health","minion_health",Options.NUMBERS.minion_health);numeric("Minion speed","minion_speed",Options.NUMBERS.minion_speed);numeric("Attack interval (s)","minion_interval",Options.NUMBERS.minion_interval);numeric("Lifetime (seconds)","duration",Project.LIMITS.duration)
  else:
   select("Placement","target_mode",Options.AIM);select("Aim guide","aim_guide",Options.AIM_GUIDES)
   numeric("Placement range","range",Project.LIMITS.range);numeric("Area radius","radius",Project.LIMITS.radius);numeric("Duration (seconds)","duration",Project.LIMITS.duration)
   if build_type=="buff_zone":select("Ally aura bonus","buff",Options.BUFFS)
 elif section==2:
  numeric("Damage per hit","damage",Project.LIMITS.damage);numeric("Ally healing","heal",Project.LIMITS.heal);numeric("Life steal (%)","lifesteal",Options.NUMBERS.lifesteal);numeric("Cooldown (seconds)","cooldown",Project.LIMITS.cooldown)
  workshop.label(gui,"Damage and healing are separate: projectiles can heal an ally they touch. Summons use these values per attack or healing pulse. Strong effects need a trade-off.",14)
 elif section==3:
  var opts={}
  for value in Project.STATUS:opts[value]=value.capitalize()
  select("On-hit status","status",opts);numeric("Status duration (s)","status_duration",Project.LIMITS.status_duration);numeric("Status damage / s","status_damage",Project.LIMITS.status_damage)
  workshop.button(gui,"Custom attack animation",animation_editor);workshop.button(gui,"How code works • field notes",lesson)
  workshop.label(gui,"Stun stops movement and attacks. Slow reduces movement. Burn, poison and bleed deal damage over time. Custom frames travel with your portable ability file.",14)
 else:
  workshop.label(gui,"SOUND DESIGN",21)
  workshop.label(gui,"Upload an original effect from BandLab or FL Studio. WAV / MP3 • up to 4 seconds. BandLab WAV exports are prepared automatically. Audio travels with your ability and hero files.",14)
  workshop.label(gui,str(attack.get("sound",{}).get("name","No sound attached")),16)
  var examples=OptionButton.new();examples.add_item("Start with an example sound…");gui.add_child(examples)
  for sound_name in ["swing","shot","heal","magic","flame","water","metal","bow"]:examples.add_item(sound_name.capitalize())
  examples.item_selected.connect(func(index:int):
   if index==0:return
   attack.sound=preload("res://scripts/studio_audio.gd").example(examples.get_item_text(index).to_lower());apply_code();render_gui())
  workshop.button(gui,"Upload sound",func():audio.choose(func(value:Dictionary,issue:String):
   if not issue.is_empty():status.text=issue;return
   attack.sound=value;apply_code();render_gui()))
  if not attack.get("sound",{}).is_empty():
   workshop.button(gui,"Listen",func():audio.play_sound(attack.sound))
   for spec in [["Level (dB)","volume_db",-36,-6,.5],["Pitch / playback speed","pitch",.5,2,.05]]:
    workshop.label(gui,spec[0],14)
    var spin=SpinBox.new();spin.min_value=spec[2];spin.max_value=spec[3];spin.step=spec[4];spin.value=attack.sound[spec[1]];gui.add_child(spin)
    var field:String=spec[1];spin.value_changed.connect(func(value:float):attack.sound[field]=value;apply_code())
   workshop.button(gui,"Remove sound",func():attack.erase("sound");apply_code();render_gui())
  workshop.button(gui,"Audio production notes",func():UI.lesson(self,"MAKE THE ACTION AUDIBLE","Build a short sound that explains the action.",[{"title":"Sound supports action","body":"Anticipation: a rising tone can announce charging. Impact: a short transient makes contact clear. Tail: leave room for other players’ sounds.

In BandLab or FL Studio, trim silence, fade the start/end to avoid clicks, and export a short WAV or MP3. Begin at a quiet level. Compare your effect with the animation; explain how rhythm, pitch and texture support your character.

BandLab web: Project → Download → Mixdown As → WAV. Use Music Studio to audition background tracks in realms. A clean game capture in Media mode is useful for scoring music. Use OBS for video recording. The global Sound mute also mutes custom effects."}]))
func select(caption:String,key:String,options:Dictionary,after:Callable=Callable())->void:
 var option=choice(caption,str(attack[key]),options)
 option.item_selected.connect(func(index:int):attack[key]=options.keys()[index];apply_code();if after.is_valid():after.call())
func numeric(caption:String,key:String,bounds:Array)->void:
 workshop.label(gui,caption,15)
 var spin=SpinBox.new();spin.min_value=bounds[0];spin.max_value=bounds[1];spin.step=bounds[2];spin.value=attack[key];spin.size_flags_horizontal=Control.SIZE_EXPAND_FILL;spin.custom_minimum_size.y=42;gui.add_child(spin);value_inputs[key]=spin
 spin.value_changed.connect(func(value:float):attack[key]=value;if key=="count" and generated:rebuild()
 elif Language.VARIABLES.has(key):replace_variable(key,value)
 elif key=="spread" and generated:rebuild()
 else:apply_code())
func rebuild()->void:
 attack.build_pattern=build_type;attack.program=Options.program(attack,build_type);updating=true;code.text=attack.program;updating=false;generated=true;apply_code()
func edit_minion()->void:
 var editor=preload("res://scripts/studio_pixel_editor.gd").new();add_child(editor);editor.setup(str(attack.get("minion_image","")),"Minion");editor.bind_live(["value","minion_image"])
 editor.saved.connect(func(encoded:String):attack.minion_image=encoded;apply_code())
func replace_variable(key:String,value:float)->void:
 if code.text.begins_with("# @structured"):return
 var lines=code.text.split("\n");var found=false
 for i in lines.size():
  if lines[i].strip_edges().begins_with("let "+key+" ="):lines[i]="let "+key+" = "+str(value);found=true;break
 if not found:lines.insert(0,"let "+key+" = "+str(value))
 updating=true;code.text="\n".join(lines);updating=false;apply_code()
func apply_code()->bool:
 var compiled=Language.compile(code.text)
 if not compiled.error.is_empty():status.text="NOT APPLIED • "+compiled.error;status.modulate=Color("#f3ad97");return false
 attack.program=code.text
 for key in compiled.variables:
  if attack.has(key):attack[key]=compiled.variables[key]
  if value_inputs.has(key):value_inputs[key].set_value_no_signal(attack[key])
 if attack.get("forced_balance",false):
  preload("res://scripts/studio_balance.gd").enforce_attack(attack)
  updating=true;code.text=attack.program;updating=false
  for key in value_inputs:
   if attack.has(key):value_inputs[key].set_value_no_signal(attack[key])
 var issue=Project.validate_attack(attack)
 if not issue.is_empty():status.text=issue;return false
 var save_error=preload("res://scripts/profile_store.gd").write(draft_path,attack)
 if save_error!=OK:status.text="Draft save failed. Download your ability.";return false
 status.text="Valid • "+str(compiled.instructions.size())+" top-level instructions • replay shows a fully charged cast.";status.modulate=Color("#b5e1bb");replay();return true
func replay()->void:
 var issue=Project.validate_attack(attack)
 if not issue.is_empty():return
 var p=Project.fresh();p.hero.primary=attack.duplicate(true);var old_pos=preview.player;var old_aim=preview.aim_point;preview.begin(p,[],"Cluster");preview.locked_player=auto_replay
 if not auto_replay:preview.player=old_pos;preview.aim_point=old_aim;preview.aim=(old_aim-old_pos).normalized()
 else:preview.player=Vector2(420,270) if category=="melee" else Vector2(180,270);preview.aim=Vector2.RIGHT;preview.aim_point=Vector2(520,270)
 if auto_replay:
  if float(attack.charge)>0:preview.press("primary")
  else:preview.cast("primary")
 replay_clock=0
func save_ability()->void:
 if not apply_code():return
 if on_use.is_valid():on_use.call(attack.duplicate(true));queue_free();return
 var issue=preload("res://scripts/studio_library.gd").add_ability(attack)
 if issue.is_empty():preload("res://scripts/learning_store.gd").activity("Ability saved",str(attack.name))
 status.text="Saved. Choose Custom • "+str(attack.name)+" in any Hero Workshop ability." if issue.is_empty() else issue
func download()->void:
 if not apply_code():return
 workshop.write_download(JSON.stringify({"format":"fx-crossroads-ability","version":1,"attack":attack},"  "),str(attack.name).validate_filename()+".ability.json")
func animation_editor(slot:String="animation")->void:
 var page=preload("res://scripts/studio_frames.gd").new();add_child(page);page.setup(self,slot)
func edit_frame(index:int,dialog:Node,slot:String="animation")->void:
 # The pixel editor can outlive the animation dialog (closed by Escape).
 if is_instance_valid(dialog):dialog.hide()
 var dialog_ref=weakref(dialog)
 var frames:Array=attack.get(slot,[]);var original=str(frames[index]) if index<frames.size() else str(frames.back()) if not frames.is_empty() else ""
 var editor=preload("res://scripts/studio_pixel_editor.gd").new();add_child(editor);editor.setup(original,"Attack frame "+str(index+1));editor.bind_live(["value",slot,index])
 editor.tree_exited.connect(func():
  var window=dialog_ref.get_ref()
  if is_instance_valid(window) and not window.is_queued_for_deletion():window.show()
 )
 editor.saved.connect(func(encoded:String):
  if not attack.has(slot):attack[slot]=[]
  if index<attack[slot].size():attack[slot][index]=encoded
  else:attack[slot].append(encoded)
  apply_code()
  var window=dialog_ref.get_ref()
  if is_instance_valid(window):window.queue_free()
  animation_editor(slot)
 )
func lesson()->void:
 UI.lesson(self,"CODE FIELD NOTES","Learn the building blocks by changing an attack you can see.",preload("res://scripts/studio_lessons.gd").code())
func _process(delta:float)->void:
 if is_instance_valid(compare_panel):
  compare_clock+=delta
  if compare_preview.holds.has("primary") and compare_clock>=float(baseline.charge):compare_preview.release("primary")
  if after_preview.holds.has("primary") and compare_clock>=float(attack.charge):after_preview.release("primary")
  compare_status.text="BEFORE: %.0f damage / %d hits / %.0f healed    •    AFTER: %.0f damage / %d hits / %.0f healed" % [compare_preview.damage,compare_preview.hits,compare_preview.healing,after_preview.damage,after_preview.hits,after_preview.healing]
  if compare_clock>5:restart_compare()
  var compare_view=get_tree().root.get_node("FXStudioPartner").editor_view();var compare_fit=minf(1,minf((compare_view.x-24)/1100,(compare_view.y-24)/620));compare_panel.size=Vector2(1100,620);compare_panel.scale=Vector2.ONE*compare_fit;compare_panel.position=(compare_view-compare_panel.size*compare_fit)*.5
  return
 var view=get_tree().root.get_node("FXStudioPartner").editor_view();var factor=minf(1,minf((view.x-16)/1140,(view.y-16)/680));panel.size=Vector2(1140,680);factor=minf(1,minf((view.x-16)/panel.size.x,(view.y-16)/panel.size.y));panel.scale=Vector2.ONE*factor;panel.position=(view-panel.size*factor)*.5
 if dirty:timer-=delta;if timer<=0:dirty=false;apply_code()
 replay_clock+=delta
 if auto_replay and preview.holds.has("primary") and replay_clock>=float(attack.charge):preview.release("primary")
 if auto_replay and replay_clock>5:replay()

func choice(caption:String,value:String,options:Dictionary)->OptionButton:
 workshop.label(gui,caption,15)
 var option=OptionButton.new();option.fit_to_longest_item=false;option.custom_minimum_size=Vector2(220,44);option.size_flags_horizontal=Control.SIZE_EXPAND_FILL;gui.add_child(option)
 for key in options:option.add_item(str(options[key]))
 option.select(maxi(0,options.keys().find(value)));return option

func open_compare()->void:
 if is_instance_valid(compare_panel):return
 panel.hide();preview.set_process(false)
 compare_panel=PanelContainer.new();add_child(compare_panel);workshop.skin(compare_panel);compare_panel.size=Vector2(1100,620);UI.apply(compare_panel);UI.enter(compare_panel)
 var box=VBoxContainer.new();compare_panel.add_child(box)
 workshop.label(box,"BEFORE / AFTER • test one change",24)
 var note=workshop.label(box,"Same targets and aim. Predict the result, change one variable, then compare damage and hits.",16);note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var labels=HBoxContainer.new();box.add_child(labels)
 for title in ["BEFORE • pinned original","AFTER • your current attack"]:
  var label=workshop.label(labels,title,19);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var previews=HBoxContainer.new();previews.size_flags_vertical=Control.SIZE_EXPAND_FILL;box.add_child(previews)
 compare_preview=preload("res://scripts/workshop_arena.gd").new();previews.add_child(compare_preview);compare_preview.custom_minimum_size=Vector2(500,300);compare_preview.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 after_preview=preload("res://scripts/workshop_arena.gd").new();previews.add_child(after_preview);after_preview.custom_minimum_size=Vector2(500,300);after_preview.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 compare_status=workshop.label(box,"",17)
 var row=HBoxContainer.new();box.add_child(row)
 workshop.button(row,"Pin current as baseline",func():baseline=attack.duplicate(true);restart_compare())
 workshop.button(row,"Run both",restart_compare)
 workshop.button(row,"Back to editing",func():compare_panel.queue_free();panel.show();preview.set_process(true);replay())
 restart_compare()
func restart_compare()->void:
 for pair in [[compare_preview,baseline],[after_preview,attack]]:
  var arena:Control=pair[0];var definition:Dictionary=pair[1];var project=Project.fresh();project.hero.primary=definition.duplicate(true);arena.begin(project,[],"Cluster");arena.locked_player=true
  arena.player=Vector2(420,270) if str(definition.category)=="melee" else Vector2(180,270);arena.aim=Vector2.RIGHT;arena.aim_point=Vector2(520,270)
  if float(definition.charge)>0:arena.press("primary")
  else:arena.cast("primary")
 auto_replay=true;replay();compare_clock=0

func load_example(value:Dictionary)->void:
 attack=value.duplicate(true);Options.complete(attack);category=attack.category;build_type=attack.build_pattern;generated=true;updating=true;code.text=attack.program;updating=false;render_gui();apply_code();baseline=attack.duplicate(true)
func clear_draft()->void:
 var fresh=Project.attack("custom");fresh.name="My new attack";Options.complete(fresh);fresh.program=Options.program(fresh,"projectile");load_example(fresh)
