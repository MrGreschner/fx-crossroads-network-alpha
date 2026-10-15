extends Node
## Bounded effects and movement history; host owns damage, burrowing and rift pins.
var combat:Node
var effects:Array=[]
var pins:Dictionary={}
var tunnels:Dictionary={}
var locks:Dictionary={}
var motion:Dictionary={}
var clock_offset:=0.0
var trail_tick:=0.0
const STYLES=["gopher_claw","gopher_dive","gopher_cave","gopher_fault","rift_pin","rift_rotate","rift_triangle","rift_scatter"]
const PERIOD:=.95
var dig_directions:Dictionary={}
const UNDER:=.78
func reset()->void:
 dig_directions.clear();effects.clear();pins.clear();tunnels.clear();locks.clear();motion.clear();clock_offset=0;trail_tick=0
func now()->float:return Time.get_ticks_msec()/1000.0+clock_offset
func hero(id:String)->String:
 if id=="training_ally":return ""
 return str(combat.adventure.game.hero_ids.get(id,"")) if combat.adventure.arcade else str(combat.adventure.game.selected_character if combat.adventure.game.mode=="town" else combat.adventure.game.character_id)
func locked(id:String)->bool:return float(locks.get(id,0))>now()
func travel(delta:float)->float:
 var t:=now()
 return distance_clock(t)-distance_clock(t-delta)
func distance_clock(t:float)->float:
 # Smooth, modest speed variation; no fast slide followed by an abrupt stop.
 return t-.20*PERIOD/TAU*sin(TAU*t/PERIOD)
func dig_vector(id:String,wish:Vector2)->Vector2:
 var cycle:=int(floor(now()/PERIOD))
 var phase:=fposmod(now(),PERIOD)/PERIOD
 if locked(id):dig_directions.erase(id);return Vector2.ZERO
 if phase>=.76:return Vector2.ZERO
 if not dig_directions.has(id) or int(dig_directions[id].cycle)!=cycle:
  if wish.is_zero_approx():return Vector2.ZERO
  dig_directions[id]={"cycle":cycle,"direction":wish.normalized()}
 return dig_directions[id].direction*.8
func triangle_vertex(e:Dictionary,index:int)->Vector2:
 var angle:=PI*clampf(float(e.age)/1.2,0,1)
 return combat.vec(e.pos)+combat.vec(e.aim).rotated(TAU*index/3+angle)*float(e.stats.get("radius",125))
func depth(id:String)->float:
 if not motion.has(id) or locked(id):return 0
 if now()-float(motion[id].recent)>.16:return 0
 return pow(maxf(0,sin(PI*clampf(fposmod(now(),PERIOD)/PERIOD/.76,0,1))),2)
func visual_rect(id:String,point:Vector2)->Rect2:
 var d:=depth(id);var size:=Vector2(56,64*(1-d*.65))
 return Rect2(point+Vector2(-28,22-size.y+d*6),size)
func sample(id:String,point:Vector2,enabled:bool)->void:
 if not enabled or hero(id)!="gopher":motion.erase(id);return
 var stamp:=now();var cycle:=int(floor(stamp/PERIOD))
 var m:Dictionary=motion.get(id,{"point":combat.point_array(point),"recent":-10.0,"cycle":cycle,"start":combat.point_array(point)})
 var before:Vector2=combat.vec(m.point)
 if before.distance_to(point)>180:motion.erase(id);return
 if before.distance_to(point)>.2:m.recent=stamp
 if int(m.cycle)!=cycle:
  var first:Vector2=combat.vec(m.start)
  if first.distance_to(before)>8:
   var lines:Array=tunnels.get(id,[]);lines.append([combat.point_array(first),combat.point_array(before)])
   while lines.size()>4:lines.pop_front()
   tunnels[id]=lines
  m.start=combat.point_array(before);m.cycle=cycle
 m.point=combat.point_array(point);motion[id]=m
func underground(id:String)->bool:
 if hero(id)!="gopher" or locked(id) or not combat.adventure.alive(id):return false
 if not motion.has(id):return false
 return depth(id)>.7
func preview_lines(owner:String)->Array:
 var lines:Array=tunnels.get(owner,[]).duplicate(true)
 if motion.has(owner):
  var m:Dictionary=motion[owner];var a:Vector2=combat.vec(m.start);var b:Vector2=combat.vec(m.point)
  if a.distance_to(b)>8:lines.append([combat.point_array(a),combat.point_array(b)])
 while lines.size()>4:lines.pop_front()
 return lines
