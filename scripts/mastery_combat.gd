extends Node
## Authored final mastery attacks: bounded effects, host-only hits, guest visuals.
var combat:Node
var effects:Array=[]
var art_cache:Dictionary={}
const STYLES=["master_fan","master_lance","master_sigils","master_fountain","master_pincer","master_chain"]
func reset()->void:effects.clear()
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 if effects.size()>=32:return true
 var origin:Vector2=combat.owner_pos(owner);var reach:=float(stats.get("range",250));var center:=origin+aim.normalized()*reach
 if not combat.path_clear(origin,center):
  for n in range(10,0,-1):
   center=origin+aim.normalized()*reach*n/10.0
   if combat.path_clear(origin,center):break
  if not combat.path_clear(origin,center):center=origin
 var entry:Dictionary={"owner":owner,"style":style,"origin":combat.point_array(origin),"center":combat.point_array(center),"aim":combat.point_array(aim.normalized()),"age":0.0,"time":float(stats.get("duration",1.8)),"damage":amount,"stats":stats.duplicate(true),"hits":{},"done":{},"tick":0.0,"targets":[]}
 if style=="master_pincer":entry.stats.range=origin.distance_to(center)
 if style=="master_fountain":entry.time=float(stats.get("duration",3))
 if style=="master_chain":
  var cursor:=origin;var remaining:Array=combat.hostile(owner)
  for n in clampi(int(stats.get("count",3)),1,5):
   var best:="";var distance:=reach
   for key in remaining:
    var target:Dictionary=combat.actor(key)
    if not target.is_empty() and target.alive and cursor.distance_to(target.pos)<distance and combat.path_clear(cursor,target.pos):best=key;distance=cursor.distance_to(target.pos)
   if best.is_empty():break
   entry.targets.append(best);remaining.erase(best);cursor=combat.actor(best).pos
 effects.append(entry)
 return true
func sigil_point(entry:Dictionary,index:int)->Vector2:
 var count:=clampi(int(entry.stats.get("count",3)),1,5)
 if count==1:return combat.vec(entry.center)
 return combat.vec(entry.center)+Vector2.from_angle(combat.vec(entry.aim).angle()+index*TAU/count)*float(entry.stats.get("spacing",65))
func pincer_point(entry:Dictionary,side:int,age:float)->Vector2:
 var origin:Vector2=combat.vec(entry.origin);var aim:Vector2=combat.vec(entry.aim);var t:=clampf(age/.8,0,1)
 if age<=.8:return origin+aim*(24+(float(entry.stats.get("range",300))-24)*t)+aim.orthogonal()*side*sin(t*PI)*float(entry.stats.get("width",85))
 t=clampf((age-.8)/.8,0,1)
 return (origin+aim*float(entry.stats.get("range",300))).lerp(combat.owner_pos(str(entry.owner)),t)+aim.orthogonal()*side*sin(t*PI)*float(entry.stats.get("width",85))
func hit_status(key:String,stats:Dictionary,owner:String)->void:
 combat.apply_hit_status(key,stats,owner)
 if float(stats.get("slow_duration",0))>0:combat.apply_status(key,"slow",float(stats.slow_duration),owner,float(stats.get("slow",.7)))
func heal(owner:String,ally:String,amount:float)->void:
 if amount<=0:return
 if combat.adventure.arcade:combat.adventure.game._heal(owner,ally,int(amount))
 else:combat.adventure.game.health=minf(combat.adventure.game.max_health(),combat.adventure.game.health+amount)
func targets(owner:String)->Array[Dictionary]:
 var result:Array[Dictionary]=[]
 for foe in combat.adventure.foes():
  if float(foe.hp)>0 and not bool(foe.get("buried",false)):result.append({"key":combat.npc_key(foe),"pos":foe.pos,"alive":true})
 for key in combat.hostile(owner):
  if key.begins_with("e:"):continue
  var actor:Dictionary=combat.actor(key)
  if not actor.is_empty() and actor.alive:result.append({"key":key,"pos":actor.pos,"alive":true})
 return result
func area(entry:Dictionary,center:Vector2,radius:float,damage:float)->void:
 for target in targets(str(entry.owner)):
  var key:String=target.key
  if target.is_empty() or not target.alive or center.distance_squared_to(target.pos)>radius*radius or not combat.path_clear(center,target.pos):continue
  hit_status(key,entry.stats,str(entry.owner));combat.damage(key,damage,str(entry.owner))
