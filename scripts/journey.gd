extends Node
const SAVE := "user://fx_journey.json"
var game: Node
var data: Dictionary = {"quest":{},"skipped":false,"unlocked":["Traveler"],"title":"Traveler","colour":0,"revives":0}
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var last_sound := 0
var cosmetics_ui:CanvasLayer
const TITLES := ["Traveler","First Footsteps","Grovekeeper","Lantern Bearer","Oath Restorer","Team Anchor"]
const COLOURS := [Color("#e6cf91"),Color("#dfac56"),Color("#83be85"),Color("#8bd5cd"),Color("#b6a1ec"),Color("#8fc1ed")]
func _ready() -> void:
	game=get_parent()
	var loaded:Variant=preload("res://scripts/profile_store.gd").read(SAVE)
	if loaded is Dictionary:data.merge(loaded,true)
	if preload("res://scripts/profile_store.gd").testing():data.unlocked=TITLES.duplicate()
	if not game.has_method("_attack_request"):
		cosmetics_ui=preload("res://scripts/journey_cosmetics.gd").new();add_child(cosmetics_ui);cosmetics_ui.setup(self)
	for name in ["swing","shot","flame","hit","hurt","reward","water","metal","magic","bow","shield","heal","victory"]:sounds[name]=load("res://assets/audio/"+name+".wav")
	for n in 6:
		var voice:=AudioStreamPlayer.new();voice.volume_db=-12;add_child(voice);voices.append(voice)
func save() -> void:
	preload("res://scripts/profile_store.gd").write(SAVE,data)
func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
func cue(name: String) -> void:
	if name not in ["victory","reward"] and Time.get_ticks_msec()-last_sound<65:return
	last_sound=Time.get_ticks_msec()
	if name=="victory":voices[0].stop();voices[0].stream=sounds["victory"];voices[0].pitch_scale=1;voices[0].play();return
	for voice in voices:
		if not voice.playing:voice.stream=sounds.get(name,sounds.get("swing"));voice.pitch_scale=randf_range(.96,1.04);voice.play();return
func mark(step: String) -> void:
	if preload("res://scripts/profile_store.gd").progression_blocked():return
	if bool(data.get("quest",{}).get(step,false)):return
	data["quest"][step]=true
	if quest_done():unlock("First Footsteps")
	save()
func quest_done() -> bool:
	for step in ["hero","practice","grove"]:
		if not bool(data.get("quest",{}).get(step,false)):return false
	return true
func unlock(title: String) -> void:
	if preload("res://scripts/profile_store.gd").progression_blocked():return
	if (data["unlocked"] as Array).has(title):return
	data["unlocked"].append(title);cue("reward");save()
	if not game.has_method("_attack_request"):
		game.message="Cosmetic earned: "+title+" • equip it at the Journey board";game.message_time=8.0
func won(realm: String) -> void:
	if preload("res://scripts/profile_store.gd").progression_blocked():return
	if realm=="grove":unlock("Grovekeeper")
	if realm=="lantern_marsh":unlock("Lantern Bearer")
	if realm=="shattered_oath":unlock("Oath Restorer")
func revived() -> void:
	if preload("res://scripts/profile_store.gd").progression_blocked():return
	data["revives"]=int(data.get("revives",0))+1
	if int(data["revives"])>=3:unlock("Team Anchor")
	save()
func ribbon() -> Color:
	return COLOURS[clampi(int(data.get("colour",0)),0,COLOURS.size()-1)]
func menu_lines() -> Array[String]:
	var lines:Array[String]=["YOUR JOURNEY • COSMETICS"]
	for entry in [["hero","Choose a hero"],["practice","Land three hits in the training yard"],["grove","Enter Whispering Grove"]]:
		lines.append(("DONE  " if bool(data.get("quest",{}).get(entry[0],false)) else "NEXT  ")+str(entry[1]))
	lines.append("1  Skip / hide the welcome checklist")
	lines.append("2  Equip next unlocked ribbon colour")
	lines.append("3  Equip next unlocked title")
	lines.append("Equipped: "+str(data.get("title","Traveler")))
	lines.append("Earned cosmetics: "+str(data.get("unlocked",[]).size())+" • cycle above to inspect and equip")
	lines.append("Cosmetics change appearance only. Escape closes.")
	return lines
func choose(code: int) -> void:
	if code==KEY_1:data["skipped"]=true
	if code==KEY_2:
		var unlocked:Array=data.get("unlocked",[])
		var current:=int(data.get("colour",0));var next:=0
		for offset in range(1,COLOURS.size()+1):
			var index: int=(current+offset)%COLOURS.size()
			if unlocked.has(TITLES[index]):next=index;break
		data["colour"]=next
	if code==KEY_3:
		var unlocked:Array=data.get("unlocked",[])
		data["title"]=unlocked[(unlocked.find(data.get("title","Traveler"))+1)%unlocked.size()]
	save()
func draw_on(canvas: Node2D, camera: Vector2) -> void:
	var arcade:bool=game.has_method("_attack_request")
	if arcade:return
	var font:=ThemeDB.fallback_font
	var player:Vector2=game.position_in_world-camera
	if not (game.media.clean_view or game.media.capturing):canvas.draw_string(font,player+Vector2(-40,-58),str(data.get("title","Traveler")),HORIZONTAL_ALIGNMENT_LEFT,-1,12,ribbon())

func draw_town(canvas:Node2D,camera:Vector2)->void:
	if game.has_method("_attack_request") or game.mode!="town":return
	var font:Font=ThemeDB.fallback_font
	var portrait:Texture2D=game.art.get(str(game.characters.get(game.selected_character,{}).get("sprite","ram"))+"_idle")
	if portrait!=null:canvas.draw_texture_rect(portrait,Rect2(Vector2(582,460)-camera,Vector2(36,40)),false)
	for n in mini(5,game.manifest.get("regions",[]).size()):
		var point:=Vector2(730+n*68,1180)-camera
		canvas.draw_line(point,point+Vector2(0,-55),Color("#aa9572"),3)
		canvas.draw_rect(Rect2(point+Vector2(3,-52),Vector2(26,32)),COLOURS[n%COLOURS.size()])
	canvas.draw_string(font,Vector2(700,1225)-camera,"REALMS BUILT AT THE CROSSROADS",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e5d8ac"))

func draw_hud(canvas:Node2D)->void:
	if game.has_method("_attack_request") or game.mode!="town":return
	var font:Font=ThemeDB.fallback_font
	if not bool(data.get("skipped",false)) and not quest_done() and not (game.media.clean_view or game.media.capturing):
		canvas.draw_rect(Rect2(25,110,650,78),Color(.04,.1,.14,.88))
		var text:="WELCOME  "
		for entry in [["hero","Choose hero"],["practice","Try training"],["grove","Enter Grove"]]:text+=("[done] " if bool(data.get("quest",{}).get(entry[0],false)) else "[ ] ")+str(entry[1])+"   "
		canvas.draw_string(font,Vector2(40,139),text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#ead9a7"))
		canvas.draw_string(font,Vector2(40,169),"Visit the Journey board to skip or equip rewards. T also opens it.",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#c6d9d8"))
