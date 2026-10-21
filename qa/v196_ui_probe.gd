extends "res://qa/v195_ui_probe.gd"
func command(args:Array)->void:
 var spec=JSON.parse_string(str(args[0]));var action=str(spec.get("action",""))
 if action=="gallery196":
  close187();g.queue_free();await process_frame;root.set_meta("fx_dev_match",true);root.set_meta("fx_intro_seen",true);root.set_meta("fx_mode","arena");root.remove_meta("fx_dedicated_server")
  var a=load("res://network/arena.gd").new();root.add_child(a);current_scene=a;g=a;await process_frame;g.set_process(false);g.set_physics_process(false);g.legacy.set_process(false);g.DEFAULT_SERVER="ws://127.0.0.1:1";g.presentation.close();g.session_menu.resume();if g.browser_peer!=null:g.browser_peer.close();g.browser_peer=null
  g.net_panel.show();g.net_panel.size=Vector2(1240,690);g.net_panel.position=Vector2(20,15);g.test_arena.select(g.arena_world.MAPS.keys().find("maze"));g._test_arena_changed(g.test_arena.selected);g._sync_network_mode_controls();JavaScriptBridge.eval("window.gallery196Ready=true;window.state196="+JSON.stringify({"dedicated":g.dedicated,"visible":g.net_panel.visible,"rect":[g.net_panel.position.x,g.net_panel.position.y,g.net_panel.size.x,g.net_panel.size.y]})+";",true);return
 if action in ["maze196","fog196"]:
  g.net_panel.hide();g.role="host";g.my_id="p0";g.host_id="p0";g.spectator_host=false;g.arena_seats=4;g.arena_map="maze" if action=="maze196" else "lanternfall";g._sync_arena_pickers()
  if g.roster.is_empty():
   for n in 4:
    var id="p"+str(n);g.roster.append({"id":id,"name":"Explorer "+str(n+1)});g._add_player(id,n);g.teams[id]=n%2;g.lobby_heroes[id]="ram" if n%2==0 else "cat"
  g._start_match();g.start_countdown=0;g.control.hide();g.session_menu.resume();g.presentation.close();g.positions.p0=Vector2(1080,1080) if action=="maze196" else Vector2(1500,1200);g.local_pos=g.positions.p0;g.camera=g.local_pos-g.VIEW*.5;g.arena_world.clock=8;g.arena_world.step(.01)
  if action=="fog196":g.arena_world.extra.light.p0=300;g.arena_world.extra.torches[0].pos=[1580,1230];g.positions.p1=Vector2(1770,1250);g.positions.p2=Vector2(2200,1600)
  g.level_cards.set_process(false);g.level_cards.panel.hide();g._process(.016);g.camera=g.local_pos-g.VIEW*.5;g.scenery_view.sync();g.terrain_cache.sync();g.queue_redraw();JavaScriptBridge.eval("window.arena196Ready=true;",true);return
 if action=="resize196":
  g._process(.016);g.camera=g.local_pos-g.VIEW*.5;g.scenery_view.sync();g.terrain_cache.sync();g.queue_redraw();return
 if action=="galleryFog196":g.test_arena.select(g.arena_world.MAPS.keys().find("lanternfall"));g._test_arena_changed(g.test_arena.selected);return
 super.command(args)
