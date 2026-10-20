extends Node
## Earthquake pulses and non-stacking allied enchantments; authority owns combat.
var combat:Node
var effects:Array=[]
var clock:=0.0
var burn_ready:Dictionary={}
const STYLES=["oar_sweep","whistle_wave","hearth_light","ram_quake","hearth_tap","hearth_kindle","hearth_beacon","hearth_mend","hearth_march"]
func reset()->void:effects.clear();burn_ready.clear();clock=0
func add(owner:String,kind:String,p:Vector2,time:float,radius:float)->Dictionary:
 var e:Dictionary={"owner":owner,"kind":kind,"pos":combat.point_array(p),"time":time,"duration":time,"radius":radius,"tick":0.0,"age":0.0,"count":0}
 if effects.size()<64:effects.append(e)
 return e
func enchant(id:String)->Dictionary:
 if not combat.playing() or not combat.adventure.alive(id):return {}
 for e in effects:
  if e.kind in ["kindle","march"] and combat.adventure.alive(str(e.owner)) and float(e.time)>0 and (e.get("targets",[]) as Array).has(id):return e
 return {}
func bonus(id:String)->float:return 1.08 if not enchant(id).is_empty() else 1.0
func defence(id:String)->float:
 if not combat.playing() or not combat.adventure.alive(id):return 0
 for owner in combat.adventure.points():
  if not combat.adventure.alive(str(owner)) or not combat.passive(str(owner),"shared_hearth") or not combat.v75.friendly(str(owner),id):continue
  if combat.owner_pos(str(owner)).distance_to(combat.owner_pos(id))<=170 and combat.path_clear(combat.owner_pos(str(owner)),combat.owner_pos(id)):return .1
 return 0
func on_hit(owner:String,target:String,actual:float)->void:
 if actual<=0 or combat.dot_damage or not combat.adventure.authoritative() or enchant(owner).is_empty():return
 var token:String=owner+"|"+target
 if clock<float(burn_ready.get(token,0)):return
 burn_ready[token]=clock+1
 var e:Dictionary=enchant(owner)
 if e.kind=="march":combat.release_heroes.heal(str(e.owner),owner,3)
 else:combat.apply_status(target,"burn",3,owner,2)
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:String=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.playing() or not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var p:Vector2=combat.owner_pos(owner)
 match style:
  "ram_quake":
   var e:Dictionary=add(owner,"quake",p,3,float(stats.get("radius",155)));e.damage=amount;e.slow_tick=0.0
  "oar_sweep":
   var e:Dictionary=add(owner,"oar",p,.28,float(stats.get("range",82)));e.aim=combat.point_array(aim);e.damage=amount;e.hits=[];e.previous_angle=-.65;e.stats=stats.duplicate(true)
  "hearth_light":
   for e in effects.duplicate():
    if e.owner==owner and e.kind=="light":effects.erase(e)
   var reach:float=float(stats.get("range",190))
   var e:Dictionary=add(owner,"light",p,.5,reach);e.aim=combat.point_array(aim)
   for key in combat.hostile(owner):
    var f:Dictionary=combat.actor(key)
    if not f.is_empty() and bool(f.alive) and combat.v56.cone(p,aim,f.pos,reach,.72) and combat.path_clear(p,f.pos):combat.damage(key,amount,owner,"Lantern Light")
   for ally in combat.party_heroes.friendly_near(owner,p,reach):
    var ap:Vector2=combat.vec(combat.adventure.game.battlegrounds.units[ally].pos) if str(ally).begins_with("bgunit:") else combat.owner_pos(str(ally))
    if str(ally)!=owner and combat.v56.cone(p,aim,ap,reach,.72) and combat.path_clear(p,ap):combat.release_heroes.heal(owner,str(ally),int(stats.get("healing",1)))
  "whistle_wave":
   var e:Dictionary=add(owner,"echo",p,float(stats.get("range",400))/360,55);e.aim=combat.point_array(aim);e.hits=[];e.damage=amount;e.travel=0.0
   for ally in combat.party_heroes.friendly_near(owner,p,110):combat.apply_status(combat.player_key(str(ally)),"guard",.8,owner,.08)
  "hearth_tap":
   var reach:float=float(stats.get("range",95))
   for key in combat.hostile(owner):
    var f:Dictionary=combat.actor(key)
    if not f.is_empty() and bool(f.alive) and combat.v56.cone(p,aim,f.pos,reach,.45) and combat.path_clear(p,f.pos):combat.damage(key,amount,owner)
   var e:Dictionary=add(owner,"tap",p,.3,reach);e.aim=combat.point_array(aim)
  "hearth_kindle","hearth_march":
   for e in effects.duplicate():
    if e.owner==owner and e.kind in ["kindle","march"]:effects.erase(e)
   var e:Dictionary=add(owner,"march" if style=="hearth_march" else "kindle",p,5,220)
   e.targets=combat.party_heroes.friendly_near(owner,p,220)
  "hearth_beacon","hearth_mend":
   for e in effects.duplicate():
    if e.owner==owner and e.kind in ["beacon","mend"]:effects.erase(e)
   var end:Vector2=combat.v79.destination(owner,aim,280)
   var e:Dictionary=add(owner,"mend" if style=="hearth_mend" else "beacon",end,6,180);e.caught=0
 return true
