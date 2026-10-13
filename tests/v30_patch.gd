extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.selected_character="patch";game.start_run(false,"honeyglass");game.level=6
 check(game.characters.size()==21,"21 heroes")
 check(game.characters.goalie.primary.damage==27 and game.characters.basketball.primary.damage==27,"primary nerfs")
 game.adventure.combat.cast("solo",game.hero.primary,Vector2.RIGHT,14)
 check(game.adventure.combat.projectiles.size()==4,"four way volley")
 game.adventure.combat.cast("solo",game.hero.secondary,Vector2.RIGHT,18)
 check(game.adventure.combat.rings[0].clear,"reset clears hostile shots")
 game.pulse();check(game.allies.size()==2 and game.allies[0].time==11,"solo buddies and passive")
 game.update_allies(12);check(game.allies.is_empty(),"buddies expire")
 for voice in game.journey.voices:voice.stop()
 game.queue_free();await process_frame
 var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party.selected_hero="patch";party._set_mode("descent");party._solo();party.levels.solo=6
 check(party.art.has("bit_buddy"),"multiplayer buddy art")
 party._attack("solo","special",Vector2.RIGHT)
 check(party.guards.size()==2 and party.guards[0].time==11 and party.guards[0].owner=="solo","multiplayer buddies passive and owner")
 for voice in party.journey.voices:voice.stop()
 party.queue_free();await create_timer(.2).timeout
 print("V30 FAILURES: "+str(failures));quit(failures)
