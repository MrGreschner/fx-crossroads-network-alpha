extends RefCounted
## Objective engine for authored courses. No stage advances solely because time passed.
const Art=preload("res://scripts/wayfarer_art305.gd")
const POINTS=[Vector2(640,410),Vector2(1040,390),Vector2(1440,490),Vector2(1430,930),Vector2(900,960)]
const COLOURS=[Color("#d59385"),Color("#83c7d5"),Color("#9ac39a")]
var game:Node
var spec:Dictionary
var stage_index=-1
var objective:Dictionary={}
var objects:Array=[]
var walls:Array=[]
var completed=false
var count=0
var age=0.0
var clock=0.0
var hold=0.0
var selected=-1
var casts:Array=[]
var cast_serial=0
var casts_by_kind:Dictionary={}
var route_cast=0
var hits:Array=[]
var wave=0
var next_wave=0.0
var escort_health=100.0
var follower=Vector2.ZERO
var following=false
var hazard:Dictionary={}
var warning=0.0
var cart_texture:Texture2D
var cycle=0.0
var phrase:Array=[]
var phrase_step=0
var listen=0.0
var volley_hits:Array=[]
var volley_clock=-100.0
var volley_power=0.0
var beam:Array=[]
var mirror_angles=[0,0,0]
var rewind_armed=false
var rewind_beacon=false
var rewind_cast=false
func setup(owner:Node,data:Dictionary)->void:
 game=owner;spec=data.duplicate(true);var cart=Image.new()
 cart.load_png_from_buffer(FileAccess.get_file_as_bytes("res://assets/merchant282/cart.png"));cart_texture=ImageTexture.create_from_image(cart);next_stage()
func passable(p:Vector2,padding:float)->bool:
 if not Rect2(70,260,1860,970).grow(-padding).has_point(p):return false
 for wall in walls:
  if (wall as Rect2).grow(padding).has_point(p):return false
 return true
func status()->String:
 if completed:return "All objectives complete"
 var extra=" • %d / %d" % [count,int(objective.n)]
 if objective.kind=="defend":extra=" • patrol %d / %d • shelter %d%%" % [wave,int(objective.n),int(escort_health)]
 if objective.kind=="rhythm":extra+=" • Listen" if listen>0 else " • Repeat the lit phrase"
 return "%d / %d • %s%s" % [stage_index+1,spec.stages.size(),str(objective.text),extra]
func interactive()->bool:return str(objective.get("kind","")) in ["collect","repair","sequence","polarity","mirror","rhythm","weather","sacrifice","rewind"]
func obj(pos:Vector2,label:String,prop:String="waystone",value:int=0)->Dictionary:
 return {"pos":pos,"label":label,"prop":prop,"value":value,"done":false}
