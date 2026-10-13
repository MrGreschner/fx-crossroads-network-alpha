extends RefCounted
## Distinct legitimate wins; repeat/practice clears never bypass the journey.
const OPEN=["grove","quarry"]
const BEGINNER=["grove","quarry","honeyglass","elementary"]
const INTRO_MODERATE=["sunfield","ice"]
const MEDIUM=["folded_coast","moonburrow","moonveil","petalbrook","middle_school"]
const CHALLENGING=["space","zombie"]
const HARD=["lantern_marsh","silverfall","confluence","brasslock","clockwork_orchard","high_school","neon_crucible"]
const EXPERT=["astral_rift","chimevault","ebonwake"]
const EXTREME=["shattered_oath"]
static func cleared(legacy:Node,id:String)->bool:
 return legacy.realm_clears(id)>0 or id in legacy.data.get("tasks",{}).get("realms",[])
static func count(legacy:Node,ids:Array)->int:
 var n=0
 for id in ids:
  if cleared(legacy,str(id)):n+=1
 return n
static func unrestricted(legacy:Node)->bool:
 return bool(legacy.data.get("teacher",false)) or preload("res://scripts/profile_store.gd").testing()
static func unlocked(legacy:Node,id:String)->bool:
 if unrestricted(legacy) or id in OPEN or cleared(legacy,id):return true
 if id in ["honeyglass","elementary"]:return count(legacy,OPEN)>=1
 if id in INTRO_MODERATE:return count(legacy,["honeyglass","elementary"])>=1
 if id in MEDIUM:return count(legacy,INTRO_MODERATE)>=1
 if id in CHALLENGING:return count(legacy,MEDIUM)>=3
 if id in HARD:return count(legacy,CHALLENGING)>=1
 if id in EXPERT:return count(legacy,HARD)>=4
 if id in EXTREME:return count(legacy,EXPERT)>=2
 return true
static func reason(legacy:Node,id:String)->String:
 if unlocked(legacy,id):return ""
 if id in ["honeyglass","elementary"]:return "Clear Whispering Grove OR Ember Quarry • %d / 1" % count(legacy,OPEN)
 if id in INTRO_MODERATE:return "Clear Honeyglass Gardens OR Firstbell Elementary • %d / 1" % count(legacy,["honeyglass","elementary"])
 if id in MEDIUM:return "Clear Sunfield Expanse OR Frostbound Rink • %d / 1" % count(legacy,INTRO_MODERATE)
 if id in CHALLENGING:return "Clear 3 different medium realms • %d / 3" % count(legacy,MEDIUM)
 if id in HARD:return "Clear 1 challenging realm • %d / 1" % count(legacy,CHALLENGING)
 if id in EXPERT:return "Clear 4 different hard realms • %d / 4" % count(legacy,HARD)
 return "Clear 2 different expert realms • %d / 2" % count(legacy,EXPERT)
static func hint(legacy:Node,id:String)->String:return reason(legacy,id)
