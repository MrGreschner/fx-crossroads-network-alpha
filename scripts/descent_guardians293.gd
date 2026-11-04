extends RefCounted
## Major guardian encounters. State/geometry are host-owned and JSON replicated.
var _battle:WeakRef
var b:RefCounted:
 get:return _battle.get_ref() if _battle!=null else null
 set(value):_battle=weakref(value)
var d:RefCounted:
 get:return b.d
var g:Node:
 get:return b.game
var states:Dictionary={}
var props:Dictionary={}
var fields:Array=[]
var solids:Array=[]
const TITLES=["BURNING WICK","THE LOOM","EXCAVATION RUN","TURNING TIDE","CRUSHING VERDICT","VENOM RIVERS","REFRACTION","TOLL SEQUENCE","SCORCHED PASSAGE","ROYAL DECREE","RISING CALDERA"]
const KITS=[ ["wick","breath","slam","summon","sweep"], ["loom","pluck","fan","bite"], ["dig","charge","debris","bite"], ["current","reflection","pulse","ward","surge"], ["claws","quarry","charge","pincer"], ["venom","heads","drain"], ["refract","growth","burst","lances"], ["toll","silence","ritual","pull","burst"], ["flight","draft","firewheel","brood","boomerang"], ["decree","march","guards","sentence","volley","beam"], ["caldera","bombard","vents","fracture","heart","firewheel"] ]
func number(e:Dictionary)->int:return 10 if str(e.type)=="ds_lava_heart" else int(str(e.type).trim_prefix("ds_boss_"))-1
func owns(e:Dictionary)->bool:return str(e.type).begins_with("ds_boss_") or str(e.type)=="ds_lava_heart"
func active(uid:int)->Dictionary:
 for e in g.opponents:
  if int(e.uid)==uid and float(e.hp)>0:return e
 return {}
func state(e:Dictionary)->Dictionary:
 var key=str(e.uid)
 if not states.has(key):states[key]={"owner":int(e.uid),"kind":number(e),"phase":"ready","left":2.5,"turn":0,"cycles":0,"tier":0,"opening":0.0,"aim":d.pack(e.pos),"from":d.pack(e.pos),"action":"","head_down":[0.0,0.0,0.0],"head_uid":[0,0,0],"head_shot":[2.0,3.5,5.0],"head_exposed":false,"reflection":[],"vent_hits":0,"setup":false,"dash_hits":[],"pulse":-1.0,"pulse_prev":0.0,"channel":0.0}
 return states[key]
func reset()->void:
 if b!=null and g!=null:clear_solids()
 states.clear();props.clear();fields.clear();solids.clear()
func clear_solids(owner:int=0)->void:
 var count=g.field_obstacles.size()
 g.field_obstacles=g.field_obstacles.filter(func(o):return not o.has("guardian293") or (owner!=0 and int(o.guardian293)!=owner))
 solids=solids.filter(func(o):return owner!=0 and int(o.owner)!=owner)
 if count!=g.field_obstacles.size():d.rebuild_navigation()
func sync_solids()->void:
 g.field_obstacles=g.field_obstacles.filter(func(o):return not o.has("guardian293"))
 for o in solids:g.field_obstacles.append({"pos":d.point(o.pos),"radius":float(o.radius),"kind":"rock","guardian293":int(o.owner)})
 d.rebuild_navigation()
func retire(uid:int)->void:
 if props.has(str(uid)):
  var p=props[str(uid)];var owner=active(int(p.owner))
  fields=fields.filter(func(f):return uid not in f.get("anchors",[]))
  if not owner.is_empty():
   var s=state(owner);s.opening=maxf(float(s.opening),3.5)
   match str(p.role):
    "head":s.head_down[int(p.slot)]=22.0-2.0*int(p.slot);s.head_uid[int(p.slot)]=0
    "vent":s.vent_hits=int(s.vent_hits)+1;s.opening=9.0
    "seal":s.phase="recover";s.left=4.5;clear_solids(int(owner.uid))
    "bell":s.channel=0;s.phase="recover";s.left=4.0
    "web":owner.pos=d.safe(d.point(p.pos));s.phase="recover";s.left=3.0
    "crystal":s.phase="recover";s.left=3.5
  var key=str(uid);props.erase(key)
  var old=solids.size();solids=solids.filter(func(o):return int(o.get("prop",0))!=uid)
  if old!=solids.size():sync_solids()
  return
 states.erase(str(uid));clear_fields(uid);clear_solids(uid)
func clear_fields(uid:int=0)->void:
 fields=fields.filter(func(f):return uid!=0 and int(f.owner)!=uid)
 var ids:Array=[]
 for key in props:
  if uid==0 or int(props[key].owner)==uid:ids.append(int(key))
 # Queue removal outside the combat damage loop (indices must remain stable).
 for key in ids:
  var e=active(key)
  if not e.is_empty():e.guardian_expired=true
  props.erase(str(key))
 for mob in g.opponents:
  if mob.has("guardian_add") and (uid==0 or int(mob.guardian_add)==uid):mob.guardian_expired=true
 if uid==0:clear_solids()
 else:clear_solids(uid)
