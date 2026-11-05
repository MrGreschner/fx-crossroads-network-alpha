extends RefCounted
## Cave-only host encounter controller. Packed world coordinates replicate through battle251.
var _battle:WeakRef
var b:RefCounted:
 get:return _battle.get_ref() if _battle!=null else null
 set(value):_battle=weakref(value)
var d:RefCounted:
 get:return b.d if b!=null else null
var g:Node:
 get:return b.game if b!=null else null
var states:Dictionary={}
var helpers:Dictionary={}
var waves:Array=[]
var clouds:Array=[]
var walls:Array=[]
var retired:Array=[]
const WAVE_THEMES={"ds_boss_01":["WICKFIRE FRONT","#e6ad70"],"ds_boss_02":["SILKEN TIDE","#c5a4c6"],"ds_boss_04":["ORACLE SURGE","#9bcbd8"],"ds_boss_06":["VENOM FRONT","#a7bc87"],"ds_boss_07":["FACET SHOCKWAVE","#b6dce8"],"ds_boss_08":["RESONANT TOLL","#dbc88e"],"ds_boss_09":["CINDER WAVE","#e7a377"],"ds_boss_10":["ROYAL ECLIPSE","#d4bfdf"],"ds_lava_heart":["MOLTEN WAVE","#edac71"]}
func reset()->void:
 if g!=null:clear_walls()
 states.clear();helpers.clear();waves.clear();clouds.clear();retired.clear()
func state(e:Dictionary)->Dictionary:
 var key=str(e.uid)
 if not states.has(key):states[key]={"owner":int(e.uid),"type":str(e.type),"phase":"ready","left":0.0,"cooldown":5.0,"cycles":0,"anchors":[],"tick":0.0,"aux":0.0,"fuel_at":-1.0}
 return states[key]
func alive(uid:int)->Dictionary:
 for e in g.opponents:
  if int(e.uid)==uid and float(e.hp)>0:return e
 return {}
func immune(id:String)->bool:return Time.get_ticks_msec()<int(g.invincible_until.get(id,0))
func harm(id:String,amount:float,owner:int,label:String,poison:float=0.0,duration:float=0.0)->void:
 if int(g.health.get(id,0))<=0 or immune(id):return
 var e=alive(owner)
 d.hurt(id,amount,e,label)
 if poison>0 and int(g.health.get(id,0))>0:
  var cause=preload("res://scripts/defeat_credit.gd").resolve(g,"e:"+str(owner),label)
  g.adventure.combat.apply_status(g.adventure.combat.player_key(id),"poison",duration,"enemy",poison,cause)
func adjusted_damage(e:Dictionary,amount:float)->float:
 var s=states.get(str(e.uid),{})
 if str(s.get("phase","")) in ["burrow","rooted","brewing","archive"]:return 0.0
 if str(e.type)=="ds_mid_04" and str(s.get("phase",""))=="shell":amount*=.3
 if str(e.type)=="ds_mid_07" and amount>0:
  s=state(e)
  if d.clock>=float(s.fuel_at):
   d.lamp.fuel=maxf(0,float(d.lamp.get("fuel",100))-1.5);s.fuel_at=d.clock+.18
 return amount
func retire(uid:int)->void:
 states.erase(str(uid));waves=waves.filter(func(x):return int(x.owner)!=uid);clouds=clouds.filter(func(x):return int(x.owner)!=uid)
 if helpers.has(str(uid)):helpers.erase(str(uid))
 if uid not in retired:retired.append(uid)
 clear_walls(uid)
func wave(e:Dictionary,label:String,color:String,delay:float=1.4,speed:float=150.0)->void:
 if waves.size()>=8:return
 waves.append({"owner":int(e.uid),"label":label,"color":color,"pos":d.pack(e.pos),"radius":42.0,"previous":42.0,"width":24.0,"speed":speed,"left":delay,"warning":delay,"life":21.0,"hits":[]})
 g.status_label.text=label+" • Expanding front: dodge THROUGH it"
