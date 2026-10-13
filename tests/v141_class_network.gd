extends SceneTree
const S=preload("res://scripts/learning_store.gd")
const A=preload("res://scripts/education_access.gd")
var failures=0
func check(ok:bool,t:String)->void:
 print("PASS • " if ok else "FAIL • ",t)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func until(test:Callable,seconds:float=8)->bool:
 var start=Time.get_ticks_msec()
 while Time.get_ticks_msec()-start<int(seconds*1000):
  if test.call():return true
  await process_frame
 return false
func run()->void:
 A.unlock("student");A.unlock("teacher");root.get_node("FXStudioPartner").service_url="ws://127.0.0.1:33481"
 var d=S.load_data();d.student="Élan • 日本";S.note(d,"DES1020","brief","A readable support ram for new players.");S.submit(d,"DES1020")
 var host=root.get_node("FXEducationRoom");host.host();check(await until(func():return not host.room_code.is_empty()),"Godot teacher opens ED room")
 var student=load("res://scripts/education_room.gd").new();root.add_child(student);student.code_field.text=host.room_code;student.join_room()
 check(await until(func():return "received your progress" in student.status.text),"join automatically sends Unicode portfolio to teacher")
 var T=load("res://scripts/teacher_store.gd");var key=host.room_code+"-"+d.learner_id
 check(T.state().students.has(key),"received progress persists in class records")
 var received=T.state().students[key].portfolio;received.submissions[0].marks={"1":{"rating":"Meets","feedback":"Clear design need","score":85}};received.submissions[0].teacher="Teacher";received.submissions[0].reviewed=S.stamp()
 host.return_feedback(host.peers[key],received)
 check(await until(func():return not student.feedback.is_empty()),"teacher feedback returns across real WebSocket")
 student.accept();check(S.load_data().submissions[0].marks.size()==1,"student accepts matching frozen submission grades")
 student.stop();host.stop();quit(failures)
