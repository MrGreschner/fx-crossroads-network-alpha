extends Node
var combat:Node
var trees:Array=[]
var flashes:Array=[]
var hops:Dictionary={}
var puddles:Array=[]
var brews:Array=[]
var armour:Dictionary={}
const STYLES=["beaver_bite","tail_slap","timber_fall","tea_shot","tumble_pour","bitter_bloom"]
func reset()->void:trees.clear();flashes.clear();hops.clear();puddles.clear();brews.clear();armour.clear()
func moving(owner:String)->bool:return hops.has(owner)
func visual_offset(owner:String)->Vector2:
 if not hops.has(owner):return Vector2.ZERO
 return Vector2(0,-sin(fmod(float(hops[owner].elapsed),.3)/.3*PI)*25)
func defence(owner:String)->float:return minf(.2,armour.get(owner,{}).size()*.02) if combat.passive(owner,"alder_armour") and combat.adventure.alive(owner) else 0
func cast(owner:String,stats:Dictionary,aim:Vector2,amount:float)->bool:
 var style:=str(stats.get("style",""))
 if style not in STYLES:return false
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return true
 aim=aim.normalized()
 if aim.is_zero_approx():aim=Vector2.RIGHT
 var origin:Vector2=combat.owner_pos(owner)
 match style:
  "beaver_bite","tail_slap":
   var reach:=90.0 if style=="beaver_bite" else 120.0
   if style=="beaver_bite":
    var bite:Dictionary={"owner":owner,"pos":combat.point_array(origin),"aim":combat.point_array(aim),"style":style,"time":.24,"damage":amount,"hits":[]}
    flashes.append(bite);bite_contact(bite);return true
   for key in combat.hostile(owner):
    var target:Dictionary=combat.actor(key)
    if target.is_empty() or not target.get("alive",false):continue
    var offset:Vector2=target.pos-origin
    if offset.length()>reach or offset.normalized().dot(aim)<(.7 if style=="beaver_bite" else .25) or not combat.path_clear(origin,target.pos):continue
    combat.damage(key,amount,owner)
    if style=="tail_slap":stun_target(owner,key,float(stats.get("stun_duration",1.2)));combat.knock(key,aim,float(stats.get("knockback",80)))
   flashes.append({"owner":owner,"pos":combat.point_array(origin),"aim":combat.point_array(aim),"style":style,"time":.35})
  "timber_fall":
   if trees.size()<8:trees.append({"owner":owner,"pos":combat.point_array(origin),"end":combat.point_array(combat.chain.clip(origin,aim,380)),"elapsed":0.0,"hit":false,"damage":amount})
  "tea_shot":
   for sign in [-1,1]:
    var shot:Dictionary=stats.duplicate(true);shot.color="#b2d774";shot.poison_duration=4;shot.poison_damage=1;shot.tea_drop=true;shot.curve=.32
    if str(stats.get("tea_element","poison"))=="burn":shot.erase("poison_duration");shot.erase("poison_damage");shot.burn_duration=4;shot.burn_damage=1;shot.color="#ffa264"
    combat.launch_projectile(owner,origin+aim*22,aim.rotated(sign*.13),shot,amount*.5,"spiral_shot")
    if not combat.projectiles.is_empty():combat.projectiles[-1].curve=-sign*.32;combat.projectiles[-1].radius=8.0
  "tumble_pour":
   if not hops.has(owner):hops[owner]={"owner":owner,"start":combat.point_array(origin),"end":combat.point_array(combat.chain.clip(origin,aim,240)),"elapsed":0.0,"phase":0,"hit":[],"healed":0,"damage":amount}
  "bitter_bloom":
   if brews.size()<8:brews.append({"owner":owner,"pos":combat.point_array(combat.chain.clip(origin,aim,220)),"elapsed":0.0,"damage":amount})
 return true
func stun_target(owner:String,key:String,duration:float)->void:
 var target:Dictionary=combat.actor(key)
 if target.is_empty() or not target.get("alive",false):return
 combat.apply_status(key,"stun",duration,owner)
 if combat.effect_time(key,"stun")>0 and combat.passive(owner,"alder_armour"):
  var stacks:Dictionary=armour.get(owner,{})
  if stacks.has(key) or stacks.size()<10:stacks[key]=8.0
  armour[owner]=stacks
