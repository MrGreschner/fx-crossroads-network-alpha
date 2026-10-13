extends "res://scripts/arcade.gd"
## Arena vertical slice: original combat, dedicated authority, independent rendering.
const PROTOCOL=1
const Move=preload("res://network/movement.gd")
var net_dash:Dictionary={}
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
var server_inputs:Dictionary={}
var server_actions:Dictionary={}
var input_ack:Dictionary={}
var projectile_serial=0
var action_serial=0
var server_snapshot_tick=0
var last_snapshot_tick=-1
var metrics={"rtt_ms":0,"corrections":0,"max_correction":0.0,"snapshots":0,"wire_bytes":0,"stale":0,"tick_ms":0.0}
func _ready()->void:
 dedicated=get_tree().root.has_meta("fx_dedicated_server")
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
 var title=Label.new();title.text="FX CONNECTIONS • DEDICATED ARENA ALPHA";box.add_child(title)
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
 net_peer=WebSocketPeer.new();net_peer.inbound_buffer_size=1048576;net_peer.outbound_buffer_size=65536;net_peer.max_queued_packets=64
 if url_field.text.strip_edges().is_empty():url_field.text=DEFAULT_SERVER
 var error=net_peer.connect_to_url(url_field.text.strip_edges())
 if error!=OK:net_status.text="Cannot connect: "+error_string(error);return
 if kind=="resume":started=false
 set_meta("joining",kind);net_status.text="Connecting…"
func send_net(data:Dictionary)->void:
 if net_peer==null or net_peer.get_ready_state()!=WebSocketPeer.STATE_OPEN:return
 if net_peer.get_current_outbound_buffered_amount()>32768:
  net_status.text="Network queue full; movement stopped. Reconnecting…";net_peer.close();return
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
   next_ping_at=Time.get_ticks_msec()+2000;send_net({"type":"ping","sent":Time.get_ticks_msec()})
  var latest={};var budget=32
  while net_peer.get_available_packet_count()>0 and budget>0:
   budget-=1;var bytes=net_peer.get_packet();metrics.wire_bytes+=bytes.size()
   if not net_peer.was_string_packet():bytes=bytes.decompress_dynamic(2097152,FileAccess.COMPRESSION_GZIP)
   var message=JSON.parse_string(bytes.get_string_from_utf8())
   if not message is Dictionary:continue
   if str(message.get("type",""))=="state":latest=message
   else:receive_net(message)
  if not latest.is_empty():receive_net(latest)
 elif net_peer.get_ready_state()==WebSocketPeer.STATE_CLOSED:
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
   positions.clear()
   for id in hero_ids:positions[id]=Vector2.ZERO
   sequence=0;history.clear();frames.clear();last_snapshot_tick=-1;applied_seq=0;pending_correction=Vector2.ZERO
   _start_match();start_countdown=0;control.hide();net_panel.hide();shots_view.tracks.clear();shots_view.predicted.clear();local_strikes.clear();predicted_actions.clear();pending_bursts.clear()
  "state":
   var tick=int(data.get("server_tick",0))
   if tick<=last_snapshot_tick:metrics.stale+=1;return
   last_snapshot_tick=tick;metrics.snapshots+=1;metrics.tick_ms=float(data.get("tick_ms",0))
   var events:Array=data.get("events",[])
   for event in events:
    if int(event.id)>applied_seq:_receive_effect(event.data);applied_seq=int(event.id)
   var own:Dictionary=data.get("players",{}).get(my_id,{})
   var dash:Array=own.get("dash",[0,0,0])
   net_dash[my_id]={"time":float(dash[0]),"direction":Vector2(float(dash[1]),float(dash[2]))}
   data.effects=[];super._packet("server",data)
   shots_view.local_owner=my_id;shots_view.latency=float(metrics.rtt_ms)/1000.0
   var shots:Array=data.get("shots",[]).duplicate()
   for shot in adventure.combat.projectiles:
    if not shot.has("net_id"):continue
    var aim:Vector2=adventure.combat.vec(shot.aim)*float(shot.speed)
    shots.append({"net_id":shot.net_id,"pos":shot.pos,"velocity":[aim.x,aim.y],"owner":shot.owner,"color":shot.color,"action_seq":shot.get("action_seq",-1),"shot_index":shot.get("shot_index",0),"custom":true})
   shots_view.receive(shots,Time.get_ticks_msec()/1000.0)
  "action_ack":
   if not bool(data.accepted):
    var rejected=int(data.seq);shots_view.reject(rejected)
    local_strikes=local_strikes.filter(func(x):return int(x.action_seq)!=rejected)
    pending_bursts=pending_bursts.filter(func(x):return int(x.seq)!=rejected)
   if data.has("style"):request_ready[str(data.style)]=Time.get_ticks_msec()+maxi(80,int(data.get("remaining",0))-int(metrics.rtt_ms))
  "pong":metrics.rtt_ms=Time.get_ticks_msec()-int(data.sent)
