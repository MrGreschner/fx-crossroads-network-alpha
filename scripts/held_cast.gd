extends Node
## Press/hold/release casts. Only the host measures remote charge and applies damage.
var combat:Node
var charges:Dictionary={}
var previous:Dictionary={}
var context:Dictionary={}
var remote_preview:Dictionary={}
var flashes:Array=[]
func reset()->void:
 charges.clear();previous.clear();context.clear();remote_preview.clear();flashes.clear()
func _notification(what:int)->void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  if combat!=null and combat.adventure.arcade and combat.adventure.game.role=="guest":combat.adventure.game._send_channel(combat.adventure.game.host_id,{"type":"held_cast","phase":"cancel"})
  charges.clear();previous.clear()
func hero(id:String)->Dictionary:
 var game:Node=combat.adventure.game
 return game.characters.get(str(game.hero_ids.get(id,"ram")),{}) if combat.adventure.arcade else game.hero
func stats_for(id:String,kind:String)->Dictionary:
 return combat.effective_stats(id,kind,hero(id).get(kind,{}))
func supports(id:String,kind:String)->bool:
 var s:Dictionary=stats_for(id,kind)
 return s.has("hold_charge") or float(s.get("travel_speed",0))>0 or str(s.get("style",""))=="rift_triangle"
func suppressed(id:String,kind:String)->bool:
 return (supports(id,kind) or charges.has(id)) and not context.has(id)
func ready(id:String,kind:String)->bool:
 if not combat.playing() or not combat.adventure.alive(id) or combat.stunned(combat.player_key(id)) or combat.busy(id):return false
 var game:Node=combat.adventure.game
 var lv:int=int(game.levels.get(id,1)) if combat.adventure.arcade else int(game.level)
 if lv<(1 if kind=="primary" else 3 if kind=="secondary" else 6):return false
 if combat.adventure.arcade:
  if game.start_countdown>0 or game.recovery.frozen:return false
  if game.role=="guest" and Time.get_ticks_msec()<int(game.get("request_ready").get(kind,0)):return false
  return Time.get_ticks_msec()>=int(game.cooldown_at.get(id,{}).get(kind,0))
 return float(game.cooldowns.get(kind,0))<=0
func begin(id:String,kind:String,aim:Vector2,target:Vector2)->void:
 if charges.has(id) or not supports(id,kind) or not ready(id,kind):return
 charges[id]={"kind":kind,"age":0.0,"aim":combat.point_array(aim.normalized()),"target":combat.point_array(target),"hero":str(hero(id).get("id","")),"heartbeat":0.0,"last_seen":0.0}
func local_input(delta:float,active:bool)->void:
 var game:Node=combat.adventure.game
 var id:String=str(game.my_id) if combat.adventure.arcade else "solo"
 if combat.adventure.arcade and game.characters.get(str(game.hero_ids.get(id,game.selected_hero)),{}).has("studio_project"):return
 var origin:Vector2=combat.owner_pos(id)
 var aim:Vector2=game.mobile.aim if game.mobile.enabled else (game.media_mouse_world()-origin).normalized()
 if aim.is_zero_approx():aim=Vector2.RIGHT
 var target:Vector2=origin+aim*2000 if game.mobile.enabled else game.media_mouse_world()
 for kind in ["primary","secondary","special"]:
  var down:bool=(game.mobile.attacking if game.mobile.enabled else Input.is_action_pressed("primary")) if kind=="primary" else Input.is_action_pressed(kind)
  var was:bool=bool(previous.get(kind,false));previous[kind]=down
  if not active:
   if charges.has(id):
    charges.erase(id)
    if combat.adventure.arcade and game.role=="guest":game._send_channel(game.host_id,{"type":"held_cast","phase":"cancel"})
   continue
  if not supports(id,kind):continue
  if (down and not was) or Input.is_action_just_pressed(kind):
   begin(id,kind,aim,target)
   if charges.has(id) and str(charges[id].kind)==kind and combat.adventure.arcade and game.role=="guest":send("begin",kind,aim,target)
  if charges.has(id) and str(charges[id].kind)==kind:
   charges[id].aim=combat.point_array(aim);charges[id].target=combat.point_array(target)
   if combat.adventure.arcade and game.role=="guest":
    charges[id].age=float(charges[id].age)+delta*(game.dev_magic.scale_for(id) if game.get("dev_magic")!=null else 1.0);charges[id].heartbeat=float(charges[id].heartbeat)+delta
    if down and float(charges[id].heartbeat)>=.2:charges[id].heartbeat=0.0;send("aim",kind,aim,target)
   if not down:
    if combat.adventure.arcade and game.role=="guest":
     send("release",kind,aim,target);charges.erase(id);game.get("request_ready")[kind]=Time.get_ticks_msec()+1000
    else:release(id)
