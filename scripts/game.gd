extends Node2D
var waylight:Node
var music=preload("res://scripts/music_player.gd").new()
var media=preload("res://scripts/media_mode.gd").new()
var dev_magic:Node2D
var session_menu:CanvasLayer
var level_cards:CanvasLayer
var town_services:Node
var business_academy:CanvasLayer
var business_district:CanvasLayer
var commerce_town=preload("res://scripts/commerce_town.gd").new()
var idle_mine_town=preload("res://scripts/idle_mine_town.gd").new()
var town_chapter=preload("res://scripts/town_chapter.gd").new()
var catalog_ui:Node
var hero_workshop:CanvasLayer
var studio_live:Control
var cosmetic_town=preload("res://scripts/cosmetic_town.gd").new()
var academy_town=preload("res://scripts/academy_town.gd").new()
var arena_town=preload("res://scripts/arena_town.gd").new()
var town_plan=preload("res://scripts/town_plan.gd").new()
var studio_town=preload("res://scripts/studio_town.gd").new()
var hero_hall:CanvasLayer
var motion_v85=preload("res://scripts/hero_motion_v85.gd").new()

var VIEW := Vector2(1280, 720)
const SAVE_PATH := "user://crossroads_profile.json"
const RULESET_VERSION := "v6"
var ROOM_SERVICE_URL := preload("res://scripts/brand.gd").room_url()
const REGION_DIR := "res://content/regions/"
const CHARACTER_DIR := "res://content/characters/"
const ITEM_DIR := "res://content/items/"
const ENEMY_DIR := "res://content/enemies/"

var region: Dictionary = {}
var hero: Dictionary = {}
var manifest: Dictionary = {}
var characters: Dictionary = {}
var items: Dictionary = {}
var enemy_types: Dictionary = {}
var realms: Dictionary = {}
var profile: Dictionary = {}
var region_id := "town"
var selected_character := "ram"
var character_id := "ram"
var mode := "town"
var menu := ""
var trial := false
var active_realm := "grove"
var position_in_world := Vector2.ZERO
var last_defeat:Dictionary={}
var continuation:Node
var version_check:Node
var health := 120.0:
	set(value):
		var gained:float=value-health
		var was_alive:bool=health>0
		health=value
		if gained>0 and was_alive and mode=="run" and adventure!=null and adventure.combat!=null:
			adventure.combat.feedback.healed("solo",position_in_world,gained)
var level := 1
var kills := 0
var experience := 0
var gold := 100
var bounty_earned := 0
var bonus_health := 0.0
var bonus_damage := 0.0
var bonus_speed := 0.0
var upgrade := ""
var mastery := ""
var run_time := 0.0
var loadout: Array[String] = []
var inventory: Array[String] = []
var invulnerable_time := 0.0
var stealth_time := 0.0
var stun_time := 0.0
var block_time := 0.0
var block_reduction := 0.0
var cooldowns := {"primary": 0.0, "secondary": 0.0, "special": 0.0}
var bullets: Array[Dictionary] = []
var enemy_shots: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var allies: Array[Dictionary] = []
var attack_effects: Array[Dictionary] = []
var next_enemy_uid := 2000000
var boss_spawned := false
var boss_defeated := false
var boss_split_triggered := false
var pulse_time := 0.0
var pulse_position := Vector2.ZERO
var special_direction := Vector2.RIGHT
var strike_time := 0.0
var strike_direction := Vector2.RIGHT
var strike_style := "melee"
var strike_stats: Dictionary = {}
var charge_time := 0.0
var charge_speed:=680.0
var charge_direction := Vector2.RIGHT
var charge_damage := 0.0
var charge_hits: Array[int] = []
var player_flash_time := 0.0
var enemy_flashes: Dictionary = {}
var floating_text: Array[Dictionary] = []
var hint := ""
var message := ""
var message_time := 0.0
var result_text := ""
var camera := Vector2.ZERO
var font: Font
var art: Dictionary = {}
var scenery_tiles: Dictionary = {}
var scenery_max_radius:=0.0
var scenery_index_count:=-1
var obstacles: Array[Dictionary] = []
var decorations: Array[Dictionary] = []
var ground_patches: Array[Dictionary] = []
var town_places: Array[Dictionary] = []
var town_art: Array[Dictionary] = []
var haste_time := 0.0
var haste_multiplier := 1.0
var provisions=preload("res://scripts/provisions.gd").new()
var town_upgrade=preload("res://scripts/town_upgrade.gd").new()
var respawn_clinic:=false
var town_v109=preload("res://scripts/town_v109.gd").new()
var training_yard=preload("res://scripts/training_yard.gd").new()
var town_scenery=preload("res://scripts/town_scenery.gd").new()
var fishing:Node
var lodges:Node
var town_polish=preload("res://scripts/town_polish.gd").new()
var town_life=preload("res://scripts/town_life.gd").new()
var skating_motion=preload("res://scripts/skating_motion.gd").new()
var wing_motion=preload("res://scripts/wing_motion.gd").new()
var fish_motion=preload("res://scripts/fish_motion.gd").new()
var basketball_motion=preload("res://scripts/basketball_motion.gd").new()
var visual_clock := 0.0
var dodge_time := 0.0
var dodge_cooldown := 0.0
var dodge_direction := Vector2.RIGHT
var attack_pose_time := 0.0
var stealth_ambush := false
var shop_page := 0
var block_reflect := false
var ice_walls: Array[Dictionary] = []
var hero_preview := ""
var hero_scroll := 0
var practice := false
var dodge_trails: Array[Dictionary] = []

var highest_level := 1
var training_hits := 0
var dealt_damage := 0.0
var damage_taken := 0.0
var mistglass_rift:Node
var tutorial=preload("res://scripts/first_steps.gd").new()
var presentation:Node
var journey: Node
var adventure: Node
var flame_bursts: Array[Dictionary] = []
var mobile: CanvasLayer

var loadout_paid:Dictionary={}
var legacy:Node

func setup_media()->void:
	add_child(music);music.setup(self)
	add_child(media);media.setup(self)
func media_mouse_world()->Vector2:
	return media.world_mouse() if media.game!=null else get_global_mouse_position()+camera
var marina_life:Node
var voyage:Node
func _ready() -> void:
	var travel=preload("res://scripts/travel_polish.gd").new();travel.name="TravelPolish";add_child(travel);travel.play("town")
	call_deferred("setup_media")
	dev_magic=preload("res://scripts/dev_magic.gd").new();add_child(dev_magic);dev_magic.setup(self)
	for sprite in ["mosaicling","hive_drone","quillling","stagelet","lanternling","deputyling","gravehorse"]:
		for pose in ["idle","walk1","walk2","attack"]:art[sprite+"_"+pose]=load("res://assets/"+sprite+"_"+pose+".png")
	provisions.setup(self)
	mobile = preload("res://scripts/mobile_controls.gd").new()
	add_child(mobile)
	adventure = preload("res://scripts/realm_trials.gd").new()
	add_child(adventure)
	journey = preload("res://scripts/journey.gd").new()
	add_child(journey)
	font = ThemeDB.fallback_font
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for asset_name in ["grass", "forest", "ash", "path", "ice", "space", "quarantine", "tree", "crystal", "ice_pillar", "satellite", "barricade", "flower", "house", "merchant", "portal", "ram_0", "ram_1", "cat_0", "cat_1", "basketball_0", "basketball_1", "mini_basketball", "elder_ram", "warden_0", "warden_1", "bramble_0", "bramble_1", "bramble_boss", "potion", "character_hall", "supply_shop", "town_lamp", "town_banner", "sunfield_boss"]:
		art[asset_name] = load("res://assets/" + asset_name + ".png")
	setup_inputs()
	for key in ["oath_stone","briar_floor","cinder_floor","mirror_floor","storm_floor","marsh_floor"]: art[key] = load("res://assets/"+key+".png")
	load_registry()
	for sprite in ["oath_void","briar_arch","kiln_forge","mirror_shard_env","storm_coil","oath_stone","briar_floor","cinder_floor","mirror_floor","storm_floor","marsh_floor","moonburrow_grass","city_cobble","moonveil_court","moonveil_canal","oath_broken_road","garden_grass","river_grass","river_water","river_bridge","waterfall","river_willow","clock_floor","brass_path","clock_arch","clock_tree","astral_void","astral_floor","astral_bridge","star_obelisk","astrolabe","oath_pillar","marsh_reeds","lantern_tree","creator_board","realm_banner"]:
		art[sprite] = load("res://assets/"+sprite+".png")
	load_profile()
	preload("res://scripts/studio_library.gd").install(self)
	selected_character = str(get_tree().root.get_meta("fx_hero", profile.get("selected_hero", "ram")))
	if not characters.has(selected_character): selected_character = "ram"
	enemy_types["training_runner"]={"sprite":"training_dummy","health":500,"speed":0,"damage":0}
	enemy_types["training_dummy"] = {"sprite":"training_dummy", "health":500, "speed":0, "damage":0}
	art["training_dummy_0"] = preload("res://scripts/source_art.gd").texture("res://assets/training_dummy.svg")
	art["training_dummy_1"] = art["training_dummy_0"]
	respawn_clinic=bool(get_tree().root.get_meta("fx_clinic",false));get_tree().root.set_meta("fx_clinic",false)
	legacy=preload("res://scripts/legacy.gd").new();add_child(legacy);legacy.setup(self)
	preload("res://scripts/prepared_supply.gd").restore(self)
	hero_workshop=preload("res://scripts/hero_workshop.gd").new();add_child(hero_workshop);hero_workshop.setup(self)
	preload("res://scripts/studio_library.gd").install(self)
	studio_live=preload("res://scripts/studio_live.gd").new();add_child(studio_live);studio_live.setup(self)
	hero_hall=preload("res://scripts/hero_hall.gd").new();add_child(hero_hall);hero_hall.setup(self)
	town_services=preload("res://scripts/town_services.gd").new();add_child(town_services);town_services.setup(self)
	catalog_ui=preload("res://scripts/adventure_catalog.gd").new();add_child(catalog_ui);catalog_ui.setup(self)
	mistglass_rift=preload("res://scripts/mistglass_rift.gd").new();add_child(mistglass_rift);mistglass_rift.setup(self)
	fishing=preload("res://scripts/fishing.gd").new();add_child(fishing);fishing.setup(self)
	lodges=preload("res://scripts/lodges.gd").new();add_child(lodges);lodges.setup(self)
	waylight=preload("res://scripts/waylight.gd").new();add_child(waylight);waylight.setup(self)
	enter_region("town")
	tutorial.game=self
	presentation=preload("res://scripts/presentation.gd").new();add_child(presentation);presentation.setup(self,false)
	session_menu=preload("res://scripts/session_menu.gd").new();add_child(session_menu);session_menu.setup(self,false)
	version_check=preload("res://scripts/build_update.gd").new();add_child(version_check);version_check.setup(self)
	var quick_slots=preload("res://scripts/loadout_hud.gd").new();add_child(quick_slots);quick_slots.setup(self)
	var guide=preload("res://scripts/ability_guide.gd").new();add_child(guide);guide.setup(self)
	voyage=preload("res://scripts/water_voyage.gd").new();add_child(voyage);voyage.setup(self)
	marina_life=preload("res://scripts/marina_life.gd").new();add_child(marina_life);marina_life.setup(self)
	level_cards=preload("res://scripts/level_cards.gd").new();add_child(level_cards);level_cards.setup(self,false)
	if not get_tree().root.has_meta("fx_intro_seen"):
		get_tree().root.set_meta("fx_intro_seen",true)
		get_tree().root.set_meta("fx_show_main",true)
		if not _has_web_sun_loader():add_child(preload("res://scripts/title_intro.gd").new())
	if _has_web_sun_loader():call_deferred("_finish_web_sun_loading")

	if get_tree().root.has_meta("fx_solo_expedition"):call_deferred("_solo_expedition")
	if get_tree().root.has_meta("fx_return_from_lobby"):
		get_tree().root.remove_meta("fx_return_from_lobby")
		if get_tree().root.has_meta("fx_show_main"):get_tree().root.remove_meta("fx_show_main")
		presentation.close();session_menu.resume();menu="";mode="town";mobile.reset_controls()


func _solo_expedition()->void:
	var plan:Dictionary=get_tree().root.get_meta("fx_solo_expedition");get_tree().root.remove_meta("fx_solo_expedition");presentation.close();session_menu.resume();menu="";waylight.launch(str(plan.kind),int(plan.tier))

func _has_web_sun_loader()->bool:
	return OS.has_feature("web") and bool(JavaScriptBridge.eval("typeof window.fxSunLoading !== 'undefined'",true))
func _finish_web_sun_loading()->void:
	# Signal the completed first frame; the browser then opens its portal and plays the fixed intro.
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	JavaScriptBridge.eval("if(window.fxSunLoading)window.fxSunLoading.ready();",true)

func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing content file: " + path)
		return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not value is Dictionary:
		push_error("Invalid JSON object: " + path)
		return {}
	return value

func load_registry() -> void:
	manifest = load_json("res://content/manifest.json")
	for character_key in manifest.get("characters", []):
		var character_data := load_json(CHARACTER_DIR + str(character_key) + ".json")
		if not character_data.is_empty():
			characters[character_key] = character_data
			load_sprite_pair(str(character_data.get("sprite", character_key)))
			var special_data: Dictionary = character_data.get("special", {})
			if str(special_data.get("style", "")) == "summon":
				var minion_sprite := str(special_data.get("minion_sprite", "mini_basketball"))
				if not art.has(minion_sprite):
					art[minion_sprite] = load("res://assets/" + minion_sprite + ".png")
	for item_key in manifest.get("items", []):
		var item_data := load_json(ITEM_DIR + str(item_key) + ".json")
		if not item_data.is_empty():
			items[item_key] = item_data
	for enemy_key in manifest.get("enemies", []):
		var enemy_data := load_json(ENEMY_DIR + str(enemy_key) + ".json")
		if not enemy_data.is_empty():
			enemy_types[enemy_key] = enemy_data
			load_sprite_pair(str(enemy_data.get("sprite", "bramble")))
			if bool(enemy_data.get("flying", false)):
				pass
	for boss_id in ["cryowarden", "signal_core", "plague_director"]:
		if ResourceLoader.exists("res://assets/" + boss_id + ".png"):
			art[boss_id] = load("res://assets/" + boss_id + ".png")
			load_sprite_pair(boss_id)
	for region_key in manifest.get("regions", []):
		var region_data := load_json(REGION_DIR + str(region_key) + ".json")
		if not region_data.is_empty():
			realms[region_key] = region_data

func load_sprite_pair(prefix: String) -> void:
	if prefix=="lockdown_aberration" or prefix.begins_with("veil_") or prefix in preload("res://scripts/cinderheart.gd").TYPES+["ratchet_keeper","spark_scarab","hinge_conjurer","latch_hound"]:
		for pose in ["idle","walk1","walk2","attack","0","1"]:art[prefix+"_"+pose]=preload("res://scripts/source_art.gd").texture("res://assets/"+prefix+"_"+pose+".svg")
		return
	for pose in ["idle", "walk1", "walk2", "attack", "attack2", "special", "open", "spin", "shell", "0", "1"]:
		var key: String = prefix + "_" + str(pose)
		var refreshed=preload("res://scripts/hero_art_refresh.gd").texture(prefix,str(pose))
		if refreshed!=null:art[key]=refreshed
		elif not art.has(key) and ResourceLoader.exists("res://assets/" + key + ".png"):
			art[key] = load("res://assets/" + key + ".png")
		elif not art.has(key) and ResourceLoader.exists("res://assets/" + key + ".svg"):
			art[key] = preload("res://scripts/source_art.gd").texture("res://assets/" + key + ".svg")

	if not art.has(prefix+"_idle") and art.has(prefix+"_0"): art[prefix+"_idle"] = art[prefix+"_0"]

func load_profile() -> void:
	profile = {"records": {}, "runs": 0}
	if FileAccess.file_exists(SAVE_PATH):
		var saved:Dictionary = preload("res://scripts/profile_store.gd").read(SAVE_PATH,func(d:Dictionary):return d.get("records",{}) is Dictionary)
		if saved.has("records"):
			profile["records"] = saved["records"]
			profile["runs"] = int(saved.get("runs", 0))
		profile["selected_hero"] = str(saved.get("selected_hero", "ram"))
		profile["tutorial_seen"]=bool(saved.get("tutorial_seen",false))
		for key in ["welcome","cosmetics","equipped","title"]:
			profile[key] = saved.get(key,{} if key == "welcome" else [] if key == "cosmetics" else "")

func save_profile() -> void:
	if preload("res://scripts/profile_store.gd").progression_blocked():return
	profile["selected_hero"] = selected_character
	get_tree().root.set_meta("fx_hero", selected_character)
	if preload("res://scripts/profile_store.gd").write(SAVE_PATH,profile)!=OK:push_warning("Could not save local profile; download your profile before leaving.")

func setup_inputs() -> void:
	for key_entry in [["move_left", KEY_A], ["move_right", KEY_D], ["move_up", KEY_W], ["move_down", KEY_S], ["interact", KEY_E], ["special", KEY_SPACE], ["dodge", KEY_SHIFT]]:
		var key_event := InputEventKey.new()
		key_event.physical_keycode = key_entry[1]
		if not InputMap.has_action(key_entry[0]):
			InputMap.add_action(key_entry[0])
			InputMap.action_add_event(key_entry[0], key_event)
	for mouse_entry in [["primary", MOUSE_BUTTON_LEFT], ["secondary", MOUSE_BUTTON_RIGHT]]:
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = mouse_entry[1]
		if not InputMap.has_action(mouse_entry[0]):
			InputMap.add_action(mouse_entry[0])
			InputMap.action_add_event(mouse_entry[0], mouse_event)