func immune(id:String)->bool:
 if underground(id):return true
 for e in effects:
  if str(e.owner)==id and str(e.style)=="gopher_dive" and float(e.age)<.55:return true
 return false
func lock(id:String,time:float)->void:
 dig_directions.erase(id)
 locks[id]=now()+time
 var game:Node=combat.adventure.game
 if combat.adventure.arcade:
  game.charges.erase(id)
  if id==game.my_id:game.dodge_time=0
 else:game.dodge_time=0;game.charge_time=0
 if motion.has(id):motion[id].recent=-10.0
func add(owner:String,style:String,p:Vector2,aim:Vector2,stats:Dictionary,damage:float,time:float)->Dictionary:
 if effects.size()>=32:return {}
 var e:Dictionary={"owner":owner,"style":style,"pos":combat.point_array(p),"aim":combat.point_array(aim),"stats":stats.duplicate(true),"damage":damage,"time":time,"age":0.0,"hits":[]}
 effects.append(e);return e
func line_hit(owner:String,a:Vector2,b:Vector2,width:float,damage:float,stats:Dictionary,hits:Array)->void:
 for key in combat.hostile(owner):
  var target:Dictionary=combat.actor(key)
  if target.is_empty() or not bool(target.alive) or hits.has(key):continue
  var q:Vector2=Geometry2D.get_closest_point_to_segment(target.pos,a,b)
  if q.distance_to(target.pos)<=width and combat.path_clear(a,q) and combat.path_clear(q,target.pos):
   hits.append(key);combat.apply_hit_status(key,stats,owner)
   if float(stats.get("slow_duration",0))>0:combat.apply_status(key,"slow",float(stats.slow_duration),owner,float(stats.get("slow",.65)))
   combat.damage(key,damage,owner)
func prepare(owner:String,stats:Dictionary)->bool:
 return str(stats.get("style",""))!="rift_rotate" or pins.get(owner,[]).size()==2
