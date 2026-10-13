extends RefCounted
## Declarative, versioned student projects. No script paths or executable code.
const FORMAT="fx-crossroads-workshop"
const SCHEMA=3
const MAX_BYTES=2097152
const PATH="user://fx_workshop_project.json"
const KINDS=["primary","secondary","special"]
const STYLES={
 "melee":"Directional melee sweep", "projectile":"Straight projectile", "spread":"Projectile fan",
 "homing":"Seeking projectile", "boomerang":"Returning blade", "beam":"Piercing beam",
 "spin":"Expanding shockwave", "chain":"Chain between targets", "target_aoe":"Lobbed explosion",
 "flame":"Held flame cone", "dash":"Dash strike", "trap":"Place a proximity mine",
 "summon":"Summon fighting allies", "heal_wave":"Healing pulse", "heal_zone":"Healing field",
 "block":"Temporary protection", "slow_aura":"Slowing field",
 "burst":"Consecutive projectile burst", "ring_shots":"Radial projectile volley", "vortex":"Pulling vortex", "poison_zone":"Poison ground", "blink":"Teleport and burst", "siphon":"Drain and heal", "burn_zone":"Burning ground", "stun_zone":"Stunning field", "buff_zone":"Ally buff field", "custom":"Custom • Ability Lab program"
}
const PASSIVES={"none":"No passive", "lifesteal":"Life on hit (8%)", "quick_primary":"Primary cooldown reduced 15%", "defence":"10% damage reduction", "regeneration":"Recover 1 HP / second", "swift":"Move 8% faster", "burn_touch":"Burn on hit", "poison_touch":"Poison on hit", "slow_touch":"Slow on hit", "critical":"Occasional critical hit", "thorns":"Reflect some incoming damage", "resilience":"Shorter hostile statuses", "shelter":"Protective aura", "mending":"Healing aura", "frost":"Slowing aura", "overload":"Periodic damage pulse", "summoner":"Longer-lived minions", "executioner":"Finisher • +10% damage below 30% target HP", "steadyhand":"Steady hands • +10% damage after standing still", "momentum":"Momentum • +10% primary damage while moving", "guardian":"Guardian • 15% protection below 35% HP", "bulwark":"Bulwark • 12% protection while stationary", "patient_power":"Patient power • +12% damage at full charge", "quickdraw":"Quick draw • instant primary cooldown −10%", "bloodthread":"Blood thread • recover 3 HP on a defeat", "scavenger":"Scavenger • defeats reduce cooldowns by 0.5s", "ebbflow":"Ebb & flow • +20% healing below half health", "mendersgift":"Mender’s gift • +20% ability healing", "packguard":"Pack guard • 2% protection per minion", "packhaste":"Pack haste • minions move 20% faster", "packfury":"Pack fury • minions deal 15% more damage", "packvitality":"Pack vitality • minions gain 20% health", "packmend":"Pack mending • minions recover 1 HP/s", "nova_echo":"Echo • every fifth cast pulses for 6 damage", "radiance":"Radiance • heal 6 HP every 8 seconds", "chill_retaliation":"Chill retaliation • nearby attacker is slowed", "toxic_thorns":"Toxic thorns • poison a nearby attacker"}
const STATUS=["none","slow","stun","burn","poison","bleed"]
const LIMITS={"damage":[0.0,60.0,1.0],"heal":[0.0,30.0,1.0],"cooldown":[0.3,20.0,0.1],"range":[40.0,600.0,10.0],"radius":[20.0,180.0,5.0],"speed":[100.0,700.0,25.0],"count":[1.0,5.0,1.0],"duration":[0.5,8.0,0.5],"charge":[0.0,2.0,0.1],"status_duration":[0.5,3.0,0.5],"status_damage":[0.0,3.0,0.5]}
static func attack(style:String="melee")->Dictionary:
 return {"name":"New ability","style":style,"damage":18.0,"heal":8.0,"cooldown":1.0,"range":180.0,"radius":70.0,"speed":350.0,"count":3,"duration":3.0,"charge":0.0,"status":"none","status_duration":1.5,"status_damage":1.0,"color":"#7bd8de"}
