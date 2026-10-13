extends SceneTree
var failures:int=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false)
 game.selected_character="pippa";game.start_run(false,"petalbrook");game.level=6
 game.adventure.immersive.initialized=true;game.enemies.clear();game.position_in_world=Vector2(2800,3400);game.health=50
 var combat=game.adventure.combat;var fern=combat.fern;var world=game.adventure.immersive
 var close:Dictionary=world.spawn("briar_tail",Vector2(2960,3400));close.hp=500;close.max_hp=500
 var distant:Dictionary=world.spawn("briar_tail",Vector2(3100,3400));distant.hp=500;distant.max_hp=500
 combat.cast("solo",game.hero.secondary,Vector2.RIGHT,24)
 fern.redirect(distant,game.position_in_world);distant.pos=Vector2(3200,3400)
 game.position_in_world=Vector2(2850,3400)
 fern.step(3.0)
 check(close.hp==476 and distant.hp==500,"explosion damages blast area once")
 check(combat.effect_time(combat.npc_key(close),"slow")>0 and combat.effect_time(combat.npc_key(distant),"slow")>0,"nearby and attracted enemies slowed")
 check(fern.decoy_for(close.pos).is_empty(),"healing phase stops attracting")
 check(game.health==50,"healing starts after a full second")
 fern.step(.4);fern.step(.6)
 check(game.health==58,"first heal tick is eight HP")
 var packet:Dictionary=JSON.parse_string(JSON.stringify(fern.snapshot()))
 check(packet.decoys[0].phase=="healing" and packet.decoys[0].ticks==1,"healing phase replicates")
 fern.step(2.0)
 check(game.health==74 and fern.decoys.is_empty(),"three ticks total 24 HP and then end")
 check(combat.effect_time("p:solo","fern_stride")>0,"passive applies to healing")
 game.hero=game.characters.dawnblade;game.position_in_world=Vector2(2900,3400)
 var before:float=close.hp
 combat.cast("solo",game.hero.special,Vector2.RIGHT,48)
 check(close.hp==before-48 and distant.hp==500,"Mara hits only her 115-unit circle")
 check(combat.visuals.any(func(effect):return effect.get("style","")=="dawn_circle" and effect.radius==115),"Mara area marker matches damage range")
 game.hero=game.characters.sunflower;game.position_in_world=Vector2(2800,3400)
 close.pos=Vector2(3100,3400);distant.pos=Vector2(3200,3550);before=close.hp
 check(game.hero.special.damage==120,"Solarbeam configured at 120")
 combat.cast("solo",game.hero.special,Vector2.RIGHT,120)
 combat.step(2.6)
 check(close.hp==before-120,"charged Solarbeam deals 120 damage")
 for voice in game.journey.voices:voice.stop()
 game.queue_free();await create_timer(.3).timeout
 print("v55 abilities: ",failures," failures");quit(1 if failures else 0)
