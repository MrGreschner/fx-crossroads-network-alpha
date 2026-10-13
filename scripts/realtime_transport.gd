extends RefCounted
## Full replaceable snapshots; reliable controls/events never depend on a delta baseline.
const MAX_PACKET=2097152
const CHUNK=12000
var assemblies:Dictionary={}
var raw_snapshot_bytes:=0
var wire_snapshot_bytes:=0
var game:Node
var serial:=0
var received:Dictionary={}
var metadata:Dictionary={}
var sent_bytes:=0
var stale:=0
var deferred:=0
var motion_timer:=0.0
var heartbeat_timer:=0.0
var ping_ms:=0.0
func reset()->void:
 serial=0;received.clear();metadata.clear();assemblies.clear();motion_timer=0;heartbeat_timer=0;ping_ms=0
func forget(id:String)->void:
 metadata.erase(id)
 for key in assemblies.keys():
  if str(key).begins_with(id+":"):assemblies.erase(key)
 for key in received.keys():
  if str(key).begins_with(id+":"):received.erase(key)
func next()->int:serial+=1;return serial
func channel(id:String,fast:bool=false):
 if not game.links.has(id):return null
 var link:Dictionary=game.links[id]
 var stream=link.get("realtime") if fast else link.get("channel")
 if stream!=null and stream.get_ready_state()==WebRTCDataChannel.STATE_OPEN:return stream
 return null
func send(id:String,data:Dictionary,fast:bool=false)->void:
 var stream=channel(id,fast)
 if stream==null:stream=channel(id)
 if stream==null:return
 if fast and stream.get_buffered_amount()>65536:deferred+=1;return
 var bytes:=JSON.stringify(data).to_utf8_buffer()
 var result:int=stream.put_packet(bytes)
 if result==OK:sent_bytes+=bytes.size()
 else:
  var stability=game.get_node_or_null("/root/FXStability")
  if stability!=null:stability.send_errors+=1
func accept(id:String,data:Dictionary)->bool:
 var type:=str(data.get("type",""))
 if type not in ["motion","pos","state"] or not data.has("seq"):return true
 if type in ["state","motion"]:
  if game.role!="guest" or id!=game.host_id:return false
  if str(data.get("match_id",""))!=game.match_id:return false
 elif game.role!="host" or not game.positions.has(id):return false
 var key:=id+":"+type;var sequence:=int(data.seq)
 if sequence<=int(received.get(key,-1)):stale+=1;return false
 received[key]=sequence;return true
func broadcast_state(data:Dictionary)->void:
 # Metadata is sent reliably only when changed; full snapshot remains the fallback.
 var packet:Dictionary=data.duplicate();packet.seq=next();packet.players={}
 for id in data.get("players",{}):packet.players[id]=data.players[id].duplicate()
 var events:Array=packet.get("effects",[]);packet.effects=[]
 for id in game.links.keys():
  if not game._link_open(str(id)):continue
  var meta:Dictionary={}
  for player in packet.get("players",{}):
   var info:Dictionary=packet.players[player]
   meta[player]={"build":info.get("build",{}),"cosmetic":info.get("cosmetic",{}),"defeat":info.get("defeat",{})}
  if metadata.get(id,{})!=meta:
   send(str(id),{"type":"player_metadata","match_id":game.match_id,"players":meta})
   metadata[id]=meta.duplicate(true)
  if not events.is_empty():send(str(id),{"type":"effect_batch","match_id":game.match_id,"events":events})
 # Keep final results reliable, and use full states for explicit recovery paths.
 var active:=bool(packet.get("active",false)) and str(packet.get("results","")).is_empty()
 for info in packet.get("players",{}).values():info.erase("build");info.erase("cosmetic");info.erase("defeat")
 var bytes:=encode(packet)
 var stability=game.get_node_or_null("/root/FXStability")
 if stability!=null:stability.last_packet_bytes=bytes.size()
 for id in game.links.keys():
  var stream=channel(str(id),active)
  if stream==null:stream=channel(str(id))
  if stream==null:continue
  var queued:int=stream.get_buffered_amount()
  if stability!=null:stability.buffered_bytes=maxi(stability.buffered_bytes,queued)
  if active and queued>65536:deferred+=1;continue
  var result:int=put_encoded(stream,bytes)
  if stability!=null:
   stability.packets_sent+=1
   if result!=OK:stability.send_errors+=1
func step(delta:float)->void:
 if not game.started:return
 heartbeat_timer-=delta
 if heartbeat_timer<=0:
  heartbeat_timer=2
  for id in game.links.keys():send(str(id),{"type":"net_ping","sent":Time.get_ticks_msec()})
 if game.role!="host":return
 motion_timer-=delta
 if motion_timer>0:return
 motion_timer=.05
 var players:Dictionary={}
 for id in game.positions:players[id]=[snappedf(game.positions[id].x,.1),snappedf(game.positions[id].y,.1)]
 var data:Dictionary={"type":"motion","seq":next(),"match_id":game.match_id,"players":players}
 var bytes:=JSON.stringify(data).to_utf8_buffer()
 for id in game.links.keys():
  var stream=channel(str(id),true)
  # Existing reliable snapshots are the fallback; don't flood that channel.
  if stream==null:continue
  if stream.get_buffered_amount()>16384:deferred+=1;continue
  if stream.put_packet(bytes)==OK:sent_bytes+=bytes.size()
