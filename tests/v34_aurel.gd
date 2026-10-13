extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: "+label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.selected_character="aurel";game.start_run(false,"honeyglass");game.obstacles.clear();game.build_scenery();game.position_in_world=Vector2(2000,1800);game.enemies.clear();game.level=6
 check(game.characters.size()>=24 and game.art.has("aurel_attack"),"24 heroes and dragon art")
 var combat=game.adventure.combat;combat.cast("solo",game.hero.special,Vector2.RIGHT,24)
 check(combat.casts.size()==7 and combat.visuals[-1].points.size()==7,"seven telegraphed constellation meteors")
 check(combat.casts[0].stats.blast_radius==77,"afterglow passive")
 game.adventure.spawn("bramble",Vector2(2230,1800),500,false)
 game.adventure.step(.41);check(game.adventure.lob_shots.size()==1,"first falling meteor")
 game.adventure.step(.4);check(game.enemies[0].hp<500,"meteor impacts for damage")
 var packet:Dictionary=game.adventure.snapshot();check(packet.combat.has("casts") and packet.has("lob_shots"),"shared snapshot includes meteor cast and flight")
 combat.setup("honeyglass");game.position_in_world=Vector2(40,40);combat.cast("solo",game.hero.special,Vector2.LEFT,24)
 for cast in combat.casts:check(Rect2(30,30,6140,3040).has_point(combat.vec(cast.pos)),"meteor remains within realm")
 for voice in game.journey.voices:voice.stop()
 game.queue_free();await process_frame
 var party=load("res://scenes/arcade.tscn").instantiate();root.add_child(party);await process_frame;party.set_process(false);party.selected_hero="aurel";party._set_mode("descent");party._solo();party.field_obstacles.clear();party._rebuild_grid();party.positions.solo=Vector2(1000,850);party.levels.solo=6
 party._attack("solo","special",Vector2.RIGHT,Vector2(1230,850))
 check(party.adventure.combat.casts.size()==7 and party.adventure.combat.casts[0].owner=="solo","host meteor owner")
 for voice in party.journey.voices:voice.stop()
 party.queue_free();await create_timer(.2).timeout
 print("V34 FAILURES: "+str(failures));quit(failures)
