extends CanvasLayer
const UI=preload("res://scripts/studio_ui.gd")
const Project=preload("res://scripts/studio_enemy_project.gd")
var workshop:Node
var enemy:Dictionary
var panel:PanelContainer
var status:Label
var body:VBoxContainer
var transfer:Node
var upload_pose="idle"
var previews:Array=[]
var stat_controls:Dictionary={}
var replay_clock=0.0
func setup(owner:Node)->void:
 workshop=owner;layer=72;enemy=preload("res://scripts/studio_examples.gd").random_example("enemy")
 var restored=preload("res://scripts/profile_store.gd").read("user://fx_enemy_lab.json",func(v:Dictionary)->bool:return Project.validate(v).is_empty())
 if not restored.is_empty():enemy=restored
 var shade=ColorRect.new();shade.color=Color("#071b26");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();panel.size=Vector2(1040,680);add_child(panel);UI.apply(panel);UI.enter(panel)
 var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;panel.add_child(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll).form_controls=true
 body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)
 transfer=preload("res://scripts/studio_transfer.gd").new();add_child(transfer);transfer.received.connect(import_text);transfer.failed.connect(func(value:String):status.text=value)
 render()
func render()->void:
 workshop.clear(body);previews.clear();stat_controls.clear()
 if not enemy.has("special"):enemy.special=preload("res://scripts/workshop_project.gd").attack("summon")
 if not enemy.has("attack_count"):enemy.attack_count=2
 var head=HBoxContainer.new();body.add_child(head);workshop.label(head,"ENEMY LAB",26).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 UI.accent(workshop.button(head,"Battle test",test));workshop.button(head,"Finalize enemy",save_enemy);workshop.button(head,"Download",download);workshop.button(head,"Import",func():transfer.mode="json";transfer.choose());workshop.button(head,"Back",func():workshop.show_hub();queue_free())
 preload("res://scripts/studio_balance.gd").toggle(body,enemy,func():persist();render())
 if preload("res://scripts/education_access.gd").student():
  var learning_row=HBoxContainer.new();body.add_child(learning_row)
  workshop.button(learning_row,"Learning journal • record this design",func():workshop.game.legacy.learning_open())
  workshop.button(learning_row,"Finalize & submit to active module",func():status.text=preload("res://scripts/studio_finalize.gd").submit("enemy",enemy,str(enemy.name)))
 workshop.button(head,"Journey",func():save_enemy();load("res://scripts/studio_showcase.gd").open(workshop))
 var samples=HBoxContainer.new();body.add_child(samples);preload("res://scripts/studio_examples.gd").picker(samples,"enemy",func(value:Dictionary):enemy=value;persist();render());UI.accent(workshop.button(samples,"Clear / Start fresh",func():preload("res://scripts/studio_examples.gd").confirm(self,func():enemy=Project.fresh();persist();render())))
 var info=UI.card(body,"MEET YOUR OPPONENT","Design → choose decisions → battle → record evidence. Tests never award profile progress.")
 var name_edit=LineEdit.new();name_edit.text=enemy.name;name_edit.max_length=60;info.add_child(name_edit);name_edit.text_changed.connect(func(value:String):enemy.name=value;persist())
 var lore=LineEdit.new();lore.text=enemy.lore;lore.placeholder_text="A short description";info.add_child(lore);lore.text_changed.connect(func(value:String):enemy.lore=value;persist())
 var saved=OptionButton.new();saved.add_item("Open a saved enemy…");info.add_child(saved);var library=preload("res://scripts/studio_library.gd").load_data().enemies
 for key in library:saved.add_item(key)
 saved.item_selected.connect(func(index:int):if index>0:enemy=library[saved.get_item_text(index)].duplicate(true);persist();render())
 var stats=HBoxContainer.new();info.add_child(stats)
 for entry in [["Health","health",20,500],["Move speed","speed",40,230],["Body radius","radius",12,36]]:
  var group=VBoxContainer.new();stats.add_child(group);workshop.label(group,entry[0],15);var spin=SpinBox.new();spin.min_value=entry[2];spin.max_value=entry[3];spin.value=enemy[entry[1]];group.add_child(spin);stat_controls[entry[1]]=spin;spin.value_changed.connect(func(value:float):enemy[entry[1]]=value;persist())
 var art=UI.card(body,"FOUR POSES","Draw in-house, or upload a PNG. Copy idle into other poses, then change feet or arms.");var poses=HBoxContainer.new();art.add_child(poses)
 for pose in ["idle","walk1","walk2","attack"]:
  var group=VBoxContainer.new();poses.add_child(group);workshop.label(group,pose.capitalize(),15)
  if enemy.art.has(pose):
   var image=Image.new();image.load_png_from_buffer(Marshalls.base64_to_raw(enemy.art[pose]));var picture=TextureRect.new();picture.texture=ImageTexture.create_from_image(image);picture.custom_minimum_size=Vector2(64,64);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;group.add_child(picture)
  workshop.button(group,"Draw / edit",func():var editor=preload("res://scripts/studio_pixel_editor.gd").new();add_child(editor);editor.setup(enemy.art.get(pose,""),pose.capitalize(),enemy.art);editor.bind_live(["value","art",pose]);editor.saved.connect(func(value:String):enemy.art[pose]=value;persist();render()))
  workshop.button(group,"Upload PNG",func():upload_pose=pose;transfer.choose("png"))
  if pose!="idle":workshop.button(group,"Copy idle",func():if enemy.art.has("idle"):enemy.art[pose]=enemy.art.idle;persist();render())
 var brain=UI.card(body,"DECISIONS",enemy.behavior.name)
 var presets=preload("res://scripts/studio_behavior.gd").presets();var preset=OptionButton.new();preset.fit_to_longest_item=false;preset.add_item("Custom / edited decisions");brain.add_child(preset)
 for title in presets:
  preset.add_item(title)
  if enemy.behavior.program==presets[title]:preset.select(preset.item_count-1)
 preset.item_selected.connect(func(index:int):if index>0:enemy.behavior=preload("res://scripts/studio_behavior.gd").fresh();enemy.behavior.name=preset.get_item_text(index);enemy.behavior.program=presets[enemy.behavior.name];persist();render())
 workshop.button(brain,"Edit decision code / advanced lessons",func():workshop.open_behavior(enemy.behavior,func(value:Dictionary):enemy.behavior=value;persist();render()))
 var pick=OptionButton.new();pick.add_item("Choose saved enemy behaviour…");brain.add_child(pick);var brains=preload("res://scripts/studio_library.gd").load_data().behaviors
 for key in brains:
  if brains[key].kind=="enemy":pick.add_item(key)
 pick.item_selected.connect(func(index:int):if index>0:enemy.behavior=brains[pick.get_item_text(index)].duplicate(true);persist();render())
 var count_row=HBoxContainer.new();body.add_child(count_row);var count_title=workshop.label(count_row,"ATTACK SLOTS",20);count_title.autowrap_mode=TextServer.AUTOWRAP_OFF;count_title.custom_minimum_size.x=180
 var count=OptionButton.new();count.custom_minimum_size=Vector2(170,42);count_row.add_child(count)
 for n in [1,2,3]:count.add_item(str(n)+" attack"+("s" if n>1 else ""))
 count.select(enemy.attack_count-1);count.item_selected.connect(func(index:int):enemy.attack_count=index+1;persist();render())
 var row=HBoxContainer.new();body.add_child(row)
 for slot in ["primary","secondary","special"].slice(0,enemy.attack_count):attack_card(row,slot)
 status=workshop.label(body,"Saved test reports: "+str(enemy.reports.size())+" • Download the enemy file to share artwork, behaviour, attacks and reports.",15)
