extends Node
var combat:Node
var copies:Dictionary={}
var folds:Array=[]
var chronicles:Dictionary={}
var replays:Array=[]
var ghosts:Array=[]
var turns:Array=[]
var overload:Dictionary={}
var pulses:Array=[]
var elements:Dictionary={}
var gardens:Array=[]
var switches:Dictionary={}
func reset()->void:copies.clear();folds.clear();chronicles.clear();replays.clear();ghosts.clear();turns.clear();overload.clear();pulses.clear();elements.clear();gardens.clear();switches.clear()
func mirror_id(owner:String)->String:return "mirror:"+owner
func is_mirror(id:String)->bool:return id.begins_with("mirror:")
func mirror_actor(id:String)->Dictionary:
 var owner:String=id.trim_prefix("mirror:")
 if not copies.has(owner):return {}
 var body:Dictionary=copies[owner]
 return {"pos":combat.vec(body.pos),"alive":float(body.hp)>0 and float(body.time)>0 or bool(body.get("transferred",false)) and combat.adventure.alive(owner),"player":id}
func target_points()->Dictionary:
 var result:Dictionary=combat.adventure.points().duplicate()
 for owner in copies:
  var body:Dictionary=copies[owner]
  if float(body.hp)>0 and float(body.time)>0 and not bool(body.get("transferred",false)):result[mirror_id(str(owner))]=combat.vec(body.pos)
 result.merge(combat.summon_points())
 if combat.adventure.arcade:
  for id in combat.adventure.game.custom_party.runtimes:
   for m in combat.adventure.game.custom_party.runtimes[id].minions:
    if float(m.hp)>0:result["c|"+str(id)+"|"+str(m.get("party_uid",""))]=m.pos
 for id in combat.morrow.units:result[id]=combat.vec(combat.morrow.units[id].pos)
 for owner in combat.pact.allies:result["bond:"+str(owner)]=combat.vec(combat.pact.allies[owner].pos)
 return result
func target_position(id:String)->Vector2:
 if id.begins_with("c|") and combat.adventure.arcade:return combat.adventure.game.custom_party.minion_actor(id).get("pos",Vector2.ZERO)
 if id.begins_with("summon:"):return combat.summon_body(id).get("pos",Vector2.ZERO)
 if id.begins_with("risen:"):return combat.morrow.actor(id).get("pos",Vector2.ZERO)
 if id.begins_with("bond:"):return combat.pact.ally_actor(id).get("pos",Vector2.ZERO)
 if is_mirror(id):return mirror_actor(id).get("pos",Vector2.ZERO)
 return combat.adventure.points().get(id,Vector2.ZERO)
func hurt_copy(owner:String,amount:float,source:String="enemy")->void:
 if not combat.adventure.authoritative() or not copies.has(owner):return
 var body:Dictionary=copies[owner]
 if bool(body.get("transferred",false)):
  if combat.adventure.arcade:combat.adventure.game._hurt(owner,amount,source)
  else:combat.adventure.game.take_player_damage(amount)
  return
 body.hp=maxf(0,float(body.hp)-amount)
 pulses.append({"pos":body.pos,"radius":27,"time":.3,"color":"#c1e3ef"})
 if float(body.hp)<=0:copies.erase(owner)
func rescue(owner:String)->bool:
 if not copies.has(owner):return false
 var body:Dictionary=copies[owner]
 if float(body.hp)<=0 or float(body.time)<=0 or bool(body.get("transferred",false)):return false
 body.transferred=true;body.time=0
 if combat.adventure.arcade:combat.adventure.game.health[owner]=maxi(1,int(body.hp))
 else:combat.adventure.game.health=float(body.hp)
 combat.adventure.teleport(owner,combat.vec(body.pos))
 var key:String=combat.player_key(owner);var echo_key:String=combat.player_key(mirror_id(owner))
 combat.statuses[key]=combat.statuses.get(echo_key,{}).duplicate(true);combat.statuses.erase(echo_key)
 pulses.append({"pos":body.pos,"radius":65,"time":.6,"color":"#d8f3f9"})
 combat.adventure.announce("The reflection survives • Twin Self")
 return true
