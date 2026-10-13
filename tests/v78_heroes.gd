extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func foe(uid:int,p:Vector2)->Dictionary:return {"uid":uid,"pos":p,"hp":1000.0,"max_hp":1000.0,"boss":false,"type":"bramble","attack_timer":99.0}
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.legacy.set_process(false)
 g.enter_region("practice");g.adventure.immersive.active=false;g.adventure.expansion.active=false;g.obstacles.clear();g.scenery_tiles.clear();g.practice=true;g.level=10;g.position_in_world=Vector2(1000,1000);g.health=100;g.menu="";g.legacy.data=g.legacy.defaults()
 var c=g.adventure.combat;var kit=c.v78
 for id in ["gopher","nullweaver"]:
  check(g.characters.has(id),id+" registry")
  for pose in ["idle","walk1","walk2","attack"]:check(g.art.has(id+"_"+pose),id+" "+pose)
 g.character_id="gopher";g.selected_character="gopher";g.hero=g.characters.gopher
 g.enemies.assign([foe(1,Vector2(1060,1000))]);c.cast("solo",g.hero.primary,Vector2.RIGHT,25)
 check(g.enemies[0].hp==975,"close claw damage")
 check(c.speed_factor("p:solo")==0 and kit.locked("solo"),"attack stops walking")
 var old:float=g.health;g.invulnerable_time=0;g.take_player_damage(10);check(g.health<old,"surfaced attacker vulnerable")
 kit.reset();g.enemies.assign([foe(1,Vector2(1220,1000))]);c.cast("solo",g.hero.secondary,Vector2.RIGHT,35)
 check(kit.immune("solo"),"dive immune")
 old=g.health;g.take_player_damage(10);check(g.health==old,"dive blocks damage")
 kit.step(.6);check(g.position_in_world.x==1195,"pounce lands short of enemy")
 check(g.enemies[0].hp==965 and c.effect_time("e:1","stun")>0,"pounce damage stun")
 kit.reset();g.position_in_world=Vector2(1000,1000);g.enemies.assign([foe(1,Vector2(1050,1000))]);kit.tunnels.solo=[[[1000,1000],[1100,1000]],[[1050,950],[1050,1050]]]
 c.cast("solo",g.hero.special,Vector2.RIGHT,65);kit.step(.6);check(g.enemies[0].hp==1000,"cave warning before damage")
 kit.step(.1);check(g.enemies[0].hp==935,"intersections hit once")
 check(c.effect_time("e:1","slow")>0,"cave slow")
 kit.reset();g.character_id="nullweaver";g.selected_character="nullweaver";g.hero=g.characters.nullweaver;g.enemies.assign([foe(1,Vector2(1140,1140))])
 check(not kit.prepare("solo",g.hero.secondary),"quarter turn requires pins before cooldown")
 c.cast("solo",g.hero.primary,Vector2.RIGHT,18);c.cast("solo",g.hero.primary,Vector2.DOWN,18)
 check(is_equal_approx(g.enemies[0].hp,974.8),"rift link hits enemy between pins")
 check(c.effect_time("e:1","slow")>0,"rift passive slow")
 c.cast("solo",g.hero.secondary,Vector2.RIGHT,42);kit.step(.3);check(g.enemies[0].hp<974.8,"rotating line hits")
 c.cast("solo",g.hero.primary,Vector2.LEFT,18);check(kit.pins.solo.size()==2,"two-pin cap")
 kit.reset();g.enemies.assign([foe(1,Vector2(1261.25,1054.125))]);c.cast("solo",g.hero.special,Vector2.RIGHT,36);kit.step(.6);check(g.enemies[0].hp==1000,"triangle warns before firing");kit.step(.1);check(g.enemies[0].hp<1000,"triangle edge deals damage")
 kit.pins.solo=[[10,10]];c.cast("solo",g.hero.primary,Vector2.RIGHT,18);check(kit.pins.solo.size()==1,"distant pins cannot create unlimited seam")
 var copy=load("res://scripts/v78_heroes.gd").new();copy.combat=c;copy.receive(JSON.parse_string(JSON.stringify(kit.snapshot())));check(copy.effects.size()==kit.effects.size(),"network snapshot roundtrip");copy.free()
 for id in ["gopher","nullweaver"]:
  g.character_id=id;g.selected_character=id;g.hero=g.characters[id];g.legacy.data.teacher=true;var rec=g.legacy.record(id);rec.technique=true;rec.final_technique=true
  var first:String=g.hero.mastery.technique.ability;var last:String=g.hero.mastery.final_technique.ability
  check(first!=last,"separate mastery alternatives "+id)
  check(c.effective_stats("solo",first,g.hero[first])!=g.hero[first],"first technique applied "+id)
  check(c.effective_stats("solo",last,g.hero[last]).style!=g.hero[last].style,"final technique applied "+id)
 # Exact cadence integration conserves average distance at both high and low FPS.
 check(is_equal_approx(kit.distance_clock(kit.PERIOD*10)-kit.distance_clock(0),kit.PERIOD*10),"gopher average speed conserved")
 var town=load("res://scenes/town.tscn").instantiate();check(town.get_node("Landmarks/RamGuardWest").position.x<750 and town.get_node("Landmarks/RamGuardEast").position.x>1050,"gate label clear of guards");town.free()
 print("v78 heroes failures: ",failures);g.queue_free();await process_frame;await create_timer(.2).timeout;quit(failures)