func persist()->void:
 if enemy.get("forced_balance",false):
  preload("res://scripts/studio_balance.gd").enforce_body(enemy,"health")
  for slot in ["primary","secondary","special"]:
   if enemy.has(slot):preload("res://scripts/studio_balance.gd").enforce_attack(enemy[slot],20)
 for key in stat_controls:
  if is_instance_valid(stat_controls[key]):stat_controls[key].set_value_no_signal(float(enemy[key]))
 if not Project.validate(enemy).is_empty():return
 var issue=preload("res://scripts/profile_store.gd").write("user://fx_enemy_lab.json",enemy)
 if issue!=OK and is_instance_valid(status):status.text="Could not save draft; download a backup."
func save_enemy()->void:
 var issue=preload("res://scripts/studio_library.gd").add_enemy(enemy);status.text="Saved to your enemy library." if issue.is_empty() else issue
 if issue.is_empty():preload("res://scripts/learning_store.gd").activity("Enemy saved",str(enemy.name))
func download()->void:
 var issue=Project.validate(enemy)
 if not issue.is_empty():status.text=issue;return
 workshop.write_download(JSON.stringify(enemy,"  "),enemy.name.validate_filename()+".enemy.json")
func import_text(text:String)->void:
 if transfer.mode=="png":
  var issue=preload("res://scripts/workshop_project.gd").png_error(Marshalls.base64_to_raw(text))
  if not issue.is_empty():status.text=issue;return
  enemy.art[upload_pose]=text;persist();render();return
 var value=JSON.parse_string(text);var issue=Project.validate(value)
 if not issue.is_empty():status.text=issue;return
 enemy=value;persist();render()
