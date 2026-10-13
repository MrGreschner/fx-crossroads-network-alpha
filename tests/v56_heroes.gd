extends SceneTree
var failures:int=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 game.selected_character="dustdevil";game.start_run(false,"petalbrook");game.level=6
 game.adventure.immersive.initialized=true;game.enemies.clear();game.position_in_world=Vector2(2800,3400)
 var combat=game.adventure.combat;var kit=combat.v56;var world=game.adventure.immersive
 var foe:Dictionary=world.spawn("briar_tail",Vector2(2855,3400));foe.hp=500;foe.max_hp=500
 check(game.manifest.characters.size()==43,"43 selectable heroes")
 kit.holding("solo",true,Vector2.RIGHT);combat.cast("solo",game.hero.primary,Vector2.RIGHT,12);kit.step(.05)
 check(foe.hp==488 and combat.effect_time(combat.npc_key(foe),"slow")>0,"intake deals low damage and slows")
 game.enemy_shots.append({"pos":Vector2(2940,3400),"direction":Vector2.LEFT,"speed":500.0,"damage":20,"distance":0.0})
 game.update_enemy_shots(.3)
 check(game.enemy_shots.is_empty() and kit.intakes.solo.has("captured"),"actual incoming shot captured before hero damage")
 check(not kit.catch_shot(Vector2(2900,3400),Vector2(2810,3400),"enemy",20,"#ffffff"),"can hold only one projectile")
 kit.holding("solo",false,Vector2.UP)
 check(kit.intakes.is_empty() and combat.projectiles.size()==1,"release fires once")
 check(combat.projectiles[0].aim==[0.0,-1.0] and combat.projectiles[0].damage==40,"release follows fresh aim after Overload replaces Deep Filter")
 kit.reset();combat.projectiles.clear();combat.cast("solo",game.hero.primary,Vector2.RIGHT,12)
 kit.holding("solo",true,Vector2.RIGHT);kit.step(.41)
 check(not kit.catch_shot(Vector2(2920,3400),Vector2(2810,3400),"enemy",20,"#ffffff"),"catch window requires timing")
 kit.reset();foe.pos=Vector2(3050,3400);combat.cast("solo",game.hero.special,Vector2.RIGHT,0)
 var before:float=foe.pos.x
 kit.step(.3)
 check(foe.pos.x<before and foe.pos.x>2800,"vacuum pulls towards nozzle")
 kit.reset();game.hero=game.characters.cairnheart;foe.pos=Vector2(2900,3400);foe.hp=500
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,24);kit.step(.5)
 check(foe.hp==476,"successive faults damage each foe once")
 check(combat.reduction("solo")>=.05,"Bedrock guard passive")
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,36)
 check(combat.stunned(combat.npc_key(foe)),"stone hoist stuns")
 kit.step(1.2);check(foe.hp==440,"hoist has delayed landing damage")
 kit.reset();foe.pos=Vector2(2970,3400);foe.hp=500;combat.cast("solo",game.hero.special,Vector2.RIGHT,62)
 for n in 20:kit.step(.1)
 check(foe.hp==438 and kit.ramps.is_empty(),"rampart hits once and ends at range")
 kit.reset();game.hero=game.characters.cloudloom;game.health=70;foe.pos=Vector2(3000,3400);foe.hp=500
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,8);kit.step(.3)
 check(combat.projectiles.is_empty(),"cloud pauses before burst")
 kit.step(.25);check(combat.projectiles.size()==3,"cloud releases three rain shots")
 combat.projectiles.clear();combat.cast("solo",game.hero.secondary,Vector2.RIGHT,7);kit.step(1)
 check(foe.hp==493 and game.health==72 and combat.effect_time("p:solo","rune_stride")>0,"wind lane damages enemies, heals and speeds allies")
 kit.reset();foe.hp=500;combat.cast("solo",game.hero.special,Vector2.RIGHT,28)
 for n in 40:kit.step(.1)
 check(foe.hp==416 and kit.storms.is_empty(),"three moving storm clouds each hit once")
 var data:Dictionary=JSON.parse_string(JSON.stringify(kit.snapshot()))
 kit.receive(data)
 check(data.has("intakes") and data.has("storms"),"new effects serialize")
 for voice in game.journey.voices:voice.stop()
 game.queue_free();await create_timer(.3).timeout
 print("v56 heroes: ",failures," failures");quit(1 if failures else 0)