func step_waves(dt:float)->void:
 for w in waves.duplicate():
  if not waves.has(w):continue
  var source=alive(int(w.owner))
  if source.is_empty():waves.erase(w);continue
  var damage=float(d.Book.profile(str(source.type)).damage)*1.3
  var before_left=float(w.left);w.left=before_left-dt
  if float(w.left)>0:continue
  var active_dt=dt if before_left<=0 else maxf(0,-float(w.left))
  w.previous=float(w.radius);w.radius=float(w.radius)+float(w.speed)*active_dt;w.life=float(w.life)-active_dt
  for id in g.positions:
   if int(g.health.get(id,0))<=0 or id in w.hits:continue
   var dist=(g.positions[id] as Vector2).distance_to(d.point(w.pos))
   # Swept annulus prevents tunnelling on a long host frame. The dodge's existing
   # 220ms immunity is respected; the 24px band can be crossed in that window.
   if dist>=float(w.previous)-float(w.width)*.5-18 and dist<=float(w.radius)+float(w.width)*.5+18 and not immune(str(id)):
    w.hits.append(id);harm(str(id),damage,int(w.owner),str(w.label))
  if float(w.life)<=0 or float(w.radius)>3000:waves.erase(w)
func cloud(owner:int,at:Vector2,radius:float,life:float=8.0,delay:float=1.5)->void:
 if clouds.size()>=28:return
 clouds.append({"owner":owner,"pos":d.pack(d.safe(at)),"radius":radius,"left":delay,"warning":delay,"life":life,"tick":0.0})
func step_clouds(dt:float)->void:
 for c in clouds.duplicate():
  if not clouds.has(c):continue
  c.left=float(c.left)-dt
  if float(c.left)>0:continue
  c.life=float(c.life)-dt;c.tick=float(c.tick)-dt
  if float(c.life)<=0:clouds.erase(c);continue
  if float(c.tick)>0:continue
  c.tick=.8
  for id in g.positions:
   if (g.positions[id] as Vector2).distance_to(d.point(c.pos))<float(c.radius)+16:harm(str(id),2,int(c.owner),"Bailiff's spore poison",3.0,3.2)
func warn(s:Dictionary,e:Dictionary,phase:String,seconds:float,label:String)->void:
 s.phase=phase;s.left=seconds;s.total=seconds;e.action="";e.dash_left=0;e.moving=0;e.strike=0
 g.status_label.text=label
func finish(s:Dictionary,e:Dictionary,cooldown:float=16.0)->void:
 s.phase="ready";s.cooldown=cooldown;e.action="";e.attack_timer=1.4;e.buried=false;e.hidden_until=0
func open_anchors()->Array:
 var result:Array=[]
 for p in [Vector2(340,340),Vector2(2060,340),Vector2(340,1400),Vector2(2060,1400)]:result.append(d.pack(d.safe(p)))
 return result
func spawn_helper(e:Dictionary,kind:String,at:Vector2,role:String,hp:float)->int:
 var mob=d.spawn(kind,at);mob.hp=hp*(1+.35*maxi(0,g.positions.size()-1));mob.max_hp=mob.hp;mob.boss=false;mob.summoned=true;mob.name={"root":"Root Turret","leaf":"Leaf Skirmisher","cauldron":"Ossuary Cauldron","seal":"Archive Seal"}.get(role,role)
 helpers[str(mob.uid)]={"owner":int(e.uid),"role":role,"shot":1.8,"spawn":3.5,"life":30.0};return int(mob.uid)
func active_helpers(owner:int,role:String)->Array:
 var ids:Array=[]
 for key in helpers:
  if int(helpers[key].owner)==owner and str(helpers[key].role)==role and not alive(int(key)).is_empty():ids.append(int(key))
 return ids
