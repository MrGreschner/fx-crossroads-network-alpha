extends SceneTree
const A=preload("res://scripts/education_access.gd")
const S=preload("res://scripts/learning_store.gd")
const R=preload("res://scripts/rolling_crowns.gd")
var failures=0
func check(ok:bool,t:String)->void:
 print("PASS • " if ok else "FAIL • ",t)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for i in 5:await process_frame
 g.set_process(false);g.presentation.close();g.session_menu.resume();g.legacy.set_process(false)
 var crown=g.legacy.crowns;crown.time_for_test=1770000000;g.legacy.data.rolling_damage={"version":1,"buckets":[]};crown.refresh()
 crown.add_damage(1200);check(crown.total()==1200 and crown.payload().crown_tier==1,"normal damage earns rolling crown")
 crown.time_for_test+=60;crown.add_damage(1800);check(crown.total()==3000 and crown.payload().crown_tier==2,"damage aggregates across minutes")
 crown.time_for_test=1770000000+R.WINDOW-60;crown.refresh();check(crown.total()==3000,"Sunday does not reset Monday history")
 crown.time_for_test=1770000000+R.WINDOW;crown.refresh();check(crown.total()==1800 and crown.payload().crown_tier==1,"oldest damage expires seven days later")
 crown.time_for_test+=60;crown.refresh();check(crown.total()==0 and crown.payload().crown_tier==0,"entire inactive history ages out")
 crown.add_damage(40000);crown.step(11);check(R.valid(JSON.parse_string(FileAccess.get_file_as_string(g.legacy.PATH)).rolling_damage),"history persists in progress file")
 var bundle=g.legacy.bundle();check(g.legacy.validate(JSON.parse_string(JSON.stringify(bundle))),"portable player profile carries rolling history")
 var malformed=bundle.duplicate(true);malformed.progress.rolling_damage.buckets=[[1,10],[1,20]];check(not g.legacy.validate(malformed),"profile upload rejects malformed rolling history")
 var before=g.legacy.data.duplicate(true);crown.time_for_test-=120;crown.add_damage(9999);check(S.fingerprint(before)==S.fingerprint(g.legacy.data),"backward clock cannot reorder damage")
 crown.time_for_test+=120
 check(not A.review_allowed(),"ordinary profiles cannot open teacher examples")
 A.unlock("teacher");check(A.review_allowed(),"teacher has example access")
 var dashboard=load("res://scripts/teacher_dashboard.gd").new();g.legacy.add_child(dashboard);dashboard.setup(g.legacy);dashboard.example_level=2;dashboard.show_examples()
 check(dashboard.example_data.size()==1 and dashboard.content.get_children().filter(func(n):return n is GridContainer)[0].get_child_count()==4,"example class has module progress cards")
 check(not dashboard.is_in_group("fx_private_assessment"),"fictional examples can be demonstrated in class broadcasts")
 dashboard.review_example("CSE1110");await process_frame
 var page=dashboard.get_children().filter(func(n):return n is CanvasLayer and n.get_script()==load("res://scripts/learning_page.gd"))[0]
 check(page.sample and page.latest().is_empty() and not page.review_work().is_empty(),"unfinished module evidence accessible")
 page.module="DES1020";page.tabs.current_tab=2;page.render();var classes=FileAccess.get_file_as_string("user://fx_teacher_classes.json");var learning=FileAccess.get_file_as_string(S.PATH)
 page.marked["1"].score=88;page.save_marks();check(dashboard.example_data[2].submissions[0].marks["1"].score==88,"practice ratings update session only")
 check(classes==FileAccess.get_file_as_string("user://fx_teacher_classes.json") and learning==FileAccess.get_file_as_string(S.PATH),"example marking changes no real records")
 page.finish();await process_frame;dashboard.example_level=-1;dashboard.render();check(dashboard.is_in_group("fx_private_assessment"),"real class records remain hidden from broadcasts")
 dashboard.finish();await process_frame
 var local_review=load("res://scripts/learning_page.gd").new();g.legacy.add_child(local_review);local_review.setup(g.legacy,true);local_review.tabs.current_tab=0;local_review.render()
 var example_button=local_review.content.get_children().filter(func(n):return n is Button and n.text=="Example")[0];example_button.pressed.emit();await process_frame
 var opened=g.legacy.get_children().filter(func(n):return n.get_script()==load("res://scripts/teacher_dashboard.gd"))[0];check(opened.example_level==1,"assignment review Example button opens demonstration portfolios");opened.finish();await process_frame
 A.toggle("teacher",false);g.legacy.enable_teacher();check(A.review_allowed() and not A.teacher(),"Game Dev gets examples without persistent teacher unlock")
 var normal_total=crown.total();crown.add_damage(100000);check(crown.total()==normal_total,"Game Dev testing excluded from crowns")
 preload("res://scripts/education_business_page.gd").open(g.legacy,"ENT1020");await process_frame
 var views=g.legacy.get_children().filter(func(n):return n.get_script()==load("res://scripts/education_business_page.gd"));check(views.size()==1,"Game Dev can preview business teaching sandbox")
 for p in views:p.queue_free()
 g.legacy.disable_teacher();await process_frame
 print("V142 RUNTIME COMPLETE • failures=",failures);quit(failures)
