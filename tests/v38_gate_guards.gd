extends SceneTree
var failures := 0
func check(ok: bool, label: String) -> void:
 if not ok: failures += 1;print("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var party = load("res://scenes/arcade.tscn").instantiate()
 root.add_child(party);await process_frame;party.set_process(false)
 party.selected_hero="ram";party._set_mode("defense");party._solo()
 party.opponents.clear();party.guards.clear();party.field_obstacles.clear()
 party.wave_timer=0;party.guard_timer=999;party._simulate(.01)
 check(party.wave==1 and party.wave_timer<28,"first wave reschedules within 28 seconds")
 for foe in party.opponents:
  check((foe.pos as Vector2).distance_to(party.GATE)<2300,"early enemies arrive nearer the guard line")
 party.opponents.clear();party.wave_timer=999
 for n in 5: party._spawn_defense_guard(0,"melee",1000,1)
 for i in party.guards.size():
  for j in range(i):check((party.guards[i].pos as Vector2).distance_to(party.guards[j].pos)>=50,"five recruits spawn separately")
 for n in 600:party._simulate_guards(.04)
 for i in party.guards.size():
  for j in range(i):check((party.guards[i].pos as Vector2).distance_to(party.guards[j].pos)>=49.9,"guards hold separate positions")
 party.guards.clear();party._spawn_defense_guard(0,"melee",1000,1)
 var center:Vector2=party.GATE+Vector2(0,-1200)
 party.guards[0].pos=center
 var stopped:Vector2=party._guard_blocked_move(center+Vector2(0,-100),Vector2(0,200),-1,44)
 check(stopped.y<=center.y-44,"guard blocks even a long enemy movement")
 party.adventure.spawn("bramble",center+Vector2(0,-46),1000,false)
 party.positions.solo=party.GATE;party.local_pos=party.GATE
 var hp:float=party.guards[0].hp
 for n in 10:party._simulate(.04)
 check(float(party.guards[0].hp)<hp,"blocked melee enemy attacks its guard")
 check((party.opponents[0].pos as Vector2).distance_to(party.guards[0].pos)>=43.9,"enemy and guard bodies remain separate")
 check(party._snapshot().guards.size()==1,"guard markers have replicated positions for guests")
 for voice in party.journey.voices:voice.stop()
 party.queue_free();await create_timer(.3).timeout
 print("V38 FAILURES: "+str(failures));quit(failures)
