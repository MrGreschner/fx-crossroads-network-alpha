extends Node2D
var fishing:Node
var music=preload("res://scripts/music_player.gd").new()
var custom_party=preload("res://scripts/custom_party.gd").new()
var allow_custom=false
var custom_picker:CheckButton
var music_network=preload("res://scripts/music_network.gd").new()
var media=preload("res://scripts/media_mode.gd").new()
var dev_magic:Node2D
var battlegrounds=preload("res://scripts/battlegrounds.gd").new()
var bg_map:="woodland"
var bg_team_size:=3
var bg_map_picker:OptionButton
var bg_help:Button
var bg_size_picker:OptionButton
var session_menu:CanvasLayer
var arena_notice_last:=""
var arena_notice_left:=0.0
var respawn_board:CanvasLayer
var level_cards:CanvasLayer
var motion_v85=preload("res://scripts/hero_motion_v85.gd").new()

# Host-authoritative room modes. Signaling and WebRTC link setup are adapted
# from Connections Lab; the Render service only exchanges room invitations.
const STUN_URL := "stun:stun.cloudflare.com:3478"
var ROOM_SERVICE_URL := preload("res://scripts/brand.gd").room_url()
var VIEW := Vector2(1280, 720)
var FIELD := Rect2(0, 0, 6200, 4200)
const GATE := Vector2(5300, 7800)
const APPROACHES := [Vector2(5300, 500), Vector2(300, 7800), Vector2(10300, 7800)]
const SEND_INTERVAL := 0.10
const MOVEMENT_INTERVAL := 0.05
const MAX_PLAYERS := 8
var arena_seats:=4
var gate_rival_plan:Array=["npc_sable","npc_bastion","npc_cinder","npc_iona"]
var bot_plan:Array=[]
var bot_count:=0
var ai_difficulty:="medium"
var difficulty_picker:OptionButton
var bots:Node
var bots_picker:OptionButton
var spectator_host:=false
var seats_picker:OptionButton
var spectator_picker:CheckButton
var start_countdown:=0.0
var countdown_overlay:CanvasLayer
var connect_elapsed:=0.0
var waiting_for_room:=false
var spectator_director:Node
var broadcast_scale:=1.0
var broadcast_offset:=Vector2.ZERO
var socket: WebSocketPeer
var links: Dictionary = {}
var room_code := ""
var my_id := ""
var host_id := ""
var role := ""
var roster: Array[Dictionary] = []
var record_party:Array=[]
var positions: Dictionary = {}
var health: Dictionary = {}
var xp: Dictionary = {}
var gold: Dictionary = {}
var levels: Dictionary = {}
var kills: Dictionary = {}
var teams: Dictionary = {}
var hero_ids: Dictionary = {}
var cooldown_at: Dictionary = {}
var cooldown_remaining: Dictionary = {}
var respawn_at: Dictionary = {}
var dodge_at: Dictionary = {}
var local_pos := Vector2(300, 390)
var opponents: Array[Dictionary] = []
var enemy_motion229=preload("res://scripts/enemy_motion229.gd").new()
var missiles: Array[Dictionary] = []
var guards: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var mode := "defense"
var realm_id := "grove"
var continuation:Node
var version_check:Node
var arena_world=preload("res://scripts/arena_world.gd").new()
var party_tools:Node
var hero_grid_button:Button
var hero_grid:Node
var hero_picker:OptionButton
var arena_map_picker:OptionButton
var opening_picker:CheckButton
var arena_opening:=false
var arena_map:="sand"
var arena_no_items:=false
var arena_random:=false
var no_items_picker:CheckButton
var random_hero_picker:CheckButton
var random_builds:Dictionary={}
var lobby_heroes:Dictionary={}
var lobby_builds:Dictionary={}
var card_save_timer:=5.0
var preferred_hero:="ram"
var match_id:=""
var match_party_size:=1
var defense_cleared_wave:=0
var arena_records:Dictionary={}
var arena_outcomes:Dictionary={}
var pvp_rule := "ffa"
var started := false
var wave := 0
var floor_number := 1
var core_art=preload("res://scripts/core_hero_art.gd").new()
var descent=preload("res://scripts/descent_journey.gd").new()
var floor_seed := 0
var gate_hp := 550.0
var gate_max := 550.0
var wave_timer := 6.0
var guard_timer := 0.0
var north_gate=preload("res://scripts/north_gate.gd").new()
var upgrade_level := {"attack": 0, "health": 0, "armor": 0, "count": 0, "ranged": 0, "area": 0}
var field_obstacles: Array[Dictionary] = []
var enemy_pool: Array[String] = []
var item_list: Array[String] = []
var inventory: Dictionary = {}
var provisions=preload("res://scripts/provisions.gd").new()
var food_slots:Dictionary={}
var supply_loadouts:Dictionary={}
var accepted_supplies:Dictionary={}
var shop_discounts:Dictionary={}
var food_loadouts:Dictionary={}
var food_registered:Dictionary={}
var control: CanvasLayer
var public_room: CheckButton
var create_public: Button
var server_matchmaking := false
var no_public_rooms := false
var search_remaining := 0.0
var status_label: Label
var roster_label: Label
var mode_picker: OptionButton
var realm_picker: OptionButton
var rule_picker: OptionButton
var item_picker: OptionButton
var name_field: LineEdit
var code_field: LineEdit
var send_timer := 0.0
var heartbeat_timer := 10.0
var last_socket_state := WebSocketPeer.STATE_CLOSED
var pending_command: Dictionary = {}
var attack_pressed := false
var secondary_pressed := false
var special_pressed := false
var skating_motion=preload("res://scripts/skating_motion.gd").new()
var wing_motion=preload("res://scripts/wing_motion.gd").new()
var fish_motion=preload("res://scripts/fish_motion.gd").new()
var basketball_motion=preload("res://scripts/basketball_motion.gd").new()
var visual_time := 0.0
var last_aim := Vector2.RIGHT
var selected_hero := "ram"
var manifest:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://content/manifest.json"))
var characters: Dictionary = {}
var items: Dictionary = {}
var enemy_defs: Dictionary = {}
var regions: Dictionary = {}
var art: Dictionary = {}
var best_path := "user://fx_descent_best.json"
var best_floor := 0
var run_time := 0.0
var coop_best := 0
var chosen_team := -1
var party_lobby:Control
var lobby_timer:=0.0
var mode_cards:Array[Button]=[]
var attack_branch: Dictionary = {}
var mastery_choice: Dictionary = {}
var shield_until: Dictionary = {}
var haste_until: Dictionary = {}
var item_haste_scale: Dictionary = {}
var invincible_until: Dictionary = {}
var camera := Vector2.ZERO
var world_patches: Array[Dictionary] = []
var world_buildings: Array[Dictionary] = []
var descent_nav: AStarGrid2D
var obstacle_grid: Dictionary = {}
var world_spawns: Array[Dictionary] = []
var world_decorations: Array[Dictionary] = []
var world_fountains:Array[Vector2]=[]
var fountain_tick:=0.0
var hit_flash:Dictionary={}
var floor_transition:=0.0
var world_terrain := "forest"
var shop_open := ""
var dodge_time := 0.0
var dodge_direction := Vector2.RIGHT
var trails: Array[Dictionary] = []
var charges: Dictionary = {}
var stealth_until: Dictionary = {}
var attack_pose_until: Dictionary = {}
var remote_draw_pos: Dictionary = {}
var smoothing=preload("res://scripts/network_smoothing.gd").new()
var transport=preload("res://scripts/realtime_transport.gd").new()
var terrain_cache:Node2D
var realm_props:Node2D
var motion_received:Dictionary={}
var position_history:Dictionary={}
var position_acks:Dictionary={}
var movement_timer:=0.0
var predicted_pose_until:=0
var request_ready:Dictionary={}
var local_position_sequence:=0
var damage_labels: Array[Dictionary] = []
var sent_effects: Array[Dictionary] = []
var ice_walls: Array[Dictionary] = []
var session_hero_sent := false
var network_charge_target := Vector2.ZERO
var notice := "Host or join a room, or play Gate Defense / Cave Descent solo."

var pvp_scores: Dictionary = {}
var shield_reduction: Dictionary = {}
var aim_angles: Dictionary = {}
var contributions: Dictionary = {}
var downed: Dictionary = {}
var revive_held: Dictionary = {}
var defeat_causes:Dictionary={}
var results_reason := ""
var player_cosmetics: Dictionary = {}
var presentation:Node
var recovery:Node
var journey: Node
var adventure: Node
var flame_bursts: Array[Dictionary] = []
var mobile: CanvasLayer

var legacy:Node
var legacy_result_recorded:=false

func setup_media()->void:
	add_child(music);music.setup(self);add_child(music_network);music_network.setup(self)
	add_child(media);media.setup(self)
func media_mouse_world()->Vector2:
	return media.world_mouse() if media.game!=null else get_global_mouse_position()+camera
