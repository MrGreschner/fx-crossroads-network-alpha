extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func foe(game,point:Vector2,hp:float=500)->Dictionary:
	game.adventure.spawn("bramble",point,hp,false)
	return game.enemies[-1]
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
	game.selected_character="sunflower";game.start_run(false,"grove");game.enemies.clear();game.obstacles.clear();game.position_in_world=Vector2(800,800);game.level=6
	var combat=game.adventure.combat
	var enemy:Dictionary=foe(game,Vector2(930,800))
	combat.burn_foe(enemy,"solo")
	for n in 5:combat.tick_statuses(1)
	check(enemy.hp==490,"burn 2 per second")
	combat.burn_foe(enemy,"solo");combat.burn_foe(enemy,"solo")
	combat.tick_statuses(1);check(enemy.hp==488,"repeated burns refresh without stacking")
	combat.setup("grove");enemy.hp=500;combat.burn_foe(enemy,"solo");combat.tick_statuses(10);check(enemy.hp==480 and combat.statuses.is_empty(),"burn ends after exactly 20 damage")
	game.bullets.clear();game.spawn_hero_projectiles(game.hero.primary,13,Vector2.RIGHT,false)
	check(game.bullets.size()==4 and game.bullets[0].damage==7,"four seeds split gear bonus")
	combat.cast("solo",game.hero.special,Vector2.RIGHT,90);combat.step(2.4);check(enemy.hp==480 and combat.busy("solo"),"beam charges before damage")
	combat.step(.1);check(enemy.hp==390 and not combat.busy("solo"),"charged wide beam releases once")
	combat.step(.5);check(enemy.hp==390,"beam does not repeat damage")
	combat.setup("grove");game.hero=game.characters.snowman;enemy.hp=500
	combat.cast("solo",game.hero.secondary,Vector2.RIGHT,0);combat.step(.1)
	check(combat.speed_factor(combat.npc_key(enemy))==.55 and combat.reduction("solo")==.3,"aura slows nearby foe and protects caster")
	enemy.pos=Vector2(1200,800);combat.step(.2);check(combat.speed_factor(combat.npc_key(enemy))==1,"leaving aura removes slow")
	game.health=100;game.level=1;game.invulnerable_time=0;game.take_player_damage(10);check(is_equal_approx(game.health,93),"caster takes 30 percent less damage")
	combat.setup("grove");enemy.pos=Vector2(1050,800);enemy.hp=500;combat.cast("solo",game.hero.special,Vector2.RIGHT,22)
	combat.step(.7);check(float(combat.projectiles[0].radius)>12,"snowball grows with travel")
	combat.step(.2);check(enemy.hp<478 and enemy.pos.x>1050 and combat.projectiles.size()==6,"snowball damages knocks back and fragments")
	combat.setup("grove");game.hero=game.characters.drum;enemy.pos=Vector2(870,800);enemy.hp=500
	var opposite:Dictionary=foe(game,Vector2(730,800))
	combat.cast("solo",game.hero.primary,Vector2.RIGHT,14);combat.step(.4);combat.step(.4)
	check(enemy.hp==486 and opposite.hp==486,"sound ring hits all directions once")
	game.enemy_shots.append({"pos":Vector2(860,800),"direction":Vector2.LEFT});combat.cast("solo",game.hero.secondary,Vector2.RIGHT,8);combat.step(.15)
	check(game.enemy_shots.is_empty(),"drum erases hostile projectiles")
	combat.step(.8);check(enemy.hp==462,"three short bursts")
	combat.cast("solo",game.hero.special,Vector2.RIGHT,45);combat.step(.2)
	var saved:Vector2=enemy.pos;game.update_enemies(.1)
	check(enemy.pos==saved and combat.stunned(combat.npc_key(enemy)),"big bang stuns movement")
	combat.tick_statuses(2);check(not combat.stunned(combat.npc_key(enemy)),"stun lasts two seconds")
	combat.setup("grove");game.hero=game.characters.magnet;enemy.hp=500;enemy.pos=Vector2(920,800)
	combat.add_anchor("solo",Vector2(880,800));combat.add_anchor("solo",Vector2(1000,800));combat.add_anchor("solo",Vector2(890,800));check(combat.owner_anchors("solo").size()==2,"magnet caps two anchors")
	combat.cast("solo",game.hero.secondary,Vector2.RIGHT,22);check(enemy.hp==478 and enemy.pos.x<920,"magnet pull damage and movement")
	combat.cast("solo",game.hero.special,Vector2.RIGHT,9);combat.step(3);check(enemy.hp==424 and combat.wires.is_empty(),"wire has six bounded ticks")
	combat.setup("grove");enemy.pos=Vector2(1000,800);enemy.hp=500
	game.adventure.launch_lob("solo",game.position_in_world,enemy.pos,game.characters.goalie.special,35);game.adventure.step_lobs(1)
	check(combat.effect_time(combat.npc_key(enemy),"slow")==3,"Frostguard landing applies slow")
	combat.setup("grove");game.hero=game.characters.welder;game.level=3;enemy.pos=game.position_in_world+game.aim_direction()*70;enemy.hp=500
	game.flame_bursts.append({"time":.9,"tick":0.0,"ticks":5,"damage":8.0,"stats":game.hero.secondary});game.update_flames(.01)
	check(enemy.hp==492 and combat.effect_time(combat.npc_key(enemy),"burn")==10,"actual welder flame applies burn and direct damage")
	combat.setup("grove");game.hero=game.characters.sunflower;game.health=50;game.enemies.clear();game.cooldowns.secondary=0;game.fire("secondary")
	check(game.health==50 and game.adventure.expansion.plants.size()==1,"sunflower seed has no instant healing")
	game.adventure.expansion.plants[0].pos=[game.position_in_world.x,game.position_in_world.y]
	for n in 52:game.adventure.expansion.step(.1)
	check(game.health>50,"sunflower planted bloom heals after its charge")
	game.selected_character="ram";game.start_run(false,"folded_coast");game.invulnerable_time=9999
	check(combat.coast.active and game.enemies.size()==30,"medium paper realm populated")
	for e in game.enemies:check(game.can_stand_at(e.pos),"paper enemies on walkable islands")
	game.position_in_world=combat.coast.GATES[0];check(game.adventure.interact("solo") and game.position_in_world.x>5000,"paired folds teleport player")
	game.bullets.clear();game.bullets.append({"pos":combat.coast.GATES[0],"direction":Vector2.RIGHT});combat.coast.step(.01);check(game.bullets[0].pos.x>5000,"paired folds teleport projectile");game.bullets.clear()
	game.enemies.clear();game.kills=30;game.boss_spawned=false;game.maybe_spawn_boss();check(game.enemies[-1].type=="cartographer","custom final boss")
	game.position_in_world=Vector2(5200,1500)
	for n in 125:combat.step(.1)
	check(not combat.projectiles.is_empty() or not combat.pools.is_empty() or not combat.coast.pending.is_empty(),"boss cycles new attacks")
	var manifest:Dictionary=game.load_json("res://content/manifest.json") if game.has_method("load_json") else JSON.parse_string(FileAccess.get_file_as_string("res://content/manifest.json"))
	var index:int=manifest.characters.find("baseball")
	for id in manifest.characters.slice(index):check(not str(game.characters[id].passive).contains("from level"),"later passive wording: "+id)
	for voice in game.journey.voices:voice.stop()
	await create_timer(.1).timeout;game.queue_free();await create_timer(.2).timeout
	var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false)
	party.role="host";party.my_id="a";party.host_id="a";party.selected_hero="drum"
	for n in 2:
		var id:String=["a","b"][n];party.roster.append({"id":id,"name":id});party._add_player(id,n)
	party._set_mode("descent");party._start_match();party.opponents.clear();party.field_obstacles.clear();party.positions.a=Vector2(1200,850);party.local_pos=party.positions.a;party.positions.b=Vector2(1250,850);party.levels.a=6;party.health.b=party._max_hp("b")
	var c=party.adventure.combat;party.adventure.spawn("bramble",Vector2(1300,850),500,false)
	party._attack("a","special",Vector2.RIGHT);c.step(.2)
	check(is_equal_approx(party.opponents[0].hp,party.opponents[0].max_hp-45*1.08) and c.stunned(c.npc_key(party.opponents[0])) and party.health.b==party._max_hp("b"),"host stun damage excludes ally")
	var packet:Dictionary=JSON.parse_string(JSON.stringify(party.adventure.snapshot()))
	var clone=load("res://scripts/realm_trials.gd").new();root.add_child(clone);clone.receive(packet)
	check(clone.combat.statuses.size()>0 and clone.combat.remote_indicators.size()>0,"status and indicators survive network serialization")
	clone.queue_free()
	for voice in party.journey.voices:voice.stop()
	await create_timer(.1).timeout;party.queue_free();await create_timer(.2).timeout
	print("V21 FAILURES: "+str(failures));quit(failures)