func suspend(e:Dictionary)->void:
 var s=state(e);clear_fields(int(e.uid));s.setup=false;s.phase="ready";s.left=2.5;s.pulse=-1.0;s.channel=0;e.buried=false
func prop(e:Dictionary,role:String,at:Vector2,hp:float,slot:int=0,solid:bool=false)->int:
 if props.size()>=24:return 0
 at=d.safe(at)
 var mob=d.spawn("ds_rootling" if role=="head" else "ds_urchin",at)
 mob.hp=hp*(1+.4*maxi(0,g.positions.size()-1));mob.max_hp=mob.hp;mob.boss=false;mob.guardian_prop=true;mob.summoned=true;mob.name=role.capitalize();mob.hit_radius=24 if role=="head" else 26
 props[str(mob.uid)]={"owner":int(e.uid),"role":role,"slot":slot,"pos":d.pack(at),"life":40.0}
 if solid and not g.positions.values().any(func(v):return (v as Vector2).distance_to(at)<145) and d.lamp_pos().distance_to(at)>145:
  solids.append({"owner":int(e.uid),"prop":int(mob.uid),"pos":d.pack(at),"radius":38.0});sync_solids()
 return int(mob.uid)
func helpers(owner:int,role:String)->Array:
 var result:Array=[]
 for key in props:
  if int(props[key].owner)==owner and str(props[key].role)==role and not active(int(key)).is_empty():result.append(int(key))
 return result
func setup(e:Dictionary,s:Dictionary)->void:
 s.setup=true
 var n=number(e);var uid=int(e.uid)
 if n==1 and helpers(uid,"web").is_empty():
  for p in [Vector2(420,350),Vector2(1980,350),Vector2(1980,1350),Vector2(420,1350)]:prop(e,"web",p,65+g.floor_number)
 if n==4 and helpers(uid,"cover").is_empty():
  for p in [Vector2(650,600),Vector2(1750,600),Vector2(650,1120),Vector2(1750,1120)]:prop(e,"cover",p,100,0,true)
 if n==6 and helpers(uid,"crystal").is_empty():
  for p in [Vector2(500,420),Vector2(1900,420),Vector2(1900,1280),Vector2(500,1280)]:prop(e,"crystal",p,130)
 if n==7 and helpers(uid,"cover").is_empty():
  for p in [Vector2(650,550),Vector2(1750,550),Vector2(650,1150),Vector2(1750,1150)]:prop(e,"cover",p,220,0,true)
 if n==10 and helpers(uid,"vent").is_empty():
  for p in [Vector2(400,400),Vector2(2000,400),Vector2(400,1300),Vector2(2000,1300)]:prop(e,"vent",p,100)
func segment(a:Vector2,z:Vector2,width:float)->Dictionary:return {"shape":"segment","a":d.pack(a),"z":d.pack(z),"width":width}
func cone(a:Vector2,z:Vector2,radius:float,angle:float)->Dictionary:return {"shape":"cone","pos":d.pack(a),"aim":d.pack((z-a).normalized()),"radius":radius,"angle":angle}
func field(e:Dictionary,label:String,shape:Dictionary,tell:float,life:float,mult:float=1.0,effect:String="",vector:Vector2=Vector2.ZERO)->void:
 if fields.size()>=40:return
 fields.append({"owner":int(e.uid),"label":label,"shape":shape,"left":tell,"warning":tell,"life":life,"tick":0.0,"damage":float(d.Book.profile(e.type).damage)*mult,"effect":effect,"vector":d.pack(vector),"hits":[],"color":str(d.Book.profile(e.type).color)})
func contains(shape:Dictionary,p:Vector2)->bool:
 if str(shape.shape)=="segment":return Geometry2D.get_closest_point_to_segment(p,d.point(shape.a),d.point(shape.z)).distance_to(p)<float(shape.width)*.5+18
 if str(shape.shape)=="cone":
  var v=p-d.point(shape.pos)
  return v.length()<float(shape.radius)+18 and (v.length()<25 or v.normalized().dot(d.point(shape.aim))>cos(float(shape.angle)))
 return b.contains(shape,p)
func announce(e:Dictionary,s:Dictionary,action:String,aim:Vector2,tell:float=1.5)->void:
 s.phase="tell";s.left=tell;s.total=tell;s.action=action;s.aim=d.pack(aim);s.from=d.pack(e.pos);e.moving=0;e.strike=.2
 g.status_label.text=str(d.Book.profile(e.type).name)+" • "+action.replace("_"," ").to_upper()
 if action in ["charge","march"]:field(e,"CHARGE PATH",segment(e.pos,e.pos+(aim-(e.pos as Vector2)).normalized()*480,110),tell,.1,0)
 if action in ["pulse","ward"] and action=="pulse":field(e,"ORACLE PULSE",b.circle(e.pos,240),tell,.5,1.0)
func recover(s:Dictionary,seconds:float=2.2)->void:s.phase="recover";s.left=seconds;s.opening=maxf(float(s.opening),seconds)
func damage(e:Dictionary,amount:float)->float:
 if not owns(e):return amount
 var s=state(e)
 if str(s.phase)=="burrow":return 0
 if number(e)==5:
  var living_heads=0
  for i in 3:
   if float(s.head_down[i])<=0:living_heads+=1
  amount*=1.0-.12*living_heads
 if number(e)==10 and float(s.opening)<=0:amount*=.45
 if number(e)==9 and not helpers(int(e.uid),"guard").is_empty():amount*=.65
 if float(s.opening)>0:amount*=1.15
 return amount
