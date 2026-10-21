extends "res://scripts/arcade.gd"
## Arena vertical slice: original combat, dedicated authority, independent rendering.
const BUILD=preload("res://network/release.gd").BUILD
const PROTOCOL=11
const ExpeditionProfile=preload("res://network/expedition_profile.gd")
var expedition=preload("res://network/expeditions.gd").new()
var expedition_tier:OptionButton
var expedition_offer={}
var font=preload("res://assets/fonts/CrossroadsUI.ttf")
var selected_character:String:
 get:return selected_hero
var position_in_world:Vector2:
 get:return local_pos
var balanced_graphics=true
var render_budget=preload("res://network/render_budget.gd").new()
var server_metrics:Dictionary={}
var gateway_metrics:Dictionary={}
var recovery_stalls=0
var recovery_active=false
var stale_peak_ms=0
var received_bytes=0
var wire_packet_count=0
var recovery_snapshot_age=0
var pre_poll_state_age=0
var previous_client_frame_us=0
var client_frame_gap_ms=0.0
var frame_gap_peak_ms=0.0
var frame_stalls=0
var delivery_stalls=0
var last_stall_context="none"
var browser_timing:Dictionary={}
var scenery_view:Node2D
var network_hud:Node2D
var dash_view=preload("res://network/dash_view.gd").new()
var reconcile_snapshot:Dictionary={}
var last_authority_point=Vector2.ZERO
var authority_point_ready=false
var correction_reset_reason=""
var server_build="unknown"
var authority_builds:Dictionary={}
var player_epochs:Dictionary={}
var authority_epoch=-1
var realm_result=""
const RealmCatalogue=preload("res://network/realms.gd")
var ability_view=preload("res://network/ability_view.gd").new()
var local_view=preload("res://network/local_view.gd").new()
var actor_motion=preload("res://network/actor_motion.gd").new()
var ground_art=preload("res://network/ground_art.gd").new()
var cosmetic_cache:Dictionary={}
var cosmetic_cache_until=0
var client_perf=preload("res://network/performance_view.gd").new()
var perf_latest:Dictionary={}
var report_downloads=0
const Move=preload("res://network/movement.gd")
var net_dash:Dictionary={}
var dodge_journal:Array=[]
var received_point_ready=false
var last_received_point=Vector2.ZERO
var net_velocity:Dictionary={}
var world_view=preload("res://network/world_view.gd").new()
var snapshot_inbox=preload("res://network/snapshot_inbox.gd").new()
var render_shots:Array=[]
var render_events:Array=[]
var remote_strike_view:Dictionary={}
var confirmed_damage_events=0
var recent_hit_events:Array=[]
var show_hit_geometry=false
var room_paused=false
var dedicated=false
var gateway:Node
var net_peer:WebSocketPeer
var net_ready=false
var net_host=false
var net_room=""
var resume_token=""
var frames:Array=[]
var history:Array=[]
var sequence=0
var applied_seq=0
var authority_tick=0
var shots_view=preload("res://network/projectile_view.gd").new()
var pending_correction=Vector2.ZERO
var net_panel:PanelContainer
var hero_button:Button
var net_status:Label
var url_field:LineEdit
var room_field:LineEdit
var net_start:Button
var net_name:LineEdit
var capacity:OptionButton
var test_arena:OptionButton
var bg_network_map:OptionButton
var arena_party_rule="ffa"
var arena_team_size=2
var local_lobby_team=0
var bg_team_controls:HBoxContainer
var bg_team_roster:Label
var battleground_render:Dictionary={}
var economy_pending=false
var economy_pending_at=0
var reconnect_until=0
var reconnect_at=0
var next_ping_at=0
var local_strikes:Array=[]
var predicted_actions:Dictionary={}
var pending_bursts:Array=[]
var connect_started_at=0
var DEFAULT_SERVER=preload("res://scripts/brand.gd").network_url()
var position_samples:Array=[]
var max_input_depth=0
var last_state_at=0
var last_snapshot_seq=-1
var disconnect_reason=""
var slow_status=""
var action_wait_ms=0
var server_hz=60.0
var server_snapshot_ms=0.0
var report_at=0
var server_inputs:Dictionary={}
var server_input_credit:Dictionary={}
var server_actions:Dictionary={}
var input_ack:Dictionary={}
var projectile_serial=0
var action_serial=0
var launch_trace:Dictionary={}
var launch_received_delays:Array=[]
var launch_drawn_delays:Array=[]
var server_snapshot_tick=0
var last_snapshot_tick=-1
var metrics={"rtt_ms":0,"corrections":0,"max_correction":0.0,"snapshots":0,"wire_bytes":0,"stale":0,"tick_ms":0.0}
func _ready()->void:
 dedicated=get_tree().root.has_meta("fx_dedicated_server")
 if not dedicated:RenderingServer.set_default_clear_color(Color("#081b27"));Engine.max_fps=120 # Also bound uncapped native/headless client polling.
 if dedicated:get_tree().root.set_meta("fx_dev_match",true)
 if not InputMap.has_action("primary"):
  InputMap.add_action("primary");var left=InputEventMouseButton.new();left.button_index=MOUSE_BUTTON_LEFT;InputMap.action_add_event("primary",left)
 var requested_realm=str(get_tree().root.get_meta("fx_realm","grove"))
 super._ready()
 add_child(expedition);expedition.setup(self)
 set_meta("requested_network_realm",requested_realm)
 _bind_test_controls()
 mode="arena" if dedicated else str(get_tree().root.get_meta("fx_mode","arena"));_set_mode(mode);control.hide();mobile.enabled=not dedicated and mobile.enabled
 if dedicated:legacy.set_process(false)
 if version_check!=null:
  if version_check.request!=null:version_check.request.cancel_request()
  version_check.queue_free();version_check=null
 if dedicated:get_tree().root.get_node("FXActivity").set_process(false)
 if dedicated:
  role="host";my_id="server";host_id="server";spectator_host=true;arena_seats=8
  # Authority advances combat explicitly. Browser UI, media polling and audio helpers do not tick here.
  for child in get_children():child.process_mode=Node.PROCESS_MODE_DISABLED
  return
 scenery_view=preload("res://network/scenery_view.gd").new();scenery_view.game=self;add_child(scenery_view)
 network_hud=preload("res://network/diagnostic_hud.gd").new();network_hud.game=self;add_child(network_hud)
 _configure_rendering()
 role="guest";host_id="server";build_lobby()
 if get_tree().root.has_meta("fx_coop_resume"):
  var saved:Dictionary=get_tree().root.get_meta("fx_coop_resume");get_tree().root.remove_meta("fx_coop_resume")
  url_field.text=str(saved.endpoint);resume_token=str(saved.token);net_room=str(saved.room);room_field.text=net_room;connect_net("resume")
func _configure_rendering()->void:
 if dedicated:return
 if has_meta("fx_render_shell"):get_meta("fx_render_shell").set_quality(render_budget.scale_for(balanced_graphics))
 if not OS.has_feature("web"):return
 # Fix the arena's browser rendering policy independently of saved town options.
 # Viewport scaling reduces high-DPI render work while keeping logical layout.
 get_tree().root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT if balanced_graphics else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 Engine.max_fps=60 if balanced_graphics else 120
 JavaScriptBridge.eval("if(window.fxCanvasBudget)window.fxCanvasBudget.set_mode("+("true" if balanced_graphics else "false")+");",true)
func _bind_test_controls()->void:
 for binding in [["move_left",KEY_A],["move_right",KEY_D],["move_up",KEY_W],["move_down",KEY_S],["special",KEY_SPACE],["dodge",KEY_SHIFT],["interact",KEY_E]]:
  var event=InputEventKey.new();event.physical_keycode=binding[1]
  if not InputMap.has_action(binding[0]):InputMap.add_action(binding[0])
  if not InputMap.action_has_event(binding[0],event):InputMap.action_add_event(binding[0],event)
 for binding in [["primary",MOUSE_BUTTON_LEFT],["secondary",MOUSE_BUTTON_RIGHT]]:
  var event=InputEventMouseButton.new();event.button_index=binding[1]
  if not InputMap.has_action(binding[0]):InputMap.add_action(binding[0])
  if not InputMap.action_has_event(binding[0],event):InputMap.action_add_event(binding[0],event)
var public_toggle:CheckButton
var competition_toggle:CheckButton
var room_listing:VBoxContainer
var browser_peer:WebSocketPeer
var browser_sent:bool=false
var browser_started:int=0
func build_lobby()->void:
 preload("res://network/party_lobby.gd").build(self)
func select_network_mode(value:String)->void:
 if net_ready:return
 if mode!=value:bot_plan=[];bot_count=0
 mode=value;_set_mode(value)
 if not preload("res://network/party_rules.gd").allows_ai(mode):bot_plan=[];bot_count=0
 capacity.select(capacity.get_item_index(bg_team_size*2 if mode=="battlegrounds" else arena_team_size*2 if mode=="arena" and arena_party_rule=="teams" else 2 if mode=="coop" else 4))
 var picker=net_panel.find_child("NetworkModes",true,false)
 if picker!=null:picker.select(maxi(0,["defense","arena","coop","descent","battlegrounds"].find(mode)))
 net_panel.find_child("NetworkRealms",true,false).visible=mode=="coop"
 test_arena.hide();_sync_network_mode_controls()
 for id in ["defense","arena","coop","descent","battlegrounds"]:
  var button=net_panel.find_child("Mode_"+id,true,false)
  if button!=null:button.modulate=Color("#f2d49c") if id==mode and not (id=="coop" and realm_id in ["between","overcharge","wayfarer"]) else Color.WHITE
func play_solo()->void:
 if net_ready:net_status.text="Leave the online room before starting solo.";return
 if get_tree().root.has_meta("fx_scene_handoff"):return
 _leave_room_connection()
 var root=get_tree().root
 root.set_meta("fx_hero",selected_hero);root.set_meta("fx_mode",mode)
 if mode=="coop":
  var reason=ExpeditionProfile.progress(self).entry_issue(realm_id) if realm_id in ["between","overcharge","attunement"] else preload("res://scripts/realm_access.gd").reason(legacy,realm_id)
  if not reason.is_empty():net_status.text=reason;return
  if realm_id in ["between","overcharge","attunement"]:
   root.set_meta("fx_solo_expedition",{"kind":realm_id,"tier":expedition_tier.get_selected_id()});preload("res://network/town_return.gd").begin(self,"res://scenes/main.tscn");return
  root.set_meta("fx_retry_realm",realm_id);preload("res://network/town_return.gd").begin(self,"res://scenes/main.tscn");return
 var plan=bot_plan.duplicate(true) if preload("res://network/party_rules.gd").allows_ai(mode) else []
 if preload("res://network/party_rules.gd").teamed(self):plan=filled_ai_plan(1,1 if local_lobby_team==0 else 0)
 var limit=8 if mode in ["arena","battlegrounds"] else 2 if mode=="coop" else 4
 if plan.size()+1>limit:net_status.text="Choose at most %d AI companions for this mode." % (limit-1);return
 root.set_meta("fx_solo_party",{"mode":mode,"hero":selected_hero,"realm":realm_id,"bg_map":bg_map,"bg_size":bg_team_size,"rule":arena_party_rule,"team_size":arena_team_size,"team":local_lobby_team,"arena_map":str(test_arena.get_item_metadata(test_arena.selected)),"bots":plan,"rivals":gate_rival_plan,"difficulty":ai_difficulty})
 preload("res://network/town_return.gd").begin(self,"res://scenes/arcade.tscn")
func filled_ai_plan(humans:int,team_zero:int)->Array:
 var result=[];var counts=[team_zero,humans-team_zero];var kits=preload("res://scripts/arena_bots.gd").IDS;var used=0
 for side in 2:
  for n in maxi(0,preload("res://network/party_rules.gd").side_limit(self)-int(counts[side])):
   var preferred=bot_plan.filter(func(b):return int(b.team)==side)
   result.append({"hero":str(preferred[n%preferred.size()].hero) if not preferred.is_empty() else kits[used%kits.size()],"team":side});used+=1
 return result
func fill_ai_seats()->void:
 if not preload("res://network/party_rules.gd").teamed(self):net_status.text="Choose individual seats with AI roster.";return
 var humans=roster.filter(func(m):return not str(m.id).begins_with("bot:"))
 var zero=humans.filter(func(m):return int(m.get("team",0))==0).size()
 bot_plan=filled_ai_plan(humans.size() if net_ready else 1,zero if net_ready else (1 if local_lobby_team==0 else 0))
 if net_ready:send_net({"type":"ai_party","bots":bot_plan,"difficulty":ai_difficulty})
 else:net_status.text="AI ready • %d seats filled." % bot_plan.size()
 _sync_network_mode_controls()
