extends Node
## Scatter rays stop at first contact; Ambush beams deliberately pierce walls and foes.
var combat:Node
var rays:Array=[]
var relays:Dictionary={}
var ambushes:Array=[]
var marks:Dictionary={}
var clock:=0.0
const STYLES=["scatterlight","corner_lens","agent_ambush"]
func reset()->void:rays.clear();relays.clear();ambushes.clear();marks.clear();clock=0
func select_target(owner:String,point:Vector2,aim:Vector2,reach:float=650)->String:
 if not is_finite(point.x) or not is_finite(point.y):return ""
 var origin:Vector2=combat.owner_pos(owner);var direct:="";var assisted:="";var closest:=120.0;var best:=INF
 for key in combat.hostile(owner):
  var target:Dictionary=combat.actor(key)
  if target.is_empty() or not target.alive or origin.distance_to(target.pos)>reach:continue
  var distance:float=point.distance_to(target.pos)
  if distance<closest:closest=distance;direct=key
  var offset:Vector2=target.pos-origin
  var along:float=offset.dot(aim.normalized());var across:float=absf(offset.cross(aim.normalized()))
  if along>0 and across<maxf(35,along*.12) and across*5+along<best:best=across*5+along;assisted=key
 return direct if not direct.is_empty() else assisted
func prepare(owner:String,stats:Dictionary,aim:Vector2,point:Vector2)->bool:
 var style:String=str(stats.get("style",""))
 if style not in STYLES:return true
 if not is_finite(point.x) or not is_finite(point.y):return false
 stats["_cast_target"]=combat.point_array(point)
 if style=="agent_ambush":
  stats["_agent_target"]=select_target(owner,point,aim,float(stats.get("range",650)))
  return not str(stats["_agent_target"]).is_empty()
 return true
func circle_entry(origin:Vector2,aim:Vector2,center:Vector2,radius:float)->float:
 var offset:Vector2=center-origin;var along:float=offset.dot(aim);var across_sq:float=offset.length_squared()-along*along
 if across_sq>radius*radius or along+radius<0:return INF
 return maxf(0,along-sqrt(maxf(0,radius*radius-across_sq)))
func trace(owner:String,origin:Vector2,aim:Vector2,reach:float)->Dictionary:
 var end:Vector2=combat.chain.clip(origin,aim,reach);var nearest:float=origin.distance_to(end);var hit:=""
 for key in combat.hostile(owner):
  var target:Dictionary=combat.actor(key)
  if target.is_empty() or not target.alive:continue
  var radius:float=maxf(18,float(target.get("npc",{}).get("hit_radius",18)))
  var distance:float=circle_entry(origin,aim,target.pos,radius)
  if distance<nearest:nearest=distance;hit=key
 return {"pos":origin+aim*nearest,"target":hit,"distance":nearest}
func add_ray(start:Vector2,end:Vector2,wide:bool=false)->void:
 if rays.size()<160:rays.append({"start":combat.point_array(start),"end":combat.point_array(end),"time":.4 if wide else .18,"wide":wide})
func lens_focus(owner:String,point:Vector2)->Vector2:
 var nearest:=360.0;var focus:=Vector2.INF
 for key in combat.hostile(owner):
  var target:Dictionary=combat.actor(key)
  if not target.is_empty() and target.alive and point.distance_to(target.pos)<nearest and combat.path_clear(point,target.pos):nearest=point.distance_to(target.pos);focus=target.pos
 return focus
func shotgun(owner:String,origin:Vector2,aim:Vector2,stats:Dictionary,amount:float)->void:
 var count:int=7;var hits:Dictionary={};var tagged:Array=[]
 # Plan all rays before applying damage: killing the front target cannot make later rays pierce it.
 for n in count:
  var direction:Vector2=aim.rotated(deg_to_rad(-18+n*6));var hit:Dictionary=trace(owner,origin,direction,float(stats.get("range",420)));var damage:float=amount/count
  var relay:Dictionary=relays.get(owner,{})
  if not relay.is_empty() and float(relay.age)>=.35:
   var lens_point:Vector2=combat.vec(relay.pos);var distance:float=circle_entry(origin,direction,lens_point,32)
   if distance<float(hit.distance) and combat.path_clear(origin,lens_point):
    add_ray(origin+aim*22 if origin.distance_to(lens_point)>22 else origin,lens_point)
    var focus:Vector2=lens_focus(owner,lens_point)
    if focus==Vector2.INF:continue
    direction=(focus-lens_point).normalized();origin_for_bounce(owner,lens_point,direction,maxf(80,float(stats.get("range",420))-distance),damage*.8,hits,tagged)
    continue
  add_ray(origin+aim*22 if float(hit.distance)>22 else origin,hit.pos)
  if not str(hit.target).is_empty():hits[hit.target]=float(hits.get(hit.target,0))+damage
 for key in hits:
  combat.damage(str(key),float(hits[key]),owner)
  if tagged.has(key) and combat.passive(owner,"crossfire_protocol") and not combat.actor(str(key)).is_empty() and combat.actor(str(key)).alive:
   if not marks.has(owner):marks[owner]={}
   marks[owner][key]=3.0
