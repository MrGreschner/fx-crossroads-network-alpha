extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var g=load("res://scenes/arcade.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.party_tools.set_process(false);g.legacy.set_process(false)
 g._set_mode("coop");g.role="host";g.my_id="host";g.host_id="host";g.roster.assign([{"id":"host","name":"Host"},{"id":"friend","name":"Friend"}]);g._add_player("host",0);g._add_player("friend",1)
 for n in g.realm_picker.item_count:
  if str(g.realm_picker.get_item_metadata(n))=="confluence":g.realm_picker.select(n)
 g._start_match();g.start_countdown=0;g.legacy.data=g.legacy.defaults();g.legacy.builds.clear();g.hero_ids[g.my_id]="tidewright";g.hero_ids.friend="cantor";g.levels[g.my_id]=10;g.levels.friend=10;g.health[g.my_id]=200;g.health.friend=200
 var c=g.adventure.combat;var w=g.adventure.foundry
 check(w.active,"co-op loads foundry")
 g.positions[g.my_id]=Vector2(450,1200);g.positions.friend=Vector2(470,1250);g.local_pos=g.positions[g.my_id];g.opponents.clear();g.adventure.spawn("sluice_crab",Vector2(650,1200),1000,false)
 var key:String=c.npc_key(g.opponents[0]);var hp:float=g.opponents[0].hp
 c.confluence.hit(g.my_id,key,20,"water");c.confluence.hit("friend",key,20,"volt")
 check(absf(float(g.opponents[0].hp)-(hp-50))<.1,"friendly opposite marks add10 once")
 check(not c.confluence.marks.has(key),"reaction consumes marks")
 c.confluence.hit(g.my_id,key,20,"water");c.confluence.hit(g.my_id,key,20,"volt")
 check(absf(float(g.opponents[0].hp)-(hp-90))<.1,"same owner cannot self-trigger synergy")
 c.confluence.reset();g.mode="arena";g.pvp_rule="ffa";hp=g.opponents[0].hp
 c.confluence.hit(g.my_id,key,20,"water");c.confluence.hit("friend",key,20,"volt")
 check(absf(float(g.opponents[0].hp)-(hp-40))<.1,"rivals cannot combine marks")
 g.mode="coop";c.confluence.reset();g.opponents[0].pos=Vector2(650,1200);g.positions.friend=Vector2(500,1250)
 for owner in [g.my_id,"friend"]:
  var id:String=g.hero_ids[owner]
  for kind in ["primary","secondary","special"]:
   g.cooldown_at[owner]={};g._attack(owner,kind,Vector2.RIGHT,Vector2(650,1200))
 check(c.confluence.zones.size()>=2,"network attack dispatch creates complementary fields")
 c.confluence.step(.1)
 var snap:Dictionary=c.confluence.snapshot();var replica=load("res://scripts/confluence_heroes.gd").new();replica.receive(snap);check(replica.snapshot()==snap,"all visible combat effects replicate");replica.free()
 var world_copy=load("res://scripts/confluence_world.gd").new();world_copy.receive(w.snapshot());check(world_copy.snapshot()==w.snapshot(),"world gates hazards and completion replicate");world_copy.free()
 g.legacy.data=g.legacy.defaults();g.legacy_result_recorded=false;g.results_reason="Confluence Foundry cleared!";g.match_party_size=2;g.legacy_results()
 check(g.legacy.eligible("tidewright"),"co-op results award local paired mastery")
 var profile:Variant=JSON.parse_string(JSON.stringify(g.legacy.bundle()))
 check(g.legacy.validate(profile) and bool(profile.progress.heroes.tidewright.duet_clear),"portable profile preserves paired mastery")
 w.started.assign([0]);w.cleared.clear();g.opponents.clear();g.levels[g.my_id]=1;g.levels.friend=1;w.step(.01)
 check(g.levels[g.my_id]>=3 and g.levels.friend>=3,"co-op checkpoint unlocks secondary for both")
 # Every peer records only their own hero, using the host's same roster/result.
 g.legacy.data=g.legacy.defaults();g.hero_ids[g.my_id]="cantor";g.hero_ids.friend="tidewright";g.legacy_result_recorded=false;g.legacy_results()
 check(g.legacy.eligible("cantor"),"second pair member also earns mastery")
 g.legacy.data=g.legacy.defaults();g.hero_ids.friend="ram";g.legacy_result_recorded=false;g.legacy_results()
 check(not g.legacy.eligible("cantor"),"wrong pairing does not unlock")
 g.hero_ids.friend="kite";g.levels.friend=10;g.positions.friend=Vector2(500,1200);g.health.friend=100;g.cooldown_at.friend={};c.v79.holding("friend",true,Vector2.UP)
 g._attack("friend","secondary",Vector2.RIGHT,Vector2(650,1200))
 for n in 10:c.v79.step(.05)
 check(c.v79.moving("friend"),"remote hero orbits on host")
 g._packet("friend",{"type":"pos","x":500,"y":1200,"secondary_held":false,"primary_angle":PI});c.v79.step(.05)
 check(not c.v79.moving("friend") and c.v79.velocities.friend.normalized().distance_to(Vector2.LEFT)<.001,"remote release uses current packet aim")
 print("v84 co-op failures: ",failures);g.queue_free();await process_frame;quit(failures)
