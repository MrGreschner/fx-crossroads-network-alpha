extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party.selected_hero="ram";party._set_mode("defense");party._solo();party.opponents.clear();party.guards.clear();party.field_obstacles.clear();party.wave_timer=999;party.guard_timer=999;party.positions.solo=party.GATE+Vector2(0,-1200);party.local_pos=party.positions.solo
 for kind in ["archer","ice_archer","spore_thrower","void_seeker"]:
  party.opponents.clear();party.adventure.spawn(kind,party.positions.solo+Vector2(80,0),500,false)
  var before:Vector2=party.opponents[0].pos
  for n in 40:party._simulate(.04)
  check((party.opponents[0].pos as Vector2).distance_to(party.positions.solo)>before.distance_to(party.positions.solo),"defense shooter retreats: "+kind)
 party.opponents.clear();party.adventure.spawn("archer",party.positions.solo+Vector2(250,0),500,false);party.adventure.spawn("ice_archer",party.positions.solo+Vector2(250,5),500,false)
 for n in 80:party._simulate(.04)
 check((party.opponents[0].pos as Vector2).distance_to(party.opponents[1].pos)>60,"defense shooters spread")
 party.opponents.clear();party.adventure.spawn("archer",party.GATE+Vector2(0,-2400),500,false);var start:Vector2=party.opponents[0].pos
 for n in 10:party._simulate(.04)
 check((party.opponents[0].pos as Vector2).distance_to(party.GATE)<start.distance_to(party.GATE),"unopposed shooter advances on gate")
 party.health.solo=120;party.opponents.clear();party.adventure.spawn("bramble",party.positions.solo+Vector2(100,0),500,false)
 for n in 10:party._simulate(.04)
 check(party.opponents[0].pos.x<party.positions.solo.x+100,"melee still pursues")
 for voice in party.journey.voices:voice.stop()
 party.queue_free();await create_timer(.2).timeout
 print("V29 FAILURES: "+str(failures));quit(failures)
