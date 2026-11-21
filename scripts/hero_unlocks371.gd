extends RefCounted
## Earned ownership only. V4 retires all pre-launch trial-based grants.
const KEY="hero_ownership"
const EPOCH=4
const ACTIVITY_IDS=["aurel","ripplejaw","mosaic","teacher","hearth_herald","navigator","cindervane"]
static func managed()->Array:return CHAMPIONS.keys()+ACTIVITY_IDS+load("res://scripts/hero_journeys373.gd").ids()
const CHAMPIONS={"briar": "grove", "recess": "elementary", "sunflower": "sunfield", "snowman": "ice", "tidewright": "confluence", "cantor": "confluence", "lockjaw": "confluence", "echo_dancer": "folded_coast", "bracken": "moonburrow", "elara": "moonveil", "kage": "moonveil", "pippa": "petalbrook", "velvetwing": "petalbrook", "chronicle": "clockwork_orchard", "apiary": "clockwork_orchard", "medic": "zombie", "tova": "lantern_marsh", "hazel_hex": "lantern_marsh", "ferryman": "silverfall", "cobbleclaw": "silverfall", "nera": "brasslock", "robot": "neon_crucible", "snail": "cinderheart", "vesper": "astral_rift", "veyra": "ebonwake"}
const PLANS={"briar": [210, 1, 115, 330, "Watch the bouncing acorn; step clear of the crossing before closing in."], "recess": [235, -1, 330, 350, "Move around the whistle waves and punish the patrol recovery."], "sunflower": [245, 1, 320, 600, "Avoid the planted bloom; sidestep the warned beam."], "snowman": [200, -1, 190, 450, "Keep out of the chilling aura; dodge across the rolling snow."], "tidewright": [270, 1, 370, 420, "Leave the sluice pool and find an opening between water needles."], "cantor": [295, -1, 370, 420, "Move out of the relay field before the thunder lands."], "lockjaw": [58, 1, 112, 100, "Bait the clamp, then punish the missed bite. Damage can force a release."], "echo_dancer": [68, -1, 360, 115, "Read the real dancer through the feint and step away from the encore."], "bracken": [135, 1, 260, 275, "Draw Bracken away from the planted mines; watch the blink landing."], "elara": [275, -1, 210, 330, "Cross between the split lances and leave the ground sequence."], "kage": [74, 1, 400, 195, "Make the thrown blades miss before entering twin-fang range."], "pippa": [230, -1, 160, 185, "Identify the fern double and keep clear of the maypole."], "velvetwing": [275, 1, 250, 355, "Watch the tripline endpoints; do not fight inside the loom."], "chronicle": [280, -1, 540, 250, "Force the rewind before committing; step out of the time bubble."], "apiary": [255, 1, 330, 335, "Use the needle charge as your warning; move away from the hive."], "medic": [65, -1, 350, 185, "Keep pressure on the medic, then leave the healing zone."], "tova": [75, 1, 125, 150, "Watch the stepping rhythm and draw Tova away from the haven."], "hazel_hex": [305, -1, 550, 235, "Avoid the poison impact and track where Hazel lands after flying."], "ferryman": [68, 1, 375, 240, "Dodge the charged oar, then follow the returning stone."], "cobbleclaw": [67, -1, 110, 275, "Wait out the shell guard and move away from the crushing landing."], "nera": [275, 1, 350, 630, "Do not stand on the latchline or the tram route."], "robot": [82, -1, 430, 160, "Step out of the piston reach; spread away from the missile volley."], "snail": [105, 1, 445, 230, "Circle the magma breath and avoid the shell landing."], "vesper": [170, -1, 295, 195, "Dodge both passes of the disc and bait the defensive block."], "veyra": [300, 1, 235, 415, "Avoid the snare and change your rhythm against the soul ledger."], "dawnblade": [70, 1, 250, 220, "Watch Mara\u2019s recovery before committing to the close-range exchange."], "rune_duelist": [90, -1, 220, 280, "Respect the counter opening. Bait a swing, then strike during recovery."], "anjali": [290, 1, 360, 420, "Dodge across the charged arrow fan and keep track of her planted return branch."]}
static func valid(value:Variant)->bool:
 if not value is Dictionary or int(value.get("version",0)) not in [1,2,3,4]:return false
 if value.has("migration_notice") and not value.migration_notice is bool:return false
 var owned=value.get("owned",[])
 if not owned is Array or owned.size()>managed().size():return false
 var seen=[]
 for id in owned:
  if not id is String or id not in managed() or id in seen:return false
  seen.append(id)
 return true
