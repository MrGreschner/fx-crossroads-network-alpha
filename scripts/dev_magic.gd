extends Node2D
## Host-authoritative, bounded demonstrations; all affected matches are practice.
var game:Node
var slow_until:int=0
var slow_owner=""
var last_request:Dictionary={}
var bolts:Array=[]
var marks:Array=[]
var pending:Array=[]
var aiming=""
var summon_kind=""
var summon_count=1
var input_until=0
var epoch_scene:Node
var quarantine=false
func setup(owner:Node)->void:game=owner
func multi()->bool:return game.get("my_id")!=null
func authority()->bool:return not multi() or game.role=="host"
func dev(id:String)->bool:
 if multi():return bool(game.cosmetic_for(id).get("game_dev",false))
 var session=get_tree().root.get_node_or_null("FXDevSession")
 return session!=null and session.active
func scale_for(id:String)->float:return .3 if Time.get_ticks_msec()<slow_until and not dev(id) else 1.0
func world_scale()->float:return .3 if Time.get_ticks_msec()<slow_until else 1.0
func owner()->String:return str(game.my_id) if multi() else "solo"
func request(kind:String,point:Vector2=Vector2.ZERO,enemy:String="",count:int=1)->bool:
 if not dev(owner()):return false
 var packet={"type":"dev_power","kind":kind,"point":[point.x,point.y],"enemy":enemy,"count":count}
 if multi() and not authority():game._send_channel(game.host_id,packet);return true
 return execute(owner(),packet)
func isolate()->void:
 if quarantine:return
 quarantine=true;epoch_scene=game
 if multi() and authority():game._broadcast({"type":"dev_test"})
 get_tree().root.set_meta("fx_dev_match",true)
 var session=get_tree().root.get_node_or_null("FXDevSession")
 if session!=null:session.test_scene=game
 if multi():game.status_label.text="GAME DEV TEST • player progress disabled for this match"
func catalogue()->Dictionary:
 var result:Dictionary=(game.enemy_defs if multi() else game.enemy_types).duplicate(true)
 var regions:Dictionary=game.regions if multi() else game.realms
 var bosses:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://content/encounter_bosses.json"))
 for realm in bosses:
  for kind in bosses[realm]:
   if result.has(kind):result[kind]["dev_boss"]=true;continue
   if str(kind).begins_with("boss:"):
    var r:Dictionary=regions.get(realm,{})
    result[kind]={"name":str(r.get("boss_name",str(kind).substr(5).replace("_"," ").capitalize())),"sprite":str(kind).substr(5),"health":maxf(250,float(r.get("boss_health",950))),"dev_boss":true}
 return result
