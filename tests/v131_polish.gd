extends SceneTree
var failures=0
func check(ok:bool,label:String)->void:
 print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g;await process_frame;g.set_process(false);g.presentation.close();g.session_menu.resume()
 var daily=g.legacy.daily
 check(daily.tasks.size()==50,"fifty daily challenges retained")
 var rewards={}
 for n in 16:
  var day=Time.get_date_string_from_unix_time(1791331200+n*86400)
  rewards[daily.reward_index(day)]=true
 check(rewards.size()==8,"eight daily rewards rotate across consecutive dates")
 for task in daily.tasks:
  daily.current_task=task;var plan=daily.quick_plan()
  check(plan.realm!="*" and (task.kind!="realm" or g.realms.has(plan.realm)),"challenge destination exists: "+str(task.id))
  if task.kind in ["descent","defense"]:check(task.target<=10,"short survival objective: "+str(task.id))
 daily.current_task={"kind":"realm","realm":"grove","hero":"ram","team":"solo"}
 daily.quick_play();check(g.mode=="run" and g.region_id=="grove" and g.character_id=="ram","solo daily quick play launches correct hero and realm")
 g.enter_region("town");g.session_menu.resume();g.position_in_world=Vector2(-390,1740);g.update_camera()
 check(g.camera.x<0 and g.can_stand_at(Vector2(-390,1740)),"expanded west district camera and walkable street")
 check(g.can_stand_at(g.studio_town.ENTRY),"Studio doorway reachable")
 check(not g.studio_town.WALL.intersects(g.town_v109.solid_rect("relay")),"Studio and Relay buildings have separate plots")
 check(not g.town_scenery.blocked(g.studio_town.ENTRY),"Studio approach free of trees")
 var research=root.get_node("FXResearch");research.begin()
 var store=preload("res://scripts/profile_store.gd");var path="user://v131_research_guard.json"
 check(store.testing(),"Research is a protected testing session")
 store.write(path,{"unsafe":true});check(not FileAccess.file_exists(path),"Research cannot persist player files")
 var old=g.legacy.record("ram").damage;g.legacy.add_damage("ram",1000);check(g.legacy.record("ram").damage==old,"Research does not accrue mastery damage")
 await process_frame;research._process(.01)
 check(research.panel.position.y+research.panel.size.y*research.panel.scale.y<=root.get_visible_rect().size.y-60,"Research panel remains above its toggle")
 research.checkpoint();check(research.checkpoints.size()==1 and "FPS" in research.report(),"Research records useful session evidence")
 check(not root.get_node("FXDevSession").active,"Research grants no Game Dev powers")
 research.notebook();var book=g.session_menu.get_node_or_null("PlaytestNotebook")
 check(book!=null and "Playtest Mode" in book.fields["method"].text,"Research evidence appears in editable report")
 if book!=null:book.queue_free()
 research.active=false;research.hide()
 var rift=g.mistglass_rift;rift.chosen=[{"entry":{"realm":"grove","kind":"bramble"},"count":10}];rift.launch();rift.countdown=0;g.menu="";g.update_camera()
 check(rift.active and g.enemies.size()==10,"Rift starts full custom lineup")
 for foe in g.enemies:check(foe.pos.y>=220 and foe.pos.y<=g.VIEW.y-65,"Rift enemy starts below HUD")
 g.enemies[0].pos=Vector2(30,30);rift.step(.02);check(g.enemies[0].pos.y>=220,"Rift enemies remain within battle area")
 check(not g.can_stand_at(Vector2(300,100)),"Rift player cannot walk into HUD")
 check(g.camera==Vector2.ZERO,"Rift arena fits one unobstructed view")
 await process_frame;check(is_instance_valid(rift.end_button),"End Battle is available")
 rift.finish(false,true);check(g.mode=="town" and g.presentation.page=="rift_result","End Battle returns to town with result")
 daily.current_task={"kind":"realm","realm":"grove","hero":"","team":"party"};check(daily.quick_plan().mode=="coop","party daily opens co-op")
 g.session_menu._process(.01);check(g.session_menu.menu_button.get_combined_minimum_size().y<=44,"Menu button fits standard top-bar height")
 print("V131 failures: ",failures);quit(failures)
