extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 game.start_run(false,"honeyglass");game.enemies.clear();game.position_in_world=Vector2(2000,1500)
 var combat=game.adventure.combat
 game.adventure.spawn("warlock",Vector2(2300,1500),100,false)
 game.enemies[0].ranged_cast_timer=0;game.enemies[0].summon_timer=0
 combat.step_summoners(.01);game.update_enemies(.01)
 check(combat.projectiles.size()==1 and game.enemies.size()==2,"solo warlock shoots and summons independently")
 for n in 10:combat.step_projectiles(.1)
 check(combat.projectiles.size()==2 and combat.projectiles[0].stats.flame_orb,"cinder orb forks into two visible flame shots")
 var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party._set_mode("defense");party._solo();party._start_match()
 party.opponents.clear();party.positions[party.my_id]=Vector2(2000,1500);party.health[party.my_id]=100
 party.adventure.spawn("warlock",Vector2(2250,1500),100,false);party.opponents[0].lane=2
 var shared=party.adventure.combat
 for n in 3:
  party.opponents[0].ranged_cast_timer=0;party.opponents[0].summon_timer=0;shared.step_summoners(.01)
 check(party.opponents.size()==3,"host summoner retains capped two minions")
 check(shared.projectiles.size()==3,"host summoner shoots alongside summons")
 check(party.opponents[1].lane==2,"summons retain defense lane")
 for voice in game.journey.voices:voice.stop()
 for voice in party.journey.voices:voice.stop()
 game.queue_free();party.queue_free();await create_timer(.3).timeout
 print("V40 SUMMONER FAILURES: "+str(failures));quit(failures)
