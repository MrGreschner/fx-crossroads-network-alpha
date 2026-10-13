extends SceneTree
const Merge=preload("res://scripts/studio_merge.gd")
const Project=preload("res://scripts/workshop_project.gd")
const Library=preload("res://scripts/studio_library.gd")
var failures=0
func check(value:bool,label:String)->void:
 print("PASS • " if value else "FAIL • ",label)
 if not value:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 var before={"value":{"a":1,"b":2,"frames":["one"]}};var after=before.duplicate(true);after.value.a=3
 var ops=Merge.diff(before,after);check(ops.size()==1 and ops[0].path==["value","a"],"leaf edits isolated")
 Merge.set_at(before,["value","frames",0.0],"two");check(before.value.frames[0]=="two","JSON numeric frame indices supported")
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 5:await process_frame
 g.set_process(false);g.presentation.close();g.session_menu.resume();var w=g.hero_workshop;w.open();w.project=Project.fresh();w.project.hero.name="Live Draft";w.panel.show();if is_instance_valid(w.hub):w.hub.hide()
 var old_draft=Project.fresh();old_draft.hero.name="Earlier saved draft"
 var saved=FileAccess.open(Project.PATH,FileAccess.WRITE);saved.store_string(JSON.stringify(old_draft));saved.close();Library.install(g)
 check(g.characters.has(Library.hero_id(old_draft)),"pre-update draft appears without publishing again")
 w.save_draft();var id=Library.hero_id(w.project)
 check(Library.load_data().heroes.has(id),"valid saved draft automatically available locally")
 w.play_draft();check(g.selected_character==id and g.practice,"direct training button plays authored hero")
 w.open();w.panel.show();if is_instance_valid(w.hub):w.hub.hide()
 var partner=root.get_node("FXStudioPartner");partner.workshop=w;partner.code="SPTEST";partner.identity="main";partner.writer="main";partner.shared={"kind":"hero","value":w.project.duplicate(true)};partner.last_local=partner.capture().duplicate(true)
 var editor=preload("res://scripts/studio_pixel_editor.gd").new();w.add_child(editor);editor.setup("","Idle");editor.bind_live(["value","hero","art","idle"])
 editor.canvas.image.set_pixel(1,1,Color.RED);editor.live_dirty=true;editor.flush_live()
 check(not w.project.hero.art.get("idle","").is_empty(),"paint edits reach hero before Save image")
 var remote=editor.canvas.image.duplicate();remote.set_pixel(2,2,Color.BLUE)
 partner.apply_edit({"kind":"hero","sender":"partner","revision":2,"ops":[{"path":["value","hero","art","idle"],"value":Marshalls.raw_to_base64(remote.save_png_to_buffer())}]})
 check(editor.canvas.image.get_pixel(1,1)==Color.RED and editor.canvas.image.get_pixel(2,2)==Color.BLUE,"remote image updates open canvas preserving other stroke")
 editor.canvas.image.set_pixel(3,3,Color.GREEN);editor.live_dirty=true
 remote.set_pixel(4,4,Color.YELLOW);editor.remote_image(Marshalls.raw_to_base64(remote.save_png_to_buffer()))
 check(editor.canvas.image.get_pixel(3,3)==Color.GREEN and editor.canvas.image.get_pixel(4,4)==Color.YELLOW,"pending local pixels survive incoming edits")
 editor.flush_live();editor.queue_free();await process_frame
 partner.last_local=partner.capture().duplicate(true);w.project.hero.name="Unsent local name"
 partner.apply_edit({"kind":"hero","sender":"partner","revision":3,"ops":[{"path":["value","hero","speed"],"value":220}]})
 check(w.project.hero.name=="Unsent local name" and w.project.hero.speed==220,"independent setting and unsent local edit coexist")
 partner.apply_edit({"kind":"hero","sender":"main","revision":4,"ops":[{"path":["value","hero","name"],"value":"Old echo"}]})
 check(w.project.hero.name=="Unsent local name","acknowledgement never overwrites newer typing")
 partner.apply_edit({"kind":"hero","sender":"partner","revision":5,"ops":[{"path":["value","hero","speed"],"value":999999}]})
 check(w.project.hero.speed==220,"invalid shared hero change rejected")
 partner.leave();w.close();g.enter_region("town");var mine=g.legacy.mine;mine.time_for_test=1000;g.legacy.data.mine=mine.fresh(1000);mine.commission();mine.state().wallet={"gold":100000.0,"ore":100000.0,"gems":1000.0};mine.upgrade("vent");mine.open()
 var view=mine.view
 check(view.bars.has("job_progress") and view.bars.has("boost_rally"),"Idle Mining has timed completion bars")
 var duration=mini(600,int(mine.CATALOG.data().services.vent.seconds)+8)
 mine.time_for_test=1000+duration*.5;view.refresh();check(absf(view.bars.job_progress.value-50)<.1,"construction bar shows half completion at halfway")
 check(view.completion(1030,1015,30)==50,"refining timer progress correct")
 view.close();w.project.reports=[{"scenario":"Cluster","damage":10,"dps":2,"seconds":5},{"scenario":"Cluster","damage":20,"dps":4,"seconds":5}];w.compare_tests();check(w.project.reports.size()==2,"comparison preserves original evidence")
 g.queue_free();await process_frame;print("V138 FAILURES: ",failures);quit(1 if failures else 0)
