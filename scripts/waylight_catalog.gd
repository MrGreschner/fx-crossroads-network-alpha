extends RefCounted
const ROTATION=["grove","quarry","ice","honeyglass","sunfield","silverfall","clockwork_orchard","astral_rift"]
const COSTS=[100,200,300]
const CHANCES=[.10,.15,.20]
const NAMES={"grove":"Whispering Grove","quarry":"Ember Quarry","ice":"Frostbound Rink","honeyglass":"Honeyglass Gardens","sunfield":"Sunfield Expanse","silverfall":"Silverfall Reach","clockwork_orchard":"The Clockwork Orchard","astral_rift":"Astral Rift"}
const FAMILIES={"grove":["thornroot","grove_seed"],"quarry":["emberstep","quarry_heart"],"ice":["frost_lens","river_pearl"],"honeyglass":["nectar_vial","prism_comb"],"sunfield":["sunseed","sunward"],"silverfall":["reed_oath","undertow_mark","tideheart"],"clockwork_orchard":["stormfolio","clockwork_drive","secondhand_guard"],"astral_rift":["astral_echo","gravity_anchor","eventide_seed"]}
const RELICS={
 "reed_oath":{"name":"Ferryman\u2019s Oath","color":"#80d8ce","effect":"Dodge grants a 6\u20139 HP shield for 4s (10s cooldown). Reed of Silverfall also restores 3 HP when it triggers. All heroes can use it.","range":[6,9],"kind":"oath"},
 "undertow_mark":{"name":"Undertow Seal","color":"#93bfef","effect":"A damaging hit slows its target by 25% for 0.8\u20131.1s. 7s cooldown.","range":[0.8,1.1],"kind":"tide"},
 "tideheart":{"name":"Tideheart Vessel","color":"#a9dfd1","effect":"Eating healing food empowers your next damaging hit within 4s by 8\u201312%. 10s cooldown.","range":[8,12],"kind":"vessel"},
 "stormfolio":{"name":"Stormscribe\u2019s Lost Folio","color":"#bfaff1","effect":"Every sixth damaging hit releases an 8\u201312 damage echo (6s cooldown). Stormscribe also arcs half that echo to up to two enemies within 130 units. Echoes cannot trigger relics. All heroes can use it.","range":[8,12],"kind":"folio"},
 "clockwork_drive":{"name":"Orchard Flywheel","color":"#d6b479","effect":"While above 80% health, your attacks deal 3\u20135% additional damage.","range":[3,5],"kind":"gear"},
 "secondhand_guard":{"name":"Secondhand Aegis","color":"#9abfd5","effect":"Reduce the first damaging hit after 8 seconds without incoming damage by 10\u201314%. Each incoming hit restarts that respite.","range":[10,14],"kind":"clock"},
 "astral_echo":{"name":"Echo of the Rift","color":"#c6a4ec","effect":"A damaging hit releases a 6\u20139 damage echo against that target. 10s cooldown. Echoes cannot trigger relics.","range":[6,9],"kind":"rift"},
 "gravity_anchor":{"name":"Gravity Anchor","color":"#8fa9df","effect":"After dodging, your next hit within 4s slows its target by 40% for 0.8\u20131.2s. 10s cooldown.","range":[0.8,1.2],"kind":"anchor"},
 "eventide_seed":{"name":"Eventide Heart","color":"#deabd9","effect":"Defeating an enemy restores 3\u20135 HP. 12s cooldown.","range":[3,5],"kind":"starheart"},
 "nectar_vial":{"name":"Mellifera's Nectar Vial","color":"#edd09b","effect":"Eating healing food restores an extra 3–5 HP. 8s cooldown.","range":[3,5],"kind":"vial"},
 "prism_comb":{"name":"Prismatic Honeycomb","color":"#b9dce4","effect":"After dodging, your next hit within 4s deals 6–9% extra damage. 8s cooldown.","range":[6,9],"kind":"comb"},
 "sunseed":{"name":"Solstice Sunseed","color":"#e6c97e","effect":"A kill grants a 4–6 HP shield for 4s. 10s cooldown; shields do not stack.","range":[4,6],"kind":"sun"},
 "sunward":{"name":"Sunward Brooch","color":"#e8ba83","effect":"While above 80% health, reduce incoming damage by 4–6%.","range":[4,6],"kind":"sun"},
 "thornroot":{"name":"Thornroot Charm","color":"#93c98e","effect":"After taking damage, your next hit within 5s deals 8–12% extra damage. 6s cooldown. Works with every hero.","range":[8,12],"kind":"thorns"},
 "grove_seed":{"name":"Rootwarden Seed","color":"#d0b97a","effect":"A kill restores 2–4 HP, at most once every 8 seconds.","range":[2,4],"kind":"seed"},
 "emberstep":{"name":"Emberstep Stone","color":"#f0a270","effect":"Dodging leaves embers for 3s, dealing 3–5 damage per second. 6s cooldown.","range":[3,5],"kind":"fire"},
 "quarry_heart":{"name":"Quarry Heart","color":"#d2a4e0","effect":"Below 35% health, reduce incoming damage by 8–12%.","range":[8,12],"kind":"geode"},
 "frost_lens":{"name":"Frostglass Lens","color":"#a9d9f2","effect":"A hit slows its target by 20% for 0.8–1.2s. 6s cooldown.","range":[.8,1.2],"kind":"snow"},
 "river_pearl":{"name":"Riverkeeper Pearl","color":"#86d8cb","effect":"Eating healing food grants an 8–12 HP shield for 5 seconds.","range":[8,12],"kind":"pearl"},
 "stormglass":{"name":"Stormglass Heart","color":"#b4b4f3","effect":"Every fifth damaging hit releases an 8–12 damage lightning echo. 5s cooldown.","range":[8,12],"kind":"bolt"},
 "master_fisher":{"name":"Riverkeeper's Covenant","color":"#edd59a","effect":"Master fisher reward: eating healing food grants a 12 HP shield for 5 seconds. Shares its shield with Riverkeeper Pearl.","range":[12,12],"kind":"fish"}}
