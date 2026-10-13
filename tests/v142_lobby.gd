extends SceneTree
const R=preload("res://scripts/rolling_crowns.gd")
class FakeChannel extends RefCounted:
 var packets:Array=[]
 func get_ready_state()->int:return WebRTCDataChannel.STATE_OPEN
 func put_packet(bytes:PackedByteArray)->int:packets.append(JSON.parse_string(bytes.get_string_from_utf8()));return OK
var failures=0
func check(ok:bool,t:String)->void:
 print("PASS • " if ok else "FAIL • ",t)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);current_scene=main
 for i in 3:await process_frame
 main.set_process(false);main.presentation.close();main.session_menu.resume()
 var host=load("res://scenes/arcade.tscn").instantiate();root.add_child(host);current_scene=host
 var guest=load("res://scenes/arcade.tscn").instantiate();root.add_child(guest)
 for i in 5:await process_frame
 for game in [host,guest]:game.set_process(false);game.custom_party.set_process(false);game.legacy.set_process(false);game.started=false;game.role="host" if game==host else "guest";game.my_id="host" if game==host else "guest";game.host_id="host";game.roster.assign([{"id":"host","name":"Host"},{"id":"guest","name":"Guest"}]);game.hero_ids={"host":"ram","guest":"book"};game.lobby_heroes=game.hero_ids.duplicate();game.mode="arena";game.legacy.crowns.time_for_test=1770000000;game.legacy.data.rolling_damage={"version":1,"buckets":[]};game.legacy.crowns.refresh()
 host.legacy.crowns.add_damage(100000);guest.legacy.crowns.add_damage(7000)
 var to_host=FakeChannel.new();guest.links.host={"channel":to_host};host.positions={"host":Vector2(400,400),"guest":Vector2(500,400)};host.health={"host":120,"guest":80}
 guest.legacy.crowns.step(11)
 check(not to_host.packets.is_empty() and to_host.packets[0].type=="lobby_cosmetic","guest transmits compact lobby cosmetic update")
 while not to_host.packets.is_empty():host._packet("guest",to_host.packets.pop_front())
 check(R.remote_tier(host.cosmetic_for("guest"))==3 and host.health.guest==80,"host receives crown without resetting hero health")
 for public in [true,false]:
  host.public_room.set_pressed_no_signal(public);var packet=JSON.parse_string(JSON.stringify(host._lobby_packet()));guest._receive_lobby(packet)
  check(R.remote_tier(guest.cosmetic_for("host"))==8 and R.remote_tier(host.cosmetic_for("guest"))==3,"public/code lobby metadata survives transport")
 var custom=preload("res://scripts/workshop_project.gd").fresh();guest.allow_custom=true;guest.custom_party.install("guest",custom)
 guest.legacy.crowns.time_for_test+=R.WINDOW;guest.legacy.crowns.step(11)
 while not to_host.packets.is_empty():host._packet("guest",to_host.packets.pop_front())
 check(R.remote_tier(host.cosmetic_for("guest"))==0,"custom-hero guest crown expires live without resending artwork")
 host.started=true;host._packet("guest",{"type":"lobby_cosmetic","cosmetic":{"crown_damage":100000}});check(R.remote_tier(host.cosmetic_for("guest"))==0,"lobby-only update ignored in battle")
 host.started=false;host._packet("stranger",{"type":"lobby_cosmetic","cosmetic":{"crown_damage":100000}});check(not host.player_cosmetics.has("stranger"),"unknown lobby sender rejected")
 guest.links.clear();host.links.clear();host.queue_free();guest.queue_free();await process_frame
 print("V142 LOBBY COMPLETE • failures=",failures);quit(failures)
