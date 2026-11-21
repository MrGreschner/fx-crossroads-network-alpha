extends RefCounted
## Duel-only controllers. Normal kits and cooldowns; sampled perception, committed casts.
const ID="bot:0"
const PROFILES={
 "briar":[1,"Acorn skirmisher",215,.26,.065,.60],"recess":[1,"Patrol defender",255,.29,.065,.58],
 "sunflower":[2,"Bloom artillery",300,.25,.055,.65],"snowman":[2,"Chilling pursuer",200,.28,.06,.60],
 "tidewright":[2,"Sluice controller",275,.24,.05,.69],"cantor":[2,"Relay conductor",310,.23,.045,.72],
 "lockjaw":[2,"Clamp hunter",65,.26,.055,.63],"echo_dancer":[2,"Feint duelist",77,.24,.05,.74],
 "bracken":[2,"Minefield baiter",120,.26,.05,.68],"elara":[2,"Shard zoner",285,.24,.05,.71],
 "kage":[2,"Blade ambusher",78,.23,.045,.76],"pippa":[2,"Fern anchor",245,.27,.055,.65],
 "velvetwing":[2,"Silk trapper",285,.25,.05,.70],"chronicle":[2,"Time counter",290,.24,.05,.72],
 "apiary":[2,"Hive marksman",275,.25,.05,.68],"medic":[2,"Sustaining brawler",72,.27,.055,.63],
 "tova":[3,"Haven footworker",82,.24,.045,.74],"hazel_hex":[3,"Poison kiter",320,.24,.045,.75],
 "ferryman":[3,"Oar and stone",76,.23,.045,.75],"cobbleclaw":[3,"Shell counter",76,.27,.05,.65],
 "nera":[3,"Latchline planner",295,.22,.04,.78],"robot":[3,"Transforming bruiser",90,.25,.045,.68],
 "snail":[3,"Volcanic bastion",105,.28,.05,.62],"vesper":[3,"Disc and guard",165,.22,.04,.79],
 "veyra":[3,"Snare punisher",310,.22,.04,.79],"dawnblade":[2,"Dawn counterguard",76,.25,.05,.69],
 "rune_duelist":[2,"Rune closer",83,.24,.045,.73],"anjali":[2,"Branch archer",300,.25,.05,.71]
}
var g:Node
var hero_id=""
var profile:Array=[]
var clock=0.0
var think=0.0
var wish=Vector2.ZERO
var aim=Vector2.RIGHT
var target=Vector2.ZERO
var velocity=Vector2.ZERO
var sampled=Vector2.ZERO
var seen_at=-1.0
var visible=false
var side=1.0
var side_at=0.0
var pending:Dictionary={}
var threat:Dictionary={}
var threat_key=""
var threat_since=0.0
var threat_checked=false
var danger:Dictionary={}
var danger_since=0.0
var dash=0.0
var dash_dir=Vector2.ZERO
var recover=0.0
var last:Dictionary={}
var rng=RandomNumberGenerator.new()
var decisions:Dictionary={"dodges":0,"casts":{},"blocks":0}
func setup(owner:Node,id:String)->void:
 g=owner;hero_id=id;profile=PROFILES[id];rng.seed=hash(id+str(g.match_id));side=1 if rng.randf()<.5 else -1
 sampled=g.positions.get(g.my_id,Vector2.ZERO);target=sampled
func ready(kind:String)->bool:
 if kind=="special" and not last.has(kind) and clock<6.5-float(profile[0])*.5:return false
 if kind=="secondary" and not last.has(kind) and clock<2:return false
 return Time.get_ticks_msec()>=int(g.cooldown_at.get(ID,{}).get(kind,0))
func hp()->float:return float(g.health.get(ID,0))/maxf(1,g._max_hp(ID))
func since(kind:String)->float:return clock-float(last.get(kind,-100))
func primary_range()->float:
 var s:Dictionary=g.characters[hero_id].primary
 return maxf(90,float(s.get("range",90))) if hero_id=="robot" else float(s.get("range",90))
func locked()->bool:
 var c=g.adventure.combat
 return g.charges.has(ID) or c.busy(ID) or c.events.locks_input(ID) or c.events.following(ID) or c.v79.moving(ID) or c.v78.locked(ID) or c.v110.charging(ID) or c.halloween.moving(ID) or c.release_heroes.locked(ID) or c.adventure.immersive.aboard(ID) or c.classics.locked(ID)