func step(delta:float)->void:
 for i in range(effects.size()-1,-1,-1):
  var e:Dictionary=effects[i];var owner:=str(e.owner)
  if not combat.adventure.alive(owner):effects.remove_at(i);continue
  var old:=float(e.age);e.age=old+maxf(0,delta)
  var age:=float(e.age);var origin:Vector2=combat.vec(e.origin);var aim:Vector2=combat.vec(e.aim);var stats:Dictionary=e.stats
  match str(e.style):
   "master_fan":
    var count:=clampi(int(stats.get("count",3)),1,5)
    for n in count:
     if age<float(stats.get("charge",.2))+n*.16 or e.done.has(n):continue
     e.done[n]=true
     var direction:Vector2=aim.rotated((n-(count-1)*.5)*.35)
     for target in targets(owner):
      var key:String=target.key
      if target.is_empty() or not target.alive or e.hits.has(key):continue
      var offset:Vector2=target.pos-origin
      if offset.length()<=float(stats.get("range",155)) and offset.normalized().dot(direction)>.8 and combat.path_clear(origin,target.pos):
       e.hits[key]=true;hit_status(key,stats,owner);combat.damage(key,float(e.damage),owner)
   "master_lance":
    if age>=float(stats.get("charge",.65)) and not e.done.has(0):
     e.done[0]=true
     var end:Vector2=combat.vec(e.center)
     for target in targets(owner):
      var key:String=target.key
      if target.is_empty() or not target.alive:continue
      if Geometry2D.get_closest_point_to_segment(target.pos,origin,end).distance_to(target.pos)<=float(stats.get("width",38))*.5+14 and combat.path_clear(origin,target.pos):hit_status(key,stats,owner);combat.damage(key,float(e.damage),owner)
   "master_sigils":
    for n in clampi(int(stats.get("count",3)),1,5):
     if age>=float(stats.get("charge",.55))+n*.18 and not e.done.has(n):e.done[n]=true;area(e,sigil_point(e,n),float(stats.get("radius",70)),float(e.damage))
   "master_fountain":
    e.tick=float(e.tick)+minf(delta,maxf(0,float(e.time)-old))
    while float(e.tick)>=.49999:
     e.tick=maxf(0,float(e.tick)-.5);area(e,combat.vec(e.center),float(stats.get("radius",100)),float(e.damage))
     for ally in combat.adventure.points():
      if not combat.adventure.alive(str(ally)):continue
      if combat.adventure.arcade and combat.adventure.game.mode=="arena" and combat.adventure.game._rival(owner,str(ally)):continue
      var point:Vector2=combat.adventure.points()[ally]
      if point.distance_to(combat.vec(e.center))<=float(stats.get("radius",100)) and combat.path_clear(combat.vec(e.center),point):heal(owner,str(ally),float(stats.get("heal",2)))
   "master_pincer":
    var leg:=0 if age<.8 else 1
    for target in targets(owner):
     var key:String=target.key;var token:String=key+":"+str(leg)
     if target.is_empty() or not target.alive or e.hits.has(token):continue
     for side in [-1,1]:
      var before:=pincer_point(e,side,old);var after:=pincer_point(e,side,age)
      if Geometry2D.get_closest_point_to_segment(target.pos,before,after).distance_to(target.pos)<26 and combat.path_clear(before,target.pos):e.hits[token]=true;hit_status(key,stats,owner);combat.damage(key,float(e.damage),owner);break
   "master_chain":
    for n in e.targets.size():
     if age<.25+n*.2 or e.done.has(n):continue
     e.done[n]=true;var target:Dictionary=combat.actor(str(e.targets[n]))
     var previous:Vector2=origin if n==0 else combat.actor(str(e.targets[n-1])).get("pos",origin)
     if not target.is_empty() and target.alive and (previous as Vector2).distance_to(target.pos)<=float(stats.get("range",250)) and combat.path_clear(previous,target.pos):hit_status(str(e.targets[n]),stats,owner);combat.damage(str(e.targets[n]),float(e.damage),owner)
  if age>=float(e.time):effects.remove_at(i)
