extends Node
## Release roster: bounded authority-owned shots, fields, health costs and held control.
var combat:Node
var owl_gazes:Dictionary={}
var aim_state:Dictionary={}
var shots:Array=[]
var fields:Array=[]
var jumps:Dictionary={}
var classes:Dictionary={}
var holding_state:Dictionary={}
var debt:Dictionary={}
var covenants:Dictionary={}
var effects:Array=[]
var doors:Array=[]
var clock:=0.0
var received_at:=0
const STYLES=["acorn_hop","acorn_kick","canopy_crossing","chestnut_rain","safety_whistle","snack_break","crossing_patrol","hallpass_fan","blood_crescent","red_covenant","debt_reckoning","sanguine_lance","advanced_knowledge","classroom_management","master_key","return_ticket","recess_shelter","blood_bloom","owl_eyes"]
func reset()->void:
 owl_gazes.clear();aim_state.clear();shots.clear();fields.clear();jumps.clear();classes.clear();holding_state.clear();debt.clear();covenants.clear();effects.clear();doors.clear();clock=0
func holding(owner:String,value:bool,aim:Vector2=Vector2.ZERO)->void:
 holding_state[owner]=value
 if not aim.is_zero_approx() and is_finite(aim.x) and is_finite(aim.y):aim_state[owner]=aim.normalized()
func locked(owner:String)->bool:return jumps.has(owner)
func teaching(owner:String)->bool:return classes.has(owner)
func shot(owner:String,p:Vector2,aim:Vector2,amount:float,range_limit:float,style:String="acorn",radius:float=32)->void:
 if shots.size()>=64:return
 shots.append({"owner":owner,"pos":combat.point_array(p),"aim":combat.point_array(aim.normalized()),"damage":amount,"left":range_limit,"age":0.0,"bounce":0,"hits":[],"style":style,"radius":radius})
func flash(owner:String,p:Vector2,r:float,style:String="leaf",aim:Vector2=Vector2.RIGHT)->void:
 if effects.size()>=64:effects.pop_front()
 effects.append({"owner":owner,"pos":combat.point_array(p),"radius":r,"style":style,"aim":combat.point_array(aim),"time":.5})
func heal(owner:String,target:String,amount:int)->void:
 if target=="training_ally":
  if not combat.adventure.arcade and combat.adventure.game.practice:combat.adventure.game.training_yard.heal(combat.adventure.game,amount)
  return
 if target.begins_with("bgunit:") and combat.adventure.arcade and combat.adventure.game.mode=="battlegrounds":
  var bg=combat.adventure.game.battlegrounds
  if bg.units.has(target) and int(bg.units[target].team)==bg.side_of(owner):bg.units[target].hp=minf(float(bg.units[target].max_hp),float(bg.units[target].hp)+amount)
  return
 if not combat.adventure.alive(target) or not combat.v75.friendly(owner,target):return
 if combat.adventure.arcade:combat.adventure.game._heal(owner,target,amount)
 else:combat.classics.heal(owner,amount)
func pay(owner:String,amount:float)->float:
 var hp:float=combat.morrow.current_hp(owner);var spent:=minf(maxf(0,hp-1),amount)
 combat.morrow.set_hp(owner,hp-spent)
 # Spending health is a cost, not enemy damage, death, lifesteal or mastery farming.
 debt[owner]=minf(40,float(debt.get(owner,0))+spent)
 return spent