func browse_rooms()->void:
 if dedicated:return
 if browser_peer!=null:browser_peer.close()
 for child in room_listing.get_children():child.queue_free()
 preload("res://network/party_lobby.gd").label(room_listing,"Looking for public parties…",14)
 browser_peer=WebSocketPeer.new();browser_sent=false;browser_started=Time.get_ticks_msec()
 if browser_peer.connect_to_url(DEFAULT_SERVER)!=OK:_show_public_rooms([],"Room browser unavailable. You can still join by room code.")
func _show_public_rooms(list:Array,message:String="")->void:
 for child in room_listing.get_children():child.queue_free()
 if list.is_empty():preload("res://network/party_lobby.gd").label(room_listing,message if not message.is_empty() else "No public rooms yet. Host a public room to invite others, or refresh to check again.",14)
 for entry in list.slice(0,8):
  var row=HBoxContainer.new();room_listing.add_child(row)
  var title=preload("res://network/party_lobby.gd").label(row,"%s • %s • %d/%d" % [str(entry.get("host","Party")),str(entry.get("title","Adventure")),int(entry.get("players",0)),int(entry.get("seats",0))],14);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  preload("res://network/party_lobby.gd").button(row,"Join",func():
   if net_ready:net_status.text="Leave your current room before joining another party.";return
   room_field.text=str(entry.get("room",""));connect_net("join"))
func _poll_browser()->void:
 if browser_peer==null:return
 browser_peer.poll()
 if browser_peer.get_ready_state()==WebSocketPeer.STATE_OPEN:
  if not browser_sent:browser_peer.send_text(JSON.stringify({"type":"browse","protocol":PROTOCOL}));browser_sent=true
  while browser_peer.get_available_packet_count()>0:
   var value=JSON.parse_string(browser_peer.get_packet().get_string_from_utf8())
   if value is Dictionary and str(value.get("type",""))=="rooms":
    _show_public_rooms(value.get("rooms",[]));browser_peer.close();browser_peer=null;return
 if browser_peer.get_ready_state()==WebSocketPeer.STATE_CLOSED or Time.get_ticks_msec()-browser_started>7000:
  browser_peer.close();browser_peer=null;_show_public_rooms([],"Public-room browser unavailable. Host or join by room code; check the matching server update.")
func _sync_network_mode_controls()->void:
 var gallery=net_panel.find_child("ArenaGallery",true,false)
 if gallery!=null:gallery.visible=mode=="arena";gallery.refresh()
 var solo=net_panel.find_child("PlaySolo",true,false)
 if solo!=null:solo.disabled=net_ready;solo.text="▶  PLAY SOLO vs AI" if mode=="battlegrounds" else "▶  PLAY SOLO"
 var ai=net_panel.find_child("AIRoster",true,false)
 if ai!=null:ai.disabled=(net_ready and not net_host) or not preload("res://network/party_rules.gd").allows_ai(mode)
 if ai!=null:ai.text="Choose AI allies & enemy rivals" if mode=="defense" else "Choose AI opponents" if mode=="arena" and arena_party_rule=="ffa" else "Choose AI heroes & teams" if preload("res://network/party_rules.gd").allows_ai(mode) else "AI unavailable in this adventure"
 if ai!=null:ai.tooltip_text="AI allies: team Arena, Battlegrounds and Gate Defence only. FFA Arena bots are opponents."
 var fill=net_panel.find_child("FillAI",true,false)
 if fill!=null:fill.visible=preload("res://network/party_rules.gd").teamed(self);fill.disabled=net_ready and not net_host;fill.text="Fill empty team seats with AI"
 for name in ["defense","arena","coop","descent","battlegrounds"]:
  var b=net_panel.find_child("Mode_"+name,true,false)
  if b!=null:b.disabled=net_ready
 for name in ["between","overcharge","wayfarer"]:
  var b=net_panel.find_child("Destination_"+name,true,false)
  if b!=null:
   b.disabled=net_ready or not (ExpeditionProfile.progress(self).entry_issue(name) if name in ["between","overcharge"] else preload("res://scripts/realm_access.gd").reason(legacy,name)).is_empty()
   b.modulate=Color("#f2d49c") if mode=="coop" and realm_id==name else Color.WHITE
 var bg=mode=="battlegrounds"
 if expedition_tier!=null:expedition_tier.visible=mode=="coop" and realm_id=="overcharge";expedition_tier.disabled=net_ready
 for i in capacity.item_count:
  var seats=capacity.get_item_id(i)
  capacity.set_item_disabled(i,seats not in ([6,8] if bg else [2,4,6,8] if mode=="arena" else [2] if mode=="coop" else [2,4]))
 if bg_network_map==null:return
 bg_network_map.visible=bg;bg_network_map.disabled=net_ready and not net_host
 bg_network_map.select(1 if bg_map=="warzone" else 0)
 var rules=preload("res://network/party_rules.gd")
 var team_mode=rules.teamed(self)
 capacity.disabled=(net_ready and not net_host) or mode=="arena" and team_mode
 var format=net_panel.find_child("ArenaFormat",true,false)
 if format!=null:
  format.visible=mode=="arena";format.disabled=net_ready and not net_host
  format.select(arena_team_size-1 if arena_party_rule=="teams" else 0)
 bg_team_controls.visible=team_mode;bg_team_roster.visible=team_mode or mode=="defense"
 for side in 2:
  var join=bg_team_controls.get_child(side);join.text="Join "+rules.side_name(side);join.disabled=started
  join.modulate=rules.colour(side)
 if mode=="defense":bg_team_roster.text="One enemy rival hero per defender, including AI allies. Rivals arrive at wave 3 and respawn after defeat."
 elif team_mode:bg_team_roster.text="Choose your side above. Both teams must be full to start. AI uses player seats."+(" E at your barracks recruits and upgrades troops." if bg else "")
func choose_lobby_team(side:int)->void:
 if side not in [0,1] or started or not preload("res://network/party_rules.gd").teamed(self):return
 if net_ready:send_net({"type":"team","team":side})
 else:
  if local_lobby_team!=side:
   var limit=preload("res://network/party_rules.gd").side_limit(self)
   var target=bot_plan.filter(func(b):return int(b.team)==side)
   if target.size()>=limit:target[-1].team=local_lobby_team
  local_lobby_team=side;_sync_network_mode_controls()
func choose_arena_format(index:int)->void:
 if net_ready:
  if net_host:send_net({"type":"arena_format","rule":"ffa" if index==0 else "teams","team_size":index+1})
  return
 arena_party_rule="ffa" if index==0 else "teams";arena_team_size=index+1 if index>0 else 2
 if arena_party_rule=="teams":capacity.select(capacity.get_item_index(arena_team_size*2))
 _sync_network_mode_controls()
func _test_arena_changed(_index:int)->void:
 arena_map=str(test_arena.get_item_metadata(test_arena.selected))
 var gallery=net_panel.find_child("ArenaGallery",true,false)
 if gallery!=null:gallery.refresh()
 if net_ready and net_host and not started:send_net({"type":"arena_choice","arena_map":str(test_arena.get_item_metadata(test_arena.selected))})
func _capacity_changed(_index:int)->void:
 if mode=="battlegrounds" and not net_ready:bg_team_size=capacity.get_selected_id()/2;_sync_network_mode_controls()
 if not net_ready or not net_host or started:return
 send_net({"type":"capacity","seats":capacity.get_selected_id()})
 net_status.text="Updating room capacity…"
func net_select(id:String)->bool:
 if id.begins_with("custom_"):return false
 selected_hero=id;preferred_hero=id;hero_button.text="Hero • "+str(characters[id].name)
 if net_ready:send_net({"type":"hero","hero":id,"build_choice":legacy.payload(id)})
 return true
func net_permission(id:String)->String:return "Official heroes only during networking validation." if id.begins_with("custom_") else ""
func _leave_room_connection()->void:
 if browser_peer!=null:
  var browse_drain=preload("res://network/leave_link.gd").new();get_tree().root.add_child(browse_drain);browse_drain.setup(browser_peer,false);browser_peer=null
 if net_peer==null:return
 var run:Dictionary=ExpeditionProfile.progress(self).state().run
 if str(run.get("coop",{}).get("room",""))==net_room:ExpeditionProfile.forfeit(self)
 var drain=preload("res://network/leave_link.gd").new();get_tree().root.add_child(drain);drain.setup(net_peer);net_peer=null
func return_to_network_menu()->void:
 if dedicated:return
 _track_card_progress();legacy.save()
 if OS.has_feature("web"):JavaScriptBridge.eval("if(window.fxReports)window.fxReports.flush('return-to-menu');",true)
 _leave_room_connection()
 net_peer=null;net_ready=false;net_host=false;resume_token="";net_room="";match_id="";roster.clear()
 reconnect_until=0;reconnect_at=0;started=false;results_reason="";shop_open=""
 if has_meta("joining"):remove_meta("joining")
 presentation.close()
 if not session_menu.page.is_empty():session_menu.resume()
 mobile.reset_controls();mobile.visible=false
 recovery_active=false;last_state_at=0;frames.clear();history.clear();snapshot_inbox.clear()
 pending_correction=Vector2.ZERO;shots_view.reset();dodge_journal.clear()
 world_view.clear();render_events.clear();render_shots.clear();local_strikes.clear();predicted_actions.clear();pending_bursts.clear()
 for node in [net_panel.find_child("NetworkModes",true,false),net_panel.find_child("NetworkRealms",true,false)]:
  if node!=null:node.disabled=false
 room_field.text="";capacity.disabled=false;test_arena.disabled=false;public_toggle.disabled=false;net_start.disabled=true
 net_status.text="Ready for another match • Host a new room or enter a room code and Join."
 shop_open="";economy_pending=false;battleground_render.clear();_sync_network_mode_controls();control.hide();net_panel.show();queue_redraw()
func return_to_town()->void:
 if dedicated or has_meta("leaving_for_town"):return
 set_meta("leaving_for_town",true)
 _leave_room_connection();set_process(false);set_physics_process(false)
 get_tree().root.set_meta("fx_hero",selected_hero)
 if is_instance_valid(net_panel):net_panel.hide()
 preload("res://network/town_return.gd").begin(self,"res://scenes/main.tscn",true)
func _town()->void:
 # Post-match return keeps Host / Join available.
 return_to_network_menu()
func connect_net(kind:String)->void:
 if kind=="join" and room_field.text.strip_edges().length()!=6:net_status.text="Enter the six-character room code, or choose a public party.";return
 if kind=="resume":metrics.resume_attempts=int(metrics.get("resume_attempts",0))+1
 if kind=="host" and mode=="coop" and realm_id not in ["between","overcharge","attunement"] and realm_id not in RealmCatalogue.available(legacy):net_status.text=preload("res://scripts/realm_access.gd").reason(legacy,realm_id);return
 if net_ready and kind in ["host","join"]:
  net_status.text="Already connected to room "+net_room+". Host: press Start match.";return
 if net_peer!=null:net_peer.close()
 frames.clear();net_ready=false;connect_started_at=Time.get_ticks_msec()
 net_peer=WebSocketPeer.new();net_peer.inbound_buffer_size=1048576;net_peer.outbound_buffer_size=65536;net_peer.max_queued_packets=256;net_peer.heartbeat_interval=5.0
 if url_field.text.strip_edges().is_empty():url_field.text=DEFAULT_SERVER
 if url_field.text.strip_edges().is_empty():net_status.text="Multiplayer service is not configured in this build.";return
 get_tree().root.get_node("FXActivity").configure_endpoint(url_field.text)
 var error=net_peer.connect_to_url(url_field.text.strip_edges())
 if error!=OK:net_status.text="Cannot connect: "+error_string(error);return
 if kind=="resume":started=false
 set_meta("joining",kind);net_status.text="Connecting…"
