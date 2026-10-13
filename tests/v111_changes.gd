extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
 if not ok:failures+=1;print("FAIL: ",label)
func _initialize()->void:call_deferred("run")
func tidy(g:Node)->void:
 for player in g.find_children("*","AudioStreamPlayer",true,false):player.stop();player.stream=null
 await create_timer(.1).timeout;g.queue_free();await process_frame;await process_frame
func run()->void:
 root.set_meta("fx_intro_seen",true)
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);await process_frame;a.set_process(false);a.party_tools.set_process(false)
 a.role="host";a.mode="arena";a.started=true;a.start_countdown=0
 for id in ["hero","foe","other","ally","far"]:a._add_player(id,0)
 a.pvp_rule="teams";a.teams={"hero":0,"ally":0,"foe":1,"other":1,"far":1};a.hero_ids.hero="hazel_hex";a.levels.hero=10
 a.positions={"hero":Vector2(700,500),"ally":Vector2(730,500),"foe":Vector2(800,500),"other":Vector2(700,700),"far":Vector2(1500,700)}
 a.adventure.setup("");a.field_obstacles.clear();a._rebuild_grid();a.opponents.clear()
 var c=a.adventure.combat;var h=c.halloween;var v=c.v110
 c.v79.prepare("hero",a.characters.hazel_hex.special,Vector2.RIGHT,Vector2(720,500));h.cast("hero",a.characters.hazel_hex.special,Vector2.RIGHT,8);h.step(.41)
 var shots:Array=h.effects.filter(func(e):return e.kind=="splatter")
 check(shots.size()==2,"cauldron shoots both enemies, excludes allies and out-of-range target")
 check(shots.any(func(e):return c.vec(e.end)==a.positions.foe) and shots.any(func(e):return c.vec(e.end)==a.positions.other),"volley has an individually aimed shot for each enemy")
 var hf:int=a.health.foe;var ho:int=a.health.other;var ha:int=a.health.ally
 h.step(.61);check(a.health.foe<hf and a.health.other<ho and a.health.ally==ha,"both splatters damage foes only")
 h.reset();c.statuses.clear();a.hero_ids.hero="hollow_rider";a.positions.foe=Vector2(770,500);a.positions.other=Vector2(700,590)
 hf=a.health.foe;ho=a.health.other;h.cast("hero",a.characters.hollow_rider.secondary,Vector2.RIGHT,26)
 check(a.health.foe==hf,"lantern slam has clear windup");h.step(.31)
 check(a.health.foe<hf and a.health.other<ho and a.positions.foe.x>770 and c.effect_time("p:other","stun")>=1.2,"lantern shockwave hits multiple foes, pushes and stuns")
 check(c.reduction("hero")>=.12,"new secondary activates Lantern Courage")
 h.reset();c.statuses.clear();a.hero_ids.hero="little_menace";a.health.hero=120;a.health.foe=300;a.positions.foe=Vector2(750,500)
 v.cast("hero",a.characters.little_menace.special,Vector2.RIGHT,0)
 check(a.health.hero==120 and a.health.foe==300 and v.charging("hero") and c.busy("hero"),"sacrifice starts a charge with no instant damage or health cost")
 check(is_equal_approx(c.speed_factor("p:hero"),.35),"charge slows movement to 35 percent")
 v.step(.5);check(a.health.hero==120 and a.health.foe==300,"sacrifice waits through windup")
 v.step(.51);check(a.health.hero==60 and a.health.foe==240 and not v.charging("hero"),"charge releases sacrifice once")
 v.reset();a.health.hero=120;v.cast("hero",a.characters.little_menace.special,Vector2.RIGHT,0);c.apply_status("p:hero","stun",2,"foe");v.step(.1)
 check(not v.charging("hero") and a.health.hero==120,"stun interrupts charge without charging health cost")
 c.statuses.clear();v.reset();v.cast("hero",a.characters.little_menace.mastery.technique.attack,Vector2.RIGHT,0);v.step(1.01)
 check(a.health.hero==30,"mastery sacrifice retains stronger cost after charge")
 await tidy(a)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume();g.journey.last_sound=Time.get_ticks_msec()+1000000
 g.selected_character="ram";g.start_training();g.set_process(false);c=g.adventure.combat
 check(g.adventure.points().has("training_ally") and c.actor("p:training_ally").alive and not c.hostile("solo").has("p:training_ally"),"green target is a live friendly actor, not an enemy")
 var hp:float=g.health;c.release_heroes.heal("solo","training_ally",25)
 check(g.training_yard.ally_health==75 and g.health==hp,"healing changes dummy health, not player health")
 g.position_in_world=g.training_yard.ALLY-Vector2(100,0)
 c.party_heroes.kindred("solo",g.position_in_world,Vector2.RIGHT,12,7,400);c.party_heroes.step(.3)
 check(g.training_yard.ally_health>75,"friendly projectile heals green target")
 c.apply_status("p:training_ally","guard",2,"solo",.2)
 check(c.reduction("training_ally")>=.2 and not c.passive("training_ally","guard"),"ally buffs apply without inheriting selected hero passive")
 g.adventure.healing_zones=[{"owner":"solo","pos":c.point_array(g.training_yard.ALLY),"radius":150,"time":2.0,"tick":0.0,"heal":10}]
 var ah:float=g.training_yard.ally_health;g.health=g.max_health()-30;hp=g.health;g.adventure.step_healing_zones(1)
 check(g.training_yard.ally_health==ah+10 and g.health==hp+10,"area healing heals each friendly exactly once")
 g.training_yard.ally_health=200;g.training_yard.step(g,3.1);check(g.training_yard.ally_health==50,"fully healed target resets after visible full-health pause")
 check(g.training_yard.HERO_BOOK.x<400 and g.town_chapter.GUIDE.x<500,"book and guide are relocated toward entrance")
 check(g.adventure.can_stand(g.training_yard.HERO_BOOK) and g.adventure.can_stand(g.town_chapter.GUIDE) and g.adventure.can_stand(g.training_yard.ALLY),"relocated interactions and ally are reachable")
 # Synthetic ally must not run a duplicate of the selected hero's automatic passives.
 for id in ["tempo","mosaic","wickowhisp","ram","little_menace"]:
  if not g.characters.has(id):continue
  g.selected_character=id;g.start_training();g.set_process(false);g.adventure.step(.05)
  check(g.adventure.combat.v78.hero("training_ally")=="","dummy is not a second playable hero")
 g.enter_region("town");check(not g.adventure.points().has("training_ally"),"ally target is removed outside practice")
 await tidy(g);print("v111 failures: ",failures);quit(1 if failures else 0)
