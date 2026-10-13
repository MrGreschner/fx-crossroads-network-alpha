extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.selected_character="bracken";game.start_run(false,"honeyglass");game.obstacles.clear();game.build_scenery();game.position_in_world=Vector2(2000,1500);game.enemies.clear();game.level=5
 var combat=game.adventure.combat;var stats:Dictionary=game.hero.primary
 combat.cast("solo",stats,Vector2.RIGHT,38);combat.cast("solo",stats,Vector2.LEFT,38)
 check(combat.mines.size()==2 and combat.rings.is_empty(),"two clicks plant without damage")
 game.adventure.spawn("bramble",Vector2(2100,1500),500,false)
 combat.cast("solo",stats,Vector2.RIGHT,38);check(combat.mines.is_empty() and combat.rings.size()==2 and combat.rings[0].max_radius==115,"third detonates and passive extends radius")
 combat.step(.2);check(game.enemies[0].hp==462,"mine damages once")
 combat.cast("solo",stats,Vector2.RIGHT,38);combat.step(13);check(combat.mines.is_empty(),"mine expires")
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,12);check(combat.casts.size()==3,"secondary staggered sequence")
 var packet:Dictionary=combat.snapshot();combat.receive(packet);check(combat.casts.size()==3 and packet.has("mines"),"network mine and cast payload")
 for voice in game.journey.voices:voice.stop()
 game.queue_free();await process_frame
 var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party.selected_hero="bracken";party._set_mode("descent");party._solo();party.opponents.clear();party.health.solo=60;party._simulate(.01)
 check(party.floor_number==2 and party.health.solo==60,"descent has no floor heal")
 check(party.floor_transition>0,"floor fade triggered")
 party.invincible_until.solo=0;party._hurt("solo",10,"enemy")
 check(party.hit_flash.has("solo") and party.effects[-1].style=="hit_ring","damage ring and tint")
 party._receive_effect({"pos":[100,100],"style":"hit_ring","victim":"guest","time":.3});check(party.hit_flash.has("guest"),"guest hit feedback")
 var shared=party.adventure.combat;shared.cast("solo",party.characters.bracken.primary,Vector2.RIGHT,38);shared.cast("solo",party.characters.bracken.primary,Vector2.LEFT,38)
 check(shared.snapshot().mines.size()==2,"host-owned mines included in network snapshot")
 shared.cast("solo",party.characters.bracken.primary,Vector2.RIGHT,38);check(shared.mines.is_empty() and shared.rings.size()==2,"multiplayer third click detonates")
 party._set_mode("defense");party._solo();check(party.world_fountains.size()==1 and party.world_decorations.size()>80,"frontier scenery and spring")
 var spring:Vector2=party.world_fountains[0];check(party._clear_path(spring,spring+Vector2(100,0)),"spring accessible")
 party.positions.solo=spring;party.health.solo=60;party._update_fountains(1)
 check(party.health.solo==63 and party.contributions.get("solo",{}).get("healing",0)==0,"spring heals without ability stats")
 party.health.solo=0;party._update_fountains(1);check(party.health.solo==0,"spring does not revive")
 for voice in party.journey.voices:voice.stop()
 party.queue_free();await create_timer(.2).timeout
 print("V32 FAILURES: "+str(failures));quit(failures)
