extends SceneTree
const C=preload("res://scripts/studio_cycle.gd")
const L=preload("res://scripts/studio_library.gd")
const S=preload("res://scripts/profile_store.gd")
var failures=0
var checks=0
func check(ok:bool,label:String)->void:
 checks+=1
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 for path in [L.PATH,"user://fx_education_access.json"]:S.erase(path)
 var p=preload("res://scripts/studio_examples.gd").all("hero")[0]
 check(L.add_hero(p).is_empty(),"save hero")
 check(not C.readiness(L.load_data(),"hero",p).ready,"saved alone not ready")
 check(C.test("hero",p,{"seconds":3,"damage":12}).is_empty(),"exact revision receipt")
 check(C.stored("hero",p,true).is_empty(),"finalize")
 check(C.readiness(L.load_data(),"hero",p).ready,"ready after test and finalize")
 var submitted=C.submit("hero",p,"Test creator","Try the primary and dodge.","")
 check(submitted.error.is_empty(),"frozen submission")
 var e=submitted.entry;var copy=p.duplicate(true);copy.hero.primary.damage+=1
 check(not C.readiness(L.load_data(),"hero",copy).ready,"edits invalidate readiness")
 check(L.load_data().cycle.submissions[e.id].value.hero.primary.damage==p.hero.primary.damage,"submission remains frozen")
 check(not C.submit("hero",p,"A","B","").error.is_empty(),"duplicate snapshot rejected")
 check(not C.review(e.id,true,{}).is_empty(),"normal profile cannot curate")
 preload("res://scripts/education_access.gd").unlock("teacher")
 var feedback={"reviewer":"Teacher","worked":"Readable silhouette","confused":"Aim","improve":"Clarify aim","date":"2026-10-09"}
 check(C.review(e.id,false,feedback).is_empty(),"teacher returns revision")
 check(L.load_data().cycle.submissions[e.id].status=="revision_requested","revision requested")
 check(C.review(e.id,true,feedback).is_empty(),"teacher approves")
 var pack=C.catalog();check(pack.entries.size()==1,"only approved showcase")
 check(C.import_catalog(pack).is_empty(),"catalog reimport")
 var bad=pack.duplicate(true);bad.entries[0].status="submitted";check(not C.import_catalog(bad).is_empty(),"unapproved catalog rejected")
 var returned=C.envelope(L.load_data().cycle.submissions[e.id]);check(C.accept(returned).is_empty(),"feedback roundtrip")
 bad=returned.duplicate(true);bad.entry.value.hero.primary.damage+=1;check(not C.accept(bad).is_empty(),"tampered fingerprint rejected")
 C.test("hero",copy,{"seconds":4});C.stored("hero",copy,true)
 var next=C.submit("hero",copy,"Test creator","Try improved damage.","Damage adjusted")
 check(next.error.is_empty() and next.entry.version==2,"new revision version increments")
 check(C.valid(L.load_data().cycle),"cycle validates")
 # Last-good recovery for malformed AND schema-invalid current files.
 var valid=L.load_data();L.save_data(valid)
 var f=FileAccess.open(L.PATH,FileAccess.WRITE);f.store_string("{broken");f.close()
 check(L.load_data().heroes.size()==1 and not L.recovery_message().is_empty(),"backup recovery")
 f=FileAccess.open(L.PATH,FileAccess.WRITE);f.store_string('{"heroes":42}');f.close()
 check(L.save_data(valid).is_empty(),"save after corrupt schema")
 check(L.validate(JSON.parse_string(FileAccess.get_file_as_string(L.PATH+".bak"))).is_empty(),"last good backup not overwritten by corrupt dict")
 # Profile ZIP preserves submissions, feedback and approved entries.
 var payload={"format":"test","studio":L.load_data()};var path="user://creation-test.zip"
 check(preload("res://scripts/studio_bundle.gd").make(payload,path)==OK,"bundle written")
 var read=preload("res://scripts/studio_bundle.gd").read(path)
 check(read.error.is_empty() and read.payload.studio.cycle==L.load_data().cycle,"full profile cycle roundtrip")
 # All Lab artifact types have valid save/test/ready paths.
 for kind in ["ability","enemy","behavior","object","realm"]:
  var value=preload("res://scripts/studio_examples.gd").all(kind)[0] if kind in ["ability","enemy","behavior"] else preload("res://scripts/studio_world_project.gd").object() if kind=="object" else preload("res://scripts/studio_world_project.gd").example(0)
  check(C.check_value(kind,value).is_empty(),kind+" validates")
  check(C.test(kind,value,{"seconds":3}).is_empty(),kind+" receipt")
  C.stored(kind,value,true);check(C.readiness(L.load_data(),kind,value).ready,kind+" ready")
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);current_scene=game
 for n in 8:await process_frame
 game.set_process(false);game.legacy.set_process(false);game.presentation.close();game.session_menu.resume();game.hero_workshop.open()
 var page=preload("res://scripts/studio_showcase.gd").new();game.hero_workshop.add_child(page);page.setup(game.hero_workshop)
 for n in 4:await process_frame
 check(page.content.get_child_count()>0,"journey renders saved creations")
 for tab in [1,2,3]:page.page=tab;page.render();check(page.content.get_child_count()>0,"page "+str(tab))
 for kind in ["hero","ability","enemy","behavior","realm","object"]:
  var value=p if kind=="hero" else preload("res://scripts/studio_examples.gd").all(kind)[0] if kind in ["ability","enemy","behavior"] else preload("res://scripts/studio_world_project.gd").object() if kind=="object" else preload("res://scripts/studio_world_project.gd").example(0)
  page.play(kind,value)
  if is_instance_valid(page.arena):page.arena.time=3
  page.finish_test();check(page.test_layer==null,"finish "+kind+" sandbox")
 for voice in game.journey.voices:voice.stop()
 game.queue_free();await process_frame;await create_timer(.3).timeout
 print("v154 creation: ",checks," checks / ",failures," failures");quit(failures)