func snapshot()->Dictionary:return {"effects":effects}
func receive(data:Dictionary)->void:effects=data.get("effects",[])
func draw_on(c:Node2D,camera:Vector2)->void:
 for e in effects:
  var origin:Vector2=combat.vec(e.origin)-camera;var center:Vector2=combat.vec(e.center)-camera;var aim:Vector2=combat.vec(e.aim);var age:=float(e.age);var stats:Dictionary=e.stats;var colour:=Color(str(stats.get("color","#ead99f")));var soft:=Color(colour, .15)
  match str(e.style):
   "master_fan":
    for n in clampi(int(stats.get("count",3)),1,5):
     var phase:=age-float(stats.get("charge",.2))-n*.16
     if phase<-.2 or phase>.3:continue
     var angle:float=aim.angle()+(n-(int(stats.get("count",3))-1)*.5)*.35
     c.draw_arc(origin,float(stats.get("range",155))*(.7+clampf(phase,0,.3)),angle-.55,angle+.55,16,Color(colour,.65),4,true)
     c.draw_line(origin+Vector2.from_angle(angle-.3)*30,origin+Vector2.from_angle(angle+.3)*float(stats.get("range",155)),Color(colour,.28),2,true)
   "master_lance":
    var charge:=float(stats.get("charge",.65))
    c.draw_line(origin,center,soft,float(stats.get("width",38)),true)
    c.draw_line(origin,center,Color(colour,.35 if age<charge else .9),2 if age<charge else 7,true)
    for n in 6:
     var p:Vector2=origin.lerp(center,n/5.0)
     c.draw_arc(p,6+sin(age*10+n)*2,0,TAU,12,colour,1,true)
   "master_sigils":
    for n in clampi(int(stats.get("count",3)),1,5):
     var p:=sigil_point(e,n)-camera;var radius:=float(stats.get("radius",70));var fired:bool=age>=float(stats.get("charge",.55))+n*.18
     c.draw_circle(p,radius,Color(colour,.09 if not fired else .18))
     c.draw_arc(p,radius*(.75+.1*sin(age*8)),0,TAU,20,Color(colour,.4 if not fired else .85),2,true)
     for k in 4:
      var tip:=p+Vector2.from_angle(k*PI/2+age)*12
      c.draw_line(p,tip,colour,2,true)
   "master_fountain":
    var radius:=float(stats.get("radius",100));c.draw_circle(center,radius,soft)
    c.draw_arc(center,radius,0,TAU,32,Color(colour,.5),2,true)
    for n in 9:
     var t:=fposmod(age*1.2+n*.11,1);var p:Vector2=center+Vector2.from_angle(n*TAU/9)*radius*.75
     c.draw_line(p,p+Vector2(0,-12-25*t),Color(colour,1-t),2,true)
   "master_pincer":
    for side in [-1,1]:
     var p:=pincer_point(e,side,age)-camera;var before:=pincer_point(e,side,maxf(0,age-.1))-camera
     c.draw_line(before,p,Color(colour,.6),6,true)
     c.draw_colored_polygon(PackedVector2Array([p+aim*12,p+aim.orthogonal()*7,p-aim*12,p-aim.orthogonal()*7]),colour)
   "master_chain":
    var previous:Vector2=origin
    for n in e.targets.size():
     var target:Dictionary=combat.actor(str(e.targets[n]))
     if target.is_empty():continue
     var p:Vector2=target.pos-camera
     c.draw_line(previous,p,Color(colour,.18 if age<.25+n*.2 else .7),2,true)
     c.draw_arc(p,18+sin(age*10)*4,0,TAU,16,colour,2,true);previous=p

  var texture:Texture2D=visual_texture(str(stats.get("visual_texture","")))
  if texture!=null:
   match str(e.style):
    "master_pincer":
     for side in [-1,1]:
      var point:Vector2=pincer_point(e,side,age)-camera
      c.draw_texture_rect(texture,Rect2(point-Vector2(14,14),Vector2(28,28)),false)
    "master_sigils":
     for n in clampi(int(stats.get("count",3)),1,5):
      var point:Vector2=sigil_point(e,n)-camera
      c.draw_texture_rect(texture,Rect2(point-Vector2(18,18),Vector2(36,36)),false)
    _:
     var anchor:Vector2=center if str(e.style)=="master_fountain" else origin+aim*minf(80,float(stats.get("range",150))*.65)
     c.draw_texture_rect(texture,Rect2(anchor-Vector2(24,24),Vector2(48,48)),false)
func visual_texture(path:String)->Texture2D:
 if not path.begins_with("res://assets/"):return null
 if not art_cache.has(path):
  var asset:Resource=load(path) if ResourceLoader.exists(path) else null
  art_cache[path]=asset if asset is Texture2D else null
 return art_cache[path]
