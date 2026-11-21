extends Node

var combat:Node
var frost=preload("res://scripts/finch_frost367.gd").new()
var nutcracker=preload("res://scripts/nutcracker350.gd").new()
var clamps:Dictionary={}
var immunity:Dictionary={}
var pressure:Dictionary={}
var gifts:Dictionary={}
var momentum:Dictionary={}
var last_position:Dictionary={}
var braces:Dictionary={}
var branches:Dictionary={}
var flights:Dictionary={}
var fields:Array=[]
var slides:Dictionary={}
var received_msec:=0
const RISE=.62
const FLIGHT=4.0
const LAND=.38
const AIR_TIME=RISE+FLIGHT+LAND
const BRACE_TIME=5.0
const ART=preload("res://scripts/event_effects343.gd")
const TECHNIQUES=preload("res://scripts/event_techniques369.gd")
var STYLES=TECHNIQUES.STYLES+["jaw_snap","jaw_clamp","jaw_brace","courtbow","flower_standard","dawn_garden","gift_toss","care_parcel","midnight_delivery","antler_sweep","sleigh_charge","flying_reindeer","spear_jab","parade_stance","winter_tree","rime_spear","white_breath","northwind_blizzard"]

func reset()->void:
 frost.reset()
 nutcracker.reset()
 clamps.clear();immunity.clear();pressure.clear();gifts.clear();momentum.clear();last_position.clear();braces.clear();branches.clear();flights.clear();fields.clear();slides.clear()

func allowed_action(id:String,kind:String)->bool:
 return not clamps.has(id) or kind=="secondary"

func visual_frame(id:String,sprite:String)->int:
 if sprite=="lockjaw":
  if clamps.has(id):return 4
  for f in fields:
   if str(f.owner)==id and str(f.kind)=="bite" and display_time(float(f.time))>0:return 3 if display_time(float(f.time))>.14 else 4
 if sprite=="nutcracker" and nutcracker.stance.has(id):
  for f in nutcracker.flashes:
   if str(f.get("owner",""))==id and f.get("jab",false) and display_time(float(f.time))>0:return 3
  return 4
 return -1

func clamped(id:String)->bool:
 var key:String=combat.player_key(id)
 return clamps.values().any(func(state):return state.target==key)

func following(id:String)->bool:return clamps.has(id) or slides.has(id)
func flying(id:String)->bool:return flights.has(id)
func height(time:float)->float:
 return 72.0*smoothstep(0,RISE,AIR_TIME-time)*smoothstep(0,LAND,time)
func locks_input(id:String)->bool:
 return following(id) or (flying(id) and (float(flights[id].time)>FLIGHT+LAND or float(flights[id].time)<=LAND))
func offset(id:String)->Vector2:
 if clamps.has(id):return Vector2(0,-4)
 return Vector2(0,-height(display_time(float(flights[id].time)))) if flying(id) else Vector2.ZERO
func sweep(id:String,kind:String,p:Vector2,aim:Vector2,reach:float)->void:
 field(id,kind,p,reach,.32)
 fields[-1].aim=combat.point_array(aim)
func drop(id:String,kind:String,origin:Vector2,target:Vector2,time:float,amount:float)->void:
 field(id,kind,target,27,time,amount)
 fields[-1].origin=combat.point_array(origin)
 fields[-1].total=time

func release(id:String)->bool:
 if not clamps.has(id):return false
 immunity[clamps[id].target]=2.0
 clamps.erase(id)
 return true

func incoming(id:String,amount:float,source:String="")->void:
 if amount<=0:return
 if clamps.has(id):
  clamps[id].taken+=amount
  if combat.passive(id,"jaw_pressure") and not bool(clamps[id].get("stored",false)) and clamps[id].target==combat.player_key(source):
   pressure[id]=true
   clamps[id].stored=true
  if clamps[id].taken>=clamps[id].limit:release(id)
 if braces.has(id):
  var state:Dictionary=braces[id]
  braces.erase(id)
  # Queue the counter so simultaneous counters cannot recurse into damage.
  field(id,"impact",combat.owner_pos(id),95,.03,float(state.damage))

func field(id:String,kind:String,p:Vector2,radius:float,time:float,damage:float=0)->void:
 if fields.size()>=96:fields.pop_front()
 fields.append({"owner":id,"kind":kind,"pos":combat.point_array(p),"radius":radius,"time":time,"damage":damage,"seen":[]})

