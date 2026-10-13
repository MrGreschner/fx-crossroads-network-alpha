extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/arcade.tscn").instantiate();root.add_child(g);await process_frame
 g.set_process(false);g.party_tools.set_process(false);g.legacy.set_process(false)
 g._set_mode("defense");g._solo();g.set_process(false)
 var gate=g.north_gate
 for wave in [1,5,30,60]:
  g.opponents.clear();gate.spawn_wave(wave)
  for foe in g.opponents:
   var lane:int=foe.lane
   check(gate.distance_at(lane,foe.pos)>gate.length_of(lane)-100,"all wave actors enter at far end")
 for lane in 3:
  check(gate.enemy_spawn(lane,1,0)==gate.enemy_spawn(lane,60,0),"fixed entrance across waves")
 g.opponents.clear();g.wave=3;gate.spawn_rival()
 var rival:Dictionary=gate.rival_body()
 check(gate.distance_at(rival.lane,rival.pos)>gate.length_of(rival.lane)-100,"rival uses entrance")
 for lane in 3:
  var foe:Dictionary={"pos":gate.point_at(lane,100),"lane":lane,"type":"imp","uid":lane,"boss":false}
  var hp:float=gate.outpost_hp[lane]
  check(gate.hold_at_outpost(foe,.1),"checkpoint intercepts bypass")
  check(gate.distance_at(lane,foe.pos)>=gate.OUTPOST_DISTANCE[lane]+119,"enemy remains outside tower")
  check(gate.outpost_hp[lane]<hp,"enemy damages tower")
  gate.outpost_hp[lane]=1;foe.siege_timer=0;gate.hold_at_outpost(foe,1.5)
  check(gate.outpost_hp[lane]==0,"outpost can be destroyed")
  check(not gate.hold_at_outpost(foe,.1),"destroyed checkpoint allows advance")
 var guest=load("res://scripts/north_gate.gd").new();guest.receive(gate.snapshot())
 check(guest.outpost_hp==gate.outpost_hp,"co-op destruction state")
 g.guards.clear();gate.reinforce()
 check(g.guards.size()==6,"destroyed outposts stop spawning, bases send two each")
 for guard in g.guards:check(guard.speed==105,"slower guard movement")
 gate.setup(g);g.guards.clear();gate.reinforce()
 check(g.guards.size()==9,"fresh match restores three outposts")
 # Real movement follows each bent road, reaches the barricade and never hits base early.
 gate.setup(g);g.guards.clear();g.opponents.clear();g.wave=1;g.wave_timer=99999;g.guard_timer=99999
 for lane in 3:
  g.opponents.append({"pos":gate.enemy_spawn(lane,1,0),"lane":lane,"type":"imp","uid":100+lane,"hp":99999.0,"max_hp":99999.0,"boss":false,"attack_timer":0.0})
 var base_health:float=g.gate_hp
 for tick in 1000:g._simulate(.1)
 for lane in 3:check(gate.outpost_hp[lane]<gate.outpost_max,"actual road travel reaches tower " + str(lane))
 check(g.gate_hp==base_health,"base protected while outposts hold")
 g.queue_free();await process_frame
 print("v80 North Gate failures: ",failures);quit(failures)
