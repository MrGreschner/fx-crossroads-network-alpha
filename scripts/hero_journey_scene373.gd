extends "res://scripts/game.gd"
## Isolated courses reuse actual hero combat and mobile movement.
var course:RefCounted
var course_active=false
var course_preparing=false
var journey_id=""
var return_hero="ram"
var course_panel:PanelContainer
var course_label:Label
var course_button:Button
func _ready()->void:
 set_meta("fx_hero_quest",true)
 super._ready()
 call_deferred("begin_course")
func begin_course()->void:
 var plan:Dictionary=get_tree().root.get_meta("fx_hero_journey",{})
 journey_id=str(plan.get("id",""));return_hero=str(plan.get("hero","ram"))
 var u=load("res://scripts/hero_unlocks371.gd");var j=load("res://scripts/hero_journeys373.gd")
 if not j.eligible(legacy,journey_id):leave_course();return
 if not characters.has(return_hero) or not u.owned(legacy,return_hero):return_hero="ram"
 selected_character=return_hero;course_preparing=true;super.start_run(false,"practice");course_preparing=false
 var spec:Dictionary=j.catalog()[journey_id]
 practice=false;mode="run";region_id="hero_journey";active_realm="hero_journey";adventure.setup("hero_journey")
 region={"name":str(spec.place),"size":[2000,1300],"spawn":[420,650],"gate":{"position":[-9000,-9000]},"boss":[-9000,-9000],"boss_level":99,"background":"path"}
 character_id=journey_id if bool(spec.loan) else return_hero;hero=characters[character_id].duplicate(true)
 level=10;highest_level=10;upgrade="base";mastery="base";health=max_health();bonus_health=0;bonus_damage=0;bonus_speed=0
 loadout.clear();inventory.clear();provisions.packed="";menu=""
 enemies.clear();bullets.clear();enemy_shots.clear();allies.clear();obstacles.clear();decorations.clear();ground_patches.clear();ground_index.invalidate()
 boss_spawned=true;boss_defeated=false;position_in_world=Vector2(420,650);level_cards.process_mode=Node.PROCESS_MODE_DISABLED;level_cards.panel.hide();level_cards.toast.hide()
 course=load("res://scripts/hero_trial373.gd").new();course.setup(self,spec)
 course_active=true;update_camera();mobile.reset_controls();message="";message_time=0
 var layer=CanvasLayer.new();layer.layer=18;add_child(layer)
 course_panel=PanelContainer.new();course_panel.position=Vector2(16,118);course_panel.size=Vector2(680,112);layer.add_child(course_panel)
 var box=VBoxContainer.new();course_panel.add_child(box);course_label=Label.new();course_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;course_label.add_theme_font_size_override("font_size",16);box.add_child(course_label)
 var row=HBoxContainer.new();box.add_child(row);course_button=Button.new();course_button.text="E • Interact / hold to repair";course_button.custom_minimum_size=Vector2(240,44);row.add_child(course_button)
 course_button.button_down.connect(func():Input.action_press("interact"));course_button.button_up.connect(func():Input.action_release("interact"))
 var exit=Button.new();exit.text="Leave journey";exit.custom_minimum_size=Vector2(130,44);row.add_child(exit);exit.pressed.connect(leave_course)
 presentation.window(str(characters[journey_id].name)+" • "+str(spec.title),"journey_intro")
 presentation.label(presentation.content,str(spec.place),20)
 for st in spec.stages:presentation.label(presentation.content,"• "+str(st.text),17)
 presentation.label(presentation.content,"WASD / joystick to move. Use your normal attacks. E or the on-screen button interacts; hold it to repair. Free retries. This isolated course consumes no supplies and awards no combat records.",16)
 presentation.button(presentation.content,"Begin journey",func():presentation.close())
 presentation.button(presentation.content,"Back to town",leave_course)
