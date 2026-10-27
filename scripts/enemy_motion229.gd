extends RefCounted
## Local presentation state only. Sample world positions, never camera offsets.
## Survives replacement of co-op dictionaries without adding network traffic.
const STOP_DELAY=.12
var tracks:Dictionary={}
var sampled_at:float=-1.0

func sample(foes:Array,clock:float)->void:
 if clock==sampled_at:return
 if clock<sampled_at:tracks.clear()
 sampled_at=clock
 var live:Dictionary={}
 for foe in foes:
  var uid=int(foe.get("uid",0));live[uid]=true
  var point:Vector2=foe.pos
  if not tracks.has(uid):
   tracks[uid]={"pos":point,"moved_at":-INF,"distance":0.0};continue
  var track:Dictionary=tracks[uid]
  var distance:float=point.distance_to(track.pos)
  track.pos=point
  # Discontinuous relocation is not a running step.
  if distance>200:
   track.moved_at=-INF;track.distance=0.0
  elif distance>.001:
   track.moved_at=clock;track.distance=float(track.distance)+distance
 for uid in tracks.keys():
  if not live.has(uid):tracks.erase(uid)

func locomotion(foe:Dictionary)->String:
 var track:Dictionary=tracks.get(int(foe.get("uid",0)),{})
 if track.is_empty() or sampled_at-float(track.moved_at)>=STOP_DELAY:return "idle"
 var stride:float=20.0 if bool(foe.get("boss",false)) else 12.0
 return "walk1" if int(float(track.distance)/stride)%2==0 else "walk2"