func area(id:String,p:Vector2,r:float,amount:float,aim:Vector2=Vector2.ZERO,push:float=0)->void:
 for key in combat.hostile(id,p,r):
  var foe:Dictionary=combat.actor(key)
  if foe.is_empty() or not foe.alive:continue
  var offset_to:Vector2=foe.pos-p
  if offset_to.length()>r or (not aim.is_zero_approx() and offset_to.normalized().dot(aim)<.15) or not combat.path_clear(p,foe.pos):continue
  combat.damage(key,amount,id)
  if push>0:combat.knock(key,offset_to.normalized(),push)

func cast(id:String,s:Dictionary,aim:Vector2,damage:float)->bool:
 var style:=str(s.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative():return true
 var p:Vector2=combat.owner_pos(id)
 var reach:=float(s.get("range",90))
 if aim.is_zero_approx():aim=Vector2.RIGHT
 if style in TECHNIQUES.STYLES:
  TECHNIQUES.cast(self,id,s,p,aim.normalized(),damage)
  return true
 match style:
  "rime_spear","white_breath","northwind_blizzard":
   frost.cast(combat,id,s,aim.normalized(),damage)
  "spear_jab":
   if nutcracker.stance.has(id):
    aim=Vector2.from_angle(float(nutcracker.stance[id].angle))
    reach*=1.4
    damage*=1.25
   nutcracker.strike(combat,id,p,aim.normalized(),reach,damage)
  "parade_stance":
   nutcracker.stance[id]={"time":nutcracker.BRACE_TIME,"angle":aim.angle()}
   stop_dodge(id)
  "winter_tree":
   var point:Vector2=combat.v75.clip(p,aim,54)
   nutcracker.trees[id]={"pos":combat.point_array(point),"time":7.2,"pulse":0.0,"roll":.29,"light":0.0,"angle":aim.angle(),"damage":damage}
  "jaw_snap":
   sweep(id,"bite",p,aim,reach)
   area(id,p,reach,damage+(9 if pressure.erase(id) else 0),aim)
  "jaw_clamp":
   var best:=""
   var dist:=reach
   for key in combat.hostile(id,p,reach):
    var foe:Dictionary=combat.actor(key)
    if foe.is_empty() or not foe.alive or not combat.path_clear(p,foe.pos):continue
    var v:Vector2=foe.pos-p
    if v.length()<=dist and (v.length()<28 or v.normalized().dot(aim)>.55):best=key;dist=v.length()
   sweep(id,"bite",p,aim,reach)
   if best.is_empty():
    combat.v79.position_owner(id,combat.v75.clip(p,aim,reach*.55))
    return true
   var target:Dictionary=combat.actor(best)
   combat.damage(best,damage,id,"Clamp")
   if immunity.has(best) or clamps.values().any(func(c):return c.target==best) or bool(target.get("npc",{}).get("boss",false)):return true
   if not best.begins_with("e:") and not combat.adventure.points().has(best.trim_prefix("p:")):return true
   if not bool(combat.actor(best).get("alive",false)):return true
   var entry:Vector2=target.pos-aim*25
   entry=combat.v75.clip(p,entry-p,p.distance_to(entry))
   stop_dodge(id)
   combat.v79.position_owner(id,entry)
   if combat.adventure.arcade and best.begins_with("p:"):
    var game:Node=combat.adventure.game
    if game.get("net_dash") is Dictionary:game.net_dash.erase(best.substr(2))
    if best.substr(2)==game.my_id:game.dodge_time=0
   clamps[id]={"target":best,"time":6.0,"tick":0.0,"taken":0.0,"limit":combat.morrow.current_hp(id)*.4,"offset":combat.point_array(entry-target.pos)}
  "jaw_brace":
   braces[id]={"time":BRACE_TIME,"damage":damage}
  "courtbow":
   var count:=arrow_count(float(s.get("charge_power",0)))
   for i in count:
    combat.launch_projectile(id,p+aim*12,aim.rotated((i-(count-1)*.5)*.13),s,damage*(.78 if count>1 else 1.0))
   if count==4 and branches.has(id) and combat.passive(id,"stand_tall") and p.distance_to(combat.vec(branches[id].pos))<=115 and float(branches[id].guard)<=0:
    branches[id].guard=3.0
    combat.apply_status(combat.player_key(id),"guard",1.5,id,.22)
  "flower_standard":
   if combat.path_clear(p,p):branches[id]={"pos":combat.point_array(p),"time":7.0,"guard":0.0}
  "dawn_garden":
   var point:Vector2=combat.v79.destination(id,aim,reach)
   field(id,"garden",point,102,.65,damage)
   fields[-1].aim=combat.point_array(aim)
  "gift_toss":
   combat.launch_projectile(id,p+aim*12,aim,s,damage)
  "care_parcel":
   drop(id,"parcel_lob",p,combat.v79.destination(id,aim,reach),.62,.36 if int(gifts.get(id,0))>=3 else .23)
   gifts.erase(id)
  "midnight_delivery":
   var center:Vector2=combat.v79.destination(id,aim,maxf(50,reach-55))
   for i in 3:
    var spot:Vector2=center+Vector2.from_angle(aim.angle()+i*TAU/3)*52
    var delta_to:Vector2=spot-p
    drop(id,"parachute",p,combat.v75.clip(p,delta_to,delta_to.length()),1.35+i*.22,damage)
  "antler_sweep":
   var ready:=float(momentum.get(id,0))>=125
   sweep(id,"antlers",p,aim,reach)
   area(id,p,reach,damage+(8 if ready else 0),aim,72 if ready else 45)
   if ready:momentum.erase(id)
  "sleigh_charge":
   slides[id]={"left":reach,"aim":combat.point_array(aim),"damage":damage,"hits":[],"trail":0.0}
   stop_dodge(id)
  "flying_reindeer":
   flights[id]={"time":AIR_TIME,"drop":0.0,"damage":damage}
   stop_dodge(id)
 return true

func stand_tall(id:String,p:Vector2)->void:
 if not branches.has(id) or not combat.passive(id,"stand_tall"):return
 if p.distance_to(combat.vec(branches[id].pos))>115 or float(branches[id].guard)>0:return
 branches[id].guard=3.0
 combat.apply_status(combat.player_key(id),"guard",1.5,id,.22)

func recast(id:String,kind:String)->bool:
 if kind=="special" and frost.storms.has(id):
  var g:Node=combat.adventure.game
  var target:Vector2=combat.vec(combat.v79.targets[id]) if combat.v79.targets.has(id) else g.aimed_point(frost.STEER_RANGE)
  frost.steer(id,target)
  return true
 if kind=="secondary":
  if nutcracker.stance.erase(id):return true
  if release(id):return true
  if branches.has(id):
   var spot:Vector2=combat.vec(branches[id].pos)
   if combat.path_clear(spot,spot):
    combat.v79.position_owner(id,spot)
    field(id,"recall",spot,28,.30)
   return true
 if kind=="special" and braces.has(id):
  var state:Dictionary=braces[id];braces.erase(id)
  area(id,combat.owner_pos(id),95,float(state.damage))
  field(id,"counter",combat.owner_pos(id),95,.32)
  return true
 return false

func follow_owner(id:String)->bool:
 if not clamps.has(id):return false
 var q:Dictionary=clamps[id]
 var foe:Dictionary=combat.actor(q.target)
 if not combat.adventure.alive(id) or not bool(foe.get("alive",false)):release(id);return false
 var next:Vector2=foe.pos+combat.vec(q.offset)
 if not combat.path_clear(combat.owner_pos(id),next):release(id);return false
 combat.v79.position_owner(id,next)
 return true

func stop_dodge(id:String)->void:
 var game:Node=combat.adventure.game
 if combat.adventure.arcade and game.get("net_dash") is Dictionary:game.net_dash.erase(id)
 if not combat.adventure.arcade or id==str(game.my_id):game.dodge_time=0

func step_slides(delta:float)->void:
 for id in slides.keys():
  if not combat.adventure.alive(id):slides.erase(id);continue
  var q:Dictionary=slides[id]
  var p:Vector2=combat.owner_pos(id)
  var aim:Vector2=combat.vec(q.aim)
  var travel:=minf(float(q.left),410.0*delta)
  var next:Vector2=combat.v75.clip(p,aim,travel)
  combat.v79.position_owner(id,next)
  q.trail-=delta
  if q.trail<=0:
   q.trail=.075
   field(id,"trail",next,35,2.5)
  for key in combat.hostile(id,next,43):
   var foe:Dictionary=combat.actor(key)
   if not bool(foe.get("alive",false)) or q.hits.has(key) or next.distance_to(foe.pos)>43 or not combat.path_clear(next,foe.pos):continue
   q.hits.append(key);combat.damage(key,float(q.damage),id);combat.knock(key,aim,65)
  q.left-=travel
  if q.left<=0 or p.distance_to(next)<travel-.01:slides.erase(id)

func step(delta:float)->void:
 if not combat.playing():
  nutcracker.reset()
  frost.reset()
  if not clamps.is_empty() or not fields.is_empty() or not flights.is_empty() or not branches.is_empty() or not braces.is_empty() or not slides.is_empty():reset()
  return
 frost.step(combat,delta)
 nutcracker.step(combat,self,delta)
 step_slides(delta)
 for owner in combat.adventure.points():
  if not combat.adventure.alive(owner) or not combat.passive(owner,"surefooted"):continue
  var p:Vector2=combat.owner_pos(owner)
  var distance:float=p.distance_to(last_position.get(owner,p))
  last_position[owner]=p
  momentum[owner]=clampf(float(momentum.get(owner,0))+minf(distance,45)-(delta*30 if distance<.2 else 0),0,125)
 for key in immunity.keys():
  immunity[key]-=delta
  if immunity[key]<=0:immunity.erase(key)
 for id in clamps.keys():
  if not clamps.has(id):continue
  var q:Dictionary=clamps[id]
  if not follow_owner(id):continue
  q.tick+=minf(delta,q.time)
  q.time-=delta
  while q.tick>=.99999:
   q.tick-=1.0
   combat.damage(q.target,8,id,"Clamp")
  if q.time<=0:release(id)
 for collection in [braces,branches,flights]:
  for id in collection.keys():
   if not combat.adventure.alive(id):collection.erase(id);pressure.erase(id);continue
   var q:Dictionary=collection[id]
   q.time-=delta
   if collection==branches:q.guard=maxf(0,float(q.guard)-delta)
   if collection==flights:
    q.drop-=delta
    var p:Vector2=combat.owner_pos(id)
    if q.drop<=0 and q.time<=FLIGHT+LAND and q.time>LAND:
     q.drop=.24
     field(id,"escort_snow" if q.get("escort",false) else "snow",p,46,.85)
    if q.time<=0:
     if q.get("escort",false):
      TECHNIQUES.support(combat,id,p,115,20,0,1.8,1.2)
      field(id,"aid_landed",p,115,.35)
     else:
      area(id,p,115,float(q.damage),Vector2.ZERO,65)
      field(id,"landing",p,115,.35)
   if q.time<=0:collection.erase(id)
 for i in range(fields.size()-1,-1,-1):
  var f:Dictionary=fields[i]
  var id:String=f.owner
  if not combat.adventure.alive(id):fields.remove_at(i);continue
  var p:Vector2=combat.vec(f.pos)
  f.time-=delta
  if f.kind=="parcel_lob" and f.time<=0:
   fields.remove_at(i)
   field(id,"parcel",p,27,6,float(f.damage))
   continue
  if f.kind=="parachute" and f.time<=0:
   fields.remove_at(i)
   area(id,p,68,float(f.damage))
   field(id,"healing_gift",p,68,3.0)
   continue
  if f.kind in ["garden","impact"] and f.time<=0:
   fields.remove_at(i)
   area(id,p,f.radius,f.damage)
   if f.kind=="impact":field(id,"counter",p,float(f.radius),.32)
   if f.kind=="garden":
    for n in 3:
     var direction:Vector2=combat.vec(f.aim).rotated(n*TAU/3)
     field(id,"blossom",combat.v75.clip(p,direction,62),22,5)
   continue
  if f.time<=0:
   fields.remove_at(i)
   var aftermath:=TECHNIQUES.impact(self,f,p)
   if not aftermath.is_empty():field(id,aftermath,p,float(f.radius),.4)
   continue
  TECHNIQUES.pulse(combat,f,p,delta)
  if f.kind in ["parcel","blossom","snow","trail","healing_gift","escort_snow"]:
   for ally in combat.party_heroes.friendly_near(id,p,f.radius):
    if f.seen.has(ally):continue
    if f.kind=="parcel" and ally==id and combat.party_heroes.friendly_near(id,p,100000).size()>1:continue
    f.seen.append(ally)
    if f.kind in ["parcel","snow"]:combat.release_heroes.heal(id,str(ally),16 if f.kind=="parcel" else 2)
    if f.kind=="healing_gift":combat.release_heroes.heal(id,str(ally),12)
    if f.kind in ["parcel","blossom"]:combat.apply_status(combat.player_key(str(ally)),"guard",2.0,id,float(f.damage) if f.kind=="parcel" else .23)
    if f.kind=="escort_snow":combat.apply_status(combat.player_key(str(ally)),"guard",1.2,id,.23)
    if f.kind=="trail":combat.apply_status(combat.player_key(str(ally)),"event_haste",.8,id,1.2)
    if f.kind in ["parcel","blossom"]:f.time=0;break
  if f.kind=="snow":
   for key in combat.hostile(id,p,f.radius):
    var foe:Dictionary=combat.actor(key)
    if not foe.is_empty() and p.distance_to(foe.pos)<=float(f.radius):combat.apply_status(key,"slow",.6,id,.72)

func snapshot()->Dictionary:return {"frost":frost.snapshot(),"nutcracker":nutcracker.snapshot(),"clamps":clamps,"slides":slides,"flights":flights,"fields":fields,"branches":branches,"braces":braces,"gifts":gifts,"momentum":momentum,"pressure":pressure}
func receive(data:Dictionary)->void:
 frost.receive(data.get("frost",{}))
 nutcracker.receive(data.get("nutcracker",{}))
 received_msec=Time.get_ticks_msec()
 clamps=data.get("clamps",{});slides=data.get("slides",{});flights=data.get("flights",{});fields=data.get("fields",[]);branches=data.get("branches",{});braces=data.get("braces",{});gifts=data.get("gifts",{});momentum=data.get("momentum",{});pressure=data.get("pressure",{})

func display_time(time:float)->float:
 if combat.adventure.authoritative() or received_msec==0:return time
 return maxf(0,time-clampf((Time.get_ticks_msec()-received_msec)*.001,0,.10))

func draw_on(canvas:Node2D,camera:Vector2)->void:
 frost.draw_on(canvas,camera,combat)
 nutcracker.draw_on(canvas,camera,combat)
 for f in fields:
  var p:Vector2=combat.vec(f.pos)-camera
  if not preload("res://scripts/combat_cues.gd").visible(canvas,p,240):continue
  var visual:Dictionary=f.duplicate()
  visual.time=display_time(float(f.time))
  ART.effect(canvas,p,visual,combat,camera)
 for id in branches:
  ART.branch(canvas,combat.vec(branches[id].pos)-camera,float(branches[id].time))
 var local:String=str(combat.adventure.game.my_id) if combat.adventure.arcade else "solo"
 if braces.has(local):
  ART.brace(canvas,combat.owner_pos(local)-camera,float(braces[local].time))
 for id in clamps:
  preload("res://scripts/event_hero_visuals375.gd").latch(canvas,camera,combat,str(id),clamps[id],str(id)==local)
 for id in gifts:
  var p:Vector2=combat.owner_pos(id)-camera
  for n in 3:canvas.draw_rect(Rect2(p+Vector2(-9+n*7,-47),Vector2(4,4)),Color("#ffcb84") if n<int(gifts[id]) else Color("#62513e"))
 for id in momentum:
  if float(momentum[id])>=125:canvas.draw_circle(combat.owner_pos(id)-camera-Vector2(0,39),3,Color("#ffe29a"))
 for id in flights:
  var p:Vector2=combat.owner_pos(id)-camera
  var remaining:=display_time(float(flights[id].time))
  var altitude:=height(remaining)
  ART.flight(canvas,p,altitude,remaining,AIR_TIME,RISE,LAND)
  if remaining<=1:canvas.draw_arc(p,115,0,TAU,36,Color("#f5d086"),3)

func can_recast(id:String,kind:String)->bool:
 return (kind=="secondary" and (clamps.has(id) or branches.has(id) or nutcracker.stance.has(id))) or (kind=="special" and (braces.has(id) or frost.storms.has(id)))

func defence(id:String)->float:
 return 1.0-(.75 if nutcracker.stance.has(id) else 1.0)*(.85 if clamps.has(id) else 1.0)*(.65 if braces.has(id) else 1.0)

func speed_factor(key:String)->float:
 if key.begins_with("p:") and nutcracker.stance.has(key.substr(2)):return .48
 for q in clamps.values():
  if q.target==key:return .7
 return 1.15 if key.begins_with("p:") and flying(key.substr(2)) else 1.0

func arrow_count(power:float)->int:
 return clampi(1+floori(power*3.0001),1,4)