func send_net(data:Dictionary)->void:
 if net_peer==null or net_peer.get_ready_state()!=WebSocketPeer.STATE_OPEN:return
 if net_peer.get_current_outbound_buffered_amount()>32768:
  disconnect_reason="client_outbound_stalled";net_status.text="Connection stalled; waiting for recovery…";return
 if data.get("cosmetic") is Dictionary:
  data=data.duplicate(true)
  var proof=legacy.cosmetics.rankings.lobby_payload()
  data.cosmetic.rank_ticket=proof.rank_ticket;data.cosmetic.rank_enabled=proof.rank_enabled
 net_peer.send_text(JSON.stringify(data))
func poll_net()->void:
 if net_peer==null:return
 net_peer.poll()
 if not net_ready and has_meta("joining") and Time.get_ticks_msec()-connect_started_at>60000:
  remove_meta("joining");net_peer.close();net_status.text="Connection timed out. Check the server /health page and try again.";return
 if net_peer.get_ready_state()==WebSocketPeer.STATE_OPEN:
  if has_meta("joining"):
   var kind=str(get_meta("joining"));remove_meta("joining")
   send_net({"type":kind,"protocol":PROTOCOL,"hero":preferred_hero,"name":net_name.text.left(24),"room":room_field.text.strip_edges().to_upper(),"mode":mode,"realm":realm_id,"build_choice":legacy.payload(preferred_hero),"cosmetic":local_cosmetic(),"food":provisions.packed,"expedition_profile":ExpeditionProfile.offer(self),"expedition_tier":expedition_tier.get_selected_id(),"unlocked_realms":RealmCatalogue.available(legacy),"rivals":gate_rival_plan,"rule":arena_party_rule,"team_size":arena_team_size,"team":local_lobby_team,"bots":(bot_plan if preload("res://network/party_rules.gd").allows_ai(mode) else []),"difficulty":ai_difficulty,"quest_states":RealmCatalogue.saved_quests() if mode=="coop" and realm_id=="wayfarer" else {},"seats":capacity.get_selected_id(),"bg_map":bg_map,"arena_map":str(test_arena.get_item_metadata(test_arena.selected)),"token":resume_token,"public":public_toggle.button_pressed,"competition":competition_toggle.button_pressed})
  if net_ready and Time.get_ticks_msec()>=next_ping_at:
   next_ping_at=Time.get_ticks_msec()+2000;send_net({"type":"ping","sent":Time.get_ticks_msec()});send_net({"type":"transport_ping","sent":Time.get_ticks_msec()})
  # Binary protocol-3 packets are replaceable full snapshots. Drain the raw
  # inbox first, retaining a short interpolation window before gzip/JSON work.
  snapshot_inbox.clear()
  var budget=256;var poll_deadline=Time.get_ticks_usec()+2500
  while net_peer.get_available_packet_count()>0 and budget>0 and Time.get_ticks_usec()<poll_deadline:
   budget-=1;var bytes=net_peer.get_packet();metrics.wire_bytes+=bytes.size()
   snapshot_inbox.push(bytes,not net_peer.was_string_packet());wire_packet_count+=1;received_bytes+=bytes.size()
  metrics.pending_packets=net_peer.get_available_packet_count()
  if int(metrics.pending_packets)>0:metrics.poll_budget_yields=int(metrics.get("poll_budget_yields",0))+1
  if snapshot_inbox.states.size()>=4 or pre_poll_state_age>=750:snapshot_inbox.retain_latest()
  metrics.coalesced_client_snapshots=int(metrics.get("coalesced_client_snapshots",0))+snapshot_inbox.dropped
  var latest={}
  for packet in snapshot_inbox.packets():
   var decode_began=Time.get_ticks_usec()
   var bytes:PackedByteArray=packet.bytes
   if packet.binary:bytes=bytes.decompress_dynamic(2097152,FileAccess.COMPRESSION_GZIP)
   var message=JSON.parse_string(bytes.get_string_from_utf8())
   client_perf.work("snapshot_decode" if packet.binary else "control_decode",Time.get_ticks_usec()-decode_began)
   if not message is Dictionary:continue
   if str(message.get("type",""))=="state":
    if not _valid_state(message):continue
    _buffer_state(message);latest=message
   else:
    if str(message.get("type",""))=="start":latest={}
    receive_net(message)
  if not latest.is_empty():receive_net(latest)
 elif net_peer.get_ready_state()==WebSocketPeer.STATE_CLOSED:
  disconnect_reason="socket_closed_"+str(net_peer.get_close_code())+": "+net_peer.get_close_reason()
  metrics.last_disconnect_reason=disconnect_reason
  net_ready=false
  if has_meta("joining"):
   remove_meta("joining");net_status.text="Connection closed before room confirmation. Check the server address and browser Console."
  if not resume_token.is_empty():
   if reconnect_until==0:reconnect_until=Time.get_ticks_msec()+15000
   if Time.get_ticks_msec()>reconnect_until:
    started=false;net_panel.show();net_status.text="Connection lost. Room can no longer be resumed.";resume_token=""
   elif Time.get_ticks_msec()>=reconnect_at:
    reconnect_at=Time.get_ticks_msec()+1500;room_field.text=net_room;connect_net("resume")
func _check_stale_link()->void:
 if dedicated or not started or not net_ready or last_state_at<=0:return
 var age=Time.get_ticks_msec()-last_state_at
 var stale=age>=750
 if stale and not recovery_active:
  recovery_stalls+=1;recovery_active=true
  if client_frame_gap_ms>=250:
   frame_stalls+=1;last_stall_context="client_frame_gap"
  else:
   delivery_stalls+=1;last_stall_context="state_delivery_gap"
  frames.clear();history.clear();pending_bursts.clear();predicted_actions.clear();local_strikes.clear();dodge_journal.clear();shots_view.reset()
  mobile.reset_controls()
  _send_channel(host_id,{"type":"held_cast","kind":"primary","phase":"cancel","angle":0})
  _send_channel(host_id,{"type":"held_cast","kind":"secondary","phase":"cancel","angle":0})
 if recovery_active and age<250:recovery_active=false
 if age>4000 and net_peer!=null and net_peer.get_ready_state()==WebSocketPeer.STATE_OPEN:
  disconnect_reason="state_timeout";net_peer.close(1000,"state_timeout")
