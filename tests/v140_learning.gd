extends SceneTree
const S=preload("res://scripts/learning_store.gd")
const P=preload("res://scripts/workshop_project.gd")
var failures=0
func check(ok:bool,title:String)->void:
 print("PASS • " if ok else "FAIL • ",title)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 preload("res://scripts/education_access.gd").unlock("student");preload("res://scripts/education_access.gd").unlock("teacher")
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for i in 4:await process_frame
 g.set_process(false);g.presentation.close();g.session_menu.resume()
 var d=S.fresh();check(not d.enabled and S.valid(d),"Student Mode optional and fresh schema valid")
 check(S.catalog().size()==14 and S.catalog()["DES1020"].outcomes.size()==7,"expanded module catalog and all seven main Design Process outcomes")
 check(S.catalog()["DRAFT-CS1"].draft and S.catalog()["DRAFT-ANIM1"].draft,"unprovided curriculum marked draft")
 var briefs=[]
 for code in S.catalog():briefs.append(S.catalog()[code].brief)
 check(briefs.size()==14 and briefs.count(briefs[0])==1,"different module briefs")
 d.enabled=true;d.student="Tester"
 check(S.note(d,"DES1020","brief","I need a legible close-range healer with a clear silhouette.").is_empty(),"design brief saves before prototype")
 var original=P.fresh();check(S.attach(d,"DES1020","hero",original,"Prototype one","Current draft").is_empty(),"hero snapshot attaches")
 var id=S.work(d,"DES1020").refs[0];var order=d.artifacts[id].order;var time=d.artifacts[id].time
 original.hero.name="Changed live draft"
 check(d.artifacts[id].value.hero.name!=original.hero.name,"snapshot independent of live draft")
 S.attach(d,"DES1020","hero",d.artifacts[id].value,"Again","Later source")
 check(d.artifacts[id].order==order and d.artifacts[id].time==time,"identical attachment preserves original capture order")
 check(d.work.DES1020.entries[0].order<d.artifacts[id].order,"brief order precedes snapshot")
 check(S.submit(d,"DES1020").is_empty(),"freeze submission")
 var submission=d.submissions[0].duplicate(true)
 S.note(d,"DES1020","brief","Changed the design after feedback.")
 check(d.submissions[0].entries.size()==1 and d.work.DES1020.entries.size()==2,"later journal entry cannot alter submission")
 var parsed=JSON.parse_string(JSON.stringify(d));check(S.valid(parsed),"portfolio survives JSON round trip including content hashes")
 var review=S.review_bundle(d);check(review.work.is_empty() and review.artifacts.size()==1 and review.submissions.size()==1,"review excludes unsubmitted journal and drafts")
 review.submissions[0].marks={"1":{"rating":"Meets","score":85,"feedback":"Clear brief and process decisions."}};review.submissions[0].teacher="Teacher";review.submissions[0].reviewed=S.stamp()
 check(S.apply_feedback(d,review).is_empty() and d.submissions[0].marks["1"].rating=="Meets","matching teacher feedback applies")
 var forged=review.duplicate(true);forged.submissions[0].entries[0].text="Replaced evidence";check(not S.valid(forged),"altered submission fails digest validation")
 var other=review.duplicate(true);other.submissions[0].id="DES1020-other";check(not S.apply_feedback(d,other).is_empty(),"feedback for another submission rejected")
 var noart=S.fresh();noart.enabled=true
 for stage in S.catalog().DES1020.stages:S.note(noart,"DES1020",stage.id,"Explanation of "+stage.title)
 check(not S.readiness(noart,"DES1020",S.work(noart,"DES1020"))["2"].ready,"notes alone do not complete production evidence")
 check(not S.safe_svg('<svg><script>alert(1)</script></svg>'),"active SVG content rejected")
 var page=load("res://scripts/learning_page.gd").new();g.legacy.add_child(page);page.setup(g.legacy)
 check(g.menu=="learning","portfolio blocks underlying town movement")
 for tab in 4:page.tabs.current_tab=tab;page.render();await process_frame
 page.module="COM1035";var graphic=load("res://scripts/learning_graphic.gd").new();page.add_child(graphic);graphic.setup(page)
 check(S.valid_artifact({"kind":"graphic","value":graphic.latest,"title":"Emblem","time":S.stamp(),"origin":"Vector Card","hash":S.fingerprint(graphic.latest)}),"vector/raster paired artifact validates")
 graphic.capture();check(page.data.work.COM1035.refs.size()==1,"vector card attaches to selected module")
 page.test_snapshot({"kind":"enemy","value":preload("res://scripts/studio_enemy_project.gd").fresh()});await process_frame
 check(is_instance_valid(page.test_panel),"teacher can battle submitted enemy snapshot")
 page.finish();await process_frame;check(g.menu!="learning","closing portfolio restores previous menu")
 var teacher=load("res://scripts/learning_page.gd").new();g.legacy.add_child(teacher);teacher.setup(g.legacy,true,d)
 for tab in 4:teacher.tabs.current_tab=tab;teacher.render();await process_frame
 teacher.tabs.current_tab=2;teacher.render();teacher.marked["2"].rating="Developing";teacher.save_marks();check(teacher.latest().marks["2"].rating=="Developing","teacher saves outcome ratings in review copy")
 check(not g.legacy.data.teacher,"teacher review does not enable Game Dev")
 teacher.finish();await process_frame
 var activity_before=S.load_data();S.activity("Test completed","Prototype");check(S.load_data().work.DES1020.activity.size()==1,"completed activity recorded only in Student Mode")
 var zip_path="user://v141-student.zip";var bundle=g.legacy.bundle();check(preload("res://scripts/studio_bundle.gd").make(bundle,zip_path)==OK,"player ZIP created with learning data")
 var reopened=preload("res://scripts/studio_bundle.gd").read(zip_path);check(reopened.get("error","").is_empty() and g.legacy.validate(reopened.payload) and reopened.payload.saves.has("fx_learning.json"),"player ZIP reimports submitted evidence and teacher feedback")
 check(g.legacy.bundle().saves.has("fx_learning.json") and g.legacy.validate(g.legacy.bundle()),"player profile includes validated learning portfolio")
 root.set_meta("fx_dev_session",true)
 # Use the actual profile-store testing gate below, not an unrelated metadata flag.
 var session=root.get_node("FXDevSession");session.begin()
 var before=JSON.stringify(d);check(not S.note(d,"DES1020","brief","Do not record preview").is_empty() and JSON.stringify(d)==before,"Game Dev rejects assessed writes and rolls back")
 session.active=false;session.memory.clear();session.overlay.hide();root.remove_meta("fx_dev_session")
 g.queue_free();await process_frame
 print("V140 LEARNING FAILURES: ",failures);quit(1 if failures else 0)
