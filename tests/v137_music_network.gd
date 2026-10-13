extends SceneTree
const Music=preload("res://scripts/music_library.gd")
const Network=preload("res://scripts/music_network.gd")
var failures=0
class Channel:
 extends RefCounted
 var buffered=0
 func get_buffered_amount()->int:return buffered
class Player:
 extends RefCounted
 var selected:Dictionary={}
 var voice:AudioStreamPlayer
 var remote_position=0.0
 var remote_position_at=0
 var remote:Dictionary={}
 var current=""
 func context()->String:return "realm:grove"
class Peer:
 extends Node
 var started=true
 var role="host"
 var host_id="host"
 var music=Player.new()
 var links={}
 var network:Node
 var destination:Node
 var packets:Array=[]
 func _link_open(id:String)->bool:return links.has(id)
 func _send_channel(_id:String,data:Dictionary)->void:
  packets.append(data.duplicate(true))
  if destination!=null:destination.network.packet("host" if role=="host" else "guest",data)
func check(value:bool,label:String)->void:
 print("PASS • " if value else "FAIL • ",label)
 if not value:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 var host=Peer.new();var guest=Peer.new();root.add_child(host);root.add_child(guest)
 guest.role="guest";host.destination=guest;guest.destination=host
 host.links["guest"]={"channel":Channel.new()};guest.links["host"]={"channel":Channel.new()}
 host.network=Network.new();host.add_child(host.network);host.network.setup(host)
 guest.network=Network.new();guest.add_child(guest.network);guest.network.setup(guest)
 var sound=preload("res://scripts/studio_audio.gd").example("water")
 var prepared=Music.prepare("water.wav",sound.data);host.music.selected=prepared.track
 host.network._process(.1)
 check(not host.packets.is_empty() and host.packets[0].type=="music_offer","host announces soundtrack metadata")
 check(not host.packets[0].meta.has("data"),"offer excludes bulk audio bytes")
 for n in 50:host.network._process(.1)
 check(not guest.music.remote.is_empty() and guest.music.remote.data==host.music.selected.data,"paced reliable transfer reconstructs host recording")
 check(guest.music.remote.context=="realm:grove","guest track remains tied to correct realm")
 check(host.network.queues.is_empty(),"completed transfer releases host queue")
 var unchanged=guest.music.remote.duplicate(true)
 guest.network.packet("intruder",{"type":"music_offer","token":"bad","length":0,"meta":{}})
 check(guest.music.remote==unchanged,"guest rejects another player overriding host music")
 guest.network.received="";guest.network.pending="";host.network.offer("guest",host.music.selected,"test")
 check(not guest.network.receiving.is_empty(),"new host track starts one bounded assembly")
 guest.network.packet("host",{"type":"music_chunk","token":"test","index":4,"data":"aaaa"})
 check(guest.network.receiving.index==0,"out-of-order chunks rejected")
 guest.network.packet("host",{"type":"music_chunk","token":"test","index":0,"data":"a".repeat(Network.CHUNK+1)})
 check(guest.network.receiving.index==0,"oversized chunks rejected")
 host.network.queues={"guest":{"token":"blocked","data":sound.data,"index":0}};host.links.guest.channel.buffered=40000;var before=host.packets.size();host.network._process(.1)
 check(host.packets.size()==before,"asset transfer waits when channel is buffered")
 host.started=false;host.network._process(.1);check(host.network.queues.is_empty(),"leaving match clears queued recording")
 host.queue_free();guest.queue_free();await process_frame
 print("V137 NETWORK FAILURES: ",failures);quit(1 if failures else 0)
