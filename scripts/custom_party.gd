extends Node
const Project=preload("res://scripts/workshop_project.gd")
const Balance=preload("res://scripts/studio_balance.gd")
const CHUNK=12000
var game:Node
var projects:Dictionary={}
var acknowledgements:Dictionary={}
var sent:Dictionary={}
var queues:Array=[]
var incoming:Dictionary={}
var pending_builds:Dictionary={}
var runtimes:Dictionary={}
var tick=0.0
var input_clock=0.0
var held:Dictionary={}
func setup(owner:Node)->void:game=owner
func project_for(id:String)->Dictionary:return game.characters.get(id,{}).get("studio_project",{})
func identity(owner:String)->String:return "custom_net_"+owner.sha256_text().left(16)
func allowed(p:Dictionary)->bool:return game.allow_custom and (not game.public_room.button_pressed or Balance.hero_checked(p))
func issue()->String:
 if not pending_builds.is_empty() or not incoming.is_empty():return "Receiving a custom build… please wait."
 for member in game.fighters():
  var id=str(member.id);var hero=str(game.hero_ids.get(id,game.selected_hero if id==game.my_id else "ram"))
  if hero.begins_with("custom_"):
   var p=project_for(hero)
   if not allowed(p):return "Custom heroes are off, or this public build has not passed Forced Balance."
   for peer in game.links:
    if game._link_open(str(peer)) and str(acknowledgements.get(str(peer)+":"+id,""))!=Project.fingerprint(p):return "Sharing custom hero artwork and abilities… please wait."
 return ""
func install(owner:String,p:Dictionary)->String:
 if runtimes.has(owner):runtimes[owner].queue_free();runtimes.erase(owner)
 var id=identity(owner);var h:Dictionary=p.hero.duplicate(true);h.id=id;h.sprite=id;h.cost=0;h.passive_effect="studio";h.studio_project=p.duplicate(true);h.studio_checked=Balance.hero_checked(p);h.studio_token=Project.fingerprint(p);h.passive=Project.PASSIVES.get(p.hero.passive,"Custom")
 game.characters[id]=h
 for pose in h.art:
  var image=Image.new()
  if image.load_png_from_buffer(Marshalls.base64_to_raw(h.art[pose]))==OK:game.art[id+"_"+pose]=ImageTexture.create_from_image(image)
 projects[owner]=p.duplicate(true);game.hero_ids[owner]=id;game.lobby_heroes[owner]=id
 if owner==game.my_id:game.selected_hero=id;game.preferred_hero=id
 return id
func enqueue(peer:String,owner:String,p:Dictionary)->void:
 var definition:Dictionary=game.characters.get(identity(owner),game.characters.get(game.selected_hero,{}) if owner==game.my_id else {})
 var token=str(definition.get("studio_token",""))
 if token.is_empty():token=Project.fingerprint(p)
 var key=peer+":"+owner
 if sent.get(key)==token:return
 sent[key]=token;game._send_channel(peer,{"type":"custom_offer","owner":owner,"token":token,"cosmetic":game.local_cosmetic() if owner==game.my_id else game.cosmetic_for(owner)});var text=JSON.stringify(p);queues.append({"peer":peer,"owner":owner,"token":token,"text":text,"index":0})
