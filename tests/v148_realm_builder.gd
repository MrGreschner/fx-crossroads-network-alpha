extends SceneTree
const W=preload("res://scripts/studio_world_project.gd")
const P=preload("res://scripts/workshop_project.gd")
var count=0
var failures=0
func check(ok:bool,message:String)->void:
 count+=1;print("PASS • " if ok else "FAIL • ",message)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func run()->void:
 var world=W.realm(256,256);check(W.validate_realm(world).is_empty(),"256-square portable full-size map")
 check(W.checks(world).is_empty(),"large map route traversal")
 check(W.blocked(world,Vector2(-1,20)),"negative world coordinates cannot escape boundary")
 var bad=world.duplicate(true);bad.environment.weather="script";check(not W.validate_realm(bad).is_empty(),"environment whitelist")
 bad=world.duplicate(true);bad.tiles[0].damage=999;check(not W.validate_realm(bad).is_empty(),"hazard damage bounded")
 bad=world.duplicate(true);bad.width=257;check(not W.validate_realm(bad).is_empty(),"map size bounded")
 var renderer=load("res://scripts/studio_world_renderer.gd").new();world=W.example(0)
 renderer.prepare(world);var first=renderer.bake(world,Vector2i(0,0));check(first!=null and renderer.bake(world,Vector2i(0,0))==first,"shared terrain chunks reused")
 for n in 24:renderer.bake(W.realm(256,256),Vector2i(n%16,n/16))
 check(renderer.chunks.size()<=16,"terrain texture cache memory bounded")
 renderer.invalidate();check(renderer.chunks.is_empty(),"painting invalidates terrain cache")
 for name in W.OBJECTS:
  check(ResourceLoader.exists("res://assets/"+W.ASSETS[name]),"professional prop asset "+name)
 var canvas=load("res://scripts/studio_world_canvas.gd").new();root.add_child(canvas);canvas.size=Vector2(900,500);canvas.setup(world);canvas.focus_spawn();var at=canvas.origin()+Vector2(10.5,10.5)*40*canvas.zoom
 var prior=world.grid[10*int(world.width)+10];canvas.snapshot();canvas.tile=3;canvas.brush=3;canvas.paint(at);check(world.grid[10*int(world.width)+10]==3,"multi-cell terrain brush")
 canvas.undo();check(world.grid[10*int(world.width)+10]==prior,"undo restores map")
 canvas.redo();check(world.grid[10*int(world.width)+10]==3,"redo restores revision");canvas.queue_free()
 var runtime=load("res://scripts/studio_realm_test.gd").new();root.add_child(runtime);var hero=P.fresh();world=W.realm(20,20);world.tiles[0].damage=8;runtime.setup(world,hero);runtime.set_process(false);runtime.tick(.05)
 check(runtime.health<float(hero.hero.max_health),"terrain hazard causes real damage")
 world.tiles[0].damage=0;world.clear_required=true;var enemy=load("res://scripts/studio_enemy_project.gd").fresh();world.enemies[enemy.id]=enemy;world.placements=[{"kind":"enemy","id":enemy.id,"cell":[10,10]}];runtime.setup(world,hero);runtime.player=Vector2(world.exit[0]*40+20,world.exit[1]*40+20);runtime.tick(.02)
 check(runtime.result.is_empty(),"clear-before-exit objective enforced");runtime.foes[0].hp=0;runtime.tick(.02);check("Realm complete" in runtime.result,"cleared objective completes")
 runtime.setup(world,hero);check(runtime.actors.size()==1 and runtime.result.is_empty(),"restart resets combat and replaces agents")
 world=W.realm(20,20)
 for y in range(0,17):world.grid[y*20+5]=4
 runtime.setup(world,hero)
 check(runtime.navigation.is_point_solid(Vector2i(5,5)),"navigation respects blocking terrain")
 check(runtime.navigation.get_id_path(Vector2i(3,3),Vector2i(7,3)).size()>20,"enemies can route around a wall through its opening")
 runtime.queue_free();await process_frame
 print("V148 ",count," checks / ",failures," failures");quit(1 if failures else 0)