static func fresh()->Dictionary:
 var h={"name":"My Crossroads Hero","role":"Melee","species":"Your choice","lore":"","max_health":120.0,"speed":230.0,"passive":"none","art":{},"passive_aura":false,"passive_radius":100.0}
 h.primary=attack();h.primary.name="First strike"
 h.secondary=attack("projectile");h.secondary.name="Second idea";h.secondary.cooldown=3.0
 h.special=attack("spin");h.special.name="Signature move";h.special.cooldown=10.0;h.special.damage=40.0
 return {"format":FORMAT,"schema_version":SCHEMA,"ability_api":"workshop-1","project_id":"student-"+str(Time.get_unix_time_from_system())+"-"+str(randi()%100000),"revision":1,"author":"","concept":"","hero":h,"techniques":[{"name":"Technique one","slot":"secondary","attack":attack("homing")},{"name":"Final technique","slot":"special","attack":attack("beam")}],"notes":{"hypothesis":"","method":"","observations":"","next_change":""},"reports":[],"code_lab":{"enabled":false,"api":"workshop-1"}}
static func fingerprint(project:Dictionary)->String:
 var copy=project.duplicate(true);copy.erase("reports");copy.erase("notes")
 # JSON imports represent numbers as floats; normalize first for portable hashes.
 return JSON.stringify(JSON.parse_string(JSON.stringify(copy))).sha256_text()
static func number(value:Variant,lo:float,hi:float)->bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)>=lo and float(value)<=hi
static func short_text(value:Variant,max_length:int)->bool:return value is String and value.length()<=max_length
static func png_error(bytes:PackedByteArray)->String:
 if bytes.size()<24 or bytes.size()>131072:return "PNG must be under 128 KB."
 if bytes.slice(0,8)!=PackedByteArray([137,80,78,71,13,10,26,10]) or bytes.slice(12,16).get_string_from_ascii()!="IHDR":return "Choose a valid PNG."
 var width=bytes[16]*16777216+bytes[17]*65536+bytes[18]*256+bytes[19]
 var height=bytes[20]*16777216+bytes[21]*65536+bytes[22]*256+bytes[23]
 if width<1 or height<1 or width>256 or height>256:return "Artwork must be at most 256 × 256 pixels."
 return ""
static func validate_attack(a:Variant)->String:
 if not a is Dictionary:return "Ability must be an object."
 if a.has("form_id") and (not short_text(a.form_id,30) or not number(a.get("form_duration",3),.2,8)):return "Invalid alternate form duration or identifier."
 if a.has("form_duration") and not number(a.form_duration,.2,8):return "Alternate form lasts 0.2–8 seconds."
 if a.has("forced_balance") and not a.forced_balance is bool:return "Invalid ability balance toggle."
 for key in a:
  if not key in LIMITS and not key in ["name","style","status","color","program","animation","charge_animation","minion_image","behavior","sound","forced_balance","form_id","form_duration"] and not key in preload("res://scripts/studio_options.gd").DEFAULTS and not key in preload("res://scripts/studio_options.gd").NUMBERS:return "Unsupported ability field: "+str(key)
 if not short_text(a.get("name"),60) or str(a.name).strip_edges().is_empty():return "Give each ability a name (1–60 characters)."
 if not STYLES.has(a.get("style")):return "Unknown ability type. Use the workshop ability library."
 for key in LIMITS:
  if not number(a.get(key),LIMITS[key][0],LIMITS[key][1]):return "Ability value outside supported limits: "+key
 if float(a.count)!=floorf(float(a.count)):return "Projectile / target count must be a whole number."
 if not str(a.get("status","")) in STATUS:return "Unknown status effect."
 if not short_text(a.get("color"),9) or not Color.html_is_valid(a.color):return "Invalid ability colour."
 if a.style=="custom":
  var result=preload("res://scripts/studio_script.gd").compile(str(a.get("program","")))
  if not result.error.is_empty():return result.error
 if a.has("behavior"):
  var issue=preload("res://scripts/studio_behavior.gd").validate(a.behavior)
  if not issue.is_empty() or a.behavior.kind!="ability":return "Invalid ability behaviour: "+issue
 if a.has("sound"):
  var audio_issue=preload("res://scripts/studio_audio.gd").validate(a.sound)
  if not audio_issue.is_empty():return audio_issue
 var option_issue=preload("res://scripts/studio_options.gd").validate(a)
 if not option_issue.is_empty():return option_issue
 for slot in ["animation","charge_animation"]:
  if not a.has(slot):continue
  if not a[slot] is Array or a[slot].size()>8:return "Use at most eight animation frames."
  for frame in a[slot]:
   if not short_text(frame,180000) or not png_error(Marshalls.base64_to_raw(frame)).is_empty():return "Invalid attack animation PNG."
   var image=Image.new()
   if image.load_png_from_buffer(Marshalls.base64_to_raw(frame))!=OK:return "Invalid attack animation image."
 return ""
