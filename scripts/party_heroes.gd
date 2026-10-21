extends Node
## Team-aware support shots, bounded summons and control fields; only authority mutates health.
var combat:Node
var shots:Array=[]
var fields:Array=[]
var flashes:Array=[]
var quiet:Dictionary={}
var marks:Dictionary={}
var clock:=0.0
var serial:=0
const STYLES=["patch_buddies","mosaic_bubbles","kindred_dart","kindred_fan","lumen_relay","lumen_sanctuary","heavy_kindred","harbor_note","rescue_buoy","safe_passage","harbor_mend","hush_buoy","mosaic_seed","mosaic_scatter","mosaic_guardian","mosaic_ward","mosaic_parade","apiary_needle","hive_lantern","swarm_relay","apiary_crook","honey_court","bailiff_thread","traffic_order","quiet_court","inward_order","twin_threads"]
func reset()->void:shots.clear();fields.clear();flashes.clear();quiet.clear();marks.clear();clock=0;serial=0
func family_units(owner:String,family:String)->Array:
 return combat.morrow.units.keys().filter(func(id):return str(combat.morrow.units[id].owner)==owner and str(combat.morrow.units[id].get("family",""))==family)
func slots(owner:String,family:String)->int:
 var count:=0
 for id in family_units(owner,family):count+=int(combat.morrow.units[id].get("weight",1))
 return count
func prepare(owner:String,stats:Dictionary)->bool:
 var style:=str(stats.get("style",""))
 # A full garden can still be commanded with primary; casting does not overfill it.
 if style=="hive_lantern" and slots(owner,"apiary")>=(4 if combat.passive(owner,"royal_hive") else 3):combat.adventure.announce("Your hive is at capacity.");return false
 if style in ["mosaic_scatter","mosaic_guardian","mosaic_ward","mosaic_parade","swarm_relay"] and family_units(owner,"mosaic" if style.begins_with("mosaic") else "apiary").is_empty():combat.adventure.announce("Summon companions first.");return false
 return true
func can_seed(owner:String)->bool:
 var ids:=family_units(owner,"mosaic");var small:=0;var large:=false
 for id in ids:
  if int(combat.morrow.units[id].weight)>1:large=true
  else:small+=1
 return slots(owner,"mosaic")<5 or (large and small<2 and slots(owner,"mosaic")<7)
func mark_target(owner:String,point:Vector2,aim:Vector2)->void:
 var best:=42.0;var chosen:="";var origin:Vector2=combat.owner_pos(owner)
 for key in combat.hostile(owner):
  var a:Dictionary=combat.actor(key)
  if a.is_empty() or not bool(a.alive) or origin.distance_to(a.pos)>600 or not combat.path_clear(origin,a.pos):continue
  var distance:float=point.distance_to(a.pos)
  if combat.adventure.game.mobile.enabled:
   if not combat.v56.cone(origin,aim,a.pos,600,.985):continue
   distance=origin.distance_to(a.pos)/15
  if distance<best:best=distance;chosen=key
 if not chosen.is_empty():marks[owner]=chosen
func preferred(owner:String)->String:
 var key:String=str(marks.get(owner,""));var a:Dictionary=combat.actor(key) if not key.is_empty() else {}
 if a.is_empty() or not bool(a.alive) or not combat.adventure.alive(owner):marks.erase(owner);return ""
 return key
func add_unit(owner:String,p:Vector2,family:String,weight:int=1,hp:float=-1,time:float=14)->String:
 serial+=1;var id:="risen:party:"+str(serial);var max_hp:float=32*weight if family=="mosaic" else 38
 combat.morrow.units[id]={"owner":owner,"pos":combat.point_array(p),"sprite":"mosaicling" if family=="mosaic" else "hive_drone","hp":max_hp if hp<0 else minf(hp,max_hp),"max_hp":max_hp,"time":time,"ranged":family=="apiary","attack":.4,"contacts":{},"pose":"idle","family":family,"weight":weight,"damage":7+4*(weight-1) if family=="mosaic" else 6,"speed":125-5*(weight-1) if family=="mosaic" else 155,"reach":58 if family=="mosaic" else 260,"interval":1.2 if family=="mosaic" else 1.3}
 return id
func flash(p:Vector2,r:float,tint:String)->void:
 if flashes.size()>=64:flashes.pop_front()
 flashes.append({"pos":combat.point_array(p),"radius":r,"time":.6,"color":tint})
