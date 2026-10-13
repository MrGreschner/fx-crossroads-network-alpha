extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func foe(uid:int,p:Vector2)->Dictionary:return {"uid":uid,"pos":p,"hp":1000.0,"max_hp":1000.0,"boss":false,"type":"bramble","attack_timer":99.0}
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false)
 g.enter_region("practice");g.adventure.immersive.active=false;g.adventure.expansion.active=false;g.obstacles.clear();g.scenery_tiles.clear();g.practice=true;g.level=10;g.position_in_world=Vector2(1000,1000);g.health=160;g.menu="";g.legacy.data=g.legacy.defaults()
 var c=g.adventure.combat;var kit=c.v79
 for id in ["snail","kite"]:
  check(g.characters.has(id),id+" registry")
  for pose in ["idle","walk1","walk2","attack"]:check(g.art.has(id+"_"+pose),id+" "+pose)
 g.character_id="snail";g.selected_character="snail";g.hero=g.characters.snail
 check(float(g.hero.speed)==75 and kit.dodge_factor("solo")==.28,"snail crawl and reduced dodge")
 g.enemies.assign([foe(1,Vector2(1080,1000)),foe(2,Vector2(1000,1110))]);c.cast("solo",g.hero.primary,Vector2.RIGHT,54)
 check(g.enemies[0].hp==946 and g.enemies[1].hp==1000,"narrow high damage lava breath")
 check(c.effect_time("e:1","burn")>0 and kit.pools.size()==2,"breath burn and ground lava")
 g.enemies[0].pos=Vector2(1080,1000);kit.pool("solo",Vector2(1080,1000),80,5);var hp:float=g.enemies[0].hp;kit.step(.5)
 check(g.enemies[0].hp==hp-4,"overlapping lava does not multiply tick damage")
 kit.reset();c.statuses.clear();g.enemies.assign([foe(1,Vector2(1420,1000))]);kit.prepare("solo",g.hero.secondary,Vector2.RIGHT,Vector2(1420,1000));c.cast("solo",g.hero.secondary,Vector2.RIGHT,32)
 check(kit.moving("solo") and c.busy("solo") and c.speed_factor("p:solo")==0,"lob locks normal movement and attacks")
 kit.step(.4);check(g.position_in_world.x>1000 and g.position_in_world.x<1420 and kit.visual_offset("solo").y<-100,"lob has travel and high visible arc")
 var old:float=g.health;g.invulnerable_time=0;g.take_player_damage(10);check(g.health<old,"snail flight remains vulnerable")
 kit.step(.4);check(g.position_in_world==Vector2(1420,1000) and not kit.moving("solo"),"lob lands at aimed position")
 check(g.enemies[0].hp==968 and kit.pools.size()==1,"landing damage and lava")
 kit.reset();g.enemies.clear();c.cast("solo",g.hero.special,Vector2.RIGHT,12)
 for n in 60:kit.step(.1)
 check(kit.effects.filter(func(e):return e.style=="back_volcano").is_empty(),"volcano ends after six seconds")
 check(kit.pools.size()<=16 and kit.pools.size()>0,"volcano patch count bounded")
 for n in 60:kit.step(.1)
 check(kit.pools.is_empty() and kit.effects.is_empty(),"volcano projectiles and lava expire")
 kit.reset();g.position_in_world=Vector2(1000,1000);g.enemies.assign([foe(1,Vector2(1120,1000))]);var alt:Dictionary=g.hero.mastery.final_technique.attack;c.cast("solo",alt,Vector2.RIGHT,60);kit.step(.8)
 check(g.enemies[0].hp==940,"caldera hits once despite overlapping patches")
 kit.reset();g.character_id="kite";g.selected_character="kite";g.hero=g.characters.kite
 var first:Vector2=kit.displacement("solo",Vector2.RIGHT,280,.1);var second:Vector2=kit.displacement("solo",Vector2.RIGHT,280,.1)
 check(second.x>first.x and second.x<28,"glide builds momentum")
 var brake:Vector2=kit.displacement("solo",Vector2.ZERO,280,.05);check(brake.x>0,"glider banks instead of instant stop")
 kit.observed.solo={"pos":[1000,1000],"speed":280.0};c.cast("solo",g.hero.primary,Vector2.RIGHT,18);check(kit.darts[0].damage==30,"momentum powers needles")
 kit.reset();g.enemies.assign([foe(1,Vector2(1180,945))]);kit.prepare("solo",g.hero.secondary,Vector2.RIGHT,Vector2(1360,1000));c.cast("solo",g.hero.secondary,Vector2.RIGHT,28);kit.step(.425)
 check(g.position_in_world.y<960,"windlass follows curved path")
 check(g.enemies[0].hp==972,"windlass contact damage")
 kit.step(.425);check(g.position_in_world.distance_to(Vector2(1360,1000))<1 and c.reduction("solo")>=.15,"swing lands and passive protects")
 kit.reset();g.enemies.clear();kit.prepare("solo",g.hero.special,Vector2.RIGHT,Vector2(1500,1000));c.cast("solo",g.hero.special,Vector2.RIGHT,42)
 for n in 18:kit.step(.1)
 check(kit.pools.filter(func(e):return e.wind).size()==3,"cargo leaves three wind pads")
 g.position_in_world=c.vec(kit.pools[0].pos);kit.step(.5);check(c.effect_time("p:solo","tailwind")>0,"friendly wind pad grants speed")
 for id in ["snail","kite"]:
  g.character_id=id;g.selected_character=id;g.hero=g.characters[id];g.legacy.data.teacher=true;var rec=g.legacy.record(id);rec.technique=true;rec.final_technique=true
  var a:String=g.hero.mastery.technique.ability;var b:String=g.hero.mastery.final_technique.ability
  check(a!=b,"distinct mastery buttons "+id);check(c.effective_stats("solo",a,g.hero[a])!=g.hero[a],"first technique works "+id);check(c.effective_stats("solo",b,g.hero[b]).style!=g.hero[b].style,"final technique works "+id)
 # Gopher visible paths are also the exact cave-in paths and slow only hostiles.
 c.v78.reset();g.character_id="gopher";g.selected_character="gopher";g.hero=g.characters.gopher;g.enemies.assign([foe(1,Vector2(1050,1000))]);c.v78.tunnels.solo=[[[1000,1000],[1100,1000]]];c.v78.step(.2)
 check(c.effect_time("e:1","slow")>0,"digging trail slows enemies")
 check(float(g.hero.secondary.range)==560,"pounce range doubled")
 var slowest:=INF;var fastest:=0.0
 for n in 130:
  var distance:float=c.v78.distance_clock(n*.01+.01)-c.v78.distance_clock(n*.01);slowest=minf(slowest,distance/.01);fastest=maxf(fastest,distance/.01)
 check(slowest>.79 and fastest<1.21,"digging speed smooth without fast slide")
 print("v79 hero failures: ",failures);g.queue_free();await process_frame;await create_timer(.2).timeout;quit(failures)