func receive_net(data:Dictionary)->void:
 match str(data.get("type","")):
  "expedition_prepare":
   expedition_offer=data.get("config",{}).duplicate(true)
   presentation.window("CO-OP EXPEDITION • confirm your entry","expedition_entry")
   var cost=preload("res://scripts/waylight_catalog.gd").COSTS[int(expedition_offer.tier)-1] if expedition_offer.kind=="overcharge" else 0
   presentation.label(presentation.content,"%s • Tier %d" % [str(expedition_offer.realm).capitalize(),int(expedition_offer.tier)],23)
   presentation.label(presentation.content,"Each player pays %d of their own Waylight Shards. Both must confirm. Cancellation before launch refunds your reservation. Live-room reconnect does not charge again." % cost,19)
   presentation.button(presentation.content,"Confirm • %d shards from MY profile" % cost,_accept_expedition)
   presentation.button(presentation.content,"Cancel entry",func():send_net({"type":"expedition_cancel","id":str(expedition_offer.id)}))
  "expedition_cancelled":
   ExpeditionProfile.cancel(self,str(data.get("id","")));expedition_offer={};presentation.close();net_status.text=str(data.get("message","Entry cancelled."));net_panel.show()
  "welcome":
   server_build=str(data.get("build","unknown"))
   my_id=str(data.id);net_room=str(data.room);resume_token=str(data.token);net_host=bool(data.host);net_ready=true;reconnect_until=0;capacity.disabled=not net_host
   room_field.text=net_room;net_status.text="Room "+net_room+" • server "+server_build+(" • install the V179-preview server repair" if server_build in ["T4.8","T4.9.1"] else "");net_start.disabled=not net_host
  "lobby":
   mode=str(data.get("mode",mode));realm_id=str(data.get("realm",realm_id));roster.assign(data.members);net_host=str(data.host)==my_id;net_start.disabled=not net_host or roster.size()<2
   capacity.disabled=not net_host
   bot_plan=preload("res://scripts/arena_bots.gd").clean_plan(data.get("bots",[]));bot_count=bot_plan.size();gate_rival_plan=data.get("rivals",preload("res://network/party_rules.gd").DEFAULT_RIVALS).duplicate()
   if not bool(data.get("preparing",false)):ExpeditionProfile.cancel(self)
   expedition_tier.select(clampi(int(data.get("expedition_tier",1))-1,0,2))
   arena_party_rule=str(data.get("rule","ffa"));arena_team_size=int(data.get("team_size",2))
   for member in roster:
    if str(member.id)==my_id:local_lobby_team=int(member.get("team",0))
   bg_map=str(data.get("bg_map",bg_map));bg_team_size=int(data.get("bg_team_size",bg_team_size));_sync_network_mode_controls()
   if preload("res://network/party_rules.gd").teamed(self):
    var cap=preload("res://network/party_rules.gd").side_limit(self)
    net_start.disabled=not net_host or roster.filter(func(m):return int(m.get("team",-1))==0).size()!=cap or roster.filter(func(m):return int(m.get("team",-1))==1).size()!=cap
   for control_node in [net_panel.find_child("NetworkModes",true,false),net_panel.find_child("NetworkRealms",true,false)]:
    if control_node!=null:control_node.disabled=net_ready
   public_toggle.set_pressed_no_signal(bool(data.get("public",false)));public_toggle.disabled=not net_host
   set_meta("crown_competition",data.get("competition",false)==true);competition_toggle.set_pressed_no_signal(bool(get_meta("crown_competition")));competition_toggle.disabled=not net_host
   var mode_control=net_panel.find_child("NetworkModes",true,false)
   var realm_control=net_panel.find_child("NetworkRealms",true,false)
   if mode_control!=null:mode_control.select(maxi(0,["defense","arena","coop","descent","battlegrounds"].find(mode)))
   if realm_control!=null:realm_control.select(maxi(0,RealmCatalogue.lobby_ids().find(realm_id)));realm_control.visible=mode=="coop"
   test_arena.hide()
   capacity.select(capacity.get_item_index(int(data.seats)))
   test_arena.disabled=not net_host;arena_map=str(data.get("arena_map","sand"));test_arena.select(maxi(0,arena_world.MAPS.keys().find(arena_map)));_sync_network_mode_controls()
   net_status.text="Room "+net_room+" • "+str(roster.size())+" / "+str(data.seats)+" players • "+("COMPETITION • crown bonuses off" if bool(get_meta("crown_competition",false)) else str(data.get("message","")))
  "error":net_status.text=str(data.get("message","Error"));net_panel.show();_sync_network_mode_controls()
  "start":
   gate_rival_plan=data.get("rivals",preload("res://network/party_rules.gd").DEFAULT_RIVALS).duplicate()
   set_meta("crown_competition",data.get("competition",false)==true)
   var same_match=not match_id.is_empty() and match_id==str(data.match_id)
   if OS.has_feature("web") and data.has("report_token"):JavaScriptBridge.eval("if(window.fxReports)window.fxReports.start("+JSON.stringify({"endpoint":url_field.text.replace("wss://","https://").replace("ws://","http://"),"token":data.report_token,"enabled":data.get("reporting",false),"match_id":data.match_id,"room":net_room})+");",true)
   authority_epoch=-1;player_epochs.clear();realm_result="";economy_pending=false
   expedition.configure(data.get("expedition",{}));ExpeditionProfile.commit(self,data.get("expedition",{}))
   mode=str(data.get("mode","arena"));realm_id=str(data.get("realm","grove"));match_party_size=data.heroes.size();match_id=str(data.match_id);floor_seed=int(data.seed);arena_map=str(data.arena_map);arena_seats=int(data.seats);spectator_host=false;bot_plan=preload("res://scripts/arena_bots.gd").clean_plan(data.get("bots",[]));bot_count=bot_plan.size();gate_rival_plan=data.get("rivals",preload("res://network/party_rules.gd").DEFAULT_RIVALS).duplicate();ai_difficulty=preload("res://scripts/arena_bots.gd").difficulty(data.get("difficulty","medium"));arena_no_items=mode=="arena";pvp_rule=str(data.get("rule","teams" if mode=="battlegrounds" else "ffa"))
   bg_map=str(data.get("bg_map","woodland"));bg_team_size=int(data.get("bg_team_size",4));teams=data.get("teams",{});_sync_bg_pickers();economy_pending=false;battleground_render.clear()
   for n in realm_picker.item_count:
    if str(realm_picker.get_item_metadata(n))==realm_id:realm_picker.select(n)
   hero_ids=data.heroes;selected_hero=str(hero_ids.get(my_id,preferred_hero));preferred_hero=selected_hero
   positions.clear();authority_builds.clear()
   for id in hero_ids:positions[id]=Vector2.ZERO
   recovery_active=false;last_state_at=Time.get_ticks_msec()
   if not same_match:frame_stalls=0;delivery_stalls=0;frame_gap_peak_ms=0;last_stall_context="none";recovery_stalls=0;stale_peak_ms=0;render_budget.reset();metrics.resume_attempts=0;metrics.last_disconnect_reason=""
   _configure_rendering()
   disconnect_reason="";sequence=0;action_serial=0;history.clear();frames.clear();last_snapshot_tick=-1;last_snapshot_seq=-1;applied_seq=0;pending_correction=Vector2.ZERO
   launch_trace.clear();launch_received_delays.clear();launch_drawn_delays.clear()
   authority_point_ready=false;dash_view.clear()
   for key in ["corrections","max_correction","authority_resets","correction_1_8","correction_8_32","correction_32_plus"]:metrics[key]=0
   metrics.last_authority_reset=""
   if scenery_view!=null:scenery_view.reset()
   _start_match();expedition.start();ability_view.reset();local_view.reset(local_pos);start_countdown=0;control.hide();net_panel.hide();shots_view.reset();dodge_journal.clear();received_point_ready=false;local_strikes.clear();predicted_actions.clear();pending_bursts.clear();world_view.clear();actor_motion.clear();render_shots.clear();render_events.clear();remote_strike_view.clear();confirmed_damage_events=0;recent_hit_events.clear()
  "state":
   if not _valid_state(data):return
   var tick=int(data.get("server_tick",0))
   var serial=int(data.get("snapshot_seq",tick))
   if serial<=last_snapshot_seq:metrics.stale+=1;return
   recovery_snapshot_age=maxi(0,Time.get_ticks_msec()-last_state_at) if last_state_at>0 else 0
   last_state_at=Time.get_ticks_msec()
   if recovery_snapshot_age>=750:
    if not recovery_active:recovery_stalls+=1
    shots_view.reset();ability_view.reset()
    history.clear();frames.clear();world_view.reset_timeline();_buffer_state(data);local_view.reset(local_pos);pending_correction=Vector2.ZERO
   recovery_active=false
   server_metrics=data.get("server_metrics",server_metrics)
   metrics.server_metrics_received_at=Time.get_ticks_msec()
   last_snapshot_seq=serial;server_hz=float(data.get("actual_hz",60));server_snapshot_ms=float(data.get("snapshot_ms",0))
   last_snapshot_tick=tick;metrics.snapshots+=1;metrics.tick_ms=float(data.get("tick_ms",0))
   receive_events(data)
   var own:Dictionary=data.get("players",{}).get(my_id,{})
   if int(own.get("hp",0))<=0:dodge_journal.clear()
   dodge_journal=dodge_journal.filter(func(event):return int(event.tick)<0 or tick<int(event.tick))
   # Release the old charge marker before normal movement is replayed. The
   # base receiver otherwise overwrites that replay with the landing packet.
   if not bool(own.get("charging",false)):charges.erase(my_id)
   var dash:Array=own.get("dash",[0,0,0])
   net_dash[my_id]={"time":float(dash[0]),"direction":Vector2(float(dash[1]),float(dash[2]))}
   for actor in positions.keys():
    if not data.get("players",{}).has(actor):
     positions.erase(actor);health.erase(actor);hero_ids.erase(actor);remote_draw_pos.erase(actor)
   if mode=="descent" and int(data.get("floor",floor_number))!=floor_number:
    floor_number=int(data.floor);_make_floor();world_view.reset_timeline();_buffer_state(data);ability_view.reset();local_view.reset(local_pos)
   # Install both local and remote authoritative builds BEFORE replaying inputs.
   for actor in data.get("players",{}):authority_builds[str(actor)]=legacy.sanitize_build(data.players[actor].get("build",{}))
   var before_ability_draw=_local_draw_position()
   var before_ability_hp=int(health.get(my_id,0))
   var apply_began=Time.get_ticks_usec()
   realm_result=str(data.get("realm_result",realm_result))
   expedition.receive(data.get("expedition",{}))
   reconcile_snapshot=own
   data.effects=[];super._packet("server",data)
   reconcile_snapshot={}
   client_perf.work("snapshot_apply",Time.get_ticks_usec()-apply_began)
   if not own.is_empty():
    var point=Vector2(float(own.pos[0]),float(own.pos[1]))
    var travelling=bool(own.get("charging",false)) or bool(own.get("stance_moving",false))
    if bool(own.get("charging",false)):
     local_pos=point;positions[my_id]=point;pending_correction=Vector2.ZERO
    if received_point_ready and last_received_point.distance_to(point)>160 or before_ability_hp<=0 and int(own.get("hp",0))>0:
     ability_view.reset();local_view.reset(local_pos)
    else:ability_view.receive(travelling,before_ability_draw,point,_charge_view_speed() if bool(own.get("charging",false)) else 0)
    last_received_point=point;received_point_ready=true
   shots_view.path_clear=Callable(self,"_clear_path");shots_view.local_owner=my_id;shots_view.latency=float(metrics.rtt_ms)/1000.0
  "input_resync":
   if str(data.get("match_id",""))!=match_id:return
   var expected=int(data.get("expected",1))
   var retry=history.filter(func(frame):return int(frame.seq)>=expected)
   if retry.is_empty() or int(retry[0].seq)!=expected:
    send_net({"type":"input_reset","match_id":match_id,"seq":sequence});return
   for index in range(0,retry.size(),8):send_net({"type":"input","match_id":match_id,"frames":retry.slice(index,index+8),"event_ack":applied_seq})
  "events":receive_events(data)
  "action_ack":
   for event in dodge_journal:
    if int(event.seq)==int(data.seq):event.tick=int(data.get("tick",last_snapshot_tick))
   if bool(data.get("accepted",false)):shots_view.acknowledge(int(data.seq),int(data.get("tick",-1)),data.get("born_indices",[]))
   action_wait_ms=int(data.get("wait_ms",0))
   if not bool(data.accepted):
    dodge_journal=dodge_journal.filter(func(event):return int(event.seq)!=int(data.seq))
    var rejected=int(data.seq);shots_view.reject(rejected);launch_trace.erase(rejected)
    local_strikes=local_strikes.filter(func(x):return int(x.action_seq)!=rejected)
    pending_bursts=pending_bursts.filter(func(x):return int(x.seq)!=rejected)
   if data.has("style"):
    var pistol:bool=str(data.style)=="primary" and str(characters.get(selected_hero,{}).get("primary",{}).get("style",""))=="v91_pistol"
    request_ready[str(data.style)]=0 if pistol else Time.get_ticks_msec()+maxi(80,int(data.get("remaining",0))-int(metrics.rtt_ms))
  "economy_ack":
   if str(data.get("match_id",""))!=match_id:return
   economy_pending=false;status_label.text=str(data.get("message","Order received."))
   if data.get("order",{}) is Dictionary:
    var order:Dictionary=data.get("order",{});gold[my_id]=int(order.get("gold",gold.get(my_id,0)))
    var base:Dictionary=battlegrounds.bases.get(battlegrounds.owners.get(my_id,""),{})
    if not base.is_empty():base.counts=order.get("counts",base.counts);base.upgrades=order.get("upgrades",base.upgrades)
   if str(data.get("kind",""))=="bg_upgrade" and presentation.page=="battlegrounds":
    presentation.close();battlegrounds.open_shop(status_label.text)
  "interaction_ack":
   if not str(data.get("notice","")).is_empty():status_label.text=str(data.notice)
  "kite_release":super._packet("server",data)
  "transport_pong":
   metrics.gateway_rtt_ms=Time.get_ticks_msec()-int(data.sent);gateway_metrics=data.get("gateway_metrics",{})
  "diagnostics":
   gateway_metrics=data.get("gateway_metrics",{});server_metrics=data.get("server_metrics",{})
  "pong":metrics.rtt_ms=Time.get_ticks_msec()-int(data.sent)
func _process(delta:float)->void:
 if dedicated:return
 var frame_began=Time.get_ticks_usec();client_perf.frame(frame_began)
 client_frame_gap_ms=(frame_began-previous_client_frame_us)/1000.0 if previous_client_frame_us>0 else 0.0
 previous_client_frame_us=frame_began;frame_gap_peak_ms=maxf(frame_gap_peak_ms,client_frame_gap_ms)
 local_view.advance(delta)
 if render_budget.observe(delta,started and balanced_graphics and not recovery_active and presentation.page.is_empty()):_configure_rendering()
 VIEW=get_viewport_rect().size
 pre_poll_state_age=maxi(0,Time.get_ticks_msec()-last_state_at) if last_state_at>0 else 0
 stale_peak_ms=maxi(stale_peak_ms,pre_poll_state_age)
 var poll_began=Time.get_ticks_usec();poll_net();client_perf.work("network_poll",Time.get_ticks_usec()-poll_began)
 _check_stale_link()
 control.visible=started and shop_open=="Supplies"
 control.offset=(VIEW-Vector2(1280,720))*.5
 for node in control.get_children():
  if node is Control:node.visible=shop_open=="Supplies" and (node==item_picker or node is Button and node.text=="BUY ITEM")
 mobile.visible=started
 _report_network()
 _poll_browser()
 if not started and is_instance_valid(net_panel):net_panel.visible=presentation.page.is_empty() and not is_instance_valid(hero_grid)
 if is_instance_valid(net_panel):net_panel.size=Vector2(minf(1240,VIEW.x-24),minf(690,VIEW.y-24));net_panel.position=(VIEW-net_panel.size)*.5
 if not started:
  if scenery_view!=null:scenery_view.visible=false
  if network_hud!=null:network_hud.visible=false
  queue_redraw();client_perf.work("client_process",Time.get_ticks_usec()-frame_began);return
 ability_view.advance(delta,local_view.point(local_pos,Engine.get_physics_interpolation_fraction()))
 expedition.step(delta)
 visual_time+=delta;motion_v85.advance(delta);skating_motion.advance(delta);actor_motion.advance(delta);actor_motion.prune(positions.keys())
 _advance_local_previews(delta)
 world_view.advance(delta)
 if mode=="battlegrounds":battleground_render=world_view.battlegrounds()
 if economy_pending and Time.get_ticks_msec()-economy_pending_at>4000:economy_pending=false;status_label.text="Order confirmation delayed. Check your CC and army before trying again."
 render_shots=world_view.shots()
 # Owned shots use fresh authority plus a short cosmetic reconciliation.
 shots_view.samples(Time.get_ticks_msec()/1000.0)
 _update_remote_strikes()
 for n in range(render_events.size()-1,-1,-1):
  if float(render_events[n].tick)/60.0<=world_view.render_time:
   var event:Dictionary=render_events[n].data
   var late=world_view.render_time-float(render_events[n].tick)/60.0
   if late<=.3 or str(event.get("style","")) in ["damage","heal_contact"]:_receive_effect(event)
   render_events.remove_at(n)
 # Both local previews and confirmed seeds use the existing combat artwork.
 var custom_shots:Array=[]
 for shot in render_shots:
  if str(shot.owner)!=my_id and bool(shot.get("custom",false)):
   var copy:Dictionary=shot.art.duplicate(true);copy.pos=[shot.draw_pos.x,shot.draw_pos.y];copy.net_rendered=true;custom_shots.append(copy)
 for track in shots_view.visuals(Time.get_ticks_msec()/1000.0):
  if bool(track.get("custom",false)):
   var copy:Dictionary=track.art.duplicate(true);var point=shots_view.point(track,Time.get_ticks_msec()/1000.0)
   copy.owner=track.owner;copy.pos=[point.x,point.y];copy.net_rendered=true;custom_shots.append(copy)
 adventure.combat.projectiles=custom_shots
 var visual_pair=world_view.pair()
 for actor in positions:
  if actor!=my_id:
   remote_draw_pos[actor]=_remote_position(str(actor),Time.get_ticks_msec()/1000.0)
   if not visual_pair.is_empty():
    var sample:Dictionary=visual_pair[0];var info:Dictionary=sample.data.get("players",{}).get(actor,{})
    var age_ms=maxf(0,world_view.render_time-float(sample.t))*1000
    attack_pose_until[actor]=Time.get_ticks_msec()+maxi(0,int(info.get("pose",0))-int(age_ms))
  var ground=_local_draw_position() if actor==my_id else remote_draw_pos.get(actor,positions[actor])
  actor_motion.sample(str(actor),ground)
  motion_v85.sample(str(actor),str(hero_ids.get(actor,"ram")),ground,true)
  skating_motion.sample(str(actor),ground,delta,true);wing_motion.step(str(actor),ground,delta,true);basketball_motion.step(str(actor),ground,delta,true);fish_motion.step(str(actor),ground,delta,true)
 missiles.assign(shots_view.samples(Time.get_ticks_msec()/1000.0))
 for shot in render_shots:
  if str(shot.owner)!=my_id and not bool(shot.get("custom",false)):missiles.append({"pos":shot.draw_pos,"owner":shot.owner,"color":shot.color})
 adventure.combat.held_cast.local_input(delta,not arena_world.shatter.active() and net_ready and shop_open.is_empty() and presentation.page.is_empty() and Time.get_ticks_msec()-last_state_at<400)
 if net_ready and shop_open.is_empty() and presentation.page.is_empty() and not fishing.busy() and Time.get_ticks_msec()-last_state_at<400:
  if adventure.combat.v90.primary_pressed(my_id,mobile.attacking if mobile.enabled else Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):_attack_request("primary")
  if Input.is_action_pressed("secondary"):_attack_request("secondary")
  if Input.is_action_just_pressed("special"):_attack_request("special")
 _refresh_draw_camera()
 _sync_dash_view(delta)
 if scenery_view!=null:
  scenery_view.visible=mode=="arena"
  if mode=="arena":scenery_view.sync()
 if network_hud!=null:network_hud.sync(delta)
 if terrain_cache!=null:
  terrain_cache.z_index=-3;terrain_cache.visible=not expedition.between()
  if not expedition.between():terrain_cache.sync()
 for n in range(effects.size()-1,-1,-1):
  effects[n].time-=delta
  if effects[n].time<=0:effects.remove_at(n)
 for n in range(damage_labels.size()-1,-1,-1):
  damage_labels[n].time-=delta;damage_labels[n].pos+=Vector2(0,-35)*delta
  if damage_labels[n].time<=0:damage_labels.remove_at(n)
 queue_redraw()
 client_perf.work("client_process",Time.get_ticks_usec()-frame_began)
