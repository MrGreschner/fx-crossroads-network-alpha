extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func cell(point:Vector2)->Vector2i:return Vector2i(floori(point.x/50),floori(point.y/50))
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 game.selected_character="sunflower";game.start_run(false,"honeyglass");game.enemies.clear();game.position_in_world=Vector2(2000,1500);game.health=70
 var combat=game.adventure.combat;var extra=game.adventure.expansion
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,8);check(extra.plants.size()==1,"Sunpetal plants a seed")
 extra.plants[0].pos=[2000,1500];extra.step(.6);extra.step(2.9);check(game.health==70 and combat.projectiles.is_empty(),"three-second planted growth delay before heal/fire")
 game.adventure.spawn("bramble",Vector2(2200,1500),100,false);extra.step(.11);extra.step(1.01)
 check(game.health==73 and combat.projectiles.size()>0 and combat.projectiles[0].stats.flame_orb,"bloom heals caster and fires visible fireball")
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,8);combat.cast("solo",game.hero.secondary,Vector2.RIGHT,8);check(extra.plants.size()==2,"plant cap two")
 game.selected_character="veyra";game.start_run(false,"honeyglass");game.enemies.clear();game.position_in_world=Vector2(2000,1500)
 game.adventure.spawn("bramble",Vector2(2190,1500),200,false);combat.cast("solo",game.hero.primary,Vector2.RIGHT,18)
 for n in 10:combat.step_projectiles(.04)
 check(extra.brands.size()==1 and game.enemies[0].hp<200,"echo brand starts on projectile impact")
 game.enemies[0].pos+=Vector2(150,0);var before:float=game.enemies[0].hp;extra.step(1.21);check(game.enemies[0].hp<before-10.8,"enemy travel strengthens delayed echo")
 combat.projectiles.clear();combat.cast("solo",game.hero.secondary,Vector2.RIGHT,14);var center:Vector2=extra.vec(extra.nets[0].pos)
 for n in 8:combat.launch_projectile("enemy",center+Vector2(n,0),Vector2.LEFT,{"range":500,"speed":200},20)
 extra.step(.1);check(extra.nets[0].count==6 and combat.projectiles.size()==2,"snare absorbs capped six enemy shots")
 extra.step(2.5);var reflected:=0
 for shot in combat.projectiles:
  if shot.owner=="solo":reflected+=1
 check(reflected==6,"stored shots return as friendly volley")
 combat.projectiles.clear();extra.brands.clear();game.enemies.clear()
 for x in [2200,2270,2350]:game.adventure.spawn("bramble",Vector2(x,1500),200,false)
 combat.cast("solo",game.hero.special,Vector2.RIGHT,10);extra.step(.01)
 var other_before:float=game.enemies[1].hp;game.damage_enemy(0,40);extra.step(.01)
 check(is_equal_approx(game.enemies[1].hp,other_before-10) and extra.shares.is_empty(),"ledger shares 25% once without recursion")
 game.enemies.clear();game.adventure.spawn("ashen_revenant",Vector2(2200,1500),135,false);var kills:int=game.kills;game.damage_enemy(0,150)
 check(game.enemies.size()==1 and game.enemies[0].hp==25 and game.kills==kills,"first lethal hit leaves finishing window without kill/XP")
 game.damage_enemy(0,30);check(game.enemies.is_empty() and game.kills==kills+1,"finishing blow prevents resurrection")
 game.adventure.spawn("ashen_revenant",Vector2(2200,1500),135,false);game.damage_enemy(0,150);extra.step(3.01);check(game.enemies[0].hp>25 and game.enemies[0].down_time==0,"unfinished revenant revives once")
 game.enemies.clear();game.adventure.spawn("gravity_husk",Vector2(2200,1500),190,false);extra.step(.01);check(combat.effect_time("p:solo","slow")>0,"husk aura slows player")
 game.position_in_world=Vector2(1800,1500);combat.tick_statuses(.3);extra.step(.01);check(combat.effect_time("p:solo","slow")==0,"slow ends after leaving aura")
 game.enemies.clear();combat.projectiles.clear();game.adventure.spawn("singularity_oracle",Vector2(2200,1500),125,false);game.enemies[0].v43_attack=0;extra.step(.01);check(extra.holes.size()==1,"oracle creates warned singularity")
 var original:Vector2=game.position_in_world;extra.holes[0].pos=[1900,1500];extra.step(.8);check(game.position_in_world==original,"black hole provides warning time")
 extra.step(.3);check(game.position_in_world.x>original.x,"active black hole pulls toward center")
 extra.step(2);check(combat.projectiles.size()>=10,"singularity bursts radial energy balls")
 game.enemies.clear();game.adventure.spawn("chrysalis_knight",Vector2(2200,1500),185,false);game.enemies[0].hp=92.5;extra.step(6.01);check(game.enemies[0].type=="exalted_wraith" and is_equal_approx(game.enemies[0].hp,game.enemies[0].max_hp*.5),"morph preserves damage fraction")
 game.enemies.clear();game.adventure.spawn("mercy_cantor",Vector2(2200,1500),110,false);game.adventure.spawn("ashen_revenant",Vector2(2260,1500),135,false);game.enemies[1].hp=50;game.enemies[0].v43_attack=0;extra.step(.01);check(game.enemies[1].hp==80,"cantor heals nearby ally")
 game.enemies.clear();game.adventure.spawn("brood_reliquary",Vector2(2200,1500),230,false)
 for n in 6:game.enemies[0].v43_attack=0;extra.step(.01)
 check(game.enemies.size()==4,"nest caps at three living minions")
 game.enemies.clear();game.adventure.spawn("singularity_oracle",game.position_in_world+Vector2(30,0),125,false);var close_before:Vector2=game.enemies[0].pos;extra.step(.1)
 check((game.enemies[0].pos as Vector2).distance_to(game.position_in_world)>close_before.distance_to(game.position_in_world),"new ranged foe retreats even at melee contact")
 game.start_run(false,"astral_rift");var husks:=0;var oracles:=0
 for foe in game.enemies:
  if foe.type=="gravity_husk":husks+=1;check(game.can_stand_at(foe.pos),"Astral husk placement clear")
  if foe.type=="singularity_oracle":oracles+=1;check(game.can_stand_at(foe.pos),"Astral oracle placement clear")
 check(husks==3 and oracles==3,"Astral Rift includes both new enemy species")
 game.start_run(false,"ebonwake");extra.step(.01);check(extra.active and game.enemies.size()==26,"expert citadel loads all authored enemies")
 for enemy in game.enemies:
  check(extra.can_stand(enemy.pos),"clear spawn "+str(enemy.type))
  check(not extra.grid.get_id_path(cell(Vector2(430,2700)),cell(enemy.pos)).is_empty(),"reachable spawn "+str(enemy.type))
 check(not extra.grid.get_id_path(cell(Vector2(430,2700)),cell(Vector2(7750,3500))).is_empty(),"boss court reachable")
 game.enemies.clear();extra.step(.01);check(game.enemies.size()==1 and game.enemies[0].type=="last_creditor","boss appears after all original patrols")
 game.position_in_world=Vector2(7500,3500)
 for n in 3:game.enemies[0].v43_attack=0;extra.step(.01)
 check(game.adventure.warnings.size()>=3 and combat.projectiles.size()>=5 and extra.holes.size()>0,"Creditor uses marked blasts, ranged fan and singularity")
 var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party._set_mode("defense");party._solo();party._set_mode("coop")
 for n in party.realm_picker.item_count:
  if str(party.realm_picker.get_item_metadata(n))=="ebonwake":party.realm_picker.select(n)
 party._start_match();party.adventure.step(.01);check(party.opponents.size()==26 and party.adventure.expansion.active,"co-op authored expert map avoids ordinary wave progression")
 for slot in 4:check(party.adventure.expansion.can_stand(party._spawn_player(slot)),"all four Citadel co-op starts walkable")
 party.opponents.clear();party.adventure.spawn("ashen_revenant",party.local_pos+Vector2(100,0),135,false);party._hit_enemy(0,200,party.my_id);check(party.opponents[0].down_time==3,"host revival interception")
 var packet:Dictionary=party._snapshot();check(packet.enemies[0].uid==party.opponents[0].uid and packet.enemies[0].down_time>0,"stable IDs and fallen state synchronize")
 party.adventure.expansion.receive(JSON.parse_string(JSON.stringify(packet.adventure.expansion)));check(party.adventure.expansion.boss_started==packet.adventure.expansion.boss_started,"construct snapshots round-trip")
 party._set_mode("arena");party.adventure.setup("arena");party.pvp_rule="teams";party.teams={"solo":0,"friend":0,"rival":1};party.positions={"solo":Vector2(2000,1500),"friend":Vector2(2010,1500),"rival":Vector2(2020,1500)};party.local_pos=party.positions.solo
 party.health={"solo":70,"friend":70,"rival":70};party.hero_ids={"solo":"sunflower","friend":"ram","rival":"ram"};party.levels={"solo":6,"friend":6,"rival":6};party.inventory={"solo":[],"friend":[],"rival":[]}
 party.adventure.combat.cast("solo",party.characters.sunflower.secondary,Vector2.RIGHT,8);var garden=party.adventure.expansion;garden.plants[0].pos=[2000,1500];garden.step(.6);garden.step(3.1);garden.step(1.01)
 check(party.health.solo==76 and party.health.friend==76 and party.health.rival==70,"PvP flowers heal caster/team only")
 party.adventure.combat.projectiles.clear();garden.plants.clear();garden.cast("solo",party.characters.veyra.secondary,Vector2.RIGHT,14);var trap_center:Vector2=garden.vec(garden.nets[0].pos)
 for owner in ["friend","rival"]:party.adventure.combat.launch_projectile(owner,trap_center,Vector2.RIGHT,{"range":300},10)
 garden.step(.01);check(garden.nets[0].count==1 and party.adventure.combat.projectiles.size()==1 and party.adventure.combat.projectiles[0].owner=="friend","PvP snare catches rivals without consuming allied shots")
 for voice in game.journey.voices:voice.stop()
 for voice in party.journey.voices:voice.stop()
 game.queue_free();party.queue_free();await create_timer(.3).timeout
 print("V43 FAILURES: "+str(failures));quit(failures)
