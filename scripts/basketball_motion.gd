extends RefCounted
## Visual-only basketball gait. Ground position and collision are never changed.
var states:Dictionary={}
func step(id:String,point:Vector2,delta:float,enabled:bool)->void:
 if not enabled:states.erase(id);return
 if not states.has(id):states[id]={"point":point,"phase":0.0};return
 var state:Dictionary=states[id];var travel:float=point.distance_to(state.point);state.point=point
 if travel>180:state.phase=0.0;return # Teleports are not walking steps.
 var moving:=travel>.15
 var phase:float=float(state.phase)
 if moving or phase>0:
  phase+=minf(delta,.1)*2.6
  if phase>=1:phase=fmod(phase,1) if moving else 0.0
 state.phase=phase
func sprite_rect(id:String,point:Vector2)->Rect2:
 var phase:float=float(states.get(id,{}).get("phase",0))
 var height:=92*phase*(1-phase)
 var impact:=maxf(0,1-minf(phase,1-phase)/.1) if phase>0 else 0.0
 var stretch:=sin(phase*PI)*.035
 var size:=Vector2(46*(1+.15*impact-stretch),46*(1-.17*impact+stretch))
 return Rect2(point+Vector2(-size.x*.5,22-size.y-height),size)
