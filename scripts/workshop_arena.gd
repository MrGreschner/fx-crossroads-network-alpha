extends Control
## Isolated educational runtime. Fixed caps; no game/profile/network access.
const Project=preload("res://scripts/workshop_project.gd")
var audio=preload("res://scripts/studio_audio.gd").new()
var project:Dictionary={}
var hero:Dictionary={}
var textures:Dictionary={}
var form_textures:Dictionary={}
var active_form=""
var form_left=0.0
var player=Vector2(180,270)
var aim=Vector2.RIGHT
var aim_point=Vector2(580,270)
var health:float=120
var ally_hp:float=50
var foes:Array=[]
var shots:Array=[]
var fields:Array=[]
var minions:Array=[]
var visuals:Array=[]
var cooldowns={"primary":0.0,"secondary":0.0,"special":0.0}
var casts={"primary":0,"secondary":0,"special":0}
var holds:Dictionary={}
var damage:float=0
var healing:float=0
var incoming:float=0
var hits:int=0
var status_hits:int=0
var time:float=0
var protection:float=0
var dodge_direction=Vector2.RIGHT
var taken_timer:float=0
var running:=false
var moving:=false
var attack_pose:float=0
var scenario:="Cluster"
var active_techniques:Array=[]
var locked_player:=false
var external:=false
var bounds=Rect2(0,0,900,540)
var passive_clock=0.0
var hit_callback:Callable
var heal_callback:Callable
var animation_cache:Dictionary={}
var cast_factor=0.0
var behavior_cache:Dictionary={}
var pending:Array=[]
var touch_direction=Vector2.ZERO
var preview_has_focus=false
var passive=preload("res://scripts/studio_passives.gd").new()
const Graphics=preload("res://scripts/studio_graphics.gd")
signal changed
func _ready()->void:
 add_child(audio)
 focus_mode=Control.FOCUS_ALL;mouse_filter=Control.MOUSE_FILTER_STOP;clip_contents=true;custom_minimum_size=Vector2(800,450)
func begin(p:Dictionary,variants:Array,scene:String)->void:
 project=p.duplicate(true);hero=p.hero.duplicate(true);active_techniques=variants.duplicate();scenario=scene
 for index in variants:
  var t:Dictionary=p.techniques[int(index)];hero[t.slot]=t.attack.duplicate(true)
 textures.clear();animation_cache.clear();behavior_cache.clear()
 for pose in hero.art:
  var image=Image.new()
  if image.load_png_from_buffer(Marshalls.base64_to_raw(hero.art[pose]))==OK:textures[pose]=ImageTexture.create_from_image(image)
 form_textures.clear()
 for id in hero.get("alternate_forms",{}):
  var img=Image.new()
  if img.load_png_from_buffer(Marshalls.base64_to_raw(hero.alternate_forms[id].image))==OK:form_textures[id]=ImageTexture.create_from_image(img)
 reset()
func reset()->void:
 active_form="";form_left=0
 player=Vector2(180,270);aim=Vector2.RIGHT;aim_point=Vector2(580,270);health=float(hero.get("max_health",120));ally_hp=50;damage=0;healing=0;incoming=0;hits=0;status_hits=0;time=0;protection=0;taken_timer=0;attack_pose=0;holds.clear();shots.clear();fields.clear();minions.clear();visuals.clear();foes.clear()
 for kind in Project.KINDS:cooldowns[kind]=0.0;casts[kind]=0
 for n in 5:
  foes.append({"pos":Vector2(490+(n%2)*65,170+n*43) if scenario=="Cluster" else Vector2(400+(n%3)*130,120+(n/3)*170),"hp":200.0,"slow":0.0,"stun":0.0,"dot":0.0,"dot_damage":0.0,"tick":0.0,"phase":float(n),"hits":0})
 pending.clear();passive.setup(self);passive_clock=0;running=true;changed.emit();queue_redraw()
func ability(kind:String)->Dictionary:return hero.get(kind,Project.attack())
func press(kind:String)->void:
 if not running or health<=0 or cooldowns[kind]>0 or holds.has(kind):return
 if ability(kind).style=="flame":holds[kind]={"age":0.0,"pulse":0.0};casts[kind]+=1
 elif float(ability(kind).charge)>0:holds[kind]={"age":0.0};cache_frames(ability(kind).get("charge_animation",[]))
 else:cast(kind)
func release(kind:String)->void:
 if not holds.has(kind):return
 var hold:Dictionary=holds[kind];holds.erase(kind)
 if ability(kind).style=="flame":cooldowns[kind]=float(ability(kind).cooldown)
 elif running:cast(kind,minf(1.0,float(hold.age)/maxf(.1,float(ability(kind).charge))))
func cancel_holds()->void:
 for kind in holds.keys():
  if ability(kind).style=="flame":cooldowns[kind]=float(ability(kind).cooldown)
 holds.clear()
