extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.selected_character="beaver";game.start_run(false,"elementary");game.enemies.clear();game.position_in_world=Vector2(3800,5400);game.level=6
 var combat=game.adventure.combat;var kit=combat.v48;var order:Array=game.manifest.characters
 check(order.size()>=32 and order[order.find("iris")-1]=="beaver" and order[order.find("nera")+1]=="teapot" and order[order.find("rune_duelist")+1]=="garrick","32 heroes and requested exact ordering")
 check(game.art.has("beaver_attack") and game.art.has("teapot_walk1"),"original new sprites imported")
 game.adventure.spawn("pencil_scrapper",Vector2(3860,5400),300,false);game.adventure.spawn("pencil_scrapper",Vector2(3680,5400),300,false)
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,28);check(game.enemies[0].hp==272 and game.enemies[1].hp==300,"bite close and directional")
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,26);var key:String=combat.npc_key(game.enemies[0])
 check(combat.effect_time(key,"stun")>0 and game.enemies[0].pos.x>3860 and is_equal_approx(combat.reduction("solo"),.02),"tail knocks, stuns and grants armour")
 kit.stun_target("solo",key,1.2);check(is_equal_approx(combat.reduction("solo"),.02),"same foe refreshes without adding armour")
 for n in 12:
  game.adventure.spawn("pencil_scrapper",Vector2(4000+n*5,5500),300,false);kit.stun_target("solo",combat.npc_key(game.enemies[-1]),1)
 check(is_equal_approx(combat.reduction("solo"),.2),"armour capped at twenty percent")
 kit.step(8.1);check(combat.reduction("solo")==0,"armour expires")
 game.enemies.clear();combat.statuses.clear();game.adventure.spawn("pencil_scrapper",Vector2(4000,5400),300,false);game.adventure.spawn("pencil_scrapper",Vector2(4000,5500),300,false)
 combat.cast("solo",game.hero.special,Vector2.RIGHT,65);kit.step(1.09);check(game.enemies[0].hp==300,"tree cannot damage during load/fall")
 kit.step(.02);check(game.enemies[0].hp==235 and game.enemies[1].hp==300 and combat.effect_time(combat.npc_key(game.enemies[0]),"stun")>0,"fallen tree damages only its lane and stuns")
 game.selected_character="teapot";game.start_run(false,"elementary");game.level=6;game.enemies.clear();game.position_in_world=Vector2(3800,5400)
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,18);check(combat.projectiles.size()==2 and combat.projectiles[0].damage==9,"two low-damage poison drops")
 game.adventure.spawn("pencil_scrapper",Vector2(3880,5400),300,false);key=combat.npc_key(game.enemies[0]);combat.apply_status(key,"poison",4,"solo",1);game.health=80
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,12);kit.step(.15)
 check(kit.moving("solo") and game.position_in_world.x>3800 and game.position_in_world.x<3880 and kit.visual_offset("solo").y<0 and combat.speed_factor("p:solo")==0,"smooth vulnerable hop with visual lift and input lock")
 game.invulnerable_time=0;game.take_player_damage(10);check(game.health==70,"hopping grants no damage immunity");game.health=80
 kit.step(.15);check(kit.puddles.size()==1 and game.health==82 and game.enemies[0].hp==288,"first landing poisons, hits and heals only from passive")
 kit.step(.6);check(not kit.moving("solo") and kit.puddles.size()==3 and is_equal_approx(game.position_in_world.x,4040),"three hops complete at intended destination")
 game.enemies.clear();game.adventure.spawn("pencil_scrapper",Vector2(4260,5400),300,false)
 combat.cast("solo",game.hero.special,Vector2.RIGHT,38);kit.step(.99);check(game.enemies[0].hp==300,"cup warns before eruption")
 kit.step(.02);check(game.enemies[0].hp==262 and combat.effect_time(combat.npc_key(game.enemies[0]),"poison")>0,"cup erupts with poison damage")
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,12);game.health=0;kit.step(.1);check(not kit.moving("solo"),"death cancels hop")
 game.health=100;var packet:Dictionary=JSON.parse_string(JSON.stringify(combat.snapshot()));check(packet.has("v48") and packet.v48.puddles.size()==3,"effects survive multiplayer JSON")
 combat.setup("elementary");check(kit.puddles.is_empty() and kit.armour.is_empty(),"run reset clears new effects")
 var host=load("res://scenes/arcade.tscn").instantiate();root.add_child(host);await process_frame;host.set_process(false);host._set_mode("defense");host._solo();host._add_player("friend",1);host.hero_ids.friend="teapot";host.levels.friend=6
 var hc=host.adventure.combat;hc.cast("friend",host.characters.teapot.secondary,Vector2.RIGHT,12);hc.v48.step(.15)
 var friend_key:String=hc.player_key(host.my_id);var hp_before:float=host.health[host.my_id]
 hc.v48.area("friend",host.positions[host.my_id],150,38);check(host.health[host.my_id]==hp_before and hc.effect_time(friend_key,"poison")==0,"co-op allies cannot be poisoned or hit")
 var snapshot:Dictionary=JSON.parse_string(JSON.stringify(host._snapshot()));check(snapshot.players.friend.charging and snapshot.adventure.combat.v48.hops.has("friend"),"host replicates remote hopping movement")
 var guest=load("res://scenes/arcade.tscn").instantiate();root.add_child(guest);await process_frame;guest.set_process(false);guest._set_mode("defense");guest._solo();guest.role="guest";guest.host_id="host";guest.my_id="friend";guest._packet("host",snapshot)
 var before:float=guest.adventure.combat.v48.hops.friend.elapsed;guest.adventure.combat.v48.step(.5);check(guest.adventure.combat.v48.hops.friend.elapsed==before,"guest cannot simulate extra hits or movement")
 for node in [game,host,guest]:
  for voice in node.journey.voices:voice.stop()
  node.queue_free()
 await create_timer(.3).timeout;print("V48 FAILURES: "+str(failures));quit(failures)
