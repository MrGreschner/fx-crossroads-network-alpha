extends Node
var players: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var last_play: Dictionary = {}
func _ready() -> void:
	for name in ["swing","shot","flame","hit","hurt","reward"]:
		sounds[name] = load("res://assets/audio/"+name+".wav")
	for i in 5:
		var player := AudioStreamPlayer.new()
		player.volume_db = -15
		add_child(player)
		players.append(player)
func cue(name: String) -> void:
	var now := Time.get_ticks_msec()
	if now-int(last_play.get(name,-1000)) < 90: return
	last_play[name] = now
	for player in players:
		if not player.playing:
			player.stream = sounds.get(name)
			player.play()
			return
