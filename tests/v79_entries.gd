extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var unbound=load("res://scripts/arena_world.gd").new()
 check(unbound.slow(Vector2.ZERO)==1,"unbound movement fallback")
 unbound.step(.1);unbound.draw()
 for mode in ["defense","descent","coop","arena"]:
  # Fresh scene every time: entering arena first used to hide the missing binding.
  var g=load("res://scenes/arcade.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.party_tools.set_process(false);g.legacy.set_process(false)
  check(g.arena_world.game==g,mode+" binds effects before first match")
  g._set_mode(mode)
  if mode in ["defense","descent"]:g._solo()
  else:
   g.role="host";g.my_id="host";g.host_id="host";g._add_player("host",0);g._add_player("friend",1);g._start_match()
  g._process(.016);g.set_process(false)
  check(g.started,mode+" starts with appropriate party size")
  check(g.arena_world.slow(g.local_pos)>0,mode+" movement does not read nil")
  g.arena_world.step(.1)
  g.queue_redraw();await process_frame;g.queue_free();await process_frame
 print("v79 entry failures: ",failures);quit(failures)
