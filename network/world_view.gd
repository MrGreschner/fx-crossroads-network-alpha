extends RefCounted
## One monotonic server-time buffer for all remote presentation.
## Arrival jitter changes buffer occupancy, not individual entity velocity.
const DELAY=.10
const LIMIT=24
var snapshots:Array=[]
var render_time=-1.0
var latest_time=0.0
var underruns=0
var clock_resyncs=0
var max_backlog=0.0
var last_tick=-1
var target_delay=DELAY
var delay_goal=DELAY
var arrival_age=0.0
var last_arrival=-1.0
var arrival_gaps:Array=[]
var jitter_samples:Array=[]
var playback_rate=1.0
var pair_time=-INF
var pair_tick=-1
var pair_cache:Array=[]
func clear()->void:
 snapshots.clear();render_time=-1.0;latest_time=0;last_tick=-1;underruns=0;clock_resyncs=0;max_backlog=0
 pair_time=-INF;pair_tick=-1;pair_cache=[]
 target_delay=DELAY;delay_goal=DELAY;arrival_age=0;last_arrival=-1;arrival_gaps.clear();jitter_samples.clear();playback_rate=1
func receive(data:Dictionary,received_at:float=-1)->void:
 var tick=int(data.server_tick)
 if tick<=last_tick:return
 var now=received_at if received_at>=0 else Time.get_ticks_usec()/1000000.0
 if last_arrival>=0:
  var gap=maxf(0,now-last_arrival)
  arrival_gaps.append(gap)
  jitter_samples.append(maxf(0,gap-(tick-last_tick)/60.0))
  while arrival_gaps.size()>64:arrival_gaps.pop_front();jitter_samples.pop_front()
  if jitter_samples.size()>=8:
   var ordered=jitter_samples.duplicate();ordered.sort()
   delay_goal=clampf(DELAY+float(ordered[mini(ordered.size()-1,int(ordered.size()*.95))]),DELAY,.18)
 last_arrival=now;arrival_age=0
 last_tick=tick;latest_time=tick/60.0
 snapshots.append({"t":latest_time,"data":data})
 while snapshots.size()>LIMIT:snapshots.pop_front()
 if render_time<0:render_time=latest_time-DELAY
func advance(delta:float)->void:
 if snapshots.is_empty():return
 arrival_age+=maxf(0,delta)
 target_delay=move_toward(target_delay,delay_goal,maxf(0,delta)*(.12 if delay_goal>target_delay else .02))
 var occupancy=latest_time-render_time
 max_backlog=maxf(max_backlog,occupancy)
 # A suspended/throttled browser can discard seconds of delta. Do not retain
 # that delay for seconds afterwards. Skip obsolete visual history once;
 # all remote actors, shots and effects still use this ONE monotonic clock.
 if occupancy>maxf(.30,target_delay+.20):
  render_time=maxf(render_time,latest_time-target_delay);clock_resyncs+=1
  return
 # Compensate for time between arrivals; packet cadence must not repeatedly
 # accelerate/decelerate playback. Small drift correction has a dead band.
 var desired=latest_time+minf(arrival_age,.1)-target_delay
 var error=desired-render_time
 playback_rate=clampf(1+error*.5,.95,1.05) if absf(error)>.015 else 1.0
 var target=render_time+minf(delta,.1)*playback_rate
 if target>latest_time:underruns+=1
 render_time=minf(target,latest_time)
func pair()->Array:
 if snapshots.is_empty():return []
 if pair_time==render_time and pair_tick==last_tick:return pair_cache
 var before:Dictionary=snapshots[0];var after:Dictionary=before
 for snapshot in snapshots:
  if float(snapshot.t)<=render_time:before=snapshot
  if float(snapshot.t)>render_time:after=snapshot;break
  after=snapshot
 pair_time=render_time;pair_tick=last_tick;pair_cache=[before,after]
 return pair_cache
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
 for shot in a.data.get("render_shots",[]):left[shot_key(shot)]=shot
 for shot in b.data.get("render_shots",[]):right[shot_key(shot)]=shot
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

static func shot_key(shot:Dictionary)->String:
 # Built-in missiles and object-combat shots have independent ID counters.
 return ("object:" if bool(shot.get("custom",false)) else "missile:")+str(shot.get("owner",""))+":"+str(shot.get("net_id",0))

func enemy(uid:int,fallback:Vector2)->Vector2:
 var values=pair()
 if values.is_empty():return fallback
 var left={};var right={}
 for foe in values[0].data.get("enemies",[]):
  if int(foe.get("uid",0))==uid:left=foe;break
 for foe in values[1].data.get("enemies",[]):
  if int(foe.get("uid",0))==uid:right=foe;break
 if left.is_empty():return fallback
 if right.is_empty():right=left
 var p=Vector2(float(left.pos[0]),float(left.pos[1]));var q=Vector2(float(right.pos[0]),float(right.pos[1]))
 if p.distance_to(q)>160:return p
 return p.lerp(q,alpha(values[0],values[1]))
