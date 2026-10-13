extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://network/client.tscn").instantiate();root.add_child(g);current_scene=g
 await process_frame
 g.preferred_hero="navigator";g.selected_hero="navigator";g.room_field.text=OS.get_environment("FX_TEST_ROOM");g.url_field.text=OS.get_environment("FX_TEST_URL") if not OS.get_environment("FX_TEST_URL").is_empty() else "ws://127.0.0.1:9081";g.connect_net("join")
 for n in 1800:
  await physics_frame
  if g.started:break
 if not g.started:push_error("Client never started");quit(1);return
 var visual={"owner":g.my_id,"style":"melee","pos":Vector2(-999,-999)}
 if g._effect_at_actor(visual).pos!=g.local_pos:push_error("Melee anchor failed");quit(1);return
 Input.action_press("move_left")
 for n in 120:await physics_frame
 Input.action_release("move_left")
 g._send_channel("server",{"type":"attack","style":"primary","angle":0.0,"target":[1500,900]})
 for n in 90:await physics_frame
 print("CLIENT_METRICS "+JSON.stringify(g.metrics)+" queue="+str(g.history.size())+" ready="+str(g.net_ready)+" closed="+str(g.net_peer.get_close_code())+" reason="+str(g.net_peer.get_close_reason()))
 var ok=g.net_ready and int(g.metrics.snapshots)>40 and g.history.size()<30 and float(g.metrics.max_correction)<5
 if not ok:push_error("Client sync failed")
 g.net_peer.close();g.queue_free();for n in 5:await process_frame
 quit(0 if ok else 1)
