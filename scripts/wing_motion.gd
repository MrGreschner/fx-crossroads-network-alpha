extends RefCounted
## Visual flight keeps ground position, speed and collision unchanged.
var states:Dictionary={}
func step(id:String,point:Vector2,delta:float,enabled:bool)->void:
 if not enabled:states.erase(id);return
 var state:Dictionary=states.get(id,{"point":point,"phase":0.0,"moving":false})
 state.moving=point.distance_to(state.point)>.15;state.point=point;state.phase=float(state.phase)+minf(delta,.1);states[id]=state
func sprite_rect(id:String,point:Vector2)->Rect2:
 var state:Dictionary=states.get(id,{})
 var phase:float=float(state.get("phase",0));var moving:bool=bool(state.get("moving",false))
 var height:float=8+sin(phase*TAU*1.3)*(5 if moving else 2)
 var width:float=56*(1+.09*sin(phase*TAU*(4 if moving else 2)))
 return Rect2(point+Vector2(-width*.5,-42-height),Vector2(width,64))