func catch_shot(start:Vector2,finish:Vector2,source:String)->bool:
 if not combat.playing() or not combat.adventure.authoritative():return false
 for e in effects:
  if e.kind!="beacon" or int(e.caught)>=6 or not combat.adventure.alive(str(e.owner)):continue
  if source!="enemy" and combat.v75.friendly(str(e.owner),source):continue
  if Geometry2D.get_closest_point_to_segment(combat.vec(e.pos),start,finish).distance_to(combat.vec(e.pos))<=float(e.radius):e.caught=int(e.caught)+1;return true
 return false
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 if not combat.playing():reset();return
 for token in burn_ready.keys():
  if clock>float(burn_ready[token])+1:burn_ready.erase(token)
 for i in range(effects.size()-1,-1,-1):
  var e:Dictionary=effects[i];var owner:String=str(e.owner)
  if not combat.adventure.alive(owner):effects.remove_at(i);continue
  var used:float=minf(delta,maxf(0,float(e.time)));e.time=float(e.time)-delta;e.age=float(e.age)+used;e.tick=float(e.tick)+used
  if e.kind=="oar":e.pos=combat.point_array(combat.owner_pos(owner))
  var p:Vector2=combat.vec(e.pos)
  if e.kind=="oar":
   var aim:Vector2=combat.vec(e.aim);var angle:float=-.65+clampf(float(e.age)/.28,0,1)*1.3
   for key in combat.hostile(owner):
    var f:Dictionary=combat.actor(key)
    if f.is_empty() or not bool(f.alive) or key in e.hits:continue
    var rel:Vector2=f.pos-p;var facing:float=wrapf(rel.angle()-aim.angle(),-PI,PI)
    if rel.length()<=float(e.radius) and facing>=float(e.previous_angle)-.15 and facing<=angle+.15 and combat.path_clear(p,f.pos):
     e.hits.append(key);combat.damage(key,float(e.damage),owner,"Oar Sweep")
     if float(e.stats.get("slow_duration",0))>0:combat.apply_status(key,"slow",float(e.stats.slow_duration),owner,.6)
   e.previous_angle=angle
  if e.kind=="echo":
   var aim:Vector2=combat.vec(e.aim);var next:Vector2=p+aim*360*used
   if not combat.path_clear(p,next):e.time=0
   else:
    for key in combat.hostile(owner):
     var f:Dictionary=combat.actor(key)
     if f.is_empty() or not bool(f.alive) or key in e.hits:continue
     var rel:Vector2=f.pos-p
     if rel.dot(aim)>=-12 and rel.dot(aim)<=360*used+12 and absf(rel.dot(aim.orthogonal()))<=55 and combat.path_clear(p,f.pos):e.hits.append(key);combat.damage(key,float(e.damage),owner,"Safety Whistle")
    e.pos=combat.point_array(next)
  if e.kind=="light":
   e.pos=combat.point_array(combat.owner_pos(owner))
   if combat.held_cast.charges.has(owner):e.aim=combat.held_cast.charges[owner].aim
   else:e.time=0
  if e.kind=="quake":
   e.slow_tick=float(e.slow_tick)+used
   if float(e.slow_tick)>=.1:
    e.slow_tick=0.0
    for key in combat.hostile(owner):
     var f:Dictionary=combat.actor(key)
     if not f.is_empty() and bool(f.alive) and p.distance_to(f.pos)<=float(e.radius) and combat.path_clear(p,f.pos):combat.apply_status(key,"slow",.65,owner,.35)
   while float(e.tick)>=.49999 and int(e.count)<6:
    e.tick=maxf(0,float(e.tick)-.5);e.count=int(e.count)+1
    var hit:float=floorf(float(e.damage)/6) if int(e.count)<6 else float(e.damage)-floorf(float(e.damage)/6)*5
    for key in combat.hostile(owner):
     var f:Dictionary=combat.actor(key)
     if not f.is_empty() and bool(f.alive) and p.distance_to(f.pos)<=float(e.radius) and combat.path_clear(p,f.pos):combat.damage(key,hit,owner)
  elif e.kind in ["beacon","mend"]:
   while float(e.tick)>=1:
    e.tick-=1
    for ally in combat.party_heroes.friendly_near(owner,p,float(e.radius)):combat.release_heroes.heal(owner,str(ally),7 if e.kind=="mend" else 4)
  if e.time<=0 and effects.has(e):effects.erase(e)
