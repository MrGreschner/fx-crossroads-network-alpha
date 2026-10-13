extends Node
## Twelve-second stances and a bounded melee/summoner kit, shared by solo and host.
var combat:Node
var states:Dictionary={}
var effects:Array=[]
var tracks:Dictionary={}
var clock:=0.0
var serial:=0
const STYLES=["monk_primary","monk_weighted","monk_secondary","monk_poison_form","monk_shadow_form","monk_punch","monk_dagger","monk_jab","monk_dash","monk_kicks","monk_flame","monk_darts","monk_veil","quill_claw","quill_lunge","quill_stampede","quill_summon","quill_pack"]
func reset()->void:states.clear();effects.clear();tracks.clear();clock=0;serial=0
func state(owner:String)->Dictionary:
 if not states.has(owner):states[owner]={"form":"melee","base":"melee","left":12.0}
 return states[owner]
func effective(owner:String,kind:String,stats:Dictionary)->Dictionary:
 if combat.v78.hero(owner)!="tempo" or kind=="special":return stats
 var form:=str(state(owner).form);var heavy:=str(stats.get("style",""))=="monk_weighted"
 var result:=stats.duplicate(true)
 var damage_scale:float=float(stats.get("damage",24 if kind=="primary" else 14))/(24 if kind=="primary" else 14)
 var cooldown_scale:float=float(stats.get("cooldown",.8 if kind=="primary" else 6))/(.8 if kind=="primary" else 6)
 if kind=="primary":
  result.style={"melee":"monk_punch","ranged":"monk_dagger","poison":"monk_jab","shadow":"monk_dash"}[form]
  result.damage=16 if form=="ranged" else 20 if form=="poison" else 24 if form=="melee" else 22;result.cooldown=.8 if form=="ranged" else 1.1 if form=="shadow" else .8 if form=="melee" else .6;result.range=420 if form=="ranged" else 160 if form=="shadow" else 85
  result.damage=float(result.damage)*damage_scale;result.cooldown=float(result.cooldown)*cooldown_scale
  if heavy:result.damage=float(result.damage)*1.25;result.cooldown=float(result.cooldown)*1.35
 else:
  result.style={"melee":"monk_kicks","ranged":"monk_flame","poison":"monk_darts","shadow":"monk_veil"}[form];result.damage={"melee":14,"ranged":6,"poison":8,"shadow":0}[form];result.cooldown=7 if form=="shadow" else 6;result.range=240 if form=="melee" else 175 if form=="ranged" else 320
 if kind=="secondary":result.damage=float(result.damage)*damage_scale;result.cooldown=float(result.cooldown)*cooldown_scale
 return result
func immune(owner:String)->bool:return effects.any(func(e):return str(e.owner)==owner and str(e.style)=="veil" and float(e.time)>0)
func moving(owner:String)->bool:return effects.any(func(e):return str(e.owner)==owner and str(e.style) in ["travel","kicks"])
func prepare(owner:String,stats:Dictionary)->bool:
 if str(stats.get("style",""))=="quill_summon" and pack(owner).size()>=3:combat.adventure.announce("Three quill companions are already active.");return false
 return true
func pack(owner:String)->Array:return combat.morrow.units.keys().filter(func(id):return str(combat.morrow.units[id].owner)==owner and str(combat.morrow.units[id].get("family",""))=="quill")
func summon(owner:String,p:Vector2)->String:
 serial+=1;var id:="risen:quill:"+str(serial);combat.morrow.units[id]={"owner":owner,"pos":combat.point_array(p),"sprite":"quillling","hp":40.0,"max_hp":40.0,"time":12.0,"ranged":false,"attack":.35,"contacts":{},"pose":"idle","family":"quill","weight":1,"damage":8,"speed":170,"reach":55,"interval":1.1};return id
func effect(owner:String,style:String,time:float,aim:Vector2,damage:float=0)->Dictionary:
 if effects.size()>=48:effects.pop_front()
 var e:Dictionary={"owner":owner,"style":style,"time":time,"duration":time,"aim":combat.point_array(aim),"pos":combat.point_array(combat.owner_pos(owner)),"damage":damage,"tick":0.0,"hits":[]};effects.append(e);return e
