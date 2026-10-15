extends Node
## Bolt's attacks: host-owned volleys, guided rocket travel and finite saw transformation.
var combat:Node
var forms:Dictionary={}
var charge:Dictionary={}
var volleys:Array=[]
var rockets:Array=[]
var flashes:Array=[]
var clock:=0.0
const STYLES=["piston_jab","missile_volley","saw_transform","saw_stomp"]
func reset()->void:forms.clear();charge.clear();volleys.clear();rockets.clear();flashes.clear();clock=0
func transformed(owner:String)->bool:return forms.has(owner) and float(forms[owner].time)>0 and combat.adventure.alive(owner)
func allowed(owner:String,kind:String)->bool:return not transformed(owner) or (kind=="primary" and float(forms[owner].age)>=.45)
func effective(owner:String,kind:String,stats:Dictionary)->Dictionary:
 if transformed(owner) and kind=="primary":return {"name":"Shock Stomp","style":"saw_stomp","damage":16,"cooldown":2.6,"radius":170}
 return stats
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 aim=aim.normalized()
 if aim.is_zero_approx():aim=Vector2.RIGHT
 var point:Vector2=combat.owner_pos(owner)
 if transformed(owner) and style!="saw_stomp":return true
 match style:
  "piston_jab":
   var hit:=false
   for key in combat.hostile(owner):
    var target:Dictionary=combat.actor(key)
    if target.is_empty() or not target.get("alive",false):continue
    var offset:Vector2=target.pos-point
    if offset.length()>100 or offset.normalized().dot(aim)<.65 or not combat.path_clear(point,target.pos):continue
    hit=true;combat.damage(key,amount,owner)
   if hit and combat.passive(owner,"overclock_reserve"):charge[owner]=mini(3,int(charge.get(owner,0))+1)
   flash(point,"jab",.25,aim,owner)
  "missile_volley":
   if volleys.size()>=12:return true
   var count:=5 if int(charge.get(owner,0))>=3 and combat.passive(owner,"overclock_reserve") else 4
   charge[owner]=0
   volleys.append({"owner":owner,"aim":combat.point_array(aim),"left":count,"total":count,"timer":0.0,"damage":amount,"targets":[]})
  "saw_transform":
   for n in range(volleys.size()-1,-1,-1):
    if str(volleys[n].owner)==owner:volleys.remove_at(n)
   forms[owner]={"time":6.0,"age":0.0,"tick":.45,"reduction":clampf(float(stats.get("reduction",.3)),0,.75),"damage":float(stats.get("contact_damage",12))+(amount-float(stats.get("damage",0)))*.15}
   # Existing primary timers should not prevent the form's only attack.
   if combat.adventure.arcade:
    var cd:Dictionary=combat.adventure.game.cooldown_at.get(owner,{});cd.primary=Time.get_ticks_msec()+450;combat.adventure.game.cooldown_at[owner]=cd
    if owner==combat.adventure.game.my_id:combat.adventure.game.dodge_time=0
   else:combat.adventure.game.cooldowns.primary=.45;combat.adventure.game.dodge_time=0;combat.adventure.game.charge_time=0
   flash(point,"transform",.45,aim)
  "saw_stomp":
   if not transformed(owner) or float(forms[owner].age)<.45:return true
   for key in combat.hostile(owner):
    var target:Dictionary=combat.actor(key)
    if target.is_empty() or not target.get("alive",false) or point.distance_to(target.pos)>170 or not combat.path_clear(point,target.pos):continue
    combat.damage(key,amount,owner);combat.apply_status(key,"stun",.4,owner);combat.apply_status(key,"slow",2.9,owner,.5)
   flash(point,"stomp",.55,aim)
 return true
func flash(point:Vector2,style:String,duration:float,aim:Vector2=Vector2.RIGHT,owner:String="")->void:
 if flashes.size()<64:flashes.append({"owner":owner,"pos":combat.point_array(point),"style":style,"time":duration,"total":duration,"aim":combat.point_array(aim)})
func target_for(owner:String,point:Vector2,exclude:Array)->String:
 var key:="";var distance:=720.0
 for candidate in combat.hostile(owner):
  if candidate in exclude:continue
  var target:Dictionary=combat.actor(candidate)
  if target.is_empty() or not target.get("alive",false) or not combat.path_clear(point,target.pos):continue
  var d:float=point.distance_to(target.pos)
  if d<distance:distance=d;key=candidate
 return key
