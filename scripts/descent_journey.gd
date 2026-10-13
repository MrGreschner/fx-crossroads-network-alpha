extends RefCounted
## Authoritative floor rewards, mineable vitality and solo boss encounters.
var game:Node
var boosts:Dictionary={}
var pending:Dictionary={}
var warnings:Array=[]
var clock:=0.0
const BOSS_TYPES=["cavern_warden","depth_sovereign"]
func reset()->void:boosts.clear();pending.clear();warnings.clear();clock=0
func state(id:String)->Dictionary:
 if not boosts.has(id):boosts[id]={"power":0,"health":0,"cooldown":0,"spent":0}
 return boosts[id]
func reward(id:String,level:int)->void:
 if game.mode=="descent" and level>10:pending[id]=int(pending.get(id,0))+1
func choose(id:String,value:String)->void:
 if game.mode!="descent" or game.role!="host" or int(pending.get(id,0))<=0 or value not in ["depth_power","depth_health","depth_cooldown"]:return
 var s:=state(id);var key:String=value.trim_prefix("depth_")
 if key=="cooldown" and int(s.cooldown)>=10:return
 pending[id]=int(pending[id])-1;s[key]=int(s[key])+1;s.spent=int(s.spent)+1
 if key=="health":game.health[id]=mini(game._max_hp(id),int(game.health.get(id,0))+18)
func power(id:String)->float:return 1+.025*int(state(id).power)
func hp(id:String)->int:return 18*int(state(id).health)
func cooldown(id:String)->float:return maxf(.8,1-.02*int(state(id).cooldown))
func combat_count()->int:
 var count:=0
 for enemy in game.opponents:
  if not bool(enemy.get("health_gem",false)):count+=1
 return count
func floor_start()->void:
 warnings.clear()
 var floor:int=game.floor_number
 if floor%5==0:
  var kind:="depth_sovereign" if floor%30==0 else "cavern_warden"
  var hp:float=(2100.0+floor*32 if floor%30==0 else 360.0+floor*35 if floor%10==0 else 180.0+floor*24)*(1+.55*maxi(0,game.positions.size()-1))
  game.opponents.append({"type":kind,"pos":game.FIELD.size*Vector2(.74,.5),"hp":hp,"max_hp":hp,"boss":true,"uid":randi(),"lane":0,"hit_radius":32,"depth_boss":true,"attack_timer":1.5,"phase":0})
  game.status_label.text=("SOVEREIGN OF THE DEEP • Four attacks. Watch the floor!" if kind=="depth_sovereign" else "BOSS FLOOR • No reinforcements" if floor%10==0 else "MINI-BOSS FLOOR • Dodge its attacks")
 elif floor>1 and randf()<.55:
  var rng:=RandomNumberGenerator.new();rng.seed=game.floor_seed+floor*157
  var point:Vector2=game._random_spawn(rng)
  game.opponents.append({"type":"vitality_geode","pos":point,"hp":1.0,"max_hp":1.0,"boss":false,"uid":randi(),"lane":0,"health_gem":true})
func shatter(enemy:Dictionary,owner:String)->void:
 if not game.health.has(owner) or int(game.health.get(owner,0))<=0:return
 var point:Vector2=enemy.pos;var healed:int=mini(30,game._max_hp(owner)-int(game.health[owner]));game.health[owner]+=healed
 game._emit_effect({"pos":point,"radius":65,"time":.5,"color":"#8ef1b7"});game.status_label.text="Vitality geode shattered • +"+str(healed)+" health"
 # Resource healing is deliberately not attributed to a character healing spell.
func cleared(floor:int)->void:
 if game.spectating():return
 game.legacy.card.descent_cleared(floor,game.match_party_size);game.legacy.save()
