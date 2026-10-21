extends "res://qa/v197_ui_probe.gd"
func command(args:Array)->void:
 var spec=JSON.parse_string(str(args[0]));var action=str(spec.get("action",""))
 if action=="gallery198":
  super.command([JSON.stringify({"action":"gallery196"})]);await process_frame;await process_frame;await process_frame;g.test_arena.select(g.arena_world.MAPS.keys().find("shatterfloor"));g._test_arena_changed(g.test_arena.selected);return
 if action.begins_with("gallery198_"):
  var map=action.trim_prefix("gallery198_");g.test_arena.select(g.arena_world.MAPS.keys().find(map));g._test_arena_changed(g.test_arena.selected);return
 if action=="shatter198":
  g.net_panel.hide();g.role="host";g.my_id="p0";g.host_id="p0";g.spectator_host=false;g.arena_seats=8;g.rule_picker.select(0);g.arena_map="shatterfloor";g._sync_arena_pickers()
  if g.roster.is_empty():
   for n in 8:
    var id="p"+str(n);g.roster.append({"id":id,"name":"Explorer "+str(n+1)});g._add_player(id,n);g.teams[id]=n%2;g.lobby_heroes[id]="cat" if n%2==1 else "ram"
  g._start_match();g.start_countdown=0;g.control.hide();g.session_menu.resume();g.presentation.close();var s=g.arena_world.shatter;s.clock=12;s.round_time=12;g.positions.p0=Vector2(640,510);g.local_pos=g.positions.p0
  for n in 140:
   if n%11 in [0,1]:s.cells[0][n]=11
   elif n%7==0:s.cells[0][n]=12.6
  g.level_cards.set_process(false);g.level_cards.panel.hide();g._process(.016);g.camera=g.local_pos-g.VIEW*.5;g.scenery_view.sync();g.terrain_cache.sync();g.queue_redraw();return
 if action=="fall198":
  var s=g.arena_world.shatter;s.fall("p0");g.local_pos=g.positions.p0;g._refresh_draw_camera();g.scenery_view.sync();g.terrain_cache.sync();g.queue_redraw();return
 if action=="results198":
  var s=g.arena_world.shatter;s.round_number=3;s.round_time=35;s.eliminated={"p1":10,"p2":14,"p3":18,"p4":22,"p5":28,"p6":30,"p7":33};s.finish_round();return
 super.command(args)