func sample()->void:
 var next:Vector2=g.positions[g.my_id];var elapsed=maxf(.01,clock-seen_at)
 velocity=((next-sampled)/elapsed).limit_length(420) if seen_at>=0 else Vector2.ZERO
 sampled=next;seen_at=clock;visible=Time.get_ticks_msec()>=int(g.stealth_until.get(g.my_id,0))
 if visible:target=next
 var field=field_threat()
 if field.is_empty():danger={}
 else:
  if danger.is_empty() or (danger.pos as Vector2).distance_to(field.pos)>30:danger_since=clock
  danger=field
 # Threats are observed only at decision ticks. A new shot must remain visible
 # for the reaction delay; instant spawns at the champion's feet are not dodged.
 var t=projectile_threat()
 if t.is_empty():threat={};threat_key=""
 else:
  if str(t.key)!=threat_key:threat_key=str(t.key);threat_since=clock;threat_checked=false
  threat=t
func projectile_threat()->Dictionary:
 var origin:Vector2=g.positions[ID];var result={};var nearest=INF
 var lists=[g.missiles,g.adventure.combat.projectiles,g.adventure.combat.confluence.shots]
 for list in lists:
  for shot in list:
   if str(shot.get("owner",""))!=g.my_id:continue
   var p:Vector2=shot.pos if shot.pos is Vector2 else g.adventure.combat.vec(shot.pos)
   if origin.distance_to(p)>700:continue
   var d:Vector2=shot.get("direction",Vector2.ZERO) if shot.has("direction") else g.adventure.combat.vec(shot.get("aim",[0,0]))
   if d.length_squared()<.1:continue
   var speed=maxf(1,float(shot.get("speed",320)));var along=(origin-p).dot(d);var eta=along/speed
   if eta<0 or eta>1.05 or absf((origin-p).cross(d))>42:continue
   if eta<nearest:
    nearest=eta;result={"key":str(shot.get("credit",{}).get("label",""))+":"+str(shot.get("origin",shot.get("born_tick",0)))+":"+str(d),"direction":d,"eta":eta}
 return result
func field_threat()->Dictionary:
 var origin:Vector2=g.positions[ID];var c=g.adventure.combat
 for list in [c.pools,c.confluence.zones,c.events.fields]:
  for field in list:
   if str(field.get("owner",""))!=g.my_id or not field.has("pos"):continue
   var point:Vector2=field.pos if field.pos is Vector2 else c.vec(field.pos)
   var radius=float(field.get("radius",field.get("max_radius",85)))
   if radius>0 and origin.distance_to(point)<radius+35:return {"pos":point,"radius":radius}
 return {}
func react()->void:
 if threat.is_empty() or clock-threat_since<float(profile[3]) or not visible or locked():return
 var d:float=g.positions[ID].distance_to(target)
 # Guards consume the real secondary/special; a missed block remains punishable.
 if hero_id in ["dawnblade","cobbleclaw"] and ready("secondary") and d<380:
  if issue("secondary",target):decisions.blocks+=1;threat={};return
 if hero_id=="vesper" and ready("special"):
  if issue("special",target):decisions.blocks+=1;threat={};return
 if Time.get_ticks_msec()<int(g.dodge_at.get(ID,0)) or dash>0:return
 # One chance per observed projectile, rather than rerolling until guaranteed.
 if threat_checked:return
 threat_checked=true
 if rng.randf()>float(profile[5]):return
 var perpendicular:Vector2=(threat.direction as Vector2).orthogonal()
 var a:Vector2=g.positions[ID]+perpendicular*155;var b:Vector2=g.positions[ID]-perpendicular*155
 dash_dir=perpendicular if clearance(a)>clearance(b) else -perpendicular
 if clearance(g.positions[ID]+dash_dir*155)<35:return
 dash=.26;pending={};g.adventure.combat.held_cast.charges.erase(ID)
 g.dodge_at[ID]=Time.get_ticks_msec()+2500;g.invincible_until[ID]=Time.get_ticks_msec()+220
 decisions.dodges+=1
func clearance(p:Vector2)->float:return minf(minf(p.x-g.FIELD.position.x,g.FIELD.end.x-p.x),minf(p.y-g.FIELD.position.y,g.FIELD.end.y-p.y))
func issue(kind:String,point:Vector2)->bool:
 if not ready(kind) or not visible or locked():return false
 var before=int(g.cooldown_at[ID].get(kind,0));var direction=(point-g.positions[ID]).normalized()
 if direction.length_squared()<.1:direction=aim
 g.cast_champion(kind,direction,point)
 var held=g.adventure.combat.held_cast
 var accepted=held.charges.has(ID) or int(g.cooldown_at[ID].get(kind,0))>before
 if accepted:
  last[kind]=clock;decisions.casts[kind]=int(decisions.casts.get(kind,0))+1;recover=.12
 return accepted
