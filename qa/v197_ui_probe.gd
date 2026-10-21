extends "res://qa/v196_ui_probe.gd"
func command(args:Array)->void:
 var spec=JSON.parse_string(str(args[0]));var action=str(spec.get("action",""))
 if action=="gallery197":
  await super.command([JSON.stringify({"action":"gallery196"})]);g.test_arena.select(g.arena_world.MAPS.keys().find("colour_clash"));g._test_arena_changed(g.test_arena.selected);JavaScriptBridge.eval("window.gallery197Ready=true;",true);return
 if action=="galleryCrown197":g.test_arena.select(g.arena_world.MAPS.keys().find("crown_chase"));g._test_arena_changed(g.test_arena.selected);return
 if action in ["colour197","crown197"]:
  g.net_panel.hide();g.role="host";g.my_id="p0";g.host_id="p0";g.spectator_host=false;g.arena_seats=8;g.rule_picker.select(0);g.arena_map="colour_clash" if action=="colour197" else "crown_chase";g._sync_arena_pickers()
  if g.roster.is_empty():
   for n in 8:
    var id="p"+str(n);g.roster.append({"id":id,"name":"Explorer "+str(n+1)});g._add_player(id,n);g.teams[id]=n%2;g.lobby_heroes[id]="cat" if n%2==1 else "ram"
  g._start_match();g.start_countdown=0;g.control.hide();g.session_menu.resume();g.presentation.close();g.local_pos=Vector2(1280,960);var o=g.arena_world.objective;o.elapsed=114;g.arena_world.clock=114
  for n in 8:
   var id="p"+str(n);g.positions[id]=Vector2(1280,960)+Vector2.from_angle(n*TAU/8)*Vector2(310,180) if n>0 else Vector2(1280,960)
   if action=="colour197":o.disc(Vector2(650+n%4*430,740+int(n/4)*450),270,o.group(id))
  if action=="colour197":o.beacons[0].owner=o.group("p0");o.beacons[1].owner=o.group("p3")
  else:o.crown.holder="p0";o.crown.pos=[1280,960];o.burdens.p0=24;o.scores.p0=41.5;o.scores.p1=28.2;o.scores.p3=19.3;o.held.p0=41.5
  g.level_cards.set_process(false);g.level_cards.panel.hide();g._process(.016);g.camera=g.local_pos-g.VIEW*.5;g.scenery_view.sync();g.terrain_cache.sync();g.queue_redraw();JavaScriptBridge.eval("window.objective197Ready=true;",true);return
 if action=="results197":
  g.arena_world.objective.finish();return
 super.command(args)
