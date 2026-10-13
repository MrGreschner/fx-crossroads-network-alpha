extends SceneTree
func _initialize()->void:
	var gait=preload("res://scripts/skating_motion.gd").new()
	for step in [1.0/60,1.0/30,0.137]:
		gait.clock=0
		var total:float=0
		var remaining:float=6
		while remaining>0.000001:
			var dt:float=minf(step,remaining)
			gait.advance(dt)
			total+=gait.travel_time
			remaining-=dt
		assert(absf(total-6)<0.00001,"Average travel changed")
	gait.clock=0
	gait.advance(0.36)
	assert(absf(gait.travel_time-0.6)<0.00001,"Slide must be fast")
	gait.advance(0.12)
	assert(absf(gait.travel_time)<0.00001,"Braking must stop")
	# Input release does not reset clock: repressing during braking stays stopped.
	gait.advance(0.06)
	assert(absf(gait.travel_time)<0.00001)
	gait.advance(0.12)
	assert(absf(gait.travel_time-0.1)<0.00001,"Frame crossing must integrate both phases")
	print("v52 skating cadence and frame-rate balance passed")
	quit()
