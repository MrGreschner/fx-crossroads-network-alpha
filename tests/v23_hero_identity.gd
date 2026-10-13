extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
	if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func add_foe(game,point:Vector2)->Dictionary:
	game.adventure.spawn("bramble",point,500,false);return game.enemies[-1]
func reset(game,id:String,level:int=6)->void:
	game.hero=game.characters[id];game.level=level;game.enemies.clear();game.bullets.clear();game.enemy_shots.clear();game.ice_walls.clear();game.cooldowns={"primary":0.0,"secondary":0.0,"special":0.0};game.adventure.setup("grove");game.position_in_world=Vector2(800,800);game.obstacles.clear();game.invulnerable_time=0
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.start_run(false,"grove")
	var c=game.adventure.combat
	reset(game,"ferryman")
	var first:Dictionary=add_foe(game,Vector2(870,800));var next:Dictionary=add_foe(game,Vector2(1010,800))
	c.cast("solo",game.hero.special,Vector2.RIGHT,48);c.step(.2)
	check(first.hp==452 and first.pos.x>870 and c.effect_time(c.npc_key(first),"slow")>0,"waterfall damages pushes slows")
	reset(game,"ferryman",4);first=add_foe(game,Vector2(870,800));next=add_foe(game,Vector2(1010,800));var stone:Dictionary=game.hero.secondary.duplicate();stone.count=1;stone.spread=0
	c.cast("solo",stone,Vector2.RIGHT,12);c.step(.1);c.step(.4);check(first.hp==488 and next.hp==500,"stone no bounce before passive")
	reset(game,"ferryman",5);first=add_foe(game,Vector2(870,800));next=add_foe(game,Vector2(1010,800));c.cast("solo",stone,Vector2.RIGHT,12);c.step(.1);c.step(.4)
	check(first.hp==488 and is_equal_approx(next.hp,492.2) and c.projectiles.is_empty(),"stone bounces exactly once at reduced damage")
	reset(game,"dawnblade",4);first=add_foe(game,game.position_in_world+game.aim_direction()*50);game.fire("primary");check(c.statuses.is_empty(),"bleed locked below five")
	game.level=5;game.cooldowns.primary=0;game.fire("primary");var hp:float=first.hp;c.tick_statuses(4)
	check(first.hp==hp-8 and c.statuses.is_empty(),"Mara primary bleed eight damage then expires")
	reset(game,"stormscribe");first=add_foe(game,Vector2(900,800));game.pulse();check(c.adventure.lob_shots.size()==1 and first.hp==500,"wizard special travels before damage")
	var shot:Dictionary=game.adventure.lob_shots[0];first.pos=game.adventure.vec(shot.end);game.adventure.step_lobs(float(shot.flight))
	check(first.hp==445 and game.adventure.lob_blasts[0].cast_visual=="storm","wizard lightning effect on impact")
	reset(game,"magnet",4)
	for n in 3:c.add_anchor("solo",Vector2(850+n*80,800))
	check(c.anchors.size()==2,"two anchors before passive")
	game.level=5;c.add_anchor("solo",Vector2(850,800));check(c.anchors.size()==3,"three anchors at five")
	first=add_foe(game,Vector2(930,800));c.cast("solo",game.hero.special,Vector2.RIGHT,9)
	check(c.wires[0].links.size()==3,"wire joins all three pins")
	c.step(3);check(first.hp==446,"overlapping wire links do not triple damage")
	reset(game,"navigator",4);first=add_foe(game,Vector2(870,800));next=add_foe(game,Vector2(880,840));c.cast("solo",game.hero.secondary,Vector2.RIGHT,27)
	check(c.projectiles.size()==1,"one orb before passive")
	c.step(.15);check(first.hp==473 and next.hp==492,"homing orb direct and modest splash")
	c.setup("grove");game.level=5;c.cast("solo",game.hero.secondary,Vector2.RIGHT,27);check(c.projectiles.size()==2,"twin seeking orbs at five")
	reset(game,"sunflower");c.cast("solo",game.hero.primary,Vector2.RIGHT,5);c.step(.01);check(c.projectiles.size()==1,"seed burst starts one shot")
	c.step(.1);check(c.projectiles.size()==2,"second seed follows first")
	c.step(.1);c.step(.1);check(c.projectiles.size()==4 and c.casts.is_empty(),"four consecutive seeds")
	for seed in c.projectiles:check(c.vec(seed.aim)==Vector2.RIGHT,"seeds follow one straight line")
	reset(game,"goalie",4);first=add_foe(game,Vector2(850,800));game.take_player_damage(3,c.npc_key(first));check(c.statuses.is_empty(),"thorns locked below five")
	game.level=5;game.invulnerable_time=0;game.take_player_damage(3,c.npc_key(first));check(c.effect_time(c.npc_key(first),"slow")==3,"melee attacker slowed three seconds")
	c.setup("grove");game.invulnerable_time=0;game.take_player_damage(3);check(c.statuses.is_empty(),"ranged or DOT does not trigger thorns")
	check(game.hero.secondary.cooldown==2.2,"Frostguard shorter guard cooldown")
	reset(game,"spindle");c.cast("solo",game.hero.primary,Vector2.RIGHT,20);c.cast("solo",game.hero.primary,Vector2.RIGHT,20);c.step(.1)
	check(c.vec(c.projectiles[0].aim).y*c.vec(c.projectiles[1].aim).y<0,"spiral darts alternate curvature")
	c.setup("grove");first=add_foe(game,Vector2(895,800));c.cast("solo",game.hero.secondary,Vector2.RIGHT,10);check(is_equal_approx(c.orbits[0].time,3.4),"Spindle passive extends orbit")
	for n in 40:c.step(.1)
	check(first.hp==470 and c.orbits.is_empty(),"three orbit shards each hit once")
	c.setup("grove");first.pos=Vector2(1040,800);first.hp=500;c.cast("solo",game.hero.special,Vector2.RIGHT,8)
	for n in 30:c.step(.1)
	check(first.hp==452 and first.pos.x<1040 and c.vortices.is_empty(),"vortex pulls six damage ticks and expires")
	check(game.characters.size()==20,"twentieth hero")
	for voice in game.journey.voices:voice.stop()
	await create_timer(.1).timeout;game.queue_free();await create_timer(.2).timeout
	var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party.role="host";party.my_id="a";party.host_id="a";party.selected_hero="goalie"
	for n in 2:
		var id:String=["a","b"][n];party.roster.append({"id":id,"name":id});party._add_player(id,n)
	party._set_mode("descent");party._start_match()
	check(party.art.has("rock") and party.art.rock!=null and party.field_obstacles.size()==6,"all descent rock obstacles have art")
	for rock in party.field_obstacles:check(not party._clear_path(rock.pos,rock.pos),"visible rock position collides")
	party.opponents.clear();party.field_obstacles.clear();party._rebuild_grid();party.positions.a=Vector2(1000,850);party.positions.b=Vector2(1050,850);party.levels.a=5
	party.adventure.spawn("bramble",Vector2(1060,850),500,false);var foe:Dictionary=party.opponents[0];var combat=party.adventure.combat
	party._hurt("a",3,"enemy",combat.npc_key(foe));check(combat.effect_time(combat.npc_key(foe),"slow")==3,"host Frostguard slows NPC melee")
	party.hero_ids.a="ferryman";party.levels.a=6;party._attack("a","special",Vector2.RIGHT);combat.step(.2)
	check(foe.hp<foe.max_hp and combat.effect_time(combat.npc_key(foe),"slow")>0 and party.health.b==party._max_hp("b"),"host waterfall excludes ally")
	party.hero_ids.a="spindle";party.cooldown_at.a.secondary=0;party._attack("a","secondary",Vector2.RIGHT)
	var packet:Dictionary=JSON.parse_string(JSON.stringify(party.adventure.snapshot()));check(packet.combat.orbits.size()==1,"new orbital style serializes for guests")
	for voice in party.journey.voices:voice.stop()
	await create_timer(.1).timeout;party.queue_free();await create_timer(.2).timeout
	print("V23 FAILURES: "+str(failures));quit(failures)