func interact(id:String)->bool:
 for key in props:
  var p=props[key]
  if str(p.role)!="vent" or (g.positions[id] as Vector2).distance_to(d.point(p.pos))>90:continue
  var boss=active(int(p.owner))
  if boss.is_empty():continue
  var s=state(boss);s.vent_hits=int(s.vent_hits)+1;s.opening=9.0
  var v=active(int(key))
  if not v.is_empty():v.guardian_expired=true
  props.erase(key);d.interact_at[id]=d.clock+.6
  g.status_label.text="COOLING VENT OPEN • Heart exposed for 9 seconds";return true
 return false
func helper_step(e:Dictionary,target:String,goal:Vector2,dt:float)->bool:
 if bool(e.get("guardian_expired",false)):return true
 if not props.has(str(e.uid)):return false
 var p=props[str(e.uid)];var boss=active(int(p.owner));e.moving=0
 if boss.is_empty():return true
 if str(p.role)=="head":
  var slot=int(p.slot);e.pos=d.safe(boss.pos+[Vector2(-57,-68),Vector2(0,-85),Vector2(57,-68)][slot]);p.pos=d.pack(e.pos)
 elif str(p.role)=="guard":
  d.walk_to(e,goal,dt,115);e.attack_timer=float(e.attack_timer)-dt
  if float(e.attack_timer)<=0 and (e.pos as Vector2).distance_to(goal)<130:e.attack_timer=2.5;d.execute(e,"sweep",goal,target)
 return true
func move(e:Dictionary,s:Dictionary,goal:Vector2,dt:float)->void:
 var n=number(e);var speed=float(d.Book.profile(e.type).speed)*float(d.scaling(g.floor_number).speed)
 var dest=goal;var dist=(e.pos as Vector2).distance_to(goal)
 var next_action=str((KITS[n] as Array)[int(s.turn)%KITS[n].size()])
 if next_action in ["slam","sweep","bite","pincer"]:dest=goal
 elif n in [1,3,6,7]:
  var angle=d.clock*(.25 if n!=1 else .4)+n;dest=goal+Vector2.from_angle(angle)*(300 if n!=7 else 380)
 elif n==5:dest=e.pos if dist<230 else goal;speed*=.65
 elif n==10:dest=goal;speed*=.65 if int(s.tier)==0 else 1.1
 elif n==9 and int(s.turn)%2==0:dest=Vector2(1200,420)
 if (e.pos as Vector2).distance_to(dest)>65:d.walk_to(e,d.safe(dest),dt,speed)
 else:e.moving=0
func boss_step(e:Dictionary,target:String,goal:Vector2,dt:float)->bool:
 if not owns(e):return false
 var s=state(e);var n=number(e)
 if not bool(s.setup):setup(e,s)
 if int(e.get("intermissions",0))>int(s.tier):
  s.tier=int(e.intermissions);s.phase="ready";s.left=1.8
  if n==10:
   g.status_label.text="CALDERA FRACTURE" if int(s.tier)==1 else "HEART UNBOUND • Final eruption"
 s.opening=maxf(0,float(s.opening)-dt)
 if n==5:heads(e,s,target,goal,dt)
 s.left=float(s.left)-dt
 if str(s.phase)=="burrow":
  var pos:Vector2=e.pos;e.pos=d.safe(pos.move_toward(d.point(s.aim),220*dt));e.moving=0
  if float(s.left)<=0:e.buried=false;field(e,"BREACH",b.circle(e.pos,150),1.2,.5,1.25);recover(s,3.0)
  return true
 if str(s.phase)=="flight":
  e.pos=d.safe((e.pos as Vector2).move_toward(d.point(s.aim),420*dt));e.moving=180;e.gait=float(e.gait)+dt*8
  if float(s.left)<=0:field(e,"HEAVY LANDING",b.circle(e.pos,140),1.0,.4,1.1);recover(s,3.0)
  return true
 if str(s.phase)=="dash":
  var before:Vector2=e.pos;var desired=before+d.point(s.direction)*480*dt;e.pos=g._move_actor(before,desired-before);e.moving=200;e.gait=float(e.gait)+dt*12
  if n==2:
   for o in g.field_obstacles:
    if (e.pos as Vector2).distance_to(o.pos)<float(o.radius)+50:s.left=0;s.opening=4.5
  for id in g.positions:
   if id in s.dash_hits:continue
   if Geometry2D.get_closest_point_to_segment(g.positions[id],before,e.pos).distance_to(g.positions[id])<58:
    if not b.encounters.immune(str(id)):b.encounters.harm(str(id),float(d.Book.profile(e.type).damage)*1.25,int(e.uid),"Guardian charge");d.knock(str(id));s.dash_hits.append(id)
  if float(s.left)<=0:recover(s,3.0)
  return true
 if str(s.phase)=="tell":
  e.moving=0
  if float(s.left)<=0:perform(e,s,target,goal)
  return true
 if str(s.phase)=="recover":
  e.moving=0
  if float(s.left)<=0:s.phase="ready";s.left=.8
  return true
 move(e,s,goal,dt)
 if float(s.left)>0:return true
 var kit:Array=KITS[n];var action=str(kit[int(s.turn)%kit.size()]);s.turn=int(s.turn)+1
 if action in ["slam","sweep","bite","pincer"] and (e.pos as Vector2).distance_to(goal)>155:
  s.left=.2;d.walk_to(e,goal,dt,160);s.turn=int(s.turn)-1;return true
 var tell=1.6 if n<5 else 1.4
 if action in ["dig","flight","decree","caldera","silence","sentence"]:tell=2.0
 announce(e,s,action,goal,tell)
 return true
