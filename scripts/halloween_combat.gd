extends Node
var combat:Node
var effects:Array=[]
var clock:=0.0
var heal_budgets:Dictionary={}
const STYLES=["grave_cleave","grave_toll","grave_ride","grave_guardian","witch_chain","witch_flight","witch_brew"]
func reset()->void:effects.clear();heal_budgets.clear();clock=0
func playing()->bool:return combat.playing()
func moving(id:String)->bool:return effects.any(func(e):return e.owner==id and e.kind=="flight")
func riding(id:String)->bool:return playing() and effects.any(func(e):return e.owner==id and e.kind=="ride")
func speed(id:String)->float:return 1.3 if riding(id) else 1.0
func visual_offset(id:String)->Vector2:
 if moving(id):return Vector2(0,-32)
 return Vector2(0,-17) if riding(id) else Vector2.ZERO
func aura(id:String)->Dictionary:
 if not playing() or not combat.adventure.alive(id):return {}
 for e in effects:
  if e.kind=="brew" and combat.adventure.alive(str(e.owner)) and combat.v75.friendly(str(e.owner),id) and combat.owner_pos(id).distance_to(combat.vec(e.pos))<=150 and combat.path_clear(combat.vec(e.pos),combat.owner_pos(id)):return e
 return {}
func bonus(id:String)->float:return 1.05 if not aura(id).is_empty() else 1.0
func on_hit(id:String,damage:float)->void:
 if damage<=0 or combat.dot_damage or not combat.adventure.authoritative():return
 var brew:Dictionary=aura(id)
 if brew.is_empty():return
 var state:Dictionary=heal_budgets.get(id,{"second":int(clock),"spent":0.0,"bank":0.0})
 if int(state.second)!=int(clock):state.second=int(clock);state.spent=0.0
 state.bank=float(state.bank)+damage*.08
 var amount:int=mini(int(state.bank),6-int(state.spent))
 if amount>0:combat.release_heroes.heal(str(brew.owner),id,amount);state.spent=float(state.spent)+amount;state.bank=float(state.bank)-amount
 state.bank=minf(float(state.bank),1);heal_budgets[id]=state
func add(id:String,kind:String,p:Vector2,time:float,damage:float=0)->Dictionary:
 var e:Dictionary={"owner":id,"kind":kind,"pos":combat.point_array(p),"time":time,"duration":time,"age":0.0,"damage":damage,"tick":0.0,"hits":[]}
 if effects.size()<160:effects.append(e)
 return e
func pool(id:String,p:Vector2,frost:bool=false)->void:
 var nearby:Array=effects.filter(func(e):return e.owner==id and e.kind=="pool" and combat.vec(e.pos).distance_to(p)<38 and bool(e.frost)==frost)
 if not nearby.is_empty():nearby[0].time=4.0;return
 var owned:Array=effects.filter(func(e):return e.owner==id and e.kind=="pool")
 if owned.size()>=10:
  owned[0].pos=combat.point_array(p);owned[0].time=4.0;owned[0].frost=frost;return
 var e:Dictionary=add(id,"pool",p,4);e.frost=frost;e.radius=43.0
func lob(id:String,p:Vector2,end:Vector2,kind:String,amount:float)->void:
 var e:Dictionary=add(id,kind,p,.6,amount);e.start=combat.point_array(p);e.end=combat.point_array(end)
