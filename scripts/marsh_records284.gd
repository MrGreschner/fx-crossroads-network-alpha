extends RefCounted
## One-time, selective course migration. Clears only Lantern Marsh speed results.
const REVISION=284
static func apply(l:Node,s:Dictionary)->void:
 if int(s.routes.solo.get("lantern_marsh_revision",0))==REVISION and int(s.routes.coop.get("lantern_marsh_revision",0))==REVISION:return
 for key in ["times_all","times_week"]:s[key].erase("lantern_marsh")
 for route in ["solo","coop"]:
  s.routes[route].all.erase("lantern_marsh");s.routes[route].week.erase("lantern_marsh");s.routes[route].lantern_marsh_revision=REVISION
 for key in s.hero_records.keys():
  if str(key).begins_with("time") and str(key).ends_with(":lantern_marsh"):s.hero_records.erase(key)
 if l.community!=null:
  for n in range(l.community.claims.size()-1,-1,-1):
   var claim=l.community.claims[n]
   if str(claim.get("kind",""))=="time"and str(claim.get("realm",""))=="lantern_marsh":l.community.claims.remove_at(n)
 var store=preload("res://scripts/profile_store.gd");var local=l.game.get("profile")
 if local is Dictionary:clear_local(local)
 var saved=store.read("user://crossroads_profile.json")
 if not saved.is_empty():clear_local(saved);store.write("user://crossroads_profile.json",saved)
 var coop=store.read("user://fx_coop_lantern_marsh.json")
 if not coop.is_empty():coop.best=0;coop.layout_revision=REVISION;store.write("user://fx_coop_lantern_marsh.json",coop)
static func clear_local(profile:Dictionary)->void:
 var records=profile.get("records",{})
 if not records is Dictionary:return
 for key in records.keys():
  if "lantern_marsh"in str(key).split(":"):records.erase(key)
