extends RefCounted

const STEER_RANGE=520.0
const STORM_SPEED=185.0
const BREATH_TICK=.25
const STORM_TICK=.8
const CHILL_LIMIT=100.0
const CHILL_HOLD=2.25
const MIN_CHILLED_SPEED=.40
var chills:Dictionary={}
var breaths:Dictionary={}
var storms:Dictionary={}

func reset()->void:
 chills.clear()
 breaths.clear()
 storms.clear()

func cast(combat:Node,id:String,stats:Dictionary,aim:Vector2,damage:float)->void:
 var origin:Vector2=combat.owner_pos(id)
 match str(stats.style):
  "rime_spear":
   combat.launch_projectile(id,origin,aim,stats,damage,"rime_spear")
  "white_breath":
   breaths[id]={"aim":combat.point_array(aim),"reach":float(stats.range),"time":float(stats.duration),"tick":0.0,"damage":damage}
  "northwind_blizzard":
   var point:Vector2=combat.v79.destination(id,aim,STEER_RANGE)
   storms[id]={"pos":combat.point_array(point),"target":combat.point_array(point),"radius":float(stats.radius),"time":float(stats.duration),"tick":0.0,"damage":damage}

func steer(id:String,target:Vector2)->void:
 if storms.has(id) and target.is_finite():storms[id].target=[target.x,target.y]

func chill(combat:Node,key:String,id:String,amount:float)->void:
 var foe:Dictionary=combat.actor(key)
 if not bool(foe.get("alive",false)) or key.begins_with("bgbase:") or key.begins_with("bgheart:"):return
 var state:Dictionary=chills.get(key,{"amount":0.0,"hold":0.0,"freeze":0.0,"immune":0.0})
 if float(state.immune)>0:return
 state.amount=minf(CHILL_LIMIT,float(state.amount)+amount)
 state.hold=CHILL_HOLD
 if float(state.amount)>=CHILL_LIMIT:
  if combat.passive(id,"deep_winter"):
   var duration=.65 if bool(foe.get("npc",{}).get("boss",false)) else .9 if foe.has("player") else 1.45
   state.amount=0.0
   state.freeze=duration
   state.immune=duration+5.0
   combat.apply_status(key,"stun",duration,id)
  else:state.amount=CHILL_LIMIT-1.0
 chills[key]=state

func speed(key:String)->float:
 return lerpf(1.0,MIN_CHILLED_SPEED,clampf(float(chills.get(key,{}).get("amount",0.0))/CHILL_LIMIT,0,1))

func spear_hits(combat:Node,shot:Dictionary,start:Vector2,end:Vector2)->void:
 var center:Vector2=(start+end)*.5
 var radius:float=start.distance_to(end)*.5+75
 for key in combat.hostile(str(shot.owner),center,radius):
  if shot.hits.has(key):continue
  var foe:Dictionary=combat.actor(key)
  if not bool(foe.get("alive",false)) or center.distance_squared_to(foe.pos)>radius*radius:continue
  var hit_radius:float=float(shot.radius)+combat.v110.target_radius(key,float(foe.get("npc",{}).get("hit_radius",18)))
  if not combat.projectile_near(start,end,key,foe.pos,hit_radius) or not combat.path_clear(start,foe.pos):continue
  shot.hits.append(key)
  combat.damage(key,float(shot.damage),str(shot.owner),"Rime Spear",shot.credit)
  chill(combat,key,str(shot.owner),35.0)

func step(combat:Node,delta:float)->void:
 for key in chills.keys():
  var state:Dictionary=chills[key]
  state.freeze=maxf(0.0,float(state.freeze)-delta)
  state.immune=maxf(0.0,float(state.immune)-delta)
  state.hold-=delta
  if float(state.hold)<=0:state.amount=maxf(0.0,float(state.amount)-22.0*delta)
  if (float(state.amount)<=0 and float(state.immune)<=0) or not bool(combat.actor(key).get("alive",false)):chills.erase(key)
 for id in breaths.keys():
  var ray:Dictionary=breaths[id]
  ray.tick-=delta
  ray.time-=delta
  if float(ray.time)<=0 or not combat.adventure.alive(id) or combat.stunned(combat.player_key(id)):
   breaths.erase(id)
   continue
  if float(ray.tick)>0:continue
  ray.tick+=BREATH_TICK
  var origin:Vector2=combat.owner_pos(id)
  var aim:Vector2=combat.vec(ray.aim)
  for key in combat.hostile(id,origin,float(ray.reach)):
   var foe:Dictionary=combat.actor(key)
   if not bool(foe.get("alive",false)) or not combat.v56.cone(origin,aim,foe.pos,float(ray.reach),.90) or not combat.path_clear(origin,foe.pos):continue
   combat.damage(key,float(ray.damage),id,"White Breath")
   chill(combat,key,id,12.5)
 for id in storms.keys():
  var storm:Dictionary=storms[id]
  storm.time-=delta
  if float(storm.time)<=0 or not combat.adventure.alive(id):
   storms.erase(id)
   continue
  var pos:Vector2=combat.vec(storm.pos).move_toward(combat.vec(storm.target),STORM_SPEED*delta)
  storm.pos=combat.point_array(pos)
  storm.tick-=delta
  if float(storm.tick)>0:continue
  storm.tick+=STORM_TICK
  var radius:float=storm.radius
  for key in combat.hostile(id,pos,radius):
   var foe:Dictionary=combat.actor(key)
   if not bool(foe.get("alive",false)) or pos.distance_squared_to(foe.pos)>radius*radius or not combat.path_clear(pos,foe.pos):continue
   combat.damage(key,float(storm.damage),id,"Northwind Blizzard")
   chill(combat,key,id,14.0)

