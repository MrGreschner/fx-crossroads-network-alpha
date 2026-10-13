extends SceneTree
var failures := 0
func check(value: bool, label: String) -> void:
	if not value: failures += 1;print("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.characters.basketball.name=="Dribble","basketball renamed")
	check(game.characters.ram.name=="Young Ram","ram unchanged")
	check(game.characters.has("dawnblade") and game.characters.has("stormscribe"),"new heroes")
	game.selected_character="stormscribe";game.start_run(false,"clockwork_orchard")
	check(game.enemies.size()==44,"orchard enemy set")
	check(game.adventure.clockwork,"orchard controller")
	var template:Dictionary=game.enemies[0].duplicate(true)
	game.enemies.clear();game.position_in_world=Vector2(2000,2100)
	for n in 5:
		var foe=template.duplicate(true);foe.uid=100+n;foe.hp=1000.0;foe.max_hp=1000.0
		foe.pos=game.position_in_world+Vector2(120+n*40,(n-2)*20)
		game.enemies.append(foe)
	game.cast_chain(game.hero.secondary,22,Vector2.RIGHT)
	var hit:=0
	for foe in game.enemies:
		if foe.hp<1000:hit+=1;check(is_equal_approx(foe.hp,978),"equal bolt damage")
	check(hit==3 and game.attack_effects.size()==3,"exactly three simultaneous targets")
	for effect in game.attack_effects:check(effect.start==game.position_in_world and effect.lightning,"fork starts at caster")
	game.kills=44;game.maybe_spawn_boss()
	var boss:Dictionary=game.enemies[-1]
	check(boss.type=="hourglass_hart" and boss.expansion_boss,"custom guardian")
	game.position_in_world=boss.pos+Vector2(-100,0)
	for n in 3:boss.skill_timer=0.0;game.adventure.step(.01)
	check(game.adventure.warnings.size()==7,"three distinct boss patterns")
	game.selected_character="dawnblade";game.start_run(false,"grove")
	check(game.hero.primary.style=="melee" and float(game.hero.primary.range)==82,"close sword reach")
	game.level=10;game.fire("primary");game.fire("secondary");game.pulse()
	check(game.block_time > 0 and game.block_reflect,"Mara riposte reflects")
	game.queue_free();await create_timer(.3).timeout
	var party=load("res://scenes/arcade.tscn").instantiate()
	root.add_child(party);await process_frame
	party.role="host";party.my_id="test";party.host_id="test";party.selected_hero="stormscribe"
	party.roster.append({"id":"test","name":"Wizard"});party._add_player("test",0)
	party._set_mode("coop")
	for n in party.realm_picker.item_count:
		if str(party.realm_picker.get_item_metadata(n))=="clockwork_orchard":party.realm_picker.select(n)
	party._start_match()
	party.opponents.clear();party.positions.test=Vector2(2000,2100);party.local_pos=party.positions.test;party.levels.test=10
	for n in 5:
		party.opponents.append({"pos":party.local_pos+Vector2(120+n*40,(n-2)*20),"hp":1000.0,"max_hp":1000.0,"uid":n+1,"boss":false,"type":"tick_acorn","lane":0,"attack_timer":0.0})
	party._attack("test","secondary",Vector2.RIGHT,party.local_pos+Vector2(350,0))
	hit=0
	for foe in party.opponents:
		if foe.hp<1000:hit+=1;check(is_equal_approx(foe.hp,978),"coop equal damage")
	check(hit==3,"coop three targets")
	var total_before:=0.0
	for foe in party.opponents: total_before+=float(foe.hp)
	party._attack("test","special",Vector2.RIGHT,party.local_pos+Vector2(200,0))
	party.adventure.step_lobs(1.0)
	var total_after:=0.0
	for foe in party.opponents: total_after+=float(foe.hp)
	check(total_before-total_after>=55*3,"Thunderfall hits multiple enemies")
	check(int(party.shield_until.get("test",0)) == 0,"wizard special is offensive")
	check(party.characters.stormscribe.special.style=="target_aoe","wizard Thunderfall")
	party.wave=3;party._spawn_wave(1)
	check(party.opponents[-1].type=="hourglass_hart" and party.opponents[-1].hp==900,"coop guardian")
	await process_frame
	party.queue_free();await create_timer(.3).timeout
	print("V14 FAILURES: "+str(failures));quit(failures)
