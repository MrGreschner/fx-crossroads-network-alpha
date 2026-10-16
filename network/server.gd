extends Node
## One process owns several bounded private Arena matches. No client runs authority.
const Arena=preload("res://network/arena.gd")
const MAX_ROOMS=4
const PROTOCOL=3
const INPUT_BACKLOG=18
const SOCKET_BACKLOG=32768
const MAX_CONNECTIONS=64
var listener=TCPServer.new()
var peers:Dictionary={}
var rooms:Dictionary={}
var identities:Dictionary={}
var actor_counter=0
var packets=0
var snapshots=0
var max_tick_ms=0.0
var metric_at=0
var disconnects:Dictionary={}
var dropped_inputs=0
var coalesced_snapshots=0
var snapshot_ms=0.0
var encode_ms=0.0
var snapshot_bytes=0
var simulation_steps=0
var epoch_steps=0
var epoch_time=0
var actual_hz=60.0
var admission_busy=false
var process_ms=0.0
var step_work_ms=0.0
var step_work_max_ms=0.0
var work_window=0.0
var snapshot_serial=0
var metrics_window=0
var active_ms=0.0
var previous_active=0
var last_poll_ms=0
func _ready()->void:
 get_tree().root.set_meta("fx_dedicated_server",true);get_tree().root.set_meta("fx_dev_match",true)
 Engine.physics_ticks_per_second=60
 Engine.max_fps=60 # Bound headless socket polling; do not busy-spin on shared CPU.
 var port=int(OS.get_environment("FX_GAME_PORT")) if not OS.get_environment("FX_GAME_PORT").is_empty() else 9081
 var error=listener.listen(port,"127.0.0.1" if OS.get_environment("FX_PROXY")!="" else "*")
 if error!=OK:push_error("Server listen failed: "+error_string(error));get_tree().quit(1);return
 epoch_time=Time.get_ticks_msec();metrics_window=epoch_time
 print("FX authority listening on ",port,"; protocol 3; simulation 60Hz; snapshots 20Hz")
func _process(_delta:float)->void:
 var poll_start=Time.get_ticks_usec()
 var now=Time.get_ticks_msec()
 if last_poll_ms>0:active_ms+=(now-last_poll_ms)*previous_active
 last_poll_ms=now
 if now>=metric_at:
  var elapsed=maxi(1,now-epoch_time)
  var active=rooms.values().filter(func(room):return room.game.started and not room.game.room_paused).size()
  actual_hz=(simulation_steps-epoch_steps)*1000.0/maxf(1,active_ms) if active_ms>0 else 60.0
  admission_busy=active>0 and actual_hz<52.0 and elapsed>=4000
  epoch_time=now;epoch_steps=simulation_steps;metric_at=now+5000;active_ms=0
  print("FX_METRICS "+JSON.stringify({"rooms":rooms.size(),"active_rooms":active,"connections":peers.size(),"packets":packets,"snapshots":snapshots,"max_tick_ms":max_tick_ms,"snapshot_ms":snapshot_ms,"encode_ms":encode_ms,"snapshot_bytes":snapshot_bytes,"actual_hz":snappedf(actual_hz,.1),"work_ms_per_second":snappedf(work_window*1000.0/maxi(1,now-metrics_window),.1),"step_work_max_ms":step_work_max_ms,"input_backlog_max":backlog_max(),"dropped_input_frames":dropped_inputs,"coalesced_snapshots":coalesced_snapshots,"disconnects":disconnects,"admission_busy":admission_busy,"memory_bytes":OS.get_static_memory_usage()}))
  work_window=0;metrics_window=now

 for n in 8:
  if not listener.is_connection_available():break
  var stream=listener.take_connection()
  if peers.size()>=MAX_CONNECTIONS:stream.disconnect_from_host();continue
  var peer=WebSocketPeer.new();peer.inbound_buffer_size=32768;peer.outbound_buffer_size=1048576;peer.max_queued_packets=256;peer.heartbeat_interval=5.0
  if peer.accept_stream(stream)!=OK:stream.disconnect_from_host();continue
  actor_counter+=1;peers[actor_counter]={"ws":peer,"actor":"","seen":now,"born":now,"budget":120.0,"tick":now}
 for key in peers.keys():
  var connection:Dictionary=peers[key];var peer:WebSocketPeer=connection.ws;peer.poll()
  if peer.get_ready_state()==WebSocketPeer.STATE_CLOSED or (connection.actor.is_empty() and now-int(connection.born)>30000) or now-int(connection.seen)>30000:
   drop_connection(key,"idle_timeout" if now-int(connection.seen)>30000 else "handshake_timeout" if connection.actor.is_empty() else "socket_closed");continue
  connection.budget=minf(120,float(connection.budget)+(now-int(connection.tick))*.12);connection.tick=now
  var count=0
  while peer.get_available_packet_count()>0 and count<32:
   count+=1;var bytes=peer.get_packet()
   if bytes.size()>16384 or connection.budget<1:peer.close(1008,"Packet limit");break
   connection.budget-=1;connection.seen=now;packets+=1
   var data=JSON.parse_string(bytes.get_string_from_utf8())
   if data is Dictionary:receive(key,data)
 for code in rooms.keys():
  var room:Dictionary=rooms[code];var g:Node=room.game
  max_tick_ms=maxf(max_tick_ms,float(g.metrics.tick_ms))
  expire_members(code,room,now)

 previous_active=rooms.values().filter(func(room):return room.game.started and not room.game.room_paused).size()
 process_ms=(Time.get_ticks_usec()-poll_start)/1000.0
 work_window+=process_ms
