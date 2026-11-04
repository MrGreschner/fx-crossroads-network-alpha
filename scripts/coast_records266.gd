extends RefCounted
## One-time, selective course migration. Clears only Folded Coast speed results.
const REVISION=266
static func apply(l:Node,s:Dictionary)->void:
 if int(s.routes.solo.get("folded_coast_revision",0))==REVISION and int(s.routes.coop.get("folded_coast_revision",0))==REVISION:return
 for key in ["times_all","times_week"]:s[key].erase("folded_coast")
 for route in ["solo","coop"]:
  s.routes[route].all.erase("folded_coast");s.routes[route].week.erase("folded_coast");s.routes[route].folded_coast_revision=REVISION
 for key in s.hero_records.keys():
  if str(key).begins_with("time") and str(key).ends_with(":folded_coast"):s.hero_records.erase(key)
 if l.community!=null:
  for n in range(l.community.claims.size()-1,-1,-1):
   var claim=l.community.claims[n]
   if str(claim.get("kind",""))=="time"and str(claim.get("realm",""))=="folded_coast":l.community.claims.remove_at(n)
 var store=preload("res://scripts/profile_store.gd");var local=l.game.get("profile")
 if local is Dictionary:clear_local(local)
 var saved=store.read("user://crossroads_profile.json")
 if not saved.is_empty():clear_local(saved);store.write("user://crossroads_profile.json",saved)
 var coop=store.read("user://fx_coop_folded_coast.json")
 if not coop.is_empty():coop.best=0;coop.layout_revision=REVISION;store.write("user://fx_coop_folded_coast.json",coop)
static func clear_local(profile:Dictionary)->void:
 var records=profile.get("records",{})
 if not records is Dictionary:return
 for key in records.keys():
  if "folded_coast"in str(key).split(":"):records.erase(key)
