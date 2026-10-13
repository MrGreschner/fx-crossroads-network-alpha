extends SceneTree
var failures:=0
func check(value:bool,label:String)->void:
	if not value:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
	game.selected_character="ram";game.start_run(false,"chimevault")
	var vault=game.adventure.vault
	check(vault.active and game.enemies.is_empty(),"custom maze starts without legacy waves")
	check(game.can_stand_at(Vector2(340,340)) and not game.can_stand_at(Vector2(120,120)),"maze wall collision")
	for n in 3:
		for cell in vault.cells[n]:check(not vault.grids[n].get_id_path(Vector2i(1,1),cell).is_empty(),"connected maze")
	game.adventure.step(.01)
	check(game.enemies.size()==11,"first stage enemies and guardian")
	game.invulnerable_time=10000
	for k in 100:game.adventure.step(.04)
	for foe in game.enemies:check(vault.can_stand(foe.pos),"actors stay inside maze corridors")
	var guardian:Dictionary=game.enemies[-1]
	check(guardian.type=="gongbreaker" and guardian.hp==1100,"large midboss")
	check(vault.interact("solo")==false,"cannot teleport remotely")
	game.position_in_world=vault.gates[0];check(vault.interact("solo") and vault.stage==0,"gate locked before clear")
	for n in 3:
		while not game.enemies.is_empty():game.damage_enemy(0,99999)
		game.position_in_world=vault.gates[n];check(vault.interact("solo"),"gate interaction")
		if n<2:check(vault.stage==n+1 and game.enemies.size()==(12 if n==1 else 11),"next stage populated")
	check(vault.complete and game.menu=="results" and not game.boss_defeated,"custom realm completes only after all stages")
	game.start_run(false,"astral_rift");game.enemies.clear();game.position_in_world=Vector2(500,1600);game.health=100;game.invulnerable_time=0
	game.adventure.warn_wave(Vector2(300,1600),Vector2(250,0),24,29,600,.5,"#d9a9fa")
	game.adventure.step(.5);check(game.adventure.waves.size()==1 and game.health==100,"wave launch after windup")
	game.adventure.step(.5);check(game.adventure.vec(game.adventure.waves[0].pos).x>300,"wave travels")
	game.adventure.step(.3);check(game.health==71,"wave damage on arrival")
	game.invulnerable_time=0;game.adventure.step(.1);check(game.health==71,"one hit per wave")
	game.adventure.step(3);check(game.adventure.waves.is_empty(),"wave lifetime bounded")
	for voice in game.journey.voices:voice.stop()
	await create_timer(.1).timeout;game.queue_free();await create_timer(.2).timeout
	var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false)
	party.role="host";party.my_id="a";party.host_id="a";party.selected_hero="ram"
	for n in 2:
		var id:String=["a","b"][n];party.roster.append({"id":id,"name":id});party._add_player(id,n)
	party._set_mode("coop")
	for n in party.realm_picker.item_count:
		if str(party.realm_picker.get_item_metadata(n))=="chimevault":party.realm_picker.select(n)
	party._start_match();party.adventure.step(.01)
	check(party.opponents.size()==11 and party.opponents[-1].hp>1100,"co-op maze and guardian scaling")
	party.opponents.clear();party.positions.a=party.adventure.vault.gates[0];party.local_pos=party.positions.a
	var key:=InputEventKey.new();key.pressed=true;key.keycode=KEY_E;party._unhandled_input(key)
	check(party.adventure.vault.stage==1 and party.positions.b.x>3000,"co-op lift moves party")
	var clone=load("res://scripts/realm_trials.gd").new();root.add_child(clone)
	var packet:Dictionary=JSON.parse_string(JSON.stringify(party.adventure.snapshot()));clone.receive(packet)
	check(clone.vault.active and clone.vault.stage==1 and clone.vault.grids.size()==3,"maze network state")
	clone.queue_free()
	party._set_mode("descent");party._start_match();party.opponents.clear()
	check(party.FIELD.size==Vector2(2400,1700) and party.field_obstacles.size()==6,"compact descent")
	var enemy:Dictionary={"pos":Vector2(500,500),"nav_timer":0.0}
	var target:=Vector2(850,500)
	for n in 250:
		var direction:Vector2=party.descent_direction(enemy,target,.04)
		enemy.pos=party._move_actor(enemy.pos,direction*90*.04)
	check((enemy.pos as Vector2).distance_to(target)<60,"enemy routes around rock")
	for voice in party.journey.voices:voice.stop()
	await create_timer(.1).timeout;party.queue_free();await create_timer(.3).timeout
	print("V20 FAILURES: "+str(failures));quit(failures)
