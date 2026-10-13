extends RefCounted
# Integrated travel time keeps the cadence balanced even at low frame rates.
const PERIOD:float=0.6
const SLIDE:float=0.36
var clock:float=0.0
var travel_time:float=0.0
var tracks:Dictionary={}

func distance_clock(t:float)->float:
	return floor(t/PERIOD)*PERIOD+minf(fposmod(t,PERIOD),SLIDE)*(PERIOD/SLIDE)

func advance(delta:float)->void:
	travel_time=distance_clock(clock+delta)-distance_clock(clock)
	clock+=delta

func sample(id:String,point:Vector2,delta:float,enabled:bool)->void:
	if not enabled:
		tracks.erase(id)
		return
	var state:Dictionary=tracks.get(id,{"point":point,"direction":Vector2.RIGHT,"trail":0.0})
	var offset:Vector2=point-state["point"]
	state["point"]=point
	state["trail"]=maxf(0.0,float(state["trail"])-delta)
	if offset.length()>0.2 and offset.length()<180:
		state["direction"]=offset.normalized()
		state["trail"]=0.16
	tracks[id]=state

func draw_skates(canvas:CanvasItem,id:String,point:Vector2)->void:
	if not tracks.has(id):return
	var state:Dictionary=tracks[id]
	var strength:float=float(state["trail"])/0.16
	if strength<=0:return
	var direction:Vector2=state["direction"]
	var side:Vector2=direction.orthogonal()*5
	var foot:Vector2=point+Vector2(0,19)
	for sign_value in [-1,1]:
		var skate:Vector2=foot+side*sign_value
		canvas.draw_line(skate-direction*22,skate,Color(0.65,0.92,1.0,strength*0.6),2,true)
		canvas.draw_circle(skate-direction*25,2,Color(0.9,0.98,1.0,strength*0.65))