func field(owner:String,p:Vector2,style:String,time:float,radius:float,damage:float=0,aim:Vector2=Vector2.RIGHT)->void:
 if fields.size()>=32:fields.pop_front()
 fields.append({"owner":owner,"pos":combat.point_array(p),"style":style,"time":time,"tick":0.0,"radius":radius,"damage":damage,"aim":combat.point_array(aim),"hits":[],"caught":0})
func kindred(owner:String,p:Vector2,aim:Vector2,damage:float,healing:float,reach:float)->void:
 if shots.size()>=96:return
 shots.append({"owner":owner,"pos":combat.point_array(p+aim*20),"aim":combat.point_array(aim),"left":reach,"damage":damage,"heal":healing,"ground":false,"life":reach/350.0+1.5})
func merge(owner:String,forced:bool=false)->void:
 var ids:=family_units(owner,"mosaic")
 if ids.size()<2:return
 ids.sort_custom(func(a,b):return int(combat.morrow.units[a].weight)>int(combat.morrow.units[b].weight))
 var first:String=str(ids[0]);var p:Vector2=combat.vec(combat.morrow.units[first].pos);var count:=int(combat.morrow.units[first].weight);var health:=float(combat.morrow.units[first].hp)
 for id in ids.slice(1):
  var u:Dictionary=combat.morrow.units[id]
  if count+int(u.weight)<=5 and (forced or p.distance_to(combat.vec(u.pos))<90):
   count+=int(u.weight);health+=float(u.hp);combat.morrow.units.erase(id)
 if count==int(combat.morrow.units[first].weight):return
 var unit:Dictionary=combat.morrow.units[first];unit.weight=count;unit.hp=health;unit.max_hp=32*count;unit.damage=7+4*(count-1);unit.speed=125-5*(count-1);unit.time=14.0+3*(count-1);flash(p,24+count*5,"#d4b2ef")
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var p:Vector2=combat.owner_pos(owner);var reach:=float(stats.get("range",400));var end:Vector2=combat.v79.destination(owner,aim,reach)
 match style:
  "kindred_dart","heavy_kindred":kindred(owner,p,aim,amount,float(stats.get("healing",7)),reach)
  "kindred_fan":
   for n in 5:kindred(owner,p,aim.rotated((n-2)*.19),amount,4,reach)
  "lumen_relay":field(owner,end,"relay",3,140)
  "lumen_sanctuary":field(owner,end,"sanctuary",4,140)
  "harbor_note":
   combat.add_ring(owner,p,{"style":"harbor_note","follow_owner":true,"radius":115,"slow_duration":.8,"slow":.75,"color":"#8fdde5"},amount)
   if combat.passive(owner,"harbor_watch"):
    for friend in friendly_near(owner,p,110):combat.apply_status(combat.player_key(friend),"guard",.8,owner,.1)
  "harbor_mend":field(owner,p,"mend",1,90)
  "rescue_buoy":field(owner,end,"buoy",4,110)
  "hush_buoy":field(owner,end,"hush",4,125)
  "safe_passage":field(owner,p,"passage",3,105,0,aim)
  "patch_buddies":
   for n in int(stats.get("count",2)):
    var created:=add_unit(owner,combat.v75.clip(p,aim.rotated(-.7 if n%2==0 else .7),65),"patch",1,-1,float(stats.get("duration",9))+(2 if combat.passive(owner,"long_buddies") else 0))
    var u:Dictionary=combat.morrow.units[created];u.sprite="bit_buddy";u.hp=45;u.max_hp=45;u.damage=amount;u.speed=float(stats.get("minion_speed",255));u.reach=56;u.interval=1.0;u.ranged=false
  "mosaic_bubbles":
   for n in 5:
    if shots.size()>=96:break
    var dir:Vector2=aim.rotated((n-2)*.2)
    shots.append({"owner":owner,"pos":combat.point_array(p+dir*24),"aim":combat.point_array(dir),"bubble":true,"left":reach,"life":reach/300,"damage":amount,"radius":12+float(stats.get("charge_power",0))*8})
  "mosaic_seed":
   mark_target(owner,end,aim)
   if can_seed(owner):add_unit(owner,combat.v75.clip(p,aim,45),"mosaic")
  "mosaic_scatter":
   var old:=family_units(owner,"mosaic")
   for id in old:
    var unit:Dictionary=combat.morrow.units[id];var count:=int(unit.weight);var hp:=float(unit.hp)/count;var time:=float(unit.time);var origin:Vector2=combat.vec(unit.pos);combat.morrow.units.erase(id)
    for n in count:
     var created:=add_unit(owner,combat.v75.clip(origin,Vector2.from_angle(n*TAU/count),30),"mosaic",1,hp,time);combat.morrow.units[created]["rally"]=combat.point_array(end);combat.morrow.units[created]["rally_time"]=3.0;combat.morrow.units[created]["haste"]=4.0
   quiet[owner]=-4.0;flash(end,60,"#d4b2ef")
  "mosaic_ward":
   for id in family_units(owner,"mosaic"):combat.apply_status("p:"+str(id),"guard",3,owner,.3)
  "mosaic_guardian":
   merge(owner,true)
   for id in family_units(owner,"mosaic"):combat.morrow.units[id]["empowered"]=5.0
   combat.v75.area(owner,p,130,amount,{"slow_duration":1.5,"slow":.6});flash(p,130,"#d4b2ef")
  "mosaic_parade":
   for id in family_units(owner,"mosaic"):
    var unit:Dictionary=combat.morrow.units[id];unit.march=combat.point_array(end);unit.march_time=3.0;unit.burst=amount*int(unit.weight)
  "apiary_needle":
   var opts:Dictionary=stats.duplicate(true);opts.speed=360;opts.color="#f4cb72"
   combat.launch_projectile(owner,p+aim*18,aim,opts,amount)
  "apiary_crook":combat.v75.area(owner,p+aim*50,60,amount,{"slow_duration":1.5,"slow":.65});flash(p+aim*50,60,"#f4cb72")
  "hive_lantern":
   var cap:=4 if combat.passive(owner,"royal_hive") else 3
   for n in mini(2,cap-slots(owner,"apiary")):add_unit(owner,combat.v75.clip(end,aim.orthogonal()*(1 if n==0 else -1),25),"apiary",1,-1,16)
  "swarm_relay":
   var ids:=family_units(owner,"apiary")
   for n in ids.size():
    var u:Dictionary=combat.morrow.units[ids[n]];var point:Vector2=combat.v75.clip(end,Vector2.from_angle(n*TAU/ids.size()),70);u.pos=combat.point_array(point)
    for j in 3:combat.launch_projectile(owner,point,aim.rotated((j-1)*.12),{"range":400,"speed":340,"color":"#f4cb72"},amount)
   flash(end,90,"#f4cb72")
  "honey_court":field(owner,end,"honey",4,140,amount)
  "bailiff_thread","twin_threads":
   for n in (2 if style=="twin_threads" else 1):combat.launch_projectile(owner,p+aim*18,aim.rotated((n-.5)*.13 if style=="twin_threads" else 0),{"range":reach,"speed":330,"color":"#d6a7f2","slow_duration":1.2,"slow":.6},amount)
  "traffic_order","inward_order":
   field(owner,end,"inward" if style=="inward_order" else "order",3,145,amount,aim)
   if combat.passive(owner,"due_process"):combat.apply_status(combat.player_key(owner),"guard",2,owner,.2)
  "quiet_court":field(owner,end,"court",.8,150,amount)
 return true
