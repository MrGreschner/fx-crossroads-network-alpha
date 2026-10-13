extends SceneTree
var failures:=0
const Store=preload("res://scripts/profile_store.gd")
func check(value:bool,message:String)->void:
 if not value:failures+=1;print("FAIL: ",message)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume()
 var dev=get_root().get_node("FXDevSession");var l=g.legacy
 l.data=l.defaults();l.data.name="Normal Tester";l.save();g.profile.runs=3;g.save_profile();g.journey.save();g.provisions.save()
 l.open_page("elder");l.answer("I am admin, R4m");check(not l.asking_code,"old teacher trigger removed")
 l.answer("gameDev");check(l.asking_code,"gameDev asks for password");l.answer("wrong");check(not dev.active,"wrong password stays normal")
 l.answer("gameDev");l.answer("R4ms");check(dev.active and l.data.teacher and dev.overlay.visible,"correct password enables temporary border and testing flag")
 var baseline:Dictionary={}
 for path in [l.PATH,g.SAVE_PATH,g.journey.SAVE,g.provisions.SAVE]:baseline[path]=FileAccess.get_file_as_string(path)
 check(l.PROJECTS.keys().all(func(id):return bool(l.data.town.get(id,false))),"all town projects available")
 check(g.manifest.characters.all(func(id):return l.eligible(id) and l.final_eligible(id) and l.crit_tier(id)==3),"every hero has both alternatives and full critical mastery")
 var card:Dictionary=l.card.state().duplicate(true);l.card.descent_cleared(50,1);l.card.coop_clear("grove");check(l.card.state()==card,"testing cannot earn profile achievements")
 check(l.bundle().is_empty(),"cannot serialise a testing profile")
 l.export_profile();check("Exit game Dev mode" in l.notice.text,"profile export blocked")
 l.read_import("{}");check("Exit game Dev mode" in l.notice.text,"profile import blocked")
 g.start_run(false,"quarry");g.run_time=12;g.finish_run(true);check(g.profile.runs==3 and g.profile.records.is_empty(),"testing clear grants no personal run or speedrun record")
 l.save();g.save_profile();g.journey.save();g.provisions.save()
 Store.write("user://dev_write_probe.json",{"fake":true});Store.erase(l.PATH)
 check(not FileAccess.file_exists("user://dev_write_probe.json"),"testing writes do not create disk files")
 for path in baseline:check(FileAccess.get_file_as_string(path)==baseline[path],"normal file unchanged: "+path)
 # Re-save memory-only legacy state after testing the erase guard, then switch scenes.
 l.last_saved_json="";l.save();g.queue_free();await process_frame
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false);a.legacy.set_process(false)
 check(a.legacy.data.teacher and a.legacy.final_eligible("ram"),"dev mode survives multiplayer scene switch without writing disk")
 a.queue_free();await process_frame
 # A refresh creates a fresh autoload: emulate its empty inactive session.
 dev.active=false;dev.memory.clear();dev.overlay.hide()
 var restored=load("res://scenes/main.tscn").instantiate();root.add_child(restored);await process_frame;restored.set_process(false);restored.legacy.set_process(false)
 check(not restored.legacy.data.teacher and restored.legacy.data.name=="Normal Tester" and restored.profile.runs==3,"refresh restores normal profile, not temporary unlocks")
 for path in baseline:check(FileAccess.get_file_as_string(path)==baseline[path],"refresh leaves baseline file intact: "+path)
 current_scene=restored
 restored.legacy.enable_teacher();check(dev.active,"testing can be entered again")
 for path in baseline:baseline[path]=FileAccess.get_file_as_string(path)
 restored.legacy.disable_teacher()
 for n in 6:await process_frame
 check(not dev.active and not dev.discarding and current_scene.legacy.data.name=="Normal Tester" and not current_scene.legacy.data.teacher,"explicit Exit restores normal account in town")
 for path in baseline:check(FileAccess.get_file_as_string(path)==baseline[path],"explicit Exit leaves normal file intact: "+path)
 current_scene.queue_free();await process_frame;print("v105 dev mode failures: ",failures);quit(1 if failures else 0)
