extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 check(game.characters.medic.primary.poison_damage==2 and game.characters.medic.primary.poison_duration==5,"medic poison")
 check(game.manifest.regions[2]=="honeyglass","realm follows quarry")
 game.enter_region("honeyglass")
 check(game.enemies.size()==24 and game.decorations.size()==76 and game.obstacles.size()==8,"realm loads scenery enemies boss")
 check(game.art.has("garden_grass") and game.art.has("glass_queen_walk1"),"terrain and boss art loaded")
 game.kills=24;game.maybe_spawn_boss()
 check(game.boss_spawned and game.enemies[0].hp==640,"queen encounter spawns")
 game.selected_character="vesper"
 game.adventure.launch_lob("solo",game.position_in_world,game.position_in_world+Vector2(200,0),game.characters.vesper.secondary,32)
 check(game.adventure.lob_shots.size()==1,"comet visible in flight")
 game.adventure.step_lobs(2.0)
 check(game.adventure.lob_shots.is_empty() and game.adventure.lob_blasts.size()==1,"comet explodes after arrival")
 for voice in game.journey.voices:voice.stop()
 game.queue_free();await create_timer(.2).timeout
 print("V28 FAILURES: "+str(failures));quit(failures)
