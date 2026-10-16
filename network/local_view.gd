extends RefCounted
## Draw between completed prediction ticks; never change collision/input state.
var previous=Vector2.ZERO
var current=Vector2.ZERO
var ready=false
var correction=Vector2.ZERO
const REPAIR_SECONDS=.09
func reset(point:Vector2)->void:
 previous=point;current=point;ready=true;correction=Vector2.ZERO
func reconcile(before:Vector2,after:Vector2,snap:bool=false)->void:
 # Prediction takes the complete repair immediately. Only the drawing retains
 # the old location, so another snapshot cannot replay a partially fixed state.
 if snap or not ready:
  reset(after);return
 var shift=after-before
 previous+=shift;current+=shift;correction-=shift
 if correction.length()>80:reset(after)
func advance(delta:float)->void:
 correction*=exp(-maxf(0,delta)/REPAIR_SECONDS)
 if correction.length()<.05:correction=Vector2.ZERO
func capture(before:Vector2,after:Vector2)->void:
 previous=before;current=after;ready=true
 if before.distance_to(after)>80:previous=after
func point(actual:Vector2,fraction:float)->Vector2:
 # Respawns/authoritative teleports can arrive between physics ticks.
 if not ready or actual.distance_squared_to(current)>.0001:return actual
 return previous.lerp(current,clampf(fraction,0,1))+correction