func _physics_process(_delta:float)->void:
 if dedicated:
  if not started or room_paused:return
  var begin=Time.get_ticks_usec();authority_tick+=1
  if gateway!=null:gateway.simulation_steps+=1
  var before_positions=positions.duplicate()
  set_meta("fx_network_previous_positions",before_positions)
  for id in positions:
   # Credit is earned by server ticks, never by the number of client packets.
   # Two-step catch-up drains jitter backlog without unbounded fast-forward.
   server_input_credit[id]=minf(12,float(server_input_credit.get(id,0))+1)
   var queue:Array=server_inputs.get(id,[])
   var steps=mini(2,mini(queue.size(),int(server_input_credit[id])))
   for _step in steps:
    var f:Dictionary=queue.pop_front();input_ack[id]=int(f.seq);server_input_credit[id]-=1
    var direction=Vector2(float(f.d[0]),float(f.d[1]))
    positions[id]=Move.advance(self,str(id),positions[id],direction)
    revive_held[id]=bool(f.get("revive",false))
    var aim=Vector2.from_angle(float(f.a));aim_angles[id]=float(f.a)
    if not arena_world.shatter.active():adventure.combat.release_heroes.holding(str(id),bool(f.sh),aim);adventure.combat.classics.holding(str(id),bool(f.sh));adventure.combat.v79.holding(str(id),bool(f.sh),aim);adventure.combat.v56.holding(str(id),bool(f.ph),aim)
    _execute_due_actions(str(id))
   _execute_due_actions(str(id))
  bots.step(Move.DT);run_time+=Move.DT;visual_time+=Move.DT;arena_world.step(Move.DT);
  if not arena_world.shatter.active():adventure.step(Move.DT)
  _update_flames(Move.DT);_simulate_charges(Move.DT);_simulate(Move.DT)
  expedition.step(Move.DT)
  _update_fountains(Move.DT);_update_revives(Move.DT);_track_card_progress()
  for actor in positions:net_velocity[actor]=(positions[actor]-before_positions.get(actor,positions[actor]))/Move.DT
  for bullet in missiles:
   if not bullet.has("net_id"):
    projectile_serial+=1;bullet.net_id=projectile_serial
    bullet.born_tick=authority_tick-float(bullet.get("distance",0))/maxf(1,float(bullet.get("speed",420)))*60
  metrics.tick_ms=(Time.get_ticks_usec()-begin)/1000.0
  position_samples.append({"tick":authority_tick,"points":positions.duplicate(),"hp":health.duplicate()})
  while position_samples.size()>16:position_samples.pop_front()
  if authority_tick%3==0:gateway.snapshot(self)
  if gateway!=null:
   var complete=(Time.get_ticks_usec()-begin)/1000.0
   gateway.step_work_ms=complete;gateway.work_window+=complete;gateway.step_work_max_ms=maxf(gateway.step_work_max_ms,complete)
  return
 if not started or not net_ready or recovery_active:return
 var physics_began=Time.get_ticks_usec()
 var direction:Vector2=mobile.movement if mobile.enabled else Input.get_vector("move_left","move_right","move_up","move_down")
 if not presentation.page.is_empty() or not shop_open.is_empty() or fishing.busy():direction=Vector2.ZERO
 var aim:Vector2=mobile.aim if mobile.enabled else (media_mouse_world()-local_pos).normalized()
 if arena_world.shatter.active() and Input.is_action_just_pressed("dodge"):arena_world.shatter.request("secondary")
 if not arena_world.shatter.active() and Input.is_action_just_pressed("dodge") and Move.movable(self,my_id) and Time.get_ticks_msec()>=int(dodge_at.get(my_id,0)):
  var dash_direction=direction.normalized() if not direction.is_zero_approx() else aim
  net_dash[my_id]={"time":.26,"direction":dash_direction};dodge_at[my_id]=Time.get_ticks_msec()+2500
  _send_channel(host_id,{"type":"dodge","direction":[dash_direction.x,dash_direction.y]})
 if history.size()>=180 or Time.get_ticks_msec()-last_state_at>400:direction=Vector2.ZERO
 sequence+=1
 var frame={"seq":sequence,"d":[snappedf(direction.x,.001),snappedf(direction.y,.001)],"a":aim.angle(),"revive":Input.is_action_pressed("interact"),"ph":mobile.attacking if mobile.enabled else Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT),"sh":Input.is_action_pressed("secondary")}
 frames.append(frame);history.append(frame)
 if history.size()>180:
  # Bounded replay during a prolonged stall. Wait for authority; do not keep moving or reconnect.
  slow_status="Waiting for authoritative state…";history=history.slice(-180)
  direction=Vector2.ZERO
 else:slow_status=""
 var before_prediction=local_pos
 local_pos=Move.advance(self,my_id,local_pos,direction)
 positions[my_id]=local_pos
 local_view.capture(before_prediction,local_pos)
 if sequence%2==0:
  send_net({"type":"input","match_id":match_id,"frames":frames,"event_ack":applied_seq});frames=[]

 client_perf.work("client_physics",Time.get_ticks_usec()-physics_began)

func _reconcile_position(ack:int,point:Vector2)->void:
 if ack<0:return
 var epoch=int(reconcile_snapshot.get("position_epoch",authority_epoch))
 var relocated=authority_epoch>=0 and epoch!=authority_epoch
 if relocated:
  dodge_journal.clear();net_dash.erase(my_id);local_strikes.clear();pending_bursts.clear();ability_view.reset();local_view.reset(point)
 authority_epoch=epoch
 if reconcile_snapshot.has("ice_velocity"):
  var velocity=reconcile_snapshot.ice_velocity
  var v=Vector2(float(velocity[0]),float(velocity[1]))
  if v.is_zero_approx():adventure.polish.momentum.erase(my_id)
  else:adventure.polish.momentum[my_id]=v
 history=history.filter(func(f):return int(f.seq)>ack)
 var replay_began=Time.get_ticks_usec()
 var movement=Move.prepare(self,my_id)
 var repaired=point
 var applied={}
 for frame in history:
  for event in dodge_journal:
   if int(frame.seq)>int(event.after) and not applied.has(event.seq):
    net_dash[my_id]={"time":.26,"direction":event.direction};applied[event.seq]=true
  repaired=Move.advance_prepared(self,my_id,repaired,Vector2(float(frame.d[0]),float(frame.d[1])),movement)
 # A snapshot can arrive between the button press and the next physics tick.
 for event in dodge_journal:
  if not applied.has(event.seq) and int(event.after)<=sequence:net_dash[my_id]={"time":.26,"direction":event.direction}
 client_perf.work("prediction_replay",Time.get_ticks_usec()-replay_began)
 metrics.replayed_inputs=history.size()
 var error=repaired-local_pos
 correction_reset_reason="realm_portal" if relocated else ""
 if not reconcile_snapshot.is_empty():
  if not authority_point_ready:correction_reset_reason="initial_state"
  elif int(health.get(my_id,0))<=0 and int(reconcile_snapshot.get("hp",0))>0:correction_reset_reason="respawn"
  elif int(reconcile_snapshot.get("hp",0))<=0:correction_reset_reason="defeated" if int(health.get(my_id,0))>0 else "defeated_state"
  elif point.distance_to(last_authority_point)>160:correction_reset_reason="authority_relocation"
  last_authority_point=point;authority_point_ready=true
 if correction_reset_reason.is_empty():
  metrics.max_correction=maxf(float(metrics.max_correction),error.length())
  if error.length()>1:metrics.corrections+=1
 else:
  if correction_reset_reason!="defeated_state":metrics.authority_resets=int(metrics.get("authority_resets",0))+1
  metrics.last_authority_reset=correction_reset_reason
  dash_view.remove(my_id)
 if error.length()>1 and correction_reset_reason.is_empty():
  var bucket="correction_1_8" if error.length()<8 else "correction_8_32" if error.length()<32 else "correction_32_plus"
  metrics[bucket]=int(metrics.get(bucket,0))+1
 local_view.reconcile(local_pos,repaired,error.length()>80 or not correction_reset_reason.is_empty())
 local_pos=repaired;pending_correction=Vector2.ZERO
 positions[my_id]=local_pos
func _send_channel(_id:String,data:Dictionary)->void:
 if dedicated:
  if gateway!=null:gateway.send_actor(_id,data)
  return
 # Critical actions must not wait for the next 30 Hz movement batch.
 if str(data.get("type","")) in ["attack","community_input","dodge","consume","rift","bg_upgrade","purchase","crown_throw"] or str(data.get("type",""))=="held_cast" and str(data.get("phase",""))=="release":
  _flush_action_inputs()
 action_serial+=1
 if str(data.get("type",""))=="dodge":
  var direction=data.get("direction",[1,0])
  dodge_journal.append({"seq":action_serial,"after":sequence,"direction":Vector2(float(direction[0]),float(direction[1])).normalized(),"tick":-1})
  while dodge_journal.size()>8:dodge_journal.pop_front()
 if str(data.get("type","")) in ["attack","held_cast","dodge"]:
  metrics.last_action={"seq":action_serial,"type":data.type,"kind":data.get("style",data.get("kind","primary")),"phase":data.get("phase",""),"angle":data.get("angle",0),"client_ms":Time.get_ticks_msec()}
  var kind=str(data.get("style",data.get("kind","primary")))
  metrics.last_action.motion_type=1 if str(data.type)=="dodge" else 2 if str(characters.get(selected_hero,{}).get(kind,{}).get("style",""))=="charge" else 0
 var packet=data.duplicate(true);packet.seq=action_serial;packet.input_seq=sequence;packet.match_id=match_id;packet.view_tick=maxi(0,floori(world_view.render_time*60))
 send_net(packet)
 if str(data.get("type",""))=="attack":_preview_attack(str(data.get("style","primary")),data,action_serial)
 elif str(data.get("type",""))=="held_cast" and str(data.get("phase",""))=="release":
  var held=adventure.combat.held_cast
  if held.charges.has(my_id):
   var kind=str(data.get("kind","primary"));held.context[my_id]=held.charges[my_id].duplicate(true)
   var stats:Dictionary=held.stats_for(my_id,kind);held.context.erase(my_id)
   _preview_attack(kind,data,action_serial,stats)
