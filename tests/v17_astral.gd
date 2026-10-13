extends SceneTree
var failures:=0
func check(value:bool,label:String)->void:
	if not value:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);await process_frame
	for id in ["baseball","golfer","soccer","welder"]:check(not str(game.characters[id].name).begins_with("The "),"name "+id)
	game.selected_character="vesper";game.start_run(false,"astral_rift")
	check(game.enemies.size()==45 and game.adventure.astral,"realm loaded")
	check(game.adventure.traps.size()==3,"timed gates")
	check(not game.can_stand_at(Vector2(2000,700)),"void blocked")
	check(game.can_stand_at(Vector2(1200,1050)),"island bridge")
	game.position_in_world=Vector2(1500,1800)
	var first:Dictionary=game.enemies[0].duplicate(true)
	game.enemies.clear()
	first.pos=Vector2(1600,1800);first.hp=1000.0;first.max_hp=1000.0;first.uid=101;first.type="rift_weaver"
	game.enemies.append(first)
	game.adventure.launch_disc("solo",Vector2.RIGHT,game.hero.primary,16)
	for n in 80:game.adventure.step_discs(.02)
	check(first.hp==968,"one hit each leg")
	check(game.adventure.discs.is_empty(),"caught disc removed")
	for n in 10:game.adventure.launch_disc("solo",Vector2.RIGHT,game.hero.primary,16)
	check(game.adventure.discs.size()==4,"disc cap")
	game.adventure.discs.clear()
	game.adventure.warnings.clear()
	for kind in ["rift_weaver","prism_kite","comet_urchin"]:
		first.type=kind;first.skill_timer=0.0
		game.handle_run(.01)
	check(game.adventure.warnings.size()==4,"three enemy attack patterns via gameplay loop")
	game.kills=45;game.maybe_spawn_boss()
	var boss:Dictionary=game.enemies[-1]
	check(boss.type=="eclipse_engine","new boss")
	game.position_in_world=boss.pos+Vector2(-150,0);game.adventure.warnings.clear()
	for n in 3:boss.skill_timer=0.0;game.handle_run(.01)
	check(game.adventure.warnings.size()>=10,"all boss attacks")
	game.start_run(false,"grove");game.position_in_world=Vector2(500,600)
	game.adventure.launch_disc("solo",Vector2.RIGHT,game.hero.primary,16)
	var old:float=game.adventure.discs[0].life
	game.handle_run(.02)
	check(game.adventure.discs[0].life>old,"disc works in ordinary realms")
	game.queue_free();await create_timer(.3).timeout
	var party=load("res://scenes/arcade.tscn").instantiate()
	root.add_child(party);await process_frame
	party.role="host";party.my_id="test";party.host_id="test";party.selected_hero="vesper"
	party.roster.append({"id":"test","name":"Courier"});party._add_player("test",0);party._set_mode("coop")
	for n in party.realm_picker.item_count:
		if str(party.realm_picker.get_item_metadata(n))=="astral_rift":party.realm_picker.select(n)
	party._start_match();party.opponents.clear();party.local_pos=Vector2(1500,1800);party.positions.test=party.local_pos
	var foe:Dictionary={"pos":Vector2(1600,1800),"hp":1000.0,"max_hp":1000.0,"uid":2,"boss":false,"type":"rift_weaver","lane":0,"attack_timer":0.0}
	party.opponents.append(foe);party._attack("test","primary",Vector2.RIGHT,Vector2(1700,1800))
	for n in 80:party.adventure.step_discs(.02)
	check(foe.hp==968,"co-op return parity")
	party._attack("test","primary",Vector2.RIGHT,Vector2(1700,1800))
	var packet:Dictionary=JSON.parse_string(JSON.stringify(party.adventure.snapshot()))
	var clone=load("res://scripts/realm_trials.gd").new()
	clone.receive(packet);check(clone.discs.size()==party.adventure.discs.size(),"JSON disc snapshot");clone.free()
	party.wave=3;party._spawn_wave(1)
	check(party.opponents[-1].type=="eclipse_engine","coop boss")
	party.queue_free();await create_timer(.3).timeout
	print("V17 FAILURES: "+str(failures));quit(failures)