func helper_step(e:Dictionary,target:String,goal:Vector2,dt:float)->bool:
 var h=helpers.get(str(e.uid),{})
 if h.is_empty():return false
 var role=str(h.role)
 if role=="leaf":
  h.life=float(h.life)-dt
  if float(h.life)<=0:e.hp=0;retired.append(-int(e.uid));return true
  if (e.pos as Vector2).distance_to(goal)>52:d.walk_to(e,goal,dt,150.0)
  else:e.moving=0
  e.attack_timer=float(e.attack_timer)-dt
  if float(e.attack_timer)<=0 and (e.pos as Vector2).distance_to(goal)<75:
   e.attack_timer=1.15;e.strike=.3;harm(target,6,int(h.owner),"Leaf skirmisher")
  return true
 e.moving=0;h.shot=float(h.shot)-dt
 if float(h.shot)<=0:
  h.shot=3.1 if role=="root" else 4.0
  if role=="root":b.shoot(e,e.pos,(d.point(h.get("aim",d.pack(goal)))-e.pos).normalized(),9.0,"shard",target)
  else:b.event("SEAL ERUPTION",[b.circle(b.predict(target,.3),80)],9.0,int(h.owner),1.25,.3)
  e.strike=.3;h.erase("aim")
 elif role=="root" and float(h.shot)<.8 and not h.has("aim"):h.aim=d.pack(b.predict(target,.3))
 if role=="root":
  h.spawn=float(h.spawn)-dt
  if float(h.spawn)<=0:
   h.spawn=4.5
   if active_helpers(int(h.owner),"leaf").size()<12:
    var boss=alive(int(h.owner))
    if not boss.is_empty():spawn_helper(boss,"ds_rootling",d.safe(e.pos+Vector2(65,35)),"leaf",24.0+g.floor_number*.10)
 return true
func clear_walls(owner:int=0)->void:
 if g==null:return
 var old=g.field_obstacles.size()
 g.field_obstacles=g.field_obstacles.filter(func(x):return not x.has("descent288_owner") or (owner!=0 and int(x.descent288_owner)!=owner))
 walls=walls.filter(func(x):return owner!=0 and int(x.owner)!=owner)
 if old!=g.field_obstacles.size():d.rebuild_navigation()
func sync_walls()->void:
 var expected=walls.size();var count=0
 for x in g.field_obstacles:
  if x.has("descent288_owner"):count+=1
 if count==expected and walls.all(func(x):return g.field_obstacles.any(func(o):return int(o.get("descent288_owner",0))==int(x.owner) and o.pos==d.point(x.pos))):return
 g.field_obstacles=g.field_obstacles.filter(func(x):return not x.has("descent288_owner"))
 for w in walls:g.field_obstacles.append({"pos":d.point(w.pos),"radius":32.0,"kind":"paper_wall","descent288_owner":int(w.owner)})
 d.rebuild_navigation()
func maze(e:Dictionary)->void:
 clear_walls(int(e.uid))
 for column in 3:
  var gap=700.0 if column%2==0 else 1080.0
  for row in 17:
   var p=Vector2(730+column*470,290+row*68)
   if absf(p.y-gap)<145:continue
   if g.positions.values().any(func(v):return (v as Vector2).distance_to(p)<110) or (e.pos as Vector2).distance_to(p)<110 or d.lamp_pos().distance_to(p)<110:continue
   if not d.segment_clear(p,p):continue
   walls.append({"owner":int(e.uid),"pos":d.pack(p)})
 sync_walls()
