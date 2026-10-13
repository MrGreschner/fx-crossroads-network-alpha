extends Node
## One process owns several bounded private Arena matches. No client runs authority.
const Arena=preload("res://network/arena.gd")
const MAX_ROOMS=4
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
func _ready()->void:
 get_tree().root.set_meta("fx_dedicated_server",true);get_tree().root.set_meta("fx_dev_match",true)
 Engine.physics_ticks_per_second=60
 var port=int(OS.get_environment("FX_GAME_PORT")) if not OS.get_environment("FX_GAME_PORT").is_empty() else 9081
 var error=listener.listen(port,"127.0.0.1" if OS.get_environment("FX_PROXY")!="" else "*")
 if error!=OK:push_error("Server listen failed: "+error_string(error));get_tree().quit(1);return
 print("FX authority listening on ",port,"; protocol 1; simulation 60Hz; snapshots 20Hz")
func _process(_delta:float)->void:
 var now=Time.get_ticks_msec()
 if now>=metric_at:
  metric_at=now+5000;print("FX_METRICS "+JSON.stringify({"rooms":rooms.size(),"connections":peers.size(),"packets":packets,"snapshots":snapshots,"max_tick_ms":max_tick_ms}))
 for n in 8:
  if not listener.is_connection_available():break
  var stream=listener.take_connection()
  if peers.size()>=MAX_CONNECTIONS:stream.disconnect_from_host();continue
  var peer=WebSocketPeer.new();peer.inbound_buffer_size=32768;peer.outbound_buffer_size=1048576;peer.max_queued_packets=64
  if peer.accept_stream(stream)!=OK:stream.disconnect_from_host();continue
  actor_counter+=1;peers[actor_counter]={"ws":peer,"actor":"","seen":now,"born":now,"budget":120.0,"tick":now}
 for key in peers.keys():
  var connection:Dictionary=peers[key];var peer:WebSocketPeer=connection.ws;peer.poll()
  if peer.get_ready_state()==WebSocketPeer.STATE_CLOSED or (connection.actor.is_empty() and now-int(connection.born)>8000) or now-int(connection.seen)>10000:
   drop_connection(key);continue
  connection.budget=minf(120,float(connection.budget)+(now-int(connection.tick))*.12);connection.tick=now
  var count=0
  while peer.get_available_packet_count()>0 and count<16:
   count+=1;var bytes=peer.get_packet()
   if bytes.size()>16384 or connection.budget<1:peer.close(1008,"Packet limit");break
   connection.budget-=1;connection.seen=now;packets+=1
   var data=JSON.parse_string(bytes.get_string_from_utf8())
   if data is Dictionary:receive(key,data)
 for code in rooms.keys():
  var room:Dictionary=rooms[code];var g:Node=room.game
  max_tick_ms=maxf(max_tick_ms,float(g.metrics.tick_ms))
  for id in room.members.keys():
   if identities.has(id) and int(identities[id].connection)<0 and now-int(identities[id].left)>60000:
    room.members.erase(id);g.positions.erase(id);g.health.erase(id);g.hero_ids.erase(id);g.server_inputs.erase(id);g.server_actions.erase(id);identities.erase(id)
  if room.members.is_empty():g.queue_free();rooms.erase(code)
func drop_connection(key:int)->void:
 var entry:Dictionary=peers[key];var id=str(entry.actor)
 if identities.has(id):
  identities[id].connection=-1;identities[id].left=Time.get_ticks_msec()
  var code=str(identities[id].room)
  if rooms.has(code):
   var g:Node=rooms[code].game;g.server_inputs[id]=[];g.server_actions[id]=[]
   g.adventure.combat.held_cast.packet(id,{"phase":"cancel"})
   g.adventure.combat.release_heroes.holding(id,false,Vector2.RIGHT);g.adventure.combat.classics.holding(id,false);g.adventure.combat.v79.holding(id,false,Vector2.RIGHT);g.adventure.combat.v56.holding(id,false,Vector2.RIGHT)
 entry.ws.close();peers.erase(key)
func send(key:int,data:Dictionary)->void:
 if not peers.has(key):return
 var ws:WebSocketPeer=peers[key].ws
 if ws.get_ready_state()!=WebSocketPeer.STATE_OPEN:return
 if ws.get_current_outbound_buffered_amount()>65536:
  ws.close(1013,"Slow connection; reconnect");return
 if str(data.get("type",""))=="state":ws.put_packet(JSON.stringify(data).to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP))
 else:ws.send_text(JSON.stringify(data))
