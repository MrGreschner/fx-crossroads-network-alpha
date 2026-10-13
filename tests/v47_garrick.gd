extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.selected_character="garrick";game.start_run(false,"elementary");game.enemies.clear();game.position_in_world=Vector2(3800,5400);game.level=6
 var combat=game.adventure.combat;var runes=combat.runebearer
 check(game.manifest.characters.size()>=30 and game.hero.name=="Garrick Runebearer" and game.art.has("garrick_attack"),"male hero 30 registered with sprites")
 game.fire("secondary");check(runes.next_rune.solo==1 and combat.effect_time("p:solo","rune_might")>0,"cycle starts with Might")
 game.fire("secondary");check(runes.next_rune.solo==1,"actual cooldown prevents immediate second buff")
 game.adventure.spawn("pencil_scrapper",Vector2(4040,5400),300,false);game.damage_enemy(0,20);check(is_equal_approx(game.enemies[0].hp,276),"Might increases actual outgoing damage 20 percent")
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,0);check(runes.next_rune.solo==2 and combat.speed_factor("p:solo")==1.3 and combat.effect_time("p:solo","rune_might")==0,"Stride grants speed and replaces Might")
 combat.apply_status("p:solo","burn",10,"enemy",2);combat.apply_status("p:solo","poison",5,"enemy",2);combat.apply_status("p:solo","bleed",4,"enemy",2)
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,0);check(runes.next_rune.solo==0 and combat.reduction("solo")==.35 and combat.speed_factor("p:solo")==1,"Ward grants protection and replaces Stride")
 check(combat.effect_time("p:solo","burn")==0 and combat.effect_time("p:solo","poison")==0 and combat.effect_time("p:solo","bleed")==0,"level-five Ward cleanses all three damage-over-time effects")
 game.health=100;game.invulnerable_time=0;game.take_player_damage(20);check(is_equal_approx(game.health,87),"Ward reduces actual incoming damage 35 percent")
 combat.tick_statuses(4.6);check(combat.reduction("solo")==0,"Ward expires without permanent protection")
 game.level=4;combat.apply_status("p:solo","poison",5,"enemy",2)
 for n in 3:combat.cast("solo",game.hero.secondary,Vector2.RIGHT,0)
 check(combat.effect_time("p:solo","poison")>0,"cleanse stays locked before passive level")
 combat.statuses.clear();game.level=6;game.enemies.clear();game.adventure.spawn("pencil_scrapper",Vector2(3990,5400),300,false)
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,24)
 check(combat.projectiles.size()==1 and combat.projectiles[0].stats.rune_hammer,"primary launches actual spinning hammer")
 for n in 10:combat.step_projectiles(.05)
 check(game.enemies[0].hp==276,"hammer hits for base damage")
 game.enemies.clear();game.adventure.spawn("pencil_scrapper",Vector2(4040,5400),300,false)
 combat.cast("solo",game.hero.special,Vector2.RIGHT,28);runes.step(.44);check(game.enemies[0].hp==300,"Verdict warns before first hit")
 runes.step(.02);check(game.enemies[0].hp==276,"first seal hits for 24")
 runes.step(.5);check(game.enemies[0].hp==248 and combat.effect_time(combat.npc_key(game.enemies[0]),"slow")>0,"crosscut hits for 28 and slows")
 runes.step(.55);check(game.enemies[0].hp==210 and combat.effect_time(combat.npc_key(game.enemies[0]),"stun")>0 and runes.verdicts.is_empty(),"last ring hits for 38 and stuns")
 combat.cast("solo",game.hero.special,Vector2.RIGHT,28);game.health=0;runes.step(.5);check(runes.verdicts.is_empty(),"death cancels delayed verdict")
 game.health=100;combat.cast("solo",game.hero.secondary,Vector2.RIGHT,0)
 var snapshot:Dictionary=JSON.parse_string(JSON.stringify(combat.snapshot()));check(snapshot.runebearer.next_rune.solo==runes.next_rune.solo,"next rune survives JSON snapshot")
 combat.setup("elementary");check(runes.next_rune.is_empty() and combat.statuses.is_empty(),"new run resets buff sequence and effects")
 var host=load("res://scenes/arcade.tscn").instantiate();root.add_child(host);await process_frame;host.set_process(false);host._set_mode("defense");host._solo();host._add_player("friend",1);host.hero_ids.friend="garrick";host.levels.friend=6
 host._attack("friend","secondary",Vector2.RIGHT);var hc=host.adventure.combat
 check(hc.runebearer.next_rune.friend==1 and hc.war_multiplier("friend")==1.2 and hc.war_multiplier(host.my_id)==1,"remote rune buffs owner only")
 host._attack("friend","secondary",Vector2.RIGHT);check(hc.runebearer.next_rune.friend==1,"host enforces rune cooldown for guest")
 var packet:Dictionary=JSON.parse_string(JSON.stringify(host._snapshot()))
 var guest=load("res://scenes/arcade.tscn").instantiate();root.add_child(guest);await process_frame;guest.set_process(false);guest._set_mode("defense");guest._solo();guest.role="guest";guest.host_id="host";guest.my_id="friend";guest._packet("host",packet)
 check(guest.adventure.combat.runebearer.next_rune.friend==1 and guest.adventure.combat.effect_time("p:friend","rune_might")>0,"guest receives next-rune indicator and active buff")
 guest.adventure.combat.runebearer.cast("friend",host.characters.garrick.secondary,Vector2.RIGHT,0);check(guest.adventure.combat.runebearer.next_rune.friend==1,"guest cannot advance sequence or grant buffs")
 for node in [game,host,guest]:
  for voice in node.journey.voices:voice.stop()
  node.queue_free()
 await create_timer(.3).timeout;print("V47 FAILURES: "+str(failures));quit(failures)