func request_battleground_order(key:String)->void:
 if economy_pending:return
 economy_pending=true;economy_pending_at=Time.get_ticks_msec()
 _send_channel(host_id,{"type":"bg_upgrade","key":key})
 status_label.text="Barracks order sent • waiting for the server…"
func _battleground_view()->Dictionary:return battleground_render
func _flush_action_inputs()->void:
 if not net_ready or frames.is_empty():return
 send_net({"type":"input","match_id":match_id,"frames":frames,"event_ack":applied_seq})
 frames=[]
 metrics.action_input_flushes=int(metrics.get("action_input_flushes",0))+1
func _broadcast(data:Dictionary)->void:
 if dedicated and gateway!=null:
  if str(data.get("type",""))=="state":gateway.snapshot(self)
  else:gateway.broadcast_game(self,data)
func _has_open_link()->bool:return dedicated and gateway!=null or net_ready
func _track_card_progress()->void:
 if dedicated:
  if mode=="defense":
   var first=wave+1
   for foe in opponents:
    if not foe.has("defense_wave"):foe.defense_wave=wave
    first=mini(first,int(foe.defense_wave))
   var cleared=maxi(0,mini(wave,first-1))
   if north_gate.boss_spawned and not north_gate.boss_defeated:cleared=mini(cleared,29)
   defense_cleared_wave=maxi(defense_cleared_wave,cleared)
  return
 super._track_card_progress()
func _unhandled_input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F9:
  set_meta("fx_show_network_hud",not bool(get_meta("fx_show_network_hud",false)));get_viewport().set_input_as_handled();return
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F6:
  balanced_graphics=not balanced_graphics;_configure_rendering();get_viewport().set_input_as_handled();return
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F8:
  download_performance();get_viewport().set_input_as_handled();return
 if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F7:
  show_hit_geometry=not show_hit_geometry;get_viewport().set_input_as_handled();return
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE and started:
  if session_menu.page.is_empty():session_menu.main()
  else:session_menu.resume()
  return
 super._unhandled_input(event)
func _draw()->void:
 if dedicated:return
 var draw_began=Time.get_ticks_usec()
 ground_art.begin()
 set_meta("fx_drawing_world",true)
 if started:_observe_launches(shots_view.visuals(Time.get_ticks_msec()/1000.0),true)
 super._draw()
 set_meta("fx_drawing_world",false)
 client_perf.work("draw_commands",Time.get_ticks_usec()-draw_began)
 if not started:return
 draw_set_transform(media.offset(),0,Vector2.ONE*media.factor())
 # The short muzzle cue accompanies the travelling prediction.
 for shot in shots_view.cues:
  var now=Time.get_ticks_msec()/1000.0
  var age=now-float(shot.t)
  if age<0 or age>shots_view.MUZZLE_SECONDS:continue
  var direction:Vector2=shot.v.normalized()
  var p=_local_draw_position()+direction*27-camera
  var tint=Color(str(shot.color));tint.a=.7*(1-age/shots_view.MUZZLE_SECONDS)
  if selected_hero=="soccer":
   draw_line(p-direction*15,p+direction*8,tint,4,true)
   draw_circle(p+direction*5,8,tint)
   draw_circle(p+direction*5,3,Color(.12,.22,.20,tint.a))
  else:draw_arc(p,8+age*35,direction.angle()-.8,direction.angle()+.8,10,tint,3,true)
 if show_hit_geometry:
  for actor in positions:
   var ground:Vector2=local_pos if actor==my_id else remote_draw_pos.get(actor,positions[actor])
   var tint=Color("#ffdd77") if int(health.get(actor,0))>0 else Color("#888888")
   draw_arc(ground-camera,18,0,TAU,32,tint,2,true)
   var protected=Time.get_ticks_msec()<int(invincible_until.get(actor,0))
   if actor!=my_id:
    var info:Dictionary=world_view.data().get("players",{}).get(actor,{})
    protected=float(info.get("invincible",0))>_render_sample_age()*1000
   if protected:draw_arc(ground-camera,23,0,TAU,32,Color("#70dfff"),3,true)
 draw_set_transform(Vector2.ZERO)

func draw_ellipse_shadow(point:Vector2)->void:
 if balanced_graphics:ground_art.shadow(self,point)
 else:super.draw_ellipse_shadow(point)

func draw_ground_patch(point:Vector2,radius:float,fade:float,clock:float,kind:String)->bool:
 if dedicated:return false
 if not balanced_graphics:return false
 ground_art.draw_on(self,point,radius,fade,clock,kind,VIEW)
 return true

func _effect_at_actor(effect:Dictionary)->Dictionary:
 var owner=str(effect.get("owner",""))
 if owner.is_empty() or not positions.has(owner) or str(effect.get("style","")) not in ["melee","punch","scratch","slash","kick"]:return effect
 var anchored=effect.duplicate()
 anchored.pos=_local_draw_position() if owner==my_id else remote_draw_pos.get(owner,positions[owner])
 return anchored
func _draw_effect(effect:Dictionary)->void:
 super._draw_effect(_effect_at_actor(effect))

func melee_visual_position(owner:String,fallback:Vector2)->Vector2:
 if not positions.has(owner):return fallback
 if dedicated:return positions[owner]
 return _local_draw_position() if owner==my_id else remote_draw_pos.get(owner,positions[owner])

func _preview_attack(kind:String,data:Dictionary,seq:int,override_stats:Dictionary={})->void:
 if arena_world.shatter.active():return
 var stats:Dictionary=override_stats if not override_stats.is_empty() else adventure.combat.effective_stats(my_id,kind,characters.get(selected_hero,{}).get(kind,{}))
 var style=str(stats.get("style",""));var aim=Vector2.from_angle(float(data.get("angle",0)))
 var now=Time.get_ticks_msec()/1000.0
 predicted_pose_until=Time.get_ticks_msec()+240
 if style=="identity_strike":
  local_strikes.append({"owner":my_id,"pos":[local_pos.x,local_pos.y],"aim":[aim.x,aim.y],"visual":stats.get("visual","horns"),"range":stats.get("range",82),"time":.26,"action_seq":seq})
  predicted_actions[seq]=now+1.0

 if style=="burst_projectile":
  launch_trace[seq]={"seq":seq,"kind":kind,"sent_ms":Time.get_ticks_msec(),"received_ms":-1,"drawn_ms":-1}
  for n in clampi(int(stats.get("count",4)),1,5):pending_bursts.append({"seq":seq,"index":n,"at":now+n*float(stats.get("burst_interval",.1)),"aim":aim,"stats":stats})
  _advance_local_previews(0)
 var launch_seeds=preload("res://network/projectile_recipe.gd").seeds(stats,aim,_local_draw_position(),adventure.combat,my_id)
 if not launch_seeds.is_empty():
  launch_trace[seq]={"seq":seq,"kind":kind,"sent_ms":Time.get_ticks_msec(),"received_ms":-1,"drawn_ms":-1}
  while launch_trace.size()>64:launch_trace.erase(launch_trace.keys()[0])
  metrics.release_cues=int(metrics.get("release_cues",0))+1
  for seed in launch_seeds:
   shots_view.preview(my_id,seq,seed.p,seed.v,seed.color,now,int(seed.index),float(seed.range),float(seed.radius),seed.art)
   # The attack is requested after this frame's regular visual assembly. Add
   # its first image now so even that frame does not wait for another process.
   if seed.art.is_empty():missiles.append({"pos":seed.p,"owner":my_id,"color":seed.color})
   else:
    var art_seed:Dictionary=seed.art.duplicate(true);art_seed.owner=my_id;art_seed.pos=[seed.p.x,seed.p.y];art_seed.net_rendered=true;adventure.combat.projectiles.append(art_seed)
func _advance_local_previews(delta:float)->void:
 var now=Time.get_ticks_msec()/1000.0
 for seq in predicted_actions.keys():
  if now>float(predicted_actions[seq]):predicted_actions.erase(seq)
 for n in range(local_strikes.size()-1,-1,-1):
  local_strikes[n].time-=delta
  if float(local_strikes[n].time)<=0:local_strikes.remove_at(n)
 for n in range(pending_bursts.size()-1,-1,-1):
  var burst=pending_bursts[n]
  if now<float(burst.at):continue
  var stats:Dictionary=burst.stats;var direction:Vector2=burst.aim
  shots_view.preview(my_id,int(burst.seq),_local_draw_position()+direction*26,direction*float(stats.get("speed",480)),str(stats.get("color","#b5dc79")),now,int(burst.index),float(stats.get("range",360)),float(stats.get("projectile_radius",12)),_preview_art(stats,direction))
  var first_image:Dictionary=_preview_art(stats,direction);first_image.owner=my_id;first_image.pos=[_local_draw_position().x+direction.x*26,_local_draw_position().y+direction.y*26];first_image.net_rendered=true;adventure.combat.projectiles.append(first_image)
  pending_bursts.remove_at(n)
func predicted_identity_strikes()->Array:return local_strikes
func suppress_confirmed_strike(entry:Dictionary)->bool:return str(entry.owner)==my_id and predicted_actions.has(int(entry.get("action_seq",-1)))
func object_projectile_display(shot:Dictionary,fallback:Vector2)->Vector2:
 var identity:Dictionary=shot.duplicate();identity.custom=true
 var key=preload("res://network/world_view.gd").shot_key(identity)
 return shots_view.point(shots_view.tracks[key],Time.get_ticks_msec()/1000.0) if shots_view.tracks.has(key) else fallback

func _remote_position(actor:String,_now:float)->Vector2:
 return world_view.player(actor,positions.get(actor,Vector2.ZERO))
func _valid_state(data:Dictionary)->bool:
 return str(data.get("match_id",match_id))==match_id
func _buffer_state(data:Dictionary)->void:
 if not _valid_state(data):return
 # Keep recent full snapshots for interpolation. Superseded compressed packets
 # from a long stall are discarded by the inbox before expensive decoding.
 var all:Array=data.get("shots",[]).duplicate()
 var custom:Array=data.get("adventure",{}).get("combat",{}).get("projectiles",[])
 for shot in custom:
  if not shot.has("net_id"):continue
  var aim=adventure.combat.vec(shot.aim)*float(shot.speed)
  all.append({"net_id":shot.net_id,"pos":shot.pos,"velocity":[aim.x,aim.y],"owner":shot.owner,"color":shot.color,"action_seq":shot.get("action_seq",-1),"shot_index":shot.get("shot_index",0),"born":float(shot.get("born_tick",0))/60.0,"custom":true,"art":shot})
 data.render_shots=all
 var own:Array=[]
 for shot in all:
  if str(shot.owner)==my_id:own.append(shot)
 _observe_launches(all,false)
 shots_view.receive(own,Time.get_ticks_msec()/1000.0,int(data.server_tick))
 world_view.receive(data)
func _preview_art(stats:Dictionary,aim:Vector2)->Dictionary:
 return {"pos":[0,0],"aim":[aim.x,aim.y],"base_aim":[aim.x,aim.y],"origin":[0,0],"radius":float(stats.get("projectile_radius",12)),"style":"pellet","stats":stats.duplicate(true),"color":str(stats.get("color","#edf7ff")),"distance":0.0,"speed":float(stats.get("speed",480))}

func _update_remote_strikes()->void:
 var data=world_view.data()
 var remote:Array=data.get("adventure",{}).get("combat",{}).get("classics",{}).get("strikes",[])
 for entry in remote:
  if str(entry.owner)==my_id:continue
  var key=str(entry.owner)+":"+str(entry.get("action_seq",-1))
  if remote_strike_view.has(key):continue
  var age=.26-float(entry.time)+_render_sample_age()
  remote_strike_view[key]={"data":entry.duplicate(true),"began":world_view.render_time-age}
 for key in remote_strike_view.keys():
  if world_view.render_time-float(remote_strike_view[key].began)>=.34:remote_strike_view.erase(key)
func network_identity_strikes()->Array:
 var result:Array=[]
 for value in remote_strike_view.values():
  var copy:Dictionary=value.data.duplicate()
  copy.time=.26*clampf(1-(world_view.render_time-float(value.began))/.34,0,1)
  if float(copy.time)>0:result.append(copy)
 for entry in adventure.combat.classics.strikes:
  if str(entry.owner)==my_id:result.append(entry)
 return result