func pair(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

func scenery_at(tx: int, ty: int) -> bool:
	return scenery_tiles.has(Vector2i(tx, ty))

func build_scenery() -> void:
	scenery_tiles.clear();scenery_max_radius=0.0;scenery_index_count=obstacles.size()
	for obstacle in obstacles:
		var location: Vector2 = obstacle["pos"]
		var key := Vector2i(floori(location.x / 64), floori(location.y / 64))
		scenery_max_radius=maxf(scenery_max_radius,float(obstacle["radius"]))
		if not scenery_tiles.has(key):
			scenery_tiles[key] = []
		scenery_tiles[key].append(obstacle)

func can_stand_at(point: Vector2) -> bool:
	if voyage!=null and voyage.active:return voyage.land_at(point)
	if mode=="town" and preload("res://scripts/town_marina.gd").on_deck(point):return true
	if waylight!=null and waylight.between() and mode=="run":return waylight.expedition.open(point)
	if mistglass_rift!=null and mistglass_rift.active and not Rect2(55,220,VIEW.x-110,VIEW.y-275).has_point(point):return false
	if mode=="town" and (preload("res://scripts/community_records.gd").blocked(point) or arena_town.blocked(point) or town_life.blocked(point) or (fishing!=null and fishing.blocked(point)) or idle_mine_town.blocked(point) or commerce_town.blocked(point) or studio_town.blocked(point) or academy_town.blocked(point) or cosmetic_town.blocked(point) or point.distance_to(town_life.WELL)<34 or (lodges!=null and lodges.blocked(point)) or town_chapter.blocked(point) or town_scenery.blocked(point) or town_upgrade.blocked(point) or preload("res://scripts/town_v173.gd").blocked(point) or town_v109.blocked(point) or legacy!=null and legacy.town_blocked(point)):return false
	if not adventure.can_stand(point): return false
	for tx in range(maxi(0, int(point.x / 64) - 1), mini(int(region_size().x / 64) + 1, int(point.x / 64) + 2)):
		for ty in range(maxi(0, int(point.y / 64) - 1), mini(int(region_size().y / 64) + 1, int(point.y / 64) + 2)):
			if scenery_at(tx, ty):
				for obstacle in scenery_tiles[Vector2i(tx, ty)]:
					if point.distance_to(obstacle["pos"]) < float(obstacle["radius"]):
						return false
	return true

func clear_of_obstacles(point: Vector2, padding: float = 0.0) -> bool:
	if voyage!=null and voyage.active:return voyage.land_at(point)
	if waylight!=null and waylight.between() and mode=="run":
		for offset in [Vector2.ZERO,Vector2(padding,0),Vector2(-padding,0),Vector2(0,padding),Vector2(0,-padding)]:
			if not waylight.expedition.open(point+offset):return false
		return true
	if scenery_index_count!=obstacles.size() or (scenery_tiles.is_empty() and not obstacles.is_empty()):build_scenery()
	if not adventure.can_stand(point): return false
	# Spatial broad phase; exact radii still decide collisions.
	var radius:=scenery_max_radius+maxf(0,padding)
	for tx in range(floori((point.x-radius)/64),floori((point.x+radius)/64)+1):
		for ty in range(floori((point.y-radius)/64),floori((point.y+radius)/64)+1):
			for obstacle in scenery_tiles.get(Vector2i(tx,ty),[]):
				if point.distance_squared_to(obstacle["pos"])<pow(float(obstacle["radius"])+padding,2):return false
	return true

func shot_path_clear(start: Vector2, finish: Vector2, flying: bool = false) -> bool:
	if flying:
		return true
	var steps := maxi(1, int(ceil(start.distance_to(finish) / 10.0)))
	for step_index in range(1, steps + 1):
		if not clear_of_obstacles(start.lerp(finish, float(step_index) / float(steps)), 5.0):
			return false
	return true

func move_enemy_around_obstacles(enemy: Dictionary, displacement: Vector2, flying: bool) -> void:
	if adventure.quests.active and displacement.length()>0:
		var definition:Dictionary=enemy_types.get(str(enemy.type),{})
		displacement=adventure.quests.direction(enemy,position_in_world,adventure.combat.ranged_enemy(enemy,definition))*displacement.length()
	if flying:
		enemy["pos"] += displacement
		return
	var steps := maxi(1, int(ceil(displacement.length() / 12.0)))
	for step_index in steps:
		var step := displacement / float(steps)
		var current: Vector2 = enemy["pos"]
		var origin: Vector2 = current
		var horizontal := current + Vector2(step.x, 0)
		if clear_of_obstacles(horizontal, 17.0):
			enemy["pos"] = horizontal
		current = enemy["pos"]
		var vertical := current + Vector2(0, step.y)
		if clear_of_obstacles(vertical, 17.0):
			enemy["pos"] = vertical
		if (enemy["pos"] as Vector2).distance_squared_to(origin) < 0.01 and step.length_squared() > 0:
			var side := 1.0 if int(enemy.get("uid", 0)) % 2 == 0 else -1.0
			var tangent := Vector2(-step.y, step.x) * side
			if clear_of_obstacles(origin + tangent, 17.0):
				enemy["pos"] = origin + tangent

func move_player(displacement: Vector2) -> void:
	# Substeps prevent the charge from passing through a tree on a slow frame.
	var steps := maxi(1, int(ceil(displacement.length() / 12.0)))
	var step := displacement / float(steps)
	for unused_step in steps:
		var horizontal := (position_in_world + Vector2(step.x, 0)).clamp(Vector2(-1370,-530) if mode=="town" else Vector2(30,30), region_size() - Vector2(30, 30))
		if can_stand_at(horizontal):
			position_in_world = horizontal
		var vertical := (position_in_world + Vector2(0, step.y)).clamp(Vector2(-1370,-530) if mode=="town" else Vector2(30,30), region_size() - Vector2(30, 30))
		if can_stand_at(vertical):
			position_in_world = vertical

func region_size() -> Vector2:
	return pair(region.get("size", [1280, 720]))

func update_camera() -> void:
	if mistglass_rift!=null and mistglass_rift.active:camera=Vector2.ZERO;return
	var effective=VIEW/media.factor();camera = (position_in_world+media.framing - effective * 0.5).clamp(Vector2(-1400,-560) if mode=="town" else Vector2.ZERO, (region_size() - effective).max(Vector2.ZERO))

func load_realm_layout() -> bool:
	var scene_path := str(region.get("scene", ""))
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_error("Missing realm scene for " + region_id + ": " + scene_path)
		return false
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		push_error("Could not load realm scene for " + region_id + ": " + scene_path)
		return false
	var layout := packed.instantiate() as Node2D
	if layout == null:
		push_error("Realm scene root must be Node2D: " + scene_path)
		return false
	for required_path in ["Points/Spawn", "Points/ReturnGate", "Points/Merchant", "Points/Boss", "Enemies", "GroundPaint", "Obstacles"]:
		if not layout.has_node(required_path):
			push_error("Realm scene is missing " + required_path + ": " + scene_path)
			layout.free()
			return false
	var points := layout.get_node("Points")
	var spawn_point := (points.get_node("Spawn") as Node2D).position
	var return_point := (points.get_node("ReturnGate") as Node2D).position
	var merchant_point := (points.get_node("Merchant") as Node2D).position
	var boss_point := (points.get_node("Boss") as Node2D).position
	region["spawn"] = [spawn_point.x, spawn_point.y]
	region["gate"] = {"position": [return_point.x, return_point.y]}
	region["merchant"] = [merchant_point.x, merchant_point.y]
	region["boss"] = [boss_point.x, boss_point.y]
	var placements: Array = []
	for marker in layout.get_node("Enemies").get_children():
		var location := (marker as Node2D).position
		placements.append({"type": str(marker.get_meta("enemy_id", "bramble")), "position": [location.x, location.y]})
	region["enemies"] = placements
	ground_patches.clear();ground_tile_cache.clear();ground_index.invalidate()
	if terrain_cache!=null:terrain_cache.reset()
	for ground_node in layout.get_node("GroundPaint").get_children():
		if ground_node is Polygon2D:
			var vertices := PackedVector2Array()
			for vertex in (ground_node as Polygon2D).polygon:
				vertices.append((ground_node as Polygon2D).transform * vertex)
			ground_patches.append({"polygon": vertices, "tile": str(ground_node.get_meta("tile", "path"))})
	obstacles.clear()
	decorations.clear()
	for obstacle_marker in layout.get_node("Obstacles").get_children():
		var obstacle_sprite := obstacle_marker as Sprite2D
		obstacles.append({"pos": (obstacle_marker as Node2D).position + Vector2(0, 6), "kind": str(obstacle_marker.get_meta("kind", "tree")), "radius": float(obstacle_marker.get_meta("radius", 43.0)), "texture": obstacle_sprite.texture if obstacle_sprite != null else null})
	if layout.has_node("Decorations"):
		for marker in layout.get_node("Decorations").get_children():
			var visual := marker as Sprite2D
			if visual != null and visual.texture != null:
				decorations.append({"pos": visual.position, "texture": visual.texture, "size": visual.texture.get_size() * visual.scale})
	layout.free()
	if adventure.vault.active: region.erase("merchant")
	build_scenery()
	return true

func load_town_layout() -> bool:
	var scene_path := str(region.get("scene", "res://scenes/town.tscn"))
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Missing town scene: " + scene_path)
		return false
	var layout := packed.instantiate() as Node2D
	if layout == null or not layout.has_node("Points") or not layout.has_node("GroundPaint") or not layout.has_node("Landmarks"):
		push_error("Town needs Points, GroundPaint and Landmarks: " + scene_path)
		if layout != null:
			layout.free()
		return false
	var spawn := layout.get_node("Points/Spawn") as Node2D
	region["spawn"] = [spawn.position.x, spawn.position.y]
	town_places.clear()
	for marker in layout.get_node("Points").get_children():
		if marker == spawn:
			continue
		town_places.append({"pos": (marker as Node2D).position, "menu": str(marker.get_meta("menu", "")), "hint": str(marker.get_meta("hint", ""))})
	town_art.clear()
	for marker in layout.get_node("Landmarks").get_children():
		var visual := marker as Sprite2D
		if visual == null or visual.texture == null:
			continue
		var key := visual.texture.resource_path.get_file().get_basename()
		if not art.has(key):
			art[key] = visual.texture
		town_art.append({"pos": visual.position, "size": visual.texture.get_size() * visual.scale, "sprite": key, "label": str(marker.get_meta("label", ""))})
		if str(marker.name).begins_with("NorthFence"):
			obstacles.append({"pos":visual.position,"radius":82.0,"kind":"town_fence","town_hidden":true})
	ground_patches.clear();ground_tile_cache.clear();ground_index.invalidate()
	if terrain_cache!=null:terrain_cache.reset()
	for ground_node in layout.get_node("GroundPaint").get_children():
		if ground_node is Polygon2D:
			var vertices := PackedVector2Array()
			for vertex in (ground_node as Polygon2D).polygon:
				vertices.append((ground_node as Polygon2D).transform * vertex)
			ground_patches.append({"polygon": vertices, "tile": str(ground_node.get_meta("tile", "path"))})
	town_plan.apply(self)
	layout.free()
	return true

var combat_epoch: int = 0

func combat_frame_active(epoch: int) -> bool:
	return epoch == combat_epoch and mode == "run" and menu.is_empty()

func enter_region(id: String) -> void:
	if voyage!=null and voyage.active and id not in ["voyage_lake","voyage_coast"]:
		voyage.fail("Voyage ended");return
	if waylight!=null:waylight.entering(id)
	if id=="town" and continuation!=null:continuation.end()
	var travel=get_node_or_null("TravelPolish")
	if travel!=null:travel.play("town" if id=="town" else "portal")
	if mistglass_rift!=null and mistglass_rift.active and id!="mistglass_rift":
		mistglass_rift.active=false;loadout.assign(mistglass_rift.saved_pack);provisions.packed=mistglass_rift.saved_food
	combat_epoch += 1
	if is_instance_valid(realm_props):realm_props.queue_free()
	realm_props=null
	var data := load_json(REGION_DIR + id + ".json")
	if data.is_empty():
		return
	region_id = id
	practice = id == "practice"
	if practice:training_yard.reset()
	region = data
	adventure.setup(id)
	flame_bursts.clear()
	mode = "town" if id == "town" else "run"
	obstacles.clear()
	decorations.clear()
	ground_patches.clear();ground_tile_cache.clear();ground_index.invalidate()
	if terrain_cache!=null:terrain_cache.reset()
	if mode == "run":
		if id!="between" and not load_realm_layout():
			enter_region("town")
			message = "Realm could not load. Check the scene file in Godot."
			message_time = 6.0
			return
	else:
		if not load_town_layout():
			return
		build_scenery()
		town_places.append({"pos":Vector2(900,-250),"menu":"battlegrounds_entrance","hint":"Battlegrounds • 3v3 / 4v4 armies"})
		town_places.append({"pos":Vector2(550,1550),"menu":"postoffice","hint":"Squirrel Post • profiles and food parcels"})
		town_places.append({"pos":Vector2(820,935),"menu":"journey","hint":"Choose an adventure"})
		# The old creator sign is now Squirrel Post, drawn by town_services.
		town_art.append({"pos":Vector2(820,890),"size":Vector2(64,96),"sprite":"creator_board","label":"ADVENTURE BOARD"})
	if id=="honeyglass":obstacles.clear();decorations.clear();build_scenery()
	position_in_world = pair(region.get("spawn", [250, 500]))
	if mode=="town":
		stun_time=0;charge_time=0;charge_hits.clear();dodge_time=0;dodge_direction=Vector2.ZERO;block_time=0;stealth_time=0;haste_time=0;ice_walls.clear();mobile.reset_controls()
	if mode=="town" and respawn_clinic:
		position_in_world=safe_town_respawn();respawn_clinic=false
		health=float(characters.get(selected_character,{}).get("max_health",120))
		message="The town healer helped you recover. Prepare supplies before your next adventure.";message_time=6
	bullets.clear()
	enemy_shots.clear()
	enemies.clear()
	allies.clear()
	attack_effects.clear()
	next_enemy_uid = 2000000
	boss_spawned = false
	boss_defeated = false
	boss_split_triggered = false
	if mode == "run":
		var enemy_uid := 0
		for entry in region.get("enemies", []):
			var enemy_type_id := str(entry.get("type", "bramble"))
			if enemy_types.has(enemy_type_id):
				var definition: Dictionary = enemy_types[enemy_type_id]
				var hp := float(definition.get("health", 65))
				enemies.append({"pos": pair(entry["position"]), "hp": hp, "max_hp": hp, "attack_timer": 0.0, "boss": false, "type": enemy_type_id, "uid": enemy_uid})
				enemy_uid += 1
	if mode=="town":town_life.setup(self)
	update_camera()
	queue_redraw()

func start_training(at:Vector2=Vector2(650,430))->void:
	var saved_loadout:=loadout.duplicate()
	start_run(false,"practice")
	loadout.assign(saved_loadout);inventory.clear();level=10;highest_level=10;health=max_health()
	position_in_world=at;update_camera();mobile.reset_controls()
	message="TRAINING • All attacks ready. E at the open book to change heroes; E at the guide for help."
	message_time=6;queue_redraw()

func start_run(is_trial: bool, realm_id: String = "grove") -> void:
	if waylight!=null and not waylight.launching:
		if waylight.special():
			if waylight.settled:
				var tab=1 if waylight.between() else 2
				presentation.return_to_town();waylight.open(tab)
			else:message="Finish this expedition, or return to town to forfeit it.";message_time=5
			return
		if realm_id=="between" or not waylight.ticket().is_empty():
			if mode=="town":waylight.open(1)
			else:message="Enter the Between through the central town portal.";message_time=5
			return
	if version_check!=null and version_check.blocked():version_check.notice();return
	if not is_trial and not tutorial.active and not preload("res://scripts/realm_access.gd").unlocked(legacy,realm_id):message=preload("res://scripts/realm_access.gd").hint(legacy,realm_id);message_time=6;return
	if continuation==null:continuation=preload("res://scripts/solo_continue.gd").new();add_child(continuation);continuation.setup(self)
	continuation.begin()
	if studio_live!=null:studio_live.last_hero=""
	if presentation!=null and not tutorial.active:presentation.begin_run()
	trial = is_trial
	active_realm = "grove" if trial else realm_id
	character_id = "ram" if trial else selected_character
	hero = characters.get(character_id, {})
	if hero.is_empty():
		return
	level = 1
	highest_level = 1
	dealt_damage = 0
	damage_taken = 0
	kills = 0
	experience = 0
	bounty_earned = 0
	bonus_health = 0.0
	bonus_damage = 0.0
	bonus_speed = 0.0
	haste_time = 0.0
	haste_multiplier = 1.0
	upgrade = ""
	mastery = ""
	charge_time = 0.0
	strike_time = 0.0
	player_flash_time = 0.0
	dodge_time = 0.0
	dodge_cooldown = 0.0
	ice_walls.clear()
	attack_pose_time = 0.0
	stealth_ambush = false
	floating_text.clear()
	enemy_flashes.clear()
	run_time = 0.0
	inventory.clear()
	if not trial:
		inventory.assign(loadout)
		if not practice and realm_id!="practice":
			for id in inventory:preload("res://scripts/prepared_supply.gd").commit(str(id))
	loadout.clear()
	health=max_health()
	adventure.combat.feedback.healing_numbers.clear()
	if bool(legacy.data.teacher):level=10;highest_level=10
	if trial:
		gold = 0
	invulnerable_time = 0.0
	stealth_time = 0.0
	stun_time = 0.0
	block_time = 0.0
	block_reduction = 0.0
	last_defeat.clear()
	cooldowns = {"primary": 0.0, "secondary": 0.0, "special": 0.0}
	menu = ""
	enter_region(active_realm)
	if waylight!=null:waylight.started()
	if active_realm == "grove": journey.mark("grove")
	if active_realm == "grove": mark_welcome("realm")
	message = "Speak to the villagers. Q / Journal shows your quests. Progress saves here." if adventure.quests.active else "Follow the target pointer, earn XP and bounties, then face the boss."
	message_time = 5.0

func finish_run(won: bool, abandoned:bool=false) -> void:
	if voyage!=null and voyage.active: voyage.fail("Voyage abandoned" if abandoned else "You fell on the island");return
	if mistglass_rift!=null and mistglass_rift.active:mistglass_rift.finish(won);return
	if tutorial.active:tutorial.finish(won);return
	if mode != "run" or menu=="results":
		return
	if won and waylight!=null and waylight.active():
		if waylight.kind=="overcharge" and not boss_defeated:return
		if waylight.between() and position_in_world.distance_to(waylight.expedition.ORIGIN)>120:return
	get_tree().root.get_node("FXActivity").event(self,"complete","cleared" if won else "returned" if abandoned else "defeated",run_time,{"damage":dealt_damage,"enemies":kills,"players":1,"banked_shards":waylight.expedition.carried if waylight!=null and waylight.between() else 0})
	if not won and not abandoned and not practice:legacy.cosmetics.competitive.defeated()
	respawn_clinic=not won and not abandoned
	var waylight_run:bool=waylight!=null and waylight.special()
	var waylight_result:String=waylight.finish(won) if waylight_run else ""
	if won and not waylight_run and not practice and not preload("res://scripts/profile_store.gd").progression_blocked():
		provisions.complete_adventure();legacy.clear_adventure(character_id,region_id)
		if not trial and not (lodges!=null and lodges.active):legacy.glimmers.credit(4)
	legacy.save()
	var label := "Ram's Trial" if trial else str(region.get("name", "Realm"))
	var seconds := int(run_time)
	var time_text := "%d:%02d" % [seconds / 60, seconds % 60]
	var new_best:=false
	if not preload("res://scripts/profile_store.gd").progression_blocked():
		profile["runs"] = int(profile.get("runs", 0)) + 1
		var relic_assisted:bool=waylight!=null and not waylight.combat.items().is_empty()
		var record_key := RULESET_VERSION + (":relics" if relic_assisted else "") + ":" + ("trial" if trial else region_id) + ":" + character_id
		var records: Dictionary = profile.get("records", {})
		var best := int(records.get(record_key, 0))
		new_best = won and not waylight_run and (best == 0 or seconds < best)
		if new_best:
			records[record_key] = seconds
			profile["records"] = records
		if won:
			unlock_cosmetic("Pathfinder")
			if region_id == "lantern_marsh": unlock_cosmetic("Lantern Keeper")
			if region_id == "shattered_oath": unlock_cosmetic("Oath Restorer")
		if won and not waylight_run: journey.won(region_id)
	save_profile()
	result_text = ("CLEARED " if won else "RETURNED FROM " if abandoned else "DEFEATED IN ") + label + "\nCharacter: " + str(hero.get("name", "Hero")) + "    Time: " + time_text + "\nReached level " + str(level) + "    Bounties earned: " + str(bounty_earned) + " CC"
	if new_best:
		result_text += "\nNEW PERSONAL BEST!"
	result_text += "\nDamage dealt: "+str(int(dealt_damage))+"   Damage taken: "+str(int(damage_taken))
	if waylight_run:result_text+="\n"+waylight_result
	result_text += "\n"+legacy.result_line(character_id)
	result_text += "\nPress Enter to return to town."
	menu = "results"
	presentation.results(won,abandoned)

func _process(delta: float) -> void:
	if mode in ["town","run"] and menu.is_empty() and legacy!=null and not practice and session_menu.page.is_empty() and presentation.page.is_empty() and not tutorial.active:
		if mode=="town" and preload("res://scripts/community_records.gd").interact(self) and Input.is_action_just_pressed("interact"):return
		if preload("res://scripts/garden_hunting.gd").interact(self):
			if Input.is_action_just_pressed("interact"):return
	town_life.calendar.step()
	if voyage!=null and voyage.step(delta):return
	town_life.events.step(self,delta)
	if mode=="town" and not has_node("FXIntro") and get_tree().root.has_meta("fx_daily_launch"):
		get_tree().root.remove_meta("fx_daily_launch");legacy.daily.quick_play();return
	if menu=="workshop":return
	motion_v85.advance(delta)
	if has_node("FXIntro"):return
	tutorial.step(delta)
	if mode=="town":
		town_life.step(delta)
		if marina_life!=null:marina_life.step(delta)
		town_scenery.step(delta)
		town_upgrade.step(delta)
		town_polish.step(delta)
	adventure.combat.v79.sample("solo",position_in_world,delta,menu.is_empty() and health>0)
	adventure.combat.v78.sample("solo",position_in_world,menu.is_empty() and health>0)
	skating_motion.advance(delta)
	var motion_hero:String=selected_character if mode=="town" else str(hero.get("id",selected_character))
	motion_v85.sample("solo",motion_hero,position_in_world,menu.is_empty() and health>0)
	skating_motion.sample("solo",position_in_world,delta,motion_hero=="goalie" and menu.is_empty() and health>0 and not adventure.immersive.aboard("solo"))
	wing_motion.step("solo",position_in_world,delta,motion_hero=="velvetwing" and menu.is_empty() and health>0)
	basketball_motion.step("solo",position_in_world,delta,motion_hero=="basketball" and menu.is_empty() and health>0 and not adventure.immersive.aboard("solo"))
	fish_motion.step("solo",position_in_world,delta,motion_hero=="ripplejaw" and menu.is_empty() and health>0 and not adventure.immersive.aboard("solo"))
	motion_v85.landing("solo",position_in_world,fish_motion.phase("solo"))
	adventure.combat.v56.holding("solo",mode=="run" and menu.is_empty() and not fishing.busy() and (mobile.attacking if mobile.enabled else Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)),aim_direction())
	adventure.combat.release_heroes.holding("solo",mode=="run" and menu.is_empty() and not fishing.busy() and Input.is_action_pressed("secondary"),aim_direction())
	adventure.combat.classics.holding("solo",mode=="run" and menu.is_empty() and not fishing.busy() and Input.is_action_pressed("secondary"))
	adventure.combat.v79.holding("solo",mode=="run" and menu.is_empty() and not fishing.busy() and Input.is_action_pressed("secondary"),aim_direction())
	adventure.combat.held_cast.local_input(delta,mode=="run" and menu.is_empty() and not fishing.busy() and presentation.page.is_empty())
	if (not menu.is_empty() or fishing.busy()) and studio_live!=null:studio_live.cancel_holds()
	var resized := VIEW != get_viewport_rect().size
	VIEW = get_viewport_rect().size
	if resized and not region.is_empty(): update_camera()
	if region.is_empty():
		return
	visual_clock += delta
	message_time = maxf(0.0, message_time - delta)
	pulse_time = maxf(0.0, pulse_time - delta)
	strike_time = maxf(0.0, strike_time - delta)
	player_flash_time = maxf(0.0, player_flash_time - delta)
	dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
	for trail_index in range(dodge_trails.size()-1,-1,-1):
		dodge_trails[trail_index]["time"] -= delta
		if float(dodge_trails[trail_index]["time"]) <= 0: dodge_trails.remove_at(trail_index)
	attack_pose_time = maxf(0.0, attack_pose_time - delta)
	for flash_uid in enemy_flashes.keys():
		enemy_flashes[flash_uid] = maxf(0.0, float(enemy_flashes[flash_uid]) - delta)
	for text_index in range(floating_text.size() - 1, -1, -1):
		var notice: Dictionary = floating_text[text_index]
		notice["time"] = float(notice["time"]) - delta
		notice["pos"] += Vector2(0, -35) * delta
		if float(notice["time"]) <= 0:
			floating_text.remove_at(text_index)
		else:
			floating_text[text_index] = notice
	if menu != "":
		queue_redraw()
		return
	if mode == "run" and adventure.combat.v90.pending_rebirth("solo"):
		run_time+=delta;adventure.step(delta*dev_magic.world_scale());queue_redraw();return
	if mode == "run":
		run_time += delta
		invulnerable_time = maxf(0.0, invulnerable_time - delta)
		stealth_time = maxf(0.0, stealth_time - delta)
		haste_time = maxf(0.0, haste_time - delta)
		stun_time = maxf(0.0, stun_time - delta)
		block_time = maxf(0.0, block_time - delta)
		for wall_index in range(ice_walls.size() - 1, -1, -1):
			ice_walls[wall_index]["time"] = float(ice_walls[wall_index]["time"]) - delta
			if float(ice_walls[wall_index]["time"]) <= 0: ice_walls.remove_at(wall_index)
		for effect_index in range(attack_effects.size() - 1, -1, -1):
			attack_effects[effect_index]["time"] = float(attack_effects[effect_index]["time"]) - delta
			if float(attack_effects[effect_index]["time"]) <= 0:
				attack_effects.remove_at(effect_index)
		for key in cooldowns:
			cooldowns[key] = maxf(0.0, float(cooldowns[key]) - delta)
	var carried_multiplier := 1.0
	var carried_speed := bonus_speed
	if mode == "run":
		for carried_id in inventory:
			var carried: Dictionary = items.get(carried_id, {})
			if str(carried.get("effect", "")) == "bonus_speed":
				carried_speed += float(carried.get("amount", 0))
				carried_multiplier *= float(carried.get("speed_multiplier",1.0))
	var speed := (float(characters.get(selected_character,{}).get("speed",230)) if selected_character in ["gopher","snail","kite"] else 230.0) if mode == "town" else (float(hero.get("speed", 230)) + carried_speed) * (1.45 if stealth_time > 0 else 1.0) * (haste_multiplier if haste_time > 0 else 1.0)
	if mode=="run":
		speed*=carried_multiplier*legacy.speed_factor("solo")
		if adventure.combat.classics.channeling("solo"):speed*=legacy.channel_speed("solo")
	if mode != "town":speed*=adventure.combat.speed_factor("p:solo")
	var direction: Vector2 = mobile.movement if mobile.enabled else Vector2(Input.get_axis("move_left", "move_right"), Input.get_axis("move_up", "move_down")).normalized()
	direction=adventure.combat.twister.sway("solo",direction)
	if mode=="run" and (stun_time > 0 or adventure.combat.v78.locked("solo") or adventure.combat.v79.moving("solo")):
		direction = Vector2.ZERO
	if studio_live.active():
		speed*=studio_live.buff_speed()
		if studio_live.hero.get("passive","")=="swift":speed*=1.08
	if mode in ["town","run"] and dodge_cooldown <= 0 and Input.is_action_just_pressed("dodge") and stun_time <= 0 and not adventure.combat.stunned("p:solo") and not adventure.combat.classics.locked("solo") and not adventure.combat.v48.moving("solo") and not adventure.immersive.aboard("solo") and not adventure.combat.robot.transformed("solo") and not adventure.combat.v78.locked("solo") and not adventure.combat.v79.moving("solo") and not adventure.combat.v110.charging("solo") and not adventure.combat.halloween.moving("solo") and not adventure.combat.release_heroes.locked("solo"):
		dodge_direction = direction if direction.length_squared() > 0 else aim_direction()
		dodge_time = 0.26
		if mode=="run":
			if waylight!=null:waylight.combat.dodge()
			invulnerable_time = maxf(invulnerable_time, 0.22)
		dodge_cooldown = 2.5
	if mode == "run" and charge_time > 0:
		var charge_step := minf(charge_time, delta)
		charge_time -= charge_step
		move_player(charge_direction * charge_speed * charge_step)
		for charge_index in range(enemies.size() - 1, -1, -1):
			var charging_enemy: Dictionary = enemies[charge_index]
			var charge_uid := int(charging_enemy["uid"])
			if not charge_hits.has(charge_uid) and position_in_world.distance_to(charging_enemy["pos"]) < (70 if charging_enemy["boss"] else 53):
				charge_hits.append(charge_uid)
				damage_enemy(charge_index, charge_damage)
	elif dodge_time > 0:
		var dodge_step := minf(delta, dodge_time)
		dodge_trails.append({"pos":position_in_world, "time":0.18})
		move_player(dodge_direction * (330.0 + 370.0 * sin(PI * dodge_time / 0.26)) * dodge_step * adventure.combat.v79.dodge_factor("solo"))
		dodge_time = maxf(0.0, dodge_time - dodge_step)
	else:
		var walking:Vector2=adventure.combat.v79.displacement("solo",direction,speed,delta) if motion_hero=="kite" else motion_v85.displacement("solo",motion_hero,direction,speed,delta) if motion_hero in ["spindle","snowman","quill"] else (adventure.combat.v78.dig_vector("solo",direction) if motion_hero=="gopher" else direction) * speed * (skating_motion.travel_time if motion_hero=="goalie" else delta)
		move_player(adventure.polish.motion("solo",position_in_world,walking,delta) if mode=="run" else walking)
	update_camera()
	hint = ""
	if mode == "town":
		handle_town_interactions()
	else:
		handle_run(delta)
	queue_redraw()

