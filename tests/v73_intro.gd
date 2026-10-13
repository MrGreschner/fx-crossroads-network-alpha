extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 var origin:Vector2=game.position_in_world
 if not game.has_node("FXIntro"):quit(1);return
 await create_timer(2.1).timeout
 if game.has_node("FXIntro") or game.position_in_world!=origin:quit(2);return
 game.enter_region("town")
 if game.has_node("FXIntro"):quit(3);return
 print("v73 intro passed");quit()