func receive(id:String,data:Dictionary)->bool:
 match str(data.get("type","")):
  "net_ping":send(id,{"type":"net_pong","sent":int(data.get("sent",0))});return true
  "net_pong":ping_ms=clampf(Time.get_ticks_msec()-int(data.get("sent",Time.get_ticks_msec())),0,60000);return true
  "player_metadata":
   if game.role=="guest" and id==game.host_id and str(data.get("match_id",""))==game.match_id:
    for player in data.get("players",{}):
     var info:Dictionary=data.players[player];game.legacy.builds[str(player)]=game.legacy.sanitize_build(info.get("build",{}));game.player_cosmetics[player]=info.get("cosmetic",{});game.defeat_causes[player]=info.get("defeat",{})
   return true
  "effect_batch":
   if game.role=="guest" and id==game.host_id and str(data.get("match_id",""))==game.match_id:
    for event in data.get("events",[]):game._receive_effect(event)
   return true
  "motion":
   if game.role=="guest" and id==game.host_id:
    var stamp:=Time.get_ticks_msec()/1000.0
    for player in data.get("players",{}):
     var pair:Variant=data.players[player]
     if player!=game.my_id and game.positions.has(player) and pair is Array and pair.size()==2:
      var p:=Vector2(float(pair[0]),float(pair[1]));game.smoothing.push("p:"+str(player),p,stamp);game.motion_received[player]=stamp
   return true
 return false

func encode(data:Dictionary)->PackedByteArray:
 var raw:=JSON.stringify(data).to_utf8_buffer()
 raw_snapshot_bytes=raw.size()
 if raw.size()<2048:wire_snapshot_bytes=raw.size();return raw
 var packed:=raw.compress(FileAccess.COMPRESSION_FASTLZ)
 if packed.size()+8>=raw.size():wire_snapshot_bytes=raw.size();return raw
 var bytes:PackedByteArray="FXZ2".to_utf8_buffer();bytes.resize(8);bytes.encode_u32(4,raw.size());bytes.append_array(packed)
 wire_snapshot_bytes=bytes.size();return bytes

func put_encoded(stream,bytes:PackedByteArray)->int:
 if bytes.size()>MAX_PACKET:return ERR_OUT_OF_MEMORY
 if bytes.size()<=CHUNK:
  var result:int=stream.put_packet(bytes)
  if result==OK:sent_bytes+=bytes.size()
  return result
 var transfer:=next();var count:=ceili(float(bytes.size())/CHUNK)
 for n in count:
  var part:PackedByteArray="FXF2".to_utf8_buffer();part.resize(16);part.encode_u32(4,transfer);part.encode_u16(8,n);part.encode_u16(10,count);part.encode_u32(12,bytes.size());part.append_array(bytes.slice(n*CHUNK,mini(bytes.size(),(n+1)*CHUNK)))
  var result:int=stream.put_packet(part)
  if result!=OK:return result
  sent_bytes+=part.size()
 return OK

func decode(bytes:PackedByteArray,owner:String="")->Dictionary:
 if bytes.size()>MAX_PACKET:return {}
 if bytes.size()>=16 and bytes.slice(0,4).get_string_from_utf8()=="FXF2":
  var stamp:=Time.get_ticks_msec()
  for key in assemblies.keys():
   if stamp-int(assemblies[key].at)>6000:assemblies.erase(key)
  var transfer:=int(bytes.decode_u32(4));var index:=int(bytes.decode_u16(8));var count:=int(bytes.decode_u16(10));var total:=int(bytes.decode_u32(12))
  if total<=CHUNK or total>MAX_PACKET or count!=ceili(float(total)/CHUNK) or index>=count:return {}
  if bytes.size()-16!=mini(CHUNK,total-index*CHUNK):return {}
  var key:=owner+":"+str(transfer)
  if not assemblies.has(key):
   var existing:Array=assemblies.keys().filter(func(k):return str(k).begins_with(owner+":"))
   while existing.size()>=2:assemblies.erase(existing.pop_front())
   var parts:Array=[];parts.resize(count);assemblies[key]={"parts":parts,"size":total,"at":stamp,"received":0}
  var entry:Dictionary=assemblies[key]
  if int(entry.size)!=total:return {}
  if entry.parts[index]==null:entry.parts[index]=bytes.slice(16);entry.received=int(entry.received)+1
  if int(entry.received)<count:return {}
  var joined:=PackedByteArray()
  for part in entry.parts:joined.append_array(part)
  assemblies.erase(key);return decode(joined,owner)
 if bytes.size()>=8 and bytes.slice(0,4).get_string_from_utf8()=="FXZ2":
  var length:=int(bytes.decode_u32(4))
  if length<1 or length>MAX_PACKET:return {}
  bytes=bytes.slice(8).decompress(length,FileAccess.COMPRESSION_FASTLZ)
  if bytes.size()!=length:return {}
 var value:Variant=JSON.parse_string(bytes.get_string_from_utf8())
 return value if value is Dictionary else {}
