extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/arcade.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.party_tools.set_process(false);g.legacy.set_process(false)
 g._set_mode("coop");g.role="host";g.my_id="host";g.host_id="host";g.roster.assign([{"id":"host","name":"Host"},{"id":"friend","name":"Friend"}]);g._add_player("host",0);g._add_player("friend",1);g._start_match();g.start_countdown=0;g.field_obstacles.clear();g.obstacle_grid.clear();g.ice_walls.clear();g.opponents.clear();g.legacy.data=g.legacy.defaults();g.legacy.builds.clear()
 g.hero_ids.host="teacher";g.hero_ids.friend="recess";g.levels.host=10;g.levels.friend=10;g.health.host=100;g.health.friend=100;g.positions.host=Vector2(1000,1000);g.positions.friend=Vector2(1130,1000);g.local_pos=g.positions.host
 var c=g.adventure.combat;var r=c.release_heroes
 g.adventure.spawn("bramble",Vector2(1090,1000),300,false);g.cooldown_at.host={};g._attack("host","secondary",Vector2.RIGHT,Vector2(1090,1000))
 check(r.classes.has("host"),"host attack dispatch starts held control")
 r.step(.1);var pos:Vector2=g.opponents[0].pos;check(c.stunned(c.npc_key(g.opponents[0])) and pos.x<1090,"host pulls and inhibits foe attacks")
 var snap:Dictionary=r.snapshot();var replica=load("res://scripts/release_heroes.gd").new();replica.receive(snap);check(replica.snapshot()==snap,"all new effect state serializes");replica.free()
 r.holding("host",false);r.step(.01);check(not r.classes.has("host"),"host release works")
 # Remote holder uses existing packet channel rather than relying on host keyboard state.
 g.hero_ids.friend="teacher";g.cooldown_at.friend={};g._attack("friend","secondary",Vector2.LEFT,Vector2(1000,1000));check(r.classes.has("friend"),"guest attack dispatch creates control")
 g._packet("friend",{"type":"pos","x":1130,"y":1000,"secondary_held":false,"primary_angle":PI});r.step(.01)
 check(not r.classes.has("friend"),"remote release packet ends hold")
 g.hero_ids.friend="recess";g.cooldown_at.friend={};g._attack("friend","secondary",Vector2.LEFT,Vector2(1080,1000));g.opponents.clear()
 for n in 40:r.step(.1)
 check(g.health.host==116 and g.health.friend==116,"support heals both allies for exactly4 ticks")
 g.mode="arena";g.pvp_rule="ffa";r.reset();g.health.host=80;g.health.friend=80;g.cooldown_at.friend={};g._attack("friend","secondary",Vector2.LEFT,Vector2(1080,1000))
 for n in 40:r.step(.1)
 check(g.health.host==80 and g.health.friend==96,"arena enemies never receive snack healing")
 r.reset();g.hero_ids.host="teacher";g.cooldown_at.host={};g._attack("host","secondary",Vector2.RIGHT,Vector2(1130,1000));r.step(.01)
 check(c.stunned("p:friend"),"player rivals cannot attack while pulled")
 check(not c.v56.catch_shot(Vector2(1090,1000),Vector2(1080,1000),"host",20,"#ffffff"),"own projectiles are not captured")
 check(c.v56.catch_shot(Vector2(1090,1000),Vector2(1080,1000),"friend",20,"#ffffff"),"rival projectiles are captured")
 r.holding("host",false);r.step(.01)
 # The timed cap releases without a button-up event, including interrupted mobile input.
 g.cooldown_at.host={};g._attack("host","secondary",Vector2.RIGHT,Vector2(1130,1000));for n in 30:r.step(.1)
 check(not r.classes.has("host"),"hold safety cap releases after2.5s")
 g.mode="coop";r.reset();g.hero_ids.friend="briar";g.positions.friend=Vector2(1000,1000);g.health.friend=100;g.cooldown_at.friend={};c.statuses.clear();g._attack("friend","special",Vector2.RIGHT,Vector2(1260,1000))
 check(r.locked("friend"),"remote canopy flight locks walking")
 for n in 22:r.step(.03)
 check(not r.locked("friend") and g.positions.friend.distance_to(Vector2(1260,1000))<1,"remote flight reaches aimed endpoint")
 r.reset();g.hero_ids.friend="teacher";g.cooldown_at.friend={};g._attack("friend","special",Vector2.RIGHT,Vector2(1450,1000));r.step(.21)
 check(g.positions.friend.distance_to(Vector2(1450,1000))<1,"remote master key destination")
 print("v86 multiplayer failures: ",failures);g.queue_free();await process_frame;quit(failures)