func spawn_minions(e:Dictionary,kinds:Array,count:int)->void:
 for i in count:
  if g.opponents.size()>=22:break
  var p=d.safe(e.pos+Vector2.from_angle(i*TAU/count)*(210+i*22));var mob=d.spawn(str(kinds[i%kinds.size()]),p);mob.guardian_add=int(e.uid);mob.summoned=true
func head_spawn(e:Dictionary,s:Dictionary,i:int)->void:
 s.head_uid[i]=prop(e,"head",e.pos+[Vector2(-57,-68),Vector2(0,-85),Vector2(57,-68)][i],maxf(150,float(e.max_hp)*.055),i)
func heads(e:Dictionary,s:Dictionary,target:String,goal:Vector2,dt:float)->void:
 var all_down=true
 for i in 3:
  if float(s.head_down[i])>0:
   s.head_down[i]=maxf(0,float(s.head_down[i])-dt)
   if float(s.head_down[i])<=0:head_spawn(e,s,i)
  elif active(int(s.head_uid[i])).is_empty():head_spawn(e,s,i)
  if float(s.head_down[i])>0:continue
  all_down=false;s.head_shot[i]=float(s.head_shot[i])-dt
  if float(s.head_shot[i])<=0 and str(s.phase)!="tell":
   s.head_shot[i]=5.0+i*1.2;var head=active(int(s.head_uid[i]));var pos:Vector2=head.get("pos",e.pos)
   if i==0:field(e,"VENOM SPIT",b.circle(b.predict(target,.35),145),1.5,4.0,.3,"poison")
   elif i==1:field(e,"HUNGRY MOUTH",cone(pos,goal,280,.65),1.4,.4,1.1)
   else:field(e,"DRAIN TETHER",segment(pos,goal,48),1.5,.4,.8,"drain")
 if all_down:s.opening=maxf(float(s.opening),.4)