func landing(entry:Dictionary,point:Vector2)->void:
 var owner:=str(entry.owner)
 puddles.append({"owner":owner,"pos":combat.point_array(point),"time":3.0,"tick":0.0})
 if puddles.size()>36:puddles.pop_front()
 for key in combat.hostile(owner):
  var target:Dictionary=combat.actor(key)
  if target.is_empty() or not target.get("alive",false) or target.pos.distance_to(point)>75 or not combat.path_clear(point,target.pos):continue
  if key not in entry.hit:
   if combat.passive(owner,"fresh_pour") and combat.effect_time(key,"poison")>0 and int(entry.healed)<6:combat.classics.heal(owner,2);entry.healed+=2
   entry.hit.append(key);combat.damage(key,float(entry.damage),owner)
  combat.apply_status(key,"poison",3,owner,1)
func area(owner:String,point:Vector2,radius:float,amount:float)->void:
 for key in combat.hostile(owner):
  var target:Dictionary=combat.actor(key)
  if target.is_empty() or not target.get("alive",false) or target.pos.distance_to(point)>radius or not combat.path_clear(point,target.pos):continue
  if amount>0:combat.damage(key,amount,owner)
  combat.apply_status(key,"poison",4,owner,2 if amount>0 else 1)
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 for owner in armour.keys():
  if not combat.adventure.alive(owner):armour.erase(owner);continue
  for key in armour[owner].keys():
   armour[owner][key]-=delta
   if float(armour[owner][key])<=0:armour[owner].erase(key)
 for i in range(flashes.size()-1,-1,-1):
  if str(flashes[i].get("style",""))=="beaver_bite" and float(flashes[i].time)>.10:bite_contact(flashes[i])
  flashes[i].time-=delta
  if float(flashes[i].time)<=0:flashes.remove_at(i)
 for i in range(trees.size()-1,-1,-1):
  var tree:Dictionary=trees[i];tree.elapsed+=delta
  if not combat.adventure.alive(str(tree.owner)):trees.remove_at(i);continue
  if float(tree.elapsed)>=1.1 and not tree.hit:
   tree.hit=true
   var start:Vector2=combat.vec(tree.pos);var end:Vector2=combat.vec(tree.end)
   for key in combat.hostile(str(tree.owner)):
    var target:Dictionary=combat.actor(key)
    if target.is_empty() or not target.get("alive",false):continue
    if Geometry2D.get_closest_point_to_segment(target.pos,start,end).distance_to(target.pos)<=33 and combat.path_clear(start,target.pos):combat.damage(key,float(tree.damage),str(tree.owner));stun_target(str(tree.owner),key,1.8)
  if float(tree.elapsed)>=1.8:trees.remove_at(i)
 for owner in hops.keys():
  var hop:Dictionary=hops[owner]
  if not combat.adventure.alive(owner) or combat.stunned(combat.player_key(owner)):hops.erase(owner);continue
  hop.elapsed=minf(.9,float(hop.elapsed)+delta)
  var start:Vector2=combat.vec(hop.start);var end:Vector2=combat.vec(hop.end)
  var next:Vector2=start.lerp(end,minf(1,float(hop.elapsed)/.9))
  if not combat.path_clear(combat.owner_pos(owner),next):hops.erase(owner);continue
  combat.chain.move_owner(owner,next)
  while int(hop.phase)<3 and float(hop.elapsed)+.00001>=(int(hop.phase)+1)*.3:
   hop.phase+=1;landing(hop,start.lerp(end,float(hop.phase)/3))
  if float(hop.elapsed)+.00001>=.9:hops.erase(owner)
 for i in range(puddles.size()-1,-1,-1):
  var pool:Dictionary=puddles[i];pool.time-=delta;pool.tick-=delta
  if float(pool.tick)<=0:pool.tick=.5;area(str(pool.owner),combat.vec(pool.pos),75,0)
  if float(pool.time)<=0:puddles.remove_at(i)
 for i in range(brews.size()-1,-1,-1):
  var brew:Dictionary=brews[i];brew.elapsed+=delta
  if not combat.adventure.alive(str(brew.owner)):brews.remove_at(i);continue
  if float(brew.elapsed)>=1:
   area(str(brew.owner),combat.vec(brew.pos),150,float(brew.damage));flashes.append({"pos":brew.pos,"aim":[1,0],"style":"bloom","time":.6});brews.remove_at(i)
