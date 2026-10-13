extends SceneTree
const S=preload("res://scripts/learning_store.gd")
var failed=false
func _initialize()->void:call_deferred("run")
func until(test:Callable,label:String)->bool:
 for n in 160:
  if test.call():print("PASS • ",label);return true
  await create_timer(.05).timeout
 print("FAIL • ",label);failed=true;return false
func run()->void:
 preload("res://scripts/education_access.gd").unlock("student");preload("res://scripts/education_access.gd").unlock("teacher")
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 4:await process_frame
 g.set_process(false);g.presentation.close();g.session_menu.resume()
 root.get_node("FXStudioPartner").service_url="ws://127.0.0.1:33478"
 var d=S.fresh();d.enabled=true;d.student="Student 🐏 demo";S.note(d,"DES1020","brief","Clear accessible hero concept — 🦉");S.attach(d,"DES1020","hero",S.P.fresh(),"Hero prototype","Local Lab");S.submit(d,"DES1020")
 var student=load("res://scripts/learning_page.gd").new();g.legacy.add_child(student);student.setup(g.legacy);student.data=d
 var teacher=load("res://scripts/learning_page.gd").new();g.legacy.add_child(teacher);teacher.setup(g.legacy,true);teacher.teacher_name="Reviewer"
 student.link.connect_review(false)
 if not await until(func():return student.link.status.text.begins_with("Ready."),"student uploads private submitted bundle"):quit(1);return
 teacher.link.code_field.text=student.link.code;teacher.link.connect_review(true)
 if not await until(func():return not student.link.client_id.is_empty(),"reviewer access request reaches student"):quit(1);return
 if teacher.remote:print("FAIL • premature transfer");quit(1);return
 student.link.approve()
 if not await until(func():return teacher.remote and teacher.data.submissions.size()==1,"approved teacher receives valid frozen evidence"):quit(1);return
 teacher.tabs.current_tab=2;teacher.render();teacher.marked["1"].rating="Meets";teacher.marked["1"].feedback="I observed the design process.";teacher.save_marks();teacher.link.return_feedback(teacher.data)
 if not await until(func():return not student.link.result.is_empty(),"teacher feedback arrives for acceptance"):quit(1);return
 student.link.accept_feedback()
 if S.load_data().submissions[0].marks["1"].rating!="Meets":print("FAIL • returned rating not persisted");quit(1);return
 print("PASS • accepted feedback persists in matching student submission")
 student.link.stop();teacher.finish();student.finish();g.queue_free();await process_frame;print("V140 NETWORK COMPLETE");quit(1 if failed else 0)
