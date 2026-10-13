extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.legacy.set_process(false);game.selected_character="thistlebond";game.start_run(false,"practice");game.practice=false;game.menu="";game.level=6;game.enemies.clear();game.obstacles.clear();game.scenery_tiles.clear();game.position_in_world=Vector2(1000,600);game.mobile.enabled=true;game.mobile.aim=Vector2.RIGHT
 var combat=game.adventure.combat
 game.adventure.spawn("bramble",Vector2(1200,600),80,false);var foe:Dictionary=game.enemies[-1]
 game.pulse();check(combat.pact.allies.has("solo") and game.enemies.is_empty(),"real solo Special action prepares and converts target")
 var cd:float=game.cooldowns.special;game.cooldowns.special=0;game.pulse();check(game.cooldowns.special==0,"no eligible target does not spend cooldown")
 combat.setup("practice");game.enemies.clear();game.adventure.spawn("bramble",Vector2(1100,600),500,false);var one:Dictionary=game.enemies[-1];game.adventure.spawn("bramble",Vector2(1000,700),500,false);var two:Dictionary=game.enemies[-1]
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,21)
 for n in 15:combat.step(.02)
 check(combat.effect_time(combat.npc_key(one),"poison")==0,"one marked enemy does not get poison")
 combat.cast("solo",game.hero.primary,Vector2.DOWN,21)
 for n in 15:combat.step(.02)
 check(combat.effect_time(combat.npc_key(one),"poison")>4 and combat.effect_time(combat.npc_key(two),"poison")>4,"second mark poisons both living enemies")
 combat.setup("practice");game.hero=game.characters.velvetwing;game.selected_character="velvetwing";game.character_id="velvetwing";game.level=5
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,22)
 check(is_equal_approx(combat.effect_time("p:solo","silk_guard"),2.5) and is_equal_approx(combat.reduction("solo"),.15),"Soft Landing protection lasts 2.5 seconds")
 combat.melee_received("solo",combat.npc_key(one));var hp:float=one.hp
 for n in 6:combat.tick_statuses(.5)
 check(is_equal_approx(hp-float(one.hp),12),"melee retaliation poisons for six half-second ticks")
 combat.setup("practice");game.enemies.clear();game.level=6;game.adventure.spawn("bramble",Vector2(1360,600),500,false);foe=game.enemies[-1];combat.cast("solo",game.hero.special,Vector2.RIGHT,18)
 var entry:Dictionary=combat.v58.looms[0]
 check(combat.v58.wing(entry,1,1.2).is_equal_approx(combat.v58.wing(entry,-1,2)),"loom wings meet and linger at endpoint")
 check(combat.v58.wing(entry,1,3.4).is_equal_approx(game.position_in_world),"loom returns to hero")
 for n in 70:combat.v58.step(.05)
 check(foe.hp<500 and foe.hp>=440 and combat.v58.looms.is_empty(),"loom pause/return damage is bounded and expires")
 combat.setup("practice");game.hero=game.characters.cloudloom;game.selected_character="cloudloom";game.character_id="cloudloom";game.level=5
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,7)
 for n in 3:check(combat.v56.catch_shot(Vector2(1120,500),Vector2(1120,620),"enemy",40,"#fff"),"charged lane catches shot "+str(n))
 check(not combat.v56.catch_shot(Vector2(1120,500),Vector2(1120,620),"enemy",40,"#fff"),"charged lane is capped at three catches")
 check(combat.projectiles.size()==3,"three catches create three returning sparks")
 check(not combat.v56.catch_shot(Vector2(1120,500),Vector2(1120,620),"solo",40,"#fff"),"friendly shots are not captured")
 combat.setup("practice");game.hero=game.characters.kage;game.selected_character="kage";game.character_id="kage";game.enemies.clear();game.adventure.spawn("bramble",Vector2(1200,600),500,false);foe=game.enemies[-1];combat.cast("solo",game.hero.secondary,Vector2.RIGHT,24)
 for n in 160:combat.ninja.step(.02)
 check(foe.hp<=476 and combat.ninja.wheels.is_empty(),"optimized returning star still hits and ends")
 var serial:Dictionary=JSON.parse_string(JSON.stringify(combat.snapshot()));combat.receive(serial);check(serial.has("v58") and serial.has("v56"),"new phases serialize for guests")
 print("V67 combat: ",failures," failures");game.queue_free();await process_frame;quit(1 if failures else 0)