func _notification(what:int)->void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:cancel_holds()
func _gui_input(event:InputEvent)->void:
 if not running:return
 if event is InputEventScreenTouch:
  if event.pressed:preview_has_focus=true;grab_focus();aim_point=(event.position-draw_offset())/scale_factor();aim=(aim_point-player).normalized();press("primary")
  else:release("primary")
  accept_event();return
 if event is InputEventScreenDrag:aim_point=(event.position-draw_offset())/scale_factor();aim=(aim_point-player).normalized();accept_event();return
 if event is InputEventMouseButton and event.device==-1:return
 if event is InputEventMouseMotion:aim_point=(event.position-draw_offset())/scale_factor();aim=(aim_point-player).normalized()
 if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_LEFT,MOUSE_BUTTON_RIGHT]:
  var kind="primary" if event.button_index==MOUSE_BUTTON_LEFT else "secondary"
  preview_has_focus=true;grab_focus()
  if event.pressed:press(kind)
  else:release(kind)
  accept_event()
func _input(event:InputEvent)->void:
 if not running or not is_visible_in_tree():return
 if event is InputEventKey and not event.echo and event.keycode==KEY_SPACE and get_viewport().gui_get_focus_owner()==self:
  if event.pressed:press("special")
  else:release("special")
  get_viewport().set_input_as_handled()
 # Release outside the arena still ends a held attack.
 if event is InputEventMouseButton and not event.pressed:
  if event.button_index==MOUSE_BUTTON_LEFT:release("primary")
  if event.button_index==MOUSE_BUTTON_RIGHT:release("secondary")
func world_mouse()->Vector2:return aim_point
func scale_factor()->Vector2:return Vector2.ONE*maxf(.1,minf(size.x/900,size.y/540))
func draw_offset()->Vector2:return (size-Vector2(900,540)*scale_factor())*.5
func valid_target(n:int)->bool:return n>=0 and n<foes.size() and foes[n].hp>0
func closest(origin:Vector2,reach:float,skip:Array=[])->int:
 var index=-1;var best=reach
 for n in foes.size():
  if not valid_target(n) or n in skip:continue
  var distance=origin.distance_to(foes[n].pos)
  if distance<best:index=n;best=distance
 return index
func hurt(index:int,a:Dictionary,multiplier:float=1.0)->void:
 if not valid_target(index):return
 var f:Dictionary=foes[index];var dealt=minf(float(f.hp),float(a.damage)*multiplier*passive.damage_multiplier(a,f)*buff_power(a.get("attack_origin",player)))
 if float(a.get("knockback",0))>0:f.pos+=(f.pos-player).normalized()*float(a.knockback)
 f.hp-=dealt;damage+=dealt;hits+=1;f.hits+=1
 if hit_callback.is_valid():hit_callback.call(index,dealt,a)
 if hero.passive=="lifesteal":restore(dealt*.08)
 if float(a.get("lifesteal",0))>0:restore(dealt*float(a.lifesteal)/100)
 if hero.passive=="critical" and randf()<.08:
  var extra=minf(float(f.hp),dealt*.3);f.hp-=extra;damage+=extra
  if hit_callback.is_valid():hit_callback.call(index,extra,a)
 if f.hp<=0:passive.defeated()
 if hero.passive in ["burn_touch","poison_touch","slow_touch"]:
  if hero.passive=="slow_touch":f.slow=maxf(float(f.slow),1.5)
  else:f.dot=maxf(float(f.dot),2);f.dot_damage=1.0
 if a.status!="none":
  status_hits+=1
  if a.status in ["slow","stun"]:f[a.status]=maxf(float(f[a.status]),float(a.status_duration))
  else:f.dot=maxf(float(f.dot),float(a.status_duration));f.dot_damage=float(a.status_damage)
 flash(f.pos,16,Color(a.color),.16)
func restore(amount:float)->void:
 var gain=minf(amount*passive.heal_multiplier(),maxf(0,float(hero.max_health)-health));health+=gain;healing+=gain
 if heal_callback.is_valid():heal_callback.call(gain)
func pulse(origin:Vector2,a:Dictionary,cone:bool=false,multiplier:float=1.0)->void:
 var reach=float(a.range) if cone else float(a.radius)
 var arc=deg_to_rad(float(a.get("melee_arc",100)))*.5
 for n in foes.size():
  var offset:Vector2=foes[n].pos-origin
  if offset.length()<=reach+14 and (not cone or float(a.get("melee_arc",100))>=359 or aim.dot(offset.normalized())>=cos(arc)):hurt(n,a,multiplier)
 if float(a.heal)>0 and a.has("category"):
  if cone:
   var copy=a.duplicate(true);copy.radius=reach
   var ally_offset=Vector2(280,370)-origin
   if not external and ally_offset.length()<=reach and (float(a.get("melee_arc",100))>=359 or aim.dot(ally_offset.normalized())>=cos(arc)):var gain=minf(float(a.heal),200-ally_hp);ally_hp+=gain;healing+=gain
   for m in minions:
    var offset:Vector2=m.pos-origin
    if offset.length()<=reach and (float(a.get("melee_arc",100))>=359 or aim.dot(offset.normalized())>=cos(arc)):m.hp=minf(float(m.get("max_hp",40)),m.hp+float(a.heal))
  else:heal_at(origin,a)
func flash(origin:Vector2,radius:float,tint:Color,duration:float=.35)->void:
 if visuals.size()>=40:visuals.pop_front()
 add_visual({"pos":origin,"radius":radius,"color":tint,"life":duration,"total":duration})
