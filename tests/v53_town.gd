extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	var life=game.town_life
	game.gold=0
	assert(not life.offer(game))
	assert(game.gold==0)
	game.gold=10
	game.loadout.assign(["potion","aegis","last_stand"])
	assert(not life.offer(game))
	assert(game.gold==10)
	game.loadout.clear()
	var winner:int=-1
	var loser:int=-1
	for seed_value in range(10000):
		life.rng.seed=seed_value
		var roll:int=life.rng.randi_range(1,100)
		if roll==1 and winner<0:winner=seed_value
		if roll!=1 and loser<0:loser=seed_value
		if winner>=0 and loser>=0:break
	assert(winner>=0)
	life.rng.seed=loser
	assert(life.offer(game))
	assert(game.gold==9 and game.loadout.is_empty())
	assert(not life.offer(game) and game.gold==9)
	life.step(.8)
	life.rng.seed=winner
	assert(life.offer(game))
	assert(game.gold==8 and game.loadout.size()==1)
	assert(game.loadout[0] in ["last_stand","aegis","heart_locket"])
	assert(not game.can_stand_at(life.WELL))
	assert(life.residents.size()==5)
	var first:Vector2=life.resident_state(0).pos
	life.step(2)
	assert(first.distance_to(life.resident_state(0).pos)>10)
	life.clock=6
	assert(life.resident_state(0).working)
	var arena:Dictionary={}
	for place in game.town_places:
		if place.menu=="arena_entrance":arena=place
	assert(not arena.is_empty())
	print("v53 town: well charging, reward, capacity, cooldown, collision, NPC routes and arena passed")
	for voice in game.journey.voices:voice.stop()
	game.queue_free()
	await create_timer(.3).timeout
	quit()