func schedule(kind:String,point:Vector2)->void:
 if not ready(kind) or not pending.is_empty():return
 var dir=(point-g.positions[ID]).normalized().rotated(rng.randf_range(-float(profile[4]),float(profile[4])))
 var committed=g.positions[ID]+dir*g.positions[ID].distance_to(point)
 pending={"kind":kind,"point":committed,"time":.62 if kind=="special" else .36 if kind=="secondary" else .14}
 if kind!="primary":g._emit_effect({"style":"ring","pos":g.positions[ID],"color":"#f0c278","radius":70,"time":float(pending.time)})
func special_tactic(d:float)->String:
 var hurt=hp()<.68;var close=d<155;var mid=d<350
 match hero_id:
  "briar":
   if ready("secondary") and d<105:return "secondary"
   if ready("special") and mid and since("secondary")<3:return "special"
  "recess":
   if ready("secondary") and hurt:return "secondary"
   if ready("special") and mid:return "special"
  "sunflower":
   if ready("secondary") and mid:return "secondary"
   if ready("special") and d<600 and since("secondary")<4:return "special"
  "snowman":
   if ready("secondary") and d<165:return "secondary"
   if ready("special") and d>160 and d<450:return "special"
  "tidewright":
   if ready("secondary") and mid:return "secondary"
   if ready("special") and d<420 and since("secondary")<4:return "special"
  "cantor":
   if ready("secondary") and mid:return "secondary"
   if ready("special") and d<410 and since("secondary")<5:return "special"
  "lockjaw":
   if g.adventure.combat.events.clamped(ID):return ""
   if ready("secondary") and d<108:return "secondary"
   if ready("special") and d<150 and not ready("secondary"):return "special"
  "echo_dancer":
   if ready("secondary") and d<230 and since("primary")<2 and not g.adventure.combat.v110.memories.get(ID,[]).is_empty():return "secondary"
   if ready("special") and d<110 and since("secondary")<4:return "special"
  "bracken":
   if ready("secondary") and d<220 and since("primary")<2:return "secondary"
   if ready("special") and (d<85 or d>180 and d<275):return "special"
  "elara":
   if ready("secondary") and d<170:return "secondary"
   if ready("special") and d<310:return "special"
  "kage":
   if ready("secondary") and d>130 and d<410:return "secondary"
   if ready("special") and d<190 and since("secondary")<4:return "special"
  "pippa":
   if ready("secondary") and d<280:return "secondary"
   if ready("special") and d<185 and since("secondary")<5:return "special"
  "velvetwing":
   if ready("secondary") and d<260:return "secondary"
   if ready("special") and mid and since("secondary")<4:return "special"
  "chronicle":
   if ready("secondary") and hurt:return "secondary"
   if ready("special") and d<250:return "special"
  "apiary":
   if ready("secondary") and mid:return "secondary"
   if ready("special") and mid and since("secondary")<5:return "special"
  "medic":
   if ready("secondary") and hp()<.76:return "secondary"
   if ready("special") and hp()<.55:return "special"
  "tova":
   if ready("secondary") and d<125:return "secondary"
   if ready("special") and (hurt or d<145):return "special"
  "hazel_hex":
   if ready("secondary") and d<160:return "secondary"
   if ready("special") and d<245:return "special"
  "ferryman":
   if ready("secondary") and d>120 and d<385:return "secondary"
   if ready("special") and d<190:return "special"
  "cobbleclaw":
   if ready("special") and d>125 and d<270:return "special"
   if ready("secondary") and close and hurt:return "secondary"
  "nera":
   if ready("secondary") and mid:return "secondary"
   if ready("special") and d<620 and since("secondary")<3:return "special"
  "robot":
   if ready("special") and d<175:return "special"
   if ready("secondary") and d>145 and d<450:return "secondary"
  "snail":
   if ready("special") and d<230:return "special"
   if ready("secondary") and d>150 and d<450:return "secondary"
  "vesper":
   if ready("special") and d<120:return "special"
   if ready("secondary") and d<295:return "secondary"
  "veyra":
   if ready("secondary") and d<235:return "secondary"
   if ready("special") and d<410 and since("secondary")<3:return "special"
  "dawnblade":
   if ready("secondary") and d<120 and ready("primary"):return "secondary"
   if ready("special") and d<115 and since("secondary")<2:return "special"
  "rune_duelist":
   if ready("secondary") and d>150 and d<460:return "secondary"
   if ready("special") and d<155 and since("secondary")<3:return "special"
  "anjali":
   var branch:Dictionary=g.adventure.combat.events.branches.get(ID,{})
   if branch.is_empty() and ready("secondary"):return "secondary"
   if not branch.is_empty() and d<160 and g.positions[ID].distance_to(g.adventure.combat.vec(branch.pos))>120 and since("secondary")>1:return "recast"
   if ready("special") and d<370:return "special"
 return ""
