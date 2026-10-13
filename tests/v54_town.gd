extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var scenery=game.town_scenery
	assert(not game.can_stand_at(scenery.POND))
	assert(not game.can_stand_at(scenery.CAMP))
	assert(not game.can_stand_at(scenery.TOWER))
	for place in game.town_places:
		assert(not scenery.blocked(place.pos),"Scenery obstructs entrance "+str(place.menu))
	assert(not scenery.blocked(Vector2(900,320)),"North gate route blocked")
	for index in scenery.routes.size():
		var origin:Vector2=scenery.guard_position(index)
		scenery.step(1)
		assert(scenery.guard_position(index).distance_to(origin)>1,"Guard does not patrol")
		for second in range(120):
			scenery.clock=float(second)
			assert(game.can_stand_at(scenery.guard_position(index)),"Guard patrol crosses obstacle")
	for hero in ["ram","book","cat"]:
		var walk:Texture2D=load("res://assets/"+hero+"_walk1.png")
		var attack:Texture2D=load("res://assets/"+hero+"_attack.png")
		assert(walk.get_size()==attack.get_size())
	print("v54 town: entrance clearance, patrol routes, scenery collision and sprite sizes passed")
	for voice in game.journey.voices:voice.stop()
	game.queue_free();await create_timer(.3).timeout;quit()
