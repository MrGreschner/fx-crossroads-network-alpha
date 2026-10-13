extends SceneTree
var failures:=0
func check(ok:bool,message:String)->void:
 if not ok:failures+=1;print("FAIL: ",message)
func _initialize()->void:call_deferred("run")
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume();g.enter_region("practice");g.menu="";g.level=10;g.character_id="wick";g.selected_character="wick";g.hero=g.characters.wick;g.health=50
 var kit=g.adventure.combat.v98
 check(kit.candle("solo"),"candle active in training gameplay")
 g.mode="town";check(not kit.candle("solo") and kit.heal_factor("solo")==1 and kit.crit_multiplier("solo")==1,"town has neither gameplay aura nor aura bonuses")
 g.mode="run";g.character_id="cobbleclaw";g.hero=g.characters.cobbleclaw
 kit.cast("solo",g.hero.secondary,Vector2.RIGHT,0);check(is_equal_approx(float(kit.shells.solo.guard),3.5),"brace starts at 3.5 seconds")
 kit.step(3);check(kit.catch_shot(g.position_in_world-Vector2(40,0),g.position_in_world,"enemy"),"brace still catches after three seconds")
 kit.step(.51);check(not kit.catch_shot(g.position_in_world-Vector2(40,0),g.position_in_world,"enemy"),"catch window ends after 3.5 seconds")
 for pose in ["idle","walk1","walk2","attack","spin"]:
  var image:Image=load("res://assets/cat_"+pose+".png").get_image();check(image.get_size()==Vector2i(28,32),"cat retains original footprint "+pose)
  check(image.get_pixel(7,4).a>0 and image.get_pixel(22,4).a>0,"ears attach above face "+pose)
 var motion=preload("res://scripts/hero_motion_v85.gd").new()
 for id in ["wick","snail","morrow","velvetwing","vesper","sunflower","iris","teapot"]:
  motion.sample(id,id,Vector2.ZERO,true);motion.sample(id,id,Vector2(30,0),true)
  check(motion.footprints.any(func(e):return e.hero==id),"moving trace exists "+id)
 motion.sample("bees","apiary",Vector2.ZERO,true);motion.sample("bees","apiary",Vector2.ZERO,true);check(motion.tracks.has("bees"),"idle bees maintain tracked hero without particle allocation")
 motion.sample("fish","ripplejaw",Vector2.ZERO,true);motion.landing("fish",Vector2.ZERO,.8);motion.sample("fish","ripplejaw",Vector2(15,0),true);motion.landing("fish",Vector2(15,0),.05)
 var puddles:int=motion.footprints.filter(func(e):return e.hero=="ripplejaw").size();check(puddles==1,"one puddle per completed flop")
 motion.landing("fish",Vector2(15,0),0);check(motion.footprints.filter(func(e):return e.hero=="ripplejaw").size()==puddles,"idle fish does not manufacture puddles")
 for n in 150:motion.sample("trail","snail",Vector2(n*30,0),true)
 check(motion.footprints.size()==96,"all trails share existing 96 cap")
 motion.sample("bees","apiary",Vector2.ZERO,false);check(not motion.tracks.has("bees"),"hidden/dead cosmetics stop")
 for n in 25:motion.advance(.1)
 check(motion.footprints.is_empty() and motion.tracks.is_empty(),"trails and stale actor tracks expire")
 g.queue_free();await process_frame;await process_frame
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false);a.presentation.set_process(false);a.legacy.set_process(false);a._set_mode("arena");a.bot_count=1;a._solo();a.hero_ids[a.my_id]="wick";a.levels[a.my_id]=10;check(a.adventure.combat.v98.candle(a.my_id),"arena aura is active")
 a.started=false;check(not a.adventure.combat.v98.candle(a.my_id),"arena lobby has no aura")
 a.queue_free();await process_frame;await process_frame;print("v99 polish failures: ",failures);quit(failures)