func _ready() -> void:
	call_deferred("_add_combat_slots")
	add_child(custom_party);custom_party.setup(self)
	call_deferred("setup_media")
	dev_magic=preload("res://scripts/dev_magic.gd").new();add_child(dev_magic);dev_magic.setup(self)
	countdown_overlay=preload("res://scripts/match_countdown.gd").new();add_child(countdown_overlay);countdown_overlay.setup(self)
	descent.game=self
	transport.game=self
	terrain_cache=preload("res://scripts/multiplayer_ground.gd").new();terrain_cache.game=self;terrain_cache.z_index=-1;add_child(terrain_cache)
	for sprite in ["mosaicling","hive_drone","quillling","stagelet","lanternling","deputyling","gravehorse"]:
		for pose in ["idle","walk1","walk2","attack"]:art[sprite+"_"+pose]=load("res://assets/"+sprite+"_"+pose+".png")
	arena_world.game=self
	legacy=preload("res://scripts/legacy.gd").new();add_child(legacy);legacy.setup(self,true)
	fishing=preload("res://scripts/fishing.gd").new();add_child(fishing);fishing.setup(self,true)
	provisions.setup(self,true)
	mobile = preload("res://scripts/mobile_controls.gd").new()
	add_child(mobile)
	adventure = preload("res://scripts/realm_trials.gd").new()
	add_child(adventure)
	journey = preload("res://scripts/journey.gd").new()
	add_child(journey)
	for action in ["move_left","move_right","move_up","move_down","primary","secondary","special","dodge","interact"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	# Direct editor launches may not have visited the main scene input setup.
	if InputMap.action_get_events("primary").is_empty():
		var primary_mouse:=InputEventMouseButton.new();primary_mouse.button_index=MOUSE_BUTTON_LEFT;InputMap.action_add_event("primary",primary_mouse)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	manifest = _json("res://content/manifest.json")
	for entry in manifest.get("characters", []):
		var data := _json("res://content/characters/" + str(entry) + ".json")
		characters[str(entry)] = data
		for pose in ["idle", "walk1", "walk2", "attack", "attack2", "special", "open", "spin", "shell"]:
			var path: String = "res://assets/" + str(data.get("sprite", entry)) + "_" + str(pose) + ".png"
			var refreshed=preload("res://scripts/hero_art_refresh.gd").texture(str(data.get("sprite",entry)),str(pose))
			if refreshed!=null:art[str(entry)+"_"+pose]=refreshed
			elif ResourceLoader.exists(path): art[str(entry) + "_" + pose] = load(path)
			elif ResourceLoader.exists(path.replace(".png",".svg")):art[str(entry)+"_"+pose]=preload("res://scripts/source_art.gd").texture(path.replace(".png",".svg"))
	for entry in manifest.get("characters", []):
		var minion:=str(characters[str(entry)].get("special",{}).get("minion_sprite",""))
		if not minion.is_empty() and ResourceLoader.exists("res://assets/"+minion+".png"):art[minion]=load("res://assets/"+minion+".png")
	for entry in manifest.get("enemies", []):
		var data := _json("res://content/enemies/" + str(entry) + ".json")
		enemy_defs[str(entry)] = data
		if str(data.get("sprite",entry)) in preload("res://scripts/enemy_visual227.gd").FACTORS:
			for pose in ["idle","walk1","walk2","attack","attack2","special"]:art[str(entry)+"_"+pose]=load("res://assets/"+str(data.get("sprite",entry))+"_"+pose+".png")
			continue
		if str(entry) in preload("res://scripts/cinderheart.gd").TYPES+["ratchet_keeper","spark_scarab","hinge_conjurer","latch_hound","bogpitch_newt","mireweaver","mirevein_collector","mistglass_skater","undertow_weaver","sluicewarden"]:
			for pose in ["idle","walk1","walk2","attack"]:art[str(entry)+"_"+pose]=preload("res://scripts/source_art.gd").texture("res://assets/"+str(entry)+"_"+pose+".svg")
			continue
		for pose in ["idle", "walk1", "walk2", "attack", "attack2", "special", "open", "spin"]:
			var path: String = "res://assets/" + str(data.get("sprite", entry)) + "_" + str(pose) + ".png"
			var refreshed=preload("res://scripts/hero_art_refresh.gd").texture(str(data.get("sprite",entry)),str(pose))
			if refreshed!=null:art[str(entry)+"_"+pose]=refreshed
			elif ResourceLoader.exists(path): art[str(entry) + "_" + pose] = load(path)
			elif ResourceLoader.exists(path.replace(".png",".svg")):art[str(entry)+"_"+pose]=preload("res://scripts/source_art.gd").texture(path.replace(".png",".svg"))
	for pose in ["idle","walk1","walk2","attack"]:art["cryowarden_"+pose]=load("res://assets/cryowarden_"+pose+".png")
	# Some realm boss sprites have no standalone manifest enemy entry.
	for sprite in preload("res://scripts/enemy_visual227.gd").FACTORS:
		if not art.has(sprite+"_idle"):
			for pose in ["idle","walk1","walk2","attack"]:art[sprite+"_"+pose]=load("res://assets/"+sprite+"_"+pose+".png")
	for entry in manifest.get("regions", [])+manifest.get("quest_regions",[]): regions[str(entry)] = _json("res://content/regions/" + str(entry) + ".json")
	for entry in manifest.get("items", []):
		items[str(entry)] = _json("res://content/items/" + str(entry) + ".json")
		if bool(items[str(entry)].get("shop",true)):item_list.append(str(entry))
	if FileAccess.file_exists(best_path): best_floor = int(_json(best_path).get("best", 0))
	for sprite in ["grass","forest","path","ash","ice","space","quarantine","tree","rock","crystal","ice_pillar","satellite","barricade","flower","house","character_hall","supply_shop","town_gate","town_banner","town_lamp","mini_basketball"]:
		if ResourceLoader.exists("res://assets/" + sprite + ".png"): art[sprite] = load("res://assets/" + sprite + ".png")
	art["arena_hall"] = preload("res://scripts/source_art.gd").texture("res://assets/arena_hall.svg")
	for guard_type in ["melee","ranged","area"]: art["guard_"+guard_type] = preload("res://scripts/source_art.gd").texture("res://assets/guard_"+guard_type+".svg")
	preload("res://scripts/studio_library.gd").install(self)
	selected_hero = str(get_tree().root.get_meta("fx_hero", "ram"))
	if not characters.has(selected_hero):selected_hero="ram";get_tree().root.set_meta("fx_hero","ram")
	if not characters.has(selected_hero): selected_hero = "ram"
	preferred_hero=selected_hero
	for sprite in ["moonburrow_grass","city_cobble","moonveil_court","moonveil_canal","oath_broken_road","oath_void","briar_arch","kiln_forge","mirror_shard_env","storm_coil","oath_stone","briar_floor","cinder_floor","mirror_floor","storm_floor","marsh_floor","river_grass","river_water","river_bridge","waterfall","river_willow","clock_floor","brass_path","clock_arch","clock_tree","astral_void","astral_floor","astral_bridge","star_obelisk","astrolabe","oath_pillar","marsh_reeds","lantern_tree","creator_board","realm_banner"]:
		art[sprite] = load("res://assets/"+sprite+".png")
	_ui()
	bots=preload("res://scripts/arena_bots.gd").new();add_child(bots);bots.setup(self)
	presentation=preload("res://scripts/presentation.gd").new();add_child(presentation);presentation.setup(self,true)
	session_menu=preload("res://scripts/session_menu.gd").new();add_child(session_menu);session_menu.setup(self,true)
	version_check=preload("res://scripts/build_update.gd").new();add_child(version_check);version_check.setup(self)
	level_cards=preload("res://scripts/level_cards.gd").new();add_child(level_cards);level_cards.setup(self,true)
	respawn_board=preload("res://scripts/respawn_board.gd").new();add_child(respawn_board);respawn_board.setup(self)
	recovery=preload("res://scripts/session_recovery.gd").new();add_child(recovery);recovery.setup(self)
	party_tools=preload("res://scripts/party_tools.gd").new();add_child(party_tools);party_tools.setup(self)
	_set_mode(str(get_tree().root.get_meta("fx_mode", "defense")))
	var requested:=str(get_tree().root.get_meta("fx_realm",""))
	for n in realm_picker.item_count:
		if str(realm_picker.get_item_metadata(n))==requested:realm_picker.select(n)
	if get_tree().root.has_meta("fx_realm"):get_tree().root.remove_meta("fx_realm")

	if get_tree().root.has_meta("fx_solo_party"):call_deferred("_begin_solo_party")

func _begin_solo_party()->void:preload("res://scripts/solo_party.gd").begin(self)

func return_to_network_menu()->void:
	_track_card_progress();legacy.save();get_tree().root.set_meta("fx_mode",mode);get_tree().root.set_meta("fx_hero",selected_hero);get_tree().change_scene_to_file("res://network/client.tscn")
func _add_combat_slots()->void:
	if get("dedicated")==true:return
	var quick=preload("res://scripts/loadout_hud.gd").new();add_child(quick);quick.setup(self)
	var guide=preload("res://scripts/ability_guide.gd").new();add_child(guide);guide.setup(self)

func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

func _label(label: String, x: float, y: float, width: float, size: int = 16) -> Label:
	var child := Label.new()
	child.text = label
	child.position = Vector2(x, y)
	child.size = Vector2(width, 30)
	child.add_theme_font_size_override("font_size", size)
	control.add_child(child)
	return child

func _button(title: String, x: float, y: float, callback: Callable, width: float = 116.0) -> Button:
	var child := Button.new()
	child.text = title
	child.position = Vector2(x, y)
	child.size = Vector2(width, 32)
	child.pressed.connect(callback)
	control.add_child(child)
	return child

func _ui() -> void:
	control=CanvasLayer.new();add_child(control)
	party_lobby=preload("res://scripts/party_lobby.gd").new();party_lobby.game=self;control.add_child(party_lobby)
	mode_picker=OptionButton.new();control.add_child(mode_picker)
	for title in ["Gate Defence","Gladiator Arena","Co-op Realms","Cave Descent","Battlegrounds"]:mode_picker.add_item(title)
	mode_picker.item_selected.connect(func(index:int):_set_mode(["defense","arena","coop","descent","battlegrounds"][index]))
	for index in 5:
		var title:String=["GATE DEFENCE\nProtect town • 1–4 heroes","GLADIATOR ARENA\nRivals & teams • 2–8 players","CO-OP REALMS\nExplore together • 2–4 players","CAVE DESCENT\nSurvive the depths • 1–4 players","BATTLEGROUNDS\nBuild armies • 3v3 / 4v4"][index]
		var card:=_button(title,32,144+index*74,_set_mode.bind(["defense","arena","coop","descent","battlegrounds"][index]),292);card.size.y=68;mode_cards.append(card)
	bg_map_picker=OptionButton.new();control.add_child(bg_map_picker);bg_map_picker.position=Vector2(700,173);bg_map_picker.size=Vector2(290,32)
	for id in battlegrounds.MAPS:bg_map_picker.add_item(str(battlegrounds.MAPS[id]));bg_map_picker.set_item_metadata(bg_map_picker.item_count-1,id)
	bg_map_picker.item_selected.connect(func(index:int):bg_map=str(bg_map_picker.get_item_metadata(index));_update_lobby_settings())
	bg_size_picker=OptionButton.new();control.add_child(bg_size_picker);bg_size_picker.position=Vector2(1005,173);bg_size_picker.size=Vector2(220,32);bg_size_picker.add_item("3v3 • Three paths");bg_size_picker.add_item("4v4 • Four paths");bg_size_picker.select(1)
	bg_size_picker.item_selected.connect(func(index:int):bg_team_size=3+index;_update_lobby_settings())
	bg_help=_button("HOW TO PLAY",700,214,func():battlegrounds.game=self;battlegrounds.help(),310)
	realm_picker=OptionButton.new();control.add_child(realm_picker);realm_picker.position=Vector2(700,173);realm_picker.size=Vector2(525,36)
	for id in regions:
		realm_picker.add_item(("LOCKED • " if not preload("res://scripts/realm_access.gd").unlocked(legacy,str(id)) else "")+str(regions[id].get("name",id)));realm_picker.set_item_metadata(realm_picker.item_count-1,id)
		if legacy.realm_mastered(str(id)):realm_picker.set_item_icon(realm_picker.item_count-1,preload("res://scripts/ui_reward_icons.gd").texture())
	rule_picker=OptionButton.new();rule_picker.add_item("Free for all");rule_picker.add_item("Teams (up to 4v4)");rule_picker.position=Vector2(375,132);rule_picker.size=Vector2(220,32);control.add_child(rule_picker)
	rule_picker.item_selected.connect(func(_index:int):_update_lobby_settings())
	realm_picker.item_selected.connect(func(_index:int):_update_lobby_settings())
	name_field=LineEdit.new();name_field.position=Vector2(860,35);name_field.size=Vector2(252,36);name_field.text=str(legacy.data.name);name_field.max_length=18;control.add_child(name_field)
	code_field=LineEdit.new();code_field.position=Vector2(375,556);code_field.size=Vector2(165,44);code_field.max_length=6;code_field.placeholder_text="ROOM CODE";control.add_child(code_field)
	_button("HOST ROOM",550,556,_host,154);_button("JOIN / REQUEST",712,556,_join,146);_button("PUBLIC ROOMS",866,556,func():party_tools.browse(),173)
	_button("START ADVENTURE",1047,556,_start_button,177)
	custom_picker=CheckButton.new();custom_picker.text="CUSTOM HEROES";custom_picker.position=Vector2(350,30);custom_picker.size=Vector2(230,42);control.add_child(custom_picker);custom_picker.tooltip_text="Public rooms: checked Forced Balance builds. Every custom build needs Forced Balance. Custom matches are unofficial and earn no records. Off by default.";custom_picker.toggled.connect(func(value:bool):allow_custom=value;_update_lobby_settings())
	public_room=CheckButton.new();public_room.text="PUBLIC ROOM";public_room.position=Vector2(375,608);public_room.size=Vector2(185,44);control.add_child(public_room)
	public_room.toggled.connect(func(value:bool):
		if role=="host" and server_matchmaking:_send_ws({"type":"room_update","public":value})
	)
	create_public=_button("CREATE PUBLIC",562,610,_create_public,160)
	_button("LEAVE ROOM",734,610,_leave_room,146);_button("SHOW PARTY",1047,610,func():results_reason="",177);_button("PLAY SOLO",32,573,func():party_tools.online_solo(),292).size.y=48;_button("BACK TO TOWN",32,634,_town,292).size.y=48
	no_items_picker=CheckButton.new();no_items_picker.text="NO ITEMS / FOOD";no_items_picker.position=Vector2(605,132);no_items_picker.size=Vector2(270,32);control.add_child(no_items_picker)
	random_hero_picker=CheckButton.new();random_hero_picker.text="RANDOM HEROES";random_hero_picker.position=Vector2(925,132);random_hero_picker.size=Vector2(300,32);control.add_child(random_hero_picker)
	no_items_picker.toggled.connect(func(value:bool):arena_no_items=value;_send_arena_rules())
	random_hero_picker.toggled.connect(func(value:bool):arena_random=value;_send_arena_rules())
	hero_picker=OptionButton.new();hero_picker.position=Vector2(375,173);hero_picker.size=Vector2(198,32);control.add_child(hero_picker)
	for id in characters:
		hero_picker.add_item("My hero: "+str(characters[id].name));hero_picker.set_item_metadata(hero_picker.item_count-1,id)
		if str(id)==selected_hero:hero_picker.select(hero_picker.item_count-1)
	hero_grid_button=_button("Grid view",580,173,_open_hero_grid,105);hero_grid_button.size.y=32
	hero_picker.item_selected.connect(func(index:int):party_tools.change_hero(index))
	arena_map_picker=OptionButton.new();arena_map_picker.position=Vector2(700,173);arena_map_picker.size=Vector2(290,32);control.add_child(arena_map_picker)
	for id in arena_world.MAPS:arena_map_picker.add_item(str(arena_world.MAPS[id]));arena_map_picker.set_item_metadata(arena_map_picker.item_count-1,id)
	arena_map_picker.select(1)
	arena_map_picker.item_selected.connect(func(index:int):arena_map=str(arena_map_picker.get_item_metadata(index));_send_arena_rules())
	opening_picker=CheckButton.new();opening_picker.text="OPENING ACT • Lv1";opening_picker.position=Vector2(925,214);opening_picker.size=Vector2(300,32);control.add_child(opening_picker)
	opening_picker.toggled.connect(func(value:bool):arena_opening=value;_send_arena_rules())
	seats_picker=OptionButton.new();control.add_child(seats_picker);seats_picker.position=Vector2(1005,173);seats_picker.size=Vector2(220,32)
	for n in range(2,9):seats_picker.add_item(str(n)+" player seats",n)
	seats_picker.select(2);seats_picker.item_selected.connect(func(index:int):arena_seats=seats_picker.get_item_id(index);bot_count=mini(bot_count,arena_seats-1);bots_picker.select(bot_count);_update_lobby_settings())
	spectator_picker=CheckButton.new();control.add_child(spectator_picker);spectator_picker.position=Vector2(375,214);spectator_picker.size=Vector2(310,32);spectator_picker.text="HOST AS SPECTATOR"
	spectator_picker.tooltip_text="A separate broadcast seat. No hero, combat or progression rewards. Change while the lobby is waiting."
	spectator_picker.toggled.connect(func(value:bool):spectator_host=value;_update_lobby_settings())
	bots_picker=OptionButton.new();control.add_child(bots_picker);bots_picker.position=Vector2(700,214);bots_picker.size=Vector2(210,32)
	for n in 8:bots_picker.add_item("Practice bots: "+str(n),n)
	bots_picker.item_selected.connect(func(index:int):bot_count=mini(index,7);arena_seats=maxi(arena_seats,bot_count+1);seats_picker.select(arena_seats-2);bots_picker.select(bot_count);_update_lobby_settings())
	difficulty_picker=OptionButton.new();control.add_child(difficulty_picker);difficulty_picker.position=Vector2(1000,102);difficulty_picker.size=Vector2(225,26)
	difficulty_picker.add_item("AI: Easy");difficulty_picker.add_item("AI: Medium");difficulty_picker.add_item("AI: Hard");difficulty_picker.select(1)
	difficulty_picker.item_selected.connect(func(index:int):ai_difficulty=["easy","medium","hard"][index];_update_lobby_settings())
	difficulty_picker.tooltip_text="Easy: slower reactions, less precise aim and fewer ability uses. Medium: normal reactions and aim. Hard: quicker decisions, better leading and more frequent dodges. Same health and damage. Change while the lobby is waiting."
	bots_picker.tooltip_text="0–3 AI fighters occupy player seats. Any bot match is practice: hero damage mastery only, no PvP records, trophies or unlocks. Change while the lobby is waiting."
	status_label=_label(notice,375,658,850,15);status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status_label.size.y=42
	roster_label=_label("",900,612,326,15)
	item_picker=OptionButton.new()
	for bottle in [false,true]:
		item_picker.add_separator("CONSUMABLES • 1 slot" if bottle else "EQUIPMENT • 3 slots")
		for id in item_list:
			if preload("res://scripts/supply_slots.gd").consumable(items[id])!=bottle:continue
			item_picker.add_icon_item(preload("res://scripts/item_icons.gd").texture(id),str(items[id].get("name",id))+" ("+str(preload("res://scripts/supply_slots.gd").price(items[id],legacy))+" CC)");item_picker.set_item_metadata(item_picker.item_count-1,id)
	item_picker.select(1)
	item_picker.position=Vector2(28,684);item_picker.size=Vector2(210,30);control.add_child(item_picker)
	_button("BUY ITEM",245,683,_buy_item,102)
	for child in control.get_children():
		if child is OptionButton:child.fit_to_longest_item=false
		if child is Button:child.clip_text=true
		if child is CheckButton:child.alignment=HORIZONTAL_ALIGNMENT_CENTER
		if child is LineEdit:child.alignment=HORIZONTAL_ALIGNMENT_CENTER
		if child is Button or child is LineEdit:
			child.size.y=maxf(child.size.y,32)
			child.add_theme_font_size_override("font_size",16)
			var style:=StyleBoxFlat.new();style.bg_color=Color("#274653");style.border_color=Color("#74938d");style.set_border_width_all(1);style.set_corner_radius_all(8);style.content_margin_left=12;style.content_margin_right=14;style.content_margin_top=4;style.content_margin_bottom=4;child.add_theme_stylebox_override("normal",style)
			var hover:StyleBoxFlat=style.duplicate();hover.bg_color=Color("#365e69");hover.border_color=Color("#ebd59f");child.add_theme_stylebox_override("hover",hover)

	difficulty_picker.size.y=26
	seats_picker.size.y=32;spectator_picker.size.y=32
	rule_picker.size.y=32;no_items_picker.size.y=32;random_hero_picker.size.y=32
	hero_picker.size.y=32;arena_map_picker.size.y=32;opening_picker.size.y=32
	hero_picker.tooltip_text="Change your hero here without leaving the waiting room."
	opening_picker.tooltip_text="Off: everybody starts at level 10. On: everybody starts at level 1."

func _set_mode(value: String) -> void:
	if started:return
	var humans:=0
	for member in roster:
		if not bots.is_bot(str(member.id)):humans+=1
	var limit:=3 if value=="defense" else 4 if value in ["coop","descent"] else 8
	if humans>limit:
		status_label.text="This mode has fewer seats than the current party. Choose another mode.";return
	mode = value
	if not value in ["arena","battlegrounds","descent"]:spectator_host=false
	if value!="arena":bot_count=0

	var index := ["defense", "arena", "coop", "descent", "battlegrounds"].find(value)
	mode_picker.select(maxi(0, index))
	realm_picker.visible = value == "coop"
	rule_picker.visible = value == "arena"
	no_items_picker.visible=value=="arena";random_hero_picker.visible=value=="arena"
	notice = "Mode: " + value.capitalize() + ". Host shares the six-letter code; only host starts."
	if status_label != null: status_label.text = notice
	_update_lobby_settings()

func _town() -> void:
	_track_card_progress()
	if started and mode=="arena" and not spectating() and not practice_match() and (recovery==null or not recovery.frozen):legacy.card.arena_result(match_id,arena_random,"loss")
	legacy.save()
	get_tree().root.set_meta("fx_clinic",not results_reason.is_empty() and int(health.get(my_id,1))<=0)
	var return_hero=preferred_hero if mode=="arena" and arena_random else selected_hero
	var return_project=custom_party.project_for(return_hero)
	if not return_project.is_empty() and not return_hero.begins_with("community_"):return_hero=preload("res://scripts/studio_library.gd").hero_id(return_project)
	get_tree().root.set_meta("fx_hero",return_hero)
	_reset_connection()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

var joining_age:Dictionary={}
var network_cursor:=0
var incoming_backlog:=0
var received_packets:=0

func _close_link(id:String)->void:
	transport.forget(id)
	if not links.has(id):return
	var link:Dictionary=links[id]
	if link.get("channel")!=null:link.channel.close()
	if link.get("realtime")!=null:link.realtime.close()
	if link.get("peer")!=null:link.peer.close()
	links.erase(id)

func _drop_member(id:String)->void:
	_close_link(id)
	smoothing.erase("p:"+id);motion_received.erase(id);position_acks.erase(id)
	for values in [defeat_causes,player_cosmetics,positions,health,downed,revive_held,hero_ids,lobby_heroes,lobby_builds,teams,remote_draw_pos,food_slots,food_loadouts,food_registered,random_builds,joining_age]:values.erase(id)
	if recovery!=null:
		for values in [recovery.seen,recovery.gaps,recovery.attempts,recovery.epochs]:values.erase(id)
	if party_tools!=null:party_tools.late_pending.erase(id)
	for n in range(roster.size()-1,-1,-1):
		if str(roster[n].get("id",""))==id:roster.remove_at(n)

func _kick_member(id:String)->void:
	if role!="host" or id==my_id or id.begins_with("bot:"):return
	var found:=false
	for member in roster:
		if str(member.get("id",""))==id:found=true
	if not found:return
	_send_channel(id,{"type":"removed_from_room"})
	_send_ws({"type":"remove_peer","id":id,"manual":true})
	_drop_member(id)
	status_label.text="Player removed. Their seat is available."

func _exit_tree()->void:
	for id in links.keys():_close_link(str(id))
	if socket!=null:socket.close()

func _reset_connection() -> void:
	waiting_for_room=false;start_countdown=0
	if party_tools!=null:party_tools.reset_requests()
	_send_ws({"type":"leave"})
	if recovery!=null:recovery.reset()
	for id in links.keys():_close_link(str(id))
	joining_age.clear();transport.reset();smoothing.clear();position_history.clear();position_acks.clear();motion_received.clear();request_ready.clear();predicted_pose_until=0
	links.clear()
	if socket != null: socket.close()
	session_hero_sent = false;defeat_causes.clear();player_cosmetics.clear();chosen_team=-1;teams.clear();hero_ids.clear();random_builds.clear();lobby_heroes.clear();lobby_builds.clear();food_slots.clear();food_loadouts.clear();food_registered.clear();legacy.builds.clear()
	socket = null;last_socket_state = WebSocketPeer.STATE_CLOSED
	role = "";my_id = "";host_id = "";room_code = "";roster.clear();positions.clear();health.clear()
	server_matchmaking = false;no_public_rooms = false;search_remaining = 0.0

func _connect(command: Dictionary) -> void:
	if version_check!=null and version_check.blocked():version_check.notice();return
	var preview_team:int=chosen_team
	_reset_connection()
	chosen_team=preview_team
	connect_elapsed=0;waiting_for_room=true
	command.game_build=preload("res://scripts/build_update.gd").BUILD
	pending_command = command
	socket = WebSocketPeer.new()
	if socket.connect_to_url(ROOM_SERVICE_URL) != OK: status_label.text = "Room service unavailable. Try again."
	else: status_label.text = "Connecting to room service..."

func _host() -> void:
	if version_check!=null and version_check.blocked():version_check.notice();return
	if selected_hero.begins_with("custom_") and not custom_party.allowed(custom_party.project_for(selected_hero)):status_label.text="Enable custom heroes; all multiplayer builds need checked Forced Balance.";return
	if started: return
	party_tools.auto_solo=false
	var command := _room_command("host")
	command["public"] = public_room.button_pressed
	_connect(command)

func _join() -> void:
	if version_check!=null and version_check.blocked():version_check.notice();return
	if started: return
	party_tools.auto_solo=false
	var code := code_field.text.strip_edges().to_upper()
	if code.length() != 6: status_label.text = "Enter the host's six-letter code.";return
	_connect({"type": "join_request", "version":32, "custom":selected_hero.begins_with("custom_"),"balanced":preload("res://scripts/studio_balance.gd").hero_checked(custom_party.project_for(selected_hero)) if selected_hero.begins_with("custom_") else true, "code": code, "name": name_field.text.strip_edges()})

func _room_command(kind: String) -> Dictionary:
	return {"type":kind,"name":name_field.text.strip_edges(),"version":32,"bg_map":bg_map,"bg_team_size":bg_team_size,"mode":mode,"realm":str(realm_picker.get_item_metadata(realm_picker.selected)),"rule":"teams" if mode=="battlegrounds" or rule_picker.selected == 1 else "ffa","arena_map":arena_map,"opening":arena_opening,"no_items":arena_no_items,"random_heroes":arena_random,"seats":arena_seats,"spectator":spectator_host,"bots":bot_count,"ai_difficulty":ai_difficulty,"allow_custom":allow_custom,"custom":selected_hero.begins_with("custom_"),"balanced":preload("res://scripts/studio_balance.gd").hero_checked(custom_party.project_for(selected_hero)) if selected_hero.begins_with("custom_") else true}

func _join_random() -> void:
	if started: return
	_connect(_room_command("join_random"));search_remaining = 20.0

func _create_public() -> void:
	public_room.set_pressed_no_signal(true)
	_host()

func _leave_room() -> void:
	if started: return
	party_tools.auto_solo=false
	_reset_connection();results_reason = "";status_label.text = "Choose a mode, then host or join a room."

func _room_config(data: Dictionary) -> void:
	allow_custom=bool(data.get("config",{}).get("allow_custom",false));custom_picker.set_pressed_no_signal(allow_custom)
	var config: Dictionary = data.get("config", {})
	bg_map=str(config.get("bg_map","woodland"));bg_team_size=clampi(int(config.get("bg_team_size",4)),3,4);_sync_bg_pickers()
	ai_difficulty=bots.difficulty(config.get("ai_difficulty","medium"))
	arena_seats=clampi(int(config.get("seats",4)),2,8);spectator_host=bool(config.get("spectator",false));bot_count=clampi(int(config.get("bots",0)),0,mini(7,arena_seats-1));arena_map=str(config.get("arena_map","sand"));arena_opening=bool(config.get("opening",false));_sync_arena_pickers()
	no_items_picker.set_pressed_no_signal(bool(config.get("no_items",false)));random_hero_picker.set_pressed_no_signal(bool(config.get("random_heroes",false)))
	if config.has("mode"):
		mode=str(config["mode"]);mode_picker.select(maxi(0,["defense","arena","coop","descent","battlegrounds"].find(mode)))
	for index in realm_picker.item_count:
		if str(realm_picker.get_item_metadata(index)) == str(config.get("realm","")): realm_picker.select(index)
	rule_picker.select(1 if str(config.get("rule","ffa")) == "teams" else 0)
	public_room.set_pressed_no_signal(bool(data.get("public",false)))
	search_remaining = 0.0;no_public_rooms = false

func _solo() -> void:
	if version_check!=null and version_check.blocked():version_check.notice();return
	if selected_hero.begins_with("custom_") and not allow_custom:status_label.text="Turn on Allow custom heroes first.";return
	if spectator_supported() and spectator_host and mode!="arena":status_label.text="A spectator watches other players. Host a room and invite fighters first.";return
	if mode == "battlegrounds":status_label.text="Battlegrounds needs balanced 3v3 or 4v4 teams.";return
	if mode == "coop":status_label.text="Co-op needs another player.";return
	if mode=="arena":
		bot_count=maxi(2 if spectator_host else 1,bot_count);arena_seats=maxi(arena_seats,bot_count+1);_sync_arena_pickers()
	_reset_connection();role = "host";my_id = "solo";host_id = "solo";roster = [{"id":"solo", "name":"You"}]
	_add_player(my_id, 0);bots.sync_lobby()
	if mode=="arena" and rule_picker.selected==1:
		var index:=0
		for member in fighters():teams[str(member.id)]=index%2;index+=1
		if not _teams_ready():status_label.text="Team practice needs equal sides: choose 1 or 3 bots, or Free-for-all.";return
	_start_match()

func _start_button() -> void:
	if version_check!=null and version_check.blocked():version_check.notice();return
	if mode=="coop" and not preload("res://scripts/realm_access.gd").unlocked(legacy,str(realm_picker.get_item_metadata(realm_picker.selected))):status_label.text=preload("res://scripts/realm_access.gd").hint(legacy,str(realm_picker.get_item_metadata(realm_picker.selected)));return
	var custom_issue=custom_party.issue()
	if not custom_issue.is_empty():status_label.text=custom_issue;return
	if role != "host": status_label.text = "Only the host can start a room.";return
	for member in roster:
		var remote_id := str(member.get("id",""))
		if bots.is_bot(remote_id):continue
		if remote_id!=my_id and not lobby_heroes.has(remote_id):status_label.text="Wait for each hero to arrive, then Start.";return
		if remote_id != my_id and not _link_open(remote_id): status_label.text = "Wait for every player to connect, then press Start.";return
	if mode == "arena" and (fighters().size() < 2 or fighters().size()>arena_seats):
		status_label.text = "Arena needs 2–8 players within the selected seat limit.";return
	if mode=="arena" and rule_picker.selected==1 and not _teams_ready():status_label.text="Choose balanced Silver and Blue teams before Start (up to four each).";return
	if mode=="battlegrounds" and (fighters().size()!=bg_team_size*2 or not _teams_ready()):status_label.text="Choose balanced "+str(bg_team_size)+"v"+str(bg_team_size)+" teams before Start.";return
	if mode == "coop" and roster.size() < 2: status_label.text = "Co-op realm needs 2–4 players.";return
	if fighters().is_empty(): status_label.text = "Invite at least one adventurer before starting a broadcast.";return
	if fighters().size() > player_limit(): status_label.text = "Too many players for this adventure.";return
	if mode=="arena" and random_hero_picker.button_pressed:
		for id in positions:
			if id!=my_id and not bots.is_bot(str(id)) and not random_builds.has(id):status_label.text="Wait for each player’s hero profile to arrive, then Start.";return
	if server_matchmaking: _send_ws({"type":"room_update","started":true})
	_start_match()
	var config := match_config()
	for peer_id in links: _send_channel(str(peer_id), config)

func match_config()->Dictionary:
	return {"type":"start","unofficial":bool(get_meta("records_unofficial",false)),"bg_map":bg_map,"bg_team_size":bg_team_size,"mode":mode,"realm":realm_id,"rule":pvp_rule,"seed":floor_seed,"no_items":arena_no_items,"random_heroes":arena_random,"seats":arena_seats,"spectator":spectator_host,"bots":bot_count,"ai_difficulty":ai_difficulty,"opening":arena_opening,"arena_map":arena_map,"heroes":hero_ids,"match_id":match_id,"party_size":match_party_size,"teams":teams,"countdown":start_countdown,"allow_custom":allow_custom}

func _start_match() -> void:
	if version_check!=null and version_check.blocked():version_check.notice();return
	if mode=="coop" and role=="host" and get("dedicated")!=true:
		var chosen=str(realm_picker.get_item_metadata(realm_picker.selected))
		if not preload("res://scripts/realm_access.gd").unlocked(legacy,chosen):status_label.text=preload("res://scripts/realm_access.gd").hint(legacy,chosen);return
	if continuation==null:continuation=preload("res://scripts/solo_continue.gd").new();add_child(continuation);continuation.setup(self,true)
	continuation.begin()
	custom_party.reset()
	var travel=preload("res://scripts/travel_polish.gd").new();add_child(travel);travel.play("descent" if mode=="descent" else "portal")
	descent.reset()
	transport.reset();smoothing.clear();motion_received.clear();position_history.clear();position_acks.clear();request_ready.clear();movement_timer=0;local_position_sequence=0
	bots.sync_lobby();bots.reset()
	if spectator_director==null:
		spectator_director=preload("res://scripts/spectator_director.gd").new();add_child(spectator_director);spectator_director.setup(self)
	if presentation!=null:presentation.close();presentation.begin_run()
	if spectator_supported() and spectator_host:
		positions.erase(host_id);health.erase(host_id);teams.erase(host_id);hero_ids.erase(host_id)
	start_countdown=5.0
	if role=="host":
		match_id=Crypto.new().generate_random_bytes(16).hex_encode();match_party_size=positions.size()
		arena_opening=opening_picker.button_pressed;arena_map=str(arena_map_picker.get_item_metadata(arena_map_picker.selected));arena_no_items=mode=="arena" and no_items_picker.button_pressed;arena_random=mode=="arena" and random_hero_picker.button_pressed
		if arena_random:
			var ids:Array=characters.keys().filter(func(id):return not str(id).begins_with("custom_") and not bool(characters[id].get("npc_only",false)))
			for id in positions:
				if bots.is_bot(str(id)):continue
				hero_ids[id]=str(ids[randi_range(0,ids.size()-1)])
				if id!=my_id:legacy.builds[id]=legacy.sanitize_build(random_builds.get(id,{}).get(hero_ids[id],{}))
			selected_hero=str(hero_ids.get(my_id,preferred_hero))
		else:
			selected_hero=preferred_hero
			if not spectating() and get("dedicated")!=true:hero_ids[my_id]=preferred_hero
			for id in positions:
				if id!=my_id:
					hero_ids[id]=lobby_heroes.get(id,hero_ids.get(id,"ram"));legacy.builds[id]=lobby_builds.get(id,legacy.builds.get(id,{}))
	else:arena_no_items=mode=="arena" and arena_no_items;arena_random=mode=="arena" and arena_random
	preload("res://scripts/record_eligibility.gd").begin(self,hero_ids.values())
	defeat_causes.clear();defense_cleared_wave=0;arena_records.clear();arena_outcomes.clear()
	legacy_result_recorded=false
	pvp_scores.clear();contributions.clear();downed.clear();revive_held.clear();shield_reduction.clear();aim_angles.clear();results_reason=""
	shop_open = ""
	remote_draw_pos.clear()
	charges.clear();effects.clear();sent_effects.clear();damage_labels.clear();trails.clear();ice_walls.clear()
	upgrade_level = {"attack":0,"health":0,"armor":0,"count":0,"ranged":0,"area":0}
	for player_id in positions:
		arena_records[player_id]={"kills":0,"npc_kills":0,"deaths":0,"kill_streak":0,"best_kill_streak":0}
		food_slots[player_id]="" if mode=="arena" and arena_no_items else food_loadouts.get(player_id,"")
		health[player_id] = _max_hp(str(player_id));levels[player_id] = 10 if mode=="arena" and not arena_opening or str(player_id)==my_id and bool(legacy.data.teacher) else 1;xp[player_id] = 0;gold[player_id] = 100;kills[player_id] = 0
		cooldown_at[player_id] = {"primary":0,"secondary":0,"special":0}
		accepted_supplies.erase(player_id)
		inventory[player_id] = []
		if not (mode=="arena" and arena_no_items) and not arena_world.shatter.active():
			var bottle=str(supply_loadouts.get(player_id,""))
			if items.has(bottle) and preload("res://scripts/supply_slots.gd").consumable(items[bottle]):
				inventory[player_id].append(bottle);accepted_supplies[player_id]=bottle
				if str(player_id)==my_id:preload("res://scripts/prepared_supply.gd").commit(bottle)
		supply_loadouts.erase(player_id)
		health[player_id] = _max_hp(str(player_id));respawn_at[player_id] = 0;dodge_at[player_id] = 0;stealth_until[player_id] = 0;shield_until[player_id] = 0;haste_until[player_id] = 0;invincible_until[player_id] = 0;attack_branch[player_id] = "";mastery_choice[player_id] = ""
	hit_flash.clear();floor_transition=0
	started = true;wave = 0;floor_number = 1;run_time = 0.0;gate_hp = gate_max;wave_timer = 0.0 if mode=="defense" else 3.0;guard_timer = 0.0;floor_seed = randi() if role == "host" else floor_seed
	if role == "host":
		pvp_rule = "teams" if mode=="battlegrounds" or rule_picker.selected == 1 else "ffa"
		if mode not in ["arena","battlegrounds"] or pvp_rule!="teams":
			for id in teams:
				if int(teams[id])<0:teams[id]=_slot(str(id))%2
	if realm_picker.selected >= 0 and role == "host": realm_id = str(realm_picker.get_item_metadata(realm_picker.selected))
	enemy_pool.clear()
	if mode == "coop":
		var data: Dictionary = regions.get(realm_id, {})
		var scene: PackedScene = load(str(data.scene)) as PackedScene if not str(data.get("scene", "")).is_empty() else null
		if scene != null:
			var layout := scene.instantiate()
			for marker in layout.get_node("Enemies").get_children():
				var id := str(marker.get_meta("enemy_id", "bramble"))
				if not enemy_pool.has(id): enemy_pool.append(id)
			layout.free()
	else:
		for id in enemy_defs:
			if not bool(enemy_defs[id].get("expansion_only",false)): enemy_pool.append(str(id))
	if enemy_pool.is_empty(): enemy_pool = ["bramble"]
	record_party=[]
	if mode in ["coop","descent"]:record_party=preload("res://scripts/named_records.gd").party(legacy)
	_make_floor()
	preload("res://scripts/record_eligibility.gd").warn(self)
	# Classic co-op waves may only use the first scene markers. Keep authored
	# expansion encounters present even when their markers are later in the scene.
	if role=="host" and mode=="coop":
		for marker in world_spawns:
			if str(marker.type) not in adventure.newcomers.TYPES:continue
			var present:=false
			for e in opponents:
				if str(e.type)==str(marker.type) and e.pos.distance_to(marker.pos)<10:present=true;break
			if not present:adventure.spawn(str(marker.type),marker.pos,float(enemy_defs.get(str(marker.type),{}).get("health",100)),false)
	for id in positions: positions[id] = _spawn_player(_slot(str(id)))
	local_pos = positions.get(my_id, _spawn_player(0))
	media.refresh_arcade() if media.game!=null else assign_base_camera()
	_track_card_progress();legacy.save()
	status_label.text = "Build your army • Protect your barracks • Break their heart" if mode=="battlegrounds" else "Match started. Survive together!" if mode != "arena" else "Arena started • "+("Opening Act: level 1" if arena_opening else "level 10, all attacks ready")

func _make_floor() -> void:
	if is_instance_valid(realm_props):realm_props.queue_free()
	realm_props=null
	world_tile_cache.clear()
	if terrain_cache!=null:terrain_cache.reset()
	downed.clear()
	adventure.setup(realm_id if mode == "coop" else "")
	flame_bursts.clear()
	descent_nav=null
	opponents.clear();missiles.clear();guards.clear();field_obstacles.clear();world_patches.clear();world_buildings.clear();world_spawns.clear();world_decorations.clear();world_fountains.clear();fountain_tick=0;ice_walls.clear()
	if mode=="battlegrounds":
		FIELD=Rect2(Vector2.ZERO,battlegrounds.SIZE);world_terrain="ash" if bg_map=="warzone" else "forest";battlegrounds.setup(self);_rebuild_grid();return
	world_terrain = ("cinder_floor" if floor_number>100 else "ash") if mode == "descent" else "forest"
	var scene_path := "res://scenes/realms/" + ("defense" if mode == "defense" else "arena" if mode == "arena" else "descent") + "_world.tscn"
	FIELD = Rect2(Vector2.ZERO, Vector2(10600,9400) if mode == "defense" else Vector2(6200,4200) if mode == "arena" else Vector2(2400,1700))
	if mode == "coop":
		var data: Dictionary = regions.get(realm_id,{})
		var size: Array = data.get("size",[6200,4200])
		FIELD = Rect2(Vector2.ZERO, Vector2(float(size[0]),float(size[1])))
		world_terrain = str(data.get("terrain","forest"))
		scene_path = str(data.get("scene",scene_path))
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed != null:
		var layout: Node2D = packed.instantiate() as Node2D
		if layout.has_node("GroundPaint"):
			for node in layout.get_node("GroundPaint").get_children():
				if node is Polygon2D:
					var polygon := PackedVector2Array()
					for vertex in node.polygon: polygon.append(node.transform * vertex)
					world_patches.append({"polygon":polygon,"tile":str(node.get_meta("tile","path"))})
		if layout.has_node("Obstacles"):
			for marker in layout.get_node("Obstacles").get_children():
				field_obstacles.append({"pos":(marker as Node2D).position,"radius":float(marker.get_meta("radius",30.0)),"kind":str(marker.get_meta("kind","tree"))})
		if layout.has_node("Buildings"):
			for marker in layout.get_node("Buildings").get_children():
				world_buildings.append({"pos":(marker as Node2D).position,"name":str(marker.name),"sprite":str(marker.get_meta("sprite","house"))})
		if layout.has_node("Decorations"):
			for marker in layout.get_node("Decorations").get_children():
				if marker is Sprite2D and marker.texture != null: world_decorations.append({"pos":marker.position,"texture":marker.texture,"size":marker.texture.get_size()*marker.scale})
		if layout.has_node("Fountains"):
			for marker in layout.get_node("Fountains").get_children():world_fountains.append(marker.position)
		if layout.has_node("Enemies"):
			for marker in layout.get_node("Enemies").get_children(): world_spawns.append({"pos":(marker as Node2D).position,"type":str(marker.get_meta("enemy_id","bramble"))})
		if layout.has_node("Points/Spawn"): world_spawns.push_front({"pos":(layout.get_node("Points/Spawn") as Node2D).position,"type":"spawn"})
		layout.free()
	if mode=="arena":arena_world.setup(self,arena_map)
	if mode=="defense":north_gate.setup(self)
	if mode=="descent":descent.setup_geometry()
	_rebuild_grid()
	if role=="host" and mode=="coop" and adventure.expansion.active:
		for marker in world_spawns:
			if str(marker.type)=="spawn":continue
			adventure.spawn(str(marker.type),marker.pos,float(enemy_defs.get(str(marker.type),{}).get("health",100)),false)
	if role == "host" and mode == "descent":
		descent.floor_start()
	elif role == "host" and mode == "coop" and not adventure.active and not adventure.vault.active and not adventure.quests.active and not adventure.expansion.active and not adventure.school.active and not adventure.tech.active and not adventure.immersive.active and not adventure.foundry.active and not adventure.cinder.active:
		if adventure.city.active or adventure.hollow.active or realm_id in ["moonveil","zombie"]:
			wave=1;_spawn_wave(world_spawns.size()-1)
		else: _spawn_wave(12 * maxi(1,roster.size()) + wave * 5)

func _spawn_player(slot: int) -> Vector2:
	if arena_world.shatter.active():return arena_world.shatter.spawn(slot)
	if mode=="arena" and arena_map=="maze" and arena_world.extra.active():return arena_world.extra.spawn_point(slot)
	if mode=="battlegrounds":
		var members=fighters()
		return battlegrounds.spawn(str(members[clampi(slot,0,members.size()-1)].id)) if not members.is_empty() else Vector2(640,790)
	if mode == "coop" and adventure.city.active: return Vector2(85,1260-slot*65)
	if mode == "defense": return GATE + Vector2(-100 + slot * 65, 180)
	if mode == "coop" and not world_spawns.is_empty() and str(world_spawns[0]["type"]) == "spawn": return world_spawns[0]["pos"] + Vector2(slot * 65,0)
	if mode == "descent": return FIELD.size * 0.5 + Vector2(slot*65,0)
	var angle:=TAU*slot/float(maxi(2,fighters().size()))
	return _safe_arena_spawn(FIELD.size*.5+Vector2(cos(angle)*FIELD.size.x*.30,sin(angle)*FIELD.size.y*.30),slot)

func _safe_arena_spawn(preferred:Vector2,slot:int)->Vector2:
	# Check the whole hero footprint, not just its centre; use the same geometry as movement.
	for ring in range(0,32):
		for spoke in (1 if ring==0 else 24):
			var candidate:=preferred+Vector2.from_angle(TAU*spoke/24.0+slot*.17)*ring*32.0
			if not FIELD.grow(-40).has_point(candidate):continue
			var clear:bool=_clear_path(candidate,candidate) and arena_world.extra.movement_clear(candidate,candidate)
			for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				if not _clear_path(candidate,candidate+direction*24):clear=false;break
			if not clear:continue
			for other in positions:
				if _slot(str(other))!=slot and (positions[other] as Vector2).distance_to(candidate)<64:clear=false;break
			if clear:return candidate
	# All authored arenas have an open central court; search it if the preferred edge is crowded.
	for y in range(80,int(FIELD.size.y)-80,64):
		for x in range(80,int(FIELD.size.x)-80,64):
			var candidate:=Vector2(x,y)
			if _clear_path(candidate,candidate) and _clear_path(candidate,candidate+Vector2(24,24)) and _clear_path(candidate,candidate-Vector2(24,24)):return candidate
	push_error("Arena has no traversable spawn position.")
	return FIELD.size*.5

func _slot(id: String) -> int:
	var active:=fighters()
	for i in active.size():
		if str(active[i].get("id", "")) == id: return i
	return 0

func _add_player(id: String, slot: int) -> void:
	if not arena_records.has(id):arena_records[id]={"kills":0,"npc_kills":0,"deaths":0,"kill_streak":0,"best_kill_streak":0}
	if spectator_supported() and spectator_host and id==host_id:return
	if id==my_id:supply_loadouts[id]=preload("res://scripts/prepared_supply.gd").ready(items);shop_discounts[id]=legacy.discount(10)<10
	food_loadouts[id]=provisions.packed if id==my_id else "";food_slots[id]=food_loadouts[id]
	if id==my_id:food_registered[id]=true
	positions[id] = _spawn_player(slot);health[id] = int(characters.get(selected_hero,{}).get("max_health",120));gold[id] = 100;xp[id] = 0;levels[id] = 1;kills[id] = 0;teams[id] = -1
	hero_ids[id] = selected_hero if id == my_id else "ram"
	cooldown_at[id] = {"primary":0,"secondary":0,"special":0};cooldown_remaining[id] = {"primary":0.0,"secondary":0.0,"special":0.0};respawn_at[id] = 0;dodge_at[id] = 0;stealth_until[id]=0;attack_pose_until[id]=0;inventory[id] = [];attack_branch[id] = "";mastery_choice[id] = "";shield_until[id]=0;haste_until[id]=0;invincible_until[id]=0

func _send_ws(data: Dictionary) -> void:
	if socket != null and socket.get_ready_state() == WebSocketPeer.STATE_OPEN: socket.send_text(JSON.stringify(data))
func _send_signal(to_id: String, data: Dictionary) -> void:
	data["epoch"]=int(recovery.epochs.get(to_id,0)) if recovery!=null else 0
	_send_ws({"type":"signal", "to":to_id, "signal":data})
func _poll_socket() -> void:
	if socket == null: return
	socket.poll()
	var state := socket.get_ready_state()
	if state == WebSocketPeer.STATE_CLOSED and last_socket_state != state:
		status_label.text = "Room service disconnected. Direct links may continue." if _has_open_link() else "Room disconnected. Host or join again."
	last_socket_state = state
	var socket_budget:=24
	while socket!=null and socket.get_ready_state() == WebSocketPeer.STATE_OPEN and socket.get_available_packet_count() > 0 and socket_budget>0:
		socket_budget-=1
		var packet: Variant = JSON.parse_string(socket.get_packet().get_string_from_utf8())
		if packet is Dictionary: _server(packet as Dictionary)

func _server(data: Dictionary) -> void:
	if str(data.get("type","")) in ["hosted","joined","error","no_rooms","join_pending"]:waiting_for_room=false
	if party_tools!=null and party_tools.server(data):return
	if recovery!=null and recovery.server(data):return
	match str(data.get("type", "")):
		"server_info":
			if int(data.get("version",0))<30 or not "custom_heroes" in data.get("features",[]):
				waiting_for_room=false;pending_command.clear();socket.close();socket=null
				status_label.text="Update the Render room service to v139 for this game build."
				return
			server_matchmaking = "room_list" in data.get("features",[])
			_send_ws(pending_command);pending_command.clear()
		"no_rooms":
			search_remaining = 0.0;no_public_rooms = true;status_label.text = "No waiting public rooms for this mode. Create a public room to invite others."
		"room_status":
			public_room.set_pressed_no_signal(bool(data.get("public",false)))
			if role=="guest" and data.has("config") and not started:_room_config(data)
			if role=="host" and data.has("config") and not started:_room_config(data);bots.sync_lobby();_send_lobby_state()
		"hosted":
			_room_config(data)
			role = "host";my_id = str(data.get("id", ""));host_id = my_id;room_code = str(data.get("code", ""));code_field.text = room_code
			roster.assign(data.get("roster", []));_add_player(my_id, 0);bots.sync_lobby();
			if chosen_team in [0,1] and (mode=="battlegrounds" or mode=="arena" and rule_picker.selected==1):_assign_team(my_id,chosen_team)
			local_pos = positions.get(my_id,Vector2.ZERO)
			status_label.text = "Room " + room_code + " ready. " + ("Public: visible in the room browser." if public_room.button_pressed else "Private: share this code.") + ""
			if party_tools.auto_solo:party_tools.auto_solo=false;_send_ws({"type":"room_update","started":true});_start_match()
		"joined":
			_room_config(data)
			role = "guest";my_id = str(data.get("id", ""));host_id = str(data.get("host_id", ""));room_code = str(data.get("code", ""));code_field.text=room_code;roster.assign(data.get("roster", []))
			_add_player(my_id, roster.size()-1);local_pos = positions.get(my_id,Vector2.ZERO);status_label.text = "Joined. Establishing direct link to host..."
		"peer_joined":
			if continuation!=null and continuation.active:
				_send_ws({"type":"remove_peer","id":str(data.get("id",""))});return
			var id := str(data.get("id", ""))
			for member in roster:
				if str(member.get("id",""))==id:return
			roster.append({"id":id, "name":str(data.get("name", "Player"))});joining_age[id]=0.0
			if role == "host":
				if started and mode in ["defense","descent"]:party_tools.late_pending[id]=30.0
				else:_add_player(id, roster.size()-1)
				_create_link(id, true)
		"peer_left":
			_drop_member(str(data.get("id","")))
		"room_closed":
			var reason:=str(data.get("reason","The host closed the room."))
			_reset_connection();started=false;status_label.text=reason+" Host or join another room."
		"signal": _receive_signal(str(data.get("from", "")), data.get("signal", {}))
		"error": status_label.text = "Room error: " + str(data.get("message", "Unknown"))
	roster_label.text = "Room "+room_code+" • "+str(roster.size())+" players"

func _create_link(remote_id: String, offer: bool) -> void:
	if links.has(remote_id): return
	var peer := WebRTCPeerConnection.new()
	if peer.initialize({"iceServers":[{"urls":[STUN_URL]}]}) != OK: status_label.text = "WebRTC unavailable in this browser.";return
	var channel := peer.create_data_channel("movement", {"negotiated":true,"id":1})
	if channel == null: peer.close();return
	var realtime:=peer.create_data_channel("realtime",{"negotiated":true,"id":2,"ordered":false,"maxRetransmits":0})
	links[remote_id] = {"peer":peer,"channel":channel,"realtime":realtime,"remote_set":false,"ice_queue":[]}
	peer.session_description_created.connect(_local_description.bind(remote_id))
	peer.ice_candidate_created.connect(_local_candidate.bind(remote_id))
	if offer: peer.create_offer()

func _local_description(kind: String, sdp: String, remote_id: String) -> void:
	if links.has(remote_id) and (links[remote_id]["peer"] as WebRTCPeerConnection).set_local_description(kind,sdp) == OK:
		_send_signal(remote_id,{"kind":"description","sdp_type":kind,"sdp":sdp})
func _local_candidate(media: String, index: int, name: String, remote_id: String) -> void:
	_send_signal(remote_id,{"kind":"ice","media":media,"index":index,"name":name})
func _receive_signal(remote_id: String, value: Variant) -> void:
	if not value is Dictionary or remote_id.is_empty(): return
	var known:=false
	for member in roster:
		if str(member.get("id",""))==remote_id:known=true
	if not known:return
	var signal_data: Dictionary = value
	if recovery!=null and recovery.signal_for(remote_id,signal_data):return
	if not links.has(remote_id):
		if role == "guest" and remote_id == host_id and signal_data.get("kind") == "description": _create_link(remote_id,false)
		else: return
	if not links.has(remote_id): return
	var link: Dictionary = links[remote_id]
	var peer: WebRTCPeerConnection = link["peer"]
	if signal_data.get("kind") == "description":
		var kind := str(signal_data.get("sdp_type", ""))
		if kind not in ["offer","answer"]: return
		if peer.set_remote_description(kind,str(signal_data.get("sdp", ""))) == OK:
			link["remote_set"] = true
			for candidate in link["ice_queue"]: peer.add_ice_candidate(str(candidate["media"]),int(candidate["index"]),str(candidate["name"]))
			link["ice_queue"].clear()
	elif signal_data.get("kind") == "ice":
		if not bool(link["remote_set"]): link["ice_queue"].append(signal_data)
		else: peer.add_ice_candidate(str(signal_data.get("media", "")),int(signal_data.get("index", 0)),str(signal_data.get("name", "")))

func _send_channel(id: String, data: Dictionary) -> void:
	if not links.has(id): return
	var channel = links[id]["channel"]
	if str(data.get("type",""))=="pos":transport.send(id,data,true)
	elif channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN: channel.put_packet(JSON.stringify(data).to_utf8_buffer())
func _link_open(id: String) -> bool:
	return links.has(id) and links[id]["channel"].get_ready_state() == WebRTCDataChannel.STATE_OPEN
func _has_open_link() -> bool:
	for id in links:
		if _link_open(str(id)): return true
	return false

func _process(delta: float) -> void:
	if started and role=="host" and not dev_magic.quarantine:
		for actor in positions:
			if dev_magic.dev(str(actor)):dev_magic.isolate();break
	if dev_magic.world_scale()<1 and role=="host":
		for actor in cooldown_at:
			if dev_magic.scale_for(str(actor))<1:
				for ability in cooldown_at[actor]:
					if int(cooldown_at[actor][ability])>Time.get_ticks_msec():cooldown_at[actor][ability]+=int(delta*700)
	if terrain_cache!=null and not started:terrain_cache.visible=false
	for id in joining_age.keys():
		if lobby_heroes.has(id):joining_age.erase(id);continue
		joining_age[id]=float(joining_age[id])+delta
		if role=="host" and not started and float(joining_age[id])>=30.0:_kick_member(str(id))
	update_arena_notice(delta)
	motion_v85.advance(delta)
	if recovery!=null:recovery.step(delta)
	if started:
		card_save_timer-=delta
		if card_save_timer<=0:card_save_timer=5;_track_card_progress();legacy.save()
	for actor_id in positions:
		motion_v85.sample(str(actor_id),str(hero_ids.get(actor_id,"ram")),positions[actor_id],started and shop_open.is_empty() and int(health.get(actor_id,0))>0)
		adventure.combat.v79.sample(str(actor_id),positions[actor_id],delta,started and shop_open.is_empty() and int(health.get(actor_id,0))>0)
		adventure.combat.v78.sample(str(actor_id),positions[actor_id],started and shop_open.is_empty() and int(health.get(actor_id,0))>0)
	skating_motion.advance(delta)
	for actor_id in positions:
		var ground:Vector2=local_pos if actor_id==my_id else remote_draw_pos.get(actor_id,positions[actor_id])
		skating_motion.sample(str(actor_id),ground,delta,started and shop_open.is_empty() and str(hero_ids.get(actor_id,"ram"))=="goalie" and int(health.get(actor_id,0))>0 and not adventure.immersive.aboard(str(actor_id)))
		wing_motion.step(str(actor_id),ground,delta,started and shop_open.is_empty() and str(hero_ids.get(actor_id,"ram"))=="velvetwing" and int(health.get(actor_id,0))>0)
		basketball_motion.step(str(actor_id),ground,delta,started and shop_open.is_empty() and str(hero_ids.get(actor_id,"ram"))=="basketball" and int(health.get(actor_id,0))>0 and not adventure.immersive.aboard(str(actor_id)))
		fish_motion.step(str(actor_id),ground,delta,started and shop_open.is_empty() and str(hero_ids.get(actor_id,"ram"))=="ripplejaw" and int(health.get(actor_id,0))>0 and not adventure.immersive.aboard(str(actor_id)))
		motion_v85.landing(str(actor_id),ground,fish_motion.phase(str(actor_id)))
	var vacuum_aim:Vector2=mobile.aim if mobile.enabled else (media_mouse_world()-local_pos).normalized()
	adventure.combat.v56.holding(my_id,not arena_world.shatter.active() and started and shop_open.is_empty() and presentation.page.is_empty() and not fishing.busy() and adventure.combat.v90.primary_pressed(my_id,mobile.attacking if mobile.enabled else Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)),vacuum_aim)
	adventure.combat.release_heroes.holding(my_id,not arena_world.shatter.active() and started and shop_open.is_empty() and presentation.page.is_empty() and not fishing.busy() and Input.is_action_pressed("secondary"),vacuum_aim)
	adventure.combat.classics.holding(my_id,not arena_world.shatter.active() and started and shop_open.is_empty() and presentation.page.is_empty() and not fishing.busy() and Input.is_action_pressed("secondary"))
	adventure.combat.v79.holding(my_id,not arena_world.shatter.active() and started and shop_open.is_empty() and presentation.page.is_empty() and not fishing.busy() and Input.is_action_pressed("secondary"),vacuum_aim)
	adventure.combat.held_cast.local_input(delta,not arena_world.shatter.active() and started and start_countdown<=0 and not fishing.busy() and shop_open.is_empty() and presentation.page.is_empty() and not spectating() and not recovery.frozen)
	VIEW = get_viewport_rect().size
	_poll_socket()
	if search_remaining > 0:
		search_remaining -= delta
		if search_remaining <= 0 and role.is_empty(): status_label.text = "Search timed out. Retry; Join Random requires the v12 room-service update."
	if socket != null and socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		heartbeat_timer -= delta
		if heartbeat_timer <= 0: heartbeat_timer = 10.0;_send_ws({"type":"heartbeat"})
	var network_budget:=24
	var network_ids:=links.keys()
	incoming_backlog=0
	if not network_ids.is_empty():network_cursor=(network_cursor+1)%network_ids.size()
	for index in network_ids.size():
		var id=network_ids[(index+network_cursor)%network_ids.size()]
		if not links.has(id):continue
		var link: Dictionary = links[id]
		(link["peer"] as WebRTCPeerConnection).poll()
		var channel: WebRTCDataChannel = link["channel"]
		
		if role == "guest" and not started and not session_hero_sent and not selected_hero.begins_with("custom_") and channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
			_send_channel(host_id,{"type":"hero","hero":selected_hero,"build":legacy.payload(selected_hero),"random_builds":_random_build_payload() if mode=="arena" and arena_random else {},"food":provisions.packed,"consumable":preload("res://scripts/prepared_supply.gd").ready(items),"shop_discount":legacy.discount(10)<10,"cosmetic":local_cosmetic()});session_hero_sent = true
			if mode=="battlegrounds" or mode=="arena" and rule_picker.selected==1:_send_channel(host_id,{"type":"team","team":chosen_team})
		var peer_budget:=8
		for incoming in [channel,link.get("realtime")]:
			if incoming==null:continue
			var latest:Dictionary={}
			while incoming.get_ready_state()==WebRTCDataChannel.STATE_OPEN and incoming.get_available_packet_count()>0 and peer_budget>0 and network_budget>0:
				peer_budget-=1;network_budget-=1;received_packets+=1
				var packet:Variant=transport.decode(incoming.get_packet(),str(id))
				if not packet is Dictionary:continue
				if incoming!=channel and str(packet.get("type",""))=="state":
					if latest.is_empty() or int(packet.get("seq",0))>int(latest.get("seq",0)):latest=packet
				else:_packet(str(id),packet)
			if not latest.is_empty():_packet(str(id),latest)
			incoming_backlog+=incoming.get_available_packet_count()
	control.offset = (VIEW-Vector2(1280,720))*0.5
	mobile.visible=not spectating()
	control.visible = not started or shop_open == "Supplies"
	if started:
		for node in control.get_children():
			if node is Control:node.visible=shop_open=="Supplies" and (node==item_picker or node is Button and node.text=="BUY ITEM")
	else:
		party_lobby.visible=true;mode_picker.visible=false;item_picker.visible=false
		for node in control.get_children():
			if node is Control and node not in [party_lobby,mode_picker,item_picker]:node.visible=not (node is Button and node.text=="BUY ITEM")
		for index in mode_cards.size():
			mode_cards[index].disabled=role=="guest";mode_cards[index].modulate=Color("#ffe3a1") if index==["defense","arena","coop","descent","battlegrounds"].find(mode) else Color.WHITE
		name_field.editable=role.is_empty();code_field.editable=role.is_empty()
		for node in control.get_children():
			if node is Button and not node is CheckButton and not node is OptionButton:
				if node.text in ["HOST ROOM","JOIN / REQUEST","PUBLIC ROOMS","PLAY SOLO"]:node.disabled=not role.is_empty() or node.text=="PLAY SOLO" and mode in ["coop","battlegrounds"]
				elif node.text=="START ADVENTURE":node.disabled=role!="host"
				elif node.text=="LEAVE ROOM":node.disabled=role.is_empty() and not party_tools.waiting
				elif node.text=="SHOW PARTY":node.visible=not results_reason.is_empty()
		roster_label.visible=false
		custom_picker.disabled=role=="guest"
		create_public.visible=no_public_rooms;public_room.disabled=role=="guest"
		no_items_picker.disabled=role=="guest";random_hero_picker.disabled=role=="guest"
		no_items_picker.visible=mode=="arena";random_hero_picker.visible=mode=="arena"
		difficulty_picker.visible=mode in ["arena","defense"];difficulty_picker.disabled=role=="guest"
		bots_picker.visible=mode=="arena";bots_picker.disabled=role=="guest"
		seats_picker.visible=mode=="arena";spectator_picker.visible=spectator_supported();seats_picker.disabled=role=="guest";spectator_picker.disabled=role=="guest"
		hero_picker.disabled=spectating();hero_grid_button.disabled=hero_picker.disabled
		arena_map_picker.visible=mode=="arena";opening_picker.visible=mode=="arena";arena_map_picker.disabled=role=="guest";opening_picker.disabled=role=="guest"
		bg_help.visible=mode=="battlegrounds"
		bg_map_picker.visible=mode=="battlegrounds";bg_size_picker.visible=mode=="battlegrounds";bg_map_picker.disabled=role=="guest";bg_size_picker.disabled=role=="guest"
		realm_picker.disabled=role=="guest";rule_picker.disabled=role=="guest"
		realm_picker.visible=mode=="coop";rule_picker.visible=mode=="arena"
		lobby_timer-=delta
		if lobby_timer<=0:lobby_timer=.3;_send_lobby_state()

	if recovery!=null and recovery.frozen:queue_redraw();return
	if not started:
		if waiting_for_room and socket!=null and role.is_empty() and not party_tools.auto_solo:
			connect_elapsed+=delta
			if connect_elapsed<30:status_label.text="Connecting to room service • %ds elapsed (up to 30s)" % int(connect_elapsed)
			else:
				_reset_connection();status_label.text="Connection timed out. Host or join again to retry."
		if role=="guest" and not session_hero_sent:status_label.text="Connecting to host • waiting for your hero link…"
		queue_redraw();return
	if start_countdown>0:
		start_countdown=maxf(0,start_countdown-delta);queue_redraw();return
	if descent.falling():
		descent.step_transition(delta)
		if role=="host":
			send_timer-=delta
			if send_timer<=0:
				send_timer=.08
				if _has_open_link():_broadcast(_snapshot())
		queue_redraw();return
	run_time += delta;visual_time += delta
	var movement: Vector2 = mobile.movement if mobile.enabled else Input.get_vector("move_left","move_right","move_up","move_down")
	movement=adventure.combat.twister.sway(my_id,movement)
	if not presentation.page.is_empty():movement=Vector2.ZERO
	var alive := int(health.get(my_id,0)) > 0
	if arena_world.shatter.active() and Input.is_action_just_pressed("dodge"):arena_world.shatter.request("secondary")
	if not arena_world.shatter.active() and Input.is_action_just_pressed("dodge") and alive and not adventure.combat.stunned(adventure.combat.player_key(my_id)) and shop_open.is_empty() and not adventure.combat.classics.locked(my_id) and not adventure.combat.v48.moving(my_id) and not adventure.immersive.aboard(my_id) and not adventure.combat.robot.transformed(my_id) and not adventure.combat.v78.locked(my_id) and not adventure.combat.v79.moving(my_id) and not adventure.combat.v110.charging(my_id) and not adventure.combat.halloween.moving(my_id) and not adventure.combat.release_heroes.locked(my_id) and Time.get_ticks_msec() >= int(dodge_at.get(my_id,0)):
		dodge_at[my_id] = Time.get_ticks_msec() + 2500
		dodge_direction = movement.normalized() if movement.length_squared() > 0 else last_aim
		dodge_time = 0.26
		if role == "host": invincible_until[my_id] = Time.get_ticks_msec() + 220
		else: _send_channel(host_id,{"type":"dodge"})
	var displacement := Vector2.ZERO
	if alive and shop_open.is_empty() and not charges.has(my_id) and not adventure.combat.v79.moving(my_id) and not adventure.combat.v110.charging(my_id) and not adventure.combat.halloween.moving(my_id) and not adventure.combat.v78.locked(my_id):
		var speed:float = float(characters.get(selected_hero,{}).get("speed",230))*adventure.combat.speed_factor(adventure.combat.player_key(my_id))*legacy.speed_factor(my_id)*arena_world.slow(local_pos)*arena_world.objective.carrier_factor(my_id)
		if adventure.combat.classics.channeling(my_id):speed*=legacy.channel_speed(my_id)
		for carried_id in inventory.get(my_id,[]):
			if str(items.get(str(carried_id),{}).get("effect","")) == "bonus_speed": speed += float(items[str(carried_id)].get("amount",0))
		for carried_id in inventory.get(my_id,[]):
			if str(items.get(str(carried_id),{}).get("effect","")) == "bonus_speed": speed *= float(items[str(carried_id)].get("speed_multiplier",1.0))
		if Time.get_ticks_msec() < int(haste_until.get(my_id,0)): speed *= float(item_haste_scale.get(my_id,1.35))
		if Time.get_ticks_msec() < int(stealth_until.get(my_id,0)): speed *= 1.45
		if dodge_time > 0:
			var step := minf(delta,dodge_time)
			trails.append({"pos":local_pos,"time":0.18})
			displacement = dodge_direction * (330.0 + 370.0 * sin(PI*dodge_time/0.26)) * step * adventure.combat.v79.dodge_factor(my_id)
			dodge_time = maxf(0.0,dodge_time-step)
		else: displacement = adventure.combat.v79.displacement(my_id,movement,speed,delta) if selected_hero=="kite" else motion_v85.displacement(my_id,selected_hero,movement,speed,delta) if selected_hero in ["spindle","snowman","quill"] else (adventure.combat.v78.dig_vector(my_id,movement) if selected_hero=="gopher" else movement) * speed * (skating_motion.travel_time if selected_hero=="goalie" else delta)
		if dodge_time<=0:displacement=adventure.polish.motion(my_id,local_pos,displacement,delta)
		local_pos = _move_actor(local_pos,displacement*dev_magic.scale_for(my_id))
	if arena_world.shatter.active():
		local_pos=positions.get(my_id,local_pos) if not arena_world.shatter.playable(my_id) or arena_world.shatter.airborne(my_id) else _move_actor(positions.get(my_id,local_pos),movement.limit_length(1)*arena_world.shatter.SPEED*delta)
	adventure.combat.release_heroes.follow_local()
	adventure.combat.v79.follow_local(delta*dev_magic.scale_for(my_id))
	if role == "guest" and charges.has(my_id): local_pos = local_pos.lerp(network_charge_target,minf(1.0,delta*18.0))
	if role == "host" and not spectating(): positions[my_id] = local_pos
	media.refresh_arcade() if media.game!=null else assign_base_camera()
	if not spectating() and not fishing.busy() and shop_open.is_empty() and presentation.page.is_empty():
		if adventure.combat.v90.primary_pressed(my_id,mobile.attacking if mobile.enabled else Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)): _attack_request("primary")
		if Input.is_action_pressed("secondary"): _attack_request("secondary")
		if Input.is_action_just_pressed("special"): _attack_request("special")
	if role == "host":
		arena_world.step(delta*dev_magic.world_scale())
		_update_fountains(delta*dev_magic.world_scale())
		_update_revives(delta*dev_magic.world_scale())
		if not arena_world.shatter.active():adventure.step(delta*dev_magic.world_scale())
		_update_flames(delta*dev_magic.world_scale())
		bots.step(delta*dev_magic.world_scale())
		_simulate_charges(delta*dev_magic.world_scale())
		_simulate(delta*dev_magic.world_scale())
		send_timer -= delta
		if send_timer <= 0 or not started:
			send_timer = SEND_INTERVAL
			if _has_open_link():_broadcast(_snapshot())
			sent_effects.clear()
	else:
		movement_timer -= delta
		if movement_timer <= 0:
			movement_timer = MOVEMENT_INTERVAL
			local_position_sequence+=1;position_history[local_position_sequence]=local_pos
			while position_history.size()>64:position_history.erase(position_history.keys()[0])
			_send_channel(host_id,{"type":"pos","seq":local_position_sequence,"revive":Input.is_action_pressed("interact"),"x":roundi(local_pos.x),"y":roundi(local_pos.y),"hero":selected_hero,"secondary_held":not preload("res://scripts/ability_guide.gd").blocks(self) and not fishing.busy() and Input.is_action_pressed("secondary") and shop_open.is_empty(),"primary_held":not fishing.busy() and adventure.combat.v90.primary_pressed(my_id,mobile.attacking if mobile.enabled else Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and shop_open.is_empty(),"primary_angle":vacuum_aim.angle()})
	for id in positions:
		if id != my_id:
			if role=="host" and bots.is_bot(str(id)):smoothing.push("p:"+str(id),positions[id],Time.get_ticks_msec()/1000.0)
			remote_draw_pos[id]=smoothing.sample("p:"+str(id),positions[id],Time.get_ticks_msec()/1000.0,.05 if role=="host" else .075)
	transport.step(delta)
	if terrain_cache!=null:terrain_cache.sync()
	floor_transition=maxf(0,floor_transition-delta)
	for i in range(effects.size()-1,-1,-1):
		effects[i]["time"] = float(effects[i]["time"]) - delta
		if float(effects[i]["time"]) <= 0: effects.remove_at(i)
	for i in range(trails.size()-1,-1,-1):
		trails[i]["time"] -= delta
		if float(trails[i]["time"]) <= 0: trails.remove_at(i)
	for i in range(ice_walls.size()-1,-1,-1):
		ice_walls[i]["time"] -= delta
		if float(ice_walls[i]["time"]) <= 0: ice_walls.remove_at(i)
	for i in range(damage_labels.size()-1,-1,-1):
		damage_labels[i]["time"] -= delta;damage_labels[i]["pos"] += Vector2(0,-35)*delta
		if float(damage_labels[i]["time"]) <= 0: damage_labels.remove_at(i)
	queue_redraw()

func _clear_path(start: Vector2, finish: Vector2) -> bool:
	if mode=="descent":return descent.segment_clear(start,finish)
	if not arena_world.extra.shot_clear(start,finish):return false
	if not adventure.can_stand(finish): return false
	var count := maxi(1,int(ceil(start.distance_to(finish)/9.0)))
	for n in range(1,count+1):
		var point := start.lerp(finish,float(n)/float(count))
		if not adventure.can_stand(point): return false
		if mode=="defense" and not north_gate.terrain_open(point):return false
		var cell := Vector2i(point / 160.0)
		for x in range(cell.x-1,cell.x+2):
			for y in range(cell.y-1,cell.y+2):
				for obstacle in obstacle_grid.get(Vector2i(x,y),[]):
					if point.distance_to(obstacle["pos"]) < float(obstacle["radius"])+18.0: return false
		for wall in ice_walls:
			if point.distance_to(wall["pos"]) < 48: return false
	return true

func _attack_request(style: String) -> void:
	if descent.falling():return
	if preload("res://scripts/ability_guide.gd").blocks(self):return
	if arena_world.shatter.active():arena_world.shatter.request(style);return
	if fishing!=null and fishing.busy():return
	if characters.get(selected_hero,{}).has("studio_project"):return
	if not dev_magic.aiming.is_empty() or Time.get_ticks_msec()<dev_magic.input_until:return
	if adventure.combat.held_cast.suppressed(my_id,style):return
	if spectating() or start_countdown>0:return
	if recovery!=null and recovery.frozen:return
	if my_id.is_empty() or int(health.get(my_id,0)) <= 0: return
	var stats: Dictionary = characters.get(selected_hero,{}).get(style,{})
	var position: Vector2 = local_pos + mobile.aim * float(stats.get("range",300)) if mobile.enabled else media_mouse_world()
	var aim := (position - local_pos).normalized()
	if aim.length_squared() < 0.01: aim = Vector2.RIGHT
	last_aim = aim
	if role == "host": _attack(my_id,style,aim,position)
	else:
		if style not in ["primary","secondary","special"]:return
		var needed:=1 if style=="primary" else 3 if style=="secondary" else 6
		if int(levels.get(my_id,1))<needed:return
		var stamp:=Time.get_ticks_msec()
		if stamp<int(request_ready.get(style,0)):return
		stats=adventure.combat.effective_stats(my_id,style,stats)
		request_ready[style]=stamp if str(stats.get("style",""))=="v91_pistol" else stamp+1000 # Six-shooter clicks may queue independently; authority enforces cylinder/reload.
		predicted_pose_until=stamp+180
		journey.cue(presentation.sound_for(str(stats.get("style","melee"))))
		_send_channel(host_id,{"type":"attack","style":style,"angle":aim.angle(),"target":[position.x,position.y]})

func _attack(id: String, kind: String, aim: Vector2, target: Vector2 = Vector2.ZERO) -> void:
	if descent.falling():return
	if arena_world.shatter.active():arena_world.shatter.action(id,kind,aim);return
	if characters.get(str(hero_ids.get(id,"")),{}).has("studio_project"):return
	if adventure.combat.held_cast.charges.has(id) and not adventure.combat.held_cast.context.has(id):return
	if start_countdown>0:return
	if adventure.immersive.aboard(id):return
	if not adventure.combat.robot.allowed(id,kind):return
	if adventure.combat.busy(id) or adventure.combat.stunned(adventure.combat.player_key(id)):return
	if role != "host" or not started or not positions.has(id) or int(health.get(id,0)) <= 0 or charges.has(id): return
	if kind not in ["primary","secondary","special"] or not is_finite(aim.x) or not is_finite(aim.y): return
	var hero: Dictionary = characters.get(str(hero_ids.get(id,"ram")),characters.get("ram",{}))
	var stats: Dictionary = adventure.combat.effective_stats(id,kind,hero.get(kind,{}))
	var needed := 1 if kind == "primary" else 3 if kind == "secondary" else 6
	if int(levels.get(id,1)) < needed: return
	adventure.combat.v79.prepare(id,stats,aim,target)
	if not adventure.combat.stance_heroes.prepare(id,stats):return
	if not adventure.combat.party_heroes.prepare(id,stats):return
	if not adventure.combat.morrow.prepare(id,stats,aim):return
	if not adventure.combat.v78.prepare(id,stats):
		if id==my_id:status_label.text="Place two rift pins before using Quarter Turn."
		return
	if not adventure.combat.pact.prepare(id,stats,aim,target):
		if id==my_id:status_label.text="Choose a visible non-boss enemy for Change of Heart."
		return
	if not adventure.combat.agent.prepare(id,stats,aim,target):
		if id==my_id:status_label.text="Aim at an enemy for Ambush."
		return
	aim_angles[id]=aim.angle()
	var now := Time.get_ticks_msec()
	var cd: Dictionary = cooldown_at.get(id,{})
	if now < int(cd.get(kind,0)): return
	if not adventure.combat.v90.pistol_ready(id,stats):return
	var delay := float(stats.get("cooldown",0.5))
	var passive := str(hero.get("passive_effect",""))
	if int(levels.get(id,1)) >= 5:
		if passive == "quick_primary" and kind == "primary": delay *= 0.7 if str(mastery_choice.get(id,"")) == "passive" else 0.8
		if passive == "quick_secondary" and kind == "secondary": delay *= 0.8
	if kind == "secondary" and str(attack_branch.get(id,"")) == "secondary": delay *= 0.7
	if kind == "special" and str(mastery_choice.get(id,"")) == "special": delay *= 0.7
	for carried_id in inventory.get(id,[]):
		if str(items.get(str(carried_id),{}).get("effect","")) == "cooldown": delay *= 1.0-float(items[str(carried_id)].get("amount",0))/100.0
	if mode=="descent":delay*=descent.cooldown(id)
	delay=adventure.combat.v90.pistol_delay(id,stats,delay)
	cd[kind] = now + int(1000.0*delay);cooldown_at[id] = cd;attack_pose_until[id] = now+240
	core_art.record(id,kind,str(hero_ids.get(id,"ram")),delay)
	var style := str(stats.get("style","melee"))
	var origin: Vector2 = positions[id]
	var damage := float(stats.get("damage",20))* (descent.power(id) if mode=="descent" else 1.0)
	for item_id in inventory.get(id,[]):
		var carried: Dictionary = items.get(str(item_id),{})
		if str(carried.get("effect","")) == "bonus_damage": damage += float(carried.get("amount",0))
	if kind == "primary" and str(attack_branch.get(id,"")) == "primary": damage += 8.0
	if now < int(stealth_until.get(id,0)): damage *= 2.0;stealth_until[id] = 0
	var reach := float(stats.get("range",stats.get("radius",85)))
	var color := str(stats.get("color","#ffd877"))
	journey.cue(presentation.sound_for(style))
	if adventure.combat.cast(id,stats,aim,damage):return
	if float(stats.get("travel_speed",0)) > 0:
		var landing := origin+aim.normalized()*minf(reach,origin.distance_to(target))
		adventure.launch_lob(id,origin,landing,stats,damage)
		return
	if style == "return_disc":
		adventure.launch_disc(id,aim,stats,damage);return
	if style == "flame":
		flame_bursts.append({"owner":id,"stats":stats,"time":.9,"tick":0.0,"ticks":5,"damage":float(stats.get("damage",8))+(damage-float(stats.get("damage",8)))/5.0,"aim":aim})
		return
	if style == "stealth":
		_heal(id,id,int(stats.get("heal",30)))
		stealth_until[id] = now+int(1000.0*float(stats.get("duration",3.0)))
		_emit_effect({"pos":origin,"radius":40.0,"time":0.4,"color":color,"victim":id});return
	if style == "block":
		shield_reduction[id]=minf(.95,float(stats.get("reduction",.75))+(0.15 if (inventory.get(id,[]) as Array).has("guard_buckler") else 0.0))
		shield_until[id] = now+int(1000.0*float(stats.get("duration",1.1)))
		_emit_effect({"pos":origin,"radius":38.0,"time":0.4,"color":color});return
	if style == "heal_zone":
		adventure.create_healing_zone(id,stats);return
	if style == "heal_wave":
		var healing_radius := float(stats.get("radius",180))
		for other in positions:
			if mode not in ["arena","battlegrounds"] or other == id or (pvp_rule == "teams" and int(teams.get(other,-1)) == int(teams.get(id,-2))):
				if origin.distance_to(positions[other]) <= healing_radius: _heal(id,str(other),int(stats.get("heal",35 if kind == "special" else 25)))
		_emit_effect({"pos":origin,"radius":healing_radius,"time":0.4,"visual":str(stats.get("visual","")),"color":color});return
	if style == "summon":
		for n in int(stats.get("count",1)):
			guards.append({"pos":origin+Vector2(45+n*25,30),"lane":-1,"hp":70.0,"max_hp":70.0,"net_uid":transport.next(),"damage":damage,"type":"summoned","owner":id,"sprite":str(stats.get("minion_sprite","mini_basketball")),"speed":float(stats.get("minion_speed",270)),"time":float(stats.get("duration",12))+(2 if adventure.combat.passive(id,"long_buddies") else 0),"attack_timer":0.3})
		return
	if style == "charge":
		charges[id] = {"direction":aim,"remaining":reach,"speed":float(stats.get("speed",680)),"damage":damage,"hits":[],"players":[]}
		return
	if style in ["projectile","homing"]:
		var count := clampi(int(stats.get("count",1)),1,5)
		for index in count:
			var direction := aim.rotated((float(index)-float(count-1)*0.5)*float(stats.get("spread",0.0)))
			missiles.append({"credit":preload("res://scripts/defeat_credit.gd").resolve(self,id,str(stats.get("name",kind.capitalize()))),"pos":origin+direction*27,"direction":direction,"speed":float(stats.get("speed",420)),"damage":float(stats.get("damage",0))+(damage-float(stats.get("damage",0)))/maxi(1,int(stats.get("count",1))) if bool(stats.get("bonus_split",false)) else damage,"owner":id,"homing":style=="homing","distance":0.0,"range":reach,"color":color})
		return
	if style == "chain":
		_chain_attack(id,origin,target,stats,damage);return
	var center := origin
	if style in ["target_aoe","ice_wall"] or (style == "trap" and kind != "special"):
		center = origin + aim * minf(reach,origin.distance_to(target))
		if style == "ice_wall": ice_walls.append({"pos":center,"time":float(stats.get("duration",4.0))})
		reach = float(stats.get("blast_radius",110))
	var melee := style in ["melee","punch","scratch","slash","kick"]
	var half_arc := deg_to_rad(float(stats.get("arc_degrees",105)))*0.5
	_emit_effect({"pos":center,"radius":reach,"angle":aim.angle(),"half_arc":half_arc,"style":style,"visual":str(stats.get("visual",style)),"owner":id if melee else "","time":0.28,"color":color})
	for i in range(opponents.size()-1,-1,-1):
		var offset: Vector2 = opponents[i]["pos"]-center
		var hit:bool = offset.length() <= reach+(float(opponents[i].get("hit_radius",0)) if melee else 0)
		if melee: hit = hit and aim.dot(offset.normalized()) > cos(half_arc)
		if style == "beam": hit = offset.dot(aim)>0 and offset.dot(aim)<reach and absf(offset.cross(aim))<45
		if hit and _clear_path(center,opponents[i]["pos"]):
			adventure.combat.apply_hit_status(adventure.combat.npc_key(opponents[i]),stats,id);_hit_enemy(i,damage,id)
	if mode in ["arena","battlegrounds"]:
		for other in adventure.combat.v59.target_points():
			if not _rival(id,adventure.combat.v59.rival_id(str(other))): continue
			var offset: Vector2 = adventure.combat.v59.target_position(str(other))-center
			var hit := offset.length() <= reach
			if melee: hit = hit and aim.dot(offset.normalized()) > cos(half_arc)
			if style == "beam": hit = offset.dot(aim)>0 and offset.dot(aim)<reach and absf(offset.cross(aim))<45
			if hit and _clear_path(center,adventure.combat.v59.target_position(str(other))):
				if Time.get_ticks_msec()>=int(invincible_until.get(other,0)):adventure.combat.apply_hit_status(adventure.combat.player_key(str(other)),stats,id)
				_hurt(str(other),damage,id,adventure.combat.player_key(id) if melee else "",preload("res://scripts/defeat_credit.gd").resolve(self,id,str(stats.get("name",kind.capitalize()))))
	if mode=="battlegrounds":
		for key in battlegrounds.hostile(id):
			var actor:Dictionary=battlegrounds.actor(key);var offset:Vector2=actor.pos-center;var hit:bool=offset.length()<=reach+20
			if melee:hit=hit and aim.dot(offset.normalized())>cos(half_arc)
			if style=="beam":hit=offset.dot(aim)>0 and offset.dot(aim)<reach and absf(offset.cross(aim))<45
			if hit and _clear_path(center,actor.pos):adventure.combat.apply_hit_status(key,stats,id);battlegrounds.damage(key,damage,id)

func _hit_enemy(index: int, amount: float, killer: String) -> void:
	amount*=adventure.pursuers.outgoing(killer)
	if index>=0 and index<opponents.size() and bool(opponents[index].get("health_gem",false)):
		var gem:Dictionary=opponents[index];opponents.remove_at(index);descent.shatter(gem,killer);return
	if not adventure.expansion.sharing:
		amount*=adventure.combat.war_multiplier(killer)
		if index>=0 and index<opponents.size() and not bool(opponents[index].get("converted",false)):amount=legacy.critical(killer,amount,opponents[index].pos)
	if index < 0 or index >= opponents.size(): return
	if bool(opponents[index].get("buried",false)):return
	if mode=="defense" and str(opponents[index].type) in north_gate.RIVALS and north_gate.rival_kit(str(opponents[index].type)) in ["npc_bastion","npc_thorn"] and adventure.combat.effect_time(adventure.combat.npc_key(opponents[index]),"guard")>0:amount*=.55
	if bool(opponents[index].get("converted",false)):amount=float(opponents[index].hp)
	if mode=="descent":amount=descent.receive_damage(opponents[index],amount);descent.struck(opponents[index])
	var actual := 0.0 if bool(opponents[index].get("converted",false)) else maxf(0,minf(amount,float(opponents[index]["hp"])))
	adventure.expansion.linked_hit(adventure.combat.npc_key(opponents[index]),actual)
	adventure.combat.v112.on_hit(killer,adventure.combat.npc_key(opponents[index]),actual)
	adventure.combat.v90.on_hit(killer,actual)
	_stat(killer,"damage",actual)
	if not bool(opponents[index].get("converted",false)):_damage_feedback(opponents[index]["pos"],amount)
	_apply_lifesteal(killer,actual)
	opponents[index]["hp"] = float(opponents[index]["hp"])-amount
	if float(opponents[index]["hp"]) > 0: return
	if adventure.expansion.revive_intercept(opponents[index]):return
	adventure.combat.morrow.fallen(opponents[index])
	adventure.combat.robot.on_kill(killer)
	var defeated: Dictionary = opponents[index]
	var boss: bool = bool(defeated.get("boss",false))
	if boss:presentation.burst(defeated.pos);journey.cue("victory")
	if mode=="descent":descent.defeated(defeated)
	opponents.remove_at(index)
	if mode=="defense":north_gate.killed(defeated)
	adventure.on_defeat(defeated)
	adventure.check_trial_clear(defeated)
	if mode == "defense": _stat(killer,"defence",1)
	if arena_records.has(killer):
		if mode=="defense" and str(defeated.get("type","")) in north_gate.RIVALS:arena_records[killer].kills+=1
		else:arena_records[killer].npc_kills+=1
	if mode=="defense" and killer=="lane_guard":north_gate.guard_bounty(boss)
	if not gold.has(killer): return
	kills[killer] = int(kills.get(killer,0))+1
	gold[killer] = int(gold.get(killer,0))+ (40 if boss else 6+posmod(int(defeated.get("uid",0)),3) if mode in ["coop","descent"] else 2) + (2 if (inventory.get(killer,[]) as Array).has("gold_magnet") else 0)
	xp[killer] = 0 if mode=="arena" and not arena_opening else int(xp.get(killer,0)) + (12 if boss else 1)
	if int(levels.get(killer,1))>=5 and str(characters.get(str(hero_ids.get(killer,"ram")),{}).get("passive_effect",""))=="heal_on_kill":
		health[killer] = mini(_max_hp(killer),int(health.get(killer,100))+(9 if str(mastery_choice.get(killer,""))=="passive" else 4))
	var target := 5 + int(levels.get(killer,1))*3
	if int(xp[killer]) >= target:
		xp[killer] = int(xp[killer])-target
		levels[killer] = int(levels[killer])+1
		var new_level := int(levels[killer])
		descent.reward(killer,new_level)
		health[killer] = mini(_max_hp(killer),int(health.get(killer,100))+(25 if new_level in [2,4,7,9] else 15))
		if killer == my_id and new_level in [8,10]:
			status_label.text = "LEVEL " + str(new_level) + ": press J for primary/special or K for secondary/passive."

func _hurt(id: String, amount: float, source: String = "", melee_attacker:String="", cause:Dictionary={}) -> void:
	if descent.falling():return
	if mode=="descent" and source=="enemy":amount*=float(descent.scaling(floor_number).damage)
	if arena_world.shatter.active():return
	if id.begins_with("c|"):
		adventure.combat.damage(id,amount,source);return
	if id.begins_with("summon:"):adventure.combat.summon_hurt(id,amount,source);return
	if id.begins_with("risen:"):adventure.combat.morrow.hurt(id,amount,source);return
	var linked_direct:bool=adventure.combat.morrow.direct_owner==id
	var adjusted:float=amount
	if not linked_direct:
		if adventure.combat.v78.immune(id) or adventure.combat.stance_heroes.immune(id):return
		if not adventure.expansion.sharing and positions.has(id):amount=legacy.critical(source,amount,positions[id])
		if amount>0 and not adventure.combat.dot_damage and adventure.combat.v90.smoke_dodges(id):return
		var before_reduction:float=amount
		amount*=legacy.hurt_factor(id)
		if id.begins_with("bond:"):adventure.combat.pact.hurt_ally(id.trim_prefix("bond:"),amount,source);return
		if adventure.combat.v59.is_mirror(id):adventure.combat.v59.hurt_copy(id.trim_prefix("mirror:"),amount,source);return
		if int(health.get(id,0))<=0 or Time.get_ticks_msec()<int(invincible_until.get(id,0)): return
		if not melee_attacker.is_empty():adventure.combat.melee_received(id,melee_attacker)
		if adventure.combat.classics.channeling(id):amount*=1.3
		adjusted = amount*(1.0 if adventure.expansion.sharing else adventure.combat.war_multiplier(source))*(1.0-adventure.combat.reduction(id))
		if Time.get_ticks_msec()<int(shield_until.get(id,0)):
			adjusted *= 1.0-float(shield_reduction.get(id,.75))
		for item_id in inventory.get(id,[]):
			var carried: Dictionary = items.get(str(item_id),{})
			if str(carried.get("effect",""))=="armor": adjusted *= 1.0-float(carried.get("amount",0))/100.0
		if int(levels.get(id,1))>=5 and str(characters.get(str(hero_ids.get(id,"ram")),{}).get("passive_effect",""))=="guard": adjusted *= 0.8 if str(mastery_choice.get(id,""))=="passive" else 0.9
		var attack_multiplier:float=(1.0 if adventure.expansion.sharing else adventure.combat.war_multiplier(source))*(1.3 if adventure.combat.classics.channeling(id) else 1.0)
		adjusted=adventure.combat.v79.erode("p:"+id,before_reduction*attack_multiplier,adjusted)
		adjusted=adventure.combat.mantis.on_damage(id,adjusted)
		if get("expedition")!=null and get("expedition").special():adjusted=get("expedition").relics.incoming(id,adjusted)
		if adjusted<=0:return
	if int(health.get(id,0))<=0:return
	adjusted=adventure.combat.morrow.share_hero(id,adjusted)
	if not linked_direct and mode in ["arena","battlegrounds"] and _rival(source,id):_stat(source,"damage",minf(adjusted,maxf(0,float(health.get(id,0)))))
	journey.cue("hurt")
	if id==my_id:presentation.impact(false,amount)
	_damage_feedback(positions[id],adjusted,id)
	if adjusted>=1:
		hit_flash[id]=Time.get_ticks_msec()+300
		_emit_effect({"pos":positions[id],"radius":34.0,"time":.3,"color":"#ff827d","style":"hit_ring","victim":id})
	if not linked_direct:
		_apply_lifesteal(source,minf(adjusted,float(health.get(id,0))))
		adventure.combat.v112.on_hit(source,"p:"+id,minf(adjusted,float(health.get(id,0))))
		adventure.combat.v90.on_hit(source,minf(adjusted,float(health.get(id,0))))
	adventure.expansion.linked_hit("p:"+id,minf(adjusted,float(health.get(id,0))))
	health[id] = maxi(0,int(health.get(id,100))-int(adjusted))
	if int(adjusted)>0:provisions.check_auto(id)
	if source == "enemy" and (inventory.get(id,[]) as Array).has("thorn_coat"):
		for foe_index in range(opponents.size()-1,-1,-1):
			if positions[id].distance_to(opponents[foe_index]["pos"])<70: _hit_enemy(foe_index,9.0,id);break
	if int(health[id])==0 and adventure.combat.v59.rescue(id):return
	if int(health[id])==0 and (inventory.get(id,[]) as Array).has("last_stand"):
		(inventory[id] as Array).erase("last_stand");health[id]=45
	if int(health[id]) == 0:
		arena_world.objective.elimination(id,source)
		defeat_causes[id]=cause.duplicate(true) if not cause.is_empty() else preload("res://scripts/defeat_credit.gd").resolve(self,source,"Melee strike" if not melee_attacker.is_empty() else "Ability hit",melee_attacker)
		var ash_pending:bool=adventure.combat.v90.intercept_defeat(id)
		adventure.combat.morrow.fallen({"pos":positions[id],"corpse_sprite":characters.get(str(hero_ids.get(id,"ram")),{}).get("sprite","ram"),"type":"hero"})
		if mode=="defense" and source in north_gate.RIVALS:north_gate.rival_gain(6,source)
		if arena_records.has(id):arena_records[id].deaths+=1;arena_records[id].kill_streak=0
		if mode in ["arena","battlegrounds"]:
			adventure.combat.robot.on_kill(source)
			respawn_at[id] = 9223372036854775807 if ash_pending else Time.get_ticks_msec()+(7000 if mode=="battlegrounds" else 2500)
			if mode=="battlegrounds":battlegrounds.command.hero_bounty(id,source)
			if positions.has(source) and source != id and (pvp_rule=="ffa" or int(teams.get(source,0))!=int(teams.get(id,0))):
				if arena_records.has(source):
					arena_records[source].kills+=1;arena_records[source].kill_streak+=1;arena_records[source].best_kill_streak=maxi(int(arena_records[source].best_kill_streak),int(arena_records[source].kill_streak))
				pvp_scores[source]=int(pvp_scores.get(source,0))+1
				kills[source] = int(kills.get(source,0))+1
		else:
			respawn_at[id] = 9223372036854775807
			if not ash_pending and positions.size()>1: downed[id]={"left":25.0,"progress":0.0,"rescuer":""}
			elif not ash_pending and mode=="defense":respawn_at[id]=Time.get_ticks_msec()+5000
			var living := false
			for player_id in health:
				if int(health[player_id])>0 or adventure.combat.v90.pending_rebirth(str(player_id)):living=true
			if not living and mode in ["coop","descent"]:end_match("Party defeated • try a new team strategy")

func _spawn_wave(amount: int) -> void:
	if mode=="defense":
		north_gate.spawn_wave(wave);return
	var authored:bool=mode=="coop" and realm_id in ["grove","quarry","ice"] and world_spawns.size()>1
	var first_marker:=1
	if authored:
		var total:=world_spawns.size()-1;var batch:=ceili(total/3.0);first_marker=1+maxi(0,wave-1)*batch;amount=maxi(0,mini(batch,world_spawns.size()-first_marker))
	var prior_size:=opponents.size()
	var random := RandomNumberGenerator.new();random.seed = floor_seed + wave*9929 + floor_number*271
	for n in amount:
		var id := enemy_pool[random.randi_range(0,enemy_pool.size()-1)]
		var stats: Dictionary = enemy_defs.get(id,{})
		var lane := n % 3
		var pos: Vector2 = APPROACHES[lane] + Vector2(random.randf_range(-55,55),random.randf_range(-55,55)) if mode == "defense" else _random_spawn(random)
		if mode == "coop" and world_spawns.size()>1:
			var marker: Dictionary = world_spawns[first_marker+n if authored else 1+n%(world_spawns.size()-1)]
			pos = marker["pos"];id = str(marker["type"]);stats = enemy_defs.get(id,{})
		if mode == "defense": pos = GATE + (APPROACHES[lane]-GATE).normalized()*minf(GATE.distance_to(APPROACHES[lane]),2200.0+maxi(0,wave-1)*180.0) + Vector2(random.randf_range(-45,45),random.randf_range(-45,45))
		if mode == "arena" and positions.size() > 0 and pos.distance_to(local_pos) < 150: pos += Vector2(200,0)
		var hp := float(stats.get("health",65))*(1.0+0.13*float(wave)+0.09*float(floor_number-1))* (1.4 if mode == "coop" else 1.0)
		if mode == "descent": hp = float(stats.get("health",65))*descent.scaling(floor_number).health*(1+.5*maxi(0,positions.size()-1))
		opponents.append({"pos":pos,"hp":hp,"max_hp":hp,"type":id,"lane":lane,"boss":false,"attack_timer":0.0,"uid":randi()})
	if mode == "defense" and wave%5 == 0 or mode == "coop" and wave == 3:
		opponents.append({"pos":APPROACHES[0] if mode == "defense" else FIELD.size * Vector2(0.78,0.5),"hp":180.0+floor_number*28.0 if mode == "descent" else 230.0+wave*75.0+floor_number*50.0,"max_hp":180.0+floor_number*28.0 if mode == "descent" else 230.0+wave*75.0+floor_number*50.0,"type":str(regions[realm_id]["boss_enemy"]) if mode=="coop" and regions.get(realm_id,{}).has("boss_enemy") else "cartographer" if adventure.combat.coast.active else "eclipse_engine" if adventure.astral else "hourglass_hart" if adventure.clockwork else "crowned_torrent" if adventure.river else "bellroot" if adventure.marsh else enemy_pool[0],"lane":0,"boss":true,"expansion_boss":(mode=="coop" and regions.get(realm_id,{}).has("boss_enemy")) or adventure.combat.coast.active or adventure.marsh or adventure.river or adventure.clockwork or adventure.astral,"skill_timer":2.0,"skill_step":0,"attack_timer":0.0,"uid":randi()})
		if mode=="coop" and realm_id=="ice":opponents[-1].sprite="cryowarden"
		if authored:
			var last:Array=regions[realm_id].route_points[-1];opponents[-1].pos=Vector2(last[0],last[1]);opponents[-1].hp=float(regions[realm_id].boss_health)*(1+.25*maxi(0,positions.size()-1));opponents[-1].max_hp=opponents[-1].hp
		if mode=="coop" and regions.get(realm_id,{}).has("boss_enemy"):
			opponents[-1]["hp"]=float(regions[realm_id].get("boss_health",1200))*(1+.55*maxi(0,positions.size()-1));opponents[-1]["max_hp"]=opponents[-1]["hp"]
		if adventure.combat.coast.active:
			var paper_boss:Dictionary=opponents[-1]
			paper_boss["pos"]=Vector2(5200,1500);paper_boss["hp"]=780.0*(1.0+.55*maxi(0,positions.size()-1));paper_boss["max_hp"]=paper_boss["hp"]
		if adventure.astral:
			var engine: Dictionary = opponents[-1]
			engine["pos"] = Vector2(7100,1800)
			engine["hp"] = 1000.0*(1.0+.55*maxi(0,positions.size()-1));engine["max_hp"] = engine["hp"]
		if adventure.clockwork:
			var guardian: Dictionary = opponents[-1]
			guardian["pos"] = Vector2(6200,2100)
			guardian["hp"] = 900.0*(1.0+.55*maxi(0,positions.size()-1));guardian["max_hp"] = guardian["hp"]
		if adventure.river:
			var boss: Dictionary = opponents[-1]
			boss["pos"] = Vector2(6900,1900)
			boss["hp"] = 950.0*(1.0+.55*maxi(0,positions.size()-1));boss["max_hp"] = boss["hp"]

	if mode=="defense":
		for n in range(prior_size,opponents.size()):opponents[n]["defense_wave"]=wave

func _simulate(delta: float) -> void:
	if arena_world.shatter.active():return
	descent.step(delta)
	if mode=="battlegrounds":
		battlegrounds.step(delta)
	elif mode == "defense":
		north_gate.step(delta)
		wave_timer -= delta
		guard_timer -= delta
		if wave_timer <= 0 and north_gate.next_wave_allowed():
			wave += 1;_spawn_wave(north_gate.wave_count(wave))
			wave_timer = float(north_gate.config.get("second_wave_delay",12)) if wave==1 else maxf(20.0,float(north_gate.config.get("wave_interval",25))-wave*.12)
		if guard_timer <= 0:
			guard_timer = float(north_gate.config.get("soldier_interval",20))
			north_gate.reinforce()
	elif mode == "arena":
		var winner := ""
		var high := -1
		var team_scores := {0:0,1:0}
		for id in positions:
			var score := int(pvp_scores.get(id,0))
			team_scores[int(teams.get(id,0))]+=score
			if score>high:high=score;winner=str(id)
		if not arena_world.objective.active() and ((pvp_rule=="ffa" and high>=10) or (pvp_rule=="teams" and maxi(int(team_scores[0]),int(team_scores[1]))>=15) or run_time>=300):
			var name := "Draw"
			if pvp_rule=="teams":
				name="Silver Team" if int(team_scores[0])>int(team_scores[1]) else "Blue Team" if int(team_scores[1])>int(team_scores[0]) else "Draw"
			else:
				var ties:=0
				for id in positions:
					if int(pvp_scores.get(id,0))==high:ties+=1
				if ties==1:
					for player in roster:
						if str(player.get("id",""))==winner:name=str(player.get("name","Player"))
			end_match("Arena finished • "+name+" • "+str(int(run_time))+"s");return
		wave_timer -= delta
		if wave_timer <= 0 and opponents.size() < 6 and arena_map=="crossroads":
			wave+=1;_spawn_wave(mini(2,6-opponents.size()));wave_timer=18.0
	elif opponents.is_empty() and mode=="coop" and realm_id in ["moonveil","zombie"]:
		if wave==1:
			wave=3;var kind="mirror_marquis" if realm_id=="moonveil" else "plague_director";var at=Vector2(6710,2600) if realm_id=="moonveil" else Vector2(8200,725)
			adventure.spawn(kind,at,float(regions[realm_id].boss_health),true);opponents[-1].sprite=kind
			status_label.text="The final guardian has arrived at the eastern end of the realm."
		else:end_match("Realm cleared • "+str(regions[realm_id].name))
	elif opponents.is_empty() and mode=="coop" and adventure.hollow.active:
		if wave==1:
			wave=3;adventure.spawn("flintroot",Vector2(3400,6300),1250,true)
		else:end_match("Moonburrow Hollow restored!")
	elif opponents.is_empty() and mode=="coop" and adventure.city.active:
		if wave==1:
			wave=3;adventure.spawn("lockmaster_regent",Vector2(3500,2330),1450,true)
		else:end_match("Brasslock Borough freed!")
	elif (descent.combat_count()==0 if mode=="descent" else opponents.is_empty()) and not (get("expedition")!=null and get("expedition").between()) and not adventure.active and not adventure.vault.active and not adventure.quests.active and not adventure.expansion.active and not adventure.school.active and not adventure.tech.active and not adventure.immersive.active and not adventure.foundry.active and not adventure.cinder.active:
		if mode == "coop" and wave >= 3:
			end_match("Realm cleared • "+str(int(run_time))+" seconds")
			var key := "user://fx_coop_"+realm_id+".json"
			var prior := _json(key)
			coop_best = int(prior.get("best",0))
			var seconds := int(run_time)
			if (coop_best == 0 or seconds < coop_best) and not preload("res://scripts/profile_store.gd").progression_blocked():
				coop_best=seconds
				var save := FileAccess.open(key,FileAccess.WRITE)
				if save!=null: save.store_string(JSON.stringify({"best":coop_best}));save.close()
			status_label.text="Realm cleared in "+str(seconds)+"s! Best on this browser: "+str(coop_best)+"s."
			return
		if mode == "descent":
			if not adventure.combat.v90.rebirth.is_empty():return
			descent.begin_fall();return
		else: wave += 1
		if mode!="descent":
			for id in health:
				if not adventure.combat.v90.pending_rebirth(str(id)):health[id] = mini(_max_hp(str(id)),int(health[id])+40)
		_make_floor()
	for id in health:
		if int(health[id]) == 0 and not downed.has(id) and Time.get_ticks_msec() >= int(respawn_at.get(id,0)) and mode in ["arena","defense"]:
			health[id] = _max_hp(str(id));positions[id] = _spawn_player(_slot(str(id)))
			if id == my_id: local_pos = positions[id]
	for i in range(opponents.size()-1,-1,-1):
		var enemy: Dictionary = opponents[i]
		if bool(enemy.get("health_gem",false)) or bool(enemy.get("depth_boss",false)):continue
		if mode=="defense" and str(enemy.get("type","")) in north_gate.TYPES:continue
		if bool(enemy.get("roaming_actor",false)) or bool(enemy.get("immersive",false)) or str(enemy.get("type","")) in adventure.additions.TYPES or str(enemy.get("type","")) in adventure.newcomers.TYPES:continue
		if bool(enemy.get("veilbound",false)) or str(enemy.get("type","")) in adventure.cinder.TYPES or str(enemy.get("type","")) in adventure.foundry.TYPES or str(enemy.get("type","")) in adventure.clockfield.TYPES or str(enemy.get("type","")) in adventure.tech.TYPES or str(enemy.get("type","")) in adventure.school.TYPES or str(enemy.get("type","")) in adventure.expansion.TYPES or str(enemy.get("type","")) in adventure.hollow.TYPES or str(enemy.get("type","")) in adventure.city.TYPES or bool(enemy.get("expansion_boss",false)) or bool(enemy.get("vault_actor",false)): continue
		if adventure.combat.stunned(adventure.combat.npc_key(enemy)):continue
		var definition: Dictionary = enemy_defs.get(str(enemy["type"]),{}).duplicate()
		if mode=="defense":
			definition["damage"]=float(definition.get("damage",10))*float(enemy.get("damage_scale",1))
			definition["speed"]=maxf(115,float(definition.get("speed",65)))*north_gate.opening_speed(enemy,delta)
		definition["speed"]=float(definition.get("speed",65))*(float(descent.scaling(floor_number).speed) if mode=="descent" else 1.0)*adventure.combat.speed_factor(adventure.combat.npc_key(enemy))
		var target_id := ""
		var nearest := INF
		for id in positions:
			if int(health.get(id,0)) > 0 and Time.get_ticks_msec() >= int(stealth_until.get(id,0)) and positions[id].distance_to(enemy["pos"]) < nearest:
				target_id = str(id);nearest = positions[id].distance_to(enemy["pos"])
		var destination: Vector2 = positions[target_id] if target_id != "" else GATE
		var leaf:Dictionary=adventure.combat.fern.decoy_for(enemy.pos)
		if not enemy.boss and not leaf.is_empty() and adventure.combat.path_clear(enemy.pos,adventure.combat.vec(leaf.pos)):destination=adventure.combat.vec(leaf.pos)
		var guard_target := -1
		if mode == "defense":
			destination = north_gate.lane_goal(int(enemy.get("lane",0)),enemy.pos,false) if target_id == "" or nearest > 480 else destination
			for guard_index in guards.size():
				if str(guards[guard_index].get("type","")) != "summoned" and (enemy["pos"] as Vector2).distance_to(guards[guard_index]["pos"]) < (330 if adventure.combat.ranged_enemy(enemy,definition) else 95):
					guard_target = guard_index;destination = guards[guard_index]["pos"];break
		if preload("res://scripts/between_guardians.gd").basic(self,enemy,delta,true):continue
		var starter_boss:bool=mode=="coop" and preload("res://scripts/starter_boss.gd").managed(realm_id,enemy)
		if starter_boss:
			enemy.attack_timer=maxf(0,float(enemy.get("attack_timer",0))-delta)
			var swing:int=preload("res://scripts/starter_boss.gd").advance(enemy,destination,delta,target_id!="")
			if swing>0:
				if swing==2:
					for player_id in positions:
						if int(health.get(player_id,0))>0 and preload("res://scripts/starter_boss.gd").hits(enemy,positions[player_id]):_hurt(str(player_id),22.0 if realm_id=="quarry" else 25.0,"enemy",adventure.combat.npc_key(enemy))
				opponents[i]=enemy;continue
		var diff := destination - (enemy["pos"] as Vector2)
		var steering:Vector2=descent_direction(enemy,destination,delta) if mode == "descent" else diff.normalized()
		if target_id!="" and adventure.combat.ranged_enemy(enemy,definition) and (mode!="defense" or nearest<=480):
			steering=descent_ranged_direction(enemy,destination,delta) if mode=="descent" else adventure.combat.ranged_direction(enemy,destination)
		if adventure.quests.active:steering=adventure.quests.direction(enemy,destination,adventure.combat.ranged_enemy(enemy,definition)) if nearest<600 else Vector2.ZERO
		if mode=="defense" and guard_target>=0 and adventure.combat.ranged_enemy(enemy,definition):steering=adventure.combat.ranged_direction(enemy,destination)
		var movement := steering * float(definition.get("speed",65)) * delta
		if mode == "defense": movement = _guard_blocked_move(enemy["pos"],movement,-1,44.0)-(enemy["pos"] as Vector2)
		if bool(definition.get("flying",false)) or _clear_path(enemy["pos"],enemy["pos"]+movement): enemy["pos"] += movement
		else:
			var sidestep := Vector2(-movement.y,movement.x)
			if mode == "defense": sidestep = _guard_blocked_move(enemy["pos"],sidestep,-1,44.0)-(enemy["pos"] as Vector2)
			if _clear_path(enemy["pos"],enemy["pos"]+sidestep): enemy["pos"] += sidestep
		if mode=="defense" and north_gate.hold_at_outpost(enemy,delta):continue
		preload("res://scripts/ice_projectiles.gd").step_boss(self,enemy,delta)
		if not starter_boss:enemy["attack_timer"] = maxf(0.0,float(enemy.get("attack_timer",0.0))-delta)
		if mode == "defense" and (enemy["pos"] as Vector2).distance_to(GATE) < 85:
			gate_hp -= 8.0 if not bool(enemy["boss"]) else 65.0
			opponents.remove_at(i)
			if gate_hp <= 0: end_match("Gate lost on wave " + str(wave))
			continue
		if mode=="defense" and guard_target>=0 and adventure.combat.ranged_enemy(enemy,definition) and float(enemy["attack_timer"])<=0 and diff.length()<360:
			if preload("res://scripts/ice_projectiles.gd").matches(str(enemy.type)):preload("res://scripts/ice_projectiles.gd").fire(self,enemy,diff.normalized(),definition)
			else:north_gate.fire(enemy.pos,diff.normalized(),float(definition.get("damage",10)),"enemy",0,preload("res://scripts/defeat_credit.gd").resolve(self,adventure.combat.npc_key(enemy),"Projectile"))
			enemy.attack_timer=float(definition.get("shot_cooldown",2.2))
		elif float(enemy["attack_timer"]) <= 0 and guard_target >= 0 and diff.length() < 56:
			guards[guard_target]["hp"] = float(guards[guard_target]["hp"])-maxf(1.0,float(definition.get("damage",10))-float(upgrade_level["armor"])*2.0)
			if float(guards[guard_target]["hp"])<=0: guards.remove_at(guard_target)
			enemy["attack_timer"] = 1.2
		elif not starter_boss and float(enemy["attack_timer"]) <= 0 and target_id != "":
			var windup := float(enemy.get("warning",-1.0))
			if windup<0 and nearest<340:
				enemy["warning"]=.55
				# Descent windups use the attack pose; no orange engagement halo.
				if mode!="descent":_emit_effect({"pos":enemy["pos"],"radius":48.0,"time":.55,"color":"#ffba6c"})
				opponents[i]=enemy;continue
			if windup>0:
				enemy["warning"]=maxf(0.0,windup-delta);opponents[i]=enemy;continue
			enemy["warning"]=-1.0
			var style := str(definition.get("behaviour","chase"))
			if style in ["ranged","burst_ranged","dual_ranged","homing"] and nearest < 340:
				if preload("res://scripts/ice_projectiles.gd").matches(str(enemy["type"])):
					preload("res://scripts/ice_projectiles.gd").fire(self,enemy,diff.normalized(),definition)
				elif str(enemy["type"]) == "lantern_moth":
					adventure.combat.launch_projectile("enemy",enemy["pos"],diff.normalized(),{"range":700,"speed":float(definition.get("shot_speed",260)),"amplitude":32,"wavelength":170,"color":"#e6b7fa"},float(definition.get("damage",10)),"weaving")
				elif str(enemy["type"])=="archer":adventure.combat.launch_projectile("enemy",enemy["pos"],diff.normalized(),{"range":700,"speed":float(definition.get("shot_speed",275)),"thorn_arrow":true,"color":"#9ecb75"},float(definition.get("damage",9)))
				else: missiles.append({"credit":preload("res://scripts/defeat_credit.gd").resolve(self,adventure.combat.npc_key(enemy),"Projectile"),"pos":enemy["pos"],"direction":diff.normalized(),"speed":float(definition.get("shot_speed",260)),"damage":float(definition.get("damage",10)),"owner":"enemy","homing":style=="homing","distance":0.0})
				enemy["attack_timer"] = float(definition.get("shot_cooldown",2.2))
			elif nearest < 39 and not adventure.combat.ranged_enemy(enemy,definition):
				_hurt(target_id,float(definition.get("damage",10)),"enemy",adventure.combat.npc_key(enemy))
				enemy["attack_timer"] = 1.2
		opponents[i] = enemy
	for i in range(missiles.size()-1,-1,-1):
		var bullet: Dictionary = missiles[i]
		var origin: Vector2 = bullet["pos"]
		if bool(bullet.get("homing",false)):
			var target := local_pos
			if str(bullet["owner"]) == "enemy":
				var nearest_player := INF
				for player_id in positions:
					if int(health.get(player_id,0)) > 0 and origin.distance_to(positions[player_id]) < nearest_player:
						nearest_player = origin.distance_to(positions[player_id]);target = positions[player_id]
			elif opponents.size()>0: target = opponents[0]["pos"]
			bullet["direction"] = ((bullet["direction"] as Vector2)*0.93+(target-origin).normalized()*0.07).normalized()
		var next: Vector2 = origin+(bullet["direction"] as Vector2)*float(bullet["speed"])*delta/maxf(.3,dev_magic.world_scale())*dev_magic.scale_for(str(bullet["owner"]))
		bullet["distance"] = float(bullet["distance"])+origin.distance_to(next)
		if not _clear_path(origin,next) or float(bullet["distance"])>float(bullet.get("range",650)): missiles.remove_at(i);continue
		if adventure.combat.v59.catch_copy(origin,next,str(bullet["owner"]),float(bullet["damage"])):missiles.remove_at(i);continue
		if adventure.combat.v56.catch_shot(origin,next,str(bullet["owner"]),float(bullet["damage"]),str(bullet.get("color","#ed9b82")),true,bullet):missiles.remove_at(i);continue
		bullet["pos"] = next
		var hit := false
		if str(bullet["owner"]) == "enemy":
			if mode=="defense":
				for guard_index in range(guards.size()-1,-1,-1):
					var segment:=next-origin
					var t:=clampf(((guards[guard_index].pos as Vector2)-origin).dot(segment)/maxf(.001,segment.length_squared()),0,1)
					if (guards[guard_index].pos as Vector2).distance_to(origin+segment*t)<28:
						if float(bullet.get("explode",0))>0:north_gate.blast(next,float(bullet.explode),float(bullet.damage),str(bullet.get("npc_source","enemy")),0,bullet.get("credit",{}))
						else:north_gate.hurt_guard(guard_index,float(bullet.damage),str(bullet.get("npc_source","enemy")))
						hit=true;break
			for id in positions:
				if hit:break
				if int(health.get(id,0))>0 and _projectile_near_player(origin,next,str(id),7+adventure.combat.v110.target_radius("p:"+str(id),20)):
					if mode=="defense" and float(bullet.get("explode",0))>0:
						north_gate.blast(next,float(bullet.explode),float(bullet.damage),str(bullet.get("npc_source","enemy")),0,bullet.get("credit",{}));hit=true;break
					_hurt(str(id),float(bullet["damage"]),str(bullet.get("npc_source","enemy")),"",bullet.get("credit",{}))
					hit=true;break
		else:
			for j in range(opponents.size()-1,-1,-1):
				if next.distance_to(opponents[j]["pos"])<float(opponents[j].get("hit_radius",30)): _hit_enemy(j,float(bullet["damage"]),str(bullet["owner"]));hit=true;break
			if mode in ["arena","battlegrounds"] and not hit:
				for id in positions:
					if id != bullet["owner"] and _projectile_near_player(origin,next,str(id),7+adventure.combat.v110.target_radius("p:"+str(id),21)) and (pvp_rule=="ffa" or int(teams[id]) != int(teams[bullet["owner"]])):
						_hurt(str(id),float(bullet["damage"]),str(bullet["owner"]),"",bullet.get("credit",{}));hit=true;break
		if mode=="battlegrounds" and not hit:
			for key in battlegrounds.hostile_near(str(bullet.owner),(origin+next)*.5,origin.distance_to(next)*.5+27):
				var actor:Dictionary=battlegrounds.actor(key)
				if _segment_near(origin,next,actor.pos,27):battlegrounds.damage(key,float(bullet.damage),str(bullet.owner));hit=true;break
		if hit: missiles.remove_at(i)
		else: missiles[i] = bullet
	_simulate_guards(delta)

func _guard_formation(lane: int, slot: int, forward: float) -> Vector2:
	if mode=="defense":return north_gate.point_at(lane,forward+int(slot/3)*65,float(slot%3-1)*55)
	var direction: Vector2 = (APPROACHES[lane]-GATE).normalized()
	var sideways := Vector2(-direction.y,direction.x)
	return GATE + direction*(forward+float(slot/3)*65.0) + sideways*float(slot%3-1)*65.0

func _spawn_defense_guard(lane: int, kind: String, hp: float, damage: float) -> void:
	var slot := 0
	while true:
		var occupied := false
		for guard in guards:
			if int(guard.get("lane",-1)) == lane and int(guard.get("slot",-1)) == slot: occupied = true;break
		if not occupied: break
		slot += 1
	var point := _guard_formation(lane,slot,220.0)
	for attempt in 30:
		var clear := true
		for guard in guards:
			if point.distance_to(guard["pos"]) < 50: clear = false;break
		if clear and _clear_path(point,point): break
		point = _guard_formation(lane,slot+attempt+1,220.0)
	guards.append({"pos":point,"slot":slot,"lane":lane,"hp":hp,"damage":damage,"type":kind,"attack_timer":0.0})

# Substeps prevent fast enemies from walking through the guard line.
func _guard_blocked_move(origin: Vector2, displacement: Vector2, ignore: int, spacing: float) -> Vector2:
	var steps := maxi(1,int(ceil(displacement.length()/8.0)))
	var point := origin
	for step in steps:
		var candidate := point+displacement/float(steps)
		var blocked := false
		for j in guards.size():
			if j == ignore or str(guards[j].get("type","")) == "summoned": continue
			var other: Vector2 = guards[j]["pos"]
			if candidate.distance_to(other) < spacing and candidate.distance_to(other) <= point.distance_to(other): blocked = true;break
		if ignore >= 0:
			for enemy in opponents:
				var enemy_pos: Vector2 = enemy["pos"]
				if candidate.distance_to(enemy_pos) < 44.0 and candidate.distance_to(enemy_pos) <= point.distance_to(enemy_pos): blocked = true;break
		if blocked: break
		point = candidate
	return point

func _simulate_guards(delta: float) -> void:
	for i in range(guards.size()-1,-1,-1):
		var guard: Dictionary = guards[i]
		var guard_origin: Vector2 = guard["pos"]
		guard["attack_timer"] = maxf(0.0,float(guard["attack_timer"])-delta)
		var summoned := str(guard["type"]) == "summoned"
		if mode=="defense" and not summoned:
			guard["age"]=float(guard.get("age",0))+delta
			if float(guard.age)>100 or north_gate.distance_at(int(guard.lane),guard.pos)>north_gate.length_of(int(guard.lane))-90:guards.remove_at(i);continue
		if summoned:
			guard["time"] = float(guard.get("time",12))-delta
			if float(guard["time"]) <= 0 or float(guard.get("hp",0))<=0:
				adventure.combat.statuses.erase("p:summon:"+str(guard.get("net_uid",0)));guards.remove_at(i);continue
			if adventure.combat.stunned("p:summon:"+str(guard.get("net_uid",0))):continue
		var target := -1
		var nearest := 650.0 if summoned else 400.0
		var reach := 220.0 if str(guard["type"]) in ["ranged","area"] else 56.0
		for j in opponents.size():
			if not summoned and int(opponents[j].get("lane",0)) != int(guard.get("lane",0)): continue
			var distance: float = (guard["pos"] as Vector2).distance_to(opponents[j]["pos"])
			if distance < nearest: nearest = distance;target = j
		var destination: Vector2 = positions.get(str(guard.get("owner","")),guard["pos"]) if summoned else _guard_formation(int(guard.get("lane",0)),int(guard.get("slot",0)),1600.0)
		if mode=="defense" and not summoned:destination=north_gate.lane_goal(int(guard.lane),guard.pos,true)
		if target >= 0: destination = opponents[target]["pos"]
		var rival_id := ""
		if summoned and mode in ["arena","battlegrounds"]:
			for other in positions:
				if _rival(str(guard.get("owner","")),str(other)):
					var distance: float = (guard["pos"] as Vector2).distance_to(positions[other])
					if distance < nearest: nearest = distance;rival_id = str(other);target = -1;destination = positions[other]
		if summoned and mode=="battlegrounds":
			var army_target:=""
			for key in battlegrounds.hostile(str(guard.owner)):
				var a:Dictionary=battlegrounds.actor(key);var d:float=(guard.pos as Vector2).distance_to(a.pos)
				if d<nearest:nearest=d;destination=a.pos;army_target=key;rival_id=""
			if not army_target.is_empty() and nearest<reach and float(guard.attack_timer)<=0:battlegrounds.damage(army_target,float(guard.damage),str(guard.owner));guard.attack_timer=1.0
		if not rival_id.is_empty() and nearest < reach and float(guard["attack_timer"]) <= 0:
			_hurt(rival_id,float(guard["damage"]),str(guard.get("owner","lane_guard" if mode=="defense" and not summoned else "")));guard["attack_timer"] = 1.0
		if target >= 0 and nearest < reach and float(guard["attack_timer"]) <= 0:
			if str(guard["type"]) == "area":
				var center: Vector2 = opponents[target]["pos"]
				_emit_effect({"pos":center,"radius":100.0,"time":0.3,"color":"#c4b0ff"})
				for j in range(opponents.size()-1,-1,-1):
					if center.distance_to(opponents[j]["pos"]) < 100: _hit_enemy(j,float(guard["damage"]),str(guard.get("owner","lane_guard" if mode=="defense" and not summoned else "")))
			else:
				if str(guard["type"]) == "ranged": _emit_effect({"pos":guard["pos"],"end":opponents[target]["pos"],"style":"line","time":0.18,"color":"#e5d6ab"})
				_hit_enemy(target,float(guard["damage"]),str(guard.get("owner","lane_guard" if mode=="defense" and not summoned else "")))
			guard["attack_timer"] = 1.6 if str(guard["type"]) == "area" else 1.0
		elif (guard["pos"] as Vector2).distance_to(destination) > (reach*0.8 if target >= 0 else 70.0):
			guard["pos"] = _move_actor(guard["pos"],(destination-(guard["pos"] as Vector2)).normalized()*float(guard.get("speed",110))*delta)
		if mode == "defense" and not summoned:
			guard["pos"] = _guard_blocked_move(guard_origin,(guard["pos"] as Vector2)-guard_origin,i,50.0)
		guards[i] = guard

func _snapshot() -> Dictionary:
	_track_card_progress()
	var players := {}
	for id in positions:
		var p: Vector2 = positions[id]
		var timers: Dictionary = cooldown_at.get(id,{})
		var remaining := {}
		for ability in ["primary","secondary","special"]:
			remaining[ability] = maxf(0.0,float(int(timers.get(ability,0))-Time.get_ticks_msec())/1000.0)
		players[id] = {"pos":[roundi(p.x),roundi(p.y)],"position_ack":int(position_acks.get(id,0)),"hp":int(health.get(id,0)),"xp":int(xp.get(id,0)),"gold":int(gold.get(id,0)),"level":int(levels.get(id,1)),"kills":int(kills.get(id,0)),"team":int(teams.get(id,0)),"hero":str(hero_ids.get(id,"ram")),"build":legacy.build(str(id)),"cosmetic":cosmetic_for(id),"defeat":defeat_causes.get(id,{}),"food_ready":bool(food_registered.get(id,false)),"food":food_slots.get(id,""),"items":inventory.get(id,[]),"consumable_entry":str(accepted_supplies.get(id,"")),"branch":str(attack_branch.get(id,"")),"mastery":str(mastery_choice.get(id,"")),"shield":maxi(0,int(shield_until.get(id,0))-Time.get_ticks_msec()),"haste_scale":float(item_haste_scale.get(id,1.35)),"haste":maxi(0,int(haste_until.get(id,0))-Time.get_ticks_msec()),"cooldowns":remaining,"stealth":maxi(0,int(stealth_until.get(id,0))-Time.get_ticks_msec()),"core_action":core_art.packet(str(id)),"pose":maxi(0,int(attack_pose_until.get(id,0))-Time.get_ticks_msec()),"stance_moving":adventure.combat.stance_heroes.moving(str(id)) or adventure.combat.v90.moving(str(id)) or adventure.combat.v98.moving(str(id)),"shield_reduction":float(shield_reduction.get(id,.75)),"invincible":maxi(0,int(invincible_until.get(id,0))-Time.get_ticks_msec()),"charging":charges.has(id) or adventure.combat.chain.moving(str(id)) or adventure.combat.classics.moving(str(id)) or adventure.combat.v48.moving(str(id)) or adventure.immersive.aboard(str(id))}
	var foes: Array = []
	for enemy in opponents: foes.append({"pos":[roundi(enemy["pos"].x),roundi(enemy["pos"].y)],"hp":enemy["hp"],"max_hp":enemy["max_hp"],"type":enemy["type"],"sprite":str(enemy.get("sprite",enemy["type"])),"boss":enemy["boss"],"lane":int(enemy.get("lane",0)),"health_gem":bool(enemy.get("health_gem",false)),"depth_boss":bool(enemy.get("depth_boss",false)),"action":str(enemy.get("action","")),"hurt":float(enemy.get("hurt",0)),"strike":float(enemy.get("strike",0)),"total":float(enemy.get("total",0)),"left":float(enemy.get("left",0)),"facing":float(enemy.get("facing",0)),"moving":float(enemy.get("moving",0)),"gait":float(enemy.get("gait",0)),"warning":float(enemy.get("warning",-1)),"melee_warning":float(enemy.get("melee_warning",0)),"melee_x":float(enemy.get("melee_x",0)),"melee_y":float(enemy.get("melee_y",1)),"v143_pose":float(enemy.get("v143_pose",0)),"veilbound":bool(enemy.get("veilbound",false)),"veil_pose":float(enemy.get("veil_pose",0)),"cinder_pose":float(enemy.get("cinder_pose",0)),"expansion_boss":bool(enemy.get("expansion_boss",false)),"trial_index":int(enemy.get("trial_index",-1)),"generation":int(enemy.get("generation",0)),"uid":int(enemy.get("uid",0)),"down_time":float(enemy.get("down_time",0)),"growth":float(enemy.get("growth",0)),"school_group":str(enemy.get("school_group","")),"ghost":float(enemy.get("ghost",0)),"hit_radius":float(enemy.get("hit_radius",18)),"quest_group":str(enemy.get("quest_group","")),"buried":bool(enemy.get("buried",false)),"immersive":bool(enemy.get("immersive",false)),"campaign_hero":bool(enemy.get("campaign_hero",false)),"between_guardian":bool(enemy.get("between_guardian",false)),"source_realm":str(enemy.get("source_realm","")),"name":str(enemy.get("name",enemy_defs.get(str(enemy.type),{}).get("name",""))),"windup":float(enemy.get("windup",0))})
	var shots: Array = []
	for bullet in missiles: shots.append({"pos":[roundi(bullet["pos"].x),roundi(bullet["pos"].y)],"owner":bullet["owner"],"color":str(bullet.get("color","#ffd985"))})
	var sent_guards: Array = []
	for guard in guards:
		if not guard.has("net_uid"):guard.net_uid=transport.next()
		sent_guards.append({"net_uid":guard.net_uid,"pos":[roundi(guard["pos"].x),roundi(guard["pos"].y)],"type":guard["type"],"sprite":str(guard.get("sprite","")),"owner":str(guard.get("owner","")),"hp":float(guard.get("hp",0)),"max_hp":float(guard.get("max_hp",70))})
	return {"type":"state","unofficial":bool(get_meta("records_unofficial",false)),"studio":custom_party.snapshot(),"dev_magic":dev_magic.snapshot(),"descent":descent.snapshot(),"battlegrounds":battlegrounds.snapshot() if mode=="battlegrounds" else {},"match_id":match_id,"party_size":match_party_size,"arena_random":arena_random,"seats":arena_seats,"spectator":spectator_host,"bots":bot_count,"ai_difficulty":ai_difficulty,"arena_no_items":arena_no_items,"arena_records":arena_records,"arena_outcomes":arena_outcomes,"defense_cleared_wave":defense_cleared_wave,"arena_world":arena_world.snapshot(),"north_gate":north_gate.snapshot() if mode=="defense" else {},"pvp_scores":pvp_scores,"contributions":contributions,"downed":downed,"results":results_reason,"notice":status_label.text,"adventure":adventure.snapshot(),"players":players,"enemies":foes,"shots":shots,"guards":sent_guards,"effects":sent_effects,"walls":_wall_packet(),"wave":wave,"floor":floor_number,"gate":gate_hp,"upgrades":upgrade_level,"active":started,"timer":run_time}

func _packet(remote_id: String, data: Dictionary) -> void:
	if role=="guest" and remote_id==host_id and data.get("unofficial",false)==true:set_meta("records_unofficial",true)
	if custom_party.packet(remote_id,data):return
	if music_network.packet(remote_id,data):return
	if str(data.get("type",""))=="dev_test":
		if role=="guest" and remote_id==host_id:dev_magic.isolate()
		return
	if str(data.get("type",""))=="dev_power":
		if role=="host":dev_magic.execute(remote_id,data)
		return
	if str(data.get("type",""))=="dev_hero":
		if role=="guest" and remote_id==host_id and characters.has(str(data.get("hero",""))):selected_hero=str(data.hero);hero_ids[my_id]=selected_hero
		return
	if not transport.accept(remote_id,data):return
	if transport.receive(remote_id,data):
		if recovery!=null:recovery.incoming(remote_id)
		return
	if str(data.get("type",""))=="removed_from_room" and role=="guest" and remote_id==host_id:
		_reset_connection();started=false;status_label.text="The host removed you from the room.";return
	if recovery!=null and recovery.packet(remote_id,data):return
	if (start_countdown>0 or descent.falling()) and str(data.get("type","")) in ["attack","pos","dodge","rift","consume"]:return
	if recovery!=null and recovery.frozen and role=="host" and str(data.get("type","")) in ["pos","attack","rift","dodge","choice","consume","purchase","upgrade"]:return
	match str(data.get("type","")):
		"held_cast":
			if role=="host" and started and start_countdown<=0 and not recovery.frozen:adventure.combat.held_cast.packet(remote_id,data)
		"lobby_notice":
			if role=="guest" and remote_id==host_id and not started:status_label.text=str(data.get("message","")).left(160)
		"lobby_cosmetic":
			if role=="host" and not started and roster.any(func(member):return str(member.get("id",""))==remote_id) and data.get("cosmetic") is Dictionary and JSON.stringify(data.cosmetic).length()<4000:player_cosmetics[remote_id]=data.cosmetic
		"lobby":
			if role=="guest" and remote_id==host_id and not started:_receive_lobby(data)
		"arena_rules":
			if role=="guest" and remote_id==host_id and not started:
				allow_custom=bool(data.get("allow_custom",false));custom_picker.set_pressed_no_signal(allow_custom)
				arena_seats=clampi(int(data.get("seats",4)),2,8);spectator_host=bool(data.get("spectator",false));ai_difficulty=bots.difficulty(data.get("ai_difficulty","medium"));bot_count=clampi(int(data.get("bots",0)),0,mini(7,arena_seats-1));arena_opening=bool(data.get("opening",false));arena_map=str(data.get("arena_map","sand"));_sync_arena_pickers();arena_no_items=bool(data.get("no_items",false));arena_random=bool(data.get("random_heroes",false));no_items_picker.set_pressed_no_signal(arena_no_items);random_hero_picker.set_pressed_no_signal(arena_random)
		"bg_notice":
			if role=="guest" and remote_id==host_id:status_label.text=str(data.get("message",""))
		"bg_upgrade":
			if role=="host" and mode=="battlegrounds":
				var purchased:bool=battlegrounds.buy(remote_id,str(data.get("key","")))
				_send_channel(remote_id,{"type":"bg_notice","message":"Army upgraded!" if purchased else "Need more CC, upgrade capped, or move closer to your own barracks."})
		"rift":
			if role == "host" and started:
				if mode=="descent":descent.interact(remote_id)
				else:adventure.interact(remote_id)
		"kite_release":
			if role=="guest" and remote_id==host_id and data.get("velocity",[]) is Array and data.velocity.size()==2:
				var launch:=Vector2(float(data.velocity[0]),float(data.velocity[1]))
				if is_finite(launch.x) and is_finite(launch.y):
					adventure.combat.v79.velocities[my_id]=launch.limit_length(480)
					for index in range(adventure.combat.v79.effects.size()-1,-1,-1):
						var effect:Dictionary=adventure.combat.v79.effects[index]
						if str(effect.owner)==my_id and str(effect.style)=="windlass_swing":adventure.combat.v79.effects.remove_at(index)
		"teleport":
			if role == "guest" and remote_id == host_id:
				local_pos = Vector2(float(data["point"][0]),float(data["point"][1]));positions[my_id] = local_pos
		"hero":
			if role=="host" and started and not party_tools.late_pending.has(remote_id):return
			var late:bool=role=="host" and started and party_tools.late_pending.has(remote_id)
			if late:_add_player(remote_id,roster.size()-1)
			if role=="host":
				random_builds[remote_id]=data.get("random_builds",{}) if data.get("random_builds",{}) is Dictionary else {}
				lobby_heroes[remote_id]=str(data.get("hero","ram")) if characters.has(str(data.get("hero",""))) else "ram";lobby_builds[remote_id]=legacy.sanitize_build(data.get("build",{}));_send_arena_rules()
			if role=="host" and not legacy.builds.has(remote_id):legacy.builds[remote_id]=legacy.sanitize_build(data.get("build",{}))
			if role=="host" and positions.has(remote_id) and not food_registered.has(remote_id):
				var offered=str(data.get("consumable",""))
				if not started and items.has(offered) and preload("res://scripts/supply_slots.gd").consumable(items[offered]):supply_loadouts[remote_id]=offered
				shop_discounts[remote_id]=data.get("shop_discount",false)==true
				var piece:String=str(data.get("food",""));food_registered[remote_id]=true
				food_loadouts[remote_id]=piece if provisions.defs.has(piece) else ""
				food_slots[remote_id]="" if mode=="arena" and arena_no_items else food_loadouts[remote_id]
			if role == "host": player_cosmetics[remote_id]=data.get("cosmetic",{})
			if role == "host" and characters.has(str(data.get("hero",""))):
				hero_ids[remote_id] = str(data["hero"]);health[remote_id] = _max_hp(remote_id)
			if late:
				party_tools.late_pending.erase(remote_id);match_party_size=positions.size();levels[remote_id]=1;xp[remote_id]=0;invincible_until[remote_id]=Time.get_ticks_msec()+3000
				var config:=match_config();config.type="late_start";_send_channel(remote_id,config);_send_channel(remote_id,_snapshot())
		"dodge":
			if arena_world.shatter.active():arena_world.shatter.action(remote_id,"secondary",Vector2.from_angle(float(aim_angles.get(remote_id,0))));return
			if role == "host" and started and int(health.get(remote_id,0)) > 0 and not adventure.combat.stunned(adventure.combat.player_key(remote_id)) and not adventure.combat.robot.transformed(remote_id) and not adventure.immersive.aboard(remote_id) and not adventure.combat.v48.moving(remote_id) and not adventure.combat.classics.locked(remote_id) and not adventure.combat.v78.locked(remote_id) and not adventure.combat.v79.moving(remote_id) and not adventure.combat.v110.charging(remote_id) and not adventure.combat.halloween.moving(remote_id) and Time.get_ticks_msec() >= int(dodge_at.get(remote_id,0)):
				dodge_at[remote_id] = Time.get_ticks_msec()+2500;invincible_until[remote_id] = Time.get_ticks_msec()+220
		"late_start":
			if role=="guest" and remote_id==host_id and not started:_packet(remote_id,dict_with_start(data));recovery.resync_local=true
		"resume_start":
			if role=="guest" and remote_id==host_id and not started and match_id!=str(data.get("match_id","")):_packet(remote_id,dict_with_start(data))
		"start":
			if role=="guest" and remote_id==host_id:teams=data.get("teams",teams)
			if role == "guest" and remote_id == host_id:
				bg_map=str(data.get("bg_map","woodland"));bg_team_size=clampi(int(data.get("bg_team_size",4)),3,4);_sync_bg_pickers()
				mode = str(data.get("mode","defense"));realm_id = str(data.get("realm","grove"));pvp_rule = str(data.get("rule","ffa"));floor_seed = int(data.get("seed",1))
				arena_seats=clampi(int(data.get("seats",4)),2,8);spectator_host=bool(data.get("spectator",false));ai_difficulty=bots.difficulty(data.get("ai_difficulty","medium"));bot_count=clampi(int(data.get("bots",0)),0,mini(7,arena_seats-1));arena_opening=bool(data.get("opening",false));arena_map=str(data.get("arena_map","sand"));_sync_arena_pickers();arena_no_items=bool(data.get("no_items",false));arena_random=bool(data.get("random_heroes",false));no_items_picker.set_pressed_no_signal(arena_no_items);random_hero_picker.set_pressed_no_signal(arena_random)
				match_id=str(data.get("match_id",""));match_party_size=int(data.get("party_size",1))
				var assignments:Dictionary=data.get("heroes",{})
				for id in assignments:
					if characters.has(str(assignments[id])):hero_ids[id]=str(assignments[id])
				selected_hero=str(hero_ids.get(my_id,preferred_hero))
				_set_mode(mode);_start_match();start_countdown=clampf(float(data.get("countdown",0)),0,5);status_label.text = "Connected. Match started!"
		"revive_reward":
			if role == "guest" and remote_id == host_id: journey.revived()
		"pos":
			if role == "host":
				position_acks[remote_id]=int(data.get("seq",0))
				revive_held[remote_id] = bool(data.get("revive",false))
				adventure.combat.release_heroes.holding(remote_id,bool(data.get("secondary_held",false)),Vector2.from_angle(float(data.get("primary_angle",0))))
				adventure.combat.classics.holding(remote_id,bool(data.get("secondary_held",false)))
				if is_finite(float(data.get("primary_angle",0))):adventure.combat.v79.holding(remote_id,bool(data.get("secondary_held",false)),Vector2.from_angle(float(data.get("primary_angle",0))))
				if is_finite(float(data.get("primary_angle",0))):adventure.combat.v56.holding(remote_id,bool(data.get("primary_held",false)),Vector2.from_angle(float(data.get("primary_angle",0))))
			if role == "host" and started and positions.has(remote_id) and int(health.get(remote_id,0))>0:
				var requested := Vector2(float(data.get("x",0)),float(data.get("y",0))).clamp(FIELD.position+Vector2(25,25),FIELD.end-Vector2(25,25))
				if not adventure.combat.stunned(adventure.combat.player_key(remote_id)) and not adventure.combat.twister.chanting(remote_id) and not charges.has(remote_id) and not adventure.combat.stance_heroes.moving(remote_id) and not adventure.combat.v90.moving(remote_id) and not adventure.combat.v98.moving(remote_id) and not adventure.combat.chain.moving(remote_id) and not adventure.combat.classics.locked(remote_id) and not adventure.combat.v78.locked(remote_id) and not adventure.combat.v79.moving(remote_id) and not adventure.combat.v110.charging(remote_id) and not adventure.combat.halloween.moving(remote_id) and not adventure.combat.release_heroes.locked(remote_id) and not adventure.immersive.aboard(remote_id) and not adventure.combat.v48.moving(remote_id) and positions[remote_id].distance_to(requested)<180 and _clear_path(positions[remote_id],requested): positions[remote_id] = requested
				smoothing.push("p:"+remote_id,positions[remote_id],Time.get_ticks_msec()/1000.0)
				# The host owns the match assignment; movement packets cannot change heroes. 
		"attack":
			if role == "host" and started and is_finite(float(data.get("angle",0))):
				var kind:=str(data.get("style","primary"))
				if kind not in ["primary","secondary","special"]:return
				var previous:=int(cooldown_at.get(remote_id,{}).get(kind,0))
				var rounds_before:=int(adventure.combat.v90.cylinders.get(remote_id,{"rounds":6}).rounds)
				_attack(remote_id,kind,Vector2.from_angle(float(data.get("angle",0))),Vector2(float(data.get("target",[0,0])[0]),float(data.get("target",[0,0])[1])))
				var deadline:=int(cooldown_at.get(remote_id,{}).get(kind,0))
				_send_channel(remote_id,{"type":"attack_ack","match_id":match_id,"style":kind,"accepted":deadline>previous or int(adventure.combat.v90.cylinders.get(remote_id,{"rounds":6}).rounds)<rounds_before,"remaining":maxi(0,deadline-Time.get_ticks_msec())})
		"attack_ack":
			if role=="guest" and remote_id==host_id and str(data.get("match_id",""))==match_id:
				var kind:=str(data.get("style",""))
				if kind in ["primary","secondary","special"]:
					# Retry near the authoritative cooldown, including early rejected requests.
					request_ready[kind]=0 if str(characters.get(selected_hero,{}).get(kind,{}).get("style",""))=="v91_pistol" else Time.get_ticks_msec()+maxi(80,int(data.get("remaining",0))-int(transport.ping_ms))
		"crown_throw":
			if role=="host":arena_world.objective.throw_crown(remote_id,Vector2.from_angle(float(data.get("angle",0))))
		"state":
			if role != "guest" or remote_id != host_id: return
			if not match_id.is_empty() and not str(data.get("match_id",match_id)).is_empty() and str(data.get("match_id",match_id))!=match_id:return
			var receive_began:=Time.get_ticks_usec()
			dev_magic.receive(data.get("dev_magic",{}))
			descent.receive(data.get("descent",{}))
			pvp_scores=data.get("pvp_scores",{});contributions=data.get("contributions",{});downed=data.get("downed",{});results_reason=str(data.get("results",""));status_label.text=str(data.get("notice",status_label.text))
			arena_world.receive(data.get("arena_world",{}))
			match_id=str(data.get("match_id",match_id));match_party_size=int(data.get("party_size",match_party_size));ai_difficulty=bots.difficulty(data.get("ai_difficulty",ai_difficulty));bot_count=clampi(int(data.get("bots",bot_count)),0,7);arena_random=bool(data.get("arena_random",arena_random));arena_no_items=bool(data.get("arena_no_items",arena_no_items));arena_records=data.get("arena_records",{});arena_outcomes=data.get("arena_outcomes",{});defense_cleared_wave=int(data.get("defense_cleared_wave",0))
			_profile_section("snapshot_aux",receive_began);receive_began=Time.get_ticks_usec()
			adventure.receive(data.get("adventure",{}))
			_profile_section("snapshot_adventure",receive_began);receive_began=Time.get_ticks_usec()
			custom_party.receive(data.get("studio",{}))
			if mode=="battlegrounds":battlegrounds.receive(data.get("battlegrounds",{}))
			if mode=="defense":north_gate.receive(data.get("north_gate",{}))
			_profile_section("snapshot_custom",receive_began);receive_began=Time.get_ticks_usec()
			var players: Dictionary = data.get("players",{})
			for id in players:
				var info: Dictionary = players[id]
				if id==my_id:
					preload("res://scripts/prepared_supply.gd").commit(str(info.get("consumable_entry","")))
				if info.has("cosmetic"):player_cosmetics[id]=info.cosmetic
				if info.has("defeat") and info.defeat is Dictionary:defeat_causes[id]=info.defeat
				if info.has("food") and bool(info.get("food_ready",true)):
					food_slots[id]=str(info.food)
					if id==my_id and not (mode=="arena" and arena_no_items):provisions.sync_local(str(info.food))
				var point := Vector2(float(info["pos"][0]),float(info["pos"][1]))
				var stamp:=Time.get_ticks_msec()/1000.0
				if id!=my_id and stamp-float(motion_received.get(id,-10))>.15:smoothing.push("p:"+str(id),point,stamp,int(health.get(id,0))<=0 and int(info.get("hp",0))>0)
				if id==my_id and not bool(info.get("charging",false)) and not bool(info.get("stance_moving",false)):_reconcile_position(int(info.get("position_ack",0)),point)
				if id != my_id or int(info.get("hp",0)) <= 0: positions[id] = point
				if id==my_id and bool(info.get("stance_moving",false)):local_pos=point;positions[id]=point
				if id==my_id and recovery.resync_local:local_pos=point;positions[id]=point;recovery.resync_local=false
				if id == my_id and int(health.get(id,0)) == 0 and int(info.get("hp",0))>0: local_pos=point
				core_art.receive(str(id),info.get("core_action",{}))
				stealth_until[id] = Time.get_ticks_msec()+int(info.get("stealth",0));attack_pose_until[id] = Time.get_ticks_msec()+int(info.get("pose",0))
				if bool(info.get("charging",false)):
					charges[id] = {}
					if id == my_id: network_charge_target = point
				else:
					if id == my_id and charges.has(id): local_pos = point
					charges.erase(id)
				if str(id)!=my_id and info.has("build"):legacy.builds[str(id)]=legacy.sanitize_build(info.build)
				health[id]=int(info.get("hp",100));xp[id]=int(info.get("xp",0));gold[id]=int(info.get("gold",0));levels[id]=int(info.get("level",1));kills[id]=int(info.get("kills",0));teams[id]=int(info.get("team",0));hero_ids[id]=str(info.get("hero","ram"));inventory[id]=info.get("items",[]);attack_branch[id]=str(info.get("branch",""));mastery_choice[id]=str(info.get("mastery",""));shield_until[id]=Time.get_ticks_msec()+int(info.get("shield",0));shield_reduction[id]=float(info.get("shield_reduction",.75));invincible_until[id]=Time.get_ticks_msec()+int(info.get("invincible",0));haste_until[id]=Time.get_ticks_msec()+int(info.get("haste",0));item_haste_scale[id]=float(info.get("haste_scale",1.35));cooldown_remaining[id]=info.get("cooldowns",{})
			if hero_ids.has(my_id):selected_hero=str(hero_ids[my_id])
			_profile_section("snapshot_players",receive_began);receive_began=Time.get_ticks_usec()
			opponents.clear()
			for foe in data.get("enemies",[]):
				foes_from_packet(foe)
			missiles.clear()
			for bullet in data.get("shots",[]): missiles.append({"pos":Vector2(float(bullet["pos"][0]),float(bullet["pos"][1])),"owner":str(bullet["owner"]),"color":str(bullet.get("color","#ffd985"))})
			guards.clear()
			for guard in data.get("guards",[]):
				guards.append({"pos":Vector2(float(guard["pos"][0]),float(guard["pos"][1])),"type":str(guard["type"]),"sprite":str(guard.get("sprite","")),"net_uid":int(guard.get("net_uid",0)),"owner":str(guard.get("owner","")),"hp":float(guard.get("hp",0)),"max_hp":float(guard.get("max_hp",70))})
				var key:="g:"+str(guard.get("net_uid",0));smoothing.push(key,guards[-1].pos,Time.get_ticks_msec()/1000.0)
			var active_tracks:Dictionary={}
			for player in players:active_tracks["p:"+str(player)]=true
			for foe in opponents:active_tracks["e:"+str(foe.get("uid",0))]=true
			for guard in guards:active_tracks["g:"+str(guard.get("net_uid",0))]=true
			smoothing.prune(active_tracks)
			for event in data.get("effects",[]): _receive_effect(event)
			ice_walls.clear()
			for wall in data.get("walls",[]): ice_walls.append({"pos":Vector2(float(wall[0]),float(wall[1])),"time":float(wall[2])})
			if mode=="descent" and int(data.get("floor",1))!=floor_number:
				descent.cleared(mini(100,maxi(0,int(data.get("floor",1))-1)))
			wave=int(data.get("wave",0));floor_number=int(data.get("floor",1));run_time=float(data.get("timer",0));gate_hp=float(data.get("gate",550));upgrade_level=data.get("upgrades",upgrade_level)
			_profile_section("snapshot_entities",receive_began);receive_began=Time.get_ticks_usec()
			_track_card_progress()
			if not results_reason.is_empty():legacy_results();presentation.results(adventure_won(results_reason) or mode=="arena" and str(arena_outcomes.get(my_id,"draw"))=="win")
			var was_active := started
			started=bool(data.get("active",true))
			if was_active and not started:
				shop_open="";status_label.text=results_reason
				if mode=="coop" and adventure_won(results_reason): journey.won(realm_id);provisions.complete_adventure()
			_profile_section("snapshot_finalize",receive_began)
		"choice":
			if role=="host": _apply_choice(remote_id,str(data.get("value","")))
		"team":
			if role=="host" and not started and (mode=="battlegrounds" or mode=="arena" and rule_picker.selected==1): _assign_team(remote_id,int(data.get("team",0)))
		"purchase":
			if role=="host": _purchase(remote_id,str(data.get("id","")))
		"consume":
			if role=="host": _consume(remote_id,int(data.get("slot",-1)))
		"upgrade":
			if role=="host": _purchase_guard(remote_id,str(data.get("id","")))
		"gift":
			if role=="host": _transfer(remote_id,str(data.get("to","")),20)

func dict_with_start(data:Dictionary)->Dictionary:
	var packet:Dictionary=data.duplicate(true);packet.type="start";return packet

func foes_from_packet(value: Dictionary) -> void:
	var point:=Vector2(float(value["pos"][0]),float(value["pos"][1]));smoothing.push("e:"+str(value.get("uid",0)),point,Time.get_ticks_msec()/1000.0)
	opponents.append({"pos":Vector2(float(value["pos"][0]),float(value["pos"][1])),"hp":float(value["hp"]),"max_hp":float(value["max_hp"]),"type":str(value["type"]),"boss":bool(value["boss"]),"lane":int(value.get("lane",1)),"warning":float(value.get("warning",-1)),"veilbound":bool(value.get("veilbound",false)),"veil_pose":float(value.get("veil_pose",0)),"cinder_pose":float(value.get("cinder_pose",0)),"v143_pose":float(value.get("v143_pose",0)), "melee_warning":float(value.get("melee_warning",0)),"melee_x":float(value.get("melee_x",0)),"melee_y":float(value.get("melee_y",1)),"expansion_boss":bool(value.get("expansion_boss",false)),"trial_index":int(value.get("trial_index",-1)),"generation":int(value.get("generation",0)),"uid":int(value.get("uid",0)),"down_time":float(value.get("down_time",0)),"growth":float(value.get("growth",0)),"school_group":str(value.get("school_group","")),"ghost":float(value.get("ghost",0)),"hit_radius":float(value.get("hit_radius",18)),"quest_group":str(value.get("quest_group","")),"immersive":bool(value.get("immersive",false)),"buried":bool(value.get("buried",false)),"campaign_hero":bool(value.get("campaign_hero",false)),"health_gem":bool(value.get("health_gem",false)),"depth_boss":bool(value.get("depth_boss",false)),"action":str(value.get("action","")),"hurt":float(value.get("hurt",0)),"strike":float(value.get("strike",0)),"total":float(value.get("total",0)),"left":float(value.get("left",0)),"facing":float(value.get("facing",0)),"moving":float(value.get("moving",0)),"gait":float(value.get("gait",0)),"between_guardian":bool(value.get("between_guardian",false)),"source_realm":str(value.get("source_realm","")),"name":str(value.get("name",enemy_defs.get(str(value.type),{}).get("name",""))),"sprite":str(value.get("sprite",value.type)),"windup":float(value.get("windup",0))})

func _consume(id: String, slot: int) -> void:
	if arena_world.shatter.active():return
	if mode=="arena" and arena_no_items:return
	if int(health.get(id,0))<=0:return
	if not inventory.has(id) or slot<0 or slot >= (inventory[id] as Array).size(): return
	var item_id := str(inventory[id][slot])
	var item: Dictionary = items.get(item_id,{})
	var effect := str(item.get("effect",""))
	if effect not in ["heal","shockwave","invulnerable","haste","cleanse","lodge_guard"]: return
	if effect=="heal" and int(health.get(id,0))>=_max_hp(id):return
	if effect == "shockwave":
		for i in range(opponents.size()-1,-1,-1):
			if positions[id].distance_to(opponents[i]["pos"])<float(item.get("radius",150)):_hit_enemy(i,float(item.get("amount",40)),id)
	elif effect=="cleanse": adventure.combat.v90.cleanse(adventure.combat.player_key(id),["poison","burn","bleed"])
	elif effect=="lodge_guard": adventure.combat.apply_status(adventure.combat.player_key(id),"guard",float(item.get("duration",4)),id,float(item.get("amount",15))/100.0)
	elif effect=="heal": _heal(id,id,int(item.get("amount",35)),false)
	elif effect=="invulnerable": invincible_until[id]=Time.get_ticks_msec()+int(1000.0*float(item.get("amount",3)))
	elif effect=="haste": item_haste_scale[id]=1+float(item.get("amount",35))/100.0;haste_until[id]=Time.get_ticks_msec()+int(1000.0*float(item.get("duration",3)))
	(inventory[id] as Array).remove_at(slot)

func _apply_choice(id: String, selection: String) -> void:
	if selection.begins_with("depth_"):descent.choose(id,selection);return
	if not levels.has(id): return
	if int(levels[id]) >= 8 and str(attack_branch.get(id,"")) == "" and selection in ["primary","secondary"]: attack_branch[id]=selection
	elif int(levels[id]) >= 10 and str(mastery_choice.get(id,"")) == "" and selection in ["special","passive"]: mastery_choice[id]=selection

func _choose_team(team: int) -> void:
	if team not in [-1,0,1] or started or spectating() or mode!="battlegrounds" and (mode!="arena" or rule_picker.selected!=1):return
	chosen_team=team
	if role.is_empty():
		status_label.text="Choose a side, then Host Room or Join. A balanced party is required to start."
		if party_lobby!=null:party_lobby.queue_redraw()
	if role=="host": _assign_team(my_id,team)
	elif role=="guest": _send_channel(host_id,{"type":"team","team":team})

func _assign_team(id: String, team: int) -> void:
	if team not in [-1,0,1] or not teams.has(id): return
	var count := 0
	for other in teams:
		if other != id and int(teams[other]) == team and positions.has(other): count += 1
	if team!=-1 and count>=(bg_team_size if mode=="battlegrounds" else mini(4,arena_seats/2)):
		status_label.text="That team is full. Choose the other side."
		if id!=my_id:_send_channel(id,{"type":"lobby_notice","message":status_label.text})
		return
	teams[id]=team
	status_label.text="Waiting in the centre." if team==-1 else ("Silver" if team==0 else "Blue")+" team selected."
	_send_lobby_state()

func _buy_item() -> void:
	if not started or item_picker.selected<0: return
	var id := str(item_picker.get_item_metadata(item_picker.selected))
	if role=="host": _purchase(my_id,id)
	else: _send_channel(host_id,{"type":"purchase","id":id})

func _purchase(id: String, item_id: String) -> void:
	if arena_world.shatter.active():return
	if mode=="arena" and arena_no_items:status_label.text="Host rule: items and food are disabled for this arena match.";return
	if not items.has(item_id) or not bool(items[item_id].get("shop",true)) or not gold.has(id) or not _near_building(id,"Supplies"): return
	var data: Dictionary = items[item_id]
	var price := int(data.get("cost",0))
	if bool(shop_discounts.get(id,false)) and price>=10:price-=1
	if int(gold[id])<price or not preload("res://scripts/supply_slots.gd").can_add(inventory.get(id,[]),item_id,items): return
	gold[id]=int(gold[id])-price
	(inventory[id] as Array).append(item_id)
	match str(data.get("effect","")):
		"bonus_health": health[id]=int(health[id])+int(data.get("amount",0))
		"revive": health[id]=maxi(60,int(health[id]))
		"bonus_damage": pass
		"armor": pass
	status_label.text="Bought " + str(data.get("name",item_id)) + " for " + str(price) + " CC."

func _upgrade_guard(index: int) -> void:
	if not started or mode!="defense": return
	var id: String = str(["attack","health","armor","count","ranged","area"][index])
	if role=="host": _purchase_guard(my_id,id)
	else: _send_channel(host_id,{"type":"upgrade","id":id})

func _purchase_guard(buyer: String, id: String) -> void:
	if mode!="defense" or not upgrade_level.has(id) or not gold.has(buyer): return
	var building := "Barracks" if id in ["health","count"] else "Forge" if id in ["attack","armor"] else "Archery" if id == "ranged" else "Sanctum"
	if not _near_building(buyer,building): return
	var cap := 3 if id in ["ranged","area","count"] else 5
	var stage := int(upgrade_level[id])
	var price := north_gate.upgrade_price(id,stage)
	if stage>=cap or int(gold[buyer])<price: return
	gold[buyer]=int(gold[buyer])-price;upgrade_level[id]=stage+1
	_stat(buyer,"upgrades",1)
	for guard in guards:
		if str(guard.get("type","")) == "summoned": continue
		if id == "attack": guard["damage"] = float(guard["damage"])+4.0
		if id == "health": guard["hp"] = float(guard["hp"])+20.0
	if id in ["ranged","area"]:
		for lane in 3:
			var converted := false
			for guard in guards:
				if int(guard.get("lane",-1)) == lane and str(guard.get("type","")) == "melee":
					guard["type"] = "ranged" if id == "ranged" else "area"
					guard["damage"] = 14.0+float(upgrade_level[id])*3.0
					converted = true;break
			if not converted:
				_spawn_defense_guard(lane,"ranged" if id == "ranged" else "area",55.0,14.0+float(upgrade_level[id])*3.0)
	status_label.text="Guard " + id + " upgraded by " + str(buyer) + "."

func _send_gold() -> void:
	if not started or roster.size()<2: return
	var other := str(roster[(_slot(my_id)+1)%roster.size()].get("id",""))
	if role=="host": _transfer(my_id,other,20)
	else: _send_channel(host_id,{"type":"gift","to":other})

func _transfer(from_id: String, to_id: String, amount: int) -> void:
	if from_id==to_id or not gold.has(from_id) or not gold.has(to_id) or int(gold[from_id])<amount: return
	gold[from_id]=int(gold[from_id])-amount;gold[to_id]=int(gold[to_id])+amount

func _unhandled_input(event: InputEvent) -> void:
	if shop_open=="dev_desk":return
	if session_menu!=null and not session_menu.page.is_empty():return
	if recovery!=null and recovery.frozen:return
	if presentation!=null and not presentation.page.is_empty():return
	if not event is InputEventKey or not event.pressed or event.echo or not started: return
	var key: InputEventKey = event
	if key.keycode==KEY_E and arena_world.objective.active() and arena_map=="crown_chase" and str(arena_world.objective.crown.get("holder",""))==my_id:
		arena_world.objective.request_throw();get_viewport().set_input_as_handled();return
	if key.keycode==KEY_F:return
	if adventure.quests.journal_key(key.keycode):return
	if key.keycode == KEY_ESCAPE:
		shop_open = "" if not shop_open.is_empty() else "Travel"
		return
	if shop_open == "Travel":
		if key.keycode == KEY_ENTER: _town()
		return
	if spectating() or start_countdown>0:return
	if key.keycode == KEY_E:
		if get("expedition")!=null and get("expedition").between():_send_channel(host_id,{"type":"rift"});return
		if mode=="battlegrounds" and battlegrounds.interact(my_id):return
		if _near_downed(my_id): return
		if mode=="descent":
			if role=="host":descent.interact(my_id)
			else:_send_channel(host_id,{"type":"rift"})
			return
		if adventure.active or adventure.vault.active or adventure.combat.coast.active or adventure.city.active or adventure.hollow.active or adventure.quests.active or adventure.school.active or adventure.tech.active or adventure.immersive.active or adventure.foundry.active or adventure.cinder.active:
			if role == "host":
				if adventure.interact(my_id): return
			else:
				_send_channel(host_id,{"type":"rift"});return
		if not shop_open.is_empty(): shop_open = "";return
		for building in world_buildings:
			if str(building["name"]) != "Gate" and local_pos.distance_to(building["pos"]) < 220: shop_open = str(building["name"]);return
	if not shop_open.is_empty() and shop_open != "Supplies":
		var upgrade_keys: Array = ["health","count"] if shop_open == "Barracks" else ["attack","armor"] if shop_open == "Forge" else ["ranged"] if shop_open == "Archery" else ["area"]
		var choice := int(key.keycode)-int(KEY_1)
		if choice >= 0 and choice < upgrade_keys.size():
			if role == "host": _purchase_guard(my_id,str(upgrade_keys[choice]))
			else: _send_channel(host_id,{"type":"upgrade","id":str(upgrade_keys[choice])})
		return
	if key.keycode in [KEY_J, KEY_K]:
		var selection := "primary" if key.keycode==KEY_J else "secondary"
		if int(levels.get(my_id,1))>=10 and str(attack_branch.get(my_id,"")) != "": selection = "special" if key.keycode==KEY_J else "passive"
		if role=="host": _apply_choice(my_id,selection)
		else: _send_channel(host_id,{"type":"choice","value":selection})
		return
	var slot := int(key.keycode)-int(KEY_1)
	slot=preload("res://scripts/supply_slots.gd").index(inventory.get(my_id,[]),slot,items)
	if slot>=0 and inventory.has(my_id) and slot<(inventory[my_id] as Array).size():
		var id := str(inventory[my_id][slot]);var item: Dictionary = items.get(id,{})
		if preload("res://scripts/supply_slots.gd").consumable(item):
			if role=="host": _consume(my_id,slot)
			else: _send_channel(host_id,{"type":"consume","slot":slot})

func _draw() -> void:
	if session_menu!=null and session_menu.page in ["main","clear","options"]:return
	var font := ThemeDB.fallback_font
	if not started:
		return

	var screen_view:=VIEW
	if spectating():
		draw_rect(Rect2(Vector2.ZERO,VIEW),Color("#0d1c26"))
		var usable=Vector2(VIEW.x-40,VIEW.y-180)
		broadcast_scale=minf(usable.x/FIELD.size.x,usable.y/FIELD.size.y)
		broadcast_offset=Vector2((VIEW.x-FIELD.size.x*broadcast_scale)*.5,85)
		camera=Vector2.ZERO;VIEW=FIELD.size
		if spectator_director!=null and spectator_director.view_mode>0:
			broadcast_scale=maxf(broadcast_scale,.55)
			VIEW=usable/broadcast_scale;camera=(spectator_director.focus-VIEW*.5).clamp(Vector2.ZERO,(FIELD.size-VIEW).max(Vector2.ZERO));broadcast_offset=Vector2(20,85)
		draw_set_transform(broadcast_offset,0,Vector2.ONE*broadcast_scale)
	if not spectating():
		draw_set_transform(media.offset(),0,Vector2.ONE*media.factor());VIEW=screen_view/media.factor()
	var section_began:=Time.get_ticks_usec()
	_draw_world()
	descent.draw(self,camera)
	if fishing!=null:fishing.draw_on(self,camera)
	if mode=="battlegrounds":battlegrounds.draw_world(self)
	arena_world.draw()
	_profile_section("world_draw",section_began)
	section_began=Time.get_ticks_usec()
	for trail in trails:
		var trail_rect:Rect2=trail.get("rect",Rect2(Vector2(-28,-42),Vector2(56,64)))
		_sprite(str(trail.get("hero",hero_ids.get(my_id,selected_hero)))+"_walk1",trail["pos"]+trail_rect.position,trail_rect.size,Color(0.7,0.9,1.0,float(trail["time"])*1.8))
	for guard in guards:
		var sprite := str(guard.get("sprite","mini_basketball")) if str(guard["type"]) == "summoned" else "guard_"+str(guard["type"])
		if not preload("res://scripts/minion_art215.gd").draw_legacy(self,guard,visual_actor("g:"+str(guard.get("net_uid",0)),guard["pos"])-camera,"guard:"+str(guard.get("net_uid",0))):_sprite(sprite,visual_actor("g:"+str(guard.get("net_uid",0)),guard["pos"])-Vector2(24,44),Vector2(48,56))
		if str(guard.get("type",""))=="summoned" and float(guard.get("hp",0))>0:
			var bar:Vector2=visual_actor("g:"+str(guard.get("net_uid",0)),guard.pos)-camera+Vector2(-20,14)
			draw_rect(Rect2(bar,Vector2(40,4)),Color("#26343a"))
			draw_rect(Rect2(bar,Vector2(40*clampf(float(guard.hp)/maxf(1,float(guard.get("max_hp",70))),0,1),4)),Color("#a8d47c"))
	enemy_motion229.sample(opponents,visual_time)
	for foe in opponents:
		if bool(foe.get("buried",false)):continue
		var id := str(foe.get("sprite",foe["type"]))
		var pos: Vector2 = visual_actor("e:"+str(foe.get("uid",0)),foe["pos"])-camera
		if bool(foe.get("health_gem",false)):pos.y-=8+sin(descent.clock*2+int(foe.uid)%7)*5
		if not Rect2(Vector2(-100,-100),VIEW+Vector2(200,200)).has_point(pos): continue
		var texture: Texture2D = art.get(id+"_"+("attack" if mode=="descent" and float(foe.get("warning",-1))>0 or float(foe.get("melee_warning",0))>0 or (str(foe.type) in preload("res://scripts/enemy_visual227.gd").FACTORS and float(foe.get("windup",0))>0) or float(foe.get("v143_pose",0))>adventure.newcomers.clock or float(foe.get("veil_pose",0))>adventure.pursuers.clock or float(foe.get("cinder_pose",0))>adventure.cinder.clock else enemy_motion229.locomotion(foe)))
		var size := Vector2(130,146) if str(foe.type)=="tollbreaker" else Vector2(54,68) if str(foe.type) in north_gate.RIVALS else Vector2(82,88) if bool(foe["boss"]) else Vector2(46,50)
		if bool(foe.get("depth_boss",false)) and str(foe.type) in ["cavern_warden","basalt_ram","garnet_widow"]:size=Vector2(150,175)
		if str(foe.type)=="sluicewarden":size=Vector2(120,120)
		if str(foe.type)=="mirevein_collector":size=Vector2(112,112)
		if str(foe.type)=="depth_sovereign":size=Vector2(124,136)
		if bool(foe.get("veilbound",false)):size=adventure.pursuers.body_size(foe)
		if str(foe.type) in adventure.cinder.TYPES:size=adventure.cinder.body_size(str(foe.type))
		if str(foe.type) in adventure.tech.TYPES:size=adventure.tech.body_size(str(foe.type))
		if str(foe.type) in adventure.school.TYPES:size=adventure.school.body_size(str(foe.type))
		if float(foe.get("down_time",0))>0:size=Vector2(70,28)
		if str(foe["type"]) in ["gongbreaker","silence_regent","rootbound_keeper"]: size=Vector2(120,128)
		if str(foe["type"])=="gilded_usurper":size*=1.0 if int(foe.get("generation",0))==0 else .78 if int(foe.get("generation",0))==1 else .56
		if bool(foe.get("depth_boss",false)):size=descent.visual_size(foe)
		preload("res://scripts/starter_boss.gd").draw_warning(self,foe,pos)
		if mode!="descent" and float(foe.get("warning",-1))>0:preload("res://scripts/combat_cues.gd").danger(self,pos,48,float(foe.warning),.55)
		if bool(foe.get("depth_boss",false)):descent.draw_boss(self,foe,pos)
		elif texture != null: draw_texture_rect(texture,preload("res://scripts/enemy_visual227.gd").adjusted(id,Rect2(pos-size*Vector2(0.5,0.7),size)),false)
		else: draw_circle(pos,19,Color("#ffad7a"))
		var hp_y:float=-size.y*.7-8 if bool(foe.get("veilbound",false)) or str(foe.type) in adventure.cinder.TYPES or str(foe.type) in adventure.tech.TYPES or str(foe.type)=="tollbreaker" else -56 if str(foe.type) in north_gate.RIVALS else -size.y*.7-8 if bool(foe.get("depth_boss",false)) else -48
		if bool(foe.get("depth_boss",false)):hp_y=descent.health_bar_y(foe)
		if not (adventure.school.active and bool(foe.boss)):draw_rect(Rect2(pos+Vector2(-23,hp_y),Vector2(46,5)),Color("#382936"))
		if not (adventure.school.active and bool(foe.boss)):draw_rect(Rect2(pos+Vector2(-23,hp_y),Vector2(46*clampf(float(foe["hp"])/float(foe["max_hp"]),0,1),5)),Color("#ee7c77"))
	for missile in missiles:
		if Rect2(camera-Vector2(12,12),VIEW+Vector2(24,24)).has_point(missile.pos):draw_circle(missile["pos"]-camera,7,Color(str(missile.get("color","#ffd985"))) if str(missile["owner"]) != "enemy" else Color("#ed7a92"))
	for slot in roster.size():
		var player: Dictionary = roster[slot];var id := str(player.get("id",""))
		if spectator_supported() and spectator_host and id==host_id:continue
		if arena_world.shatter.active() and arena_world.shatter.eliminated.has(id):continue
		if not adventure.combat.visible_owner(id):continue
		var pos: Vector2 = arena_world.shatter.draw_point(id,_player_draw_position(id,_spawn_player(slot))) - camera
		if not Rect2(Vector2(-100,-100),VIEW+Vector2(200,200)).has_point(pos): continue
		var hero_id := str(hero_ids.get(id,"ram"))
		if arena_world.shatter.active() and arena_world.shatter.airborne(id):pos.y-=sin(PI*clampf((float(arena_world.shatter.hops[id].until)-arena_world.shatter.visual_clock())/.34,0,1))*35
		if arena_world.shatter.active() and arena_world.shatter.dropping.has(id):
			arena_world.shatter.draw_falling_hero(id,pos,art.get(hero_id+"_idle"),Color.WHITE);continue
		var walking := _actor_walking(id)
		if hero_id=="caelum" and adventure.combat.v59.copies.has(id):walking=bool(adventure.combat.v59.copies[id].get("walking",false))
		var pose := "attack" if Time.get_ticks_msec() < maxi(int(attack_pose_until.get(id,0)),predicted_pose_until if id==my_id else 0) else ("walk1" if int(visual_time*7)%2 == 0 else "walk2") if walking else "idle"
		if adventure.combat.classics.channeling(id):pose="open"
		elif adventure.combat.classics.spinning(id):pose="spin"
		if adventure.combat.v90.pending_rebirth(str(id)):pass
		elif hero_id=="snail" and adventure.combat.v79.moving(str(id)):pose="shell"
		if hero_id=="sunflower" and adventure.combat.charging_sun(str(id)):pose="special"
		if pose=="attack" and art.has(hero_id+"_attack2") and int(visual_time*12)%2==1:pose="attack2"
		var texture: Texture2D = core_art.picture(str(id),hero_id,pose,_player_draw_position(str(id),pos+camera),walking,visual_time,adventure.combat.classics.channeling(str(id)),charges.has(id) or adventure.combat.classics.moving(str(id))) if hero_id in core_art.HEROES else art.get(hero_id+"_"+pose)
		var tint := Color.WHITE if int(health.get(id,0)) > 0 else Color(0.5,0.5,0.5,0.45)
		if Time.get_ticks_msec() < int(stealth_until.get(id,0)): tint.a = 0.43
		if Time.get_ticks_msec()<int(hit_flash.get(id,0)):tint=Color(1,.45,.4)
		if hero_id=="goalie":skating_motion.draw_skates(self,str(id),pos)
		draw_ellipse_shadow(pos,17.0 if hero_id=="book" else 16.0 if hero_id=="basketball" else 23.0)
		adventure.combat.halloween.draw_mount(self,str(id),camera)
		if custom_party.runtimes.has(str(id)) and custom_party.runtimes[str(id)].form_texture()!=null:texture=custom_party.runtimes[str(id)].form_texture()
		var hero_rect:Rect2=adventure.combat.v78.visual_rect(str(id),pos) if hero_id=="gopher" else fish_motion.sprite_rect(str(id),pos) if hero_id=="ripplejaw" else wing_motion.sprite_rect(str(id),pos) if hero_id=="velvetwing" else basketball_motion.sprite_rect(str(id),pos) if hero_id=="basketball" else Rect2(pos+adventure.combat.v48.visual_offset(str(id))-Vector2(28,42),Vector2(56,64))
		hero_rect.position+=adventure.combat.stance_heroes.visual_offset(str(id))+adventure.combat.release_heroes.visual_offset(str(id))+adventure.combat.v79.visual_offset(str(id))+motion_v85.offset(hero_id)+motion_v85.actor_offset(str(id),hero_id)+adventure.combat.halloween.visual_offset(str(id))
		hero_rect.position+=adventure.combat.classics.body_offset(str(id))
		if hero_id=="navigator":hero_rect.position.y-=3+sin(visual_time*2.8)*2.5
		hero_rect=adventure.combat.v110.resize(str(id),hero_rect)
		hero_rect=core_art.body_rect(hero_id,hero_rect,visual_time)
		if mode=="descent":hero_rect=descent.hero_rect(hero_rect)
		if adventure.combat.v90.pending_rebirth(str(id)):pass
		elif hero_id=="snail" and adventure.combat.v79.moving(str(id)):
			adventure.combat.v79.draw_shell(self,str(id),pos,texture,tint)
		elif hero_id=="gopher" and adventure.combat.v78.immune(str(id)):
			adventure.combat.v78.draw_burrow(self,str(id),pos)
		elif texture != null and hero_id=="ripplejaw":
			world_transform(pos,fish_motion.angle(str(id)));draw_texture_rect(texture,Rect2(hero_rect.position-pos,hero_rect.size),false,tint);world_transform()
		elif texture != null and not adventure.combat.robot.transformed(str(id)) and not adventure.combat.twister.drawn_transformed(str(id)):draw_texture_rect(texture,hero_rect,false,tint)
		var cosmetic:Dictionary=cosmetic_for(id)
		if str(cosmetic.get("daily_date",""))==legacy.daily.today and int(health.get(id,0))>0:
			preload("res://scripts/daily_challenge.gd").draw_on(self,pos,visual_time)
		if int(health.get(id,0))>0:preload("res://scripts/player_cosmetics.gd").draw_on(self,pos,visual_time,str(cosmetic.get("extra_effect","")),str(cosmetic.get("weekly_week","")))
		if int(health.get(id,0))>0:preload("res://scripts/creation_badges.gd").draw_on(self,pos,visual_time,cosmetic)
		if bool(cosmetic.get("game_dev",false)) and int(health.get(id,0))>0:
			preload("res://scripts/dev_insignia.gd").draw_on(self,pos,visual_time)
		if not cosmetic.is_empty() and not (media.clean_view or media.capturing):
			draw_string(font,pos+Vector2(-35,-70),("GAME DEV" if bool(cosmetic.get("game_dev",false)) else str(cosmetic.get("title",""))),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#ddcba3"))
		if downed.has(id):
			draw_string(font,pos+Vector2(-65,55),"DOWN "+str(int(downed[id].get("left",0)))+"s • HOLD INTERACT",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#a5e4b6"))
			draw_rect(Rect2(pos+Vector2(-40,65),Vector2(80*float(downed[id].get("progress",0))/2.0,6)),Color("#9addb4"))
		if mode in ["arena","battlegrounds"] and pvp_rule=="teams":draw_arc(pos+Vector2(0,14),23,0,TAU,24,Color("#c5d6df") if int(teams.get(id,0))==0 else Color("#69b4f0"),2)
		elif id == my_id: draw_arc(pos+Vector2(0,14),21,0,TAU,24,Color(1,0.92,0.65,0.5),2)
		if not (media.clean_view or media.capturing):draw_string(font,pos+Vector2(-28,-50),str(player.get("name","Player"))+("" if arena_world.shatter.active() else " L"+str(levels.get(id,1))),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color.WHITE)
		if not arena_world.shatter.active() and not (media.clean_view or media.capturing):draw_rect(Rect2(pos+Vector2(-24,26),Vector2(48*clampf(float(health.get(id,0))/maxf(1.0,float(_max_hp(id))),0,1),4)),Color("#83dda0"))
		if Time.get_ticks_msec() < int(shield_until.get(id,0)): draw_arc(pos,38,0,TAU,32,Color("#91dcff"),4)
	for wall in ice_walls:
		_sprite("ice_pillar",wall["pos"]-Vector2(32,48),Vector2(64,84))
	for effect in effects: _draw_effect(effect)
	for label in ([] if media.clean_view or media.capturing else damage_labels):
		if not adventure.combat.visible_owner(str(label.get("victim",""))):continue
		draw_string(font,label["pos"]-camera,str(label["text"]),HORIZONTAL_ALIGNMENT_LEFT,-1,19,Color(1,0.88,0.58,minf(1.0,float(label["time"])*2)))
	_profile_section("actors_effects_draw",section_began)
	section_began=Time.get_ticks_usec()
	adventure.draw_on(self,camera)
	custom_party.draw_on(self,camera)
	if get("expedition")!=null and get("expedition").special():get("expedition").draw_world()
	if mode=="defense":north_gate.draw_attacks(self,camera)
	arena_world.objective.draw_crown()
	arena_world.extra.draw_fog()
	descent.draw_darkness(self,camera)
	_profile_section("adventure_draw",section_began)
	section_began=Time.get_ticks_usec()
	if media.clean_view or media.capturing:
		VIEW=screen_view;draw_set_transform(Vector2.ZERO,0,Vector2.ONE);return
	if spectating():
		VIEW=screen_view;draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
		_draw_broadcast(font)
		_draw_countdown(font)
		return
	VIEW=screen_view;draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
	_draw_countdown(font)
	adventure.school.draw_hud(self)
	adventure.cinder.draw_hud(self);adventure.tech.draw_hud(self);adventure.immersive.draw_hud(self)
	if mode=="battlegrounds":battlegrounds.draw_hud(self)
	if get("expedition")!=null and get("expedition").special():get("expedition").draw_hud()
	if arena_world.shatter.active():
		arena_world.shatter.draw_overlay();_profile_section("hud_draw",section_began);return
	var title := ("PRACTICE CONTINUE • " if continuation!=null and continuation.active else "") + ("Battlegrounds • "+str(battlegrounds.MAPS.get(bg_map,"Front")) if mode=="battlegrounds" else "Wave " + str(wave) + "  |  Town gate " + str(int(gate_hp)) + "/" + str(int(gate_max)) if mode == "defense" else "Floor " + str(floor_number) + "  |  Best " + str(best_floor) if mode == "descent" else "PvP " + pvp_rule.to_upper() + "  |  Score " + str(pvp_scores.get(my_id,0)) + "  |  " + str(maxi(0,300-int(run_time))) + "s left" if mode == "arena" else str(regions.get(realm_id,{}).get("name",realm_id)) + ("  |  Quests "+str(adventure.quests.completed_count())+"/"+str(adventure.quests.data.get("quests",[]).size()) if adventure.quests.active else "  |  Sluices "+str(int(adventure.foundry.cleared.has(1))+int(adventure.foundry.cleared.has(2)))+"/2" if adventure.foundry.active else "  |  Explore" if adventure.immersive.active else "  |  Continuum hunt" if adventure.tech.active else "  |  School adventure" if adventure.school.active else "  |  Stage " + str(wave) + "/3"))
	if get("expedition")!=null and get("expedition").special():title=("Portal attunement" if get("expedition").kind=="attunement" else "The Between" if get("expedition").between() else "Overcharged "+str(regions.get(realm_id,{}).get("name",realm_id)))+" • 2-player expedition"
	if arena_world.shatter.active():title=arena_world.shatter.header()
	elif arena_world.objective.active():title=arena_world.objective.header()
	preload("res://scripts/combat_hud.gd").header(self,title,int(gold.get(my_id,0)),float(health.get(my_id,0)),float(_max_hp(my_id)))
	preload("res://scripts/boss_health.gd").draw_on(self)
	_draw_hero_cooldowns(font)
	var needed_xp=5+int(levels.get(my_id,1))*3
	preload("res://scripts/combat_hud.gd").experience(self,"LEVEL 10 • ALL ABILITIES READY" if mode=="arena" and not arena_opening else "Lv %d • XP %d / %d" % [levels.get(my_id,1),xp.get(my_id,0),needed_xp],1.0 if mode=="arena" and not arena_opening else clampf(float(xp.get(my_id,0))/needed_xp,0,1))
	if continuation!=null and continuation.active:
		draw_rect(Rect2(24,94,245,24),Color("#18475d"));draw_string(font,Vector2(29,111),"PRACTICE • discoveries only",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#c3ebf4"))
	if mode not in ["arena","battlegrounds"]:draw_string(font,Vector2(24,VIEW.y-115),status_label.text,HORIZONTAL_ALIGNMENT_LEFT,VIEW.x-50,14,Color("#d9d1ae"))
	elif arena_notice_left>0 and not arena_world.objective.active():
		var opacity:=minf(1,arena_notice_left)
		draw_rect(Rect2(20,110,600,53),Color(.03,.08,.11,.65*opacity))
		draw_string(font,Vector2(34,132),status_label.text,HORIZONTAL_ALIGNMENT_LEFT,572,15,Color(.85,.82,.68,opacity))
		draw_string(font,Vector2(34,152),str(arena_world.MAPS.get(arena_map,"Arena")),HORIZONTAL_ALIGNMENT_LEFT,572,14,Color(.91,.81,.6,opacity))
	_draw_minimap()
	arena_world.extra.draw_hud()
	arena_world.objective.draw_hud()
	arena_world.shatter.draw_hud()
	if mode=="defense":north_gate.draw_hud(self)
	if shop_open.is_empty():adventure.quests.draw_hud(self)
	for building in world_buildings:
		if str(building["name"]) != "Gate" and local_pos.distance_to(building["pos"]) < 220:
			draw_string(font,Vector2(450,VIEW.y-140),"E  Visit " + str(building["name"]),HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("#ffe8a7"));break
	if level_cards==null and int(levels.get(my_id,1)) >= 8 and str(attack_branch.get(my_id,"")) == "": draw_string(font,Vector2(420,635),"LV8: J +primary / K faster secondary",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#ffe9b7"))
	elif level_cards==null and int(levels.get(my_id,1)) >= 10 and str(mastery_choice.get(my_id,"")) == "": draw_string(font,Vector2(420,635),"LV10: J faster special / K stronger passive",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#ffe9b7"))
	if not shop_open.is_empty():
		draw_set_transform((VIEW-Vector2(1280,720))*0.5)
		_draw_shop(font)
		draw_set_transform(Vector2.ZERO)

	descent.draw_overlay(self)

	_profile_section("hud_draw",section_began)

func draw_ellipse_shadow(pos: Vector2, radius:float=23.0) -> void:
	world_transform(pos+Vector2(0,18),0,Vector2(1,0.3))
	draw_circle(Vector2.ZERO,radius,Color(0.02,0.07,0.09,0.3))
	world_transform()

var world_tile_cache:Dictionary={}
func cached_world_tile(tx:int,ty:int,tile_size:int)->String:
	var key:=Vector3i(tx,ty,tile_size)
	if world_tile_cache.has(key):return str(world_tile_cache[key])
	var tile:=world_terrain
	var point:=Vector2(tx*tile_size+tile_size/2,ty*tile_size+tile_size/2)
	for patch in world_patches:
		if Geometry2D.is_point_in_polygon(point,patch["polygon"]):tile=str(patch["tile"])
	if world_tile_cache.size()>=4096:world_tile_cache.clear()
	world_tile_cache[key]=tile
	return tile
func _draw_world() -> void:
	var tile_size:int=128 if spectating() else 64
	var bounds := Rect2(camera-Vector2(160,160),VIEW+Vector2(320,320))
	if realm_id=="moonveil" and mode=="coop":
		if terrain_cache!=null:terrain_cache.hide()
		preload("res://scripts/moon_castle.gd").draw(self,camera)
	elif realm_id=="silverfall" and mode=="coop":
		if terrain_cache!=null:terrain_cache.hide()
	elif spectating() or terrain_cache==null:
		for tx in range(int(camera.x/tile_size),int((camera.x+VIEW.x)/tile_size)+1):
			for ty in range(int(camera.y/tile_size),int((camera.y+VIEW.y)/tile_size)+1):
				var point := Vector2(tx*tile_size+tile_size/2,ty*tile_size+tile_size/2)
				var tile := cached_world_tile(tx,ty,tile_size)
				_sprite(tile,Vector2(tx*tile_size,ty*tile_size),Vector2(tile_size,tile_size))
				if tile in ["grass","forest"] and (tx*37+ty*71)%23 == 3: _sprite("flower",point-Vector2(16,20),Vector2(32,32))
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
	for spring in world_fountains:
		if bounds.has_point(spring):
			draw_arc(spring-camera,135,0,TAU,32,Color(.5,.9,.8,.3),2,true)
			draw_string(ThemeDB.fallback_font,spring-camera+Vector2(-100,-110),("" if mode=="defense" and spring.distance_to(GATE+Vector2(0,600))<10 else "PILGRIM’S SPRING"),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#b7efdb"))
	var retained_props:bool=mode=="coop" and realm_id=="moonveil" and not spectating()
	if retained_props and not is_instance_valid(realm_props):
		realm_props=preload("res://scripts/realm_props.gd").new();add_child(realm_props);realm_props.setup(self,true)
	if not retained_props:
		for decoration in world_decorations:
			if bounds.has_point(decoration["pos"]): draw_texture_rect(decoration["texture"],Rect2(decoration["pos"]-(decoration["size"] as Vector2)*0.5-camera,decoration["size"]),false)
	for obstacle in field_obstacles:
		if bounds.has_point(obstacle["pos"]):
			if str(obstacle.get("kind","tree"))=="rock":
				var diameter:=float(obstacle.get("radius",38))*2+8
				_sprite("rock",obstacle["pos"]-Vector2.ONE*diameter*.5,Vector2.ONE*diameter)
			else:_sprite(str(obstacle.get("kind","tree")),obstacle["pos"]-Vector2(44,65),Vector2(88,112))
	for building in world_buildings:
		if mode=="battlegrounds":continue
		if not bounds.has_point(building["pos"]): continue
		var is_gate := str(building["name"]) == "Gate"
		var size := Vector2(260,210) if is_gate else Vector2(170,150)
		_sprite(str(building["sprite"]),building["pos"]-size*Vector2(0.5,0.7),size)
		draw_string(ThemeDB.fallback_font,building["pos"]-camera+Vector2(-65,65),str(building["name"]).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#f5e3bb"))
	if mode == "defense":
		north_gate.draw_world(self,camera)
		for lane in 3:
			var sign: Vector2 = GATE + (APPROACHES[lane]-GATE).normalized()*600
			_sprite("town_banner",sign-Vector2(32,90),Vector2(64,100))
			draw_string(ThemeDB.fallback_font,sign-camera+Vector2(-55,32),north_gate.NAMES[lane],HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#ffe7aa"))

func _sprite(key: String, point: Vector2, size: Vector2, tint: Color = Color.WHITE) -> void:
	var texture: Texture2D = art.get(key)
	if texture != null and Rect2(camera-size,VIEW+size*2).has_point(point): draw_texture_rect(texture,preload("res://scripts/enemy_visual227.gd").adjusted(key,Rect2(point-camera,size)),false,tint)

func _draw_effect(effect: Dictionary) -> void:
	if str(effect.get("style",""))=="heal_contact":return
	if effect.has("victim") and not adventure.combat.visible_owner(str(effect.victim)):return
	var color := Color(str(effect.get("color","#ffd877")))
	color.a = clampf(float(effect["time"])*4.0,0,1)
	var pos: Vector2 = effect["pos"]-camera
	var radius := float(effect.get("radius",40))
	if effect.get("visual","")=="medic_pulse":
		preload("res://scripts/medic_visuals.gd").pulse(self,pos,radius,1-float(effect.time)/.4);return
	var style := str(effect.get("style","ring"))
	var angle := float(effect.get("angle",0))
	var aim := Vector2.from_angle(angle)
	if style in ["melee","punch","scratch","slash","kick"]:
		var half_arc := float(effect.get("half_arc",0.6))
		var visual := str(effect.get("visual",style))
		if visual == "forge_hammer":
			preload("res://scripts/hero_visuals1984.gd").hammer(self,_player_draw_position(str(effect.get("owner","")),effect.pos)-camera,aim,radius,1-float(effect.time)/.28)
		elif visual == "bounce":
			draw_arc(pos+aim*(radius-12),12,0,TAU,20,color,4,true)
		elif visual == "medic_boot":
			preload("res://scripts/medic_visuals.gd").boot(self,pos,aim,radius,1-float(effect.time)/.28)
		elif visual in ["kick","punch"]:
			draw_line(pos+aim*24,pos+aim*radius,color,10,true)
		elif visual == "scratch":
			for n in [-1,0,1]:
				var tangent := aim.orthogonal()*float(n)*9.0
				draw_line(pos+aim*30+tangent,pos+aim*radius+tangent,color,4,true)
		else: draw_arc(pos,radius,angle-half_arc,angle+half_arc,24,color,7,true)
	elif style == "beam": draw_line(pos,pos+aim*radius,color,35,true)
	elif style == "lightning": preload("res://scripts/lightning.gd").draw_on(self,pos,effect["end"]-camera,color)
	elif style == "line": draw_line(pos,effect["end"]-camera,color,7,true)
	elif style == "damage": pass
	else: draw_arc(pos,radius,0,TAU,40,color,4,true)

func _draw_minimap() -> void:
	if mode=="descent":return
	if arena_world.shatter.active():arena_world.shatter.draw_minimap();return
	if arena_world.objective.active():arena_world.objective.draw_minimap();return
	if mode=="arena" and arena_map=="lanternfall":return
	if mode=="battlegrounds":return
	if adventure.quests.active:return
	var rect := Rect2(VIEW.x-220,100,200,145)
	draw_rect(rect,Color(0.03,0.08,0.10,0.85))
	draw_rect(rect,Color("#8ba696"),false,2)
	if mode == "defense":
		north_gate.draw_minimap(self,rect)
		draw_rect(Rect2(rect.position+GATE/FIELD.size*rect.size-Vector2(3,3),Vector2(6,6)),Color("#ffe4a1"))
	for enemy in opponents: draw_circle(rect.position+(enemy["pos"] as Vector2)/FIELD.size*rect.size,2,Color("#ef8c81"))
	if mode == "defense":
		for guard in guards:
			var marker: Vector2 = rect.position+(guard["pos"] as Vector2)/FIELD.size*rect.size
			draw_rect(Rect2(marker-Vector2(2,2),Vector2(4,4)),Color("#75efa0"))
	for id in positions:
		if adventure.combat.visible_owner(str(id)):draw_circle(rect.position+(local_pos if id == my_id else positions[id])/FIELD.size*rect.size,3,Color.WHITE if id == my_id else Color("#86cff2"))
	for id in adventure.combat.v59.copies:
		var body:Dictionary=adventure.combat.v59.copies[id]
		if not body.get("transferred",false):draw_circle(rect.position+adventure.combat.vec(body.pos)/FIELD.size*rect.size,3,Color.WHITE if str(id)==my_id else Color("#86cff2"))
	draw_rect(Rect2(rect.position+camera/FIELD.size*rect.size,VIEW/FIELD.size*rect.size),Color(1,1,1,0.35),false,1)

func _draw_shop(font: Font) -> void:
	if shop_open=="dev_desk":return
	draw_rect(Rect2(350,210,580,300),Color(0.04,0.09,0.12,0.95))
	draw_string(font,Vector2(380,250),shop_open.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color("#ffe5a9"))
	if shop_open == "Travel":
		draw_string(font,Vector2(380,310),"Enter: return to town as " + str(characters.get(selected_hero,{}).get("name",selected_hero)),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
		draw_string(font,Vector2(380,350),"Escape: keep playing",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
	elif shop_open == "Supplies":
		draw_string(font,Vector2(380,310),"Choose an item below and press BUY ITEM.",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
		draw_string(font,Vector2(380,350),"CC: " + str(gold.get(my_id,0)) + "  |  Carry 3 equipment + 1 consumable. Use key 4 for the bottle.",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
		if item_picker.selected >= 0:
			var item: Dictionary = items.get(str(item_picker.get_item_metadata(item_picker.selected)),{})
			var line := ""
			var y := 385.0
			for word in str(item.get("description","")).split(" "):
				var next := word if line.is_empty() else line+" "+word
				if font.get_string_size(next,HORIZONTAL_ALIGNMENT_LEFT,-1,18).x > 510:
					draw_string(font,Vector2(380,y),line,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#bde8d0"));y+=24;line=word
				else: line=next
			draw_string(font,Vector2(380,y),line,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#bde8d0"))
	else:
		var keys: Array = ["health","count"] if shop_open == "Barracks" else ["attack","armor"] if shop_open == "Forge" else ["ranged"] if shop_open == "Archery" else ["area"]
		for n in keys.size():
			var key := str(keys[n]);var stage := int(upgrade_level.get(key,0))
			var price := north_gate.upgrade_price(key,stage) if mode=="defense" else (85 if key == "ranged" else 130 if key == "area" else 45)+stage*35
			draw_string(font,Vector2(380,310+n*42),str(n+1)+"  Guard "+key.capitalize()+"  Lv"+str(stage)+"  -  "+str(price)+" CC",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
	draw_string(font,Vector2(380,470),"E / Escape: close  |  Combat continues while shopping",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#c5d6cf"))

func _draw_hero_cooldowns(font: Font) -> void:
	var hero: Dictionary = characters.get(str(hero_ids.get(my_id,"ram")),{})
	var keys: Array[String] = ["primary","secondary","special"]
	var labels: Array[String] = ["LMB","RMB","SPC"]
	if mobile.enabled: labels.assign(["AIM","2ND","SPC"])

	for index in range(3):
		var key: String = keys[index]
		var needed: int = 1 if index==0 else 3 if index==1 else 6
		var locked: bool = int(levels.get(my_id,1))<needed
		var stats: Dictionary = hero.get(key,{})
		var duration: float = maxf(0.1,float(stats.get("cooldown",1.0)))
		var remaining: float = maxf(0.0,float(cooldown_remaining.get(my_id,{}).get(key,0.0))) if role=="guest" else maxf(0.0,float(int(cooldown_at.get(my_id,{}).get(key,0))-Time.get_ticks_msec())/1000.0)
		var fraction: float = 0.0 if locked else clampf(1.0-remaining/duration,0.0,1.0)

		var text_value: String = "Lv"+str(needed) if locked else "READY" if remaining<=0 else "%.1f" % remaining
		preload("res://scripts/combat_hud.gd").cooldown(self,index,labels[index],fraction,text_value,locked)

func _rebuild_grid() -> void:
	obstacle_grid.clear()
	for obstacle in field_obstacles:
		var key := Vector2i((obstacle["pos"] as Vector2)/160.0)
		if not obstacle_grid.has(key): obstacle_grid[key] = []
		obstacle_grid[key].append(obstacle)

func descent_direction(enemy: Dictionary, target: Vector2, delta: float) -> Vector2:
	var origin: Vector2=enemy["pos"]
	if _clear_path(origin,target): return (target-origin).normalized()
	if descent_nav == null:
		descent_nav=AStarGrid2D.new();descent_nav.region=Rect2i(0,0,30,22);descent_nav.cell_size=Vector2(80,80);descent_nav.offset=Vector2(40,40);descent_nav.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_NEVER;descent_nav.update()
		for x in 30:
			for y in 22:
				var point:=Vector2(x*80+40,y*80+40)
				var blocked:=point.y>FIELD.end.y-40
				for rock in field_obstacles:
					if point.distance_to(rock["pos"])<float(rock["radius"])+65:blocked=true
				descent_nav.set_point_solid(Vector2i(x,y),blocked)
	enemy["nav_timer"]=float(enemy.get("nav_timer",0))-delta
	if float(enemy["nav_timer"])<=0:
		enemy["nav_timer"]=.4+float(int(enemy.get("uid",0))%7)*.025
		var start:=descent_cell(origin);var finish:=descent_cell(target)
		var path:=descent_nav.get_point_path(start,finish,true)
		enemy["nav_goal"]=(path[1] if _clear_path(origin,path[1]) else path[0]) if path.size()>1 else target
	var goal:Vector2=enemy.get("nav_goal",target)
	return (goal-origin).normalized()

func descent_ranged_direction(enemy:Dictionary,target:Vector2,delta:float)->Vector2:
	# Reuse a short-lived firing-position plan instead of chasing the same point.
	var origin:Vector2=enemy.pos;var uid:=int(enemy.get("uid",0))
	enemy["firing_timer"]=float(enemy.get("firing_timer",0))-delta
	if float(enemy.firing_timer)<=0 or origin.distance_to(enemy.get("firing_goal",origin))<22 and not _clear_path(origin,target):
		enemy.firing_timer=.7+float(posmod(uid,7))*.09
		var desired:=250.0+float(posmod(uid,4))*15
		var radial:Vector2=(origin-target).normalized()
		if radial.length()<.1:radial=Vector2.RIGHT
		var best:Vector2=origin;var best_score:=-INF
		# Consider the near firing arc and flanks; never teleport or shoot through walls.
		for k in [0,1,-1,2,-2,3,-3,4]:
			var point:Vector2=target+radial.rotated(float(k)*.43)*desired
			if not FIELD.grow(-60).has_point(point) or not _clear_path(point,target):continue
			var score:=-origin.distance_to(point)*.08
			for other in opponents:
				if int(other.get("uid",-1))==uid or bool(other.get("health_gem",false)):continue
				var other_goal:Vector2=other.get("firing_goal",other.pos)
				score-=maxf(0,175-point.distance_to(other_goal))*1.8
			if _clear_path(origin,point):score+=22
			if score>best_score:best_score=score;best=point
		enemy.firing_goal=best if best_score>-INF else target
	var goal:Vector2=enemy.get("firing_goal",target)
	var wish:=descent_direction(enemy,goal,delta) if origin.distance_to(goal)>28 else Vector2.ZERO
	# Local separation remains cheap; expensive goal scoring runs about once a second.
	var separation:=Vector2.ZERO
	for other in opponents:
		if int(other.get("uid",-1))==uid:continue
		var away:Vector2=origin-(other.pos as Vector2);var gap:=away.length()
		if gap<125:
			if gap<1:away=Vector2.from_angle(float(posmod(uid,628))/100);gap=1
			separation+=away.normalized()*(1-gap/125.0)
	wish=(wish+separation*1.7).limit_length()
	if wish.length()<.1:return Vector2.ZERO
	for angle in [0.0,.6,-.6,1.2,-1.2]:
		var direction:=wish.rotated(angle)
		if _clear_path(origin,origin+direction*45):return direction
	return Vector2.ZERO

func descent_cell(point: Vector2) -> Vector2i:
	var cell:=Vector2i((point/80).floor())
	if descent_nav.region.has_point(cell) and not descent_nav.is_point_solid(cell): return cell
	var closest:=INF;var answer:=Vector2i(15,10)
	for x in range(maxi(0,cell.x-3),mini(30,cell.x+4)):
		for y in range(maxi(0,cell.y-3),mini(22,cell.y+4)):
			var candidate:=Vector2i(x,y)
			if descent_nav.is_point_solid(candidate): continue
			var distance:=point.distance_squared_to(Vector2(x*80+40,y*80+40))
			if distance<closest: closest=distance;answer=candidate
	return answer

func _move_actor(origin: Vector2, displacement: Vector2) -> Vector2:
	var steps := maxi(1,int(ceil(displacement.length()/10.0)))
	var step := displacement/float(steps)
	var point := origin
	for n in steps:
		var horizontal := (point+Vector2(step.x,0)).clamp(FIELD.position+Vector2(30,30),FIELD.end-Vector2(30,30))
		if _clear_path(point,horizontal) and arena_world.extra.movement_clear(point,horizontal): point = horizontal
		var vertical := (point+Vector2(0,step.y)).clamp(FIELD.position+Vector2(30,30),FIELD.end-Vector2(30,30))
		if _clear_path(point,vertical) and arena_world.extra.movement_clear(point,vertical): point = vertical
	return point

func _max_hp(id: String) -> int:
	var total := int(characters.get(str(hero_ids.get(id,selected_hero)),{}).get("max_health",120))
	for item_id in inventory.get(id,[]):
		var item: Dictionary = items.get(str(item_id),{})
		if str(item.get("effect","")) == "bonus_health": total += int(item.get("amount",0))
	return int(total*legacy.hp_factor(id))+(descent.hp(id) if mode=="descent" else 0)

func _rival(id: String, other: String) -> bool:
	if mode=="battlegrounds":
		var a:int=battlegrounds.side_of(id);var b:int=battlegrounds.side_of(other)
		return id!=other and a>=0 and b>=0 and a!=b and (int(health.get(other,0))>0 or other.begins_with("bgarmy:"))
	return other != id and int(health.get(other,0)) > 0 and (pvp_rule == "ffa" or int(teams.get(id,0)) != int(teams.get(other,0)))

func _near_building(id: String, name: String) -> bool:
	if not positions.has(id) or int(health.get(id,0)) <= 0: return false
	for building in world_buildings:
		if str(building["name"]) == name and (positions[id] as Vector2).distance_to(building["pos"]) < 220: return true
	return false

func _random_spawn(random: RandomNumberGenerator) -> Vector2:
	for attempt in 60:
		var point := Vector2(random.randf_range(180,FIELD.size.x-180),random.randf_range(180,FIELD.size.y-180))
		if _clear_path(point,point) and point.distance_to(local_pos)>300: return point
	return FIELD.size*0.5+Vector2(400,0)

func _emit_effect(effect: Dictionary) -> void:
	if effect.has("cue"): journey.cue(str(effect["cue"]))
	effects.append(effect.duplicate())
	var event := effect.duplicate()
	var point: Vector2 = event["pos"]
	event["pos"] = [point.x,point.y]
	if event.has("end"):
		var endpoint: Vector2 = event["end"];event["end"] = [endpoint.x,endpoint.y]
	sent_effects.append(event)

func _receive_effect(event: Dictionary) -> void:
	if event.has("cue"): journey.cue(str(event["cue"]))
	var effect := event.duplicate()
	effect["pos"] = Vector2(float(event["pos"][0]),float(event["pos"][1]))
	if event.has("end"): effect["end"] = Vector2(float(event["end"][0]),float(event["end"][1]))
	if str(effect.get("style","")) == "damage":
		adventure.combat.feedback.hit(effect["pos"]+Vector2(18,45),float(effect.get("amount",0)),str(effect.get("victim","")))
		damage_labels.append({"pos":effect["pos"],"time":0.7,"text":"-"+str(int(effect.get("amount",0))),"victim":str(effect.get("victim",""))})
	elif str(effect.get("style",""))=="heal_contact":
		adventure.combat.feedback.hit(effect["pos"],float(effect.get("amount",0)),str(effect.get("victim","")),true)
	else:
		if str(effect.get("style",""))=="hit_ring":hit_flash[str(effect.get("victim",""))]=Time.get_ticks_msec()+300
		effects.append(effect)

func _damage_feedback(point: Vector2, amount: float, victim:String="") -> void:
	adventure.combat.feedback.hit(point,amount,victim)
	journey.cue("hit")
	damage_labels.append({"pos":point-Vector2(18,45),"time":0.7,"text":"-"+str(int(amount)),"victim":victim})
	var event := {"pos":[point.x-18,point.y-45],"style":"damage","amount":amount,"time":0.7,"color":"#ffe28f","victim":victim}
	sent_effects.append(event)

func _apply_lifesteal(id: String, damage: float) -> void:
	if adventure.pursuers.leech_blocked(id):return
	if not health.has(id): return
	var hero: Dictionary = characters.get(str(hero_ids.get(id,"ram")),{})
	var steal := 0.0
	if int(levels.get(id,1)) >= 5 and str(hero.get("passive_effect","")) == "life_steal": steal = 0.13 if str(mastery_choice.get(id,"")) == "passive" else float(hero.get("passive_amount",0.08))
	for item_id in inventory.get(id,[]):
		var item: Dictionary = items.get(str(item_id),{})
		if str(item.get("effect","")) == "lifesteal": steal += float(item.get("amount",0))/100.0
	if steal > 0: health[id] = mini(_max_hp(id),int(health[id])+int(ceil(damage*steal)))

func _wall_packet() -> Array:
	var walls: Array = []
	for wall in ice_walls: walls.append([wall["pos"].x,wall["pos"].y,wall["time"]])
	return walls

func _simulate_charges(delta: float) -> void:
	for id in charges.keys():
		if int(health.get(id,0)) <= 0: charges.erase(id);continue
		var charge: Dictionary = charges[id]
		var travel := minf(float(charge["remaining"]),float(charge["speed"])*arena_world.objective.carrier_factor(str(id))*delta/maxf(.3,dev_magic.world_scale())*dev_magic.scale_for(str(id)))
		var origin: Vector2 = positions[id]
		positions[id] = _move_actor(origin,(charge["direction"] as Vector2)*travel)
		if id == my_id: local_pos = positions[id]
		charge["remaining"] = float(charge["remaining"])-travel
		_emit_effect({"pos":origin,"end":positions[id],"style":"line","radius":0.0,"time":0.18,"color":"#a6ddbb"})
		for n in range(opponents.size()-1,-1,-1):
			var foe: Dictionary = opponents[n]
			if positions[id].distance_to(foe["pos"]) < (70 if bool(foe["boss"]) else 53) and not (charge["hits"] as Array).has(int(foe.get("uid",0))):
				charge["hits"].append(int(foe.get("uid",0)));_hit_enemy(n,float(charge["damage"]),str(id))
		if mode=="battlegrounds":
			for key in battlegrounds.hostile(str(id)):
				var a:Dictionary=battlegrounds.actor(key)
				if _segment_near(origin,positions[id],a.pos,53) and not charge.players.has(key):charge.players.append(key);battlegrounds.damage(key,float(charge.damage),str(id))
		if mode in ["arena","battlegrounds"]:
			for other in adventure.combat.v59.target_points():
				if _rival(str(id),adventure.combat.v59.rival_id(str(other))) and positions[id].distance_to(adventure.combat.v59.target_position(str(other))) < 53 and not (charge["players"] as Array).has(other):
					charge["players"].append(other);_hurt(str(other),float(charge["damage"]),str(id))
		if float(charge["remaining"]) <= 0 or origin.distance_to(positions[id]) < travel*0.2: charges.erase(id)
		else: charges[id] = charge

func _chain_attack(id: String, origin: Vector2, target: Vector2, stats: Dictionary, damage: float) -> void:
	if stats.get("visual","")=="golf_ricochet":
		adventure.combat.golf.launch(id,origin,target,stats,damage);return
	if mode=="battlegrounds":
		var struck:Array=[];var previous:=origin
		for jump in int(stats.get("jumps",3)):
			var focus:Vector2=target if jump==0 else previous;var best:="";var nearest:float=float(stats.get("range",350)) if jump==0 else float(stats.get("jump_range",220))
			for key in adventure.combat.hostile(id):
				var a:Dictionary=adventure.combat.actor(key)
				if a.is_empty() or struck.has(key) or not a.alive:continue
				if jump==0 and origin.distance_to(a.pos)>float(stats.get("range",350)):continue
				var d:float=focus.distance_to(a.pos)
				if d<nearest and _clear_path(previous,a.pos):best=key;nearest=d
			if best.is_empty():break
			var end:Vector2=adventure.combat.actor(best).pos;struck.append(best);adventure.combat.damage(best,damage*pow(.8,jump),id)
			_emit_effect({"pos":previous,"end":end,"style":"line","time":.32,"color":str(stats.get("color","#edaa65"))});previous=end
		return
	if bool(stats.get("fork",false)):
		_fork_attack(id,origin,(target-origin).normalized(),stats,damage)
		return
	var previous := origin
	var hit_enemies: Array = []
	var hit_players: Array = []
	for jump in int(stats.get("jumps",3)):
		var foe_index := -1
		var player_id := ""
		var nearest := 145.0 if jump == 0 else float(stats.get("jump_range",220))
		var focus := target if jump == 0 else previous
		for n in opponents.size():
			var foe: Dictionary = opponents[n]
			if hit_enemies.has(int(foe.get("uid",0))) or (jump == 0 and origin.distance_to(foe["pos"]) > float(stats.get("range",350))): continue
			var distance: float = focus.distance_to(foe["pos"])
			if distance < nearest and _clear_path(previous,foe["pos"]): nearest = distance;foe_index = n
		if mode == "arena":
			for other in adventure.combat.v59.target_points():
				if not _rival(id,adventure.combat.v59.rival_id(str(other))) or hit_players.has(other) or (jump == 0 and origin.distance_to(adventure.combat.v59.target_position(str(other))) > float(stats.get("range",350))): continue
				var distance: float = focus.distance_to(adventure.combat.v59.target_position(str(other)))
				if distance < nearest and _clear_path(previous,adventure.combat.v59.target_position(str(other))): nearest = distance;player_id = str(other);foe_index = -1
		if foe_index < 0 and player_id.is_empty(): break
		var endpoint: Vector2 = adventure.combat.v59.target_position(player_id) if not player_id.is_empty() else opponents[foe_index]["pos"]
		_emit_effect({"pos":previous,"end":endpoint,"style":"line","time":0.32,"color":str(stats.get("color","#edaa65"))})
		if player_id.is_empty(): hit_enemies.append(int(opponents[foe_index].get("uid",0)));_hit_enemy(foe_index,damage*pow(0.8,jump),id)
		else: hit_players.append(player_id);_hurt(player_id,damage*pow(0.8,jump),id)
		previous = endpoint

func _descent_pool() -> Array[String]:
	var pool: Array[String] = []
	for id in ["bramble","bramble","bramble","bramble"]:
		if enemy_defs.has(id): pool.append(id)
	if floor_number >= 2 and enemy_defs.has("rusher"): pool.append("rusher")
	if floor_number >= 4 and enemy_defs.has("archer"): pool.append("archer")
	if floor_number >= 5:
		for id in ["imp","frostling"]:
			if enemy_defs.has(id): pool.append(id)
	if floor_number >= 7:
		for id in ["spore_thrower","ice_archer","glacier_hound"]:
			if enemy_defs.has(id): pool.append(id)
	if floor_number >= 9 and enemy_defs.has("void_seeker"): pool.append("void_seeker")
	if floor_number >= 12:
		for id in enemy_defs:
			if not bool(enemy_defs[id].get("expansion_only",false)) and not pool.has(str(id)): pool.append(str(id))
	if pool.is_empty():
		for id in enemy_defs:
			if not bool(enemy_defs[id].get("expansion_only",false)):pool.append(str(id))
	return pool

func _update_flames(delta: float) -> void:
	for n in range(flame_bursts.size()-1,-1,-1):
		var burst:Dictionary=flame_bursts[n];var id:=str(burst["owner"])
		burst["time"]-=delta;burst["tick"]-=delta
		if int(levels.get(id,1))<3:flame_bursts.remove_at(n);continue
		if float(burst["time"])<=0 or int(health.get(id,0))<=0:flame_bursts.remove_at(n);continue
		if float(burst["tick"])>0:continue
		if int(burst.get("ticks",0))<=0:flame_bursts.remove_at(n);continue
		burst["ticks"]=int(burst["ticks"])-1
		burst["tick"]=.18
		var origin:Vector2=positions[id];var aim:Vector2=last_aim if id==my_id else Vector2.from_angle(float(aim_angles.get(id,(burst["aim"] as Vector2).angle())))
		_emit_effect({"pos":origin,"end":origin+aim*150,"style":"line","radius":150.0,"time":.17,"color":"#ff9d45","cue":"flame"})
		for i in range(opponents.size()-1,-1,-1):
			var offset:Vector2=opponents[i]["pos"]-origin
			if offset.length()<float(burst.get("stats",{}).get("range",150)) and aim.dot(offset.normalized())>cos(deg_to_rad(float(burst.get("stats",{}).get("arc_degrees",55))*.5)) and _clear_path(origin,opponents[i]["pos"]):
				adventure.combat.burn_foe(opponents[i],id);_hit_enemy(i,float(burst["damage"]),id)
		if mode=="battlegrounds":
			for key in battlegrounds.hostile(id):
				var a:Dictionary=battlegrounds.actor(key);var offset:Vector2=a.pos-origin
				if offset.length()<float(burst.get("stats",{}).get("range",150)) and aim.dot(offset.normalized())>cos(deg_to_rad(float(burst.get("stats",{}).get("arc_degrees",55))*.5)) and _clear_path(origin,a.pos):adventure.combat.apply_status(key,"burn",10,id,2);battlegrounds.damage(key,float(burst.damage),id)
		if mode in ["arena","battlegrounds"]:
			for other in adventure.combat.v59.target_points():
				if not _rival(id,adventure.combat.v59.rival_id(str(other))):continue
				var offset:Vector2=adventure.combat.v59.target_position(str(other))-origin
				if offset.length()<float(burst.get("stats",{}).get("range",150)) and aim.dot(offset.normalized())>cos(deg_to_rad(float(burst.get("stats",{}).get("arc_degrees",55))*.5)) and _clear_path(origin,adventure.combat.v59.target_position(str(other))):
					adventure.combat.apply_status(adventure.combat.player_key(str(other)),"burn",10,id,2);_hurt(str(other),float(burst["damage"]),id)

func _stat(id: String, key: String, amount: float) -> void:
	if mode=="descent" and floor_number>100:return
	if key=="damage" and amount>0 and spectator_director!=null and positions.has(id):spectator_director.record_damage(positions[id],amount)
	if key=="damage" and id==my_id and positions.has(id) and not practice_match():legacy.add_damage(str(hero_ids.get(id,selected_hero)),amount)
	if id.is_empty() or id=="enemy" or not positions.has(id):return
	if not contributions.has(id):contributions[id]={"damage":0.0,"healing":0.0,"revives":0,"defence":0,"upgrades":0}
	contributions[id][key]=float(contributions[id].get(key,0))+amount
func _heal(buyer: String, target: String, amount: int, ability_heal:bool=true) -> void:
	if int(health.get(target,0))<=0:return
	var old:=int(health[target]);health[target]=mini(_max_hp(target),old+int(round(amount*adventure.combat.v98.heal_factor(target))))
	if int(health[target])>old:
		adventure.combat.feedback.hit(positions.get(target,Vector2.ZERO),int(health[target])-old,target,true)
		adventure.combat.feedback.healed(target,positions.get(target,Vector2.ZERO),int(health[target])-old)
		_emit_effect({"pos":positions.get(target,Vector2.ZERO),"style":"heal_contact","victim":target,"amount":int(health[target])-old,"time":.18,"color":"#a0eab1"})
	if ability_heal:_stat(buyer,"healing",int(health[target])-old)
func _near_downed(id: String) -> bool:
	for other in downed:
		if other!=id and (positions.get(id,Vector2.ZERO) as Vector2).distance_to(positions.get(other,Vector2.ZERO))<110:return true
	return false
func _update_revives(delta: float) -> void:
	revive_held[my_id]=Input.is_action_pressed("interact")
	for fallen in downed.keys():
		var state:Dictionary=downed[fallen]
		state["left"]-=delta
		if float(state["left"])<=0:
			downed.erase(fallen)
			if mode=="defense":respawn_at[fallen]=Time.get_ticks_msec()+5000
			continue
		var rescuer:=""
		for id in positions:
			if str(id)==str(fallen) or int(health.get(id,0))<=0 or not bool(revive_held.get(id,false)):continue
			if (positions[id] as Vector2).distance_to(positions[fallen])<=110 and _clear_path(positions[id],positions[fallen]):rescuer=str(id);break
		if rescuer=="":state["progress"]=0.0;state["rescuer"]="";continue
		if str(state.get("rescuer",""))!=rescuer:state["progress"]=0.0
		state["rescuer"]=rescuer;state["progress"]=float(state.get("progress",0))+delta
		if float(state["progress"])>=2.0:
			health[fallen]=maxi(25,int(_max_hp(str(fallen))*.35));invincible_until[fallen]=Time.get_ticks_msec()+2000
			downed.erase(fallen);_stat(rescuer,"revives",1)
			if rescuer==my_id:journey.revived()
			else:_send_channel(rescuer,{"type":"revive_reward"})
			_emit_effect({"pos":positions[fallen],"radius":65.0,"time":.6,"color":"#a1edb1","cue":"reward"})
func adventure_won(reason:String)->bool:
	if mode=="battlegrounds":return battlegrounds.winner==int(teams.get(my_id,-1))
	return mode=="coop" and ("cleared" in reason.to_lower() or "restored" in reason.to_lower() or "freed" in reason.to_lower() or adventure.quests.active and adventure.quests.completed_count()==adventure.quests.data.get("quests",[]).size())

func end_match(reason: String) -> void:
	if not started:return
	if mode=="arena":
		for id in positions:arena_outcomes[id]="interrupted" if "interrupted" in reason.to_lower() else _arena_outcome(str(id))
	started=false;shop_open="";results_reason=reason;status_label.text=reason
	if not spectating() and ("cleared" in reason.to_lower() or "restored" in reason.to_lower()):journey.won(realm_id);provisions.complete_adventure()
	legacy_results()
	if spectating():
		presentation.window(mode.to_upper()+" RESULTS • BROADCAST", "results")
		presentation.label(presentation.content,reason,24);presentation.team_results()
	else:presentation.results(adventure_won(reason) or mode=="arena" and str(arena_outcomes.get(my_id,"draw"))=="win")
	if role=="host":
		if server_matchmaking: _send_ws({"type":"room_update","started":false})
		if _has_open_link():_broadcast(_snapshot())
func _draw_results(font: Font) -> void:
	if presentation!=null and presentation.page=="results":return
	if results_reason.is_empty():return
	draw_rect(Rect2(160,225,960,360),Color(.025,.075,.11,.97))
	draw_string(font,Vector2(190,265),results_reason,HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("#ecd9a2"))
	draw_string(font,Vector2(190,305),"PLAYER",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#a9d1d0"))
	for n in 5:draw_string(font,Vector2(470+n*122,305),["DAMAGE","ABILITY HEAL","REVIVES","DEFENCE","UPGRADES"][n],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#a9d1d0"))
	var row:=0
	for player in roster:
		var id:=str(player.get("id",""));var stats:Dictionary=contributions.get(id,{})
		var y:=345+row*46
		draw_string(font,Vector2(190,y),str(player.get("name","Player")),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color.WHITE)
		for n in 5:draw_string(font,Vector2(470+n*122,y),str(int(stats.get(["damage","healing","revives","defence","upgrades"][n],0))),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#e9deb9"))
		row+=1
	draw_string(font,Vector2(190,525),legacy.result_line(str(hero_ids.get(my_id,selected_hero))),HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#ffe5ab"))
	draw_string(font,Vector2(190,552),"Every role counts. Host can start again, or use TOWN above.",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#c8d7d4"))

func _fork_attack(id: String, origin: Vector2, direction: Vector2, stats: Dictionary, damage: float) -> void:
	var hit_foes: Array[int] = []
	var hit_players: Array[String] = []
	for bolt in mini(3,int(stats.get("jumps",3))):
		var foe_index := -1
		var player_id := ""
		var nearest := float(stats.get("range",350))
		for n in opponents.size():
			var offset: Vector2 = opponents[n]["pos"]-origin
			if hit_foes.has(int(opponents[n].get("uid",0))) or offset.normalized().dot(direction)<.25: continue
			if offset.length()<nearest and _clear_path(origin,opponents[n]["pos"]): nearest=offset.length();foe_index=n
		if mode == "arena":
			for other in adventure.combat.v59.target_points():
				var offset: Vector2 = adventure.combat.v59.target_position(str(other))-origin
				if not _rival(id,adventure.combat.v59.rival_id(str(other))) or hit_players.has(str(other)) or offset.normalized().dot(direction)<.25: continue
				if offset.length()<nearest and _clear_path(origin,adventure.combat.v59.target_position(str(other))): nearest=offset.length();player_id=str(other);foe_index=-1
		if foe_index<0 and player_id.is_empty(): break
		var end: Vector2 = opponents[foe_index]["pos"] if player_id.is_empty() else adventure.combat.v59.target_position(player_id)
		_emit_effect({"pos":origin,"end":end,"style":"lightning","time":.32,"color":str(stats.get("color","#b8daff"))})
		if player_id.is_empty(): hit_foes.append(int(opponents[foe_index].get("uid",0)));_hit_enemy(foe_index,damage,id)
		else: hit_players.append(player_id);_hurt(player_id,damage,id)

func _update_fountains(delta:float)->void:
	if mode!="defense" or role!="host":return
	fountain_tick+=delta
	if fountain_tick<1:return
	fountain_tick=fmod(fountain_tick,1)
	for id in positions:
		for spring in world_fountains:
			if (positions[id] as Vector2).distance_to(spring)<135:
				_heal(str(id),str(id),3,false);break

func legacy_results()->void:
	if preload("res://scripts/profile_store.gd").progression_blocked():return
	if dev_magic.quarantine:return
	if spectating():return
	if practice_match():bots.practice_progress();legacy.save();return
	if legacy_result_recorded or results_reason.is_empty():return
	legacy_result_recorded=true
	if bool(legacy.card.cursor(match_id).get("done",false)):return
	get_tree().root.get_node("FXActivity").event(self,"complete",str(arena_outcomes.get(my_id,"draw")) if mode=="arena" else "cleared" if adventure_won(results_reason) else "returned" if get("realm_result")=="returned" else "defeated",run_time,{"damage":float(contributions.get(my_id,{}).get("damage",0)),"players":match_party_size,"floor":floor_number,"wave":defense_cleared_wave},match_id)
	var hero_id:String=str(hero_ids.get(my_id,selected_hero))
	_track_card_progress()
	if mode=="arena":legacy.card.arena_result(match_id,arena_random,str(arena_outcomes.get(my_id,"draw")))
	if mode=="battlegrounds":legacy.cosmetics.competitive.result(match_id,"win" if battlegrounds.winner==int(teams.get(my_id,-1)) else "loss")
	if mode=="coop" and adventure_won(results_reason) and not (get("expedition")!=null and get("expedition").special()):
		legacy.clear_adventure(hero_id,realm_id)
		if realm_id=="confluence" and match_party_size>=2 and hero_id in ["tidewright","cantor"] and hero_ids.values().has("tidewright") and hero_ids.values().has("cantor"):
			legacy.record(hero_id)["duet_clear"]=true
		if match_party_size>=2:legacy.card.coop_clear(realm_id)
	elif mode=="descent" or mode=="defense":
		if floor_number>=3 or wave>=5:legacy.clear_adventure(hero_id,"descent" if mode=="descent" else "defense")
	if mode!="arena":legacy.card.finish_cursor(match_id)
	_refresh_realm_stars();legacy.save()

func _random_build_payload()->Dictionary:
	var result:Dictionary={}
	for id in characters:
		if not bool(characters[id].get("npc_only",false)):result[id]=legacy.payload(str(id))
	return result
func _update_lobby_settings()->void:
	if started or role!="host":return
	if not allow_custom:
		for id in hero_ids:
			if str(hero_ids[id]).begins_with("custom_"):
				allow_custom=true;custom_picker.set_pressed_no_signal(true);status_label.text="Choose official heroes before turning custom builds off.";return
	var humans:=0
	for member in roster:
		if not bots.is_bot(str(member.id)):humans+=1
	if mode=="arena":
		var fighters_count:=humans-(1 if spectator_host else 0)
		bot_count=mini(bot_count,8-fighters_count)
		arena_seats=maxi(arena_seats,fighters_count+bot_count)
		_sync_arena_pickers()
	if spectating():positions.erase(my_id);health.erase(my_id)
	elif not positions.has(my_id):_add_player(my_id,0)
	bots.sync_lobby()
	_send_arena_rules();_send_lobby_state()

func _send_arena_rules()->void:
	if role!="host" or started:return
	_send_ws({"type":"room_update","settings":_room_command("settings")})
	for id in links:_send_channel(str(id),{"type":"arena_rules","no_items":arena_no_items,"random_heroes":arena_random,"seats":arena_seats,"spectator":spectator_host,"bots":bot_count,"ai_difficulty":ai_difficulty,"opening":arena_opening,"arena_map":arena_map,"allow_custom":allow_custom})
func _arena_outcome(id:String)->String:
	if arena_world.shatter.active():return arena_world.shatter.outcome(id)
	if arena_world.objective.active():return arena_world.objective.outcome(id)
	if pvp_rule=="teams":
		var scores:Dictionary={0:0,1:0}
		for player in positions:scores[int(teams.get(player,0))]+=int(pvp_scores.get(player,0))
		if scores[0]==scores[1]:return "draw"
		return "win" if int(teams.get(id,0))==(0 if scores[0]>scores[1] else 1) else "loss"
	var high:=0;var tied:=0
	for player in positions:high=maxi(high,int(pvp_scores.get(player,0)))
	for player in positions:
		if int(pvp_scores.get(player,0))==high:tied+=1
	if int(pvp_scores.get(id,0))<high:return "loss"
	return "win" if tied==1 else "draw"
func _track_card_progress()->void:
	if dev_magic.quarantine:return
	if spectating():return
	if practice_match():bots.practice_progress();return
	if my_id.is_empty() or match_id.is_empty():return
	if mode=="defense" and role=="host":
		var first:=wave+1
		for foe in opponents:
			if bool(foe.get("campaign_hero",false)):continue
			if not foe.has("defense_wave"):foe["defense_wave"]=wave
			first=mini(first,int(foe.defense_wave))
		var clear_candidate:=maxi(0,mini(wave,first-1))
		if north_gate.boss_spawned and not north_gate.boss_defeated:clear_candidate=mini(clear_candidate,29)
		var previous_clear:=defense_cleared_wave
		defense_cleared_wave=maxi(defense_cleared_wave,clear_candidate)
		if previous_clear<30 and defense_cleared_wave>=30:
			status_label.text="NORTH GATE SECURED • Wave-30 boss defeated. Town bastion earned!"
			_emit_effect({"pos":GATE,"radius":210.0,"time":1.2,"color":"#ffe4a4"})
			wave_timer=maxf(wave_timer,12)
	legacy.card.sync_match(match_id,mode,arena_random,str(hero_ids.get(my_id,selected_hero)),arena_records.get(my_id,{}),float(contributions.get(my_id,{}).get("damage",0)),role=="guest")
	if mode=="defense":legacy.card.wave_cleared(defense_cleared_wave,match_party_size)
	if mode=="descent":legacy.card.descent_cleared(mini(100,maxi(0,floor_number-1)),match_party_size)

func _lobby_packet()->Dictionary:
	var players:Array=[]
	for member in roster:
		var id:=str(member.get("id",""));players.append({"id":id,"name":str(member.get("name","Player")),"hero":str(hero_ids.get(id,"")) if id==my_id or lobby_heroes.has(id) else "","team":int(teams.get(id,-1)),"cosmetic":cosmetic_for(id)})
	return {"type":"lobby","mode":mode,"realm":str(realm_picker.get_item_metadata(realm_picker.selected)),"bg_map":bg_map,"bg_team_size":bg_team_size,"players":players,"rule":rule_picker.selected,"no_items":arena_no_items,"random_heroes":arena_random,"seats":arena_seats,"spectator":spectator_host,"bots":bot_count,"ai_difficulty":ai_difficulty,"opening":arena_opening,"arena_map":arena_map,"allow_custom":allow_custom}
func _send_lobby_state()->void:
	if role!="host" or started:return
	var packet:=_lobby_packet()
	_broadcast(packet)
func _receive_lobby(data:Dictionary)->void:
	allow_custom=bool(data.get("allow_custom",false));custom_picker.set_pressed_no_signal(allow_custom)
	if str(data.get("mode",mode)) in ["arena","defense","coop","descent","battlegrounds"]:mode=str(data.get("mode",mode))
	for index in realm_picker.item_count:
		if str(realm_picker.get_item_metadata(index))==str(data.get("realm","")):realm_picker.select(index);break
	bg_map=str(data.get("bg_map","woodland"));bg_team_size=clampi(int(data.get("bg_team_size",4)),3,4);_sync_bg_pickers()
	if not data.has("players") or not data.players is Array or data.players.size()>9:return
	var next:Array[Dictionary]=[]
	for member in data.players:
		if not member is Dictionary:return
		var id:=str(member.get("id",""));var hero:=str(member.get("hero",""));var side:=int(member.get("team",-1))
		if id.is_empty() or side not in [-1,0,1]:return
		next.append({"id":id,"name":str(member.get("name","Player")).left(18)})
		teams[id]=side
		if member.get("cosmetic",{}) is Dictionary:player_cosmetics[id]=member.get("cosmetic",{})
		if characters.has(hero):hero_ids[id]=hero
	roster.assign(next);rule_picker.select(clampi(int(data.get("rule",0)),0,1))
	arena_seats=clampi(int(data.get("seats",4)),2,8);spectator_host=bool(data.get("spectator",false));ai_difficulty=bots.difficulty(data.get("ai_difficulty","medium"));bot_count=clampi(int(data.get("bots",0)),0,mini(7,arena_seats-1));arena_opening=bool(data.get("opening",false));arena_map=str(data.get("arena_map","sand"));_sync_arena_pickers();arena_no_items=bool(data.get("no_items",false));arena_random=bool(data.get("random_heroes",false));no_items_picker.set_pressed_no_signal(arena_no_items);random_hero_picker.set_pressed_no_signal(arena_random)

func _teams_ready()->bool:
	var silver:=0;var blue:=0
	for id in positions:
		if int(teams.get(id,-1))==0:silver+=1
		elif int(teams.get(id,-1))==1:blue+=1
	return silver>0 and silver==blue and silver<=4 and silver+blue==fighters().size()

func _refresh_realm_stars()->void:
	for index in realm_picker.item_count:
		var id:=str(realm_picker.get_item_metadata(index));realm_picker.set_item_text(index,("LOCKED • " if not preload("res://scripts/realm_access.gd").unlocked(legacy,str(id)) else "")+str(regions.get(id,{}).get("name",id)))
		realm_picker.set_item_icon(index,preload("res://scripts/ui_reward_icons.gd").texture() if legacy.realm_mastered(id) else null)

func _broadcast(data:Dictionary)->void:
	if not _has_open_link():return
	if str(data.get("type",""))=="state":transport.broadcast_state(data);return
	var bytes:=JSON.stringify(data).to_utf8_buffer()
	var stability=get_node_or_null("/root/FXStability")
	if stability!=null:stability.last_packet_bytes=bytes.size()
	for id in links:
		var channel:WebRTCDataChannel=links[id]["channel"]
		if channel.get_ready_state()==WebRTCDataChannel.STATE_OPEN:
			var queued:=channel.get_buffered_amount()
			if stability!=null:stability.buffered_bytes=maxi(stability.buffered_bytes,queued)
			if _defer_state(data,queued):
				if stability!=null:stability.deferred_states+=1
				continue
			var error:=channel.put_packet(bytes)
			if stability!=null:
				stability.packets_sent+=1
				if error!=OK:stability.send_errors+=1

func _defer_state(data:Dictionary,buffered:int)->bool:
	return str(data.get("type",""))=="state" and bool(data.get("active",false)) and buffered>524288

func _segment_near(start:Vector2,end:Vector2,point:Vector2,radius:float)->bool:
	var segment:=end-start
	var t:=clampf((point-start).dot(segment)/maxf(.001,segment.length_squared()),0,1)
	return point.distance_to(start+segment*t)<radius

func _sync_arena_pickers()->void:
	difficulty_picker.select(["easy","medium","hard"].find(ai_difficulty));bots_picker.select(bot_count);seats_picker.select(clampi(arena_seats-2,0,6));spectator_picker.set_pressed_no_signal(spectator_host)
	opening_picker.set_pressed_no_signal(arena_opening)
	for n in arena_map_picker.item_count:
		if str(arena_map_picker.get_item_metadata(n))==arena_map:arena_map_picker.select(n)

func spectating()->bool:return spectator_supported() and spectator_host and my_id==host_id and not my_id.is_empty()
func fighters()->Array[Dictionary]:
	var list:Array[Dictionary]=[]
	for member in roster:
		if spectator_supported() and spectator_host and str(member.get("id",""))==host_id:continue
		list.append(member)
	return list
func spectator_supported()->bool:return mode in ["arena","battlegrounds","descent"]
func player_limit()->int:
	return bg_team_size*2 if mode=="battlegrounds" else arena_seats if mode=="arena" else 3 if mode=="defense" else 2 if mode=="coop" and str(realm_picker.get_item_metadata(realm_picker.selected))=="wayfarer" else 4
func _draw_countdown(_font:Font)->void:
	# The screen-space CanvasLayer displays this above all lobby/world controls.
	pass
func _draw_broadcast(font:Font)->void:
	draw_rect(Rect2(0,0,VIEW.x,75),Color("#12232e"))
	draw_string(font,Vector2(VIEW.x-310,58),"Esc: leave broadcast",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#bdd5df"))
	if shop_open=="Travel":draw_string(font,Vector2(22,80),"Enter: return to town / Esc: keep watching",HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color("#ffcc88"))
	draw_string(font,Vector2(22,30),"CROSSROADS: REALMS BEYOND  •  LIVE "+("BATTLEGROUNDS" if mode=="battlegrounds" else "DESCENT" if mode=="descent" else "ARENA"),HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("#ffe0a1"))
	var subtitle:String="Floor "+str(floor_number)+" • CO-OP SURVIVAL" if mode=="descent" else str(battlegrounds.MAPS.get(bg_map,bg_map))+" • TEAM BATTLE" if mode=="battlegrounds" else str(arena_world.MAPS.get(arena_map,"Arena"))+" • "+("TEAM BATTLE" if pvp_rule=="teams" else "FREE FOR ALL")+" • %d:%02d remaining" % [int(maxf(0,300-run_time))/60,int(maxf(0,300-run_time))%60]
	if arena_world.shatter.active():subtitle=arena_world.shatter.header()
	draw_string(font,Vector2(22,58),subtitle,HORIZONTAL_ALIGNMENT_LEFT,VIEW.x-350,17,Color("#bdd5df"))
	if mode=="arena" and pvp_rule=="teams":
		var tally:Dictionary={0:0,1:0}
		for id in positions:tally[int(teams.get(id,0))]+=int(pvp_scores.get(id,0))
		if arena_world.shatter.active():
			var score=arena_world.shatter.totals();tally={0:int(score.get("team:0",0)),1:int(score.get("team:1",0))}
		draw_string(font,Vector2(720,30),"SILVER %d   :   %d BLUE" % [tally[0],tally[1]],HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#b4d8f5"))
	var active:=fighters();var width:float=(VIEW.x-24)/maxi(1,active.size())
	for n in active.size():
		var member:Dictionary=active[n];var id:=str(member.id);var x:float=12+n*width;var y:float=VIEW.y-88
		var tint:=Color("#74c8ff") if int(teams.get(id,0))==1 and pvp_rule=="teams" else Color("#e4d2a4")
		draw_rect(Rect2(x,y,width-5,78),Color("#1c3340"))
		draw_string(font,Vector2(x+7,y+20),str(n+1)+" "+str(member.name).left(14),HORIZONTAL_ALIGNMENT_LEFT,width-14,15,tint)
		var player_summary=(str(int(pvp_scores.get(id,0)))+" KOs" if mode=="arena" else str(int(contributions.get(id,{}).get("damage",0)))+" DMG")+" • "+str(int(health.get(id,0)))+" HP"
		if arena_world.shatter.active():player_summary="%d PTS • %s" % [int(arena_world.shatter.points.get(id,0)),"OUT" if arena_world.shatter.eliminated.has(id) else "FLOOR %d" % (int(arena_world.shatter.layers.get(id,0))+1)]
		draw_string(font,Vector2(x+7,y+42),player_summary,HORIZONTAL_ALIGNMENT_LEFT,width-14,14,Color.WHITE)
		draw_rect(Rect2(x+7,y+55,(width-19)*clampf(float(health.get(id,0))/maxf(1,_max_hp(id)),0,1),7),Color("#85dcb0"))
		if positions.has(id):
			var p:Vector2=broadcast_offset+((remote_draw_pos.get(id,positions[id]) as Vector2)-camera)*broadcast_scale
			draw_arc(p,12,0,TAU,20,tint,2,true)
			draw_string(font,p+Vector2(-5,-17),str(n+1),HORIZONTAL_ALIGNMENT_LEFT,-1,16,tint)

func world_transform(p:Vector2=Vector2.ZERO,angle:float=0,zoom:Vector2=Vector2.ONE)->void:
	draw_set_transform(broadcast_offset+p*broadcast_scale if spectating() else media.offset()+p*media.factor(),angle,zoom*broadcast_scale if spectating() else zoom*media.factor())

func practice_match()->bool:return mode=="arena" and bot_count>0

func _sync_bg_pickers()->void:
	if not is_instance_valid(bg_map_picker):return
	bg_size_picker.select(bg_team_size-3)
	for n in bg_map_picker.item_count:
		if str(bg_map_picker.get_item_metadata(n))==bg_map:bg_map_picker.select(n)

func update_arena_notice(delta:float)->void:
	if not started or mode!="arena" or start_countdown>0:arena_notice_last="";arena_notice_left=0;return
	if status_label.text!=arena_notice_last:arena_notice_last=status_label.text;arena_notice_left=5
	else:arena_notice_left=maxf(0,arena_notice_left-delta)

func visual_actor(key:String,point:Vector2)->Vector2:
	return smoothing.sample(key,point,Time.get_ticks_msec()/1000.0,.06) if role=="guest" else point

func _reconcile_position(ack:int,point:Vector2)->void:
	if ack<=0 or not position_history.has(ack):return
	var correction:Vector2=point-(position_history[ack] as Vector2)
	# Only repair a rejected/colliding movement path; retain movement since the ACK.
	if correction.length()>4 and correction.length()<180 and int(health.get(my_id,0))>0:
		local_pos=_move_actor(local_pos,correction)
	for seq in position_history.keys():
		if int(seq)<=ack:position_history.erase(seq)

func local_cosmetic()->Dictionary:
	var session:Node=get_tree().root.get_node_or_null("FXDevSession")
	var testing:bool=session!=null and bool(session.active)
	var identity_flags=custom_party.flags(my_id);identity_flags.media=media.active;identity_flags.playtest=get_tree().root.get_node("FXResearch").active
	var result={"crown_damage":legacy.crowns.payload().crown_damage,"crown_tier":legacy.crowns.payload().crown_tier,"crown_best":legacy.crowns.payload().crown_best,"crown_expiry":legacy.crowns.payload().crown_expiry,"custom":identity_flags.custom,"balanced":identity_flags.balanced,"media":identity_flags.media,"playtest":identity_flags.playtest,"colour":journey.ribbon().to_html(),"title":"GAME DEV" if testing else str(journey.data.get("title","Traveler")),"game_dev":testing,"daily_date":legacy.daily.cosmetic_date() if legacy.cosmetics.daily_visible() else "","extra_effect":legacy.cosmetics.effect(),"weekly_week":legacy.cosmetics.effect_week(legacy.cosmetics.effect())}
	result.merge(legacy.cosmetics.rankings.display_payload());return result
func cosmetic_for(id:String)->Dictionary:
	var value:Dictionary=(local_cosmetic() if id==my_id else player_cosmetics.get(id,{})).duplicate(true)
	value.merge(custom_party.flags(id),true)
	return value

func assign_base_camera()->void:
	camera=(arena_world.shatter.camera_point(local_pos)-VIEW*.5).clamp(Vector2.ZERO,(FIELD.size-VIEW).max(Vector2.ZERO))

func _open_hero_grid()->void:
	if started or spectating() or is_instance_valid(hero_grid):return
	hero_grid=preload("res://scripts/hero_grid.gd").new()
	hero_grid.open(self,selected_hero,_grid_select,_grid_permission)
func _grid_permission(id:String)->String:
	if started or spectating():return "Hero selection is unavailable during a match or while spectating."
	if id.begins_with("custom_") and not custom_party.allowed(custom_party.project_for(id)):return "Enable custom heroes; all multiplayer rooms require Forced Balance."
	return ""
func _grid_select(id:String)->bool:
	if not _grid_permission(id).is_empty():return false
	for index in hero_picker.item_count:
		if str(hero_picker.get_item_metadata(index))==id:
			hero_picker.select(index);party_tools.change_hero(index);return selected_hero==id
	return false

func _projectile_near_player(start:Vector2,finish:Vector2,actor:String,radius:float)->bool:
	return _segment_near(start,finish,positions[actor],radius)

func _actor_walking(id:String)->bool:
	return id != my_id or Input.get_vector("move_left","move_right","move_up","move_down").length_squared() > 0 or dodge_time > 0 or charges.has(id)

func _profile_section(kind:String,began:int)->void:
	if has_method("profile_work"):call("profile_work",kind,Time.get_ticks_usec()-began)

func _player_draw_position(id:String,fallback:Vector2)->Vector2:
	return local_pos if id==my_id else remote_draw_pos.get(id,positions.get(id,fallback))
