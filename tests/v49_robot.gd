extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.selected_character="robot";game.start_run(false,"elementary");game.enemies.clear();game.position_in_world=Vector2(3800,5400);game.level=6
 var combat=game.adventure.combat;var bot=combat.robot
 check(game.manifest.characters.size()>=33 and game.manifest.regions.size()>=22 and game.hero.name=="Bolt Ironcore" and game.art.has("robot_attack"),"33 heroes, 22 realms and original robot art")
 game.adventure.spawn("pencil_scrapper",Vector2(3880,5400),600,false)
 for n in 3:combat.cast("solo",game.hero.primary,Vector2.RIGHT,30)
 check(game.enemies[0].hp==510 and bot.charge.solo==3,"three successful close jabs charge reserve")
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,14);check(bot.volleys[0].total==5 and bot.charge.solo==0,"charged volley adds one missile and consumes reserve")
 bot.step(.05);check(bot.rockets.size()==1 and game.enemies[0].hp==510 and bot.rockets[0].age>0,"missiles travel before impact")
 for n in 40:bot.step(.05)
 check(game.enemies[0].hp<510 and game.enemies[0].hp>=440 and bot.volleys.is_empty(),"five rockets hit with bounded direct damage")
 bot.reset();game.enemies.clear();game.adventure.spawn("pencil_scrapper",Vector2(3870,5400),500,false);game.adventure.spawn("pencil_scrapper",Vector2(4000,5400),500,false)
 combat.cast("solo",game.hero.special,Vector2.RIGHT,0);check(bot.transformed("solo") and is_equal_approx(combat.speed_factor("p:solo"),.42),"saw transforms and slows owner to 42 percent")
 game.fire("primary");bot.step(.3);check(game.enemies[0].hp==500,"transform load causes no early hit or stomp")
 bot.step(.16);check(game.enemies[0].hp==488 and game.enemies[1].hp==500,"saw contacts only nearby foes")
 bot.step(.3);check(game.enemies[0].hp==476,"saw repeats contact damage")
 game.cooldowns.primary=0;game.fire("primary");var key:String=combat.npc_key(game.enemies[0])
 check(game.enemies[0].hp==460 and combat.effect_time(key,"stun")>0 and combat.effect_time(key,"slow")>0,"actual primary switches to stun-and-slow stomp")
 game.fire("primary");check(game.enemies[0].hp==460,"stomp cooldown prevents spam")
 var before:float=bot.forms.solo.time;game.cooldowns.special=0;game.fire("special");game.cooldowns.secondary=0;game.fire("secondary")
 check(bot.forms.solo.time==before and bot.volleys.is_empty(),"form cannot restart or use normal missiles")
 game.health=100;game.invulnerable_time=0;game.take_player_damage(20);check(game.health==86,"saw reduces damage by 30 percent without immunity")
 bot.step(6);check(not bot.transformed("solo") and combat.speed_factor("p:solo")==1 and combat.effective_stats("solo","primary",game.hero.primary).style=="piston_jab","finite form restores movement and primary")
 combat.cast("solo",game.hero.special,Vector2.RIGHT,0);game.health=0;bot.step(.1);check(bot.forms.is_empty(),"death cancels form")
 game.start_run(false,"neon_crucible");game.level=6;game.invulnerable_time=100;var tech=game.adventure.tech
 check(tech.active and game.enemies.is_empty(),"new realm initializes without generic enemies or premature boss")
 for body in tech.data.bodies:
  var point:Vector2=tech.v(body.pos);var cell:=Vector2i(floori(point.x/50),floori(point.y/50))
  check(tech.can_stand(point) and not tech.grid.get_point_path(Vector2i(11,64),cell).is_empty(),"connected route from arrival to "+str(body.name))
 for entry in tech.data.spawns:check(tech.can_stand(tech.v(entry.pos)),"authored enemy spawn is walkable")
 check(tech.can_stand(tech.v(tech.data.exit)),"completion exit is accessible")
 tech.step(.05);check(game.enemies.size()==44 and not tech.boss_live,"six machine roles populate the whole realm once")
 var turret:Dictionary={}
 for enemy in game.enemies:
  if str(enemy.type)=="hatch_sentinel":turret=enemy;break
 game.position_in_world=turret.pos+Vector2(0,-400);tech.step(.4);check(turret.buried,"turret rises with a warning before vulnerable active state")
 tech.step(.4);check(not turret.buried,"turret emerges from ground")
 combat.projectiles.clear();tech.hazards.clear();tech.skill(turret,game.position_in_world);tech.step_hazards(.49);check(combat.projectiles.is_empty(),"turret does not fire before warning")
 tech.step_hazards(.02);check(combat.projectiles.size()==3,"turret fires its real fan after warning")
 combat.projectiles.clear();tech.hazards.clear();game.position_in_world=Vector2(550,3200)
 for n in range(game.enemies.size()-1,-1,-1):
  if int(game.enemies[n].get("tech_sector",-1))==0:game.enemies[n].buried=false;game.damage_enemy(n,100000)
 game.menu="";tech.step(.01);check(tech.boss_live and tech.stage==0,"foundry clear awakens first Continuum body")
 for expected in 4:
  var index:=-1
  for n in game.enemies.size():
   if str(game.enemies[n].type)==str(tech.data.bodies[expected].type):index=n;break
  check(index>=0,"correct body spawned at stage "+str(expected))
  if index<0:break
  game.damage_enemy(index,100000);check(tech.stage==expected+1 and (not game.boss_defeated if expected<3 else game.boss_defeated),"intermediate defeat cannot finish realm")
  if expected<3:
   tech.step(2.49);check(not tech.boss_live,"upload has visible delay")
   tech.step(.02);check(tech.boss_live,"intelligence uploads into distant next chassis")
 check(tech.done and tech.wrecks.size()==4,"all four bodies required for victory")
 game.position_in_world=tech.v(tech.data.exit);game.menu="";tech.interact("solo");check(game.menu=="results" and game.result_text.begins_with("CLEARED"),"reachable uplink interaction completes run")
 game.start_run(false,"neon_crucible");game.level=6;game.enemies.clear();game.position_in_world=Vector2(2600,650);game.adventure.spawn("sweep_drone",Vector2(2820,650),300,false)
 bot.launch("solo",game.position_in_world,Vector2.RIGHT,14,combat.npc_key(game.enemies[0]));bot.step(.2);check(bot.rockets.is_empty() and game.enemies[0].hp==300,"server racks stop missiles and prevent through-wall splash")
 game.enemies.clear();game.position_in_world=Vector2(3125,700);game.adventure.spawn("fork_runner",Vector2(3275,700),300,false)
 combat.cast("solo",game.hero.special,Vector2.RIGHT,0);bot.step(.5);combat.cast("solo",{"style":"saw_stomp"},Vector2.RIGHT,16);check(game.enemies[0].hp==300,"stomp cannot damage through a console")
 game.start_run(false,"neon_crucible");game.level=6;game.invulnerable_time=100;tech.initialized=true;game.enemies.clear();game.position_in_world=Vector2(1250,2200)
 var hauler:Dictionary=tech.spawn("magnet_hauler",Vector2(1000,1900),0);hauler.hp=70
 tech.spawn("repair_wisp",Vector2(1140,1900),0);tech.step(1);check(hauler.hp==76,"repair wisp actually repairs nearby machines")
 game.enemies.clear();var drone:Dictionary=tech.spawn("sweep_drone",Vector2(1200,1800),0);game.position_in_world=Vector2(1230,1800);var gap:float=drone.pos.distance_to(game.position_in_world);tech.step(.15);check(drone.pos.distance_to(game.position_in_world)>gap,"ranged drones retreat from melee users")
 tech.hazards.clear();combat.projectiles.clear();var runner:Dictionary=tech.spawn("fork_runner",Vector2(1000,1800),0);tech.skill(runner,Vector2(1200,1800));var start:Vector2=runner.pos;tech.step_hazards(.64);check(runner.pos==start,"runner warns before rush");tech.step_hazards(.03);check(runner.pos.x>start.x,"runner moves physically during rush")
 for kind in ["continuum_forge","continuum_archive","continuum_reactor","continuum_crown"]:
  var enemy:Dictionary=tech.spawn(kind,Vector2(1050,1900),0,true);var initial:int=tech.hazards.size()+combat.robot.rockets.size()+combat.projectiles.size()
  for n in (4 if kind=="continuum_crown" else 3):tech.skill(enemy,Vector2(1250,2050))
  check(tech.hazards.size()+combat.robot.rockets.size()+combat.projectiles.size()>initial,"different attacks authored for "+kind)
 check(tech.hazards.size()<=64 and combat.robot.rockets.size()<=64,"effects and rockets bounded")
 var host=load("res://scenes/arcade.tscn").instantiate();root.add_child(host);await process_frame;host.set_process(false);host._set_mode("defense");host._solo();host._set_mode("coop");
 for n in host.realm_picker.item_count:
  if str(host.realm_picker.get_item_metadata(n))=="neon_crucible":host.realm_picker.select(n)
 host._start_match();host._add_player("friend",1);host.hero_ids.friend="robot";host.levels.friend=6
 var hc=host.adventure.combat;host.adventure.tech.step(.05);host._attack("friend","special",Vector2.RIGHT)
 check(hc.robot.transformed("friend") and not hc.robot.transformed(host.my_id),"remote transformation affects owner only")
 hc.robot.step(.5);var ally_hp:float=host.health[host.my_id];host.positions[host.my_id]=host.positions.friend;hc.robot.step(.3);host._attack("friend","primary",Vector2.RIGHT)
 check(host.health[host.my_id]==ally_hp and hc.effect_time(hc.player_key(host.my_id),"stun")==0,"friendly saw contact and stomp cannot hurt allies")
 host.invincible_until.friend=0;host.dodge_at.friend=0;host._packet("friend",{"type":"dodge"});check(host.invincible_until.friend==0,"host refuses dodge while transformed")
 var packet:Dictionary=JSON.parse_string(JSON.stringify(host._snapshot()));check(packet.adventure.combat.robot.forms.has("friend") and packet.adventure.tech.initialized,"forms and whole-realm progress serialize for co-op")
 var guest=load("res://scenes/arcade.tscn").instantiate();root.add_child(guest);await process_frame;guest.set_process(false);guest._set_mode("defense");guest._solo();guest._set_mode("coop");
 for n in guest.realm_picker.item_count:
  if str(guest.realm_picker.get_item_metadata(n))=="neon_crucible":guest.realm_picker.select(n)
 guest._start_match();guest.role="guest";guest.host_id="host";guest.my_id="friend";guest._packet("host",packet)
 var form_time:float=guest.adventure.combat.robot.forms.friend.time;guest.adventure.combat.robot.step(2);guest.adventure.tech.step(2)
 check(guest.adventure.combat.robot.forms.friend.time==form_time and guest.adventure.tech.initialized,"guest renders replicated state without simulating hits or boss uploads")
 for node in [game,host,guest]:
  for voice in node.journey.voices:voice.stop()
  node.queue_free()
 await create_timer(.3).timeout;print("V49 FAILURES: "+str(failures));quit(failures)
