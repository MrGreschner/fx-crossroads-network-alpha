extends Node
## Converted foes are removed through the normal defeat path exactly once.
## The remaining body is a separate, damageable summon, never a live room enemy.
var combat:Node
var allies:Dictionary={}
var needles:Array=[]
var knots:Array=[]
var marks:Dictionary={}
var sparks:Array=[]
var clock:=0.0
var poison_marked:Dictionary={}
const STYLES=["pact_needle","gathering_knot","change_of_heart"]
func reset()->void:allies.clear();needles.clear();knots.clear();marks.clear();sparks.clear();poison_marked.clear();clock=0
func ally_actor(id:String)->Dictionary:
 var owner:String=id.trim_prefix("bond:")
 if not allies.has(owner):return {}
 var body:Dictionary=allies[owner]
 return {"pos":combat.vec(body.pos),"alive":float(body.hp)>0 and float(body.time)>0,"player":id}
func enemy_to_ally(owner:String,source:String)->bool:
 return source=="enemy" or combat.adventure.arcade and combat.adventure.game.mode in ["arena","battlegrounds"] and combat.adventure.game._rival(owner,source)
func hurt_ally(owner:String,amount:float,source:String="enemy")->void:
 if not combat.adventure.authoritative() or not allies.has(owner) or not enemy_to_ally(owner,source):return
 var body:Dictionary=allies[owner];body.hp=maxf(0,float(body.hp)-maxf(0,amount))
 sparks.append({"pos":body.pos,"time":.3,"radius":26,"color":"#f7b898"})
 if float(body.hp)<=0:allies.erase(owner);combat.statuses.erase("p:bond:"+owner)
func catch_ally(start:Vector2,end:Vector2,source:String,amount:float)->bool:
 for owner in allies.keys():
  if not enemy_to_ally(str(owner),source):continue
  var p:Vector2=combat.vec(allies[owner].pos)
  if Geometry2D.get_closest_point_to_segment(p,start,end).distance_to(p)<24 and combat.path_clear(start,p):hurt_ally(str(owner),amount,source);return true
 return false
func blast_allies(center:Vector2,radius:float,source:String,amount:float)->void:
 for owner in allies.keys():
  var p:Vector2=combat.vec(allies[owner].pos)
  if center.distance_to(p)<=radius and combat.path_clear(center,p):hurt_ally(str(owner),amount,source)
func convertible(key:String)->bool:
 if key.begins_with("bgunit:") and combat.adventure.arcade and combat.adventure.game.mode=="battlegrounds":return combat.adventure.game.battlegrounds.units.has(key)
 var actor:Dictionary=combat.actor(key)
 if not key.begins_with("e:") or actor.is_empty() or not bool(actor.alive):return false
 var foe:Dictionary=actor.npc
 return not bool(foe.get("boss",false)) and not str(foe.type).begins_with("training_") and float(foe.get("down_time",0))<=0
func prepare(owner:String,stats:Dictionary,aim:Vector2,point:Vector2)->bool:
 var style:String=str(stats.get("style",""))
 if style not in STYLES:return true
 if not is_finite(point.x) or not is_finite(point.y):return false
 var origin:Vector2=combat.owner_pos(owner);var reach:float=float(stats.get("range",380))
 var ground:Vector2=origin+ (point-origin).limit_length(reach)
 stats["_pact_point"]=combat.point_array(ground)
 if style!="change_of_heart":return true
 var chosen:="";var best:=INF
 for key in combat.hostile(owner):
  if not convertible(key):continue
  var p:Vector2=combat.actor(key).pos;var offset:Vector2=p-origin
  if offset.length()>reach or not combat.path_clear(origin,p):continue
  var cursor:float=point.distance_to(p)
  var along:float=offset.dot(aim.normalized());var across:float=absf(offset.cross(aim.normalized()))
  var score:float=cursor if cursor<100 else 100+along+across*4 if along>0 and across<40 else INF
  if score<best:best=score;chosen=key
 stats["_pact_target"]=chosen
 return not chosen.is_empty()
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:String=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var origin:Vector2=combat.owner_pos(owner)
 if aim.is_zero_approx():aim=Vector2.RIGHT
 aim=aim.normalized()
 match style:
  "pact_needle":
   needles.append({"owner":owner,"pos":combat.point_array(origin+aim*24),"aim":combat.point_array(aim),"distance":0.0,"damage":amount,"range":float(stats.get("range",450))})
  "gathering_knot":
   var point:Vector2=combat.vec(stats.get("_pact_point",combat.point_array(origin+aim*200)))
   if not combat.path_clear(origin,point):point=combat.chain.clip(origin,(point-origin).normalized(),origin.distance_to(point))
   knots.append({"owner":owner,"pos":combat.point_array(point),"time":.45,"damage":amount})
  "change_of_heart":turn_enemy(owner,str(stats.get("_pact_target","")))
 return true
