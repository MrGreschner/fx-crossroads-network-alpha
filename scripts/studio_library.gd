extends RefCounted
const PATH="user://fx_studio_library.json"
const Project=preload("res://scripts/workshop_project.gd")
static func load_data()->Dictionary:
 var result={"heroes":{},"abilities":{},"enemies":{},"behaviors":{},"objects":{},"realms":{},"cycle":preload("res://scripts/studio_cycle.gd").fresh()}
 var parsed=preload("res://scripts/profile_store.gd").read(PATH,func(v:Dictionary)->bool:return validate(v).is_empty())
 if not parsed.is_empty():result.merge(parsed,true)
 return result
static func validate(value:Variant)->String:
 if not value is Dictionary or not value.get("heroes") is Dictionary or not value.get("abilities") is Dictionary:return "Invalid Studio library."
 for key in ["enemies","behaviors","objects","realms"]:
  if value.has(key) and not value[key] is Dictionary:return "Invalid Studio "+key+" collection."
 if value.heroes.size()>20 or value.abilities.size()>40 or value.get("enemies",{}).size()>20 or value.get("behaviors",{}).size()>40:return "Keep up to 20 heroes/enemies and 40 abilities/behaviours per collection."
 if value.has("cycle") and not preload("res://scripts/studio_cycle.gd").valid(value.cycle):return "Invalid creation journey / Showcase data."
 for id in value.heroes:
  if not id is String or id.length()>32:return "Invalid custom hero identifier."
  var issue=Project.validate(value.heroes[id])
  if not issue.is_empty():return issue
 for id in value.abilities:
  if not id is String or id.length()>100:return "Invalid custom ability identifier."
  var issue=Project.validate_attack(value.abilities[id])
  if not issue.is_empty():return issue
 for key in value.get("enemies",{}):
  if not key is String or key.length()>100:return "Invalid enemy identifier."
  var issue=preload("res://scripts/studio_enemy_project.gd").validate(value.enemies[key])
  if not issue.is_empty():return issue
 for key in value.get("behaviors",{}):
  if not key is String or key.length()>100:return "Invalid behaviour identifier."
  var issue=preload("res://scripts/studio_behavior.gd").validate(value.behaviors[key])
  if not issue.is_empty():return issue
 for collection in ["objects","realms"]:
  if value.get(collection,{}).size()>20:return "Keep up to 20 saved "+collection+"."
  for id in value.get(collection,{}):
   if not Project.short_text(id,100):return "Invalid world project identifier."
   var issue=preload("res://scripts/studio_world_project.gd").validate("object" if collection=="objects" else "realm",value[collection][id])
   if not issue.is_empty():return issue
 return ""
static func save_data(value:Dictionary)->String:
 var issue=validate(value)
 if not issue.is_empty():return issue
 var encoded=JSON.stringify(value)
 if encoded.to_utf8_buffer().size()>16777216:return "Studio library exceeds 16 MB. Export and remove older projects."
 var error=preload("res://scripts/profile_store.gd").write(PATH,value,encoded,func(v:Dictionary)->bool:return validate(v).is_empty())
 return "" if error==OK else "Could not save. Your last-good backup is retained; download this project."
static func recovery_message()->String:
 var parser=JSON.new()
 if FileAccess.file_exists(PATH) and parser.parse(FileAccess.get_file_as_string(PATH))==OK and validate(parser.data).is_empty():return ""
 if FileAccess.file_exists(PATH+".bak") and parser.parse(FileAccess.get_file_as_string(PATH+".bak"))==OK and validate(parser.data).is_empty():return "Recovered the last-good Studio backup. Download your profile before continuing."
 return ""
static func hero_id(p:Dictionary)->String:return "custom_"+str(p.project_id).sha256_text().left(20)
static func add_hero(p:Dictionary)->String:
 var issue=Project.validate(p)
 if not issue.is_empty():return issue
 issue=preload("res://scripts/community_validation.gd").art_issue(p)
 if not issue.is_empty():return issue
 var data=load_data();var id=hero_id(p)
 if data.heroes.get(id)==p:return ""
 data.heroes[id]=p.duplicate(true);preload("res://scripts/studio_cycle.gd").record(data,"hero",p);return save_data(data)