func area(owner:String,p:Vector2,r:float,amount:float,hits:Array,stats:Dictionary={})->void:
 for key in combat.hostile(owner):
  var actor:Dictionary=combat.actor(key)
  if hits.has(key) or actor.is_empty() or not bool(actor.alive) or p.distance_to(actor.pos)>r or not combat.path_clear(p,actor.pos):continue
  hits.append(key);combat.damage(key,amount,owner);combat.apply_hit_status(key,stats,owner)
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 aim=aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
 var p:Vector2=combat.owner_pos(owner);var reach:=float(stats.get("range",400));var target:Vector2=combat.v79.destination(owner,aim,reach)
 match style:
  "acorn_hop":shot(owner,p,aim,amount,reach)
  "acorn_kick":
   for key in combat.hostile(owner):
    var foe:Dictionary=combat.actor(key)
    if not foe.is_empty() and bool(foe.alive) and combat.v56.cone(p,aim,foe.pos,110,cos(PI*.3)) and combat.path_clear(p,foe.pos):combat.damage(key,amount,owner);combat.knock(key,aim,60)
   for s in shots:
    if str(s.owner)==owner and str(s.style)=="acorn" and p.distance_to(combat.vec(s.pos))<145:s.damage=float(s.damage)+8;s.radius=58;s.style="charged_acorn";s.aim=combat.point_array(aim)
   flash(owner,p,110,"kick",aim)
  "chestnut_rain":
   for n in 3:shot(owner,p,aim.rotated((n-1)*.3),amount,reach)
  "canopy_crossing":
   jumps[owner]={"from":combat.point_array(p),"to":combat.point_array(target),"time":0.0,"duration":.65,"damage":amount,"placed":0,"hits":[]}
  "safety_whistle","hallpass_fan":
   for n in (3 if style=="hallpass_fan" else 1):combat.launch_projectile(owner,p+aim*16,aim.rotated((n-1)*.22 if style=="hallpass_fan" else 0),{"range":reach,"speed":400,"color":"#f7d37b"},amount)
   for friend in combat.adventure.points():
    if combat.adventure.alive(str(friend)) and combat.v75.friendly(owner,str(friend)) and p.distance_to(combat.owner_pos(str(friend)))<110:combat.apply_status(combat.player_key(str(friend)),"guard",.8,owner,.08)
  "owl_eyes":
   owl_gazes[owner]={"time":2.0,"tick":0.0,"range":reach,"damage":amount,"aim":combat.point_array(aim)}
  "snack_break":
   if fields.size()>=24:fields.pop_front()
   fields.append({"owner":owner,"pos":combat.point_array(target),"style":"snack","time":4.0,"tick":0.0,"radius":float(stats.get("radius",120)),"heal":int(stats.get("healing",4)),"cleaned":[]})
  "recess_shelter":
   if fields.size()>=24:fields.pop_front()
   fields.append({"owner":owner,"pos":combat.point_array(target),"style":"shelter","time":4.0,"radius":145.0,"caught":0,"tick":0.0})
  "crossing_patrol":
   if fields.size()>=24:fields.pop_front()
   fields.append({"owner":owner,"pos":combat.point_array(p),"aim":combat.point_array(aim),"style":"patrol","time":3.0,"radius":105.0,"caught":0,"damage":amount,"hits":[]})
  "blood_crescent","sanguine_lance":
   var spent:=pay(owner,float(stats.get("health_cost",4)))
   if style=="sanguine_lance":combat.launch_projectile(owner,p,aim,{"range":reach,"speed":440,"color":"#ec7284"},amount)
   else:
    for key in combat.hostile(owner):
     var foe:Dictionary=combat.actor(key)
     if not foe.is_empty() and bool(foe.alive) and combat.v56.cone(p,aim,foe.pos,reach,cos(PI*.32)) and combat.path_clear(p,foe.pos):
      var before:float=combat.morrow.target_hp(key);combat.damage(key,amount,owner)
      if covenants.has(owner) and int(covenants[owner].uses)>0 and before>combat.morrow.target_hp(key):heal(owner,owner,3);covenants[owner].uses=int(covenants[owner].uses)-1
    flash(owner,p,reach,"blood",aim)
   if spent>0 and combat.passive(owner,"blood_reserve"):combat.apply_status(combat.player_key(owner),"guard",.6,owner,.1)
  "red_covenant":
   pay(owner,10);combat.apply_status(combat.player_key(owner),"guard",2,owner,.45);covenants[owner]={"time":4.0,"uses":3}
   flash(owner,p,55,"blood")
  "debt_reckoning":
   var bonus:float=minf(4,float(debt.get(owner,0))/10);debt[owner]=0
   for n in 5:shot(owner,p,aim.rotated((n-2)*.18),amount+bonus,reach,"blood_return",18)
  "blood_bloom":
   fields.append({"owner":owner,"pos":combat.point_array(target),"style":"bloom","time":1.2,"damage":amount+minf(8,float(debt.get(owner,0))*.2),"hits":[]});debt[owner]=0
  "advanced_knowledge":
   for key in combat.hostile(owner):
    var foe:Dictionary=combat.actor(key)
    if not foe.is_empty() and bool(foe.alive) and combat.v56.cone(p,aim,foe.pos,80,cos(PI*.28)) and combat.path_clear(p,foe.pos):combat.damage(key,amount,owner)
   combat.launch_projectile(owner,p+aim*18,aim,{"range":reach,"speed":390,"color":"#f5da8a"},float(stats.get("projectile_damage",11)))
   flash(owner,p,80,"knowledge",aim)
   if combat.passive(owner,"clear_explanation"):
    for friend in combat.adventure.points():
     if combat.adventure.alive(str(friend)) and combat.v75.friendly(owner,str(friend)) and p.distance_to(combat.owner_pos(str(friend)))<110:combat.apply_status(combat.player_key(str(friend)),"guard",1,owner,.08)
  "classroom_management":
   classes[owner]={"time":0.0,"duration":float(stats.get("duration",2.5)),"tick":0.0,"radius":float(stats.get("radius",155)),"damage":amount,"release_damage":float(stats.get("release_damage",16)),"captured":[]}
   # Remote input packets may follow the attack packet; assume held until one arrives.
   holding_state[owner]=true
  "master_key","return_ticket":
   doors.append({"owner":owner,"from":combat.point_array(p),"to":combat.point_array(target),"time":0.0,"style":style,"moved":false,"returned":false})
 return true