func friendly_near(owner:String,p:Vector2,r:float)->Array:
 var ids:Array=[]
 for id in combat.adventure.points():
  if combat.adventure.alive(str(id)) and combat.v75.friendly(owner,str(id)) and p.distance_to(combat.owner_pos(str(id)))<=r and combat.path_clear(p,combat.owner_pos(str(id))):ids.append(str(id))
 if combat.adventure.arcade and combat.adventure.game.mode=="battlegrounds":
  var bg=combat.adventure.game.battlegrounds
  for key in bg.units:
   if int(bg.units[key].team)==bg.side_of(owner) and p.distance_to(bg.units[key].pos)<=r and combat.path_clear(p,bg.units[key].pos):ids.append(str(key))
 return ids
func heal(owner:String,id:String,amount:int)->void:combat.release_heroes.heal(owner,id,amount)
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 for owner in marks.keys():preferred(str(owner))
 for owner in combat.adventure.points():
  if combat.v78.hero(str(owner))!="mosaic":continue
  var foes_near:=false
  for key in combat.hostile(str(owner)):
   var foe:Dictionary=combat.actor(key)
   if not foe.is_empty() and bool(foe.alive) and combat.owner_pos(str(owner)).distance_to(foe.pos)<480:foes_near=true;break
   for id in family_units(str(owner),"mosaic"):
    if not foe.is_empty() and bool(foe.alive) and combat.vec(combat.morrow.units[id].pos).distance_to(foe.pos)<480:foes_near=true;break
  if float(quiet.get(owner,0))<0:quiet[owner]=minf(0,float(quiet[owner])+delta);continue
  quiet[owner]=0.0 if foes_near else float(quiet.get(owner,0))+delta
  if float(quiet[owner])>=2:merge(str(owner))
 for id in combat.morrow.units:
  var u:Dictionary=combat.morrow.units[id]
  if str(u.get("family",""))=="mosaic":
   u.damage=7+4*(int(u.weight)-1)+(4 if float(u.get("empowered",0))>0 else 0);u.empowered=maxf(0,float(u.get("empowered",0))-delta)
   if combat.passive(str(u.owner),"tessellated"):u.speed=140-5*(int(u.weight)-1)
 for i in range(shots.size()-1,-1,-1):
  var s:Dictionary=shots[i]
  if bool(s.get("bubble",false)):
   var owner:String=str(s.owner);var a:Vector2=combat.vec(s.pos);var b:Vector2=a+combat.vec(s.aim)*minf(300*delta,float(s.left));s.left=float(s.left)-a.distance_to(b);s.life=float(s.life)-delta
   var pop:bool=not combat.path_clear(a,b) or float(s.left)<=0 or float(s.life)<=0;var impact:="";var best:=INF
   for key in combat.hostile(owner):
    var f:Dictionary=combat.actor(key)
    if f.is_empty() or not bool(f.alive):continue
    var at:=Geometry2D.get_closest_point_to_segment(f.pos,a,b)
    if f.pos.distance_to(at)<=float(s.radius)+combat.v110.target_radius(key,18) and a.distance_to(at)<best and combat.path_clear(a,at):best=a.distance_to(at);impact=key;b=at;pop=true
   if combat.v56.catch_shot(a,b,owner,float(s.damage),"#a1e4ec"):shots.remove_at(i);continue
   if pop:
    if not impact.is_empty():combat.damage(impact,float(s.damage),owner,"Bubble Bloom")
    field(owner,b if combat.path_clear(a,b) else a,"bubble_pool",3,38+float(s.radius)*.5);shots.remove_at(i)
   else:s.pos=combat.point_array(b)
   continue
  var owner:=str(s.owner);var a:Vector2=combat.vec(s.pos);var b:Vector2=a if bool(s.get("ground",false)) else a+combat.vec(s.aim)*minf(350*delta,float(s.left));s.life=float(s.get("life",1.5))-delta
  if float(s.life)<=0:shots.remove_at(i);continue
  var best:=INF;var target:="";var is_friend:=false
  if combat.v56.catch_shot(a,b,owner,float(s.damage),"#94ead2"):shots.remove_at(i);continue
  if not combat.path_clear(a,b):s.ground=true;s.life=1.5;b=a
  for id in combat.adventure.points():
   if str(id)==owner or not combat.adventure.alive(str(id)) or not combat.v75.friendly(owner,str(id)):continue
   var q:Vector2=combat.owner_pos(str(id));var hit:=Geometry2D.get_closest_point_to_segment(q,a,b)
   if q.distance_to(hit)<24 and a.distance_to(hit)<best:best=a.distance_to(hit);target=str(id);is_friend=true
  for key in combat.hostile(owner):
   var foe:Dictionary=combat.actor(key)
   if foe.is_empty() or not bool(foe.alive):continue
   var hit:=Geometry2D.get_closest_point_to_segment(foe.pos,a,b)
   if foe.pos.distance_to(hit)<6+combat.v110.target_radius(key,18) and a.distance_to(hit)<best:best=a.distance_to(hit);target=key;is_friend=false
  if not target.is_empty():
   if is_friend:
    heal(owner,target,int(s.heal))
    if combat.passive(owner,"gentle_arrival"):combat.apply_status(combat.player_key(target),"guard",.8,owner,.08)
   else:combat.damage(target,float(s.damage),owner)
   flash(b,25,"#94ead2");shots.remove_at(i);continue
  s.pos=combat.point_array(b);s.left=float(s.left)-a.distance_to(b)
  if float(s.left)<=0 and not bool(s.get("ground",false)):s.ground=true;s.life=1.5
 for i in range(fields.size()-1,-1,-1):
  var f:Dictionary=fields[i];var owner:=str(f.owner);var p:Vector2=combat.vec(f.pos);var active:=minf(delta,float(f.time));f.time=float(f.time)-delta;f.tick=float(f.tick)+active
  if not combat.adventure.alive(owner):fields.remove_at(i);continue
  var style:=str(f.style)
  if style=="court":
   if float(f.time)<=0:combat.v75.area(owner,p,150,float(f.damage),{"stun_duration":1.8});flash(p,150,"#d6a7f2");fields.remove_at(i)
   continue
  if style=="bubble_pool":
   for key in combat.hostile(owner):
    var a:Dictionary=combat.actor(key)
    if not a.is_empty() and bool(a.alive) and p.distance_to(a.pos)<=float(f.radius) and combat.path_clear(p,a.pos):combat.apply_status(key,"slow",.4,owner,.6)
  if style=="passage":f.pos=combat.point_array(combat.v75.clip(p,combat.vec(f.aim),110*delta));p=combat.vec(f.pos)
  for id in friendly_near(owner,p,float(f.radius)):
   if style in ["buoy","relay","sanctuary","passage"]:combat.apply_status(combat.player_key(id),"guard",.3,owner,.2 if style in ["sanctuary","passage"] else .12)
   if style=="passage" and id not in f.hits:f.hits.append(id);heal(owner,id,12)
  while float(f.tick)+.00001>=1:
   f.tick=float(f.tick)-1
   for id in friendly_near(owner,p,float(f.radius)):
    if style in ["buoy","relay","mend"]:heal(owner,id,6 if style=="relay" else 4)
    if style=="sanctuary":combat.statuses.get(combat.player_key(id),{}).erase("poison");combat.statuses.get(combat.player_key(id),{}).erase("burn")
   if style=="honey":combat.v75.area(owner,p,float(f.radius),float(f.damage),{"slow_duration":1.2,"slow":.45})
  if style in ["order","inward"]:
   for key in combat.hostile(owner):
    var foe:Dictionary=combat.actor(key)
    if foe.is_empty() or not bool(foe.alive) or p.distance_to(foe.pos)>float(f.radius) or not combat.path_clear(p,foe.pos):continue
    combat.apply_status(key,"slow",.3,owner,.55);combat.knock(key,(p-foe.pos).normalized() if style=="inward" else combat.vec(f.aim).orthogonal(),35*delta)
  if float(f.time)<=0:fields.remove_at(i)
 for i in range(flashes.size()-1,-1,-1):
  flashes[i].time=float(flashes[i].time)-delta
  if float(flashes[i].time)<=0:flashes.remove_at(i)