func strike(owner:String,p:Vector2,aim:Vector2,reach:float,damage:float,poison:bool=false,visual:bool=true)->bool:
 var hit:=false
 for key in combat.hostile(owner):
  var foe:Dictionary=combat.actor(key)
  if foe.is_empty() or not bool(foe.alive) or not combat.v56.cone(p,aim,foe.pos,reach,cos(PI*.3)) or not combat.path_clear(p,foe.pos):continue
  if poison:combat.apply_status(key,"poison",3,owner,2)
  combat.damage(key,damage,owner);hit=true
 if visual:combat.party_heroes.flash(p+aim*reach*.5,reach*.45,"#b1d297" if poison else "#e6c18a")
 return hit
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var p:Vector2=combat.owner_pos(owner)
 match style:
  "monk_poison_form","monk_shadow_form":
   var s:=state(owner);s.form="shadow" if style=="monk_shadow_form" else "poison";s.left=12.0;combat.party_heroes.flash(p,65,"#9e8de1" if s.form=="shadow" else "#a3d795")
  "monk_punch":
   var e:=effect(owner,"jabs",.3,aim,amount/3);e.stage=0;e.contacts={}
  "monk_jab":strike(owner,p,aim,85,amount,true)
  "monk_dagger":combat.launch_projectile(owner,p+aim*20,aim,{"speed":410,"range":420,"color":"#f5d6a0"},amount)
  "monk_darts":
   effect(owner,"spin",.7,aim)
   for n in 8:combat.launch_projectile(owner,p+Vector2.from_angle(n*TAU/8)*20,Vector2.from_angle(n*TAU/8),{"speed":290,"range":320,"color":"#a3d795","poison_duration":3,"poison_damage":2},amount)
  "monk_flame":effect(owner,"flame",2,aim,amount)
  "monk_veil":combat.apply_status(combat.player_key(owner),"guard",1.5,owner,1);effect(owner,"veil",1.5,aim)
  "monk_kicks":
   var targets:Array=[]
   for key in combat.hostile(owner):
    var f:Dictionary=combat.actor(key)
    if not f.is_empty() and bool(f.alive) and p.distance_to(f.pos)<=240 and combat.path_clear(p,f.pos):targets.append(key)
   targets.sort_custom(func(a,b):return p.distance_squared_to(combat.actor(a).pos)<p.distance_squared_to(combat.actor(b).pos))
   var e:=effect(owner,"kicks",1.0,aim,amount);e.targets=targets.slice(0,3);e.stage=0;e.tick=0.0
  "monk_dash","quill_lunge","quill_stampede":
   var distance:=float(stats.get("range",180));var e:=effect(owner,"travel",.24 if style!="quill_stampede" else .6,aim,amount);e.start=combat.point_array(p);e.end=combat.point_array(combat.v75.clip(p,aim,distance));e.knock=35 if style=="quill_stampede" else 25 if style=="quill_lunge" else 0;e.stun=.4 if style=="quill_lunge" else 0;e.hero=style
  "quill_claw":
   effect(owner,"briar_claw",.4,aim)
   if strike(owner,p,aim,85,amount,false,false) and combat.passive(owner,"prickle_guard"):combat.apply_status(combat.player_key(owner),"guard",1,owner,.1)
  "quill_summon":
   if pack(owner).size()<3:summon(owner,combat.v75.clip(p,aim,40))
  "quill_pack":
   var end:Vector2=combat.v79.destination(owner,aim,300)
   while pack(owner).size()<3:summon(owner,combat.v75.clip(p,Vector2.from_angle(pack(owner).size()*TAU/3),40))
   for id in pack(owner):
    combat.morrow.units[id].rally=combat.point_array(end);combat.morrow.units[id].rally_time=4.0;combat.apply_status("p:"+str(id),"guard",4,owner,.3)
   combat.party_heroes.flash(end,80,"#d4ba85")
 return true
