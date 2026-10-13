extends SceneTree
var failures=0
func check(value:bool,text:String)->void:
 print("PASS: " if value else "FAIL: ",text)
 if not value:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);current_scene=game;await process_frame;game.set_process(false);game.presentation.close();game.session_menu.resume();game.menu=""
 var L=preload("res://scripts/studio_library.gd");var P=preload("res://scripts/workshop_project.gd");var p=P.fresh();p.hero.name="Shared pupil";L.add_hero(p);var w=game.hero_workshop;w.project=p;w.save_draft()
 game.legacy.open_page("profile");game.legacy.export_profile();await process_frame
 var path=OS.get_user_data_dir()+"/native-player.zip";game.legacy.native_dialog.file_selected.emit(path);await process_frame
 check(FileAccess.file_exists(path),"profile Download writes native ZIP")
 var result=preload("res://scripts/studio_bundle.gd").read(path);check(result.error.is_empty() and game.legacy.validate(result.payload),"exported player ZIP passes real profile validation")
 game.legacy.import_zip(path);await process_frame;check(game.legacy.pending.has("studio") and game.legacy.pending.studio.heroes.size()==1,"ZIP import opens replacement preview with custom hero")
 check(result.payload.has("studio_draft") and result.payload.studio_draft.hero.name=="Shared pupil","unfinished Studio draft included")
 var old=game.legacy.bundle();check(game.legacy.validate(old),"old JSON player profiles remain supported")
 var broken=PackedByteArray();broken.resize(22);broken.encode_u32(0,0x06054b50);broken.encode_u16(10,91)
 check(not preload("res://scripts/studio_bundle.gd").zip_size_check(broken).is_empty(),"oversized member count rejected before decompression")
 var bad=P.fresh();bad.hero.primary=bad.hero.primary.duplicate();bad.hero.primary.style="custom";bad.hero.primary.program="emit OS.execute";check(not P.validate(bad).is_empty(),"arbitrary executable code rejected on import")
 var lib=L.load_data();lib.heroes={};L.save_data(lib);check(L.load_data().heroes.is_empty(),"library replacement round-trip")
 # Inspect main menu geometry across viewport sizes after layout settles.
 game.legacy.close();game.session_menu.open("main")
 for view in [Vector2i(1280,720),Vector2i(960,540),Vector2i(640,360)]:
  root.size=view
  for n in 5:await process_frame
  var panel=game.session_menu.panel;var rect=Rect2(panel.position,panel.size*panel.scale)
  check(rect.position.y>=0 and rect.end.y<=root.get_visible_rect().size.y+1,"main menu stays in viewport "+str(view))
 game.legacy.pending=result.payload;game.legacy.pending.progress.name="ZIP restored pupil";game.legacy.apply_import()
 for n in 12:await process_frame
 check(current_scene!=null and current_scene.legacy.data.name=="ZIP restored pupil" and current_scene.characters.has(L.hero_id(p)),"confirmed import restores profile and playable creation after scene reload")
 print("V124 profile ZIP failures: ",failures);quit(1 if failures else 0)
