extends SceneTree
var failures:=0
func check(ok:bool,value:String)->void:
 if not ok:failures+=1;print("FAIL: ",value)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume();g.legacy.set_process(false)
 check(g.town_scenery.trees.all(func(p):return p.x<=2200 or p.x>=2520),"river silhouette clear of tree canopies")
 check(g.town_art.any(func(a):return a.sprite=="town_fence" and a.pos==Vector2(2200,190)),"fence reaches river bank")
 check(g.town_places.any(func(a):return a.menu=="quest_entrance" and a.pos==Vector2(2940,1160)),"quest entry at east end of forest trail")
 for p in [Vector2(2460,1150),Vector2(2590,1150),Vector2(2590,1000),Vector2(2590,825),Vector2(2800,825),Vector2(2800,655),Vector2(2940,1160)]:check(g.can_stand_at(p),"fork route accessible "+str(p))
 g.queue_free();await process_frame
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.legacy.set_process(false);a.presentation.set_process(false);a.party_tools.set_process(false)
 a._set_mode("arena");a.rule_picker.select(1)
 a.party_lobby.pick(Vector2(500,400));check(a.chosen_team==0 and a.party_lobby.position_for("preview",0).x<650,"empty lobby click chooses silver and moves hero")
 a.party_lobby.pick(Vector2(1100,400));check(a.chosen_team==1 and a.party_lobby.side_count(1)==1 and a.party_lobby.position_for("preview",0).x>940,"empty lobby click chooses blue")
 a._start_button();check(not a.started,"preview cannot start an unhosted match")
 a._connect({"type":"host"});check(a.chosen_team==1,"preview team survives connecting")
 a._server({"type":"hosted","id":"host","code":"ABCDEF","config":{"mode":"arena","rule":"teams","seats":4},"roster":[{"id":"host","name":"You"}],"seats":4});check(a.teams.get("host",-1)==1,"host inherits preview side")
 a._choose_team(0);check(a.teams.host==0,"solo host can change sides")
 a._start_button();check(not a.started,"unbalanced hosted arena cannot start")
 a._reset_connection();a._set_mode("battlegrounds");a.party_lobby.pick(Vector2(500,400));check(a.chosen_team==0 and a.party_lobby.side_count(0)==1,"Battlegrounds preview can choose team without peers")
 a._set_mode("coop");a._process(0)
 check(not a.hero_picker.get_rect().intersects(a.realm_picker.get_rect()),"co-op hero and realm selectors do not overlap")
 a._reset_connection();a.queue_free();await process_frame;await process_frame;print("v94 polish failures: ",failures);quit(failures)