func execute(id:String,packet:Dictionary)->bool:
 if not authority() or not dev(id):return false
 if multi() and (not game.started or game.start_countdown>0):return false
 if not multi() and game.mode!="run":return false
 var kind=str(packet.get("kind",""))
 if kind not in ["random","slow","summon","volley","blink","rally","sweep","spotlight"]:return false
 var xy=packet.get("point",[])
 if not xy is Array or xy.size()!=2:return false
 var point=Vector2(float(xy[0]),float(xy[1]))
 if not is_finite(point.x) or not is_finite(point.y):return false
 var now=Time.get_ticks_msec()
 if now-int(last_request.get(id,-10000))<1000:return false
 var origin=game.positions.get(id,game.camera+game.VIEW*.5) if multi() else game.position_in_world
 var bounds=game.FIELD if multi() else Rect2(Vector2.ZERO,game.region_size())
 point=point.clamp(bounds.position+Vector2.ONE*28,bounds.end-Vector2.ONE*28)
 if kind=="summon" and (not catalogue().has(str(packet.get("enemy",""))) or game.adventure.foes().size()>=120):return false
 if kind=="blink" and multi() and not game.positions.has(id):return false
 if kind=="blink" and not (game._clear_path(point,point) if multi() else game.can_stand_at(point)):return false
 last_request[id]=now;isolate()
 match kind:
  "random":
   if multi():
    for other in game.positions.keys():
     if dev(str(other)) or game.bots.is_bot(str(other)):continue
     var fraction=float(game.health.get(other,0))/maxf(1,game._max_hp(str(other)))
     var keys=game.characters.keys();var hero=str(keys[randi()%keys.size()])
     game.hero_ids[other]=hero;game.cooldown_at[other]={};game.charges.erase(other);game.adventure.combat.held_cast.charges.erase(other)
     game.health[other]=roundi(game._max_hp(str(other))*fraction)
     if other==game.my_id:game.selected_hero=hero
     else:game._send_channel(str(other),{"type":"dev_hero","hero":hero})
     mark(game.positions[other],"flash",1.0)
   else:mark(origin,"flash",1.0)
  "slow":slow_owner=id;slow_until=now+16000;mark(origin,"clock",2)
  "summon":
   var key=str(packet.enemy);var definition:Dictionary=catalogue()[key]
   var boss=bool(definition.get("dev_boss",false))
   var sprite=str(definition.get("sprite",key));var types:Dictionary=game.enemy_defs if multi() else game.enemy_types
   if not types.has(key):types[key]={"name":definition.name,"sprite":sprite,"health":definition.health,"speed":95,"damage":18,"behaviour":"chase"}
   for pose in ["idle","walk1","walk2","attack"]:
    var path="res://assets/"+sprite+"_"+pose+".png"
    if ResourceLoader.exists(path):game.art[key+"_"+pose]=load(path)
   if not multi():game.load_sprite_pair(sprite)
   for n in mini(clampi(int(packet.get("count",1)),1,9),120-game.adventure.foes().size()):
    var location=point+Vector2.from_angle(n*2.4)*(35+n*10)
    if game.adventure.can_stand(location):game.adventure.spawn(key,location,float(definition.get("health",85)),false)
    if not game.adventure.foes().is_empty():
     var summoned:Dictionary=game.adventure.foes().back();summoned["boss"]=boss;summoned["expansion_boss"]=false;summoned["sprite"]=sprite
   mark(point,"portal",1.5)
  "volley":
   if pending.size()+bolts.size()>120:return false
   for n in 40:pending.append({"owner":id,"origin":origin,"target":point,"delay":n*.065})
   mark(point,"target",3)
  "blink":
   mark(origin,"portal",.8);mark(point,"portal",.8)
   if multi():
    game.positions[id]=point
    if id==game.my_id:game.local_pos=point
    else:game._send_channel(id,{"type":"teleport","point":[point.x,point.y]})
   else:game.position_in_world=point
  "rally":
   if multi():
    for other in game.positions:
     game.health[other]=game._max_hp(str(other));game.respawn_at[other]=0;game.downed.erase(other);mark(game.positions[other],"rally",1.2)
   else:game.health=game.max_health();mark(origin,"rally",1.2)
  "sweep":
   if multi():game.missiles.clear()
   else:game.enemy_shots.clear();game.bullets.clear()
   game.adventure.lob_shots.clear();game.adventure.waves.clear();game.adventure.combat.projectiles.clear();mark(origin,"sweep",1)
  "spotlight":mark(point,"spotlight",8)
 return true
func mark(point:Vector2,kind:String,life:float)->void:
 if marks.size()>=24:marks.pop_front()
 marks.append({"pos":point,"kind":kind,"life":life,"total":life})
func targets(id:String,point:Vector2)->Array:
 var result:Array=[]
 for foe in game.adventure.foes():
  if float(foe.hp)>0 and (foe.pos as Vector2).distance_to(point)<200:result.append({"key":game.adventure.combat.npc_key(foe),"pos":foe.pos})
 if multi():
  for other in game.positions:
   if game._rival(id,str(other)) and float(game.health.get(other,0))>0 and (game.positions[other] as Vector2).distance_to(point)<200:result.append({"key":"p:"+str(other),"pos":game.positions[other]})
 return result
func hit(key:String,id:String)->void:
 if key.begins_with("p:"):
  game._hurt(key.substr(2),3,id)
 else:
  var foes=game.adventure.foes()
  for n in range(foes.size()-1,-1,-1):
   if game.adventure.combat.npc_key(foes[n])==key:
    if multi():game._hit_enemy(n,3,id)
    else:game.damage_enemy(n,3)
    break
 game.adventure.combat.apply_status(key,"stun",.35,id)