func test()->void:
 var issue=Project.validate(enemy)
 if not issue.is_empty():status.text=issue;return
 var page=preload("res://scripts/studio_battle_page.gd").new();add_child(page);page.setup(self)
func _process(_delta:float)->void:
 replay_clock+=_delta
 if replay_clock>3:
  replay_clock=0
  for preview in previews:
   if is_instance_valid(preview):
    for foe in preview.foes:foe.hp=float(foe.get("max_hp",200))
    if float(preview.hero.primary.charge)>0:preview.press("primary");preview.tick(float(preview.hero.primary.charge));preview.release("primary")
    else:preview.cast("primary")
 var view=get_tree().root.get_node("FXStudioPartner").editor_view();var factor=minf(1,minf((view.x-20)/1040,(view.y-20)/680));panel.scale=Vector2.ONE*factor;panel.position=(view-Vector2(1040,680)*factor)*.5

func attack_card(row:HBoxContainer,slot:String)->void:
 var card=UI.card(row,slot.to_upper(),"Choose a pattern, then tune it visually.");card.size_flags_horizontal=Control.SIZE_EXPAND_FILL;card.custom_minimum_size.x=285
 var patterns=preload("res://scripts/studio_options.gd").PATTERNS
 var options:Dictionary={}
 for family in patterns:
  for key in patterns[family]:options[key]=patterns[family][key]
 var choice=OptionButton.new();choice.fit_to_longest_item=false;card.add_child(choice)
 for key in options:choice.add_item(str(options[key]))
 var pattern=str(enemy[slot].get("build_pattern",enemy[slot].style));choice.select(maxi(0,options.keys().find(pattern)))
 choice.item_selected.connect(func(index:int):
  var type=str(options.keys()[index]);var a=preload("res://scripts/workshop_project.gd").attack("custom");preload("res://scripts/studio_options.gd").complete(a)
  for family in patterns:
   if patterns[family].has(type):a.category=family
  a.build_pattern=type;a.damage=8;a.heal=8 if type in ["heal_wave","heal_zone"] else 0;a.program=preload("res://scripts/studio_options.gd").program(a,type);enemy[slot]=a;persist();render())
 var preview=preload("res://scripts/workshop_arena.gd").new();card.add_child(preview);preview.custom_minimum_size=Vector2(285,170)
 var build=preload("res://scripts/workshop_project.gd").fresh();build.hero.primary=enemy[slot].duplicate(true);preview.begin(build,[],"Cluster");preview.locked_player=true;preview.cast("primary");previews.append(preview)
 workshop.label(card,str(enemy[slot].name)+" • "+str(int(enemy[slot].damage))+" damage • "+str(enemy[slot].cooldown)+"s cooldown",14)
 UI.accent(workshop.button(card,"Edit attack & animation",func():var page=preload("res://scripts/studio_lab.gd").new();add_child(page);page.setup(workshop,enemy[slot],func(a:Dictionary):enemy[slot]=a;persist();render())))
 var abilities=OptionButton.new();abilities.fit_to_longest_item=false;abilities.add_item("Saved custom ability…");card.add_child(abilities);var all=preload("res://scripts/studio_library.gd").load_data().abilities
 for key in all:abilities.add_item(key)
 abilities.item_selected.connect(func(index:int):if index>0:enemy[slot]=all[abilities.get_item_text(index)].duplicate(true);persist();render())
