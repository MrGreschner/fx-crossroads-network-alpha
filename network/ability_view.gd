extends RefCounted
## Smooth received server-driven travel for the local body and camera only.
const SECONDS=.05
var starts=0
var active=false
var finishing=false
var origin=Vector2.ZERO
var target=Vector2.ZERO
var elapsed=0.0
var speed_limit=0.0
var rendered=Vector2.ZERO
func reset()->void:
 active=false;finishing=false;elapsed=0;speed_limit=0
func point(actual:Vector2)->Vector2:
 if not active:return actual
 if speed_limit>0:return rendered
 return origin.lerp(actual if finishing else target,clampf(elapsed/SECONDS,0,1))
func receive(moving:bool,drawn:Vector2,authoritative:Vector2,travel_speed:float=0)->void:
 if moving:
  if not active or finishing:starts+=1
  active=true;finishing=false;origin=drawn;rendered=drawn;target=authoritative;elapsed=0;speed_limit=travel_speed
 elif active and not finishing:
  origin=drawn;rendered=drawn;target=authoritative;finishing=true;elapsed=0
func advance(delta:float,actual:Variant=null)->void:
 elapsed+=maxf(0,delta)
 if active and speed_limit>0:
  var destination:Vector2=actual if finishing and actual is Vector2 else target
  rendered=rendered.move_toward(destination,speed_limit*maxf(0,delta))
  if finishing and elapsed>=.12 and rendered.distance_squared_to(destination)<.0001:reset()
 elif finishing and elapsed>=SECONDS:reset()