func snapshot()->Dictionary:return {"effects":effects,"clock":clock}
func receive(data:Dictionary)->void:effects=data.get("effects",[]);clock=float(data.get("clock",clock))
func draw_on(c:Node2D,camera:Vector2)->void:
 if not combat.playing():return
 var visible:=Rect2(camera-Vector2(230,230),c.get_viewport_rect().size+Vector2(460,460))
 for owner in combat.adventure.points():
  if combat.passive(str(owner),"shared_hearth") and combat.adventure.alive(str(owner)) and combat.visible_owner(str(owner)):
   var p:Vector2=combat.owner_pos(str(owner))-camera
   if visible.has_point(combat.owner_pos(str(owner))):c.draw_arc(p,170,clock*.2,clock*.2+TAU,36,Color(.98,.7,.4,.18),1.5,true)
  if not enchant(str(owner)).is_empty() and combat.visible_owner(str(owner)):
   var p:Vector2=combat.owner_pos(str(owner))-camera
   if visible.has_point(combat.owner_pos(str(owner))):
    for n in 3:c.draw_circle(p+Vector2.from_angle(clock*1.5+n*TAU/3)*23-Vector2(0,20),3,Color("#ffb061"))
 var drawing:Array=effects
 if combat.adventure.arcade and combat.adventure.game.has_method("network_v112_effects") and not combat.adventure.game.dedicated:drawing=combat.adventure.game.network_v112_effects()
 for e in drawing:
  var world:Vector2=combat.draw_effect_position("v112",e,combat.vec(e.pos))
  if not visible.has_point(world):continue
  var p:Vector2=world-camera;var radius:float=float(e.radius)
  match str(e.kind):
   "oar":
    var aim:Vector2=combat.vec(e.aim).rotated(-.65+clampf(float(e.age)/.28,0,1)*1.3);var side:=aim.orthogonal();var end:=p+aim*radius
    c.draw_line(p+aim*12,end-aim*18,Color("#93764e"),4,true)
    c.draw_colored_polygon(PackedVector2Array([end-aim*24-side*6,end-side*8,end+side*8,end-aim*24+side*6]),Color("#d8bc89"))
    c.draw_arc(p,radius,aim.angle()-.16,aim.angle(),8,Color(.65,.94,.9,.35),3,true)
   "light":
    var aim:Vector2=combat.vec(e.aim);var sector:=PackedVector2Array([p]);var half:float=acos(.72)
    for n in 25:sector.append(p+aim.rotated(-half+n/24.0*half*2)*radius)
    c.draw_colored_polygon(sector,Color(1,.86,.4,.15))
    for n in 3:c.draw_arc(p,radius*(.35+n*.3),aim.angle()-half,aim.angle()+half,24,Color(1,.9,.5,.25),2,true)
    c.draw_circle(p+aim*18,7,Color("#fff4a9"))
   "echo":
    var aim:Vector2=combat.vec(e.aim);var side:=aim.orthogonal()
    for n in 3:
     var wave:=PackedVector2Array()
     for j in 17:
      var offset:float=(j/16.0-.5)*110
      wave.append(p+side*offset-aim*(n*9+12*pow(offset/55,2)))
     c.draw_polyline(wave,Color(1,.85,.45,.75-n*.18),3,true)
   "quake":
    var shake:=Vector2(sin(clock*43)*2,cos(clock*37)*2)
    c.draw_circle(p,radius,Color(.65,.46,.24,.12));c.draw_arc(p+shake,radius,0,TAU,40,Color(.95,.77,.45,.6),3,true)
    for n in 8:
     var dir:=Vector2.from_angle(n*TAU/8);var side:=dir.orthogonal()
     c.draw_polyline(PackedVector2Array([p+dir*30,p+dir*65+side*sin(clock*17+n)*7,p+dir*100-side*9,p+dir*(radius-5)+side*4]),Color(.88,.67,.34,.65),2,true)
    for n in 3:c.draw_arc(p+shake,radius*fposmod(float(e.age)*1.7+n/3.0,1),0,TAU,32,Color(.88,.7,.42,.3),2,true)
   "tap":
    var aim:Vector2=combat.vec(e.aim);var angle:float=aim.angle()-.7+float(e.age)/.3*1.4
    c.draw_line(p+Vector2.from_angle(angle)*25,p+Vector2.from_angle(angle)*radius,Color("#e9b776"),4,true);c.draw_arc(p,radius,angle-.2,angle+.2,8,Color("#ffc982"),4,true)
   "kindle","march":pass
   "beacon","mend":
    c.draw_circle(p,radius,Color(.94,.7,.3,.08));c.draw_arc(p,radius,0,TAU,40,Color(.99,.74,.42,.38),2,true)
    c.draw_line(p+Vector2(0,12),p-Vector2(0,65),Color("#8b624b"),5,true)
    c.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-65),p+Vector2(38,-62),p+Vector2(29,-40),p+Vector2(0,-43)]),Color("#bb674b"))
    c.draw_circle(p+Vector2(16,-53),6,Color("#ffd894"))
    for n in 4:c.draw_circle(p+Vector2(sin(clock*2+n)*17,-28-fposmod(clock*10+n*13,36)),2,Color(.98,.79,.48,.6))