func perform(e:Dictionary,s:Dictionary,target:String,goal:Vector2)->void:
 var n=number(e);var action=str(s.action);var at:Vector2=e.pos;var aim=d.point(s.aim);var enraged=float(e.hp)<float(e.max_hp)*.5
 var uid=int(e.uid);s.cycles=int(s.cycles)+1;recover(s,1.8 if n<8 else maxf(.8,1.2-int(s.tier)*.08))
 match action:
  "wick":
   for i in 6:
    var a=at+Vector2.from_angle(i*.28)*i*105;field(e,"BURNING WICK",segment(d.safe(a),d.safe(a+Vector2(90,60)),65),.7,7.0 if enraged else 4.5,.35)
  "breath":field(e,"HUNGRY BREATH",cone(at,aim,520,.6),.7,2.0,.5,"pull",at)
  "loom":
   var anchors=helpers(uid,"web")
   if anchors.size()<2:s.setup=false
   else:
    for i in range(anchors.size()-1):
     var a=active(int(anchors[i]));var z=active(int(anchors[i+1]));field(e,"WEB STRAND • Break its anchor",segment(a.pos,z.pos,35),1.5,9.0,.15,"slow");fields[-1].anchors=[int(a.uid),int(z.uid)]
    if enraged and anchors.size()>2:field(e,"CROSS THREAD",segment(active(int(anchors[0])).pos,active(int(anchors[2])).pos,35),2.2,7.0,.15,"slow");fields[-1].anchors=anchors.duplicate()
  "pluck":
   var anchors=helpers(uid,"web")
   if anchors.size()>1:
    var a=active(int(anchors[int(s.cycles)%anchors.size()]));field(e,"PLUCKED STRING",segment(a.pos,aim,60),1.8,.5,1.2)
  "dig":
   e.buried=true;s.phase="burrow";s.left=3.0;s.aim=d.pack(b.predict(target,.5))
   field(e,"EXCAVATED TRENCH",segment(at,aim,105),.7,9.0,.15,"slow")
  "debris","bombard":
   for i in (5 if n==10 else 3):field(e,"FALLING DEBRIS",b.circle(d.safe(aim+Vector2.from_angle(i*2.4)*i*105),120),1.3+i*.35,.4,1.2)
  "charge","march":s.phase="dash";s.left=1.0;s.direction=d.pack((aim-at).normalized());s.dash_hits=[]
  "current":
   for i in 3:field(e,"TURNING TIDE • Islands give grip",segment(Vector2(160,350+i*440),Vector2(2240,550+i*380),170),1.4,7.0,.2,"current",Vector2(90 if int(s.cycles)%2==0 else -90,35))
   s.last_water="current"
  "reflection":
   var mirror=d.safe(Vector2(2400,1700)-at);s.reflection=[d.pack(mirror),d.pack(aim)]
   if str(s.get("last_water","pulse"))=="current":
    for i in 3:field(e,"REFLECTED TIDE",segment(Vector2(160,500+i*380),Vector2(2240,300+i*440),125),2.5+i*.3,4.0,.25,"current",Vector2(-90,35))
   else:field(e,"REFLECTED PULSE",b.circle(mirror,240),2.5,.5,1.0)
  "surge":field(e,"ORACLE SURGE",cone(at,aim,800,.7),1.8,.6,1.2)
  "claws":
   var dir=(aim-at).normalized();var side=dir.orthogonal()*145
   for i in 2:field(e,"CRUSHING VERDICT • Claw "+str(i+1),cone(at+side*(1 if i==0 else -1),aim,390,.65),1.5+i*.85,.5,1.3)
   s.opening=4.2;s.left=4.2
   if enraged:
    for key in helpers(uid,"cover"):
     var cover=active(int(key));cover.guardian_expired=true
    clear_solids(uid)
  "quarry":
   for i in 5:b.shoot(e,at,(aim-at).normalized().rotated((i-2)*.22),float(d.Book.profile(e.type).damage),"boulder",target)
  "venom":
   for i in 3:field(e,"VENOM RIVER",segment(Vector2(220+i*780,180),Vector2(450+i*660,1510),115),1.8,8.0,.3,"poison")
  "heads":s.opening=3.0;s.left=3.0
  "drain":field(e,"DRAIN TETHER • Break sight",segment(at,aim,50),1.5,.6,.8,"drain")
  "growth":
   if helpers(uid,"crystal").size()<6:prop(e,"crystal",d.safe(Vector2(500+int(s.cycles)%3*650,850)),130)
  "refract":
   var anchors=helpers(uid,"crystal");var start=at
   for i in mini(3,anchors.size()):
    var next:Vector2=active(int(anchors[(i+int(s.cycles))%anchors.size()])).pos;field(e,"REFRACTED LANCE",segment(start,next,65),2.0,.5,1.25);fields[-1].anchors=anchors.duplicate();start=next
   field(e,"FINAL REFLECTION",segment(start,aim,65),2.0,.5,1.25);fields[-1].anchors=anchors.duplicate()
   if enraged:field(e,"REFRACTION ECHO",segment(aim,Vector2(1200,850),65),3.2,.5,1.25)
  "lances":
   for i in 5:b.shoot(e,at,(aim-at).normalized().rotated((i-2)*.16),float(d.Book.profile(e.type).damage),"shard",target)
  "toll":
   for i in 3:
    var center=Vector2(350+i*850,850);field(e,"TOLL "+str(i+1)+" • Shelter behind stone",cone(center,aim,1200,.55),1.4+i*.85,.5,1.1,"sound")
   if enraged:field(e,"DELAYED ECHO",cone(Vector2(1200,220),aim,1400,.5),4.2,.5,1.1,"sound")
  "silence":s.pulse=42.0;s.pulse_prev=42.0;s.opening=0;s.phase="recover";s.left=5.0
  "ritual":
   if helpers(uid,"bell").is_empty():prop(e,"bell",d.safe(at+Vector2(320,0)),180)
   s.channel=4.0;g.status_label.text="HEALING RESONANCE • Break the small bell"
  "flight":
   var landing=d.safe(aim+(aim-at).normalized()*320);field(e,"SCORCHED PASSAGE",segment(at,landing,145),.8,7.0,.5)
   s.phase="flight";s.left=2.0;s.aim=d.pack(landing)
  "draft":
   for i in 3:field(e,"FURNACE DRAFT",b.circle(Vector2(450+i*750,420+int(s.cycles)%2*860),170),1.3+i*.65,4.0,.4,"current",Vector2(120,0))
   for wheel in d.wheels:wheel.dir=d.pack(d.point(wheel.dir).rotated(PI*.5))
  "brood":spawn_minions(e,["ds_salamander","ds_drake"],3 if not enraged else 4)
  "decree":
   clear_solids(uid)
   for col in 2:
    for row in 9:
     if row in [2+int(s.cycles)%2,3+int(s.cycles)%2,6,7]:continue
     var pos=Vector2(800+col*800,260+row*145)
     if g.positions.values().any(func(v):return (v as Vector2).distance_to(pos)<145) or d.lamp_pos().distance_to(pos)<145 or at.distance_to(pos)<145:continue
     solids.append({"owner":uid,"pos":d.pack(pos),"radius":42.0})
   sync_solids()
   if helpers(uid,"seal").is_empty():prop(e,"seal",Vector2(1200,350),240)
   for i in 3:field(e,"ROYAL SEAL",b.circle(Vector2(400+i*800,750+int(s.cycles)%2*400),160),1.6+i*.5,.5,1.2)
  "guards":
   if helpers(uid,"guard").size()<2:
    for side in [-1,1]:prop(e,"guard",d.safe(at+Vector2(side*200,80)),float(e.max_hp)*.035)
  "sentence":
   for id in g.positions:
    if int(g.health.get(id,0))<=0:continue
    var pos:Vector2=g.positions[id]
    for i in 3:field(e,"CROWN SENTENCE "+str(i+1),b.circle(pos,130) if i==0 else b.ring(pos,210+(i-1)*150,280+(i-1)*150),1.8+i*.8,.45,1.3)
  "caldera":
   var tier=int(s.tier)
   for i in (2+tier):
    var y=300+i*(1100.0/(2+tier));var gap=550.0 if (i+int(s.cycles))%2==0 else 1600.0
    field(e,"LAVA CHANNEL • Use basalt bridges",segment(Vector2(150,y),Vector2(gap-140,y),110),2.2,7.0,.6)
    field(e,"LAVA CHANNEL • Use basalt bridges",segment(Vector2(gap+140,y),Vector2(2250,y),110),2.2,7.0,.6)
  "vents":
   if helpers(uid,"vent").size()<2:
    for p in [Vector2(400,400),Vector2(2000,1300)]:prop(e,"vent",p,100)
   field(e,"PRESSURE RELEASE • E at a vent",b.ring(at,180,270),2.2,.5,1.1)
  "fracture":
   if int(s.tier)>0:
    for i in 4:
     var start=Vector2(300+i*600,200);field(e,"CALDERA FRACTURE",segment(start,start+Vector2(150,1300),85),1.8+i*.4,5.0,.7)
    spawn_minions(e,["ds_salamander","ds_ironback"],3)
   else:field(e,"SHELL IMPACT",cone(at,aim,450,.8),1.5,.5,1.2)
  "heart":
   if int(s.tier)>=2:
    for i in 5:field(e,"HEART UNBOUND • Staggered lava arcs",b.ring(at,150+i*170,220+i*170),1.6+i*.65,.5,1.35)
    s.opening=6.0
   else:field(e,"MOLTEN HEART",cone(at,aim,650,.55),1.6,.5,1.25)
  "pulse":s.last_water="pulse" # Damage was scheduled with its full ground telegraph in announce.
  _:
   if action in ["slam","sweep","bite","pincer"]:field(e,action.to_upper(),cone(at,aim,180,.9),.15,.35,1.0,"knock" if action=="slam" else "")
   else:d.execute(e,action,aim,target)
