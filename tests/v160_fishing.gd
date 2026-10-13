extends SceneTree
const C=preload("res://scripts/fishing_catalog.gd")
const R=preload("res://scripts/fishing_records.gd")
var failures=0
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;push_error(message)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 14:await process_frame
 g.presentation.close();g.session_menu.resume();g.set_process(false);g.legacy.set_process(false)
 var f=g.fishing;var r=g.legacy.fishing_records;r.legacy.data.fishing=r.defaults()
 check(C.fish().size()==32,"32 illustrated species")
 check(C.pools().town_pond.fish.size()==8,"8 pond species")
 check(C.pools().town_river.fish.size()==16,"16 river species")
 for id in C.fish():check(C.texture(id)!=null,"Embedded texture loads: "+str(id))
 for id in C.pools():
  var pool:Dictionary=C.pools()[id]
  check(pool.fish.size()>=3 and pool.fish.size()<=16,"Pool counts")
  for species in pool.fish:check(C.fish().has(species),"Known fish in "+str(id))
 var rarity_count={}
 for id in C.pools().town_pond.fish:
  var tier=str(C.fish()[id].rarity);rarity_count[tier]=int(rarity_count.get(tier,0))+1
 check(rarity_count=={"Common":3,"Uncommon":2,"Rare":2,"Legendary":1},"Pond rarity distribution")
 for pair in [["silverfall_spring",1,4],["silverfall_cascade",2,9]]:
  var rare=0
  for id in C.pools()[pair[0]].fish:
   if C.fish()[id].rarity=="Legendary":rare+=1
  check(rare==pair[1] and C.pools()[pair[0]].fish.size()==pair[2],"Silverfall pool distribution")
 check(R.valid(r.defaults()),"Default progress schema")
 var rng=RandomNumberGenerator.new();rng.seed=159
 var sample=C.roll("town_pond",rng)
 check(R.valid_catch(sample),"Rolled catch validates")
 check(not r.state().rod,"Rod starts undiscovered")
 g.position_in_world=Vector2(230,520);f._process(.01);f.activate();check(not f.busy(),"No fishing before rod")
 r.unlock();f.activate();check(f.phase=="waiting","F starts a cast")
 f.bite_at=.001;f._process(.02);check(f.phase=="bite","Cast reaches bite")
 f.activate();check(f.phase=="landed","Hook lands fish")
 f.finish_catch(true);check(r.state().kept.size()==1 and r.state().total==1,"Keep commits catch once")
 f.finish_catch(true);check(r.state().total==1,"Repeated button event does not duplicate catch")
 var id=str(r.state().kept[0].id);r.set_favorite(id);check(not r.favorite().is_empty(),"Favourite set")
 r.showcase(id,0);r.showcase(id,3);check(r.state().display[0]=="" and r.state().display[3]==id,"One specimen occupies one tank")
 check(R.valid(r.state()),"Completed record validates")
 var exported=g.legacy.bundle();check(g.legacy.validate(exported),"Fish included in validated full profile download")
 r.release(id);check(r.favorite().is_empty() and r.state().display[3]=="" and r.state().journal.size()==1,"Release clears displays, preserves discovery")
 f.activate();f.bite_at=.001;f._process(.02);f.timer=.01;f._process(.02);check(not f.busy(),"Missed bite cancels")
 f.activate();g.position_in_world+=Vector2(25,0);f._process(.02);check(not f.busy(),"Walking cancels cast")
 g.position_in_world=Vector2(230,520);f.activate();g.health-=1;f._process(.02);check(not f.busy(),"Damage cancels cast")
 var before=int(r.state().total);root.set_meta("fx_practice_continue",true);check(not r.complete(C.roll("town_river",rng),true),"Practice catch cannot award profile progress");root.remove_meta("fx_practice_continue");check(r.state().total==before,"Practice leaves journal unchanged")
 var original=r.state().duplicate(true);g.legacy.data.teacher=true;root.set_meta("fx_dev_match",true)
 check(r.state().rod and r.complete(C.roll("town_river",rng),true),"Game Dev can test a temporary fish collection")
 root.remove_meta("fx_dev_match");g.legacy.data.teacher=false;g.legacy.data.fishing=original
 var malformed=r.defaults();malformed.kept=[{"species":3}];check(not R.valid(malformed),"Malformed catch rejected")
 malformed=r.defaults();malformed.display=["bad","","","",""];check(not R.valid(malformed),"Dangling display rejected")
 for pool in ["town_pond","town_river"]:
  var p=C.pools()[pool].bank;check(g.clear_of_obstacles(Vector2(p[0],p[1]),20),"Town bank reachable: "+pool)
 check(g.clear_of_obstacles(f.SHOP,20),"Shop door reachable")
 var wall=g.town_v109.solid_rect("tower").grow(20)
 var route=g.town_scenery.routes[3]
 for n in range(1,route.size()):
  for t in 30:
   var p=route[n-1].lerp(route[n],float(t)/29)
   check(not wall.has_point(p) and not wall.has_point(p+Vector2(0,18)),"Patrol avoids Mistglass collider")
   check(not Rect2(1940,850,300,265).intersects(Rect2(p-Vector2(20,43),Vector2(40,48))),"Patrol sprite does not clip behind the Spire")
 g.legacy.data.tasks.realms=["grove","honeyglass","sunfield","folded_coast","moonburrow","moonveil","space"]
 for realm in ["silverfall","folded_coast","lantern_marsh","wayfarer"]:
  g.start_run(false,realm);g.presentation.close();g.menu=""
  for spot in C.spots(realm):
   var bank=Vector2(spot.bank[0],spot.bank[1]);check(g.clear_of_obstacles(bank,16),"Realm shore accessible: "+str(spot.id))
  f._process(.01);check(f.spots.size()==C.spots(realm).size(),"Correct spot activation")
 g.enter_region("town");f.open_shop();check(g.menu=="fishing_shop" and is_instance_valid(f.room),"Enterable shop")
 f.open_journal();check(is_instance_valid(f.journal),"Collection UI opens inside shop");f.close_journal();check(g.menu=="fishing_shop","Collection returns to shop");f.close_shop();check(g.menu=="","Shop exit restores town")
 g.queue_free();for n in 4:await process_frame
 print("Fishing v160: "+str(failures)+" failures");quit(failures)