func snapshot()->Dictionary:
 if chills.is_empty() and breaths.is_empty() and storms.is_empty():return {}
 return {"chills":chills,"breaths":breaths,"storms":storms}

func receive(data:Dictionary)->void:
 chills=data.get("chills",{})
 breaths=data.get("breaths",{})
 storms=data.get("storms",{})

func draw_on(canvas:Node2D,camera:Vector2,combat:Node)->void:
 var cues=preload("res://scripts/combat_cues.gd")
 var t=float(Time.get_ticks_msec())*.001
 for id in storms:
  var storm:Dictionary=storms[id]
  var p:Vector2=combat.vec(storm.pos)-camera
  var radius:float=storm.radius
  if not cues.visible(canvas,p,radius+25):continue
  canvas.draw_circle(p,radius,Color(.62,.85,1,.16))
  canvas.draw_arc(p,radius,0,TAU,40,Color("#9edaff"),2)
  for i in 3:
   var a=t*1.8+i*TAU/3.0
   canvas.draw_arc(p,radius-21-i*28,a,a+1.85,17,Color(.81,.94,1,.34),2)
  for i in 24:
   var p2=p+Vector2.from_angle(i*2.397+t*(1.5+float(i%4)*.2))*(radius*(.18+.8*float((i*7)%24)/24.0))
   canvas.draw_rect(Rect2(p2,Vector2.ONE*(2+i%3)),Color(.86,.97,1,.72))
 for id in breaths:
  var ray:Dictionary=breaths[id]
  var p:Vector2=combat.owner_pos(id)-camera
  var aim:Vector2=combat.vec(ray.aim)
  var reach:float=ray.reach
  if not cues.visible(canvas,p,reach):continue
  var cone=PackedVector2Array([p])
  for i in 9:cone.append(p+aim.rotated(lerpf(-.42,.42,float(i)/8.0))*reach)
  canvas.draw_colored_polygon(cone,Color(.46,.79,1,.22))
  for i in 7:
   var d=aim.rotated(lerpf(-.38,.38,float(i)/6.0))
   var phase=fposmod(t*2+float(i)*.17,1.0)
   canvas.draw_line(p+d*reach*phase,p+d*reach*minf(1.0,phase+.21),Color(.74,.92,1,.85),3)
 for key in chills:
  var state:Dictionary=chills[key]
  var target:Dictionary=combat.actor(key)
  if not bool(target.get("alive",false)):continue
  var p:Vector2=target.pos-camera
  if not cues.visible(canvas,p,40):continue
  if float(state.freeze)>0 and combat.stunned(key):
   var ice=PackedVector2Array([p+Vector2(-21,10),p+Vector2(-23,-24),p+Vector2(-10,-48),p+Vector2(14,-44),p+Vector2(23,-19),p+Vector2(19,10)])
   canvas.draw_colored_polygon(ice,Color(.25,.66,1,.58))
   ice.append(ice[0])
   canvas.draw_polyline(ice,Color("#aaf0ff"),2)
  elif float(state.amount)>0:
   canvas.draw_arc(p+Vector2(0,9),19,-PI*.5,-PI*.5+TAU*float(state.amount)/CHILL_LIMIT,14,Color("#8ddcf6"),2)
   var percent=roundi((1.0-speed(str(key)))*100)
   canvas.draw_style_box(preload("res://scripts/event_hero_visuals375.gd").plate(),Rect2(p+Vector2(-51,-94),Vector2(102,19)))
   canvas.draw_string(ThemeDB.fallback_font,p+Vector2(-48,-80),"CHILL • −%d%%" % percent,HORIZONTAL_ALIGNMENT_CENTER,96,11,Color("#9edff2"))
