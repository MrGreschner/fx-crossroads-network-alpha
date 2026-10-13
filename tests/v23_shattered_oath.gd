extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.selected_character="ram";game.start_run(false,"shattered_oath")
	var adventure=game.adventure;var combat=adventure.combat
	check(game.region_size()==Vector2(14000,8120),"realm expanded forty percent per axis")
	adventure.step(.01);check(game.enemies.size()==16,"sixteen hub defenders")
	adventure.step(.01);check(game.enemies.size()==16,"hub defenders spawn once")
	for portal in adventure.portals():check(game.can_stand_at(portal.pos) and game.can_stand_at(portal.destination),"all expanded rifts reachable")
	check(game.can_stand_at(adventure.OATH_EXIT) and game.shot_path_clear(adventure.FINAL_SPAWN,adventure.OATH_EXIT),"exit seal reachable from entrance")
	game.invulnerable_time=10000
	for n in 4:
		var entrance:Dictionary=adventure.portals()[0]
		for portal in adventure.portals():
			if portal.trial==n:entrance=portal;break
		game.position_in_world=entrance.pos;check(adventure.interact("solo"),"enter trial")
		var count:=0;var boss:Dictionary={}
		for foe in game.enemies:
			if int(foe.get("trial_index",-1))==n:
				count+=1;check(game.can_stand_at(foe.pos),"trial enemy has walkable position")
				if bool(foe.boss):boss=foe
		check(count==19 and float(boss.hp)>=850,"expanded trial enemy count and guardian health")
		game.position_in_world=boss.pos+Vector2(-180,0);boss.ranged_timer=0;combat.projectiles.clear();adventure.step(.01)
		check(combat.projectiles.size()>=3,"each guardian has a ranged fan")
		for i in range(game.enemies.size()-1,-1,-1):
			if int(game.enemies[i].get("trial_index",-1))==n:game.damage_enemy(i,99999)
		check(adventure.cleared.has(n),"seal waits for all trial actors")
	check(adventure.cleared.size()==4,"four seals")
	game.position_in_world=adventure.HUB+Vector2(0,728);check(adventure.interact("solo"),"final rift unlocked")
	var thief:Dictionary=game.enemies[-1];check(thief.type=="gilded_usurper" and thief.hp==1300,"harder final boss")
	game.position_in_world=thief.pos-Vector2(250,0);var before:Vector2=thief.pos;adventure.step(.2);check(thief.pos!=before,"thief moves continuously")
	combat.projectiles.clear();thief.ranged_timer=0;adventure.step(.01);check(combat.projectiles.size()>=3,"thief ranged fan")
	combat.projectiles.clear();adventure.warnings.clear();thief.skill_timer=0;thief.skill_step=1;game.invulnerable_time=0;game.health=1000;game.experience=200;game.level=6;adventure.step(.01)
	check(adventure.warnings.size()==1 and adventure.warnings[0].time==.65 and adventure.warnings[0].damage==26,"faster harder soul tax windup")
	thief.skill_timer=99;thief.ranged_timer=99;adventure.step(.66)
	check(game.experience==164 and game.health==974,"soul tax steals more XP and damage")
	game.invulnerable_time=10000
	var destroyed:=0
	while true:
		var index:=-1
		for n in game.enemies.size():
			if game.enemies[n].type=="gilded_usurper":index=n;break
		if index<0:break
		game.damage_enemy(index,99999);destroyed+=1
	check(destroyed==13 and adventure.complete,"boss splits three then nine before completion")
	check(game.experience>164,"stolen XP restored on victory")
	game.position_in_world=adventure.OATH_EXIT;check(adventure.interact("solo") and game.menu=="results","reachable visible seal finishes solo realm")
	for voice in game.journey.voices:voice.stop()
	await create_timer(.1).timeout;game.queue_free();await create_timer(.2).timeout
	var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party.role="host";party.my_id="a";party.host_id="a";party.selected_hero="ram"
	for n in 2:
		var id:String=["a","b"][n];party.roster.append({"id":id,"name":id});party._add_player(id,n)
	party._set_mode("coop")
	for n in party.realm_picker.item_count:
		if str(party.realm_picker.get_item_metadata(n))=="shattered_oath":party.realm_picker.select(n)
	party._start_match();party.adventure.step(.01);check(party.opponents.size()==16 and party.FIELD.size==Vector2(14000,8120),"co-op expanded hub")
	party.adventure.complete=true;party.positions.a=party.adventure.OATH_EXIT;party.local_pos=party.positions.a
	check(party._clear_path(party.adventure.FINAL_SPAWN,party.adventure.OATH_EXIT),"co-op exit seal reachable")
	check(party.adventure.interact("a") and not party.started,"co-op final interaction ends match")
	for voice in party.journey.voices:voice.stop()
	await create_timer(.1).timeout;party.queue_free();await create_timer(.2).timeout
	print("V23 OATH FAILURES: "+str(failures));quit(failures)