func miniboss_step(e:Dictionary,target:String,goal:Vector2,dt:float)->bool:
 if helper_step(e,target,goal,dt):return true
 if str(d.Book.profile(str(e.type)).get("rank",""))!="mid":return false
 var s=state(e);s.left=float(s.left)-dt;s.cooldown=float(s.cooldown)-dt
 if str(s.phase)=="ready":
  if float(s.cooldown)>0 or not str(e.action).is_empty() or float(e.dash_left)>0:return false
  s.cycles=int(s.cycles)+1;s.aim=d.pack(b.predict(target,.3))
  match str(e.type):
   "ds_mid_01":warn(s,e,"dig",1.5,"CRAGJAW DIGS • Leave the marked burrow")
   "ds_mid_02":warn(s,e,"spores",1.65,"FUNGAL SENTENCE • Large poison clouds incoming")
   "ds_mid_03":warn(s,e,"sting",2.0,"COPPERSTING • Heavy venom strike: move or dodge")
   "ds_mid_04":warn(s,e,"shell",4.0,"RUSTED TOLL • Armoured shell; dodge the resonant fronts");wave(e,"RUSTED TOLL","#c6b3cf",1.3)
   "ds_mid_05":warn(s,e,"map",1.8,"MAP REWRITTEN • Temporary walls; follow the open passages")
   "ds_mid_06":warn(s,e,"root_warning",1.8,"ROOT NOTARY • Four roots are taking hold")
   "ds_mid_07":warn(s,e,"steal",1.8,"LANTERN COLLECTOR • Lamp sent to the far corner; hits cost fuel")
   "ds_mid_08":warn(s,e,"brew_warning",2.0,"OSSUARY BREW • Break the three cauldrons to stop the ritual")
   "ds_mid_09":warn(s,e,"survey",1.8,"THORNBOUND SURVEY • Crossed thorn lattice: watch the lanes")
   "ds_mid_10":warn(s,e,"archive_warning",2.2,"COAL ARCHIVIST • Break three seals; each broken seal changes the barrage")
  return true
 e.moving=0
 match str(s.phase):
  "dig":
   if float(s.left)<=0:s.phase="burrow";s.left=3.2;e.buried=true;e.hidden_until=d.clock+3.2;s.from=d.pack(e.pos)
  "burrow":
   var destination=d.safe(d.point(s.aim));e.pos=(e.pos as Vector2).move_toward(destination,240*dt)
   if float(s.left)<=0:
    e.pos=d.safe(e.pos);e.buried=false;e.hidden_until=0
    b.event("CRAGJAW EMERGES",[b.circle(e.pos,160)],18.0,int(e.uid),1.2,.4);finish(s,e,14)
  "spores":
   if float(s.left)<=0:
    for id in g.positions:
     if int(g.health.get(id,0))>0:cloud(int(e.uid),g.positions[id],185,8,1.4)
    for n in 5:cloud(int(e.uid),e.pos+Vector2.from_angle(n*TAU/5+int(s.cycles)*.6)*360,175,8,1.4)
    finish(s,e,17)
  "sting":
   if float(s.left)<=0:
    var dir=(d.point(s.aim)-e.pos).normalized();var finish_at:Vector2=e.pos+dir*430
    for id in g.positions:
     if Geometry2D.get_closest_point_to_segment(g.positions[id],e.pos,finish_at).distance_to(g.positions[id])<62 and d.segment_clear(e.pos,g.positions[id]):harm(str(id),25.0,int(e.uid),"Coppersting's heavy venom",6.0,6.0)
    e.strike=.3;finish(s,e,14)
  "shell":
   if float(s.left)<=0:wave(e,"RUSTED AFTERTOLL","#c6b3cf",1.0);finish(s,e,17)
  "map":
   if float(s.left)<=0:maze(e);s.phase="ambush";s.left=13.0;s.tick=0
  "ambush":
   if float(s.get("bolt_left",0))>0:
    s.bolt_left=float(s.bolt_left)-dt
    if float(s.bolt_left)<=0:b.shoot(e,e.pos,(d.point(s.bolt_aim)-e.pos).normalized(),12.0,"shard",target);e.strike=.3
   s.tick=float(s.tick)-dt
   if float(s.tick)<=0:
    var anchors=open_anchors();e.pos=d.point(anchors[posmod(int(s.cycles)+int(s.aux),4)]);s.aux=int(s.aux)+1;s.tick=3.8;e.hidden_until=d.clock+.45
    b.event("CARTOGRAPHER AMBUSH",[b.rect(Rect2(goal-Vector2(200,55),Vector2(400,110)))],19.0,int(e.uid),1.45,.4)
    s.bolt_left=.9;s.bolt_aim=d.pack(goal)
   if float(s.left)<=0:clear_walls(int(e.uid));finish(s,e,18)
  "root_warning":
   if float(s.left)<=0:
    s.phase="rooted";s.tick=0
    for p in open_anchors():spawn_helper(e,"ds_totem",d.point(p),"root",85.0+g.floor_number*.5)
  "rooted":
   var count=active_helpers(int(e.uid),"root").size()
   if count==0:
    for uid in active_helpers(int(e.uid),"leaf"):retired.append(-int(uid))
    finish(s,e,24)
   else:g.status_label.text="ROOT NOTARY IMMUNE • Destroy roots: %d / 4 remain"%count
  "steal":
   if float(s.left)<=0:
    var far=d.lamp_pos();var score=-1.0
    for p in open_anchors():
     var candidate=d.point(p);var nearest=INF
     for id in g.positions:
      if int(g.health.get(id,0))>0:nearest=minf(nearest,candidate.distance_to(g.positions[id]))
     if nearest>score:score=nearest;far=candidate
    d.drop_lamp(far);finish(s,e,22)
  "brew_warning":
   if float(s.left)<=0:
    s.phase="brewing";s.tick=1.0;s.aux=0
    for n in 3:spawn_helper(e,"ds_totem",d.safe(g.FIELD.size*.5+Vector2.from_angle(n*TAU/3-.5)*560),"cauldron",100.0)
  "brewing":
   var count=active_helpers(int(e.uid),"cauldron").size()
   if count==0:finish(s,e,25)
   else:
    s.tick=float(s.tick)-dt
    if float(s.tick)<=0:
     s.tick=4.0;s.aux=int(s.aux)+1;wave(e,"OSSUARY OVERFLOW","#a5c4ac",1.4,145)
     for uid in active_helpers(int(e.uid),"cauldron"):cloud(int(e.uid),alive(uid).pos,180,4.0,1.1)
    g.status_label.text="OSSUARY RITUAL • %d cauldrons remain • Dodge the overflow"%count
  "survey":
   if float(s.left)<=0:s.phase="lattice";s.left=13.5;s.tick=0;s.aux=0
  "lattice":
   s.tick=float(s.tick)-dt
   if float(s.tick)<=0:
    s.tick=3.7;s.aux=int(s.aux)+1;var shapes:Array=[]
    for n in 4:
     var x=260+n*540+posmod(int(s.aux),2)*150;var y=200+n*370+posmod(int(s.aux)+1,2)*110
     shapes.append(b.rect(Rect2(x,85,110,g.FIELD.size.y-170)));shapes.append(b.rect(Rect2(85,y,g.FIELD.size.x-170,95)))
    b.event("THORNBOUND LATTICE • Run to open squares",shapes,22.0,int(e.uid),1.6,.45)
    if int(s.aux)%2==0:wave(e,"THORN SCYTHE","#aec3a0",2.3,145)
   if float(s.left)<=0:finish(s,e,20)
  "archive_warning":
   if float(s.left)<=0:
    s.phase="archive";s.tick=1.0;s.aux=0
    for n in 3:spawn_helper(e,"ds_totem",d.safe(Vector2(450+n*750,430+posmod(n,2)*820)),"seal",125.0)
  "archive":
   var count=active_helpers(int(e.uid),"seal").size()
   if count==0:finish(s,e,28)
   else:
    s.tick=float(s.tick)-dt
    if float(s.tick)<=0:
     s.tick=4.0;s.aux=int(s.aux)+1
     if count==3:wave(e,"ARCHIVE OF ASH","#d9b68d",1.5,140)
     elif count==2:
      var shapes:Array=[]
      for id in g.positions:shapes.append(b.circle(b.predict(str(id),.5),180))
      b.event("BURNING MARGINS • Leave the marked pages",shapes,25.0,int(e.uid),1.6,.4)
     else:
      b.arena(e,int(s.aux));wave(e,"FINAL COAL VERDICT","#e3b380",2.6,150)
    g.status_label.text="COAL ARCHIVIST IMMUNE • %d archive seals remain"%count
 return true