func step(dt:float)->void:
 # Expired environment targets are removed away from combat index iteration.
 for e in g.opponents.duplicate():
  if bool(e.get("guardian_expired",false)):
   retire(int(e.uid));g.opponents.erase(e)
 for key in props.keys():
  var p=props[key];p.life=float(p.life)-dt
  if active(int(p.owner)).is_empty():continue
  if p.life<=0 and str(p.role)!="head":
   var e=active(int(key))
   if not e.is_empty():e.guardian_expired=true
 for key in states:
  var s=states[key];var e=active(int(key))
  if e.is_empty() or bool(e.get("phase_pending",false)) or float(e.get("return_ward",0))>0:continue
  if float(s.channel)>0:
   s.channel=float(s.channel)-dt
   if helpers(int(e.uid),"bell").is_empty():s.channel=0
   elif float(s.channel)<=0:e.hp=minf(float(e.max_hp),float(e.hp)+float(e.max_hp)*.09)
  if float(s.pulse)>=0:
   s.pulse_prev=s.pulse;s.pulse=float(s.pulse)+190*dt
   var center:Vector2=e.pos;var previous_radius=float(s.pulse_prev);var radius=float(s.pulse)
   # Erase both teams' projectiles; compare swept shot segments with the pulse.
   g.adventure.combat.projectiles=g.adventure.combat.projectiles.filter(func(p):return not pulse_cross(center,previous_radius,radius,d.point(p.pos),d.point(p.pos)-d.point(p.aim)*float(p.speed)*dt))
   g.missiles=g.missiles.filter(func(p):return not pulse_cross(center,previous_radius,radius,p.pos,(p.pos as Vector2)-(p.get("direction",Vector2.ZERO) as Vector2)*float(p.get("speed",0))*dt))
   b.bolts=b.bolts.filter(func(p):return not pulse_cross(center,previous_radius,radius,d.point(p.pos),d.point(p.pos)-d.point(p.dir)*float(p.speed)*dt))
   if radius>900:s.pulse=-1.0;s.opening=3.0
 for f in fields.duplicate():
  if not fields.has(f):continue
  var boss=active(int(f.owner))
  if boss.is_empty():fields.erase(f);continue
  if bool(boss.get("phase_pending",false)) or float(boss.get("return_ward",0))>0:continue
  var old=float(f.left);f.left=old-dt
  if float(f.left)>0:continue
  var elapsed=dt if old<=0 else maxf(0,-float(f.left));f.life=float(f.life)-elapsed;f.tick=float(f.tick)-elapsed
  if float(f.life)<=0:fields.erase(f);continue
  if float(f.tick)>0:continue
  f.tick=.8
  for id in g.positions:
   if int(g.health.get(id,0))<=0 or not contains(f.shape,g.positions[id]):continue
   if str(f.effect)=="current" and on_island(g.positions[id]):continue
   if str(f.effect)=="drain" and not d.segment_clear(boss.pos,g.positions[id]):continue
   if str(f.effect)=="sound" and not d.segment_clear(d.point(f.shape.pos),g.positions[id]):continue
   if float(f.warning)>0 and float(f.life)<.8 and id in f.hits:continue
   if b.encounters.immune(str(id)):continue
   b.encounters.harm(str(id),float(f.damage),int(f.owner),str(f.label),2.0 if str(f.effect)=="poison" else 0.0,3.0)
   f.hits.append(id)
   match str(f.effect):
    "slow":g.adventure.combat.apply_status(g.adventure.combat.player_key(str(id)),"slow",1.0,"enemy",.65)
    "current":
     if not on_island(g.positions[id]):g.positions[id]=g._move_actor(g.positions[id],d.point(f.vector)*.35)
    "pull":g.positions[id]=g._move_actor(g.positions[id],(d.point(f.vector)-(g.positions[id] as Vector2)).normalized()*70)
    "drain":
     if d.segment_clear(boss.pos,g.positions[id]):boss.hp=minf(float(boss.max_hp),float(boss.hp)+float(f.damage)*.7)
    "knock":d.knock(str(id))
