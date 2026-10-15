extends "res://scripts/arcade.gd"
## Arena vertical slice: original combat, dedicated authority, independent rendering.
const PROTOCOL=3
var server_build="unknown"
var authority_builds:Dictionary={}
var ability_view=preload("res://network/ability_view.gd").new()
var local_view=preload("res://network/local_view.gd").new()
var actor_motion=preload("res://network/actor_motion.gd").new()
var cosmetic_cache:Dictionary={}
var cosmetic_cache_until=0
var client_perf=preload("res://network/performance_view.gd").new()
var perf_latest:Dictionary={}
var report_downloads=0
const Move=preload("res://network/movement.gd")
var net_dash:Dictionary={}
var net_velocity:Dictionary={}
var world_view=preload("res://network/world_view.gd").new()
var render_shots:Array=[]
var render_events:Array=[]
var remote_strike_view:Dictionary={}
var confirmed_damage_events=0
var recent_hit_events:Array=[]
var show_hit_geometry=false
var room_paused=false
var dedicated=false
var gateway:Node
var net_peer:WebSocketPeer
var net_ready=false
var net_host=false
var net_room=""
var resume_token=""
var frames:Array=[]
var history:Array=[]
var sequence=0
var applied_seq=0
var authority_tick=0
var shots_view=preload("res://network/projectile_view.gd").new()
var pending_correction=Vector2.ZERO
var net_panel:PanelContainer
var hero_button:Button
var net_status:Label
var url_field:LineEdit
var room_field:LineEdit
var net_start:Button
var net_name:LineEdit
var capacity:OptionButton
var reconnect_until=0
var reconnect_at=0
var next_ping_at=0
var local_strikes:Array=[]
var predicted_actions:Dictionary={}
var pending_bursts:Array=[]
var connect_started_at=0
const DEFAULT_SERVER="wss://fx-crossroads-network-alpha.onrender.com"
var position_samples:Array=[]
var max_input_depth=0
var last_state_at=0
var last_snapshot_seq=-1
var disconnect_reason=""
var slow_status=""
var action_wait_ms=0
var server_hz=60.0
var server_snapshot_ms=0.0
var report_at=0
var server_inputs:Dictionary={}
var server_input_credit:Dictionary={}
var server_actions:Dictionary={}
var input_ack:Dictionary={}
var projectile_serial=0
var action_serial=0
var server_snapshot_tick=0
var last_snapshot_tick=-1
var metrics={"rtt_ms":0,"corrections":0,"max_correction":0.0,"snapshots":0,"wire_bytes":0,"stale":0,"tick_ms":0.0}
func _ready()->void:
 dedicated=get_tree().root.has_meta("fx_dedicated_server")
 if not dedicated:Engine.max_fps=120 # Also bound uncapped native/headless client polling.
 get_tree().root.set_meta("fx_dev_match",true)
 if not InputMap.has_action("primary"):
  InputMap.add_action("primary");var left=InputEventMouseButton.new();left.button_index=MOUSE_BUTTON_LEFT;InputMap.action_add_event("primary",left)
 super._ready()
 _bind_test_controls()
 mode="arena";_set_mode("arena");control.hide();mobile.enabled=not dedicated and mobile.enabled
 legacy.set_process(false)
 if version_check!=null:
  if version_check.request!=null:version_check.request.cancel_request()
  version_check.queue_free();version_check=null
 get_tree().root.get_node("FXActivity").set_process(false)
 if dedicated:
  role="host";my_id="server";host_id="server";spectator_host=true;arena_seats=8
  # Authority advances combat explicitly. Browser UI, media polling and audio helpers do not tick here.
  for child in get_children():child.process_mode=Node.PROCESS_MODE_DISABLED
  return
 role="guest";host_id="server";build_lobby()
func _bind_test_controls()->void:
 for binding in [["move_left",KEY_A],["move_right",KEY_D],["move_up",KEY_W],["move_down",KEY_S],["special",KEY_SPACE],["dodge",KEY_SHIFT],["interact",KEY_E]]:
  var event=InputEventKey.new();event.physical_keycode=binding[1]
  if not InputMap.has_action(binding[0]):InputMap.add_action(binding[0])
  if not InputMap.action_has_event(binding[0],event):InputMap.action_add_event(binding[0],event)
 for binding in [["primary",MOUSE_BUTTON_LEFT],["secondary",MOUSE_BUTTON_RIGHT]]:
  var event=InputEventMouseButton.new();event.button_index=binding[1]
  if not InputMap.has_action(binding[0]):InputMap.add_action(binding[0])
  if not InputMap.action_has_event(binding[0],event):InputMap.action_add_event(binding[0],event)
func build_lobby()->void:
 var layer_node=CanvasLayer.new();layer_node.layer=100;add_child(layer_node)
 net_panel=PanelContainer.new();layer_node.add_child(net_panel);preload("res://scripts/studio_ui.gd").apply(net_panel)
 var box=VBoxContainer.new();net_panel.add_child(box)
 var title=Label.new();title.text="FX CONNECTIONS • DEDICATED ARENA ALPHA T4.8";box.add_child(title)
 var help=Label.new();help.text="Development test • no saved progress • server runs combat\nHost creates a room; everyone, including the host, is a client.";box.add_child(help)
 url_field=LineEdit.new();url_field.text=DEFAULT_SERVER;url_field.placeholder_text="wss://your-test-server";box.add_child(url_field)
 net_name=LineEdit.new();net_name.text="Tester";net_name.placeholder_text="Display name";box.add_child(net_name)
 room_field=LineEdit.new();room_field.placeholder_text="Room code";room_field.max_length=6;box.add_child(room_field)
 capacity=OptionButton.new()
 for number in [2,4,8]:capacity.add_item(str(number)+" players",number)
 box.add_child(capacity)
 capacity.select(1)
 capacity.item_selected.connect(_capacity_changed)
 var heroes=Button.new();hero_button=heroes;heroes.text="Choose hero • Grid view";box.add_child(heroes);heroes.pressed.connect(func():
  if is_instance_valid(hero_grid):return
  hero_grid=preload("res://scripts/hero_grid.gd").new();hero_grid.open(self,selected_hero,net_select,net_permission))
 for entry in [["Host test room","host"],["Join test room","join"]]:
  var b=Button.new();b.text=entry[0];b.custom_minimum_size.y=44;box.add_child(b);b.pressed.connect(connect_net.bind(entry[1]))
 net_start=Button.new();net_start.text="Start match";net_start.custom_minimum_size.y=44;net_start.disabled=true;box.add_child(net_start);net_start.pressed.connect(func():send_net({"type":"start"}))
 var leave=Button.new();leave.text="Leave test • return to town";box.add_child(leave);leave.pressed.connect(func():
  if net_peer!=null:send_net({"type":"leave"});net_peer.close()
  get_tree().root.remove_meta("fx_dev_match");get_tree().change_scene_to_file("res://scenes/main.tscn"))
 net_status=Label.new();net_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;net_status.text="Online test server selected • choose Host or enter a room code and Join.";box.add_child(net_status)
 for field in [url_field,net_name,room_field]:
  var typing=preload("res://scripts/mobile_text_entry.gd").new();field.add_child(typing);typing.setup(field)
