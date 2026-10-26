extends Node
var combat:Node
var trams:Array=[]
const STYLES=["corkscrew_key","latchline","spectral_tram"]
func reset()->void:trams.clear()
func cast(owner:String,stats:Dictionary,aim:Vector2,damage:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var origin:Vector2=combat.owner_pos(owner)
 if style=="spectral_tram":
  if trams.size()<12:trams.append({"owner":owner,"pos":combat.point_array(origin),"aim":combat.point_array(aim.normalized()),"windup":.75,"distance":0.0,"range":float(stats.get("range",650)),"damage":damage,"hits":[]})
 else:
  var options:Dictionary=stats.duplicate(true)
  if style=="corkscrew_key":options["pierce"]=3 if combat.passive(owner,"master_key") else 2
  combat.launch_projectile(owner,origin+aim.normalized()*26,aim,options,damage,style)
 return true
func step(delta:float)->void:
 for i in range(trams.size()-1,-1,-1):
  var tram:Dictionary=trams[i]
  if not combat.adventure.alive(str(tram.owner)):trams.remove_at(i);continue
  if float(tram.windup)>0:tram.windup-=delta;continue
  var origin:Vector2=combat.vec(tram.pos);var direction:Vector2=combat.vec(tram.aim)
  var distance:float=minf(420*delta,float(tram.range)-float(tram.distance));var end:=origin
  for n in maxi(1,int(ceil(distance/8))):
   var next:=end+direction*distance/float(maxi(1,int(ceil(distance/8))))
   var side:=Vector2(-direction.y,direction.x)*40
   if not combat.path_clear(end,next) or not combat.path_clear(end+side,next+side) or not combat.path_clear(end-side,next-side):break
   end=next
  if combat.v56.catch_travelling(origin,end,str(tram.owner),float(tram.damage),"#8ecac2",{"stolen_visual":"tram","radius":40,"speed":420}):trams.remove_at(i);continue
  for key in combat.hostile(str(tram.owner)):
   if (tram.hits as Array).has(key):continue
   var target:Dictionary=combat.actor(key)
   if not target.is_empty() and Geometry2D.get_closest_point_to_segment(target.pos,origin,end).distance_to(target.pos)<66 and combat.path_clear(origin,target.pos):
    tram.hits.append(key);combat.damage(key,float(tram.damage),str(tram.owner));combat.knock(key,direction,75);combat.apply_status(key,"stun",.75,str(tram.owner))
  tram.pos=combat.point_array(end);tram.distance+=origin.distance_to(end)
  if end.distance_to(origin)<distance*.9 or float(tram.distance)>=float(tram.range):trams.remove_at(i)
func snapshot()->Dictionary:return {"trams":trams}
func receive(data:Dictionary)->void:trams=data.get("trams",[])
func draw_on(canvas:Node2D,camera:Vector2)->void:
 for tram in trams:
  var origin:Vector2=combat.vec(tram.pos)-camera;var direction:Vector2=combat.vec(tram.aim);var side:=Vector2(-direction.y,direction.x)
  if float(tram.windup)>0:
   for offset in [-36,36]:canvas.draw_line(origin+side*offset,origin+side*offset+direction*float(tram.range),Color(.3,.85,.85,.25),2,true)
   continue
  preload("res://scripts/combat_art215.gd").tram(canvas,origin,direction)
  for n in 4:canvas.draw_circle(origin-direction*(75+n*17),7-n,Color(.55,.86,.81,.16))

 # Hook chains and spinning key teeth use the shared replicated projectile state.
 for shot in combat.projectiles:
  if str(shot.style) not in ["latchline","corkscrew_key"]:continue
  var point:Vector2=combat.vec(shot.pos)-camera
  if str(shot.style)=="latchline":
   canvas.draw_line(combat.owner_pos(str(shot.owner))-camera,point,Color(.8,.7,.5,.6),2,true);canvas.draw_arc(point,9,0,PI*1.5,12,Color("#f6d197"),3,true)
  else:
   var direction:=Vector2.from_angle(float(shot.distance)*.035)
   canvas.draw_line(point-direction*13,point+direction*13,Color("#ffd88b"),4,true);canvas.draw_circle(point-direction*12,5,Color("#d4f4ce"));canvas.draw_line(point+direction*8,point+direction*8+direction.rotated(PI*.5)*7,Color("#ffe6a0"),3,true)
