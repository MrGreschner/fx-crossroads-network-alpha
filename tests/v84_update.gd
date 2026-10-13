extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();g.set_script(load("res://tests/v82_input_game.gd"));root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false)
 g.enter_region("practice");g.obstacles.clear();g.scenery_tiles.clear();g.level=10;g.health=150;g.menu="";g.position_in_world=Vector2(1000,1000);g.enemies.clear()
 var c=g.adventure.combat
 g.character_id="nullweaver";g.selected_character="nullweaver";g.hero=g.characters.nullweaver
 for target in [Vector2(1090,1040),Vector2(980,1150)]:
  g.test_target=target;g.cooldowns.primary=0;g.fire("primary")
  check(c.vec(c.v78.pins.solo[-1]).distance_to(target)<1,"pin lands at exact near mouse target")
 g.character_id="kite";g.selected_character="kite";g.hero=g.characters.kite;c.v79.reset();g.position_in_world=Vector2(1000,1000);g.test_target=Vector2(1150,1000);g.cooldowns.secondary=0
 c.v79.holding("solo",true,Vector2.UP);g.fire("secondary")
 for n in 30:c.v79.step(.05)
 check(c.v79.moving("solo"),"hold stays in orbit")
 c.v79.holding("solo",false,Vector2.DOWN);c.v79.step(.05)
 check(not c.v79.moving("solo"),"release stops orbit")
 check(c.v79.velocities.solo.normalized().distance_to(Vector2.DOWN)<.001,"release launches in current aim direction")
 for id in ["tidewright","cantor","shuttle","regent"]:
  check(g.characters.has(id),"hero loaded "+id)
  for pose in ["idle","walk1","walk2","attack"]:check(ResourceLoader.exists("res://assets/"+id+"_"+pose+".png"),"portrait/pose "+id+pose)
  g.character_id=id;g.selected_character=id;g.hero=g.characters[id];g.position_in_world=Vector2(1000,1000);g.test_target=Vector2(1200,1000);g.level=10;g.enemies.clear();c.setup("practice")
  g.adventure.spawn("bramble",Vector2(1200,1000),9999,false)
  for kind in ["primary","secondary","special"]:
   g.cooldowns[kind]=0
   if kind=="special":g.pulse()
   else:g.fire(kind)
   for n in 25:c.confluence.step(.02)
  check(float(g.enemies[0].hp)<9999,"hero damages via actual dispatch "+id)
  for alt in [g.hero.mastery.technique,g.hero.mastery.final_technique]:
   var stats:Dictionary=alt.get("attack",g.hero[alt.ability].duplicate(true))
   for key in alt.get("set",{}):stats[key]=alt.set[key]
   c.v79.prepare("solo",stats,Vector2.RIGHT,g.test_target);check(c.confluence.cast("solo",stats,Vector2.RIGHT,float(stats.damage)),"mastery alternate recognized "+id)
   c.confluence.step(.2)
 g.legacy.data=g.legacy.defaults();check(not g.legacy.eligible("tidewright"),"duet locked initially")
 var rec:Dictionary=g.legacy.record("tidewright");rec.clears=100;rec.damage=999999;rec.realms=["grove","quarry"]
 check(not g.legacy.eligible("tidewright"),"ordinary grinding cannot bypass duet clear")
 rec.duet_clear=true;check(g.legacy.eligible("tidewright"),"paired clear unlocks")
 g.enter_region("confluence");g.set_process(false);g.menu="";g.health=150
 var w=g.adventure.foundry
 check(w.active,"world activated")
 for p in [Vector2(320,1200),Vector2(1200,1200),Vector2(1500,590),Vector2(1500,1800),Vector2(2400,1200),Vector2(2520,430)]:check(w.can_stand(p),"walkable room "+str(p))
 check(not w.can_stand(Vector2(2935,1200)),"heart bridge locked")
 # Follow both real approach corridors with a 10px sampled route.
 var routes:Array=[[Vector2(320,1200),Vector2(1200,1200),Vector2(1200,600),Vector2(1540,600)],[Vector2(1200,1200),Vector2(1200,1800),Vector2(1540,1800)],[Vector2(1540,600),Vector2(2300,600),Vector2(2300,1200),Vector2(2510,1200)],[Vector2(2510,1200),Vector2(2475,950),Vector2(2475,430)]]
 for route in routes:
  for i in range(route.size()-1):
   var a:Vector2=route[i];var b:Vector2=route[i+1]
   for n in range(int(a.distance_to(b)/10)+1):check(w.can_stand(a.move_toward(b,n*10)),"connected route at "+str(a.move_toward(b,n*10)))
 for index in [0,1,2]:
  g.position_in_world=w.ROOMS[index].get_center();w.step(.016)
  check(w.started.has(index),"room encounter starts")
  for n in 15:w.step(.1)
  for enemy in g.enemies.duplicate():
   for i in range(g.enemies.size()-1,-1,-1):
    if g.enemies[i].uid==enemy.uid:g.damage_enemy(i,99999);break
  w.step(.016)
 check(w.can_stand(Vector2(2935,1200)),"both wings open bridge")
 g.position_in_world=Vector2(3500,1200);w.step(.016)
 check(g.enemies.any(func(e):return e.type=="confluence_heart"),"final boss exists")
 for n in 100:w.step(.1)
 check(w.bolts.size()<=24 and w.warnings.size()<=32,"bounded boss effects")
 for i in range(g.enemies.size()-1,-1,-1):
  if g.enemies[i].type=="confluence_heart":g.damage_enemy(i,99999)
 check(w.done,"boss unlocks exit")
 check(w.can_stand(w.EXIT),"exit reachable")
 print("v84 solo failures: ",failures);g.queue_free();await process_frame;quit(failures)
