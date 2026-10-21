extends "res://qa/v194_ui_probe.gd"
func command(args:Array)->void:
 var spec=JSON.parse_string(str(args[0]));var action=str(spec.get("action",""))
 if action=="battle195":
  close187();g.queue_free();await process_frame
  root.set_meta("fx_dev_match",true);root.set_meta("fx_intro_seen",true)
  var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);current_scene=a;g=a;await process_frame;g.set_process(false);g.set_physics_process(false);g.legacy.set_process(false);g.party_tools.set_process(false);g.presentation.close();g.role="host";g.my_id="p0";g.host_id="p0";g.spectator_host=false;g._set_mode("battlegrounds");g.bg_team_size=3;g.bg_map="woodland";g.arena_seats=6
  for n in 6:
   var id="p"+str(n);g.roster.append({"id":id,"name":"Commander "+str(n+1)});g._add_player(id,n);g.teams[id]=n/3;g.lobby_heroes[id]="ram"
  g._start_match();g.start_countdown=0;g.control.hide();g.session_menu.resume();g.shop_open="";g.health.p0=80;g.gold.p0=900;var bg=g.battlegrounds
  g.local_pos=Vector2(950,2350);g.positions.p0=g.local_pos;g.camera=Vector2(400,1900);bg.clock=1.1
  for side in 2:
   var base=bg.bases[str(side)+":0"]
   for kind in 11:
    if not bg.available(kind,side):continue
    bg.spawn_unit(base,kind,0);var u=bg.units[bg.units.keys()[-1]];u.pos=Vector2(1150+kind%5*130,2090+int(kind/5)*150+side*60);u.last_x=u.pos.x;u.last_y=u.pos.y;u.attack_at=1.0 if kind%2==0 else -10;u.winding=kind%2==1;u.facing=1 if side==0 else -1
  JavaScriptBridge.eval("window.battle195Ready=true;",true);g.queue_redraw();return
 if action=="state195":
  var bg=g.battlegrounds;JavaScriptBridge.eval("window.state195="+JSON.stringify({"display":DisplayServer.get_name(),"ui":is_instance_valid(bg.command.ui),"started":g.started,"owner":bg.owners.has(g.my_id),"shop":g.shop_open,"page":g.presentation.page,"session":g.session_menu.page,"visible":bg.command.ui.visible if is_instance_valid(bg.command.ui) else false})+";",true);return
 if action=="orders195":g.battlegrounds.command.ui.choices.show();return
 if action=="capital195":g.camera=Vector2(5250,1870);g.local_pos=Vector2(5850,2350);g.positions.p0=g.local_pos;g.queue_redraw();return
 if action=="shop195":g.positions.p0=g.battlegrounds.bases[g.battlegrounds.owners.p0].pos;g.battlegrounds.open_shop();return
 super.command(args)