func expire_members(code:String,room:Dictionary,now:int)->void:
 var g:Node=room.game
 for id in room.members.keys():
  if not identities.has(id):continue
  if int(identities[id].connection)<0 and now-int(identities[id].left)>60000:
   remove_actor(g,id);room.members.erase(id);identities.erase(id)
   if room.host==id:room.host=str(room.members.keys()[0]) if not room.members.is_empty() else ""
   if not room.members.is_empty():lobby(code)
 if room.members.is_empty():g.queue_free();rooms.erase(code)
func _physics_process(delta:float)->void:
 # Dedicated games bypass Arcade._process, including its temporary-wall timer.
 # Expire on the authority's physics clock before the rooms move and snapshot.
 for room in rooms.values():expire_walls(room.game,delta)
func expire_walls(game:Node,delta:float)->void:
 if not game.started or game.room_paused:return
 for index in range(game.ice_walls.size()-1,-1,-1):
  game.ice_walls[index].time=maxf(0,float(game.ice_walls[index].time)-maxf(0,delta))
  if float(game.ice_walls[index].time)<=.00001:game.ice_walls.remove_at(index)
func backlog_max()->int:
 var value=0
 for room in rooms.values():
  for queue in room.game.server_inputs.values():value=maxi(value,queue.size())
 return value
func remove_actor(g:Node,id:String)->void:
 # Remove expired actors from every per-player map; no retained combat identities.
 for field in ["positions","health","hero_ids","server_inputs","server_actions","server_input_credit","input_ack","net_dash","net_velocity","pvp_scores","contributions","arena_records","arena_outcomes","teams","cooldown_at","inventory","levels","gold","kills","xp","invincible_until","shield_until","haste_until","stealth_until","respawn_at","dodge_at","aim_angles","attack_pose_until","defeat_causes","food_registered","food_slots","food_loadouts","attack_branch","mastery_choice"]:
  var value=g.get(field)
  if value is Dictionary:value.erase(id)