func fail(key:int,text:String)->void:send(key,{"type":"error","message":text})
func send_actor(id:String,data:Dictionary)->void:
 if identities.has(id):send(int(identities[id].connection),data)
func receive(key:int,data:Dictionary)->void:
 if not peers.has(key):return
 var kind=str(data.get("type",""));var connection:Dictionary=peers[key]
 if connection.actor.is_empty():
  if kind not in ["host","join","resume"]:return
  if int(data.get("protocol",0))!=1:fail(key,"Network protocol mismatch. Use this alpha client.");return
  join(key,data);return
 var id=str(connection.actor);var identity:Dictionary=identities[id];var room:Dictionary=rooms[identity.room];var g:Node=room.game
 if kind=="leave":
  room.members.erase(id);g.positions.erase(id);g.health.erase(id);g.hero_ids.erase(id)
  if room.host==id:room.host=str(room.members.keys()[0]) if not room.members.is_empty() else ""
  identities.erase(id);drop_connection(key)
  if not room.members.is_empty():lobby(str(identity.room))
  return
 if kind=="ping":send(key,{"type":"pong","sent":int(data.get("sent",0))});return
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
  g._start_match();g.start_countdown=0;g.server_inputs.clear();g.server_actions.clear();g.input_ack.clear();g.net_dash.clear();g.authority_tick=0
  room.events=[];room.event_seq=0
  for member in room.members:g.server_inputs[member]=[];g.server_actions[member]=[];g.input_ack[member]=0;identities[member].last_seq=0
  broadcast_game(g,start_packet(g));snapshot(g);return
 if kind=="hero":
  if g.started:return
  var hero=str(data.get("hero",""))
  if valid_hero(g,hero):room.members[id].hero=hero;lobby(identity.room)
  return
 if not g.started or str(data.get("match_id",""))!=g.match_id:return
 if kind=="input":
  var batch=data.get("frames",[])
  if not batch is Array or batch.size()>4:return
  for raw in batch:
   if not valid_frame(raw):fail(key,"Invalid movement frame");return
   var seq=int(raw.seq)
   if seq<=int(identity.last_seq):continue
   if seq!=int(identity.last_seq)+1 or g.server_inputs.get(id,[]).size()>=120:
    print("FX_INPUT_REJECT expected=",int(identity.last_seq)+1," actual=",seq," queue=",g.server_inputs.get(id,[]).size());peers[key].ws.close(1008,"Input sequence or queue limit");return
   identity.last_seq=seq;g.server_inputs[id].append(raw)
  identity.event_ack=maxi(int(identity.get("event_ack",0)),mini(int(room.event_seq),int(data.get("event_ack",0))))
 elif kind in ["attack","held_cast","dodge","consume"]:
  if g.server_actions.get(id,[]).size()>=32:return
  var serial=int(data.get("seq",0))
  if serial<=int(identity.get("action_seq",0)):return
  if not valid_action(data):return
  identity.action_seq=serial;g.server_actions[id].append(data)
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
   if rooms.size()>=MAX_ROOMS:fail(key,"Test server room capacity reached.");return
   code=Crypto.new().generate_random_bytes(4).hex_encode().left(6).to_upper()
   var g=Arena.new();g.gateway=self;add_child(g)
   var seats=clampi(int(data.get("seats",2)),2,8);g.arena_seats=seats
   rooms[code]={"game":g,"members":{},"host":"","seats":seats,"events":[],"event_seq":0}
  if not rooms.has(code):fail(key,"Room not found.");return
  var room:Dictionary=rooms[code]
  if room.game.started:fail(key,"Match already started. Reconnect using your existing seat.");return
  if room.members.size()>=int(room.seats):fail(key,"Room full; disconnected seats are reserved for 60 seconds.");return
  var hero=str(data.get("hero","ram"))
  if not valid_hero(room.game,hero):fail(key,"Choose an official hero.");return
  id=Crypto.new().generate_random_bytes(8).hex_encode()
  identities[id]={"room":code,"token":Crypto.new().generate_random_bytes(24).hex_encode(),"connection":key,"left":0,"last_seq":0,"action_seq":0,"event_ack":0}
  room.members[id]={"id":id,"name":str(data.get("name","Tester")).left(24),"hero":hero}
  if room.host.is_empty():room.host=id
 peers[key].actor=id;identities[id].connection=key
 send(key,{"type":"welcome","protocol":1,"id":id,"room":code,"token":identities[id].token,"host":rooms[code].host==id})
 if rooms[code].game.started:
  var g:Node=rooms[code].game;g.server_inputs[id]=[];g.server_actions[id]=[]
  send(key,start_packet(g));send_state(key,g,id)
 else:lobby(code)