func _receive_effect(event:Dictionary)->void:
 if str(event.get("style",""))=="damage":
  confirmed_damage_events+=1
  recent_hit_events.append({"tick":last_snapshot_tick,"victim":str(event.get("victim","")),"amount":float(event.get("amount",0))})
  while recent_hit_events.size()>12:recent_hit_events.pop_front()
 super._receive_effect(event)

func _execute_due_actions(actor:String)->void:
 var actions:Array=server_actions.get(actor,[])
 while not actions.is_empty() and int(actions[0].get("input_seq",0))<=int(input_ack.get(actor,0)):
  gateway.execute_action(self,actor,actions.pop_front())

func _render_sample_age()->float:
 var values=world_view.pair()
 return maxf(0,world_view.render_time-float(values[0].t)) if not values.is_empty() else 0.0
func network_v112_effects()->Array:
 var result:Array=[]
 var data=world_view.data()
 for effect in data.get("adventure",{}).get("combat",{}).get("v112",{}).get("effects",[]):
  if str(effect.owner)==my_id:continue
  var copy:Dictionary=effect.duplicate();var elapsed=_render_sample_age()
  copy.age=float(copy.get("age",0))+elapsed;copy.time=float(copy.time)-elapsed
  if float(copy.time)>0:result.append(copy)
 for effect in adventure.combat.v112.effects:
  if str(effect.owner)==my_id:result.append(effect)
 return result

func rewind_melee_targets(actor:String,data:Dictionary)->Dictionary:
 if str(data.get("type",""))!="attack" or str(data.get("style",""))!="primary":return {}
 var stats:Dictionary=characters.get(str(hero_ids.get(actor,"")),{}).get("primary",{})
 if str(stats.get("style","")) not in ["melee","cone","arc","identity_strike"]:return {}
 if position_samples.is_empty():return {}
 var wanted=clampi(int(data.get("view_tick",authority_tick)),maxi(0,authority_tick-12),authority_tick)
 var sample:Dictionary=position_samples[0]
 for item in position_samples:
  if int(item.tick)<=wanted:sample=item
 var restore={}
 for other in positions:
  if other==actor or not sample.points.has(other):continue
  if int(health.get(other,0))<=0 or int(sample.hp.get(other,0))<=0:continue
  var historical:Vector2=sample.points[other]
  if positions[other].distance_to(historical)>100 or not _clear_path(positions[other],historical):continue
  restore[other]={"present":positions[other],"historical":historical};positions[other]=historical
 return restore
func restore_targets(saved:Dictionary)->void:
 for actor in saved:
  if positions.has(actor):positions[actor]=_move_actor(saved[actor].present,positions[actor]-saved[actor].historical)
func adventure_won(reason:String)->bool:
 if expedition.special() and not expedition.outcome.is_empty():return bool(expedition.outcome.get("won",false))
 if mode=="coop" and not realm_result.is_empty():return realm_result=="cleared"
 return super.adventure_won(reason)
func end_match(reason:String)->void:
 if not dedicated:super.end_match(reason);return
 if not started:return
 if expedition.special():expedition.finish(not reason.begins_with("Party defeated"))
 if mode=="coop":
  realm_result="defeated" if reason.begins_with("Party defeated") else "returned" if adventure.quests.active and adventure.quests.completed_count()<adventure.quests.data.get("quests",[]).size() else "cleared"
 if mode=="arena":
  for actor in positions:arena_outcomes[actor]=_arena_outcome(str(actor))
 started=false;results_reason=reason;status_label.text=reason
 if gateway!=null:gateway.snapshot(self)

func network_projectile_near(start:Vector2,finish:Vector2,key:String,point:Vector2,radius:float)->bool:
 if dedicated and key.begins_with("p:") and has_meta("fx_network_previous_positions"):
  var previous:Dictionary=get_meta("fx_network_previous_positions")
  var actor=key.trim_prefix("p:")
  if previous.has(actor):
   var old:Vector2=previous[actor]
   if old.distance_to(point)<120:
    return Geometry2D.get_closest_point_to_segment(Vector2.ZERO,start-old,finish-point).length()<=radius
 return super._segment_near(start,finish,point,radius)
func _projectile_near_player(start:Vector2,finish:Vector2,actor:String,radius:float)->bool:
 return network_projectile_near(start,finish,"p:"+actor,positions[actor],radius)

func receive_events(data:Dictionary)->void:
 if str(data.get("match_id",match_id))!=match_id:return
 var current=int(data.get("server_tick",last_snapshot_tick))
 for event in data.get("events",[]):
  if int(event.id)<=applied_seq:continue
  applied_seq=int(event.id)
  # Expired cosmetic effects must not all replay after a long connection stall.
  if current-int(event.get("tick",current))>30:continue
  render_events.append({"tick":int(event.get("tick",current)),"data":event.data})
 while render_events.size()>256:render_events.pop_front()

