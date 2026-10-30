extends Node
## Corpse summons are independent allies, never encounter enemies or extra XP sources.
var combat:Node
var corpses:Array=[]
var units:Dictionary={}
var links:Dictionary={}
var flashes:Array=[]
var serial:=0
var clock:=0.0
var direct_owner:=""
const STYLES=["gravespark","raise_remains","life_lattice","last_procession"]
func reset()->void:
 corpses.clear();units.clear();links.clear();flashes.clear();serial=0;clock=0;direct_owner=""
func actor(id:String)->Dictionary:
 if not units.has(id):return {}
 return {"pos":combat.vec(units[id].pos),"alive":float(units[id].hp)>0,"player":id,"hit_radius":18.0*(1+.18*(int(units[id].get("weight",1))-1))}
func owner_of(id:String)->String:return str(units.get(id,{}).get("owner",""))
func enemy_to(id:String,source:String)->bool:
 var owner:=owner_of(id)
 return not owner.is_empty() and (source=="enemy" or combat.adventure.arcade and combat.adventure.game.mode in ["arena","battlegrounds"] and combat.adventure.game._rival(source,owner))
func owned(owner:String)->Array:
 return units.keys().filter(func(id):return str(units[id].owner)==owner and float(units[id].hp)>0)
func current_hp(owner:String)->float:
 if owner=="training_ally" and not combat.adventure.arcade:return combat.adventure.game.training_yard.ally_health
 return float(combat.adventure.game.health.get(owner,0)) if combat.adventure.arcade else float(combat.adventure.game.health)
func max_hp(owner:String)->float:
 if owner=="training_ally":return 200
 return float(combat.adventure.game._max_hp(owner)) if combat.adventure.arcade else float(combat.adventure.game.max_health())
func set_hp(owner:String,value:float)->void:
 if owner=="training_ally" and not combat.adventure.arcade:combat.adventure.game.training_yard.ally_health=clampf(value,1,200);return
 if combat.adventure.arcade:combat.adventure.game.health[owner]=maxi(0,int(value))
 else:combat.adventure.game.health=value
func fallen(foe:Dictionary)->void:
 if not combat.adventure.authoritative() or bool(foe.get("boss",false)) or bool(foe.get("converted",false)) or bool(foe.get("summoned",false)) or str(foe.get("type","")).begins_with("training_"):return
 var relevant:=false
 for owner in combat.adventure.points():
  if combat.v78.hero(str(owner))=="morrow":relevant=true;break
 if not relevant:return
 var defs:Dictionary=combat.adventure.game.enemy_defs if combat.adventure.arcade else combat.adventure.game.enemy_types
 var sprite:=str(foe.get("corpse_sprite",defs.get(str(foe.get("type","")),{}).get("sprite","bramble")))
 if corpses.size()>=24:corpses.pop_front()
 corpses.append({"pos":combat.point_array(foe.pos),"sprite":sprite,"time":25.0})
func slots(owner:String,stats:Dictionary)->Array:
 var result:Array=[];var counts={"melee":0,"ranged":0,"healer":0}
 for id in owned(owner):
  var body:Dictionary=units[id];var kind="healer" if bool(body.get("healer",false)) else "ranged" if bool(body.ranged) else "melee";counts[kind]+=1
 for n in maxi(0,3-int(counts.melee)):result.append("melee")
 if combat.passive(owner,"grave_chorus"):
  var kind="healer" if bool(stats.get("healer_vigil",false)) else "ranged"
  for n in maxi(0,(1 if kind=="healer" else 2)-int(counts[kind])):result.append(kind)
 return result
