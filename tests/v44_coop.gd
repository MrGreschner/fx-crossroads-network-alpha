extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func party_setup()->Node:
 var p=load("res://scenes/arcade.tscn").instantiate();root.add_child(p);await process_frame;p.set_process(false);p._set_mode("defense");p._solo();p._set_mode("coop")
 for n in p.realm_picker.item_count:
  if str(p.realm_picker.get_item_metadata(n))=="high_school":p.realm_picker.select(n)
 p._start_match();return p
func kill_group(p:Node,key:String)->void:
 for n in range(p.opponents.size()-1,-1,-1):
  if str(p.opponents[n].get("school_group",""))==key:p._hit_enemy(n,100000,p.my_id)
func run()->void:
 var host=await party_setup();host._add_player("friend",1);host.adventure.step(.01);var school=host.adventure.school
 check(host.opponents.size()==6 and host.opponents[0].hp>118,"host scales authored enemies for party")
 host.positions.friend=Vector2(4050,4850);school.clock=1;host._packet("friend",{"type":"rift"});check(school.opened.front,"guest interaction request opens host door")
 kill_group(host,"arrival");host.adventure.step(.01);check(host.levels.friend>=3 and host.opponents.size()==15,"shared checkpoint unlocks teammate secondary")
 for department in school.data.departments:
  kill_group(host,str(department.id));host.adventure.step(.01);kill_group(host,"boss:"+str(department.id));host.adventure.step(.01)
 check(school.completed.has("departments") and host.levels.friend>=6,"three department seals unlock party specials")
 host.positions.friend=Vector2(4370,2870);school.clock+=1;host._packet("friend",{"type":"rift"});check(school.floor_id(host.positions.friend)==1,"host authorizes remote stairs")
 kill_group(host,"upper");host.adventure.step(.01);check(host.levels.friend>=8 and school.opened.exam,"upstairs checkpoint opens final and upgrades")
 host.positions.friend=Vector2(12050,1700);host.adventure.step(.01);var selected:String=school.exam_choice;check(selected in school.EXAMS and host.opponents.size()==1,"guest classroom entry chooses one host exam")
 var guest=await party_setup();guest.role="guest";guest.host_id="host";guest.my_id="friend";guest._packet("host",host.match_config());guest._packet("host",JSON.parse_string(JSON.stringify(host._snapshot())))
 check(guest.adventure.school.exam_choice==selected and guest.adventure.school.opened.exam and guest.opponents.size()==1 and guest.opponents[0].school_group=="boss:final","guest receives matching exam, doors and boss")
 check(guest.adventure.school.can_stand(Vector2(11950,2300)),"received open classroom affects guest collision")
 var count:int=guest.opponents.size();guest.adventure.step(1);check(guest.opponents.size()==count and guest.adventure.school.exam_choice==selected,"guest never rerolls or simulates extra encounters")
 kill_group(host,"boss:final");host.adventure.step(.01);check(school.done and host.started,"boss defeat requires return to street instead of premature match end")
 host.positions.friend=Vector2(11750,3850);school.clock+=1;host._packet("friend",{"type":"rift"});check(school.floor_id(host.positions.friend)==0,"remote return stairs work after final")
 host.positions.friend=school.v(school.data.exit);host._packet("friend",{"type":"rift"});check(not host.started and host.results_reason.contains("cleared"),"remote street exit completes shared run")
 for p in [host,guest]:
  for voice in p.journey.voices:voice.stop()
  p.queue_free()
 await create_timer(.3).timeout;print("V44 COOP FAILURES: "+str(failures));quit(failures)
