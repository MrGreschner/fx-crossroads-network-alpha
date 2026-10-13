extends RefCounted
## Utility-based spacing with pursuit, evasion, separation and obstacle feelers.
## Decisions use observed world positions, never player input or hidden cooldowns.
static func spacing(origin:Vector2,goal:Vector2,near:float,far:float,health_ratio:float,side:float)->Vector2:
 var offset:=goal-origin;var distance:=offset.length();var toward:=offset.normalized()
 var retreat:=clampf((.4-health_ratio)*3,0,1)
 var close:=clampf((near-distance)/maxf(near,1),0,1)
 var chase:=clampf((distance-far)/maxf(far*.4,1),0,1)
 if retreat>.25 and distance<far*1.5:return (-toward+toward.orthogonal()*side*.25).normalized()
 return (toward*(chase-close*2)+toward.orthogonal()*side*(.35 if distance<far+100 else .1)).normalized()
static func steer(origin:Vector2,wish:Vector2,clear:Callable,neighbours:Array,side:float=1)->Vector2:
 if wish.is_zero_approx():return wish
 var separation:=Vector2.ZERO
 for p in neighbours:
  var offset:Vector2=origin-p
  if offset.length_squared()>1 and offset.length()<75:separation+=offset.normalized()*(1-offset.length()/75)
 var desired:Vector2=(wish+separation*.9).normalized()
 var best:=Vector2.ZERO;var score:=-INF
 for angle in [0.0,.45,-.45,.9,-.9,1.5,-1.5,2.2,-2.2,PI]:
  var direction:=desired.rotated(angle*side)
  if not clear.call(origin,origin+direction*65):continue
  var value:float=direction.dot(desired)-absf(angle)*.05
  if value>score:score=value;best=direction
 return best
static func lead(origin:Vector2,target:Vector2,velocity:Vector2,speed:float)->Vector2:
 return target+velocity.limit_length(340)*minf(.6,origin.distance_to(target)/maxf(1,speed))
