extends RefCounted
## One catalogue for lobby, authority admission and realm coverage tests.
static func ids()->Array:
 var manifest=JSON.parse_string(FileAccess.get_file_as_string("res://content/manifest.json"))
 return manifest.get("regions",[])+manifest.get("quest_regions",[])
static func available(legacy:Node)->Array:
 var result=[]
 for id in ids():
  if preload("res://scripts/realm_access.gd").unlocked(legacy,str(id)):result.append(id)
 var progress=preload("res://network/expedition_profile.gd").progress(legacy.game)
 if progress.between_unlocked():result.append("between")
 if progress.state().attuned or progress.blocked():result.append("overcharge")
 return result
static func lobby_ids()->Array:return ids()+["between","overcharge"]
static func saved_quests()->Dictionary:
 var stored=preload("res://scripts/profile_store.gd").read("user://fx_quests_wayfarer_party.json")
 return stored.get("states",{}) if stored is Dictionary else {}
