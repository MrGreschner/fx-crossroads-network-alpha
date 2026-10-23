extends RefCounted
## Authoritative floor rewards, mineable vitality and solo boss encounters.
var game:Node
var boosts:Dictionary={}
var pending:Dictionary={}
var warnings:Array=[]
var clock:=0.0
const PROFILES={"basalt_ram": {"name": "Basalt Gatehorn", "color": "#b89175", "attacks": ["charge", "cross", "fall"]}, "garnet_widow": {"name": "Garnet Widow", "color": "#c56b9f", "attacks": ["pincer", "fall", "burst"]}, "undertow_nautilus": {"name": "Undertow Nautilus", "color": "#69bbc5", "attacks": ["pull", "ring", "spiral"]}, "rootgrasp_colossus": {"name": "Rootgrasp Colossus", "color": "#91a77b", "attacks": ["cross", "pincer", "fall"]}, "furnace_crown": {"name": "Furnace Crown", "color": "#ed9858", "attacks": ["fan", "ring", "charge"]}, "clockwork_dredger": {"name": "Clockwork Dredger", "color": "#b5c5ce", "attacks": ["cross", "spiral", "pincer"]}, "hollow_choir": {"name": "Choir of the Hollow", "color": "#a996db", "attacks": ["pull", "fall", "fan"]}, "starved_leviathan": {"name": "Starved Leviathan", "color": "#70b5a2", "attacks": ["charge", "pincer", "ring"]}, "unmade_surveyor": {"name": "Unmade Surveyor", "color": "#e2c996", "attacks": ["cross", "fall", "spiral"]}, "below_king": {"name": "The King Below", "color": "#c19ee1", "attacks": ["pull", "cross", "fan", "charge", "ring"]}}
const BOSS_TYPES=["basalt_ram", "garnet_widow", "undertow_nautilus", "rootgrasp_colossus", "furnace_crown", "clockwork_dredger", "hollow_choir", "starved_leviathan", "unmade_surveyor", "below_king"]
static func scaling(floor:int)->Dictionary:
 var d=maxi(0,floor-1)
 return {"health":.8+.05*d+.0011*d*d,"damage":1+.018*d+.00038*d*d,"speed":minf(1.6,1+.007*d),"pace":minf(1.85,1+.012*d)}