func _process(delta:float)->void:
 if not is_instance_valid(game):return
 if (multi() and not game.started) or (not multi() and game.mode!="run"):
  pending.clear();bolts.clear();aiming=""
 if authority():
  for n in range(pending.size()-1,-1,-1):
   pending[n].delay-=delta
   if pending[n].delay<=0:
    var cast:Dictionary=pending[n];var choices=targets(str(cast.owner),cast.target)
    var target:Dictionary=choices[randi()%choices.size()] if not choices.is_empty() else {"key":"","pos":cast.target}
    bolts.append({"pos":cast.origin,"end":target.pos,"key":target.key,"owner":cast.owner,"blast":cast.target,"life":maxf(4,(cast.origin as Vector2).distance_to(target.pos)/480.0+3)});pending.remove_at(n)
  for n in range(bolts.size()-1,-1,-1):
   var bolt:Dictionary=bolts[n];bolt.life-=delta
   var choices=targets(str(bolt.owner),bolt.end)
   for target in choices:
    if target.key==bolt.key:bolt.end=target.pos;break
   bolt.pos=(bolt.pos as Vector2).move_toward(bolt.end,480*delta)
   if (bolt.pos as Vector2).distance_to(bolt.end)<12:
    for victim in targets(str(bolt.owner),bolt.blast):hit(str(victim.key),str(bolt.owner))
    mark(bolt.end,"spark",.25);bolts.remove_at(n)
   elif bolt.life<=0:bolts.remove_at(n)
 for n in range(marks.size()-1,-1,-1):
  marks[n].life-=delta
  if marks[n].life<=0:marks.remove_at(n)
 queue_redraw()
func snapshot()->Dictionary:
 var packet={"testing":quarantine,"slow":maxi(0,slow_until-Time.get_ticks_msec()),"bolts":[],"marks":[]}
 for b in bolts:packet.bolts.append([b.pos.x,b.pos.y,b.end.x,b.end.y])
 for m in marks:packet.marks.append([m.pos.x,m.pos.y,m.kind,m.life,m.total])
 return packet
func receive(packet:Dictionary)->void:
 if bool(packet.get("testing",false)):isolate()
 slow_until=Time.get_ticks_msec()+clampi(int(packet.get("slow",0)),0,16000)
 bolts.clear();marks.clear()
 for b in packet.get("bolts",[]).slice(0,160):bolts.append({"pos":Vector2(b[0],b[1]),"end":Vector2(b[2],b[3])})
 for m in packet.get("marks",[]).slice(0,24):marks.append({"pos":Vector2(m[0],m[1]),"kind":m[2],"life":m[3],"total":m[4]})
func _draw()->void:
 if not is_instance_valid(game):return
 var camera:Vector2=game.camera
 draw_set_transform(game.media.offset(),0,Vector2.ONE*game.media.factor())
 if multi() and game.spectating():draw_set_transform(game.broadcast_offset,0,Vector2.ONE*game.broadcast_scale)
 var clock=Time.get_ticks_msec()/1000.0
 for b in bolts:
  var point:Vector2=b.pos-camera;var direction:Vector2=(b.end-b.pos).normalized()
  draw_line(point-direction*18,point,Color("#e9adff"),3,true);draw_circle(point,4,Color("#fff5b8"))
 for m in marks:
  var point:Vector2=m.pos-camera;var tint=Color("#ffcf69");tint.a=minf(1,float(m.life)/.4)
  var radius=55.0 if m.kind in ["portal","rally","flash"] else 180.0 if m.kind=="target" else 90.0
  draw_arc(point,radius*(1+.05*sin(clock*5)),clock,clock+TAU,32,tint,2,true)
  if m.kind=="spotlight":draw_line(point+Vector2(0,-190),point,Color(1,.88,.5,.2),24,true)
  if m.kind=="spark":draw_circle(point,8,tint)
 if not aiming.is_empty():
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  var point=get_viewport().get_mouse_position()
  draw_arc(point,32+sin(clock*5)*5,clock,clock+TAU,24,Color("#ffdb87"),2,true)
  draw_line(point-Vector2(12,0),point+Vector2(12,0),Color.WHITE,2)
func _input(event:InputEvent)->void:
 if aiming.is_empty():return
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:aiming="";get_viewport().set_input_as_handled()
 if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
  var kind=aiming;aiming="";input_until=Time.get_ticks_msec()+250
  var point=get_viewport().get_mouse_position()
  if multi() and game.spectating():point=(point-game.broadcast_offset)/maxf(.1,game.broadcast_scale)
  else:point=game.media.screen_point(point)
  request(kind,point+game.camera,summon_kind,summon_count);get_viewport().set_input_as_handled()

func _exit_tree()->void:
 pending.clear();bolts.clear();marks.clear()
