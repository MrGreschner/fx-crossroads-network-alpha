extends SceneTree
const C=preload("res://scripts/fishing_catalog.gd")
var failures=0
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;push_error(message)
func _initialize()->void:call_deferred("run")
func run()->void:
 if not InputMap.has_action("primary"):InputMap.add_action("primary")
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);current_scene=a
 for n in 14:await process_frame
 a.set_process(false);a.party_tools.auto_solo=false;a.presentation.close();a.session_menu.resume();a.legacy.set_process(false)
 a.my_id="local";a.host_id="local";a.role="host";a.started=true;a.start_countdown=0;a.shop_open="";a.health={"local":100};a.enemy_pool.assign(["bramble"]);a.hero_ids={"local":"ram"};a.positions={"local":Vector2(100,100)};a.legacy.fishing_records.state().rod=true
 var f=a.fishing
 for realm in ["silverfall","folded_coast","lantern_marsh","wayfarer"]:
  a.mode="coop";a.realm_id=realm;a._make_floor();f._process(.01)
  check(f.spots.size()==C.spots(realm).size(),"Co-op spots activate: "+realm)
  for spot in f.spots:
   var p=Vector2(spot.bank[0],spot.bank[1]);check(a._clear_path(p,p),"Co-op bank accessible: "+str(spot.id))
  var spot=f.spots[0];a.local_pos=Vector2(spot.bank[0],spot.bank[1]);a.positions.local=a.local_pos;f.activate();check(f.busy(),"Co-op cast starts")
  var before=a.missiles.size();a._attack_request("primary");check(a.missiles.size()==before,"Cast UI click does not fire an attack")
  f.timer=.01;f._process(.02);f.activate();check(f.phase=="landed","Co-op fish lands")
  f.finish_catch(false);check(not f.busy(),"Co-op release completes")
 a.mode="descent";a.floor_number=56;a.floor_seed=159;a._make_floor();f._process(.01)
 check(f.spots.size()==1,"Descent floor 56 hidden spring")
 if not f.spots.is_empty():
  var p=Vector2(f.spots[0].bank[0],f.spots[0].bank[1]);check(a._clear_path(p,p),"Floor 56 bank accessible")
 a.floor_number=55;f._process(.01);check(f.spots.is_empty(),"Spring absent on other floors")
 a.mode="arena";f._process(.01);check(f.spots.is_empty(),"No fishing in PvP arena")
 a.mode="coop";a.realm_id="silverfall";a.role="guest";a.host_id="host";a.local_pos=Vector2(1650,6240);f._process(.01);f.activate();check(f.phase=="waiting","Guest can use own rod and collection")
 a.health.local=0;f._process(.01);check(not f.busy(),"Death cancels guest fishing")
 a.started=false;a.queue_free();for n in 4:await process_frame
 print("Co-op fishing v159: "+str(failures)+" failures");quit(failures)
