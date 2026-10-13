extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party.role="host";party.my_id="a";party.host_id="a";party.selected_hero="ram";party.roster.append({"id":"a","name":"a"});party._add_player("a",0);party._set_mode("descent");party._start_match();party.opponents.clear();party.field_obstacles.clear();party._rebuild_grid();party.positions.a=Vector2(1200,850);party.local_pos=party.positions.a
	for kind in ["archer","ice_archer","spore_thrower"]:
		party.opponents.clear();party.adventure.spawn(kind,Vector2(1280,850),500,false);var enemy:Dictionary=party.opponents[0];var away:Vector2=party.descent_ranged_direction(enemy,party.positions.a,.04)
		check(away.x>0,"ranged retreats: "+kind)
		for n in 40:party._simulate(.04)
		check((enemy.pos as Vector2).distance_to(party.positions.a)>130,"ranged opens distance: "+kind)
	party.opponents.clear();party.adventure.spawn("archer",Vector2(1450,850),500,false);party.adventure.spawn("ice_archer",Vector2(1450,855),500,false)
	for n in 80:party._simulate(.04)
	check((party.opponents[0].pos as Vector2).distance_to(party.opponents[1].pos)>60,"ranged enemies spread apart")
	party.opponents.clear();party.adventure.spawn("bramble",Vector2(1300,850),500,false)
	for n in 10:party._simulate(.04)
	check(party.opponents[0].pos.x<1300,"melee still pursues")
	party.opponents.clear();party.adventure.spawn("archer",Vector2(2320,850),500,false);party.positions.a=Vector2(2280,850)
	for n in 100:party._simulate(.04)
	check(party.FIELD.grow(-25).has_point(party.opponents[0].pos),"retreat stays in dungeon")
	party.field_obstacles.append({"pos":Vector2(1400,850),"radius":38.0,"kind":"rock"});party._rebuild_grid();party.opponents[0].pos=Vector2(1340,850);party.positions.a=Vector2(1280,850)
	var direction:Vector2=party.descent_ranged_direction(party.opponents[0],party.positions.a,.04)
	check(direction!=Vector2.ZERO and party._clear_path(Vector2(1340,850),Vector2(1340,850)+direction*65),"retreat routes beside blocking rock")
	for voice in party.journey.voices:voice.stop()
	await create_timer(.1).timeout;party.queue_free();await create_timer(.2).timeout
	print("V26 FAILURES: "+str(failures));quit(failures)