func pulse_cross(center:Vector2,lo:float,hi:float,a:Vector2,z:Vector2)->bool:
 var near=Geometry2D.get_closest_point_to_segment(center,a,z).distance_to(center)
 return near<=hi+18 and maxf(a.distance_to(center),z.distance_to(center))>=lo-18
func intercept(a:Vector2,z:Vector2)->bool:
 if g.mode!="descent":return false
 for key in states:
  var s=states[key]
  if float(s.pulse)<0:continue
  var e=active(int(key))
  if not e.is_empty() and pulse_cross(e.pos,float(s.pulse)-15,float(s.pulse)+15,a,z):return true
 return false
func cover_impact(a:Vector2,z:Vector2,amount:float)->void:
 for key in props:
  var p=props[key]
  if str(p.role)!="cover":continue
  var e=active(int(key))
  if not e.is_empty() and Geometry2D.get_closest_point_to_segment(e.pos,a,z).distance_to(e.pos)<58:
   e.hp=float(e.hp)-amount*2
   if float(e.hp)<=0:e.guardian_expired=true
   return
func on_island(p:Vector2)->bool:
 for at in [Vector2(450,400),Vector2(1950,400),Vector2(1200,850),Vector2(450,1300),Vector2(1950,1300)]:
  if p.distance_to(at)<115:return true
 return false
func snapshot()->Dictionary:return {"states":states,"props":props,"fields":fields,"solids":solids}
func receive(v:Dictionary)->void:
 states=v.get("states",{});props=v.get("props",{});fields=v.get("fields",[])
 var incoming:Array=v.get("solids",[])
 if incoming!=solids:solids=incoming;sync_solids()
func draw_shape(c:Node2D,shape:Dictionary,camera:Vector2,color:Color,fill:bool)->void:
 match str(shape.shape):
  "segment":c.draw_line(d.point(shape.a)-camera,d.point(shape.z)-camera,color,float(shape.width) if fill else 3,true)
  "cone":
   var p=d.point(shape.pos)-camera;var angle=d.point(shape.aim).angle();var radius=float(shape.radius);var points=PackedVector2Array([p])
   for i in 20:points.append(p+Vector2.from_angle(angle-float(shape.angle)+2*float(shape.angle)*i/19)*radius)
   points.append(p)
   if fill:c.draw_colored_polygon(points,color)
   else:c.draw_polyline(points,color,2,true)
  "ring":c.draw_arc(d.point(shape.pos)-camera,(float(shape.radius)+float(shape.inner))*.5,0,TAU,64,color,float(shape.radius)-float(shape.inner) if fill else 3,true)
  "circle":
   if fill:c.draw_circle(d.point(shape.pos)-camera,float(shape.radius),color)
   else:c.draw_arc(d.point(shape.pos)-camera,float(shape.radius),0,TAU,48,color,2,true)
