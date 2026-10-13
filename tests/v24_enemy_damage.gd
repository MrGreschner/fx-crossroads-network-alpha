extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false)
	party.role="host";party.my_id="a";party.host_id="a";party.selected_hero="ram"
	for n in 2:
		var id:String=["a","b"][n];party.roster.append({"id":id,"name":id});party._add_player(id,n)
	party._set_mode("descent");party._start_match();party.field_obstacles.clear();party._rebuild_grid()
	for delta in [.016,.033,.04,.1]:
		for target in ["a","b"]:
			party.opponents.clear();party.missiles.clear();party.positions.a=Vector2(1100,850);party.positions.b=Vector2(1400,850);party.local_pos=party.positions.a
			party.health[target]=party._max_hp(target);party.invincible_until[target]=0;party.adventure.spawn("bramble",party.positions[target]+Vector2(25,0),500,false)
			var initial:int=party.health[target]
			party._simulate(float(delta));check(party.health[target]==initial,"windup before melee damage")
			for frame in int(ceil(1.0/float(delta))):party._simulate(float(delta))
			check(party.health[target]<initial,"melee damages "+target+" at step "+str(delta))
			var hit_hp:int=party.health[target];party._simulate(float(delta));check(party.health[target]==hit_hp,"melee respects cooldown")
	party.opponents.clear();party.missiles.clear();party.positions.a=Vector2(1100,850);party.positions.b=Vector2(1600,850);party.health.a=120;party.invincible_until.a=0
	party.adventure.spawn("archer",Vector2(1300,850),500,false)
	for frame in 50:party._simulate(.04)
	check(party.health.a<120,"ranged enemy fires after completed windup")
	party.opponents.clear();party.missiles.clear();party.health.a=120;party.invincible_until.a=Time.get_ticks_msec()+10000
	party.adventure.spawn("bramble",Vector2(1120,850),500,false)
	for frame in 30:party._simulate(.04)
	check(party.health.a==120,"intentional invulnerability still works")
	party.invincible_until.a=0;party.opponents[0].attack_timer=0;party.opponents[0].warning=-1
	for frame in 30:party._simulate(.04)
	check(party.health.a<120,"enemy damage resumes without invulnerability")
	for voice in party.journey.voices:voice.stop()
	await create_timer(.1).timeout;party.queue_free();await create_timer(.2).timeout
	print("V24 FAILURES: "+str(failures));quit(failures)
