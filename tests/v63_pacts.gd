extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 game.selected_character="drum";game.start_run(false,"practice");game.practice=false;game.level=1;game.enemies.clear();game.position_in_world=Vector2(1100,600)
 var combat=game.adventure.combat
 game.adventure.spawn("training_dummy",Vector2(1170,600),500,false);var foe:Dictionary=game.enemies[-1];var key:String=combat.npc_key(foe)
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,14)
 for n in 30:combat.step(.02)
 check(foe.hp==486 and combat.effect_time(key,"slow")>0 and is_equal_approx(combat.speed_factor(key),.75),"primary hits once and slows 25 percent")
 combat.setup("practice");foe.hp=500
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,8)
 for n in 45:combat.step(.02)
 check(foe.hp==476 and combat.effect_time(key,"burn")>0,"three pulses hit once each and activate burn")
 for n in 160:combat.step(.02)
 check(foe.hp==467 and combat.effect_time(key,"burn")==0,"burn ticks exactly three times for nine damage")
 combat.setup("practice");foe.hp=500
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,8)
 for n in 10:combat.step(.02)
 foe.pos=Vector2(1600,600)
 for n in 50:combat.step(.02)
 check(foe.hp==492 and combat.effect_time(key,"burn")==0,"missing later pulses does not ignite target")
 # A new cast cannot reuse a previous cast's partial tally.
 foe.pos=Vector2(1170,600);combat.cast("solo",game.hero.secondary,Vector2.RIGHT,8)
 for n in 10:combat.step(.02)
 foe.pos=Vector2(1600,600)
 for n in 50:combat.step(.02)
 check(foe.hp==484 and combat.effect_time(key,"burn")==0,"separate incomplete casts cannot combine hits")
 game.selected_character="thistlebond";game.start_run(false,"practice");game.practice=false;game.level=6;game.enemies.clear();game.position_in_world=Vector2(1100,600)
 var pact=combat.pact
 check(game.manifest.characters.size()==43 and game.art.has("thistlebond_idle"),"hero 43 and all selection artwork load")
 game.adventure.spawn("bramble",Vector2(1250,600),80,false);foe=game.enemies[-1];key=combat.npc_key(foe)
 var stats:Dictionary=game.hero.special.duplicate(true);check(pact.prepare("solo",stats,Vector2.RIGHT,foe.pos),"capture selects visible normal enemy")
 var old_xp:float=game.experience;var old_gold:int=game.gold;var old_damage:float=game.dealt_damage;var old_kills:int=game.kills
 combat.cast("solo",stats,Vector2.RIGHT,0)
 check(combat.actor(key).is_empty() and pact.allies.has("solo") and pact.allies.solo.time==8,"conversion removes hostile and creates eight-second ally")
 check(game.experience==old_xp+10 and game.gold==old_gold+2 and game.kills==old_kills+1 and game.dealt_damage==old_damage,"normal defeat rewards once without fictitious conversion damage")
 check(combat.hostile("enemy").has("p:bond:solo") and not combat.hostile("solo").has("p:bond:solo"),"enemy attacks target the ally but player attacks exclude it")
 check(combat.v59.target_points().has("bond:solo") and game.adventure.alive("bond:solo"),"ground attacks include the damageable converted body")
 var hp:float=pact.allies.solo.hp;game.adventure.hit_player("bond:solo",7)
 check(pact.allies.solo.hp==hp-7 and game.health==game.max_health(),"enemy area hit damages summon independently")
 var p:Vector2=combat.vec(pact.allies.solo.pos)
 check(combat.v59.catch_copy(p-Vector2(80,0),p+Vector2(10,0),"enemy",9) and pact.allies.solo.hp==hp-16,"native hostile projectile hits temporary ally")
 old_xp=game.experience;old_gold=game.gold;old_kills=game.kills
 pact.step(7.99);check(pact.allies.has("solo"),"ally remains before eight-second expiry")
 pact.step(.02);check(pact.allies.is_empty() and game.experience==old_xp and game.gold==old_gold and game.kills==old_kills,"expiry removes body without second rewards")
 game.adventure.spawn("bramble",Vector2(1250,600),80,false);foe=game.enemies[-1];pact.turn_enemy("solo",combat.npc_key(foe));pact.hurt_ally("solo",100)
 check(pact.allies.is_empty(),"enough damage defeats ally before timer")
 game.adventure.spawn("bramble",Vector2(1250,600),200,true);foe=game.enemies[-1]
 stats=game.hero.special.duplicate(true);check(not pact.prepare("solo",stats,Vector2.RIGHT,foe.pos),"bosses cannot be converted")
 game.enemies.clear();game.adventure.spawn("training_dummy",Vector2(1250,600),500,false);foe=game.enemies[-1]
 check(not pact.prepare("solo",stats,Vector2.RIGHT,foe.pos),"training targets cannot be converted")
 game.enemies.clear();game.adventure.spawn("ashen_revenant",Vector2(1250,600),80,false);foe=game.enemies[-1];pact.turn_enemy("solo",combat.npc_key(foe))
 check(game.enemies.is_empty() and pact.allies.has("solo"),"conversion cannot also revive the hostile original")
 pact.reset();game.enemies.clear();game.adventure.spawn("archer",Vector2(1250,600),60,false);foe=game.enemies[-1];pact.turn_enemy("solo",combat.npc_key(foe))
 game.adventure.spawn("bramble",Vector2(1460,600),200,false);foe=game.enemies[-1]
 pact.step(.3);check(pact.allies.solo.ranged and combat.projectiles.size()>0,"converted ranged foe retains ranged role")
 for n in 35:combat.step_projectiles(.02)
 check(foe.hp==186,"ranged ally shot damages enemy and credits summoner")
 # Mark needle travels, then a delayed knot pulls only marked enemies.
 pact.reset();combat.projectiles.clear();game.enemies.clear();game.adventure.spawn("bramble",Vector2(1230,600),200,false);foe=game.enemies[-1];key=combat.npc_key(foe)
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,21);pact.step(.05);check(foe.hp==200,"needle has visible travel time")
 for n in 8:pact.step(.03)
 check(foe.hp==179 and pact.marks.solo.has(key),"needle marks first hit")
 stats=game.hero.secondary.duplicate(true);pact.prepare("solo",stats,Vector2.RIGHT,Vector2(1310,600));combat.cast("solo",stats,Vector2.RIGHT,24)
 pact.step(.44);check(foe.hp==179,"knot warns before impact")
 pact.step(.02);check(foe.hp==155 and foe.pos.x>1230 and combat.effect_time(key,"slow")>0,"knot gathers marked foes and slows")
 # Clearing the final hostile by conversion must also unlock school progression.
 game.start_run(false,"elementary");var school=game.adventure.school;school.step(.01)
 for door in school.data.doors:
  if door.id!="playground":school.open_door(door)
 var last:Dictionary={}
 for enemy in game.enemies:
  if not bool(enemy.boss) and not bool(enemy.get("summoned",false)):last=enemy;break
 var last_key:String=combat.npc_key(last)
 for n in range(game.enemies.size()-1,-1,-1):
  if combat.npc_key(game.enemies[n])!=last_key:game.damage_enemy(n,100000)
 game.position_in_world=last.pos-Vector2(30,0);pact.turn_enemy("solo",last_key);school.step(.01)
 check(school.opened.get("playground",false) and pact.allies.has("solo"),"school barrier unlocks while converted last foe remains a friendly body")
 var host=load("res://scenes/arcade.tscn").instantiate();root.add_child(host);await process_frame;host.set_process(false);host._set_mode("defense");host._solo();host.hero_ids[host.my_id]="thistlebond";host._start_match();host.opponents.clear();host.levels[host.my_id]=6;host.field_obstacles.clear();host.obstacle_grid.clear()
 var hc=host.adventure.combat;var origin:Vector2=host.positions[host.my_id]
 host.adventure.spawn("archer",origin+Vector2(150,0),60,false);foe=host.opponents[-1];var enemy_key:String=hc.npc_key(foe)
 old_xp=host.xp[host.my_id];old_damage=float(host.contributions.get(host.my_id,{}).get("damage",0))
 host._attack(host.my_id,"special",Vector2.RIGHT,foe.pos)
 check(hc.pact.allies.has(host.my_id) and host.opponents.is_empty() and host.xp[host.my_id]==old_xp+1,"real multiplayer cast captures and awards normal XP once")
 var packet:Dictionary=JSON.parse_string(JSON.stringify(host._snapshot()))
 check(packet.adventure.combat.pact.allies[host.my_id].time==8,"ally lifetime and appearance serialize in host snapshot")
 var guest=load("res://scenes/arcade.tscn").instantiate();root.add_child(guest);await process_frame;guest.set_process(false);guest.role="guest";guest.adventure.combat.receive(packet.adventure.combat)
 var gp=guest.adventure.combat.pact;var count:int=gp.allies.size();gp.step(20);gp.hurt_ally(host.my_id,100)
 check(gp.allies.size()==count,"guest cannot expire or damage authoritative summon")
 host.positions.friend=origin+Vector2(180,0);host.health.friend=100;host.hero_ids.friend="ram"
 host.mode="arena";host.pvp_rule="ffa";stats=host.characters.thistlebond.special.duplicate(true)
 check(not hc.pact.prepare(host.my_id,stats,Vector2.RIGHT,host.positions.friend),"PvP player cannot be converted")
 var before:float=hc.pact.allies[host.my_id].hp;hc.damage("p:bond:"+host.my_id,10,"friend")
 check(hc.pact.allies[host.my_id].hp==before-10,"PvP rival can defeat converted body")
 hc.damage("p:bond:"+host.my_id,10,host.my_id)
 check(hc.pact.allies[host.my_id].hp==before-10,"owner cannot damage own converted body")
 for node in [game,host,guest]:
  for voice in node.journey.voices:voice.stop()
  node.queue_free()
 await create_timer(.4).timeout
 print("v63: ",failures," failures");quit(1 if failures else 0)
