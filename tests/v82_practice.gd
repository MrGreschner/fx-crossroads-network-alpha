extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/arcade.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.party_tools.set_process(false);g.legacy.set_process(false)
 g._set_mode("arena");g.spectator_host=true;g.arena_seats=8
 check(g.party_lobby.members().is_empty(),"preview host leaves all fighter seats")
 g.spectator_host=false;g.bot_count=3;g.legacy.data=g.legacy.defaults();g._solo();g.recovery=null;g.start_countdown=0
 check(g.started and g.positions.size()==4,"solo starts with three bots")
 check(g.hero_picker.item_count==50,"NPC kits stay out of human hero picker")
 check(g.bots.is_bot("bot:0") and not g.bots.is_bot("solo"),"AI ownership explicit")
 var card_before:Dictionary=g.legacy.card.state().duplicate(true);var tasks:Dictionary=g.legacy.data.tasks.duplicate(true)
 var hero:String=g.selected_hero;var previous:float=g.legacy.record(hero).damage
 g._stat("solo","damage",51);g._track_card_progress();g._track_card_progress()
 check(g.legacy.record(hero).damage==previous+51,"practice mastery damage counted once")
 check(g.legacy.card.state()==card_before and g.legacy.data.tasks==tasks,"no card or town unlock stats")
 g.arena_map_picker.select(1);g._start_match();g.start_countdown=0
 var center:Vector2=g.FIELD.get_center()
 for n in 4:
  var id:String=g.fighters()[n].id;g.positions[id]=center+Vector2.from_angle(n*TAU/4)*150;g.health[id]=g._max_hp(id)
 g.local_pos=g.positions.solo
 var initial:Vector2=g.positions["bot:0"]
 for tick in 80:
  g.bots.step(.05);g._simulate_charges(.05);g._simulate(.05);g.adventure.step(.05);g.run_time+=.05
 check(g.positions["bot:0"].distance_to(initial)>20,"bots move and maintain spacing")
 check(g.cooldown_at["bot:0"].primary>0 and g.cooldown_at["bot:1"].special>0,"distinct bot attacks execute")
 check(not g.links.has("bot:0"),"bots need no network peers")
 var packet:Dictionary=g._snapshot();var config:Dictionary=g.match_config()
 check(packet.bots==3 and config.bots==3,"practice flag synchronized")
 var guest=load("res://scenes/arcade.tscn").instantiate();root.add_child(guest);await process_frame;guest.set_process(false);guest.party_tools.set_process(false);guest.legacy.set_process(false)
 guest.role="guest";guest.my_id="solo";guest.host_id="teacher";guest._set_mode("arena");guest._add_player("solo",0);guest._receive_lobby(g._lobby_packet());guest._packet("teacher",config);guest._packet("teacher",packet)
 check(guest.bot_count==3 and guest.hero_ids.get("bot:0")=="npc_sable","guest sees same NPC kit and practice rules")
 g.end_match("Arena finished • practice");check(g.legacy.card.state()==card_before,"practice result cannot change PvP record")
 # Broadcast-only bot match has no host body, and eight fighter seats still fit.
 g.started=false;g._reset_connection();g.spectator_host=true;g.bot_count=3;g._solo();g.start_countdown=0
 check(g.spectating() and g.positions.size()==3 and not g.positions.has("solo"),"solo spectator watches AI fighters separately")
 guest.queue_free();g.queue_free();await process_frame
 print("v82 practice failures: ",failures);quit(failures)