func turn_enemy(owner:String,key:String)->void:
 if key.begins_with("bgunit:") and combat.adventure.arcade and combat.adventure.game.mode=="battlegrounds":combat.adventure.game.battlegrounds.convert(owner,key);return
 if not convertible(key):return
 var foe:Dictionary=combat.actor(key).npc
 var origin:Vector2=combat.owner_pos(owner)
 if origin.distance_to(foe.pos)>380 or not combat.path_clear(origin,foe.pos):return
 var defs:Dictionary=combat.adventure.game.enemy_defs if combat.adventure.arcade else combat.adventure.game.enemy_types
 var definition:Dictionary=defs.get(str(foe.type),{})
 var ranged:bool=combat.ranged_enemy(foe,definition)
 var body:Dictionary={"pos":combat.point_array(foe.pos),"type":str(foe.type),"sprite":str(definition.get("sprite",foe.type)),"hp":clampf(float(foe.hp),1,90),"max_hp":clampf(float(foe.hp),1,90),"time":8.0,"ranged":ranged,"attack":.25,"contacts":{},"pose":"walk1"}
 foe["converted"]=true
 combat.damage(key,float(foe.hp),owner)
 # Practice targets were rejected; a successfully removed hostile is the only valid summon.
 if combat.actor(key).is_empty():
  allies[owner]=body
  combat.statuses.erase("p:bond:"+owner)
  sparks.append({"pos":body.pos,"time":.8,"radius":60,"color":"#afefb6"})
  combat.adventure.announce("Change of Heart • ally joins for 8 seconds")
func move_body(body:Dictionary,motion:Vector2)->void:
 var point:Vector2=combat.vec(body.pos)
 for n in int(ceil(motion.length()/8.0)):
  var step:Vector2=motion.normalized()*minf(8,motion.length()-n*8)
  for shift in [step,Vector2(step.x,0),Vector2(0,step.y)]:
   if not shift.is_zero_approx() and combat.path_clear(point,point+shift) and combat.adventure.can_stand(point+shift):point+=shift;break
 body.pos=combat.point_array(point)
