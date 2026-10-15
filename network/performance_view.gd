extends RefCounted
## Local timing only; bounded samples, no gameplay changes.
const LIMIT=180
var windows:Dictionary={}
var previous_frame=0
var long_frames=0
func work(kind:String,elapsed_us:int)->void:
 if not windows.has(kind):windows[kind]=[]
 windows[kind].append(maxf(0,elapsed_us/1000.0))
 if windows[kind].size()>LIMIT:windows[kind].pop_front()
func frame(now:int)->void:
 if previous_frame>0:
  var elapsed=now-previous_frame
  work("frame_interval",elapsed)
  if elapsed>50000:long_frames+=1
 previous_frame=now
func summary()->Dictionary:
 var result={}
 for key in windows:
  var values:Array=windows[key].duplicate();values.sort()
  if not values.is_empty():result[key]={"samples":values.size(),"median_ms":values[values.size()/2],"p95_ms":values[mini(values.size()-1,int(values.size()*.95))],"max_ms":values[-1]}
 return result
