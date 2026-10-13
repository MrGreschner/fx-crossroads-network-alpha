extends SceneTree
var failures:=0
var checks:=0
func check(ok:bool,label:String)->void:
 checks+=1;print("PASS • " if ok else "FAIL • ",label)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g
 for n in 5:await process_frame
 g.set_process(false);g.presentation.close();g.session_menu.resume();g.legacy.set_process(false)
 var academy=g.academy_town
 check(not academy.allowed(),"Academy is locked on a fresh ordinary profile")
 g.hero_workshop.open();g.hero_workshop.enter_classroom()
 check(not is_instance_valid(g.hero_workshop.room),"direct classroom entry cannot bypass education lock")
 g.hero_workshop.close()
 check(preload("res://scripts/education_access.gd").unlock("student"),"student access unlocks")
 check(academy.allowed(),"student can enter Academy")
 g.hero_workshop.open();g.hero_workshop.enter_classroom()
 check(is_instance_valid(g.hero_workshop.room),"classroom opens for student")
 g.hero_workshop.close()
 check(g.can_stand_at(g.studio_town.ENTRY),"Studio doorstep is walkable")
 check(g.can_stand_at(academy.ENTRY),"Academy doorstep is walkable")
 check(g.can_stand_at(g.town_v109.ENTRIES.relay),"Relay workshop doorstep is walkable")
 for route in g.town_plan.ROADS:
  for point in route:
   check(g.can_stand_at(point),"street waypoint clear: "+str(point))
 for id in g.legacy.PROJECTS:g.legacy.data.town[id]=true
 for route in g.town_plan.ROADS:
  for n in range(1,route.size()):
   var a:Vector2=route[n-1];var b:Vector2=route[n];var clear=true
   for k in range(1,1+int(a.distance_to(b)/15)):
    if not g.can_stand_at(a.lerp(b,k/(1.0+int(a.distance_to(b)/15)))):clear=false
   check(clear,"connected street clear: "+str(a)+" → "+str(b))
 for realm in ["astral_rift","clockwork_orchard","brasslock","moonveil","zombie"]:
  g.start_run(false,realm);g.presentation.close();g.menu=""
  var added=g.enemies.filter(func(e):return str(e.type) in g.adventure.newcomers.TYPES)
  check(added.size()==(2 if realm in ["astral_rift","clockwork_orchard","brasslock"] else 4 if realm=="moonveil" else 7),"new encounters load in "+realm)
  for e in added:check(g.can_stand_at(e.pos),"enemy placement accessible: "+str(e.type)+" "+str(e.pos))
  var foe=added[0];var before:Vector2=foe.pos
  g.position_in_world=before+Vector2(100,0)
  for n in 100:g.adventure.newcomers.step(.05)
  check(g.adventure.newcomers.clock>0 and (foe.pos!=before or not g.adventure.newcomers.warnings.is_empty()),"new AI moves/casts in "+realm)
  check(g.adventure.newcomers.warnings.size()<=28 and g.adventure.newcomers.pools.size()<=12,"effects bounded in "+realm)
  var snap=g.adventure.newcomers.snapshot();g.adventure.newcomers.receive(snap);check(g.adventure.newcomers.clock>0,"realm effects survive network snapshot")
 g.start_run(false,"zombie");g.presentation.close();g.menu="";g.position_in_world=Vector2(3900,725)
 g.adventure.newcomers.step(.1)
 var warden=g.enemies.filter(func(e):return e.type=="quarantine_warden")[0]
 check(warden.boss,"Quarantine Warden uses boss health/portrait presentation")
 check(g.adventure.on_defeat(warden) and not g.boss_defeated,"midboss defeat does not finish realm before Director")
 g.health=50;g.adventure.combat.feedback.healing_numbers.clear();g.health=57.5
 check(g.adventure.combat.feedback.healing_numbers.size()==1 and float(g.adventure.combat.feedback.healing_numbers[0].amount)==7.5,"direct healing and life-on-hit display actual restored health")
 g.health=g.max_health();g.adventure.combat.feedback.healing_numbers.clear();g.health=minf(g.max_health(),g.health+10)
 check(g.adventure.combat.feedback.healing_numbers.is_empty(),"overheal creates no false healing number")
 g.enter_region("town");g.health=40;g.health=60
 check(g.adventure.combat.feedback.healing_numbers.is_empty(),"town healing does not show combat numbers")
 for voice in g.journey.voices:voice.stop()
 await create_timer(.3).timeout
 g.free();await process_frame
 print("V143 CHECKS: ",checks,"; FAILURES: ",failures);quit(1 if failures else 0)
