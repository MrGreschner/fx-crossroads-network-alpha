extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 game.start_run(false,"honeyglass");game.enemies.clear();game.position_in_world=Vector2(2000,1500)
 var combat=game.adventure.combat
 combat.add_anchor("solo",Vector2(2250,1500));combat.add_anchor("solo",Vector2(2400,1700))
 game.adventure.spawn("bramble",Vector2(2310,1500),100,false)
 combat.cast("solo",{"style":"magnet_pull","radius":170},Vector2.RIGHT,20)
 var surges:=0;var tethers:=0;var failed:=false
 for effect in combat.visuals:
  if effect.get("style","")=="magnet_surge":surges+=1;failed=failed or combat.vec(effect.pos)==game.position_in_world
  elif effect.get("style","")=="magnet_tether":tethers+=1;failed=failed or combat.vec(effect.end)!=Vector2(2250,1500)
  else:failed=true
 failed=failed or surges!=2 or tethers!=1 or game.enemies[0].hp!=80
 var packet:Dictionary=combat.snapshot();failed=failed or packet.visuals.size()!=3
 combat.step(.6);failed=failed or not combat.visuals.is_empty()
 for voice in game.journey.voices:voice.stop()
 game.queue_free();await create_timer(.3).timeout
 print("V41 POLARITY FAILURES: "+str(int(failed)));quit(int(failed))