func cast(id:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:String=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.playing() or not combat.adventure.authoritative() or not combat.adventure.alive(id):return true
 var p:Vector2=combat.owner_pos(id)
 match style:
  "grave_cleave":
   var e:Dictionary=add(id,"cleave",p,.34,amount+(6 if riding(id) else 0));e.aim=combat.point_array(aim);e.radius=float(stats.get("range",95));e.hit=false;e.stats=stats.duplicate(true)
  "grave_toll":
   var e:Dictionary=add(id,"toll",p,.75,amount);e.radius=float(stats.get("range",125));e.hit=false
  "grave_ride":
   for e in effects.duplicate():
    if e.owner==id and e.kind=="ride":effects.erase(e)
   add(id,"ride",p,5,amount)
  "grave_guardian":
   var unit:String=combat.party_heroes.add_unit(id,combat.v75.clip(p,aim,70),"mosaic",1,70,6)
   var u:Dictionary=combat.morrow.units[unit];u.sprite="gravehorse";u.hp=70;u.max_hp=70;u.damage=14;u.speed=0;u.reach=120;u.family="grave_guardian"
  "witch_chain":
   var end:Vector2=combat.v79.destination(id,aim,float(stats.get("range",480)))
   var e:Dictionary=add(id,"chain",p+aim*18,2,amount);e.aim=combat.point_array(aim);e.end=combat.point_array(end);e.frost=bool(stats.get("frost",false))
  "witch_flight":
   var end:Vector2=combat.v79.destination(id,aim,float(stats.get("range",1100)));var seconds:float=maxf(.3,p.distance_to(end)/560)
   var e:Dictionary=add(id,"flight",p,seconds,amount);e.start=combat.point_array(p);e.end=combat.point_array(end);e.next=.05;e.count=0
  "witch_brew":
   for e in effects.duplicate():
    if e.owner==id and e.kind=="brew":effects.erase(e)
   var end:Vector2=combat.v79.destination(id,aim,240)
   var e:Dictionary=add(id,"brew",end,7,amount);e.next=.4;e.gentle=bool(stats.get("gentle",false));e.tick=0.0
 return true
func area(id:String,p:Vector2,r:float,damage:float,stun:float=0,burn:float=0)->void:
 for key in combat.hostile(id):
  var f:Dictionary=combat.actor(key)
  if f.is_empty() or not bool(f.alive) or p.distance_to(f.pos)>r or not combat.path_clear(p,f.pos):continue
  combat.damage(key,damage,id)
  if stun>0:combat.apply_status(key,"stun",stun,id)
  if burn>0:combat.apply_status(key,"burn",burn,id,2)
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 for i in range(effects.size()-1,-1,-1):
  var e:Dictionary=effects[i];var id:String=str(e.owner)
  if not playing() or not combat.adventure.alive(id):effects.remove_at(i);continue
  e.time=float(e.time)-delta;e.age=float(e.age)+delta;var p:Vector2=combat.vec(e.pos)
  match str(e.kind):
   "cleave":
    if not bool(e.hit) and float(e.age)>=.12:
     e.hit=true
     for key in combat.hostile(id):
      var f:Dictionary=combat.actor(key)
      if not f.is_empty() and bool(f.alive) and combat.v56.cone(p,combat.vec(e.aim),f.pos,float(e.radius),.55) and combat.path_clear(p,f.pos):combat.damage(key,float(e.damage),id);combat.apply_hit_status(key,e.get("stats",{}),id)
   "toll":
    if not bool(e.hit) and float(e.age)>=.3:
     e.hit=true
     var landed:=false
     for key in combat.hostile(id):
      var f:Dictionary=combat.actor(key)
      if f.is_empty() or not bool(f.alive) or p.distance_to(f.pos)>float(e.radius) or not combat.path_clear(p,f.pos):continue
      landed=true;combat.damage(key,float(e.damage),id);combat.knock(key,(f.pos-p).normalized(),55);combat.apply_status(key,"stun",1.2,id)
     if landed and combat.passive(id,"lantern_courage"):combat.apply_status(combat.player_key(id),"guard",2,id,.12)
   "ride":
    p=combat.owner_pos(id);e.pos=combat.point_array(p);e.tick=float(e.tick)+delta
    if float(e.tick)>=.75:e.tick=0.0;area(id,p,52,float(e.damage))
   "chain":
    var end:Vector2=combat.vec(e.end);var next:Vector2=p.move_toward(end,300*delta);var impact:bool=not combat.path_clear(p,next);var struck:bool=false
    for key in combat.hostile(id):
     var f:Dictionary=combat.actor(key)
     if f.is_empty() or not bool(f.alive):continue
     if Geometry2D.get_closest_point_to_segment(f.pos,p,next).distance_to(f.pos)<=10+combat.v110.target_radius(key,9) and combat.path_clear(p,f.pos):
      combat.damage(key,float(e.damage),id);combat.apply_status(key,"slow",2,id,.5 if bool(e.frost) else .65);e.time=0;struck=true;break
    if not struck:
     if impact or next.distance_to(end)<2 or e.time<=0:pool(id,p if impact else next,bool(e.frost));e.time=0
     else:e.pos=combat.point_array(next)
   "flight":
    var progress:float=clampf(float(e.age)/float(e.duration),0,1);p=combat.vec(e.start).lerp(combat.vec(e.end),progress);e.pos=combat.point_array(p);combat.v79.position_owner(id,p)
    if e.time<=0:combat.adventure.teleport(id,p)
    e.next=float(e.next)-delta
    if float(e.next)<=0 and int(e.count)<6:e.next=.3;e.count=int(e.count)+1;lob(id,p,p,"bomb",float(e.damage))
   "bomb","splatter":
    if e.time<=0:
     var end:Vector2=combat.vec(e.end)
     if e.kind=="bomb":area(id,end,46,float(e.damage),.45,4 if combat.passive(id,"ember_infusion") else 3)
     else:area(id,end,38,float(e.damage));pool(id,end)
     var burst:Dictionary=add(id,"burst",end,.3);burst.radius=46.0;burst.fire=e.kind=="bomb"
   "pool":
    e.tick=float(e.tick)+delta
    if float(e.tick)>=.5:
     e.tick=0.0
     for key in combat.hostile(id):
      var f:Dictionary=combat.actor(key)
      if not f.is_empty() and bool(f.alive) and p.distance_to(f.pos)<=float(e.radius) and combat.path_clear(p,f.pos):
       combat.apply_status(key,"slow",.65,id,.7)
       if not bool(e.frost):combat.apply_status(key,"poison",1.2,id,2)
   "brew":
    e.next=float(e.next)-delta
    if e.next<=0:
     e.next=.7 if bool(e.gentle) else 1.0
     if bool(e.gentle):
      for ally in combat.party_heroes.friendly_near(id,p,150):combat.release_heroes.heal(id,str(ally),3)
     else:
      for key in combat.hostile(id):
       var f:Dictionary=combat.actor(key)
       if not f.is_empty() and bool(f.alive) and p.distance_to(f.pos)<=310 and combat.path_clear(p,f.pos):lob(id,p,f.pos,"splatter",float(e.damage))
  if e.time<=0:effects.remove_at(i)
func snapshot()->Dictionary:return {"effects":effects,"clock":clock}
func receive(data:Dictionary)->void:
 effects=data.get("effects",[]);clock=float(data.get("clock",clock))
 if combat.adventure.arcade:
  var g:Node=combat.adventure.game
  for e in effects:
   if e.kind=="flight" and str(e.owner)==str(g.my_id):g.local_pos=combat.vec(e.pos)
func draw_on(c:Node2D,camera:Vector2)->void:
 if not playing():return
 var visible:=Rect2(camera-Vector2(180,180),c.get_viewport_rect().size+Vector2(360,360))
 for e in effects:
  var p:Vector2=combat.vec(e.pos)-camera
  if not visible.has_point(combat.vec(e.pos)):continue
  match str(e.kind):
   "cleave":
    var aim:Vector2=combat.vec(e.aim);var angle:float=aim.angle()-1.0+float(e.age)/.34*2
    c.draw_line(p,p+Vector2.from_angle(angle)*float(e.radius)*.85,Color("#9bb8a5"),5,true)
    c.draw_arc(p,float(e.radius),angle-.28,angle+.12,12,Color("#c4f1c2"),6,true)
    c.draw_arc(p,float(e.radius)*.78,angle-.28,angle+.12,12,Color(.64,.91,.8,.4),3,true)
    var tip:=p+Vector2.from_angle(angle)*float(e.radius)
    c.draw_line(tip,tip+Vector2.from_angle(angle-.8)*-22,Color("#e3f7de"),3,true)
   "toll":
    var t:float=clampf((float(e.age)-.3)/.45,0,1)
    var lantern:Vector2=p+Vector2(0,-60*(1-clampf(float(e.age)/.3,0,1)))
    c.draw_line(p+Vector2(0,-22),lantern,Color("#829d8c"),4,true)
    c.draw_circle(lantern,11,Color("#c4f1c2"));c.draw_circle(lantern,18,Color(.5,.9,.65,.2))
    c.draw_arc(p,float(e.radius) if not bool(e.hit) else maxf(2,float(e.radius)*t),0,TAU,32,Color(.55,.94,.72,.3 if not bool(e.hit) else 1-t),3,true)
   "ride":pass
   "chain":
    var tint:Color=Color("#99d9f2") if bool(e.frost) else Color("#ffb768")
    c.draw_circle(p,10,tint);c.draw_arc(p,14,clock*4,clock*4+PI*1.7,15,tint,2,true)
    for n in 3:c.draw_circle(p+Vector2.from_angle(clock*4+n*1.7)*13,3,tint)
   "flight":
    c.draw_line(p+Vector2(-27,-29),p+Vector2(22,-34),Color("#b69761"),4,true)
    for n in 5:c.draw_line(p+Vector2(-26,-27+n*2),p+Vector2(-43,-32+n*4),Color("#d4bc83"),2,true)
    for n in 3:c.draw_circle(p+Vector2(-35-n*9,-22+sin(clock*5+n)*3),2,Color(.72,.76,.95,.5))
   "bomb","splatter":
    var end:Vector2=combat.vec(e.end)-camera;var start:Vector2=combat.vec(e.start)-camera;var t:float=clampf(float(e.age)/.6,0,1);var at:Vector2=start.lerp(end,t)-Vector2(0,35+sin(t*PI)*65)*(1-t)
    c.draw_arc(end,46 if e.kind=="bomb" else 38,0,TAU,18,Color(.9,.68,.4,.4) if e.kind=="bomb" else Color(.58,.76,.45,.4),1.5,true)
    c.draw_circle(at,6,Color("#f2b16c") if e.kind=="bomb" else Color("#91bd66"))
   "pool":
    var tint:Color=Color(.52,.78,.95,.3) if bool(e.frost) else Color(.43,.68,.27,.35)
    c.draw_circle(p,43,tint);c.draw_arc(p,43,0,TAU,20,Color(.66,.78,.46,minf(.7,float(e.time))),1.5,true)
    for n in 3:c.draw_circle(p+Vector2(sin(clock+n*2)*23,cos(n*2)*14),3,Color(.74,.9,.45,.6))
   "brew":
    c.draw_circle(p,150,Color(.53,.73,.45,.07));c.draw_arc(p,150,0,TAU,32,Color(.7,.8,.52,.25),1.5,true)
    c.draw_circle(p-Vector2(0,15),29,Color("#354653"));c.draw_rect(Rect2(p+Vector2(-24,-15),Vector2(48,23)),Color("#354653"));c.draw_arc(p-Vector2(0,26),28,0,TAU,24,Color("#899c8e"),4,true)
    c.draw_circle(p-Vector2(0,26),23,Color("#92b85e"));c.draw_line(p+Vector2(-20,7),p+Vector2(-25,17),Color("#65767b"),5);c.draw_line(p+Vector2(20,7),p+Vector2(25,17),Color("#65767b"),5)
    for n in 4:c.draw_circle(p+Vector2(sin(clock*2+n)*19,-30-fposmod(clock*15+n*12,45)),3,Color(.76,.85,.48,.6))
   "burst":
    c.draw_arc(p,float(e.radius)*float(e.age)/.3,0,TAU,20,Color(1,.68,.35,float(e.time)/.3) if bool(e.fire) else Color(.65,.8,.42,float(e.time)/.3),3,true)

func draw_mount(c:Node2D,id:String,camera:Vector2)->void:
 if not riding(id):return
 var p:Vector2=combat.owner_pos(id)-camera
 # Translucent spectral mount: galloping legs, neck, mane and ember hoofprints.
 c.draw_circle(p+Vector2(0,-16),30,Color(.4,.75,.67,.2));c.draw_line(p+Vector2(-24,-20),p+Vector2(22,-20),Color(.67,.9,.78,.8),22,true)
 c.draw_line(p+Vector2(18,-20),p+Vector2(25,-47),Color("#9bd9bd"),12,true);c.draw_line(p+Vector2(25,-47),p+Vector2(40,-41),Color("#bee4c3"),11,true)
 for n in 4:
  var leg:=p+Vector2(-20+n*12,-12);var foot:=leg+Vector2(sin(clock*9+n*PI/2)*11,25);c.draw_line(leg,foot,Color("#80c5b1"),4,true);c.draw_circle(foot,4,Color("#b8ead4"))
 c.draw_line(p+Vector2(-25,-21),p+Vector2(-41,-33+sin(clock*5)*7),Color("#92d5b9"),5,true)

func client_step(delta:float)->void:
 if not combat.adventure.arcade or not playing():return
 clock+=delta
 var g:Node=combat.adventure.game
 for e in effects:
  if e.kind=="flight" and str(e.owner)==str(g.my_id):
   e.age=minf(float(e.duration),float(e.age)+minf(delta,.1))
   var p:Vector2=combat.vec(e.start).lerp(combat.vec(e.end),clampf(float(e.age)/float(e.duration),0,1))
   e.pos=combat.point_array(p);g.local_pos=p