func _capacity_changed(_index:int)->void:
 if not net_ready or not net_host or started:return
 send_net({"type":"capacity","seats":capacity.get_selected_id()})
 net_status.text="Updating room capacity…"
func net_select(id:String)->bool:
 if id.begins_with("custom_"):return false
 selected_hero=id;preferred_hero=id;hero_button.text="Hero • "+str(characters[id].name)
 if net_ready:send_net({"type":"hero","hero":id})
 return true
func net_permission(id:String)->String:return "Official heroes only during networking validation." if id.begins_with("custom_") else ""
func connect_net(kind:String)->void:
 if net_ready and kind in ["host","join"]:
  net_status.text="Already connected to room "+net_room+". Host: press Start match.";return
 if net_peer!=null:net_peer.close()
 frames.clear();net_ready=false;connect_started_at=Time.get_ticks_msec()
 net_peer=WebSocketPeer.new();net_peer.inbound_buffer_size=1048576;net_peer.outbound_buffer_size=65536;net_peer.max_queued_packets=256;net_peer.heartbeat_interval=5.0
 if url_field.text.strip_edges().is_empty():url_field.text=DEFAULT_SERVER
 var error=net_peer.connect_to_url(url_field.text.strip_edges())
 if error!=OK:net_status.text="Cannot connect: "+error_string(error);return
 if kind=="resume":started=false
 set_meta("joining",kind);net_status.text="Connecting…"
func send_net(data:Dictionary)->void:
 if net_peer==null or net_peer.get_ready_state()!=WebSocketPeer.STATE_OPEN:return
 if net_peer.get_current_outbound_buffered_amount()>32768:
  disconnect_reason="client_outbound_stalled";net_status.text="Connection stalled; waiting for recovery…";return
 net_peer.send_text(JSON.stringify(data))
func poll_net()->void:
 if net_peer==null:return
 net_peer.poll()
 if not net_ready and has_meta("joining") and Time.get_ticks_msec()-connect_started_at>60000:
  remove_meta("joining");net_peer.close();net_status.text="Connection timed out. Check the server /health page and try again.";return
 if net_peer.get_ready_state()==WebSocketPeer.STATE_OPEN:
  if has_meta("joining"):
   var kind=str(get_meta("joining"));remove_meta("joining")
   send_net({"type":kind,"protocol":PROTOCOL,"hero":preferred_hero,"name":net_name.text.left(24),"room":room_field.text.strip_edges().to_upper(),"seats":capacity.get_selected_id(),"token":resume_token})
  if net_ready and Time.get_ticks_msec()>=next_ping_at:
   next_ping_at=Time.get_ticks_msec()+2000;send_net({"type":"ping","sent":Time.get_ticks_msec()});send_net({"type":"transport_ping","sent":Time.get_ticks_msec()})
  var latest={};var budget=96;var poll_deadline=Time.get_ticks_usec()+2500
  while net_peer.get_available_packet_count()>0 and budget>0 and Time.get_ticks_usec()<poll_deadline:
   budget-=1;var bytes=net_peer.get_packet();metrics.wire_bytes+=bytes.size()
   if not net_peer.was_string_packet():bytes=bytes.decompress_dynamic(2097152,FileAccess.COMPRESSION_GZIP)
   var message=JSON.parse_string(bytes.get_string_from_utf8())
   if not message is Dictionary:continue
   if str(message.get("type",""))=="state":
    _buffer_state(message);latest=message
   else:receive_net(message)
  metrics.pending_packets=net_peer.get_available_packet_count()
  if int(metrics.pending_packets)>0:metrics.poll_budget_yields=int(metrics.get("poll_budget_yields",0))+1
  if not latest.is_empty():receive_net(latest)
 elif net_peer.get_ready_state()==WebSocketPeer.STATE_CLOSED:
  disconnect_reason="socket_closed_"+str(net_peer.get_close_code())+": "+net_peer.get_close_reason()
  net_ready=false
  if has_meta("joining"):
   remove_meta("joining");net_status.text="Connection closed before room confirmation. Check the server address and browser Console."
  if not resume_token.is_empty():
   if reconnect_until==0:reconnect_until=Time.get_ticks_msec()+15000
   if Time.get_ticks_msec()>reconnect_until:
    started=false;net_panel.show();net_status.text="Connection lost. Room can no longer be resumed.";resume_token=""
   elif Time.get_ticks_msec()>=reconnect_at:
    reconnect_at=Time.get_ticks_msec()+1500;room_field.text=net_room;connect_net("resume")