func _process(delta:float)->void:
 if dedicated:return
 VIEW=get_viewport_rect().size;poll_net();control.hide();mobile.visible=started
 if not started and is_instance_valid(net_panel):net_panel.visible=not is_instance_valid(hero_grid)
 if is_instance_valid(net_panel):net_panel.size=Vector2(minf(850,VIEW.x-24),minf(590,VIEW.y-24));net_panel.position=(VIEW-net_panel.size)*.5
 if not started:queue_redraw();return
 visual_time+=delta;motion_v85.advance(delta);skating_motion.advance(delta)
 _advance_local_previews(delta)
 for actor in positions:
  if actor!=my_id:remote_draw_pos[actor]=smoothing.sample("p:"+str(actor),positions[actor],Time.get_ticks_msec()/1000.0,.075)
  var ground=local_pos if actor==my_id else remote_draw_pos.get(actor,positions[actor])
  motion_v85.sample(str(actor),str(hero_ids.get(actor,"ram")),ground,true)
  skating_motion.sample(str(actor),ground,delta,true);wing_motion.step(str(actor),ground,delta,true);basketball_motion.step(str(actor),ground,delta,true);fish_motion.step(str(actor),ground,delta,true)
 missiles.assign(shots_view.samples(Time.get_ticks_msec()/1000.0))
 adventure.combat.held_cast.local_input(delta,net_ready and presentation.page.is_empty())
 if net_ready and presentation.page.is_empty():
  if (mobile.attacking if mobile.enabled else Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):_attack_request("primary")
  if Input.is_action_pressed("secondary"):_attack_request("secondary")
  if Input.is_action_just_pressed("special"):_attack_request("special")
 media.refresh_arcade() if media.game!=null else assign_base_camera()
 for n in range(effects.size()-1,-1,-1):
  effects[n].time-=delta
  if effects[n].time<=0:effects.remove_at(n)
 for n in range(damage_labels.size()-1,-1,-1):
  damage_labels[n].time-=delta;damage_labels[n].pos+=Vector2(0,-35)*delta
  if damage_labels[n].time<=0:damage_labels.remove_at(n)
 queue_redraw()
func _physics_process(_delta:float)->void:
 if dedicated:
  if not started:return
  var begin=Time.get_ticks_usec();authority_tick+=1
  for id in positions:
   var queue:Array=server_inputs.get(id,[])
   if not queue.is_empty():
    var f:Dictionary=queue.pop_front();input_ack[id]=int(f.seq)
    var direction=Vector2(float(f.d[0]),float(f.d[1]))
    positions[id]=Move.advance(self,str(id),positions[id],direction)
    var aim=Vector2.from_angle(float(f.a));aim_angles[id]=float(f.a)
    adventure.combat.release_heroes.holding(str(id),bool(f.sh),aim);adventure.combat.classics.holding(str(id),bool(f.sh));adventure.combat.v79.holding(str(id),bool(f.sh),aim);adventure.combat.v56.holding(str(id),bool(f.ph),aim)
   var actions:Array=server_actions.get(id,[])
   while not actions.is_empty() and int(actions[0].get("input_seq",0))<=int(input_ack.get(id,0)):
    gateway.execute_action(self,str(id),actions.pop_front())
  run_time+=Move.DT;visual_time+=Move.DT;arena_world.step(Move.DT);adventure.step(Move.DT);_update_flames(Move.DT);_simulate_charges(Move.DT);_simulate(Move.DT)
  for bullet in missiles:
   if not bullet.has("net_id"):projectile_serial+=1;bullet.net_id=projectile_serial
  metrics.tick_ms=(Time.get_ticks_usec()-begin)/1000.0
  if authority_tick%3==0:gateway.snapshot(self)
  return
 if not started or not net_ready:return
 var direction:Vector2=mobile.movement if mobile.enabled else Input.get_vector("move_left","move_right","move_up","move_down")
 if not presentation.page.is_empty():direction=Vector2.ZERO
 var aim:Vector2=mobile.aim if mobile.enabled else (media_mouse_world()-local_pos).normalized()
 if Input.is_action_just_pressed("dodge") and Move.movable(self,my_id) and Time.get_ticks_msec()>=int(dodge_at.get(my_id,0)):
  var dash_direction=direction.normalized() if not direction.is_zero_approx() else aim
  net_dash[my_id]={"time":.26,"direction":dash_direction};dodge_at[my_id]=Time.get_ticks_msec()+2500
  _send_channel(host_id,{"type":"dodge","direction":[dash_direction.x,dash_direction.y]})
 sequence+=1
 var frame={"seq":sequence,"d":[snappedf(direction.x,.001),snappedf(direction.y,.001)],"a":aim.angle(),"ph":mobile.attacking if mobile.enabled else Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT),"sh":Input.is_action_pressed("secondary")}
 frames.append(frame);history.append(frame)
 if history.size()>180:net_peer.close();history.clear();frames.clear();return
 local_pos=Move.advance(self,my_id,local_pos,direction)
 if pending_correction.length_squared()>0:
  var repair=pending_correction*.25;local_pos+=repair;pending_correction-=repair
  if pending_correction.length()<.1:pending_correction=Vector2.ZERO
 positions[my_id]=local_pos
 if sequence%2==0:
  send_net({"type":"input","match_id":match_id,"frames":frames,"event_ack":applied_seq});frames=[]

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
 if error.length()>80:local_pos=repaired;pending_correction=Vector2.ZERO
 else:pending_correction=error if error.length()>.75 else Vector2.ZERO
 positions[my_id]=local_pos