func _process(delta:float)->void:
 if game==null:return
 if game.role.is_empty():queues.clear();sent.clear();projects.clear();acknowledgements.clear();return
 tick+=delta
 if not game.my_id.is_empty():
  var p=project_for(game.selected_hero)
  if not p.is_empty() and game.allow_custom and (not game.public_room.button_pressed or bool(game.characters[game.selected_hero].get("studio_checked",false))):
   if game.role=="host":
    if game.selected_hero!=identity(game.my_id) or not projects.has(game.my_id):install(game.my_id,p)
   elif game._link_open(game.host_id):enqueue(game.host_id,game.my_id,p)
  if game.role=="host":
   for peer in game.links:
    if not game._link_open(str(peer)):continue
    for owner in projects:enqueue(str(peer),str(owner),projects[owner])
 if tick>=.05:
  tick=0
  if not queues.is_empty():
   var q:Dictionary=queues[0]
   if not game._link_open(q.peer):queues.pop_front();sent.erase(str(q.peer)+":"+str(q.owner))
   else:
    game._send_channel(q.peer,{"type":"custom_chunk","owner":q.owner,"token":q.token,"index":q.index,"length":q.text.length(),"text":q.text.substr(q.index*CHUNK,CHUNK)})
    q.index+=1
    if q.index*CHUNK>=q.text.length():queues.pop_front()
 for owner in pending_builds.keys():
  if Time.get_ticks_msec()-int(pending_builds[owner])>20000:pending_builds.erase(owner);game.status_label.text="Custom transfer timed out. Re-select your hero or reconnect."
 for key in incoming.keys():
  if Time.get_ticks_msec()-int(incoming[key].stamp)>20000:incoming.erase(key)
 if not game.started or game.start_countdown>0 or game.recovery!=null and game.recovery.frozen:return
 input_clock+=delta
 var local_custom=not project_for(str(game.hero_ids.get(game.my_id,game.selected_hero))).is_empty()
 if local_custom and game.start_countdown<=0 and game.presentation.page.is_empty() and game.shop_open.is_empty() and not game.spectating():
  for kind in Project.KINDS:
   var down=game.mobile.attacking if game.mobile.enabled and kind=="primary" else Input.is_action_pressed(kind)
   if down!=bool(held.get(kind,false)) or down and input_clock>=.12:
    var p:Vector2=game.local_pos+game.mobile.aim*400 if game.mobile.enabled else game.media_mouse_world()
    if game.role=="host":input(game.my_id,kind,down,p)
    else:game._send_channel(game.host_id,{"type":"custom_input","kind":kind,"down":down,"point":[p.x,p.y]})
    held[kind]=down
  if input_clock>=.12:input_clock=0
 if game.role=="host":
  for owner in game.positions:
   var p=project_for(str(game.hero_ids.get(owner,"")))
   if p.is_empty():continue
   if not runtimes.has(owner):
    var runtime=preload("res://scripts/custom_party_runtime.gd").new();add_child(runtime);runtime.setup_party(game,str(owner),p);runtimes[owner]=runtime
   runtimes[owner].step(minf(delta,.05))
func input(owner:String,kind:String,down:bool,point:Vector2)->void:
 if game.role!="host" or not game.started or game.start_countdown>0 or not Project.KINDS.has(kind) or not game.positions.has(owner):return
 if not is_finite(point.x) or not is_finite(point.y) or int(game.health.get(owner,0))<=0:return
 if game.adventure.combat.stunned("p:"+owner) or int(game.levels.get(owner,1))<({"primary":1,"secondary":3,"special":6}[kind]):return
 if not runtimes.has(owner):return
 var runtime=runtimes[owner];runtime.aim_point=game.positions[owner]+(point-game.positions[owner]).limit_length(600);runtime.aim=(runtime.aim_point-game.positions[owner]).normalized()
 if down:runtime.press(kind)
 else:runtime.release(kind)
func packet(sender:String,data:Dictionary)->bool:
 var type=str(data.get("type",""))
 if type=="custom_offer":
  if game.role=="host" and (not game.started or game.party_tools.late_pending.has(sender)) and str(data.get("owner",""))==sender:
   if data.get("cosmetic") is Dictionary and JSON.stringify(data.cosmetic).length()<4000:game.player_cosmetics[sender]=data.cosmetic
   pending_builds[sender]=Time.get_ticks_msec();game.lobby_heroes.erase(sender)
  return true
 if type=="custom_input":
  if data.get("point") is Array and data.point.size()==2:input(sender,str(data.get("kind","")),bool(data.get("down",false)),Vector2(float(data.point[0]),float(data.point[1])))
  return true
 if type=="custom_ack":
  if game.role=="host" and projects.has(str(data.get("owner",""))) and data.get("token")==Project.fingerprint(projects[str(data.owner)]):acknowledgements[sender+":"+str(data.owner)]=str(data.token)
  return true
 if type!="custom_chunk":return false
 if game.role=="guest" and sender!=game.host_id:return true
 var owner=str(data.get("owner",""));var token=str(data.get("token",""));var index=int(data.get("index",-1));var length=int(data.get("length",0));var text=data.get("text",null)
 if game.role=="host" and owner!=sender:return true
 if not game.roster.any(func(member):return str(member.id)==owner):return true
 if owner.length()>80 or token.length()!=64 or not text is String or text.length()>CHUNK or length<=0 or length>Project.MAX_BYTES or index<0 or index>180:return true
 var key=sender+":"+owner
 if index==0:incoming[key]={"token":token,"index":0,"length":length,"parts":[],"stamp":Time.get_ticks_msec()}
 if not incoming.has(key):return true
 var q:Dictionary=incoming[key]
 if q.token!=token or q.index!=index or q.length!=length or index*CHUNK+text.length()>length:incoming.erase(key);return true
 q.parts.append(text);q.index+=1;q.stamp=Time.get_ticks_msec()
 if q.index*CHUNK<length:return true
 var p=JSON.parse_string("".join(q.parts));incoming.erase(key)
 if not Project.validate(p).is_empty() or Project.fingerprint(p)!=token:return true
 if game.role=="host" and game.started and not game.party_tools.late_pending.has(sender):return true
 if game.role=="host" and not allowed(p):game.status_label.text="Rejected a custom build: enable customs; public builds need Forced Balance.";game._kick_member(sender);return true
 pending_builds.erase(owner)
 install(owner,p)
 if game.role=="guest":game._send_channel(game.host_id,{"type":"custom_ack","owner":owner,"token":token})
 else:
  if game.started and game.party_tools.late_pending.has(owner):
   game._add_player(owner,game.roster.size()-1);game.hero_ids[owner]=identity(owner);game.health[owner]=game._max_hp(owner);game.levels[owner]=1;game.xp[owner]=0
   game.party_tools.late_pending.erase(owner);var config=game.match_config();config.type="late_start";game._send_channel(owner,config)
  game._send_lobby_state()
 return true
