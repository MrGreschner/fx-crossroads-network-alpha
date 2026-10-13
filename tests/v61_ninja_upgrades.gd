extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 game.selected_character="robot";game.start_run(false,"practice");game.practice=false;game.level=6;game.enemies.clear();game.position_in_world=Vector2(1100,600);game.health=100
 var combat=game.adventure.combat;var bot=combat.robot
 combat.cast("solo",game.hero.special,Vector2.RIGHT,0);game.invulnerable_time=0;game.take_player_damage(20)
 check(game.health==86 and is_equal_approx(combat.reduction("solo"),.3),"saw form reduces damage by 30 percent")
 game.adventure.spawn("training_dummy",Vector2(1150,600),1,false);var before:float=bot.forms.solo.time
 game.damage_enemy(0,2);check(bot.forms.solo.time==before+1,"actual enemy defeat adds one second")
 game.adventure.spawn("training_dummy",Vector2(1150,600),100,false);before=bot.forms.solo.time;game.damage_enemy(0,2)
 check(bot.forms.solo.time==before,"damage without defeat adds no time")
 game.practice=true;game.enemies[0].hp=1;game.damage_enemy(0,2);check(bot.forms.solo.time==before,"training dummy reset is not a kill")
 game.practice=false;bot.reset();check(combat.reduction("solo")==0,"damage reduction ends with saw form")
 game.selected_character="rook";game.start_run(false,"practice");game.practice=false;game.level=6;game.enemies.clear();game.position_in_world=Vector2(1100,600);game.health=100
 game.adventure.spawn("training_dummy",Vector2(1200,600),500,false);var foe:Dictionary=game.enemies[-1]
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,22)
 # Fully extended chain crosses this inner target while the flail tip is far away.
 var sweep:Dictionary=combat.chain.sweeps[0];sweep.elapsed=.325
 combat.chain.advance(.001)
 check(foe.hp==500 and combat.effect_time(combat.npc_key(foe),"slow")==1.5,"chain slows inner target without flail damage")
 combat.chain.reset();combat.statuses.clear();game.enemies.clear()
 for x in [1200,1290]:game.adventure.spawn("training_dummy",Vector2(x,600),500,false)
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,18);combat.chain.step(.8)
 check(game.enemies[0].hp==480 and game.enemies[1].hp==480 and game.health==104,"rush steals two HP from each distinct target once")
 combat.chain.step(.2);check(game.health==104,"rush cannot repeatedly heal from one target")
 game.selected_character="kage";game.start_run(false,"practice");game.practice=false;game.level=6;game.enemies.clear();game.position_in_world=Vector2(1100,600)
 var ninja=combat.ninja
 check(game.manifest.characters.size()==43 and game.art.has("kage_idle") and game.hero.name=="Kage Moonstep","hero 41 registered with portrait")
 game.adventure.spawn("training_dummy",Vector2(1170,600),500,false);foe=game.enemies[-1]
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,12);ninja.step(.1)
 check(foe.hp==488,"first katana cut occurs before second")
 ninja.step(.1);check(foe.hp==476,"second timed cut hits once")
 ninja.step(.2);check(foe.hp==476,"cuts finish without extra hits")
 ninja.reset();game.enemies.clear();game.adventure.spawn("training_dummy",Vector2(1250,600),500,false);foe=game.enemies[-1]
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,24)
 for n in 72:ninja.step(.025)
 check(foe.hp==460 and ninja.wheels.is_empty(),"star hits once outward, once returning, then is caught")
 check(ninja.marks.get("solo",{}).has(combat.npc_key(foe)),"returning star applies Moon Thread")
 game.position_in_world=Vector2(1180,600);combat.cast("solo",game.hero.primary,Vector2.RIGHT,12);ninja.step(.35)
 check(foe.hp==428 and not ninja.marks.get("solo",{}).has(combat.npc_key(foe)),"next primary consumes mark for eight bonus damage once")
 ninja.reset();game.enemies.clear();game.position_in_world=Vector2(1100,600);game.adventure.spawn("training_dummy",Vector2(1300,600),500,false);foe=game.enemies[-1]
 combat.cast("solo",game.hero.special,Vector2.RIGHT,12);ninja.step(.25)
 check(foe.hp==500 and ninja.eclipses.size()==1,"eclipse warns before attack")
 for n in 56:ninja.step(.025)
 check(foe.hp==446 and ninja.eclipses.is_empty(),"eight stars have three-hit cap plus one center burst")
 combat.cast("solo",game.hero.special,Vector2.RIGHT,12);game.health=0;ninja.step(.025)
 check(ninja.eclipses.is_empty(),"death cancels ninja special")
 var host=load("res://scenes/arcade.tscn").instantiate();root.add_child(host);await process_frame;host.set_process(false);host._set_mode("defense");host._solo();host.hero_ids[host.my_id]="robot";host._start_match();host.opponents.clear();host.levels[host.my_id]=6
 var hc=host.adventure.combat;hc.cast(host.my_id,host.characters.robot.special,Vector2.RIGHT,0);before=hc.robot.forms[host.my_id].time
 host.adventure.spawn("bramble",host.positions[host.my_id]+Vector2(60,0),1,false);host._hit_enemy(0,2,host.my_id)
 check(hc.robot.forms[host.my_id].time==before+1,"co-op NPC kill extends correct owner's saw form")
 host.health[host.my_id]=100;host._hurt(host.my_id,20,"enemy");check(host.health[host.my_id]==86,"co-op damage reduction applied")
 host.hero_ids[host.my_id]="rook";hc.robot.reset();host.health[host.my_id]=100;host.mode="arena";host.pvp_rule="ffa"
 var origin:Vector2=host.positions[host.my_id];host.positions["rival"]=origin+Vector2(100,0);host.health["rival"]=100;host.hero_ids["rival"]="ram";host.invincible_until["rival"]=Time.get_ticks_msec()+10000
 hc.cast(host.my_id,host.characters.rook.secondary,Vector2.RIGHT,18);hc.chain.step(.8)
 check(host.health[host.my_id]==100 and host.health.rival==100,"protected target gives no stolen health")
 host.hero_ids[host.my_id]="kage";host.mode="defense";host.health[host.my_id]=100
 hc.cast(host.my_id,host.characters.kage.secondary,Vector2.RIGHT,24);hc.cast(host.my_id,host.characters.kage.special,Vector2.RIGHT,12)
 var packet:Dictionary=JSON.parse_string(JSON.stringify(host._snapshot()))
 check(packet.adventure.combat.ninja.wheels.size()==1 and packet.adventure.combat.ninja.eclipses.size()==1,"ninja effects serialize for multiplayer")
 hc.ninja.eclipses.clear()
 for n in 72:hc.ninja.step(.025)
 check(host.health.rival==100 and host.health[host.my_id]==100,"ninja stars cannot damage co-op allies")
 host.mode="arena";host.pvp_rule="ffa";host.invincible_until.rival=0;host.positions.rival=host.positions[host.my_id]+Vector2(100,0)
 hc.cast(host.my_id,host.characters.kage.secondary,Vector2.RIGHT,24)
 for n in 72:hc.ninja.step(.025)
 check(host.health.rival==60,"ninja outward and returning stars damage PvP opponent")
 host.hero_ids[host.my_id]="robot";hc.cast(host.my_id,host.characters.robot.special,Vector2.RIGHT,0);before=hc.robot.forms[host.my_id].time;host.health.rival=1
 host._hurt("rival",5,host.my_id);check(hc.robot.forms[host.my_id].time==before+1,"PvP defeat extends saw form")
 host._hurt("rival",5,host.my_id);check(hc.robot.forms[host.my_id].time==before+1,"same defeated player is not counted twice")
 var serialized:Dictionary=packet.adventure.combat.ninja
 hc.ninja.reset();hc.ninja.receive(serialized)
 check(hc.ninja.wheels.size()==1 and hc.ninja.eclipses.size()==1,"ninja effects restore from snapshot")
 for node in [game,host]:
  for voice in node.journey.voices:voice.stop()
  node.queue_free()
 await create_timer(.3).timeout;print("v61: ",failures," failures");quit(1 if failures else 0)