func poison_group(owner:String)->void:
 var live:Array=[]
 for key in marks.get(owner,{}):
  var target:Dictionary=combat.actor(str(key))
  if not target.is_empty() and target.alive:live.append(key)
 if live.size()<2:return
 for key in live:
  var token:String=owner+":"+str(key)
  if poison_marked.has(token):continue
  poison_marked[token]=true;combat.apply_status(str(key),"poison",5,owner,2)
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 for owner in marks.keys():
  for key in marks[owner].keys():
   marks[owner][key]=float(marks[owner][key])-delta
   if float(marks[owner][key])<=0 or combat.actor(str(key)).is_empty():marks[owner].erase(key);poison_marked.erase(str(owner)+":"+str(key))
 for i in range(needles.size()-1,-1,-1):
  var dart:Dictionary=needles[i];var start:Vector2=combat.vec(dart.pos);var end:Vector2=start+combat.vec(dart.aim)*420*delta
  dart.distance=float(dart.distance)+420*delta
  if not combat.path_clear(start,end) or float(dart.distance)>float(dart.range):needles.remove_at(i);continue
  var hit:="";var nearest:=INF
  for key in combat.hostile(str(dart.owner)):
   var target:Dictionary=combat.actor(key)
   if target.is_empty() or not target.alive:continue
   if Geometry2D.get_closest_point_to_segment(target.pos,start,end).distance_to(target.pos)<23 and start.distance_to(target.pos)<nearest:nearest=start.distance_to(target.pos);hit=key
  dart.pos=combat.point_array(end)
  if not hit.is_empty():
   combat.damage(hit,float(dart.damage),str(dart.owner))
   if not marks.has(str(dart.owner)):marks[str(dart.owner)]={}
   marks[str(dart.owner)][hit]=4.0
   if combat.passive(str(dart.owner),"binding_thorns"):poison_group(str(dart.owner))
   needles.remove_at(i)
 for i in range(knots.size()-1,-1,-1):
  var knot:Dictionary=knots[i];knot.time=float(knot.time)-delta
  if float(knot.time)>0:continue
  var center:Vector2=combat.vec(knot.pos);var owner:String=str(knot.owner)
  for key in marks.get(owner,{}).keys():
   var target:Dictionary=combat.actor(str(key))
   if target.is_empty() or not target.alive or center.distance_to(target.pos)>240 or not combat.path_clear(center,target.pos):continue
   sparks.append({"pos":combat.point_array(target.pos),"end":knot.pos,"time":.4,"radius":20,"color":"#b4e8bd"})
   if not bool(target.get("npc",{}).get("boss",false)):combat.knock(str(key),(center-(target.pos as Vector2)).normalized(),minf(110,center.distance_to(target.pos)))
   combat.damage(str(key),float(knot.damage),owner);combat.apply_status(str(key),"slow",2,owner,.65)
  sparks.append({"pos":knot.pos,"time":.5,"radius":65,"color":"#b4e8bd"});knots.remove_at(i)
 for owner in allies.keys():
  var body:Dictionary=allies[owner];body.time=float(body.time)-delta
  if float(body.time)<=0 or not combat.adventure.alive(str(owner)):
   sparks.append({"pos":body.pos,"time":.5,"radius":35,"color":"#afefb6"});allies.erase(owner);combat.statuses.erase("p:bond:"+str(owner));continue
  var p:Vector2=combat.vec(body.pos);var target:="";var distance:=600.0
  for key in combat.hostile(str(owner)):
   var candidate:Dictionary=combat.actor(key)
   if candidate.is_empty() or not candidate.alive or not combat.path_clear(p,candidate.pos):continue
   var d:float=p.distance_to(candidate.pos)
   if marks.get(str(owner),{}).has(key):d*=.7
   if d<distance:target=key;distance=d
  body.attack=float(body.attack)-delta
  if not combat.stunned("p:bond:"+str(owner)):
   if target.is_empty():
    var home:Vector2=combat.owner_pos(str(owner))
    if p.distance_to(home)>90:move_body(body,(home-p).normalized()*160*delta*combat.speed_factor("p:bond:"+str(owner)))
   else:
    var enemy:Dictionary=combat.actor(target);var offset:Vector2=enemy.pos-p;var reach:=250.0 if bool(body.ranged) else 52.0
    var direction:Vector2=offset.normalized()
    if bool(body.ranged) and offset.length()<145:direction=-direction
    elif offset.length()<=reach:direction=Vector2.ZERO
    move_body(body,direction*160*delta*combat.speed_factor("p:bond:"+str(owner)))
    if offset.length()<=reach and float(body.attack)<=0:
     var bonus:=0.0
     body.attack=1.0;body.pose="attack"
     if bool(body.ranged):combat.launch_projectile(str(owner),p+offset.normalized()*25,offset.normalized(),{"range":400,"speed":330,"color":"#9be1b1"},14+bonus)
     else:combat.damage(target,18+bonus,str(owner))
    else:body.pose="walk1" if int(clock*5)%2==0 else "walk2"
  # Nearby hostile melee strikes also hit this independent summon.
  for foe in combat.adventure.foes():
   var definition:Dictionary=(combat.adventure.game.enemy_defs if combat.adventure.arcade else combat.adventure.game.enemy_types).get(str(foe.type),{})
   if combat.ranged_enemy(foe,definition) or bool(foe.get("buried",false)) or combat.stunned(combat.npc_key(foe)):continue
   var uid:String=str(foe.uid)
   if p.distance_to(foe.pos)<58 and clock>=float(body.contacts.get(uid,0)) and combat.path_clear(p,foe.pos):
    body.contacts[uid]=clock+1.2;hurt_ally(str(owner),float(definition.get("damage",12)),"enemy")
    if not allies.has(owner):break
 for i in range(sparks.size()-1,-1,-1):
  sparks[i].time=float(sparks[i].time)-delta
  if float(sparks[i].time)<=0:sparks.remove_at(i)