func cast(kind:String,factor:float=0.0)->void:
 if not running or health<=0 or cooldowns[kind]>0:return
 var a:Dictionary=ability(kind).duplicate(true);preload("res://scripts/studio_charge.gd").apply(a,factor)
 if hero.passive=="mendersgift" and a.style!="custom":a.heal*=1.2
 cooldowns[kind]=float(a.cooldown)*passive.cooldown(kind,a)*(.85 if kind=="primary" and hero.passive=="quick_primary" else 1.0);casts[kind]+=1;attack_pose=.25
 activate_form(a)
 cast_factor=factor
 var target=world_mouse()
 if a.get("category")=="control" and a.get("target_mode")=="direction":target=player+aim*float(a.range)
 target=player+(target-player).limit_length(float(a.range));target=target.clamp(bounds.position+Vector2(25,25),bounds.end-Vector2(25,25))
 if not audio.is_inside_tree():add_child(audio)
 audio.play_sound(a.get("sound",{}))
 execute_attack(a,target);passive.cast()
 changed.emit();queue_redraw()
func execute_attack(a:Dictionary,target:Vector2)->void:
 match str(a.style):
  "melee":
   var delay=.0 if a.get("melee_visual","swing")=="instant" else .2 if a.get("melee_visual")=="pulse" else .12
   if delay==0:pulse(player,a,true)
   elif pending.size()<32:pending.append({"age":delay,"origin":player,"aim":aim,"ability":a})
   if visuals.size()<40:add_visual({"pos":player,"aim":aim,"ability":a,"life":.35,"total":.35,"color":Color(a.color),"radius":float(a.range),"shape":"melee"})
  "spin":pulse(player,a);flash(player,float(a.radius),Color(a.color))
  "projectile","spread","homing","boomerang":
   var count=int(a.count) if a.style=="spread" else 1
   for n in count:
    var direction=aim.rotated(deg_to_rad((float(n)-(count-1)*.5)*float(a.get("spread",24))/maxf(1,count-1)));spawn_shot(player,direction,a)
  "beam":
   var end=player+aim*float(a.range)
   for n in foes.size():
    if Geometry2D.get_closest_point_to_segment(foes[n].pos,player,end).distance_to(foes[n].pos)<float(a.radius)*.25+14:hurt(n,a)
   add_visual({"pos":player,"end":end,"life":.4,"total":.4,"color":Color(a.color),"radius":float(a.radius)*.25,"shape":"beam"})
  "chain":
   var origin=player;var visited:Array=[]
   for n in int(a.count):
    var index=closest(origin,float(a.range),visited)
    if index<0:break
    visited.append(index);add_visual({"pos":origin,"end":foes[index].pos,"life":.5,"total":.5,"color":Color(a.color),"radius":3.0,"shape":"beam"});hurt(index,a);origin=foes[index].pos
  "target_aoe":spawn_shot(player,(target-player).normalized(),a,target)
  "trap":add_field(target,a,"trap")
  "heal_wave":heal_at(player,a);flash(player,float(a.radius),Color("#98f0ac"))
  "heal_zone":add_field(target,a,"heal")
  "slow_aura":add_field(target,a,"slow")
  "block":protection=float(a.duration);flash(player,40,Color("#b8d4ed"),float(a.duration))
  "dash":
   var end=target
   for n in foes.size():
    if Geometry2D.get_closest_point_to_segment(foes[n].pos,player,end).distance_to(foes[n].pos)<30:hurt(n,a)
   add_visual({"pos":player,"end":end,"life":.4,"total":.4,"color":Color(a.color),"radius":9.0,"shape":"beam"});player=end
  "summon":
   for n in int(a.count):
    if minions.size()>=5:break
    minions.append({"pos":player+Vector2(36,0).rotated(n*TAU/maxi(1,int(a.count))),"life":float(a.duration)*(1.3 if hero.passive=="summoner" else 1.0),"timer":0.0,"hp":float(a.get("minion_health",40))*(1.2 if hero.passive=="packvitality" else 1.0),"max_hp":float(a.get("minion_health",40))*(1.2 if hero.passive=="packvitality" else 1.0),"ability":a})
  "flame":pulse(player,a,true,.2)
  "custom":
   var compiled=preload("res://scripts/studio_script.gd").compile(str(a.program))
   if compiled.error.is_empty():
    var actions=preload("res://scripts/studio_script.gd").actions(compiled.instructions,cast_factor>=.75,closest(player,600)>=0,0,[],int(a.count))
    if str(a.program).begins_with("# @structured"):
     var data=preload("res://scripts/structured_program.gd").sample_inputs(mini(12,foes.size()));data.base_damage=float(a.damage);data.jump_limit=int(a.count);data.reach=float(a.range)
     for n in int(data.target_count):data.distances[n]=player.distance_to(foes[n].pos) if valid_target(n) else 1000000;data.shields[n]=bool(foes[n].get("shield",false))
     var run=preload("res://scripts/structured_program.gd").run(str(a.program),data)
     actions=run.actions if run.error.is_empty() else []
    var original_aim=aim;var chain_origin=player
    for action in actions:
     var copy=a.duplicate(true);copy.erase("program")
     for key in compiled.variables:
      if copy.has(key):copy[key]=compiled.variables[key]
     for key in action.get("stats",{}):
      if copy.has(key):copy[key]=clampf(float(action.stats[key]),float(preload("res://scripts/studio_script.gd").VARIABLES[key][0]),minf(float(a.get(key,preload("res://scripts/studio_script.gd").VARIABLES[key][1])),float(preload("res://scripts/studio_script.gd").VARIABLES[key][1])))
     if action.command=="zap":
      var n=int(action.target)
      if valid_target(n) and player.distance_to(foes[n].pos)<=float(a.range):
       var from=chain_origin;chain_origin=foes[n].pos
       if visuals.size()<40:add_visual({"pos":from,"end":foes[n].pos,"life":.5,"total":.5,"color":Color(a.color),"radius":3,"shape":"beam"})
       hurt(n,copy)
      continue
     if hero.passive=="mendersgift":copy.heal*=1.2
     preload("res://scripts/studio_charge.gd").apply(copy,cast_factor)
     copy.style={"pulse":"spin","field":"poison_zone","heal":"heal_wave","lob":"target_aoe","healing_field":"heal_zone","slow_field":"slow_aura","burn_field":"burn_zone","stun_field":"stun_zone","buff_field":"buff_zone","mine":"trap","protect":"block"}.get(action.command,action.command)
     aim=original_aim.rotated(deg_to_rad(float(action.angle)));execute_attack(copy,target)
    aim=original_aim
  "burst":
   for n in int(a.count):
    var copy=a.duplicate(true);copy.style="projectile";spawn_shot(player-aim*n*14,aim,copy)
  "ring_shots":
   for n in int(a.count):
    var copy=a.duplicate(true);copy.style="projectile";spawn_shot(player,aim.rotated(n*TAU/int(a.count)),copy)
  "vortex":add_field(target,a,"vortex")
  "poison_zone":add_field(target,a,"poison")
  "burn_zone":add_field(target,a,"burn")
  "stun_zone":add_field(target,a,"stun")
  "buff_zone":add_field(target,a,"buff")
  "blink":flash(player,30,Color(a.color));player=target;pulse(player,a);flash(player,float(a.radius),Color(a.color))
  "siphon":
   var before=damage;pulse(player,a,true);restore((damage-before)*.2)
 if a.style!="custom" and a.has("animation") and not a.animation.is_empty() and not (a.has("melee_visual") and a.get("category")=="melee" and a.melee_visual!="custom") and not (a.has("projectile_graphic") and a.get("category")=="ranged"):
  var key=JSON.stringify(a.animation).sha256_text()
  if not animation_cache.has(key):
   var frames:Array=[]
   for encoded in a.animation:
    var img=Image.new()
    if img.load_png_from_buffer(Marshalls.base64_to_raw(encoded))==OK:frames.append(ImageTexture.create_from_image(img))
   animation_cache[key]=frames
  if visuals.size()<40:add_visual({"pos":target if a.style in ["poison_zone","vortex","target_aoe","trap"] else player+aim*minf(float(a.range),100),"life":.125*a.animation.size(),"total":.125*a.animation.size(),"animation":key,"color":Color(a.color),"radius":float(a.radius)})