func draw(c:Node2D,camera:Vector2)->void:
 for key in states:
  var s=states[key];var e=active(int(key))
  if e.is_empty():continue
  var p:Vector2=e.pos-camera;var n=int(s.kind)
  if n==3:
   for island in [Vector2(450,400),Vector2(1950,400),Vector2(1200,850),Vector2(450,1300),Vector2(1950,1300)]:c.draw_circle(island-camera,115,Color("#9eb5ba",.14));c.draw_arc(island-camera,115,0,TAU,24,Color("#b6c5c5",.6),3)
  if str(s.phase)=="tell":
   var aim=d.point(s.aim)-camera;c.draw_line(p,aim,Color("#f4d1a1",.7),2);c.draw_arc(p,65,-PI*.5,-PI*.5+TAU*clampf(1-float(s.left)/float(s.total),0,1),32,Color("#f4d1a1"),4)
   c.draw_string(ThemeDB.fallback_font,p+Vector2(-140,-115),str(s.action).replace("_"," ").to_upper(),HORIZONTAL_ALIGNMENT_CENTER,280,16,Color("#fff0ce"))
  if str(s.phase)=="burrow":c.draw_circle(p,35,Color("#b6a58d",.7));c.draw_arc(p,48,0,PI,16,Color("#dbc7a2"),5)
  if float(s.pulse)>=0:c.draw_arc(p,float(s.pulse),0,TAU,80,Color("#f5e7ad",.8),14,true)
  if n==5:
   draw_hydra(c,e,s,camera)
   c.draw_string(ThemeDB.fallback_font,p+Vector2(-150,-175),str(d.Book.profile(e.type).name),HORIZONTAL_ALIGNMENT_CENTER,300,16,Color("#eadbb9"))
   for i in 3:
    if float(s.head_down[i])>0:c.draw_string(ThemeDB.fallback_font,p+Vector2((i-1)*115-65,-165),"HEAD %d: %.1fs"%[i+1,float(s.head_down[i])],HORIZONTAL_ALIGNMENT_CENTER,130,15,Color("#e6d39e"))
  if n==10:c.draw_string(ThemeDB.fallback_font,p+Vector2(-160,-160),["ARMOURED CALDERA","CALDERA FRACTURE","HEART UNBOUND"][mini(2,int(s.tier))]+(" • EXPOSED" if float(s.opening)>0 else " • E: VENT"),HORIZONTAL_ALIGNMENT_CENTER,320,16,Color("#f2c391"))
 for f in fields:
  var color=Color(str(f.color));var warning=float(f.left)>0
  draw_shape(c,f.shape,camera,Color(color,.15 if warning else .40),true);draw_shape(c,f.shape,camera,Color("#f4ddb5") if warning else color.lightened(.4),false)
 for o in solids:
  var p=d.point(o.pos)-camera;preload("res://scripts/descent_map251.gd").pillar(c,d.point(o.pos),float(o.radius),camera);c.draw_line(p+Vector2(-14,-20),p+Vector2(14,-20),Color("#cfb5dd"),4)
 for key in props:
  var prop_data=props[key];var mob=active(int(key))
  if mob.is_empty():continue
  var p:Vector2=mob.pos-camera;var role=str(prop_data.role);var color=Color("#a6b5a0") if role=="head" else Color("#b6b4cc") if role=="crystal" else Color("#c4aa78")
  if role=="head":
   pass # Heads use the original painted sprite regions, drawn with their body above.
  elif role=="web":c.draw_circle(p,23,Color("#b4a8ba"));c.draw_arc(p,31,0,TAU,8,Color("#dfd1dd"),3)
  elif role=="guard":
   var art=mob.duplicate();art.merge(d.Book.profile("ds_angel"),false);art.kind="ds_angel";art.pos=p;art.cell=[128,160];art.art_scale=.65;art.color="#b6a8c3";d.Art.enemy(c,art,d.clock,1.0)
  elif role=="vent":preload("res://scripts/cast_art232.gd").draw_prop(c,"vent",Rect2(p-Vector2(45,65),Vector2(90,100)))
  else:
   var pts=PackedVector2Array([p+Vector2(0,-40),p+Vector2(28,2),p+Vector2(15,30),p+Vector2(-24,25),p+Vector2(-28,-4)]);c.draw_colored_polygon(pts,color);c.draw_line(p+Vector2(0,-30),p+Vector2(0,20),color.lightened(.3),4)
  var label={"head":"Head "+str(int(prop_data.slot)+1),"vent":"Cooling vent • E","seal":"Royal seal","bell":"Healing bell","web":"Web anchor","crystal":"Reflector","cover":"Stone cover","guard":"Oath guard"}.get(role,role)
  c.draw_string(ThemeDB.fallback_font,p+Vector2(-85,-55),label,HORIZONTAL_ALIGNMENT_CENTER,170,13,Color("#f0e2c3"));c.draw_rect(Rect2(p+Vector2(-28,40),Vector2(56,5)),Color("#343d43"));c.draw_rect(Rect2(p+Vector2(-28,40),Vector2(56*clampf(float(mob.hp)/float(mob.max_hp),0,1),5)),color)
func draw_hydra(c:Node2D,e:Dictionary,s:Dictionary,camera:Vector2)->void:
 # Split only at draw time; original source artwork and neutral poses stay intact.
 var pose=0
 if float(e.get("moving",0))>.05:pose=1+posmod(int(float(e.gait)/TAU*2),2)
 var tex=preload("res://scripts/descent_detail259.gd").texture("ds_boss_06",pose)
 var scale=160.0/54.0*80.0/320.0;var origin:Vector2=e.pos-camera+Vector2(.5,34)-Vector2(160,296)*scale
 var tint=Color(1,.7,.65) if float(e.get("hurt",0))>0 else Color.WHITE
 c.draw_texture_rect_region(tex,Rect2(origin+Vector2(0,200)*scale,Vector2(320,120)*scale),Rect2(0,200,320,120),tint)
 for i in 3:
  if float(s.head_down[i])>0:continue
  var region=[Rect2(0,65,122,135),Rect2(122,65,90,135),Rect2(212,65,108,135)][i]
  c.draw_texture_rect_region(tex,Rect2(origin+region.position*scale,region.size*scale),region,tint)
