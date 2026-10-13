extends SceneTree
class FakeChannel extends RefCounted:
 var packets:Array=[]
 func get_ready_state()->int:return WebRTCDataChannel.STATE_OPEN
 func put_packet(bytes:PackedByteArray)->int:packets.append(JSON.parse_string(bytes.get_string_from_utf8()));return OK
var failures:=0
var checks:=0
func check(ok:bool,t:String)->void:
 checks+=1;print("PASS • " if ok else "FAIL • ",t)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var main=load("res://scenes/main.tscn").instantiate();root.add_child(main);current_scene=main
 for n in 3:await process_frame
 main.set_process(false);main.presentation.close();main.session_menu.resume()
 var host=load("res://scenes/arcade.tscn").instantiate();root.add_child(host);current_scene=host
 var guest=load("res://scenes/arcade.tscn").instantiate();root.add_child(guest)
 for n in 5:await process_frame
 for g in [host,guest]:
  g.set_process(false);g.legacy.set_process(false);g.role="host" if g==host else "guest";g.my_id="host" if g==host else "guest";g.host_id="host";g.mode="coop";g.realm_id="zombie";g.roster.assign([{"id":"host","name":"Host"},{"id":"guest","name":"Guest"}]);g.hero_ids={"host":"ram","guest":"book"};g.lobby_heroes=g.hero_ids.duplicate();g.positions={"host":Vector2(3900,725),"guest":Vector2(3950,725)};g.health={"host":60,"guest":50};g.gold={"host":100,"guest":100};g.xp={"host":0,"guest":0};g.levels={"host":1,"guest":1};g.realm_picker.select(g.realm_picker.get_item_count()-1)
 for i in host.realm_picker.item_count:
  if str(host.realm_picker.get_item_metadata(i))=="zombie":host.realm_picker.select(i)
 guest.match_id="guest_test"
 var outbound=FakeChannel.new();host.links.guest={"channel":outbound};guest.links.host={"channel":FakeChannel.new()}
 host._start_match();host.start_countdown=0;host.positions.host=Vector2(4000,725);host.positions.guest=Vector2(4000,900)
 check(host.opponents.filter(func(e):return e.type in host.adventure.newcomers.TYPES).size()==7,"co-op loads all Quarantine expansion actors")
 for n in 36:host.adventure.newcomers.step(.05)
 var packet=JSON.parse_string(JSON.stringify(host.adventure.snapshot()));guest.adventure.receive(packet)
 check(not guest.adventure.newcomers.warnings.is_empty(),"guest receives host's attack telegraphs")
 host.health.host=50;host.adventure.combat.feedback.healing_numbers.clear();host._heal("guest","host",8)
 check(host.health.host==58 and host.adventure.combat.feedback.healing_numbers.size()==1,"party healing produces green actual-gain number")
 guest.started=true;guest.adventure.combat.feedback._process(.1);guest.health.guest=57;guest.adventure.combat.feedback._process(.1)
 check(not guest.adventure.combat.feedback.healing_numbers.is_empty(),"guest health snapshots show received heals")
 host.started=false;host.results_reason="Party defeated";host.presentation.results(false)
 check(host.presentation.modal.find_children("*","Button",true,false).any(func(b):return b.text=="Replay with party"),"host has direct party replay button")
 guest.started=false;guest.results_reason="Party defeated";guest.presentation.results(false)
 check(not guest.presentation.modal.find_children("*","Button",true,false).any(func(b):return b.text=="Replay with party"),"guest cannot force a room restart")
 host.presentation.return_to_party();pass # start reads picker metadata below
 for i in host.realm_picker.item_count:
  if str(host.realm_picker.get_item_metadata(i))=="zombie":host.realm_picker.select(i)
 host.rule_picker.select(0);host._start_button()
 check(host.started and host.start_countdown==5 and host.results_reason.is_empty(),"replay starts existing five-second countdown and resets results")
 check(outbound.packets.any(func(v):return v.type=="start") and host.roster.size()==2,"replay keeps the room and broadcasts new start")
 host.links.clear();guest.links.clear()
 for g in [host,guest]:
  for voice in g.journey.voices:voice.stop()
 await create_timer(.1).timeout
 main.queue_free();host.queue_free();guest.queue_free();await process_frame
 print("V143 PARTY CHECKS: ",checks,"; FAILURES: ",failures);quit(failures)
