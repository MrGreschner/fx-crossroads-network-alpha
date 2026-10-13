extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 for party in [1,3,4]:
  var game=load("res://scenes/arcade.tscn").instantiate();root.add_child(game);await process_frame
  game.set_process(false);game.legacy.set_process(false);game.role="host";game.my_id="p0";game.host_id="p0";game._set_mode("defense")
  for n in party:game._add_player("p"+str(n),n)
  game._start_match();game.gate_hp=100000
  for id in game.positions:game.positions[id]=game.north_gate.point_at(int(str(id).substr(1))%3,850);game.health[id]=10000
  game.local_pos=game.positions.p0
  for tick in 900:
   game.run_time+=.1;game.adventure.step(.1);game._simulate(.1)
   if tick%100==0:game._track_card_progress()
   # Keep the stress test about combat simulation, rather than allowing a test player knockout.
   for id in game.health:game.health[id]=10000
   game.effects.clear();game.sent_effects.clear();game.damage_labels.clear()
  if game.opponents.size()>94 or game.guards.size()>48:print("FAIL actor budgets");quit(1);return
  print("90-second party ",party," run: wave ",game.wave," enemies ",game.opponents.size()," guards ",game.guards.size()," rival level ",game.north_gate.rival_level)
  game.queue_free();await process_frame;await create_timer(.2).timeout
 print("v74 continuous simulation passed");quit()