func range_step299(e:Dictionary,target:String,goal:Vector2,dt:float)->bool:
 if str(d.Book.profile(str(e.type)).get("rank",""))!="mid":return false
 if bool(e.get("buried",false)) or float(e.get("hidden_until",0))>d.clock:return false
 var n=int(str(e.type).trim_prefix("ds_mid_"))-1
 if not e.has("range299"):e.range299={"cooldown":2.2+n*.09,"left":0.0,"aim":d.pack(goal),"casts":0}
 var r:Dictionary=e.range299
 r.cooldown=float(r.cooldown)-dt
 if float(r.left)>0:
  e.moving=0;r.left=maxf(0,float(r.left)-dt)
  if float(r.left)<=0:
   var aim=d.point(r.aim);var direction=(aim-(e.pos as Vector2)).normalized();var damage=float(d.Book.profile(e.type).damage)
   match n:
    0: # Cragjaw throws a heavy pick-like stone; splash pressure at long range.
     b.shoot(e,e.pos,direction,damage,"boulder",target)
    1:
     for i in 5:b.shoot(e,e.pos,direction.rotated((i-2)*.18),damage*.8,"shard",target)
     cloud(int(e.uid),aim,110,3.5,1.0)
    2:
     for i in 3:b.shoot(e,e.pos,direction.rotated((i-1)*.16),damage,"shard",target)
    3:
     for i in 3:b.shoot(e,e.pos,direction.rotated((i-1)*.5),damage*.85,"homing",target)
    4:
     b.event("COMPASS SPEAR • Step off the bearing",[b.rect(Rect2(Vector2(85,aim.y-48),Vector2(g.FIELD.size.x-170,96)))],damage,int(e.uid),.7,.35)
     b.shoot(e,e.pos,direction,damage*.9,"shard",target)
    5:
     for i in 3:b.event("ROOT LANCES • Leave the marked roots",[b.circle(d.safe(aim+Vector2((i-1)*150,0)),90)],damage,int(e.uid),.75+i*.25,.35)
    6:b.event("WICK CHAIN • Leave the lit tether",[b.rect(Rect2(aim-Vector2(170,55),Vector2(340,110)))],damage,int(e.uid),.8,.4);b.shoot(e,e.pos,direction,damage*.8,"homing",target)
    7:
     for i in 3:b.event("OSSUARY FLASK • Leave the falling glass",[b.circle(d.safe(aim+Vector2((i-1)*135,absf(i-1)*65)),95)],damage*.9,int(e.uid),.8+i*.25,.4)
    8:
     for i in 5:b.shoot(e,e.pos,direction.rotated((i-2)*.24),damage*.9,"shard",target)
    9:
     for i in 3:b.shoot(e,e.pos,direction.rotated((i-1)*.24),damage*.8,"boulder",target)
   r.casts=int(r.casts)+1;e.strike=.3
  return true
 if float(r.cooldown)>0:return false
 var names=["FOREMAN'S STONE PICK","FUNGAL SPORE FAN","COPPER VENOM NEEDLES","TOLLING NOTES","COMPASS SPEAR","ROOT LANCES","WICK CHAIN","OSSUARY FLASKS","THORN SCATTER","CINDER COMETS"]
 r.aim=d.pack(b.predict(target,.35));r.left=1.2;r.cooldown=7.0+n*.12
 e.moving=0
 var aim=d.point(r.aim)
 b.event(names[n]+" • Dodge the marked attack",[b.circle(aim,85)],0,int(e.uid),1.2,.01)
 g.status_label.text=str(d.Book.profile(e.type).name)+" • "+names[n]
 return true
