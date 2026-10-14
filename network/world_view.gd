extends RefCounted
## One monotonic server-time buffer for all remote presentation.
## Arrival jitter changes buffer occupancy, not individual entity velocity.
const DELAY=.10
const LIMIT=24
var snapshots:Array=[]
var render_time=-1.0
var latest_time=0.0
var underruns=0
var last_tick=-1
func clear()->void:
 snapshots.clear();render_time=-1.0;latest_time=0;last_tick=-1;underruns=0
func receive(data:Dictionary)->void:
 var tick=int(data.server_tick)
 if tick<=last_tick:return
 last_tick=tick;latest_time=tick/60.0
 snapshots.append({"t":latest_time,"data":data})
 while snapshots.size()>LIMIT:snapshots.pop_front()
 if render_time<0:render_time=latest_time-DELAY
func advance(delta:float)->void:
 if snapshots.is_empty():return
 var occupancy=latest_time-render_time
 # Smooth clock correction. Do not reset the clock to packet arrival time.
 var rate=clampf(1+(occupancy-DELAY)*2,.90,1.10)
 var target=render_time+minf(delta,.1)*rate
 if target>latest_time:underruns+=1
 render_time=minf(target,latest_time)
func pair()->Array:
 if snapshots.is_empty():return []
 var before:Dictionary=snapshots[0];var after:Dictionary=before
 for snapshot in snapshots:
  if float(snapshot.t)<=render_time:before=snapshot
  if float(snapshot.t)>render_time:after=snapshot;break
  after=snapshot
 return [before,after]
func alpha(a:Dictionary,b:Dictionary)->float:
 return clampf((render_time-float(a.t))/maxf(.0001,float(b.t)-float(a.t)),0,1)
func player(id:String,fallback:Vector2)->Vector2:
 var values=pair()
 if values.is_empty():return fallback
 var a:Dictionary=values[0];var b:Dictionary=values[1]
 var left:Dictionary=a.data.get("players",{}).get(id,{})
 var right:Dictionary=b.data.get("players",{}).get(id,left)
 if left.is_empty():return fallback
 var p=Vector2(float(left.pos[0]),float(left.pos[1]));var q=Vector2(float(right.pos[0]),float(right.pos[1]))
 if p.distance_to(q)>160:return q if render_time>=float(b.t) else p
 return p.lerp(q,alpha(a,b))
func data()->Dictionary:
 var values=pair()
 return values[0].data if not values.is_empty() else {}
func shots()->Array:
 var values=pair()
 if values.is_empty():return []
 var a:Dictionary=values[0];var b:Dictionary=values[1]
 var left={};var right={};var result:Array=[]
 for shot in a.data.get("render_shots",[]):left[str(shot.net_id)]=shot
 for shot in b.data.get("render_shots",[]):right[str(shot.net_id)]=shot
 # Include births from the next snapshot, but only once their actual launch time
 # reaches the shared render clock. Backtrace to the transmitted spawn position.
 var keys=left.keys()
 for key in right:
  if not left.has(key):keys.append(key)
 for key in keys:
  var shot:Dictionary=left.get(key,right.get(key,{}))
  var born=float(shot.get("born",float(a.t)))
  if render_time<born:continue
  var p=Vector2(float(shot.pos[0]),float(shot.pos[1]))
  var v=Vector2(float(shot.velocity[0]),float(shot.velocity[1]))
  if left.has(key) and right.has(key):
   var next:Dictionary=right[key];var q=Vector2(float(next.pos[0]),float(next.pos[1]));p=p.lerp(q,alpha(a,b))
  elif not left.has(key):
   p+=v*(render_time-float(b.t))
  elif render_time>=float(b.t) and not right.has(key):continue
  else:p+=v*maxf(0,render_time-float(a.t))
  var copy=shot.duplicate();copy.draw_pos=p;result.append(copy)
 return result