func launch(owner:String,origin:Vector2,aim:Vector2,damage:float,focus:String="")->void:
 if rockets.size()>=64:return
 rockets.append({"owner":owner,"pos":combat.point_array(origin),"aim":combat.point_array(aim.normalized()),"focus":focus,"age":0.0,"damage":damage})
func impact(shot:Dictionary,point:Vector2,direct:String)->void:
 var owner:=str(shot.owner)
 for key in combat.hostile(owner):
  var target:Dictionary=combat.actor(key)
  if target.is_empty() or not target.get("alive",false):continue
  if key==direct:combat.damage(key,float(shot.damage),owner)
  elif point.distance_to(target.pos)<58 and combat.path_clear(point,target.pos):combat.damage(key,6,owner)
 flash(point,"blast",.4)
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 for owner in forms.keys():
  if not combat.adventure.alive(owner):forms.erase(owner);charge.erase(owner);continue
  var form:Dictionary=forms[owner];form.time-=delta;form.age+=delta;form.tick-=delta
  if float(form.time)<=0:forms.erase(owner);continue
  if float(form.age)<.45 or combat.stunned(combat.player_key(owner)):continue
  if float(form.tick)<=0:
   form.tick=.3
   var point:Vector2=combat.owner_pos(owner)
   for key in combat.hostile(owner):
    var target:Dictionary=combat.actor(key)
    if not target.is_empty() and target.get("alive",false) and point.distance_to(target.pos)<=78+float(target.get("npc",{}).get("hit_radius",16)) and combat.path_clear(point,target.pos):combat.damage(key,float(form.damage),owner)
 for owner in charge.keys():
  if not combat.adventure.alive(owner):charge.erase(owner)
 for i in range(volleys.size()-1,-1,-1):
  var volley:Dictionary=volleys[i];var owner:=str(volley.owner)
  if not combat.adventure.alive(owner):volleys.remove_at(i);continue
  volley.timer-=delta
  if float(volley.timer)<=0:
   var point:Vector2=combat.owner_pos(owner);var focus:=target_for(owner,point,volley.targets)
   if focus.is_empty():focus=target_for(owner,point,[])
   if not focus.is_empty():volley.targets.append(focus)
   var aim:Vector2=combat.vec(volley.aim).rotated((int(volley.total)-int(volley.left)-(int(volley.total)-1)*.5)*.18)
   launch(owner,point+aim*26,aim,float(volley.damage),focus);volley.left-=1;volley.timer=.16
  if int(volley.left)<=0:volleys.remove_at(i)
 for i in range(rockets.size()-1,-1,-1):
  var shot:Dictionary=rockets[i];var start:Vector2=combat.vec(shot.pos);var aim:Vector2=combat.vec(shot.aim);shot.age+=delta
  if float(shot.age)>.2:
   var target:Dictionary=combat.actor(str(shot.focus))
   if target.is_empty() or not target.get("alive",false):shot.focus=target_for(str(shot.owner),start,[]);target=combat.actor(str(shot.focus))
   if not target.is_empty():aim=Vector2.from_angle(rotate_toward(aim.angle(),(target.pos-start).angle(),delta*3.0))
  var end:Vector2=start+aim*360*delta;shot.aim=combat.point_array(aim)
  if not combat.path_clear(start,end):impact(shot,combat.chain.clip(start,aim,start.distance_to(end)),"");rockets.remove_at(i);continue
  var direct:="";var closest:=INF
  for key in combat.hostile(str(shot.owner)):
   var target:Dictionary=combat.actor(key)
   if target.is_empty() or not target.get("alive",false):continue
   var radius:=float(target.get("npc",{}).get("hit_radius",18))+8
   var near:Vector2=Geometry2D.get_closest_point_to_segment(target.pos,start,end)
   if near.distance_to(target.pos)<radius and start.distance_to(near)<closest:closest=start.distance_to(near);direct=key
  if not direct.is_empty():impact(shot,start+aim*closest,direct);rockets.remove_at(i);continue
  shot.pos=combat.point_array(end)
  if float(shot.age)>2.3:impact(shot,end,"");rockets.remove_at(i)
 for i in range(flashes.size()-1,-1,-1):
  flashes[i].time-=delta
  if float(flashes[i].time)<=0:flashes.remove_at(i)