func next_stage()->void:
 stage_index+=1
 if stage_index>=spec.stages.size():completed=true;game.finish_course(true);return
 objective=spec.stages[stage_index];count=0;age=0;hold=0;selected=-1;casts=[];hits=[];objects=[];walls=[];wave=0;next_wave=.8;escort_health=100;following=false;hazard={};warning=0;cycle=1;rewind_armed=false;rewind_beacon=false;rewind_cast=false
 game.enemies.clear();game.enemy_shots.clear();game.bullets.clear();game.allies.clear();game.health=minf(game.max_health(),maxf(game.health,game.max_health()*.7))
 for key in game.cooldowns:game.cooldowns[key]=0.0
 game.add_float_text(game.position_in_world-Vector2(0,80),"OBJECTIVE "+str(stage_index+1),Color("#aee0d5"))
 var kind=str(objective.kind)
 route_cast=int(casts_by_kind.get(str(objective.get("requires","")),0))
 if kind in ["collect","repair","route","escort","weather"]:
  for i in int(objective.n):objects.append(obj(POINTS[i%POINTS.size()],str(i+1),str(objective.get("prop","waystone")),i))
  if kind=="weather":
   for i in objects.size():objects[i].label=["Clear","Cloudy","Fog","Rain"][i]
  if kind=="escort":follower=Vector2(440,650);objects.append(obj(follower,"Meet travellers","tent",-1))
  if bool(objective.get("mini",false)):
   # Real gaps are narrower than normal-body collision, passable only when shrunk.
   objects=[obj(Vector2(800,650),"Small door 1","arch"),obj(Vector2(1150,650),"Small door 2","arch"),obj(Vector2(1500,650),"Small door 3","arch")]
   for x in [800,1150,1500]:walls.append(Rect2(x-24,260,48,375));walls.append(Rect2(x-24,665,48,565))
   game.position_in_world=Vector2(500,650)
 elif kind in ["sequence","rhythm","polarity"]:
  for i in 3:objects.append(obj(Vector2(710+i*290,650),["Red","Blue","Green"][i],"bell" if kind=="rhythm" else "valve",0))
  if kind=="rhythm":new_phrase()
  if kind=="polarity":objects.append(obj(Vector2(1000,950),"Receiver • hold E","seal",0))
 elif kind=="mirror":
  objects=[obj(Vector2(700,500),"Mirror 1 • E","seal"),obj(Vector2(700,850),"Mirror 2 • E","seal"),obj(Vector2(1250,850),"Mirror 3 • E","seal")];mirror_angles=[0,0,0];trace_beam()
 elif kind in ["targets","volley"]:spawn_targets()
 elif kind=="defend":objects.append(obj(Vector2(1000,700),"Protect the shelter","tent"))
 elif kind in ["parry","evade"]:objects.append(obj(Vector2(980,650),"Stand here for the lesson","seal"));cycle=2.0
 elif kind=="rewind":objects=[obj(Vector2(520,650),"Anchor • E","seal"),obj(Vector2(1000,650),"Memory beacon • E","waystone")]
 elif kind=="sacrifice":objects=[obj(Vector2(950,650),"Offering • E","seal")]
 # Clear stale gate/pillar collision after a course-specific gap has disappeared.
 game.update_camera()
func spawn_targets()->void:
 var n=3 if objective.kind=="volley" else int(objective.n)
 for i in n:
  var pos=POINTS[i%5]
  if objective.kind=="volley":pos=Vector2(460,650)+Vector2.RIGHT.rotated([-.195,-.065,.195][i])*350
  var uid=game.next_enemy_uid;game.next_enemy_uid+=1
  game.enemies.append({"uid":uid,"type":"training_dummy","pos":pos,"origin":pos,"hp":500.0,"max_hp":500.0,"boss":false,"attack_timer":100.0,"journey_target":true,"target_index":i})
 if objective.kind=="volley":game.position_in_world=Vector2(460,650);objects=[obj(Vector2(460,650),"Charge fully; aim at centre","seal")]
func hit(enemy:Dictionary,amount:float)->void:
 if amount<=0 or int(enemy.uid) in hits or not game.course_active:return
 var distance=game.position_in_world.distance_to(enemy.pos)
 if str(objective.get("distance",""))=="near" and distance>135:return
 if str(objective.get("distance",""))=="far" and distance<175:return
 if bool(objective.get("window",false)) and fmod(age,4.0)>1.8:return
 if objective.kind=="volley":
  if clock-volley_clock>1.6 or volley_power<.99 or game.position_in_world.distance_to(Vector2(460,650))>55:return
  if int(enemy.uid) not in volley_hits:volley_hits.append(int(enemy.uid))
  count=volley_hits.size()
  if count>=3:next_stage()
  return
 hits.append(int(enemy.uid));count+=1;game.enemy_flashes[int(enemy.uid)]=.2
 game.enemies.erase(enemy)
 if count>=int(objective.n):next_stage()
func cast(kind:String,power:float)->void:
 cast_serial+=1;casts_by_kind[kind]=int(casts_by_kind.get(kind,0))+1
 if kind=="primary":volley_clock=clock;volley_power=power;volley_hits=[]
 if objective.kind=="rewind" and rewind_beacon and kind=="secondary":rewind_cast=true
 if objective.kind!="ability":return
 var sequence:Array=objective.casts
 if count<sequence.size() and str(sequence[count])==kind:count+=1
 if count>=sequence.size():next_stage()
func new_phrase()->void:
 phrase=[[0,1,2],[2,0,1],[1,2,0]][count%3].duplicate();phrase_step=0;listen=3.1;age=0
func near()->int:
 var best=-1;var distance=88.0
 for i in objects.size():
  if bool(objects[i].done):continue
  var d=game.position_in_world.distance_to(objects[i].pos)
  if d<distance:best=i;distance=d
 return best