static func add_ability(a:Dictionary)->String:
 var issue=Project.validate_attack(a)
 if not issue.is_empty():return issue
 var data=load_data();data.abilities[str(a.name)]=a.duplicate(true);preload("res://scripts/studio_cycle.gd").record(data,"ability",a,true);return save_data(data)
static func install(game:Node)->void:
 var service=game.get_tree().root.get_node_or_null("FXCommunityHeroes")
 if service!=null:service.install(game)
 var data=load_data()
 # A pre-update local draft is playable too; no re-import or manual publishing.
 var draft=preload("res://scripts/profile_store.gd").read(Project.PATH,func(v:Dictionary)->bool:return Project.validate(v).is_empty())
 if not draft.is_empty():
  var draft_id=hero_id(draft)
  if data.heroes.get(draft_id)!=draft:
   data.heroes[draft_id]=draft
   save_data(data)
 for id in game.characters.keys():
  if str(id).begins_with("custom_"):
   game.characters.erase(id)
   if not data.heroes.has(id):
    for pose in ["idle","walk1","walk2","attack"]:game.art.erase(str(id)+"_"+pose)
    var tokens:Dictionary=game.get_meta("studio_art_tokens",{});tokens.erase(id);game.set_meta("studio_art_tokens",tokens)
 for id in data.heroes:
  var p:Dictionary=data.heroes[id]
  if not preload("res://scripts/community_validation.gd").art_issue(p).is_empty():continue
  var h=p.hero.duplicate(true)
  h.id=id;h.sprite=id;h.cost=0;h.passive_effect="studio";h.studio_project=p;h.studio_checked=preload("res://scripts/studio_balance.gd").hero_checked(p);h.studio_token=Project.fingerprint(p)
  h.passive=Project.PASSIVES.get(p.hero.passive,"Custom passive")
  h.mastery={"technique":{"name":p.techniques[0].name,"ability":p.techniques[0].slot,"description":"Studio alternative • equip while testing."},"final_technique":{"name":p.techniques[1].name,"ability":p.techniques[1].slot,"description":"Studio alternative • equip while testing."}}
  game.characters[id]=h
  var art_tokens:Dictionary=game.get_meta("studio_art_tokens",{})
  var art_hash=JSON.stringify(p.hero.art).sha256_text()
  if art_tokens.get(id,"")==art_hash:continue
  art_tokens[id]=art_hash;game.set_meta("studio_art_tokens",art_tokens)
  for pose in p.hero.art:
   var image=Image.new();image.load_png_from_buffer(Marshalls.base64_to_raw(p.hero.art[pose]));game.art[id+"_"+pose]=ImageTexture.create_from_image(image)

static func add_enemy(value:Dictionary)->String:
 var issue=preload("res://scripts/studio_enemy_project.gd").validate(value)
 if not issue.is_empty():return issue
 var data=load_data();data.enemies[value.id]=value.duplicate(true);preload("res://scripts/studio_cycle.gd").record(data,"enemy",value,true);return save_data(data)
static func add_behavior(value:Dictionary)->String:
 var issue=preload("res://scripts/studio_behavior.gd").validate(value)
 if not issue.is_empty():return issue
 var data=load_data();data.behaviors[value.name]=value.duplicate(true);preload("res://scripts/studio_cycle.gd").record(data,"behavior",value,true);return save_data(data)

static func add_world(kind:String,value:Dictionary)->String:
 var issue=preload("res://scripts/studio_world_project.gd").validate(kind,value)
 if not issue.is_empty():return issue
 var data=load_data();data["objects" if kind=="object" else "realms"][value.id]=value.duplicate(true);preload("res://scripts/studio_cycle.gd").record(data,kind,value,true);return save_data(data)
