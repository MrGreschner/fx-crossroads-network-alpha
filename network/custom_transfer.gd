extends Node
## Small ordered chunks; authority validates full projects before installing them.
const P=preload("res://scripts/workshop_project.gd")
const B=preload("res://scripts/studio_balance.gd")
const CHUNK=3000
var game:Node
var server:Node
var incoming={}
var outgoing:Array=[]
var acks={}
func setup(g:Node,authority:Node=null)->void:game=g;server=authority
func _process(_dt:float)->void:
 var now=Time.get_ticks_msec()
 for key in incoming.keys():
  if now-int(incoming[key].stamp)>30000:incoming.erase(key)
 if outgoing.is_empty():return
 var q:Dictionary=outgoing[0]
 if server!=null and not server.identities.has(q.peer):outgoing.pop_front();return
 if server==null and not game.net_ready:outgoing.clear();return
 if server==null and game.net_peer.get_current_outbound_buffered_amount()>14000:return
 var packet={"type":"custom_build","owner":q.owner,"token":q.token,"length":q.text.length(),"index":q.index,"text":q.text.substr(q.index*CHUNK,CHUNK)}
 if server==null:game.send_net(packet)
 else:server.send_actor(q.peer,packet)
 q.index+=1
 if q.index*CHUNK>=q.text.length():outgoing.pop_front()
func enqueue(peer:String,owner:String,p:Dictionary)->void:
 outgoing.append({"peer":peer,"owner":owner,"token":P.fingerprint(p),"text":JSON.stringify(p),"index":0})
func upload(id:String)->String:
 var p:Dictionary=game.characters.get(id,{}).get("studio_project",{})
 if not B.hero_checked(p):return "Turn on Forced Balance and save this hero before multiplayer."
 enqueue("",game.my_id,p);return "Sharing custom hero • Forced Balance • unofficial match"
func share(room:Dictionary,peer:String="")->void:
 var g=room.game
 for owner in room.members:
  var hero=str(room.members[owner].hero)
  if not hero.begins_with("custom_"):continue
  var p:Dictionary=g.characters.get(hero,{}).get("studio_project",{})
  for target in room.members:
   if not peer.is_empty() and target!=peer:continue
   enqueue(str(target),str(owner),p)
func ready(room:Dictionary)->bool:
 for key in incoming:
  if room.members.has(str(key).get_slice(":",0)):return false
 for owner in room.members:
  var h:Dictionary=room.game.characters.get(room.members[owner].hero,{})
  if str(room.members[owner].hero).begins_with("custom_"):
   if not B.hero_checked(h.get("studio_project",{})):return false
   for target in room.members:
    if str(acks.get(str(target)+":"+str(owner),""))!=str(h.get("studio_token","")):return false
 return true
func receive(sender:String,data:Dictionary,room:Dictionary={})->bool:
 var type=str(data.get("type",""))
 if type=="custom_ready":
  if server!=null and not room.game.started:
   var owner=str(data.get("owner",""));var h:Dictionary=room.game.characters.get(room.members.get(owner,{}).get("hero",""),{})
   if h.get("studio_token","")==data.get("token"):acks[sender+":"+owner]=str(data.token)
  return true
 if type!="custom_build":return false
 if server!=null and (room.game.started or data.get("owner")!=sender):return true
 var owner=str(data.get("owner",""));var token=str(data.get("token",""));var index=int(data.get("index",-1));var length=int(data.get("length",0));var text=data.get("text")
 if owner.length()>80 or token.length()!=64 or not text is String or text.length()>CHUNK or length<=0 or length>P.MAX_BYTES or index<0 or index>900:return true
 var key=sender+":"+owner
 if index==0:
  if incoming.size()>=64 and not incoming.has(key):return true
  incoming[key]={"token":token,"index":0,"length":length,"parts":[],"stamp":Time.get_ticks_msec()}
 if not incoming.has(key):return true
 var q:Dictionary=incoming[key]
 if q.token!=token or q.index!=index or q.length!=length or index*CHUNK+text.length()>length:incoming.erase(key);return true
 q.parts.append(text);q.index+=1;q.stamp=Time.get_ticks_msec()
 if q.index*CHUNK<length:return true
 var p=JSON.parse_string("".join(q.parts));incoming.erase(key)
 if not p is Dictionary or not P.validate(p).is_empty() or P.fingerprint(p)!=token or not B.hero_checked(p) or not preload("res://scripts/community_validation.gd").art_issue(p).is_empty():
  if server!=null:server.fail(int(server.identities[sender].connection),"Custom hero rejected: Forced Balance and valid artwork are required.")
  return true
 var g=room.game if server!=null else game
 var id=g.custom_party.install(owner,p)
 if server!=null:
  room.members[owner].hero=id;room.members[owner].build_choice={};g.allow_custom=true;share(room);server.lobby(str(server.identities[sender].room))
 else:game.send_net({"type":"custom_ready","owner":owner,"token":token})
 return true

func forget(id:String)->void:
 for key in acks.keys():
  if str(key).begins_with(id+":") or str(key).ends_with(":"+id):acks.erase(key)
 for key in incoming.keys():
  if str(key).begins_with(id+":"):incoming.erase(key)
 outgoing=outgoing.filter(func(q):return q.peer!=id and q.owner!=id)
