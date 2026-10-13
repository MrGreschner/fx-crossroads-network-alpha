extends SceneTree
const P=preload("res://scripts/workshop_project.gd")
const E=preload("res://scripts/studio_enemy_project.gd")
const B=preload("res://scripts/studio_behavior.gd")
const O=preload("res://scripts/studio_options.gd")
func _initialize()->void:
 var data={"hero":[],"ability":[],"enemy":[],"behavior":[]}
 var styles=["melee","spread","heal_wave","summon","vortex"]
 var names=["Stone Apprentice","Prism Sprout","Lantern Friend","Hive Keeper","River Warden"]
 var sprites=["ram","book","medic","apiary","ferryman"]
 var roles=["Melee","Ranged","Support","Summoner","Control"]
 var lessons=["Compare quick sweeps with a charged strike.","Study count, spread and projectile speed.","Balance healing against attack strength.","Compare a group of minions with one stronger ally.","Control space with pulls and slowing fields."]
 for n in 5:
  var hero=P.fresh();hero.hero.name=names[n];hero.hero.role=roles[n];hero.hero.species=["Ram","Living book","Ram healer","Mechanical beekeeper","Bear"][n];hero.hero.lore=lessons[n];hero.concept=lessons[n]
  hero.hero.primary=P.attack(styles[n]);hero.hero.primary.heal=0 if n!=2 else 12;hero.hero.primary.name=["Stone Sweep","Prism Fan","Lantern Pulse","Little Swarm","River Pull"][n];hero.hero.primary.damage=12;hero.hero.primary.cooldown=1.2;hero.hero.primary.charge=.8 if n==0 else 0.0
  hero.hero.secondary=P.attack(["dash","homing","heal_zone","buff_zone","slow_aura"][n]);hero.hero.secondary.cooldown=4
  hero.hero.special=P.attack(["spin","beam","heal_wave","summon","vortex"][n]);hero.hero.special.cooldown=10
  hero.hero.passive=["defence","patient_power","mending","packguard","frost"][n];hero.hero.passive_aura=n in [2,4]
  for pose in ["idle","walk1","walk2","attack"]:
   var path="res://assets/"+sprites[n]+"_"+pose+".png"
   if FileAccess.file_exists(path):hero.hero.art[pose]=Marshalls.raw_to_base64(FileAccess.get_file_as_bytes(path))
  assert(P.validate(hero).is_empty(),P.validate(hero));data.hero.append(hero)
 var patterns=["melee","spread","boomerang","summon","vortex"]
 for n in 5:
  var a=P.attack("custom");O.complete(a);a.name=["Charged Crescent","Five Colour Fan","Returning Ribbon","Pocket Patrol","Tidal Well"][n];a.category=["melee","ranged","ranged","summon","control"][n];a.build_pattern=patterns[n];a.heal=0;a.charge=1 if n==0 else 0;a.count=5 if n==1 else 3;a.status="slow" if n==4 else "none";a.program=O.program(a,patterns[n]);assert(P.validate_attack(a).is_empty(),P.validate_attack(a));data.ability.append(a)
 var brains=["move chase\nif distance < 90\n use primary\nend\n",B.template("enemy"),"if cycle < 2\n move chase\n use primary\nelse\n move retreat\nend\n","if health < 40\n move retreat\n use secondary\nelse\n move patrol\n use primary\nend\n",B.template("ability")]
 for n in 5:
  var b=B.fresh("ability" if n==4 else "enemy");b.name=["Close Pursuit","Keep Your Distance","Charge and Retreat","Survival Patrol","Living Flight"][n];b.program="# Example: change one condition and predict the result.\n"+brains[n];assert(B.validate(b).is_empty(),B.validate(b));data.behavior.append(b)
  var enemy=E.fresh();enemy.name=["Bramble Practice","Wave Sentry","Rush Beetle","Mending Sentinel","Nest Keeper"][n];enemy.lore=lessons[n];enemy.behavior=data.behavior[mini(n,3)].duplicate(true);enemy.primary=P.attack(["melee","spread","dash","projectile","summon"][n]);enemy.primary.damage=8;enemy.primary.heal=0;enemy.primary.cooldown=1.5;enemy.attack_count=3 if n==4 else 2;enemy.secondary=P.attack("heal_wave" if n==3 else "spin");enemy.secondary.cooldown=5;enemy.special=P.attack("summon");enemy.special.cooldown=8
  var sprite=["bramble","archer","bramble","bramble","archer"][n]
  for pose in ["idle","walk1","walk2","attack"]:
   var path="res://assets/"+sprite+"_"+pose+".png"
   if FileAccess.file_exists(path):enemy.art[pose]=Marshalls.raw_to_base64(FileAccess.get_file_as_bytes(path))
  assert(E.validate(enemy).is_empty(),E.validate(enemy));data.enemy.append(enemy)
 var file=FileAccess.open("res://content/workshop/lab-examples.json",FileAccess.WRITE);file.store_string(JSON.stringify(data,"  "));file.close();print("20 VALID EXAMPLES GENERATED");quit()