func snapshot()->Dictionary:return {"trees":trees,"flashes":flashes,"hops":hops,"puddles":puddles,"brews":brews,"armour":armour}
func receive(data:Dictionary)->void:trees=data.get("trees",[]);flashes=data.get("flashes",[]);hops=data.get("hops",{});puddles=data.get("puddles",[]);brews=data.get("brews",[]);armour=data.get("armour",{})
func draw_on(canvas:Node2D,camera:Vector2)->void:
 for pool in puddles:
  var point:Vector2=combat.vec(pool.pos)-camera
  canvas.draw_circle(point,75,Color(.4,.65,.2,.22));canvas.draw_arc(point,75,0,TAU,32,Color(.65,.8,.3,.55),2,true)
 for tree in trees:
  var start:Vector2=combat.vec(tree.pos)-camera;var end:Vector2=combat.vec(tree.end)-camera;var elapsed:=float(tree.elapsed)
  canvas.draw_line(start,end,Color(.8,.7,.25,.17),66,true)
  canvas.draw_line(start,end,Color(.9,.8,.3,.5),2,true)
  var progress:=clampf((elapsed-.35)/.75,0,1);progress*=progress
  var tip:=start.lerp(end,progress)+Vector2(sin(elapsed*35)*3*(1-progress),-135*(1-progress))
  preload("res://scripts/combat_art215.gd").falling_tree(canvas,start,tip,progress,clampf((1.8-elapsed)/.5,0,1))

 for brew in brews:
  var point:Vector2=combat.vec(brew.pos)-camera
  canvas.draw_arc(point,150,0,TAU,40,Color(.6,.8,.3,.4),2,true)
  canvas.draw_rect(Rect2(point-Vector2(28,20),Vector2(56,40)),Color("#e6dbc1"),true)
  canvas.draw_rect(Rect2(point+Vector2(-24,16-float(brew.elapsed)*32),Vector2(48,float(brew.elapsed)*32)),Color("#7eaa45"),true)
  canvas.draw_arc(point+Vector2(28,0),16,-PI*.5,PI*.5,12,Color("#e6dbc1"),5,true)
 for owner in hops:
  var point:Vector2=combat.owner_pos(owner)-camera;var hop:Dictionary=hops[owner];var height:=sin(fmod(float(hop.elapsed),.3)/.3*PI)*25
  canvas.draw_arc(point+Vector2(0,-height),34,-PI,0,20,Color("#b9d88e"),3,true)
  canvas.draw_circle(point+Vector2(0,22),13,Color(0,0,0,.25))
 for flash in combat.draw_effect_records("v48","flashes",flashes):
  var point:Vector2=combat.draw_effect_position("v48",flash,combat.vec(flash.pos))-camera;var aim:Vector2=combat.vec(flash.aim);var phase:=1-float(flash.time)/(.6 if flash.style=="bloom" else .35)
  if flash.style=="bloom":canvas.draw_arc(point,150*phase,0,TAU,48,Color(.65,.9,.3,1-phase),8,true)
  elif flash.style=="tail_slap":
   preload("res://scripts/combat_art215.gd").tail(canvas,point,aim,phase)
  elif flash.style=="beaver_bite":preload("res://scripts/combat_art215.gd").bite(canvas,point,aim,clampf(1-float(flash.time)/.24,0,1))

 for owner in armour:
  if defence(str(owner))<=0:continue
  var point:Vector2=combat.owner_pos(str(owner))-camera
  canvas.draw_arc(point,34,PI*.15,PI*.85,20,Color("#8fc395"),3,true)
  canvas.draw_string(ThemeDB.fallback_font,point+Vector2(-22,53),str(roundi(defence(str(owner))*100))+"% ward",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#b4ddb5"))

func bite_contact(entry:Dictionary)->void:
 var owner:String=str(entry.owner)
 if not combat.adventure.alive(owner) or combat.stunned(combat.player_key(owner)):return
 var origin:Vector2=combat.owner_pos(owner);entry.pos=combat.point_array(origin)
 for key in combat.hostile(owner):
  if key in entry.hits:continue
  var f:Dictionary=combat.actor(key)
  if f.is_empty() or not bool(f.alive) or not combat.v56.cone(origin,combat.vec(entry.aim),f.pos,90,.7):continue
  entry.hits.append(key);combat.damage(key,float(entry.damage),owner)
