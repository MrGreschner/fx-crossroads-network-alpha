extends Node
## Close fighters and support kits. All damage, healing and summons are host authoritative.
var combat:Node
var effects:Array=[]
var feathers:Dictionary={}
var clock:=0.0
var serial:=0
var life_ready:Dictionary={}
var rebirth:Dictionary={}
var rebirth_ready:Dictionary={}
const REED_TIME=.20
const REED_IMPACT=.07
const STYLES=["v90_wing","v90_ascent","v90_phoenix","v90_nest","v90_reed","v90_steps","v90_haven","v90_guides","v90_hook","v90_puppets","v90_curtain","v90_stage","v90_chop","v90_pot","v90_feast","v90_pepper","v90_rope","v90_lasso","v90_stampede","v90_posse","v91_scissors","v91_pistol"]
func reset()->void:effects.clear();feathers.clear();serial=0;rebirth.clear();life_ready.clear()
func moving(owner:String)->bool:return effects.any(func(e):return str(e.owner)==owner and str(e.style)=="travel")
func effect(owner:String,style:String,time:float,p:Vector2,aim:Vector2,damage:float=0,reach:float=100)->Dictionary:
 if effects.size()>=80:effects.pop_front()
 var e:Dictionary={"owner":owner,"style":style,"time":time,"duration":time,"pos":combat.point_array(p),"aim":combat.point_array(aim),"damage":damage,"range":reach,"tick":0.0,"hits":[],"stage":0};effects.append(e);return e
func bank(owner:String)->void:feathers[owner]=mini(3,int(feathers.get(owner,0))+1)
func hit(owner:String,p:Vector2,aim:Vector2,range_limit:float,amount:float,style:String,stats:Dictionary={})->Array:
 var struck:Array=[]
 for key in combat.hostile(owner):
  var f:Dictionary=combat.actor(key)
  if f.is_empty() or not bool(f.alive) or not primary_contains(style,p,aim,f.pos,range_limit) or not combat.path_clear(p,f.pos):continue
  combat.damage(key,amount,owner);struck.append(key)
  if style=="rope":
   combat.apply_status(key,"slow",float(stats.get("slow_duration",.6)),owner,.25)
   if combat.passive(owner,"true_grit"):
    for e in effects:
     if str(e.style)=="tied" and str(e.owner)==owner and str(e.get("target",""))==str(key) and not bool(e.get("used",false)):e.used=true;combat.release_heroes.heal(owner,owner,3)
  if style=="hook":combat.knock(key,(p-f.pos).normalized(),float(stats.get("pull",18)))
 if struck.is_empty():return struck
 if style=="wing":bank(owner)
 if style=="reed":
  var friends:Array=combat.party_heroes.friendly_near(owner,p,160);friends.sort_custom(func(a,b):return health_ratio(str(a))<health_ratio(str(b)))
  if not friends.is_empty():combat.release_heroes.heal(owner,str(friends[0]),2)
 if style=="hook" and combat.passive(owner,"shared_applause"):
  for id in units(owner):
   var u:Dictionary=combat.morrow.units[id]
   if str(u.family)=="puppet" and p.distance_to(combat.vec(u.pos))<180:u.hp=minf(float(u.max_hp),float(u.hp)+2)
 if style=="chop" and combat.passive(owner,"well_fed") and effects.any(func(e):return str(e.owner)==owner and str(e.style)=="pot" and p.distance_to(combat.vec(e.pos))<100):combat.apply_status(combat.player_key(owner),"guard",1,owner,.15)
 return struck
func health_ratio(id:String)->float:
 return combat.morrow.current_hp(id)/maxf(1,combat.morrow.max_hp(id))