func send(phase:String,kind:String,aim:Vector2,target:Vector2)->void:
 var game:Node=combat.adventure.game
 game._send_channel(game.host_id,{"type":"held_cast","match_id":game.match_id,"phase":phase,"kind":kind,"angle":aim.angle(),"target":combat.point_array(target)})
func packet(id:String,data:Dictionary)->void:
 if not combat.adventure.authoritative() or not combat.adventure.game.positions.has(id):return
 var game:Node=combat.adventure.game
 if not str(data.get("match_id",game.match_id)).is_empty() and str(data.get("match_id",game.match_id))!=game.match_id:return
 var phase:String=str(data.get("phase",""))
 if phase=="cancel":charges.erase(id);return
 var kind:String=str(data.get("kind",""))
 if kind not in ["primary","secondary","special"]:return
 var raw:Variant=data.get("target",[]);var angle:float=float(data.get("angle",0))
 if not raw is Array or raw.size()!=2 or not is_finite(angle):return
 var target:=Vector2(float(raw[0]),float(raw[1]))
 if not is_finite(target.x) or not is_finite(target.y):return
 var aim:=Vector2.from_angle(angle)
 if phase=="begin":begin(id,kind,aim,target)
 elif charges.has(id) and str(charges[id].kind)==kind:
  charges[id].aim=combat.point_array(aim);charges[id].target=combat.point_array(target);charges[id].last_seen=charges[id].age
  if phase=="release":release(id)
 if phase=="release":
  var deadline:int=int(game.cooldown_at.get(id,{}).get(kind,0))
  game._send_channel(id,{"type":"attack_ack","match_id":game.match_id,"style":kind,"remaining":maxi(0,deadline-Time.get_ticks_msec())})
func power(q:Dictionary,s:Dictionary)->float:
 var seconds:float=float(s.get("hold_charge",{}).get("seconds",0))
 return clampf(float(q.age)/seconds,0,1) if seconds>0 else 0.0
func effective(id:String,kind:String,s:Dictionary)->Dictionary:
 if not context.has(id) or str(context[id].kind)!=kind:return s
 var q:Dictionary=context[id];var cfg:Dictionary=s.get("hold_charge",{});var t:float=power(q,s)
 s["released_hold"]=true;s["charge_power"]=t
 if t>=.999:
  if float(cfg.get("full_stun",0))>0:s["stun_duration"]=float(cfg.full_stun)
  if str(s.get("style",""))=="grave_cleave":s["bleed_duration"]=3.0;s["bleed_damage"]=2.0
  if str(s.get("style",""))=="apiary_needle":s["stun_duration"]=1.25
  if str(s.get("style",""))=="oar_sweep":s["slow_duration"]=2.0;s["slow"]=.6;s["knockback"]=110.0
  if str(hero(id).get("id",""))=="stormscribe" and str(s.get("style",""))=="projectile":s["ball_lightning"]=true
 for prop in ["damage","speed"]:
  if cfg.has(prop):s[prop]=float(s.get(prop,0))*lerpf(1,float(cfg[prop]),t)
 s["projectile_radius"]=lerpf(6,6*float(cfg.get("size",1)),t)
 if cfg.has("blast"):s["blast_radius"]=float(s.get("blast_radius",85))*lerpf(1,float(cfg.blast),t)
 if cfg.has("splash"):
  s["splash_radius"]=float(s.get("splash_radius",75))*lerpf(1,float(cfg.splash),t)
  s["splash_damage"]=float(s.get("splash_damage",8))*lerpf(1,1.5,t)
 if str(s.get("style",""))=="tail_slap":
  s["stun_duration"]=1.2*lerpf(1,float(cfg.get("stun",1)),t);s["knockback"]=80*lerpf(1,float(cfg.get("knockback",1)),t)
 if bool(s.get("charged_cleave",false)):s["knockback"]=70*t
 return s