func release_class(owner:String)->void:
 if not classes.has(owner):return
 var cls:Dictionary=classes[owner];var p:Vector2=combat.owner_pos(owner)
 for key in combat.hostile(owner):
  var foe:Dictionary=combat.actor(key)
  if not foe.is_empty() and bool(foe.alive) and p.distance_to(foe.pos)<float(cls.radius)+25 and combat.path_clear(p,foe.pos):
   combat.damage(key,float(cls.release_damage),owner);combat.knock(key,(foe.pos-p).normalized(),150);combat.apply_status(key,"slow",1,owner,.7)
 flash(owner,p,float(cls.radius)+30,"release");classes.erase(owner)
func hostile_source(owner:String,source:String)->bool:
 return source=="enemy" or combat.adventure.arcade and combat.adventure.game.mode in ["arena","battlegrounds"] and combat.adventure.game._rival(owner,source)
func catch_shot(start:Vector2,end:Vector2,source:String)->bool:
 if not combat.adventure.authoritative():return false
 for owner in classes:
  if not hostile_source(str(owner),source):continue
  var p:Vector2=combat.owner_pos(str(owner));var nearest:=Geometry2D.get_closest_point_to_segment(p,start,end)
  if p.distance_to(nearest)<float(classes[owner].radius) and combat.path_clear(p,nearest):
   if classes[owner].captured.size()<24:classes[owner].captured.append(combat.point_array(nearest))
   return true
 for f in fields:
  if str(f.style) not in ["patrol","shelter"] or int(f.caught)>=(6 if str(f.style)=="shelter" else 16) or not hostile_source(str(f.owner),source):continue
  if str(f.style)=="shelter":
   var center:Vector2=combat.vec(f.pos)
   if center.distance_to(Geometry2D.get_closest_point_to_segment(center,start,end))<float(f.radius) and combat.path_clear(center,start):f.caught=int(f.caught)+1;return true
   continue
  var p:Vector2=combat.vec(f.pos);var side:Vector2=combat.vec(f.aim).orthogonal()*105
  if Geometry2D.segment_intersects_segment(start,end,p-side,p+side)!=null:f.caught=int(f.caught)+1;return true
 return false
