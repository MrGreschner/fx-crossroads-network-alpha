extends RefCounted
## A real object used by Battle Test. Each agent owns its cooldowns and decisions.
const Behavior=preload("res://scripts/studio_behavior.gd")
var definition:Dictionary
var body:Dictionary
var brain:Dictionary
var cooldowns={"primary":0.0,"secondary":0.0,"special":0.0}
var guarded=false
var elapsed=0.0
var heading=Vector2.ZERO
func setup(enemy:Dictionary,target_body:Dictionary)->void:
 definition=enemy.duplicate(true);body=target_body;brain=Behavior.compile(definition.behavior.program,"enemy")
func update(delta:float,target:Vector2)->Array:
 elapsed+=delta;guarded=false;heading=Vector2.ZERO
 for slot in cooldowns:cooldowns[slot]=maxf(0,cooldowns[slot]-delta)
 if body.hp<=0 or body.stun>0:return []
 var offset:Vector2=target-body.pos;var distance=offset.length();var context={"distance":distance,"health":float(body.hp)/float(definition.health)*100,"time":elapsed,"charged":0,"targets":1,"cycle":fmod(elapsed,6.0)}
 var decisions=Behavior.evaluate(brain,context);var attacks:Array=[]
 for action in decisions:
  if action.command=="move":
   match action.value:
    "chase":heading=offset.normalized()
    "retreat":heading=-offset.normalized()
    "orbit":heading=offset.normalized().rotated(PI*.5)
    "patrol":heading=Vector2(cos(elapsed*.8),sin(elapsed*.8))
    "hold":heading=Vector2.ZERO
  elif action.command=="guard":guarded=true
  elif action.command=="use":
   var slots=["primary","secondary","special"]
   if slots.find(action.value)>=int(definition.get("attack_count",2)) or not definition.has(action.value):continue
   var attack:Dictionary=definition[action.value]
   if cooldowns[action.value]<=0 and distance<=float(attack.range)+20:
    attacks.append({"slot":action.value,"ability":attack.duplicate(true)});cooldowns[action.value]=float(attack.cooldown)
 return attacks