static func state(l:Node)->Dictionary:
 if not l.data.has(KEY):l.data[KEY]={"version":EPOCH,"owned":[]}
 var s:Dictionary=l.data[KEY]
 if int(s.version)<EPOCH:
  # A pre-launch ownership reset, not a profile/stat reset. Old imports migrate too.
  # Previous versions mixed earned and tried grants, so none can prove a duel win.
  s={"version":EPOCH,"owned":[],"migration_notice":true};l.data[KEY]=s
 return s
static func announce(l:Node)->void:
 var s=state(l)
 if not bool(s.get("migration_notice",false)):return
 load("res://scripts/record_toast.gd").show(l.game,"HERO UNLOCK UPDATE • Earn your favourites. Your other progress is safe.")
 s.erase("migration_notice");l.save()
static func owned(l:Node,id:String)->bool:
 return id not in managed() or preload("res://scripts/realm_access.gd").unrestricted(l) or id in state(l).owned
static func ready(l:Node,id:String)->bool:
 if load("res://scripts/hero_journeys373.gd").catalog().has(id):return load("res://scripts/hero_journeys373.gd").duel_ready(l,id)
 return CHAMPIONS.has(id) and preload("res://scripts/realm_access.gd").cleared(l,str(CHAMPIONS[id]))
static func claim(l:Node)->Array:return state(l).owned.duplicate()
static func clean_claim(value:Variant)->Array:
 if not value is Array or value.size()>managed().size():return []
 var result=[]
 for id in value:
  if id is String and id in managed() and id not in result:result.append(id)
 return result
static func allowed_claim(id:String,value:Variant)->bool:return id not in managed() or id in clean_claim(value)
static func hint(g:Node,id:String)->String:
 if owned(g.legacy,id):return "Owned"
 if id in ACTIVITY_IDS:return str(load("res://scripts/hero_goals372.gd").progress(g.legacy,id).text)+" • Hero Goals"
 if load("res://scripts/hero_journeys373.gd").catalog().has(id):return load("res://scripts/hero_journeys373.gd").progress(g.legacy,id)+" • Hero Journeys"
 var realm=str(CHAMPIONS[id]);var name=str(g.realms.get(realm,{}).get("name",realm)) if g.get("realms") is Dictionary else realm
 return "Duel ready • Challenge Hall" if ready(g.legacy,id) else "Clear %s, then win this hero’s duel in the Challenge Hall." % name
static func award(l:Node,id:String)->bool:
 if not ready(l,id) or preload("res://scripts/realm_access.gd").unrestricted(l):return false
 if not CHAMPIONS.has(id):return load("res://scripts/hero_journeys373.gd").award(l,id)
 var s=state(l)
 if id in s.owned:return false
 s.owned.append(id);l.save();return true
static func open_hall(g:Node)->void:
 g.hero_hall.close(false);g.lodges.challenge_page=preload("res://scripts/lodge_catalog.gd").TYPES.size()+1;g.lodges.open("challenge")
static func draw_menu(g:Node,body:Node)->void:
 var ui=g.lodges
 ui.label(body,"REALM CHAMPIONS • %d / %d owned" % [state(g.legacy).owned.filter(func(hero):return CHAMPIONS.has(hero)).size(),CHAMPIONS.size()],23)
 ui.label(body,"Clear a champion’s home realm, then win their 1v1 to unlock them permanently. Level 10 • base kits • no equipment • first knockout wins • free retries.",16)
 ui.label(body,"Fighting as: "+str(g.characters[g.selected_character].name)+" • Change your hero in the Character Hall.",16)
 for id in CHAMPIONS:
  var h:Dictionary=g.characters[id];var home=str(g.realms.get(CHAMPIONS[id],{}).get("name",CHAMPIONS[id]))
  var earned=owned(g.legacy,id);var eligible=ready(g.legacy,id)
  var box=ui.card(body,str(h.name),home+" • "+("Owned" if earned else "Duel ready" if eligible else "Clear home realm first"))
  ui.label(box,str(PLANS[id][4]),15)
  var b=ui.button(box,"Practice rematch" if earned and eligible else "Challenge champion" if eligible else "Locked • "+home,launch.bind(g,str(id)))
  b.disabled=not eligible
  if eligible:preload("res://scripts/studio_ui.gd").accent(b)
static func launch(g:Node,id:String)->void:
 if not ready(g.legacy,id) or not owned(g.legacy,str(g.selected_character)):return
 if not preload("res://scripts/record_eligibility.gd").hero_allowed(g,str(g.selected_character)):
  g.lodges.notice="Choose an official or approved community hero for champion duels.";g.lodges.open("challenge");return
 g.save_profile();g.legacy.save();g.get_tree().root.set_meta("fx_champion_trial",{"champion":id,"hero":str(g.selected_character)})
 g.get_tree().change_scene_to_file("res://scenes/champion_duel371.tscn")
