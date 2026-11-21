extends "res://scripts/arcade.gd"
## Isolated first-knockout duels using the same combat, hitboxes and mobile controls.
const Unlocks=preload("res://scripts/hero_unlocks371.gd")
var champion_id=""
var controller:RefCounted
var settled=false
var brain={"think":0.0,"wish":Vector2.ZERO,"warn":0.0,"pending":"","age":0.0}
func _ready()->void:
 set_meta("fx_champion_duel",true)
 super._ready()
 call_deferred("begin_trial")
func _draw()->void:
 super._draw()
 if not characters.has(champion_id) or not health.has("bot:0"):return
 draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
 var at=Vector2(get_viewport_rect().size.x*.5-180,108)
 draw_string(ThemeDB.fallback_font,at,str(characters[champion_id].name)+" • "+str(maxi(0,int(health["bot:0"])))+" / "+str(_max_hp("bot:0")),HORIZONTAL_ALIGNMENT_CENTER,360,16,Color("#ecd6a0"))
 draw_rect(Rect2(at+Vector2(0,7),Vector2(360,8)),Color("#203942"))
 draw_rect(Rect2(at+Vector2(0,7),Vector2(360*clampf(float(health["bot:0"])/maxf(1,_max_hp("bot:0")),0,1),8)),Color("#98c7ca"))
func _process(delta:float)->void:
 if presentation!=null and presentation.page in ["champion_intro","champion_result"]:queue_redraw();return
 super._process(delta)
func network_build(_owner:String)->Dictionary:
 return {"technique":false,"final_technique":false,"points":0,"crit_tier":0,"tuning":[0,0,0],"crown_damage":0}
func begin_trial()->void:
 var plan:Dictionary=get_tree().root.get_meta("fx_champion_trial",{})
 champion_id=str(plan.get("champion",""))
 if not Unlocks.ready(legacy,champion_id):_town();return
 selected_hero=str(plan.get("hero","ram"))
 if not characters.has(selected_hero) or not Unlocks.owned(legacy,selected_hero) or not preload("res://scripts/record_eligibility.gd").hero_allowed(self,selected_hero):selected_hero="ram"
 preferred_hero=selected_hero
 level_cards.process_mode=Node.PROCESS_MODE_DISABLED;level_cards.panel.hide();level_cards.toast.hide()
 _set_mode("arena");arena_map="sand";_sync_arena_pickers();_reset_connection()
 role="host";my_id="solo";host_id="solo";spectator_host=false
 roster.assign([{"id":"solo","name":"You"}]);_add_player("solo",0)
 bot_plan=[{"hero":"npc_sable","team":1}];bot_count=1
 opening_picker.button_pressed=false;no_items_picker.button_pressed=true;random_hero_picker.button_pressed=false;rule_picker.select(0)
 bots.sync_lobby();_start_match();control.hide()
 hero_ids["bot:0"]=champion_id;lobby_heroes["bot:0"]=champion_id
 for member in roster:
  if str(member.id)=="bot:0":member.name=str(characters[champion_id].name)
 FIELD=Rect2(Vector2.ZERO,Vector2(1400,1000));field_obstacles.clear();world_patches.clear();world_buildings.clear();world_decorations.clear();world_fountains.clear();world_terrain="path";art.path=preload("res://scripts/training_environment303.gd").texture("clay");_rebuild_grid();terrain_cache.reset()
 positions["solo"]=Vector2(440,500);positions["bot:0"]=Vector2(960,500);local_pos=positions.solo
 for id in positions:
  health[id]=_max_hp(str(id));levels[id]=10;inventory[id]=[];food_slots[id]="";attack_branch[id]="base";mastery_choice[id]="base"
 status_label.text="Champion duel • "+str(characters[champion_id].name)+" • First knockout wins"
 controller=preload("res://scripts/champion_brain374.gd").new();controller.setup(self,champion_id)
 start_countdown=0.0
 # Brief player-readable introduction, then a countdown starts on dismissal.
 presentation.window(str(characters[champion_id].name)+" • Champion duel","champion_intro")
 presentation.label(presentation.content,str(Unlocks.PLANS[champion_id][4]),20)
 presentation.label(presentation.content,"Opponent: "+str(controller.profile[1])+" • Difficulty "+["", "Introductory", "Challenging", "Advanced"][int(controller.profile[0])],17)
 presentation.label(presentation.content,"Win the first knockout. Level 10 base kits, no equipment or mastery upgrades. Retry as often as you like.",17)
 presentation.button(presentation.content,"Begin duel",func():start_countdown=3.0;presentation.close())
 presentation.button(presentation.content,"Back to town",_town)
func champion_step(delta:float)->void:
 if controller!=null:controller.step(delta)
func cast_champion(kind:String,aim:Vector2,target:Vector2)->void:
 var held=adventure.combat.held_cast
 if held.supports("bot:0",kind):held.begin("bot:0",kind,aim,target)
 else:_attack("bot:0",kind,aim,target)
func _hurt(id:String,amount:float,source:String="",melee_attacker:String="",cause:Dictionary={})->void:
 if settled:return
 super._hurt(id,amount,source,melee_attacker,cause)
 # Resolve local death first, including a simultaneous knockout: no ambiguous reward.
 if float(health.get(my_id,1))<=0:finish_trial(false)
 elif float(health.get("bot:0",1))<=0:finish_trial(true)
func finish_trial(won:bool)->void:
 if settled:return
 settled=true;started=false
 var granted=Unlocks.award(legacy,champion_id) if won else false
 presentation.window("CHAMPION UNLOCKED" if granted else "Duel won" if won else "Try again","champion_result")
 presentation.label(presentation.content,(str(characters[champion_id].name)+" is now permanently yours!") if granted else "Victory! This rematch does not award extra progression." if won else "No cost, no lost progress. Change your approach and try again.",21)
 presentation.button(presentation.content,"Rematch" if won else "Retry duel",func():get_tree().reload_current_scene())
 presentation.button(presentation.content,"Back to town / change hero",_town)
func end_match(_reason:String)->void:
 if not settled:finish_trial(false)
func legacy_results()->void:pass
func _track_card_progress()->void:pass
func _town()->void:
 started=false;legacy.save();set_process(true)
 get_tree().root.set_meta("fx_hero",selected_hero);get_tree().root.set_meta("fx_return_from_lobby",true)
 get_tree().change_scene_to_file("res://scenes/main.tscn")
