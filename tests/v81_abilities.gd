extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false)
 g.enter_region("practice");g.obstacles.clear();g.scenery_tiles.clear();g.level=10;g.position_in_world=Vector2(1000,1000);g.health=160;g.menu="";g.legacy.data=g.legacy.defaults();g.enemies.clear()
 var c=g.adventure.combat;var kit=c.v78
 g.character_id="gopher";g.selected_character="gopher";g.hero=g.characters.gopher
 kit.clock_offset=kit.PERIOD*100+.2-Time.get_ticks_msec()/1000.0
 var direction:Vector2=kit.dig_vector("solo",Vector2.RIGHT)
 check(direction.x>0 and direction.length()<1,"dig speed reduced")
 check(kit.dig_vector("solo",Vector2.UP)==direction,"cannot steer halfway through dig")
 check(kit.dig_vector("solo",Vector2.ZERO)==direction,"dig finishes committed stroke")
 kit.clock_offset=kit.PERIOD*100+.8-Time.get_ticks_msec()/1000.0
 check(kit.dig_vector("solo",Vector2.UP)==Vector2.ZERO,"surface pause between strokes")
 kit.clock_offset=kit.PERIOD*101+.2-Time.get_ticks_msec()/1000.0
 check(kit.dig_vector("solo",Vector2.UP).y<0,"next stroke chooses new direction")
 kit.lock("solo",.3);check(kit.dig_vector("solo",Vector2.RIGHT)==Vector2.ZERO,"attacks stop digging")
 kit.reset();g.character_id="nullweaver";g.selected_character="nullweaver";g.hero=g.characters.nullweaver
 for x in [1100,1380]:
  var target:=Vector2(x,1050);c.v79.prepare("solo",g.hero.special,Vector2.RIGHT,target);c.cast("solo",g.hero.special,Vector2.RIGHT,40)
  var e:Dictionary=kit.effects[-1];check(c.vec(e.pos).distance_to(target)<1,"free aim uses cursor distance")
  var start:Vector2=kit.triangle_vertex(e,0)-c.vec(e.pos);e.age=1.2
  check((kit.triangle_vertex(e,0)-c.vec(e.pos)).distance_to(-start)<.01,"triangle visibly rotates 180 degrees")
 kit.reset();g.character_id="kite";g.selected_character="kite";g.hero=g.characters.kite;c.v79.reset()
 c.v79.prepare("solo",g.hero.secondary,Vector2.RIGHT,Vector2(1360,1000));c.cast("solo",g.hero.secondary,Vector2.RIGHT,28)
 c.v79.step(.85);check(c.v79.moving("solo"),"swing still active after old duration")
 check(g.position_in_world.y<970,"swing follows curved tether path")
 c.v79.step(.8);check(not c.v79.moving("solo"),"swing finishes at 1.65 seconds")
 print("v81 ability failures: ",failures);g.queue_free();await process_frame;quit(failures)
