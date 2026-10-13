extends SceneTree
var failures := 0
func check(value: bool, label: String) -> void:
	if not value: failures += 1;print("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func press(game: Node, code: int) -> void:
	var event := InputEventKey.new();event.pressed=true;event.keycode=code
	game._unhandled_input(event)
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game);await process_frame
	game.set_process(false);game.mobile.enabled=true
	check(game.characters.goalie.name=="Frostguard","goaltender name")
	for index in game.manifest.characters.size():
		game.menu="characters";game.select_hero_entry(index);game.mobile._process(0)
		var button: Button
		for candidate in game.mobile.buttons:
			if candidate.text=="Continue": button=candidate
		check(button!=null,"continue exists")
		var event:=InputEventScreenTouch.new();event.index=4;event.position=button.get_global_rect().get_center();event.pressed=true
		game.mobile._input(event);event.pressed=false;game.mobile._input(event)
		check(game.menu=="","continue closes for every hero")
		check(game.mobile.held_buttons.is_empty(),"touch released")
	for dimensions in [Vector2i(1600,720),Vector2i(1280,1800),Vector2i(1600,720)]:
		root.size=dimensions;await process_frame
		game.mobile._process(0)
		check(game.mobile.layout_size==root.get_visible_rect().size,"rotation rebuilds overlay")
		game.mobile.movement=Vector2.RIGHT
		game.mobile.layout_size=Vector2.ZERO;game.mobile._process(0)
		check(game.mobile.movement==Vector2.ZERO,"resize resets held movement")
	game.menu="portal";game.scroll_list(999)
	check(game.list_scroll.portal==game.manifest.regions.size()-7,"all realms reachable")
	game.select_list_entry(game.manifest.regions.size()-1);game.confirm_list_entry()
	check(game.region_id==str(game.manifest.regions[-1]),"last realm launches")
	game.menu="supplies";game.gold=1000;game.loadout.clear();game.scroll_list(999)
	game.select_list_entry(game.manifest.items.size()-1)
	var id:=str(game.manifest.items[-1]);var cost:=int(game.items[id].cost)
	press(game,KEY_ENTER);check(game.loadout.has(id) and game.gold==1000-cost,"last shop item buys")
	check(not str(game.items[id].description).is_empty(),"item explanation")
	press(game,KEY_BACKSPACE);check(game.gold==1000 and game.loadout.is_empty(),"refund")
	game.menu="merchant";game.inventory.clear();game.select_list_entry(game.manifest.items.size()-1);game.confirm_list_entry()
	check(game.gold==1000-maxi(10,cost/2) and game.inventory.has(id),"merchant discount")
	game.selected_character="soccer";game.start_run(false,"grove");game.menu="";game.health=40
	game.adventure.create_healing_zone("solo",game.hero.special)
	for n in 50:game.adventure.step_healing_zones(.1)
	check(is_equal_approx(game.health,70),"five healing ticks")
	check(game.adventure.healing_zones.is_empty(),"zone expires")
	game.queue_free();await create_timer(.2).timeout
	var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame
	party.set_process(false);party.role="host";party.my_id="a";party.host_id="a";party.selected_hero="soccer"
	for n in 3:
		var who: String=["a","b","c"][n];party.roster.append({"id":who,"name":who});party._add_player(who,n)
		party.positions[who]=Vector2(500,500);party.health[who]=40
	party.mode="arena";party.pvp_rule="teams";party.teams={"a":0,"b":0,"c":1}
	party.adventure.create_healing_zone("a",party.characters.soccer.special)
	party.adventure.step_healing_zones(1)
	check(party.health.a==46 and party.health.b==46 and party.health.c==40,"heals allies only")
	var packet:Dictionary=JSON.parse_string(JSON.stringify(party.adventure.snapshot()))
	var clone=load("res://scripts/realm_trials.gd").new();party.add_child(clone);clone.receive(packet)
	check(clone.healing_zones.size()==1 and clone.healing_zones[0].time==4,"network zone snapshot");clone.free()
	party.health.b=0;party.adventure.step_healing_zones(1);check(party.health.b==0,"no revival")
	party.pvp_rule="ffa";party.health.b=40;party.adventure.step_healing_zones(1);check(party.health.b==40,"FFA rivals not healed")
	party.queue_free();await create_timer(.2).timeout
	print("V18 FAILURES: "+str(failures));quit(failures)
