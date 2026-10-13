extends SceneTree
var checks=0
var failures=0
func check(ok:bool,note:String)->void:
 checks+=1;print("PASS • " if ok else "FAIL • ",note)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 5:await process_frame
 g.set_process(false);g.legacy.set_process(false);g.presentation.close();g.session_menu.resume();g.menu=""
 g.presentation.adventures()
 var titles=[]
 for node in g.presentation.content.find_children("*","Button",true,false):titles.append(node.text)
 check(titles.any(func(t):return t.begins_with("IDLE MINING")) and titles.any(func(t):return t.begins_with("CROSSROADS MARKET")),"Adventures contains both account simulations")
 check(not titles.any(func(t):return t.begins_with("CROSSROADS ACADEMY")),"locked curriculum entry hidden from Adventures")
 g.presentation.choose_adventure("mine");check(g.menu=="idle_mine" and g.legacy.mine.view.active,"Adventure tile opens Mine directly")
 g.legacy.mine.commission();g.legacy.mine.view.render()
 for n in 6:g.legacy.mine.view.tabs.current_tab=n;await process_frame
 check(g.legacy.mine.view.labels.has("furnace"),"Smelter tab has live furnace feedback")
 root.size=Vector2i(896,414)
 for n in 4:await process_frame
 print("MINE BOUNDS: ",root.size," visible ",root.get_visible_rect()," panel ",g.legacy.mine.view.panel.get_global_rect());check(root.get_visible_rect().encloses(g.legacy.mine.view.panel.get_global_rect()),"Mine panel fits a small landscape screen")
 root.size=Vector2i(1280,720)
 g.legacy.mine.view.close();check(g.visible and g.menu.is_empty(),"Mine navigation restores town")
 g.presentation.adventures();g.presentation.choose_adventure("market");check(g.menu=="commerce" and g.legacy.commerce.view.active,"Adventure tile opens Market directly")
 for n in 5:g.legacy.commerce.view.tabs.current_tab=n;await process_frame
 root.size=Vector2i(896,414)
 for n in 4:await process_frame
 print("MARKET BOUNDS: ",root.size," visible ",root.get_visible_rect()," panel ",g.legacy.commerce.view.panel.get_global_rect());check(root.get_visible_rect().encloses(g.legacy.commerce.view.panel.get_global_rect()),"Market panel fits a small landscape screen")
 root.size=Vector2i(1280,720)
 g.legacy.commerce.view.close();check(g.visible and g.menu.is_empty(),"Market navigation restores town")
 var bundle=g.legacy.bundle();check(g.legacy.validate(bundle),"whole player profile retains foundry and new market stock")
 var zip="user://v144-player.zip";check(preload("res://scripts/studio_bundle.gd").make(bundle,zip)==OK,"profile ZIP export")
 var decoded=preload("res://scripts/studio_bundle.gd").read(zip);check(decoded.error.is_empty() and decoded.payload.progress.mine.has("foundry") and g.legacy.validate(decoded.payload),"profile ZIP includes metal and furnace state")
 var patch_count=g.ground_patches.size();var points=[]
 for x in range(-22,49):
  for y in range(-9,36):points.append(Vector2(x*64+32,y*64+32))
 var expected=[];var start=Time.get_ticks_usec()
 for point in points:
  var tile="grass"
  for patch in g.ground_patches:
   if Geometry2D.is_point_in_polygon(point,patch.polygon):tile=str(patch.tile)
  expected.append(tile)
 var slow=Time.get_ticks_usec()-start
 g.ground_index.invalidate();start=Time.get_ticks_usec();var equal=true
 for n in points.size():
  if g.ground_index.tile(points[n],"grass",g.ground_patches)!=expected[n]:equal=false
 var fast=Time.get_ticks_usec()-start
 check(equal,"indexed terrain exactly matches full scan across all town tiles")
 check(g.ground_index.candidate_checks<points.size()*patch_count/4,"terrain cold-build polygon checks reduced by at least 75 percent")
 print("TERRAIN BENCHMARK • points=",points.size()," patches=",patch_count," full_checks=",points.size()*patch_count," indexed_checks=",g.ground_index.candidate_checks," scan_us=",slow," index_us=",fast)
 for realm in ["grove","honeyglass","zombie"]:
  if not g.realms.has(realm):continue
  g.enter_region(realm);check(not g.ground_index.ready,"realm change invalidates path index: "+realm)
  var match_tiles=true
  for n in 200:
   var tx=n%20;var ty=n/20;var point=Vector2(tx*64+32,ty*64+32);var wanted=str(g.region.get("terrain","forest"))
   for patch in g.ground_patches:
    if Geometry2D.is_point_in_polygon(point,patch.polygon):wanted=str(patch.tile)
   if g.ground_tile_at(tx,ty,str(g.region.get("terrain","forest")))!=wanted:match_tiles=false
  check(match_tiles,"cached indexed path selection correct: "+realm)
 var path="user://v144-save-test.json";var sample={"value":13,"name":"Ram"};var serialized=JSON.stringify(sample)
 check(preload("res://scripts/profile_store.gd").write(path,sample,serialized)==OK and FileAccess.get_file_as_string(path)==serialized,"single-serialization save retains file contents")
 g.enter_region("town");g.menu="supplies";g.catalog_ui.context="supplies";g.catalog_ui.entries=[]
 var key=InputEventKey.new();key.keycode=KEY_DOWN;key.pressed=true;g.catalog_ui.key(key);check(g.catalog_ui.entries.is_empty(),"empty list keyboard navigation is safe")
 for voice in g.journey.voices:voice.stop()
 g.free();await create_timer(.3).timeout
 print("V144 RUNTIME CHECKS: ",checks,"; FAILURES: ",failures);quit(1 if failures else 0)