func interact(index:int,delta:float,pressed:bool,held:bool)->void:
 var kind=str(objective.kind)
 if index<0:hold=0;selected=-1;return
 if index!=selected:hold=0;selected=index
 var o:Dictionary=objects[index]
 if kind in ["repair","polarity"] and (kind=="repair" or index==3):
  if not held:hold=0;return
  if kind=="polarity" and [int(objects[0].value),int(objects[1].value),int(objects[2].value)]!=[1,0,1]:return
  hold+=delta
  if hold<1.2:return
 elif not pressed:return
 match kind:
  "collect","repair":o.done=true;count+=1
  "sequence":
   if index==int(objective.order[count]):count+=1
   else:count=0;game.add_float_text(o.pos,"Try the sequence again",Color("#e6bc92"))
  "rhythm":
   if listen>0:return
   if index!=int(phrase[phrase_step]):new_phrase();return
   phrase_step+=1
   if phrase_step>=phrase.size():count+=1;if count<int(objective.n):new_phrase()
  "polarity":
   if index<3:o.value=1-int(o.value)
   else:count=int(objective.n)
  "mirror":mirror_angles[index]=1-int(mirror_angles[index]);trace_beam()
  "weather":
   var weather_index=int(floor(age/4.0))%4
   if index!=weather_index or index in hits:return
   hits.append(index);count=hits.size();o.done=true
  "sacrifice":game.health=maxf(1,game.health-game.max_health()*.2);count=1
  "rewind":
   if index==0 and not rewind_armed:
    rewind_armed=true;game.adventure.combat.confluence.paths.erase("solo");o.label="Return with rewind"
   elif index==1 and rewind_armed:rewind_beacon=true;o.done=true
 if count>=int(objective.n):next_stage()
func trace_beam()->void:
 beam=[Vector2(400,500)];var at=Vector2(400,500);var direction=Vector2.RIGHT
 for b in 5:
  var nearest=-1;var distance=2200.0
  for i in objects.size():
   var off:Vector2=objects[i].pos-at
   if off.dot(direction)>1 and absf(off.cross(direction))<1 and off.length()<distance:nearest=i;distance=off.length()
  var receiver=Vector2(1250,400);var off=receiver-at
  if off.dot(direction)>0 and absf(off.cross(direction))<1 and off.length()<distance:beam.append(receiver);count=3;return
  if nearest<0:beam.append(at+direction*600);count=0;return
  at=objects[nearest].pos;beam.append(at)
  direction=Vector2(-direction.y,-direction.x) if int(mirror_angles[nearest])==0 else Vector2(direction.y,direction.x)
 count=0
func spawn_wave()->void:
 wave+=1
 var pools=["bramble","warden","glowcap_slinger"]
 var available=pools.filter(func(k):return game.enemy_types.has(k))
 if available.is_empty():available=["bramble"]
 for i in 2+mini(2,wave):
  var id=str(available[(stage_index+wave+i)%available.size()]);var hp=45.0+wave*8
  game.enemies.append({"uid":game.next_enemy_uid,"type":id,"pos":Vector2(1450+i%2*110,400+int(i/2)*350),"hp":hp,"max_hp":hp,"boss":false,"attack_timer":1.0,"journey_foe":true,"summoned":true});game.next_enemy_uid+=1