const STATS={"power":"Damage","vitality":"Max health","focus":"Cooldown reduction"}
static func day_number(utc:float)->int:return int(preload("res://scripts/town_weather.gd").context(utc).day)
static func featured(day:int)->String:return ROTATION[posmod(day,ROTATION.size())]
static func roll(realm:String,tier:int,seed_value:int)->Dictionary:
 var rng=RandomNumberGenerator.new();rng.seed=seed_value
 var choices=FAMILIES[realm].duplicate();choices.append("stormglass")
 var type=str(choices[rng.randi_range(0,choices.size()-1)]);var spec=RELICS[type]
 var strength=snappedf(lerpf(float(spec.range[0]),float(spec.range[1]),rng.randf_range((tier-1)*.18,1)),.01)
 return {"id":"r%d-%d" % [seed_value,rng.randi()],"type":type,"value":strength,"rank":0,"stat":["power","vitality","focus"][rng.randi_range(0,2)],"roll":rng.randi_range(1+(tier-1),4),"tier":tier,"source":realm}
static func conclave_roll(realm:String,tier:int,seed_value:int)->Dictionary:
 var item=roll(realm,tier,seed_value^549117);item.id="c"+str(item.id);item.rank=1;item["conclave"]=true;return item
static func display_name(item:Dictionary)->String:return ("Conclave-forged " if item.get("conclave",false) else "")+str(RELICS[item.type].name)
static func number(v:Variant,limit:float=1e9)->bool:return (v is int or v is float) and is_finite(float(v)) and float(v)>=0 and float(v)<=limit
static func valid_relic(v:Variant)->bool:
 if not v is Dictionary or v.get("type","") not in RELICS:return false
 if v.has("conclave") and not v.conclave is bool:return false
 if not v.get("id",null) is String or v.id.is_empty() or v.id.length()>80:return false
 if v.get("stat","") not in STATS or not number(v.get("roll"),4) or float(v.roll)<1:return false
 if not number(v.get("rank"),3) or not number(v.get("tier"),3) or float(v.tier)<1:return false
 for key in ["rank","tier","roll"]:
  if float(v[key])!=floorf(float(v[key])):return false
 var bounds=RELICS[v.type].range
 return number(v.get("value"),100) and float(v.value)>=float(bounds[0]) and float(v.value)<=float(bounds[1]) and str(v.get("source","")).length()<40
static func effective(v:Dictionary)->float:return float(v.value)*(1+.05*int(v.rank))
static func stat_bonus(v:Dictionary)->float:
 var base=float(v.roll)+int(v.rank)*.35
 return base*.005 if v.stat=="power" else base*.0075 if v.stat=="vitality" else base*.003
