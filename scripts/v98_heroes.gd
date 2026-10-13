extends Node
## Seasonal control and a melee catcher. Authority owns every landing and field.
var combat:Node
var effects:Array=[]
var shells:Dictionary={}
var clock:=0.0
const STYLES=["wick_fire","wick_face","wick_treats","crab_pincers","crab_shell","crab_crush","crab_nursery"]
const COLOURS={"slow":"#7abdda","poison":"#b385d6","burn":"#f69d53","shock":"#f1de83","heal":"#96d6a4"}
func reset()->void:effects.clear();shells.clear();clock=0
func add(owner:String,kind:String,p:Vector2,aim:Vector2,time:float,amount:float=0)->Dictionary:
 var e:Dictionary={"owner":owner,"kind":kind,"pos":combat.point_array(p),"aim":combat.point_array(aim),"time":time,"duration":time,"damage":amount,"tick":0.0,"stage":0,"hits":[]}
 if effects.size()<192:effects.append(e)
 return e
func moving(owner:String)->bool:return effects.any(func(e):return str(e.owner)==owner and str(e.kind)=="crush")
func playing()->bool:return combat.adventure.game.started if combat.adventure.arcade else combat.adventure.game.mode=="run"
func candle(id:String)->bool:
 if not playing():return false
 if not combat.adventure.alive(id):return false
 var p:Vector2=combat.owner_pos(id)
 for owner in combat.adventure.points():
  if not combat.adventure.alive(str(owner)) or not combat.passive(str(owner),"candle_light") or not combat.v75.friendly(str(owner),id):continue
  var centre:Vector2=combat.owner_pos(str(owner))
  if not combat.path_clear(centre,p):continue
  for n in 3:
   if p.distance_to(centre+Vector2.from_angle(clock*.8+n*TAU/3)*28)<=115:return true
 return false
func crit_multiplier(id:String)->float:return 1.5 if candle(id) else 1.0
func heal_factor(id:String)->float:return 1.15 if candle(id) else 1.0
func defence(id:String)->float:
 return mini(4,int(shells.get(id,{}).get("ammo",0)))*.03 if combat.passive(id,"shell_ledger") and combat.adventure.alive(id) else 0.0
func catch_shot(a:Vector2,b:Vector2,source:String)->bool:
 if not combat.adventure.authoritative():return false
 for owner in shells:
  var s:Dictionary=shells[owner]
  if float(s.guard)<=0 or int(s.ammo)>=4 or not combat.adventure.alive(str(owner)) or source!="enemy" and combat.v75.friendly(str(owner),source):continue
  var p:Vector2=combat.owner_pos(str(owner));var near:Vector2=Geometry2D.get_closest_point_to_segment(p,a,b)
  if p.distance_to(near)<=45 and combat.path_clear(p,near):s.ammo=int(s.ammo)+1;s.time=12.0;add(str(owner),"catch",p,Vector2.RIGHT,.25);return true
 return false
func strike(owner:String,p:Vector2,aim:Vector2,reach:float,damage:float,hits:Array,half_angle:float=.65)->void:
 for key in combat.hostile(owner):
  var f:Dictionary=combat.actor(key)
  if f.is_empty() or not bool(f.alive) or hits.has(key) or not combat.v56.cone(p,aim,f.pos,reach,cos(half_angle)) or not combat.path_clear(p,f.pos):continue
  hits.append(key);combat.damage(key,damage,owner)
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:String=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var p:Vector2=combat.owner_pos(owner);var reach:float=float(stats.get("range",100))
 match style:
  "wick_fire":
   combat.launch_projectile(owner,p+aim*18,aim,stats,amount);add(owner,"ember",p,aim,.22)
  "wick_face":
   var e:Dictionary=add(owner,"face",p,aim,.65);e.range=reach
   for key in combat.hostile(owner):
    var f:Dictionary=combat.actor(key)
    if f.is_empty() or not bool(f.alive) or not combat.v56.cone(p,aim,f.pos,reach,cos(PI*.35)) or not combat.path_clear(p,f.pos):continue
    var stun:float=float(stats.get("stun_duration",1.1));combat.apply_status(key,"stun",stun,owner);combat.apply_status(key,"slow",stun+3,owner,.65)
  "wick_treats":
   var e:Dictionary=add(owner,"volley",p,aim,2,amount);e.range=reach;e.count=int(stats.get("count",20));e.good=bool(stats.get("goodies",false));e.seed=randi_range(0,4)
  "crab_pincers":
   var e:Dictionary=add(owner,"pincers",p,aim,.36,amount);e.range=reach
  "crab_shell":
   var s:Dictionary=shells.get(owner,{"ammo":0,"time":12.0});s.guard=float(stats.get("duration",3.5));s.time=12.0;shells[owner]=s;combat.apply_status(combat.player_key(owner),"guard",float(s.guard),owner,.5)
  "crab_crush":
   var e:Dictionary=add(owner,"crush",p,aim,.65,amount);e.start=combat.point_array(p);e.end=combat.point_array(combat.v75.clip(p,aim,reach));e.ammo=int(shells.get(owner,{}).get("ammo",0));shells.erase(owner);combat.apply_status(combat.player_key(owner),"guard",.65,owner,.25)
  "crab_nursery":
   var e:Dictionary=add(owner,"nursery",p,aim,4,0);e.range=reach;e.heal=4+int(shells.get(owner,{}).get("ammo",0));shells.erase(owner)
 return true