func units(owner:String)->Array:return combat.morrow.units.keys().filter(func(id):return str(combat.morrow.units[id].owner)==owner and str(combat.morrow.units[id].get("family","")) in ["puppet","guide","deputy","stage"])
func summon(owner:String,family:String,hp:float,damage:float,time:float)->void:
 var cap:=4 if family=="puppet" else 1 if family=="stage" else 2
 if units(owner).filter(func(id):return str(combat.morrow.units[id].family)==family).size()>=cap:return
 serial+=1;var id:="risen:v90:"+str(serial);var offset:=Vector2.from_angle(serial*2.4)*35
 combat.morrow.units[id]={"owner":owner,"pos":combat.point_array(combat.v75.clip(combat.owner_pos(owner),offset,35)),"sprite":"stagelet" if family in ["puppet","stage"] else "lanternling" if family=="guide" else "deputyling","hp":hp,"max_hp":hp,"time":time,"ranged":false,"attack":.6,"contacts":{},"pose":"idle","family":family,"weight":1,"damage":damage,"speed":150,"reach":55,"interval":1.0,"guide_tick":0.0}
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var p:Vector2=combat.owner_pos(owner);var reach:float=float(stats.get("range",100))
 match style:
  "v91_scissors":
   var e:=effect(owner,"scissors",.4,p,aim,amount,reach);e.radius=float(stats.get("blast_radius",42));e.center=combat.point_array(combat.v75.clip(p,aim,reach))
  "v91_pistol":
   combat.launch_projectile(owner,p+aim*20,aim,dict_pistol(stats),amount);effect(owner,"muzzle",.16,p,aim)
  "v90_wing":effect(owner,"wing",.38,p,aim,amount,reach)
  "v90_reed","v90_hook","v90_chop","v90_rope":
   var type:="reed" if style=="v90_reed" else "hook" if style=="v90_hook" else "chop" if style=="v90_chop" else "rope"
   if type=="reed":
    var e:=effect(owner,type,REED_TIME,p,aim,amount,reach);e.stats=stats
   else:hit(owner,p,aim,reach,amount,type,stats);effect(owner,type,.4,p,aim,0,reach)
  "v90_ascent","v90_stampede":
   var extra:=int(feathers.get(owner,0))*35 if style=="v90_ascent" else 0;feathers[owner]=0 if style=="v90_ascent" else int(feathers.get(owner,0))
   var e:=effect(owner,"travel",.6 if style=="v90_ascent" else .5,p,aim,amount,reach+extra);e.start=combat.point_array(p);e.end=combat.point_array(combat.v75.clip(p,aim,reach+extra));e.ascent=style=="v90_ascent"
  "v90_phoenix":
   effect(owner,"smoke",5.5,p,aim,0,reach)
   var e:=effect(owner,"phoenix",1.2,p,aim,amount,reach);combat.release_heroes.heal(owner,owner,int(feathers.get(owner,0))*3);feathers[owner]=0
  "v90_steps":effect(owner,"steps",4,p,aim,0,reach)
  "v90_haven","v90_nest","v90_pot":effect(owner,"haven" if style=="v90_haven" else "nest" if style=="v90_nest" else "pot",5 if style!="v90_nest" else 6,p,aim,amount,reach)
  "v90_guides":for n in 2:summon(owner,"guide",25,5,8)
  "v90_puppets":for n in 2:summon(owner,"puppet",30,5,8)
  "v90_stage":summon(owner,"stage",75,12,8)
  "v90_posse":for n in 2:summon(owner,"deputy",45,8,8)
  "v90_curtain":effect(owner,"curtain",.9,p,aim,amount,reach)
  "v90_feast","v90_pepper":var e:=effect(owner,"feast",1.1,p,aim,amount,reach);e.pepper=style=="v90_pepper"
  "v90_lasso":
   var target:="";var best:=reach
   for key in combat.hostile(owner):
    var f:Dictionary=combat.actor(key)
    if not f.is_empty() and bool(f.alive) and p.distance_to(f.pos)<best and combat.v56.cone(p,aim,f.pos,reach,cos(.45)) and combat.path_clear(p,f.pos):target=str(key);best=p.distance_to(f.pos)
   var e:=effect(owner,"lasso",.4,p,aim,amount,reach);e.target=target
 return true
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 step_rebirth(delta)
 for owner in feathers.keys():
  if not combat.adventure.alive(str(owner)):feathers.erase(owner)
  elif combat.passive(str(owner),"ember_plumage") and int(feathers[owner])>0:combat.apply_status(combat.player_key(str(owner)),"guard",.2,str(owner),int(feathers[owner])*.02)
 for id in combat.morrow.units.keys():
  var u:Dictionary=combat.morrow.units[id]
  if str(u.get("family",""))!="guide":continue
  u.guide_tick=float(u.get("guide_tick",0))+delta
  if float(u.guide_tick)>=1:
   u.guide_tick=fmod(float(u.guide_tick),1);var friends:Array=combat.party_heroes.friendly_near(str(u.owner),combat.vec(u.pos),130);friends.sort_custom(func(a,b):return health_ratio(str(a))<health_ratio(str(b)))
   if not friends.is_empty():combat.release_heroes.heal(str(u.owner),str(friends[0]),2)
 for i in range(effects.size()-1,-1,-1):
  var e:Dictionary=effects[i];var owner:=str(e.owner);var active:=minf(delta,float(e.time));e.time=float(e.time)-delta;e.tick=float(e.tick)+active
  if not combat.adventure.alive(owner):effects.remove_at(i);continue
  var p:Vector2=combat.owner_pos(owner);var origin:Vector2=combat.vec(e.pos);var aim:Vector2=combat.vec(e.aim);var elapsed:=float(e.duration)-float(e.time)
  match str(e.style):
   "reed":
    if int(e.stage)==0 and elapsed>=REED_IMPACT:
     e.stage=1;hit(owner,origin,aim,float(e.range),float(e.damage),"reed",e.get("stats",{}))
   "scissors":
    if elapsed>=.18 and int(e.stage)==0:
     e.stage=1;var struck:=false;var center:Vector2=combat.vec(e.center)
     for key in combat.hostile(owner):
      var f:Dictionary=combat.actor(key)
      if not f.is_empty() and bool(f.alive) and center.distance_to(f.pos)<=float(e.radius) and combat.path_clear(p,f.pos):combat.damage(key,float(e.damage),owner);struck=true
     if struck and combat.passive(owner,"shared_applause"):
      for id in units(owner):
       var u:Dictionary=combat.morrow.units[id]
       if str(u.family)=="puppet" and center.distance_to(combat.vec(u.pos))<180:u.hp=minf(float(u.max_hp),float(u.hp)+2)
   "pull":
    var target:Dictionary=combat.actor(str(e.target))
    if not target.is_empty() and bool(target.alive):
     var goal:Vector2=combat.vec(e.destination);var step:Vector2=goal-target.pos
     combat.knock(str(e.target),step.normalized(),minf(step.length(),active*450))
   "wing":
    while int(e.stage)<2 and elapsed>=float(e.stage)*.16:
     hit(owner,p,aim.rotated((-.16 if int(e.stage)==0 else .16)),float(e.range),float(e.damage),"wing");e.stage=int(e.stage)+1
   "travel":
    var before:=p;var progress:=clampf(elapsed/float(e.duration),0,1);var destination:Vector2=combat.vec(e.start).lerp(combat.vec(e.end),progress)
    if bool(e.ascent):destination+=aim.orthogonal()*sin(progress*PI)*55
    var point:Vector2=combat.v75.clip(before,destination-before,before.distance_to(destination));combat.stance_heroes.place(owner,point)
    if not bool(e.ascent):
     for key in combat.hostile(owner):
      var f:Dictionary=combat.actor(key)
      if not f.is_empty() and bool(f.alive) and key not in e.hits and f.pos.distance_to(Geometry2D.get_closest_point_to_segment(f.pos,before,point))<45 and combat.path_clear(point,f.pos):e.hits.append(key);combat.damage(key,float(e.damage),owner);combat.knock(key,aim,35)
    if float(e.time)<=0:
     if bool(e.ascent):combat.v75.area(owner,point,85,float(e.damage),{"burn_duration":3,"burn_damage":2})
     combat.adventure.teleport(owner,point)
   "phoenix":
    while int(e.stage)<3 and elapsed>=float(e.stage)*.4:
     combat.v75.area(owner,p,float(e.range),float(e.damage),{"burn_duration":2,"burn_damage":2});e.stage=int(e.stage)+1
   "steps","haven","nest","pot":
    while float(e.tick)+.0001>=1:
     e.tick=float(e.tick)-1;var centres:Array=[origin]
     if str(e.style)=="steps":centres=[p-aim*30,p-aim*70,p-aim*110]
     var hit_friends:Array=[];var hit_foes:Array=[]
     for centre in centres:
      var radius:float=40 if str(e.style)=="steps" else float(e.range)
      for id in combat.party_heroes.friendly_near(owner,centre,radius):
       if id in hit_friends:continue
       hit_friends.append(id);combat.release_heroes.heal(owner,str(id),2 if str(e.style)=="steps" else 4 if str(e.style)=="haven" else 3)
       if str(e.style)=="haven":combat.apply_status(combat.player_key(str(id)),"guard",1.2,owner,.15)
       if str(e.style)=="steps" and not str(id) in e.hits:cleanse(combat.player_key(str(id)),["slow"]);e.hits.append(str(id))
      for key in combat.hostile(owner):
       var f:Dictionary=combat.actor(key)
       if f.is_empty() or not bool(f.alive) or key in hit_foes or centre.distance_to(f.pos)>radius or not combat.path_clear(centre,f.pos):continue
       hit_foes.append(key)
       if str(e.style) in ["pot","nest"]:combat.damage(key,float(e.damage) if str(e.style)=="pot" else 3,owner)
       if str(e.style)!="nest":combat.apply_status(key,"slow",1.2,owner,.25)
   "curtain":
    if elapsed>=.6 and int(e.stage)==0:
     e.stage=1;combat.v75.area(owner,origin,float(e.range),float(e.damage),{"stun_duration":1})
     for id in units(owner):combat.apply_status("p:"+str(id),"guard",3,owner,.2)
   "feast":
    if elapsed>=1 and int(e.stage)==0:
     e.stage=1;combat.v75.area(owner,origin,float(e.range),float(e.damage),{"burn_duration":3 if bool(e.pepper) else 0,"burn_damage":2})
     for id in combat.party_heroes.friendly_near(owner,origin,float(e.range)):combat.release_heroes.heal(owner,str(id),8 if bool(e.pepper) else 18);cleanse(combat.player_key(str(id)),["poison","burn"])
   "lasso":
    if elapsed>=.3 and int(e.stage)==0:
     e.stage=1;var f:Dictionary=combat.actor(str(e.target))
     if not f.is_empty() and bool(f.alive) and p.distance_to(f.pos)<=float(e.range) and combat.path_clear(p,f.pos):
      combat.damage(str(e.target),float(e.damage),owner);combat.apply_status(str(e.target),"stun",2.0,owner);var tie:=effect(owner,"tied",2.0,f.pos,aim);tie.target=e.target;tie.used=false
      var pull:=effect(owner,"pull",.4,f.pos,aim);pull.target=e.target;pull.destination=combat.point_array(p+(f.pos-p).normalized()*48)
  if float(e.time)<=0:effects.remove_at(i)
