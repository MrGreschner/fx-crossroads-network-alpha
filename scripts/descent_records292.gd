extends RefCounted
## Current boss-era depth records. Progression, unlocks and personal cards are retained.
const REVISION=292
static func apply(s:Dictionary,week:String)->void:
 if int(s.get("descent",{}).get("revision",0))!=REVISION:
  s.descent={"solo":0,"coop":0,"week":{"solo":0,"coop":0},"week_id":week,"revision":REVISION}
  for key in s.hero_records.keys():
   if str(key).begins_with("descent:"):s.hero_records.erase(key)
 if str(s.descent.week_id)!=week:
  s.descent.week={"solo":0,"coop":0};s.descent.week_id=week
  for key in s.hero_records.keys():
   if str(key).begins_with("descent:") and not str(key).begins_with("descent:all:"):s.hero_records.erase(key)