static func milestone(floor:int)->String:return BOSS_TYPES[posmod(maxi(1,floor/10)-1,BOSS_TYPES.size())]

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
  var kind:String=milestone(floor) if floor%10==0 else "cavern_warden"
  var scale=scaling(floor);var hp:float=(420 if floor%10==0 else 180)*float(scale.health)*(1+.6*maxi(0,game.positions.size()-1))
  var rng=RandomNumberGenerator.new();rng.seed=game.floor_seed+floor*157;var at:Vector2=game._random_spawn(rng)
  game.opponents.append({"type":kind,"pos":at,"hp":hp,"max_hp":hp,"boss":true,"uid":randi(),"lane":0,"hit_radius":40,"depth_boss":true,"attack_timer":1.8,"phase":0})
  var title:String=PROFILES.get(kind,{"name":"Cavern Warden"}).name
  game.status_label.text="DEPTH "+str(floor)+" • "+title+" • "+("New guardian • watch its tells" if floor%10==0 else "Sentinel encounter")

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
 game.legacy.card.descent_cleared(floor,game.match_party_size);preload("res://scripts/named_records.gd").descent_cleared(game.legacy,floor);game.legacy.save()
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
  var goal:Vector2=game.positions[target];var aim:Vector2=(goal-enemy.pos).normalized();var speed:float=(115.0 if enemy.type!="cavern_warden" else 90.0)*float(scaling(game.floor_number).speed)
  var steering:Vector2=game.descent_direction(enemy,goal+aim.orthogonal()*130,delta)
  enemy.pos=game._move_actor(enemy.pos,steering*speed*delta*game.adventure.combat.speed_factor(game.adventure.combat.npc_key(enemy)))
  enemy.attack_timer=float(enemy.get("attack_timer",1))-delta
  if float(enemy.attack_timer)>0:continue
  var profile:Dictionary=PROFILES.get(str(enemy.type),{"attacks":["charge","burst"]})
  var style:String=profile.attacks[int(enemy.phase)%profile.attacks.size()];enemy.phase=int(enemy.phase)+1
  enemy.attack_timer=3.8/float(scaling(game.floor_number).pace)
  var origin:Vector2=enemy.pos;var color:String=profile.get("color","#d1acda")
  var warning={"kind":style,"from":[origin.x,origin.y],"pos":[goal.x,goal.y],"left":1.05,"total":1.05,"boss":enemy.uid,"damage":18.0 if style in ["burst","fan","spiral","pull"] else 24.0,"color":color}
  if style=="charge":
   var end:Vector2=game._move_actor(origin,aim*520);warning.pos=[end.x,end.y];warning.left=.95
  elif style in ["burst","ring","cross","spiral","pull"]:warning.pos=[origin.x,origin.y]
  if style=="pincer":
   for side in [-1,1]:
    var copy=warning.duplicate(true);var point=goal+aim.orthogonal()*side*125;copy.kind="fall";copy.pos=[point.x,point.y];copy.left=1.15;warnings.append(copy)
  elif style=="fall":
   for n in mini(5,2+int(game.floor_number/30)):
    var copy=warning.duplicate(true);var point=goal+Vector2.from_angle(n*2.4)*n*82;copy.pos=[point.x,point.y];copy.left=1.1+n*.20;warnings.append(copy)
  else:warnings.append(warning)

 for i in range(warnings.size()-1,-1,-1):
  var w:Dictionary=warnings[i];w.left=float(w.left)-delta
  if float(w.left)>0:continue
  warnings.remove_at(i);var p:=Vector2(w.pos[0],w.pos[1]);var from:=Vector2(w.get("from",w.pos)[0],w.get("from",w.pos)[1])
  if w.kind in ["burst","spiral","fan"]:
   var origin=Vector2(w.from[0],w.from[1]);var aim=(p-origin).normalized();var count=12 if w.kind!="fan" else 7
   for n in count:
    var direction=Vector2.from_angle(n*TAU/count+clock) if w.kind!="fan" else aim.rotated((n-3)*.17)
    game.adventure.combat.launch_projectile("enemy",origin,direction,{"range":1100,"speed":255*float(scaling(game.floor_number).speed),"radius":9,"color":w.color},float(w.damage))
  elif w.kind!="charge":
   for id in game.positions:
    if int(game.health.get(id,0))<=0:continue
    var point:Vector2=game.positions[id];var distance=point.distance_to(p)
    var hit:bool=distance<95 if w.kind=="fall" else (absf(point.x-p.x)<42 or absf(point.y-p.y)<42) if w.kind=="cross" else distance>145 and distance<235 if w.kind=="ring" else distance<320 if w.kind=="pull" else false
    if hit:
     if w.kind=="pull":game.positions[id]=game._move_actor(point,(p-point).normalized()*70)
     game._hurt(str(id),float(w.damage),"enemy","",preload("res://scripts/defeat_credit.gd").resolve(game,"e:"+str(w.boss),str(w.kind).capitalize()))
   game._emit_effect({"pos":p,"radius":230 if w.kind=="ring" else 100,"time":.35,"color":w.color})

  if w.kind=="charge":
   for boss in game.opponents:
    if int(boss.uid)==int(w.boss):boss.dash_target=w.pos;boss.dash_hits=[]
func snapshot()->Dictionary:return {"boosts":boosts,"pending":pending,"warnings":warnings,"clock":clock}
func receive(value:Dictionary)->void:boosts=value.get("boosts",{});pending=value.get("pending",{});warnings=value.get("warnings",[]);clock=float(value.get("clock",clock))
func draw(canvas:Node2D,camera:Vector2)->void:
 if game.mode!="descent" or not game.started:return
 for w in warnings:
  var p:=Vector2(w.pos[0],w.pos[1])-camera;var tint:=Color(str(w.get("color","#eca259")),.3)
  if w.kind=="charge":
   var start:=Vector2(w.from[0],w.from[1])-camera;canvas.draw_line(start,p,tint,85);canvas.draw_line(start,p,Color("#f8cd83"),3)
  elif w.kind=="cross":
   canvas.draw_rect(Rect2(-camera+Vector2(p.x+camera.x-45,0),Vector2(90,game.FIELD.size.y)),tint);canvas.draw_rect(Rect2(-camera+Vector2(0,p.y+camera.y-45),Vector2(game.FIELD.size.x,90)),tint)
  elif w.kind=="ring":
   canvas.draw_arc(p,190,0,TAU,48,tint,80,true);canvas.draw_arc(p,145,0,TAU,48,Color("#f3dfa2"),2,true)
  elif w.kind=="pull":
   canvas.draw_arc(p,320,0,TAU,48,tint,3,true)
   for n in 8:
    var dir=Vector2.from_angle(n*TAU/8+clock);canvas.draw_line(p+dir*270,p+dir*190,Color("#cdbfe7"),3,true)
  else:preload("res://scripts/combat_cues.gd").danger(canvas,p,95,float(w.left),1.2,Color(str(w.get("color","#e2b6f5"))))

