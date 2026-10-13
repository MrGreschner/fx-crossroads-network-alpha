extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.selected_character="bracken";game.start_run(false,"honeyglass");game.obstacles.clear();game.build_scenery();game.position_in_world=Vector2(2000,1500);game.enemies.clear()
 var combat=game.adventure.combat;var variants=combat.variants
 combat.cast("solo",game.hero.special,Vector2.RIGHT,62)
 check(game.position_in_world==Vector2(2280,1500) and variants.bombs.size()==1 and variants.bombs[0].pos==[2000.0,1500.0],"blink leaves bomb at original spot")
 game.adventure.spawn("bramble",Vector2(2000,1500),500,false);combat.step(.9);check(game.enemies[0].hp==500,"bomb fuse telegraph")
 combat.step(.2);check(game.enemies[0].hp==438,"bomb damage after fuse")
 game.obstacles.append({"pos":Vector2(2400,1500),"radius":40.0,"kind":"rock"});game.build_scenery();combat.cast("solo",game.hero.special,Vector2.RIGHT,62)
 check(game.position_in_world.x<2360,"blink stops before rock")
 game.hero=game.characters.elara;game.level=5;game.position_in_world=Vector2(2000,1800);game.obstacles.clear();game.build_scenery();combat.setup("honeyglass");combat.cast("solo",game.hero.secondary,Vector2.RIGHT,14)
 check(variants.spirals.size()==1 and variants.spirals[0].radius==310,"outward shards and passive")
 variants.step(.5);check(variants.spirals[0].elapsed==.5,"spirals expand over time")
 game.enemies.clear();game.adventure.spawn("bramble",game.position_in_world+Vector2.from_angle(2.4)*(25+285*.6/2),500,false);variants.step(.1)
 check(game.enemies[0].hp==486,"outward shard hits")
 game.enemies[0].pos=game.position_in_world+Vector2.from_angle(2.8)*(25+285*.7/2);variants.step(.1);check(game.enemies[0].hp==486,"same shard does not hit twice")
 game.hero=game.characters.aurel;game.level=1;combat.setup("honeyglass");game.enemies.clear();game.adventure.spawn("bramble",game.position_in_world+Vector2(100,0),500,false)
 combat.cast("solo",game.hero.primary,Vector2.RIGHT,4)
 # Use the live aim toward the test foe, as gameplay does.
 variants.breaths[0].aim=[game.aim_direction().x,game.aim_direction().y];game.enemies[0].pos=game.position_in_world+game.aim_direction()*100
 variants.step(.4);check(game.enemies[0].hp==484,"four level-one breath ticks")
 check(combat.effect_time(combat.npc_key(game.enemies[0]),"burn")==3,"breath applies refreshing burn")
 game.hero=game.characters.rune_duelist;combat.setup("honeyglass");game.enemies.clear();game.position_in_world=Vector2(2000,1800);game.adventure.spawn("bramble",Vector2(2060,1800),500,false)
 for n in 3:combat.cast("solo",game.hero.primary,Vector2.RIGHT,24)
 check(game.enemies[0].hp==418 and variants.runes.size()==3,"duelist three-cut combo and marks")
 game.position_in_world=Vector2(2250,1800);combat.cast("solo",game.hero.secondary,Vector2.RIGHT,28)
 check(game.position_in_world==Vector2(2000,1800),"runestep returns to mark")
 combat.cast("solo",game.hero.special,Vector2.RIGHT,10);check(variants.domains.size()==1,"special forms rune court")
 game.enemies[0].pos=Vector2(2000,1800);var hp:float=game.enemies[0].hp;variants.step(.5);check(game.enemies[0].hp==hp-10,"court damage ticks")
 check(game.characters.size()>=25 and combat.snapshot().variants.has("bombs"),"25 heroes and network variant state")
 for voice in game.journey.voices:voice.stop()
 game.queue_free();await process_frame
 var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party.selected_hero="aurel";party._set_mode("descent");party._solo();party.field_obstacles.clear();party._rebuild_grid();party.positions.solo=Vector2(1000,850);party.local_pos=party.positions.solo;party.last_aim=Vector2.RIGHT;party.opponents.clear();party.adventure.spawn("bramble",Vector2(1100,850),500,false)
 party._attack("solo","primary",Vector2.RIGHT);party.adventure.combat.variants.step(.4);check(party.opponents[0].hp==484,"multiplayer level-one fire breath")
 party.hero_ids.solo="bracken";party.levels.solo=6;party.cooldown_at.solo.special=0;party._attack("solo","special",Vector2.RIGHT);check(party.adventure.combat.variants.bombs.size()==1 and party.local_pos.x>1000,"host blink and bomb")
 for voice in party.journey.voices:voice.stop()
 party.queue_free();await create_timer(.2).timeout
 print("V36 FAILURES: "+str(failures));quit(failures)
