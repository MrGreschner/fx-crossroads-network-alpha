extends Node
## Finite afterimages and a genuinely smaller projectile target. Host owns all damage.
var combat:Node
var effects:Array=[]
var memories:Dictionary={}
var mini:Dictionary={}
var clock:=0.0
const STYLES=["echo_cut","echo_feint","echo_encore","echo_company","mini_jabs","mini_shift","heart_forfeit"]
func reset()->void:effects.clear();memories.clear();mini.clear();clock=0
func small(id:String)->bool:return combat.playing() and float(mini.get(id,{}).get("time",0))>0
func charging(id:String)->bool:return effects.any(func(e):return e.owner==id and e.kind=="charge" and e.time>0)
func speed(id:String)->float:
 if charging(id):return .35
 return float(mini.get(id,{}).get("speed",1.5)) if small(id) else 1.0
func resize(id:String,rect:Rect2)->Rect2:
 if not small(id):return rect
 var foot:Vector2=rect.position+Vector2(rect.size.x*.5,rect.size.y)
 var size:Vector2=rect.size*.5
 return Rect2(foot-Vector2(size.x*.5,size.y),size)
func target_radius(key:String,fallback:float=18)->float:return fallback*.4 if key.begins_with("p:") and small(key.substr(2)) else fallback
func remember(id:String,p:Vector2,aim:Vector2)->void:
 var records:Array=memories.get(id,[])
 records.append({"pos":combat.point_array(p),"aim":combat.point_array(aim),"left":5.0})
 if records.size()>3:records.pop_front()
 memories[id]=records
func spawn(id:String,kind:String,p:Vector2,aim:Vector2,time:float,damage:float,radius:float)->Dictionary:
 var e:Dictionary={"owner":id,"kind":kind,"pos":combat.point_array(p),"aim":combat.point_array(aim),"time":time,"duration":time,"damage":damage,"radius":radius,"tick":0.0,"count":0,"hits":{},"done":false}
 if effects.size()<96:effects.append(e)
 return e
func strike(id:String,p:Vector2,aim:Vector2,reach:float,amount:float,cone:bool=true)->Array[String]:
 var hits:Array[String]=[]
 for key in combat.hostile(id):
  var f:Dictionary=combat.actor(key)
  if f.is_empty() or not bool(f.alive) or not combat.path_clear(p,f.pos):continue
  if (combat.v56.cone(p,aim,f.pos,reach,.4) if cone else p.distance_to(f.pos)<=reach):combat.damage(key,amount,id);hits.append(str(key))
 return hits
