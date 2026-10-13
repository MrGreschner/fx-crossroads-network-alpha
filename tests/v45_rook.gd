extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 game.selected_character="rook";game.start_run(false,"elementary");game.enemies.clear();game.position_in_world=Vector2(3800,5400);game.level=5
 var combat=game.adventure.combat;var chains=combat.chain
 var roster:Array=game.manifest.characters;var ember:int=roster.find("welder")
 check(roster[ember+1]=="medic" and roster[ember+2]=="navigator","Medic and Navigator directly follow Emberwright")
 check(roster.size()>=28 and game.hero.name=="Rook Ironhand" and game.art.has("rook_idle"),"hero 28 loads data and artwork")
 game.adventure.spawn("pencil_scrapper",Vector2(3990,5400),300,false);combat.cast("solo",game.hero.primary,Vector2.RIGHT,22)
 chains.step(.7);check(is_equal_approx(game.enemies[0].hp,278),"sweep crosses target and hits exactly once")
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,22);chains.step(.7);check(is_equal_approx(game.enemies[0].hp,256),"reverse swing also hits once")
 game.enemies.clear();game.adventure.spawn("pencil_scrapper",Vector2(3800,5600),300,false)
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,22);chains.step(.7);check(game.enemies[0].hp==300,"flail does not act as full-circle melee")
 game.enemies.clear();game.adventure.spawn("pencil_scrapper",Vector2(3930,5400),300,false)
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,18);chains.step(.19);check(game.position_in_world==Vector2(3800,5400),"grapnel visibly travels before pull begins")
 chains.step(.1);check(game.position_in_world.x>3800 and game.position_in_world.x<4060,"rush moves over time rather than teleporting")
 chains.step(.5);check(game.position_in_world.distance_to(Vector2(4060,5400))<2 and game.enemies[0].hp==280,"rush reaches anchor and hits once")
 check(combat.effect_time(combat.npc_key(game.enemies[0]),"stun")>0 and chains.follow_through.has("solo"),"rush stuns and arms unique passive")
 game.position_in_world=Vector2(3800,5400);game.enemies[0].pos=Vector2(3990,5400)
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,22);chains.step(.7);check(game.enemies[0].hp==250 and not chains.follow_through.has("solo"),"Follow Through adds eight once")
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,22);chains.step(.7);check(game.enemies[0].hp==228,"passive does not remain permanently empowered")
 chains.reset();game.enemies.clear();game.position_in_world=Vector2(3800,5400)
 for n in 6:game.adventure.spawn("pencil_scrapper",Vector2(3920+n*45,5400),300,false)
 combat.cast("solo",game.hero.special,Vector2.RIGHT,38);chains.step(.7)
 var caught:int=chains.hauls[0].caught.size();check(caught==4,"Iron Haul catches at most four enemies")
 var first_key:String=combat.npc_key(game.enemies[0]);var before:Vector2=game.enemies[0].pos
 chains.step(.8);check(chains.hauls.is_empty() and game.enemies[0].hp==250 and game.enemies[4].hp==300,"haul applies catch and return damage once with cap")
 check(game.enemies[0].pos.x<before.x and game.enemies[0].pos.x>=3800,"caught ordinary enemies visibly pulled back")
 game.enemies.clear();game.adventure.spawn("recess_ringleader",Vector2(4000,5400),500,true);before=game.enemies[0].pos
 combat.cast("solo",game.hero.special,Vector2.RIGHT,38);chains.step(1);chains.step(.5)
 check(game.enemies[0].hp==450 and game.enemies[0].pos==before,"boss takes damage but resists displacement")
 chains.reset();game.enemies.clear();game.position_in_world=Vector2(6750,5400)
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,18);chains.step(.8)
 check(game.adventure.school.can_stand(game.position_in_world) and game.position_in_world.x<6800,"grapnel stops at street boundary")
 combat.cast("solo",game.hero.special,Vector2.RIGHT,38);check(combat.vec(chains.hauls[0].end).x<6800,"haul path also clips at walls")
 chains.reset();game.position_in_world=Vector2(3800,5400)
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,22);game.health=0;chains.step(.1);check(chains.sweeps.is_empty(),"death cancels active swing")
 game.health=100;combat.cast("solo",game.hero.secondary,Vector2.RIGHT,18);combat.apply_status("p:solo","stun",1,"enemy");chains.step(.1);check(chains.rushes.is_empty(),"stun interrupts grapnel without leaving movement lock")
 var host=load("res://scenes/arcade.tscn").instantiate();root.add_child(host);await process_frame;host.set_process(false);host._set_mode("defense");host._solo();host._add_player("friend",1)
 host.hero_ids.friend="rook";host.levels.friend=6;host.positions.friend=Vector2(0,0)
 host.positions.friend=host._spawn_player(1);var hc=host.adventure.combat;var origin:Vector2=host.positions.friend
 hc.cast("friend",host.characters.rook.secondary,Vector2.RIGHT,18);hc.chain.step(.3)
 var snapshot:Dictionary=JSON.parse_string(JSON.stringify(host._snapshot()))
 check(snapshot.players.friend.charging and snapshot.adventure.combat.chain.rushes.size()==1,"co-op snapshot carries grapnel movement and graphics")
 var moved:Vector2=host.positions.friend;host._packet("friend",{"type":"pos","x":origin.x,"y":origin.y});check(host.positions.friend==moved,"guest position input cannot undo authoritative rush")
 var guest=load("res://scenes/arcade.tscn").instantiate();root.add_child(guest);await process_frame;guest.set_process(false);guest._set_mode("defense");guest._solo();guest.role="guest";guest.host_id="host";guest.my_id="friend"
 guest._packet("host",snapshot);check(guest.adventure.combat.chain.rushes.size()==1 and guest.charges.has("friend"),"guest receives visible chain and host movement target")
 var count:int=guest.adventure.combat.chain.rushes.size();guest.adventure.combat.chain.step(.8);check(guest.adventure.combat.chain.rushes.size()==count,"guest never applies chain damage or advances authoritative state")
 hc.chain.step(.8);snapshot=JSON.parse_string(JSON.stringify(host._snapshot()));guest._packet("host",snapshot)
 check(not guest.charges.has("friend") and guest.local_pos.distance_to(host.positions.friend)<2,"ending rush releases guest controls at final position")
 hc.chain.reset();host.opponents.clear();host.positions.friend=host._spawn_player(1);origin=host.positions.friend
 host.positions[host.my_id]=origin+Vector2(190,0);host.local_pos=host.positions[host.my_id];host.health[host.my_id]=100;host.invincible_until.clear();host.shield_until.clear()
 host.mode="coop";hc.cast("friend",host.characters.rook.primary,Vector2.RIGHT,22);hc.chain.step(.7)
 check(host.health[host.my_id]==100,"co-op chain swings never damage allies")
 host.mode="arena";host.pvp_rule="ffa";hc.cast("friend",host.characters.rook.primary,Vector2.RIGHT,22);hc.chain.step(.7)
 check(host.health[host.my_id]<100,"same flail damages a PvP opponent")
 hc.chain.reset();host.invincible_until.clear();var rival_before:Vector2=host.positions[host.my_id]
 hc.cast("friend",host.characters.rook.special,Vector2.RIGHT,38);hc.chain.step(.8);hc.chain.step(.6)
 check(host.positions[host.my_id].x<rival_before.x and host.positions[host.my_id].distance_to(origin)>0,"PvP haul pulls opponents without teleporting them to caster")
 for node in [game,host,guest]:
  for voice in node.journey.voices:voice.stop()
  node.queue_free()
 await create_timer(.3).timeout;print("V45 FAILURES: "+str(failures));quit(failures)