func step(dt:float)->void:
 if not retired.is_empty():
  for owner in retired:
   g.opponents=g.opponents.filter(func(e):return int(e.uid)!=-int(owner) and int(helpers.get(str(e.uid),{}).get("owner",0))!=int(owner))
  for key in helpers.keys():
   if alive(int(key)).is_empty():helpers.erase(key)
  retired.clear()
 step_waves(dt);step_clouds(dt)
 for e in g.opponents:
  var kind=str(e.type)
  if b.guardians.owns(e) or not WAVE_THEMES.has(kind) or bool(e.get("phase_pending",false)) or float(e.get("return_ward",0))>0:continue
  var s=state(e);s.cooldown=float(s.cooldown)-dt
  if float(s.cooldown)<=0 and b.events.is_empty() and waves.is_empty() and str(e.action).is_empty() and float(e.get("dash_left",0))<=0:
   var theme=WAVE_THEMES[kind];wave(e,theme[0],theme[1],1.5,145+minf(20,g.floor_number*.15));s.cooldown=13.0
func snapshot()->Dictionary:return {"states":states,"helpers":helpers,"waves":waves,"clouds":clouds,"walls":walls}
func receive(value:Dictionary)->void:
 states=value.get("states",{});helpers=value.get("helpers",{});waves=value.get("waves",[]);clouds=value.get("clouds",[]);walls=value.get("walls",[])
 sync_walls()