func place(owner:String,point:Vector2)->void:
 if combat.adventure.arcade:
  combat.adventure.game.positions[owner]=point
  if owner==combat.adventure.game.my_id:combat.adventure.game.local_pos=point
 else:combat.adventure.teleport(owner,point)
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 for owner in combat.adventure.points():
  if not combat.adventure.alive(str(owner)):states.erase(owner);tracks.erase(owner);continue
  var p:Vector2=combat.owner_pos(str(owner));var previous:Vector2=combat.vec(tracks.get(owner,{}).get("pos",combat.point_array(p)));tracks[owner]={"pos":combat.point_array(p),"moving":p.distance_to(previous)>.1}
  if combat.v78.hero(str(owner))!="tempo":continue
  var s:=state(str(owner));s.left=float(s.left)-delta
  while float(s.left)<=0:
   if str(s.form) in ["poison","shadow"]:s.form=s.base
   else:
    s.base="ranged" if str(s.base)=="melee" else "melee";s.form=s.base
    if combat.passive(str(owner),"measured_breath"):combat.release_heroes.heal(str(owner),str(owner),4)
   s.left=float(s.left)+12
 for i in range(effects.size()-1,-1,-1):
  var e:Dictionary=effects[i];var owner:=str(e.owner);var active:=minf(delta,float(e.time));e.time=float(e.time)-delta;e.tick=float(e.tick)+active
  if not combat.adventure.alive(owner):effects.remove_at(i);continue
  var p:Vector2=combat.owner_pos(owner);var aim:Vector2=combat.vec(e.aim)
  match str(e.style):
   "jabs":
    while int(e.stage)<3 and float(e.duration)-float(e.time)>=int(e.stage)*.09:
     e.stage=int(e.stage)+1
     for key in combat.hostile(owner):
      var f:Dictionary=combat.actor(key)
      if f.is_empty() or not bool(f.alive) or not combat.v56.cone(p,aim,f.pos,85,cos(.33)) or not combat.path_clear(p,f.pos):continue
      combat.damage(key,float(e.damage),owner);e.contacts[key]=int(e.contacts.get(key,0))+1
      if int(e.contacts[key])==3:combat.apply_status(key,"slow",1,owner,.3)
   "flame":
    while float(e.tick)+.00001>=.25:
     e.tick=float(e.tick)-.25
     for key in combat.hostile(owner):
      var f:Dictionary=combat.actor(key)
      if not f.is_empty() and bool(f.alive) and combat.v56.cone(p,aim,f.pos,175,cos(deg_to_rad(22))) and combat.path_clear(p,f.pos):combat.apply_status(key,"burn",3,owner,2);combat.damage(key,float(e.damage),owner)
   "veil":
    while float(e.tick)+.00001>=.5:e.tick=float(e.tick)-.5;combat.release_heroes.heal(owner,owner,2)
   "travel":
    var before:Vector2=combat.owner_pos(owner);var end:Vector2=combat.vec(e.start).lerp(combat.vec(e.end),clampf(1-float(e.time)/float(e.duration),0,1));end=combat.v75.clip(before,end-before,before.distance_to(end));place(owner,end)
    for key in combat.hostile(owner):
     var f:Dictionary=combat.actor(key)
     if f.is_empty() or not bool(f.alive) or key in e.hits or f.pos.distance_to(Geometry2D.get_closest_point_to_segment(f.pos,before,end))>50 or not combat.path_clear(end,f.pos):continue
     e.hits.append(key);combat.damage(key,float(e.damage),owner);combat.knock(key,aim,float(e.knock))
     if float(e.stun)>0:combat.apply_status(key,"stun",float(e.stun),owner)
     if str(e.hero)=="quill_lunge" and combat.passive(owner,"prickle_guard"):combat.apply_status(combat.player_key(owner),"guard",1,owner,.1)
    combat.party_heroes.flash(end,24,"#d4ba85")
   "kicks":
    if int(e.stage)<e.targets.size():
     var f:Dictionary=combat.actor(str(e.targets[int(e.stage)]))
     if f.is_empty() or not bool(f.alive) or p.distance_to(f.pos)>280 or not combat.path_clear(p,f.pos):e.stage=int(e.stage)+1;e.tick=0
     else:
      var dest:Vector2=combat.v75.clip(p,(f.pos-p).normalized(),minf(p.distance_to(f.pos),850*delta));place(owner,dest)
      if dest.distance_to(f.pos)<=35:
       combat.damage(str(e.targets[int(e.stage)]),float(e.damage),owner);combat.apply_status(str(e.targets[int(e.stage)]),"stun",.7,owner);combat.party_heroes.flash(dest,40,"#e6c18a");e.stage=int(e.stage)+1
  if float(e.time)<=0:
   if str(e.style) in ["travel","kicks"]:combat.adventure.teleport(owner,combat.owner_pos(owner))
   effects.remove_at(i)