func spawn_shot(origin:Vector2,direction:Vector2,a:Dictionary,target:Vector2=Vector2(-1,-1))->void:
 if shots.size()>=60:return
 cache_animation(a)
 var copy=a.duplicate(true)
 if a.has("behavior"):
  var key=str(a.behavior.program).sha256_text()
  if not behavior_cache.has(key):
   if behavior_cache.size()>40:behavior_cache.clear()
   behavior_cache[key]=preload("res://scripts/studio_behavior.gd").compile(a.behavior.program,"ability")
  var nearest=closest(origin,700);var context={"distance":origin.distance_to(foes[nearest].pos) if nearest>=0 else 999,"health":health/float(hero.max_health)*100,"time":time,"charged":1 if float(a.get("charged",0))>=.75 else 0,"targets":1 if nearest>=0 else 0}
  for action in preload("res://scripts/studio_behavior.gd").evaluate(behavior_cache[key],context):
   if action.command=="flight":copy.projectile_motion=action.value
   elif action.command=="impact":copy.impact_burst=action.value=="burst"
   elif action.command=="aim":
    if action.value=="nearest" and nearest>=0:direction=(foes[nearest].pos-origin).normalized()
    elif action.value!="nearest":copy.target_mode=action.value
 if a.style in ["projectile","spread","burst","ring_shots"]:
  if copy.get("projectile_motion")=="lob":copy.style="target_aoe"
  elif copy.get("projectile_motion")=="homing":copy.style="homing"
  elif copy.get("projectile_motion")=="return":copy.style="boomerang"
 if target==Vector2(-1,-1) and (copy.style=="target_aoe" or copy.get("target_mode")=="cursor"):
  var distance=player.distance_to(world_mouse()) if copy.get("target_mode")=="cursor" else float(a.range)
  target=origin+direction*minf(float(a.range),maxf(8,distance))
 shots.append({"pos":origin,"origin":origin,"direction":direction,"base_direction":direction,"ability":copy,"distance":0.0,"life":5.0,"target":target,"returning":false,"hit":[],"hostile":false})

func add_field(origin:Vector2,a:Dictionary,kind:String)->void:
 if fields.size()>=16:fields.pop_front()
 fields.append({"pos":origin,"ability":a,"kind":kind,"life":float(a.duration),"timer":0.0})