func cast(id:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:String=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.playing() or not combat.adventure.authoritative() or not combat.adventure.alive(id):return true
 var p:Vector2=combat.owner_pos(id)
 match style:
  "echo_cut":
   var reach:float=float(stats.get("range",90));strike(id,p,aim,reach,amount);remember(id,p,aim)
   spawn(id,"saber",p,aim,.2,0,reach)
   spawn(id,"echo",p,aim,.65,amount*float(stats.get("echo_ratio",.65 if combat.passive(id,"echo_applause") else .5)),reach).delay=.45
  "echo_feint":
   var records:Array=memories.get(id,[])
   if not records.is_empty():
    var end:Vector2=combat.vec(records[-1].pos)
    if p.distance_to(end)<=400 and combat.path_clear(p,end):
     strike(id,p,aim,70,amount,false);combat.adventure.teleport(id,end);spawn(id,"ring",p,aim,.4,0,70)
  "echo_encore":
   var records:Array=memories.get(id,[])
   for n in records.size():
    var rec:Dictionary=records[n];var e:Dictionary=spawn(id,"echo",combat.vec(rec.pos),combat.vec(rec.aim),.65+n*.3,amount,105);e.delay=.45+n*.3;e.encore=true
  "echo_company":
   var records:Array=memories.get(id,[])
   for rec in records:
    var unit:String=combat.party_heroes.add_unit(id,combat.vec(rec.pos),"echo_company",1,24,6)
    var u:Dictionary=combat.morrow.units[unit];u.sprite="echo_dancer";u.hp=24;u.max_hp=24;u.damage=6;u.ranged=false;u.speed=150;u.reach=65;u.family="echo_company"
  "mini_jabs":spawn(id,"jabs",p,aim,.37,amount,float(stats.get("range",72)))
  "mini_shift":mini[id]={"time":float(stats.get("duration",4)),"speed":float(stats.get("move_factor",1.5))};spawn(id,"ring",p,aim,.35,0,28)
  "heart_forfeit":
   var e:Dictionary=spawn(id,"charge",p,aim,1.0,0,float(stats.get("range",165)));e.fraction=float(stats.get("health_cost",.5))
 return true
func sacrifice(id:String,p:Vector2,aim:Vector2,radius:float,fraction:float)->void:
 var g:Node=combat.adventure.game
 var maximum:float=g._max_hp(id) if combat.adventure.arcade else g.max_health()
 var cost:float=ceilf(maximum*fraction)
 var reach:float=radius;strike(id,p,aim,reach,cost,false);spawn(id,"forfeit",p,aim,.55,0,reach)
 # Direct cost bypasses armour, shields, sharing, food, rescue and kill-credit.
 if combat.adventure.arcade:
  g.health[id]=maxi(0,int(g.health.get(id,0))-int(cost));g.hit_flash[id]=Time.get_ticks_msec()+250
  if int(g.health[id])==0:
   g.defeat_causes[id]=preload("res://scripts/defeat_credit.gd").resolve(g,id,"Heart Forfeit • health sacrifice")
   if g.arena_records.has(id):g.arena_records[id].deaths+=1;g.arena_records[id].kill_streak=0
   g.respawn_at[id]=Time.get_ticks_msec()+2500 if g.mode=="arena" else Time.get_ticks_msec()+7000 if g.mode=="battlegrounds" else Time.get_ticks_msec()+5000 if g.mode=="defense" else 9223372036854775807
   if g.mode in ["coop","descent"] and g.positions.size()>1:g.downed[id]={"left":25.0,"progress":0.0,"rescuer":""}
   if g.mode in ["coop","descent"] and not g.health.values().any(func(h):return int(h)>0):g.end_match("Party defeated")
 else:
  g.health=maxf(1 if g.practice else 0,g.health-cost);g.player_flash_time=.25
  if g.health<=0:
   g.last_defeat=preload("res://scripts/defeat_credit.gd").resolve(g,"self","Heart Forfeit • health sacrifice");g.last_defeat.sprite=str(g.hero.get("sprite",g.character_id));g.finish_run(false)
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 if not combat.playing():reset();return
 for id in mini.keys():
  mini[id].time=float(mini[id].time)-delta
  if mini[id].time<=0 or not combat.adventure.alive(str(id)):mini.erase(id)
 for id in memories.keys():
  var records:Array=memories[id]
  for n in range(records.size()-1,-1,-1):
   records[n].left=float(records[n].left)-delta
   if records[n].left<=0 or not combat.adventure.alive(str(id)):records.remove_at(n)
  if records.is_empty():memories.erase(id)
 for i in range(effects.size()-1,-1,-1):
  var e:Dictionary=effects[i];var id:String=str(e.owner);e.time=float(e.time)-delta
  if e.kind=="charge":
   e.pos=combat.point_array(combat.owner_pos(id))
   if not combat.adventure.alive(id) or combat.stunned(combat.player_key(id)):e.time=0
   elif e.time<=0:sacrifice(id,combat.vec(e.pos),combat.vec(e.aim),float(e.radius),float(e.fraction))
  elif e.kind=="echo" and not e.done and float(e.duration)-float(e.time)>=float(e.delay):e.done=true;strike(id,combat.vec(e.pos),combat.vec(e.aim),float(e.radius),float(e.damage));
  elif e.kind=="jabs" and combat.adventure.alive(id):
   e.tick=float(e.tick)-delta
   if e.tick<=0 and int(e.count)<3:
    e.count=int(e.count)+1;e.tick=.1;e.pos=combat.point_array(combat.owner_pos(id))
    for key in strike(id,combat.vec(e.pos),combat.vec(e.aim),float(e.radius),float(e.damage)):
     e.hits[key]=int(e.hits.get(key,0))+1
     if int(e.hits[key])==3:
      combat.apply_status(key,"slow",2,id,.65)
      if combat.passive(id,"small_courage"):combat.apply_status(combat.player_key(id),"guard",1.5,id,.1)
  if e.time<=0 and effects.has(e):effects.erase(e)
func snapshot()->Dictionary:return {"effects":effects,"memories":memories,"mini":mini,"clock":clock}
func receive(d:Dictionary)->void:effects=d.get("effects",[]);memories=d.get("memories",{});mini=d.get("mini",{});clock=float(d.get("clock",clock))
func draw_on(c:Node2D,camera:Vector2)->void:
 if not combat.playing():return
 var visible:=Rect2(camera-Vector2(120,120),c.get_viewport_rect().size+Vector2(240,240))
 for id in memories:
  for rec in memories[id]:
   var world:Vector2=combat.vec(rec.pos)
   if not visible.has_point(world):continue
   var p:Vector2=world-camera;var dir:Vector2=combat.vec(rec.aim)
   c.draw_arc(p,18,clock*.8,clock*.8+PI*1.4,12,Color(.45,.8,.91,.25),1.5,true);c.draw_line(p,p+dir*26,Color(.6,.9,1,.25),2,true)
 for e in combat.draw_effect_records("v110","effects",effects):
  if not visible.has_point(combat.draw_effect_position("v110",e,combat.vec(e.pos))):continue
  var p:Vector2=combat.draw_effect_position("v110",e,combat.vec(e.pos))-camera;var dir:Vector2=combat.vec(e.aim);var t:float=1-float(e.time)/float(e.duration)
  match str(e.kind):
   "saber","echo":
    var tint:=Color(.63,.9,1,.7) if e.kind=="saber" or bool(e.done) else Color(.63,.9,1,.18)
    var angle:float=dir.angle()-.65+t*1.3
    c.draw_arc(p,float(e.radius),angle-.22,angle+.22,10,tint,4 if e.kind=="saber" else 2,true)
    c.draw_line(p+Vector2.from_angle(angle)*25,p+Vector2.from_angle(angle)*float(e.radius),tint,3,true)
   "jabs":
    var phase:float=fposmod(t*3,1);var point:Vector2=p+dir*(20+sin(phase*PI)*(float(e.radius)-20))
    c.draw_line(p+dir*18,point,Color(.94,.75,.68,.8),5,true);c.draw_circle(point,6,Color("#deb39a"))
   "ring":c.draw_arc(p,maxf(1,float(e.radius)*t),0,TAU,20,Color(.6,.86,1,1-t),2,true)
   "charge":
    c.draw_circle(p,float(e.radius),Color(.8,.1,.25,.06))
    c.draw_arc(p,float(e.radius),0,TAU,32,Color(.93,.37,.51,.35),2,true)
    c.draw_arc(p,25,-PI/2,-PI/2+TAU*t,24,Color(1,.55,.65,.9),4,true)
    c.draw_circle(p+Vector2(0,-40),5+t*6,Color(1,.3,.45,.8))
   "forfeit":
    c.draw_circle(p,float(e.radius),Color(.75,.13,.3,.15*(1-t)));c.draw_arc(p,float(e.radius),0,TAU,32,Color(.93,.37,.51,1-t),4,true)
    for n in 8:c.draw_line(p+Vector2.from_angle(n*TAU/8)*float(e.radius)*t,p+Vector2.from_angle(n*TAU/8)*float(e.radius),Color(.95,.45,.55,1-t),2,true)