static func validate(p:Variant)->String:
 if not p is Dictionary:return "This is not a workshop project."
 if JSON.stringify(p).to_utf8_buffer().size()>MAX_BYTES:return "Project exceeds 2 MB. Use smaller art or fewer reports."
 if p.get("format")!=FORMAT:return "Choose a workshop project file, not a player profile."
 if not number(p.get("schema_version"),1,SCHEMA) or float(p.schema_version)!=floorf(float(p.schema_version)) or p.get("ability_api")!="workshop-1":return "This project needs a different workshop version."
 if not short_text(p.get("project_id"),100) or not number(p.get("revision"),1,1000000):return "Invalid project identity."
 if float(p.revision)!=floorf(float(p.revision)):return "Revision must be a whole number."
 for key in ["author","concept"]:
  if not short_text(p.get(key),1000):return "Invalid author or concept."
 var h:Variant=p.get("hero")
 if not h is Dictionary:return "Missing hero."
 for key in ["name","role","species","lore"]:
  if not short_text(h.get(key),1000):return "Invalid hero text: "+key
 if not h.role in ["Melee","Ranged","Support","Summoner","Control"]:return "Unknown hero role."
 if str(h.name).strip_edges().is_empty() or h.name.length()>60:return "Give your hero a name of 1–60 characters."
 if h.species.length()>100 or p.author.length()>100:return "Species and author must be at most 100 characters."
 if not number(h.get("max_health"),70,200) or not number(h.get("speed"),100,300):return "Health or movement outside workshop limits."
 if not PASSIVES.has(h.get("passive")):return "Unknown passive."
 for kind in KINDS:
  var error=validate_attack(h.get(kind))
  if not error.is_empty():return kind+": "+error
 if not h.get("art") is Dictionary:return "Invalid artwork."
 for pose in h.art:
  if not pose in ["idle","walk1","walk2","attack"] or not short_text(h.art[pose],180000):return "Invalid artwork slot or size."
  var bytes=Marshalls.base64_to_raw(h.art[pose]);var image=Image.new()
  var png_issue=png_error(bytes)
  if not png_issue.is_empty():return png_issue
  if bytes.size()>131072 or image.load_png_from_buffer(bytes)!=OK:return "Artwork must be a PNG under 128 KB."
  if image.get_width()>256 or image.get_height()>256:return "Artwork must be at most 256 × 256 pixels."
 var forms=h.get("alternate_forms",{})
 if not forms is Dictionary or forms.size()>4:return "Use up to four alternate forms."
 for id in forms:
  if not short_text(id,30) or not forms[id] is Dictionary or not short_text(forms[id].get("name"),60) or not short_text(forms[id].get("image"),180000):return "Invalid alternate form."
  var image=Image.new();var bytes=Marshalls.base64_to_raw(forms[id].image)
  if not png_error(bytes).is_empty() or image.load_png_from_buffer(bytes)!=OK:return "Alternate forms need a valid PNG."
 for slot in KINDS:
  if not str(h[slot].get("form_id","")).is_empty() and not forms.has(h[slot].form_id):return "Select an existing alternate form for "+slot+"."
 var techniques:Variant=p.get("techniques")
 if not techniques is Array or techniques.size()!=2:return "Two mastery alternatives are required."
 for technique in techniques:
  if not technique is Dictionary or not short_text(technique.get("name"),60) or not technique.get("slot") in KINDS:return "Invalid mastery alternative."
  for key in technique:
   if not key in ["name","slot","attack"]:return "Unsupported mastery field: "+str(key)
  var error=validate_attack(technique.get("attack"))
  if not error.is_empty():return "Mastery: "+error
  if not str(technique.attack.get("form_id","")).is_empty() and not forms.has(technique.attack.form_id):return "Mastery uses a missing alternate form."
 if techniques[0].slot==techniques[1].slot:return "Mastery alternatives must change different ability slots."
 if not p.get("notes") is Dictionary:return "Missing test notes."
 for key in ["hypothesis","method","observations","next_change"]:
  if not short_text(p.notes.get(key),3000):return "Invalid test note."
 for key in p.notes:
  if not key in ["hypothesis","method","observations","next_change"]:return "Unsupported test note: "+str(key)
 if not p.get("reports") is Array or p.reports.size()>20:return "Keep at most 20 reports per project."
 for report in p.reports:
  if not report is Dictionary or JSON.stringify(report).length()>40000:return "Invalid test report."
  if report.get("format")!="fx-crossroads-test-report" or not report.get("notes") is Dictionary:return "Invalid test report format."
 # Versioned educational programs use only the Studio command whitelist.
 if p.get("code_lab")!={"enabled":false,"api":"workshop-1"}:return "Use bounded Ability Lab instructions inside an ability."
 if h.has("passive_aura") and not h.passive_aura is bool:return "Invalid aura toggle."
 if h.has("passive_radius") and not number(h.passive_radius,40,180):return "Aura radius must be 40–180."
 if p.has("forced_balance") and not p.forced_balance is bool:return "Invalid balance toggle."
 if h.has("defence") and not number(h.defence,0,.25):return "Defence must be 0–25%."
 if h.has("balance_tradeoff") and not h.balance_tradeoff in ["speed","defence"]:return "Unknown health trade-off."
 var allowed=["format","schema_version","ability_api","project_id","revision","author","concept","hero","techniques","notes","reports","code_lab","forced_balance"]
 for key in p:
  if not key in allowed:return "Unsupported project field: "+str(key)
 var hero_fields=["name","role","species","lore","max_health","speed","passive","art","primary","secondary","special","passive_aura","passive_radius","defence","balance_tradeoff","alternate_forms"]
 for key in h:
  if not key in hero_fields:return "Unsupported hero field: "+str(key)
 return ""
static func warnings(p:Dictionary)->Array[String]:
 var result:Array[String]=[]
 for kind in KINDS:
  var a:Dictionary=p.hero[kind]
  var hits:float=float(a.count) if a.style in ["spread","chain","summon"] else 1.0
  var rate=float(a.damage)*hits/float(a.cooldown)
  if a.style=="flame":rate=float(a.damage)
  elif a.style=="summon":rate=float(a.damage)*hits
  elif a.style=="slow_aura":rate=float(a.damage)*.5
  if rate>55:result.append(kind.capitalize()+": high potential damage per second. Consider less damage, shorter range or a longer cooldown.")
  if a.status=="stun" and float(a.status_duration)>=float(a.cooldown):result.append(kind.capitalize()+": stun can repeat before it ends. Try a longer cooldown.")
  if a.style=="heal_zone" and float(a.heal)*2>20:result.append(kind.capitalize()+": strong sustained healing. Test the recovery against incoming damage.")
 if p.hero.art.size()<4:result.append("Some artwork poses use the workshop placeholder. Add idle, two walk frames, and attack for the complete animation.")
 return result