func heal_at(origin:Vector2,a:Dictionary)->void:
 if origin.distance_to(player)<=float(a.radius):restore(float(a.heal))
 for m in minions:
  if origin.distance_to(m.pos)<=float(a.radius):m.hp=minf(float(m.get("max_hp",40)),m.hp+float(a.heal))
 if not external and origin.distance_to(Vector2(280,370))<=float(a.radius):
  var gain=minf(float(a.heal),200-ally_hp);ally_hp+=gain;healing+=gain
func _process(delta:float)->void:
 if not running or not is_visible_in_tree():return
 tick(minf(delta,.05))
func tick(delta:float)->void:
 form_left=maxf(0,form_left-delta)
 if form_left<=0:active_form=""
 for slot in holds:
  if ability(slot).style=="flame":activate_form(ability(slot))
 time+=delta;protection=maxf(0,protection-delta);attack_pose=maxf(0,attack_pose-delta)
 var input=touch_direction
 var focus=get_viewport().gui_get_focus_owner()
 if not external and not focus is TextEdit and not focus is LineEdit:
  input+=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
 input=input.normalized()
 if not external:moving=not input.is_zero_approx() and not locked_player
 if moving and not external:player=(player+input*float(hero.speed)*delta*(1.08 if hero.passive=="swift" else 1.0)*buff_speed()).clamp(Vector2(25,25),Vector2(875,515))
 passive.tick(delta)
 for n in range(pending.size()-1,-1,-1):
  pending[n].age-=delta
  if pending[n].age<=0:
   var strike=pending[n];var old_aim=aim;aim=strike.aim;pulse(strike.origin,strike.ability,true);aim=old_aim;pending.remove_at(n)
 if hero.passive=="regeneration":restore(delta)
 if hero.passive=="mending":
  restore(delta)
  if hero.get("passive_aura",false) and player.distance_to(Vector2(280,370))<float(hero.get("passive_radius",100)):ally_hp=minf(200,ally_hp+delta)
 if hero.passive=="frost":
  var reach=float(hero.get("passive_radius",100)) if hero.get("passive_aura",false) else 45.0
  for f in foes:
   if f.pos.distance_to(player)<reach:f.slow=maxf(float(f.slow),.3)
 passive_clock+=delta
 if hero.passive=="overload" and passive_clock>=6:
  passive_clock=0;var a=Project.attack("spin");a.damage=5;a.radius=float(hero.get("passive_radius",100));pulse(player,a);flash(player,float(a.radius),Color(a.color))
 for kind in Project.KINDS:cooldowns[kind]=maxf(0,float(cooldowns[kind])-delta)
 for kind in holds:
  holds[kind].age+=delta
  if ability(kind).style=="flame":
   holds[kind].pulse+=delta
   if holds[kind].pulse>=.2:holds[kind].pulse=0;pulse(player,ability(kind),true,.2);attack_pose=.22
 for f in foes:
  f.slow=maxf(0,float(f.slow)-delta);f.stun=maxf(0,float(f.stun)-delta)
  if not external and f.hp>0 and f.dot>0:
   var amount=minf(float(f.hp),float(f.dot_damage)*minf(delta,float(f.dot)));f.hp-=amount;damage+=amount;f.dot=maxf(0,float(f.dot)-delta)
  if not external and scenario=="Moving targets" and f.hp>0 and f.stun<=0:f.pos.y=270+sin(time*(.7 if f.slow<=0 else .35)+f.phase)*150
  if not external and scenario=="Combat" and f.hp>0:
   if f.stun<=0:f.pos+=(player-f.pos).normalized()*55*delta*(.55 if f.slow>0 else 1.0)
   f.tick-=delta
   if f.tick<=0 and f.stun<=0:
    f.tick=2.0
    if f.pos.distance_to(player)<40:take_hit(8)
    else:
     if shots.size()<60:shots.append({"pos":f.pos,"direction":(player-f.pos).normalized(),"ability":{"damage":6.0,"speed":150.0,"color":"#ef9c7a","style":"hostile"},"distance":0.0,"life":4.0,"target":Vector2(-1,-1),"returning":false,"hit":[],"hostile":true})
 for n in range(shots.size()-1,-1,-1):
  var shot:Dictionary=shots[n];var a:Dictionary=shot.ability;var old:Vector2=shot.pos;shot.life-=delta
  if a.style=="homing":
   var index=closest(shot.pos,600)
   if index>=0:shot.direction=shot.direction.lerp((foes[index].pos-shot.pos).normalized(),minf(1,delta*4)).normalized()
  if a.style=="boomerang" and shot.distance>=float(a.range) and not shot.returning:shot.returning=true;shot.hit.clear()
  if shot.returning:shot.direction=(player-shot.pos).normalized()
  var travel=float(a.speed)*delta;shot.pos+=shot.direction*travel;shot.distance+=travel
  if a.get("projectile_motion")=="wave" and not shot.returning:
   shot.pos=shot.origin+shot.base_direction*shot.distance+Vector2(-shot.base_direction.y,shot.base_direction.x)*sin(shot.distance/35)*18
  var remove=shot.life<=0 or not bounds.has_point(shot.pos)
  if shot.hostile:
   if Geometry2D.get_closest_point_to_segment(player,old,shot.pos).distance_to(player)<22:take_hit(float(a.damage));remove=true
  elif a.style=="target_aoe":
   if old.distance_to(shot.target)<=travel:
    pulse(shot.target,a);flash(shot.target,float(a.radius),Color(a.color));remove=true
  else:
   if not external and float(a.get("heal",0))>0 and Geometry2D.get_closest_point_to_segment(Vector2(280,370),old,shot.pos).distance_to(Vector2(280,370))<20:heal_at(Vector2(280,370),a);remove=true
   for index in foes.size():
    if remove or index in shot.hit or not valid_target(index):continue
    if Geometry2D.get_closest_point_to_segment(foes[index].pos,old,shot.pos).distance_to(foes[index].pos)<20*(1+float(a.get("charge_size",0))):
     hurt(index,a);shot.hit.append(index)
     if a.style!="boomerang":remove=true;break
   if a.style=="boomerang":
    if shot.returning and player.distance_to(shot.pos)<22:remove=true
   elif shot.distance>=float(a.range):remove=true
   if shot.target!=Vector2(-1,-1) and shot.distance>=shot.origin.distance_to(shot.target):remove=true
   if remove and a.get("impact_burst",false):pulse(shot.pos,a);flash(shot.pos,float(a.radius),Color(a.color))
  if remove:shots.remove_at(n)
 for n in range(fields.size()-1,-1,-1):
  var f:Dictionary=fields[n];var a:Dictionary=f.ability;f.life-=delta;f.timer-=delta
  if f.life<=0:fields.remove_at(n);continue
  if f.kind=="trap" and closest(f.pos,float(a.radius))>=0:pulse(f.pos,a);flash(f.pos,float(a.radius),Color(a.color));f.life=0
  elif f.timer<=0:
   f.timer=.5
   if f.kind=="heal":heal_at(f.pos,a)
   if f.kind in ["poison","vortex","burn","stun","slow"]:
    var copy=a.duplicate(true);copy.status="poison" if f.kind=="poison" else "burn" if f.kind=="burn" else "stun" if f.kind=="stun" else "slow";pulse(f.pos,copy,false,.2)
  if f.kind=="vortex":
   for foe in foes:
    if foe.hp>0 and foe.pos.distance_to(f.pos)<float(a.radius):foe.pos+=(f.pos-foe.pos).normalized()*70*delta

  if f.life<=0:fields.remove_at(n)
 for n in range(minions.size()-1,-1,-1):
  var m:Dictionary=minions[n];m.life-=delta;m.timer-=delta;var index=closest(m.pos,650);var style=str(m.ability.get("minion_attack","melee"))
  var speed=float(m.ability.get("minion_speed",120))*(1.2 if hero.passive=="packhaste" else 1.0)*buff_speed(m.pos)
  if style=="heal":
   if m.pos.distance_to(player)>65:m.pos+=(player-m.pos).normalized()*speed*delta
   if m.timer<=0:
    var a=m.ability.duplicate(true);a.radius=maxf(70,float(a.radius));heal_at(m.pos,a);m.timer=float(a.get("minion_interval",1))
  elif index>=0:
   var reach=200.0 if style=="projectile" else 32.0
   if m.pos.distance_to(foes[index].pos)>reach*.8:m.pos+=(foes[index].pos-m.pos).normalized()*speed*delta
   if m.pos.distance_to(foes[index].pos)<reach and m.timer<=0:
    var a=m.ability.duplicate(true);a.damage*=1.15 if hero.passive=="packfury" else 1.0;a.minion_attack_cast=true;a.attack_origin=m.pos
    if style=="projectile":a.style="projectile";a.projectile_motion="straight";spawn_shot(m.pos,(foes[index].pos-m.pos).normalized(),a)
    else:hurt(index,a)
    m.timer=float(a.get("minion_interval",1))
   if not external and scenario=="Combat" and m.pos.distance_to(foes[index].pos)<40:m.hp-=delta*8*(1-buff_reduction(m.pos))
  if m.life<=0 or m.hp<=0:minions.remove_at(n)
 for n in range(visuals.size()-1,-1,-1):
  visuals[n].life-=delta
  if visuals[n].life<=0:visuals.remove_at(n)
 if health<=0:running=false;cancel_holds();changed.emit()
 queue_redraw()