func snapshot()->Dictionary:return {"effects":effects,"feathers":feathers,"clock":clock,"rebirth":rebirth,"rebirth_ready":rebirth_ready}
func receive(d:Dictionary)->void:effects=d.get("effects",[]);feathers=d.get("feathers",{});clock=float(d.get("clock",0));rebirth=d.get("rebirth",{});rebirth_ready=d.get("rebirth_ready",{})
func draw_on(c:Node2D,camera:Vector2)->void:
 if not combat.playing():return
 for owner in rebirth:
  var p:Vector2=combat.vec(rebirth[owner].pos)-camera
  c.draw_circle(p,24,Color(.7,.25,.12,.25));c.draw_arc(p,35,0,TAU,24,Color("#f4ba76"),2,true)
  for n in 8:c.draw_circle(p+Vector2.from_angle(n*TAU/8+clock)*25,3,Color("#ffcf8f"))
  c.draw_string(ThemeDB.fallback_font,p+Vector2(-40,-85),"REBIRTH "+str(ceili(float(rebirth[owner].left))),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ffe4aa"))
 for owner in combat.adventure.points():
  if not combat.adventure.alive(str(owner)) or combat.v78.hero(str(owner))!="cindervane":continue
  var p:Vector2=draw_position(str(owner))-camera
  for n in int(feathers.get(owner,0)):c.draw_line(p+Vector2(-12+n*10,-60),p+Vector2(-8+n*10,-70),Color("#ffd09a"),3,true)
 for owner in combat.adventure.points():
  if combat.adventure.alive(str(owner)) and combat.passive(str(owner),"waylight_life"):
   var center:Vector2=draw_position(str(owner))-camera
   c.draw_arc(center,160,0,TAU,40,Color(.65,.87,.57,.18),1,true)
 for e in effects:
  var p:Vector2=combat.vec(e.pos)-camera;var owner:=str(e.owner);var aim:Vector2=combat.vec(e.aim);var t:=clampf(1-float(e.time)/float(e.duration),0,1);var r:=float(e.range);var side:=aim.orthogonal()
  match str(e.style):
   "scissors":
    var center:Vector2=combat.vec(e.center)-camera;var spread:float=38*(1-t)
    for n in [-1,1]:
     c.draw_line(p+side*n*22,center+side*n*spread,Color("#d9a5dd"),3,true)
     c.draw_line(center+side*n*spread-aim*22,center-side*n*spread+aim*22,Color("#f4d6ef"),4,true)
    c.draw_circle(center,5,Color("#ffecb3"))
   "muzzle":
    c.draw_line(p+aim*22,p+aim*42,Color("#ffe09a"),5,true)
    for n in [-1,1]:c.draw_line(p+aim*25,p+aim*38+side*n*9,Color("#eca956"),3,true)
   "wing","phoenix":
    p=draw_position(owner)-camera
    for n in 5:
     var angle:=aim.angle()+(t*PI-.5)*(-1 if n%2 else 1);var end:=p+Vector2.from_angle(angle)*r;c.draw_line(p+Vector2.from_angle(angle)*30,end,Color(1,.64,.3,(1-t)*.8),4,true)
   "travel":
    p=draw_position(owner)-camera
    if bool(e.ascent):
     var texture:Texture2D=combat.adventure.game.art.get("cindervane_open")
     if texture!=null:c.draw_texture_rect(texture,Rect2(p-Vector2(45,62),Vector2(90,80)),false)
    else:
     for n in 6:c.draw_circle(p-aim*n*12+side*sin(n+clock*8)*10,7-n*.6,Color(.8,.65,.43,.4-n*.04))
   "reed","hook","rope":
    var path:=PackedVector2Array()
    var reed_length:=1.0
    if str(e.style)=="reed":reed_length=clampf((float(e.duration)-float(e.time))/REED_IMPACT,0,1) if float(e.time)>=REED_TIME-REED_IMPACT-.025 else clampf(float(e.time)/(REED_TIME-REED_IMPACT-.025),0,1)
    for n in 18:path.append(p+aim*(n/17.0*(maxf(0,r-12)*reed_length if str(e.style)=="reed" else r))+side*sin(n/17.0*PI)*sin(t*PI)*(4 if str(e.style)=="reed" else 35))
    c.draw_polyline(path,Color("#9ed6af") if str(e.style)=="reed" else Color("#dca9d6") if str(e.style)=="hook" else Color("#e5c58c"),3,true)
    c.draw_circle(path[-1],12 if str(e.style)=="reed" else 5,Color("#edd8aa"))
   "chop":
    draw_sector(c,p,aim,r,PI*.28,Color(.95,.82,.65,.1*(1-t)))
    c.draw_arc(p,r,aim.angle()-PI*.28,aim.angle()+PI*.28,24,Color(.95,.82,.65,.75*(1-t)),2,true)
    var end:=p+aim*(r-14);c.draw_line(p+aim*20,end,Color("#f7dec2"),4,true)
    c.draw_colored_polygon(PackedVector2Array([end-side*10,end+side*10,end+aim*12]),Color("#b5c8ca"))
   "steps","haven","nest","pot":
    if str(e.style)=="steps":p=draw_position(owner)-camera
    var tint:=Color("#d9b770") if str(e.style) in ["pot","nest"] else Color("#a9e0c7")
    var centres:Array=[p] if str(e.style)!="steps" else [p-aim*30,p-aim*70,p-aim*110]
    for centre in centres:
     var radius:=35.0 if str(e.style)=="steps" else r;c.draw_circle(centre,radius,Color(tint,.08));c.draw_arc(centre,radius,0,TAU,32,Color(tint,.45),2,true)
     if str(e.style)=="pot":c.draw_arc(centre,18,0,PI,18,tint,6,true);c.draw_line(centre-Vector2(21,0),centre+Vector2(21,0),tint,3);c.draw_circle(centre-Vector2(0,8+fposmod(clock*15,18)),4,Color(tint,.6))
     else:
      for n in 4:c.draw_line(centre+Vector2.from_angle(clock+n*TAU/4)*18,centre+Vector2.from_angle(clock+n*TAU/4)*26,tint,3,true)
   "curtain":
    c.draw_rect(Rect2(p-Vector2(r,r*.4),Vector2(r*2,r*.8)),Color(.57,.26,.48,.13))
    for side_n in [-1,1]:c.draw_line(p+Vector2(side_n*r*(1-t),-r*.35),p+Vector2(side_n*r*(1-t),r*.35),Color("#bd78aa"),12,true)
   "feast":
    c.draw_arc(p,r,0,TAU,36,Color(1,.7,.4,.5),2,true)
    for n in 12:c.draw_circle(p+Vector2.from_angle(n*TAU/12+clock)*r*t,5,Color(1,.58,.2,1-t))
   "smoke":
    c.draw_circle(p,r,Color(.58,.65,.68,.1))
    c.draw_arc(p,r,0,TAU,40,Color(.82,.84,.78,.55),2,true)
    for n in 7:
     var q:=p+Vector2.from_angle(n*TAU/7+clock*.18)*r*.56
     c.draw_circle(q,16+sin(clock*2+n)*4,Color(.65,.69,.72,.13))
   "lasso","tied":
    var f:Dictionary=combat.actor(str(e.get("target","")));var end:Vector2=f.pos-camera if not f.is_empty() else p+aim*r
    c.draw_line(draw_position(owner)-camera,end,Color("#cdae78"),3,true);c.draw_arc(end,23,0,TAU,24,Color("#edcc8f"),3,true)

func cleanse(key:String,kinds:Array)->void:
 if not combat.statuses.has(key):return
 for kind in kinds:combat.statuses[key].erase(kind)

func dict_pistol(stats:Dictionary)->Dictionary:
 var s:=stats.duplicate(true);s.color="#ffd9a0";s.pistol=true;return s
func pistol_hit(owner:String,key:String)->void:
 if not combat.passive(owner,"true_grit"):return
 for e in effects:
  if str(e.style)=="tied" and str(e.owner)==owner and str(e.get("target",""))==key and not bool(e.get("used",false)):e.used=true;combat.release_heroes.heal(owner,owner,3)
func pending_rebirth(owner:String)->bool:return rebirth.has(owner)
func intercept_defeat(owner:String)->bool:
 if not combat.adventure.authoritative() or not combat.passive(owner,"ash_rebirth") or clock<float(rebirth_ready.get(owner,0)) or rebirth.has(owner):return false
 rebirth[owner]={"left":3.0,"pos":combat.point_array(combat.owner_pos(owner))};rebirth_ready[owner]=clock+120
 var g=combat.adventure.game
 if combat.adventure.arcade:
  g.health[owner]=0;g.respawn_at[owner]=9223372036854775807;g.downed.erase(owner)
 else:g.health=0;g.charge_time=0;g.dodge_time=0
 return true
func step_rebirth(delta:float)->void:
 for owner in rebirth.keys():
  var state:Dictionary=rebirth[owner];state.left=float(state.left)-delta
  if float(state.left)>0:continue
  var g=combat.adventure.game;var point:Vector2=combat.vec(state.pos)
  if combat.adventure.arcade:
   if not g.positions.has(owner):rebirth.erase(owner);continue
   g.health[owner]=maxi(1,roundi(g._max_hp(owner)*.5));g.positions[owner]=point;g.downed.erase(owner);g.respawn_at[owner]=0;g.invincible_until[owner]=Time.get_ticks_msec()+800
   if owner==g.my_id:g.local_pos=point
  else:g.health=g.max_health()*.5;g.position_in_world=point;g.invulnerable_time=.8;g.stun_time=0
  combat.statuses.erase(combat.player_key(owner));rebirth.erase(owner);combat.adventure.teleport(owner,point)
  combat.visuals.append({"pos":combat.point_array(point),"radius":65,"time":.7,"color":"#ffcf83"})

func primary_contains(style:String,p:Vector2,aim:Vector2,point:Vector2,reach:float)->bool:
 if style=="reed":
  var end:=p+aim*maxf(0,reach-12)
  return (point-p).dot(aim)>=0 and point.distance_to(Geometry2D.get_closest_point_to_segment(point,p,end))<=12
 return combat.v56.cone(p,aim,point,reach,cos(PI*.28))
func draw_sector(c:Node2D,p:Vector2,aim:Vector2,r:float,half:float,tint:Color)->void:
 var points:=PackedVector2Array([p])
 for n in 25:points.append(p+Vector2.from_angle(aim.angle()-half+n/24.0*half*2)*r)
 c.draw_colored_polygon(points,tint)
func smoke_chance(id:String)->float:
 if not combat.adventure.alive(id):return 0
 var p:Vector2=combat.owner_pos(id)
 for e in effects:
  if str(e.style)=="smoke" and float(e.time)>0 and combat.v75.friendly(str(e.owner),id) and p.distance_to(combat.vec(e.pos))<=float(e.range) and combat.path_clear(p,combat.vec(e.pos)):return .12
 return 0
func smoke_dodges(id:String,roll:float=-1)->bool:
 var chance:=smoke_chance(id)
 if chance<=0 or (randf() if roll<0 else roll)>=chance:return false
 combat.visuals.append({"pos":combat.point_array(combat.owner_pos(id)),"radius":28,"time":.25,"color":"#d9e0de"})
 return true
func on_hit(owner:String,amount:float)->void:
 combat.halloween.on_hit(owner,amount)
 if amount<=0 or combat.dot_damage or not combat.adventure.alive(owner) or clock<float(life_ready.get(owner,0)):return
 var p:Vector2=combat.owner_pos(owner)
 for id in combat.adventure.points():
  if combat.adventure.alive(str(id)) and combat.passive(str(id),"waylight_life") and combat.v75.friendly(str(id),owner) and p.distance_to(combat.owner_pos(str(id)))<=160 and combat.path_clear(p,combat.owner_pos(str(id))):
   life_ready[owner]=clock+.75;combat.release_heroes.heal(str(id),owner,2);return

func draw_position(owner:String)->Vector2:
 var p=combat.owner_pos(owner);var game=combat.adventure.game
 return game.melee_visual_position(owner,p) if game.has_method("melee_visual_position") else p
