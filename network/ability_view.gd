extends RefCounted
## Smooth received server-driven travel for the local body and camera only.
const SECONDS=.05
var starts=0
var active=false
var finishing=false
var origin=Vector2.ZERO
var target=Vector2.ZERO
var elapsed=0.0
func reset()->void:
 active=false;finishing=false;elapsed=0
func point(actual:Vector2)->Vector2:
 if not active:return actual
 return origin.lerp(actual if finishing else target,clampf(elapsed/SECONDS,0,1))
func receive(moving:bool,drawn:Vector2,authoritative:Vector2)->void:
 if moving:
  if not active or finishing:starts+=1
  active=true;finishing=false;origin=drawn;target=authoritative;elapsed=0
 elif active and not finishing:
  origin=drawn;finishing=true;elapsed=0
func advance(delta:float)->void:
 elapsed+=maxf(0,delta)
 if finishing and elapsed>=SECONDS:reset()
