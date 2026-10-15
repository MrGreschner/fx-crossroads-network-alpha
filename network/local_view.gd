extends RefCounted
## Draw between completed prediction ticks; never change collision/input state.
var previous=Vector2.ZERO
var current=Vector2.ZERO
var ready=false
func reset(point:Vector2)->void:
 previous=point;current=point;ready=true
func capture(before:Vector2,after:Vector2)->void:
 previous=before;current=after;ready=true
 if before.distance_to(after)>80:previous=after
func point(actual:Vector2,fraction:float)->Vector2:
 # Respawns/authoritative teleports can arrive between physics ticks.
 if not ready or actual.distance_squared_to(current)>.0001:return actual
 return previous.lerp(current,clampf(fraction,0,1))