func visual_offset(owner:String)->Vector2:
 return Vector2(0,-maxf(0,sin(float(combat.adventure.game.motion_v85.clock)*TAU/.8))*12) if combat.v78.hero(owner)=="quill" and bool(tracks.get(owner,{}).get("moving",false)) else Vector2.ZERO
func snapshot()->Dictionary:return {"states":states,"effects":effects,"tracks":tracks,"clock":clock}
func receive(d:Dictionary)->void:states=d.get("states",{});effects=d.get("effects",[]);tracks=d.get("tracks",{});clock=float(d.get("clock",0))
func draw_on(c:Node2D,camera:Vector2)->void:
 for owner in combat.adventure.points():
  if not combat.adventure.alive(str(owner)) or not combat.visible_owner(str(owner)):continue
  var p:Vector2=combat.owner_pos(str(owner))-camera
  if combat.v78.hero(str(owner))=="tempo":
   var s:Dictionary=states.get(owner,{"form":"melee","left":12});var tint:=Color({"melee":"#e6c18a","ranged":"#ee9473","poison":"#a3d795","shadow":"#bcb1ed"}[str(s.form)])
   c.draw_arc(p,34,-PI/2,-PI/2+TAU*float(s.left)/12,40,tint,3,true);c.draw_string(ThemeDB.fallback_font,p+Vector2(-45,-82),str(s.form).capitalize()+" "+str(ceili(float(s.left))),HORIZONTAL_ALIGNMENT_LEFT,-1,12,tint)
  var dr:float=combat.display_reduction(str(owner))
  if dr>0:
   var strength:=.35+.3*(sin(Time.get_ticks_msec()/500.0)+1)*.5;c.draw_circle(p+Vector2(0,-66),6,Color(.76,.79,.83,strength));c.draw_arc(p+Vector2(0,-66),7,0,TAU,16,Color(.85,.89,.94,strength),2,true);c.draw_string(ThemeDB.fallback_font,p+Vector2(11,-62),"DR "+str(roundi(dr*100))+"%",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#d7e1ea"))
 for e in effects:
  var p:Vector2=combat.owner_pos(str(e.owner))-camera;var aim:Vector2=combat.vec(e.aim)
  if str(e.style)=="jabs":
   var t:float=fposmod((float(e.duration)-float(e.time))/.09,1);var jab:Vector2=p+aim*(22+58*sin(t*PI));var side:Vector2=aim.orthogonal()
   c.draw_line(p+aim*18+side*6,jab,Color("#f1d4a6"),4,true);c.draw_circle(jab,6,Color("#c5906d"));c.draw_line(jab-side*8,jab+side*8,Color("#fff0d1"),2,true)
  elif str(e.style)=="briar_claw":
   var t:float=1-float(e.time)/float(e.duration)
   for n in 3:
    var points:=PackedVector2Array()
    for j in 12:
     var angle:float=aim.angle()-.65+t*.9+j*.07;points.append(p+Vector2.from_angle(angle)*(46+n*12))
    c.draw_polyline(points,Color(.85,.94,.72,(1-t)*.9),3,true)
   for n in 5:
    var leaf:Vector2=p+aim*(38+t*55)+aim.orthogonal()*sin(n*2.4)*t*35;c.draw_line(leaf,leaf+Vector2.from_angle(n*2.4)*7,Color(.55,.75,.5,1-t),3,true)
  elif str(e.style)=="flame":
   for n in 20:
    var t:=fposmod(clock*1.8+n*.073,1);var offset:=aim.rotated(sin(n*2.7+clock*5)*.29)*t*175;c.draw_circle(p+offset,2+6*(1-t),Color(1,.4+.3*(1-t),.1,.75*(1-t)))
  elif str(e.style)=="spin":c.draw_arc(p,50,clock*12,clock*12+PI*1.4,24,Color("#a3d795"),6,true)
  elif str(e.style)=="veil":c.draw_circle(p,28,Color(.7,.65,.9,.2));c.draw_arc(p,31,0,TAU,24,Color(.8,.8,1,.7),2,true)
