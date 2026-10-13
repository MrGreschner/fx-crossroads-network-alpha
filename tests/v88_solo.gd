extends SceneTree
var failures:=0
func check(ok:bool,name:String)->void:
 if not ok:failures+=1;print("FAIL: ",name)
func _initialize()->void:call_deferred("run")
func choose(g:Node,id:String)->void:
 g.character_id=id;g.selected_character=id;g.hero=g.characters[id];g.health=g.max_health();g.level=10;g.cooldowns={"primary":0.0,"secondary":0.0,"special":0.0};g.enemies.clear();g.adventure.combat.setup("practice");g.position_in_world=Vector2(1000,1000);g.test_target=Vector2(1200,1000)
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();g.set_script(load("res://tests/v82_input_game.gd"));root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false);g.presentation.asked=true;g.session_menu.resume();g.legacy.data=g.legacy.defaults();g.inventory.clear()
 g.enter_region("practice");g.menu="";g.obstacles.clear();g.scenery_tiles.clear();g.invulnerable_time=0
 var c=g.adventure.combat;var p=c.party_heroes
 check(g.characters.size()>=65,"solo roster65")
 choose(g,"lumen");g.adventure.spawn("bramble",Vector2(1100,1000),500,false);g.fire("primary");for n in 12:c.step(.03)
 check(g.enemies[0].hp<500,"solo hostile dart dispatch")
 g.health=60;g.test_target=g.position_in_world;g.pulse();for n in 30:c.step(.1)
 check(g.health==78,"solo relay heals self18")
 choose(g,"harbor");g.test_target=g.position_in_world;g.health=60;g.fire("secondary");for n in 40:c.step(.1)
 check(g.health==76,"buoy heals16 over4s")
 p.reset();c.statuses.clear();var sanctuary:Dictionary=g.characters.lumen.mastery.final_technique.attack;c.v79.prepare("solo",sanctuary,Vector2.RIGHT,g.position_in_world);p.cast("solo",sanctuary,Vector2.RIGHT,0);c.apply_status("p:solo","poison",5,"enemy",2);p.step(1)
 check(c.effect_time("p:solo","poison")==0 and c.reduction("solo")>=.2,"sanctuary cleanses and wards")
 choose(g,"mosaic");g.fire("primary");g.cooldowns.primary=0;g.fire("primary");g.adventure.spawn("bramble",Vector2(1300,1000),500,false);p.step(2.2)
 check(p.family_units("solo","mosaic").size()==2,"nearby foes prevent merging")
 var unit:String=str(p.family_units("solo","mosaic")[0]);p.cast("solo",g.hero.mastery.technique.attack,Vector2.RIGHT,0);c.morrow.hurt(unit,10,"enemy");check(c.morrow.units[unit].hp==25,"protective pattern reduces companion damage30percent")
 g.enemies.clear();p.step(2.1);check(p.family_units("solo","mosaic").size()==1,"quiet merges after combat")
 var fused:String=str(p.family_units("solo","mosaic")[0]);c.morrow.step(14.1);check(not c.morrow.units.has(fused),"merged summon still expires")
 for n in 3:p.cast("solo",g.hero.primary,Vector2.RIGHT,7)
 c.v79.prepare("solo",g.hero.mastery.final_technique.attack,Vector2.RIGHT,Vector2(1100,1000));p.cast("solo",g.hero.mastery.final_technique.attack,Vector2.RIGHT,15);g.adventure.spawn("bramble",Vector2(1100,1000),500,false)
 for n in 50:c.step(.05)
 check(c.morrow.units.is_empty() and g.enemies[0].hp<500,"parade consumes tiles with delayed explosions")
 choose(g,"apiary");g.fire("secondary");check(p.family_units("solo","apiary").size()==2,"solo hive dispatch")
 g.health=0;c.morrow.step(.1);check(c.morrow.units.is_empty(),"companions disappear after owner death")
 choose(g,"bailiff");g.adventure.spawn("bramble",Vector2(1200,1000),500,false);g.fire("secondary");p.step(.1);check(c.effect_time(c.npc_key(g.enemies[0]),"slow")>0,"traffic field slows")
 for id in ["lumen","harbor","mosaic","apiary","bailiff"]:
  choose(g,id)
  if id in ["mosaic","apiary"]:p.cast("solo",g.hero.primary if id=="mosaic" else g.hero.secondary,Vector2.RIGHT,7)
  for key in ["technique","final_technique"]:
   var a:Dictionary=g.hero.mastery[key].attack;c.v79.prepare("solo",a,Vector2.RIGHT,g.position_in_world);check(p.cast("solo",a,Vector2.RIGHT,float(a.damage)),"mastery dispatch "+id+key)
   for n in 12:c.step(.1)
 g.queue_free();await process_frame;print("v88 solo failures: ",failures);quit(failures)
