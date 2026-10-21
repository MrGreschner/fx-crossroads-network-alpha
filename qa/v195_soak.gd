extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_dedicated_server",true);root.set_meta("fx_dev_match",true);root.get_node("FXActivity").set_enabled(false);root.get_node("FXCommunityHeroes").set_process(false)
 var a=load("res://network/arena.gd").new();root.add_child(a);current_scene=a;await process_frame;a.set_process(false);a.set_physics_process(false);a.legacy.set_process(false);a.mode="battlegrounds";a._set_mode("battlegrounds");a.bg_team_size=4;a.bg_map="warzone";a.arena_seats=8;a._sync_bg_pickers();a.role="host";a.spectator_host=false
 for n in 8:
  var id="p"+str(n);a.roster.append({"id":id,"name":id});a._add_player(id,n);a.teams[id]=n%2;a.lobby_heroes[id]="ram"
 a._start_match();a.start_countdown=0;var bg=a.battlegrounds
 for base in bg.bases.values():
  var kinds=[]
  for kind in bg.TYPES.size():
   if bg.available(kind,int(base.team)):kinds.append(kind)
  for n in 32:
   bg.spawn_unit(base,int(kinds[n%kinds.size()]),n);var u=bg.units[bg.units.keys()[-1]];u.pos=Vector2(3000 if int(base.team)==0 else 3800,1050+int(base.lane)*700+(n%8)*24);u.last_x=u.pos.x;u.last_y=u.pos.y
 var peak=bg.units.size();var began=Time.get_ticks_usec()
 for frame in 600:
  bg.step(1.0/60);a.adventure.combat.step(1.0/60);peak=maxi(peak,bg.units.size())
  if frame%60==0:print("SOAK frame ",frame," work ",bg.work," shots ",a.adventure.combat.projectiles.size()," elapsed ",(Time.get_ticks_usec()-began)/1000.0)
 var valid=peak<=256
 for u in bg.units.values():valid=valid and is_finite(u.pos.x) and is_finite(u.pos.y) and Rect2(Vector2.ZERO,bg.SIZE).has_point(u.pos) and float(u.hp)>0
 var result={"passed":valid,"simulated_seconds":10,"initial_troops":256,"peak_troops":peak,"surviving_troops":bg.units.size(),"projectiles":a.adventure.combat.projectiles.size(),"wall_simulation_ms":(Time.get_ticks_usec()-began)/1000.0,"strategy_work":bg.work}
 var f=FileAccess.open("res://validation/v195/army-soak.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close();print("V195 SOAK ",JSON.stringify(result));bg.command.bg=null;quit(0 if valid else 1)