func origin_for_bounce(owner:String,origin:Vector2,aim:Vector2,reach:float,amount:float,hits:Dictionary,tagged:Array)->void:
 var hit:Dictionary=trace(owner,origin,aim,reach);add_ray(origin,hit.pos)
 if not str(hit.target).is_empty():hits[hit.target]=float(hits.get(hit.target,0))+amount;tagged.append(hit.target)
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:String=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 aim=aim.normalized()
 if aim.is_zero_approx():aim=Vector2.RIGHT
 var origin:Vector2=combat.owner_pos(owner)
 match style:
  "scatterlight":shotgun(owner,origin,aim,stats,amount)
  "corner_lens":
   var requested:Vector2=combat.vec(stats.get("_cast_target",combat.point_array(origin+aim*260)))
   var point:Vector2=combat.chain.clip(origin,aim,minf(260,origin.distance_to(requested)))
   relays[owner]={"pos":combat.point_array(point),"start":combat.point_array(origin),"age":0.0,"time":5.35}
  "agent_ambush":
   var key:String=str(stats.get("_agent_target",select_target(owner,combat.vec(stats.get("_cast_target",combat.point_array(origin+aim*400))),aim)))
   var target:Dictionary=combat.actor(key)
   if target.is_empty() or not target.alive or origin.distance_to(target.pos)>float(stats.get("range",650)) or ambushes.size()>=12:return true
   var back:Vector2=(target.pos-origin).normalized()
   if back.is_zero_approx():back=aim
   var spots:Array=[]
   for angle in [-60,0,60]:spots.append(combat.point_array(target.pos+back.rotated(deg_to_rad(angle))*180))
   ambushes.append({"owner":owner,"target":key,"target_pos":combat.point_array(target.pos),"spots":spots,"age":0.0,"damage":amount/3,"fired":false})
 return true
func fire_ambush(entry:Dictionary)->void:
 var owner:String=str(entry.owner);var target:Dictionary=combat.actor(str(entry.target));var center:Vector2=target.get("pos",combat.vec(entry.target_pos))
 entry.target_pos=combat.point_array(center);entry["ends"]=[]
 for spot in entry.spots:
  var start:Vector2=combat.vec(spot);var aim:Vector2=(center-start).normalized()
  if aim.is_zero_approx():aim=Vector2.LEFT
  var end:Vector2=start+aim*1000;entry.ends.append(combat.point_array(end));add_ray(start,end,true)
  var targets:Array=[]
  for key in combat.hostile(owner):
   var candidate:Dictionary=combat.actor(key)
   if candidate.is_empty() or not candidate.alive:continue
   if Geometry2D.get_closest_point_to_segment(candidate.pos,start,end).distance_to(candidate.pos)<=14+float(candidate.get("npc",{}).get("hit_radius",18)):targets.append(key)
  for key in targets:
   var bonus:=5.0 if float(marks.get(owner,{}).get(key,0))>0 and combat.passive(owner,"crossfire_protocol") else 0.0
   combat.damage(str(key),float(entry.damage)+bonus,owner)
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 for n in range(rays.size()-1,-1,-1):
  rays[n].time-=delta
  if float(rays[n].time)<=0:rays.remove_at(n)
 for owner in relays.keys():
  relays[owner].age+=delta;relays[owner].time-=delta
  if float(relays[owner].time)<=0 or not combat.adventure.alive(str(owner)):relays.erase(owner)
 for owner in marks.keys():
  for key in (marks[owner] as Dictionary).keys():
   marks[owner][key]=float(marks[owner][key])-delta
   var target:Dictionary=combat.actor(str(key))
   if float(marks[owner][key])<=0 or target.is_empty() or not target.alive:marks[owner].erase(key)
  if (marks[owner] as Dictionary).is_empty():marks.erase(owner)
 for n in range(ambushes.size()-1,-1,-1):
  var entry:Dictionary=ambushes[n];entry.age+=delta
  if not combat.adventure.alive(str(entry.owner)):ambushes.remove_at(n);continue
  if float(entry.age)>=1.6 and not entry.fired:entry.fired=true;fire_ambush(entry)
  if float(entry.age)>=2:ambushes.remove_at(n)