func catch_shot(a:Vector2,b:Vector2,source:String)->bool:
 for f in fields:
  if str(f.style) not in ["hush","passage"] or source!="enemy" and combat.v75.friendly(str(f.owner),source) or int(f.caught)>=12:continue
  var p:Vector2=combat.vec(f.pos)
  if p.distance_to(Geometry2D.get_closest_point_to_segment(p,a,b))<=float(f.radius) and combat.path_clear(p,b):f.caught=int(f.caught)+1;flash(p,30,"#8fdde5");return true
 return false
func snapshot()->Dictionary:return {"shots":shots,"fields":fields,"flashes":flashes,"marks":marks}
func receive(d:Dictionary)->void:marks=d.get("marks",{});shots=d.get("shots",[]);fields=d.get("fields",[]);flashes=d.get("flashes",[])
func draw_on(c:Node2D,camera:Vector2)->void:
 for owner in marks:
  var a:Dictionary=combat.actor(str(marks[owner]))
  if a.is_empty() or not bool(a.alive):continue
  var p:Vector2=a.pos-camera
  c.draw_arc(p,25,clock,clock+TAU,24,Color("#e6b8fb"),2,true)
  c.draw_colored_polygon(PackedVector2Array([p+Vector2(-7,-50),p+Vector2(7,-50),p+Vector2(0,-40)]),Color("#e6b8fb"))
 for s in shots:
  if bool(s.get("bubble",false)):
   var p:Vector2=combat.vec(s.pos)-camera;var r:float=float(s.radius)
   c.draw_circle(p,r,Color(.65,.88,.97,.18));c.draw_arc(p,r,0,TAU,24,Color(.68,.9,1,.8),2,true);c.draw_arc(p,r*.65,PI,PI*1.5,8,Color("#f5ebff"),2,true);continue
  var p:Vector2=combat.vec(s.pos)-camera;var aim:Vector2=combat.vec(s.aim);var alpha:=clampf(float(s.get("life",1.5))/1.5,0,1) if bool(s.get("ground",false)) else 1.0
  c.draw_line(p-aim*16,p,Color(Color("#94ead2"),alpha),5,true);c.draw_circle(p,5,Color(Color("#f0ffe6"),alpha))
  if bool(s.get("ground",false)):c.draw_arc(p,18,0,TAU,20,Color(.6,.92,.8,.4*alpha),1,true)
 for f in fields:
  var p:Vector2=combat.vec(f.pos)-camera;var r:=float(f.radius);var tint:=Color("#d6a7f2") if str(f.style) in ["order","inward","court"] else Color("#f4cb72") if str(f.style)=="honey" else Color("#94ead2")
  if str(f.style)=="bubble_pool":
   for n in 5:c.draw_circle(p+Vector2.from_angle(n*TAU/5)*r*.35,r*.5,Color(.5,.8,.94,.15*minf(1,float(f.time))))
   continue
  if str(f.style)!="passage":c.draw_circle(p,r,Color(tint,.12));c.draw_arc(p,r,0,TAU,40,Color(tint,.7),3,true)
  if str(f.style)=="passage":
   var aim:Vector2=combat.vec(f.aim);var side:=aim.orthogonal();var t:=Time.get_ticks_msec()/1000.0
   for n in 3:
    var crest:=PackedVector2Array()
    for j in 25:
     var x:float=(j/24.0-.5)*r*2
     crest.append(p+side*x+aim*(sin(x*.04+t*3)*6-n*13))
    c.draw_polyline(crest,Color(.55,.9,1,.8-n*.2),5-n,true)
  elif str(f.style) in ["buoy","hush"]:
   # Floating life-ring, rope spokes and small waves, distinct from a lantern.
   var bob:=sin(Time.get_ticks_msec()/300.0)*3
   c.draw_circle(p+Vector2(0,bob),22,Color("#f0e3be"));c.draw_circle(p+Vector2(0,bob),12,Color("#267c9e"))
   for n in 4:
    var v:=Vector2.from_angle(n*PI/2)*17;c.draw_circle(p+Vector2(0,bob)+v,5,Color("#df815c"));c.draw_line(p+v*1.6,p+v*2.4,Color("#d7c595"),2,true)
   for n in 3:c.draw_arc(p+Vector2(0,25+n*9),27+n*9,0,PI,20,Color(.4,.8,.95,.45),2,true)
  elif str(f.style) in ["order","inward"]:
   var arrow:Vector2=combat.vec(f.aim).orthogonal() if str(f.style)=="order" else Vector2.LEFT
   for n in 5:
    var q:=p+Vector2(-60+n*30,sin(Time.get_ticks_msec()/600.0+n)*20)
    if str(f.style)=="inward":arrow=(p-q).normalized()
    c.draw_line(q-arrow*12,q+arrow*12,tint,3,true);c.draw_line(q+arrow*12,q+arrow.rotated(2.4)*10,tint,3,true);c.draw_line(q+arrow*12,q+arrow.rotated(-2.4)*10,tint,3,true)
   c.draw_circle(p,11,Color("#6b4f80"));c.draw_line(p-Vector2(6,0),p+Vector2(6,0),Color("#dec7ed"),3)
  elif str(f.style)=="court":
   for n in 3:c.draw_line(p+Vector2(-r*.6,-50+n*50),p+Vector2(r*.6,-50+n*50),Color(tint,.5),3,true)
  else:c.draw_arc(p,18,0,TAU,20,tint,4,true);c.draw_line(p-Vector2(0,12),p+Vector2(0,12),tint,3)
 for f in flashes:c.draw_arc(combat.vec(f.pos)-camera,float(f.radius)*(1-float(f.time)/.6),0,TAU,24,Color(Color(f.color),float(f.time)/.6),3,true)
