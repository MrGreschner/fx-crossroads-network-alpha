extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
	game.selected_character="medic";game.start_run(false,"grove");game.enemies.clear();game.obstacles.clear();game.position_in_world=Vector2(800,800)
	var c=game.adventure.combat
	game.adventure.spawn("bramble",game.position_in_world+game.aim_direction()*50,500,false)
	var foe:Dictionary=game.enemies[0]
	game.fire("primary");check(foe.hp==469 and c.effect_time(c.npc_key(foe),"poison")==4,"actual kick adds poison")
	c.tick_statuses(4);check(foe.hp==465 and c.statuses.is_empty(),"four damage over four seconds")
	game.cooldowns.primary=0;game.fire("primary");c.tick_statuses(.5);game.cooldowns.primary=0;game.fire("primary");c.tick_statuses(.5)
	check(foe.hp==402,"refresh preserves tick and does not stack")
	check(game.ability_info(game.hero.primary,"primary").contains("Poisons"),"preview explains poison")
	check(c.indicators()[0].flags.has("poison"),"purple poison indicator")
	for voice in game.journey.voices:voice.stop()
	await create_timer(.1).timeout;game.queue_free();await create_timer(.2).timeout
	var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false)
	party.role="host";party.my_id="a";party.host_id="a";party.selected_hero="medic"
	for n in 3:
		var id:String=["a","b","c"][n];party.roster.append({"id":id,"name":id});party._add_player(id,n)
	party._set_mode("arena");party._start_match();party.opponents.clear();party.field_obstacles.clear();party.pvp_rule="teams";party.teams={"a":0,"b":1,"c":0}
	party.positions.a=Vector2(1000,1000);party.positions.b=Vector2(1050,1000);party.positions.c=Vector2(1040,1000)
	var combat=party.adventure.combat
	party._attack("a","primary",Vector2.RIGHT)
	check(combat.effect_time("p:b","poison")==4 and combat.effect_time("p:c","poison")==0,"PvP poisons rival only")
	var hp:int=party.health.b;combat.tick_statuses(4);check(party.health.b==hp-4,"PvP poison damage")
	party.invincible_until.b=Time.get_ticks_msec()+10000;party.cooldown_at.a.primary=0;party._attack("a","primary",Vector2.RIGHT)
	check(combat.effect_time("p:b","poison")==0,"invulnerable rival rejects poison")
	party._set_mode("descent");party._start_match();party.opponents.clear();party.field_obstacles.clear();party.positions.a=Vector2(1000,850)
	party.adventure.spawn("bramble",Vector2(1050,850),500,false);var enemy:Dictionary=party.opponents[0];var before:float=enemy.hp
	party._attack("a","primary",Vector2.RIGHT);combat.tick_statuses(4);check(enemy.hp==before-35,"multiplayer NPC kick and poison")
	for voice in party.journey.voices:voice.stop()
	await create_timer(.1).timeout;party.queue_free();await create_timer(.2).timeout
	print("V22 FAILURES: "+str(failures));quit(failures)
