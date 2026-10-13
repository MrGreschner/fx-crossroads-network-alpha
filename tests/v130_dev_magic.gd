extends SceneTree
var failures=0
func check(ok:bool,label:String)->void:
 print("PASS: " if ok else "FAIL: ",label)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func ready_main()->Node:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 await process_frame;g.set_process(false);g.presentation.close();g.session_menu.resume();return g
func run()->void:
 var g=await ready_main();var session=root.get_node("FXDevSession");session.begin();g.legacy.data.teacher=true
 g.tutorial.start("ram");g.presentation.close();g.menu="";g.enemies.clear();g.dev_magic.set_process(false)
 var d=g.dev_magic;var point=g.position_in_world+Vector2(130,0)
 check(d.catalogue().size()>100,"full enemy and boss catalogue")
 check(d.request("summon",point,"bramble",9),"summon accepts nine copies")
 check(g.enemies.size()>0 and g.enemies.size()<=9,"summons respect terrain and count")
 d.last_request.clear();check(not d.request("summon",point,"not-real",9),"unknown summon rejected")
 d.last_request.clear();check(d.request("slow"),"time slow starts")
 check(d.slow_until-Time.get_ticks_msec()>15900 and d.world_scale()==.3 and d.scale_for("solo")==1,"16 second slow with dev exemption")
 check(not d.request("slow"),"spam rate limited")
 d.last_request.clear();g.enemies.clear();g.adventure.spawn("bramble",point,1000,false)
 var initial=g.enemies[0].hp
 check(d.request("volley",point),"volley starts")
 check(d.pending.size()==40,"exactly forty staggered missiles")
 for n in 100:d._process(.08)
 check(g.enemies[0].hp<initial and initial-g.enemies[0].hp<=120.1,"volley deals bounded chip damage")
 check(d.pending.is_empty() and d.bolts.is_empty(),"missiles expire and clean up")
 d.last_request.clear();check(d.request("spotlight",point),"presentation spotlight")
 d.last_request.clear();g.health=1;check(d.request("rally") and g.health==g.max_health(),"solo rally restores health")
 d.last_request.clear();check(d.request("sweep") and g.enemy_shots.is_empty(),"projectile sweep")
 check(root.has_meta("fx_dev_match") and preload("res://scripts/profile_store.gd").testing(),"test isolation blocks profile writes")
 var damage_before=g.legacy.record("ram").damage;g.legacy.add_damage("ram",9999);check(g.legacy.record("ram").damage==damage_before,"no mastery earned in test session")
 var w=g.hero_workshop;w.open();var lab=preload("res://scripts/studio_lab.gd").new();w.add_child(lab);lab.setup(w);lab.open_compare();lab.set_process(false)
 check(lab.baseline==lab.attack,"comparison captures original attack")
 lab.attack.damage=40;lab.restart_compare()
 check(lab.compare_preview.hero.primary.damage!=lab.after_preview.hero.primary.damage,"baseline remains independent of edited attack")
 for n in 100:
  lab.compare_preview._process(.05);lab.after_preview._process(.05);lab._process(.05)
 check(is_instance_valid(lab.compare_status) and "BEFORE" in lab.compare_status.text,"comparison shows real damage and hit counters")
 w.close();current_scene=null;g.queue_free();await process_frame;await process_frame
 session.active=false;session.memory.clear()
 root.set_meta("fx_mode","arena");var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);current_scene=a;await process_frame;a.set_process(false);a.presentation.close();a.session_menu.resume();a.role="host";a.my_id="host";a.host_id="host";a.roster.assign([{"id":"host","name":"Dev"},{"id":"p1","name":"Student"}]);a._add_player("host",0);a._add_player("p1",1);a.started=true;a.start_countdown=0;session.begin();a.player_cosmetics["p1"]={"game_dev":false};a.health["p1"]=int(a._max_hp("p1")*.5)
 var before=float(a.health.p1)/a._max_hp("p1");var old=a.hero_ids.host
 check(a.dev_magic.request("random"),"host randomises remote heroes")
 check(absf(float(a.health.p1)/a._max_hp("p1")-before)<.015,"hero change preserves health percentage")
 check(a.hero_ids.host==old,"Game Dev excluded from randomisation")
 a.dev_magic.last_request.clear();check(not a.dev_magic.execute("p1",{"kind":"slow","point":[0,0]}),"ordinary peer cannot request powers")
 a.dev_magic.last_request.clear();check(a.dev_magic.request("slow") and a.dev_magic.scale_for("p1")==.3 and a.dev_magic.scale_for("host")==1,"multiplayer actor exemptions")
 var snap=a.dev_magic.snapshot();check(snap.testing and snap.slow>15000,"test and time state replicated")
 a.dev_magic.last_request.clear();check(a.dev_magic.request("summon",a.positions.host+Vector2(80,0),"bramble",2),"multiplayer summons use enemy_defs registry")
 check(a.opponents.size()<=2,"multiplayer summon count bounded")
 a.dev_magic.last_request.clear();a.health.p1=0;a.downed.p1={"left":10};check(a.dev_magic.request("rally") and a.health.p1>0 and not a.downed.has("p1"),"Rally revives allied players")
 a.dev_magic.slow_until=0;check(a.dev_magic.world_scale()==1,"slow expires automatically")
 current_scene=null;a.queue_free();await process_frame;await process_frame;session.active=false
 check(not root.has_meta("fx_dev_match"),"test flag cleared when leaving scene")
 print("V130 failures: ",failures);quit(failures)
