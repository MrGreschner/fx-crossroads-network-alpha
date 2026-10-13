extends RefCounted
## Presentation only. Collision, damage and authoritative positions stay separate.
const LIMIT=6
var tracks:Dictionary={}
var stale_packets:=0
func clear()->void:tracks.clear();stale_packets=0
func erase(id:String)->void:tracks.erase(id)
func push(id:String,p:Vector2,stamp:float,teleport:bool=false)->void:
 if not is_finite(p.x) or not is_finite(p.y):return
 var samples:Array=tracks.get(id,[])
 if not samples.is_empty():
  var last:Dictionary=samples.back()
  if stamp<=float(last.t):return
  if teleport or p.distance_to(last.p)>320:samples.clear()
 samples.append({"p":p,"t":stamp})
 while samples.size()>LIMIT:samples.pop_front()
 tracks[id]=samples
func sample(id:String,fallback:Vector2,stamp:float,delay:float=.075)->Vector2:
 var samples:Array=tracks.get(id,[])
 if samples.is_empty():return fallback
 var target:=stamp-delay
 if samples.size()==1 or target<=float(samples[0].t):return samples[0].p
 for i in range(1,samples.size()):
  var a:Dictionary=samples[i-1];var b:Dictionary=samples[i]
  if target<=float(b.t):return (a.p as Vector2).lerp(b.p,clampf((target-float(a.t))/maxf(.001,float(b.t)-float(a.t)),0,1))
 # Brief, bounded extrapolation hides one late movement packet; then hold.
 var last:Dictionary=samples.back();var before:Dictionary=samples[-2]
 var velocity:Vector2=((last.p as Vector2)-(before.p as Vector2))/maxf(.001,float(last.t)-float(before.t))
 return (last.p as Vector2)+velocity.limit_length(800)*clampf(target-float(last.t),0,.04)
func prune(active:Dictionary)->void:
 for id in tracks.keys():
  if not active.has(id):tracks.erase(id)