func receive_net(data:Dictionary)->void:
 match str(data.get("type","")):
  "welcome":
   server_build=str(data.get("build","unknown"))
   my_id=str(data.id);net_room=str(data.room);resume_token=str(data.token);net_host=bool(data.host);net_ready=true;reconnect_until=0;capacity.disabled=not net_host
   room_field.text=net_room;net_status.text="Room "+net_room+" • server connected";net_start.disabled=not net_host
  "lobby":
   roster.assign(data.members);net_host=str(data.host)==my_id;net_start.disabled=not net_host or roster.size()<2
   capacity.disabled=not net_host
   capacity.select(capacity.get_item_index(int(data.seats)))
   net_status.text="Room "+net_room+" • "+str(roster.size())+" / "+str(data.seats)+" players • "+str(data.get("message",""))
  "error":net_status.text=str(data.get("message","Error"));net_panel.show()
  "start":
   mode="arena";match_id=str(data.match_id);floor_seed=int(data.seed);arena_map=str(data.arena_map);arena_seats=int(data.seats);spectator_host=false;bot_count=0;arena_no_items=true;pvp_rule="ffa"
   hero_ids=data.heroes;selected_hero=str(hero_ids.get(my_id,preferred_hero));preferred_hero=selected_hero
   positions.clear();authority_builds.clear()
   for id in hero_ids:positions[id]=Vector2.ZERO
   sequence=0;action_serial=0;history.clear();frames.clear();last_snapshot_tick=-1;last_snapshot_seq=-1;applied_seq=0;pending_correction=Vector2.ZERO
   _start_match();ability_view.reset();local_view.reset(local_pos);start_countdown=0;control.hide();net_panel.hide();shots_view.tracks.clear();shots_view.predicted.clear();local_strikes.clear();predicted_actions.clear();pending_bursts.clear();world_view.clear();actor_motion.clear();render_shots.clear();render_events.clear();remote_strike_view.clear();confirmed_damage_events=0;recent_hit_events.clear()
  "state":
   var tick=int(data.get("server_tick",0))
   var serial=int(data.get("snapshot_seq",tick))
   if serial<=last_snapshot_seq:metrics.stale+=1;return
   last_state_at=Time.get_ticks_msec()
   last_snapshot_seq=serial;server_hz=float(data.get("actual_hz",60));server_snapshot_ms=float(data.get("snapshot_ms",0))
   last_snapshot_tick=tick;metrics.snapshots+=1;metrics.tick_ms=float(data.get("tick_ms",0))
   receive_events(data)
   var own:Dictionary=data.get("players",{}).get(my_id,{})
   var dash:Array=own.get("dash",[0,0,0])
   net_dash[my_id]={"time":float(dash[0]),"direction":Vector2(float(dash[1]),float(dash[2]))}
   for actor in positions.keys():
    if not data.get("players",{}).has(actor):
     positions.erase(actor);health.erase(actor);hero_ids.erase(actor);remote_draw_pos.erase(actor)
   # Install both local and remote authoritative builds BEFORE replaying inputs.
   for actor in data.get("players",{}):authority_builds[str(actor)]=legacy.sanitize_build(data.players[actor].get("build",{}))
   var before_ability_draw=_local_draw_position()
   var before_ability_hp=int(health.get(my_id,0))
   var apply_began=Time.get_ticks_usec()
   data.effects=[];super._packet("server",data)
   client_perf.work("snapshot_apply",Time.get_ticks_usec()-apply_began)
   if not own.is_empty():
    var point=Vector2(float(own.pos[0]),float(own.pos[1]))
    if before_ability_draw.distance_to(point)>160 or before_ability_hp<=0 and int(own.get("hp",0))>0:
     ability_view.reset();local_view.reset(local_pos)
    else:ability_view.receive(bool(own.get("stance_moving",false)),before_ability_draw,point)
   shots_view.local_owner=my_id;shots_view.latency=float(metrics.rtt_ms)/1000.0
  "input_resync":
   if str(data.get("match_id",""))!=match_id:return
   var expected=int(data.get("expected",1))
   var retry=history.filter(func(frame):return int(frame.seq)>=expected)
   if retry.is_empty() or int(retry[0].seq)!=expected:
    send_net({"type":"input_reset","match_id":match_id,"seq":sequence});return
   for index in range(0,retry.size(),8):send_net({"type":"input","match_id":match_id,"frames":retry.slice(index,index+8),"event_ack":applied_seq})
  "events":receive_events(data)
  "action_ack":
   action_wait_ms=int(data.get("wait_ms",0))
   if not bool(data.accepted):
    var rejected=int(data.seq);shots_view.reject(rejected)
    local_strikes=local_strikes.filter(func(x):return int(x.action_seq)!=rejected)
    pending_bursts=pending_bursts.filter(func(x):return int(x.seq)!=rejected)
   if data.has("style"):request_ready[str(data.style)]=Time.get_ticks_msec()+maxi(80,int(data.get("remaining",0))-int(metrics.rtt_ms))
  "transport_pong":metrics.gateway_rtt_ms=Time.get_ticks_msec()-int(data.sent)
  "pong":metrics.rtt_ms=Time.get_ticks_msec()-int(data.sent)
