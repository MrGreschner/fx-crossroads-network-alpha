extends SceneTree
const C=preload("res://scripts/fishing_catalog.gd")
var failures=0
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;push_error(message)
func _initialize()->void:call_deferred("run")
func run()->void:
 if not InputMap.has_action("primary"):InputMap.add_action("primary")
 root.get_node("FXActivity").set_process(false)
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);current_scene=a
 for n in 14:await process_frame
 a.set_process(false);a.party_tools.auto_solo=false;a.presentation.close();a.session_menu.resume();a.legacy.set_process(false)
 a.my_id="local";a.host_id="local";a.role="host";a.started=true;a.start_countdown=0;a.shop_open="";a.health={"local":100};a.enemy_pool.assign(["bramble"]);a.hero_ids={"local":"ram"};a.positions={"local":Vector2(100,100)};a.legacy.fishing_records.state().rod=true
 var f=a.fishing;var rng=RandomNumberGenerator.new();rng.seed=162
 check(C.fish().size()==46,"46 fish species")
 var added=[]
 for spec in [["descent38_spring",3],["gate_watchwater",3],["moonveil_canal",8]]:
  var pool=C.pools()[spec[0]];check(pool.fish.size()==spec[1],"New species count: "+spec[0])
  for id in pool.fish:
   check(id not in added,"Unique new species");added.append(id);check(C.texture(id)!=null,"Fish illustration: "+str(id))
   var fish=C.fish()[id];check(fish.chance>0 and fish.min_kg>0 and fish.max_kg>fish.min_kg,"Weighted species and sizes")
  for n in 30:check(preload("res://scripts/fishing_records.gd").valid_catch(C.roll(spec[0],rng)),"Valid generated catch: "+spec[0])
 for depth in [37,38,39,56,57]:
  a.mode="descent";a.floor_number=depth;a.floor_seed=162;a._make_floor();f._process(.01)
  check(f.spots.size()==(1 if depth in [38,56] else 0),"Correct Descent floor: "+str(depth))
  if not f.spots.is_empty():
   var bank=Vector2(f.spots[0].bank[0],f.spots[0].bank[1]);check(a._clear_path(bank,bank),"Reachable buried spring")
   a.local_pos=bank;a.positions.local=bank;f.activate();check(f.phase=="waiting","Cast on Descent "+str(depth));f.start_bite();f.activate();check(f.phase=="landed","Catch on Descent");f.finish_catch(true)
 a.mode="defense";a._make_floor();f._process(.01);check(f.spots.size()==1,"North Gate fishing spot")
 if not f.spots.is_empty():
  var bank=Vector2(f.spots[0].bank[0],f.spots[0].bank[1]);check(a._clear_path(bank,bank),"North Gate bank reachable");check(not a.north_gate.terrain_open(Vector2(f.spots[0].water[0],f.spots[0].water[1])),"Fishing target is in the real river")
  a.local_pos=bank;a.positions.local=bank;f.activate();check(f.phase=="waiting","North Gate cast");f.start_bite();f.activate();f.finish_catch(false)
 for realm in ["moonveil","silverfall","folded_coast","lantern_marsh"]:
  a.mode="coop";a.realm_id=realm;a._make_floor();f._process(.01);check(not f.spots.is_empty(),"Fishing in realm: "+realm)
  for spot in f.spots:
   var bank=Vector2(spot.bank[0],spot.bank[1]);check(a._clear_path(bank,bank),"Bank reachable: "+str(spot.id))
  a.role="guest";a.host_id="host";var bank=Vector2(f.spots[0].bank[0],f.spots[0].bank[1]);a.local_pos=bank;f.activate();check(f.busy(),"Guest can fish: "+realm);f.cancel("");a.role="host";a.host_id="local"
 a.mode="arena";f._process(.01);check(f.spots.is_empty(),"Arena has no fishing")
 a.mode="descent";a.floor_number=38;a.spectator_host=true;f._process(.01);check(f.spots.is_empty(),"Spectator cannot fish")
 a.started=false;a.queue_free();for n in 5:await process_frame
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 14:await process_frame
 g.set_process(false);g.presentation.close();g.session_menu.resume();g.legacy.set_process(false)
 g.mode="run";g.practice=false;g.tutorial.active=false;g.enter_region("moonveil");g.menu="";g.fishing._process(.01)
 check(g.fishing.spots.size()==1,"Solo Moonveil spot")
 for spot in g.fishing.spots:
  var bank=Vector2(spot.bank[0],spot.bank[1]);check(g.clear_of_obstacles(bank,16),"Solo canal bank reachable")
 check(g.legacy.validate(g.legacy.bundle()),"Expanded fish collection remains exportable")
 g.presentation.window("DAILY MISSION","daily");g.legacy.daily.ui(g.presentation.content)
 var text=FileAccess.get_file_as_string("res://scripts/daily_challenge.gd")
 check("DAILY MISSION" in text and "DAILY CHALLENGE" not in text,"Daily Mission naming")
 g.queue_free();for n in 4:await process_frame
 print("Fishing v162: "+str(failures)+" failures");quit(failures)