func handle_town_interactions() -> void:
	if marina_life!=null and marina_life.interact():return
	if voyage!=null and voyage.pier_interact():return
	if fishing!=null and fishing.interact():return
	if town_life.events.interact(self):return
	if commerce_town.interact(self):return
	if idle_mine_town.interact(self):return
	if academy_town.interact(self):return
	if cosmetic_town.interact(self):return
	if studio_town.interact(self):return
	if lodges!=null and lodges.interact():return
	if town_v109.interact(self):return
	if town_upgrade.interact(self):return
	if position_in_world.distance_to(town_life.WELL)<85:
		hint="E • Toss 1 CC • 1 in 100 treasure chance"
		if Input.is_action_just_pressed("interact"):town_life.offer(self)
		return
	for place in town_places:
		if position_in_world.distance_to(place["pos"]) < 105:
			hint = "E  " + str(place["hint"])
			if Input.is_action_just_pressed("interact"):
				menu = str(place["menu"])
				if menu=="portal" and waylight!=null:menu="";waylight.open();return
				if menu=="journey":presentation.adventures();return
				if menu == "characters":
					mark_welcome("hero")
					hero_preview = selected_character
					hero_scroll = clampi((manifest.get("characters",[]) as Array).find(selected_character)-3,0,maxi(0,manifest.get("characters",[]).size()-7))
			if menu == "practice_entrance":
				start_training()
				return
			if menu in ["arena_entrance", "defense_entrance", "descent_entrance", "battlegrounds_entrance"]:
				get_tree().root.set_meta("fx_mode", "battlegrounds" if menu=="battlegrounds_entrance" else "arena" if menu == "arena_entrance" else "defense" if menu == "defense_entrance" else "descent")
				get_tree().root.set_meta("fx_hero", selected_character)
				get_tree().change_scene_to_file("res://network/client.tscn")
			return

	town_life.interact(self)

func handle_run(delta: float) -> void:
	if voyage!=null and voyage.active:
		adventure.step(delta);update_flames(delta)
		if voyage.active:voyage.combat(delta)
		return
	if tutorial.active and tutorial.interact():return
	var epoch := combat_epoch
	if waylight!=null:waylight.step(delta)
	if not combat_frame_active(epoch): return
	if adventure.active or adventure.vault.active or adventure.combat.coast.active or adventure.city.active or adventure.hollow.active or adventure.quests.active or adventure.school.active or adventure.tech.active or adventure.immersive.active or adventure.foundry.active or adventure.cinder.active:
		if Input.is_action_just_pressed("interact") and adventure.interact("solo"): return
	adventure.step(delta*dev_magic.world_scale())
	if not combat_frame_active(epoch): return
	update_flames(delta)
	if not combat_frame_active(epoch): return
	if practice:
		training_yard.step(self,delta)
		if position_in_world.distance_to(training_yard.HERO_BOOK)<85:
			hint="E • Open hero book / choose another hero"
			if Input.is_action_just_pressed("interact"):
				menu="characters";hero_preview=selected_character;mobile.reset_controls()
			return
		if position_in_world.distance_to(town_chapter.GUIDE)<85:
			hint="E • Ask the training guide / replay First Steps"
			if Input.is_action_just_pressed("interact"):menu="training_guide"
			return
		if position_in_world.distance_to(pair(region["gate"]["position"])) < 85:
			hint = "E  Return to town"
			if Input.is_action_just_pressed("interact"):
				enter_region("town")
				return
		if studio_live.active() and not fishing.busy():studio_live.step(delta)
		else:
			if adventure.combat.v90.primary_pressed("solo",mobile.attacking if mobile.enabled else Input.is_action_pressed("primary")): fire("primary")
			if Input.is_action_pressed("secondary"): fire("secondary")
			if Input.is_action_just_pressed("special"): pulse()
		update_enemy_shots(delta)
		if not combat_frame_active(epoch): return
		update_bullets(delta)
		if not combat_frame_active(epoch): return
		update_allies(delta)
		if not combat_frame_active(epoch): return
		return
	if not combat_frame_active(epoch): return
	var return_gate := pair(region["gate"]["position"])
	if region.has("merchant") and not tutorial.active and position_in_world.distance_to(pair(region["merchant"])) < 95:
		hint = "E  Visit the realm merchant"
		if Input.is_action_just_pressed("interact"):
			menu = "merchant"
			return
	if not (waylight!=null and waylight.between()) and position_in_world.distance_to(return_gate) < 85:
		hint = "E  Abandon run and return to town"
		if Input.is_action_just_pressed("interact"):
			finish_run(false,true)
			return
	if boss_defeated and position_in_world.distance_to(pair(region["boss"])) < 105:
		hint = "E  Finish run and return to town"
		if Input.is_action_just_pressed("interact"):
			finish_run(true)
			return
	if studio_live.active() and not fishing.busy():studio_live.step(delta)
	if not studio_live.active() and stun_time <= 0 and charge_time <= 0 and adventure.combat.v90.primary_pressed("solo",mobile.attacking if mobile.enabled else Input.is_action_pressed("primary")):
		fire("primary")
	if not studio_live.active() and stun_time <= 0 and charge_time <= 0 and level >= 3 and Input.is_action_pressed("secondary"):
		fire("secondary")
	if not studio_live.active() and stun_time <= 0 and level >= 6 and Input.is_action_just_pressed("special"):
		pulse()
	update_bullets(delta)
	if not combat_frame_active(epoch): return
	update_allies(delta)
	if not combat_frame_active(epoch): return
	if mistglass_rift!=null and mistglass_rift.active:mistglass_rift.step(delta)
	else:update_enemies(delta)
	if not combat_frame_active(epoch): return
	update_enemy_shots(delta)
	if not combat_frame_active(epoch): return
	maybe_spawn_boss()

func max_health() -> float:
	var total:float = float(hero.get("max_health", 100)) * (legacy.hp_factor("solo") if legacy!=null else 1.0) + bonus_health
	for carried_id in inventory:
		var carried: Dictionary = items.get(carried_id,{})
		if str(carried.get("effect", "")) == "bonus_health": total += float(carried.get("amount",0))
	if waylight!=null:total*=1+waylight.combat.bonus("vitality")
	return total

func aim_direction() -> Vector2:
	if adventure.combat.held_cast.context.has("solo"):return adventure.combat.vec(adventure.combat.held_cast.context.solo.aim)
	if mobile.enabled: return mobile.aim
	var direction := (media_mouse_world() - position_in_world).normalized()
	return direction if direction.length_squared() > 0.01 else Vector2.RIGHT

func aimed_point(max_range: float) -> Vector2:
	if adventure.combat.held_cast.context.has("solo"):return adventure.combat.held_cast.release_point("solo",max_range)
	if mobile.enabled: return position_in_world + mobile.aim * max_range
	var mouse_world := media_mouse_world()
	return position_in_world + aim_direction() * minf(max_range, position_in_world.distance_to(mouse_world))

func fire(kind: String) -> void:
	if preload("res://scripts/ability_guide.gd").blocks(self):return
	if fishing!=null and fishing.busy():return
	if not dev_magic.aiming.is_empty() or Time.get_ticks_msec()<dev_magic.input_until:return
	if studio_live.active():return
	if adventure.combat.held_cast.suppressed("solo",kind):return
	if adventure.combat.v90.pending_rebirth("solo"):return
	if adventure.immersive.aboard("solo"):return
	if not adventure.combat.robot.allowed("solo",kind):return
	if adventure.combat.busy("solo") or adventure.combat.stunned("p:solo"):return
	if float(cooldowns[kind]) > 0.0:
		return
	var stats: Dictionary = adventure.combat.effective_stats("solo",kind,hero[kind])
	adventure.combat.v79.prepare("solo",stats,aim_direction(),aimed_point(float(stats.get("range",300))))
	if not adventure.combat.stance_heroes.prepare("solo",stats):return
	if not adventure.combat.party_heroes.prepare("solo",stats):return
	if not adventure.combat.morrow.prepare("solo",stats,aim_direction()):return
	if not adventure.combat.v78.prepare("solo",stats):
		message="Place two rift pins before using Quarter Turn.";message_time=2;return
	if not adventure.combat.pact.prepare("solo",stats,aim_direction(),aimed_point(float(stats.get("range",650)))):
		message="Choose a visible non-boss enemy for Change of Heart.";message_time=2;return
	if not adventure.combat.agent.prepare("solo",stats,aim_direction(),aimed_point(float(stats.get("range",650)))):
		message="Aim at an enemy for Ambush.";message_time=2;return
	if not adventure.combat.v90.pistol_ready("solo",stats):return
	var delay := float(stats.get("cooldown", 0.5))
	if level >= 5 and str(hero.get("passive_effect", "")) == "quick_primary" and kind == "primary":
		delay *= 0.7 if mastery == "passive" else 0.8
	if upgrade == "secondary" and kind == "secondary":
		delay *= 0.7
	if level >= 5 and str(hero.get("passive_effect", "")) == "quick_secondary" and kind == "secondary": delay *= 0.8
	for carried_id in inventory:
		var cooldown_item: Dictionary = items.get(carried_id, {})
		if str(cooldown_item.get("effect", "")) == "cooldown": delay *= 1.0 - float(cooldown_item.get("amount", 0)) / 100.0
	delay=adventure.combat.v90.pistol_delay("solo",stats,delay)
	cooldowns[kind] = delay
	var direction := aim_direction()
	var damage := float(stats.get("damage", 15)) + bonus_damage
	if upgrade == "primary" and kind == "primary":
		damage += 8
	for item_id in inventory:
		var item: Dictionary = items.get(item_id, {})
		if str(item.get("effect", "")) == "bonus_damage":
			damage += float(item.get("amount", 0))
	var attack_style := str(stats.get("style", "projectile"))
	journey.cue(presentation.sound_for(attack_style))
	attack_pose_time = 0.24
	if stealth_time > 0 and stealth_ambush:
		damage *= 2.0
		stealth_time = 0.0
		stealth_ambush = false
		add_float_text(position_in_world - Vector2(35, 65), "AMBUSH x2", Color("#c0fae0"))
	if adventure.combat.cast("solo",stats,direction,damage):return
	if attack_style in ["melee", "punch", "scratch", "slash", "kick"]:
		strike_style = attack_style
		strike_stats = stats
		strike_direction = direction
		strike_time = 0.18
		for melee_index in range(enemies.size() - 1, -1, -1):
			var melee_target: Dictionary = enemies[melee_index]
			var offset: Vector2 = melee_target["pos"] - position_in_world
			var angle_limit := cos(deg_to_rad(float(stats.get("arc_degrees", 105)) * 0.5))
			if offset.length() <= float(stats.get("range", 82)) + float(melee_target.get("hit_radius",22 if melee_target["boss"] else 0)) and direction.dot(offset.normalized()) > angle_limit and (not adventure.school.active or shot_path_clear(position_in_world,melee_target.pos)):
				adventure.combat.apply_hit_status(adventure.combat.npc_key(melee_target),stats,"solo")
				damage_enemy(melee_index, damage)
	elif attack_style == "flame":
		flame_bursts.append({"time":float(stats.get("duration",.9)),"tick":0.0,"ticks":5,"stats":stats,"damage":float(stats.get("damage",8))+(damage-float(stats.get("damage",8)))/5.0})
	elif attack_style == "spin":
		strike_style = "spin"
		strike_stats = stats
		strike_time = 0.28
		for spin_index in range(enemies.size() - 1, -1, -1):
			if position_in_world.distance_to(enemies[spin_index]["pos"]) <= float(stats.get("range", 125)):
				damage_enemy(spin_index, damage)
	elif attack_style == "charge":
		charge_direction = direction
		charge_speed=float(stats.get("speed",900))
		charge_time = float(stats.get("range", 235)) / charge_speed
		charge_damage = damage
		charge_hits.clear()
		
	elif attack_style == "homing":
		spawn_hero_projectiles(stats,damage,direction,true)
	elif attack_style == "heal_wave":
		attack_effects.append({"center":position_in_world,"radius":float(stats.get("radius",180)),"time":.5,"visual":str(stats.get("visual","")),"color":Color("#a7e99b")})
		health = minf(max_health(), health + float(stats.get("heal", 25))*adventure.combat.v98.heal_factor("solo"))
		if practice and position_in_world.distance_to(training_yard.ALLY)<=float(stats.get("radius",180)):training_yard.heal(self,float(stats.get("heal",25)))
	elif attack_style == "trap":
		cast_target_aoe(stats, damage, direction)
	elif attack_style == "return_disc":
		adventure.launch_disc("solo",direction,stats,damage)
	elif attack_style == "chain":
		cast_chain(stats, damage, direction)
	elif attack_style == "target_aoe":
		if float(stats.get("travel_speed",0)) > 0: adventure.launch_lob("solo",position_in_world,aimed_point(float(stats.get("range",330))),stats,damage)
		else: cast_target_aoe(stats, damage, direction)
	elif attack_style == "block":
		activate_block(stats)
	else:
		spawn_hero_projectiles(stats,damage,direction,false)