func cast(owner:String,stats:Dictionary,aim:Vector2,damage:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var p:Vector2=combat.owner_pos(owner);aim=aim.normalized() if not aim.is_zero_approx() else Vector2.RIGHT
 match style:
  "gopher_claw":
   lock(owner,.32)
   add(owner,style,p,aim,stats,damage,.32)
  "gopher_dive":
   lock(owner,.8)
   var key:String=combat.v75.selected(owner,aim,float(stats.get("range",560)))
   var dest:Vector2=combat.actor(key).get("pos",combat.v75.clip(p,aim,float(stats.get("range",560))))
   # Stop just short of a target and never burrow through map walls.
   var delta:Vector2=dest-p;dest=combat.v75.clip(p,delta,maxf(0,delta.length()-25))
   var e:=add(owner,style,p,aim,stats,damage,.9)
   if not e.is_empty():e["end"]=combat.point_array(dest);e["origin"]=combat.point_array(p)
  "gopher_cave","gopher_fault":
   lock(owner,.75)
   var lines:Array=preview_lines(owner)
   if style=="gopher_fault":lines=[[combat.point_array(p),combat.point_array(combat.v75.clip(p,aim,340))]]
   if lines.is_empty():lines=[[combat.point_array(p-aim*32),combat.point_array(combat.v75.clip(p,aim,90))]]
   var e:=add(owner,style,p,aim,stats,damage,1.25)
   if not e.is_empty():e["lines"]=lines
  "rift_pin":
   var point:Vector2=combat.v79.destination(owner,aim,float(stats.get("range",280)))
   var pair:Array=pins.get(owner,[])
   pair.append(combat.point_array(point))
   while pair.size()>2:pair.pop_front()
   if pair.size()==2 and combat.vec(pair[0]).distance_to(combat.vec(pair[1]))>600:pair.pop_front()
   pins[owner]=pair
   combat.v75.area(owner,point,26,damage,stats)
   var e:=add(owner,style,point,aim,stats,damage,.5)
   if pair.size()==2 and not e.is_empty():
    e["lines"]=[[pair[0],pair[1]]];line_hit(owner,combat.vec(pair[0]),combat.vec(pair[1]),18,damage*float(stats.get("link_multiplier",1.4)),stats,e.hits)
  "rift_rotate":
   var pair:Array=pins.get(owner,[])
   if pair.size()<2:
    add(owner,"rift_empty",p,aim,stats,0,.7);return true
   var a:Vector2=combat.vec(pair[0]);var b:Vector2=combat.vec(pair[1]);var e:=add(owner,style,(a+b)*.5,aim,stats,damage,.65)
   if not e.is_empty():e["arm"]=combat.point_array((b-a)*.5)
   var arm:Vector2=(b-a).rotated(PI*.5)*.5;pins[owner]=[combat.point_array((a+b)*.5-arm),combat.point_array((a+b)*.5+arm)]
  "rift_triangle":
   var point:Vector2=combat.v79.destination(owner,aim,float(stats.get("range",500)));var e:=add(owner,style,point,aim,stats,damage,1.8)
   if not e.is_empty():
    var vertices:Array=[]
    for n in 3:vertices.append(combat.point_array(point+aim.rotated(TAU*n/3)*float(stats.get("radius",125))))
    e["vertices"]=vertices
  "rift_scatter":
   for n in 3:
    var e:=add(owner,style,combat.v75.clip(p,aim.rotated((n-1)*.35),180),aim,stats,damage,1.0+n*.15)
    if not e.is_empty():e["delay"]=.6+n*.15
 return true
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 trail_tick+=delta
 if trail_tick>=.15:trail_tick=fmod(trail_tick,.15);slow_trails()
 for owner in pins.keys():
  if not combat.adventure.alive(str(owner)):pins.erase(owner)
 for i in range(effects.size()-1,-1,-1):
  var e:Dictionary=effects[i];e.age=float(e.age)+delta
  var owner:=str(e.owner);var p:Vector2=combat.vec(e.pos);var stats:Dictionary=e.stats
  if not combat.adventure.alive(owner):effects.remove_at(i);continue
  match str(e.style):
   "gopher_claw":
    for swipe in 2:
     if float(e.age)<swipe*.14 or e.hits.has(swipe):continue
     e.hits.append(swipe)
     for key in combat.hostile(owner):
      var target:Dictionary=combat.actor(key)
      var origin:Vector2=combat.owner_pos(owner)
      if target.is_empty() or not bool(target.alive):continue
      if combat.v56.cone(origin,combat.vec(e.aim),target.pos,80,cos(deg_to_rad(50))) and combat.path_clear(origin,target.pos):
       if randf()<.4:combat.apply_status(key,"bleed",3,owner,2)
       combat.damage(key,float(e.damage),owner)
   "gopher_dive":
    var origin:Vector2=combat.vec(e.origin);var end:Vector2=combat.vec(e.end)
    if float(e.age)<.55:combat.adventure.teleport(owner,origin.lerp(end,clampf(float(e.age)/.55,0,1)))
    elif not e.hits.has("done"):
     e.hits.append("done");combat.adventure.teleport(owner,end);combat.v75.area(owner,end,float(stats.get("radius",65)),float(e.damage),stats)
     if combat.passive(owner,"packed_earth"):combat.apply_status(combat.player_key(owner),"guard",2,owner,.12)
   "gopher_cave","gopher_fault":
    if float(e.age)>=.65 and not e.hits.has("done"):
     for line in e.lines:line_hit(owner,combat.vec(line[0]),combat.vec(line[1]),float(stats.get("width",38)),float(e.damage),stats,e.hits)
     e.hits.append("done")
   "rift_rotate":
    var arm:Vector2=combat.vec(e.arm).rotated(minf(1,float(e.age)/.6)*PI*.5)
    line_hit(owner,p-arm,p+arm,float(stats.get("width",20)),float(e.damage),stats,e.hits)
   "rift_triangle":
    for n in 3:
     if float(e.age)<.65+n*.3 or e.hits.has(n):continue
     e.hits.append(n)
     var hits:Array=[];line_hit(owner,triangle_vertex(e,n),triangle_vertex(e,(n+1)%3),24,float(e.damage),stats,hits)
   "rift_scatter":
    if float(e.age)>=float(e.delay) and not e.hits.has("done"):
     e.hits.append("done");combat.v75.area(owner,p,60,float(e.damage),stats)
  if float(e.age)>=float(e.time):effects.remove_at(i)
func slow_trails()->void:
 for owner in combat.adventure.points():
  if hero(str(owner))!="gopher" or not combat.adventure.alive(str(owner)):continue
  for line in preview_lines(str(owner)):
   var a:Vector2=combat.vec(line[0]);var b:Vector2=combat.vec(line[1])
   for key in combat.hostile(str(owner)):
    var target:Dictionary=combat.actor(key)
    if target.is_empty() or not bool(target.alive):continue
    var q:Vector2=Geometry2D.get_closest_point_to_segment(target.pos,a,b)
    if q.distance_to(target.pos)<24 and combat.path_clear(q,target.pos):combat.apply_status(key,"slow",.35,str(owner),.8)
func snapshot()->Dictionary:
 var left:Dictionary={}
 for id in locks:
  if locked(str(id)):left[id]=maxf(0,float(locks[id])-now())
 return {"effects":effects,"pins":pins,"tunnels":tunnels,"motion":motion,"lock_left":left,"clock":now()}
func receive(data:Dictionary)->void:
 clock_offset=float(data.get("clock",Time.get_ticks_msec()/1000.0))-Time.get_ticks_msec()/1000.0
 effects=data.get("effects",[]);pins=data.get("pins",{});tunnels=data.get("tunnels",{})
 # Host history is authoritative; local gait sampling stays smooth between snapshots.
 locks.clear()
 for id in data.get("lock_left",{}):locks[id]=now()+float(data.lock_left[id])
func draw_burrow(c:CanvasItem,id:String,p:Vector2)->void:
 if motion.has(id):
  var offset:Vector2=combat.vec(motion[id].start)-combat.owner_pos(id)
  if offset.length()<180:c.draw_line(p+offset+Vector2(0,10),p+Vector2(0,10),Color(.3,.23,.13,.35),12,true)
 c.draw_circle(p+Vector2(0,10),19,Color("#594733"))
 c.draw_arc(p+Vector2(0,10),20,PI,TAU,14,Color("#b39b60"),5,true)
 for n in 5:
  var offset:=Vector2((n-2)*10,sin(now()*14+n)*4)
  c.draw_circle(p+offset,3,Color("#d4b578"))
func draw_on(c:Node2D,camera:Vector2)->void:
 for owner in combat.adventure.points():
  if hero(str(owner))!="gopher" or not combat.adventure.alive(str(owner)):continue
  var lines:Array=preview_lines(str(owner))
  for n in lines.size():
   var a:Vector2=combat.vec(lines[n][0])-camera;var b:Vector2=combat.vec(lines[n][1])-camera
   c.draw_line(a,b,Color(.34,.24,.12,.45),26,true)
   c.draw_line(a,b,Color(.77,.6,.32,.7),3,true)
   c.draw_arc(a,9,0,TAU,12,Color("#b0915b"),2,true);c.draw_arc(b,9,0,TAU,12,Color("#b0915b"),2,true)
   for stone in 7:
    var q:Vector2=a.lerp(b,(stone+.5)/7.0)+(b-a).normalized().orthogonal()*(11 if stone%2 else -11)
    c.draw_circle(q,2.5,Color("#a5844e"))
  for n in lines.size():
   var end:Vector2=combat.vec(lines[n][1])-camera+Vector2(0,-16)
   c.draw_circle(end,9,Color(.16,.12,.07,.8))
   c.draw_string(ThemeDB.fallback_font,end+Vector2(-4,4),str(n+1),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#ffe3a7"))
 draw_aim(c,camera)
 for owner in pins:
  var pair:Array=pins[owner]
  for v in pair:
   var p:Vector2=combat.vec(v)-camera;c.draw_arc(p,12,0,TAU,16,Color("#c89aff"),3,true)
  if pair.size()==2:c.draw_line(combat.vec(pair[0])-camera,combat.vec(pair[1])-camera,Color(.65,.35,1,.22),2,true)
 for e in combat.draw_effect_records("v78","effects",effects):
  var p:Vector2=combat.draw_effect_position("v78",e,combat.vec(e.pos))-camera;var age:float=float(e.age);var aim:Vector2=combat.vec(e.aim)
  match str(e.style):
   "gopher_claw":
    var progress:=fposmod(age,.14)/.14;var angle:=aim.angle()+lerpf(-.8,.8,progress)*(1 if age<.14 else -1)
    for n in 3:c.draw_arc(p+aim*25+aim.orthogonal()*(n-1)*10,30+n*4,angle-.22,angle+.22,12,Color("#efdbac"),3,true)
   "gopher_dive":
    var q:Vector2=combat.vec(e.end)-camera
    c.draw_arc(q,float(e.stats.get("radius",65)),0,TAU,24,Color(.9,.7,.35,.6),2,true)
    if age<.55:draw_burrow(c,str(e.owner),combat.owner_pos(str(e.owner))-camera)
    else:c.draw_arc(q,clampf((age-.55)*180,0,65),0,TAU,24,Color("#e7c98a"),5,true)
   "gopher_cave","gopher_fault","rift_pin":
    for line in e.get("lines",[]):
     var a:Vector2=combat.vec(line[0])-camera;var b:Vector2=combat.vec(line[1])-camera
     var cave:bool=str(e.style).begins_with("gopher")
     c.draw_line(a,b,Color(.8,.65,.35,.18) if cave else Color(.6,.3,1,.2),float(e.stats.get("width",18))*2,true)
     c.draw_line(a,b,Color("#e0b576") if cave else Color("#dab8ff"),3 if age<.65 else 7,true)
     if cave and age>=.65:
      for n in 8:c.draw_circle(a.lerp(b,n/7.0)+Vector2(0,-sin((age-.65)*PI)*18),5,Color("#806344"))
   "rift_rotate":
    var arm:Vector2=combat.vec(e.arm).rotated(minf(1,age/.6)*PI*.5)
    c.draw_line(p-arm,p+arm,Color(.7,.4,1,.3),float(e.stats.get("width",20))*2,true);c.draw_line(p-arm,p+arm,Color("#e4c6ff"),5,true)
   "rift_triangle":
    for n in 3:
     var a:Vector2=triangle_vertex(e,n)-camera;var b:Vector2=triangle_vertex(e,(n+1)%3)-camera
     c.draw_line(a,b,Color(.7,.4,1,.25),6,true)
     if age>=.65+n*.3 and age<1.05+n*.3:c.draw_line(a,b,Color("#f1b6ff"),12,true)
   "rift_scatter":c.draw_arc(p,60,0,TAU,24,Color("#d1a7ff"),2 if age<float(e.delay) else 7,true)
   "rift_empty":c.draw_string(ThemeDB.fallback_font,p+Vector2(-65,-40),"Place two rift pins",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#cba5ff"))

func draw_aim(c:Node2D,camera:Vector2)->void:
 var game:Node=combat.adventure.game
 var owner:String=str(game.my_id) if combat.adventure.arcade else "solo"
 if combat.adventure.arcade:
  if not game.started or not game.shop_open.is_empty():return
 elif game.mode!="run" or not game.menu.is_empty():return
 if hero(owner)!="nullweaver" or not combat.adventure.alive(owner):return
 var lv:int=int(game.levels.get(owner,1)) if combat.adventure.arcade else int(game.level)
 var primary:Dictionary=combat.effective_stats(owner,"primary",game.characters.nullweaver.primary)
 var mouse:Vector2=combat.owner_pos(owner)+game.mobile.aim*float(primary.get("range",280)) if game.mobile.enabled else game.media_mouse_world()
 var delta:Vector2=mouse-combat.owner_pos(owner)
 var pin:Vector2=combat.v75.clip(combat.owner_pos(owner),delta,minf(delta.length(),float(primary.get("range",280))))-camera
 c.draw_arc(pin,11,0,TAU,18,Color(.82,.7,1,.7),2,true)
 if lv<6 or not Input.is_action_pressed("special"):return
 var aim:Vector2=game.mobile.aim if game.mobile.enabled else (game.media_mouse_world()-combat.owner_pos(owner)).normalized()
 if aim.is_zero_approx():aim=Vector2.RIGHT
 var stats:Dictionary=game.characters.nullweaver.special
 stats=combat.effective_stats(owner,"special",stats)
 var target:Vector2=combat.owner_pos(owner)+aim*float(stats.get("range",500)) if game.mobile.enabled else game.media_mouse_world()
 var offset:Vector2=target-combat.owner_pos(owner)
 var p:Vector2=combat.v75.clip(combat.owner_pos(owner),offset,minf(offset.length(),float(stats.get("range",500))))-camera
 var tint:=Color(.82,.7,1,.78)
 if str(stats.style)=="rift_triangle":
  var vertices:Array=[]
  for n in 3:vertices.append(p+aim.rotated(TAU*n/3)*float(stats.get("radius",125)))
  for n in 3:
   c.draw_dashed_line(vertices[n],vertices[(n+1)%3],Color(.15,.08,.23,.7),4,9,true)
   c.draw_dashed_line(vertices[n],vertices[(n+1)%3],tint,2,9,true)
 else:
  for n in 3:c.draw_arc(combat.v75.clip(combat.owner_pos(owner),aim.rotated((n-1)*.35),180)-camera,60,0,TAU,24,tint,1,true)
 c.draw_line(p-Vector2(7,0),p+Vector2(7,0),tint,2);c.draw_line(p-Vector2(0,7),p+Vector2(0,7),tint,2)
 c.draw_rect(Rect2(p+Vector2(-52,-29),Vector2(98,19)),Color(.12,.09,.2,.65))
 c.draw_string(ThemeDB.fallback_font,p+Vector2(-49,-14),"SPECIAL AIM",HORIZONTAL_ALIGNMENT_LEFT,-1,12,tint)
