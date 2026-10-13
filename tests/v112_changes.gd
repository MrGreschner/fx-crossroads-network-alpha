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
 for id in ["hero","ally","foe"]:a._add_player(id,0)
 a.pvp_rule="teams";a.teams={"hero":0,"ally":0,"foe":1};a.levels.hero=10;a.levels.ally=10;a.my_id="hero"
 a.positions={"hero":Vector2(700,500),"ally":Vector2(750,500),"foe":Vector2(760,500)};a.hero_ids.hero="ram";a.adventure.setup("");a.field_obstacles.clear();a._rebuild_grid();a.opponents.clear()
 var c=a.adventure.combat;var v=c.v112;var t=c.twister
 a.health.foe=300;a.health.ally=100
 v.cast("hero",a.characters.ram.special,Vector2.RIGHT,85);check(a.health.foe==300,"earthquake has no instant 85-damage hit")
 v.step(.5);check(a.health.foe==286 and c.speed_factor("p:foe")<=.35,"first quake pulse deals portion and strongly slows")
 for n in 5:v.step(.5)
 check(a.health.foe==215 and a.health.ally==100 and v.effects.is_empty(),"six pulses total exactly 85 damage over three seconds, exclude allies and expire")
 c.statuses.clear();a.health.foe=300;v.cast("hero",a.characters.ram.special,Vector2.RIGHT,85);v.step(.5);a.positions.foe=Vector2(1100,500);v.step(2.5)
 check(a.health.foe==286,"leaving quake avoids remaining damage")
 a.positions.foe=Vector2(760,500);a.hero_ids.foe="cat";a.stealth_until.foe=Time.get_ticks_msec()+3000
 check(not c.visible_owner("foe") and c.visible_owner("hero"),"enemy cat is hidden while local hero is visible")
 a.teams.foe=0;check(c.visible_owner("foe"),"allies retain cat silhouette");a.teams.foe=1;a.stealth_until.foe=0;check(c.visible_owner("foe"),"cat becomes visible after stealth")
 a.pvp_rule="ffa";a.stealth_until.foe=Time.get_ticks_msec()+3000;check(not c.visible_owner("foe"),"invisibility works in free-for-all");a.stealth_until.foe=0;a.pvp_rule="teams"
 a.hero_ids.hero="twisterspell";a.health.foe=300;c.statuses.clear();t.holding("hero",true,Vector2.RIGHT);t.cast("hero",a.characters.twisterspell.primary,Vector2.RIGHT,6);t.charges.hero.age=1.6;t.holding("hero",false,Vector2.RIGHT)
 check(t.effects[0].damage>14 and t.effects[0].radius>60 and t.effects[0].pull,"fully charged tornado is stronger and wider")
 a.positions.foe=Vector2(820,500);var distance:float=a.positions.foe.distance_to(c.vec(t.effects[0].pos));t.step(.1)
 check(a.positions.foe.distance_to(c.vec(t.effects[0].pos))<distance-8,"full tornado pulls substantially toward its centre")
 t.reset();a.health.foe=300;a.positions.foe=Vector2(780,500);a.positions.ally=Vector2(780,500)
 for p in [Vector2(700,500),Vector2(860,500),Vector2(780,650)]:
  var e:Dictionary=t.add("hero","funnel",p,4.2,6);e.radius=36;e.pull=false;e.zap=1.2
 t.lightning(.1);check(t.links.size()==3 and a.health.foe==292 and c.effect_time("p:foe","stun")>0 and a.health.ally==100,"three funnels link lightning with one damage/stun hit per target, never allies")
 var hp:int=a.health.foe;t.link_clock=0;t.lightning(.1);check(a.health.foe==hp,"links cannot chain-lock target with simultaneous stuns")
 t.reset();c.statuses.clear();a.health.foe=300
 var e:Dictionary=t.add("hero","funnel",Vector2(700,500),4.2,14.4);e.radius=61;e.pull=true;e.zap=0
 t.lightning(.1);check(a.health.foe==290 and not t.links.is_empty(),"one full funnel zaps enemy without needing three funnels")
 t.reset();a.levels.hero=4;e=t.add("hero","funnel",Vector2(700,500),4.2,14.4);e.radius=61;e.pull=true;e.zap=0;hp=a.health.foe;t.lightning(.1);check(a.health.foe==hp,"lightning is gated by passive unlock");a.levels.hero=10
 t.reset();c.statuses.clear();v.reset();a.hero_ids.hero="hearth_herald";a.positions.hero=Vector2(700,500);a.positions.ally=Vector2(730,500);a.positions.foe=Vector2(760,500);a.health.foe=300
 check(a.characters.has("hearth_herald"),"new support hero loads")
 v.cast("hero",a.characters.hearth_herald.secondary,Vector2.RIGHT,0)
 check(v.bonus("hero")==1.08 and v.bonus("ally")==1.08 and v.bonus("foe")==1,"enchantment buffs self and allies only")
 check(c.reduction("ally")>=.1 and c.reduction("foe")==0,"protective aura only benefits allies")
 v.on_hit("ally","p:foe",10);check(c.effect_time("p:foe","burn")==3,"enchanted ally's hit applies burn")
 c.statuses.clear();c.dot_damage=true;v.on_hit("hero","p:foe",10);c.dot_damage=false;check(c.effect_time("p:foe","burn")==0,"damage-over-time cannot recursively add weapon burns")
 v.reset();a.health.ally=50;v.cast("hero",a.characters.hearth_herald.mastery.technique.attack,Vector2.RIGHT,0);v.on_hit("ally","p:foe",10)
 check(a.health.ally==53 and c.effect_time("p:foe","burn")==0,"first mastery trades added burn for life-on-hit")
 v.reset();c.v79.prepare("hero",a.characters.hearth_herald.special,Vector2.RIGHT,Vector2(720,500));v.cast("hero",a.characters.hearth_herald.special,Vector2.RIGHT,0);v.step(1)
 check(a.health.ally==57,"banner heals allies over time")
 check(not v.catch_shot(Vector2(600,500),Vector2(800,500),"ally"),"banner preserves friendly projectiles")
 for n in 6:check(v.catch_shot(Vector2(600,500),Vector2(800,500),"foe"),"banner catches hostile projectile")
 check(not v.catch_shot(Vector2(600,500),Vector2(800,500),"foe"),"banner catch limit is finite")
 var snap:Dictionary=c.snapshot().duplicate(true);v.reset();c.receive(snap);check(not v.effects.is_empty(),"new combat state survives snapshot round-trip")
 v.reset();a.role="guest";v.cast("hero",a.characters.hearth_herald.secondary,Vector2.RIGHT,0);check(v.effects.is_empty(),"guests cannot author buffs or damage");a.role="host"
 a.started=false;v.step(.1);check(v.effects.is_empty() and v.defence("ally")==0,"new effects and aura inactive outside game")
 await tidy(a)
 var g=load("res://scenes/main.tscn").instantiate();root.add_child(g);await process_frame;g.set_process(false);g.presentation.asked=true;g.presentation.close();g.session_menu.resume();g.journey.last_sound=Time.get_ticks_msec()+1000000
 check(g.characters.size()==80,"all 80 playable heroes load")
 g.selected_character="hearth_herald";g.start_training();g.set_process(false);g.position_in_world=g.training_yard.ALLY-Vector2(100,0);g.fire("secondary")
 check(g.adventure.combat.v112.bonus("training_ally")==1.08,"new support buff works on allied training target")
 g.enter_region("town");check(g.adventure.combat.v112.effects.is_empty() and g.adventure.combat.v112.defence("solo")==0,"town clears combat aura and buffs")
 await tidy(g);print("v112 failures: ",failures);quit(1 if failures else 0)