func drop_connection(key:int,reason:String="socket_closed")->void:
 if not peers.has(key):return
 disconnects[reason]=int(disconnects.get(reason,0))+1
 print("FX_DISCONNECT "+JSON.stringify({"connection":key,"reason":reason,"actor":peers[key].actor,"socket_code":peers[key].ws.get_close_code(),"outbound_bytes":peers[key].ws.get_current_outbound_buffered_amount()}))
 var entry:Dictionary=peers[key];var id=str(entry.actor)
 if identities.has(id):
  identities[id].connection=-1;identities[id].left=Time.get_ticks_msec()
  var code=str(identities[id].room)
  if rooms.has(code):
   var g:Node=rooms[code].game;g.server_inputs[id]=[];g.server_actions[id]=[]
   g.room_paused=rooms[code].members.keys().all(func(member):return int(identities[member].connection)<0)
   g.adventure.combat.held_cast.packet(id,{"phase":"cancel"})
   g.adventure.combat.release_heroes.holding(id,false,Vector2.RIGHT);g.adventure.combat.classics.holding(id,false);g.adventure.combat.v79.holding(id,false,Vector2.RIGHT);g.adventure.combat.v56.holding(id,false,Vector2.RIGHT)
 entry.ws.close();peers.erase(key)
func send(key:int,data:Dictionary)->void:
 if not peers.has(key):return
 var ws:WebSocketPeer=peers[key].ws
 if ws.get_ready_state()!=WebSocketPeer.STATE_OPEN:return
 if ws.get_current_outbound_buffered_amount()>262144:
  ws.close(1013,"Connection stalled for too long");return
 var error=ws.send_text(JSON.stringify(data))
 if error!=OK:print("FX_SEND_ERROR ",error_string(error))
func send_snapshot(key:int,bytes:PackedByteArray)->void:
 if not peers.has(key):return
 var ws:WebSocketPeer=peers[key].ws
 if ws.get_ready_state()!=WebSocketPeer.STATE_OPEN:return
 # A stale state is replaceable. Do not disconnect a player for one burst.
 if ws.get_current_outbound_buffered_amount()>SOCKET_BACKLOG:
  coalesced_snapshots+=1;return
 var error=ws.put_packet(bytes)
 if error!=OK:coalesced_snapshots+=1

func fail(key:int,text:String)->void:send(key,{"type":"error","message":text})
func send_actor(id:String,data:Dictionary)->void:
 if identities.has(id):send(int(identities[id].connection),data)
