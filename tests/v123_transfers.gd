extends SceneTree
var failures:=0
func check(ok:bool,title:String)->void:
 print("PASS: " if ok else "FAIL: ",title)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 await process_frame;g.set_process(false);g.presentation.close();g.session_menu.resume();g.menu=""
 var w=g.hero_workshop;w.project=JSON.parse_string(FileAccess.get_file_as_string("res://content/workshop/example-project.json"));w.open();await process_frame
 check(w.hub.is_visible_in_tree() and not g.visible,"workshop remains visible while underlying world is hidden")
 w.export_project();await process_frame
 var path=OS.get_user_data_dir()+"/workshop-transfer-test.json";w.native_dialog.file_selected.emit(path);await process_frame
 check(FileAccess.file_exists(path),"native project save callback writes file")
 check(w.read_project(FileAccess.get_file_as_string(path)),"saved project imports with embedded artwork")
 w.request_import(FileAccess.get_file_as_string(path));await process_frame
 var confirm:ConfirmationDialog
 for child in w.get_children():
  if child is ConfirmationDialog:confirm=child
 check(confirm!=null and confirm.visible,"UI import asks before replacing draft")
 if confirm!=null:confirm.confirmed.emit();await process_frame
 w.start_test();await process_frame;w.arena.set_process(false);w.arena.player=Vector2(420,270);w.arena.aim=Vector2.RIGHT;w.arena.cast("primary");w.arena.tick(.5);w.finish_test();await process_frame
 w.project.notes.observations="Measured a slow effect on a target."
 w.export_readable_report();await process_frame
 var report_path=OS.get_user_data_dir()+"/workshop-transfer-report.md";w.native_dialog.file_selected.emit(report_path);await process_frame
 check(FileAccess.get_file_as_string(report_path).contains("Measured a slow effect"),"readable report includes post-test reflection")
 w.export_report();await process_frame
 var data_path=OS.get_user_data_dir()+"/workshop-transfer-report.json";w.native_dialog.file_selected.emit(data_path);await process_frame
 var report:Variant=JSON.parse_string(FileAccess.get_file_as_string(data_path))
 check(report is Dictionary and report.get("format")=="fx-crossroads-test-report" and report.get("tested_build",{}).has("primary"),"JSON report includes tested ability build")
 w.close();check(g.visible,"closing restores world visibility")
 print("V123 transfers failures: ",failures);quit(1 if failures else 0)
