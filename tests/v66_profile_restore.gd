extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);current_scene=game;await process_frame;game.set_process(false)
 var legacy=game.legacy;legacy.data=legacy.defaults();legacy.data.name="Student One";legacy.record("ram").damage=1234;game.selected_character="cat";game.provisions.packed="antidote_pear";game.provisions.paid=18;game.save_profile();game.provisions.save();legacy.save()
 var exported:Dictionary=legacy.bundle()
 legacy.enable_teacher();legacy.record("ram").technique=true;legacy.title_equip("ram");game.provisions.packed="";game.provisions.save();game.selected_character="robot";game.save_profile()
 check(legacy.bundle().saves["fx_provisions.json"].food=="antidote_pear","teacher downloads retain pre-test food")
 legacy.disable_teacher();await process_frame;await process_frame;game=current_scene;game.set_process(false)
 check(not game.legacy.data.teacher and game.legacy.data.name=="Student One" and game.legacy.record("ram").damage==1234,"leaving teacher restores normal mastery")
 check(game.provisions.packed=="antidote_pear","leaving teacher restores provision save")
 game.legacy.data.name="Changed";game.legacy.data.town.market=true;game.legacy.pending=exported;game.legacy.apply_import();await process_frame;await process_frame;game=current_scene;game.set_process(false)
 check(game.legacy.data.name=="Student One" and not game.legacy.data.town.get("market",false),"confirmed import replaces rather than merges profiles")
 check(game.selected_character=="cat" and game.provisions.packed=="antidote_pear","import restores selected hero and food")
 game.legacy.pending={"new":true};game.legacy.apply_import();await process_frame;await process_frame;game=current_scene;game.set_process(false)
 check(game.legacy.data.name=="Traveler" and game.legacy.data.heroes.is_empty() and game.provisions.packed.is_empty() and game.selected_character=="ram","new player resets shared PC progress")
 print("V66 profile restoration: ",failures," failures");game.queue_free();await process_frame;quit(1 if failures else 0)
