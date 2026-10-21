extends Node
## One travelling ball, host-owned impacts, at most five different targets.
var combat:Node
var balls:Array=[]
func choose(owner:String,origin:Vector2,focus:Vector2,stats:Dictionary,hits:Array)->String:
 var best:="";var nearest:float=145 if hits.is_empty() else float(stats.get("jump_range",180))
 for key in combat.hostile(owner):
  if hits.has(key):continue
  var body:Dictionary=combat.actor(key)
  if body.is_empty() or not body.alive:continue
  if hits.is_empty() and origin.distance_to(body.pos)>float(stats.get("range",440)):continue
  var distance:float=focus.distance_to(body.pos)
  if distance<nearest and combat.path_clear(origin,body.pos):nearest=distance;best=key
 return best
func launch(owner:String,origin:Vector2,focus:Vector2,stats:Dictionary,amount:float)->void:
 if not combat.adventure.authoritative() or not combat.adventure.alive(owner):return
 var target:=choose(owner,origin,focus,stats,[])
 if target.is_empty():return
 if balls.size()>=16:balls.pop_front()
 balls.append({"owner":owner,"pos":combat.point_array(origin),"aim":[1,0],"target":target,"hits":[],"stats":stats.duplicate(true),"damage":amount,"life":4.0})
func step(delta:float)->void:
 if not combat.adventure.authoritative():return
 for ball in balls.duplicate():
  ball.life=float(ball.life)-delta
  if float(ball.life)<=0 or not combat.adventure.alive(str(ball.owner)):balls.erase(ball);continue
  var body:Dictionary=combat.actor(str(ball.target))
  if body.is_empty() or not body.alive:balls.erase(ball);continue
  var origin:Vector2=combat.vec(ball.pos);var destination:Vector2=body.pos
  var heading:Vector2=origin.direction_to(destination);var next:Vector2=origin.move_toward(destination,820*delta)
  if not combat.path_clear(origin,next):balls.erase(ball);continue
  if combat.v56.catch_travelling(origin,next,str(ball.owner),float(ball.damage),"#f5f4df",{"golf_ball":true}):balls.erase(ball);continue
  ball.pos=combat.point_array(next);ball.aim=combat.point_array(heading)
  if next.distance_to(destination)>8:continue
  combat.damage(str(ball.target),float(ball.damage),str(ball.owner),"Course Ricochet")
  ball.hits.append(str(ball.target))
  if ball.hits.size()>=mini(5,int(ball.stats.get("jumps",5))):balls.erase(ball);continue
  var target:=choose(str(ball.owner),destination,destination,ball.stats,ball.hits)
  if target.is_empty():balls.erase(ball);continue
  ball.target=target;ball.damage=float(ball.damage)*.8
func draw_on(canvas:Node2D,camera:Vector2)->void:
 for ball in balls:
  preload("res://scripts/hero_visuals1984.gd").ball(canvas,combat.vec(ball.pos)-camera,combat.vec(ball.aim))