func enemy_to_copy(owner:String,source:String)->bool:
 return source=="enemy" or combat.adventure.arcade and combat.adventure.game.mode=="arena" and combat.adventure.game._rival(owner,source)
func catch_copy(start:Vector2,end:Vector2,source:String,amount:float)->bool:
 if combat.catch_summon(start,end,source,amount):return true
 if combat.morrow.catch_shot(start,end,source,amount):return true
 if combat.pact.catch_ally(start,end,source,amount):return true
 for owner in copies.keys():
  var body:Dictionary=copies[owner]
  if bool(body.get("transferred",false)) or not enemy_to_copy(str(owner),source):continue
  var point:Vector2=combat.vec(body.pos)
  if Geometry2D.get_closest_point_to_segment(point,start,end).distance_to(point)<25 and combat.path_clear(start,point):hurt_copy(str(owner),amount,source);return true
 return false
func clone_blast(center:Vector2,radius:float,source:String,amount:float)->void:
 for id in combat.summon_points():
  var body:Dictionary=combat.summon_body(str(id))
  if combat.summon_enemy_to(str(id),source) and center.distance_to(body.pos)<=radius and combat.path_clear(center,body.pos):combat.summon_hurt(str(id),amount,source)
 combat.morrow.blast(center,radius,source,amount)
 combat.pact.blast_allies(center,radius,source,amount)
 for owner in copies.keys():
  var body:Dictionary=copies[owner]
  if not bool(body.get("transferred",false)) and enemy_to_copy(str(owner),source) and center.distance_to(combat.vec(body.pos))<=radius and combat.path_clear(center,combat.vec(body.pos)):hurt_copy(str(owner),amount,source)
func spear(owner:String,origin:Vector2,aim:Vector2,damage:float,reach:float=460)->void:
 combat.launch_projectile(owner,origin+aim*22,aim,{"range":reach,"speed":480,"pierce":2,"amplitude":0,"wavelength":180,"color":"#c9ecf1","mirror_shard":true},damage,"corkscrew_key")
func comet(owner:String,origin:Vector2,aim:Vector2,damage:float,replay:bool=false)->void:
 combat.launch_projectile(owner,origin+aim*24,aim,{"range":1200,"speed":300,"amplitude":18,"wavelength":180,"color":"#e8d393","lantern_comet":true,"chronicle_echo":replay},damage,"weaving")
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:String=str(stats.get("style",""))
 if style not in ["facet_spear","prism_fold","twin_self","lantern_comet","compass_turn","walking_chronicle"]:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 aim=aim.normalized()
 if aim.is_zero_approx():aim=Vector2.RIGHT
 var origin:Vector2=combat.owner_pos(owner)
 match style:
  "facet_spear":
   spear(owner,origin,aim,amount)
   if copies.has(owner) and not copies[owner].get("transferred",false):spear(owner,combat.vec(copies[owner].pos),aim,amount*.6)
  "prism_fold":
   make_fold(owner,origin,aim,amount)
   if copies.has(owner) and not copies[owner].get("transferred",false):make_fold(owner,combat.vec(copies[owner].pos),aim,amount*.6)
  "twin_self":
   if not copies.has(owner):
    var point:Vector2=combat.chain.clip(origin,aim.orthogonal(),90)
    copies[owner]={"owner":owner,"pos":combat.point_array(point),"hp":maxf(1,minf(66,current_hp(owner)*.6)),"max_hp":maxf(1,minf(66,current_hp(owner)*.6)),"time":6.0,"last_owner":combat.point_array(origin),"walking":false,"melee":{},"transferred":false}
  "lantern_comet":
   comet(owner,origin,aim,amount)
   var history:Array=chronicles.get(owner,[]);history.append({"pos":combat.point_array(origin),"aim":combat.point_array(aim),"damage":amount})
   while history.size()>4:history.pop_front()
   chronicles[owner]=history
  "compass_turn":
   var found:=false
   for shot in combat.projectiles:
    if str(shot.owner)!=owner or not bool(shot.stats.get("lantern_comet",false)):continue
    shot.stats["element"]=element(owner);shot.color="#a5d17f" if element(owner)=="earth" else "#ff9c50"
    shot.speed=0;turns.append({"shot":shot,"owner":owner,"aim":combat.point_array(aim),"time":.25});found=true
   if not found:
    comet(owner,origin,aim,amount)
    if not combat.projectiles.is_empty():combat.projectiles[-1].stats["element"]=element(owner);combat.projectiles[-1].color="#a5d17f" if element(owner)=="earth" else "#ff9c50"
   if combat.passive(owner,"trailkeeper"):combat.apply_status(combat.player_key(owner),"rune_stride",1,owner)
  "walking_chronicle":
   var history:Array=chronicles.get(owner,[]).duplicate(true)
   if history.is_empty():
    for n in 4:history.append({"pos":combat.point_array(origin),"aim":combat.point_array(aim),"damage":26})
   if switches.has(owner):return true
   switches[owner]=maxf(0,(history.size()-1)*.25)+.01
   for n in history.size():
    if replays.size()<24:replays.append({"owner":owner,"pos":history[n].pos,"aim":history[n].aim,"damage":float(history[n].damage)*.65,"time":n*.25})
 return true
