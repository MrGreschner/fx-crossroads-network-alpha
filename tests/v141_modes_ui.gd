extends SceneTree
var failures=0
func check(ok:bool,t:String)->void:
 print("PASS • " if ok else "FAIL • ",t)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for i in 5:await process_frame
 g.set_process(false);g.presentation.close();g.session_menu.resume()
 var A=load("res://scripts/education_access.gd");var S=load("res://scripts/learning_store.gd")
 g.legacy.answer("studentModeOn");check(A.student(),"exact student chat unlock")
 g.legacy.answer("teacherModeOn");check(g.legacy.education_password and g.legacy.asking_code,"teacher asks for password")
 g.legacy.answer("wrong");check(not A.teacher(),"wrong teacher password rejected")
 g.legacy.answer("teacherModeOn");g.legacy.answer("56Gt9");check(A.teacher() and not root.get_node("FXDevSession").active,"teacher unlock gives no Dev powers")
 var broadcast=root.get_node("FXClassroom");broadcast.role="host";broadcast.started=true;broadcast.capture();check(not broadcast.capturing and "PRIVATE REVIEW" in broadcast.host_strip.get_child(0).text,"broadcast holds while teacher assessments are open");broadcast.role="";broadcast.started=false
 for child in g.legacy.get_children():if child.get_script()!=null and child.get_script().resource_path.ends_with("teacher_dashboard.gd"):child.finish()
 var page=load("res://scripts/learning_page.gd").new();g.legacy.add_child(page);page.setup(g.legacy);check(page.module_picker.item_count==9,"nine supplied modules, archived drafts hidden")
 page.module="CSE1110";page.tabs.current_tab=4;page.render()
 for i in 5:await process_frame
 check(page.panel.size.x<=1140 and page.panel.size.y<=680,"practice layout remains inside target panel")
 page.finish();await process_frame
 var payload=g.legacy.bundle();check(payload.saves.has("fx_education_access.json") and g.legacy.validate(payload),"persistent unlocks included in portable profile")
 g.legacy.answer("gameDev");g.legacy.answer("R4ms!");check(not root.get_node("FXDevSession").active,"former Dev password rejected")
 g.legacy.answer("gameDev");g.legacy.answer("R4ms!90");check(root.get_node("FXDevSession").active,"new Dev password accepted")
 check(not S.save(S.fresh()).is_empty(),"Dev profile cannot record assessed work")
 quit(failures)
