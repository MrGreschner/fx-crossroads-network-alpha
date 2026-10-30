extends RefCounted
const FORMAT="fx-crossroads-enemy"
const Project=preload("res://scripts/workshop_project.gd")
const Behavior=preload("res://scripts/studio_behavior.gd")
static func fresh()->Dictionary:
 var primary=Project.attack("projectile");primary.name="Practice bolt";primary.damage=8;primary.heal=0;primary.range=350;primary.cooldown=1.5
 var secondary=Project.attack("spin");secondary.name="Keep away";secondary.damage=10;secondary.heal=0;secondary.cooldown=5
 return {"format":FORMAT,"version":1,"id":"enemy-"+str(randi()),"name":"My practice enemy","lore":"A watchful sparring partner.","health":100.0,"speed":100.0,"radius":20.0,"art":preload("res://scripts/studio_art249.gd").encoded("bramble_practice"),"attack_count":2,"primary":primary,"secondary":secondary,"special":Project.attack("summon"),"behavior":Behavior.fresh(),"reports":[]}
static func validate(value:Variant)->String:
 if not value is Dictionary or value.get("format")!=FORMAT or value.get("version")!=1:return "Not a Crossroads enemy project."
 if JSON.stringify(value).to_utf8_buffer().size()>Project.MAX_BYTES:return "Enemy project exceeds 2 MB."
 for key in value:
  if not key in ["format","version","id","name","lore","health","speed","radius","art","primary","secondary","behavior","reports","attack_count","special","forced_balance","defence","balance_tradeoff"]:return "Unknown enemy field: "+str(key)
 if value.has("forced_balance") and not value.forced_balance is bool:return "Invalid balance toggle."
 if value.has("defence") and not Project.number(value.defence,0,.25):return "Defence outside balance limits."
 for key in ["name","id","lore"]:
  if not value.get(key) is String or value[key].length()>(600 if key=="lore" else 60):return "Invalid enemy "+key
 if value.name.strip_edges().is_empty():return "Give the enemy a name."
 for pair in [["health",20,500],["speed",40,230],["radius",12,36]]:
  if not Project.number(value.get(pair[0]),pair[1],pair[2]):return "Enemy "+pair[0]+" is outside the supported range."
 if not value.get("art") is Dictionary:return "Add enemy artwork or use the practice silhouette."
 for pose in value.art:
  if not pose in ["idle","walk1","walk2","attack"] or not value.art[pose] is String:return "Unknown enemy pose."
  var issue=Project.png_error(Marshalls.base64_to_raw(value.art[pose]))
  if not issue.is_empty():return issue
 if value.has("attack_count") and (not value.attack_count is float and not value.attack_count is int or not float(value.attack_count) in [1.0,2.0,3.0]):return "Choose one to three attacks."
 if int(value.get("attack_count",2))==3 and not value.has("special"):return "Add the third attack before choosing three slots."
 for slot in (["primary","secondary","special"] if value.has("special") else ["primary","secondary"]):
  var issue=Project.validate_attack(value.get(slot))
  if not issue.is_empty():return issue
 var issue=Behavior.validate(value.get("behavior"))
 if not issue.is_empty():return issue
 if value.behavior.kind!="enemy":return "Enemies need an enemy behaviour."
 if not value.get("reports") is Array or value.reports.size()>20:return "Keep at most 20 enemy test reports."
 for report in value.reports:
  if not report is Dictionary or JSON.stringify(report).length()>4000:return "Invalid enemy test report."
 return ""