func current_hp(owner:String)->float:return float(combat.adventure.game.health.get(owner,0)) if combat.adventure.arcade else float(combat.adventure.game.health)
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 for list in [ghosts,pulses]:
  for n in range(list.size()-1,-1,-1):
   list[n].time-=delta
   if float(list[n].time)<=0:list.remove_at(n)
 for owner in combat.adventure.points():
  if not combat.adventure.alive(str(owner)) or not combat.passive(str(owner),"overload"):overload.erase(owner);continue
  overload[owner]=float(overload.get(owner,6))-delta
  if float(overload[owner])<=0:
   overload[owner]=float(overload[owner])+6
   var origin:Vector2=combat.owner_pos(str(owner))
   pulses.append({"pos":combat.point_array(origin),"radius":145,"time":.65,"color":"#be80ed"})
   for key in combat.hostile(str(owner)):
    var target:Dictionary=combat.actor(key)
    if not target.is_empty() and target.alive and origin.distance_to(target.pos)<=145 and combat.path_clear(origin,target.pos):combat.apply_status(key,"poison",4,str(owner),3)
 for owner in copies.keys():
  var body:Dictionary=copies[owner];body.time-=delta
  if float(body.time)<=0 or not combat.adventure.alive(str(owner)):copies.erase(owner);continue
  var owner_point:Vector2=combat.owner_pos(str(owner))
  var movement:Vector2=owner_point-combat.vec(body.get("last_owner",combat.point_array(owner_point)))
  body.last_owner=combat.point_array(owner_point);body.walking=movement.length_squared()>.01
  var origin:Vector2=combat.vec(body.pos)
  if not combat.stunned(combat.player_key(mirror_id(str(owner)))) and not movement.is_zero_approx():
   origin=combat.chain.clip(origin,movement.normalized(),movement.length()*minf(1,combat.speed_factor(combat.player_key(mirror_id(str(owner))))));body.pos=combat.point_array(origin)
  for foe in combat.adventure.foes():
   if origin.distance_to(foe.pos)>65 or not combat.path_clear(origin,foe.pos):continue
   var definition:Dictionary=(combat.adventure.game.enemy_defs if combat.adventure.arcade else combat.adventure.game.enemy_types).get(str(foe.type),{})
   if str(definition.get("behaviour","melee")) in ["ranged","homing","dual_ranged","burst_ranged","summoner"] or combat.stunned(combat.npc_key(foe)):continue
   var token:String=str(foe.uid);body.melee[token]=float(body.melee.get(token,0))-delta
   if float(body.melee[token])<=0:body.melee[token]=1.2;hurt_copy(str(owner),float(definition.get("damage",12)))
 for n in range(folds.size()-1,-1,-1):
  var fold:Dictionary=folds[n];fold.time-=delta
  if not combat.adventure.alive(str(fold.owner)):folds.remove_at(n);continue
  if float(fold.time)<=0 and not bool(fold.hit):
   fold.hit=true
   for key in combat.hostile(str(fold.owner)):
    var target:Dictionary=combat.actor(key)
    if target.is_empty() or not target.alive:continue
    for arm in fold.arms:
     var start:Vector2=combat.vec(arm[0]);var end:Vector2=combat.vec(arm[1])
     if Geometry2D.get_closest_point_to_segment(target.pos,start,end).distance_to(target.pos)<25 and combat.path_clear(start,target.pos):
      combat.damage(key,float(fold.damage),str(fold.owner))
      if combat.passive(str(fold.owner),"clear_sight"):combat.apply_status(key,"slow",2,str(fold.owner),.6)
      break
  if float(fold.time)<=-.3:folds.remove_at(n)
 for n in range(turns.size()-1,-1,-1):
  var turn:Dictionary=turns[n];turn.time-=delta
  if float(turn.time)>0:continue
  if combat.projectiles.has(turn.shot):
   var shot:Dictionary=turn.shot;shot.speed=300;shot.aim=turn.aim;shot.base_aim=turn.aim;shot.origin=shot.pos;shot.range=maxf(0,float(shot.range)-float(shot.distance));shot.distance=0
  turns.remove_at(n)
 for n in range(replays.size()-1,-1,-1):
  var replay:Dictionary=replays[n];replay.time-=delta
  if float(replay.time)>0:continue
  if combat.adventure.alive(str(replay.owner)) and combat.adventure.can_stand(combat.vec(replay.pos)):
   comet(str(replay.owner),combat.vec(replay.pos),combat.vec(replay.aim),float(replay.damage),true)
   ghosts.append({"pos":replay.pos,"time":.8,"owner":replay.owner})
  replays.remove_at(n)
 for owner in switches.keys():
  switches[owner]=float(switches[owner])-delta
  if float(switches[owner])<=0:
   if combat.adventure.alive(str(owner)):elements[owner]="fire" if element(str(owner))=="earth" else "earth"
   switches.erase(owner)
 step_gardens(delta)
