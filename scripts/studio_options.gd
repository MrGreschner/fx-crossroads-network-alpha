extends RefCounted
const CATEGORIES={"melee":"Melee","ranged":"Ranged / projectile","control":"Control / support","summon":"Summoning"}
const PATTERNS={"melee":{"melee":"Directional strike","spin":"All-around pulse","dash":"Dash strike","siphon":"Life-draining strike"},"ranged":{"projectile":"Single projectile","spread":"Projectile fan","burst":"Short burst","ring_shots":"All-direction volley","beam":"Piercing beam","chain":"Chain between targets"},"control":{"heal_wave":"Healing pulse","heal_zone":"Healing ground","slow_aura":"Slowing ground","poison_zone":"Poison ground","burn_zone":"Burning ground","vortex":"Pulling vortex","trap":"Proximity mine","block":"Protective shell","stun_zone":"Stunning pulse field","buff_zone":"Ally buff field"},"summon":{"summon":"Summon allies"}}
const MELEE={"swing":"Sweeping arc","instant":"Instant impact","pulse":"Slow expanding pulse","jab":"Line punches","slash":"Twin slashes","slam":"Ground slam","claw":"Claw rake","scythe":"Scythe crescent","staff":"Staff sweep","custom":"Custom pixel frames"}
const PROJECTILES={"bolt":"Energy bolt","arrow":"Arrow","fire":"Fireball","ice":"Ice shard","water":"Water drop","leaf":"Leaf","star":"Throwing star","orb":"Glowing orb","lightning":"Lightning spark","seed":"Seed","skull":"Spirit skull","bubble":"Bubble","stone":"Stone","heart":"Healing heart","custom":"Custom pixel frames"}
const CHARGES={"gauge":"Ring gauge","grow":"Growing projectile","orbit":"Orbiting sparks","runes":"Rune circle","flame":"Gathering embers","custom":"Custom pixel frames"}
const MOTIONS={"straight":"Straight","lob":"Lobbed arc / impact burst","homing":"Seeking target","return":"Out and back","wave":"Waving flight"}
const AIM={"direction":"Aim direction • full range","cursor":"Mouse / touch point • stop there"}
const AIM_GUIDES={"line":"Direction line","reticle":"Landing / aim circle","cone":"Area / spread preview","none":"No extra guide"}
const MINIONS={"ram":"Ram guard","cat":"Crossroads cat","rabbit":"Rabbit helper","bee":"Clockwork bee","wisp":"Spirit wisp","golem":"Stone golem","custom":"Custom pixel image"}
const MINION_ATTACKS={"melee":"Close melee","projectile":"Ranged bolt","heal":"Heal hero / allies"}
const BUFFS={"defence":"15% damage reduction","power":"10% extra attack damage","haste":"15% faster movement"}
const DEFAULTS={"charge_effect":"balanced","max_charge_status":"none","category":"ranged","build_pattern":"projectile","melee_arc":100.0,"spread":24.0,"lifesteal":0.0,"melee_visual":"swing","projectile_graphic":"bolt","charge_visual":"gauge","projectile_motion":"straight","target_mode":"direction","aim_guide":"line","minion_graphic":"ram","minion_attack":"melee","minion_health":40.0,"minion_speed":120.0,"minion_interval":1.0,"buff":"defence","impact_burst":false}
const NUMBERS={"melee_arc":[20,360,5],"spread":[0,180,5],"lifesteal":[0,20,1],"minion_health":[20,80,5],"minion_speed":[60,180,10],"minion_interval":[.5,2,.1]}
static func complete(a:Dictionary)->void:
 for key in DEFAULTS:
  if not a.has(key):a[key]=DEFAULTS[key]
static func validate(a:Dictionary)->String:
 for key in NUMBERS:
  if a.has(key) and not load("res://scripts/workshop_project.gd").number(a[key],NUMBERS[key][0],NUMBERS[key][1]):return "Invalid option: "+key
 var enums={"charge_effect":preload("res://scripts/studio_charge.gd").EFFECTS,"max_charge_status":{ "none":"", "slow":"", "stun":"", "burn":"", "poison":"", "bleed":""},"category":CATEGORIES,"melee_visual":MELEE,"projectile_graphic":PROJECTILES,"charge_visual":CHARGES,"projectile_motion":MOTIONS,"target_mode":AIM,"aim_guide":AIM_GUIDES,"minion_graphic":MINIONS,"minion_attack":MINION_ATTACKS,"buff":BUFFS}
 if a.has("build_pattern") and not load("res://scripts/workshop_project.gd").STYLES.has(a.build_pattern):return "Unknown build pattern."
 for key in enums:
  if a.has(key) and not enums[key].has(a[key]):return "Unknown option: "+key
 if a.has("impact_burst") and not a.impact_burst is bool:return "Invalid impact toggle."
 if a.has("minion_image"):
  if not a.minion_image is String or not load("res://scripts/workshop_project.gd").png_error(Marshalls.base64_to_raw(a.minion_image)).is_empty():return "Invalid minion image."
 return ""
static func program(a:Dictionary,pattern:String)->String:
 var code="# Built in Crossroads Studio. Edit the instructions below to experiment.\n"
 for key in ["damage","heal","range","radius","speed","count","duration","cooldown","charge"]:code+="let "+key+" = "+str(a[key])+"\n"
 var command={"spin":"pulse","spread":"projectile","burst":"burst","ring_shots":"projectile","target_aoe":"lob","heal_wave":"heal","heal_zone":"healing_field","slow_aura":"slow_field","poison_zone":"field","burn_zone":"burn_field","stun_zone":"stun_field","buff_zone":"buff_field","vortex":"vortex","trap":"mine","block":"protect"}.get(pattern,pattern)
 if pattern in ["spread","ring_shots"]:
  var step=float(a.get("spread",24))/maxf(1,float(a.count)-1)
  if pattern=="ring_shots":step=360.0/float(a.count)
  code+="repeat count\n  emit "+str(command)+" angle index * "+str(step)+" - "+str(float(a.get("spread",24))*.5 if pattern!="ring_shots" else 0)+"\nend\n"
 else:code+="emit "+str(command)+"\n"
 return code
