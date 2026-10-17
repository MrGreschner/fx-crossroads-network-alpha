extends RefCounted
const MODES=[["Gate Defence","defense"],["Gladiator Arena","arena"],["Co-op Realms","coop"],["Ram’s Descent","descent"],["Battlegrounds","battlegrounds"]]
static func label(parent:Node,value:String,fs:int=16)->Label:
 var node=Label.new();node.text=value;node.add_theme_font_size_override("font_size",fs);parent.add_child(node);return node
static func button(parent:Node,value:String,action:Callable)->Button:
 var node=Button.new();node.text=value;node.custom_minimum_size.y=38;node.size_flags_horizontal=Control.SIZE_EXPAND_FILL;node.add_theme_font_size_override("font_size",16);parent.add_child(node);node.pressed.connect(action);return node
static func field(parent:Node,value:String,hint:String)->LineEdit:
 var node=LineEdit.new();node.text=value;node.placeholder_text=hint;node.custom_minimum_size.y=38;node.add_theme_font_size_override("font_size",16);node.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(node);return node
static func build(g:Node)->void:
 var layer=CanvasLayer.new();layer.layer=100;g.add_child(layer)
 g.net_panel=PanelContainer.new();g.net_panel.name="NetworkPartyLobby";layer.add_child(g.net_panel);preload("res://scripts/studio_ui.gd").apply(g.net_panel)
 var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;g.net_panel.add_child(scroll);preload("res://scripts/touch_list_scroll.gd").attach(scroll)
 var body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",8);scroll.add_child(body)
 var header=HBoxContainer.new();body.add_child(header)
 var heading=label(header,"GATHER YOUR PARTY",25);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var back=button(header,"Back to town",func():
  g._leave_room_connection();g.get_tree().root.set_meta("fx_hero",g.selected_hero);g.get_tree().change_scene_to_file("res://scenes/main.tscn"))
 back.size_flags_horizontal=Control.SIZE_SHRINK_END;back.custom_minimum_size.x=150
 var main=HBoxContainer.new();main.add_theme_constant_override("separation",16);body.add_child(main)
 var left=VBoxContainer.new();left.custom_minimum_size.x=230;main.add_child(left)
 label(left,"CHOOSE YOUR ADVENTURE",14)
 # A hidden picker preserves one source of truth for room replication.
 var modes=OptionButton.new();modes.name="NetworkModes";body.add_child(modes);modes.hide()
 for entry in MODES:modes.add_item(entry[0]);modes.set_item_metadata(modes.item_count-1,entry[1])
 for entry in MODES:
  var mode_button=button(left,entry[0],func():g.select_network_mode(str(entry[1])));mode_button.name="Mode_"+str(entry[1]);mode_button.custom_minimum_size.y=43
 var summary=label(left,"Your hero, your progress.\nShare a room code or browse\npublic parties below.",14);summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var right=VBoxContainer.new();right.size_flags_horizontal=Control.SIZE_EXPAND_FILL;main.add_child(right)
 var identity=HBoxContainer.new();right.add_child(identity)
 g.net_name=field(identity,str(g.legacy.data.get("name","Traveller")),"Display name");g.net_name.name="NetworkName";g.net_name.max_length=24
 g.hero_button=button(identity,"Choose hero",func():
  if is_instance_valid(g.hero_grid):return
  g.hero_grid=preload("res://scripts/hero_grid.gd").new();g.hero_grid.open(g,g.selected_hero,g.net_select,g.net_permission))
 var stage=preload("res://network/party_stage.gd").new();stage.name="PartyStage";stage.game=g;stage.custom_minimum_size=Vector2(0,155);right.add_child(stage)
 var settings=HBoxContainer.new();right.add_child(settings)
 g.capacity=OptionButton.new();g.capacity.size_flags_horizontal=Control.SIZE_EXPAND_FILL;settings.add_child(g.capacity)
 for number in [2,4,6,8]:g.capacity.add_item(str(number)+" player seats",number)
 g.capacity.select(1);g.capacity.item_selected.connect(g._capacity_changed)
 g.public_toggle=CheckButton.new();g.public_toggle.text="Public room";g.public_toggle.button_pressed=true;settings.add_child(g.public_toggle);g.public_toggle.toggled.connect(func(value:bool):
  if g.net_ready and g.net_host:g.send_net({"type":"visibility","public":value}))
 g.competition_toggle=CheckButton.new();g.competition_toggle.name="CompetitionRules";g.competition_toggle.text="Competition • crown bonuses OFF for everyone";right.add_child(g.competition_toggle);g.competition_toggle.toggled.connect(func(value:bool):
  if g.net_ready and g.net_host:g.send_net({"type":"competition","enabled":value}))
 g.test_arena=OptionButton.new();g.test_arena.add_item("Arena • players only",0);g.test_arena.add_item("Gladiator • players + enemies",1);right.add_child(g.test_arena);g.test_arena.item_selected.connect(g._test_arena_changed)
 var realms=OptionButton.new();realms.name="NetworkRealms";right.add_child(realms)
 for id in g.RealmCatalogue.lobby_ids():
  realms.add_item({"between":"The Between • shared expedition","overcharge":"Today’s overcharged realm"}.get(id,str(g.regions.get(id,{}).get("name",id))));realms.set_item_metadata(realms.item_count-1,id)
  var reason=g.ExpeditionProfile.progress(g).entry_issue(str(id)) if id in ["between","overcharge","attunement"] else preload("res://scripts/realm_access.gd").reason(g.legacy,str(id))
  realms.set_item_disabled(realms.item_count-1,not reason.is_empty());realms.get_popup().set_item_tooltip(realms.item_count-1,reason)
 realms.item_selected.connect(func(i:int):g.realm_id=str(realms.get_item_metadata(i));g._sync_network_mode_controls())
 g.realm_id=str(g.get_meta("requested_network_realm","grove"))
 if g.realm_id not in g.RealmCatalogue.available(g.legacy):g.realm_id="grove"
 realms.select(g.RealmCatalogue.lobby_ids().find(g.realm_id))
 g.expedition_tier=OptionButton.new();g.expedition_tier.name="ExpeditionTier";right.add_child(g.expedition_tier)
 for n in 3:g.expedition_tier.add_item("Overcharge tier %d • %d shards EACH" % [n+1,preload("res://scripts/waylight_catalog.gd").COSTS[n]],n+1)
 g.expedition_tier.select(clampi(int(g.get_tree().root.get_meta("fx_expedition_tier",1))-1,0,2))
 g.bg_network_map=OptionButton.new();g.bg_network_map.name="BattlegroundMap";right.add_child(g.bg_network_map)
 for id in ["woodland","warzone"]:g.bg_network_map.add_item(str(g.battlegrounds.MAPS[id]));g.bg_network_map.set_item_metadata(g.bg_network_map.item_count-1,id)
 g.bg_network_map.item_selected.connect(func(i:int):
  g.bg_map=str(g.bg_network_map.get_item_metadata(i))
  if g.net_ready and g.net_host:g.send_net({"type":"bg_choice","bg_map":g.bg_map}))
 g.bg_team_controls=HBoxContainer.new();right.add_child(g.bg_team_controls)
 for side in 2:button(g.bg_team_controls,"Join "+str(g.battlegrounds.FACTIONS[side]),func():g.send_net({"type":"team","team":side}))
 g.bg_team_roster=label(right,"");g.bg_team_roster.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var connection=HBoxContainer.new();body.add_child(connection)
 g.room_field=field(connection,"","Room code");g.room_field.name="NetworkRoomCode";g.room_field.max_length=6
 button(connection,"Host room",g.connect_net.bind("host")).name="HostRoom"
 button(connection,"Join room",g.connect_net.bind("join")).name="JoinRoom"
 g.net_start=button(connection,"Start match",func():g.send_net({"type":"start"}));g.net_start.name="StartMatch";g.net_start.disabled=true
 button(connection,"Leave room",g.return_to_network_menu).name="LeaveRoom"
 g.net_status=label(body,"Choose your adventure, then host or join a party.",14);g.net_status.name="NetworkStatus";g.net_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 var room_heading=HBoxContainer.new();body.add_child(room_heading);var title=label(room_heading,"PUBLIC ROOMS",16);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var refresh=button(room_heading,"Refresh rooms",g.browse_rooms);refresh.name="RefreshRooms";refresh.size_flags_horizontal=Control.SIZE_SHRINK_END;refresh.custom_minimum_size.x=150
 g.room_listing=VBoxContainer.new();g.room_listing.name="RoomListing";body.add_child(g.room_listing);label(g.room_listing,"Select Refresh rooms to find a party.",14)
 # Address is configuration, never a required student input.
 g.url_field=LineEdit.new();g.url_field.name="NetworkEndpoint";g.url_field.text=g.DEFAULT_SERVER;body.add_child(g.url_field);g.url_field.hide()
 for edit in [g.net_name,g.room_field]:
  var typing=preload("res://scripts/mobile_text_entry.gd").new();edit.add_child(typing);typing.setup(edit,"done")
 g.net_select(g.selected_hero);g.select_network_mode(g.mode);g.call_deferred("browse_rooms")
