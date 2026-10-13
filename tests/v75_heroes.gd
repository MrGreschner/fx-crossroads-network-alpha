extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func foe(uid:int,pos:Vector2)->Dictionary:return {"uid":uid,"pos":pos,"hp":1000.0,"max_hp":1000.0,"boss":false,"type":"bramble","attack_timer":99.0}
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false)
 g.enter_region("practice");g.adventure.immersive.active=false;g.adventure.expansion.active=false;g.obstacles.clear();g.scenery_tiles.clear();g.practice=true;g.level=10;g.position_in_world=Vector2(1000,1000);g.health=100;g.menu="";g.legacy.data=g.legacy.defaults()
 var c=g.adventure.combat;var kit=c.v75
 for id in ["ripplejaw","hearthwarden"]:
  check(g.characters.has(id),id+" in registry")
  for pose in ["idle","walk1","walk2","attack"]:check(g.art.has(id+"_"+pose),id+" "+pose+" texture")
 g.character_id="ripplejaw";g.selected_character="ripplejaw";g.hero=g.characters.ripplejaw
 g.enemies.assign([foe(1,Vector2(1120,1000)),foe(2,Vector2(1200,1000))])
 c.cast("solo",g.hero.primary,Vector2.RIGHT,21);kit.step(.26)
 check(is_equal_approx(g.enemies[0].hp,979) and g.enemies[1].hp==1000,"water stream three pulses, no piercing")
 kit.reset();c.cast("solo",g.hero.secondary,Vector2.RIGHT,26)
 check(kit.effects.filter(func(e):return e.style=="puddle").size()==3,"three puddles")
 var puddle:Vector2=c.vec(kit.effects.filter(func(e):return e.style=="puddle")[0].pos)
 g.enemies[0].pos=puddle;kit.step(.1);check(c.effect_time("e:1","slow")>0,"puddle slow")
 c.cast("solo",g.hero.secondary,Vector2.RIGHT,26);check(kit.effects.filter(func(e):return e.style=="puddle").size()==3,"puddles replace previous cast")
 kit.reset();g.enemies.assign([foe(1,Vector2(1200,1000)),foe(2,Vector2(1220,1000))])
 c.cast("solo",g.hero.special,Vector2.RIGHT,72)
 check(kit.effects[0].target=="e:2","aimed maw target")
 g.enemies[1].pos+=Vector2(80,0);kit.step(.5);var followed:Vector2=c.vec(kit.effects[0].pos)
 check(followed.x>1220 and followed.x<1300,"shadow follows slowly")
 kit.step(1.1);var locked:Vector2=c.vec(kit.effects[0].pos);g.enemies[1].pos=locked;g.enemies[0].pos=locked+Vector2(30,0)
 kit.step(.4);check(g.enemies[0].hp==928 and c.effect_time("e:1","stun")>0,"bite damage and stun")
 check(g.enemies[0].pos.distance_to(locked)<30,"bite pulls inward")
 kit.step(.4);check(g.enemies[0].hp==928,"bite only once")
 kit.reset();g.enemies.assign([foe(1,Vector2(1200,1000))])
 var alt:Dictionary=g.hero.mastery.final_technique.attack
 c.cast("solo",alt,Vector2.RIGHT,60)
 for n in 42:kit.step(.1)
 check(is_equal_approx(g.enemies[0].hp,940),"whirlpool exactly six ticks")
 kit.reset();c.projectiles.clear()
 check(not kit.catch_shot(Vector2(980,1000),Vector2(1020,1000),"enemy",20,"#eee"),"first shot passes")
 check(not kit.catch_shot(Vector2(980,1000),Vector2(1020,1000),"enemy",20,"#eee"),"second shot passes")
 check(kit.catch_shot(Vector2(980,1000),Vector2(1020,1000),"enemy",20,"#eee"),"third shot reflected")
 check(c.projectiles.size()==1 and c.projectiles[0].owner=="solo" and c.projectiles[0].damage==16,"real reflected projectile")
 g.level=4;check(not kit.catch_shot(Vector2(980,1000),Vector2(1020,1000),"enemy",20,"#eee"),"scales locked before passive level");g.level=10
 kit.reset();c.statuses.clear();g.character_id="hearthwarden";g.selected_character="hearthwarden";g.hero=g.characters.hearthwarden;g.enemies.assign([foe(1,Vector2(1060,1000))])
 for n in 3:c.cast("solo",g.hero.primary,Vector2.RIGHT,22)
 check(g.enemies[0].hp==923,"third swing boosted")
 check(c.reduction("solo")>=.15,"combo passive armor")
 kit.reset();c.cast("solo",g.hero.secondary,Vector2.RIGHT,0);g.position_in_world=Vector2(1120,1000);kit.step(.1)
 check(c.reduction("solo")>=.18,"rally protection")
 kit.reset();g.position_in_world=Vector2(1000,1000);g.enemies.assign([foe(1,Vector2(1100,1000))])
 c.cast("solo",g.hero.special,Vector2.RIGHT,50);kit.step(.5);check(g.enemies[0].hp==950,"marching wall hits")
 kit.step(.3);check(g.enemies[0].hp==950,"march only once per foe")
 var wall:Vector2=c.vec(kit.effects[0].pos)
 for n in 6:check(kit.catch_shot(wall+Vector2(30,0),wall-Vector2(30,0),"enemy",10,"#fff"),"wall catches shot "+str(n))
 check(not kit.catch_shot(wall+Vector2(30,0),wall-Vector2(30,0),"enemy",10,"#fff"),"wall catch cap")
 var copy=load("res://scripts/v75_heroes.gd").new();copy.combat=c;copy.receive(JSON.parse_string(JSON.stringify(kit.snapshot())));check(copy.effects.size()==kit.effects.size(),"guest snapshot");copy.free()
 for id in ["ripplejaw","hearthwarden"]:
  g.character_id=id;g.hero=g.characters[id];g.legacy.data.teacher=true;var rec=g.legacy.record(id);rec.technique=true;rec.final_technique=true
  var first:String=g.hero.mastery.technique.ability;var last:String=g.hero.mastery.final_technique.ability
  check(first!=last,"separate mastery buttons "+id)
  check(c.effective_stats("solo",first,g.hero[first])!=g.hero[first],"technique applied "+id)
  check(c.effective_stats("solo",last,g.hero[last]).style!=g.hero[last].style,"final mechanic applied "+id)
 var motion=load("res://scripts/fish_motion.gd").new();motion.step("f",Vector2.ZERO,.1,true);motion.step("f",Vector2(10,0),.1,true);check(absf(motion.angle("f"))>.1,"fish flops");motion.step("f",Vector2(500,0),.1,true);check(motion.phase("f")==0,"teleport resets gait")
 print("v75 heroes failures: ",failures);g.queue_free();await process_frame;await create_timer(.2).timeout;quit(failures)
