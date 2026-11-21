extends RefCounted

const BRACE_TIME=4.5
const TREE_TIME=7.2
const REACH=180.0
const CONE_COS=.866
var stance:Dictionary={}
var trees:Dictionary={}
var ornaments:Array=[]
var flashes:Array=[]
var rng:=RandomNumberGenerator.new()

func reset()->void:
 stance.clear();trees.clear();ornaments.clear();flashes.clear()

func strike(combat:Node,id:String,origin:Vector2,aim:Vector2,reach:float,damage:float)->void:
 var tip:Vector2=combat.v75.clip(origin,aim,reach)
 for key in combat.hostile(id,origin,reach+18):
  var actor:Dictionary=combat.actor(key)
  if not actor.get("alive",false):continue
  var offset:Vector2=actor.pos-origin
  if offset.dot(aim)<0 or offset.dot(aim)>reach:continue
  if Geometry2D.get_closest_point_to_segment(actor.pos,origin,tip).distance_to(actor.pos)<=17 and combat.path_clear(origin,actor.pos):
   combat.damage(key,damage,id,"Spear Jab")
 flashes.append({"from":[origin.x,origin.y],"to":[tip.x,tip.y],"owner":id,"time":.23,"jab":true})

func step(combat:Node,events:Node,delta:float)->void:
 for id in stance.keys():
  var state:Dictionary=stance[id]
  state.time-=delta
  if state.time<=0 or not combat.adventure.alive(id):
   stance.erase(id)
   continue
  var game:Node=combat.adventure.game
  var target:float=float(game.aim_angles.get(id,state.angle)) if combat.adventure.arcade else game.raw_aim_direction().angle()
  if combat.adventure.arcade and id==game.my_id:
   var direction:Vector2=game.mobile.aim if game.mobile.enabled else game.media_mouse_world()-game.local_pos
   if direction.length_squared()>.01:target=direction.angle()
  state.angle=rotate_toward(float(state.angle),target,delta*2.7)
 for id in trees.keys():
  var tree:Dictionary=trees[id]
  tree.time-=delta
  if tree.time<=0 or not combat.adventure.alive(id):
   trees.erase(id)
   continue
  var p:Vector2=combat.vec(tree.pos)
  tree.light=maxf(0,float(tree.light)-delta)
  tree.pulse-=delta
  tree.roll-=delta
  if tree.pulse<=0:
   tree.pulse+=.9
   tree.light=.34
   tree.angle+=.42
   for ally in combat.party_heroes.friendly_near(id,p,REACH):
    var offset:Vector2=combat.owner_pos(str(ally))-p
    if offset.length()<20 or in_beam(offset,float(tree.angle)):
     combat.release_heroes.heal(id,str(ally),5)
  if tree.roll<=0:
   tree.roll+=.78
   if ornaments.size()<48:
    ornaments.append({"owner":id,"pos":tree.pos,"angle":rng.randf_range(0,TAU),"time":1.4,"damage":tree.damage})
 for i in range(ornaments.size()-1,-1,-1):
  var orb:Dictionary=ornaments[i]
  orb.time-=delta
  if orb.time<=0 or not combat.adventure.alive(orb.owner):
   ornaments.remove_at(i)
   continue
  var p:Vector2=combat.vec(orb.pos)
  var end:=p+Vector2.from_angle(float(orb.angle))*145*delta
  if not combat.path_clear(p,end):
   ornaments.remove_at(i)
   continue
  orb.pos=[end.x,end.y]
  for key in combat.hostile(orb.owner,p,22+p.distance_to(end)):
   var foe:Dictionary=combat.actor(key)
   if not foe.get("alive",false) or not combat.path_clear(p,foe.pos):continue
   if Geometry2D.get_closest_point_to_segment(foe.pos,p,end).distance_to(foe.pos)>19:continue
   events.area(orb.owner,end,54,float(orb.damage))
   flashes.append({"to":orb.pos,"time":.24})
   ornaments.remove_at(i)
   break
 for i in range(flashes.size()-1,-1,-1):
  flashes[i].time-=delta
  if flashes[i].time<=0:flashes.remove_at(i)

