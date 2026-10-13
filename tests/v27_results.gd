extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party.selected_hero="medic";party._set_mode("descent");party._solo();party.opponents.clear();party.field_obstacles.clear();party._rebuild_grid();party.positions.solo=Vector2(1000,850);party.local_pos=party.positions.solo
	party.adventure.spawn("bramble",Vector2(1050,850),500,false);party._hit_enemy(0,31,"solo")
	check(party.contributions.solo.damage==31,"solo damage recorded")
	party.health.solo=50;party.levels.solo=3;party._attack("solo","secondary",Vector2.RIGHT)
	check(party.contributions.solo.healing==25,"ability healing counted")
	party._heal("solo","solo",10,false);check(party.contributions.solo.healing==25,"item healing excluded")
	party.opponents.clear();party._simulate(.01);check(party.floor_number==2 and party.contributions.solo.healing==25 and party.contributions.solo.damage==31,"floor recovery excluded and damage retained")
	party.health.solo=party._max_hp("solo")-3;party._heal("solo","solo",25);check(party.contributions.solo.healing==28,"only actual spell recovery counted")
	party.end_match("Test results");var packet:Dictionary=party._snapshot();check(packet.contributions.solo.damage==31 and packet.contributions.solo.healing==28,"results network payload has separate totals")
	for voice in party.journey.voices:voice.stop()
	await create_timer(.1).timeout;party.queue_free();await create_timer(.2).timeout
	print("V27 FAILURES: "+str(failures));quit(failures)
