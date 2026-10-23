extends RefCounted
## Distinct legitimate wins; repeat/practice clears never bypass the journey.
const OPEN=["grove"]
const BEGINNER=["grove","quarry","honeyglass","elementary"]
const INTRO_MODERATE=["sunfield","ice"]
const MEDIUM=["folded_coast","moonburrow","moonveil","petalbrook","middle_school","clockwork_orchard"]
const CHALLENGING=["space","zombie"]
const HARD=["lantern_marsh","silverfall","confluence","brasslock","high_school","neon_crucible","cinderheart"]
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
 if id in ["quarry","honeyglass"]:return cleared(legacy,"grove")
 if id=="elementary":return count(legacy,["quarry","honeyglass"])>=1
 if id in INTRO_MODERATE:return cleared(legacy,"elementary")
 if id=="middle_school":return count(legacy,MEDIUM.filter(func(v):return v!="middle_school"))>=3
 if id=="high_school":return count(legacy,HARD.filter(func(v):return v!="high_school"))>=3
 if id in MEDIUM:return count(legacy,INTRO_MODERATE)>=1
 if id in CHALLENGING:return cleared(legacy,"middle_school")
 if id in HARD:return count(legacy,CHALLENGING)>=1
 if id in EXPERT:return count(legacy,HARD)>=4
 if id in EXTREME:return count(legacy,EXPERT)>=2
 return true
static func reason(legacy:Node,id:String)->String:
 if unlocked(legacy,id):return ""
 if id in ["quarry","honeyglass"]:return "Clear Whispering Grove first"
 if id=="elementary":return "Clear Ember Quarry OR Honeyglass Gardens • %d / 1" % count(legacy,["quarry","honeyglass"])
 if id in INTRO_MODERATE:return "Clear Firstbell Elementary first"
 if id=="middle_school":return "Clear 3 different medium realms • %d / 3" % count(legacy,MEDIUM.filter(func(v):return v!="middle_school"))
 if id=="high_school":return "Clear 3 different hard realms • %d / 3" % count(legacy,HARD.filter(func(v):return v!="high_school"))
 if id in MEDIUM:return "Clear Sunfield Expanse OR Frostbound Rink • %d / 1" % count(legacy,INTRO_MODERATE)
 if id in CHALLENGING:return "Clear Crossbell Middle School first"
 if id in HARD:return "Clear 1 challenging realm • %d / 1" % count(legacy,CHALLENGING)
 if id in EXPERT:return "Clear 4 different hard realms • %d / 4" % count(legacy,HARD)
 return "Clear 2 different expert realms • %d / 2" % count(legacy,EXPERT)
static func hint(legacy:Node,id:String)->String:return reason(legacy,id)
