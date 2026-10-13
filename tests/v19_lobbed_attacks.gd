extends SceneTree
var failures := 0
func check(value: bool, label: String) -> void:
	if not value: failures+=1;print("FAIL: "+label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.set_process(false);game.selected_character="goalie";game.start_run(false,"grove")
	game.mobile.enabled=true;game.mobile.aim=Vector2.RIGHT;game.position_in_world=Vector2(500,600);game.level=10
	var foe:Dictionary=game.enemies[0].duplicate(true);foe.pos=Vector2(840,600);foe.hp=1000.0;foe.max_hp=1000.0
	game.enemies.clear();game.enemies.append(foe);game.pulse()
	check(game.adventure.lob_shots.size()==1,"ice orb launches")
	check(game.ice_walls.is_empty() and foe.hp==1000,"no instant damage or wall")
	game.adventure.step_lobs(.4);check(foe.hp==1000,"no damage in flight")
	game.adventure.step_lobs(.5)
	check(foe.hp==965 and game.ice_walls.size()==1,"ice impact deals damage and creates wall")
	check(game.ice_walls[0].pos==Vector2(840,600),"wall at selected location")
	game.selected_character="golfer";game.start_run(false,"grove");game.position_in_world=Vector2(500,600);game.level=10
	foe=game.enemies[0].duplicate(true);foe.pos=Vector2(830,600);foe.hp=1000.0;foe.max_hp=1000.0;game.enemies.clear();game.enemies.append(foe)
	game.fire("secondary");check(foe.hp==1000 and game.adventure.lob_shots.size()==1,"chip launches before impact")
	game.adventure.step_lobs(1);check(foe.hp==976 and game.ice_walls.is_empty(),"chip blast only at landing")
	check(game.manifest.regions.slice(0,3)==["grove","quarry","sunfield"],"intro order unchanged")
	check(game.manifest.regions[-1]=="shattered_oath","five-boss realm last")
	game.selected_character="ram";game.start_run(false,"lantern_marsh");game.position_in_world=Vector2(500,600)
	foe=game.enemies[0].duplicate(true);foe.type="wick_wisp";foe.pos=Vector2(750,600);foe.skill_timer=0;game.enemies.clear();game.enemies.append(foe)
	game.adventure.step(.01);check(game.adventure.lob_shots.size()==1,"enemy fires lob through gameplay")
	game.health=100;game.adventure.step_lobs(.3);check(game.health==100,"enemy damage delayed")
	game.position_in_world+=Vector2(0,200);game.adventure.step_lobs(1)
	check(game.health==100,"dodging landing marker avoids explosion")
	game.position_in_world=Vector2(500,600);game.adventure.launch_lob("enemy",Vector2(750,600),game.position_in_world,{"travel_speed":300,"blast_radius":75},12)
	game.adventure.step_lobs(1);check(game.health==88,"enemy explosion hits standing player")
	game.adventure.launch_lob("solo",game.position_in_world,game.position_in_world,game.characters.golfer.secondary,24)
	game.adventure.step_lobs(.1);check(game.adventure.lob_shots.size()==1,"near cast still visibly travels")
	game.adventure.setup("grove");check(game.adventure.lob_shots.is_empty() and game.adventure.lob_blasts.is_empty(),"realm reset clears shots")
	for voice in game.journey.voices: voice.stop()
	await create_timer(.1).timeout
	game.queue_free();await create_timer(.3).timeout
	var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame
	party.set_process(false);party.role="host";party.my_id="a";party.host_id="a";party.selected_hero="goalie"
	for n in 3:
		var id:String=["a","b","c"][n];party.roster.append({"id":id,"name":id});party._add_player(id,n)
	party._set_mode("arena");party._start_match();party.opponents.clear();party.positions.a=Vector2(500,600);party.local_pos=party.positions.a
	party.positions.b=Vector2(840,600);party.positions.c=Vector2(840,600);party.health.b=100;party.health.c=100;party.levels.a=10;party.pvp_rule="teams";party.teams={"a":0,"b":0,"c":1}
	party._attack("a","special",Vector2.RIGHT,Vector2(840,600))
	check(party.ice_walls.is_empty() and party.health.c==100,"multiplayer delayed impact")
	var packet:Dictionary=JSON.parse_string(JSON.stringify(party.adventure.snapshot()))
	var clone=load("res://scripts/realm_trials.gd").new();clone.receive(packet)
	check(clone.lob_shots.size()==1 and clone.lob_shots[0].end==[840.0,600.0],"network projectile target")
	clone.free();party.adventure.step_lobs(1)
	check(party.health.b==100 and party.health.c<100,"explosion respects PvP teams")
	check(party.ice_walls.size()==1,"multiplayer ice wall on impact")
	party.hero_ids.a="golfer";party.cooldown_at.a={};party.positions.c=Vector2(830,600);party.health.c=100;party.ice_walls.clear()
	party._attack("a","secondary",Vector2.RIGHT,Vector2(830,600));check(party.health.c==100,"multiplayer chip delayed")
	party.adventure.step_lobs(1);check(party.health.c<100 and party.ice_walls.is_empty(),"multiplayer chip damage parity")
	party.mode="coop";party.adventure.setup("clockwork_orchard");party.ice_walls.clear()
	party.opponents.append({"pos":Vector2(750,600),"hp":85.0,"max_hp":85.0,"uid":200,"type":"pendulum_moth","boss":false,"skill_timer":0.0})
	party.adventure.step(.01)
	check(party.adventure.lob_shots.size()==1 and party.adventure.lob_shots[0].owner=="enemy","multiplayer enemy lob")
	party.adventure.setup("")
	for n in 80: party.adventure.launch_lob("a",Vector2(500,600),Vector2(700,600),{},1)
	check(party.adventure.lob_shots.size()==64,"projectile count bounded")
	party.adventure.setup("")
	party.role="guest";party.adventure.launch_lob("a",Vector2.ZERO,Vector2.RIGHT,{},5)
	check(party.adventure.lob_shots.is_empty(),"guest cannot launch authoritative projectiles")
	for voice in party.journey.voices: voice.stop()
	await create_timer(.1).timeout
	party.queue_free();await create_timer(.3).timeout
	print("V19 FAILURES: "+str(failures));quit(failures)
