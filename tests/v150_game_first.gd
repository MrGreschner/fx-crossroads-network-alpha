extends SceneTree
const A=preload("res://scripts/education_access.gd")
var checks=0
var failures=0
func check(ok:bool,label:String)->void:
 checks+=1;print("PASS • " if ok else "FAIL • ",label)
 if not ok:failures+=1
func texts(node:Node)->String:
 var out=""
 if node is Label or node is Button:out+=node.text+"\n"
 for c in node.get_children():out+=texts(c)
 return out
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 8:await process_frame
 g.set_process(false);g.legacy.set_process(false);g.presentation.close();g.session_menu.resume();g.menu=""
 A.unlock("student");A.toggle("student",false)
 var w=g.hero_workshop;w.project=w.Project.fresh();w.project.concept="Kept idea";w.project.notes.hypothesis="Kept prediction";w.open();w.tabs.current_tab=0;w.render()
 check(not texts(w.content).contains("Design concept"),"normal hero editor hides concept prompt")
 check(texts(w.content).contains("Lore (optional)"),"optional game lore remains")
 w.tabs.current_tab=6;w.render();check(not texts(w.content).contains("Prediction •"),"normal test page hides reflection inputs")
 check(texts(w.content).contains("Start test"),"normal test tools remain")
 var report={"notes":{"hypothesis":"Kept prediction"},"project_hash":"test"}
 check(not w.report_summary(report).contains("## Prediction"),"normal readable report contains measurements without worksheets")
 var realm=load("res://scripts/studio_world_lab.gd").new();w.add_child(realm);realm.setup(w,true);realm.value.vision="Kept realm vision";realm.render()
 check(not texts(realm.tools).contains("Vision before building"),"normal realm editor begins with map controls")
 check(texts(realm.tools).contains("Map size:"),"normal realm settings remain")
 var object_lab=load("res://scripts/studio_world_lab.gd").new();w.add_child(object_lab);object_lab.setup(w,false)
 check(texts(object_lab.col).contains("OBJECT LAB") and not texts(object_lab.col).contains("RASTER"),"Object Lab label consistent")
 var m=g.legacy.commerce;m.open();m.view.tabs.current_tab=1;m.view.render()
 check(not m.report().contains("forecast"),"normal exported market report omits worksheets")
 check(not texts(m.view.page).contains("Forecast:") and not texts(m.view.page).contains("Reflection:"),"normal market hides written predictions")
 check(texts(m.view.page).contains("Price per unit"),"normal market strategy remains")
 m.view.tabs.current_tab=4;m.view.render();check(not texts(m.view.page).contains("Assessment evidence"),"trading help stays optional without assessment")
 A.toggle("student",true);w.tabs.current_tab=0;w.render();check(texts(w.content).contains("Design concept"),"Student Mode restores hero planning")
 w.tabs.current_tab=6;w.render();check(texts(w.content).contains("Prediction •"),"Student Mode restores test reflections")
 realm.render();check(texts(realm.tools).contains("Vision before building") and realm.value.vision=="Kept realm vision","Student Mode restores saved realm plan")
 m.view.tabs.current_tab=1;m.view.render();check(m.report().contains("forecast"),"student exported report retains written evidence")
 check(texts(m.view.page).contains("Forecast:") and texts(m.view.page).contains("Reflection:"),"Student Mode restores business notes")
 check(w.project.concept=="Kept idea" and w.project.notes.hypothesis=="Kept prediction","mode toggles preserve authored notes")
 A.toggle("student",false)
 var tips=preload("res://scripts/studio_lessons.gd").design();check(tips.size()==4 and not tips[3].has("task"),"normal guidance stays available without writing tasks")
 check(g.can_stand_at(g.commerce_town.DOOR),"market entrance stays walkable")
 for r in g.commerce_town.STOCK:check(not g.can_stand_at(r.get_center()),"market stock areas have collision")
 check(g.commerce_town.YARD.has_point(g.commerce_town.DOOR),"market door belongs to expanded yard")
 m.view.close();object_lab.queue_free();realm.queue_free();w.close()
 print("V150 ",checks," checks / ",failures," failures");quit(1 if failures else 0)
