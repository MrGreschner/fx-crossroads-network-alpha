extends RefCounted
## One-time, selective course migration. Clears only Sunfield speed results.
const REVISION=257
static func apply(l:Node,s:Dictionary)->void:
 if int(s.routes.solo.get("sunfield_revision",0))==REVISION and int(s.routes.coop.get("sunfield_revision",0))==REVISION:return
 for key in ["times_all","times_week"]:s[key].erase("sunfield")
 for route in ["solo","coop"]:
  s.routes[route].all.erase("sunfield");s.routes[route].week.erase("sunfield");s.routes[route].sunfield_revision=REVISION
 for key in s.hero_records.keys():
  if str(key).begins_with("time") and str(key).ends_with(":sunfield"):s.hero_records.erase(key)
 if l.community!=null:
  for n in range(l.community.claims.size()-1,-1,-1):
   var claim=l.community.claims[n]
   if str(claim.get("kind",""))=="time"and str(claim.get("realm",""))=="sunfield":l.community.claims.remove_at(n)
 var store=preload("res://scripts/profile_store.gd");var local=l.game.get("profile")
 if local is Dictionary:clear_local(local)
 var saved=store.read("user://crossroads_profile.json")
 if not saved.is_empty():clear_local(saved);store.write("user://crossroads_profile.json",saved)
 var coop=store.read("user://fx_coop_sunfield.json")
 if not coop.is_empty():coop.best=0;coop.layout_revision=REVISION;store.write("user://fx_coop_sunfield.json",coop)
static func clear_local(profile:Dictionary)->void:
 var records=profile.get("records",{})
 if not records is Dictionary:return
 for key in records.keys():
  if "sunfield"in str(key).split(":"):records.erase(key)