func step(delta:float)->void:
 if completed or not game.course_active:return
 clock+=delta;age+=delta
 var kind=str(objective.kind)
 interact(near(),delta,Input.is_action_just_pressed("interact"),Input.is_action_pressed("interact"))
 if completed or not game.course_active:return
 # Interactions may have advanced the stage; never run old-stage mechanics afterwards.
 if kind!=str(objective.kind):return
 if kind=="mirror" and count==3:next_stage();return
 if kind=="rhythm":listen=maxf(0,listen-delta)
 if kind=="rewind" and rewind_cast and rewind_beacon and game.position_in_world.distance_to(objects[0].pos)<110:count=1;next_stage();return
 if kind=="route":
  var active=true
  if bool(objective.get("mini",false)):active=game.adventure.combat.v110.small("solo") and game.position_in_world.x>float(objects[count].pos.x)+30
  if bool(objective.get("flight",false)):active=game.adventure.combat.events.flying("solo")
  if objective.has("requires"):active=active and int(casts_by_kind.get(str(objective.requires),0))>route_cast
  if count<objects.size() and game.position_in_world.distance_to(objects[count].pos)<65 and active:
   objects[count].done=true;count+=1;route_cast=int(casts_by_kind.get(str(objective.get("requires","")),0))
   if count>=int(objective.n):next_stage();return
  if bool(objective.get("wind",false)):game.move_player(Vector2(sin(age*.7)*36,cos(age*.5)*18)*delta)
 if kind=="escort":
  if not following and game.position_in_world.distance_to(follower)<90:following=true;objects[-1].done=true
  if following:
   var offset:Vector2=game.position_in_world-follower
   if offset.length()>65 and offset.length()<230:follower+=offset.normalized()*minf(145*delta,offset.length()-65)
   if count<int(objective.n) and follower.distance_to(objects[count].pos)<90:objects[count].done=true;count+=1
   if count>=int(objective.n):next_stage();return
   # Raiders threaten the group; lingering next to them damages the escort.
   if wave==0 and age>4:spawn_wave()
   for foe in game.enemies:
    if not bool(foe.get("journey_target",false)) and follower.distance_to(foe.pos)<95:escort_health-=delta*8
 if kind=="defend":
  if game.enemies.is_empty():
   if wave>=int(objective.n):count=wave;next_stage();return
   next_wave-=delta
   if next_wave<=0:spawn_wave();next_wave=2
  for foe in game.enemies:
   if foe.pos.distance_to(Vector2(1000,700))<100:escort_health-=delta*7
 if escort_health<=0:game.finish_course(false);return
 if kind in ["targets","volley"]:
  for foe in game.enemies:
   if bool(objective.get("moving",false)):foe.pos=foe.origin+Vector2(0,sin(age*1.3+int(foe.target_index))*95)
 if kind in ["parry","evade"]:lesson(delta)
 if bool(objective.get("hazards",false)):hazards(delta)
func hazards(delta:float)->void:
 cycle-=delta
 if hazard.is_empty() and cycle<=0:hazard={"pos":game.position_in_world,"time":1.1};cycle=3.1
 if not hazard.is_empty():
  hazard.time=float(hazard.time)-delta
  if float(hazard.time)<=0:
   if game.position_in_world.distance_to(hazard.pos)<68:game.take_player_damage(10)
   hazard={}
func lesson(delta:float)->void:
 var parry=objective.kind=="parry"
 if hazard.is_empty() and game.position_in_world.distance_to(objects[0].pos)>105:return
 cycle-=delta
 if hazard.is_empty() and cycle<=0:hazard={"pos":game.position_in_world,"time":1.2};cycle=maxf(4.0,float(game.hero.secondary.get("cooldown",4.5))+.8)
 if hazard.is_empty():return
 hazard.time=float(hazard.time)-delta
 if float(hazard.time)>0:return
 var inside=game.position_in_world.distance_to(hazard.pos)<68
 if parry:
  var guard=game.adventure.combat.mantis;var armed=float(guard.guards.get("solo",0))>guard.clock
  var hp=float(game.health)
  if inside:game.take_player_damage(12)
  if inside and armed and not guard.guards.has("solo") and game.health>=hp:count+=1
 else:
  if inside:game.take_player_damage(10)
  else:count+=1
 hazard={}
 if count>=int(objective.n):next_stage()
func text(at:Vector2,value:String,size:int=16,tint:Color=Color("#e6d9b7"))->void:
 game.draw_string(game.font,at-game.camera+Vector2(-130,-72),value,HORIZONTAL_ALIGNMENT_CENTER,260,size,tint)
func picture(key:String,at:Vector2,size:Vector2)->void:
 var t=Art.texture(key)
 if t!=null:game.draw_texture_rect(t,Rect2(at-game.camera-size*Vector2(.5,.8),size),false)