func visual_offset(owner:String)->Vector2:
 if not jumps.has(owner):return Vector2.ZERO
 var jump:Dictionary=jumps[owner];return Vector2(0,-sin(clampf(float(jump.time)/float(jump.duration),0,1)*PI)*60)
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 for owner in owl_gazes.keys():
  var gaze:Dictionary=owl_gazes[owner]
  if not combat.adventure.alive(str(owner)):owl_gazes.erase(owner);continue
  var active_delta:=minf(delta,float(gaze.time));gaze.time=float(gaze.time)-delta;gaze.tick=float(gaze.tick)+active_delta
  var direction:Vector2=aim_state.get(owner,combat.vec(gaze.aim));gaze.aim=combat.point_array(direction)
  var p:Vector2=combat.owner_pos(str(owner))
  while float(gaze.tick)+.00001>=.25:
   gaze.tick=float(gaze.tick)-.25
   for key in combat.hostile(str(owner)):
    var foe:Dictionary=combat.actor(key)
    if foe.is_empty() or not bool(foe.alive):continue
    var offset:Vector2=foe.pos-p;var along:=absf(offset.dot(direction));var across:=absf(offset.dot(direction.orthogonal()))
    if along<=float(gaze.range) and across<=18 and combat.path_clear(p,foe.pos):combat.damage(key,float(gaze.damage),str(owner))
  if float(gaze.time)<=0:owl_gazes.erase(owner)
 for i in range(effects.size()-1,-1,-1):
  effects[i].time=float(effects[i].time)-delta
  if float(effects[i].time)<=0:effects.remove_at(i)
 for owner in covenants.keys():
  covenants[owner].time=float(covenants[owner].time)-delta
  if float(covenants[owner].time)<=0 or not combat.adventure.alive(str(owner)):covenants.erase(owner)
 for owner in debt.keys():
  if not combat.adventure.alive(str(owner)):debt.erase(owner)
 for owner in classes.keys():
  var cls:Dictionary=classes[owner]
  if not combat.adventure.alive(str(owner)) or combat.stunned(combat.player_key(str(owner))):classes.erase(owner);continue
  cls.time=float(cls.time)+delta;cls.tick=float(cls.tick)+delta
  var p:Vector2=combat.owner_pos(str(owner))
  if not bool(holding_state.get(owner,true)) or float(cls.time)>=float(cls.duration):release_class(str(owner));continue
  for n in cls.captured.size():cls.captured[n]=combat.point_array(combat.vec(cls.captured[n]).move_toward(p,90*delta))
  for key in combat.hostile(str(owner)):
   var foe:Dictionary=combat.actor(key)
   if foe.is_empty() or not bool(foe.alive) or p.distance_to(foe.pos)>float(cls.radius) or not combat.path_clear(p,foe.pos):continue
   # Pull is manual movement, so targets cannot attack while caught.
   combat.apply_status(key,"stun",.16,str(owner));combat.knock(key,(p-foe.pos).normalized(),minf(maxf(0,p.distance_to(foe.pos)-40),90*delta))
   if float(cls.tick)>=.5:combat.damage(key,float(cls.damage),str(owner))
  if float(cls.tick)>=.5:cls.tick=fmod(float(cls.tick),.5)
 for owner in jumps.keys():
  var j:Dictionary=jumps[owner]
  if not combat.adventure.alive(str(owner)):jumps.erase(owner);continue
  j.time=float(j.time)+delta;var t:=clampf(float(j.time)/float(j.duration),0,1)
  var a:Vector2=combat.vec(j.from);var b:Vector2=combat.vec(j.to)
  if combat.adventure.arcade:
   combat.adventure.game.positions[owner]=a.lerp(b,t)
   if str(owner)==combat.adventure.game.my_id:combat.adventure.game.local_pos=a.lerp(b,t)
  else:combat.adventure.teleport(str(owner),a.lerp(b,t))
  while int(j.placed)<3 and t>=float(j.placed)/3:
   var q:Vector2=a.lerp(b,(float(j.placed)+.5)/3)
   fields.append({"owner":str(owner),"pos":combat.point_array(q),"style":"trail","time":1.15,"damage":float(j.damage),"hits":j.hits});j.placed=int(j.placed)+1
  if t>=1:
   if combat.adventure.arcade:combat.adventure.teleport(str(owner),b)
   if combat.passive(str(owner),"woodland_footwork"):combat.apply_status(combat.player_key(str(owner)),"guard",1.5,str(owner),.15)
   jumps.erase(owner)
 for i in range(doors.size()-1,-1,-1):
  var d:Dictionary=doors[i];var owner:=str(d.owner);d.time=float(d.time)+delta
  if not combat.adventure.alive(owner):doors.remove_at(i);continue
  if not bool(d.moved) and float(d.time)>=.2:
   d.moved=true;combat.adventure.teleport(owner,combat.vec(d.to));heal(owner,owner,12 if str(d.style)=="master_key" else 6);combat.apply_status(combat.player_key(owner),"guard",2,owner,.2)
  if str(d.style)=="return_ticket" and not bool(d.returned) and float(d.time)>=3.2:
   d.returned=true
   if combat.adventure.can_stand(combat.vec(d.from)):combat.adventure.teleport(owner,combat.vec(d.from));flash(owner,combat.vec(d.from),45,"door")
  if float(d.time)>(3.8 if str(d.style)=="return_ticket" else .9):doors.remove_at(i)
 for i in range(shots.size()-1,-1,-1):
  var s:Dictionary=shots[i];var owner:=str(s.owner)
  if not combat.adventure.alive(owner):shots.remove_at(i);continue
  var old:Vector2=combat.vec(s.pos);var next:Vector2=old+combat.vec(s.aim)*300*delta;s.age=float(s.age)+delta;s.left=float(s.left)-300*delta
  if str(s.style)=="blood_return" and (float(s.left)<=0 or bool(s.get("returning",false))):
   s.returning=true;next=old.move_toward(combat.owner_pos(owner),450*delta)
   if next.distance_to(combat.owner_pos(owner))<18:shots.remove_at(i);continue
  if combat.v56.catch_shot(old,next,owner,float(s.damage),"#ddbd8a"):shots.remove_at(i);continue
  if not combat.path_clear(old,next):
   if str(s.style)=="blood_return" and not bool(s.get("returning",false)):s.returning=true;continue
   shots.remove_at(i);continue
  if str(s.style)=="blood_return":
   for key in combat.hostile(owner):
    var foe:Dictionary=combat.actor(key)
    if s.hits.has(key) or foe.is_empty() or not bool(foe.alive) or Geometry2D.get_closest_point_to_segment(foe.pos,old,next).distance_to(foe.pos)>20:continue
    var before:float=combat.morrow.target_hp(key);s.hits.append(key);combat.damage(key,float(s.damage),owner)
    if before>combat.morrow.target_hp(key) and int(s.get("healed",0))<2:heal(owner,owner,2);s.healed=int(s.get("healed",0))+1
  else:
   var bounce:=int(float(s.age)/.32)
   if bounce>int(s.bounce):s.bounce=bounce;area(owner,next,float(s.radius),float(s.damage),s.hits,{"slow_duration":1,"slow_factor":.7} if str(s.style)=="charged_acorn" else {});flash(owner,next,float(s.radius))
   if float(s.left)<=0:area(owner,next,float(s.radius),float(s.damage),s.hits);shots.remove_at(i);continue
  if float(s.age)>4:shots.remove_at(i);continue
  s.pos=combat.point_array(next)
 for i in range(fields.size()-1,-1,-1):
  var f:Dictionary=fields[i];var owner:=str(f.owner);var p:Vector2=combat.vec(f.pos);var active_delta:=minf(delta,maxf(0,float(f.time)));f.time=float(f.time)-delta
  if not combat.adventure.alive(owner):fields.remove_at(i);continue
  if str(f.style)=="bloom":
   if float(f.time)<=0:
    area(owner,p,120,float(f.damage),f.hits);flash(owner,p,120,"blood")
    if not f.hits.is_empty():heal(owner,owner,6)
    fields.remove_at(i)
   continue
  if str(f.style)=="shelter":
   if active_delta<=0:fields.remove_at(i);continue
   f.tick=float(f.tick)+active_delta
   for friend in combat.adventure.points():
    var id:=str(friend)
    if combat.adventure.alive(id) and combat.v75.friendly(owner,id) and p.distance_to(combat.owner_pos(id))<float(f.radius) and combat.path_clear(p,combat.owner_pos(id)):
     combat.apply_status(combat.player_key(id),"guard",.3,owner,.2)
     if float(f.tick)+.00001>=1:heal(owner,id,2)
   if float(f.tick)+.00001>=1:f.tick=maxf(0,float(f.tick)-1)
   if float(f.time)<=0:fields.remove_at(i)
   continue
  if str(f.style)=="trail":
   if float(f.time)<=0:area(owner,p,65,float(f.damage),f.hits,{"slow_duration":1.5,"slow_factor":.6});flash(owner,p,65);fields.remove_at(i)
   continue
  if float(f.time)<=0 and str(f.style)!="snack":fields.remove_at(i);continue
  if str(f.style)=="snack":
   f.tick=float(f.tick)+active_delta
   for friend in combat.adventure.points():
    var id:=str(friend)
    if not combat.adventure.alive(id) or not combat.v75.friendly(owner,id) or p.distance_to(combat.owner_pos(id))>float(f.radius) or not combat.path_clear(p,combat.owner_pos(id)):continue
    if id not in f.cleaned:
     f.cleaned.append(id);var status:Dictionary=combat.statuses.get(combat.player_key(id),{});status.erase("poison");status.erase("burn")
    if float(f.tick)+.00001>=1:heal(owner,id,int(f.heal))
    if combat.passive(owner,"shared_recess"):combat.apply_status(combat.player_key(id),"guard",.3,owner,.1)
   if float(f.tick)+.00001>=1:f.tick=maxf(0,float(f.tick)-1)
   if float(f.time)<=0:fields.remove_at(i)
  else:
   var end:Vector2=combat.v75.clip(p,combat.vec(f.aim),120*delta);f.pos=combat.point_array(end);var side:Vector2=combat.vec(f.aim).orthogonal()*105
   for key in combat.hostile(owner):
    var foe:Dictionary=combat.actor(key)
    if f.hits.has(key) or foe.is_empty() or not bool(foe.alive) or Geometry2D.get_closest_point_to_segment(foe.pos,end-side,end+side).distance_to(foe.pos)>28 or not combat.path_clear(end,foe.pos):continue
    f.hits.append(key);combat.damage(key,float(f.damage),owner);combat.knock(key,combat.vec(f.aim),70);combat.apply_status(key,"slow",1,owner,.65)
   for friend in combat.adventure.points():
    if combat.adventure.alive(str(friend)) and combat.v75.friendly(owner,str(friend)) and end.distance_to(combat.owner_pos(str(friend)))<130:combat.apply_status(combat.player_key(str(friend)),"guard",.3,owner,.2)