func treat(volley:Dictionary,index:int)->void:
 var owner:String=str(volley.owner);var p:Vector2=combat.owner_pos(owner);var aim:Vector2=Vector2.from_angle(index*2.39996+float(volley.seed))
 var target:Vector2=combat.v75.clip(p,aim,randf_range(70,float(volley.range)))
 var e:Dictionary=add(owner,"treat",p,aim,1.25,float(volley.damage));e.start=combat.point_array(p);e.first=combat.point_array(target);e.second=combat.point_array(combat.v75.clip(target,aim,32));e.flavour=["slow","poison","burn","shock","heal"][(index+int(volley.seed))%5] if not bool(volley.good) else ("slow" if index%2==0 else "heal")
func open_treat(e:Dictionary)->void:
 var field:Dictionary=add(str(e.owner),"patch",combat.vec(e.second),Vector2.RIGHT,3);field.flavour=e.flavour;field.range=36.0;field.tick=.5
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 for owner in shells.keys():
  var s:Dictionary=shells[owner];s.guard=maxf(0,float(s.get("guard",0))-delta);s.time=float(s.time)-delta
  if s.time<=0 or not combat.adventure.alive(str(owner)):shells.erase(owner)
 for i in range(effects.size()-1,-1,-1):
  var e:Dictionary=effects[i];var owner:String=str(e.owner);var active:float=minf(delta,float(e.time));e.time=float(e.time)-delta;e.tick=float(e.tick)+active
  if not combat.adventure.alive(owner):effects.remove_at(i);continue
  var elapsed:float=float(e.duration)-float(e.time);var origin:Vector2=combat.vec(e.pos);var aim:Vector2=combat.vec(e.aim);var p:Vector2=combat.owner_pos(owner)
  match str(e.kind):
   "volley":
    while int(e.stage)<int(e.count) and elapsed>=int(e.stage)*(2.0/int(e.count)):treat(e,int(e.stage));e.stage=int(e.stage)+1
   "treat":
    if elapsed>=.75 and int(e.stage)==0:
     e.stage=1;combat.v75.area(owner,combat.vec(e.first),26,float(e.damage),{});add(owner,"impact",combat.vec(e.first),aim,.2)
    if elapsed>=1.25 and int(e.stage)==1:
     e.stage=2;combat.v75.area(owner,combat.vec(e.second),26,float(e.damage),{});open_treat(e)
   "patch":
    while float(e.tick)+.0001>=.5:
     e.tick=float(e.tick)-.5
     if str(e.flavour)=="heal":
      for id in combat.party_heroes.friendly_near(owner,origin,float(e.range)):combat.release_heroes.heal(owner,str(id),2)
     else:
      for key in combat.hostile(owner):
       var f:Dictionary=combat.actor(key)
       if f.is_empty() or not bool(f.alive) or origin.distance_to(f.pos)>float(e.range) or not combat.path_clear(origin,f.pos):continue
       match str(e.flavour):
        "slow":combat.apply_status(key,"slow",.65,owner,.55)
        "poison":combat.apply_status(key,"poison",2,owner,2)
        "burn":combat.apply_status(key,"burn",2,owner,3)
        "shock":
         combat.damage(key,2,owner)
         if int(e.stage)%2==0:combat.apply_status(key,"stun",.18,owner)
      e.stage=int(e.stage)+1
   "pincers":
    while int(e.stage)<2 and elapsed>=int(e.stage)*.16:
     var direction:Vector2=aim.rotated(-.22 if int(e.stage)==0 else .22);strike(owner,p,direction,float(e.range),float(e.damage),[],.58);e.stage=int(e.stage)+1
   "crush":
    var progress:float=clampf(elapsed/.65,0,1);var destination:Vector2=combat.vec(e.start).lerp(combat.vec(e.end),progress)+aim.orthogonal()*sin(progress*TAU)*18
    var next:Vector2=combat.v75.clip(p,destination-p,p.distance_to(destination));combat.stance_heroes.place(owner,next)
    for key in combat.hostile(owner):
     var f:Dictionary=combat.actor(key)
     if f.is_empty() or not bool(f.alive) or e.hits.has(key) or f.pos.distance_to(Geometry2D.get_closest_point_to_segment(f.pos,p,next))>42 or not combat.path_clear(next,f.pos):continue
     e.hits.append(key);combat.damage(key,float(e.damage),owner);combat.knock(key,aim,55);combat.apply_status(key,"slow",1.2,owner,.65)
    if float(e.time)<=0:
     for n in int(e.ammo):combat.launch_projectile(owner,next,aim.rotated((n-(int(e.ammo)-1)*.5)*.18),{"range":260,"speed":380,"color":"#aad4d2"},12)
     add(owner,"impact",next,aim,.3);combat.adventure.teleport(owner,next)
   "nursery":
    for id in combat.party_heroes.friendly_near(owner,origin,float(e.range)):combat.apply_status(combat.player_key(str(id)),"guard",.2,owner,.2)
    while float(e.tick)+.0001>=1:
     e.tick=float(e.tick)-1
     for id in combat.party_heroes.friendly_near(owner,origin,float(e.range)):combat.release_heroes.heal(owner,str(id),int(e.heal))
  if float(e.time)<=0:effects.remove_at(i)
