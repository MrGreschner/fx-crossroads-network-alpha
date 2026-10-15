extends RefCounted
## Animation uses the same buffered positions that the player sees.
const HOLD=.10
var clock=0.0
var tracks:Dictionary={}
func clear()->void:
 clock=0;tracks.clear()
func advance(delta:float)->void:
 clock+=maxf(0,delta)
func sample(id:String,point:Vector2)->void:
 if not tracks.has(id):
  tracks[id]={"point":point,"until":-1.0};return
 var track:Dictionary=tracks[id]
 var distance=point.distance_to(track.point)
 track.point=point
 if distance>160:track.until=-1.0 # Teleports/spawns do not trigger walking.
 elif distance>.15:track.until=clock+HOLD
func walking(id:String)->bool:
 return clock<float(tracks.get(id,{}).get("until",-1.0))
func prune(ids:Array)->void:
 for id in tracks.keys():
  if id not in ids:tracks.erase(id)