func _report_network()->void:
 if not OS.has_feature("web") or Time.get_ticks_msec()<report_at:return
 report_at=Time.get_ticks_msec()+1000
 var sample={"build":BUILD,"protocol":PROTOCOL,"fps":Engine.get_frames_per_second(),"rtt_ms":metrics.rtt_ms,"simulation_ms":metrics.tick_ms,"snapshot_ms":server_snapshot_ms,"authority_hz":server_hz,"prediction_queue":history.size(),"state_age_ms":Time.get_ticks_msec()-last_state_at,"buffer_ms":maxf(0,world_view.latest_time-world_view.render_time)*1000,"buffer_holds":world_view.underruns,"wire_bytes":metrics.wire_bytes,"disconnect_reason":disconnect_reason,"clock_resyncs":world_view.clock_resyncs,"max_world_backlog_ms":world_view.max_backlog*1000,"projectile_handoffs":shots_view.handoffs,"projectile_confirmations":shots_view.confirmations,"max_handoff_error_px":shots_view.max_handoff_error,"confirmed_damage_events":confirmed_damage_events,"recent_hit_events":recent_hit_events}
 sample.mode=mode;sample.realm=realm_id;sample.players=positions.size()
 sample.category=get_tree().root.get_node("FXActivity").gameplay_category(self)
 sample.platform="web"
 sample.moving=_actor_walking(my_id);sample.ai_players=bot_count;sample.human_players=maxi(0,positions.size()-bot_count)
 sample.wave=wave;sample.floor=floor_number;sample.gate_hp=gate_hp;sample.downed_heroes=downed.size()
 sample.rival_heroes=opponents.filter(func(e):return bool(e.get("campaign_hero",false))).size() if mode=="defense" else 0
 if expedition.special():sample.expedition={"between":expedition.between(),"overcharge":expedition.kind=="overcharge","attunement":expedition.kind=="attunement","tier":int(expedition.config.get("tier",1)),"shared_shards":expedition.expedition.carried,"depth":expedition.expedition.farthest,"streamed_chunks":expedition.expedition.chunks.size(),"bonus_events":expedition.completed_events()}
 if mode=="battlegrounds":sample.battlegrounds={"warzone":bg_map=="warzone","lanes":bg_team_size,"strategy_work":battlegrounds.work,"troops":battlegrounds.units.size(),"siege_shots":battlegrounds.shots.size(),"airstrike_warnings":battlegrounds.bombs.size(),"hearts":battlegrounds.heart_hp,"team":int(teams.get(my_id,-1))}
 sample.client_profile=client_perf.summary()
 var browser_json=JavaScriptBridge.eval("JSON.stringify(window.fxFrameTiming?window.fxFrameTiming.sample():{})",true)
 var parsed_browser=JSON.parse_string(str(browser_json))
 browser_timing=parsed_browser if parsed_browser is Dictionary else {}
 sample.browser_timing=browser_timing;sample.focused=not bool(browser_timing.get("hidden",false))
 sample.client_frame_gap_ms=client_frame_gap_ms;sample.frame_gap_peak_ms=frame_gap_peak_ms
 sample.frame_gap_stalls=frame_stalls;sample.delivery_gap_stalls=delivery_stalls;sample.last_stall_context=last_stall_context
 sample.visual_correction_px=local_view.correction.length()
 sample.terrain_geometry=terrain_cache.counters() if terrain_cache!=null and terrain_cache.has_method("counters") else {}
 sample.shell_resize_count=get_meta("fx_render_shell").resize_count if has_meta("fx_render_shell") else 0
 sample.long_frames_50ms=client_perf.long_frames
 sample.active_fps_cap=Engine.max_fps
 sample.engine_process_ms=Performance.get_monitor(Performance.TIME_PROCESS)*1000
 sample.engine_physics_ms=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000
 sample.draw_calls=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
 sample.primitives=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
 sample.projectiles=render_shots.size();sample.contacts=adventure.combat.feedback.contacts.size();sample.damage_labels=damage_labels.size()
 sample.firing=mobile.attacking if mobile.enabled else Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
 sample.pending_packets=metrics.get("pending_packets",0)
 sample.poll_budget_yields=metrics.get("poll_budget_yields",0)
 sample.coalesced_client_snapshots=metrics.get("coalesced_client_snapshots",0)
 sample.replayed_inputs=metrics.get("replayed_inputs",0)
 sample.render_scale_mode=get_tree().root.content_scale_mode
 sample.mobile_aim=[mobile.aim.x,mobile.aim.y]
 sample.mobile_attacking=mobile.attacking
 sample.last_action=metrics.get("last_action",{})
 sample.release_cues=metrics.get("release_cues",0)
 sample.action_input_flushes=metrics.get("action_input_flushes",0)
 sample.memory_bytes=int(Performance.get_monitor(Performance.MEMORY_STATIC))
 sample.video_memory_bytes=int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
 sample.texture_memory_bytes=int(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
 sample.render_objects=int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
 sample.scenery_chunks=scenery_view.chunks.size() if scenery_view!=null else 0
 sample.dash_afterimages=dash_view.records.size()
 sample.dash_samples=dash_view.emitted
 sample.dash_sample_owners=dash_view.owners.duplicate()
 sample.hud_rebuilds=network_hud.rebuilds if network_hud!=null else 0
 sample.authority_resets=metrics.get("authority_resets",0)
 sample.last_authority_reset=metrics.get("last_authority_reset","")
 sample.correction_histogram=[metrics.get("correction_1_8",0),metrics.get("correction_8_32",0),metrics.get("correction_32_plus",0)]
 sample.terrain_chunks=terrain_cache.chunks.size() if terrain_cache!=null else 0
 sample.mobile_controls=mobile.enabled
 sample.graphics_mode="auto" if balanced_graphics else "full"
 sample.quality_scale=render_budget.scale_for(balanced_graphics);sample.quality_changes=render_budget.changes
 sample.server_metrics=server_metrics;sample.gateway_metrics=gateway_metrics
 sample.server_metrics_age_ms=maxi(0,Time.get_ticks_msec()-int(metrics.get("server_metrics_received_at",Time.get_ticks_msec())))
 sample.resume_attempts=metrics.get("resume_attempts",0);sample.last_disconnect_reason=metrics.get("last_disconnect_reason","")
 sample.state_stalls=recovery_stalls;sample.state_stale_peak_ms=stale_peak_ms;sample.recovery_active=recovery_active
 sample.received_packets=wire_packet_count;sample.received_bytes=received_bytes;sample.coalesced_client_snapshots=metrics.get("coalesced_client_snapshots",0);sample.poll_budget_yields=metrics.get("poll_budget_yields",0)
 var render_size=get_viewport().get_texture().get_size()
 sample.render_size=[render_size.x,render_size.y]
 sample.server_build=server_build
 sample.gateway_rtt_ms=metrics.get("gateway_rtt_ms",-1)
 sample.snapshot_interarrival_ms=world_view.arrival_age*1000
 sample.target_buffer_ms=world_view.target_delay*1000
 sample.playback_rate=world_view.playback_rate
 sample.arrival_gap_max_ms=world_view.arrival_gaps.max()*1000 if not world_view.arrival_gaps.is_empty() else 0
 sample.ability_view_starts=ability_view.starts
 sample.ability_view_active=ability_view.active
 sample.ability_view_offset_px=local_pos.distance_to(_local_draw_position())
 sample.authoritative_build=network_build(my_id)
 sample.twister_effects=adventure.combat.twister.effects.size()
 sample.position_corrections=metrics.corrections
 sample.max_position_correction_px=metrics.max_correction
 sample.local_view_offset_px=local_pos.distance_to(_local_draw_position())
 sample.walking_actors={}
 for actor in positions:sample.walking_actors[str(actor)]=_actor_walking(str(actor))
 sample.action_ack_wait_ms=action_wait_ms
 sample.launch_received_ms=_delay_summary(launch_received_delays)
 sample.launch_drawn_ms=_delay_summary(launch_drawn_delays)
 sample.ice_walls=ice_walls.size()
 sample.oldest_wall_remaining=0.0
 for wall in ice_walls:sample.oldest_wall_remaining=maxf(sample.oldest_wall_remaining,float(wall.time))
 sample.client_profile.ground_effects=ground_art.counters()
 sample.mode=mode;sample.realm=realm_id
 sample.client_elapsed_ms=Time.get_ticks_msec();sample.match_elapsed_ms=int(run_time*1000);sample.active=started;sample.match_id=match_id;sample.room=net_room;sample.arena_map=arena_map;sample.arena_objective=arena_world.shatter.report() if arena_world.shatter.active() else arena_world.objective.report() if arena_world.objective.active() else {};sample.arena_variant={"closed_gates":arena_world.extra.doors.filter(func(d):return d.closed).size(),"cliffs":arena_world.extra.cliffs.size(),"torches_ready":arena_world.extra.torches.filter(func(t):return arena_world.clock>=float(t.ready)).size(),"light_radius":arena_world.extra.radius(my_id) if arena_map=="lanternfall" else 0};sample.enemies=opponents.size();sample.predicted_projectiles=shots_view.predicted.size();sample.prediction_expiries=shots_view.expired;sample.last_launch=metrics.get("last_launch",{});sample.hero=selected_hero;sample.players=positions.size();sample.viewport=[VIEW.x,VIEW.y]
 perf_latest=sample
 JavaScriptBridge.eval("window.fxPerf=window.fxPerf||{version:'V179-preview',samples:[]};window.fxPerf.samples.push("+JSON.stringify(sample)+");if(window.fxPerf.samples.length>180)window.fxPerf.samples.shift();",true)
 JavaScriptBridge.eval("if(window.fxDiagnostics)window.fxDiagnostics.sample("+JSON.stringify(sample)+");if(window.fxReports)window.fxReports.sample("+JSON.stringify(sample)+");",true)

func profile_work(kind:String,elapsed:int)->void:
 if not dedicated:client_perf.work(kind,elapsed)
func download_performance()->void:
 if not OS.has_feature("web"):return
 report_downloads+=1
 JavaScriptBridge.eval("(()=>{const r=window.fxPerf||{version:'V179-preview',samples:[]};r.graphics=window.fxDiagnostics?window.fxDiagnostics.inspect():{};const a=document.createElement('a');const u=URL.createObjectURL(new Blob([JSON.stringify(r,null,2)],{type:'application/json'}));a.href=u;a.download='Crossroads_V179_performance.json';a.click();setTimeout(()=>URL.revokeObjectURL(u),2000);})()",true)

func _actor_walking(id:String)->bool:
 if id==my_id:return float(net_dash.get(id,{}).get("time",0))>0 or super._actor_walking(id)
 return actor_motion.walking(id)
func local_cosmetic()->Dictionary:
 # Calendar/reward selection is static during this isolated arena test. Avoid
 # repeatedly rebuilding it from the drawing path; refresh twice per second.
 var now=Time.get_ticks_msec()
 if dedicated:return super.local_cosmetic()
 if now>=cosmetic_cache_until or cosmetic_cache.is_empty():
  cosmetic_cache=super.local_cosmetic();cosmetic_cache_until=now+500
 return cosmetic_cache

func _local_draw_position()->Vector2:
 return local_pos if dedicated else ability_view.point(local_view.point(local_pos,Engine.get_physics_interpolation_fraction()))
func _player_draw_position(id:String,fallback:Vector2)->Vector2:
 return _local_draw_position() if id==my_id else super._player_draw_position(id,fallback)
func _refresh_draw_camera()->void:
 var factor=media.factor() if media.game!=null else 1.0
 var framing=media.framing if media.game!=null else Vector2.ZERO
 var size=VIEW/factor
 camera=(arena_world.shatter.camera_point(_local_draw_position())+framing-size*.5).clamp(Vector2.ZERO,(FIELD.size-size).max(Vector2.ZERO))

func network_twister_view()->Dictionary:
 var twister=adventure.combat.twister
 var live={"effects":twister.effects,"charges":twister.charges,"links":twister.links,"clock":twister.clock}
 if dedicated:return live
 return preload("res://network/twister_view.gd").sample(world_view,my_id,live)

func _spawn_player(slot:int)->Vector2:
 if expedition.between():return preload("res://scripts/waylight_expedition.gd").ORIGIN+Vector2(slot*65,0)
 var point=super._spawn_player(slot)
 return _safe_arena_spawn(point,slot) if mode=="coop" else point
func network_relocate(owner:String,point:Vector2)->void:
 if not dedicated or not positions.has(owner):return
 positions[owner]=point;charges.erase(owner);net_dash.erase(owner);adventure.polish.momentum.erase(owner)
 player_epochs[owner]=int(player_epochs.get(owner,0))+1
 if owner==my_id:local_pos=point;dodge_time=0
func network_build(owner:String)->Dictionary:
 var empty={"technique":false,"final_technique":false,"crit_tier":0,"tuning":[0,0,0],"points":0}
 return legacy.builds.get(owner,empty) if dedicated else authority_builds.get(owner,empty)

func network_effect_records(module:String,collection:String,live:Array)->Array:
 if dedicated or not net_ready:return live
 var policy=preload("res://network/effect_anchors.gd")
 var result:Array=[]
 for record in live:
  var kind=str(record.get("kind",record.get("style","")))
  if not policy.attached(module,kind):result.append(record);continue
  if str(record.get("owner",""))==my_id:
   var copy=_aged_draw_record(record,minf(.1,maxf(0,(Time.get_ticks_msec()-last_state_at)/1000.0)))
   if not copy.is_empty():result.append(copy)
 var combat_view:Dictionary=world_view.data().get("adventure",{}).get("combat",{})
 var buffered:Dictionary=combat_view if module=="root" else combat_view.get(module,{})
 for record in buffered.get(collection,[]):
  var kind=str(record.get("kind",record.get("style","")))
  if str(record.get("owner",""))==my_id or not policy.attached(module,kind):continue
  var copy=_aged_draw_record(record,_render_sample_age())
  if not copy.is_empty():result.append(copy)
 return result
func _aged_draw_record(record:Dictionary,elapsed:float)->Dictionary:
 if record.has("time") and float(record.time)<=elapsed:return {}
 var copy=record.duplicate(true)
 if copy.has("time"):copy.time=float(copy.time)-elapsed
 for key in ["age","elapsed"]:
  if copy.has(key):copy[key]=float(copy[key])+elapsed
 return copy

func _sync_dash_view(delta:float)->void:
 dash_view.advance(delta)
 var pair=world_view.pair()
 for actor in positions:
  var active=false
  if actor==my_id:active=float(net_dash.get(actor,{}).get("time",0))>0
  elif not pair.is_empty():
   var sample:Dictionary=pair[0];var info:Dictionary=sample.data.get("players",{}).get(actor,{})
   var dash:Array=info.get("dash",[0,0,0])
   active=float(dash[0])>maxf(0,world_view.render_time-float(sample.t))
  var ground=_local_draw_position() if actor==my_id else remote_draw_pos.get(actor,positions[actor])
  dash_view.sample(str(actor),str(hero_ids.get(actor,"ram")),ground,active and presentation.page.is_empty() and int(health.get(actor,0))>0 and adventure.combat.visible_owner(str(actor)),adventure.combat.v110.resize(str(actor),Rect2(Vector2(-28,-42),Vector2(56,64))))
 trails.clear()
 for ghost in dash_view.records:
  trails.append({"pos":ghost.point,"time":ghost.left,"hero":ghost.hero,"rect":ghost.rect})

func _draw_world()->void:
 if expedition.between():expedition.expedition.draw_ground(self,camera);return
 if dedicated or mode!="arena" or spectating() or scenery_view==null:
  super._draw_world();return
 adventure.polish.draw_world(self,camera)
 motion_v85.draw_trails(self,camera)

func _observe_launches(shots:Array,drawn:bool)->void:
 if dedicated:return
 var now=Time.get_ticks_msec()
 for shot in shots:
  if str(shot.get("owner",""))!=my_id:continue
  var seq=int(shot.get("action_seq",shot.get("seq",-1)))
  if not launch_trace.has(seq):continue
  var record:Dictionary=launch_trace[seq]
  var key="drawn_ms" if drawn else "received_ms"
  if int(record[key])>=0:continue
  record[key]=now
  var samples:Array=launch_drawn_delays if drawn else launch_received_delays
  samples.append(maxi(0,now-int(record.sent_ms)))
  if samples.size()>64:samples.pop_front()
  metrics.last_launch=record.duplicate()
func _delay_summary(samples:Array)->Dictionary:
 if samples.is_empty():return {"samples":0}
 var ordered=samples.duplicate();ordered.sort()
 return {"samples":ordered.size(),"median":ordered[ordered.size()/2],"p95":ordered[mini(ordered.size()-1,int(ordered.size()*.95))],"max":ordered[-1]}

func visual_actor(key:String,point:Vector2)->Vector2:
 if not dedicated and key.begins_with("e:"):return world_view.enemy(int(key.substr(2)),point)
 return super.visual_actor(key,point)

func _charge_view_speed()->float:
 # Only ordinary charge families get a speed-bounded catch-up. Existing jump
 # and other stance-driven views retain their authored visual timing.
 for kind in ["primary","secondary","special"]:
  var stats:Dictionary=characters.get(selected_hero,{}).get(kind,{})
  if str(stats.get("style",""))=="charge":return maxf(1,float(stats.get("speed",680)))
 return 0.0

func _exit_tree()->void:
 if dedicated:return
 _track_card_progress();legacy.save()
 if is_inside_tree():get_tree().root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 super._exit_tree()
 Engine.max_fps=60
 if OS.has_feature("web"):JavaScriptBridge.eval("if(window.fxReports)window.fxReports.flush('leave');",true)

func _accept_expedition()->void:
 if expedition_offer.is_empty():return
 var problem=ExpeditionProfile.reserve(self,expedition_offer)
 if not problem.is_empty():
  send_net({"type":"expedition_cancel","id":str(expedition_offer.id)});net_status.text=problem;return
 send_net({"type":"expedition_accept","id":str(expedition_offer.id),"profile":expedition_offer.offer})
 presentation.close();net_status.text="Entry reserved • waiting for your partner’s confirmation…"
func _make_floor()->void:
 if not expedition.between():super._make_floor();return
 if terrain_cache!=null:terrain_cache.reset()
 adventure.setup("");opponents.clear();missiles.clear();guards.clear();field_obstacles.clear();world_buildings.clear();world_decorations.clear();world_patches.clear();world_fountains.clear();world_spawns.clear();ice_walls.clear()
 FIELD=Rect2(Vector2.ZERO,Vector2(33024,33024));world_terrain="forest";_rebuild_grid()
func _draw_minimap()->void:
 if not expedition.between():super._draw_minimap()
func draw_sprite(key:String,point:Vector2,size:Vector2)->void:_sprite(key,point,size)
func _max_hp(id:String)->int:return int(super._max_hp(id)*(1+expedition.relics.bonus(id,"vitality"))) if expedition.special() else super._max_hp(id)
func _hit_enemy(index:int,amount:float,killer:String)->void:
 if not expedition.special() or not dedicated:super._hit_enemy(index,amount,killer);return
 var foe:Dictionary=opponents[index] if index>=0 and index<opponents.size() else {}
 var old=float(foe.get("hp",0));var previous=expedition.current_killer;expedition.current_killer=killer
 super._hit_enemy(index,expedition.relics.damage(killer,amount),killer)
 expedition.current_killer=previous
 if not foe.is_empty():expedition.relics.hit(killer,foe,maxf(0,old-float(foe.get("hp",0))))
 for id in levels:
  if int(levels[id])>=10:levels[id]=10;xp[id]=0
func _hurt(id:String,amount:float,source:String="",melee_attacker:String="",cause:Dictionary={})->void:
 if expedition.special():
  if expedition.between() and positions.get(id,Vector2.ZERO).distance_to(preload("res://scripts/waylight_expedition.gd").ORIGIN)<105:return
  amount*=1+.08*expedition.expedition.farthest if expedition.between() else 1+.15*int(expedition.config.tier)
 super._hurt(id,amount,source,melee_attacker,cause)