func cast_chain(stats: Dictionary, damage: float, _direction: Vector2) -> void:
	if stats.get("visual","")=="golf_ricochet":
		adventure.combat.golf.launch("solo",position_in_world,aimed_point(float(stats.get("range",440))),stats,damage);return
	if bool(stats.get("fork",false)):
		cast_fork(stats,damage,_direction)
		return
	var aim_point := aimed_point(float(stats.get("range", 300)))
	var origin := position_in_world
	var already_hit: Array[int] = []
	for jump_index in range(int(stats.get("jumps", 3))):
		var target_index := -1
		var nearest := INF
		for index in enemies.size():
			if already_hit.has(int(enemies[index]["uid"])):
				continue
			var distance: float = enemies[index]["pos"].distance_to(aim_point if jump_index == 0 else origin)
			if jump_index == 0 and position_in_world.distance_to(enemies[index]["pos"]) > float(stats.get("range", 300)):
				continue
			if distance < nearest and distance < (145.0 if jump_index == 0 else float(stats.get("jump_range", 220))) and shot_path_clear(origin,enemies[index]["pos"]):
				nearest = distance
				target_index = index
		if target_index < 0:
			break
		var target: Dictionary = enemies[target_index]
		var target_position: Vector2 = target["pos"]
		already_hit.append(int(target["uid"]))
		attack_effects.append({"start": origin, "end": target_position, "time": 0.32, "color": Color("#edaa65")})
		damage_enemy(target_index, damage * pow(0.8, jump_index))
		origin = target_position

func cast_fork(stats: Dictionary, damage: float, direction: Vector2) -> void:
	var hit: Array[int] = []
	for bolt in mini(3,int(stats.get("jumps",3))):
		var target := -1
		var nearest := INF
		for index in enemies.size():
			var offset: Vector2 = enemies[index]["pos"]-position_in_world
			if hit.has(int(enemies[index]["uid"])) or offset.length()>float(stats.get("range",350)): continue
			if offset.normalized().dot(direction)<0.25 or not shot_path_clear(position_in_world,enemies[index]["pos"]): continue
			if offset.length()<nearest: nearest=offset.length();target=index
		if target<0: break
		var foe: Dictionary = enemies[target]
		hit.append(int(foe["uid"]))
		attack_effects.append({"start":position_in_world,"end":foe["pos"],"time":.32,"lightning":true,"color":Color(str(stats.get("color","#b8daff")))})
		damage_enemy(target,damage)

func cast_target_aoe(stats: Dictionary, damage: float, _direction: Vector2) -> void:
	var target := aimed_point(float(stats.get("range", stats.get("radius", 300))))
	var blast_radius := float(stats.get("blast_radius", 110))
	attack_effects.append({"center": target, "radius": blast_radius, "time": 0.42, "color": Color.html(str(stats.get("color", "#e6ac75")))})
	for index in range(enemies.size() - 1, -1, -1):
		if enemies[index]["pos"].distance_to(target) <= blast_radius:
			damage_enemy(index, damage)

func activate_block(stats: Dictionary) -> void:
	block_time = maxf(block_time, float(stats.get("duration", 2.0)))
	block_reduction = float(stats.get("reduction", 0.7))
	block_reflect = bool(stats.get("reflect", false)) or inventory.has("mirror_shard")
	if inventory.has("guard_buckler"):
		block_time += 0.3
		block_reduction = minf(0.95, block_reduction + 0.15)
	add_float_text(position_in_world + Vector2(-25, -65), "BLOCK", Color("#a9ddef"))

func pulse() -> void:
	if preload("res://scripts/ability_guide.gd").blocks(self):return
	if fishing!=null and fishing.busy():return
	if studio_live.active():return
	if adventure.combat.held_cast.suppressed("solo","special"):return
	if adventure.combat.v90.pending_rebirth("solo"):return
	if adventure.combat.busy("solo") or adventure.combat.stunned("p:solo"):return
	if float(cooldowns["special"]) > 0.0:
		return
	var stats: Dictionary = adventure.combat.effective_stats("solo","special",hero["special"])
	adventure.combat.v79.prepare("solo",stats,aim_direction(),aimed_point(float(stats.get("range",650))))
	if not adventure.combat.stance_heroes.prepare("solo",stats):return
	if not adventure.combat.party_heroes.prepare("solo",stats):return
	if not adventure.combat.morrow.prepare("solo",stats,aim_direction()):return
	if not adventure.combat.pact.prepare("solo",stats,aim_direction(),aimed_point(float(stats.get("range",650)))):
		message="Aim at a visible non-boss enemy for Change of Heart.";message_time=3;return
	cooldowns["special"] = float(stats.get("cooldown", 7.0)) * (0.7 if mastery == "special" else 1.0)
	pulse_time = 0.28
	pulse_position = position_in_world
	special_direction = aim_direction()
	var special_style := str(stats.get("style", "stomp"))
	journey.cue(presentation.sound_for(special_style))
	if adventure.combat.cast("solo",stats,special_direction,float(stats.get("damage",0))):pulse_time=0;return
	if special_style in ["projectile","homing"]:
		spawn_hero_projectiles(stats,float(stats.get("damage",20)),special_direction,special_style == "homing")
		return
	if special_style == "chain":
		cast_chain(stats,float(stats.get("damage",34)),special_direction)
		return
	if special_style == "stealth":
		stealth_ambush = true
		stealth_time = float(stats.get("duration", 3.0))
		health = minf(max_health(), health + float(stats.get("heal", 30))*adventure.combat.v98.heal_factor("solo"))
		add_float_text(position_in_world + Vector2(-36, -60), "+30 HP  STEALTH", Color("#b9e4c3"))
		return
	if special_style == "ice_wall":
		adventure.launch_lob("solo",position_in_world,aimed_point(float(stats.get("range",340))),stats,float(stats.get("damage",35)))
		return
	if special_style == "heal_zone":
		adventure.create_healing_zone("solo",stats)
		return
	if special_style == "heal_wave":
		if stats.get("visual","")=="medic_pulse":attack_effects.append({"center":position_in_world,"radius":float(stats.get("radius",155)),"time":.5,"visual":"medic_pulse"})
		health = minf(max_health(), health + float(stats.get("heal", 35))*adventure.combat.v98.heal_factor("solo"))
		if practice and position_in_world.distance_to(training_yard.ALLY)<=float(stats.get("radius",180)):training_yard.heal(self,float(stats.get("heal",35)))
		add_float_text(position_in_world - Vector2(20, 60), "+HEAL", Color("#91efad"))
		return
	if special_style == "summon":
		for ally_index in int(stats.get("count", 1)):
			allies.append({"pos": position_in_world + Vector2(45 + ally_index * 25, 30), "time": float(stats.get("duration", 12.0)) + (2 if adventure.combat.passive("solo","long_buddies") else 0), "attack_timer": 0.3, "damage": float(stats.get("damage", 20)), "speed": float(stats.get("minion_speed", 270)), "sprite": str(stats.get("minion_sprite", "mini_basketball"))})
		return
	if special_style == "block":
		activate_block(stats)
		return
	if special_style == "target_aoe":
		if float(stats.get("travel_speed",0))>0:adventure.launch_lob("solo",position_in_world,aimed_point(float(stats.get("range",330))),stats,float(stats.get("damage",50)))
		else:cast_target_aoe(stats, float(stats.get("damage", 50)), special_direction)
		return
	for i in range(enemies.size() - 1, -1, -1):
		var offset: Vector2 = enemies[i]["pos"] - position_in_world
		var in_range := offset.length() < float(stats.get("radius", 135))
		if special_style == "beam":
			var forward := offset.dot(special_direction)
			in_range = forward > 0 and forward < float(stats.get("radius", 570)) and absf(offset.cross(special_direction)) < 45
		if in_range:
			damage_enemy(i, float(stats.get("damage", 50)))

func use_item_slot(slot: int) -> void:
	slot=preload("res://scripts/supply_slots.gd").index(inventory,slot,items)
	if mode != "run" or menu != "" or slot < 0 or slot >= inventory.size():
		return
	var item: Dictionary = items.get(inventory[slot], {})
	var effect := str(item.get("effect", ""))
	if effect in ["bonus_damage", "bonus_speed", "lifesteal", "armor", "bonus_health", "block_boost", "reflect", "cooldown", "bounty", "thorns", "revive"]:
		return
	if effect == "heal" and health >= max_health():
		return
	inventory.remove_at(slot)
	if effect == "heal":
		health = minf(max_health(), health + float(item.get("amount", 0))*adventure.combat.v98.heal_factor("solo"))
	elif effect == "cleanse":
		adventure.combat.v90.cleanse("p:solo",["poison","burn","bleed"])
	elif effect == "lodge_guard":
		adventure.combat.apply_status("p:solo","guard",float(item.get("duration",4)),"solo",float(item.get("amount",15))/100.0)
	elif effect == "invulnerable":
		invulnerable_time = float(item.get("amount", 0))
	elif effect == "haste":
		haste_time = float(item.get("duration", 5))
		haste_multiplier = 1.0 + float(item.get("amount", 30)) / 100.0
	elif effect == "shockwave":
		var radius := float(item.get("radius", 140))
		attack_effects.append({"center": position_in_world, "radius": radius, "time": 0.35})
		for index in range(enemies.size() - 1, -1, -1):
			if position_in_world.distance_to(enemies[index]["pos"]) <= radius:
				damage_enemy(index, float(item.get("amount", 35)))

