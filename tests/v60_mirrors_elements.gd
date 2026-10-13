extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 for id in ["velvetwing","caelum","wanderlight"]:
  check(game.art.get(id+"_idle")!=null,"portrait and standing image: "+id)
 game.selected_character="caelum";game.start_run(false,"practice");game.level=6;game.enemies.clear();game.position_in_world=Vector2(1100,600);game.health=100
 var combat=game.adventure.combat;var kit=combat.v59
 combat.cast("solo",game.hero.special,Vector2.RIGHT,15)
 var start:Vector2=combat.vec(kit.copies.solo.pos)
 game.position_in_world+=Vector2(40,-20);kit.step(.1)
 check(combat.vec(kit.copies.solo.pos).is_equal_approx(start+Vector2(40,-20)),"mirror follows the same movement delta")
 check(kit.copies.solo.walking,"moving pose copied")
 var stayed:Vector2=combat.vec(kit.copies.solo.pos);kit.step(.2)
 check(combat.vec(kit.copies.solo.pos)==stayed and not kit.copies.solo.walking and combat.projectiles.is_empty(),"mirror stops and never independently chases or fires")
 combat.cast("solo",game.hero.primary,Vector2.UP,25)
 check(combat.projectiles.size()==2 and combat.projectiles[0].aim==combat.projectiles[1].aim and combat.projectiles[1].damage==15,"same aim and attack at balanced copy damage")
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,34)
 check(kit.folds.size()==2 and is_equal_approx(kit.folds[1].damage,20.4),"secondary copied from its own body")
 # Duplicate collides with walls instead of teleporting through them.
 var expected:Vector2=combat.chain.clip(stayed,Vector2.LEFT,5000)
 game.position_in_world-=Vector2(5000,0);kit.step(.1)
 check(combat.vec(kit.copies.solo.pos)==expected,"mirror movement respects collision")
 game.selected_character="wanderlight";game.start_run(false,"practice");game.level=6;game.enemies.clear();game.position_in_world=Vector2(1100,600)
 check(kit.element("solo")=="earth","Earth is the starting element")
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,26)
 check(float(combat.projectiles[0].range)/float(combat.projectiles[0].speed)>=4,"longer projectile flight gives time to redirect")
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,16)
 check(combat.projectiles[0].stats.element=="earth" and combat.projectiles[0].speed==0,"redirect infuses Earth and briefly pauses")
 kit.step(.3);check(combat.projectiles[0].speed==300,"redirect releases projectile")
 game.adventure.spawn("training_dummy",Vector2(1250,600),500,false);var direct:Dictionary=game.enemies[-1]
 game.adventure.spawn("training_dummy",Vector2(1250,660),500,false);var splash:Dictionary=game.enemies[-1]
 combat.step_projectiles(.5)
 check(direct.hp==462 and splash.hp==488 and kit.gardens.size()==1,"real projectile impact deals direct plus Earth splash")
 check(combat.effect_time(combat.npc_key(splash),"poison")==4,"Earth splash poisons nearby enemies")
 kit.step(1.9);check(combat.effect_time(combat.npc_key(splash),"slow")==0,"roots warn for two seconds")
 kit.step(.11);check(combat.effect_time(combat.npc_key(splash),"slow")>0,"roots grow and slow enemies")
 check(kit.gardens[0].time>7.9,"roots remain eight seconds after growth")
 for n in 4:combat.tick_statuses(1)
 check(splash.hp==480,"Earth poison totals eight damage")
 for n in 3:combat.cast("solo",game.hero.primary,Vector2.UP,26)
 combat.projectiles.clear();combat.cast("solo",game.hero.special,Vector2.RIGHT,0)
 kit.step(.7);check(kit.element("solo")=="earth","element stays unchanged until replay finishes")
 kit.step(.1);check(kit.element("solo")=="fire" and not kit.switches.has("solo"),"switch to Fire after final replay")
 combat.projectiles.clear();combat.cast("solo",game.hero.primary,Vector2.RIGHT,26);combat.cast("solo",game.hero.secondary,Vector2.RIGHT,16);kit.step(.3)
 combat.step_projectiles(.5)
 check(direct.hp==408 and splash.hp==460,"Fire deals more splash damage than Earth")
 check(combat.effect_time(combat.npc_key(splash),"burn")==4,"Fire applies burn")
 var fire_patch:Dictionary=kit.gardens[-1];check(fire_patch.element=="fire" and fire_patch.time==8,"lava lasts eight seconds")
 splash.pos=Vector2(1100,450);combat.tick_statuses(4);check(splash.hp==448,"burn persists after leaving lava: twelve damage")
 splash.pos=Vector2(1250,660);kit.step(.1);check(combat.effect_time(combat.npc_key(splash),"burn")==4,"lava burns new contacts")
 var captured:Dictionary=kit.snapshot().duplicate(true);kit.reset();kit.receive(captured)
 check(kit.element("solo")=="fire" and kit.gardens.size()==2,"element and terrain synchronize")
 kit.step(8.1);check(kit.gardens.is_empty(),"all expired terrain is removed")
 combat.projectiles.clear();combat.cast("solo",game.hero.special,Vector2.RIGHT,0);kit.step(.8)
 check(kit.element("solo")=="earth","next completed replay switches back to Earth")
 # Friendly players remain unaffected in co-op; rivals are affected in PvP.
 var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party._set_mode("defense");party._solo();party.hero_ids[party.my_id]="wanderlight";party._start_match();party.opponents.clear()
 var pc=party.adventure.combat;var center:Vector2=party.positions[party.my_id]
 party.positions["friend"]=center+Vector2(30,0);party.health["friend"]=100;party.hero_ids["friend"]="ram"
 pc.v59.impact({"owner":party.my_id,"stats":{"element":"fire"}},center);pc.v59.step(.1)
 check(party.health["friend"]==100 and pc.effect_time("p:friend","burn")==0,"co-op ally never takes elemental damage")
 party.mode="arena";party.pvp_rule="ffa"
 pc.v59.impact({"owner":party.my_id,"stats":{"element":"fire"}},center)
 check(party.health["friend"]==80 and pc.effect_time("p:friend","burn")==4 and pc.effect_time(pc.player_key(party.my_id),"burn")==0,"PvP rivals take splash and burn, caster does not")
 for voice in game.journey.voices:voice.stop()
 for voice in party.journey.voices:voice.stop()
 game.queue_free();party.queue_free();await create_timer(.3).timeout
 print("v60: ",failures," failures");quit(1 if failures else 0)