func in_beam(offset:Vector2,angle:float)->bool:
 for n in 4:
  if offset.normalized().dot(Vector2.from_angle(angle+n*TAU/4))>=CONE_COS:return true
 return false

func draw_on(canvas:Node2D,camera:Vector2,combat:Node)->void:
 for id in stance:
  var origin:Vector2=combat.owner_pos(id)-camera
  var angle:float=stance[id].angle
  canvas.draw_arc(origin,24,angle-1.0,angle+1.0,14,Color("#d5ac71"),2)
  canvas.draw_line(origin+Vector2.from_angle(angle)*25,origin+Vector2.from_angle(angle)*37,Color("#e9c68b"),2)
  for x in [-8,8]:canvas.draw_line(origin+Vector2(x-4,5),origin+Vector2(x+4,5),Color("#9e9b7a"),3)
  var game:Node=combat.adventure.game
  var local=not combat.adventure.arcade or str(id)==str(game.my_id)
  if local:
   var reach=112.0*1.4
   var tip=origin+Vector2.from_angle(angle)*reach
   canvas.draw_line(origin+Vector2.from_angle(angle)*40,tip,Color(.76,.82,.7,.34),1)
   canvas.draw_arc(tip,5,0,TAU,12,Color("#b3c7b5"),1)
   var seconds=combat.events.display_time(float(stance[id].time))
   canvas.draw_style_box(preload("res://scripts/event_hero_visuals375.gd").plate(),Rect2(origin+Vector2(-84,-102),Vector2(168,22)))
   canvas.draw_string(ThemeDB.fallback_font,origin+Vector2(-80,-86),"STAND FAST • %.1fs" % seconds,HORIZONTAL_ALIGNMENT_CENTER,160,12,Color("#e9c68b"))
 for tree in trees.values():
  var p:Vector2=combat.vec(tree.pos)-camera
  if tree.light>0:
   for i in 4:
    var angle:float=tree.angle+i*TAU/4
    var cone:=PackedVector2Array([p])
    for n in 7:cone.append(p+Vector2.from_angle(angle+lerpf(-PI/6,PI/6,n/6.0))*REACH)
    canvas.draw_colored_polygon(cone,Color(1,.84,.52,.18))
  canvas.draw_rect(Rect2(p+Vector2(-5,-10),Vector2(10,13)),Color("#785447"))
  for i in 3:
   var center:=p-Vector2(0,10+i*12)
   var width:=26-i*6
   canvas.draw_colored_polygon(PackedVector2Array([center+Vector2(-width,0),center+Vector2(0,-28),center+Vector2(width,0)]),Color(["#28594d","#347564","#4a896b"][i]))
   canvas.draw_rect(Rect2(center+Vector2(width*.45-2,-5),Vector2(4,4)),Color("#d88c6f"))
   canvas.draw_rect(Rect2(center+Vector2(-width*.52,-6),Vector2(4,4)),Color("#f3cf80"))
  canvas.draw_rect(Rect2(p+Vector2(-3,-65),Vector2(6,6)),Color("#ffe9a4"))
 for orb in ornaments:
  var p:Vector2=combat.vec(orb.pos)-camera
  canvas.draw_circle(p,8,Color("#9d484d"))
  canvas.draw_arc(p,5,float(orb.angle)+float(orb.time)*12,float(orb.angle)+float(orb.time)*12+2.0,8,Color("#f0ba74"),2)
 for flash in flashes:
  var p:Vector2=combat.vec(flash.to)-camera
  if flash.get("jab",false):
   var start:Vector2=combat.vec(flash.from)-camera
   canvas.draw_line(start,p,Color("#a77c59"),5)
   canvas.draw_line(p.move_toward(start,19),p,Color("#ffe3a9"),4)
  else:
   canvas.draw_arc(p,54*(1-float(flash.time)/.30),0,TAU,24,Color("#efb275"),3)

func snapshot()->Dictionary:
 return {"stance":stance,"trees":trees,"ornaments":ornaments,"flashes":flashes}

func receive(data:Dictionary)->void:
 stance=data.get("stance",{});trees=data.get("trees",{});ornaments=data.get("ornaments",[]);flashes=data.get("flashes",[])
