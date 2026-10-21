extends SceneTree
var checks=0
var failures=[]
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures.append(label);push_error(label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_dedicated_server",true);root.set_meta("fx_dev_match",true);root.get_node("FXActivity").set_enabled(false);root.get_node("FXCommunityHeroes").set_process(false)
 var g=load("res://network/arena.gd").new();root.add_child(g);current_scene=g;await process_frame;g.set_process(false);g.set_physics_process(false);g.legacy.set_process(false);g.mode="arena";g._set_mode("arena");g.arena_seats=4;g.role="host";g.spectator_host=false;g.my_id="p0";g.host_id="p0";g.arena_map="maze";g._sync_arena_pickers()
 for n in 4:
  var id="p"+str(n);g.roster.append({"id":id,"name":id});g._add_player(id,n);g.teams[id]=n%2;g.lobby_heroes[id]="ram"
 g._start_match();g.start_countdown=0;var w=g.arena_world;var v=w.extra
 check(g.arena_map=="maze" and w.MAPS.size()==7,"seven maps and maze choice preserved at start");check(v.walls.size()==82 and v.doors.size()==17,"authored maze walls and doors");check(v.build_stone_mesh().get_surface_count()==1,"maze stone geometry batches into one mesh")
 for id in g.positions:check(v.movement_clear(g.positions[id],g.positions[id]),"safe maze spawn "+id)
 check(not v.movement_clear(Vector2(650,100),Vector2(800,100)),"solid maze wall blocks walking");check(not g._clear_path(Vector2(650,100),Vector2(800,100)),"solid maze wall blocks projectiles")
 g.positions.p0=Vector2(360,360);w.clock=7.9;w.step(.01);check(v.doors[0].warning and not v.doors[0].closed,"amber warning before gate closes")
 w.clock=9.5;w.step(.01);check(v.doors[0].closed,"timed gate closes");check(not v.shot_clear(Vector2(650,360),Vector2(800,360)),"closed gate blocks shots")
 g.positions.p0=Vector2(720,360);w.step(.01);check(not v.doors[0].closed,"gate waits for doorway occupant")
 g.positions.p0=Vector2(1080,1080);v.chambers["5"].ready=0;w.clock=1;w.step(.01);check(v.chambers["5"].active and not v.chambers["5"].spawned,"room ambush warns before spawning")
 w.clock=3.1;w.step(.01);check(v.chambers["5"].spawned and g.opponents.size()==3,"three chamber enemies spawn")
 for e in g.opponents:check(v.movement_clear(e.pos,e.pos),"enemy spawns inside traversable room")
 var packet=JSON.parse_string(JSON.stringify(w.snapshot()));var clone=load("res://scripts/arena_world.gd").new();clone.setup(g,"maze");clone.receive(packet)
 check(clone.extra.doors.map(func(d):return d.closed)==v.doors.map(func(d):return d.closed),"gate state replicates through JSON");check(bool(clone.extra.chambers["5"].active)==bool(v.chambers["5"].active) and is_equal_approx(float(clone.extra.chambers["5"].until),float(v.chambers["5"].until)),"ambush state replicates")
 w.clock=17;w.step(.01);check(not v.chambers["5"].active,"ambush safety timeout releases room")
 g.opponents.clear();v.chambers["5"].active=true;v.chambers["5"].spawned=true;v.chambers["5"].until=100;w.step(.01);check(not v.chambers["5"].active,"defeating chamber enemies ends lock early")
 for door in v.doors:door.closed=false
 v.revision+=1;var p=Vector2(360,360);var goal=Vector2(1800,1080)
 for n in 600:p=g._move_actor(p,v.navigate("qa",p,goal)*12);w.clock+=.1
 check(p.distance_to(goal)<100,"maze navigation reaches another chamber")
 g.arena_map="lanternfall";g.floor_seed=196;w.setup(g,"lanternfall");g._rebuild_grid();v=w.extra;var terrain=v.cliffs.duplicate();var torches=v.torches.duplicate(true)
 check(terrain.size()>10 and torches.size()==14,"random cliffs and torch pool");check(v.build_stone_mesh().get_surface_count()==1,"random cliffs batch into one mesh");w.setup(g,"lanternfall");check(v.cliffs==terrain and v.torches==torches,"same seed yields identical terrain and pickups")
 g.floor_seed=197;w.setup(g,"lanternfall");check(v.cliffs!=terrain,"new match seed changes terrain");g.floor_seed=196;w.setup(g,"lanternfall")
 var cliff:Rect2=v.cliffs[0];var a=cliff.get_center()-Vector2(cliff.size.x,0);var b=cliff.get_center()+Vector2(cliff.size.x,0)
 check(not v.movement_clear(a,b),"cliffs block players");check(g._clear_path(a,b),"ranged projectiles pass over cliff");check(g._move_actor(a,b-a).x<cliff.position.x,"hero cannot dash through cliff")
 for torch in v.torches:check(v.movement_clear(w.point(torch.pos),w.point(torch.pos)),"torch reachable outside cliffs")
 g.positions.p0=Vector2(100,100);g.positions.p1=Vector2(2900,2300);g.positions.p2=Vector2(100,2300);g.positions.p3=Vector2(2900,100)
 w.clock=1;w.step(1);check(v.radius("p0")<360,"light fades over time");v.light.p0=171;w.step(1);check(v.radius("p0")==170,"light never becomes completely blind")
 var torch:Dictionary=v.torches[0];g.positions.p0=w.point(torch.pos);g.positions.p1=g.positions.p0;v.light.p0=200;v.light.p1=200;w.step(.01)
 check(v.radius("p0")>340 and v.radius("p1")<201,"contested pickup awarded to one hero only");check(float(torch.ready)>w.clock,"collected torch has respawn cooldown");var before=v.radius("p0");w.step(.01);check(v.radius("p0")<=before,"torch cannot be collected repeatedly")
 v.light.p0=510;torch.ready=0;w.step(.01);check(v.radius("p0")==520,"light capped to keep fog meaningful")
 packet=JSON.parse_string(JSON.stringify(w.snapshot()));clone.setup(g,"lanternfall");clone.receive(packet);check(is_equal_approx(clone.extra.radius("p0"),v.radius("p0")) and is_equal_approx(float(clone.extra.torches[0].ready),float(v.torches[0].ready)),"light and shared torch cooldown replicate")
 check(not v.can_see("p0",g.positions.p0+Vector2(900,0)),"bots cannot see beyond light radius");g.positions.p1=g.positions.p0+Vector2(100,0);g.teams.p1=1;g.health.p1=120;g.health.p3=0
 check(v.nearest_enemy("p0",g.positions.p0)==g.positions.p1,"beacon detects nearest living enemy");g.pvp_rule="teams";g.teams.p1=0;g.teams.p0=0;check(v.nearest_enemy("p0",g.positions.p0)!=g.positions.p1,"beacon excludes allies")
 g.health.p1=120;g.teams.p1=1;g.health.p3=120;g.positions.p1=g.positions.p0+Vector2(200,0);v.light.p0=170
 check(v.bot_wish("p0",g.positions.p0,Vector2.RIGHT,g.positions.p1).is_finite(),"AI uses fog arena navigation and pickups")
 g.health.p0=0;v.light.p0=170;w.step(.1);g.health.p0=120;g.positions.p0=Vector2(100,100);w.step(.1);check(v.radius("p0")>350,"respawn restores a fair light radius")
 for map in w.MAPS:
  g.arena_map=map;w.setup(g,map);check(w.map_id==map,"official map loads "+map)
 var result={"passed":failures.is_empty(),"checks":checks,"failures":failures};DirAccess.make_dir_recursive_absolute("res://validation/v196");var f=FileAccess.open("res://validation/v196/arenas.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"  "));f.close();print("V196 ARENAS ",JSON.stringify(result));quit(0 if failures.is_empty() else 1)
