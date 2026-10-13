extends SceneTree
const Project=preload("res://scripts/workshop_project.gd")
const Options=preload("res://scripts/studio_options.gd")
const Language=preload("res://scripts/studio_script.gd")
var failures=0
var arena:Node
func check(ok:bool,message:String)->void:
 print("PASS: " if ok else "FAIL: ",message)
 if not ok:failures+=1
func _initialize()->void:call_deferred("run")
func attack(pattern:String,category:String="ranged")->Dictionary:
 var a=Project.attack("custom");Options.complete(a);a.category=category;a.build_pattern=pattern;a.damage=20;a.heal=0;a.charge=0;a.program=Options.program(a,pattern);return a
func start(a:Dictionary,passive:String="none")->void:
 var p=Project.fresh();p.hero.primary=a;p.hero.passive=passive;arena.begin(p,[],"Cluster");arena.set_process(false);arena.player=Vector2(420,270);arena.aim=Vector2.RIGHT;arena.aim_point=Vector2(520,270)
func run()->void:
 arena=preload("res://scripts/workshop_arena.gd").new();root.add_child(arena)
 for category in Options.CATEGORIES:
  for pattern in Options.PATTERNS[category]:
   var a=attack(pattern,category);check(Project.validate_attack(a).is_empty(),"generated code validates: "+pattern);start(a);arena.cast("primary");arena.tick(.25)
   check(arena.shots.size()<=60 and arena.fields.size()<=16 and arena.minions.size()<=5,"bounded execution: "+pattern)
 var a=attack("melee","melee");a.melee_arc=360;start(a);arena.foes[0].pos=Vector2(350,270);arena.cast("primary");arena.tick(.15);check(arena.foes[0].hp<200,"360° melee reaches behind hero")
 a.melee_arc=50;start(a);arena.foes[0].pos=Vector2(350,270);arena.cast("primary");arena.tick(.15);check(arena.foes[0].hp==200,"narrow melee arc excludes targets behind")
 for motion in Options.MOTIONS:
  a=attack("projectile");a.projectile_motion=motion;a.range=400;start(a);arena.foes.clear();arena.cast("primary");arena.tick(.1)
  check(not arena.shots.is_empty() and (motion!="wave" or absf(arena.shots[0].pos.y-270)>1),"flight path executes: "+motion)
 a=attack("projectile");a.target_mode="cursor";start(a);arena.foes.clear();arena.aim_point=Vector2(450,270);arena.cast("primary");arena.tick(.1);check(arena.shots.is_empty(),"projectile stops at short mouse destination")
 a=attack("projectile");a.charge=1;a.program=Options.program(a,"projectile");start(a);arena.press("primary");arena.tick(1);check(arena.shots.is_empty(),"charge holds fire until release");arena.release("primary");check(arena.shots.size()==1 and arena.shots[0].ability.damage>20,"release applies charge strength")
 a=attack("melee","melee");a.lifesteal=10;start(a);arena.health=60;arena.foes[0].pos=Vector2(470,270);arena.cast("primary");arena.tick(.15);check(arena.health>60,"melee lifesteal restores health")
 for kind in Options.MINION_ATTACKS:
  a=attack("summon","summon");a.minion_attack=kind;a.minion_health=60;a.heal=5;a.program=Options.program(a,"summon");start(a);arena.health=60;arena.cast("primary");arena.tick(.1)
  check(arena.minions.size()==3 and arena.minions[0].max_hp==60,"summon health / count: "+kind)
  check((arena.health>60) if kind=="heal" else (arena.shots.size()>0) if kind=="projectile" else true,"summon attack: "+kind)
 var p=Project.fresh();p.hero.passive="guardian";arena.begin(p,[],"Cluster");arena.health=20;check(arena.passive.reduction()==.15,"guardian low-health protection")
 for passive in ["executioner","steadyhand","momentum","patient_power"]:
  start(Project.attack(),passive);arena.foes[0].hp=20;arena.passive.still=1;arena.moving=true;var hit=arena.hero.primary.duplicate();hit.charged=1;check(arena.passive.damage_multiplier(hit,arena.foes[0])>1,"damage passive: "+passive)
 for mode in ["power","haste","defence"]:
  a=attack("buff_zone","control");a.buff=mode;a.radius=100;start(a);arena.add_field(arena.player,a,"buff")
  check(arena.buff_power()>1 if mode=="power" else arena.buff_speed()>1 if mode=="haste" else arena.buff_reduction(arena.player)==.15,"ground buff: "+mode)
 start(Project.attack(),"bloodthread");arena.health=60;arena.passive.defeated();check(arena.health==63,"kill healing")
 start(Project.attack(),"scavenger");arena.cooldowns.primary=2;arena.passive.defeated();check(arena.cooldowns.primary==1.5,"kill cooldown reward")
 start(Project.attack(),"bulwark");arena.passive.still=1;check(arena.passive.reduction()==.12,"stationary armour")
 start(Project.attack(),"quickdraw");check(arena.passive.cooldown("primary",arena.hero.primary)==.9,"tap attack speed")
 start(Project.attack(),"ebbflow");arena.health=20;arena.restore(10);check(arena.health==32,"low health healing bonus")
 for passive in ["packguard","packhaste","packfury","packvitality","packmend"]:
  a=attack("summon","summon");start(a,passive);arena.cast("primary");arena.minions[0].hp=20;arena.tick(1);check(arena.minions.size()==3,"pack passive active: "+passive)
  if passive=="packguard":check(is_equal_approx(arena.passive.reduction(),.06),"pack armour counts minions")
  if passive=="packvitality":check(arena.minions[0].max_hp==48,"pack vitality increases health")
  if passive=="packmend":check(arena.minions[0].hp==21,"pack mending restores health")
 a=attack("heal_wave","control");a.heal=10;a.program=Options.program(a,"heal_wave");start(a,"mendersgift");arena.health=60;arena.cast("primary");check(arena.health==72,"mender boosts custom-program healing")
 start(Project.attack(),"radiance");arena.health=60;arena.passive.tick(8);check(arena.health==66,"radiance timed healing")
 start(Project.attack(),"nova_echo");arena.foes[0].pos=arena.player+Vector2(25,0)
 for i in 5:arena.passive.cast()
 check(arena.foes[0].hp==194,"fifth-cast pulse")
 for passive in ["chill_retaliation","toxic_thorns"]:
  start(Project.attack(),passive);arena.foes[0].pos=arena.player+Vector2(30,0);arena.passive.received();check(arena.foes[0].slow>0 if passive=="chill_retaliation" else arena.foes[0].dot>0,"retaliation status: "+passive)
 a=attack("summon","summon");a.count=1;a.program=Options.program(a,"summon");start(a,"packfury");arena.foes[0].pos=Vector2(460,270);arena.cast("primary");arena.tick(.1);check(is_equal_approx(arena.foes[0].hp,177),"pack damage increases actual hit")
 start(a,"packhaste");arena.foes[0].pos=Vector2(600,270);arena.cast("primary");var first=arena.minions[0].pos;arena.tick(.1);check(is_equal_approx(first.distance_to(arena.minions[0].pos),14.4),"pack haste increases actual movement")
 check(Project.PASSIVES.size()==37,"20 new passives available")
 var invalid=attack("projectile");invalid.projectile_motion="execute code";check(not Project.validate_attack(invalid).is_empty(),"reject unsupported motion")
 arena.queue_free();await process_frame;print("V127 failures: ",failures);quit(1 if failures else 0)