func step(delta:float)->void:
 if not g.started or g.start_countdown>0 or g.settled or not g.positions.has(ID) or float(g.health.get(ID,0))<=0:return
 clock+=delta;think-=delta;recover=maxf(0,recover-delta)
 var c=g.adventure.combat
 if c.stunned("p:"+ID):pending={};dash=0;return
 if dash>0:
  var dt=minf(delta,dash);g.trails.append({"pos":g.positions[ID],"time":.18})
  g.positions[ID]=g._move_actor(g.positions[ID],dash_dir*(330+370*sin(PI*dash/.26))*dt*c.v79.dodge_factor(ID));dash=maxf(0,dash-dt);return
 if think<=0:
  var elapsed=maxf(.01,clock-seen_at);sample();think=float(profile[3]);side_at-=elapsed
  if side_at<=0:side_at=rng.randf_range(2.4,4.1);side=-side
  if visible:
   var origin:Vector2=g.positions[ID];var offset:Vector2=target-origin;var d=offset.length();aim=offset.normalized()
   var desired=float(profile[2]);var kit:Dictionary=g.characters[hero_id]
   # Close in after a ranged setup; back out when the melee opener is on cooldown.
   if hero_id=="kage" and clock<2:desired=260
   if hero_id in ["velvetwing","veyra"] and ready("secondary"):desired=215
   if hero_id in ["kage","echo_dancer","rune_duelist"] and since("secondary")<2.8:desired=74
   if hero_id in ["dawnblade","cobbleclaw"] and since("secondary")<1.3:desired=65
   if hero_id in ["lockjaw","briar"] and ready("secondary"):desired=minf(desired,85)
   if hero_id=="robot" and c.robot.transformed(ID):desired=65
   if hero_id=="medic" and hp()<.5:desired=140
   if hero_id=="hazel_hex" and d<160:desired=350
   wish=aim if d>desired+30 else -aim if d<desired-30 else aim.orthogonal()*side*.75
   if not danger.is_empty() and clock-danger_since>=float(profile[3]):
    var away=origin-(danger.pos as Vector2);wish=away.normalized() if away.length_squared()>1 else aim.orthogonal()*side
   if clearance(origin+wish*130)<60:wish=(g.FIELD.get_center()-origin).normalized();side=-side
   react()
   if dash>0:return
   if not pending.is_empty() or c.held_cast.charges.has(ID) or recover>0:pass
   elif clock>1.1:
    var choice=special_tactic(d)
    if choice=="recast":g._attack(ID,"secondary",aim,target);last.secondary=clock
    elif not choice.is_empty():schedule(choice,target+velocity*.18 if hero_id in ["nera","veyra","cantor","tidewright"] else target)
    elif ready("primary") and d<primary_range()+8:
     var travel=minf(.55,.14+d/maxf(250,float(kit.primary.get("speed",420))))
     if primary_range()<140:travel=.1
     schedule("primary",target+velocity*travel*.85)
 if not visible:return
 # Charges track only the last sampled target, not the player's live position.
 var held=c.held_cast
 if held.charges.has(ID):
  var q:Dictionary=held.charges[ID];var stats:Dictionary=held.stats_for(ID,str(q.kind));var duration=float(stats.get("hold_charge",{}).get("seconds",.8))
  q.last_seen=q.age
  if float(q.age)>=duration:held.release(ID)
  if not locked():move(delta,.25)
  return
 if not pending.is_empty():
  pending.time=float(pending.time)-delta
  if float(pending.time)<=0:
   var action=pending;pending={};issue(str(action.kind),action.point)
  if not locked():move(delta,.35)
  return
 if not locked():move(delta,1.0)
func move(delta:float,factor:float)->void:
 var c=g.adventure.combat;var direction=wish
 # Use the real hero's displacement rules for plant steps/rolling, rather than
 # bypassing a stance or an attached clamp with manual position edits.
 var speed=float(g.characters[hero_id].speed)*c.speed_factor("p:"+ID)*factor
 var displacement=direction*speed*delta
 if hero_id=="snowman":displacement=g.motion_v85.displacement(ID,hero_id,direction,speed,delta)
 g.positions[ID]=g._move_actor(g.positions[ID],displacement)
