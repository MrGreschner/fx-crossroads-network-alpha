extends SceneTree
const Project=preload("res://scripts/workshop_project.gd")
var failures:=0
var game:Node
func check(ok:bool,title:String)->void:
 print("PASS: " if ok else "FAIL: ",title)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func arena_for(p:Dictionary)->Control:
 var a=load("res://scripts/workshop_arena.gd").new();root.add_child(a);a.size=Vector2(900,540);a.begin(p,[],"Cluster");a.set_process(false);return a
func run()->void:
 var p=Project.fresh();check(Project.validate(p).is_empty(),"fresh project validates")
 var roundtrip:Variant=JSON.parse_string(JSON.stringify(p));check(Project.validate(roundtrip).is_empty(),"portable JSON round-trip")
 check(Project.fingerprint(p)==Project.fingerprint(roundtrip),"build fingerprint survives portable JSON numeric types")
 var invalid=p.duplicate(true);invalid.hero.primary.damage=INF;check(not Project.validate(invalid).is_empty(),"nonfinite damage rejected")
 invalid=p.duplicate(true);invalid.hero.primary.style="res://scripts/game.gd";check(not Project.validate(invalid).is_empty(),"unknown behaviour rejected")
 invalid=p.duplicate(true);invalid.hero.primary.script="arbitrary";check(not Project.validate(invalid).is_empty(),"code fields rejected")
 invalid=p.duplicate(true);invalid.techniques[1].slot="secondary";check(not Project.validate(invalid).is_empty(),"mastery slots must differ")
 invalid=p.duplicate(true);invalid.code_lab.enabled=true;check(not Project.validate(invalid).is_empty(),"future code execution disabled")
 check(not Project.validate({"format":"profile"}).is_empty(),"profile is not a student project")
 var image=Image.create(32,32,false,Image.FORMAT_RGBA8);image.fill(Color("#e6b070"));p.hero.art.idle=Marshalls.raw_to_base64(image.save_png_to_buffer())
 check(Project.validate(p).is_empty(),"embedded PNG accepted")
 var bytes=image.save_png_to_buffer();bytes[16]=1;check(not Project.png_error(bytes).is_empty(),"PNG oversized dimensions rejected before decode")
 var a=arena_for(p);a.player=Vector2(420,270);a.aim=Vector2.RIGHT;p.hero.primary.damage=18
 a.cast("primary");check(a.damage>0,"melee hits directional target cluster")
 var before:float=a.damage;a.cast("primary");check(a.damage==before,"cooldown prevents repeated instant casts")
 a.reset();a.player=Vector2(420,270);a.aim=Vector2.RIGHT;a.hero.primary.charge=1.0;a.press("primary");check(a.damage==0,"charge does not hit before release");a.tick(1);a.release("primary");check(a.damage>0,"charged release applies damage")
 a.reset();a.player=Vector2(420,270);a.hero.primary=Project.attack("projectile");a.hero.primary.range=500;a.aim=Vector2.RIGHT;a.cast("primary")
 for n in 50:a.tick(.02)
 check(a.damage>0 and a.shots.is_empty(),"projectile damage and expiry")
 a.reset();a.player=Vector2(420,270);a.hero.primary=Project.attack("spin");a.hero.primary.status="slow";a.hero.primary.radius=180;a.cast("primary");check(a.status_hits>0 and a.foes.any(func(f):return f.slow>0),"area slow visible in target state")
 for n in 100:a.tick(.05)
 check(a.foes.all(func(f):return f.slow==0),"status expires")
 a.reset();a.player=Vector2(280,370);a.health=70;a.hero.primary=Project.attack("heal_wave");a.cast("primary");check(a.healing>0 and a.ally_hp>50,"heal self and allied target")
 a.reset();a.hero.primary=Project.attack("summon");a.hero.primary.count=5;a.cast("primary");check(a.minions.size()==5,"bounded minion summon")
 a.cooldowns.primary=0;a.cast("primary");check(a.minions.size()==5,"minion cap")
 for n in 100:a.tick(.05)
 check(a.minions.is_empty(),"summons expire")
 a.reset();a.hero.primary=Project.attack("target_aoe");a.hero.primary.range=600;a.hero.primary.radius=100;a.aim_point=Vector2(500,270);a.cast("primary")
 for n in 80:a.tick(.02)
 check(a.damage>0,"lob detonates on aimed position")
 a.reset();a.hero.primary=Project.attack("flame");a.player=Vector2(420,270);a.aim=Vector2.RIGHT;a.press("primary");a.tick(.25);check(a.damage>0,"held flame channel ticks");a.release("primary");before=a.damage;a.tick(.25);check(a.damage==before,"release stops channel")
 a.reset();a.take_hit(20);var ordinary=a.incoming;a.reset();a.protection=3;a.take_hit(20);check(a.incoming<ordinary,"protection reduces incoming damage")
 for style in Project.STYLES:
  a.reset();a.hero.primary=Project.attack(style)
  if style=="custom":a.hero.primary.program=preload("res://scripts/studio_script.gd").template(Project.attack("spread"))
  a.player=Vector2(420,270);a.aim=Vector2.RIGHT
  if style=="flame":a.press("primary")
  else:a.cast("primary")
  for n in 80:a.tick(.05)
  a.cancel_holds()
  check(a.shots.size()<=60 and a.fields.size()<=16 and a.minions.size()<=5,"runtime bounded: "+style)
 a.reset();a.player=Vector2(420,270);a.hero.primary=Project.attack("chain");a.hero.primary.count=3;a.cast("primary");check(a.hits==3,"chain hits exactly three distinct targets")
 a.reset();a.player=Vector2(420,270);a.hero.primary=Project.attack("dash");a.aim_point=Vector2(580,270);a.cast("primary");check(a.player.x>420 and a.damage>0,"dash moves and damages its line")
 a.reset();a.hero.primary=Project.attack("trap");a.player=Vector2(420,270);a.aim_point=Vector2(500,270);a.cast("primary");a.tick(.1);check(a.damage>0 and a.fields.is_empty(),"mine detonates on proximity")
 a.reset();a.hero.primary=Project.attack("heal_zone");a.aim_point=Vector2(280,370);a.cast("primary");a.tick(.1);check(a.ally_hp>50,"placed field heals allied target")
 for n in 200:a.tick(.05)
 check(a.fields.is_empty(),"fields expire")
 a.reset();a.hero.primary=Project.attack("spin");a.hero.primary.status="burn";a.player=Vector2(420,270);a.hero.primary.radius=180;a.cast("primary");var immediate:float=a.damage
 a.tick(.5);check(a.damage>immediate,"status damage continues after initial hit")
 a.reset();a.player=Vector2(420,270);a.hero.primary=Project.attack("spin");a.hero.primary.radius=180;a.hero.primary.charge=1;a.aim=Vector2.RIGHT;a.cast("primary",0);var base_damage:float=a.damage
 a.reset();a.player=Vector2(420,270);a.cast("primary",1);check(a.damage>base_damage,"full charge strengthens damage")
 a.reset();a.scenario="Combat";a.hero.primary=Project.attack("summon");a.hero.primary.count=1;a.player=Vector2(420,270);a.cast("primary")
 for n in 20:a.tick(.05)
 check(a.minions.is_empty() or a.minions[0].hp<40,"combat targets can damage summons")
 a.reset();a.hero.primary=Project.attack("flame");a.press("primary");a._notification(NOTIFICATION_APPLICATION_FOCUS_OUT);check(a.holds.is_empty(),"focus loss cancels held attacks")
 var alternate=p.duplicate(true);alternate.techniques[0].slot="primary";alternate.techniques[0].attack.style="homing";a.begin(alternate,[0],"Cluster");check(a.hero.primary.style=="homing" and alternate.hero.primary.style=="melee","mastery replaces test build without editing base hero")
 var report=a.report(p.notes);check(report.project_id==p.project_id and report.project_hash==Project.fingerprint(a.project) and report.scope.contains("not a public"),"report identifies exact tested project + scope")
 a.queue_free()
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);current_scene=game
 await process_frame;game.set_process(false);game.presentation.close();game.session_menu.resume();game.menu=""
 var snapshot=JSON.stringify(game.legacy.data);var selected:String=game.selected_character;var roster:int=game.characters.size();var gold:int=game.gold
 var w:Node=game.hero_workshop;w.project=p.duplicate(true);w.open()
 for n in 3:await process_frame
 check(w.hub.visible and game.menu=="workshop","workshop opens from game")
 for tab in [0,1,2,3,4,6]:
  print("Editor tab ",tab);w.tabs.current_tab=tab;w.render();await process_frame;print("Tab ready ",tab)
 check(w.project.hero.art.has("idle"),"artwork survives editor tabs")
 check(not w.read_project('{"bad":true}') and w.project.hero.name==p.hero.name,"bad import preserves current project")
 check(w.read_project(JSON.stringify(p)),"valid project imports")
 w.start_test();await process_frame;check(w.test_panel.visible and w.arena!=null,"one-click playtest")
 w.arena.set_process(false);w.arena.player=Vector2(420,270);w.arena.aim=Vector2.RIGHT;w.arena.cast("primary");w.arena.tick(.5);w.finish_test()
 check(w.project.reports.size()==1 and w.latest_report.damage>0,"finished test stored in portable project")
 check(Project.validate(w.project).is_empty(),"tested project remains valid")
 w.close();await process_frame
 check(JSON.stringify(game.legacy.data)==snapshot and game.selected_character==selected and game.characters.size()==roster and game.gold==gold,"workshop never changes player progress, selection, gold or roster")
 check(not w.active and game.menu.is_empty(),"closing returns to previous menu")
 var local=arena_for(p);local.size=Vector2(650,350);var e=InputEventMouseMotion.new();e.position=local.draw_offset()+Vector2(500,270)*local.scale_factor();local._gui_input(e);check(local.aim_point.distance_to(Vector2(500,270))<.1,"scaled aim matches pointer in letterboxed arena");local.queue_free()

 print("V123 workshop failures: ",failures);quit(1 if failures else 0)
