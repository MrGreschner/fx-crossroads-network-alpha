extends Node
const SAVE := "user://fx_journey.json"
var game: Node
var data: Dictionary = {"quest":{},"skipped":false,"unlocked":["Traveler"],"title":"Traveler","colour":0,"revives":0}
var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var last_sound := 0
var welcome_remaining:float=8.0
var welcome_tick_ms:int=0
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
	if not (game.media.clean_view or game.media.capturing):canvas.draw_string(font,preload("res://scripts/hero_layout250.gd").title(game.hero_painted_bounds,game.mode=="town" and game.legacy.crowns.display_tier()>0)+Vector2(-75,0),str(data.get("title","Traveler")),HORIZONTAL_ALIGNMENT_CENTER,150,12,ribbon())

func draw_town(canvas:Node2D,camera:Vector2)->void:
	if game.has_method("_attack_request") or game.mode!="town":return
	var font:Font=ThemeDB.fallback_font
	var portrait:Texture2D=game.art.get(str(game.characters.get(game.selected_character,{}).get("sprite","ram"))+"_idle")
	if portrait!=null:canvas.draw_texture_rect(portrait,Rect2(Vector2(582,460)-camera,Vector2(36,40)),false)

func welcome_visible()->bool:
	return not game.has_method("_attack_request") and game.mode=="town" and game.menu.is_empty() and game.presentation.page.is_empty() and game.session_menu.page.is_empty() and not game.has_node("FXIntro") and not bool(data.get("skipped",false)) and not quest_done() and not (game.media.clean_view or game.media.capturing)
func _process(_delta:float)->void:
	var now:int=Time.get_ticks_msec()
	var elapsed:float=maxf(0,float(now-welcome_tick_ms)/1000.0) if welcome_tick_ms>0 else 0.0
	welcome_tick_ms=now
	if game!=null and welcome_remaining>0 and welcome_visible():welcome_remaining=maxf(0,welcome_remaining-elapsed)
func draw_hud(canvas:Node2D)->void:
	if welcome_remaining<=0 or not welcome_visible():return
	var font:Font=ThemeDB.fallback_font
	var top:float=preload("res://scripts/town_hud.gd").height(game)+85
	var width:float=minf(680,game.VIEW.x-48)
	canvas.draw_rect(Rect2(24,top,width,48),Color(.04,.1,.14,.9))
	canvas.draw_line(Vector2(24,top),Vector2(24+width*welcome_remaining/8,top),Color("#86bdb7"),2)
	canvas.draw_string(font,Vector2(36,top+19),"WELCOME • Choose a hero, try training or enter a realm.",HORIZONTAL_ALIGNMENT_LEFT,width-24,15,Color("#ead9a7"))
	canvas.draw_string(font,Vector2(36,top+38),"Your checklist stays available at the Adventure board.",HORIZONTAL_ALIGNMENT_LEFT,width-24,13,Color("#c6d9d8"))
