extends SceneTree
const Project=preload("res://scripts/workshop_project.gd")
const Language=preload("res://scripts/studio_script.gd")
const Library=preload("res://scripts/studio_library.gd")
var failures=0
func check(ok:bool,message:String)->void:
 print("PASS: " if ok else "FAIL: ",message)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 var p=Project.fresh();p.hero.primary.style="custom";p.hero.primary.program=Language.template(Project.attack("spread"))
 check(Project.validate(p).is_empty(),"custom project validates")
 var parsed=Language.compile(p.hero.primary.program);check(parsed.error.is_empty(),"code compiles")
 check(Language.actions(parsed.instructions,false,true,0,[]).size()==3,"loop produces three actions")
 check(Language.actions(parsed.instructions,true,true,0,[]).size()==4,"charge condition adds an action")
 for source in ["emit OS.execute","let damage = 10000\nemit pulse","repeat 1000\nemit pulse\nend","emit projectile angle load('secret')","end","repeat 3\nemit pulse","emit projectile angle 1 / 0"]:check(not Language.compile(source).error.is_empty(),"reject unsafe / invalid instruction: "+source.left(28))
 var compiled=Language.compile("repeat 5\nrepeat 5\nrepeat 5\nemit projectile\nend\nend\nend");check(Language.actions(compiled.instructions,false,true,0,[]).size()<=32,"nested loops capped at 32 actions")
 var a=preload("res://scripts/workshop_arena.gd").new();root.add_child(a);a.begin(p,[],"Cluster");a.set_process(false);a.player=Vector2(420,270);a.cast("primary");check(a.shots.size()==3,"custom code launches actual projectiles")
 for n in 100:a.tick(.03)
 check(a.damage>0,"custom code damages synthetic targets")
 for style in Project.STYLES:
  var build=Project.fresh();build.hero.primary=Project.attack(style)
  if style=="custom":build.hero.primary.program=Language.template(Project.attack("spread"))
  check(Project.validate(build).is_empty(),"supported style validates: "+style)
  a.begin(build,[],"Cluster");a.player=Vector2(420,270);a.aim=Vector2.RIGHT;a.aim_point=Vector2(500,270)
  if style=="flame":a.press("primary")
  else:a.cast("primary")
  for n in 80:a.tick(.04)
  check(a.shots.size()<=60 and a.fields.size()<=16 and a.minions.size()<=5,"runtime remains bounded: "+style)
 for passive in Project.PASSIVES:
  var build=Project.fresh();build.hero.passive=passive;build.hero.passive_aura=true
  a.begin(build,[],"Combat");a.player=Vector2(420,270);a.health=70;a.cast("primary");a.tick(.5);check(a.health>=0,"passive works: "+passive)
 var pixels=preload("res://scripts/studio_pixel_canvas.gd").new();root.add_child(pixels);pixels.size=Vector2(320,320);pixels.load_png("");pixels.ink=Color("#ef9244");pixels.snapshot();pixels.edit_at(Vector2(50,50));var encoded=pixels.encoded();check(not encoded.is_empty(),"pixel painting produces PNG")
 pixels.undo();check(pixels.image.get_pixel(5,5).a==0,"pixel undo restores transparency");pixels.load_png(encoded);pixels.transform_pose("Mirror");check(pixels.image.get_size()==Vector2i(32,32),"mirror preserves pixel dimensions")
 p.hero.art.idle=encoded;p.hero.primary.animation=[encoded,encoded];check(Project.validate(p).is_empty(),"custom program + pixel animation validates")
 check(Library.add_hero(p).is_empty() and Library.add_ability(p.hero.primary).is_empty(),"custom library persists")
 var payload={"format":"fx-crossroads-profile","version":1,"progress":{},"saves":{}}
 var path="user://test_studio_bundle.zip";check(preload("res://scripts/studio_bundle.gd").make(payload,path)==OK,"player ZIP writes")
 var restored=preload("res://scripts/studio_bundle.gd").read(path);check(restored.error.is_empty() and restored.payload.studio.heroes.size()==1 and restored.payload.studio.abilities.size()==1,"player ZIP restores heroes and custom attacks")
 check(restored.error.is_empty() and not restored.payload.studio.heroes.is_empty() and restored.payload.studio.heroes.values()[0].hero.primary.program==p.hero.primary.program,"portable code preserved")
 var example=JSON.parse_string(FileAccess.get_file_as_string("res://content/workshop/example-project.json"));check(Project.validate(example).is_empty() and example.hero.primary.style=="custom","example has working custom attack")
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);current_scene=game;await process_frame;game.set_process(false);game.presentation.close();game.session_menu.resume();game.menu=""
 var id=Library.hero_id(p);check(game.characters.has(id),"local hero registered separately from official roster")
 check(game.manifest.characters.size()==80,"official roster unchanged")
 game.selected_character=id;game.start_training();game.set_process(false);game.menu="";game.presentation.close()
 game.studio_live.initialise();game.position_in_world=game.enemies[0].pos-Vector2(50,0);game.studio_live.step(.01);game.studio_live.aim=Vector2.RIGHT;game.studio_live.hero.primary=Project.attack("melee");game.studio_live.hero.primary.range=100;var before=game.training_hits;game.studio_live.cast("primary");game.studio_live.tick(.15);check(game.training_hits>before,"custom runtime hits real training target")
 game.studio_live.hero.primary=Project.attack("dash");game.studio_live.aim_point=Vector2(0,0);game.studio_live.cooldowns.primary=0;game.studio_live.cast("primary");check(game.can_stand_at(game.studio_live.player),"custom movement respects terrain")
 game.hero_hall.custom_only=true;game.hero_hall.refresh();check(game.hero_hall.shown.has(id),"Custom Hall toggle shows local hero")
 var w=game.hero_workshop;w.project=p;w.open();check(w.hub.visible,"Studio opens two-tool hub")
 w.hub.hide();w.panel.show();w.tabs.current_tab=1;w.render();await process_frame
 var editor=preload("res://scripts/studio_pixel_editor.gd").new();w.add_child(editor);editor.setup(encoded,"Walk 1",p.hero.art);await process_frame;check(editor.canvas.image!=null,"pixel editor opens");editor.queue_free()
 w.open_lab();await process_frame;check(w.lab.preview.hero.primary.style=="custom","Ability Lab live replay uses custom program");w.lab.save_ability();w.lab.queue_free();await process_frame
 preload("res://scripts/education_access.gd").unlock("student")
 w.enter_classroom();await process_frame;check(w.room.player==Vector2(450,450),"separate walkable classroom map opens");w.room.talk();await process_frame;check(w.room.speech!=null,"Mr. G explains Studio and provides entry button");w.close()
 a.queue_free();pixels.queue_free();game.queue_free();await process_frame;await process_frame
 print("V124 failures: ",failures);quit(1 if failures else 0)
