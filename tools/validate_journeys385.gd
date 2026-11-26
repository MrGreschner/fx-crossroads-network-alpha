extends SceneTree
const J=preload("res://scripts/hero_journeys373.gd")
const U=preload("res://scripts/hero_unlocks371.gd")
const D=preload("res://scripts/journey_design385.gd")
var g:Node
func _initialize():call_deferred("run")
func stable():
 await process_frame;await process_frame;await create_timer(.12).timeout
func capture(name:String):
 g.queue_redraw();await stable();await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("user://"+name+".png")
func run():
 root.set_meta("fx_intro_seen",true);g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await stable();g.set_process(false);g.get_window().size=Vector2i(1280,720)
 g.legacy.data.teacher=false;g.legacy.data.hero_ownership={"version":4,"owned":[]};g.legacy.data.hero_journeys={"version":1,"prepared":[]}
 var realms=load("res://scripts/hero_goals372.gd").realms().filter(func(k):return load("res://scripts/hero_goals372.gd").normal_realm(str(k)))
 for count in [3,4,7,13]:
  g.legacy.data.tasks.realms=realms.slice(0,count)
  var available=[]
  for id in J.ids():
   if id=="patch" or J.catalog()[id].has("event"):continue
   if J.eligible(g.legacy,id):available.append(id)
  print("BATCH ",count," ",available)
  if count==3:assert(available.is_empty())
  if count==4:assert(available.size()==4 and "beaver" in available and "drum" in available and "spindle" in available and "dawnblade" in available)
  if count==7:assert(available.size()==18)
 assert(U.EPOCH==4);g.legacy.data.hero_ownership.owned=["caelum"];g.legacy.data.tasks.realms=[];assert(U.owned(g.legacy,"caelum"));assert(J.progress(g.legacy,"caelum").contains("Owned"));g.legacy.data.hero_ownership.owned=[]
 for id in J.ids():
  if id=="patch":continue
  assert(J.catalog()[id].loan)
  if J.battle(id):assert(load("res://scripts/champion_brain374.gd").PROFILES.has(id) and U.PLANS.has(id))
  else:assert(D.COURSES.has(id) and not J.catalog()[id].stages.is_empty())
 print("PASS unlock batches, permanent earned ownership, every journey kit and every duel profile")
 g.menu="characters";g.hero_hall.refresh();g.hero_hall.was_open=true;g.hero_hall.open_grid();await stable()
 var grid=g.hero_hall.portrait_grid
 for size in [Vector2i(1280,720),Vector2i(960,540),Vector2i(390,844)]:
  g.get_window().size=size;await stable();await stable()
  assert(grid.tiles.size()==80)
  var top=grid.scroll.get_global_rect();var max_bottom=0.0
  for tile in grid.tiles.values():
   var rect:Rect2=tile.get_global_rect();max_bottom=maxf(max_bottom,rect.end.y)
   assert(rect.position.x>=top.position.x-1 and rect.end.x<=top.end.x+1)
  print("GRID ",size," columns ",grid.grid.columns," bottom ",max_bottom," viewport bottom ",top.end.y," min ",grid.grid.get_combined_minimum_size())
  assert(max_bottom<=top.end.y+1)
  var logical=grid.get_viewport().get_visible_rect().size
  assert(top.end.y<=logical.y and grid.panel.get_global_rect().end.x<=logical.x and grid.panel.get_global_rect().end.y<=logical.y)
  assert(grid.scroll.scroll_vertical==0)
  await capture("Hero_Grid_"+str(size.x)+"_V385")
 grid.close();await stable();g.get_window().size=Vector2i(1280,720);await stable();await capture("Hero_Hall_V385")
 g.queue_free();await stable()
 # Real scene entry from a different starter must always load the requested borrowed kit.
 for id in ["beaver","anjali","nutcracker"]:
  root.set_meta("fx_hero_journey",{"id":id,"hero":"cat"})
  g=load("res://scenes/hero_journey373.tscn").instantiate();root.add_child(g)
  g.legacy.data.teacher=false;g.legacy.data.hero_ownership={"version":4,"owned":[]};g.legacy.data.tasks.realms=realms
  await stable();g.set_process(false)
  assert(g.course_active and g.character_id==id and g.selected_character==id and g.hero.id==id and g.return_hero=="cat")
  assert(not U.owned(g.legacy,id))
  g.presentation.close();g.menu="";g.mobile.enabled=false;g.mobile.reset_controls();g.message="";g.message_time=0;g.journey.welcome_remaining=0;g.legacy.flash=0;g.course_label.text=str(g.characters[id].name)+" • "+g.course.status();g.course_button.visible=g.course.interactive()
  g.camera=Vector2(300,250);await capture("Journey_"+id+"_V385")
  if id=="anjali":
   var trial=g.course
   var foe=g.enemies[0];trial.hit(foe,20);assert(trial.count==1)
   for target in g.enemies.duplicate():trial.hit(target,20)
   assert(trial.advance_pending and trial.stage_index==0)
   trial.step(.01);assert(trial.stage_index==1 and not trial.advance_pending)
   for target in g.enemies.duplicate():trial.hit(target,20)
   assert(trial.advance_pending and trial.stage_index==1);trial.step(.01);assert(trial.stage_index==2)
   print("PASS same-kind target stages advance once after combat, not during projectile iteration")
  print("PASS actual course entry ",id," uses borrowed target kit, keeps previous selection for return, grants no ownership")
  if id=="beaver":
   for lesson in D.COURSES:
    g.journey_id=lesson;g.character_id=lesson;g.selected_character=lesson;g.hero=g.characters[lesson].duplicate(true);g.position_in_world=Vector2(420,650)
    g.course=load("res://scripts/hero_trial373.gd").new();g.course.setup(g,J.catalog()[lesson]);g.course_active=true
    for stage in J.catalog()[lesson].stages.size():
     g.course.stage_index=stage-1;g.course.next_stage()
     assert(g.course.passable(g.position_in_world,8))
     for object in g.course.objects:assert(g.course.passable(object.pos,8))
    if lesson=="finch_frost":
     g.course.stage_index=0;g.course.next_stage();assert(g.course.objective.kind=="freeze")
     var frozen_key=g.adventure.combat.npc_key(g.enemies[0])
     g.adventure.combat.events.frost.chills[frozen_key]={"freeze":1.0};g.course.step(.01);assert(g.course.advance_pending)
    if lesson=="nutcracker":
     g.course.stage_index=0;g.course.next_stage();g.course.cast("primary",0);assert(g.course.count==0)
     g.adventure.combat.events.nutcracker.stance["solo"]={"time":4.5,"angle":0.0};g.course.cast("secondary",0)
     for hit in 3:g.course.cast("primary",0);g.course.hit(g.enemies[0],21)
     assert(g.course.advance_pending)
   print("PASS every authored lesson/stage enters with reachable markers; frost requires real frozen state and planted spear lesson requires stance hits")

  g.queue_free();await stable()
 # Direct personal duel also borrows its target hero while retaining the return hero.
 root.set_meta("fx_champion_trial",{"champion":"dawnblade","hero":"cat","loan":true})
 g=load("res://scenes/champion_duel371.tscn").instantiate();root.add_child(g);g.legacy.data.teacher=false;g.legacy.data.hero_ownership={"version":4,"owned":[]};g.legacy.data.tasks.realms=realms;await stable();g.set_process(false)
 assert(g.champion_id=="dawnblade" and g.hero_ids.solo=="dawnblade" and g.hero_ids["bot:0"]=="dawnblade" and g.return_hero=="cat")
 assert(not U.owned(g.legacy,"dawnblade"));g.presentation.close();await capture("Personal_Duel_V385")
 g.queue_free();await stable();print("ALL V385 CHECKS PASSED");quit()