func prepare(owner:String,stats:Dictionary,aim:Vector2)->bool:
 var style:=str(stats.get("style",""))
 if style=="life_lattice" or style=="last_procession":
  if owned(owner).is_empty():combat.adventure.announce("Raise fallen enemies before using this special.");return false
 if style!="raise_remains":return true
 var vacancies=slots(owner,stats);var cap=owned(owner).size()+vacancies.size()
 if owned(owner).size()>=cap:combat.adventure.announce("Your echo companions are already at full strength.");return false
 var p:Vector2=combat.v79.destination(owner,aim,float(stats.get("range",420)))
 if not combat.adventure.arcade and combat.adventure.game.practice and corpses.is_empty():
  for n in cap:corpses.append({"pos":combat.point_array(combat.v75.clip(p,Vector2.from_angle(n*TAU/cap),28)),"sprite":"bramble","time":25.0})
 for corpse in corpses:
  if p.distance_to(combat.vec(corpse.pos))<=float(stats.get("radius",200)) and combat.path_clear(p,combat.vec(corpse.pos)):return true
 combat.adventure.announce("Aim Raise Remains at the small grave markers left by fallen enemies.");return false
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 var origin:Vector2=combat.owner_pos(owner)
 if combat.passive(owner,"grave_chorus"):
  for id in owned(owner):
   if not units[id].has("family") and float(units[id].max_hp)==42.0:units[id].hp=float(units[id].hp)/42.0*60.0;units[id].max_hp=60.0
 match style:
  "gravespark":combat.launch_projectile(owner,origin+aim*20,aim,{"range":float(stats.get("range",430)),"speed":360,"color":"#a9dcca"},amount)
  "raise_remains":
   if links.has(owner):finish_link(owner)
   var target:Vector2=combat.v79.destination(owner,aim,float(stats.get("range",420)))
   var vacancies=slots(owner,stats);var cap=owned(owner).size()+vacancies.size()
   var available:Array=[]
   for corpse in corpses:
    if target.distance_to(combat.vec(corpse.pos))<=float(stats.get("radius",200)) and combat.path_clear(origin,combat.vec(corpse.pos)):available.append(corpse)
   available.sort_custom(func(a,b):return target.distance_squared_to(combat.vec(a.pos))<target.distance_squared_to(combat.vec(b.pos)))
   for corpse in available:
    var count:=owned(owner).size()
    if count>=cap:break
    var role:String=vacancies.pop_front()
    serial+=1;var id:="risen:"+str(serial);var hp:=60.0 if combat.passive(owner,"grave_chorus") else 42.0
    units[id]={"self_id":id,"owner":owner,"pos":corpse.pos,"sprite":"morrow_healer" if role=="healer" else corpse.sprite,"healer":role=="healer","hp":hp,"max_hp":hp,"time":30.0,"ranged":role!="melee","attack":.35,"contacts":{},"pose":"idle"}
    corpses.erase(corpse);flashes.append({"pos":corpse.pos,"time":.6,"radius":36})
  "life_lattice":
   if links.has(owner):finish_link(owner)
   var members:=owned(owner);var hp:=current_hp(owner);var capacity:=max_hp(owner)
   for id in members:hp+=float(units[id].hp);capacity+=float(units[id].max_hp)
   links[owner]={"members":members,"hp":hp,"max_hp":capacity,"time":7.0,"tick":0.0,"last_hp":current_hp(owner)}
   sync_link(owner)
  "last_procession":
   if links.has(owner):finish_link(owner)
   var end:Vector2=combat.v79.destination(owner,aim,float(stats.get("range",430)))
   for id in owned(owner):units[id]["march"]=combat.point_array(end);units[id]["march_time"]=2.0;units[id]["burst"]=amount
 return true
func sync_link(owner:String,set_hero:bool=true)->float:
 if not links.has(owner):return current_hp(owner)
 var link:Dictionary=links[owner];var ratio:=clampf(float(link.hp)/maxf(1,float(link.max_hp)),0,1)
 var hp:=max_hp(owner)*ratio
 if hp>0:hp=maxf(1,hp)
 for id in link.members:
  if units.has(id):units[id].hp=maxf(1,float(units[id].max_hp)*ratio) if ratio>0 else 0.0
 if set_hero:set_hp(owner,hp);link.last_hp=current_hp(owner)
 return hp
func share_hero(owner:String,amount:float)->float:
 if direct_owner==owner or not links.has(owner):return amount
 var old:=current_hp(owner);var link:Dictionary=links[owner]
 link.hp=maxf(0,float(link.hp)-maxf(0,amount));var new_hp:=sync_link(owner,false)
 var routed:=maxf(0,old-new_hp)
 link.last_hp=old-(int(routed) if combat.adventure.arcade else routed)
 return routed
