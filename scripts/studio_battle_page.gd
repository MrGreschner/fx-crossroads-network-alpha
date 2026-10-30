extends CanvasLayer
const UI=preload("res://scripts/studio_ui.gd")
var lab:Node
var panel:PanelContainer
var arena:Node
var status:Label
var chosen="workshop"
var count=1
var saved=false
func setup(owner:Node)->void:
 lab=owner;layer=79
 var shade=ColorRect.new();shade.color=Color("#071b26");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();panel.size=Vector2(1100,720);add_child(panel);UI.apply(panel)
 var col=VBoxContainer.new();panel.add_child(col);lab.workshop.label(col,"LIVE ENEMY BATTLE TEST",26)
 var row=HBoxContainer.new();col.add_child(row)
 var hero_choice=OptionButton.new();row.add_child(hero_choice)
 for name in ["Your Workshop hero","Practice melee ram","Practice ranged book"]:hero_choice.add_item(name)
 hero_choice.item_selected.connect(func(index:int):chosen=["workshop","ram","book"][index];restart())
 var number=SpinBox.new();number.min_value=1;number.max_value=4;number.value=1;row.add_child(number);number.value_changed.connect(func(value:float):count=int(value);restart())
 lab.workshop.button(row,"Retry battle",restart);lab.workshop.button(row,"Save test report",save_report);lab.workshop.button(row,"Back to Enemy Lab",queue_free)
 arena=preload("res://scripts/studio_battle.gd").new();arena.size_flags_vertical=Control.SIZE_EXPAND_FILL;arena.custom_minimum_size=Vector2(1000,440);col.add_child(arena)
 var movement=HBoxContainer.new();col.add_child(movement)
 for pair in [["Left",Vector2.LEFT],["Up",Vector2.UP],["Down",Vector2.DOWN],["Right",Vector2.RIGHT]]:
  var button=lab.workshop.button(movement,pair[0],func():pass);button.button_down.connect(func():arena.touch_direction=pair[1]);button.button_up.connect(func():arena.touch_direction=Vector2.ZERO)
 status=lab.workshop.label(col,"WASD to move • LMB / RMB / Space to attack • click the battlefield to focus. No profile progress.",15)
 restart()
func restart()->void:
 if is_instance_valid(arena):
  for actor in arena.runtimes:actor.queue_free()
 var p=lab.workshop.project.duplicate(true)
 if chosen!="workshop":
  p=preload("res://scripts/workshop_project.gd").fresh();p.hero.name="Practice ram" if chosen=="ram" else "Practice book";p.hero.primary.damage=18;p.hero.primary.heal=0;p.hero.primary.range=110 if chosen=="ram" else 500;p.hero.primary.cooldown=.6;p.hero.primary.style="melee" if chosen=="ram" else "projectile";p.hero.secondary.style="heal_wave";p.hero.special.style="block"
  p.hero.art=preload("res://scripts/studio_art249.gd").encoded("stone_apprentice" if chosen=="ram" else "prism_sprout")
 arena.setup(lab.enemy,p,count);arena.grab_focus();saved=false
func save_report()->void:
 var report={"date":Time.get_datetime_string_from_system(true),"enemy":lab.enemy.name,"hero":arena.hero.name,"count":count,"seconds":snappedf(arena.time,.1),"damage":snappedf(arena.damage,.1),"incoming":snappedf(arena.incoming,.1),"result":arena.result if not arena.result.is_empty() else "Test in progress"}
 lab.enemy.reports.append(report)
 preload("res://scripts/learning_store.gd").activity("Enemy battle report",str(lab.enemy.name))
 if lab.enemy.reports.size()>20:lab.enemy.reports.pop_front()
 lab.persist()
 if arena.time>=2:preload("res://scripts/studio_cycle.gd").test("enemy",lab.enemy,report)
 saved=true;status.text="Report saved in this enemy project. Download it to share your evidence."
func _process(_delta:float)->void:
 var view=get_viewport().get_visible_rect().size;panel.size=Vector2(1100,720);var factor=minf(1,minf((view.x-20)/panel.size.x,(view.y-20)/panel.size.y));panel.scale=Vector2.ONE*factor;panel.position=(view-panel.size*factor)*.5
func _input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:queue_free();get_viewport().set_input_as_handled()