func follow_local()->void:
 if not combat.adventure.arcade or combat.adventure.authoritative():return
 var owner:String=combat.adventure.game.my_id
 if not jumps.has(owner):return
 var j:Dictionary=jumps[owner];var elapsed:float=(Time.get_ticks_msec()-received_at)/1000.0
 var t:=clampf((float(j.time)+elapsed)/float(j.duration),0,1)
 combat.adventure.game.local_pos=combat.vec(j.from).lerp(combat.vec(j.to),t)
func snapshot()->Dictionary:return {"owl_gazes":owl_gazes,"shots":shots,"fields":fields,"jumps":jumps,"classes":classes,"debt":debt,"covenants":covenants,"effects":effects,"doors":doors,"clock":clock}
func receive(d:Dictionary)->void:
 received_at=Time.get_ticks_msec()
 owl_gazes=d.get("owl_gazes",{});shots=d.get("shots",[]);fields=d.get("fields",[]);jumps=d.get("jumps",{});classes=d.get("classes",{});debt=d.get("debt",{});covenants=d.get("covenants",{});effects=d.get("effects",[]);doors=d.get("doors",[]);clock=float(d.get("clock",clock))
func draw_on(c:Node2D,camera:Vector2)->void:
 for owner in owl_gazes:
  var gaze:Dictionary=owl_gazes[owner];var p:Vector2=combat.owner_pos(str(owner))-camera;var aim:Vector2=combat.vec(gaze.aim)
  for side in [-1,1]:
   var world_start:Vector2=p+camera;var end:Vector2=combat.v75.clip(world_start,aim*float(side),float(gaze.range))-camera
   c.draw_line(p,end,Color(.9,.76,.3,.25),32,true);c.draw_line(p,end,Color(.9,.88,.5,.8),12,true);c.draw_line(p,end,Color(1,1,.85,.95),3,true)
  c.draw_arc(p,24,aim.angle()-.6,aim.angle()+.6,16,Color("#ffe48b"),3,true)
 for s in shots:
  var p:Vector2=combat.vec(s.pos)-camera
  if str(s.style)=="blood_return":c.draw_line(p-combat.vec(s.aim)*18,p,Color("#ef7a93"),4,true)
  else:
   var height:=sin(fmod(float(s.age),.32)/.32*PI)*28;c.draw_circle(p,8,Color(0,0,0,.2));p.y-=height;c.draw_circle(p,8,Color("#d6b779") if str(s.style)=="acorn" else Color("#a3eb8d"));c.draw_arc(p,9,PI,TAU,8,Color("#6f533b"),4)
 for f in fields:
  var p:Vector2=combat.vec(f.pos)-camera
  match str(f.style):
   "snack":
    c.draw_circle(p,float(f.radius),Color(.5,.8,.55,.16));c.draw_arc(p,float(f.radius),0,TAU,32,Color(.7,.9,.6,.6),2,true)
    c.draw_rect(Rect2(p-Vector2(20,14),Vector2(40,28)),Color("#cc967b"));c.draw_rect(Rect2(p-Vector2(15,10),Vector2(30,8)),Color("#ffe2a1"));c.draw_line(p+Vector2(-5,-5),p+Vector2(-5,8),Color.WHITE,2);c.draw_line(p+Vector2(-12,1),p+Vector2(2,1),Color.WHITE,2)
   "shelter":c.draw_circle(p,145,Color(.8,.85,.5,.13));c.draw_arc(p,145,0,TAU,48,Color(.9,.85,.6,.65),4,true)
   "bloom":c.draw_arc(p,120,0,TAU,32,Color(.9,.35,.5,.5),2,true);c.draw_circle(p,20*(1-float(f.time)/1.2),Color(.9,.3,.4,.5))
   "trail":c.draw_arc(p,65,0,TAU,24,Color(.65,.85,.4,.5),2,true);c.draw_circle(p,9,Color("#d6b779"))
   "patrol":
    var side:Vector2=combat.vec(f.aim).orthogonal()*105;c.draw_line(p-side,p+side,Color(.9,.85,.5,.7),7,true)
    for n in 5:
     var q:=p+side*(float(n)/2-1);c.draw_colored_polygon(PackedVector2Array([q+Vector2(-10,10),q+Vector2(10,10),q+Vector2(0,-14)]),Color("#f2be6b"));c.draw_line(q+Vector2(-5,0),q+Vector2(5,0),Color.WHITE,3)
 for owner in classes:
  var p:Vector2=combat.owner_pos(str(owner))-camera;var cls:Dictionary=classes[owner];var r:=float(cls.radius)
  c.draw_circle(p,r,Color(.4,.7,.8,.12));c.draw_arc(p,r,clock*3,clock*3+PI*1.7,48,Color(.7,.9,1,.65),3,true)
  for n in 8:
   var direction:=Vector2.from_angle(n*TAU/8+clock);var q:=p+direction*(r-fmod(clock*50,60));c.draw_line(q,q-direction*10,Color(.6,.9,1,.65),2,true)
  for held in cls.captured:c.draw_circle(combat.vec(held)-camera,5,Color("#f7d384"))
  c.draw_string(ThemeDB.fallback_font,p+Vector2(-50,-60),"RELEASE TO PUSH",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#d1edf5"))
 for d in doors:
  for key in ["from","to"]:
   var p:Vector2=combat.vec(d[key])-camera
   c.draw_rect(Rect2(p-Vector2(20,48),Vector2(40,66)),Color(.5,.85,1,.5));c.draw_rect(Rect2(p-Vector2(22,50),Vector2(44,68)),Color("#e9cc89"),false,3);c.draw_circle(p+Vector2(11,-12),3,Color("#f9e5ad"))
 for e in effects:
  var p:Vector2=combat.vec(e.pos)-camera;var alpha:=float(e.time)*2;var r:=float(e.radius)*(1-alpha*.5)
  var tint:=Color(1,.4,.5,alpha) if str(e.style)=="blood" else Color(.6,1,.55,alpha) if str(e.style)=="leaf" else Color(.8,.9,1,alpha)
  if str(e.style)!="knowledge":c.draw_arc(p,r,0,TAU,32,tint,3,true)
  if str(e.style)=="knowledge":
   var aim:Vector2=combat.vec(e.aim);c.draw_arc(p,float(e.radius),aim.angle()-PI*.28,aim.angle()+PI*.28,20,Color(1,.85,.55,alpha),4,true)
 for owner in debt:
  if not combat.adventure.alive(str(owner)):continue
  var p:Vector2=combat.owner_pos(str(owner))-camera;c.draw_rect(Rect2(p+Vector2(-20,-48),Vector2(40,4)),Color("#4e2636"));c.draw_rect(Rect2(p+Vector2(-20,-48),Vector2(float(debt[owner]),4)),Color("#ee788b"))
