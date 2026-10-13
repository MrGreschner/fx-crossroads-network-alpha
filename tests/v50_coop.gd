extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func party(id:String)->Node:
 var game=load("res://scenes/arcade.tscn").instantiate();root.add_child(game)
 for n in 8:await process_frame
 game.set_process(false);game.party_tools.auto_solo=false;game.presentation.close();game.session_menu.resume();game.role="host";game.my_id="solo";game.host_id="solo";game.roster.assign([{"id":"solo","name":"Host"}]);game._add_player("solo",0);game.legacy.data.teacher=true;game._set_mode("coop")
 for n in game.realm_picker.item_count:
  if str(game.realm_picker.get_item_metadata(n))==id:game.realm_picker.select(n)
 game._start_match();game.start_countdown=0;return game
func run()->void:
 for action in ["primary","secondary","special"]:
  if not InputMap.has_action(action):InputMap.add_action(action)
 root.set_meta("fx_dev_match",true);root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var host=await party("silverfall");host._add_player("friend",1);host.adventure.step(.01);var world=host.adventure.immersive
 check(world.active and host.opponents.size()==15,"host uses authored Silverfall rather than three generic waves")
 var dock:Vector2=world.v(world.data.raft.docks[0]);host.positions.friend=dock;host.positions[host.my_id]=dock+Vector2(40,0);host.local_pos=host.positions[host.my_id]
 host._packet("friend",{"type":"rift"});world.interact(host.my_id);check(world.boat.passengers.size()==2,"both players board same raft")
 for index in [2,3]:
  var id:="rider"+str(index);host._add_player(id,index);host.positions[id]=dock;world.interact(id)
 check(world.boat.passengers.size()==4,"four players board during shared window")
 var before:Vector2=host.positions.friend;host._packet("friend",{"type":"pos","pos":[before.x+50,before.y]});check(host.positions.friend==before,"host refuses walking packets while aboard")
 host.dodge_at.friend=0;host.invincible_until.friend=0;host._packet("friend",{"type":"dodge"});check(host.invincible_until.friend==0,"raft blocks remote dodge")
 host.hero_ids.friend="pippa";host.levels.friend=6;host.cooldown_at.friend={};host._attack("friend","special",Vector2.RIGHT);check(host.adventure.combat.fern.dances.is_empty(),"raft blocks attack casts")
 world.step_boat(1.21);world.step_boat(3)
 var packet:Dictionary=JSON.parse_string(JSON.stringify(host._snapshot()));check(packet.players.friend.charging and packet.adventure.immersive.boat.moving,"raft motion and movement lock serialize")
 var guest=await party("silverfall");guest.role="guest";guest.host_id="host";guest.my_id="friend";guest._packet("host",host.match_config());guest._packet("host",packet)
 check(guest.adventure.immersive.boat.passengers.size()==4 and guest.adventure.immersive.aboard("friend") and guest.opponents[0].immersive,"guest receives shared raft and authored actors")
 var pos:Array=guest.adventure.immersive.boat.pos.duplicate();guest.adventure.step(2);check(guest.adventure.immersive.boat.pos==pos,"guest does not simulate extra raft movement")
 world.step_boat(12);check(not world.aboard("friend") and world.can_stand(host.positions.friend) and world.can_stand(host.positions[host.my_id]),"party disembarks on legal shore positions")
 host.positions.friend=Vector2(3100,4800);host.positions[host.my_id]=Vector2(3110,4800);host.local_pos=host.positions[host.my_id];host.health.friend=70;host.health[host.my_id]=70
 host.hero_ids.friend="pippa";host.levels.friend=6;host.cooldown_at.friend={};host._attack("friend","secondary",Vector2.RIGHT);host.positions.friend=Vector2(3150,4800);host.positions[host.my_id]=Vector2(3160,4800)
 host.adventure.combat.fern.step(3.01)
 host.adventure.combat.fern.step(1.0)
 check(host.health.friend==78 and host.health[host.my_id]==78,"decoy bloom heals both allies")
 check(host.adventure.combat.effect_time("p:friend","fern_stride")>0 and host.contributions.friend.healing==16,"passive stride and actual healing attribution")
 host.cooldown_at.friend={};host._attack("friend","special",Vector2.RIGHT);packet=JSON.parse_string(JSON.stringify(host._snapshot()));guest._packet("host",packet)
 check(guest.adventure.combat.fern.dances.size()==1,"guest receives travelling maypole ribbons")
 check(not guest.adventure.combat.fern.decoys.is_empty() and guest.adventure.combat.fern.decoys[0].phase=="healing","guest receives yellow healing zone")
 host.adventure.combat.fern.step(2)
 check(host.health.friend==94 and host.health[host.my_id]==94 and host.contributions.friend.healing==48,"party receives 24 HP each across three ticks")
 for game in [host,guest]:
  for voice in game.journey.voices:voice.stop()
  game.queue_free()
 await process_frame;await create_timer(.3).timeout;print("v50 co-op: "+str(failures)+" failures");quit(1 if failures else 0)