func receive(key:int,data:Dictionary)->void:
 if not peers.has(key):return
 var kind=str(data.get("type",""));var connection:Dictionary=peers[key]
 if connection.actor.is_empty():
  if kind not in ["host","join","resume"]:return
  if int(data.get("protocol",0))!=PROTOCOL:fail(key,"Server requires the T4 alpha. Refresh the updated itch.io build.");return
  join(key,data);return
 var id=str(connection.actor);var identity:Dictionary=identities[id];var room:Dictionary=rooms[identity.room];var g:Node=room.game
 if kind=="leave":
  room.members.erase(id);remove_actor(g,id)
  if room.host==id:room.host=str(room.members.keys()[0]) if not room.members.is_empty() else ""
  identities.erase(id);drop_connection(key,"leave")
  if not room.members.is_empty():lobby(str(identity.room))
  return
 if kind=="ping":send(key,{"type":"pong","sent":int(data.get("sent",0))});return
 if kind=="arena_choice":
  if room.host!=id or g.started:return
  var chosen=str(data.get("arena_map",""))
  if chosen not in ["sand","crossroads"]:return
  g.arena_map=chosen;g._sync_arena_pickers();lobby(str(identity.room));return
 if kind=="capacity":
  if room.host!=id:fail(key,"Only the host can change room capacity.");return
  if g.started:fail(key,"Capacity can be changed before the match starts.");return
  var seats=int(data.get("seats",0))
  if seats not in [2,4,8]:fail(key,"Choose 2, 4 or 8 seats.");return
  if seats<room.members.size():
   fail(key,"Cannot reduce capacity below the players already in this room.");lobby(str(identity.room));return
  room.seats=seats;g.arena_seats=seats;lobby(str(identity.room));return
 if kind=="start":
  if room.host!=id or g.started:return
  if room.members.size()<2:fail(key,"At least two connected players are needed.");return
  for member in room.members:
   if int(identities[member].connection)<0:fail(key,"Wait for disconnected players to reconnect.");return
  g.roster.assign(room.members.values());g.positions.clear()
  for member in room.members:
   g._add_player(str(member),g.positions.size());g.lobby_heroes[member]=room.members[member].hero
  g.spectator_host=true;g.bot_count=0;g.no_items_picker.button_pressed=true
  g._start_match();g.start_countdown=0;
  if g.arena_map=="crossroads":g.arena_world.test_enemies()
  g.server_inputs.clear();g.server_input_credit.clear();g.server_actions.clear();g.input_ack.clear();g.net_dash.clear();g.authority_tick=0;g.position_samples.clear();g.max_input_depth=0
  room.events=[];room.event_seq=0
  for member in room.members:g.server_inputs[member]=[];g.server_actions[member]=[];g.input_ack[member]=0;identities[member].last_seq=0;identities[member].action_seq=0;identities[member].event_ack=0;identities[member].event_sent=0
  broadcast_game(g,start_packet(g));snapshot(g);return
 if kind=="hero":
  if g.started:return
  var hero=str(data.get("hero",""))
  if valid_hero(g,hero):room.members[id].hero=hero;lobby(identity.room)
  return
 if not g.started or str(data.get("match_id",""))!=g.match_id:return
 if kind=="input_reset":
  var seq=int(data.get("seq",0))
  if seq<int(identity.last_seq) or seq>int(identity.last_seq)+3600:return
  identity.last_seq=seq;g.input_ack[id]=seq;g.server_inputs[id]=[];g.server_input_credit[id]=0
  send_state_snapshot(g);return
 if kind=="input":
  var batch=data.get("frames",[])
  if not batch is Array or batch.size()>8:return
  for raw in batch:
   if not valid_frame(raw):fail(key,"Invalid movement frame");return
   var seq=int(raw.seq)
   if seq<=int(identity.last_seq):continue
   if seq!=int(identity.last_seq)+1:
    # Reliable ordered transport: a gap needs an explicit bounded resync, never a reconnect storm.
    send(key,{"type":"input_resync","expected":int(identity.last_seq)+1,"match_id":g.match_id});return
   identity.last_seq=seq;g.server_inputs[id].append(raw)
  var queue:Array=g.server_inputs.get(id,[])
  if queue.size()>INPUT_BACKLOG:
   var discard=queue.size()-INPUT_BACKLOG
   # Acknowledge discarded prediction frames: authoritative position remains unchanged.
   g.input_ack[id]=maxi(int(g.input_ack.get(id,0)),int(queue[discard-1].seq))
   dropped_inputs+=discard;queue=queue.slice(discard);g.server_inputs[id]=queue
  g.max_input_depth=maxi(g.max_input_depth,queue.size())
  identity.event_ack=maxi(int(identity.get("event_ack",0)),mini(int(room.event_seq),int(data.get("event_ack",0))))
 elif kind in ["attack","held_cast","dodge","consume"]:
  if g.server_actions.get(id,[]).size()>=32:return
  var serial=int(data.get("seq",0))
  if serial<=int(identity.get("action_seq",0)):return
  if not valid_action(data):return
  identity.action_seq=serial
  data["received_ms"]=Time.get_ticks_msec()
  data["view_tick"]=clampi(int(data.get("view_tick",g.authority_tick)),maxi(0,g.authority_tick-12),g.authority_tick)
  g.server_actions[id].append(data)
