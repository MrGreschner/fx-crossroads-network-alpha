extends SceneTree
var failures:=0
func check(ok:bool,name:String)->void:
 if not ok:failures+=1;print("FAIL: ",name)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g;await process_frame;g.presentation.asked=true;g.profile.tutorial_seen=true
 g.legacy.data.favourites=["teacher"];g.legacy.record("teacher").damage=90000;g.legacy.save();g.save_profile()
 var paths:Array=g.legacy.save_names();paths.append("fx_legacy.json")
 for path in paths:
  for suffix in [".bak",".tmp"]:
   var file:=FileAccess.open("user://"+str(path)+suffix,FileAccess.WRITE);file.store_string('{"old_student":true}');file.close()
 g.session_menu.open("clear");g.session_menu.clear_profile()
 for n in 8:await process_frame
 var fresh:Node=current_scene
 check(fresh!=g and fresh.session_menu.page=="main","reset reloads a fresh main menu")
 check(fresh.legacy.data.favourites.is_empty() and fresh.legacy.record("teacher").damage==0,"mastery and favourites erased")
 check(not bool(fresh.profile.get("tutorial_seen",false)),"new player receives tutorial")
 for path in paths:
  check(not FileAccess.file_exists("user://"+str(path)+".bak") and not FileAccess.file_exists("user://"+str(path)+".tmp"),"old backups removed: "+str(path))
 fresh.queue_free();await process_frame;print("v87 profile reset failures: ",failures);quit(failures)