func target_point(id:String,q:Dictionary,s:Dictionary)->Vector2:
 var origin:Vector2=combat.owner_pos(id);var reach:float=float(s.get("range",500));var cfg:Dictionary=s.get("hold_charge",{})
 var aim:Vector2=combat.vec(q.aim)
 if bool(cfg.get("distance_charge",false)):return combat.v75.clip(origin,aim,lerpf(float(cfg.get("min_range",85)),reach,power(q,s)))
 var offset:Vector2=combat.vec(q.target)-origin
 return combat.v75.clip(origin,offset,minf(reach,offset.length()))
func release_point(id:String,reach:float)->Vector2:
 if context.has(id):return target_point(id,context[id],stats_for(id,str(context[id].kind)))
 return combat.owner_pos(id)+Vector2.RIGHT*reach
func release(id:String)->void:
 if not charges.has(id):return
 var q:Dictionary=charges[id];charges.erase(id)
 if bool(stats_for(id,str(q.kind)).get("held_channel",false)):return
 perform(id,q)
func perform(id:String,q:Dictionary)->void:
 if str(hero(id).get("id",""))!=str(q.hero) or not ready(id,str(q.kind)):return
 context[id]=q
 var game:Node=combat.adventure.game
 var s:Dictionary=stats_for(id,str(q.kind));var aim:Vector2=combat.vec(q.aim);var target:Vector2=target_point(id,q,s)
 if combat.adventure.arcade:game._attack(id,str(q.kind),aim,target)
 elif str(q.kind)=="special":game.pulse()
 else:game.fire(str(q.kind))
 context.erase(id)
func step(delta:float)->void:
 if combat.adventure.authoritative():
  for id in charges.keys():
   var q:Dictionary=charges[id];q.age=float(q.age)+combat.clock_delta(str(id),delta)
   if combat.adventure.arcade and str(id)!=str(combat.adventure.game.my_id) and float(q.age)-float(q.get("last_seen",0))>1.5:charges.erase(id);continue
   if bool(stats_for(str(id),str(q.kind)).get("held_channel",false)) and ready(str(id),str(q.kind)):perform(str(id),q)
   if not combat.playing() or not combat.adventure.alive(str(id)) or combat.stunned(combat.player_key(str(id))) or combat.busy(str(id)) or str(hero(str(id)).get("id",""))!=str(q.hero) or (float(q.age)>8 and not bool(stats_for(str(id),str(q.kind)).get("held_channel",false))):charges.erase(id)
 for n in range(flashes.size()-1,-1,-1):
  flashes[n].time=float(flashes[n].time)-delta
  if float(flashes[n].time)<=0:flashes.remove_at(n)
func cast(id:String,s:Dictionary,aim:Vector2,amount:float)->bool:
 if not bool(s.get("released_hold",false)) and str(s.get("style",""))!="mirror_fan":return false
 if str(s.get("style","")) in ["projectile","homing","mirror_fan"]:
  if not combat.adventure.authoritative():return true
  var count:int=3 if str(s.style)=="mirror_fan" else int(s.get("count",1))
  if str(s.style)=="homing" and combat.passive(id,"twin_orbs"):count=2
  var opts:Dictionary=s.duplicate(true)
  if str(s.style)=="mirror_fan":opts["mirror_shard"]=true;opts["pierce"]=2;opts["amplitude"]=0;opts["wavelength"]=180;opts["spread"]=.23
  if str(s.style)=="mirror_fan" and combat.passive(id,"clear_sight"):opts["slow_duration"]=2;opts["slow"]=.7
  volley(id,combat.owner_pos(id),aim,opts,amount,count)
  if str(s.style)=="mirror_fan" and combat.v59.copies.has(id) and not bool(combat.v59.copies[id].get("transferred",false)):volley(id,combat.vec(combat.v59.copies[id].pos),aim,opts,amount*.6,count)
  return true
 if bool(s.get("sky_comet",false)):
  var target:Vector2=release_point(id,float(s.get("range",300)))
  var opts:Dictionary=s.duplicate(true);opts["cast_visual"]="meteor"
  combat.adventure.launch_lob(id,target+Vector2(-55,-390),target,opts,amount);return true
 if bool(s.get("charged_cleave",false)):
  var origin:Vector2=combat.owner_pos(id);var reach:float=float(s.get("range",82));var arc:float=deg_to_rad(float(s.get("arc_degrees",70))*.5)
  for key in combat.hostile(id):
   var a:Dictionary=combat.actor(key)
   if a.is_empty() or not bool(a.get("alive",false)):continue
   var offset:Vector2=a.pos-origin
   if offset.length()<=reach+float(a.get("npc",{}).get("hit_radius",0)) and offset.normalized().dot(aim)>=cos(arc) and combat.path_clear(origin,a.pos):
    combat.damage(key,amount,id,str(s.get("name","Sword Cut")));combat.apply_hit_status(key,s,id)
    if float(s.get("knockback",0))>0:combat.knock(key,aim,float(s.knockback))
  if flashes.size()<24:flashes.append({"pos":combat.point_array(origin),"aim":combat.point_array(aim),"range":reach,"time":.22})
  return true
 return false