func draw_floor()->void:
 var cam:Vector2=game.camera;var field=Rect2(Vector2.ZERO,Vector2(2000,1300))
 var texture=Art.repeat_texture(str(spec.get("ground","meadow")))
 if texture!=null:game.draw_texture_rect(texture,Rect2(field.position-cam,field.size),true)
 # One restrained ground and a quiet path; production props frame the usable space.
 game.draw_polyline(PackedVector2Array([Vector2(340,650)-cam,Vector2(1660,650)-cam]),Color(.65,.55,.4,.25),105)
 for i in 12:
  picture("spruce" if str(spec.ground)=="snow" else "beech",Vector2(130+i*155,220),Vector2(130,150))
  picture("spruce" if str(spec.ground)=="snow" else "oak",Vector2(130+i*155,1290),Vector2(120,140))
 for wall in walls:
  var rect:Rect2=wall
  game.draw_rect(Rect2(rect.position-cam,rect.size),Color("#66735b"))
  for y in range(int(rect.position.y),int(rect.end.y),85):picture("roots",Vector2(rect.position.x+24,y+60),Vector2(92,94))
 for i in objects.size():
  var o:Dictionary=objects[i];var tint=Color("#7bbdba") if not o.done else Color("#88bb8a")
  if o.done:continue
  if objective.kind in ["route","escort"] and i!=count and int(o.value)>=0:tint=Color("#7c897f")
  game.draw_arc(o.pos-cam,38,0,TAU,36,tint,2)
  picture(str(o.prop),o.pos,Vector2(80,88));text(o.pos,str(o.label))
  if objective.kind in ["sequence","rhythm","polarity"] and i<3:
   var c:Color=COLOURS[i];game.draw_circle(o.pos-cam+Vector2(0,-27),10,c)
   if objective.kind=="polarity":text(o.pos+Vector2(0,27),("+" if int(o.value)==1 else "−")+" → "+["+","−","+"][i],19)
   if objective.kind=="rhythm" and listen>0 and int(floor((3.1-listen)/1.0))==i:
    var note=int(phrase[mini(2,int(floor(3.1-listen)))]);game.draw_arc(objects[note].pos-cam,48,0,TAU,36,Color("#ffe9a9"),5)
  if i==selected and hold>0:game.draw_arc(o.pos-cam,43,-PI/2,-PI/2+TAU*clampf(hold/1.2,0,1),32,Color("#e6d6a2"),4)
 if objective.kind=="mirror":
  game.draw_polyline(PackedVector2Array(beam.map(func(p):return p-cam)),Color("#e8d2a2"),4)
  for i in 3:
   var center:Vector2=objects[i].pos-cam;var offset=Vector2(21,-21) if mirror_angles[i]==0 else Vector2(21,21)
   game.draw_line(center-offset,center+offset,Color("#a1d4d8"),7)
  picture("waystone",Vector2(1250,400),Vector2(80,88));text(Vector2(1250,400),"Receiver")
 if objective.kind=="weather":text(Vector2(1000,330),"SIMULATED SKY • "+["Clear","Cloudy","Fog","Rain"][int(floor(age/4))%4],22)
 if objective.kind in ["sequence"]:text(Vector2(1000,350),"Order: "+" → ".join(objective.order.map(func(v):return ["Red","Blue","Green"][int(v)])),18)
 if objective.kind=="rewind":text(Vector2(1000,350),"Anchor set" if rewind_armed else "Start at the anchor",18)
 if objective.kind=="targets":
  for foe in game.enemies:
   var distance=str(objective.get("distance",""))
   if distance!="":game.draw_arc(foe.pos-cam,90 if distance=="near" else 190,0,TAU,48,Color("#83c7d5"),2)
   if bool(objective.get("window",false)):text(foe.pos,"COUNTER NOW" if fmod(age,4)<1.8 else "Wait…",16,Color("#a6d79d"))
 if objective.kind=="escort" and following:
  var cart=game.journey_id in ["rook","dustmarshal"]
  var t=cart_texture if cart else load("res://scripts/hero_portrait.gd").texture(game,"ram")
  if t!=null:game.draw_texture_rect(t,Rect2(follower-cam-(Vector2(65,90) if cart else Vector2(34,64)),Vector2(130,110) if cart else Vector2(68,68)),false)
  text(follower,"Stay close • %d%%" % int(escort_health),14)
 if not hazard.is_empty():
  game.draw_circle(hazard.pos-cam,68,Color(.85,.3,.25,.15));game.draw_arc(hazard.pos-cam,68,0,TAU,40,Color("#df8f7f"),3)
  text(hazard.pos,"GUARD!" if objective.kind=="parry" else "MOVE!",18)