func snapshot()->Dictionary:return {"allies":allies,"needles":needles,"knots":knots,"marks":marks,"sparks":sparks,"clock":clock}
func receive(data:Dictionary)->void:allies=data.get("allies",{});needles=data.get("needles",[]);knots=data.get("knots",[]);marks=data.get("marks",{});sparks=data.get("sparks",[]);clock=float(data.get("clock",0))
func draw_on(c:Node2D,camera:Vector2)->void:
 for owner in allies:
  var body:Dictionary=allies[owner];var p:Vector2=combat.vec(body.pos)-camera
  var texture:Texture2D=combat.adventure.game.art.get(str(body.sprite)+"_"+str(body.pose),combat.adventure.game.art.get(str(body.sprite)+"_0"))
  c.draw_ellipse_shadow(p) if combat.adventure.arcade else c.draw_circle(p+Vector2(0,15),18,Color(0,0,0,.2))
  c.draw_arc(p,26,0,TAU,32,Color("#9ce6ad"),2)
  if texture!=null:c.draw_texture_rect(texture,Rect2(p-Vector2(23,35),Vector2(46,50)),false)
  else:c.draw_circle(p,16,Color("#8ccf9a"))
  c.draw_rect(Rect2(p+Vector2(-23,-43),Vector2(46,4)),Color("#193b2c"));c.draw_rect(Rect2(p+Vector2(-23,-43),Vector2(46*float(body.hp)/float(body.max_hp),4)),Color("#a8ecb0"))
  c.draw_string(ThemeDB.fallback_font,p+Vector2(-24,-50),"ALLY "+str(int(ceil(float(body.time))))+"s",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#c7f4cf"))
 for dart in needles:
  var p:Vector2=combat.vec(dart.pos)-camera;var aim:Vector2=combat.vec(dart.aim)
  c.draw_line(p-aim*19,p+aim*7,Color("#8ce6a9"),3);c.draw_circle(p,5,Color("#eff8b6"))
 for knot in knots:
  var p:Vector2=combat.vec(knot.pos)-camera
  for sign in [-1,1]:c.draw_arc(p+Vector2(sign*11,0),20,clock*9,clock*9+PI*1.6,20,Color("#bfe7a6"),3)
  c.draw_arc(p,65,0,TAU,36,Color(.6,.9,.7,.3),2)
 for owner in marks:
  for key in marks[owner]:
   var target:Dictionary=combat.actor(str(key))
   if not target.is_empty():
    var p:Vector2=target.pos-camera+Vector2(0,-40)
    c.draw_arc(p,7,0,TAU,16,Color("#b9edb5"),2);c.draw_line(p+Vector2(-4,-5),p+Vector2(4,5),Color("#f1e9b8"),2)
 for spark in sparks:
  var p:Vector2=combat.vec(spark.pos)-camera
  if spark.has("end"):c.draw_line(p,combat.vec(spark.end)-camera,Color("#b4e8bd"),2)
  c.draw_arc(p,float(spark.radius)*(1-float(spark.time)*.5),0,TAU,32,Color(str(spark.color),minf(1,float(spark.time)*2)),2)