func snapshot()->Dictionary:return {"copies":copies,"folds":folds,"ghosts":ghosts,"pulses":pulses,"elements":elements,"gardens":gardens}
func receive(data:Dictionary)->void:copies=data.get("copies",{});folds=data.get("folds",[]);ghosts=data.get("ghosts",[]);pulses=data.get("pulses",[]);elements=data.get("elements",{});gardens=data.get("gardens",[])
func mirror_pose(owner:String,body:Dictionary)->String:
 var game:Node=combat.adventure.game
 var clock:float=game.visual_time if combat.adventure.arcade else game.visual_clock
 var attacking:bool=Time.get_ticks_msec()<int(game.attack_pose_until.get(owner,0)) if combat.adventure.arcade else game.attack_pose_time>0
 return "attack" if attacking else ("walk1" if int(clock*7)%2==0 else "walk2") if bool(body.get("walking",false)) else "idle"
func draw_on(c:Node2D,camera:Vector2)->void:
 for owner in copies:
  var body:Dictionary=copies[owner]
  if bool(body.get("transferred",false)):continue
  var point:Vector2=combat.vec(body.pos)-camera
  if combat.adventure.arcade:
   var game:Node=combat.adventure.game
   var drawn:Vector2=game.local_pos if str(owner)==str(game.my_id) else game.remote_draw_pos.get(owner,combat.owner_pos(str(owner)))
   point+=drawn-combat.owner_pos(str(owner))
  var art:Texture2D=combat.adventure.game.art.get("caelum_"+mirror_pose(str(owner),body))
  if combat.adventure.arcade:c.draw_ellipse_shadow(point)
  if art!=null:c.draw_texture_rect(art,Rect2(point-Vector2(28,42),Vector2(56,64)),false,Color.WHITE)
  if combat.adventure.arcade:
   var game:Node=combat.adventure.game
   var cosmetic:Dictionary=game.player_cosmetics.get(owner,{"title":str(game.journey.data.get("title","Traveler"))} if str(owner)==str(game.my_id) else {})
   if not cosmetic.is_empty():c.draw_string(ThemeDB.fallback_font,point+Vector2(-35,-70),str(cosmetic.get("title","")),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#ddcba3"))
   var player_name:="Player"
   for player in game.roster:
    if str(player.get("id",""))==str(owner):player_name=str(player.get("name","Player"));break
   c.draw_string(ThemeDB.fallback_font,point+Vector2(-28,-50),player_name+" L"+str(game.levels.get(owner,1)),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color.WHITE)
   c.draw_rect(Rect2(point+Vector2(-24,26),Vector2(48*clampf(float(body.hp)/maxf(1,float(game._max_hp(str(owner)))*.6),0,1),4)),Color("#83dda0"))
  else:
   var game:Node=combat.adventure.game
   c.draw_string(ThemeDB.fallback_font,point+Vector2(-40,-58),str(game.journey.data.get("title","Traveler")),HORIZONTAL_ALIGNMENT_LEFT,-1,12,game.journey.ribbon())
 draw_gardens(c,camera)
 for owner in combat.adventure.points():
  var game:Node=combat.adventure.game
  var hero_id:String=str(game.hero_ids.get(owner,"")) if combat.adventure.arcade else str(game.selected_character)
  if hero_id!="wanderlight":continue
  if combat.adventure.arcade and str(owner)!=str(game.my_id):continue
  var tint:Color=Color("#a8d585") if element(str(owner))=="earth" else Color("#ff9c50")
  c.draw_string(ThemeDB.fallback_font,Vector2(22,164),"LANTERN • "+element(str(owner)).to_upper()+"   |   Special switches element",HORIZONTAL_ALIGNMENT_LEFT,-1,15,tint)
 for fold in folds:
  for arm in fold.arms:
   var start:Vector2=combat.vec(arm[0])-camera;var end:Vector2=combat.vec(arm[1])-camera
   c.draw_line(start,end,Color(.75,.9,1,.85 if fold.hit else .25),8 if fold.hit else 2,true)
   c.draw_colored_polygon(PackedVector2Array([start+Vector2(0,-15),start+Vector2(9,0),start+Vector2(0,15),start+Vector2(-9,0)]),Color("#d7ebef"))
 for ghost in ghosts:
  var image:Texture2D=combat.adventure.game.art.get("wanderlight_attack",combat.adventure.game.art.get("wanderlight_0"))
  if image!=null:c.draw_texture_rect(image,Rect2(combat.vec(ghost.pos)-camera-Vector2(28,42),Vector2(56,64)),false,Color(1,.9,.6,float(ghost.time)*.6))
 for pulse in pulses:
  var point:Vector2=combat.vec(pulse.pos)-camera;var tint:=Color(str(pulse.color));var progress:float=1-clampf(float(pulse.time)/.65,0,1)
  c.draw_circle(point,float(pulse.radius)*progress,Color(tint,.09));c.draw_arc(point,maxf(1,float(pulse.radius)*progress),0,TAU,48,Color(tint,.7),3,true)

func rival_id(id:String)->String:
 if id.begins_with("c|") and id.split("|").size()==3:return id.split("|")[1]
 if id.begins_with("summon:"):return str(combat.summon_body(id).get("owner",""))
 if id.begins_with("risen:"):return combat.morrow.owner_of(id)
 return id.trim_prefix("mirror:").trim_prefix("bond:")

func element(owner:String)->String:return str(elements.get(owner,"earth"))
func make_fold(owner:String,origin:Vector2,aim:Vector2,amount:float)->void:
 var arms:Array=[]
 for sign in [-1,1]:
  var start:Vector2=combat.chain.clip(combat.chain.clip(origin,aim,110),aim.orthogonal()*sign,80)
  var end:Vector2=combat.chain.clip(origin,aim,300)+aim.orthogonal()*(-sign)*70
  if not combat.path_clear(start,end):end=combat.chain.clip(start,(end-start).normalized(),start.distance_to(end))
  arms.append([combat.point_array(start),combat.point_array(end)])
 if folds.size()<16:folds.append({"owner":owner,"arms":arms,"time":.65,"flash":.3,"damage":amount,"hit":false})
func impact(shot:Dictionary,center:Vector2)->void:
 var kind:String=str(shot.stats.get("element",""))
 if kind not in ["earth","fire"]:return
 var owner:String=str(shot.owner)
 for key in combat.hostile(owner):
  var target:Dictionary=combat.actor(key)
  if target.is_empty() or not target.alive or center.distance_to(target.pos)>85 or not combat.path_clear(center,target.pos):continue
  combat.damage(key,12 if kind=="earth" else 20,owner)
  combat.apply_status(key,"poison" if kind=="earth" else "burn",4,owner,2 if kind=="earth" else 3)
 var count:=0
 for patch in gardens:
  if str(patch.owner)==owner:count+=1
 if count>=6:
  for n in gardens.size():
   if str(gardens[n].owner)==owner:gardens.remove_at(n);break
 gardens.append({"owner":owner,"element":kind,"pos":combat.point_array(center),"time":10.0 if kind=="earth" else 8.0,"age":0.0})
 pulses.append({"pos":combat.point_array(center),"radius":85,"time":.65,"color":"#b5d77d" if kind=="earth" else "#ff9b50"})
func step_gardens(delta:float)->void:
 for n in range(gardens.size()-1,-1,-1):
  var patch:Dictionary=gardens[n];patch.time-=delta;patch.age+=delta
  if float(patch.time)<=0:gardens.remove_at(n);continue
  var center:Vector2=combat.vec(patch.pos)
  if str(patch.element)=="earth" and float(patch.age)<2:continue
  for key in combat.hostile(str(patch.owner)):
   var target:Dictionary=combat.actor(key)
   if target.is_empty() or not target.alive or center.distance_to(target.pos)>85 or not combat.path_clear(center,target.pos):continue
   if str(patch.element)=="earth":combat.apply_status(key,"slow",1.2,str(patch.owner),.55)
   else:combat.apply_status(key,"burn",4,str(patch.owner),3)
func draw_gardens(c:Node2D,camera:Vector2)->void:
 var clock:float=Time.get_ticks_msec()/1000.0
 for patch in gardens:
  var point:Vector2=combat.vec(patch.pos)-camera;var earth:bool=str(patch.element)=="earth"
  var tint:Color=Color("#719b55") if earth else Color("#f36a35")
  c.draw_circle(point,85,Color(tint,.17));c.draw_arc(point,85,0,TAU,48,Color(tint,.65),2,true)
  for n in 10:
   var ray:Vector2=Vector2.from_angle(TAU*n/10);var seed:Vector2=point+ray*(25+(n%3)*18)
   if earth:
    c.draw_circle(seed,3,Color("#dcc493"))
    if float(patch.age)>=2:
     var grow:float=minf(1,(float(patch.age)-2)*2)
     var tip:Vector2=seed+Vector2(sin(clock*2+n)*4,-18)*grow
     c.draw_line(seed,tip,Color("#aad177"),3,true);c.draw_line(tip,tip+Vector2(7,-4),Color("#aad177"),2,true)
     c.draw_line(seed,point+ray*78,Color(.55,.72,.32,.65),2,true)
   else:
    var lift:float=8+sin(clock*7+n)*5
    c.draw_colored_polygon(PackedVector2Array([seed+Vector2(-5,3),seed+Vector2(2,-lift),seed+Vector2(6,3)]),Color("#ffb34e",.8))
    c.draw_arc(seed,10+sin(clock*4+n)*3,0,PI,10,Color("#ffc55c",.6),2,true)
