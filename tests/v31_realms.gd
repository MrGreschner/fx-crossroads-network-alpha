extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.start_run(false,"honeyglass");game.obstacles.clear();game.build_scenery();game.position_in_world=Vector2(2000,1500);game.enemies.clear()
 for kind in ["archer","ice_archer","spore_thrower","void_seeker","seed_blossom","sluice_beetle","pendulum_moth","rift_weaver","prism_kite","foldwing","inkfin","tuning_wraith","warlock"]:
  var foe:Dictionary={"uid":7,"type":kind,"pos":Vector2(2080,1500),"boss":false}
  check(game.adventure.combat.ranged_enemy(foe,game.enemy_types[kind]),"ranged classifier: "+kind)
  check(game.adventure.combat.ranged_direction(foe,game.position_in_world).x>0,"shooter retreats: "+kind)
 game.adventure.spawn("seed_blossom",Vector2(2080,1500),500,false);game.update_enemies(.1);check(game.enemies[0].pos.x>2080,"solo ranged integrated movement")
 game.start_run(false,"shattered_oath")
 check(game.decorations.size()==79 and game.obstacles.size()==36,"main world ruins load")
 for portal in game.adventure.portals():check(game.can_stand_at(portal.pos),"portal pad accessible")
 check(game.shot_path_clear(game.adventure.HUB,game.adventure.HUB+Vector2(0,728)),"central final rift route clear")
 check(game.art.has("oath_broken_road"),"broken road texture loaded")
 for voice in game.journey.voices:voice.stop()
 game.queue_free();await create_timer(.2).timeout
 print("V31 FAILURES: "+str(failures));quit(failures)