func draw_boss(c:Node2D,enemy:Dictionary,p:Vector2)->void:
 var n=BOSS_TYPES.find(str(enemy.type));var ink=Color(PROFILES.get(str(enemy.type),{"color":"#b69b87"}).color);var dark=Color("#242837");var phase=clock*2;var q=p+Vector2(0,-32+sin(phase)*3)
 c.draw_circle(p+Vector2(0,7),38,Color(0,0,0,.24))
 match n:
  0,-1:
   c.draw_rect(Rect2(q-Vector2(28,22),Vector2(56,52)),ink);c.draw_circle(q-Vector2(0,22),23,ink.lightened(.2))
   for side in [-1,1]:
    c.draw_arc(q+Vector2(side*27,-26),18,-PI if side<0 else 0,0 if side<0 else PI,14,ink.darkened(.25),9,true);c.draw_line(q+Vector2(side*17,25),p+Vector2(side*22,8),dark,12,true)
  1:
   c.draw_circle(q,26,ink);c.draw_circle(q+Vector2(0,-25),17,ink.lightened(.2))
   for side in [-1,1]:
    for k in 4:
     var joint=q+Vector2(side*(40+k*3),-35+k*22);c.draw_line(q,joint,ink,6,true);c.draw_line(joint,p+Vector2(side*(61+k*4),sin(phase+k)*5),ink.darkened(.2),5,true)
  2:
   for k in range(26,0,-1):
    var a=Vector2.from_angle(k*.5+phase*.1)*k*1.3;c.draw_circle(q+a,10,ink.lerp(dark,k/35.0))
   for k in 5:c.draw_line(q+Vector2(25,k*5),q+Vector2(56+sin(phase+k)*12,k*12),ink,5,true)
  3:
   c.draw_colored_polygon(PackedVector2Array([q+Vector2(-37,27),q+Vector2(-22,-60),q+Vector2(22,-64),q+Vector2(39,27)]),ink)
   for k in 5:c.draw_line(q+Vector2(0,20),p+Vector2((k-2)*28,9+sin(phase+k)*5),ink.darkened(.25),8,true)
  4:
   c.draw_rect(Rect2(q-Vector2(29,29),Vector2(58,60)),dark);c.draw_rect(Rect2(q-Vector2(19,16),Vector2(38,38)),ink)
   for k in 5:c.draw_colored_polygon(PackedVector2Array([q+Vector2(-27+k*13,-26),q+Vector2(-20+k*13,-60-sin(phase+k)*9),q+Vector2(-14+k*13,-25)]),ink)
  5:
   c.draw_circle(q,36,ink)
   for k in 10:
    var dir=Vector2.from_angle(k*TAU/10+phase*.2);c.draw_line(q+dir*30,q+dir*48,ink,9,true)
   c.draw_circle(q,22,dark);c.draw_line(q,q+Vector2.from_angle(phase)*21,ink,5,true)
  6:
   for k in 3:
    var at=q+Vector2((k-1)*34,-25+sin(phase+k)*12);c.draw_colored_polygon(PackedVector2Array([at+Vector2(-15,0),at+Vector2(0,-30),at+Vector2(15,0),at+Vector2(22,39),at+Vector2(-22,39)]),ink.darkened(k*.1));c.draw_circle(at,5,dark)
  7:
   for k in range(10,-1,-1):c.draw_circle(q+Vector2(sin(phase+k*.55)*24,k*8-50),8+k*.9,ink.darkened(k*.025))
  8:
   for k in 4:
    var direction=Vector2.from_angle(k*PI/2+phase*.15);var a=q+direction*32;var side=direction.orthogonal()*18;c.draw_colored_polygon(PackedVector2Array([q+direction*8,a+side,q+direction*62,a-side]),ink.lightened(k*.04))
  _:
   c.draw_colored_polygon(PackedVector2Array([q+Vector2(-43,40),q+Vector2(-24,-41),q+Vector2(24,-41),q+Vector2(43,40)]),ink.darkened(.25));c.draw_circle(q-Vector2(0,24),22,ink)
   for k in 5:c.draw_line(q+Vector2(-25+k*12,-39),q+Vector2(-25+k*12,-68-(12 if k==2 else 0)),Color("#e7ca82"),6,true)
 for side in [-1,1]:c.draw_circle(q+Vector2(side*8,-24),3,Color("#ffeab1"))
 var title:String=PROFILES.get(str(enemy.type),{"name":"Cavern Warden"}).name
 c.draw_string(ThemeDB.fallback_font,p+Vector2(-90,-128 if n==9 else -106),title,HORIZONTAL_ALIGNMENT_CENTER,180,14,ink.lightened(.3))
