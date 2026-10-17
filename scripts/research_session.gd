extends CanvasLayer
## Volatile student playtesting overlay; reports are separate from saved player progress.
var frame:Control
var active=false
var discarding=false
var departing:Node
var panel:PanelContainer
var stats:Label
var toggle:Button
var samples:Array=[]
var timer=0.0
var checkpoints:Array=[]
func _ready()->void:
 layer=89;frame=Control.new();frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(frame);frame.draw.connect(func():
  var size=frame.get_viewport_rect().size;frame.draw_rect(Rect2(Vector2(3,3),size-Vector2(6,6)),Color("#66baff"),false,3)
 );process_mode=Node.PROCESS_MODE_ALWAYS
 toggle=Button.new();toggle.text="PLAYTEST MODE • F8";toggle.custom_minimum_size=Vector2(210,40);add_child(toggle);preload("res://scripts/top_button_style.gd").apply(toggle);toggle.pressed.connect(func():panel.visible=not panel.visible)
 panel=PanelContainer.new();panel.custom_minimum_size=Vector2(330,240);add_child(panel);preload("res://scripts/studio_ui.gd").apply(panel)
 var col=VBoxContainer.new();panel.add_child(col)
 var title=Label.new();title.text="PLAYTEST MODE";title.add_theme_font_size_override("font_size",22);col.add_child(title)
 var info=Label.new();info.text="Observe • reproduce • explain\nNormal combat. No saved progress.";col.add_child(info)
 stats=Label.new();stats.add_theme_font_size_override("font_size",15);col.add_child(stats)
 for pair in [["Record checkpoint",checkpoint],["Open playtest notebook",notebook],["Copy session evidence",copy_evidence],["Exit Playtest Mode • restore profile",finish]]:
  var b=Button.new();b.text=pair[0];b.custom_minimum_size.y=38;b.pressed.connect(pair[1]);col.add_child(b)
 hide()
func begin()->void:
 if get_tree().root.get_node("FXDevSession").active:return
 active=true;checkpoints.clear();samples.clear();show();panel.show()
func game()->Node:return get_tree().current_scene
func observation()->Dictionary:
 var g=game();var id=g.get("my_id")
 if id!=null:
  return {"hero":str(g.hero_ids.get(str(id),g.selected_hero)),"damage":float(g.contributions.get(str(id),{}).get("damage",0)),"kills":int(g.kills.get(str(id),0)),"mode":str(g.mode)}
 return {"hero":str(g.selected_character),"damage":float(g.dealt_damage),"kills":int(g.kills),"mode":str(g.mode)}
func report()->String:
 var g=game();var info=observation()
 return "Crossroads: Realms Beyond • Playtest Mode\n"+Time.get_datetime_string_from_system()+"\nScene: "+str(g.scene_file_path)+"\nMode: "+info.mode+" • Hero: "+info.hero+"\nFPS: "+str(Engine.get_frames_per_second())+"\nDamage: "+str(int(info.damage))+" • Kills: "+str(info.kills)+"\nCheckpoints:\n"+"\n".join(checkpoints)+"\nExplain expected vs observed behaviour, reproduction steps and suggested improvements in the notebook."
func checkpoint()->void:
 if checkpoints.size()>=30:checkpoints.pop_front()
 var info=observation();checkpoints.append(Time.get_time_string_from_system()+" • "+info.mode+" • FPS "+str(Engine.get_frames_per_second())+" • Damage "+str(int(info.damage))+" • Kills "+str(info.kills))
func copy_evidence()->void:preload("res://scripts/release_support.gd").copy_text(report())
func notebook()->void:
 var g=game();g.session_menu.open_notebook()
 var book=g.session_menu.get_node_or_null("PlaytestNotebook")
 if book!=null:
  book.notes["method"]=str(book.notes.get("method",""))+"\n"+report()
  if book.fields.has("method"):book.fields["method"].text=book.notes["method"]
  book.dirty=true
 panel.hide()
func finish()->void:
 if not active:return
 active=false;discarding=true;departing=game();hide();get_tree().root.set_meta("fx_show_main",true);get_tree().change_scene_to_file("res://scenes/main.tscn")
func _process(delta:float)->void:
 if discarding and is_instance_valid(game()) and game()!=departing:discarding=false;departing=null
 if not active:return
 frame.queue_redraw()
 var view=get_viewport().get_visible_rect().size
 toggle.position=Vector2(16,view.y-52)
 var fit=minf(1.0,minf((view.y-175)/maxf(panel.size.y,1),(view.x-32)/maxf(panel.size.x,1)))
 panel.scale=Vector2.ONE*fit;panel.position=Vector2(16,maxf(105,view.y-66-panel.size.y*fit))
 timer-=delta
 if timer<=0:
  timer=1;var fps=Engine.get_frames_per_second();samples.append(fps)
  if samples.size()>20:samples.pop_front()
  var low=fps
  for value in samples:low=mini(low,int(value))
  stats.text="FPS %d • recent low %d\nCheckpoints %d / 30 • F8 toggles this panel" % [fps,low,checkpoints.size()]
func _unhandled_input(event:InputEvent)->void:
 if active and event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F8:panel.visible=not panel.visible;get_viewport().set_input_as_handled()
