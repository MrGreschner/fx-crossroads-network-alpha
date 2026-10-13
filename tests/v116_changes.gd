extends SceneTree
var failures:=0
const Credit=preload("res://scripts/defeat_credit.gd")
func check(value:bool,title:String)->void:
 if not value:failures+=1;print("FAIL: ",title)
func _initialize()->void:call_deferred("run")
func tidy(g:Node)->void:
 for player in g.find_children("*","AudioStreamPlayer",true,false):player.stop();player.stream=null
 await create_timer(.1).timeout;g.queue_free();await process_frame;await process_frame;await process_frame;await create_timer(.2).timeout
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g;await process_frame;g.set_process(false);g.presentation.close();g.session_menu.resume();g.start_run(false,"grove");g.set_process(false)
 var foe:Dictionary=g.enemies[0];var key:String=g.adventure.combat.npc_key(foe)
 var cause:Dictionary=Credit.resolve(g,key,"Projectile")
 check(cause.kind=="enemy" and Credit.texture(g,cause)!=null,"enemy identity and portrait resolve")
 g.health=20;g.invulnerable_time=5;g.take_player_damage(100,key,cause);check(g.last_defeat.is_empty(),"blocked hit is not a defeat")
 g.invulnerable_time=0;g.inventory.clear();g.provisions.packed="";g.health=1;g.take_player_damage(999,key,cause)
 check(g.last_defeat==cause and g.presentation.page=="results","fatal enemy hit records exact cause")
 check(g.presentation.content.find_children("*","TextureRect",true,false).size()>=2,"defeat results show attacker portrait")
 g.start_run(false,"grove");check(g.last_defeat.is_empty(),"new run clears stale defeat")
 cause=Credit.resolve(g,g.adventure.combat.npc_key(g.enemies[0]),"Poison");g.enemies.clear();g.health=1;g.take_player_damage(999,"",cause)
 check(g.last_defeat.attack=="Poison" and g.last_defeat.name==cause.name,"stored projectile/status cause survives attacker removal")
 g.start_run(false,"grove");g.health=1;cause=Credit.resolve(g,g.adventure.combat.npc_key(g.enemies[0]),"Poison");g.adventure.combat.apply_status("p:solo","poison",2,"enemy",100,cause);g.enemies.clear();g.adventure.combat.tick_statuses(1.0)
 check(g.last_defeat.name==cause.name and g.last_defeat.attack=="Poison","real status tick retains enemy portrait after removal")
 g.start_run(false,"grove");g.health=1;cause=Credit.resolve(g,g.adventure.combat.npc_key(g.enemies[0]),"Projectile");g.enemies.clear();g.enemy_shots.assign([{"pos":g.position_in_world,"direction":Vector2.RIGHT,"damage":100,"speed":0,"distance":0,"credit":cause}]);g.update_enemy_shots(0)
 check(g.last_defeat==cause,"real legacy projectile impact retains source after removal")
 g.start_run(false,"grove");g.health=1;g.take_player_damage(999,"",Credit.hazard("Realm trap"));check(g.last_defeat.kind=="environment" and g.last_defeat.attack=="Realm trap","environment is distinct from enemy attack")
 await tidy(g)
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);current_scene=a;await process_frame;a.set_process(false);a.party_tools.set_process(false);a.mode="arena";a.role="host";a.started=true;a.start_countdown=0;a.my_id="victim";a.host_id="victim";a.roster.assign([{"id":"victim","name":"Student"},{"id":"killer","name":"Friend"}]);a._add_player("victim",0);a._add_player("killer",1);a.hero_ids.killer="basketball";a.health.victim=1;a.inventory.victim=[];a.food_slots.victim="";a.invincible_until.victim=0
 cause=Credit.resolve(a,"killer","Bounce");a._hurt("victim",999,"killer","",cause)
 check(a.defeat_causes.victim.name==a.characters.basketball.name and a.defeat_causes.victim.player=="Friend","PvP identifies player and hero")
 var snapshot:Dictionary=a._snapshot();check(snapshot.players.victim.defeat==cause,"host distributes per-player fatal provenance")
 var board:Node=a.get_node("RespawnBoard") if a.has_node("RespawnBoard") else a.respawn_board
 board.refresh();check(board.cause_box.get_child_count()>0,"respawn leaderboard shows fatal source")
 a.defeat_causes.clear();a.role="guest";a.host_id="killer"
 a.transport.receive("killer",{"type":"player_metadata","match_id":a.match_id,"players":{"victim":{"defeat":cause}}})
 check(a.defeat_causes.victim==cause,"guest receives reliable fatal metadata")
 for info in snapshot.players.values():info.erase("defeat")
 a._packet("killer",snapshot)
 check(a.defeat_causes.get("victim",{})==cause,"fast state cannot erase reliable defeat metadata")
 check(Credit.resolve(a,"enemy").kind=="unknown","unknown source never guessed as nearest enemy or terrain")
 await tidy(a);print("v116 failures: ",failures);quit(1 if failures else 0)