func snapshot()->Dictionary:return {"forms":forms,"charge":charge,"volleys":volleys,"rockets":rockets,"flashes":flashes,"clock":clock}
func receive(data:Dictionary)->void:forms=data.get("forms",{});charge=data.get("charge",{});volleys=data.get("volleys",[]);rockets=data.get("rockets",[]);flashes=data.get("flashes",[]);clock=float(data.get("clock",clock))
func draw_on(canvas:Node2D,camera:Vector2)->void:
 for shot in rockets:
  var point:Vector2=combat.vec(shot.pos)-camera;var aim:Vector2=combat.vec(shot.aim);var side:=aim.rotated(PI*.5)
  canvas.draw_colored_polygon(PackedVector2Array([point+aim*15,point-aim*10+side*6,point-aim*7,point-aim*10-side*6]),Color("#c8dcdb"))
  canvas.draw_line(point-aim*6,point+aim*6,Color("#526a72"),4,true)
  for n in 4:canvas.draw_circle(point-aim*(14+n*7),4-n*.7,Color(1,.65,.25,.65-n*.12))
 for owner in forms:
  if not transformed(owner):continue
  var form:Dictionary=forms[owner];var point:Vector2=combat.owner_pos(owner)-camera;var radius:=lerpf(25,78,clampf(float(form.age)/.45,0,1));var angle:=clock*18
  canvas.draw_circle(point+Vector2(0,14),radius,Color(0,0,0,.25))
  for n in 18:
   var a:=angle+TAU*n/18;var p:=Vector2.from_angle(a);var q:=Vector2.from_angle(a+.17)
   canvas.draw_colored_polygon(PackedVector2Array([point+p*(radius-9),point+p*(radius+3),point+q*(radius-9)]),Color("#d4e6df"))
  canvas.draw_circle(point,radius-8,Color("#708f96"));canvas.draw_arc(point,radius-17,0,TAU,48,Color("#b1c4c1"),3,true)
  for n in 6:
   var spoke:=Vector2.from_angle(angle+TAU*n/6)
   canvas.draw_line(point+spoke*24,point+spoke*(radius-22),Color("#3c626e"),5,true)
  canvas.draw_circle(point,23,Color("#33454e"));canvas.draw_circle(point,12,Color("#a4eef0"))
  canvas.draw_arc(point,radius+7,angle,angle+PI*1.2,36,Color(.65,.94,.98,.25),3,true)
  if str(owner)==("solo" if not combat.adventure.arcade else combat.adventure.game.my_id):canvas.draw_string(ThemeDB.fallback_font,point+Vector2(-79,-radius-20),"SAW "+str(snappedf(float(form.time),.1))+"s • PRIMARY: STOMP",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#e4d08d"))
 for flash in combat.draw_effect_records("robot","flashes",flashes):
  var point:Vector2=combat.draw_effect_position("robot",flash,combat.vec(flash.pos))-camera;var t:=1-float(flash.time)/float(flash.total);var tint:=Color(.65,.92,1,1-t)
  match str(flash.style):
   "jab":
    var aim:Vector2=combat.vec(flash.aim);var side:=aim.rotated(PI*.5);var end:=point+aim*(35+sin(t*PI)*65)
    canvas.draw_line(point+aim*15,end,Color("#849b9b"),15,true);canvas.draw_line(end-side*13,end+side*13,Color("#e6d58b"),9,true);canvas.draw_line(end,end+aim*12,tint,3,true)
   "stomp":
    canvas.draw_arc(point,170*t,0,TAU,48,tint,8*(1-t)+1,true)
    for n in 8:canvas.draw_line(point+Vector2.from_angle(TAU*n/8)*45,point+Vector2.from_angle(TAU*n/8+.1)*170*t,tint,2,true)
   "blast":canvas.draw_circle(point,58*t,Color(1,.6,.2,(1-t)*.3));canvas.draw_arc(point,58*t,0,TAU,24,Color(1,.8,.4,1-t),3,true)
   "kill_charge":canvas.draw_string(ThemeDB.fallback_font,point+Vector2(-22,-92-15*t),"+1s",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color(.6,1,.8,1-t))
   "transform":canvas.draw_arc(point,85,0,TAU,32,tint,4,true)
 for owner in charge:
  if transformed(str(owner)) or not combat.adventure.alive(str(owner)):continue
  var point:Vector2=combat.owner_pos(str(owner))-camera
  for n in 3:canvas.draw_circle(point+Vector2(-10+n*10,37),3,Color("#e5d084") if n<int(charge[owner]) else Color("#526873"))

func reduction(owner:String)->float:return float(forms[owner].get("reduction",.3)) if transformed(owner) else 0.0
func on_kill(owner:String)->void:
 if not combat.adventure.authoritative() or not transformed(owner):return
 forms[owner].time=float(forms[owner].time)+1.0
 flash(combat.owner_pos(owner),"kill_charge",.5)
