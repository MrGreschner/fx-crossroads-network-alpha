extends Node
## Slow reliable asset transfer: never place audio in state/input snapshots or signaling.
const Library=preload("res://scripts/music_library.gd")
const CHUNK=16384
var game:Node
var tick=0.0
var announced=""
var queues:Dictionary={}
var receiving:Dictionary={}
var last_activity=0
var pending=""
var received=""
var offer_tick=0.0
func setup(owner:Node)->void:game=owner
func _process(delta:float)->void:
 tick+=delta
 if tick<.05:return
 tick=0
 if not game.started:announced="";queues.clear();receiving.clear();received="";pending="";game.music.remote={};return
 if game.role=="host":
  var track:Dictionary=game.music.selected
  offer_tick+=.05
  var token=game.music.context()+":"+str(track.get("id",""))+":"+str(track.get("volume_db",0))
  if token!=announced or offer_tick>=2.0:
   if token!=announced:queues.clear()
   announced=token;offer_tick=0
   for id in game.links:offer(str(id),track,token)
  for id in queues.keys():
   if not game._link_open(id):queues.erase(id);continue
   var channel=game.links[id].channel
   if channel.get_buffered_amount()>32768:continue
   var q:Dictionary=queues[id]
   game._send_channel(id,{"type":"music_chunk","token":q.token,"index":q.index,"data":q.data.substr(q.index*CHUNK,CHUNK)})
   q.index+=1
   if q.index*CHUNK>=q.data.length():queues.erase(id)
   break # One asset chunk per tick across the whole room; gameplay retains priority.
 else:
  if not receiving.is_empty() and Time.get_ticks_msec()-last_activity>30000:receiving.clear();pending=""
func offer(id:String,track:Dictionary,token:String)->void:
 if not game._link_open(id):return
 var meta=track.duplicate(false);meta.erase("data")
 game._send_channel(id,{"type":"music_offer","token":token,"context":game.music.context(),"meta":meta,"position":game.music.voice.get_playback_position() if game.music.voice!=null else 0.0,"length":str(track.get("data","")).length()})
func packet(sender:String,data:Dictionary)->bool:
 var kind=str(data.get("type",""))
 if not kind in ["music_offer","music_request","music_chunk"]:return false
 if game.role=="host":
  if kind=="music_request" and data.get("token")==announced and game._link_open(sender) and not game.music.selected.is_empty():
   if not queues.has(sender):queues[sender]={"token":announced,"data":str(game.music.selected.data),"index":0}
  return true
 if game.role!="guest" or sender!=game.host_id:return true
 if kind=="music_offer":
  var token=str(data.get("token",""));var length=int(data.get("length",0));var meta=data.get("meta",{})
  if token.length()>220 or length<0 or length>11184812 or not meta is Dictionary:return true
  if length==0:game.music.remote={};game.music.current="";receiving.clear();received=token;return true
  var position=float(data.get("position",0))
  if not is_finite(position) or position<0 or position>Library.MAX_SECONDS:return true
  game.music.remote_position=position;game.music.remote_position_at=Time.get_ticks_msec()
  if token==received or token==pending:return true
  if meta.size()!=8 or not meta.has_all(["format","version","id","title","author","notes","audio_format","volume_db"]):return true
  for key in ["id","title","author","notes","audio_format"]:
   if not meta[key] is String or meta[key].length()>(1200 if key=="notes" else 80):return true
  if str(data.get("context","")).length()>100:return true
  receiving={"token":token,"meta":meta,"context":str(data.get("context","")),"length":length,"parts":[],"index":0};pending=token;last_activity=Time.get_ticks_msec()
  game._send_channel(game.host_id,{"type":"music_request","token":token})
 elif kind=="music_chunk" and not receiving.is_empty():
  if data.get("token")!=receiving.token or int(data.get("index",-1))!=receiving.index or not data.get("data") is String:return true
  var chunk:String=data.data
  if chunk.length()>CHUNK or chunk.is_empty() or receiving.index*CHUNK+chunk.length()>receiving.length:return true
  receiving.parts.append(chunk);receiving.index+=1;last_activity=Time.get_ticks_msec()
  if receiving.index*CHUNK>=receiving.length:
   var track:Dictionary=receiving.meta;track.data="".join(receiving.parts)
   if Library.validate_track(track).is_empty():track.context=receiving.context;game.music.remote=track;game.music.current="";received=receiving.token
   receiving.clear();pending=""
 return true