func _process(delta:float)->void:
 if dedicated:return
 var frame_began=Time.get_ticks_usec();client_perf.frame(frame_began)
 VIEW=get_viewport_rect().size
 var poll_began=Time.get_ticks_usec();poll_net();client_perf.work("network_poll",Time.get_ticks_usec()-poll_began)
 control.hide();mobile.visible=started
 _report_network()
 if not started and is_instance_valid(net_panel):net_panel.visible=not is_instance_valid(hero_grid)
 if is_instance_valid(net_panel):net_panel.size=Vector2(minf(850,VIEW.x-24),minf(590,VIEW.y-24));net_panel.position=(VIEW-net_panel.size)*.5
 if not started:queue_redraw();client_perf.work("client_process",Time.get_ticks_usec()-frame_began);return
 ability_view.advance(delta)
 visual_time+=delta;motion_v85.advance(delta);skating_motion.advance(delta);actor_motion.advance(delta);actor_motion.prune(positions.keys())
 _advance_local_previews(delta)
 world_view.advance(delta)
 render_shots=world_view.shots()
 # Confirmed owned projectiles share the opponents' playback clock. Receiving
 # a latest packet must not remove them while an older world is still drawn.
 var own_shots:Array=[]
 for shot in render_shots:
  if str(shot.owner)==my_id:own_shots.append(shot)
 shots_view.receive(own_shots,Time.get_ticks_msec()/1000.0)
 _update_remote_strikes()
 for n in range(render_events.size()-1,-1,-1):
  if float(render_events[n].tick)/60.0<=world_view.render_time:
   var event:Dictionary=render_events[n].data
   var late=world_view.render_time-float(render_events[n].tick)/60.0
   if late<=.3 or str(event.get("style","")) in ["damage","heal_contact"]:_receive_effect(event)
   render_events.remove_at(n)
 # Both local previews and confirmed seeds use the existing combat artwork.
 var custom_shots:Array=[]
 for shot in render_shots:
  if str(shot.owner)!=my_id and bool(shot.get("custom",false)):
   var copy:Dictionary=shot.art.duplicate(true);copy.pos=[shot.draw_pos.x,shot.draw_pos.y];copy.net_rendered=true;custom_shots.append(copy)
 for track in shots_view.tracks.values():
  if bool(track.get("custom",false)):
   var copy:Dictionary=track.art.duplicate(true);var point=shots_view.point(track,Time.get_ticks_msec()/1000.0)
   copy.pos=[point.x,point.y];copy.net_rendered=true;custom_shots.append(copy)
 adventure.combat.projectiles=custom_shots
 var visual_pair=world_view.pair()
 for actor in positions:
  if actor!=my_id:
   remote_draw_pos[actor]=_remote_position(str(actor),Time.get_ticks_msec()/1000.0)
   if not visual_pair.is_empty():
    var sample:Dictionary=visual_pair[0];var info:Dictionary=sample.data.get("players",{}).get(actor,{})
    var age_ms=maxf(0,world_view.render_time-float(sample.t))*1000
    attack_pose_until[actor]=Time.get_ticks_msec()+maxi(0,int(info.get("pose",0))-int(age_ms))
  var ground=_local_draw_position() if actor==my_id else remote_draw_pos.get(actor,positions[actor])
  actor_motion.sample(str(actor),ground)
  motion_v85.sample(str(actor),str(hero_ids.get(actor,"ram")),ground,true)
  skating_motion.sample(str(actor),ground,delta,true);wing_motion.step(str(actor),ground,delta,true);basketball_motion.step(str(actor),ground,delta,true);fish_motion.step(str(actor),ground,delta,true)
 missiles.assign(shots_view.samples(Time.get_ticks_msec()/1000.0))
 for shot in render_shots:
  if str(shot.owner)!=my_id and not bool(shot.get("custom",false)):missiles.append({"pos":shot.draw_pos,"owner":shot.owner,"color":shot.color})
 adventure.combat.held_cast.local_input(delta,net_ready and presentation.page.is_empty() and Time.get_ticks_msec()-last_state_at<400)
 if net_ready and presentation.page.is_empty() and Time.get_ticks_msec()-last_state_at<400:
  if (mobile.attacking if mobile.enabled else Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):_attack_request("primary")
  if Input.is_action_pressed("secondary"):_attack_request("secondary")
  if Input.is_action_just_pressed("special"):_attack_request("special")
 _refresh_draw_camera()
 if terrain_cache!=null:terrain_cache.sync()
 for n in range(effects.size()-1,-1,-1):
  effects[n].time-=delta
  if effects[n].time<=0:effects.remove_at(n)
 for n in range(damage_labels.size()-1,-1,-1):
  damage_labels[n].time-=delta;damage_labels[n].pos+=Vector2(0,-35)*delta
  if damage_labels[n].time<=0:damage_labels.remove_at(n)
 queue_redraw()
 client_perf.work("client_process",Time.get_ticks_usec()-frame_began)
func _physics_process(_delta:float)->void:
 if dedicated:
  if not started or room_paused:return
  var begin=Time.get_ticks_usec();authority_tick+=1
  if gateway!=null:gateway.simulation_steps+=1
  var before_positions=positions.duplicate()
  set_meta("fx_network_previous_positions",before_positions)
  for id in positions:
   # Credit is earned by server ticks, never by the number of client packets.
   # Two-step catch-up drains jitter backlog without unbounded fast-forward.
   server_input_credit[id]=minf(12,float(server_input_credit.get(id,0))+1)
   var queue:Array=server_inputs.get(id,[])
   var steps=mini(2,mini(queue.size(),int(server_input_credit[id])))
   for _step in steps:
    var f:Dictionary=queue.pop_front();input_ack[id]=int(f.seq);server_input_credit[id]-=1
    var direction=Vector2(float(f.d[0]),float(f.d[1]))
    positions[id]=Move.advance(self,str(id),positions[id],direction)
    var aim=Vector2.from_angle(float(f.a));aim_angles[id]=float(f.a)
    adventure.combat.release_heroes.holding(str(id),bool(f.sh),aim);adventure.combat.classics.holding(str(id),bool(f.sh));adventure.combat.v79.holding(str(id),bool(f.sh),aim);adventure.combat.v56.holding(str(id),bool(f.ph),aim)
    _execute_due_actions(str(id))
   _execute_due_actions(str(id))
  run_time+=Move.DT;visual_time+=Move.DT;arena_world.step(Move.DT);adventure.step(Move.DT);_update_flames(Move.DT);_simulate_charges(Move.DT);_simulate(Move.DT)
  for actor in positions:net_velocity[actor]=(positions[actor]-before_positions.get(actor,positions[actor]))/Move.DT
  for bullet in missiles:
   if not bullet.has("net_id"):
    projectile_serial+=1;bullet.net_id=projectile_serial
    bullet.born_tick=authority_tick-float(bullet.get("distance",0))/maxf(1,float(bullet.get("speed",420)))*60
  metrics.tick_ms=(Time.get_ticks_usec()-begin)/1000.0
  position_samples.append({"tick":authority_tick,"points":positions.duplicate(),"hp":health.duplicate()})
  while position_samples.size()>16:position_samples.pop_front()
  if authority_tick%3==0:gateway.snapshot(self)
  if gateway!=null:
   var complete=(Time.get_ticks_usec()-begin)/1000.0
   gateway.work_window+=complete;gateway.step_work_max_ms=maxf(gateway.step_work_max_ms,complete)
  return
 if not started or not net_ready:return
 var physics_began=Time.get_ticks_usec()
 var direction:Vector2=mobile.movement if mobile.enabled else Input.get_vector("move_left","move_right","move_up","move_down")
 if not presentation.page.is_empty():direction=Vector2.ZERO
 var aim:Vector2=mobile.aim if mobile.enabled else (media_mouse_world()-local_pos).normalized()
 if Input.is_action_just_pressed("dodge") and Move.movable(self,my_id) and Time.get_ticks_msec()>=int(dodge_at.get(my_id,0)):
  var dash_direction=direction.normalized() if not direction.is_zero_approx() else aim
  net_dash[my_id]={"time":.26,"direction":dash_direction};dodge_at[my_id]=Time.get_ticks_msec()+2500
  _send_channel(host_id,{"type":"dodge","direction":[dash_direction.x,dash_direction.y]})
 if history.size()>=180 or Time.get_ticks_msec()-last_state_at>400:direction=Vector2.ZERO
 sequence+=1
 var frame={"seq":sequence,"d":[snappedf(direction.x,.001),snappedf(direction.y,.001)],"a":aim.angle(),"ph":mobile.attacking if mobile.enabled else Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT),"sh":Input.is_action_pressed("secondary")}
 frames.append(frame);history.append(frame)
 if history.size()>180:
  # Bounded replay during a prolonged stall. Wait for authority; do not keep moving or reconnect.
  slow_status="Waiting for authoritative state…";history=history.slice(-180)
  direction=Vector2.ZERO
 else:slow_status=""
 var before_prediction=local_pos
 local_pos=Move.advance(self,my_id,local_pos,direction)
 if pending_correction.length_squared()>0:
  var repair=pending_correction*.25;local_pos+=repair;pending_correction-=repair
  if pending_correction.length()<.1:pending_correction=Vector2.ZERO
 positions[my_id]=local_pos
 local_view.capture(before_prediction,local_pos)
 if sequence%2==0:
  send_net({"type":"input","match_id":match_id,"frames":frames,"event_ack":applied_seq});frames=[]

 client_perf.work("client_physics",Time.get_ticks_usec()-physics_began)