func update_bullets(delta: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[i]
		var stats: Dictionary = bullet["stats"]
		var travel := float(stats.get("speed", 500)) * delta
		if bool(bullet.get("homing", false)) and not enemies.is_empty():
			var nearest: Vector2 = enemies[0]["pos"]
			for target in enemies:
				if bullet["pos"].distance_squared_to(target["pos"]) < bullet["pos"].distance_squared_to(nearest): nearest = target["pos"]
			bullet["direction"] = (bullet["direction"] * 0.85 + (nearest - bullet["pos"]).normalized() * 0.15).normalized()
		var bullet_next: Vector2 = bullet["pos"] + bullet["direction"] * travel
		if not shot_path_clear(bullet["pos"], bullet_next):
			bullets.remove_at(i)
			continue
		bullet["pos"] = bullet_next
		bullet["distance"] += travel
		if not clear_of_obstacles(bullet["pos"], 5.0):
			bullets.remove_at(i)
			continue
		var collided := false
		for j in range(enemies.size() - 1, -1, -1):
			if bullet["pos"].distance_to(enemies[j]["pos"]) < float(enemies[j].get("hit_radius",43 if enemies[j]["boss"] else 29)):
				damage_enemy(j, float(bullet["damage"]))
				collided = true
				break
		if collided or float(bullet["distance"]) > float(stats.get("range", 500)):
			bullets.remove_at(i)
		else:
			bullets[i] = bullet

func update_allies(delta: float) -> void:
	for ally_index in range(allies.size() - 1, -1, -1):
		var ally: Dictionary = allies[ally_index]
		ally["time"] = float(ally["time"]) - delta
		if float(ally["time"]) <= 0:
			allies.remove_at(ally_index)
			continue
		ally["attack_timer"] = maxf(0.0, float(ally["attack_timer"]) - delta)
		var target_position := position_in_world + Vector2(48 + ally_index * 28, 34)
		var nearest_enemy := -1
		var nearest_distance := 155.0
		for enemy_index in enemies.size():
			var distance: float = ally["pos"].distance_to(enemies[enemy_index]["pos"])
			if distance < nearest_distance:
				nearest_enemy = enemy_index
				nearest_distance = distance
		if nearest_enemy >= 0:
			target_position = enemies[nearest_enemy]["pos"]
		var offset: Vector2 = target_position - ally["pos"]
		if offset.length() > 40:
			ally["pos"] += offset.normalized() * minf(offset.length() - 35, float(ally["speed"]) * delta)
		if nearest_enemy >= 0 and ally["pos"].distance_to(enemies[nearest_enemy]["pos"]) < 65 and float(ally["attack_timer"]) <= 0:
			damage_enemy(nearest_enemy, float(ally["damage"]))
			ally["attack_timer"] = 0.8
		allies[ally_index] = ally

func maybe_spawn_boss() -> void:
	if waylight!=null and waylight.between():return
	if tutorial.active:return
	if adventure.active or adventure.vault.active or adventure.quests.active or adventure.expansion.active or adventure.school.active or adventure.tech.active or adventure.immersive.active or adventure.foundry.active or adventure.cinder.active: return
	var waiting_for_defenders=not enemies.filter(func(e):return not bool(e.get("summoned",false)) and not bool(e.get("converted",false))).is_empty() if region_id=="zombie" else kills < region.get("enemies", []).size()
	if mode != "run" or boss_spawned or waiting_for_defenders:
		return
	boss_spawned = true
	if waylight!=null and waylight.kind=="overcharge":
		for i in range(enemies.size()-1,-1,-1):
			if not enemies[i].has("waylight_event"):enemies.remove_at(i)
	else:enemies.clear() # Summoned enemies do not delay the boss encounter.
	enemy_shots.clear()
	var boss_hp := float(region.get("boss_health", 350))
	enemies.append({"pos": pair(region["boss"]), "hp": boss_hp, "max_hp": boss_hp, "attack_timer": 0.0, "secondary_timer": 3.0, "windup": 0.0, "boss": true, "type": str(region["boss_enemy"]) if region.has("boss_enemy") else "cartographer" if adventure.combat.coast.active else "eclipse_engine" if adventure.astral else "hourglass_hart" if adventure.clockwork else "crowned_torrent" if adventure.river else "bellroot" if adventure.marsh else "boss", "expansion_boss":region.has("boss_enemy") or adventure.combat.coast.active or adventure.marsh or adventure.river or adventure.clockwork or adventure.astral,"skill_timer":2.0,"skill_step":0,"uid": 1000000})
	message = str(region.get("name", "Realm")) + " Guardian has appeared!"
	message_time = 5.0

func damage_enemy(index: int, amount: float) -> void:
	if index<0 or index>=enemies.size():return
	amount*=adventure.pursuers.outgoing("solo")
	if waylight!=null:amount=waylight.combat.damage(amount)
	if mistglass_rift!=null and mistglass_rift.active:mistglass_rift.damage(index,amount);return
	if tutorial.active:tutorial.damage(index,amount);return
	if not adventure.expansion.sharing:
		amount*=adventure.combat.war_multiplier("solo")
		if index>=0 and index<enemies.size() and not bool(enemies[index].get("converted",false)):amount=legacy.critical("solo",amount,enemies[index].pos)
	var enemy: Dictionary = enemies[index]
	if bool(enemy.get("converted",false)):amount=float(enemy.hp)
	if bool(enemy.get("buried",false)):return
	journey.cue("hit")
	if not bool(enemy.get("converted",false)):adventure.combat.feedback.hit(enemy.pos,minf(amount,maxf(0,float(enemy.hp))))
	if practice:
		adventure.combat.v112.on_hit("solo",adventure.combat.npc_key(enemy),minf(amount,float(enemy.hp)))
		adventure.combat.v90.on_hit("solo",minf(amount,float(enemy.hp)))
		training_hits += 1
		if training_hits >= 3: mark_welcome("practice")
		add_float_text(enemy["pos"] + Vector2(-18,-42), "-" + str(int(amount)), Color("#ffe28f"))
		enemy_flashes[int(enemy["uid"])] = 0.16
		enemy["hp"] = float(enemy["hp"]) - amount
		if float(enemy["hp"]) <= 0: enemy["hp"] = enemy["max_hp"]
		return
	var actual_damage := 0.0 if bool(enemy.get("converted",false)) else minf(amount, maxf(0.0, float(enemy["hp"])))
	adventure.combat.v112.on_hit("solo",adventure.combat.npc_key(enemy),actual_damage)
	adventure.combat.v90.on_hit("solo",actual_damage)
	adventure.expansion.linked_hit(adventure.combat.npc_key(enemy),actual_damage)
	if waylight!=null:waylight.combat.hit(enemy,actual_damage)
	dealt_damage += actual_damage
	legacy.add_damage(character_id,actual_damage)
	var steal := 0.0
	if level >= 5 and str(hero.get("passive_effect", "")) == "life_steal":
		steal = 0.13 if mastery == "passive" else float(hero.get("passive_amount", 0.08))
	for carried_id in inventory:
		var carried: Dictionary = items.get(carried_id, {})
		if str(carried.get("effect", "")) == "lifesteal":
			steal += float(carried.get("amount", 0)) / 100.0
	if adventure.pursuers.leech_blocked("solo"):steal=0
	if steal > 0:
		health = minf(max_health(), health + actual_damage * steal*adventure.combat.v98.heal_factor("solo"))
	add_float_text(enemy["pos"] + Vector2(-18, -42), "ALLY" if bool(enemy.get("converted",false)) else "-" + str(int(amount)), Color("#ffe28f"))
	enemy_flashes[int(enemy["uid"])] = 0.16
	enemy["hp"] = float(enemy["hp"]) - amount
	if enemy["boss"] and int(enemy["uid"]) == 1000000 and bool(region.get("boss_split", false)) and not boss_split_triggered and float(enemy["hp"]) <= float(enemy["max_hp"]) * 0.5:
		boss_split_triggered = true
		var split_point: Vector2 = enemy["pos"]
		enemies.remove_at(index)
		for fragment_index in 2:
			var fragment_position := split_point + Vector2(-125 if fragment_index == 0 else 125, -60 if fragment_index == 0 else 60)
			enemies.append({"pos": fragment_position, "hp": 240.0 if region_id=="quarry" else 300.0, "max_hp": 240.0 if region_id=="quarry" else 300.0, "attack_timer": 0.0, "secondary_timer": 3.5 + fragment_index, "windup": 0.0, "boss": true, "type": "fragment", "uid": 1000001 + fragment_index})
		add_float_text(split_point, "SPLIT! TWO GUARDIANS", Color("#ffb987"))
		message = "The Quarry Guardian split in two! Defeat both fragments."
		message_time = 7.0
		return
	if float(enemy["hp"]) <= 0:
		if adventure.expansion.revive_intercept(enemy):return
		adventure.combat.morrow.fallen(enemy)
		adventure.combat.robot.on_kill("solo")
		var was_boss: bool = enemy["boss"]
		if was_boss and presentation!=null:presentation.burst(enemy.pos);journey.cue("victory")
		enemies.remove_at(index)
		if waylight!=null and waylight.defeated(enemy):return
		if not bool(enemy.get("summoned",false)):
			var cc=40 if was_boss else 6+posmod(int(enemy.get("uid",kills)),3)
			cc+=2 if inventory.has("gold_magnet") else 0
			gold+=cc;bounty_earned+=cc
			add_float_text(enemy.pos+Vector2(-22,-68),"+"+str(cc)+" CC",Color("#f3d697"))
		if adventure.on_defeat(enemy):
			grant_enemy_xp(50)
			return
		adventure.check_trial_clear(enemy)
		if was_boss:
			var remaining_guardians := 0
			for guardian in enemies:
				if guardian["boss"]:
					remaining_guardians += 1
			if remaining_guardians == 0:
				boss_defeated = true
				message = "Boss defeated! Enter the new portal to finish."
				message_time = 8.0
		elif not bool(enemy.get("summoned", false)):
			kills += 1
			experience += 10
			add_float_text(enemy["pos"] + Vector2(-22, -90), "+10 XP", Color("#a9ecba"))
			if level >= 5 and str(hero.get("passive_effect", "")) == "heal_on_kill":
				health = minf(max_health(), health + (8.0 if mastery == "passive" else 4.0))
			if kills % 10 == 0 and not trial:
				health = minf(max_health(), health + 35.0)
				add_float_text(position_in_world + Vector2(-24, -62), "+35 HP", Color("#a9ecba"))
			if level < 10 and experience >= level * int(region.get("xp_per_level", 5)) * 10:
				level += 1
				if level <= highest_level: return
				highest_level = level
				message = "LEVEL " + str(level) + "!"
				message_time = 4.0
				add_float_text(position_in_world + Vector2(-20, -70), "LEVEL " + str(level), Color("#f7e7a2"))
				menu = "levelup"
	else:
		enemies[index] = enemy

func level_award_text() -> String:
	match level:
		2, 4, 7, 9: return "Choose a stat: [1] +25 maximum HP (and heal 25)   [2] +4 damage   [3] +20 speed"
		3: return "SECONDARY ATTACK: " + str(hero["secondary"].get("name", "Secondary")) + ". Right click to use it."
		5: return "PASSIVE ACTIVE: " + str(hero.get("passive", ""))
		6: return "SPECIAL UNLOCKED: " + str(hero["special"].get("name", "Special")) + ". Press Space."
		8: return "Choose: [1] +8 primary damage   [2] 30% faster secondary cooldown"
		10: return "Choose mastery: [1] 30% faster special   [2] stronger passive"
	return ""

func update_enemies(delta: float) -> void:
	delta*=dev_magic.world_scale()
	var epoch := combat_epoch
	for i in enemies.size():
		if not combat_frame_active(epoch) or i >= enemies.size(): return
		var enemy: Dictionary = enemies[i]
		enemy["strike_flash"]=maxf(0,float(enemy.get("strike_flash",0))-delta)
		if bool(enemy.get("roaming_actor",false)) or bool(enemy.get("immersive",false)) or str(enemy.get("type","")) in adventure.additions.TYPES or str(enemy.get("type","")) in adventure.newcomers.TYPES:continue
		if bool(enemy.get("veilbound",false)) or str(enemy.get("type","")) in adventure.cinder.TYPES or str(enemy.get("type","")) in adventure.foundry.TYPES or str(enemy.get("type","")) in adventure.clockfield.TYPES or str(enemy.get("type","")) in adventure.tech.TYPES or str(enemy.get("type","")) in adventure.school.TYPES or str(enemy.get("type","")) in adventure.expansion.TYPES or str(enemy.get("type","")) in adventure.hollow.TYPES or str(enemy.get("type","")) in adventure.city.TYPES or bool(enemy.get("vault_actor",false)) or adventure.combat.stunned(adventure.combat.npc_key(enemy)):continue
		if enemy.get("expansion_boss",false): continue
		if tutorial.active and tutorial.update_melee(enemy,delta):continue
		var definition: Dictionary = enemy_types.get(enemy.get("type", ""), {}).duplicate()
		definition["speed"]=float(definition.get("speed",65))*adventure.combat.speed_factor(adventure.combat.npc_key(enemy))
		var target_point:Vector2=position_in_world
		var leaf:Dictionary=adventure.combat.fern.decoy_for(enemy.pos)
		if not enemy.boss and not leaf.is_empty() and adventure.combat.path_clear(enemy.pos,adventure.combat.vec(leaf.pos)):target_point=adventure.combat.vec(leaf.pos)
		var diff: Vector2 = target_point - enemy["pos"]
		enemy["attack_timer"] = maxf(0.0, float(enemy["attack_timer"]) - delta)
		if preload("res://scripts/starter_boss.gd").managed(region_id,enemy) and not tutorial.active:
			var swing:int=preload("res://scripts/starter_boss.gd").advance(enemy,position_in_world,delta,stealth_time<=0)
			if swing>0:
				if swing==2 and stealth_time<=0 and preload("res://scripts/starter_boss.gd").hits(enemy,position_in_world):
					take_player_damage((16.0 if str(enemy.type)=="fragment" else 22.0) if region_id=="quarry" else 25.0,adventure.combat.npc_key(enemy))
				continue
		if enemy["boss"]:
			preload("res://scripts/ice_projectiles.gd").step_boss(self,enemy,delta)
			enemy["secondary_timer"] = maxf(0.0, float(enemy.get("secondary_timer", 3.0)) - delta)
			if float(enemy.get("windup", 0.0)) > 0.0:
				enemy["windup"] = float(enemy["windup"]) - delta
				if float(enemy["windup"]) <= 0.0 and stealth_time <= 0:
					enemy["strike_flash"]=.35;enemy["strike_direction"]=(position_in_world-enemy.pos).normalized()
					if str(region.get("boss_secondary", "stomp")) == "fireball":
						var aim: Vector2 = position_in_world - enemy["pos"]
						if aim.length() > 0:
							enemy_shots.append({"credit":preload("res://scripts/defeat_credit.gd").resolve(self,adventure.combat.npc_key(enemy),"Projectile"),"pos": enemy["pos"], "direction": aim.normalized(), "damage": 20.0 if region_id=="quarry" else 24.0, "speed": 225.0 if region_id=="quarry" else 245.0, "distance": 0.0, "fireball": true})
					elif str(region.get("boss_secondary", "stomp")) in ["sunburst", "frostburst", "seekerstorm", "sporeburst"]:
						for ray in 10:
							var angle := TAU * float(ray) / 10.0 + visual_clock * 0.35
							enemy_shots.append({"credit":preload("res://scripts/defeat_credit.gd").resolve(self,adventure.combat.npc_key(enemy),"Projectile"),"pos": enemy["pos"], "direction": Vector2.RIGHT.rotated(angle), "damage": 15.0, "speed": 280.0, "distance": 0.0, "fireball": str(region.get("boss_secondary", ""))!="frostburst", "ice_visual":"orb" if str(region.get("boss_secondary", ""))=="frostburst" else "", "homing": str(region.get("boss_secondary", "")) == "seekerstorm"})
					elif enemy["pos"].distance_to(position_in_world) < 175 and stealth_time <= 0:
						stun_time = maxf(stun_time, 1.0)
						take_player_damage(12.0,"",preload("res://scripts/defeat_credit.gd").resolve(self,adventure.combat.npc_key(enemy),str(region.get("boss_secondary","stomp")).capitalize()))
						if not combat_frame_active(epoch): return
						add_float_text(position_in_world + Vector2(-25, -74), "STUNNED 1s", Color("#f7c384"))
			elif float(enemy["secondary_timer"]) <= 0 and diff.length() < 550 and stealth_time <= 0:
				enemy["windup"] = 0.8
				enemy["secondary_timer"] = 5.0 if str(enemy["type"]) == "fragment" else (4.8 if region_id=="quarry" else 4.0)
		if str(definition.get("behaviour", "")) == "summoner":
			enemy["summon_timer"] = maxf(0.0, float(enemy.get("summon_timer", 1.5)) - delta)
			if stealth_time <= 0 and diff.length() < float(definition.get("aggro_range", 450)):
				var nearby_minions := 0
				for spawned_enemy in enemies:
					if int(spawned_enemy.get("summoned_by", -1)) == int(enemy["uid"]):
						nearby_minions += 1
				if nearby_minions < int(definition.get("max_summons", 2)) and float(enemy["summon_timer"]) <= 0:
					var minion_id := str(definition.get("summon_type", "imp"))
					var minion_stats: Dictionary = enemy_types.get(minion_id, {})
					if not minion_stats.is_empty():
						next_enemy_uid += 1
						var minion_hp := float(minion_stats.get("health", 25))
						enemies.append({"pos": enemy["pos"] + Vector2(55, 45), "hp": minion_hp, "max_hp": minion_hp, "attack_timer": 0.6, "boss": false, "type": minion_id, "uid": next_enemy_uid, "summoned": true, "summoned_by": int(enemy["uid"])})
						add_float_text(enemy["pos"] + Vector2(-25, -60), "SUMMON!", Color("#d4b2e9"))
					enemy["summon_timer"] = float(definition.get("summon_cooldown", 5.0))
			if diff.length() < float(definition.get("aggro_range",460)):
				move_enemy_around_obstacles(enemy, adventure.combat.ranged_direction(enemy,target_point)*float(definition.get("speed",70))*delta, bool(definition.get("flying",false)))
			continue
		if str(definition.get("behaviour", "")) in ["ranged", "burst_ranged", "dual_ranged", "homing"]:
			if stealth_time > 0:
				continue
			if diff.length() < float(definition.get("aggro_range",490)):
				move_enemy_around_obstacles(enemy, adventure.combat.ranged_direction(enemy,target_point)*float(definition.get("speed",95))*delta, bool(definition.get("flying",false)))
			if diff.length() < float(definition.get("aggro_range", 490)) and float(enemy["attack_timer"]) <= 0 and diff.length() > 0:
				if preload("res://scripts/ice_projectiles.gd").matches(str(enemy["type"])):
					preload("res://scripts/ice_projectiles.gd").fire(self,enemy,diff.normalized(),definition)
				elif str(enemy["type"]) == "lantern_moth":
					adventure.combat.launch_projectile("enemy",enemy["pos"],diff.normalized(),{"range":700,"speed":float(definition.get("shot_speed",275)),"amplitude":32,"wavelength":170,"color":"#e6b7fa"},float(definition.get("damage",9)),"weaving")
				elif str(definition.get("behaviour", "")) == "burst_ranged":
					for angle in [-0.22, 0.0, 0.22]:
						enemy_shots.append({"credit":preload("res://scripts/defeat_credit.gd").resolve(self,adventure.combat.npc_key(enemy),"Projectile"),"pos": enemy["pos"], "direction": diff.normalized().rotated(angle), "damage": float(definition.get("damage", 9)), "speed": float(definition.get("shot_speed", 275)), "distance": 0.0, "fireball": true})
				elif str(enemy["type"])=="archer":
					adventure.combat.launch_projectile("enemy",enemy["pos"],diff.normalized(),{"range":700,"speed":float(definition.get("shot_speed",275)),"thorn_arrow":true,"color":"#9ecb75"},float(definition.get("damage",9)))
				else:
					enemy_shots.append({"credit":preload("res://scripts/defeat_credit.gd").resolve(self,adventure.combat.npc_key(enemy),"Projectile"),"pos": enemy["pos"], "direction": diff.normalized(), "damage": float(definition.get("damage", 9)), "speed": float(definition.get("shot_speed", 275)), "distance": 0.0, "homing": str(definition.get("behaviour", "")) == "homing", "flying": bool(definition.get("flying", false))})
					if str(definition.get("behaviour", "")) == "dual_ranged":
						enemy_shots.append({"credit":preload("res://scripts/defeat_credit.gd").resolve(self,adventure.combat.npc_key(enemy),"Projectile"),"pos": enemy["pos"], "direction": diff.normalized().rotated(0.2), "damage": float(definition.get("damage", 9)) * 0.8, "speed": 200.0, "distance": 0.0})
				enemy["attack_timer"] = float(definition.get("shot_cooldown", 2.3))
		else:
			var enemy_speed := (145.0 if str(enemy["type"]) == "fragment" else 108.0) if enemy["boss"] else float(definition.get("speed", 72))
			if enemy["boss"]:enemy_speed*=adventure.combat.speed_factor(adventure.combat.npc_key(enemy))
			if stealth_time > 0:
				continue
			if diff.length() < (570 if enemy["boss"] else float(definition.get("aggro_range", 320))) and diff.length() > (46 if enemy["boss"] else 37):
				move_enemy_around_obstacles(enemy, (adventure.combat.ranged_direction(enemy,target_point) if adventure.combat.ranged_enemy(enemy,definition) else diff.normalized()) * enemy_speed * delta, bool(definition.get("flying", false)))
			if not preload("res://scripts/starter_boss.gd").managed(region_id,enemy) and not adventure.combat.ranged_enemy(enemy,definition) and diff.length() < (54 if enemy["boss"] else 41) and float(enemy["attack_timer"]) <= 0.0:
				var incoming := (18.0 if str(enemy["type"]) == "fragment" else 25.0) if enemy["boss"] else float(definition.get("damage", 9))
				if position_in_world.distance_to(enemy.pos)<65:
					enemy["strike_flash"]=.28;enemy["strike_direction"]=(position_in_world-enemy.pos).normalized()
					take_player_damage(incoming,adventure.combat.npc_key(enemy))
				if not combat_frame_active(epoch): return
				enemy["attack_timer"] = 1.2

func update_enemy_shots(delta: float) -> void:
	delta*=dev_magic.world_scale()
	var epoch := combat_epoch
	for shot_index in range(enemy_shots.size() - 1, -1, -1):
		if not combat_frame_active(epoch) or shot_index >= enemy_shots.size(): return
		var shot: Dictionary = enemy_shots[shot_index]
		if bool(shot.get("homing", false)):
			shot["direction"] = (shot["direction"] * 0.94 + (position_in_world - shot["pos"]).normalized() * 0.06).normalized()
		var travel := float(shot["speed"]) * delta
		var shot_next: Vector2 = shot["pos"] + shot["direction"] * travel
		var wall_hit := false
		for wall in ice_walls:
			if shot_next.distance_to(wall["pos"]) < float(wall["radius"]): wall_hit = true
		if wall_hit or not shot_path_clear(shot["pos"], shot_next, bool(shot.get("flying", false))):
			enemy_shots.remove_at(shot_index)
			continue
		if adventure.combat.v59.catch_copy(shot["pos"],shot_next,"enemy",float(shot["damage"])):enemy_shots.remove_at(shot_index);continue
		if adventure.combat.v56.catch_shot(shot["pos"],shot_next,"enemy",float(shot["damage"]),str(shot.get("color","#ed9b82")),true,shot):enemy_shots.remove_at(shot_index);continue
		shot["pos"] = shot_next
		shot["distance"] += travel
		if not bool(shot.get("flying", false)) and not clear_of_obstacles(shot["pos"], 5.0):
			enemy_shots.remove_at(shot_index)
			continue
		if shot["pos"].distance_to(position_in_world) < (12 if shot.get("fireball", false) else 6)+adventure.combat.v110.target_radius("p:solo",18):
			if block_time > 0 and block_reflect:
				for target_index in enemies.size():
					if shot["pos"].distance_to(enemies[target_index]["pos"]) < 340:
						damage_enemy(target_index, float(shot["damage"]) * 1.5)
						break
			else:
				take_player_damage(float(shot["damage"]),"",shot.get("credit",{}))
				if not combat_frame_active(epoch): return
			enemy_shots.remove_at(shot_index)
			if not combat_frame_active(epoch):
				return
		elif float(shot["distance"]) > 800:
			enemy_shots.remove_at(shot_index)
		else:
			enemy_shots[shot_index] = shot

func take_player_damage(amount: float, melee_attacker:String="", cause:Dictionary={}) -> void:
	if adventure.combat.v90.pending_rebirth("solo"):return
	var linked_direct:bool=adventure.combat.morrow.direct_owner=="solo"
	if not linked_direct:
		if adventure.combat.v78.immune("solo") or adventure.combat.stance_heroes.immune("solo"):return
		if amount>0 and not adventure.combat.dot_damage and adventure.combat.v90.smoke_dodges("solo"):return
		var before_reduction:float=amount
		amount*=legacy.hurt_factor("solo") if legacy!=null else 1.0
		if practice:amount=minf(amount,maxf(0,health-1))
		amount*=1.0-adventure.combat.reduction("solo")
		if studio_live.active():amount*=1.0-studio_live.reduction()
		if invulnerable_time > 0:
			return
		if not melee_attacker.is_empty():adventure.combat.melee_received("solo",melee_attacker)
		if block_time > 0:
			amount *= 1.0 - block_reduction
		if level >= 5 and str(hero.get("passive_effect", "")) == "guard": amount *= 0.9
		for carried_id in inventory:
			var carried: Dictionary = items.get(carried_id, {})
			if str(carried.get("effect", "")) == "armor": amount *= maxf(0.3, 1.0 - float(carried.get("amount", 0)) / 100.0)
		amount=adventure.combat.v79.erode("p:solo",before_reduction,amount)
		if practice:amount=minf(amount,maxf(0,health-1))
		if adventure.combat.classics.channeling("solo"):amount*=1.3
		amount=adventure.combat.mantis.on_damage("solo",amount)
		if amount<=0:return
	if waylight!=null:amount=waylight.incoming(amount,block_time>0)
	if amount<=0:return
	amount=adventure.combat.morrow.share_hero("solo",amount)
	adventure.combat.feedback.hit(position_in_world,minf(amount,maxf(0,health)),"solo")
	damage_taken += amount
	journey.cue("hurt")
	presentation.impact(false,amount)
	adventure.expansion.linked_hit("p:solo",minf(amount,health))
	health -= amount
	if studio_live!=null and studio_live.active():studio_live.received(amount)
	if amount>0 and not tutorial.active:provisions.check_auto()
	if inventory.has("thorn_coat"):
		for index in range(enemies.size()-1,-1,-1):
			if position_in_world.distance_to(enemies[index]["pos"]) < 85:
				damage_enemy(index, 9.0)
				break
	player_flash_time = 0.22
	add_float_text(position_in_world + Vector2(-16, -55), "-" + str(int(amount)) + " HP", Color("#ff8d8b"))
	if health <= 0:
		if adventure.combat.v59.rescue("solo"):return
		if inventory.has("last_stand"):
			inventory.erase("last_stand")
			health = 45
			add_float_text(position_in_world - Vector2(30, 80), "LAST STAND", Color("#fbd480"))
		else:
			if adventure.combat.v90.intercept_defeat("solo"):return
			last_defeat=cause.duplicate(true) if not cause.is_empty() else preload("res://scripts/defeat_credit.gd").resolve(self,melee_attacker,"Melee strike" if not melee_attacker.is_empty() else "Attack")
			finish_run(false)

func add_float_text(world_pos: Vector2, label: String, shade: Color) -> void:
	floating_text.append({"pos": world_pos, "label": label, "shade": shade, "time": 0.85})

var render_work:Dictionary={}
var town_perf=preload("res://network/performance_view.gd").new()
func _draw() -> void:
	var draw_began=Time.get_ticks_usec()
	var aquarium_open:bool=fishing!=null and is_instance_valid(fishing.room)
	if terrain_cache!=null:terrain_cache.visible=menu!="workshop" and not aquarium_open and not (session_menu!=null and session_menu.page in ["main","clear","options"])
	if menu=="workshop" or aquarium_open:return
	if session_menu!=null and session_menu.page in ["main","clear","options"]:return
	if region.is_empty():
		return
	var screen=VIEW;var magnify=media.factor()
	draw_set_transform(media.offset(),0,Vector2.ONE*magnify);VIEW=screen/magnify
	var world_began=Time.get_ticks_usec()
	draw_world()
	render_work["world"]=Time.get_ticks_usec()-world_began
	tutorial.draw_world(self,camera)
	adventure.draw_on(self,camera)
	if studio_live!=null:studio_live.draw_on(self,camera)
	if mode in ["town","run"] and not practice:preload("res://scripts/garden_hunting.gd").draw_on(self,camera)
	draw_flames()
	journey.draw_on(self,camera)
	if waylight!=null:waylight.draw_fog(self,camera);waylight.draw_world(self,camera)
	if mode=="town":
		var light_began=Time.get_ticks_usec()
		town_life.calendar.draw_lighting(self,camera)
		render_work["lighting"]=Time.get_ticks_usec()-light_began
		preload("res://scripts/town_afterglow.gd").draw_on(self,camera)
	if voyage!=null and voyage.active:voyage.draw_lighting(self,camera)
	VIEW=screen;draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	if (media.clean_view or media.capturing) and menu.is_empty():return
	draw_hud()
	if waylight!=null:waylight.draw_hud(self)
	journey.draw_hud(self)
	tutorial.draw_on(self)
	if menu.is_empty():adventure.quests.draw_hud(self);adventure.school.draw_hud(self);adventure.cinder.draw_hud(self);adventure.tech.draw_hud(self);adventure.immersive.draw_hud(self)
	if menu != "":
		draw_set_transform((VIEW-Vector2(1280,720))*0.5)
		draw_menu()
		draw_set_transform(Vector2.ZERO)

	render_work["draw"]=Time.get_ticks_usec()-draw_began
	if mode=="town":
		for key in ["draw","world","lighting"]:town_perf.work(key,int(render_work.get(key,0)))

var ground_tile_cache:Dictionary={}
var ground_index=preload("res://scripts/terrain_patch_index.gd").new()
var terrain_cache:Node2D
var realm_props:Node2D
func sync_terrain()->void:
	if terrain_cache==null:
		terrain_cache=preload("res://scripts/ground_cache.gd").new();terrain_cache.game=self;terrain_cache.show_behind_parent=true;add_child(terrain_cache)
	terrain_cache.sync()
func ground_tile_at(tx:int,ty:int,base:String)->String:
	var cell:=Vector2i(tx,ty)
	if ground_tile_cache.has(cell):return str(ground_tile_cache[cell])
	var tile:String=ground_index.tile(Vector2(tx*64+32,ty*64+32),base,ground_patches)
	if ground_tile_cache.size()>=4096:
		for old_cell in ground_tile_cache.keys().slice(0,256):ground_tile_cache.erase(old_cell)
	ground_tile_cache[cell]=tile
	return tile

func draw_world() -> void:
	if voyage!=null and voyage.active:
		if terrain_cache!=null:terrain_cache.hide()
		voyage.draw_ground(self,camera)
	elif waylight!=null and waylight.between() and mode=="run":
		if terrain_cache!=null:terrain_cache.hide()
		waylight.expedition.draw_ground(self,camera)
	elif region_id=="moonveil" and mode=="run":
		if terrain_cache!=null:terrain_cache.hide()
		preload("res://scripts/moon_castle.gd").draw(self,camera)
	else:sync_terrain()
	if practice:training_yard.draw_on(self,camera);town_chapter.draw_guide(self,camera)
	adventure.polish.draw_world(self,camera)
	if adventure.immersive.active:adventure.immersive.draw_world(self,camera)
	if adventure.foundry.active:adventure.foundry.draw_world(self,camera)
	if adventure.clockfield.active:adventure.clockfield.draw_world(self,camera)
	if adventure.cinder.active:adventure.cinder.draw_world(self,camera)
	if adventure.tech.active:adventure.tech.draw_world(self,camera)
	if adventure.school.active:adventure.school.draw_world(self,camera)
	if adventure.expansion.active:adventure.expansion.draw_world(self,camera)
	if adventure.quests.active:adventure.quests.draw_world(self,camera)
	if adventure.hollow.active:adventure.hollow.draw_world(self,camera)
	if adventure.city.active: adventure.city.draw_world(self,camera)
	if adventure.vault.active: adventure.vault.draw_world(self,camera)
	if adventure.combat.coast.active:adventure.combat.coast.draw_world(self,camera)
	motion_v85.draw_trails(self,camera)
	var retained_props:bool=mode=="run" and region_id=="moonveil"
	if retained_props and not is_instance_valid(realm_props):
		realm_props=preload("res://scripts/realm_props.gd").new();add_child(realm_props);realm_props.setup(self,false)
	if not retained_props:
		for decoration in decorations:
			var deco_texture: Texture2D = decoration["texture"]
			var deco_size: Vector2 = decoration["size"]
			if deco_texture != null and Rect2(camera - deco_size, VIEW + deco_size * 2).has_point(decoration["pos"]):
				draw_texture_rect(deco_texture, Rect2(decoration["pos"] - deco_size * 0.5 - camera, deco_size), false)
	for obstacle in obstacles:
		if bool(obstacle.get("town_hidden",false)): continue
		if Rect2(camera - Vector2(100, 100), VIEW + Vector2(200, 200)).has_point(obstacle["pos"]):
			var obstacle_texture: Texture2D = obstacle.get("texture")
			if obstacle_texture != null:
				draw_texture_rect(obstacle_texture, Rect2(obstacle["pos"] - Vector2(32, 48) - camera, Vector2(64, 84)), false)
			else:
				draw_sprite(str(obstacle["kind"]), obstacle["pos"] - Vector2(32, 48), Vector2(64, 84))
	if mode == "town":
		town_chapter.draw_ground(self,camera)
		town_plan.draw_ground(self,camera)
		if voyage!=null:voyage.draw_pier(self,camera)
		preload("res://scripts/town_v173.gd").draw_tracks(self,camera)
		idle_mine_town.draw_on(self,camera)
		commerce_town.draw_on(self,camera)
		town_chapter.draw_forest(self,camera)
		town_scenery.draw_on(self,camera,font)
		town_life.draw_world(self,camera,font)
		if marina_life!=null:marina_life.draw_on(self,camera)
		for landmark in town_art:
			if landmark.sprite in ["arena_stadium","town_lamp"]:continue
			var landmark_size: Vector2 = landmark["size"]
			var landmark_pos: Vector2 = landmark["pos"]
			if Rect2(camera - landmark_size, VIEW + landmark_size * 2).has_point(landmark_pos):
				if str(landmark.sprite)!="portal":draw_sprite(str(landmark["sprite"]), landmark_pos - landmark_size * 0.5, landmark_size)
				if str(landmark.sprite)=="portal":preload("res://scripts/town_v176.gd").draw_portal(self,camera)
				if not str(landmark["label"]).is_empty():
					if str(landmark.sprite)=="creator_board":
						var p:Vector2=landmark_pos-camera+Vector2(-30,74)
						draw_rect(Rect2(p-Vector2(63,16),Vector2(126,37)),Color("#203b45"));draw_rect(Rect2(p-Vector2(63,16),Vector2(126,37)),Color("#b7a278"),false,1)
						draw_string(font,p+Vector2(-59,-1),"ADVENTURE",HORIZONTAL_ALIGNMENT_CENTER,118,14,Color("#fff1ca"))
						draw_string(font,p+Vector2(-59,15),"BOARD",HORIZONTAL_ALIGNMENT_CENTER,118,13,Color("#e7d5aa"))
					else:
						var title := str(landmark["label"])
						var label_size := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
						var label_origin := landmark_pos - camera + Vector2(-label_size.x * 0.5-(75 if str(landmark.sprite)=="creator_board" else 0),landmark_size.y * 0.5 + 24)
						draw_rect(Rect2(label_origin - Vector2(7, 18), Vector2(label_size.x+14,24)), Color(0.08, 0.16, 0.19, 0.91))
						draw_string(font, label_origin, title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#fff1ca"))
		studio_town.draw_on(self,camera)
		academy_town.draw_on(self,camera)
		cosmetic_town.draw_on(self,camera)
		town_v109.draw_on(self,camera)
		town_upgrade.draw_on(self,camera,font);town_services.draw_post(self,camera,font);town_services.draw_garden(self,camera)
		if lodges!=null:lodges.draw_town(self,camera)
		town_chapter.draw_pads(self,camera)
		arena_town.draw_on(self,camera)
		if fishing!=null:fishing.draw_on(self,camera)
		if legacy!=null:legacy.draw_town(self,camera)
		journey.draw_town(self,camera)
		town_life.neighborhood.draw_on(self,camera,town_life.clock)
		preload("res://scripts/town_v173.gd").draw_trees(self,camera)
		town_life.calendar.draw_props(self,camera)
		town_life.draw_residents(self,camera)
		town_scenery.draw_patrols(self,camera)
		town_life.draw_recognition(self,camera,font)
		presentation.elder_guide.draw_marker(self,camera)
	else:
		if voyage==null or not voyage.active:draw_sprite("portal", pair(region["gate"]["position"]) - Vector2(40, 76), Vector2(80, 120))
		if region.has("merchant") and not practice and not tutorial.active and (voyage==null or not voyage.active):
			draw_sprite("merchant", pair(region["merchant"]) - Vector2(48, 72), Vector2(96, 80))
			draw_world_label(pair(region["merchant"]), "MERCHANT")
		if boss_defeated:
			draw_sprite("portal", pair(region["boss"]) - Vector2(40, 76), Vector2(80, 120))
		if fishing!=null:fishing.draw_on(self,camera)
		if mistglass_rift!=null and mistglass_rift.active:mistglass_rift.draw_on(self,camera)
		for enemy in enemies:
			if waylight!=null and waylight.between() and enemy.pos.distance_to(position_in_world)>365:continue
			if bool(enemy.get("buried",false)):continue
			if not Rect2(camera,VIEW).grow(180).has_point(enemy["pos"]):continue
			var ep: Vector2 = enemy["pos"] - camera
			var is_boss: bool = enemy["boss"]
			var definition: Dictionary = enemy_types.get(enemy.get("type", ""), {}).duplicate()
			var sprite_prefix := str(definition.get("sprite", "bramble"))
			var boss_size := Vector2(72, 72) if str(enemy["type"]) == "fragment" else Vector2(100, 100)
			if str(enemy["type"]) in ["gongbreaker","silence_regent"]: boss_size=Vector2(120,120)
			var enemy_pose := "attack" if (float(enemy.get("melee_warning",0))>0 or float(enemy.get("strike_flash",0))>0 or float(enemy.get("v143_pose",0))>adventure.newcomers.clock or float(enemy.get("veil_pose",0))>adventure.pursuers.clock or float(enemy.get("cinder_pose",0))>adventure.cinder.clock) else ("walk1" if int(visual_clock * 3.0) % 2 == 0 else "walk2")
			var enemy_sprite := sprite_prefix + "_" + enemy_pose if art.has(sprite_prefix + "_" + enemy_pose) else sprite_prefix + "_" + str(int(visual_clock * 3.0) % 2)
			if is_boss:
				var boss_prefix := "bramble_boss" if str(enemy["type"]) == "fragment" else str(enemy.get("type")) if enemy.get("expansion_boss",false) else str(enemy.get("sprite",region.get("boss_sprite", "bramble_boss")))
				enemy_sprite = boss_prefix + "_attack" if float(enemy.get("windup",0.0)) > 0 and art.has(boss_prefix+"_attack") else boss_prefix + "_" + enemy_pose if art.has(boss_prefix+"_"+enemy_pose) else boss_prefix
			if enemy.get("expansion_boss",false): boss_size *= (1.0 if int(enemy.get("generation",0)) == 0 else .78 if int(enemy.get("generation",0)) == 1 else .56)
			if bool(enemy.get("veilbound",false)):
				var veil_size:Vector2=adventure.pursuers.body_size(enemy);draw_sprite(enemy_sprite,enemy.pos-veil_size*Vector2(.5,.7),veil_size)
			elif str(enemy.type) in adventure.cinder.TYPES:
				var body:Vector2=adventure.cinder.body_size(str(enemy.type));draw_sprite(enemy_sprite,enemy.pos-body*Vector2(.5,.7),body)
			elif str(enemy.type) in adventure.tech.TYPES:
				var tech_size:Vector2=adventure.tech.body_size(str(enemy.type));draw_sprite(enemy_sprite,enemy.pos-tech_size*Vector2(.5,.7),tech_size)
			elif str(enemy.type) in adventure.school.TYPES:
				var school_size:Vector2=adventure.school.body_size(str(enemy.type));draw_sprite(enemy_sprite,enemy.pos-school_size*Vector2(.5,.7),school_size)
			elif float(enemy.get("down_time",0))>0:draw_sprite(enemy_sprite,enemy.pos-Vector2(35,14),Vector2(70,28))
			elif str(enemy.type)=="rootbound_keeper":
				draw_sprite(enemy_sprite,enemy.pos-Vector2(54,64),Vector2(108,120))
			else:draw_sprite(enemy_sprite, enemy["pos"] - (boss_size * 0.5 if is_boss else Vector2(28, 30)), boss_size if is_boss else Vector2(56, 56))
			if float(enemy.get("strike_flash",0))>0:
				var direction:Vector2=enemy.get("strike_direction",Vector2.DOWN);var progress:float=1.0-float(enemy.strike_flash)/.35;var angle:float=direction.angle()
				draw_arc(ep,65 if is_boss else 38,angle-.8+progress*.8,angle+.3+progress*.8,16,Color(1,.68,.4,minf(1,float(enemy.strike_flash)*5)),6,true)
			if float(enemy_flashes.get(int(enemy["uid"]), 0.0)) > 0:
				draw_circle(ep, 49 if is_boss else 28, Color(1, 1, 0.8, 0.42))
			if is_boss and not tutorial.active and float(enemy.get("windup", 0.0)) > 0:
				if str(region.get("boss_secondary", "stomp")) in ["stomp", "sunburst", "frostburst", "seekerstorm", "sporeburst"]:
					preload("res://scripts/combat_cues.gd").danger(self,ep,225 if str(region.get("boss_secondary", ""))=="sunburst" else 175,float(enemy.windup),.8)
				else:
					preload("res://scripts/combat_cues.gd").corridor(self,ep,position_in_world-camera,14)
			preload("res://scripts/starter_boss.gd").draw_warning(self,enemy,ep)
			var hp_y:float=-adventure.pursuers.body_size(enemy).y*.7-8 if bool(enemy.get("veilbound",false)) else -adventure.cinder.body_size(str(enemy.type)).y*.7-8 if str(enemy.type) in adventure.cinder.TYPES else -adventure.tech.body_size(str(enemy.type)).y*.7-8 if str(enemy.type) in adventure.tech.TYPES else -47 if is_boss else -32
			if not (adventure.school.active and is_boss) and not (media.clean_view or media.capturing):draw_rect(Rect2(ep + Vector2(-27,hp_y), Vector2(54 * float(enemy["hp"]) / float(enemy["max_hp"]), 5)), Color("#e8d586"))
		for bullet in bullets:
			draw_circle(bullet["pos"] - camera, 9, Color.html(str(bullet["stats"].get("color", "#ffffff"))))
		for enemy_shot in enemy_shots:
			if not str(enemy_shot.get("ice_visual","")).is_empty():preload("res://scripts/ice_projectiles.gd").draw(self,enemy_shot.pos-camera,enemy_shot.direction,str(enemy_shot.ice_visual),visual_clock);continue
			draw_circle(enemy_shot["pos"] - camera, 13 if enemy_shot.get("fireball", false) else 8, Color("#fc6735") if enemy_shot.get("fireball", false) else Color("#ef8978"))
			draw_circle(enemy_shot["pos"] - camera, 3, Color("#fff0b7"))
		for wall in ice_walls:
			draw_circle(wall["pos"] - camera, float(wall["radius"]), Color("#a9eaff",0.65))
		for ally in allies:
			draw_sprite(str(ally["sprite"]), ally["pos"] - Vector2(19, 19), Vector2(38, 38))
		for effect in attack_effects:
			if effect.get("visual","")=="medic_pulse":
				preload("res://scripts/medic_visuals.gd").pulse(self,effect.center-camera,float(effect.radius),1-float(effect.time)/.5);continue
			if effect.has("start"):
				if bool(effect.get("lightning",false)):
					preload("res://scripts/lightning.gd").draw_on(self,effect["start"]-camera,effect["end"]-camera,Color(effect.get("color",Color.WHITE),minf(1,float(effect["time"])*3)))
				else: draw_line(effect["start"] - camera, effect["end"] - camera, Color(effect.get("color",Color("#edaa65")), float(effect["time"]) * 3), 9)
			else:
				draw_arc(effect["center"] - camera, float(effect["radius"]), 0, TAU, 48, Color(effect.get("color",Color("#edaa65")), float(effect["time"]) * 2), 9, true)
		if pulse_time > 0 and str(hero["special"].get("style", "stomp")) in ["stomp", "beam"]:
			if str(hero["special"].get("style", "stomp")) == "beam":
				draw_line(pulse_position - camera, pulse_position + special_direction * float(hero["special"].get("radius", 570)) - camera, Color(0.72, 0.58, 1, pulse_time * 2.8), 16)
			else:
				draw_arc(pulse_position - camera, float(hero["special"].get("radius", 155)), 0, TAU, 64, Color(1, 0.85, 0.55, pulse_time * 2.8), 9, true)
		if strike_time > 0:
			if strike_style == "spin":
				draw_arc(position_in_world - camera, float(strike_stats.get("range", 125)), 0, TAU, 48, Color(0.75, 0.9, 1, strike_time * 3), 10, true)
			else:
				var primary_stats: Dictionary = strike_stats
				var half_arc := deg_to_rad(float(primary_stats.get("arc_degrees", 105)) * 0.5)
				var sweep := strike_direction.angle()
				var reach := float(primary_stats.get("range", 82))
				var visual := str(primary_stats.get("visual", strike_style))
				if visual == "forge_hammer":
					preload("res://scripts/hero_visuals1984.gd").hammer(self,position_in_world-camera,strike_direction,reach,1-clampf(strike_time/.18,0,1))
				elif visual == "scratch":
					for claw_index in 3:
						var shift := (float(claw_index) - 1.0) * 9.0
						var tangent := Vector2(-strike_direction.y, strike_direction.x) * shift
						var start := position_in_world + strike_direction * 31 + tangent - camera
						draw_line(start, start + strike_direction * (reach - 31), Color(0.77, 0.96, 0.89, strike_time * 5), 4)
				elif visual == "punch":
					draw_circle(position_in_world + strike_direction * reach - camera, 16, Color(1, 0.8, 0.5, strike_time * 4))
				elif visual == "medic_boot":
					preload("res://scripts/medic_visuals.gd").boot(self,position_in_world-camera,strike_direction,reach,1-clampf(strike_time/.18,0,1))
				elif visual == "kick":
					draw_line(position_in_world + strike_direction * 24 - camera, position_in_world + strike_direction * reach - camera, Color(1, 0.8, 0.5, strike_time * 4), 13)
				elif visual == "bounce":
					var landing := position_in_world + strike_direction * reach - camera
					draw_arc(landing, 27, 0, TAU, 28, Color(1, 0.67, 0.34, strike_time * 5), 6, true)
				else:
					draw_arc(position_in_world - camera, reach, sweep - half_arc, sweep + half_arc, 20, Color(1, 0.9, 0.6, strike_time * 5), 8, true)
		if charge_time > 0:
			draw_line(position_in_world - charge_direction * 75 - camera, position_in_world - camera, Color(0.63, 0.89, 0.68, 0.58), 12)
	if mode=="town":preload("res://scripts/community_records.gd").draw_on(self,camera)
	for trail in dodge_trails:
		var trail_sprite := str(hero.get("sprite", "ram")) + "_walk1"
		draw_sprite(trail_sprite, trail["pos"] - Vector2(28,42), Vector2(56,64), Color(0.7,0.9,1.0, float(trail["time"])*1.8))
	if voyage!=null and voyage.active and not voyage.ashore:return
	var walking: bool = mobile.movement.length_squared() > 0 or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") or Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down")
	var frame := int(visual_clock * 7.0) % 2 if walking and menu == "" else 0
	var town_sprite_data: Dictionary = characters.get(selected_character, {})
	var sprite := str(town_sprite_data.get("sprite", "ram")) if mode == "town" else str(hero.get("sprite", "ram"))
	var pose := "attack" if attack_pose_time > 0 and mode == "run" else ("walk1" if frame == 0 else "walk2") if walking and menu == "" else "idle"
	if adventure.combat.v90.pending_rebirth("solo"):pass
	elif sprite=="snail" and adventure.combat.v79.moving("solo"):pose="shell"
	if adventure.combat.classics.channeling("solo"):pose="open"
	elif adventure.combat.classics.spinning("solo"):pose="spin"
	if pose=="attack" and art.has(sprite+"_attack2") and int(visual_clock*12)%2==1:pose="attack2"
	var hero_art := sprite + "_" + pose if art.has(sprite + "_" + pose) else sprite + "_" + str(frame)
	if sprite=="goalie":skating_motion.draw_skates(self,"solo",position_in_world-camera)
	adventure.combat.halloween.draw_mount(self,"solo",camera)
	var hero_rect:Rect2=adventure.combat.v78.visual_rect("solo",position_in_world) if sprite=="gopher" else fish_motion.sprite_rect("solo",position_in_world) if sprite=="ripplejaw" else wing_motion.sprite_rect("solo",position_in_world) if sprite=="velvetwing" else basketball_motion.sprite_rect("solo",position_in_world) if sprite=="basketball" else Rect2(position_in_world+adventure.combat.v48.visual_offset("solo")-Vector2(28,42),Vector2(56,64))
	if sprite=="navigator":hero_rect.position.y-=3+sin(visual_clock*2.8)*2.5
	hero_rect.position+=adventure.combat.stance_heroes.visual_offset("solo")+adventure.combat.release_heroes.visual_offset("solo")+adventure.combat.v79.visual_offset("solo")+motion_v85.offset(sprite)+adventure.combat.halloween.visual_offset("solo")
	hero_rect.position+=adventure.combat.classics.body_offset("solo")
	hero_rect=adventure.combat.v110.resize("solo",hero_rect)
	if sprite=="basketball":draw_circle(position_in_world-camera+Vector2(0,20),13,Color(0,0,0,.23))
	if adventure.combat.v90.pending_rebirth("solo"):pass
	elif sprite=="snail" and adventure.combat.v79.moving("solo"):
		adventure.combat.v79.draw_shell(self,"solo",position_in_world-camera,art.get(hero_art),Color.WHITE)
	elif sprite=="gopher" and adventure.combat.v78.immune("solo"):
		adventure.combat.v78.draw_burrow(self,"solo",position_in_world-camera)
	elif sprite=="ripplejaw":
		var pivot:Vector2=position_in_world-camera
		world_transform(pivot,fish_motion.angle("solo"));draw_sprite(hero_art,hero_rect.position-position_in_world+camera,hero_rect.size);world_transform()
	elif mode=="run" and studio_live!=null and studio_live.active() and studio_live.form_texture()!=null:draw_texture_rect(studio_live.form_texture(),Rect2(hero_rect.position-camera,hero_rect.size),false)
	elif not adventure.combat.robot.transformed("solo") and not adventure.combat.twister.transformed("solo"):draw_sprite(hero_art,hero_rect.position,hero_rect.size,Color(1,1,1,.43) if stealth_time>0 and mode=="run" else Color.WHITE)
	if health>0 and legacy.daily.earned() and legacy.cosmetics.daily_visible():preload("res://scripts/daily_challenge.gd").draw_on(self,position_in_world-camera,visual_clock)
	var dev_session:Node=get_tree().root.get_node_or_null("FXDevSession")
	if mode=="town" and health>0:preload("res://scripts/rolling_crowns.gd").draw_town(self,Vector2(hero_rect.get_center().x,hero_rect.position.y+5)-camera,visual_clock,legacy.crowns.display_tier())
	if health>0:preload("res://scripts/player_cosmetics.gd").draw_on(self,position_in_world-camera,visual_clock,legacy.cosmetics.effect(),legacy.cosmetics.effect_week(legacy.cosmetics.effect()))
	if dev_session!=null and bool(dev_session.active) and health>0:preload("res://scripts/dev_insignia.gd").draw_on(self,position_in_world-camera,visual_clock)
	if health>0:preload("res://scripts/creation_badges.gd").draw_on(self,position_in_world-camera,visual_clock,{"custom":hero.has("studio_project"),"balanced":bool(hero.get("studio_checked",false)),"playtest":get_tree().root.get_node("FXResearch").active,"media":media.active})
	if player_flash_time > 0:
		draw_circle(position_in_world - camera, 34, Color(1, 0.32, 0.34, player_flash_time * 2.4))
	if block_time > 0 and mode == "run":
		draw_arc(position_in_world - camera, 38, 0, TAU, 36, Color(0.55, 0.85, 1, minf(1.0, block_time)), 5, true)
	for notice in ([] if media.clean_view or media.capturing else floating_text):
		draw_string(font, notice["pos"] - camera, str(notice["label"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, notice["shade"])
	if mode == "run":
		draw_line(position_in_world - camera, position_in_world - camera + aim_direction() * 34, Color("#f5db79", 0.7), 2)
func draw_sprite(name: String, world_pos: Vector2, size: Vector2, tint: Color = Color.WHITE) -> void:
	if mode=="town" and not Rect2(camera,VIEW).intersects(Rect2(world_pos,size)):return
	if art.has(name) and art[name] != null:
		draw_texture_rect(art[name], Rect2(world_pos - camera, size), false, tint)

func draw_world_label(world_pos: Vector2, label: String) -> void:
	draw_string(font, world_pos - camera + Vector2(-48, -83), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)

func draw_hud() -> void:
	draw_rect(Rect2(0, 0, VIEW.x, preload("res://scripts/town_hud.gd").height(self) if mode=="town" else 90), Color(0.06, 0.11, 0.14, 0.9))
	if mode == "town":
		preload("res://scripts/town_hud.gd").draw_heading(self)
		preload("res://scripts/town_hud.gd").draw_on(self)

	else:
		var layout=preload("res://scripts/combat_hud.gd")
		var title=("RAM'S TRIAL" if trial else str(region.get("name","Realm")))+" • "+str(hero.get("name","Hero"))+" • Lv "+str(level)
		layout.header(self,title,gold,health,max_health())
		preload("res://scripts/boss_health.gd").draw_on(self)
		draw_ability_cooldowns()
		var span=int(region.get("xp_per_level",5))*10
		var fraction=clampf(float(tutorial.defeated)/7.0,0,1) if tutorial.active else clampf(float(experience-(level-1)*span)/float(span),0,1)
		var label="First steps • wave %d/3" % mini(3,1+int(tutorial.defeated)/3) if tutorial.active else "Lv %d • XP %s" % [level,"MAX" if level>=10 else str(experience)+" / "+str(level*span)]
		layout.experience(self,label,1.0 if level>=10 else fraction)
		draw_string(font,Vector2(24,78),"PRACTICE • discoveries only" if continuation!=null and continuation.active else "%02d:%02d" % [int(run_time)/60,int(run_time)%60],HORIZONTAL_ALIGNMENT_LEFT,240,13,Color("#b7cbd6"))
		if not (waylight!=null and waylight.between()) and not enemies.is_empty() and not tutorial.active and not adventure.quests.active and not adventure.school.active and not adventure.tech.active and not adventure.immersive.active and not adventure.foundry.active and not adventure.cinder.active and (voyage==null or not voyage.active or voyage.ashore):
			var closest_enemy: Dictionary = enemies[0]
			for candidate in enemies:
				if position_in_world.distance_squared_to(candidate["pos"]) < position_in_world.distance_squared_to(closest_enemy["pos"]):
					closest_enemy = candidate
			var target_direction: Vector2 = (closest_enemy["pos"] - position_in_world).normalized()
			var arrow_center := Vector2(VIEW.x-115, 138)
			draw_arc(arrow_center, 23, 0, TAU, 32, Color("#ffe3a1"), 2)
			draw_line(arrow_center, arrow_center + target_direction * 19, Color("#ffe3a1"), 5)
			draw_circle(arrow_center + target_direction * 19, 4, Color("#ffe3a1"))
			draw_string(font, arrow_center + Vector2(-4, -28), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
			draw_string(font, Vector2(VIEW.x-260, 177), "Next enemy: " + str(int(position_in_world.distance_to(closest_enemy["pos"]) / 64)) + " tiles", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

		if invulnerable_time > 0:
			draw_string(font, Vector2(VIEW.x-260, VIEW.y-110), "Shield: %.1fs" % invulnerable_time, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#abdcca"))
		elif haste_time > 0:
			draw_string(font, Vector2(VIEW.x-260, VIEW.y-110), "Rush: %.1fs" % haste_time, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#abdcca"))
		elif stealth_time > 0:
			draw_string(font, Vector2(VIEW.x-260, VIEW.y-110), "Stealth: %.1fs" % stealth_time, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#abdcca"))
		elif stun_time > 0:
			draw_string(font, Vector2(VIEW.x-260, VIEW.y-110), "Stunned: %.1fs" % stun_time, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#ffb38d"))
	if hint != "" and menu == "":
		draw_string(font, Vector2(370, VIEW.y-135 if mobile.enabled else VIEW.y-110), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color("#fbeba9"))
	if message_time > 0 and menu == "":
		draw_string(font, Vector2(24, 275 if tutorial.active and mobile.enabled else VIEW.y-150 if mode=="run" else VIEW.y-28), message, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)

func draw_ability_cooldowns() -> void:
	var labels: Array[String] = ["LMB", "RMB", "SPC"]
	if mobile.enabled: labels.assign(["AIM","2ND","SPC"])
	var keys: Array[String] = ["primary", "secondary", "special"]
	for index in range(3):
		var ability_key: String = keys[index]
		var required_level: int = 1 if index == 0 else 3 if index == 1 else 6
		var locked: bool = level < required_level
		var stats: Dictionary = hero.get(ability_key, {})
		var duration: float = maxf(0.1, float(stats.get("cooldown", 1.0)))
		var remaining: float = maxf(0.0, float(cooldowns.get(ability_key, 0.0)))
		var readiness: float = 0.0 if locked else clampf(1.0 - remaining / duration, 0.0, 1.0)

		var state: String = "Lv" + str(required_level) if locked else "READY" if remaining <= 0.0 else "%.1fs" % remaining
		preload("res://scripts/combat_hud.gd").cooldown(self,index,labels[index],readiness,state,locked)

var list_scroll: Dictionary = {}
var list_preview: Dictionary = {}

var supply_category="equipment"
func list_entries() -> Array:
	if menu in ["supplies","merchant"]:return manifest.get("items",[]).filter(func(id):return bool(items.get(id,{}).get("shop",true)) and preload("res://scripts/supply_slots.gd").consumable(items.get(id,{}))==(supply_category=="consumables"))
	return provisions.defs.keys().filter(func(id):return bool(provisions.defs[id].get("shop",true))) if menu=="food" else town_upgrade.route_entries(self) if menu=="wayfinder" else manifest.get("regions",[]) if menu=="portal" else manifest.get("items",[]).filter(func(id):return bool(items.get(id,{}).get("shop",true)))

func scroll_list(steps: int) -> void:
	list_scroll[menu] = clampi(int(list_scroll.get(menu,0))+steps,0,maxi(0,list_entries().size()-7))

func select_list_entry(index: int) -> void:
	if index >= 0 and index < list_entries().size(): list_preview[menu] = index

func confirm_list_entry() -> void:
	var entries := list_entries()
	if entries.is_empty(): return
	var id := str(entries[clampi(int(list_preview.get(menu,0)),0,entries.size()-1)])
	if menu=="food":provisions.buy(id);return
	if menu in ["portal","wayfinder"]:
		start_run(false,id)
		return
	var item: Dictionary = items.get(id,{})
	var price:int = preload("res://scripts/supply_slots.gd").price(item,legacy)
	var packed: Array = inventory if menu == "merchant" else loadout
	if not preload("res://scripts/supply_slots.gd").can_add(packed,id,items) or gold < price: return
	if packed.has(id) and str(item.get("effect","")) in ["bonus_damage","bonus_speed","lifesteal","armor","bonus_health","cooldown"]: return
	gold -= price
	packed.append(id)
	if menu=="supplies":
		loadout_paid[id]=price
		if preload("res://scripts/supply_slots.gd").consumable(item):preload("res://scripts/prepared_supply.gd").set_ready(id,price)
		save_profile()

func draw_scroll_menu() -> void:
	draw_rect(Rect2(80,105,1120,555),Color(.09,.16,.19,.97))
	draw_rect(Rect2(80,105,1120,555),Color("#c7ad78"),false,3)
	draw_string(font,Vector2(100,148),"WAYFINDER LODGE" if menu=="wayfinder" else "CHOOSE A REALM" if menu=="portal" else "FOOD STAND" if menu=="food" else "REALM MERCHANT" if menu == "merchant" else "SUPPLY SHOP",HORIZONTAL_ALIGNMENT_LEFT,-1,28,Color("#f5e7cc"))
	var entries := list_entries()
	var first := int(list_scroll.get(menu,0))
	var selected := int(list_preview.get(menu,0))
	for row in mini(7,entries.size()-first):
		var index := first+row
		var id := str(entries[index])
		var data: Dictionary = realms.get(id,{}) if menu in ["portal","wayfinder"] else provisions.defs.get(id,{}) if menu=="food" else items.get(id,{})
		draw_rect(Rect2(100,182+row*43,405,41),Color(.2,.36,.48) if index == selected else Color(.06,.12,.18))
		draw_string(font,Vector2(110,210+row*43),("MASTERED • " if menu in ["portal","wayfinder"] and legacy.realm_mastered(id) else "")+str(data.get("name",id)),HORIZONTAL_ALIGNMENT_LEFT,385,20,Color("#f3d489") if menu in ["portal","wayfinder"] and legacy.realm_mastered(id) else Color.WHITE)
	var cap := maxi(0,entries.size()-7)
	draw_rect(Rect2(509,182,14,301),Color(.1,.2,.25))
	var thumb := 301.0*minf(1.0,7.0/maxi(1,entries.size()))
	draw_rect(Rect2(509,182+(301-thumb)*first/maxi(1,cap),14,thumb),Color("#d4b879"))
	if not entries.is_empty():
		var id := str(entries[clampi(selected,0,entries.size()-1)])
		var data: Dictionary = realms.get(id,{}) if menu in ["portal","wayfinder"] else provisions.defs.get(id,{}) if menu=="food" else items.get(id,{})
		var y := _draw_wrapped(str(data.get("name",id)),Vector2(560,205),590,28,Color("#f5e7cc"))
		y = _draw_wrapped(str(data.get("description","Explore this realm, defeat its enemies and challenge its boss.")),Vector2(560,y+25),570,21,Color.WHITE)
		if menu not in ["portal","wayfinder"]:
			var price:int = preload("res://scripts/supply_slots.gd").price(data,legacy)
			y = _draw_wrapped("Cost: "+str(price)+" CC. "+("Buy Food / Enter to pack one automatic provision." if menu=="food" else "Select an item to read its effects, then Buy Item / Enter to purchase."),Vector2(560,y+25),570,20,Color("#d4b879"))
			_draw_wrapped("Food slot: "+provisions.name_of(provisions.packed)+" • separate from your three items. Refund before replacing." if menu=="food" else "Packed: "+str(inventory if menu == "merchant" else loadout)+" (3 equipment + 1 consumable)",Vector2(560,y+25),570,19,Color.WHITE)
		else:
			y = _draw_wrapped(str(data.get("difficulty_label",""))+" • "+str(legacy.realm_clears(id))+" clears"+(" • Realm mastered" if legacy.realm_mastered(id) else " • Mastery star at 10 clears"),Vector2(560,y+25),570,21,Color("#d4b879"))
			_draw_wrapped("Enter / Enter Realm to begin. Use Left / Right or Previous / Next to change route difficulty." if menu=="wayfinder" else "Enter / Enter Realm to begin. Co-op opens multiplayer rooms.",Vector2(560,y+25),570,20,Color.WHITE)
	if message_time>0 and menu=="food":_draw_wrapped(message,Vector2(560,550),570,17,Color("#cde1b5"))
	if menu=="wayfinder":draw_string(font,Vector2(100,605 if mobile.enabled else 585),"Route: "+town_upgrade.FILTERS[town_upgrade.route_filter],HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("#d4b879"))
	draw_string(font,Vector2(100,585 if mobile.enabled else 555),"CC: "+str(gold)+" | Swipe, mouse wheel or Up / Down to scroll.",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)

func launch_quest_party() -> void:
	menu=""
	get_tree().root.set_meta("fx_mode","coop")
	get_tree().root.set_meta("fx_realm","wayfarer")
	get_tree().root.set_meta("fx_hero",selected_character)
	get_tree().change_scene_to_file("res://network/client.tscn")

func elder_lines() -> Array[String]:
	return ["THE ELDER RAM • YOUR GUIDE TO CROSSROADS",
		"Character Hall: scroll through heroes and read their abilities before choosing.",
		"Food Stand: pack one automatic meal or cure alongside your three items.",
		"Healer House: recover here after defeat. Seedhouse: grow food after an adventure.",
		"Training Yard: practise your attacks safely before entering an adventure.",
		"Realms: explore, defeat enemies and challenge a guardian. Start at level 1.",
		"School adventures: clear wings, open doors and return to the starting street.",
		"Co-op: share an adventure. Stay near a fallen teammate and hold Interact to revive.",
		"Arena: battle other players; choose free-for-all or teams in the lobby.",
		"Gate Defence: protect town, cover three routes, and visit guard/upgrade buildings.",
		"Ram Descent: survive deeper floors. There is no free heal between floors.",
		"Wayfarer Wilds: enter beyond Training, talk to villagers; Q / Journal shows quests.",
		"Level 3: secondary. Level 5: passive. Level 6: special. Levels 8/10: upgrades.",
		"Use room codes or Join Random to meet teammates. Everyone needs the same build.",
		"WASD / touch stick: move. E / Interact: doors and stairs. Shift / Dodge: evade.",
		"Enter / Continue or Escape: close. Visit the Journey board for local progress."]

func draw_menu() -> void:
	if menu in ["waylight","levelup","session","journey_cosmetics","dev_desk","workshop","town_almanac"]:return
	if menu in ["rift_builder","rift_countdown","arcane_tower","barracks","chimehouse","presentation","seedhouse","postoffice","training_guide","portal","wayfinder","supplies","merchant","food"]:return
	if menu in ["portal","supplies","merchant","food","wayfinder"]:
		draw_scroll_menu()
		return
	if menu in ["healer","seedhouse"]:
		town_upgrade.draw_menu(self);return
	if menu == "characters":
		draw_hero_selection()
		return
	draw_rect(Rect2(180, 110, 920, 510), Color(0.09, 0.16, 0.19, 0.97))
	draw_rect(Rect2(180, 110, 920, 510), Color("#c7ad78"), false, 3)
	var lines: Array[String] = []
	match menu:
		"quest_entrance":
			lines = ["WAYFARER WILDS • QUEST EXPEDITION", "A forest world beyond the training yard, with Willowrest village and two dungeons.", "Talk to Edda and Orrin. Restore the waylights and reclaim the mill.", "Then help Sable recover the ancient heartbell. Tamsin guides the snowy summit; Fenna restores the Skyworks.", "1 / Enter: Continue solo with your chosen hero", "2: Open a co-op room (2 heroes, shared quest progress)", "3: Start a fresh solo expedition (resets this browser's quest progress)", "Quest progress saves on this browser. Co-op checkpoints save on both browsers; the host chooses the starting checkpoint.", "Escape: close. Q / Journal in the world shows your current tasks."]
		"journey":
			presentation.adventures();return
		"journey_cosmetics":
			lines=journey.menu_lines()
		"creators":
			lines = ["STUDENT CREATORS • CREATED BY THE CROSSROADS COMMUNITY"]
			for entry in load_json("res://content/creators.json").get("entries",[]):
				lines.append(str(entry.get("name","Creator"))+" — "+str(entry.get("contribution","")))
			lines.append("Design the art. Code the adventures. Leave your mark.")
			lines.append("Escape or Continue to close.")
		"elder":
			lines = elder_lines()
		"levelup":
			lines = ["LEVEL " + str(level) + " - " + ("CHOOSE YOUR REWARD" if level in [2, 4, 7, 8, 9, 10] else "NEW ABILITY"), level_award_text()]
			lines.append("Press a number to choose, or Enter to continue." if level in [3, 5, 6] else "Select a number to continue the run.")
		"results":
			for line in result_text.split("\n"):
				lines.append(line)
	var y := 164.0
	for line in lines:
		if menu=="levelup":
			y=_draw_wrapped(line,Vector2(215,y),850,20 if mobile.enabled or y==164 else 18,Color("#f5e7cc") if y==164 else Color.WHITE)
		else:
			draw_string(font, Vector2(215, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 20 if y == 164 else 16 if menu=="elder" else 20 if mobile.enabled else 18, Color("#f5e7cc") if y == 164 else Color.WHITE)
		y += 27 if menu=="elder" else 32

func _unhandled_input(event: InputEvent) -> void:
	if menu in ["fishing_shop","fishing_journal"]:return
	if menu in ["dev_desk","workshop"]:return
	if menu in catalog_ui.MENUS:
		catalog_ui.key(event);return
	if session_menu!=null and not session_menu.page.is_empty():return
	if hero_hall!=null and menu=="characters":
		if hero_hall.handle_key(event):get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE and tutorial.active:tutorial.finish(false,true);return
	if presentation!=null and not presentation.page.is_empty():return
	if tutorial.active and menu.is_empty() and event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		tutorial.attacked=true;queue_redraw()
	if menu=="legacy":
		if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:legacy.close()
		return
	if adventure.quests.active and adventure.quests.journal and event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:adventure.quests.journal_key(KEY_UP if event.button_index==MOUSE_BUTTON_WHEEL_UP else KEY_DOWN);return
	if menu=="quest_entrance" and event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var point:=get_global_mouse_position()-(VIEW-Vector2(1280,720))*.5
		if Rect2(205,274,850,32).has_point(point):start_run(false,"wayfarer");return
		if Rect2(205,306,850,32).has_point(point):launch_quest_party();return
		if Rect2(205,338,850,32).has_point(point):
			if FileAccess.file_exists("user://fx_quests_wayfarer_solo.json"):DirAccess.remove_absolute("user://fx_quests_wayfarer_solo.json")
			start_run(false,"wayfarer");return
	if menu in ["portal","supplies","merchant","food","wayfinder"] and event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]: scroll_list(-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var point: Vector2 = event.position-(VIEW-Vector2(1280,720))*0.5
			if Rect2(100,182,405,301).has_point(point): select_list_entry(int(list_scroll.get(menu,0))+int((point.y-182)/43.0))
		return
	if menu == "characters" and event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			hero_scroll = clampi(hero_scroll+(-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1),0,maxi(0,manifest.get("characters",[]).size()-7))
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			var point := get_global_mouse_position()-(VIEW-Vector2(1280,720))*0.5
			if Rect2(100,182,405,301).has_point(point): select_hero_entry(hero_scroll+int((point.y-182)/43.0))
			elif Rect2(509,182,14,301).has_point(point):
				hero_scroll = clampi(roundi((point.y-182)/301.0*float(maxi(0,manifest.get("characters",[]).size()-7))),0,maxi(0,manifest.get("characters",[]).size()-7))
			return
	if not event is InputEventKey:
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	var code := key.keycode
	if adventure.quests.journal_key(code):return
	if menu=="quest_entrance":
		if code in [KEY_1,KEY_ENTER,KEY_KP_ENTER]:start_run(false,"wayfarer")
		elif code==KEY_2:launch_quest_party()
		elif code==KEY_3:
			if FileAccess.file_exists("user://fx_quests_wayfarer_solo.json"):DirAccess.remove_absolute("user://fx_quests_wayfarer_solo.json")
			start_run(false,"wayfarer")
		elif code==KEY_ESCAPE:menu=""
		return
	if mode == "town" and menu == "" and code == KEY_T: presentation.adventures();return
	if menu == "journey_cosmetics":
		journey.choose(code)
		if code in [KEY_ESCAPE,KEY_ENTER]: menu = ""
		return
	if menu == "creators":
		if code in [KEY_ESCAPE,KEY_ENTER]: menu = ""
		return
	if menu in ["healer","seedhouse"]:
		if code==KEY_1 and menu=="seedhouse":provisions.garden_action()
		elif code in [KEY_ESCAPE,KEY_ENTER,KEY_KP_ENTER]:menu=""
		return
	if menu=="wayfinder" and code in [KEY_LEFT,KEY_RIGHT]:
		town_upgrade.route_filter=posmod(town_upgrade.route_filter+(-1 if code==KEY_LEFT else 1),4);list_scroll[menu]=0;list_preview[menu]=0;return
	if menu == "results":
		if code == KEY_ENTER or code == KEY_KP_ENTER:
			menu = ""
			gold = 100
			character_id = selected_character
			get_tree().root.set_meta("fx_hero", selected_character)
			loadout.clear()
			enter_region("town")
		return
	if menu == "levelup":
		if level in [3, 5, 6]:
			if code in [KEY_ENTER, KEY_KP_ENTER]:
				menu = ""
		elif level in [2, 4, 7, 9] and code in [KEY_1, KEY_2, KEY_3]:
			if code == KEY_1:
				bonus_health += 25
				health += 25
			elif code == KEY_2:
				bonus_damage += 4
			else:
				bonus_speed += 20
			menu = ""
		elif level == 8 and code in [KEY_1, KEY_2]:
			upgrade = "primary" if code == KEY_1 else "secondary"
			menu = ""
		elif level == 10 and code in [KEY_1, KEY_2]:
			mastery = "special" if code == KEY_1 else "passive"
			menu = ""
		return
	if menu in ["supplies","merchant","portal","food","wayfinder"]:
		if code in [KEY_UP,KEY_DOWN]: scroll_list(-1 if code == KEY_UP else 1)
		elif code in [KEY_ENTER,KEY_KP_ENTER]: confirm_list_entry()
		elif code == KEY_ESCAPE: menu = ""
		elif code==KEY_BACKSPACE and menu=="food":provisions.refund()
		elif code == KEY_BACKSPACE and menu == "supplies":
			preload("res://scripts/supply_slots.gd").refund(self)
		elif code == KEY_0 and menu == "portal":
			get_tree().root.set_meta("fx_mode","coop")
			get_tree().root.set_meta("fx_hero",selected_character)
			get_tree().change_scene_to_file("res://network/client.tscn")
		elif code >= KEY_1 and code <= KEY_7: select_list_entry(int(list_scroll.get(menu,0))+int(code)-int(KEY_1))
		return
	if menu == "characters":
		if code in [KEY_UP,KEY_DOWN]:
			hero_scroll = clampi(hero_scroll+(-1 if code == KEY_UP else 1),0,maxi(0,manifest.get("characters",[]).size()-7))
			return
		select_hero_entry(int(code)-int(KEY_1))
		return_if_not_escape(code)
		return
	if menu == "elder":
		if code in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER]:
			menu = ""
		return
	if menu=="voyage":
		if code==KEY_ESCAPE:voyage.close_menu()
		return
	if mode == "run":
		var inventory_choice := int(code) - int(KEY_1)
		if inventory_choice >= 0 and inventory_choice < 4:
			use_item_slot(inventory_choice)
	elif code == KEY_ESCAPE:
		pass # Double Escape opens the session menu; a single Escape never quits.

func return_if_not_escape(code: Key) -> void:
	if code in [KEY_ESCAPE,KEY_ENTER,KEY_KP_ENTER]:
		menu = ""

func select_hero_entry(index: int) -> void:
	var entries: Array = manifest.get("characters",[])
	if index < 0 or index >= entries.size(): return
	var id := str(entries[index])
	if index < hero_scroll: hero_scroll = index
	elif index >= hero_scroll+7: hero_scroll = index-6
	hero_preview = id
	mark_welcome("hero")
	var choice: Dictionary = characters.get(id,{})
	var cost := int(choice.get("run_cost",0))
	var previous: Dictionary = characters.get(selected_character,{})
	var refund := int(previous.get("run_cost",0))
	if id != selected_character and gold+refund >= cost:
		gold += refund-cost;selected_character = id;save_profile()

func draw_hero_selection() -> void:
	if hero_hall!=null:return
	draw_rect(Rect2(80,105,1120,555),Color(0.06,0.13,0.16,0.98))
	draw_rect(Rect2(80,105,1120,555),Color("#c7ad78"),false,3)
	draw_string(font,Vector2(105,145),"CHARACTER HALL",HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color("#ffe5ab"))
	draw_string(font,Vector2(105,170),"Click a hero - scroll down to see more",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#bfd7cc"))
	var entries: Array = manifest.get("characters",[])
	for index in mini(7,maxi(0,entries.size()-hero_scroll)):
		var id := str(entries[hero_scroll+index])
		var data: Dictionary = characters.get(id,{})
		var y := 182.0+index*43.0
		var active := id == selected_character
		draw_rect(Rect2(100,y,405,39),Color("#355a52") if active else Color("#1d343c"))
		var cost := int(data.get("run_cost",0))
		var label := str(hero_scroll+index+1)+"  "+str(data.get("name",id))
		draw_string(font,Vector2(112,y+25),label,HORIZONTAL_ALIGNMENT_LEFT,300,19,Color("#ffe6af") if active else Color.WHITE)
		draw_string(font,Vector2(420,y+25),"Chosen" if active else "Free" if cost == 0 else str(cost)+"g",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#bcd9c8"))
	draw_rect(Rect2(509,182,10,301),Color("#1a3035"))
	if entries.size()>7:
		var thumb_height := 301.0*7.0/float(entries.size())
		var thumb_y := 182.0+(301.0-thumb_height)*float(hero_scroll)/float(entries.size()-7)
		draw_rect(Rect2(509,thumb_y,10,thumb_height),Color("#d7bc82"))
	draw_string(font,Vector2(108,520),"CC: "+str(gold)+"  |  "+str(entries.size())+" heroes",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#ffe5ab"))
	_draw_wrapped("Scroll to browse. Click to select. Enter / Continue or Escape: close.",Vector2(108,555),380,16,Color("#bfd7cc"))
	var id := selected_character if hero_preview.is_empty() else hero_preview
	var data: Dictionary = characters.get(id,{})
	draw_line(Vector2(530,125),Vector2(530,635),Color("#587b70"),2)
	var texture_key := str(data.get("sprite",id))+"_idle"
	var texture: Texture2D = art.get(texture_key)
	if texture != null: draw_texture_rect(texture,Rect2(1105,124,64,72),false)
	draw_string(font,Vector2(555,153),str(data.get("name",id)),HORIZONTAL_ALIGNMENT_LEFT,540,25,Color("#ffe5ab"))
	draw_string(font,Vector2(555,183),"Health "+str(data.get("max_health",100))+"  |  Speed "+str(data.get("speed",230))+"  |  Cost "+str(data.get("run_cost",0))+"g",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#bce3d4"))
	var y := 225.0
	for kind in ["primary","secondary","special"]:
		var ability: Dictionary = legacy.preview_stats(id,kind,data.get(kind,{}))
		var label := "LMB" if kind == "primary" else "RMB - Lv3" if kind == "secondary" else "Space - Lv6"
		draw_string(font,Vector2(555,y),label+": "+str(ability.get("name",kind.capitalize())),HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("#f4d79a"))
		y += 24.0
		y = _draw_wrapped(ability_info(ability,kind),Vector2(555,y),615,17,Color("#e4ece7"))+24.0
	draw_string(font,Vector2(555,y),"PASSIVE - Lv5",HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color("#f4d79a"))
	_draw_wrapped(str(data.get("passive","No passive ability.")),Vector2(555,y+25),615,17,Color("#e4ece7"))
	if id != selected_character:
		draw_string(font,Vector2(555,640),"Not enough CC to select this hero.",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#efad98"))

func _draw_wrapped(value: String, point: Vector2, width: float, size: int, tint: Color) -> float:
	var line := ""
	var y := point.y
	for word in value.split(" "):
		var candidate := word if line.is_empty() else line+" "+word
		if font.get_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x > width and not line.is_empty():
			draw_string(font,Vector2(point.x,y),line,HORIZONTAL_ALIGNMENT_LEFT,-1,size,tint)
			y += size+5;line = word
		else: line = candidate
	if not line.is_empty(): draw_string(font,Vector2(point.x,y),line,HORIZONTAL_ALIGNMENT_LEFT,-1,size,tint)
	return y

func ability_info(stats: Dictionary, kind: String) -> String:
	var style := str(stats.get("style","melee"))
	var damage := str(stats.get("damage",0))
	var reach := str(stats.get("range",stats.get("radius",85)))
	var effect := ""
	match style:
		"melee","punch","scratch","slash","kick": effect = "Close directional hit: "+damage+" damage, "+reach+" reach, "+str(stats.get("arc_degrees",105))+" degree arc."
		"charge": effect = "Rush forward up to "+reach+" distance, hitting each enemy once for "+damage+" damage."
		"spin","stomp": effect = "Hit enemies around you for "+damage+" damage within "+reach+" distance."
		"flame": effect = "Sweep a short flame cone for 0.9s: up to 5 hits of "+damage+" damage, "+reach+" reach. Aim while firing."
		"beam": effect = "Aim a straight beam: "+damage+" damage, "+reach+" reach."
		"golf_drive": effect = "Drive a small golf ball for "+damage+" damage, "+reach+" reach."
		"projectile": effect = ("Fire "+str(stats.get("count",1))+" balls in a spread: "+damage+" damage each, "+reach+" reach." if int(stats.get("count",1))>1 else "Fire an aimed shot: "+damage+" damage, "+reach+" reach.")
		"return_disc": effect = "Throw a returning star-disc: "+damage+" damage per pass, "+reach+" reach. Each enemy can be hit once outward and once on return."
		"homing": effect = "Fire an orb that follows enemies: "+damage+" damage, "+reach+" reach."
		"chain": effect = ("Fire up to three simultaneous lightning bolts at different enemies in front of you. "+damage+" damage each; "+reach+" reach. Obstacles block the bolts." if bool(stats.get("fork",false)) else "Bounce between up to "+str(stats.get("jumps",3))+" targets, starting at "+damage+" damage; later hits deal less. Aim within "+reach+" distance.")
		"stealth": effect = "Become semi-transparent for "+str(stats.get("duration",3))+"s, move 45% faster, heal "+str(stats.get("heal",30))+" HP. Your next attack deals double damage."
		"block": effect = "Block for "+str(stats.get("duration",2))+"s, reducing incoming damage by "+str(roundi(float(stats.get("reduction",0.7))*100))+"%."+(" Reflect enemy projectiles." if bool(stats.get("reflect",false)) else "")
		"heal_zone": effect = "Create a healing field for %s seconds: %s HP each second for you and nearby allies. Never heals enemies." % [str(stats.get("duration",5)),str(stats.get("heal_per_tick",6))]
		"heal_wave": effect = "Restore "+str(stats.get("heal",35 if kind == "special" else 25))+" HP; also heals nearby allies in multiplayer."
		"summon": effect = "Summon "+str(stats.get("count",1))+" teammate for "+str(stats.get("duration",12))+"s. It pursues enemies and deals "+damage+" damage per hit."
		"ice_wall": effect = "Launch an ice orb at your aim. On landing, deal "+damage+" area damage and create an ice barrier for "+str(stats.get("duration",4))+"s."
		"trap": effect = "Nearby area pulse: "+damage+" damage within "+reach+" distance." if kind == "special" else "Place an aimed area attack for "+damage+" damage."
		"target_aoe": effect = "Aim an area strike: "+damage+" damage, "+str(stats.get("blast_radius",110))+" blast radius, "+reach+" cast reach."
		_: effect = str(stats.get("description",style.capitalize()+": "+damage+" damage."))
	if style == "target_aoe" and float(stats.get("travel_speed",0)) > 0: effect += " A travelling projectile explodes on landing."
	if float(stats.get("fragment_count",0))>0:effect+=" Releases "+str(stats.fragment_count)+" small fragment bombs for "+str(stats.fragment_damage)+" damage each after the first explosion."
	if float(stats.get("self_speed_seconds",0))>0:effect+=" Gain 25% movement speed for "+str(stats.self_speed_seconds)+" seconds after use."
	if float(stats.get("stun_duration",0))>0:effect+=" Stuns enemies hit for "+str(stats.stun_duration)+" seconds."
	if stats.has("description"):effect=str(stats["description"])
	if style=="flame":effect+=" Burns enemies for 2 damage per second for 10 seconds; repeated hits refresh the burn."
	if float(stats.get("slow_duration",0))>0:effect+=" Slows struck enemies for %s seconds." % float(stats.slow_duration)
	if float(stats.get("bleed_duration",0))>0:effect+=" Causes bleeding for 2 damage per second for 4 seconds."
	if float(stats.get("splash_radius",0))>0:effect+=" On contact, nearby enemies take 8 splash damage."
	if float(stats.get("poison_duration",0))>0:effect+=" Poisons for "+str(stats.get("poison_damage",1))+" damage per second for "+str(stats["poison_duration"])+" seconds. Repeated hits refresh the poison."
	return effect+" Cooldown: "+str(stats.get("cooldown",0.5))+"s."

func spawn_hero_projectiles(stats: Dictionary, damage: float, aim: Vector2, homing: bool) -> void:
	var count := clampi(int(stats.get("count",1)),1,5)
	if bool(stats.get("bonus_split",false)):damage=float(stats.get("damage",0))+(damage-float(stats.get("damage",0)))/count
	var spread := float(stats.get("spread",0.0))
	for index in count:
		var direction := aim.rotated((float(index)-float(count-1)*0.5)*spread)
		bullets.append({"pos":position_in_world+direction*27,"direction":direction,"distance":0.0,"stats":stats,"damage":damage,"homing":homing})

func mark_welcome(step: String) -> void:
	if step == "skip": journey.data["skipped"] = true;journey.save();return
	journey.mark("grove" if step == "realm" else step)

func unlock_cosmetic(title: String) -> void:
	if preload("res://scripts/profile_store.gd").progression_blocked():return
	journey.unlock("Grovekeeper" if title == "Pathfinder" else "Lantern Bearer" if title == "Lantern Keeper" else title)

func drain_xp(amount: int) -> int:
	var taken := mini(experience,amount);experience -= taken
	var old_level := level
	level = maxi(1,mini(10,1+experience/(int(region.get("xp_per_level",4))*10)))
	if level < old_level:
		add_float_text(position_in_world-Vector2(45,90),"XP STOLEN — LEVEL "+str(level),Color("#d5a1ed"))
	return taken
func grant_enemy_xp(amount: int) -> void:
	experience += amount
	var target := mini(10,1+experience/(int(region.get("xp_per_level",4))*10))
	if target > level:
		level += 1
		if level > highest_level: highest_level = level;menu = "levelup"

func update_flames(delta: float) -> void:
	for n in range(flame_bursts.size()-1,-1,-1):
		var burst:Dictionary=flame_bursts[n]
		burst["time"]-=delta;burst["tick"]-=delta
		if level<3 and not practice:flame_bursts.clear();return
		if float(burst["time"])<=0:flame_bursts.remove_at(n);continue
		if float(burst["tick"])>0:continue
		if int(burst.get("ticks",0))<=0:flame_bursts.remove_at(n);continue
		burst["ticks"]=int(burst["ticks"])-1
		burst["tick"]=float(burst["stats"].get("tick",.18))
		var aim:=aim_direction();var reach:=float(burst["stats"].get("range",150));var angle:=cos(deg_to_rad(float(burst["stats"].get("arc_degrees",55))*.5))
		journey.cue("flame")
		for i in range(enemies.size()-1,-1,-1):
			var offset:Vector2=enemies[i]["pos"]-position_in_world
			if offset.length()<reach and aim.dot(offset.normalized())>angle and shot_path_clear(position_in_world,enemies[i]["pos"]):
				adventure.combat.burn_foe(enemies[i],"solo");damage_enemy(i,float(burst["damage"]))
func draw_flames() -> void:
	if flame_bursts.is_empty():return
	var origin:=position_in_world-camera;var aim:=aim_direction()
	var stats:Dictionary=flame_bursts[0].get("stats",{})
	var reach:float=float(stats.get("range",150));var spread:float=deg_to_rad(float(stats.get("arc_degrees",55)))/8
	for n in 9:
		var direction:=aim.rotated((n-4)*spread)
		draw_line(origin+direction*22,origin+direction*(reach*(.7+.2*sin(visual_clock*19+n))),Color(1,.45+.035*n,.12,.7),7,true)

func safe_town_respawn()->Vector2:
	var origin:Vector2=town_upgrade.CLINIC_SPAWN
	for ring in range(0,12):
		for side in 16:
			var candidate:=origin+Vector2.from_angle(TAU*side/16)*ring*32
			var clear:=can_stand_at(candidate)
			for offset in [Vector2(32,0),Vector2(-32,0),Vector2(0,32),Vector2(0,-32)]:clear=clear and can_stand_at(candidate+offset)
			if clear:return candidate
	return pair(region.get("spawn",[1250,1000]))

func world_transform(p:Vector2=Vector2.ZERO,angle:float=0,zoom:Vector2=Vector2.ONE)->void:
	draw_set_transform(media.offset()+p*media.factor(),angle,zoom*media.factor())

func open_business_district()->void:
	if is_instance_valid(business_district):return
	business_district=preload("res://scripts/business_district/view.gd").new();add_child(business_district);business_district.setup(self)

func open_business_academy()->void:
	if is_instance_valid(business_academy):return
	if is_instance_valid(business_district):
		business_district.leave()
		await get_tree().process_frame
	business_academy=preload("res://scripts/business_academy/page.gd").new();add_child(business_academy);business_academy.setup(self)
