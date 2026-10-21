extends "res://qa/v197_objectives.gd"
func run()->void:
 root.set_meta("fx_dedicated_server",true);root.set_meta("fx_dev_match",true);root.get_node("FXActivity").set_enabled(false);root.get_node("FXCommunityHeroes").set_process(false)
 g=load("res://network/arena.gd").new();root.add_child(g);current_scene=g;await process_frame;g.set_process(false);g.set_physics_process(false);g.legacy.set_process(false);g.mode="arena";g._set_mode("arena");g.arena_seats=8;g.role="host";g.spectator_host=false;g.my_id="p0";g.host_id="p0"
 g.roster.append({"id":"p0","name":"Player"});g._add_player("p0",0);g.lobby_heroes.p0="ram";g.bot_count=7;g.bots.sync_lobby()
 var result=[]
 for map in ["colour_clash","crown_chase"]:
  g.arena_map=map;g._sync_arena_pickers();g.rule_picker.select(0);g._start_match();g.start_countdown=0
  for id in g.positions:g.health[id]=100000;g.invincible_until[id]=0
  var o=g.arena_world.objective;var start_positions=g.positions.duplicate()
  for n in 1800:
   g.run_time+=1.0/60;g.bots.step(1.0/60);g.arena_world.step(1.0/60)
  var moved=0;var score=0.0
  for id in g.positions:
   if str(id).begins_with("bot:"):
    if g.positions[id].distance_to(start_positions[id])>100:moved+=1
    score+=float(o.scores.get(id,0))
  check(moved>=6,map+" AI heroes navigate the court");check(score>20 if map=="colour_clash" else score>1,map+" bots pursue and score the objective")
  result.append({"map":map,"simulated_seconds":30,"bots":7,"moved":moved,"objective_score":score})
 var data={"passed":failures.is_empty(),"checks":checks,"failures":failures,"results":result};var f=FileAccess.open("res://validation/v197/ai.json",FileAccess.WRITE);f.store_string(JSON.stringify(data,"  "));f.close();print("V197 AI ",JSON.stringify(data));quit(0 if failures.is_empty() else 1)