func _process(delta:float)->void:
 if course==null:
  if not course_preparing:super._process(delta)
  return
 if not course_active or presentation.page in ["journey_intro","journey_result"]:queue_redraw();return
 # Courses keep a fixed kit. Escape opens the usual menu; all objectives pause with it.
 super._process(delta)
 if not course_active or menu!="" or presentation.page!="" or session_menu.page!="":return
 course.step(minf(delta,.1));course_label.text=str(characters[journey_id].name)+" • "+course.status()
 course_panel.size.x=minf(680,maxf(300,VIEW.x-32));course_button.visible=course.interactive()
func handle_run(delta:float)->void:
 super.handle_run(delta)
func start_run(is_trial:bool,realm_id:String="grove")->void:
 if course!=null:return
 super.start_run(is_trial,realm_id)
func enter_region(id:String)->void:
 if course!=null:
  leave_course();return
 super.enter_region(id)
func start_training(_at:Vector2=Vector2(650,430))->void:
 if course!=null:return
 super.start_training(_at)
func maybe_spawn_boss()->void:pass
func can_stand_at(point:Vector2)->bool:
 if course==null:return super.can_stand_at(point)
 return course.passable(point,8 if adventure.combat.v110.small("solo") else 18)
func clear_of_obstacles(point:Vector2,padding:float=0)->bool:
 if course==null:return super.clear_of_obstacles(point,padding)
 return course.passable(point,maxf(0,(8 if adventure.combat.v110.small("solo") else 18)+padding))
func shot_path_clear(start:Vector2,finish:Vector2,flying:bool=false)->bool:
 if course==null:return super.shot_path_clear(start,finish,flying)
 for i in range(1,12):
  if not course.passable(start.lerp(finish,float(i)/12),0):return false
 return true
func fire(kind:String)->void:
 if course==null:super.fire(kind);return
 if not course_active:return
 var before=float(cooldowns.get(kind,0));var power=adventure.combat.held_cast.power(adventure.combat.held_cast.context.solo,hero[kind]) if adventure.combat.held_cast.context.has("solo") else 0.0
 super.fire(kind)
 if before<=0 and float(cooldowns.get(kind,0))>0:course.cast(kind,power)
func pulse()->void:
 if course==null:super.pulse();return
 if not course_active:return
 var before=float(cooldowns.special);super.pulse()
 if before<=0 and float(cooldowns.special)>0:course.cast("special",0)
func damage_enemy(index:int,amount:float)->void:
 if course!=null and index>=0 and index<enemies.size() and bool(enemies[index].get("journey_target",false)):
  course.hit(enemies[index],amount);return
 super.damage_enemy(index,amount)
func update_enemies(delta:float)->void:
 if course==null:super.update_enemies(delta);return
 var targets=[]
 for foe in enemies:
  if bool(foe.get("journey_target",false)):targets.append(foe)
 for foe in targets:enemies.erase(foe)
 super.update_enemies(delta)
 enemies.append_array(targets)
func finish_run(_won:bool,_abandoned:bool=false)->void:
 if course!=null:finish_course(false)
func finish_course(won:bool)->void:
 if not course_active:return
 if won and not course.completed:return
 course_active=false;Input.action_release("interact");course_panel.hide()
 var j=load("res://scripts/hero_journeys373.gd");var awarded=j.finish(legacy,journey_id) if won else false
 var duel=won and bool(course.spec.duel)
 presentation.window("HERO UNLOCKED" if awarded else "Personal duel ready" if duel else "Journey complete" if won else "Try again","journey_result")
 presentation.label(presentation.content,str(characters[journey_id].name)+(" is now permanently yours." if awarded else " invites you to the final personal duel." if duel else " • No supplies lost. Replay or return whenever you like."),21)
 if duel:presentation.button(presentation.content,"Begin personal duel",func():selected_character=return_hero;load("res://scripts/hero_unlocks371.gd").launch(self,journey_id))
 presentation.button(presentation.content,"Replay journey" if won else "Retry",func():get_tree().reload_current_scene())
 presentation.button(presentation.content,"Back to town",leave_course)
func leave_course()->void:
 Input.action_release("interact");course_active=false
 if legacy!=null:legacy.save()
 get_tree().root.set_meta("fx_hero",return_hero);get_tree().root.set_meta("fx_return_from_lobby",true)
 get_tree().change_scene_to_file("res://scenes/main.tscn")