func snapshot()->Dictionary:return {"rays":rays,"relays":relays,"ambushes":ambushes,"marks":marks,"clock":clock}
func receive(data:Dictionary)->void:rays=data.get("rays",[]);relays=data.get("relays",{});ambushes=data.get("ambushes",[]);marks=data.get("marks",{});clock=float(data.get("clock",clock))
func draw_on(c:Node2D,camera:Vector2)->void:
 for ray in rays:
  var start:Vector2=combat.vec(ray.start)-camera;var end:Vector2=combat.vec(ray.end)-camera;var fade:float=clampf(float(ray.time)/(.4 if ray.wide else .18),0,1)
  c.draw_line(start,end,Color(1,.1,.12,fade*.15),16 if ray.wide else 6,true)
  c.draw_line(start,end,Color(1,.18,.22,fade),7 if ray.wide else 1.7,true)
  if ray.wide:c.draw_line(start,end,Color(1,.84,.8,fade),2,true)
 for owner in relays:
  var relay:Dictionary=relays[owner];var point:Vector2=combat.vec(relay.start).lerp(combat.vec(relay.pos),clampf(float(relay.age)/.35,0,1))-camera
  c.draw_circle(point,32,Color(.7,.07,.15,.1));c.draw_arc(point,32,clock*2,clock*2+PI*1.5,24,Color(1,.22,.28,.6),2,true)
  c.draw_colored_polygon(PackedVector2Array([point+Vector2(-12,0),point+Vector2(0,-15),point+Vector2(12,0),point+Vector2(0,15)]),Color("#658c9d"));c.draw_circle(point,5,Color("#ff696b"))
 for entry in ambushes:
  var age:float=float(entry.age)
  for spot in entry.spots:
   var point:Vector2=combat.vec(spot)-camera
   if age<.6:
    var bright:bool=fmod(age,.3)<.16
    c.draw_circle(point,27,Color(1,.12,.2,.15 if bright else .025));c.draw_arc(point,27,0,TAU,24,Color(1,.22,.28,.95 if bright else .2),3,true)
   else:
    var image:Texture2D=combat.adventure.game.art.get("agent_attack" if entry.fired else "agent_idle")
    if image!=null:c.draw_texture_rect(image,Rect2(point-Vector2(28,42),Vector2(56,64)),false,Color(1,.78,.8,clampf((2-age)/.35,0,1)))
    var progress:float=clampf((age-.6),0,1)
    c.draw_arc(point+Vector2(0,-14),33,-PI*.5,-PI*.5+TAU*progress,32,Color(1,.2,.3,.65),3,true)
    if not entry.fired:
     var focus:Vector2=combat.actor(str(entry.target)).get("pos",combat.vec(entry.target_pos))-camera
     c.draw_line(point,focus,Color(1,.16,.2,.15),1,true);c.draw_circle(point+Vector2(15,-16),4+progress*6,Color(1,.25,.3,.6))
 for owner in marks:
  for key in marks[owner]:
   var target:Dictionary=combat.actor(str(key))
   if not target.is_empty():c.draw_arc(target.pos-camera+Vector2(0,-73),8,clock*3,clock*3+PI*1.6,16,Color("#ff7c7c"),2,true)
 # Show which foe aim-assist will choose before the player spends the special.
 var game:Node=combat.adventure.game;var owner:String=str(game.my_id) if combat.adventure.arcade else "solo"
 var hero_id:String=str(game.hero_ids.get(owner,"")) if combat.adventure.arcade else str(game.selected_character)
 var level:int=int(game.levels.get(owner,1)) if combat.adventure.arcade else int(game.level)
 if hero_id=="agent" and level>=6 and combat.adventure.alive(owner):
  var aim:Vector2=(game.mobile.aim if game.mobile.enabled else game.last_aim) if combat.adventure.arcade else game.aim_direction()
  var point:Vector2=combat.owner_pos(owner)+aim*650 if game.mobile.enabled else game.media_mouse_world()
  var key:String=select_target(owner,point,aim)
  var target:Dictionary=combat.actor(key)
  if not target.is_empty():c.draw_arc(target.pos-camera,36,clock*2,clock*2+PI*1.7,24,Color(1,.28,.3,.6),2,true)