func _reconcile_position(ack:int,point:Vector2)->void:
 if ack<0:return
 history=history.filter(func(f):return int(f.seq)>ack)
 var repaired=point
 var dash_before=net_dash.get(my_id,{}).duplicate(true)
 for frame in history:repaired=Move.advance(self,my_id,repaired,Vector2(float(frame.d[0]),float(frame.d[1])))
 net_dash[my_id]=dash_before
 var error=repaired-local_pos
 metrics.max_correction=maxf(float(metrics.max_correction),error.length())
 if error.length()>1:metrics.corrections+=1
 if error.length()>80:local_pos=repaired;local_view.reset(local_pos);pending_correction=Vector2.ZERO
 else:pending_correction=error if error.length()>.75 else Vector2.ZERO
 positions[my_id]=local_pos
func _send_channel(_id:String,data:Dictionary)->void:
 if dedicated:
  if gateway!=null:gateway.send_actor(_id,data)
  return
 action_serial+=1;var packet=data.duplicate(true);packet.seq=action_serial;packet.input_seq=sequence;packet.match_id=match_id;packet.view_tick=maxi(0,floori(world_view.render_time*60))
 send_net(packet)
 if str(data.get("type",""))=="attack":_preview_attack(str(data.get("style","primary")),data,action_serial)
 elif str(data.get("type",""))=="held_cast" and str(data.get("phase",""))=="release":
  var held=adventure.combat.held_cast
  if held.charges.has(my_id):
   var kind=str(data.get("kind","primary"));held.context[my_id]=held.charges[my_id].duplicate(true)
   var stats:Dictionary=held.stats_for(my_id,kind);held.context.erase(my_id)
   _preview_attack(kind,data,action_serial,stats)
func _broadcast(data:Dictionary)->void:
 if dedicated and gateway!=null:
  if str(data.get("type",""))=="state":gateway.snapshot(self)
  else:gateway.broadcast_game(self,data)
func _has_open_link()->bool:return dedicated and gateway!=null or net_ready
func _track_card_progress()->void:pass
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F8:
  download_performance();get_viewport().set_input_as_handled();return
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F7:
  show_hit_geometry=not show_hit_geometry;get_viewport().set_input_as_handled();return
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE and started:
  if session_menu.page.is_empty():session_menu.main()
  else:session_menu.resume()