func reset()->void:
 for runtime in runtimes.values():runtime.queue_free()
 runtimes.clear();held.clear()
func flags(id:String)->Dictionary:
 var p=project_for(str(game.hero_ids.get(id,game.selected_hero if id==game.my_id else "")))
 return {"custom":not p.is_empty(),"balanced":bool(game.characters.get(str(game.hero_ids.get(id,game.selected_hero if id==game.my_id else "")),{}).get("studio_checked",false))}
func minion_actor(key:String)->Dictionary:
 var parts=key.split("|")
 if parts.size()!=3 or not runtimes.has(parts[1]):return {}
 for m in runtimes[parts[1]].minions:
  if str(m.get("party_uid",""))==parts[2]:return {"pos":m.pos,"alive":float(m.hp)>0,"minion":m}
 return {}
func minion_keys(owner:String)->Array[String]:
 var result:Array[String]=[]
 for player in runtimes:
  if owner!="enemy" and not (game.mode in ["arena","battlegrounds"] and game._rival(owner,str(player))):continue
  for m in runtimes[player].minions:result.append("c|"+str(player)+"|"+str(m.get("party_uid","")))
 return result

func wire(value:Variant)->Variant:
 if value is Vector2:return {"v":[snappedf(value.x,.1),snappedf(value.y,.1)]}
 if value is Color:return {"color_value":value.to_html()}
 if value is Dictionary:
  var result={}
  for key in value:
   if key in ["animation","charge_animation","sound","program","behavior","minion_image"]:continue
   result[key]=wire(value[key])
  return result
 if value is Array:
  var result=[]
  for entry in value:result.append(wire(entry))
  return result
 return value
func unpack(value:Variant)->Variant:
 if value is Dictionary:
  if value.size()==1 and value.get("v") is Array and value.v.size()==2:return Vector2(float(value.v[0]),float(value.v[1]))
  if value.size()==1 and value.has("color_value"):return Color(str(value.color_value))
  var result={}
  for key in value:result[key]=unpack(value[key])
  return result
 if value is Array:
  var result=[]
  for entry in value:result.append(unpack(entry))
  return result
 return value
func snapshot()->Dictionary:
 var result={}
 for owner in runtimes:
  var r=runtimes[owner];result[owner]=wire({"shots":r.shots.slice(0,24),"fields":r.fields.slice(0,12),"minions":r.minions.slice(0,5),"visuals":r.visuals.slice(0,16),"holds":r.holds,"aim":r.aim,"time":r.time,"protection":r.protection,"active_form":r.active_form,"form_left":r.form_left})
 return result
func receive(value:Dictionary)->void:
 if value.size()>8:return
 for owner in value:
  if not value[owner] is Dictionary:return
  var p=project_for(str(game.hero_ids.get(owner,"")))
  if p.is_empty():continue
  if not runtimes.has(owner):
   var r=preload("res://scripts/custom_party_runtime.gd").new();add_child(r);r.setup_party(game,str(owner),p);runtimes[owner]=r
  var r=runtimes[owner];var state:Dictionary=unpack(value[owner])
  for key in ["shots","fields","minions","visuals"]:
   if state.get(key) is Array and state[key].size()<=40:r.set(key,state[key])
  r.active_form=str(state.get("active_form","")) if r.form_textures.has(str(state.get("active_form",""))) else "";r.form_left=clampf(float(state.get("form_left",0)),0,8)
  r.holds=state.get("holds",{});r.aim=state.get("aim",Vector2.RIGHT);r.time=float(state.get("time",0));r.protection=float(state.get("protection",0));r.player=game.positions.get(owner,Vector2.ZERO)
func draw_on(c:Node2D,camera:Vector2)->void:
 for owner in runtimes:
  if int(game.health.get(owner,0))>0:runtimes[owner].draw_on(c,camera)