func take_hit(amount:float)->void:
 var reduction=maxf(float(hero.get("defence",0)),maxf(maxf(.6 if protection>0 else .1 if hero.passive in ["defence","shelter"] else 0.0,passive.reduction()),buff_reduction(player)))
 var actual=minf(health,amount*(1-reduction));health-=actual;incoming+=actual
 passive.received()
 if hero.passive=="thorns":
  var index=closest(player,55)
  if index>=0:
   var a=Project.attack();a.damage=actual*.15;hurt(index,a)
func report(notes:Dictionary)->Dictionary:
 return {"format":"fx-crossroads-test-report","schema_version":1,"project_id":project.project_id,"revision":project.revision,"project_hash":Project.fingerprint(project),"hero":hero.name,"author":project.author,"tested_build":{"primary":hero.primary.duplicate(true),"secondary":hero.secondary.duplicate(true),"special":hero.special.duplicate(true),"passive":hero.passive,"max_health":hero.max_health,"speed":hero.speed},"date_utc":Time.get_datetime_string_from_system(true),"scenario":scenario,"techniques":active_techniques.duplicate(),"seconds":snappedf(time,.01),"casts":casts.duplicate(),"damage":snappedf(damage,.01),"healing":snappedf(healing,.01),"damage_taken":snappedf(incoming,.01),"hits":hits,"status_applications":status_hits,"dps":snappedf(damage/maxf(.01,time),.01),"targets_defeated":foes.filter(func(f):return f.hp<=0).size(),"notes":notes.duplicate(true),"runtime":"workshop-1","limits":{"projectiles":60,"fields":16,"minions":5},"scope":"Synthetic workshop arena; not a public match or proof of balance."}