func snapshot()->Dictionary:return {"effects":effects,"shells":shells,"clock":clock}
func receive(data:Dictionary)->void:effects=data.get("effects",[]);shells=data.get("shells",{});clock=float(data.get("clock",clock))
func draw_on(c:Node2D,camera:Vector2)->void:
 if not playing():return
 var visible:Rect2=Rect2(camera-Vector2(320,320),c.get_viewport_rect().size+Vector2(640,640))
 for owner in combat.adventure.points():
  var p:Vector2=combat.owner_pos(str(owner))-camera
  if combat.adventure.alive(str(owner)) and combat.passive(str(owner),"candle_light") and visible.has_point(p+camera):
   for n in 3:
    var centre:Vector2=p+Vector2.from_angle(clock*.8+n*TAU/3)*28;c.draw_circle(centre,115,Color(1,.65,.2,.035));c.draw_arc(centre,115,0,TAU,36,Color(1,.74,.35,.22),1,true)
  if shells.has(owner):
   var s:Dictionary=shells[owner]
   if float(s.get("guard",0))>0:c.draw_circle(p,45,Color(.42,.7,.73,.18));c.draw_arc(p,45,0,TAU,24,Color(.72,.9,.9,.65),3,true)
   for n in int(s.ammo):c.draw_circle(p+Vector2.from_angle(clock+n*TAU/4)*29,4,Color("#b3dfcf"))
 for shot in combat.projectiles:
  if str(shot.get("stats",{}).get("style",""))!="wick_fire":continue
  var point:Vector2=combat.vec(shot.pos)-camera;var direction:Vector2=combat.vec(shot.aim)
  if not visible.has_point(point+camera):continue
  c.draw_line(point-direction*18,point,Color(1,.4,.13,.4),9,true);c.draw_circle(point,8,Color("#ef8b3e"));c.draw_circle(point+direction*2,4,Color("#ffe09a"))
 for e in effects:
  var origin:Vector2=combat.vec(e.pos)
  if not visible.has_point(origin):continue
  var p:Vector2=origin-camera;var aim:Vector2=combat.vec(e.aim);var age:float=float(e.duration)-float(e.time)
  match str(e.kind):
   "treat":
    var t:float=clampf(age/.75,0,1);var floor_pos:Vector2=combat.vec(e.start).lerp(combat.vec(e.first),t);var height:float=sin(t*PI)*90
    if age>.75:t=clampf((age-.75)/.5,0,1);floor_pos=combat.vec(e.first).lerp(combat.vec(e.second),t);height=sin(t*PI)*38
    var tint:Color=Color(COLOURS[str(e.flavour)]);var q:Vector2=floor_pos-camera-Vector2(0,height)
    c.draw_circle(floor_pos-camera,7,Color(0,0,0,.16));c.draw_arc(combat.vec(e.first)-camera,26,0,TAU,16,Color(tint,.17),1,true)
    c.draw_rect(Rect2(q-Vector2(6,5),Vector2(12,10)),tint);c.draw_line(q-Vector2(0,5),q+Vector2(0,5),Color("#fff0cf"),2);c.draw_line(q-Vector2(6,0),q+Vector2(6,0),Color("#fff0cf"),2)
    c.draw_line(q-Vector2(7,2),q-Vector2(11,5),tint,3);c.draw_line(q+Vector2(7,2),q+Vector2(11,5),tint,3)
   "patch":
    var tint:Color=Color(COLOURS[str(e.flavour)]);c.draw_circle(p,float(e.range),Color(tint,.13));c.draw_arc(p,float(e.range),0,TAU,24,Color(tint,.7*minf(1,float(e.time))),2,true)
    match str(e.flavour):
     "heal":c.draw_line(p-Vector2(7,0),p+Vector2(7,0),tint,3);c.draw_line(p-Vector2(0,7),p+Vector2(0,7),tint,3)
     "shock":c.draw_polyline(PackedVector2Array([p+Vector2(3,-10),p+Vector2(-4,0),p+Vector2(4,0),p+Vector2(-3,10)]),tint,2,true)
     "slow":for n in 6:c.draw_line(p,p+Vector2.from_angle(n*TAU/6)*9,tint,1,true)
     "poison":c.draw_circle(p-Vector2(4,2),4,tint);c.draw_circle(p+Vector2(5,3),3,tint)
     "burn":c.draw_colored_polygon(PackedVector2Array([p+Vector2(-7,7),p+Vector2(0,-11),p+Vector2(7,7)]),tint)
   "face":
    var radius:float=float(e.range);var opacity:float=minf(1,age/.12)*minf(1,float(e.time)/.25)
    # Two carved eyes project triangular cones; their outer fan matches the fright reach.
    c.draw_arc(p,radius,aim.angle()-PI*.35,aim.angle()+PI*.35,24,Color(1,.78,.35,.25*opacity),1,true)
    for side in [-1,1]:
     var eye:Vector2=p+aim*18+aim.orthogonal()*side*10
     var edge:Vector2=p+aim.rotated(side*PI*.35)*radius;var middle:Vector2=p+aim*radius
     c.draw_colored_polygon(PackedVector2Array([eye,edge,middle]),Color(1,.74,.22,.18*opacity))
     c.draw_polyline(PackedVector2Array([edge,eye,middle]),Color(1,.85,.5,.65*opacity),2,true)
     c.draw_colored_polygon(PackedVector2Array([eye-aim*4-aim.orthogonal()*5,eye-aim*4+aim.orthogonal()*5,eye+aim*7]),Color(1,.93,.67,opacity))
   "pincers":
    p=combat.owner_pos(str(e.owner))-camera
    for n in 2:
     var a:float=aim.angle()+(-.22 if n==0 else .22);var r:float=float(e.range);var tip:Vector2=p+Vector2.from_angle(a)*r
     c.draw_arc(p,r,a-.58,a+.58,18,Color(.83,.92,.84,.22),1,true)
     c.draw_line(p+Vector2.from_angle(a)*25,tip,Color("#7bada6"),4,true);c.draw_arc(tip-Vector2.from_angle(a)*12,12,a-PI*.6+sin(age*14)*.2,a+PI*.6-sin(age*14)*.2,12,Color("#deccb0"),3,true)
   "crush":
    c.draw_line(combat.vec(e.start)-camera,combat.vec(e.end)-camera,Color(.65,.83,.78,.22),34,true)
   "nursery":
    c.draw_circle(p,float(e.range),Color(.51,.79,.73,.12));c.draw_arc(p,float(e.range),0,TAU,32,Color("#bedaca"),3,true)
    for n in 6:c.draw_arc(p+Vector2.from_angle(n*TAU/6)*float(e.range),10,PI,TAU,10,Color("#dacbaa"),3,true)
   "impact","catch","ember":c.draw_arc(p,10+age*45,0,TAU,20,Color(1,.77,.44,maxf(0,float(e.time)*2)),2,true)
