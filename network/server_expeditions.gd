extends RefCounted
const C=preload("res://scripts/waylight_catalog.gd")
const Profile=preload("res://network/expedition_profile.gd")
var server:Node
func special(room:Dictionary)->bool:return str(room.get("expedition_choice","")) in ["between","attunement","overcharge"]
func cancel(room:Dictionary,reason:String)->void:
 var pending:Dictionary=room.get("preparation",{})
 if pending.is_empty() or room.game.started:return
 room.preparation={}
 for actor in room.members:server.send_actor(str(actor),{"type":"expedition_cancelled","id":str(pending.id),"message":reason})
func prepare(key:int,room:Dictionary)->void:
 if room.members.size()!=2:server.fail(key,"Expeditions need two connected players.");return
 if not room.get("preparation",{}).is_empty():server.fail(key,"Waiting for both entry confirmations.");return
 var g=room.game;var day=C.day_number(Time.get_unix_time_from_system());var kind=str(room.expedition_choice);var realm=C.featured(day) if kind=="overcharge" else "between"
 var host_profile:Dictionary=room.members[room.host].get("expedition_profile",{})
 var cfg={"depth":int(host_profile.get("between_depth",6)),"id":Crypto.new().generate_random_bytes(16).hex_encode(),"kind":kind,"realm":realm,"tier":g.get_meta("expedition_tier",1),"day":day,"seed":randi_range(1,2000000000),"deadline":Time.get_ticks_msec()+45000,"accepted":{}}
 for actor in room.members:
  var member:Dictionary=room.members[actor];var problem=Profile.issue(member.get("expedition_profile",{}),cfg)
  if not problem.is_empty():server.fail(key,problem);return
  if kind=="overcharge" and not member.expedition_profile.practice and realm not in member.get("unlocked",[]):server.fail(key,"Both players must have today's realm unlocked.");return
  if int(server.identities[actor].connection)<0:server.fail(key,"Wait for your partner to reconnect.");return
 room.preparation=cfg
 for actor in room.members:
  var personal=cfg.duplicate(true);personal.erase("accepted");personal.erase("deadline");personal.personal_seed=posmod(hash(str(cfg.id)+str(actor)),1999999999)+1;personal.offer=room.members[actor].expedition_profile
  server.send_actor(str(actor),{"type":"expedition_prepare","config":personal})
func receive(key:int,id:String,room:Dictionary,data:Dictionary)->void:
 var pending:Dictionary=room.get("preparation",{})
 if room.game.started or pending.is_empty() or str(data.get("id",""))!=str(pending.id):return
 if data.type=="expedition_cancel":cancel(room,"Entry cancelled; unstarted entry shards refunded.");return
 var offer=Profile.clean(data.get("profile",{}));var problem=Profile.issue(offer,pending)
 if not problem.is_empty():cancel(room,problem);return
 pending.accepted[id]=offer
 if pending.accepted.size()!=2:return
 if pending.kind=="overcharge" and int(pending.day)!=C.day_number(Time.get_unix_time_from_system()):cancel(room,"Daily rotation changed before launch. Entry shards refunded.");return
 var g=room.game;g.realm_id=str(pending.realm)
 for n in g.realm_picker.item_count:
  if str(g.realm_picker.get_item_metadata(n))==g.realm_id:g.realm_picker.select(n)
 var cfg=pending.duplicate(true);cfg.offers={}
 for actor in pending.accepted:cfg.offers[actor]={"relics":pending.accepted[actor].relics}
 cfg.erase("accepted");cfg.erase("deadline");g.expedition.configure(cfg)
 g.set_meta("expedition_committed",true)
 var host_key=int(server.identities[room.host].connection);server.receive(host_key,{"type":"start"});g.remove_meta("expedition_committed")
 if g.started:room.preparation={}
 else:cancel(room,"Launch failed; unstarted entry shards refunded.")
func poll(room:Dictionary)->void:
 var pending:Dictionary=room.get("preparation",{})
 if not pending.is_empty() and Time.get_ticks_msec()>int(pending.deadline):cancel(room,"Entry confirmation timed out; unstarted entry shards refunded.")
