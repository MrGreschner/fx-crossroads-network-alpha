extends SceneTree
var failures:=0
class FakeChannel extends RefCounted:
 var state:=WebRTCDataChannel.STATE_OPEN
 var packets:Array=[]
 func close()->void:state=WebRTCDataChannel.STATE_CLOSED
 func get_ready_state()->int:return state
 func put_packet(bytes:PackedByteArray)->int:packets.append(JSON.parse_string(bytes.get_string_from_utf8()));return OK
class FakePeer extends RefCounted:
 func close()->void:pass
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;print("FAIL: ",message)
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/arcade.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false)
 g.mode="descent";g.role="guest";g.my_id="friend";g.host_id="host";g.roster.assign([{"id":"host","name":"Host"},{"id":"friend","name":"You"}]);g._add_player("host",0);g._add_player("friend",1);g._start_match()
 var r=g.recovery;var channel=FakeChannel.new();g.links.host={"peer":FakePeer.new(),"channel":channel}
 r.seen.host=r.now()-5;r.attempts.host=20;r.step(.1)
 check(r.frozen and r.overlay.visible,"missing host pauses play and shows recovery")
 var hp:int=g.health.friend;var floor:int=g.floor_number;var match_token:String=g.match_id
 r.packet("host",{"type":"link_heartbeat"});r.step(.1)
 check(not r.frozen and r.resync_local,"fresh host resumes with local resync")
 check(g.health.friend==hp and g.floor_number==floor and g.match_id==match_token,"repair does not restart or heal")
 var config:Dictionary=g.match_config();config.type="resume_start";g.health.friend=27;g.floor_number=3;g._packet("host",config);check(g.health.friend==27 and g.floor_number==3,"resumed start metadata does not initialize an existing match")
 r.host_paused=true;r.step(.1);check(r.frozen,"guest respects shared pause")
 r.packet("host",{"type":"session_pause","paused":false});r.step(.1);check(not r.frozen,"host releases shared pause")
 r.remember({"resume_token":"one"});r.server({"type":"resumed","id":"friend","resume_token":"two","roster":g.roster});check(r.token=="two","room resume rotates token")
 r.seen.host=r.now()-5;r.gaps.host=44.9;r.attempts.host=20;r.step(.2)
 check(r.failed and r.frozen and r.solo_button.visible,"expired host offers honest restart")
 g.mode="arena";r.show_overlay();check(not r.solo_button.visible,"PvP cannot restart as solo")
 r.reset();check(not r.frozen and r.token.is_empty() and r.gaps.is_empty(),"leaving clears recovery identity")
 g.mode="descent";g.role="host";g.my_id="host";g.host_id="host";g.started=true;g.links.clear();g.roster.assign([{"id":"host","name":"You"},{"id":"friend","name":"Friend"}]);g._add_player("friend",1)
 r.seen.friend=r.now()-5;r.gaps.friend=44.9;r.attempts.friend=20;r.step(.2)
 check(not g.positions.has("friend") and g.roster.size()==1 and not r.frozen,"co-op host can continue after grace expires")
 g.mode="arena";g.started=true;g.match_id="recovery-test";g.legacy_result_recorded=false;g._add_player("friend",1);g.roster.append({"id":"friend","name":"Friend"});r.seen.friend=r.now()-5;r.gaps.friend=44.9;r.attempts.friend=20
 var wins:int=g.legacy.card.state().arena.standard.wins;var losses:int=g.legacy.card.state().arena.standard.losses;var draws:int=g.legacy.card.state().arena.standard.draws
 r.step(.2)
 check(not g.started and "interrupted" in g.results_reason,"PvP ends without a fabricated winner")
 check(g.legacy.card.state().arena.standard.wins==wins and g.legacy.card.state().arena.standard.losses==losses and g.legacy.card.state().arena.standard.draws==draws,"interruption leaves arena records untouched")
 g.links.clear();g.queue_free();await process_frame;await create_timer(.5).timeout
 print("v76 recovery failures: ",failures);quit(failures)