func draw(c:Node2D,camera:Vector2)->void:
 for w in walls:
  var p=d.point(w.pos)-camera
  if not Rect2(Vector2.ZERO,g.VIEW).grow(55).has_point(p):continue
  c.draw_rect(Rect2(p-Vector2(31,53),Vector2(62,70)),Color("#bfb49a"));c.draw_rect(Rect2(p-Vector2(25,47),Vector2(50,55)),Color("#e0d6b9"),false,2)
  c.draw_line(p+Vector2(-20,-34),p+Vector2(19,-23),Color("#8f8990"),3);c.draw_line(p+Vector2(0,-45),p+Vector2(4,11),Color("#a09990"),2)
 for w in waves:
  var p=d.point(w.pos)-camera;var radius=float(w.radius);var col=Color(w.color)
  if float(w.left)>0:
   c.draw_arc(p,72,0,TAU,32,Color(col,.65),3,true);c.draw_arc(p,90,-PI*.5,-PI*.5+TAU*(1-float(w.left)/float(w.warning)),40,col,4,true)
  else:
   var view=Rect2(Vector2.ZERO,g.VIEW)
   var extent=radius+float(w.width)*.5+4
   if not view.grow(extent).has_point(p):continue
   c.draw_arc(p,radius,0,TAU,96,Color(col,.40),float(w.width),true)
   c.draw_arc(p,radius+float(w.width)*.5,0,TAU,96,col,3,true)
   if not c.has_method("low_effect_detail") or not c.low_effect_detail():
    for n in 48:
     var v=p+Vector2.from_angle(n*TAU/48)*radius
     if view.grow(20).has_point(v):c.draw_rect(Rect2(v-Vector2(4,4),Vector2(8,8)),col)
 for cloud_value in clouds:
  var p=d.point(cloud_value.pos)-camera;var radius=float(cloud_value.radius)
  if not Rect2(Vector2.ZERO,g.VIEW).grow(radius).has_point(p):continue
  var warning=float(cloud_value.left)>0
  c.draw_circle(p,radius,Color("#9eaf7f",.13 if warning else .32));c.draw_arc(p,radius,0,TAU,40,Color("#c8d19c"),2,true)
  if not warning:
   for n in 8:c.draw_circle(p+Vector2.from_angle(n*TAU/8+d.clock*.15)*radius*.56,18,Color("#bacb8f",.3))
 for e in g.opponents:
  var s=states.get(str(e.uid),{});var phase=str(s.get("phase",""));var p:Vector2=e.pos-camera
  if phase in ["dig","burrow"]:
   c.draw_arc(p,48,0,TAU,24,Color("#c6ad8e"),8,true)
   var landing=d.point(s.aim)-camera;c.draw_circle(landing,160,Color("#d8bc92",.13));c.draw_arc(landing,160,0,TAU,40,Color("#d8bc92"),2,true)
  if phase=="sting":
   var aim=d.point(s.aim)-e.pos;var end=p+aim.normalized()*430;c.draw_line(p,end,Color("#e0bd7e",.4),124,true);c.draw_circle(end,62,Color("#e0bd7e",.28));c.draw_line(p,end,Color("#f2d69e"),2,true)
  if phase=="ambush" and float(s.get("bolt_left",0))>0:c.draw_line(p,d.point(s.bolt_aim)-camera,Color("#ddcfb7",.8),2,true)
  if phase in ["rooted","brewing","archive"]:c.draw_arc(p+Vector2(0,-32),75,0,TAU,40,Color("#b4c694",.8),3,true)
  if phase in ["dig","spores","map","root_warning","steal","brew_warning","survey","archive_warning"]:
   c.draw_arc(p,80,0,TAU,40,Color("#ead4a7",.7),3,true)
  var extra:Dictionary=e.get("range299",{})
  if float(extra.get("left",0))>0:
   var aimed=d.point(extra.aim)-camera;c.draw_line(p,aimed,Color(.89,.74,.48,.65),2,true);c.draw_arc(p,62,0,TAU,32,Color("#e8cb92"),3,true)
  var helper=helpers.get(str(e.uid),{})
  if not helper.is_empty():
   var role=str(helper.role)
   if role!="leaf":
    c.draw_arc(p,42,0,TAU,24,Color("#bfd0a0") if role=="root" else Color("#d7b88b"),3,true)
    c.draw_string(ThemeDB.fallback_font,p+Vector2(-90,-77),str(e.get("name",role)),HORIZONTAL_ALIGNMENT_CENTER,180,13,Color("#eadbb9"))
   if role=="root" and helper.has("aim"):c.draw_line(p,d.point(helper.aim)-camera,Color("#cad5ab",.7),2,true)
