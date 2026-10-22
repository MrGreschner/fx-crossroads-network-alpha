extends RefCounted
const INGREDIENTS={"worm":{"name":"Riverbank Worms","color":"#c99591"},"sunleaf":{"name":"Sunleaf Herb","color":"#97c578"},"mooncap":{"name":"Mooncap Mushroom","color":"#b59dcc"},"willow":{"name":"Willow Bark","color":"#c5a278"},"firefly":{"name":"Glowwing Insect","color":"#e8d68b"},"mint":{"name":"River Mint","color":"#73c3b6"},"petal":{"name":"Ember Petals","color":"#e7a16f"}}
const ROUTES={"meadow":{"name":"Sunlit Meadow","seconds":300,"finds":{"sunleaf":3,"petal":1},"seed":"forage_sun","chance":.18},"brook":{"name":"Willow Brook","seconds":600,"finds":{"mint":3,"willow":2,"worm":2},"seed":"forage_mint","chance":.20},"hollow":{"name":"Mooncap Hollow","seconds":900,"finds":{"mooncap":3,"firefly":2},"seed":"forage_moon","chance":.22},"lantern":{"name":"Lantern Thicket","seconds":1200,"finds":{"firefly":3,"petal":2,"sunleaf":1},"seed":"forage_glow","chance":.25}}
const RECIPES={"lodge_tonic":{"name":"Sunleaf Tonic","tier":1,"seconds":60,"needs":{"sunleaf":2,"mooncap":1},"effect":"heal","amount":30,"description":"Restore 30 HP. One use; uses the separate consumable slot."},"lodge_cleanse":{"name":"Clearwater Draught","tier":1,"seconds":90,"needs":{"mint":2,"willow":1},"effect":"cleanse","amount":0,"description":"Remove poison, burn and bleed. No immunity afterwards."},"lodge_stride":{"name":"Trailrunner Brew","tier":2,"seconds":120,"needs":{"mint":2,"firefly":1},"effect":"haste","amount":15,"duration":4,"description":"Move 15% faster for 4 seconds. One use."},"lodge_guard":{"name":"Barkskin Phial","tier":2,"seconds":150,"needs":{"willow":3,"sunleaf":1},"effect":"lodge_guard","amount":15,"duration":4,"description":"Gain 15% damage reduction for 4 seconds. Does not stack with another Barkskin."},"lodge_restore":{"name":"Mooncap Restorative","tier":3,"seconds":180,"needs":{"mooncap":3,"petal":2,"firefly":1},"effect":"heal","amount":45,"description":"Restore 45 HP. One use; cannot revive."},"lodge_river":{"name":"River Mint Remedy","tier":1,"seconds":75,"needs":{"mint":2,"sunleaf":1},"fish":"river_sprat","effect":"heal","amount":35,"description":"Restore 35 HP. Uses one ordinary kept River Sprat and gathered herbs. One use."},"lodge_silverfall":{"name":"Silverfall Clearwater","tier":1,"seconds":90,"needs":{"willow":1,"mint":2},"fish":"sprayfin_shiner","effect":"cleanse","amount":0,"description":"Remove poison, burn and bleed. Uses one ordinary kept Sprayfin Shiner. One use."},"lodge_coast":{"name":"Seafoam Sprint","tier":2,"seconds":135,"needs":{"sunleaf":2,"firefly":1},"fish":"seafoam_anchovy","effect":"haste","amount":20,"duration":5,"description":"Move 20% faster for 5 seconds. Uses one ordinary kept Seafoam Anchovy. One use."},"lodge_marsh":{"name":"Peatwater Guard","tier":2,"seconds":150,"needs":{"willow":3,"mooncap":1},"fish":"peatfin_minnow","effect":"lodge_guard","amount":20,"duration":5,"description":"Gain 20% damage reduction for 5 seconds. Uses one ordinary kept Peatfin Minnow. One use; guard does not stack."},"lodge_cavern":{"name":"Chalkspring Restorative","tier":3,"seconds":210,"needs":{"mooncap":3,"petal":2},"fish":"chalknose_gudgeon","effect":"heal","amount":50,"description":"Restore 50 HP. Uses one ordinary kept Chalknose Gudgeon. One use; cannot revive."},"lodge_oldwater":{"name":"Oldwater Recovery Broth","tier":1,"seconds":100,"needs":{"sunleaf":2,"mint":1},"fish":"v20_olive_lake_perch","effect":"heal","amount":38,"description":"Restore 38 HP. Uses one ordinary kept Olive Lake Perch. One use; cannot revive."},"lodge_bluebar":{"name":"Bluebar Restorative","tier":2,"seconds":175,"needs":{"mooncap":2,"petal":1},"fish":"v20_bluebar_trout","effect":"heal","amount":48,"description":"Restore 48 HP. Uses one ordinary kept Bluebar Trout. One use; cannot revive."},"lodge_saltwind":{"name":"Saltwind Elixir","tier":2,"seconds":160,"needs":{"mint":2,"firefly":1},"fish":"v20_copperback_mackerel","effect":"haste","amount":22,"duration":5,"description":"Move 22% faster for 5 seconds. Uses one ordinary kept Copperback Mackerel. One use."},"lodge_reefguard":{"name":"Reefshell Phial","tier":3,"seconds":210,"needs":{"willow":3,"mooncap":1},"fish":"v25_copper_reef_lobster","effect":"lodge_guard","amount":22,"duration":5,"description":"Gain 22% damage reduction for 5 seconds. Uses one ordinary kept Copper Reef Lobster. One use; guard does not stack."},"lodge_seaclear":{"name":"Seaglass Purifier","tier":1,"seconds":110,"needs":{"mint":2,"willow":1},"fish":"v20_blue_shore_squid","effect":"cleanse","amount":0,"description":"Remove poison, burn and bleed. Uses one ordinary kept Blue Shore Squid. One use; no lasting immunity."}}
const TYPES=[{"id":"stand","name":"Last Stand","text":"Survive for 120 seconds. No items or food; fight to keep space open.","recommend":"Defender / melee"},{"id":"boss","name":"Boss Rush","text":"Defeat three moving boss echoes. Restore 15% health between rounds.","recommend":"Any practiced hero"},{"id":"courier","name":"Protect the Courier","text":"Stay close to the ram courier to move it along the trail. Clear ambushers before they reach it.","recommend":"Control / support"},{"id":"rules","name":"Changing Rules","text":"Survive for 120 seconds. A warned rule changes every 30 seconds.","recommend":"Mobile / ranged"},{"id":"timing","name":"Perfect Timing","text":"Defeat 12 opponents while dodging marked strikes. Fewer hits earn a better medal.","recommend":"Precise / mobile"}]
static func week()->String:return preload("res://scripts/player_cosmetics.gd").week_key(Time.get_date_string_from_system())
static func weekly()->Array:
 var index=int(Time.get_unix_time_from_datetime_string(week()+"T00:00:00")/604800)
 var result=[]
 for n in 3:result.append({"type":posmod(index+n*2,5),"variant":posmod(index+n,3),"key":week()+":"+str(n)})
 return result