func lobby(code:String)->void:
 var room:Dictionary=rooms[code]
 for id in room.members:send_actor(id,{"type":"lobby","host":room.host,"seats":room.seats,"members":room.members.values()})
func room_for(g:Node)->Dictionary:
 for room in rooms.values():
  if room.game==g:return room
 return {}
func start_packet(g:Node)->Dictionary:return {"type":"start","match_id":g.match_id,"seed":g.floor_seed,"arena_map":g.arena_map,"seats":g.arena_seats,"heroes":g.hero_ids}
func broadcast_game(g:Node,data:Dictionary)->void:
 var room=room_for(g)
 for id in room.get("members",{}):send_actor(str(id),data)
func execute_action(g:Node,id:String,data:Dictionary)->void:
 var before=g.missiles.size();var style=str(data.get("style","primary"));var previous=int(g.cooldown_at.get(id,{}).get(style,0))
 var dodge_before=int(g.dodge_at.get(id,0))
 g.set_meta("fx_action_seq",int(data.seq));g._packet(id,data);g.remove_meta("fx_action_seq")
 if str(data.type)=="dodge" and int(g.dodge_at.get(id,0))>dodge_before:
  var d=data.get("direction",[1,0]);g.net_dash[id]={"time":.26,"direction":Vector2(float(d[0]),float(d[1])).normalized()}
 for n in range(before,g.missiles.size()):g.missiles[n].action_seq=int(data.seq);g.missiles[n].shot_index=n-before
 var after=int(g.cooldown_at.get(id,{}).get(style,0))
 send_actor(id,{"type":"action_ack","seq":int(data.seq),"style":style,"accepted":after>previous or str(data.type)!="attack","remaining":maxi(0,after-Time.get_ticks_msec())})
func snapshot(g:Node)->void:
 var room=room_for(g)
 if room.is_empty():return
 for effect in g.sent_effects:
  room.event_seq+=1;room.events.append({"id":room.event_seq,"data":effect})
 g.sent_effects.clear()
 # Keep events until acknowledged, bounded against absent or malicious clients.
 while room.events.size()>256:room.events.pop_front()
 var state=g._snapshot();state.server_tick=g.authority_tick;state.tick_ms=g.metrics.tick_ms;state.effects=[]
 state.shots=[]
 for shot in g.missiles:
  var v:Vector2=shot.get("dir",shot.get("direction",Vector2.ZERO))*float(shot.get("speed",0))
  state.shots.append({"net_id":int(shot.get("net_id",0)),"pos":[snappedf(shot.pos.x,.1),snappedf(shot.pos.y,.1)],"velocity":[snappedf(v.x,.1),snappedf(v.y,.1)],"owner":str(shot.owner),"color":str(shot.get("color","#ffd985")),"action_seq":int(shot.get("action_seq",-1)),"shot_index":int(shot.get("shot_index",0))})
 for id in state.players:
  var precise:Vector2=g.positions[id];state.players[id].pos=[snappedf(precise.x,.001),snappedf(precise.y,.001)]
  var velocity:Vector2=g.net_velocity.get(id,Vector2.ZERO)
  state.players[id].velocity=[snappedf(velocity.x,.001),snappedf(velocity.y,.001)]
  state.players[id].position_ack=int(g.input_ack.get(id,0))
  var dash:Dictionary=g.net_dash.get(id,{})
  var d:Vector2=dash.get("direction",Vector2.ZERO)
  state.players[id].dash=[float(dash.get("time",0)),d.x,d.y]
 for id in room.members:
  var key=int(identities[id].connection)
  if key<0:continue
  var outgoing=state.duplicate();outgoing.events=room.events.filter(func(e):return int(e.id)>int(identities[id].event_ack))
  send(key,outgoing);snapshots+=1
func send_state(key:int,g:Node,id:String)->void:
 identities[id].last_seq=0;g.input_ack[id]=0;snapshot(g)
