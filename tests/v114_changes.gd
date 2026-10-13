extends SceneTree
var failures:=0
func check(value:bool,title:String)->void:
 if not value:failures+=1;print("FAIL: ",title)
func _initialize()->void:call_deferred("run")
func tidy(g:Node)->void:
 for player in g.find_children("*","AudioStreamPlayer",true,false):player.stop();player.stream=null
 await create_timer(.1).timeout;g.queue_free();await process_frame;await process_frame
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume()
 var support=preload("res://scripts/release_support.gd")
 g.legacy.data.backup_reminder={"known":[],"pending":false,"last_export":""};var rec:Dictionary=g.legacy.record("ram");rec.clears=3;rec.realms=["grove","quarry"];rec.damage=10000
 support.scan_mastery(g.legacy);check(support.backup_due(g.legacy),"first technique requests quiet backup")
 support.exported(g.legacy);support.scan_mastery(g.legacy);check(not support.backup_due(g.legacy),"same milestone does not repeatedly remind")
 rec.clears=12;rec.realms=["grove","quarry","sunfield","silverfall","honeyglass","lantern_marsh"];rec.damage=85000;support.scan_mastery(g.legacy);check(support.backup_due(g.legacy),"final technique requests another backup")
 check("Steps to reproduce" in support.bug_report(g) and "v119" in support.bug_report(g),"bug copy includes context and useful prompts")
 g.session_menu.open("options");g.session_menu.open_notebook();await process_frame
 var notebook:Node=g.session_menu.get_node("PlaytestNotebook")
 notebook.fields.areas.text="Training yard / Young Ram";notebook.fields.title1.text="Example observation";notebook.fields.steps1.text="Aim, strike, repeat three times";for field in ["areas","title1","steps1"]:notebook.fields[field].text_changed.emit()
 notebook.save_draft()
 check("Example observation" in notebook.report() and "Reflection".to_upper() in notebook.report(),"student report retains issues and reflection")
 check(g.session_menu.page=="options","notebook leaves safe menu context")
 var dev:Node=root.get_node("FXDevSession");dev.begin();var state_before:Dictionary=g.legacy.data.backup_reminder.duplicate(true);support.scan_mastery(g.legacy)
 check(not support.backup_due(g.legacy) and g.legacy.data.backup_reminder==state_before,"Game Dev cannot change backup milestones")
 check("Testing mode: true" in notebook.report(),"student reports identify temporary test mode")
 dev.active=false;dev.overlay.hide();dev.memory.clear()
 notebook.clear_notes();check(not FileAccess.file_exists(notebook.DRAFT),"clear notes removes local draft without changing hero progress")
 notebook.queue_free();await process_frame;g.session_menu.resume();g.start_training();g.set_process(false)
 var f:Node=g.adventure.combat.feedback
 f.contacts.clear();f.hit(Vector2(500,500),0);check(f.contacts.is_empty(),"zero damage does not show false impact")
 f.hit(Vector2(500,500),8);f.hit(Vector2(502,500),9);check(f.contacts.size()==1,"overlapping contacts merge")
 for n in 40:f.hit(Vector2(100+n*20,300),8)
 check(f.contacts.size()<=24,"contacts are capped")
 f._process(.3);check(f.contacts.is_empty(),"impact visual expires promptly")
 g.selected_character="ram";g.start_training();check(f.guide_stats().range==82,"optional reach uses actual Ram primary stats")
 g.selected_character="book";g.start_training();check(f.guide_stats().range==float(g.hero.primary.range),"book melee primary shares actual reach")
 g.enter_region("town");f.hit(Vector2(500,500),8);check(f.contacts.is_empty() and f.guide_stats().is_empty(),"no combat feedback or guides in town")
 await tidy(g)
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false);a.role="host";a.mode="arena";a.started=true;a.start_countdown=0;a.my_id="host";a._add_player("host",0);a._add_player("cat",1);a.pvp_rule="ffa";a.stealth_until.cat=Time.get_ticks_msec()+3000
 f=a.adventure.combat.feedback;f.hit(Vector2(500,500),8,"cat");check(f.contacts.is_empty(),"contact feedback cannot reveal invisible Cat")
 a._damage_feedback(Vector2(500,500),8,"host");check(f.contacts.size()==1,"authoritative PvP damage produces impact")
 f.contacts.clear();a._receive_effect({"pos":[482,455],"style":"damage","amount":8,"victim":"host"});check(f.contacts.size()==1,"remote damage event uses same impact visual")
 a.health.host=50;a._heal("host","host",10);check(f.contacts.any(func(e):return e.healing),"actual healing uses distinct green feedback")
 var b:Node=a.session_menu;b.open("options");b.open_notebook();await process_frame;notebook=b.get_node("PlaytestNotebook");check("arena" in notebook.report(),"notebook works in multiplayer context")
 await tidy(a);print("v114 failures: ",failures);quit(1 if failures else 0)
