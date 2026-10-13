extends SceneTree
var failures:=0
class FakeChannel extends RefCounted:
 var packets:Array=[]
 var queued:=0
 var closed:=false
 func close()->void:closed=true
 func get_ready_state()->int:return WebRTCDataChannel.STATE_CLOSED if closed else WebRTCDataChannel.STATE_OPEN
 func get_buffered_amount()->int:return queued
 func put_packet(bytes:PackedByteArray)->int:packets.append(preload("res://scripts/realtime_transport.gd").new().decode(bytes));return OK
class RawChannel extends RefCounted:
 var packets:Array=[]
 func put_packet(bytes:PackedByteArray)->int:packets.append(bytes);return OK
class FakePeer extends RefCounted:
 func close()->void:pass
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var smooth=preload("res://scripts/network_smoothing.gd").new()
 smooth.push("p",Vector2.ZERO,1);smooth.push("p",Vector2(10,0),1.1)
 check(smooth.sample("p",Vector2.ZERO,1.125,.075).is_equal_approx(Vector2(5,0)),"interpolate at presentation time")
 check(smooth.sample("p",Vector2.ZERO,2,.075).is_equal_approx(Vector2(14,0)),"extrapolation holds after 40ms")
 smooth.push("p",Vector2(500,0),1.2);check(smooth.sample("p",Vector2.ZERO,1.2)==Vector2(500,0),"teleports snap without sweeping through walls")
 smooth.push("p",Vector2(1,0),1.1);check(smooth.tracks.p.size()==1,"out-of-order sample ignored")
 for n in 100:smooth.push("p",Vector2(500+n,0),2+n*.05)
 check(smooth.tracks.p.size()==6,"history bounded")
 smooth.prune({});check(smooth.tracks.is_empty(),"deleted actors release history")
 root.set_meta("fx_intro_seen",true)
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false);a.legacy.set_process(false)
 a._set_mode("arena");a.bot_count=1;a._solo();a.start_countdown=0;a.FIELD=Rect2(0,0,10000,10000);a.field_obstacles.clear();a.obstacle_grid.clear();a.camera=Vector2.ZERO;a.terrain_cache.sync()
 var count:int=a.terrain_cache.chunks.size();a.terrain_cache.sync();check(a.terrain_cache.chunks.size()==count,"multiplayer ground commands reused")
 for n in 60:a.camera=Vector2(n%10*512,n/10*512);a.terrain_cache.sync();await process_frame
 check(a.terrain_cache.chunks.size()<=48,"multiplayer terrain cache bounded")
 a.started=false;a.terrain_cache.sync();check(not a.terrain_cache.visible,"lobby hides ground")
 a.started=true;a.role="host";a.my_id="host";a.host_id="host";a.match_id="smooth-test";a.positions.clear();a._add_player("host",0);a._add_player("guest",1)
 var reliable=FakeChannel.new();var fast=FakeChannel.new();a.links.guest={"peer":FakePeer.new(),"channel":reliable,"realtime":fast}
 var state:Dictionary=a._snapshot();state.effects=[{"pos":[100,100],"radius":5,"time":.2,"color":"#ffffff"}]
 a.transport.broadcast_state(state)
 check(fast.packets.size()==1 and fast.packets[0].type=="state","replaceable snapshot uses fast channel")
 check(reliable.packets.size()==2 and reliable.packets[0].type=="player_metadata" and reliable.packets[1].type=="effect_batch","metadata and effects stay reliable")
 check(not fast.packets[0].players.host.has("build") and fast.packets[0].effects.is_empty(),"remove repeated build and event payload")
 var old_size:int=JSON.stringify(state).length();var new_size:int=JSON.stringify(fast.packets[0]).length()
 print("Snapshot bytes full=",old_size," streamlined=",new_size," compressed=",a.transport.wire_snapshot_bytes)
 check(Vector2(a.transport.decode(a.transport.encode(state)).players.host.pos[0],a.transport.decode(a.transport.encode(state)).players.host.pos[1]).is_equal_approx(Vector2(state.players.host.pos[0],state.players.host.pos[1])),"compressed state round trips")
 var raw=RawChannel.new();var decoder=preload("res://scripts/realtime_transport.gd").new()
 var large:Dictionary={"type":"state","payload":"x".repeat(35000)}
 a.transport.put_encoded(raw,JSON.stringify(large).to_utf8_buffer())
 check(raw.packets.size()==3,"large snapshots use bounded fragments")
 check(decoder.decode(raw.packets[1],"host").is_empty(),"incomplete state never applies")
 check(decoder.decode(raw.packets[1],"host").is_empty(),"duplicate fragment does not complete state")
 decoder.decode(raw.packets[2],"host")
 check(decoder.decode(raw.packets[0],"host").get("payload","")==large.payload,"reordered fragments reassemble")
 for n in 5:
  var fragment:PackedByteArray=raw.packets[0].duplicate();fragment.encode_u32(4,100+n);decoder.decode(fragment,"host")
 check(decoder.assemblies.size()==2,"lost fragment assemblies bounded per peer")
 var invalid:PackedByteArray=raw.packets[0].duplicate();invalid.encode_u32(12,3000000)
 check(decoder.decode(invalid,"host").is_empty(),"oversize fragments rejected")
 a.transport.broadcast_state(state);check(reliable.packets.size()==3,"unchanged metadata not resent")
 var prior:int=fast.packets.size();fast.queued=70000;a.transport.broadcast_state(state);check(fast.packets.size()==prior,"backpressure drops replaceable snapshot only")
 state.active=false;state.results="finished";a.transport.broadcast_state(state);check(reliable.packets.back().type=="state" and not reliable.packets.back().active,"final results reliable even when fast congested")
 fast.queued=0;a.transport.step(.1);check(fast.packets.back().type=="motion","20Hz lightweight motion stream")
 a.links.clear();a.role="guest";a.my_id="guest";a.host_id="host"
 var packet:Dictionary=fast.packets[0]
 check(a.transport.accept("host",packet),"first sequenced snapshot accepted")
 check(not a.transport.accept("host",packet),"duplicate snapshot rejected")
 var older:Dictionary=packet.duplicate(true);older.seq=int(packet.seq)-1;check(not a.transport.accept("host",older),"late snapshot rejected")
 older.seq=999;older.match_id="previous-match";check(not a.transport.accept("host",older),"old match cannot overwrite new match")
 a.local_pos=Vector2(105,100);a.position_history[4]=Vector2(100,100);a.health.guest=100;a._reconcile_position(4,Vector2(90,100));check(a.local_pos.is_equal_approx(Vector2(95,100)),"reconcile retains movement since acknowledged input")
 a.transport.received.clear();a._packet("host",reliable.packets[0]);a._packet("host",packet)
 check(a.player_cosmetics.has("host"),"full state applies")
 a._packet("host",{"type":"motion","match_id":a.match_id,"seq":1000,"players":{"host":[200,200]}})
 check(a.smoothing.tracks.has("p:host"),"received motion feeds visual buffer")
 a._packet("host",{"type":"attack_ack","match_id":a.match_id,"style":"primary","accepted":false,"remaining":10})
 check(int(a.request_ready.primary)-Time.get_ticks_msec()<=80,"early attack rejection retries quickly")
 a._packet("host",{"type":"attack_ack","match_id":a.match_id,"style":"primary","accepted":true,"remaining":500})
 check(int(a.request_ready.primary)>Time.get_ticks_msec()+400,"accepted attacks respect authoritative cooldown")
 a.transport.reset();check(a.transport.received.is_empty() and a.transport.metadata.is_empty(),"new match resets transport state")
 a.queue_free();await process_frame
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume();g.enter_region("practice");g.mode="run";g.menu="";g.level=10;g.obstacles.clear();g.scenery_tiles.clear();g.position_in_world=Vector2(1000,1000);g.character_id="tova";g.hero=g.characters.tova;g.enemies.clear()
 var kit=g.adventure.combat.v90;g.adventure.spawn("bramble",Vector2(1094,1000),500,false)
 kit.cast("solo",g.hero.primary,Vector2.RIGHT,21);check(g.enemies[0].hp==500,"reed doesn't damage before visible extension")
 kit.step(.04);check(g.enemies[0].hp==500,"reed has short extension windup")
 kit.step(.031);check(g.enemies[0].hp==479,"reed hits at full extension")
 kit.step(.12);check(g.enemies[0].hp==479,"reed hits once during retraction")
 kit.step(.02);check(not kit.effects.any(func(e):return e.style=="reed"),"reed retracts within 0.2 seconds")
 g.adventure.spawn("hourglass_hart",Vector2(1250,1000),900,true);var boss:Dictionary=g.enemies.back();var before:Vector2=boss.pos
 g.adventure.move_clockwork_hart(boss,g.position_in_world,.1);check(boss.pos.distance_to(before)>5,"clockwork stag moves")
 g.obstacles.assign([{"pos":boss.pos+Vector2(5,0),"radius":30,"kind":"rock"}]);g.build_scenery();before=boss.pos;g.adventure.move_clockwork_hart(boss,g.position_in_world,.1)
 check(boss.pos.distance_to(before)<25,"stag moves in bounded steps")
 g.queue_free();await process_frame
 print("v102 smooth failures: ",failures);quit(failures)
