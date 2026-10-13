extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();g.set_script(load("res://tests/v82_input_game.gd"));root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false)
 g.enter_region("practice");g.obstacles.clear();g.scenery_tiles.clear();g.level=10;g.position_in_world=Vector2(1000,1000);g.health=160;g.menu="";g.legacy.data=g.legacy.defaults();g.enemies.clear()
 var c=g.adventure.combat
 g.character_id="nullweaver";g.selected_character="nullweaver";g.hero=g.characters.nullweaver
 for target in [Vector2(1100,1050),Vector2(1300,900)]:
  g.test_target=target;g.cooldowns.special=0;g.pulse()
  check(c.vec(c.v78.effects[-1].pos).distance_to(target)<1,"actual special dispatch uses free target")
 c.v78.reset();g.character_id="kite";g.selected_character="kite";g.hero=g.characters.kite;c.v79.reset();g.position_in_world=Vector2(1000,1000);g.test_target=Vector2(1150,1000);c.v79.velocities.solo=Vector2(0,-280)
 g.fire("secondary");var previous:Vector2=g.position_in_world;var travelled:=0.0
 for n in 30:
  c.v79.step(.05);travelled+=previous.distance_to(g.position_in_world);previous=g.position_in_world
 check(travelled>450,"swing keeps momentum and accelerates")
 check(c.v79.moving("solo"),"swing remains active after 1.5s")
 check(absf(g.position_in_world.distance_to(g.test_target)-150)<1,"true orbit around selected anchor")
 c.v79.holding("solo",false,Vector2.RIGHT);c.v79.step(.05)
 check(not c.v79.moving("solo") and c.v79.velocities.solo.length()>400,"swing releases with aim-directed momentum")
 c.v79.reset();g.character_id="gopher";g.selected_character="gopher";g.hero=g.characters.gopher;g.position_in_world=Vector2(1000,1000);g.test_target=Vector2(1050,1000)
 g.adventure.spawn("bramble",g.test_target,1000,false)
 var hp:float=g.enemies[-1].hp
 g.cooldowns.primary=0;g.fire("primary");c.v78.step(.02)
 check(g.enemies[-1].hp==hp-18,"first swipe deals18")
 c.v78.step(.15);check(g.enemies[-1].hp==hp-36,"second swipe deals18")
 c.v78.step(.1);check(g.enemies[-1].hp==hp-36,"no extra frame hits")
 var bleeds:=0;seed(82)
 for n in 200:
  g.enemies[-1].hp=1000;c.statuses.clear();c.v78.reset();c.v78.cast("solo",g.hero.primary,Vector2.RIGHT,18);c.v78.step(.01)
  if c.effect_time(c.npc_key(g.enemies[-1]),"bleed")>0:bleeds+=1
 check(bleeds>55 and bleeds<105,"40 percent bleed sampled independently")
 print("v82 ability failures: ",failures);g.queue_free();await process_frame;quit(failures)
