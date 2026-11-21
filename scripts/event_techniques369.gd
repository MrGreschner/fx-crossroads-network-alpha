extends RefCounted
const STYLES=["waterhammer","sluice_gate","thornbow","briar_circle","doorstep_bell","emergency_delivery","driftkick","whiteout_escort","banner_drill","clockwork_volley","icicle_fan","glacier_break"]
static func targets(c:Node,id:String,p:Vector2,r:float)->Array[String]:
 var keys:Array[String]=[]
 for key in c.hostile(id,p,r):
  var foe:Dictionary=c.actor(key)
  if foe.get("alive",false) and p.distance_squared_to(foe.pos)<=r*r and c.path_clear(p,foe.pos):keys.append(key)
 return keys
static func support(c:Node,id:String,p:Vector2,r:float,heal:int,guard:float,time:float,speed:float)->void:
 for ally in c.party_heroes.friendly_near(id,p,r):
  if heal>0:c.release_heroes.heal(id,str(ally),heal)
  if guard>0:c.apply_status(c.player_key(str(ally)),"guard",time,id,guard)
  if speed>1:c.apply_status(c.player_key(str(ally)),"scout_stride",time,id,speed)
static func cast(e:Node,id:String,s:Dictionary,p:Vector2,aim:Vector2,damage:float)->void:
 var c:Node=e.combat
 match str(s.style):
  "waterhammer":
   c.launch_projectile(id,p+aim*12,aim,s,damage+(9 if e.pressure.erase(id) else 0))
  "thornbow","doorstep_bell":
   e.sweep(id,str(s.style),p,aim,float(s.range))
   var hit=false
   for key in targets(c,id,p,float(s.range)):
    if (c.actor(key).pos-p).normalized().dot(aim)<.4:continue
    c.damage(key,damage,id,str(s.name));hit=true
    if s.style=="thornbow":c.apply_status(key,"slow",.75,id,.7)
   if hit and s.style=="doorstep_bell" and c.passive(id,"gift_wrap"):e.gifts[id]=mini(3,int(e.gifts.get(id,0))+1)
   if hit and s.style=="thornbow":e.stand_tall(id,p)
  "driftkick":
   var full:bool=float(e.momentum.get(id,0))>=125
   var shot=s.duplicate()
   shot.slow_factor=.65 if full else .8;shot.slow_duration=1.15 if full else .8
   if full:e.momentum.erase(id)
   c.launch_projectile(id,p+aim*12,aim,shot,damage+(8 if full else 0))
  "whiteout_escort":
   e.flights[id]={"time":e.AIR_TIME,"drop":0.0,"damage":0,"escort":true};e.stop_dodge(id)
  "icicle_fan":
   for angle in [-.24,0.0,.24]:c.launch_projectile(id,p+aim.rotated(angle)*10,aim.rotated(angle),s,damage)
  _:
   var point:Vector2=c.v79.destination(id,aim,float(s.range))
   var kind:String=s.style
   if kind=="emergency_delivery":
    e.drop(id,"aid_parachute",p,point,1.25,0);e.fields[-1].radius=s.radius
   else:
    var time:float={"sluice_gate":.6,"glacier_break":.75,"briar_circle":2.85,"banner_drill":4.0,"clockwork_volley":2.95}[kind]
    e.field(id,kind,point,float(s.radius),time,damage)
    if kind in ["briar_circle","banner_drill","clockwork_volley"]:
     e.fields[-1].pulse=.15 if kind=="banner_drill" else .6
     e.fields[-1].aim=c.point_array(aim)
static func impact(e:Node,f:Dictionary,p:Vector2)->String:
 var c:Node=e.combat
 match str(f.kind):
  "aid_parachute":
   support(c,f.owner,p,f.radius,24,.3,2,1);return "aid_landed"
  "sluice_gate":
   for key in targets(c,f.owner,p,f.radius):
    var v:Vector2=p-c.actor(key).pos
    c.damage(key,f.damage,f.owner,"Sluice Gate");c.knock(key,v.normalized(),minf(v.length(),58))
   return "sluice_splash"
  "glacier_break":
   for key in targets(c,f.owner,p,f.radius):
    c.damage(key,f.damage,f.owner,"Glacier Break");e.frost.chill(c,key,f.owner,70)
   return "glacier_shatter"
 return ""
static func pulse(c:Node,f:Dictionary,p:Vector2,dt:float)->void:
 if not f.has("pulse"):return
 f.pulse-=dt
 if f.pulse>0:return
 match str(f.kind):
  "briar_circle":
   f.pulse+=1
   for key in targets(c,f.owner,p,f.radius):
    c.damage(key,f.damage,f.owner,"Briar Circle");c.apply_status(key,"slow",.9,f.owner,.72)
  "banner_drill":
   f.pulse+=.25;support(c,f.owner,p,f.radius,0,.18,.32,1.15)
  "clockwork_volley":
   f.pulse+=1
   var aim:Vector2=c.vec(f.aim)
   for offset in [-.22,0.0,.22]:
    c.launch_projectile(f.owner,p,aim.rotated(offset),{"name":"Clockwork Volley","style":"clockwork_bolt","range":235,"speed":485,"color":"#f5b98b"},f.damage)