func step(delta:float)->void:
 if game.mode!="descent" or not game.started:return
 clock+=delta
 if game.role!="host":return
 for enemy in game.opponents:
  if not bool(enemy.get("depth_boss",false)) or game.adventure.combat.stunned(game.adventure.combat.npc_key(enemy)):continue
  var target:="";var distance:=INF
  for id in game.positions:
   if int(game.health.get(id,0))>0 and enemy.pos.distance_squared_to(game.positions[id])<distance:target=str(id);distance=enemy.pos.distance_squared_to(game.positions[id])
  if target.is_empty():continue
  if enemy.has("dash_target"):
   var endpoint:=Vector2(enemy.dash_target[0],enemy.dash_target[1]);var from:Vector2=enemy.pos
   enemy.pos=game._move_actor(enemy.pos,(endpoint-enemy.pos).normalized()*650*delta)
   for id in game.positions:
    if id not in enemy.dash_hits and int(game.health.get(id,0))>0 and Geometry2D.get_closest_point_to_segment(game.positions[id],from,enemy.pos).distance_to(game.positions[id])<52:
     enemy.dash_hits.append(id);game._hurt(str(id),26,"enemy","",preload("res://scripts/defeat_credit.gd").resolve(game,"e:"+str(enemy.uid),"Boss charge"))
   if enemy.pos.distance_to(endpoint)<30 or from.distance_to(enemy.pos)<.5:enemy.erase("dash_target")
   continue
  var goal:Vector2=game.positions[target];var aim:Vector2=(goal-enemy.pos).normalized();var speed:=125.0 if enemy.type=="depth_sovereign" else 90.0
  var steering:Vector2=game.descent_direction(enemy,goal+aim.orthogonal()*130,delta)
  enemy.pos=game._move_actor(enemy.pos,steering*speed*delta*game.adventure.combat.speed_factor(game.adventure.combat.npc_key(enemy)))
  enemy.attack_timer=float(enemy.get("attack_timer",1))-delta
  if float(enemy.attack_timer)>0:continue
  var attack:int=int(enemy.phase)%(4 if enemy.type=="depth_sovereign" else 3 if game.floor_number%10==0 else 2);enemy.phase=int(enemy.phase)+1;enemy.attack_timer=2.9 if enemy.type=="depth_sovereign" else 3.4
  var origin:Vector2=enemy.pos
  if attack==0:
   var end:Vector2=game._move_actor(origin,aim*450)
   warnings.append({"kind":"charge","from":[origin.x,origin.y],"pos":[end.x,end.y],"left":.85,"boss":enemy.uid,"damage":26.0})
  elif attack==1:warnings.append({"kind":"burst","pos":[origin.x,origin.y],"left":.95,"damage":16.0})
  elif attack==2:
   for n in 3:
    var point:Vector2=goal+Vector2.from_angle(n*TAU/3)*80
    warnings.append({"kind":"fall","pos":[point.x,point.y],"left":1.2+n*.12,"damage":28.0})
  else:warnings.append({"kind":"cross","pos":[origin.x,origin.y],"left":1.15,"damage":30.0})
 for i in range(warnings.size()-1,-1,-1):
  var w:Dictionary=warnings[i];w.left=float(w.left)-delta
  if float(w.left)>0:continue
  warnings.remove_at(i);var p:=Vector2(w.pos[0],w.pos[1]);var from:=Vector2(w.get("from",w.pos)[0],w.get("from",w.pos)[1])
  if w.kind=="burst":
   for n in 12:game.adventure.combat.launch_projectile("enemy",p,Vector2.from_angle(n*TAU/12+clock),{"range":1100,"speed":255,"radius":10,"color":"#e1b5fa"},float(w.damage))
  elif w.kind!="charge":
   for id in game.positions:
    if int(game.health.get(id,0))<=0:continue
    var point:Vector2=game.positions[id];var hit:bool=point.distance_to(p)<100 if w.kind=="fall" else (absf(point.x-p.x)<45 or absf(point.y-p.y)<45) if w.kind=="cross" else Geometry2D.get_closest_point_to_segment(point,from,p).distance_to(point)<52
    if hit:game._hurt(str(id),float(w.damage),"enemy","",preload("res://scripts/defeat_credit.gd").resolve(game,"e:"+str(w.boss),str(w.kind).capitalize()))
   game._emit_effect({"pos":p,"radius":100,"time":.35,"color":"#cf9cec"})
  if w.kind=="charge":
   for boss in game.opponents:
    if int(boss.uid)==int(w.boss):boss.dash_target=w.pos;boss.dash_hits=[]
func snapshot()->Dictionary:return {"boosts":boosts,"pending":pending,"warnings":warnings,"clock":clock}
func receive(value:Dictionary)->void:boosts=value.get("boosts",{});pending=value.get("pending",{});warnings=value.get("warnings",[]);clock=float(value.get("clock",clock))
func draw(canvas:Node2D,camera:Vector2)->void:
 if game.mode!="descent" or not game.started:return
 for w in warnings:
  var p:=Vector2(w.pos[0],w.pos[1])-camera;var tint:=Color(1,.65,.28,.3)
  if w.kind=="charge":
   var start:=Vector2(w.from[0],w.from[1])-camera;canvas.draw_line(start,p,tint,85);canvas.draw_line(start,p,Color("#f8cd83"),3)
  elif w.kind=="cross":
   canvas.draw_rect(Rect2(-camera+Vector2(p.x+camera.x-45,0),Vector2(90,game.FIELD.size.y)),tint);canvas.draw_rect(Rect2(-camera+Vector2(0,p.y+camera.y-45),Vector2(game.FIELD.size.x,90)),tint)
  else:preload("res://scripts/combat_cues.gd").danger(canvas,p,100,float(w.left),1.2,Color("#e2b6f5"))
