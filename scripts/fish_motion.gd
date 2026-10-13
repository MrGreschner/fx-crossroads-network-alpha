extends RefCounted
## Visual flopping only; collision, targeting and travel speed use the ground point.
var states:Dictionary={}
func step(id:String,point:Vector2,delta:float,enabled:bool)->void:
 if not enabled:states.erase(id);return
 if not states.has(id):states[id]={"point":point,"phase":0.0};return
 var e:Dictionary=states[id];var travel:float=point.distance_to(e.point);e.point=point
 if travel>180:e.phase=0;return
 var moving:bool=travel>.15
 if moving or float(e.phase)>0:
  e.phase=float(e.phase)+minf(delta,.1)*2.5
  if float(e.phase)>=1:e.phase=fmod(float(e.phase),1) if moving else 0.0
func phase(id:String)->float:return float(states.get(id,{}).get("phase",0))
func sprite_rect(id:String,point:Vector2)->Rect2:
 var t:=phase(id);var hop:=sin(t*PI)*14
 var squash:=maxf(0,1-t/.12) if t>0 else 0.0
 var size:=Vector2(64*(1+.1*squash),56*(1-.12*squash))
 return Rect2(point+Vector2(-size.x*.5,20-size.y-hop),size)
func angle(id:String)->float:return sin(phase(id)*TAU)*.22