func _draw()->void:
 if dedicated:return
 var draw_began=Time.get_ticks_usec()
 set_meta("fx_drawing_world",true)
 super._draw()
 set_meta("fx_drawing_world",false)
 client_perf.work("draw_commands",Time.get_ticks_usec()-draw_began)
 if not started:return
 draw_set_transform(media.offset(),0,Vector2.ONE*media.factor())
 # Local feedback is a muzzle flash, never an unconfirmed travelling bullet.
 for shot in shots_view.predicted:
  var now=Time.get_ticks_msec()/1000.0
  var age=now-float(shot.t)
  if age<0 or age>shots_view.MUZZLE_SECONDS:continue
  var direction:Vector2=shot.v.normalized()
  var p=_local_draw_position()+direction*27-camera
  var tint=Color(str(shot.color));tint.a=.7*(1-age/shots_view.MUZZLE_SECONDS)
  draw_arc(p,6,direction.angle()-.8,direction.angle()+.8,8,tint,2,true)
 if show_hit_geometry:
  for actor in positions:
   var ground:Vector2=local_pos if actor==my_id else remote_draw_pos.get(actor,positions[actor])
   var tint=Color("#ffdd77") if int(health.get(actor,0))>0 else Color("#888888")
   draw_arc(ground-camera,18,0,TAU,32,tint,2,true)
   var protected=Time.get_ticks_msec()<int(invincible_until.get(actor,0))
   if actor!=my_id:
    var info:Dictionary=world_view.data().get("players",{}).get(actor,{})
    protected=float(info.get("invincible",0))>_render_sample_age()*1000
   if protected:draw_arc(ground-camera,23,0,TAU,32,Color("#70dfff"),3,true)
 draw_set_transform(Vector2.ZERO)
 var cpu=perf_latest.get("client_profile",{}).get("client_process",{}).get("p95_ms",0)
 var draw_ms=perf_latest.get("client_profile",{}).get("draw_commands",{}).get("p95_ms",0)
 draw_rect(Rect2(174,VIEW.y-82,minf(VIEW.x-180,1040),25),Color(0,.08,.12,.85))
 draw_string(preload("res://assets/fonts/CrossroadsUI.ttf"),Vector2(180,VIEW.y-63),"Update p95 %.1f ms • draw commands p95 %.1f ms • F8: download performance report" % [cpu,draw_ms],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
 draw_string(preload("res://assets/fonts/CrossroadsUI.ttf"),Vector2(180,VIEW.y-40),"T4.8 • RTT %d ms • sim %.2f ms • snapshot %.2f ms • input queue %d • authority %.0f Hz" % [metrics.rtt_ms,metrics.tick_ms,server_snapshot_ms,history.size(),server_hz],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#a8ddf0"))

 draw_string(preload("res://assets/fonts/CrossroadsUI.ttf"),Vector2(180,VIEW.y-22),"T4.8 • remote buffer %d ms • buffer holds %d • FPS %d" % [maxf(0,world_view.latest_time-world_view.render_time)*1000,world_view.underruns,Engine.get_frames_per_second()],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#a8ddf0"))

func _effect_at_actor(effect:Dictionary)->Dictionary:
 var owner=str(effect.get("owner",""))
 if owner.is_empty() or not positions.has(owner) or str(effect.get("style","")) not in ["melee","punch","scratch","slash","kick"]:return effect
 var anchored=effect.duplicate()
 anchored.pos=_local_draw_position() if owner==my_id else remote_draw_pos.get(owner,positions[owner])
 return anchored
func _draw_effect(effect:Dictionary)->void:
 super._draw_effect(_effect_at_actor(effect))

func melee_visual_position(owner:String,fallback:Vector2)->Vector2:
 if not positions.has(owner):return fallback
 if dedicated:return positions[owner]
 return _local_draw_position() if owner==my_id else remote_draw_pos.get(owner,positions[owner])

func _preview_attack(kind:String,data:Dictionary,seq:int,override_stats:Dictionary={})->void:
 var stats:Dictionary=override_stats if not override_stats.is_empty() else adventure.combat.effective_stats(my_id,kind,characters.get(selected_hero,{}).get(kind,{}))
 var style=str(stats.get("style",""));var aim=Vector2.from_angle(float(data.get("angle",0)))
 var now=Time.get_ticks_msec()/1000.0
 predicted_pose_until=Time.get_ticks_msec()+240
 if style=="identity_strike":
  local_strikes.append({"owner":my_id,"pos":[local_pos.x,local_pos.y],"aim":[aim.x,aim.y],"visual":stats.get("visual","horns"),"range":stats.get("range",82),"time":.26,"action_seq":seq})
  predicted_actions[seq]=now+1.0
 elif style in ["projectile","ranged"]:
  var count=clampi(int(stats.get("count",1)),1,8)
  for n in count:
   var direction=aim.rotated((n-(count-1)*.5)*float(stats.get("spread",0)))
   shots_view.preview(my_id,seq,local_pos+direction*27,direction*float(stats.get("speed",420)),str(stats.get("color","#ffd985")),now,n,float(stats.get("range",480)),float(stats.get("projectile_radius",7)))
 elif style=="burst_projectile":
  for n in clampi(int(stats.get("count",4)),1,5):pending_bursts.append({"seq":seq,"index":n,"at":now+n*float(stats.get("burst_interval",.1)),"aim":aim,"stats":stats})
  _advance_local_previews(0)
func _advance_local_previews(delta:float)->void:
 var now=Time.get_ticks_msec()/1000.0
 for seq in predicted_actions.keys():
  if now>float(predicted_actions[seq]):predicted_actions.erase(seq)
 for n in range(local_strikes.size()-1,-1,-1):
  local_strikes[n].time-=delta
  if float(local_strikes[n].time)<=0:local_strikes.remove_at(n)
 for n in range(pending_bursts.size()-1,-1,-1):
  var burst=pending_bursts[n]
  if now<float(burst.at):continue
  var stats:Dictionary=burst.stats;var direction:Vector2=burst.aim
  shots_view.preview(my_id,int(burst.seq),local_pos+direction*26,direction*float(stats.get("speed",480)),str(stats.get("color","#b5dc79")),now,int(burst.index),float(stats.get("range",360)),float(stats.get("projectile_radius",12)),_preview_art(stats,direction))
  pending_bursts.remove_at(n)
func predicted_identity_strikes()->Array:return local_strikes
func suppress_confirmed_strike(entry:Dictionary)->bool:return str(entry.owner)==my_id and predicted_actions.has(int(entry.get("action_seq",-1)))
func object_projectile_display(shot:Dictionary,fallback:Vector2)->Vector2:
 var identity:Dictionary=shot.duplicate();identity.custom=true
 var key=preload("res://network/world_view.gd").shot_key(identity)
 return shots_view.point(shots_view.tracks[key],Time.get_ticks_msec()/1000.0) if shots_view.tracks.has(key) else fallback

func _remote_position(actor:String,_now:float)->Vector2:
 return world_view.player(actor,positions.get(actor,Vector2.ZERO))
func _buffer_state(data:Dictionary)->void:
 # Preserve EVERY snapshot for interpolation, even when only the newest state
 # is applied to gameplay/reconciliation during this frame.
 var all:Array=data.get("shots",[]).duplicate(true)
 var custom:Array=data.get("adventure",{}).get("combat",{}).get("projectiles",[])
 for shot in custom:
  if not shot.has("net_id"):continue
  var aim=adventure.combat.vec(shot.aim)*float(shot.speed)
  all.append({"net_id":shot.net_id,"pos":shot.pos,"velocity":[aim.x,aim.y],"owner":shot.owner,"color":shot.color,"action_seq":shot.get("action_seq",-1),"shot_index":shot.get("shot_index",0),"born":float(shot.get("born_tick",0))/60.0,"custom":true,"art":shot})
 data.render_shots=all
 world_view.receive(data)
func _preview_art(stats:Dictionary,aim:Vector2)->Dictionary:
 return {"pos":[0,0],"aim":[aim.x,aim.y],"base_aim":[aim.x,aim.y],"origin":[0,0],"radius":float(stats.get("projectile_radius",12)),"style":"pellet","stats":stats.duplicate(true),"color":str(stats.get("color","#edf7ff")),"distance":0.0,"speed":float(stats.get("speed",480))}

func _update_remote_strikes()->void:
 var data=world_view.data()
 var remote:Array=data.get("adventure",{}).get("combat",{}).get("classics",{}).get("strikes",[])
 for entry in remote:
  if str(entry.owner)==my_id:continue
  var key=str(entry.owner)+":"+str(entry.get("action_seq",-1))
  if remote_strike_view.has(key):continue
  var age=.26-float(entry.time)+_render_sample_age()
  remote_strike_view[key]={"data":entry.duplicate(true),"began":world_view.render_time-age}
 for key in remote_strike_view.keys():
  if world_view.render_time-float(remote_strike_view[key].began)>=.34:remote_strike_view.erase(key)
func network_identity_strikes()->Array:
 var result:Array=[]
 for value in remote_strike_view.values():
  var copy:Dictionary=value.data.duplicate()
  copy.time=.26*clampf(1-(world_view.render_time-float(value.began))/.34,0,1)
  if float(copy.time)>0:result.append(copy)
 for entry in adventure.combat.classics.strikes:
  if str(entry.owner)==my_id:result.append(entry)
 return result
func _receive_effect(event:Dictionary)->void:
 if str(event.get("style",""))=="damage":
  confirmed_damage_events+=1
  recent_hit_events.append({"tick":last_snapshot_tick,"victim":str(event.get("victim","")),"amount":float(event.get("amount",0))})
  while recent_hit_events.size()>12:recent_hit_events.pop_front()
 super._receive_effect(event)

func _execute_due_actions(actor:String)->void:
 var actions:Array=server_actions.get(actor,[])
 while not actions.is_empty() and int(actions[0].get("input_seq",0))<=int(input_ack.get(actor,0)):
  gateway.execute_action(self,actor,actions.pop_front())

func _render_sample_age()->float:
 var values=world_view.pair()
 return maxf(0,world_view.render_time-float(values[0].t)) if not values.is_empty() else 0.0
func network_v112_effects()->Array:
 var result:Array=[]
 var data=world_view.data()
 for effect in data.get("adventure",{}).get("combat",{}).get("v112",{}).get("effects",[]):
  if str(effect.owner)==my_id:continue
  var copy:Dictionary=effect.duplicate();var elapsed=_render_sample_age()
  copy.age=float(copy.get("age",0))+elapsed;copy.time=float(copy.time)-elapsed
  if float(copy.time)>0:result.append(copy)
 for effect in adventure.combat.v112.effects:
  if str(effect.owner)==my_id:result.append(effect)
 return result

func rewind_melee_targets(actor:String,data:Dictionary)->Dictionary:
 if str(data.get("type",""))!="attack" or str(data.get("style",""))!="primary":return {}
 var stats:Dictionary=characters.get(str(hero_ids.get(actor,"")),{}).get("primary",{})
 if str(stats.get("style","")) not in ["melee","cone","arc","identity_strike"]:return {}
 if position_samples.is_empty():return {}
 var wanted=clampi(int(data.get("view_tick",authority_tick)),maxi(0,authority_tick-12),authority_tick)
 var sample:Dictionary=position_samples[0]
 for item in position_samples:
  if int(item.tick)<=wanted:sample=item
 var restore={}
 for other in positions:
  if other==actor or not sample.points.has(other):continue
  if int(health.get(other,0))<=0 or int(sample.hp.get(other,0))<=0:continue
  var historical:Vector2=sample.points[other]
  if positions[other].distance_to(historical)>100 or not _clear_path(positions[other],historical):continue
  restore[other]={"present":positions[other],"historical":historical};positions[other]=historical
 return restore
func restore_targets(saved:Dictionary)->void:
 for actor in saved:
  if positions.has(actor):positions[actor]=_move_actor(saved[actor].present,positions[actor]-saved[actor].historical)
func end_match(reason:String)->void:
 if not dedicated:super.end_match(reason);return
 if not started:return
 for actor in positions:arena_outcomes[actor]=_arena_outcome(str(actor))
 started=false;results_reason=reason;status_label.text=reason
 if gateway!=null:gateway.snapshot(self)

func network_projectile_near(start:Vector2,finish:Vector2,key:String,point:Vector2,radius:float)->bool:
 if dedicated and key.begins_with("p:") and has_meta("fx_network_previous_positions"):
  var previous:Dictionary=get_meta("fx_network_previous_positions")
  var actor=key.trim_prefix("p:")
  if previous.has(actor):
   var old:Vector2=previous[actor]
   if old.distance_to(point)<120:
    return Geometry2D.get_closest_point_to_segment(Vector2.ZERO,start-old,finish-point).length()<=radius
 return super._segment_near(start,finish,point,radius)
func _projectile_near_player(start:Vector2,finish:Vector2,actor:String,radius:float)->bool:
 return network_projectile_near(start,finish,"p:"+actor,positions[actor],radius)

func receive_events(data:Dictionary)->void:
 if str(data.get("match_id",match_id))!=match_id:return
 var current=int(data.get("server_tick",last_snapshot_tick))
 for event in data.get("events",[]):
  if int(event.id)<=applied_seq:continue
  applied_seq=int(event.id)
  # Expired cosmetic effects must not all replay after a long connection stall.
  if current-int(event.get("tick",current))>30:continue
  render_events.append({"tick":int(event.get("tick",current)),"data":event.data})
 while render_events.size()>256:render_events.pop_front()

func _report_network()->void:
 if not OS.has_feature("web") or Time.get_ticks_msec()<report_at:return
 report_at=Time.get_ticks_msec()+1000
 var sample={"build":"T4.8","protocol":PROTOCOL,"fps":Engine.get_frames_per_second(),"rtt_ms":metrics.rtt_ms,"simulation_ms":metrics.tick_ms,"snapshot_ms":server_snapshot_ms,"authority_hz":server_hz,"prediction_queue":history.size(),"state_age_ms":Time.get_ticks_msec()-last_state_at,"buffer_ms":maxf(0,world_view.latest_time-world_view.render_time)*1000,"buffer_holds":world_view.underruns,"wire_bytes":metrics.wire_bytes,"disconnect_reason":disconnect_reason,"clock_resyncs":world_view.clock_resyncs,"max_world_backlog_ms":world_view.max_backlog*1000,"projectile_handoffs":shots_view.handoffs,"projectile_confirmations":shots_view.confirmations,"max_handoff_error_px":shots_view.max_handoff_error,"confirmed_damage_events":confirmed_damage_events,"recent_hit_events":recent_hit_events}
 sample.client_profile=client_perf.summary()
 sample.long_frames_50ms=client_perf.long_frames
 sample.active_fps_cap=Engine.max_fps
 sample.engine_process_ms=Performance.get_monitor(Performance.TIME_PROCESS)*1000
 sample.engine_physics_ms=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000
 sample.draw_calls=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
 sample.primitives=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
 sample.projectiles=render_shots.size();sample.contacts=adventure.combat.feedback.contacts.size();sample.damage_labels=damage_labels.size()
 sample.firing=mobile.attacking if mobile.enabled else Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
 sample.pending_packets=metrics.get("pending_packets",0)
 sample.poll_budget_yields=metrics.get("poll_budget_yields",0)
 sample.server_build=server_build
 sample.gateway_rtt_ms=metrics.get("gateway_rtt_ms",-1)
 sample.snapshot_interarrival_ms=world_view.arrival_age*1000
 sample.target_buffer_ms=world_view.target_delay*1000
 sample.playback_rate=world_view.playback_rate
 sample.arrival_gap_max_ms=world_view.arrival_gaps.max()*1000 if not world_view.arrival_gaps.is_empty() else 0
 sample.ability_view_starts=ability_view.starts
 sample.ability_view_active=ability_view.active
 sample.ability_view_offset_px=local_pos.distance_to(_local_draw_position())
 sample.authoritative_build=network_build(my_id)
 sample.twister_effects=adventure.combat.twister.effects.size()
 sample.position_corrections=metrics.corrections
 sample.max_position_correction_px=metrics.max_correction
 sample.local_view_offset_px=local_pos.distance_to(_local_draw_position())
 sample.walking_actors={}
 for actor in positions:sample.walking_actors[str(actor)]=_actor_walking(str(actor))
 sample.hero=selected_hero;sample.players=positions.size();sample.viewport=[VIEW.x,VIEW.y]
 perf_latest=sample
 JavaScriptBridge.eval("window.fxPerf=window.fxPerf||{version:'T4.8',samples:[]};window.fxPerf.samples.push("+JSON.stringify(sample)+");if(window.fxPerf.samples.length>180)window.fxPerf.samples.shift();",true)
 JavaScriptBridge.eval("if(window.fxDiagnostics)window.fxDiagnostics.sample("+JSON.stringify(sample)+");",true)

func profile_work(kind:String,elapsed:int)->void:
 if not dedicated:client_perf.work(kind,elapsed)
func download_performance()->void:
 if not OS.has_feature("web"):return
 report_downloads+=1
 JavaScriptBridge.eval("(()=>{const r=window.fxPerf||{version:'T4.8',samples:[]};r.graphics=window.fxDiagnostics?window.fxDiagnostics.inspect():{};const a=document.createElement('a');const u=URL.createObjectURL(new Blob([JSON.stringify(r,null,2)],{type:'application/json'}));a.href=u;a.download='FX_T48_performance.json';a.click();setTimeout(()=>URL.revokeObjectURL(u),2000);})()",true)

func _actor_walking(id:String)->bool:
 if id==my_id:return super._actor_walking(id)
 return actor_motion.walking(id)
func local_cosmetic()->Dictionary:
 # Calendar/reward selection is static during this isolated arena test. Avoid
 # repeatedly rebuilding it from the drawing path; refresh twice per second.
 var now=Time.get_ticks_msec()
 if dedicated:return super.local_cosmetic()
 if now>=cosmetic_cache_until or cosmetic_cache.is_empty():
  cosmetic_cache=super.local_cosmetic();cosmetic_cache_until=now+500
 return cosmetic_cache

func _local_draw_position()->Vector2:
 return local_pos if dedicated else ability_view.point(local_view.point(local_pos,Engine.get_physics_interpolation_fraction()))
func _player_draw_position(id:String,fallback:Vector2)->Vector2:
 return _local_draw_position() if id==my_id else super._player_draw_position(id,fallback)
func _refresh_draw_camera()->void:
 var factor=media.factor() if media.game!=null else 1.0
 var framing=media.framing if media.game!=null else Vector2.ZERO
 var size=VIEW/factor
 camera=(_local_draw_position()+framing-size*.5).clamp(Vector2.ZERO,(FIELD.size-size).max(Vector2.ZERO))

func network_twister_view()->Dictionary:
 var twister=adventure.combat.twister
 var live={"effects":twister.effects,"charges":twister.charges,"links":twister.links,"clock":twister.clock}
 if dedicated:return live
 return preload("res://network/twister_view.gd").sample(world_view,my_id,live)

func network_build(owner:String)->Dictionary:
 var empty={"technique":false,"final_technique":false,"crit_tier":0,"tuning":[0,0,0],"points":0}
 return legacy.builds.get(owner,empty) if dedicated else authority_builds.get(owner,empty)

func network_effect_records(module:String,collection:String,live:Array)->Array:
 if dedicated or not net_ready:return live
 var policy=preload("res://network/effect_anchors.gd")
 var result:Array=[]
 for record in live:
  var kind=str(record.get("kind",record.get("style","")))
  if not policy.attached(module,kind):result.append(record);continue
  if str(record.get("owner",""))==my_id:
   var copy=_aged_draw_record(record,minf(.1,maxf(0,(Time.get_ticks_msec()-last_state_at)/1000.0)))
   if not copy.is_empty():result.append(copy)
 var buffered:Dictionary=world_view.data().get("adventure",{}).get("combat",{}).get(module,{})
 for record in buffered.get(collection,[]):
  var kind=str(record.get("kind",record.get("style","")))
  if str(record.get("owner",""))==my_id or not policy.attached(module,kind):continue
  var copy=_aged_draw_record(record,_render_sample_age())
  if not copy.is_empty():result.append(copy)
 return result
func _aged_draw_record(record:Dictionary,elapsed:float)->Dictionary:
 if record.has("time") and float(record.time)<=elapsed:return {}
 var copy=record.duplicate(true)
 if copy.has("time"):copy.time=float(copy.time)-elapsed
 for key in ["age","elapsed"]:
  if copy.has(key):copy[key]=float(copy[key])+elapsed
 return copy
