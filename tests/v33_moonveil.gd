extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.selected_character="elara";game.start_run(false,"moonveil");game.obstacles.clear();game.build_scenery();game.position_in_world=Vector2(2000,1800);game.enemies.clear()
 check(game.characters.size()>=23 and game.decorations.size()==100,"23 heroes and detailed realm")
 var combat=game.adventure.combat
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,20);combat.step_projectiles(.4)
 check(combat.projectiles.size()==2 and combat.projectiles[0].damage==13,"lance splits with reduced damage")
 combat.projectiles.clear();game.adventure.spawn("mask_duelist",Vector2(2075,1800),500,false);combat.cast("solo",game.hero.primary,Vector2.RIGHT,20);combat.step_projectiles(.15)
 check(game.enemies[0].hp==480,"lance damages before splitting")
 game.enemies.clear();game.kills=36;game.maybe_spawn_boss();var boss:Dictionary=game.enemies[0];game.position_in_world=boss.pos-Vector2(250,0);var before:Vector2=boss.pos;boss.skill_timer=0;game.adventure.step(.1)
 check(boss.type=="mirror_marquis" and boss.hp==1200 and boss.pos!=before,"mobile marquis spawns")
 check(game.adventure.warnings.size()>0,"boss telegraphed dash")
 boss.skill_timer=0;boss.skill_step=1;combat.projectiles.clear();game.adventure.step(.01);check(combat.projectiles.size()>=3,"boss prism fan")
 game.hero=game.characters.drum;game.level=5;check(combat.war_multiplier("solo")==1.08,"solo drum aura");var old_hp:float=boss.hp;game.damage_enemy(0,100);check(is_equal_approx(old_hp-boss.hp,108),"aura boosts actual damage")
 for voice in game.journey.voices:voice.stop()
 game.queue_free();await process_frame
 var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party.selected_hero="drum";party._set_mode("defense");party._solo();party._add_player("b",1);party.hero_ids.b="elara";party.health.b=105;party.positions.b=party.positions.solo+Vector2(100,0);party.levels.solo=5
 check(party.adventure.combat.war_multiplier("b")==1.08,"ally aura")
 party.positions.b+=Vector2(300,0);check(party.adventure.combat.war_multiplier("b")==1,"aura range")
 party.positions.b=party.positions.solo+Vector2(100,0);party.mode="arena";party.pvp_rule="ffa";check(party.adventure.combat.war_multiplier("b")==1,"rivals excluded")
 party.pvp_rule="teams";party.teams.b=party.teams.solo;check(party.adventure.combat.war_multiplier("b")==1.08,"PvP teammates included")
 party.hero_ids.b="drum";party.levels.b=5;check(party.adventure.combat.war_multiplier("b")==1.08,"auras do not stack")
 party._set_mode("coop")
 for n in party.realm_picker.item_count:
  if str(party.realm_picker.get_item_metadata(n))=="moonveil":party.realm_picker.select(n)
 party._start_match();party.opponents.clear();party.wave=3;party._spawn_wave(0)
 check(party.opponents[-1].type=="mirror_marquis" and party.opponents[-1].hp>=1200,"co-op custom boss and health")
 for voice in party.journey.voices:voice.stop()
 party.queue_free();await create_timer(.2).timeout
 print("V33 FAILURES: "+str(failures));quit(failures)