func _draw()->void:
 if hero.is_empty():return
 draw_set_transform(draw_offset(),0,scale_factor())
 draw_rect(Rect2(0,0,900,540),Color("#152f36"))
 for x in range(0,901,45):draw_line(Vector2(x,0),Vector2(x,540),Color(.5,.8,.8,.06))
 for y in range(0,541,45):draw_line(Vector2(0,y),Vector2(900,y),Color(.5,.8,.8,.06))
 for f in fields:
  var tint=Color(f.ability.color);tint.a=.2;draw_circle(f.pos,float(f.ability.radius),tint);draw_arc(f.pos,float(f.ability.radius),0,TAU,32,Color(f.ability.color),2)
 for f in foes:
  var tint=Color("#b98776") if f.hp>0 else Color("#46575a")
  draw_circle(f.pos,16,tint);draw_rect(Rect2(f.pos+Vector2(-22,-30),Vector2(44,4)),Color("#253138"));draw_rect(Rect2(f.pos+Vector2(-22,-30),Vector2(44*clampf(f.hp/float(f.get("max_hp",200)),0,1),4)),Color("#efab79"))
  if f.slow>0:draw_circle(f.pos+Vector2(-10,-40),4,Color("#74bff3"))
  if f.stun>0:draw_circle(f.pos+Vector2(0,-40),4,Color.WHITE)
  if f.dot>0:draw_circle(f.pos+Vector2(10,-40),4,Color("#c294de"))
 var ally=Vector2(280,370);draw_circle(ally,18,Color("#82c39b"));draw_string(ThemeDB.fallback_font,ally+Vector2(-30,38),"Ally "+str(int(ally_hp)),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
 for m in minions:
  draw_minion(self,m,Vector2.ZERO);draw_arc(m.pos,18,0,TAU*clampf(m.hp/float(m.get("max_hp",40)),0,1),16,Color("#a6e2b7"),2)
 for shot in shots:
  var point:Vector2=shot.pos
  if shot.ability.style=="target_aoe":
   var progress=clampf(float(shot.distance)/maxf(1.0,(shot.target-shot.origin).length()),0,1);point+=Vector2(0,-sin(progress*PI)*60)
   draw_circle(shot.pos,6,Color(0,0,0,.25));draw_arc(shot.target,float(shot.ability.radius),0,TAU,28,Color(.7,.8,.7,.2),1)
  var animation_key=JSON.stringify(shot.ability.get("animation",[])).sha256_text()
  var frames:Array=animation_cache.get(animation_key,[]) if not shot.ability.has("projectile_graphic") or shot.ability.projectile_graphic=="custom" else []
  if not frames.is_empty():draw_texture_rect(frames[int((5-float(shot.life))*8)%frames.size()],Rect2(point-Vector2.ONE*18,Vector2.ONE*36),false)
  else:Graphics.shot(self,point,shot.direction,shot.ability,1+float(shot.ability.get("charge_size",float(shot.ability.get("charged",0))*.5)))
 for v in visuals:
  if v.has("animation"):
   var frames:Array=animation_cache.get(v.animation,[])
   if not frames.is_empty():draw_texture_rect(frames[mini(frames.size()-1,int((v.total-v.life)/.125))],Rect2(v.pos-Vector2.ONE*32,Vector2.ONE*64),false)
   continue
  if v.get("shape")=="melee":Graphics.strike(self,v,Vector2.ZERO);continue
  var tint:Color=v.color;tint.a=clampf(float(v.life)/float(v.total),0,1)
  if v.has("end"):
   if v.get("shape")=="sweep":
    var direction:Vector2=(v.end-v.pos).normalized();var angle=direction.angle();draw_arc(v.pos,v.pos.distance_to(v.end),angle-.85,angle+.85,24,tint,4,true)
   else:draw_line(v.pos,v.end,tint,float(v.radius),true)
  else:draw_arc(v.pos,float(v.radius)*(1-float(v.life)/float(v.total)*.3),0,TAU,32,tint,3,true)
 if hero.get("passive_aura",false):draw_arc(player,float(hero.get("passive_radius",100)),0,TAU,32,Color(.6,.8,.95,.22),2)
 if protection>0 or hero.passive in ["defence","shelter"]:draw_arc(player,31,0,TAU,32,Color(.7,.8,.85,.4+.1*sin(time*3)),2)
 draw_circle(player+Vector2(0,21),22,Color(0,0,0,.3))
 var pose="attack" if attack_pose>0 else "walk1" if moving and int(time*8)%2==0 else "walk2" if moving else "idle"
 var texture:Texture2D=form_textures.get(active_form,textures.get(pose,textures.get("idle")))
 if texture!=null:draw_texture_rect(texture,Rect2(player-Vector2(28,42),Vector2(56,64)),false)
 else:
  draw_circle(player,21,Color("#87dbe1"));draw_circle(player+aim*12,6,Color("#fff1ae"));draw_line(player+Vector2(-12,20),player+Vector2(-12,26+sin(time*8)*4 if moving else 26),Color("#85bcc8"),5)
 draw_aim(self,Vector2.ZERO)
 for kind in holds:
  var a=ability(kind);var age=float(holds[kind].age);var ratio=clampf(age/maxf(.1,float(a.charge)),0,1)
  Graphics.charge(self,player,aim,a,ratio,time)
  var frames:Array=animation_cache.get(JSON.stringify(a.get("charge_animation",[])).sha256_text(),[]) if a.get("charge_visual")=="custom" else []
  if not frames.is_empty():draw_texture_rect(frames[int(time*8)%frames.size()],Rect2(player-Vector2.ONE*35,Vector2.ONE*70),false)
  if a.style=="flame":draw_colored_polygon(PackedVector2Array([player,player+aim.rotated(-.65)*float(a.range),player+aim.rotated(.65)*float(a.range)]),Color(Color(a.color),.2))
  if a.style in ["target_aoe","trap","heal_zone","slow_aura"]:draw_arc(player+(world_mouse()-player).limit_length(float(a.range)),float(a.radius),0,TAU,32,Color(a.color),2)
 draw_rect(Rect2(20,18,190,10),Color("#293e44"));draw_rect(Rect2(20,18,190*health/float(hero.max_health),10),Color("#8cdbb3"))
 draw_string(ThemeDB.fallback_font,Vector2(20,48),str(int(health))+" HP  •  "+str(int(time))+"s  •  DR "+str(int(100*maxf(maxf(.6 if protection>0 else .1 if hero.passive in ["defence","shelter"] else 0,passive.reduction()),buff_reduction(player))))+"%",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color.WHITE)
 draw_string(ThemeDB.fallback_font,Vector2(20,522),"WORKSHOP TEST • no profile progress",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ecd393"))

func cache_animation(a:Dictionary)->void:
 if not a.has("animation") or a.animation.is_empty():return
 var key=JSON.stringify(a.animation).sha256_text()
 if animation_cache.has(key):return
 if animation_cache.size()>=40:animation_cache.clear()
 var frames:Array=[]
 for encoded in a.animation:
  var image=Image.new()
  if image.load_png_from_buffer(Marshalls.base64_to_raw(encoded))==OK:frames.append(ImageTexture.create_from_image(image))
 animation_cache[key]=frames

func buff_power(at:Vector2=Vector2(INF,INF))->float:
 if at==Vector2(INF,INF):at=player
 for f in fields:
  if f.kind=="buff" and f.ability.get("buff","defence")=="power" and at.distance_to(f.pos)<float(f.ability.radius):return 1.1
 return 1.0
func buff_speed(at:Vector2=Vector2(INF,INF))->float:
 if at==Vector2(INF,INF):at=player
 for f in fields:
  if f.kind=="buff" and f.ability.get("buff","defence")=="haste" and at.distance_to(f.pos)<float(f.ability.radius):return 1.15
 return 1.0
func buff_reduction(at:Vector2)->float:
 for f in fields:
  if f.kind=="buff" and f.ability.get("buff","defence")=="defence" and at.distance_to(f.pos)<float(f.ability.radius):return .15
 return 0.0
func cache_frames(encoded:Array)->void:
 if encoded.is_empty():return
 cache_animation({"animation":encoded})
func draw_minion(canvas:CanvasItem,m:Dictionary,camera:Vector2)->void:
 var encoded=str(m.ability.get("minion_image",""));var key=encoded.sha256_text()
 if m.ability.get("minion_graphic")=="custom" and not encoded.is_empty():
  if not animation_cache.has(key):
   var image=Image.new()
   if image.load_png_from_buffer(Marshalls.base64_to_raw(encoded))==OK:animation_cache[key]=[ImageTexture.create_from_image(image)]
  if animation_cache.has(key):canvas.draw_texture_rect(animation_cache[key][0],Rect2(m.pos-camera-Vector2(18,28),Vector2(36,40)),false)
 else:Graphics.minion(canvas,m.pos-camera,m,time)

func draw_aim(canvas:CanvasItem,camera:Vector2)->void:
 var a=ability("primary");var p=player-camera;var guide=str(a.get("aim_guide","line"));var color=Color(a.color,.35)
 if guide=="line":canvas.draw_line(p,p+aim*minf(float(a.range),200),color,1)
 elif guide=="reticle":canvas.draw_arc(world_mouse()-camera,12,0,TAU,24,color,2)
 elif guide=="cone":
  var half=deg_to_rad(float(a.get("melee_arc",100))*.5 if a.get("category")=="melee" else float(a.get("spread",24))*.5)
  canvas.draw_arc(p,minf(200,float(a.range)),aim.angle()-half,aim.angle()+half,32,color,2)
  for direction in [-1,1]:canvas.draw_line(p,p+aim.rotated(half*direction)*minf(200,float(a.range)),color,1)

func add_visual(v:Dictionary)->void:
 if visuals.size()>=40:visuals.pop_front()
 visuals.append(v)

func activate_form(a:Dictionary)->void:
 var id=str(a.get("form_id",""))
 if form_textures.has(id):active_form=id;form_left=float(a.get("form_duration",3))
func form_texture()->Texture2D:return form_textures.get(active_form)