func hurt(id:String,amount:float,source:String="enemy")->void:
 if not combat.adventure.authoritative() or not units.has(id) or not enemy_to(id,source):return
 var owner:=owner_of(id)
 if combat.effect_time("p:"+id,"guard")>0:amount*=1-clampf(float(combat.statuses.get("p:"+id,{}).get("guard",{}).get("value",0)),0,.8)
 if links.has(owner):
  var old:=current_hp(owner);var routed:=share_hero(owner,amount)
  if combat.adventure.arcade:combat.adventure.game._stat(source,"damage",minf(amount,float(links[owner].hp)+amount))
  if routed>0:
   direct_owner=owner
   if combat.adventure.arcade:combat.adventure.game._hurt(owner,routed,source)
   else:combat.adventure.game.take_player_damage(routed)
   direct_owner=""
  if old>0 and not combat.adventure.alive(owner):clear_owner(owner)
 else:
  var taken:float=minf(float(units[id].hp),maxf(0,amount));units[id].hp=maxf(0,float(units[id].hp)-taken)
  if combat.adventure.arcade:
   combat.adventure.game._stat(source,"damage",taken)
   if taken>0:combat.adventure.game._damage_feedback(combat.vec(units[id].pos),taken,id)
  elif taken>0:combat.feedback.hit(combat.vec(units[id].pos),taken)
  if float(units[id].hp)<=0:units.erase(id);combat.statuses.erase("p:"+id)
func clear_owner(owner:String)->void:
 links.erase(owner)
 for id in owned(owner):units.erase(id);combat.statuses.erase("p:"+id)
 # Include exhausted pool bodies (owned() deliberately excludes dead units).
 for id in units.keys():
  if str(units[id].owner)==owner:units.erase(id);combat.statuses.erase("p:"+id)
func finish_link(owner:String)->void:
 if not links.has(owner):return
 var link:Dictionary=links[owner];var remaining:=maxf(0,float(link.hp));var members:Array=[]
 for id in link.members:
  if units.has(id):members.append(id)
 var hero_part:=minf(remaining,minf(max_hp(owner),maxf(1,remaining*.6) if not members.is_empty() else remaining));remaining-=hero_part
 var capacity:=0.0
 for id in members:capacity+=float(units[id].max_hp)
 for id in members:units[id].hp=minf(float(units[id].max_hp),remaining*float(units[id].max_hp)/maxf(1,capacity))
 var overflow:=maxf(0,remaining-capacity);set_hp(owner,minf(max_hp(owner),hero_part+overflow));links.erase(owner)
 for id in members:
  if float(units[id].hp)<=0:units.erase(id)
func catch_shot(start:Vector2,end:Vector2,source:String,amount:float)->bool:
 var chosen:="";var nearest:=INF
 for id in units:
  if not enemy_to(str(id),source):continue
  var p:Vector2=combat.vec(units[id].pos);var q:=Geometry2D.get_closest_point_to_segment(p,start,end)
  if q.distance_to(p)<22 and start.distance_to(q)<nearest and combat.path_clear(start,p):chosen=str(id);nearest=start.distance_to(q)
 if chosen.is_empty():return false
 hurt(chosen,amount,source);return true
func blast(p:Vector2,r:float,source:String,amount:float)->void:
 for id in units.keys():
  if units.has(id) and p.distance_to(combat.vec(units[id].pos))<r and combat.path_clear(p,combat.vec(units[id].pos)):hurt(str(id),amount,source)
func segments(owner:String)->Array:
 var points:Array=[combat.owner_pos(owner)]
 for id in owned(owner):
  var p:Vector2=combat.vec(units[id].pos)
  if p.distance_to(points[0])<450:points.append(p)
 var result:Array=[]
 for i in points.size():
  for j in range(i+1,points.size()):
   if combat.path_clear(points[i],points[j]):result.append([points[i],points[j]])
 return result
