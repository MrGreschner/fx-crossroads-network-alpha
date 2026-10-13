extends SceneTree
var failures:=0
class FakeChannel extends RefCounted:
 var closed:=false
 func close()->void:closed=true
 func get_ready_state()->int:return WebRTCDataChannel.STATE_OPEN
class FakePeer extends RefCounted:
 var closed:=false
 func close()->void:closed=true
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;print("FAIL: ",message)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/arcade.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false)
 g.role="host";g.my_id="host";g.host_id="host";g.roster.assign([{"id":"host","name":"Host"},{"id":"ghost","name":"Traveler"}])
 g.positions.ghost=Vector2.ONE;g.health.ghost=100;g.hero_ids.ghost="ram";g.teams.ghost=1;g.joining_age.ghost=5.0
 var channel=FakeChannel.new();var peer=FakePeer.new();g.links.ghost={"channel":channel,"peer":peer}
 g._server({"type":"peer_left","id":"ghost"})
 check(channel.closed and peer.closed and not g.links.has("ghost"),"departure closes even an apparently open direct link")
 check(g.roster.size()==1 and not g.positions.has("ghost") and not g.hero_ids.has("ghost") and not g.teams.has("ghost"),"authoritative departure cleans all member state")
 g._kick_member("host");check(g.roster.size()==1,"host cannot kick self")
 g.roster.append({"id":"ghost","name":"Traveler"});g.joining_age.ghost=29.9;g._process(.2)
 check(g.roster.size()==1 and not g.joining_age.has("ghost"),"unfinished handshake expires after 30 seconds")
 g.roster.append({"id":"guest","name":"Guest"});g.party_lobby.sync_kicks()
 check(g.party_lobby.kick_buttons.has("guest") and g.party_lobby.kick_buttons.guest.visible,"host has guest kick control")
 g.role="guest";g.party_lobby.sync_kicks();check(not g.party_lobby.kick_buttons.guest.visible,"guest cannot kick")
 g.my_id="guest";g.host_id="host";g._packet("stranger",{"type":"removed_from_room"});check(g.role=="guest","untrusted kick rejected")
 g._packet("host",{"type":"removed_from_room"});check(g.role.is_empty() and g.roster.is_empty(),"host kick tears down room")
 g.queue_free();await process_frame
 print("v101 stability failures: ",failures);quit(failures)