func valid_frame(value)->bool:
 if not value is Dictionary:return false
 var d=value.get("d",[])
 return d is Array and d.size()==2 and int(value.get("seq",0))>0 and finite_number(d[0]) and finite_number(d[1]) and absf(float(d[0]))<=1 and absf(float(d[1]))<=1 and finite_number(value.get("a",null)) and value.get("ph") is bool and value.get("sh") is bool
func finite_number(v)->bool:return (v is float or v is int) and is_finite(float(v))
func valid_action(data:Dictionary)->bool:
 var kind=str(data.get("type",""))
 if kind=="held_cast" and str(data.get("phase",""))=="cancel":return true
 if kind in ["attack","held_cast"]:
  if not finite_number(data.get("angle",null)):return false
  var p=data.get("target",[])
  if not p is Array or p.size()!=2 or not finite_number(p[0]) or not finite_number(p[1]):return false
  if Vector2(float(p[0]),float(p[1])).length()>25000:return false
  if kind=="attack" and str(data.get("style","")) not in ["primary","secondary","special"]:return false
  if kind=="held_cast" and str(data.get("phase","")) not in ["begin","aim","release","cancel"]:return false
 if kind=="dodge":
  var d=data.get("direction",[])
  if not d is Array or d.size()!=2 or not finite_number(d[0]) or not finite_number(d[1]):return false
 return int(data.get("input_seq",-1))>=0
func valid_hero(g:Node,id:String)->bool:return g.characters.has(id) and not id.begins_with("custom_") and not bool(g.characters[id].get("npc_only",false))
func join(key:int,data:Dictionary)->void:
 var kind=str(data.type);var code=str(data.get("room","")).to_upper();var id=""
 if kind=="resume":
  if not rooms.has(code):fail(key,"Room expired.");return
  for member in rooms[code].members:
   if str(identities[member].token)==str(data.get("token","")) and not str(data.get("token","")).is_empty():id=member;break
  if id.is_empty():fail(key,"Resume token rejected.");return
  var old=int(identities[id].connection)
  if old>=0 and peers.has(old):drop_connection(old)
 else:
  if kind=="host":
   if admission_busy:fail(key,"Server is at its measured playtest capacity. Existing matches take priority.");return
   if rooms.size()>=MAX_ROOMS:fail(key,"Test server room capacity reached.");return
   code=Crypto.new().generate_random_bytes(4).hex_encode().left(6).to_upper()
   var g=Arena.new();g.gateway=self;add_child(g)
   var seats=clampi(int(data.get("seats",2)),2,8);g.arena_seats=seats
   g.arena_map="crossroads" if str(data.get("arena_map","sand"))=="crossroads" else "sand";g._sync_arena_pickers()
   rooms[code]={"game":g,"members":{},"host":"","seats":seats,"events":[],"event_seq":0}
  if not rooms.has(code):fail(key,"Room not found.");return
  var room:Dictionary=rooms[code]
  if room.game.started:fail(key,"Match already started. Reconnect using your existing seat.");return
  if room.members.size()>=int(room.seats):fail(key,"Room full; disconnected seats are reserved for 60 seconds.");return
  var hero=str(data.get("hero","ram"))
  if not valid_hero(room.game,hero):fail(key,"Choose an official hero.");return
  id=Crypto.new().generate_random_bytes(8).hex_encode()
  identities[id]={"room":code,"token":Crypto.new().generate_random_bytes(24).hex_encode(),"connection":key,"left":0,"last_seq":0,"action_seq":0,"event_ack":0,"event_sent":0}
  room.members[id]={"id":id,"name":str(data.get("name","Tester")).left(24),"hero":hero}
  if room.host.is_empty():room.host=id
 peers[key].actor=id;identities[id].connection=key;identities[id].event_sent=int(identities[id].get("event_ack",0));rooms[code].game.room_paused=false
 send(key,{"type":"welcome","protocol":PROTOCOL,"build":"T4.13","id":id,"room":code,"token":identities[id].token,"host":rooms[code].host==id})
 if rooms[code].game.started:
  var g:Node=rooms[code].game;g.server_inputs[id]=[];g.server_actions[id]=[]
  send(key,start_packet(g));send_state(key,g,id)
 else:lobby(code)