func target_hp(key:String)->float:
 var target:Dictionary=combat.actor(key)
 if target.is_empty():return 0
 if target.has("npc"):return maxf(0,float(target.npc.hp))
 var id:=str(target.get("player",""))
 if units.has(id):return maxf(0,float(units[id].hp))
 if id.begins_with("bond:"):return maxf(0,float(combat.pact.allies.get(id.trim_prefix("bond:"),{}).get("hp",0)))
 if id.begins_with("mirror:"):return maxf(0,float(combat.v59.copies.get(id.trim_prefix("mirror:"),{}).get("hp",0)))
 return current_hp(id)
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 clock+=delta
 for list in [corpses,flashes]:
  for i in range(list.size()-1,-1,-1):
   list[i].time=float(list[i].time)-delta
   if float(list[i].time)<=0:list.remove_at(i)
 for owner in links.keys():
  if not combat.adventure.alive(str(owner)):clear_owner(str(owner));continue
  var link:Dictionary=links[owner]
  # Direct healing/food/level rewards join the pool once; redistribution is not healing.
  var gained:=maxf(0,current_hp(str(owner))-float(link.last_hp));link.hp=minf(float(link.max_hp),float(link.hp)+gained)
  link.time=float(link.time)-delta;link.tick=float(link.tick)+delta;sync_link(str(owner))
  if float(link.tick)>=.5:
   link.tick=0;var stolen:=0.0;var lines:=segments(str(owner))
   for key in combat.hostile(str(owner)):
    var target:Dictionary=combat.actor(key)
    if target.is_empty() or not bool(target.alive):continue
    for line in lines:
     if Geometry2D.get_closest_point_to_segment(target.pos,line[0],line[1]).distance_to(target.pos)<18 and combat.path_clear(line[0],target.pos):
      var before:=target_hp(key);combat.damage(key,2,str(owner));stolen+=maxf(0,before-target_hp(key));break
   var heal:=minf(3,minf(stolen,float(link.max_hp)-float(link.hp)))
   link.hp=float(link.hp)+heal
   if heal>0 and combat.adventure.arcade:combat.adventure.game._stat(str(owner),"healing",heal)
   sync_link(str(owner))
  if float(link.time)<=0:finish_link(str(owner))
 for id in units.keys():
  if not units.has(id):continue
  var body:Dictionary=units[id];var owner:=str(body.owner)
  if not combat.adventure.alive(owner):clear_owner(owner);continue
  if not links.has(owner):body.time=float(body.time)-delta
  if float(body.time)<=0:units.erase(id);continue
  var p:Vector2=combat.vec(body.pos);body.attack=float(body.attack)-delta
  if body.has("march"):
   var end:Vector2=combat.vec(body.march);body.march_time=float(body.march_time)-delta
   combat.pact.move_body(body,(end-p).normalized()*220*delta)
   if p.distance_to(end)<40 or float(body.march_time)<=0:
    combat.v75.area(owner,p,80,float(body.burst),{"slow_duration":1.5,"slow":.6});flashes.append({"pos":body.pos,"time":.6,"radius":80});units.erase(id)
   continue
  var tending:bool=bool(body.get("healer",false)) and healer_step(body,delta)
  var target:="";var best:=480.0
  for key in ([] if tending else combat.hostile(owner)):
   var foe:Dictionary=combat.actor(key)
   if not foe.is_empty() and bool(foe.alive) and p.distance_to(foe.pos)<best and combat.path_clear(p,foe.pos):target=key;best=p.distance_to(foe.pos)
  if str(body.get("family",""))=="mosaic":
   var marked:String=combat.party_heroes.preferred(owner)
   if not marked.is_empty():
    var f:Dictionary=combat.actor(marked)
    if p.distance_to(f.pos)<=900 and combat.path_clear(p,f.pos):target=marked;best=p.distance_to(f.pos)
  body.haste=maxf(0,float(body.get("haste",0))-delta)
  var destination:Vector2=combat.owner_pos(owner)+Vector2.from_angle(float(String(id).hash()%100)/100*TAU)*65
  var direction:Vector2=(destination-p).normalized() if p.distance_to(destination)>25 else Vector2.ZERO
  if float(body.get("rally_time",0))>0:
   body.rally_time=float(body.rally_time)-delta;destination=combat.vec(body.rally);direction=(destination-p).normalized() if p.distance_to(destination)>25 else Vector2.ZERO
  if not target.is_empty():
   var q:Vector2=combat.actor(target).pos;var reach:int=int(body.get("reach",250 if bool(body.ranged) else 52))
   direction=(q-p).normalized() if best>reach else -(q-p).normalized() if bool(body.ranged) and best<130 else Vector2.ZERO
   if best<=reach and float(body.attack)<=0 and not combat.stunned("p:"+str(id)):
    body.attack=float(body.get("interval",1.2))/(1.4 if float(body.get("haste",0))>0 else 1.0);body.pose="attack"
    if bool(body.ranged):combat.launch_projectile(owner,p,(q-p).normalized(),{"range":400,"speed":310,"color":"#bce6cf" if bool(body.get("healer",false)) else "#db96bb","slow_duration":2.0 if bool(body.get("healer",false)) else 0.0,"slow_factor":.8},4.0 if bool(body.get("healer",false)) else float(body.get("damage",8)))
    else:combat.damage(target,float(body.get("damage",10)),owner)
  if float(body.attack)<.9:body.pose="walk1" if int(clock*6)%2==0 else "walk2"
  # Mild separation keeps three bodies readable and their life-link lines distinct.
  for other in units:
   if other==id:continue
   var away:Vector2=p-combat.vec(units[other].pos)
   var spacing:float=42+4*(int(body.get("weight",1))+int(units[other].get("weight",1))-2)
   if away.length()<.1:away=Vector2.RIGHT if str(id)>str(other) else Vector2.LEFT
   if away.length()<spacing:direction+=away.normalized()*1.2*(1-away.length()/spacing)
  combat.pact.move_body(body,direction.limit_length(1)*float(body.get("speed",145))*(1.35 if float(body.get("haste",0))>0 else 1.0)*delta*combat.speed_factor("p:"+str(id)))
  for foe in combat.adventure.foes().duplicate():
   if not units.has(id):break
   var defs:Dictionary=combat.adventure.game.enemy_defs if combat.adventure.arcade else combat.adventure.game.enemy_types
   if combat.ranged_enemy(foe,defs.get(str(foe.type),{})) or combat.stunned(combat.npc_key(foe)):continue
   var uid:=str(foe.uid)
   if p.distance_to(foe.pos)<54 and clock>=float(body.contacts.get(uid,0)) and combat.path_clear(p,foe.pos):body.contacts[uid]=clock+1.2;hurt(str(id),float(defs.get(str(foe.type),{}).get("damage",12)),"enemy")
