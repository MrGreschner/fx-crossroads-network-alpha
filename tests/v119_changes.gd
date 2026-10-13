extends SceneTree
var failures:=0
var g:Node
func check(ok:bool,title:String)->void:
 if not ok:failures+=1;print("FAIL: ",title)
func _initialize()->void:call_deferred("run")
func pick_day(d:RefCounted,id:String)->void:
 for n in 120:
  var day:String=Time.get_datetime_string_from_unix_time(1791244800+n*86400).left(10)
  if str(d.task_for(day).id)==id:d.date_for_test=day;d.refresh();return
 check(false,"calendar includes "+id)
func tidy(node:Node)->void:
 for p in node.find_children("*","AudioStreamPlayer",true,false):p.stop();p.stream=null
 node.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g;await process_frame;g.set_process(false)
 g.presentation.close();g.menu="";g.session_menu.open("main");root.remove_meta("fx_tutorial_offered");g.session_menu.resume()
 for n in 3:await process_frame
 check(g.presentation.page.is_empty() and g.menu.is_empty(),"Continue enters town with no forced tutorial")
 var d:RefCounted=g.legacy.daily
 check(d.tasks.size()==50,"fifty authored daily tasks")
 var ids:Dictionary={}
 for spec in d.tasks:
  ids[spec.id]=true
  check(str(spec.kind) in ["realm","descent","defense"],"known challenge kind")
  if str(spec.kind)=="realm" and str(spec.realm)!="*":check(g.realms.has(spec.realm),"daily realm exists")
  if not str(spec.hero).is_empty():check(g.characters.has(spec.hero),"daily hero exists")
 check(ids.size()==50,"task IDs unique")
 # One complete shuffled cycle has no repeats, and lookup is reproducible.
 var start:int=int(Time.get_unix_time_from_datetime_string("2026-10-06T00:00:00"))/86400
 var cycle:int=int(floor(float(start)/50))*50;var seen:Dictionary={}
 for n in 50:
  var date:String=Time.get_datetime_string_from_unix_time((cycle+n)*86400).left(10)
  var spec:Dictionary=d.task_for(date);seen[spec.id]=true
  check(spec==d.task_for(date),"deterministic daily selection")
 check(seen.size()==50,"cycle contains every task exactly once")
 var previous_id:=""
 for n in 200:
  var date:String=Time.get_datetime_string_from_unix_time((cycle+n)*86400).left(10)
  var id:String=str(d.task_for(date).id);check(id!=previous_id,"daily challenge always changes, including cycle boundary");previous_id=id
 pick_day(d,"grove_solo");d.realm_clear("ram","quarry");check(not d.earned(),"wrong realm does not award")
 g.start_run(false,"grove");g.presentation.close();g.menu="";g.finish_run(true)
 check(d.earned(),"real solo realm victory awards daily crest")
 var saved:Dictionary=g.legacy.bundle();check(saved.progress.daily.done and g.legacy.validate(saved),"reward included in portable profile")
 d.event("realm",1,1,"grove","ram");check(d.earned(),"repeat events idempotent")
 d.date_for_test=Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_datetime_string(d.today+"T00:00:00"))+86400).left(10);d.step(2)
 check(not d.earned() and d.cosmetic_date().is_empty(),"midnight expires reward and advances task")
 pick_day(d,"hero_book");d.realm_clear("ram","grove");check(not d.earned(),"wrong hero cannot complete featured hero task")
 d.realm_clear("book","grove");check(d.earned(),"featured hero clear awards")
 pick_day(d,"grove_party");d.realm_clear("book","grove");check(not d.earned(),"solo cannot earn co-op task")
 d.event("realm",1,2,"grove","book");check(d.earned(),"two-person party completes co-op goal")
 pick_day(d,"quarry_solo");g.legacy.data.teacher=true;d.event("realm",1,1,"quarry","ram");check(not d.earned(),"Game Dev does not award challenge")
 g.legacy.data.teacher=false;g.presentation.close();g.enter_region("town");g.legacy.open_page("elder")
 var inputs:Array=g.legacy.body.find_children("*","LineEdit",true,false)
 check(inputs.size()==1 and not inputs[0].secret,"elder chat immediately available")
 g.legacy.answer("tell me a joke");check("ladder" in g.legacy.notice.text,"elder humour response")
 g.legacy.answer("gameDev");check(g.legacy.asking_code,"existing Game Dev keyword retained")
 inputs=g.legacy.body.find_children("*","LineEdit",true,false);check(inputs.size()==1 and inputs[0].secret,"password input protected")
 g.legacy.answer("wrong");check(not g.legacy.asking_code,"wrong password remains normal mode")
 g.legacy.close();g.session_menu.open("clear")
 check(g.session_menu.body.find_children("*","Button",true,false).any(func(b):return b.text=="START • enter tutorial"),"new game has clear welcoming start action")
 check(g.town_chapter.GUIDE.x-g.training_yard.HERO_BOOK.x>=270,"guide separated from hero book")
 for point in g.legacy.WATER_BEDS:
  check(g.can_stand_at(point),"watering beds remain reachable")
  for patch in g.ground_patches:check(not Geometry2D.is_point_in_polygon(point,patch.polygon),"watering beds are off the town paths")
 # Exercise actual reset/reload, not just button labels.
 g.legacy.data.name="Old school player";g.legacy.data.heroes.ram={"clears":9,"damage":12345,"realms":["grove"],"points":2,"tuning":[0,0,0]};g.legacy.save()
 g.session_menu.clear_profile()
 for n in 6:await process_frame
 g=current_scene;g.set_process(false)
 check(g.legacy.data.name=="Traveler" and float(g.legacy.record("ram").damage)==0 and int(g.legacy.record("ram").clears)==0,"New game clears local progress")
 check(g.presentation.page=="starter" and g.session_menu.page.is_empty(),"New game leads directly into skippable hero tutorial")
 await tidy(g)
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);current_scene=a;await process_frame;a.set_process(false);a.mode="descent";a.role="host";a.my_id="test";a.match_party_size=1
 d=a.legacy.daily;pick_day(d,"descent_20_solo");a.legacy.card.descent_cleared(19,1);check(not d.earned(),"survival must clear target, not enter floor")
 a.legacy.card.descent_cleared(20,1);check(d.earned() and a.local_cosmetic().daily_date==d.today,"survival clear and network cosmetic metadata")
 pick_day(d,"defense_5_party");a.mode="defense";a.legacy.card.wave_cleared(5,1);check(not d.earned(),"solo defence does not satisfy party task")
 a.legacy.card.wave_cleared(5,2);check(d.earned(),"cleared co-op wave awards crest")
 a.legacy.daily.date_for_test="2099-01-01";a.legacy.daily.refresh();check(a.local_cosmetic().daily_date.is_empty(),"network reward disappears at expiry")
 await tidy(a)
 print("v119 failures: ",failures);quit(failures)
