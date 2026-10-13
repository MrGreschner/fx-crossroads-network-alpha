extends RefCounted
const INGREDIENTS={"sunleaf":{"name":"Sunleaf Herb","color":"#97c578"},"mooncap":{"name":"Mooncap Mushroom","color":"#b59dcc"},"willow":{"name":"Willow Bark","color":"#c5a278"},"firefly":{"name":"Glowwing Insect","color":"#e8d68b"},"mint":{"name":"River Mint","color":"#73c3b6"},"petal":{"name":"Ember Petals","color":"#e7a16f"}}
const ROUTES={"meadow":{"name":"Sunlit Meadow","seconds":300,"finds":{"sunleaf":3,"petal":1},"seed":"forage_sun","chance":.18},"brook":{"name":"Willow Brook","seconds":600,"finds":{"mint":3,"willow":2},"seed":"forage_mint","chance":.20},"hollow":{"name":"Mooncap Hollow","seconds":900,"finds":{"mooncap":3,"firefly":2},"seed":"forage_moon","chance":.22},"lantern":{"name":"Lantern Thicket","seconds":1200,"finds":{"firefly":3,"petal":2,"sunleaf":1},"seed":"forage_glow","chance":.25}}
const RECIPES={"lodge_tonic":{"name":"Sunleaf Tonic","tier":1,"seconds":60,"needs":{"sunleaf":2,"mooncap":1},"effect":"heal","amount":30,"description":"Restore 30 HP. One use; uses one of your three item slots."},"lodge_cleanse":{"name":"Clearwater Draught","tier":1,"seconds":90,"needs":{"mint":2,"willow":1},"effect":"cleanse","amount":0,"description":"Remove poison, burn and bleed. No immunity afterwards."},"lodge_stride":{"name":"Trailrunner Brew","tier":2,"seconds":120,"needs":{"mint":2,"firefly":1},"effect":"haste","amount":15,"duration":4,"description":"Move 15% faster for 4 seconds. One use."},"lodge_guard":{"name":"Barkskin Phial","tier":2,"seconds":150,"needs":{"willow":3,"sunleaf":1},"effect":"lodge_guard","amount":15,"duration":4,"description":"Gain 15% damage reduction for 4 seconds. Does not stack with another Barkskin."},"lodge_restore":{"name":"Mooncap Restorative","tier":3,"seconds":180,"needs":{"mooncap":3,"petal":2,"firefly":1},"effect":"heal","amount":45,"description":"Restore 45 HP. One use; cannot revive."}}
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