func _send_channel(_id:String,data:Dictionary)->void:
 if dedicated:
  if gateway!=null:gateway.send_actor(_id,data)
  return
 action_serial+=1;var packet=data.duplicate(true);packet.seq=action_serial;packet.input_seq=sequence;packet.match_id=match_id
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
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE and started:
  if session_menu.page.is_empty():session_menu.main()
  else:session_menu.resume()
func _draw()->void:
 super._draw()
 if dedicated or not started:return
 draw_set_transform(media.offset(),0,Vector2.ONE*media.factor())
 for shot in shots_view.predicted:
  var now=Time.get_ticks_msec()/1000.0
  if now<float(shot.t):continue
  var p=shots_view.preview_position(shot,now)-camera
  if _clear_path(shot.p,p+camera):draw_circle(p,float(shot.radius),Color(str(shot.color)))
 draw_set_transform(Vector2.ZERO)
 draw_string(preload("res://assets/fonts/CrossroadsUI.ttf"),Vector2(24,VIEW.y-40),"NETWORK ALPHA • RTT %d ms • server %.2f ms/tick • queue %d" % [metrics.rtt_ms,metrics.tick_ms,history.size()],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#a8ddf0"))

func _effect_at_actor(effect:Dictionary)->Dictionary:
 var owner=str(effect.get("owner",""))
 if owner.is_empty() or not positions.has(owner) or str(effect.get("style","")) not in ["melee","punch","scratch","slash","kick"]:return effect
 var anchored=effect.duplicate()
 anchored.pos=local_pos if owner==my_id else remote_draw_pos.get(owner,positions[owner])
 return anchored
func _draw_effect(effect:Dictionary)->void:
 super._draw_effect(_effect_at_actor(effect))

func melee_visual_position(owner:String,fallback:Vector2)->Vector2:
 if not positions.has(owner):return fallback
 if dedicated:return positions[owner]
 return local_pos if owner==my_id else remote_draw_pos.get(owner,positions[owner])

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
   shots_view.preview(my_id,seq,local_pos+direction*24,direction*float(stats.get("speed",420)),str(stats.get("color","#ffd985")),now,n,float(stats.get("range",480)),float(stats.get("projectile_radius",7)))
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
  shots_view.preview(my_id,int(burst.seq),local_pos+direction*26,direction*float(stats.get("speed",480)),str(stats.get("color","#b5dc79")),now,int(burst.index),float(stats.get("range",360)),float(stats.get("projectile_radius",12)))
  pending_bursts.remove_at(n)
func predicted_identity_strikes()->Array:return local_strikes
func suppress_confirmed_strike(entry:Dictionary)->bool:return str(entry.owner)==my_id and predicted_actions.has(int(entry.get("action_seq",-1)))
func object_projectile_display(shot:Dictionary,fallback:Vector2)->Vector2:
 var key=str(shot.get("net_id",0))
 return shots_view.point(shots_view.tracks[key],Time.get_ticks_msec()/1000.0) if shots_view.tracks.has(key) else fallback