func volley(id:String,origin:Vector2,aim:Vector2,s:Dictionary,amount:float,count:int)->void:
 for n in count:
  var direction:Vector2=aim.rotated((n-(count-1)*.5)*float(s.get("spread",0)))
  combat.launch_projectile(id,origin+direction*26,direction,s,amount,"homing" if str(s.style)=="homing" else "corkscrew_key" if str(s.style)=="mirror_fan" else "plain")
func snapshot()->Dictionary:return {"charges":charges,"flashes":flashes}
func receive(data:Dictionary)->void:
 remote_preview=data.get("charges",{});flashes=data.get("flashes",[])
func clock_angle(q:Dictionary)->float:return float(q.age)*4
func draw_on(c:Node2D,camera:Vector2)->void:
 if not combat.playing():return
 var game:Node=combat.adventure.game;var local:String=str(game.my_id) if combat.adventure.arcade else "solo"
 var visible:Dictionary=remote_preview.duplicate();visible.merge(charges,true)
 if combat.adventure.arcade and game.role=="guest" and not charges.has(local):visible.erase(local)
 for id in visible:
  if not combat.adventure.alive(str(id)):continue
  var q:Dictionary=visible[id];var s:Dictionary=stats_for(str(id),str(q.kind));var t:float=power(q,s)
  var p:Vector2=combat.owner_pos(str(id))-camera;var aim:Vector2=combat.vec(q.aim);var tint:=Color(str(s.get("color","#ffe2a0")))
  c.draw_arc(p-Vector2(0,39),13,-PI*.5,-PI*.5+TAU*maxf(.01,t),24,tint,3,true)
  if float(s.get("travel_speed",0))>0 or str(s.get("style",""))=="rift_triangle":
   if str(id)==local and str(s.get("style",""))!="rift_triangle":
    var target:Vector2=target_point(str(id),q,s)-camera
    var radius:float=float(s.get("blast_radius",s.get("radius",70)))*lerpf(1,float(s.get("hold_charge",{}).get("blast",1)),t)
    c.draw_arc(target,radius,0,TAU,40,Color(tint,.65),2,true);c.draw_circle(target,4,tint)
  else:
   var r:float=lerpf(4,11,t);c.draw_circle(p+aim*26,r,Color(tint,.55))
  if str(hero(str(id)).get("id",""))=="apiary":
   var focus:=p+aim*30
   c.draw_circle(focus,7+12*t,Color(1,.7,.2,.18));c.draw_arc(focus,8+12*t,clock_angle(q),clock_angle(q)+TAU*.8,28,Color("#ffe394"),3,true)
   for n in 3:c.draw_circle(focus+Vector2.from_angle(clock_angle(q)+n*TAU/3)*(10+12*t),3,Color("#ffcc6d"))
  if str(hero(str(id)).get("id",""))=="golfer":
   var swing:Vector2=aim.rotated(-1.7*t-PI*.2)
   c.draw_line(p,p+swing*36,tint,3,true);c.draw_line(p+swing*36-swing.orthogonal()*6,p+swing*36+swing.orthogonal()*6,tint,5,true)
 for f in flashes:
  var p:Vector2=combat.vec(f.pos)-camera;var a:float=combat.vec(f.aim).angle();var t:float=1-float(f.time)/.22
  c.draw_arc(p,float(f.range),a-.65+t*.4,a+.1+t*.55,20,Color(1,.88,.6,1-t),4,true)
