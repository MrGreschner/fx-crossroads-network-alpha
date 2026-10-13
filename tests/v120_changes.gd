extends SceneTree
var failures:=0
var g:Node
var combat:Node
var held:Node
func check(ok:bool,title:String)->void:
 if not ok:failures+=1;print("FAIL: ",title)
func _initialize()->void:call_deferred("run")
func setup(id:String)->void:
 g.start_run(false,"grove");g.presentation.close();g.menu="";g.selected_character=id;g.hero=g.characters[id].duplicate(true);g.level=10;g.health=g.max_health();g.position_in_world=Vector2(450,450);g.enemies.clear();g.obstacles.clear();g.build_scenery();g.inventory.clear();g.bonus_damage=0;g.upgrade="";g.mastery="";combat.setup("grove");g.cooldowns={"primary":0.0,"secondary":0.0,"special":0.0}
func enemy(uid:int,offset:Vector2)->String:
 var p:Vector2=g.position_in_world+offset
 g.enemies.append({"uid":uid,"pos":p,"type":"bramble","hp":1000.0,"max_hp":1000.0,"boss":false,"hit_radius":18,"speed":0.0,"timer":9.0,"attack_timer":9.0,"name":"Test Bramble"})
 return "e:"+str(uid)
func cast(id:String,kind:String,seconds:float,offset:Vector2=Vector2(220,0))->void:
 setup(id);held.begin("solo",kind,offset.normalized(),g.position_in_world+offset)
 check(held.charges.has("solo"),id+" starts hold")
 held.step(seconds);held.release("solo")
func tidy(node:Node)->void:
 for p in node.find_children("*","AudioStreamPlayer",true,false):p.stop();p.stream=null
 node.queue_free();await process_frame;await process_frame;await create_timer(.2).timeout
func run()->void:
 root.set_meta("fx_intro_seen",true);root.set_meta("fx_tutorial_offered",true)
 g=load("res://scenes/main.tscn").instantiate();root.add_child(g);current_scene=g;await process_frame;g.set_process(false)
 combat=g.adventure.combat;held=combat.held_cast
 setup("hollow_rider");var key:=enemy(601,Vector2(70,0));held.begin("solo","primary",Vector2.RIGHT,Vector2(650,450));held.step(1.3);held.release("solo");combat.halloween.step(.13)
 check(is_equal_approx(float(g.enemies[0].hp),955),"full scythe damage")
 check(combat.statuses.get(key,{}).has("bleed"),"full scythe bleed")
 setup("hollow_rider");key=enemy(602,Vector2(70,0));held.begin("solo","primary",Vector2.RIGHT,Vector2(650,450));held.release("solo");combat.halloween.step(.13)
 check(is_equal_approx(float(g.enemies[0].hp),975) and not combat.statuses.get(key,{}).has("bleed"),"tap scythe no bleed")
 cast("apiary","primary",1.4);check(is_equal_approx(float(combat.projectiles[0].damage),36) and is_equal_approx(float(combat.projectiles[0].stats.stun_duration),1.25),"charged needle damage and stun")
 key=enemy(603,Vector2(80,0));combat.step_projectiles(.2)
 check(combat.statuses.get(key,{}).has("stun"),"needle impact stuns")
 setup("hearth_herald");key=enemy(604,Vector2(90,0));var outside:=enemy(605,Vector2(0,90));g.health=80
 held.begin("solo","primary",Vector2.RIGHT,Vector2(650,450));held.step(.05)
 check(is_equal_approx(float(g.enemies[0].hp),994) and is_equal_approx(float(g.enemies[1].hp),1000),"held light damages cone only")
 check(g.health==82 and combat.v112.effects.size()==1,"held light heals self and bounded visual")
 g.cooldowns.primary=0;held.step(.5);check(g.enemies[0].hp==988 and g.health==84,"light repeats while held")
 held.release("solo");combat.v112.step(.01);check(combat.v112.effects.is_empty(),"release stops light immediately")
 setup("recess");key=enemy(606,Vector2(70,0));var second:=enemy(607,Vector2(150,0));combat.cast("solo",g.hero.primary,Vector2.RIGHT,18)
 for n in 20:combat.v112.step(.03)
 check(g.enemies[0].hp==982 and g.enemies[1].hp==982,"echo pierces multiple targets once")
 check(g.training_yard.HERO_BOOK==Vector2(660,400) and g.town_chapter.GUIDE==Vector2(290,400),"book right guide left")
 await tidy(g)
 var a=load("res://scenes/arcade.tscn").instantiate();root.add_child(a);current_scene=a;await process_frame;a.set_process(false);a.party_tools.set_process(false);a.mode="arena";a.role="host";a.started=true;a.start_countdown=0;a.my_id="host";a.host_id="host";a.roster.assign([{"id":"host","name":"Host"},{"id":"guest","name":"Friend"}]);a._add_player("host",0);a._add_player("guest",1);a.hero_ids.guest="hearth_herald";a.levels.guest=10;a.positions.guest=Vector2(450,450);a.positions.host=Vector2(510,450);a.adventure.combat.setup("grove");a.inventory.guest=[];a.cooldown_at.guest={};a.health.guest=80;a.health.host=80
 combat=a.adventure.combat;held=combat.held_cast
 a._packet("guest",{"type":"held_cast","phase":"begin","kind":"primary","angle":0,"target":[650,450]})
 held.step(.05)
 check(a.health.guest==82 and a.health.host<80,"host channel heals caster and damages opposing player")
 a._packet("guest",{"type":"held_cast","phase":"release","kind":"primary","angle":0,"target":[650,450]});combat.v112.step(.01)
 check(not held.charges.has("guest") and combat.v112.effects.is_empty(),"guest release stops replicated channel")
 a.cooldown_at.guest={};held.begin("guest","primary",Vector2.RIGHT,Vector2(650,450));held.step(2)
 check(not held.charges.has("guest"),"missing remote input cancels channel")
 await tidy(a);print("v120 failures: ",failures);quit(1 if failures else 0)
