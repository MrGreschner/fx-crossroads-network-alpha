extends SceneTree
var failures := 0
func check(value: bool, label: String) -> void:
	if not value: failures += 1;print("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game.characters.has("ferryman"),"hero registry")
	check(game.realms.has("silverfall"),"realm registry")
	game.selected_character="ferryman"
	game.start_run(false,"silverfall")
	check(game.enemies.size()==48,"48 original enemies")
	check(game.adventure.river,"river controller")
	check(not game.can_stand_at(Vector2(1700,1900)),"river blocked")
	check(game.can_stand_at(Vector2(1700,1100)),"bridge open")
	check(game.art.has("river_water"),"terrain loaded")
	game.kills=48
	game.maybe_spawn_boss()
	var boss = game.enemies[-1]
	check(boss.type=="crowned_torrent" and boss.expansion_boss,"unique boss")
	game.position_in_world=boss.pos+Vector2(-100,0)
	for phase in 3:
		boss.skill_timer=0.0
		game.adventure.step(.01)
	check(game.adventure.warnings.size()>=7,"three boss attacks")
	check(game.enemies.size()>1,"boss summon")
	game.level=10;game.fire("primary");game.fire("secondary");game.pulse()
	check(game.adventure.combat.projectiles.size()==3,"solo stone spread")
	check(game.adventure.combat.rings.size()==1,"solo waterfall wave")
	game.mobile.enabled=true
	root.size=Vector2i(1920,720)
	await process_frame
	await process_frame
	var view=game.get_viewport_rect().size
	check(game.VIEW==view,"camera viewport")
	check(game.mobile.aim_center.x==view.x-170,"aim anchored right")
	check(game.mobile.move_center.y==view.y-135,"move anchored bottom")
	for button in game.mobile.buttons:
		check(Rect2(Vector2.ZERO,view).encloses(button.get_rect()),"button fits: "+button.text)
	game.menu="characters"
	await process_frame
	check(game.mobile.menu_offset==(view-Vector2(1280,720))*0.5,"menus centered")
	game.queue_free()
	await create_timer(.3).timeout
	var party=load("res://scenes/arcade.tscn").instantiate()
	root.add_child(party)
	await process_frame
	party.role="host";party.my_id="test";party.host_id="test";party.selected_hero="ferryman"
	party.roster.append({"id":"test","name":"Test"})
	party._add_player("test",0)
	party._set_mode("coop")
	for n in party.realm_picker.item_count:
		if str(party.realm_picker.get_item_metadata(n))=="silverfall":party.realm_picker.select(n)
	party._start_match()
	check(party.adventure.river,"coop river controller")
	party.levels["test"]=10
	for kind in ["primary","secondary","special"]: party._attack("test",kind,Vector2.RIGHT,party.local_pos+Vector2(200,0))
	check(party.adventure.combat.projectiles.size()==3,"coop stone spread")
	check(party.adventure.combat.rings.size()==1,"coop waterfall wave")
	party.wave=3;party._spawn_wave(1)
	check(party.opponents[-1].type=="crowned_torrent","coop boss")
	party.mobile.enabled=true
	await process_frame
	check(party.mobile.aim_center.x==party.VIEW.x-170,"coop mobile anchors")
	party.queue_free()
	await create_timer(.3).timeout
	print("V13 FAILURES: "+str(failures))
	quit(failures)