func snapshot()->Dictionary:return {"corpses":corpses,"units":units,"links":links,"flashes":flashes,"clock":clock}
func receive(d:Dictionary)->void:
 corpses=d.get("corpses",[]);units=d.get("units",{});links=d.get("links",{});flashes=d.get("flashes",[]);clock=float(d.get("clock",clock))
func draw_on(c:Node2D,camera:Vector2)->void:
 for corpse in corpses:
  var p:Vector2=combat.vec(corpse.pos)-camera;c.draw_circle(p,15,Color(.35,.6,.6,.16));c.draw_line(p+Vector2(-8,4),p+Vector2(8,-4),Color(.75,.85,.8,.5),3);c.draw_line(p+Vector2(-8,-4),p+Vector2(8,4),Color(.75,.85,.8,.5),3)
 for owner in links:
  for line in segments(str(owner)):c.draw_line(line[0]-camera,line[1]-camera,Color(.9,.12,.25,.2),9,true);c.draw_line(line[0]-camera,line[1]-camera,Color(1,.25,.3,.65+.2*sin(clock*7)),2,true)
  var p:Vector2=combat.owner_pos(str(owner))-camera+Vector2(-45,-68);var link:Dictionary=links[owner]
  c.draw_rect(Rect2(p,Vector2(90,6)),Color("#431e31"));c.draw_rect(Rect2(p,Vector2(90*clampf(float(link.hp)/float(link.max_hp),0,1),6)),Color("#ed777f"))
  c.draw_string(ThemeDB.fallback_font,p+Vector2(0,-5),"LINK "+str(int(ceil(float(link.time))))+"s",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#ffc7cf"))
 for id in units:
  var body:Dictionary=units[id];var p:Vector2=combat.vec(body.pos)-camera
  var texture:Texture2D=combat.adventure.game.art.get(str(body.sprite)+"_"+str(body.pose),combat.adventure.game.art.get(str(body.sprite)+"_0"))
  var updated:Texture2D=preload("res://scripts/minion_art215.gd").unit_texture(body,str(id),p)
  if updated!=null:texture=updated
  if str(body.get("family",""))!="puppet" and preload("res://scripts/actor_art248.gd").has(str(body.sprite)):texture=preload("res://scripts/actor_art248.gd").texture(str(body.sprite),str(body.pose))
  if str(body.sprite).begins_with("ds_"):texture=preload("res://scripts/descent203_art.gd").companion_texture(str(body.sprite),str(body.pose))
  if bool(body.get("healer",false)):texture=preload("res://scripts/source_art.gd").texture("res://assets/morrow_healer_"+str(body.pose)+".svg")
  c.draw_circle(p+Vector2(0,14),18,Color(0,0,0,.2));c.draw_arc(p,23,0,TAU,24,Color("#d899ca") if bool(body.ranged) else Color("#9bcdbb"),2,true)
  if texture!=null:
   var scale_factor:float=1+.18*(int(body.get("weight",1))-1);var shape:Vector2=Vector2(32,36) if str(body.sprite)=="bit_buddy" else Vector2(38,44) if str(body.get("family",""))=="puppet" else Vector2(46,52);var rect=Rect2(p-shape*Vector2(.5,.7)*scale_factor,shape*scale_factor);var art_id="morrow_healer" if bool(body.get("healer",false)) else "" if str(body.get("family",""))=="puppet" else str(body.sprite)
   if preload("res://scripts/actor_art248.gd").has(art_id):rect=preload("res://scripts/actor_art248.gd").fitted(art_id,rect)
   c.draw_texture_rect(texture,rect,false,Color.WHITE if body.has("family") else Color(.68,.85,.78,.85))
   if int(body.get("weight",1))>1:c.draw_string(ThemeDB.fallback_font,p+Vector2(-6,-53),"×"+str(body.weight),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#ebc9fa"))
  else:
   c.draw_circle(p-Vector2(0,15),9,Color("#d6dbba"));c.draw_rect(Rect2(p-Vector2(10,5),Vector2(20,24)),Color("#718b81"))
  if bool(body.get("healer",false)):
   c.draw_line(p+Vector2(12,-18),p+Vector2(26,-18),Color("#c5f2cd"),4);c.draw_line(p+Vector2(19,-25),p+Vector2(19,-11),Color("#c5f2cd"),4)
  if bool(body.ranged):c.draw_arc(p+Vector2(18,-8),15,-PI*.5,PI*.5,12,Color("#e7b3da"),2)
  c.draw_rect(Rect2(p+Vector2(-22,-43),Vector2(44,4)),Color("#263c38"));c.draw_rect(Rect2(p+Vector2(-22,-43),Vector2(44*clampf(float(body.hp)/float(body.max_hp),0,1),4)),Color("#a3dfc8"))
 for f in flashes:c.draw_arc(combat.vec(f.pos)-camera,float(f.radius)*(1-float(f.time)),0,TAU,24,Color(.75,.9,.8,float(f.time)),3,true)

func healer_step(body:Dictionary,_delta:float)->bool:
 var owner=str(body.owner);var p=combat.vec(body.pos);var chosen="";var lowest=.9
 for friend in combat.adventure.points():
  if not combat.adventure.alive(str(friend)) or not combat.v75.friendly(owner,str(friend)):continue
  var at:Vector2=combat.owner_pos(str(friend));var fraction=current_hp(str(friend))/maxf(1,max_hp(str(friend)))
  if fraction<lowest and p.distance_to(at)<230 and combat.path_clear(p,at):lowest=fraction;chosen="p:"+str(friend)
 for id in units:
  var unit:Dictionary=units[id];var fraction=float(unit.hp)/maxf(1,float(unit.max_hp))
  if fraction<lowest and combat.v75.friendly(owner,str(unit.owner)) and p.distance_to(combat.vec(unit.pos))<230 and combat.path_clear(p,combat.vec(unit.pos)):lowest=fraction;chosen=str(id)
 if chosen.is_empty():return false
 if float(body.attack)<=0 and not combat.stunned("p:"+str(body.get("self_id",""))):
  body.attack=1.5;body.pose="attack";var at:Vector2=p
  var recipient=chosen.substr(2) if chosen.begins_with("p:") else str(units[chosen].owner)
  var amount=6.0
  if links.has(recipient):links[recipient].hp=minf(float(links[recipient].max_hp),float(links[recipient].hp)+amount);sync_link(recipient)
  elif chosen.begins_with("p:"):amount=minf(6,max_hp(recipient)-current_hp(recipient));set_hp(recipient,current_hp(recipient)+amount)
  else:amount=minf(6,float(units[chosen].max_hp)-float(units[chosen].hp));units[chosen].hp=float(units[chosen].hp)+amount
  at=combat.owner_pos(recipient) if chosen.begins_with("p:") else combat.vec(units[chosen].pos)
  flashes.append({"pos":combat.point_array(at),"time":.5,"radius":22})
  if combat.adventure.arcade:combat.adventure.game._stat(owner,"healing",amount)
 return true
