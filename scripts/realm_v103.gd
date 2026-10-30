extends Node
var adventure:Node
var warnings:Array=[]
var clock:=0.0
const TYPES=["crease_sentry","lunar_usher"]
func setup()->void:warnings.clear();clock=0
func step(delta:float)->void:
 clock+=delta
 if not adventure.authoritative():return
 var combat=adventure.combat
 for enemy in adventure.foes():
  if str(enemy.type) not in TYPES or combat.stunned(combat.npc_key(enemy)):continue
  var goal:=Vector2.ZERO;var distance:=INF
  for id in adventure.points():
   if adventure.alive(str(id)) and enemy.pos.distance_squared_to(adventure.points()[id])<distance:goal=adventure.points()[id];distance=enemy.pos.distance_squared_to(goal)
  if is_inf(distance):continue
  goal=combat.fern.redirect(enemy,goal);distance=enemy.pos.distance_squared_to(goal)
  if distance>850*850:continue
  var aim:Vector2=(goal-enemy.pos).normalized();var move:Vector2=combat.ranged_direction(enemy,goal)*95*delta*combat.speed_factor(combat.npc_key(enemy))
  if adventure.can_stand(enemy.pos+move) and combat.path_clear(enemy.pos,enemy.pos+move):enemy.pos+=move
  else:
   var turn:Vector2=move.rotated(PI*.5)
   if adventure.can_stand(enemy.pos+turn) and combat.path_clear(enemy.pos,enemy.pos+turn):enemy.pos+=turn
  enemy.v103_timer=float(enemy.get("v103_timer",1.8))-delta
  if float(enemy.v103_timer)>0:continue
  enemy.v103_timer=3.3
  preload("res://scripts/enemy_visual227.gd").mark(adventure,enemy,.65)
  var origin:Vector2=enemy.pos
  if enemy.type=="crease_sentry":
   for side in [-1,1]:combat.launch_projectile("enemy",origin+aim.orthogonal()*side*22,aim,{"range":800,"speed":230,"amplitude":36,"wavelength":220,"color":"#93dcca"},10,"weaving")
  elif warnings.size()<12:warnings.append({"pos":[goal.x,goal.y],"left":1.1,"source":combat.npc_key(enemy)})
 for i in range(warnings.size()-1,-1,-1):
  var warning:Dictionary=warnings[i];warning.left=float(warning.left)-delta
  if float(warning.left)>0:continue
  warnings.remove_at(i)
  if combat.actor(str(warning.source)).is_empty():continue
  var point:=Vector2(warning.pos[0],warning.pos[1])
  for key in combat.hostile("enemy"):
   var actor:Dictionary=combat.actor(str(key))
   if not actor.is_empty() and point.distance_to(actor.pos)<95:combat.damage(str(key),14,"enemy");combat.apply_status(str(key),"slow",1.8,"enemy",.65)
  for n in 6:combat.launch_projectile("enemy",point,Vector2.from_angle(n*TAU/6),{"range":400,"speed":190,"color":"#cbb4f2"},6)
func snapshot()->Dictionary:return {"warnings":warnings,"clock":clock}
func receive(value:Dictionary)->void:warnings=value.get("warnings",[]);clock=float(value.get("clock",clock))
func draw_on(canvas:Node2D,camera:Vector2)->void:
 if not adventure.combat.playing():return
 for warning in warnings:preload("res://scripts/combat_cues.gd").danger(canvas,Vector2(warning.pos[0],warning.pos[1])-camera,95,float(warning.left),1.1,Color("#cbb4f2"))