func lobby(code:String)->void:
 var room:Dictionary=rooms[code]
 for id in room.members:send_actor(id,{"type":"lobby","host":room.host,"seats":room.seats,"arena_map":room.game.arena_map,"members":room.members.values()})
func room_for(g:Node)->Dictionary:
 for room in rooms.values():
  if room.game==g:return room
 return {}
func start_packet(g:Node)->Dictionary:return {"type":"start","match_id":g.match_id,"seed":g.floor_seed,"arena_map":g.arena_map,"seats":g.arena_seats,"heroes":g.hero_ids}
func broadcast_game(g:Node,data:Dictionary)->void:
 var room=room_for(g)
 for id in room.get("members",{}):send_actor(str(id),data)
func execute_action(g:Node,id:String,data:Dictionary)->void:
 var began=Time.get_ticks_msec()
 var custom_before=g.adventure.combat.projectiles.size()
 var born:Array=[]
 var before=g.missiles.size();var style=str(data.get("style","primary"));var previous=int(g.cooldown_at.get(id,{}).get(style,0))
 var dodge_before=int(g.dodge_at.get(id,0))
 g.set_meta("fx_action_seq",int(data.seq));g.set_meta("fx_shot_index",0)
 # Rewind targets for ordinary instant melee only. Projectile simulation stays in the present.
 var restore=g.rewind_melee_targets(id,data)
 g._packet(id,data)
 g.restore_targets(restore);g.remove_meta("fx_action_seq")
 if str(data.type)=="dodge" and int(g.dodge_at.get(id,0))>dodge_before:
  var d=data.get("direction",[1,0]);g.net_dash[id]={"time":.26,"direction":Vector2(float(d[0]),float(d[1])).normalized()}
 for n in range(before,g.missiles.size()):
  var shot:Dictionary=g.missiles[n];shot.action_seq=int(data.seq);shot.shot_index=n-before
  if not shot.has("net_id"):g.projectile_serial+=1;shot.net_id=g.projectile_serial;shot.born_tick=g.authority_tick-1
  born.append(int(shot.shot_index))
 for n in range(custom_before,g.adventure.combat.projectiles.size()):
  var shot:Dictionary=g.adventure.combat.projectiles[n]
  if str(shot.get("owner",""))==id:born.append(int(shot.get("shot_index",0)))
 var after=int(g.cooldown_at.get(id,{}).get(style,0))
 var accepted=after>previous or str(data.type)!="attack"
 send_actor(id,{"type":"action_ack","seq":int(data.seq),"style":style,"accepted":accepted,"born_indices":born,"tick":g.authority_tick,"reason":"" if accepted else "cooldown_or_state","remaining":maxi(0,after-began),"wait_ms":maxi(0,began-int(data.get("received_ms",began)))})
func prune_idle(value:Variant)->Variant:
 # Preserve all active hero mechanics, while omitting dormant component containers.
 if value is Array:return value
 if not value is Dictionary:return value
 var result={}
 for key in value:
  var item=prune_idle(value[key])
  if (item is Array or item is Dictionary) and item.is_empty():continue
  result[key]=item
 if result.size()==1 and result.has("clock"):return {}
 return result
