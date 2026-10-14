extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://network/client.tscn").instantiate();root.add_child(g);current_scene=g
 await process_frame
 var kind=OS.get_environment("FX_TEST_KIND");var hero="sunflower" if kind=="host" else "ram"
 g.preferred_hero=hero;g.selected_hero=hero;g.room_field.text=OS.get_environment("FX_TEST_ROOM");g.url_field.text="ws://127.0.0.1:9082";g.connect_net(kind)
 var announced=false;var requested=false
 for n in 1800:
  await physics_frame
  if g.net_ready and not announced:print("TEST_ROOM "+g.net_room);announced=true
  if kind=="host" and g.roster.size()==2 and not requested:g.send_net({"type":"start"});requested=true
  if g.started:break
 if not g.started:push_error("Two-view match never started");quit(1);return
 var previous=Vector2.ZERO;var has_previous=false;var max_step=0.0;var samples=0;var previews=0;var remote_seeds=0;var errors=0;var measured_at=Time.get_ticks_msec();var previous_render=0.0
 for n in 360:
  for action in ["move_left","move_right","move_up","move_down"]:Input.action_release(action)
  var action=["move_right","move_left","move_down","move_up"][int(n/60)%4]
  Input.action_press(action)
  if kind=="host" and n%60==0:
   g._send_channel("server",{"type":"attack","style":"primary","angle":-PI/2,"target":[g.local_pos.x,g.local_pos.y-500]})
   if not g.shots_view.predicted.is_empty():
    var seed:Dictionary=g.shots_view.predicted[-1]
    if not bool(seed.get("custom",false)) or seed.art.style!="pellet" or float(seed.art.radius)!=12:errors+=1
    previews+=1
  await physics_frame
  var remote=""
  for id in g.positions:
   if id!=g.my_id:remote=id;break
  if not remote.is_empty() and n>30:
   var point:Vector2=g.remote_draw_pos.get(remote,g.positions[remote])
   if has_previous:
    var step=point.distance_to(previous);max_step=maxf(max_step,step)
    if step>15:print("JUMP_TRACE "+JSON.stringify({"n":n,"step":step,"previous":[previous.x,previous.y],"point":[point.x,point.y],"raw":[g.positions[remote].x,g.positions[remote].y],"render":g.world_view.render_time,"latest":g.world_view.latest_time,"size":g.world_view.snapshots.size(),"remote_hp":g.health[remote],"elapsed_ms":Time.get_ticks_msec()-measured_at,"render_delta":g.world_view.render_time-previous_render,"fps":Engine.get_frames_per_second()}))
   previous=point;has_previous=true;samples+=1;measured_at=Time.get_ticks_msec();previous_render=g.world_view.render_time
  for shot in g.render_shots:
   if str(shot.owner)!=g.my_id and bool(shot.get("custom",false)):remote_seeds+=1
 for action in ["move_left","move_right","move_up","move_down"]:Input.action_release(action)
 print("TWO_VIEW_METRICS "+JSON.stringify({"kind":kind,"samples":samples,"max_remote_step":max_step,"previews":previews,"remote_seeds":remote_seeds,"queue":g.history.size(),"rtt":g.metrics.rtt_ms,"snapshots":g.metrics.snapshots,"art_errors":errors,"underruns":g.world_view.underruns}))
 var ok=g.net_ready and samples>250 and max_step<15 and errors==0 and (previews>3 if kind=="host" else remote_seeds>20)
 if not ok:push_error("Two-view presentation failed")
 g.net_peer.close();g.queue_free();for n in 5:await process_frame
 quit(0 if ok else 1)