static func item(id:String)->Dictionary:
 var r:Dictionary=RECIPES[id].duplicate(true);r.id=id;r.cost=0;r.sprite="lodges/"+id;r.shop=false;r.crafted=true;return r
static func valid(data:Variant)->bool:
 if not data is Dictionary:return false
 var apple:Variant=data.get("apple_next",0)
 if not (apple is int or apple is float) or not is_finite(float(apple)) or float(apple)<0 or float(apple)>1e12:return false
 if not data.get("ingredients",{}) is Dictionary or not data.get("potions",{}) is Dictionary or not data.get("seeds",[]) is Array or not data.get("jobs",[]) is Array or data.get("jobs",[]).size()>3:return false
 for key in ["ingredients","potions"]:
  for id in data.get(key,{}):
   if id not in (INGREDIENTS if key=="ingredients" else RECIPES):return false
   var count=data[key][id]
   if not (count is int or count is float) or not is_finite(float(count)) or float(count)<0 or float(count)>100000:return false
 if int(data.get("crew",2)) not in [2,3]:return false
 if int(data.get("tier",1))<1 or int(data.get("tier",1))>3:return false
 for seed in data.get("seeds",[]):if seed not in ["forage_sun","forage_mint","forage_moon","forage_glow"]:return false
 for job in data.get("jobs",[]):
  if not job is Dictionary or job.get("route","") not in ROUTES or not job.get("finds",{}) is Dictionary:return false
  if job.get("seed","") not in ["","forage_sun","forage_mint","forage_moon","forage_glow"]:return false
  for id in job.finds:if id not in INGREDIENTS or int(job.finds[id])<0 or int(job.finds[id])>8:return false
  for key in ["start","end"]:
   if not job.get(key) is int and not job.get(key) is float:return false
   if not is_finite(float(job[key])) or float(job[key])<0:return false
 var brew=data.get("brew",{})
 if not brew is Dictionary:return false
 if not brew.is_empty() and (brew.get("id","") not in RECIPES or not brew.get("end") is int and not brew.get("end") is float):return false
 if not brew.is_empty():
  for key in ["start","end"]:
   if not (brew.get(key) is int or brew.get(key) is float) or not is_finite(float(brew[key])) or float(brew[key])<0:return false
 if not data.get("weekly",{}) is Dictionary:return false
 for value in data.get("weekly",{}).values():
  if not value is Array or value.size()>3:return false
 if not data.get("medals",{}) is Dictionary or not data.get("weekly",{}) is Dictionary:return false
 for medal in data.get("medals",{}).values():if int(medal)<0 or int(medal)>3:return false
 return true
