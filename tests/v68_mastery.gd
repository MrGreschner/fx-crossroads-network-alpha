extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func foe(uid:int,pos:Vector2)->Dictionary:return {"uid":uid,"pos":pos,"hp":1000.0,"max_hp":1000.0,"boss":false,"type":"bramble","attack_timer":99.0}
func run()->void:
 var game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame;game.set_process(false);game.legacy.set_process(false)
 var legacy=game.legacy;var combat=game.adventure.combat;legacy.data=legacy.defaults();game.journey.data.skipped=true;game.enter_region("practice");game.adventure.immersive.active=false;game.adventure.expansion.active=false;game.obstacles.clear();game.scenery_tiles.clear();game.practice=true;game.level=10;game.position_in_world=Vector2(1000,1000);game.health=50
 for id in game.manifest.characters:
  game.character_id=str(id);game.selected_character=str(id);game.hero=game.characters[id];combat.setup("practice")
  var spec:Dictionary=game.characters[id].mastery;var rec:Dictionary=legacy.record(str(id));var final:Dictionary=spec.final_technique
  check(final.ability!=spec.technique.ability,str(id)+" alternate uses a different button")
  check(combat.mastery_combat.visual_texture(str(final.attack.visual_texture))!=null,str(id)+" custom final spell artwork loads")
  check(final.attack.style!=game.hero[final.ability].style,str(id)+" alternate has a different mechanic")
  rec.final_technique=true
  check(not legacy.payload(str(id)).final_technique,str(id)+" locked alternate cannot apply")
  rec.clears=11;rec.realms=["grove","ember","sunfield","silverfall","marsh","astral"];rec.damage=60000
  check(not legacy.final_eligible(str(id)),str(id)+" 11 clears is not enough")
  rec.clears=12;check(legacy.final_eligible(str(id)),str(id)+" final unlock requirements met")
  var original:Dictionary=game.hero[final.ability].duplicate(true);var stats:Dictionary=legacy.stats("solo",str(final.ability),original)
  check(stats.style==final.attack.style and game.hero[final.ability]==original,str(id)+" actual ability replaced without changing original")
  rec.technique=true
  check(legacy.stats("solo",str(spec.technique.ability),game.hero[spec.technique.ability])!=game.hero[spec.technique.ability],str(id)+" first technique works alongside final")
  game.enemies.assign([foe(4,game.position_in_world+Vector2(float(stats.get("range",250)),0)),foe(1,game.position_in_world+Vector2(100,0)),foe(2,game.position_in_world+Vector2(220,0)),foe(3,game.position_in_world+Vector2(300,50))])
  check(combat.cast("solo",stats,Vector2.RIGHT,float(stats.damage)),str(id)+" alternate accepted by combat")
  check(combat.mastery_combat.effects.size()+combat.v75.effects.size()==1,str(id)+" creates bounded visual effect")
  var packet:Variant=JSON.parse_string(JSON.stringify(combat.snapshot()));check(packet is Dictionary,str(id)+" effect snapshot serializes")
  for n in 100:combat.step(.05)
  check(combat.mastery_combat.effects.is_empty() and combat.v75.effects.is_empty(),str(id)+" effect expires")
  check(game.enemies.any(func(e:Dictionary)->bool:return float(e.hp)<1000),str(id)+" alternate damages reachable enemies")
  rec.clears=0;check(legacy.crit_tier(str(id))==0,str(id)+" crit starts locked")
  for tier in range(1,4):
   rec.clears=tier*3
   check(legacy.crit_tier(str(id))==tier,str(id)+" crit milestone "+str(tier))
   check(is_equal_approx(legacy.critical("solo",100,Vector2.ZERO,0),100*(1+tier*.2)),str(id)+" crit bonus "+str(tier))
   check(is_equal_approx(legacy.critical("solo",100,Vector2.ZERO,.99),100),str(id)+" noncritical damage unchanged")
  check(is_equal_approx(legacy.critical("enemy",100,Vector2.ZERO,0),100),"enemy does not inherit mastery crit")
 legacy.data=legacy.defaults();legacy.data.heroes.ram={"clears":6,"damage":20000,"realms":["grove","ember","silverfall"],"points":3,"technique":true,"tuning":[1,1,1]}
 check(not legacy.record("ram").final_technique and legacy.crit_tier("ram")==2,"old profiles migrate with original progress and no final equipped")
 var old:Dictionary=legacy.bundle();check(legacy.validate(old),"old/new export shape validates")
 legacy.record("ram").final_technique=true
 var upgraded:Dictionary=JSON.parse_string(JSON.stringify(legacy.bundle()))
 check(legacy.validate(upgraded) and upgraded.progress.heroes.ram.final_technique,"final equipped choice survives portable JSON round-trip")
 check(legacy.sanitize_build({"crit_tier":99,"final_technique":true,"points":99,"tuning":[99,99,99]}).crit_tier==3,"remote crit tier clamped")
 legacy.data.teacher=true;check(legacy.final_eligible("ram") and legacy.crit_tier("ram")==3,"teacher bypass unlocks new progression")
 # Focused burn/slow/stun and healing checks without mastery crit randomness.
 legacy.data=legacy.defaults();game.character_id="medic";game.hero=game.characters.medic;game.health=50;combat.setup("practice");game.enemies.assign([foe(77,game.position_in_world+Vector2(180,0))])
 var fountain:Dictionary=game.hero.mastery.final_technique.attack;combat.cast("solo",fountain,Vector2.RIGHT,float(fountain.damage));game.position_in_world+=Vector2(180,0)
 for n in 60:combat.step(.05)
 check(is_equal_approx(game.health,68),"healing garden grants exactly 18 HP over three seconds")
 check(combat.effect_time("e:77","poison")>0,"garden poison applies")
 game.character_id="ram";game.hero=game.characters.ram;game.position_in_world=Vector2(1000,1000);combat.setup("practice");game.enemies.assign([foe(78,Vector2(1120,1000))])
 combat.cast("solo",game.hero.mastery.final_technique.attack,Vector2.RIGHT,70)
 for n in 15:combat.step(.05)
 check(combat.effect_time("e:78","stun")>0,"faultline stun applies")
 # Obstructed hits do not pass walls.
 combat.setup("practice");game.obstacles.assign([{"pos":Vector2(1100,1000),"radius":45,"kind":"rock"}]);game.enemies.assign([foe(79,Vector2(1200,1000))])
 combat.cast("solo",game.hero.mastery.final_technique.attack,Vector2.RIGHT,70)
 for n in 30:combat.step(.05)
 check(is_equal_approx(float(game.enemies[0].hp),1000),"charged lance respects blocked path")
 game.obstacles.clear();legacy.data=legacy.defaults();game.mode="town";game.menu="";legacy.open_hero("book");check(legacy.root.visible,"scrollable mastery renders new locked options")
 legacy.close()
 var arcade=load("res://scenes/arcade.tscn").instantiate();root.add_child(arcade);await process_frame;arcade.set_process(false);arcade.role="host";arcade.my_id="host";arcade._add_player("host",0);arcade._add_player("guest",1);arcade.hero_ids.guest="book";arcade.legacy.data=arcade.legacy.defaults();arcade.legacy.builds.guest=arcade.legacy.sanitize_build({"technique":true,"final_technique":true,"crit_tier":2,"tuning":[0,0,0]})
 var remote:Dictionary=arcade.adventure.combat.effective_stats("guest","primary",arcade.characters.book.primary)
 check(remote.style=="master_pincer","host uses guest final primary")
 check(arcade.adventure.combat.effective_stats("guest","secondary",arcade.characters.book.secondary).channel_move==.3,"host keeps guest first technique")
 var snap:Dictionary=arcade._snapshot();check(snap.players.guest.build.final_technique and snap.players.guest.build.crit_tier==2,"new build fields travel in snapshot")
 print("V68 mastery: ",failures," failures")
 arcade.queue_free();game.queue_free();await process_frame;quit(1 if failures else 0)