func snapshot(g:Node)->void:
 var room=room_for(g)
 if room.is_empty():return
 for effect in g.sent_effects:
  room.event_seq+=1;room.events.append({"id":room.event_seq,"tick":g.authority_tick,"data":effect})
 g.sent_effects.clear()
 # Keep events until acknowledged, bounded against absent or malicious clients.
 while room.events.size()>256:room.events.pop_front()
 var began=Time.get_ticks_usec()
 var state=g._snapshot()
 # Arena-only envelope; hero combat state remains complete for all official heroes.
 for field in ["studio","dev_magic","descent","battlegrounds","north_gate","defense_cleared_wave","wave","floor","gate","upgrades"]:state.erase(field)
 state.adventure=prune_idle(state.adventure)
 state.server_tick=g.authority_tick;state.tick_ms=g.metrics.tick_ms;state.effects=[]
 state.snapshot_seq=room.get("snapshot_seq",0)+1;room.snapshot_seq=state.snapshot_seq
 state.input_backlog=g.max_input_depth;state.actual_hz=actual_hz;state.snapshot_ms=float(g.metrics.get("snapshot_ms",0))
 state.shots=[]
 for shot in g.missiles:
  var v:Vector2=shot.get("dir",shot.get("direction",Vector2.ZERO))*float(shot.get("speed",0))
  state.shots.append({"net_id":int(shot.get("net_id",0)),"pos":[snappedf(shot.pos.x,.1),snappedf(shot.pos.y,.1)],"velocity":[snappedf(v.x,.1),snappedf(v.y,.1)],"owner":str(shot.owner),"color":str(shot.get("color","#ffd985")),"action_seq":int(shot.get("action_seq",-1)),"shot_index":int(shot.get("shot_index",0)),"born":float(shot.get("born_tick",g.authority_tick))/60.0})
 for id in state.players:
  var precise:Vector2=g.positions[id];state.players[id].pos=[snappedf(precise.x,.001),snappedf(precise.y,.001)]
  var velocity:Vector2=g.net_velocity.get(id,Vector2.ZERO)
  state.players[id].velocity=[snappedf(velocity.x,.001),snappedf(velocity.y,.001)]
  state.players[id].position_ack=int(g.input_ack.get(id,0))
  var dash:Dictionary=g.net_dash.get(id,{})
  var d:Vector2=dash.get("direction",Vector2.ZERO)
  state.players[id].dash=[float(dash.get("time",0)),d.x,d.y]
 # All connected recipients get the same retained events and deduplicate by ID.
 var ack=int(room.event_seq)
 for id in room.members:
  if int(identities[id].connection)>=0:ack=mini(ack,int(identities[id].get("event_ack",0)))
 room.events=room.events.filter(func(e):return int(e.id)>ack)
 state.events=[]
 # Reliable effects are sent once per recipient, separately from replaceable state.
 # One slow event acknowledgement must not inflate everybody else's snapshots.
 for id in room.members:
  var key=int(identities[id].connection)
  if key<0 or not peers.has(key):continue
  var ws:WebSocketPeer=peers[key].ws
  if ws.get_ready_state()!=WebSocketPeer.STATE_OPEN or ws.get_current_outbound_buffered_amount()>SOCKET_BACKLOG:continue
  var pending=room.events.filter(func(event):return int(event.id)>int(identities[id].get("event_sent",0)))
  if pending.is_empty():continue
  if ws.send_text(JSON.stringify({"type":"events","match_id":g.match_id,"server_tick":g.authority_tick,"events":pending}))==OK:identities[id].event_sent=int(pending[-1].id)
 var encoding=Time.get_ticks_usec()
 var bytes=JSON.stringify(state).to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)
 encode_ms=(Time.get_ticks_usec()-encoding)/1000.0;snapshot_bytes=bytes.size()
 for id in room.members:
  var key=int(identities[id].connection)
  if key<0:continue
  send_snapshot(key,bytes);snapshots+=1
 snapshot_ms=(Time.get_ticks_usec()-began)/1000.0
 g.metrics.snapshot_ms=snapshot_ms

func send_state(key:int,g:Node,id:String)->void:
 identities[id].last_seq=0;g.input_ack[id]=0;g.server_input_credit[id]=0;snapshot(g)

func send_state_snapshot(g:Node)->void:snapshot(g)
