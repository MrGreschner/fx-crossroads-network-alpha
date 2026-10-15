extends Node
## One-hit timing guard and earned counter charges; no held invulnerability.
var combat:Node
var guards:Dictionary={}
var poise:Dictionary={}
var heals:Dictionary={}
var swings:Dictionary={}
var effects:Array=[]
var clock:=0.0
const STYLES=["scissor_feint","mirror_guard","glass_verdict","patient_execution"]
func reset()->void:
 guards.clear();poise.clear();heals.clear();swings.clear();effects.clear();clock=0
func on_damage(owner:String,amount:float)->float:
 if amount<5 or float(guards.get(owner,0))<=clock:return amount
 guards.erase(owner);poise[owner]=mini(3,int(poise.get(owner,0))+1)
 effects.append({"owner":owner,"style":"parry","pos":combat.point_array(combat.owner_pos(owner)),"aim":[1,0],"time":.5,"duration":.5,"range":55.0})
 if combat.passive(owner,"second_wind") and clock>=float(heals.get(owner,0)):
  heals[owner]=clock+6
  var old:float=combat.morrow.current_hp(owner);combat.morrow.set_hp(owner,minf(combat.morrow.max_hp(owner),old+8))
  if combat.adventure.arcade:combat.adventure.game._stat(owner,"healing",combat.morrow.current_hp(owner)-old)
 return 0
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var p:Vector2=combat.owner_pos(owner);var reach:=float(stats.get("range",85))
 match style:
  "mirror_guard":guards[owner]=clock+.45
  "scissor_feint":
   swings[owner]=1-int(swings.get(owner,0))
   for key in combat.hostile(owner):
    var target:Dictionary=combat.actor(key)
    if not target.is_empty() and bool(target.alive) and combat.v56.cone(p,aim,target.pos,reach,cos(PI*.3)) and combat.path_clear(p,target.pos):combat.damage(key,amount,owner)
   effects.append({"owner":owner,"style":style,"pos":combat.point_array(p),"aim":combat.point_array(aim),"time":.25,"duration":.25,"range":reach,"side":swings[owner]})
  "glass_verdict","patient_execution":
   var charge:=int(poise.get(owner,0));poise[owner]=0
   effects.append({"owner":owner,"style":style,"pos":combat.point_array(p),"aim":combat.point_array(aim),"time":1.1,"duration":1.1,"range":reach,"damage":amount+charge*(12 if style=="patient_execution" else 10),"stage":0,"hits":[]})
 return true
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 for owner in poise.keys():
  if not combat.adventure.alive(str(owner)):poise.erase(owner);guards.erase(owner)
 for i in range(effects.size()-1,-1,-1):
  var fx:Dictionary=effects[i];fx.time=float(fx.time)-delta
  if float(fx.time)<=0:effects.remove_at(i);continue
  var style:=str(fx.style)
  if style not in ["glass_verdict","patient_execution"] or not combat.adventure.alive(str(fx.owner)):continue
  var elapsed:=float(fx.duration)-float(fx.time);var p:Vector2=combat.vec(fx.pos);var aim:Vector2=combat.vec(fx.aim)
  if style=="patient_execution":
   if elapsed>=.8 and int(fx.stage)==0:
    fx.stage=1
    for key in combat.hostile(str(fx.owner)):
     var target:Dictionary=combat.actor(key)
     if not target.is_empty() and bool(target.alive) and combat.v56.cone(p,aim,target.pos,float(fx.range),cos(PI*.38)) and combat.path_clear(p,target.pos):combat.damage(key,float(fx.damage),str(fx.owner))
  else:
   while int(fx.stage)<3 and elapsed>=.2+float(fx.stage)*.2:
    var start:Vector2=p+aim*(float(fx.stage)*float(fx.range)/3);var end:Vector2=p+aim*((float(fx.stage)+1)*float(fx.range)/3)
    combat.v78.line_hit(str(fx.owner),start,end,45,float(fx.damage),{},fx.hits);fx.stage=int(fx.stage)+1
func snapshot()->Dictionary:return {"guards":guards,"poise":poise,"effects":effects,"clock":clock}
func receive(data:Dictionary)->void:
 guards=data.get("guards",{});poise=data.get("poise",{});effects=data.get("effects",[]);clock=float(data.get("clock",clock))
func draw_on(c:Node2D,camera:Vector2)->void:
 for owner in combat.adventure.points():
  if combat.v78.hero(str(owner))!="mantis":continue
  var p:Vector2=combat.owner_pos(str(owner))-camera
  for n in 3:
   var q:=p+Vector2((n-1)*13,-46);c.draw_colored_polygon(PackedVector2Array([q+Vector2(0,-5),q+Vector2(4,0),q+Vector2(0,5),q+Vector2(-4,0)]),Color("#ffe2a0") if n<int(poise.get(owner,0)) else Color("#4e665c"))
  if float(guards.get(owner,0))>clock:c.draw_arc(p,34,0,TAU,32,Color("#c9fff0"),4,true)
 for fx in combat.draw_effect_records("mantis","effects",effects):
  var p:Vector2=combat.draw_effect_position("mantis",fx,combat.vec(fx.pos))-camera;var aim:Vector2=combat.vec(fx.aim);var ratio:=1-float(fx.time)/float(fx.duration);var r:=float(fx.range)
  match str(fx.style):
   "parry":c.draw_arc(p,r*ratio,0,TAU,24,Color(1,.9,.6,1-ratio),4,true)
   "scissor_feint":
    var angle:=aim.angle()+lerpf(-PI*.3+.25,PI*.3-.25,ratio)*(1 if int(fx.side)==0 else -1)
    combat.v90.draw_sector(c,p,aim,r,PI*.3,Color(.7,1,.8,.08*(1-ratio)))
    c.draw_arc(p,r,aim.angle()-PI*.3,aim.angle()+PI*.3,24,Color(.7,1,.8,.3*(1-ratio)),1,true)
    c.draw_arc(p,r,angle-.25,angle+.25,16,Color(.7,1,.8,1-ratio),4,true)
   "glass_verdict":
    for n in 3:
     var a:=p+aim*n*r/3;var b:=p+aim*(n+1)*r/3;var tint:=Color(1,.9,.65,.32 if n<int(fx.stage) else .12)
     c.draw_line(a,b,Color(tint,.08),90,true)
     c.draw_arc(a,45,aim.angle()+PI*.5,aim.angle()+PI*1.5,16,tint,1,true)
     c.draw_arc(b,45,aim.angle()-PI*.5,aim.angle()+PI*.5,16,tint,1,true)
     for side in [-1,1]:c.draw_line(a+aim.orthogonal()*45*side,b+aim.orthogonal()*45*side,tint,1,true)
     var q:Vector2=(a+b)*.5;var cross:=aim.orthogonal()*32
     c.draw_polyline(PackedVector2Array([q-aim*40,q+cross,q+aim*40,q-cross,q-aim*40]),Color(1,.9,.65,.8 if n<int(fx.stage) else .2),3,true)
   "patient_execution":
    c.draw_arc(p,r,aim.angle()-PI*.38,aim.angle()+PI*.38,32,Color(1,.8,.5,.35 if int(fx.stage)==0 else .95),3 if int(fx.stage)==0 else 9,true)
    c.draw_line(p,p+aim.rotated(-PI*.38)*r,Color(1,.8,.5,.4),2);c.draw_line(p,p+aim.rotated(PI*.38)*r,Color(1,.8,.5,.4),2)
