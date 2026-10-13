extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 for count in [1,2,3]:
  var g=load("res://scenes/arcade.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.party_tools.set_process(false);g.legacy.set_process(false)
  g._set_mode("defense");g._solo();g.start_countdown=0
  for n in range(1,count):g._add_player("p"+str(n),n)
  g.north_gate.setup(g)
  check(g.player_limit()==3,"defence cap is three")
  g._simulate(.01)
  check(g.wave==1 and g.wave_timer==float(g.north_gate.config.second_wave_delay),"first wave immediate, second arrives sooner")
  var gate=g.north_gate;var foe:Dictionary=g.opponents[0]
  check(gate.opening_speed(foe,.1)==2,"first wave eight-second march boost")
  gate.opening_speed(foe,8);check(gate.opening_speed(foe,.1)==1,"boost expires")
  g.guards.clear();gate.reinforce()
  for guard in g.guards:check(guard.speed==105,"guards slowed to105")
  g.wave=3;gate.step(.1)
  var rivals:Array=g.opponents.filter(func(e):return bool(e.get("campaign_hero",false)))
  check(rivals.size()==count,"one enemy hero per player")
  for n in count:
   var id:String=gate.RIVALS[n];var body:Dictionary=gate.rival_body(id)
   check(int(body.lane)==n,"dedicated lane for each rival")
   gate.rival_gain(20,id);check(int(gate.rival_state(id).level)>1,"independent hero XP")
   body.hp=0;gate.killed(body);g.opponents.erase(body);gate.rival_state(id).respawn=.01
  gate.step(.02)
  for n in count:check(not gate.rival_body(gate.RIVALS[n]).is_empty(),"every rival respawns")
  var replica=load("res://scripts/north_gate.gd").new();replica.receive(gate.snapshot());check(replica.rivals==gate.rivals,"all rival states replicate")
  # Test each kit at its own front line, past the destroyed checkpoint.
  gate.outpost_hp.assign([0.0,0.0,0.0]);g.guards.clear()
  for n in count:
   var id:String=gate.RIVALS[n];var body:Dictionary=gate.rival_body(id);gate.rival_state(id).level=6
   var pos:Vector2=gate.point_at(n,gate.OUTPOST_DISTANCE[n]+600)
   g.positions.solo=pos;g.health.solo=1000;body.pos=pos+Vector2(80 if n==1 else 300,0);body.target="p:solo";body.think=1;body.attack_timer=0;body.secondary_cd=0;body.special_cd=0
   gate.step_rival(body,.05)
   check(float(body.attack_timer)>0,"each rival uses primary")
  g._room_config({"config":{"mode":"defense","ai_difficulty":"hard"}});check(g.ai_difficulty=="hard" and g.match_config().ai_difficulty=="hard","difficulty roundtrip")
  g.queue_free();await process_frame
 print("v83 gate failures: ",failures);quit(failures)
