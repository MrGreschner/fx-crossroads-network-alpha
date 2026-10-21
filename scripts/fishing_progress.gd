extends RefCounted
const E=preload("res://scripts/fishing_ecology.gd")
const C=preload("res://scripts/fishing_catalog.gd")
const MAX_LEVEL=80
const VERSION=2
const MAX_POINTS=26
const LEGACY_LEVELS={"steady":5,"swift":5,"frugal":10,"cook":10,"weaver":15,"keeper":15,"eye":20,"scholar":20}
const BRANCHES=[{"id":"rod","name":"Rodcraft","color":"#80d7d0","nodes":["steady","swift","patient","depths","rod_master","rod_line","rod_rhythm","rod_sense","rod_archive","rod_abyss"]},{"id":"net","name":"Netcraft","color":"#91d5a6","nodes":["net_window","net_speed","weaver","net_select","net_master","net_rim","net_current","net_sense","net_archive","net_sieve"]},{"id":"basket","name":"Basketcraft","color":"#e7b77b","nodes":["pot_speed","pot_study","pot_frugal","keeper","pot_master","pot_relay","pot_outpost","pot_sense","pot_archive","pot_reserve"]},{"id":"water","name":"Watersense","color":"#bba9ed","nodes":["scholar","frugal","cook","fieldguide","eye","water_journal","water_recipe","water_study","water_trophy","water_lens"]},{"id":"packing","name":"Trailcraft","color":"#e2bd92","nodes":["packing_satchel","packing_sort","packing_trade","packing_case","packing_merchant","packing_crate","packing_frugal","packing_porter","packing_bazaar","packing_kit"]},{"id":"steward","name":"Stewardship","color":"#a6d9bf","nodes":["steward_notes","steward_release","steward_recipes","steward_lessons","steward_mentor","steward_patience","steward_reuse","steward_records","steward_master","steward_trophy"]}]
const TALENTS={"steady":{"level":3,"name":"Steady Hand","text":"Rod hook window +0.5 seconds.","branch":"rod","slot":0,"requires":[],"any":false},"swift":{"level":8,"name":"Quick Cast","text":"Rod waiting time reduced 15%.","branch":"rod","slot":1,"requires":["steady"],"any":false},"patient":{"level":8,"name":"Patient Angler","text":"Rod bite chance rises from 70% to 78%.","branch":"rod","slot":2,"requires":["steady"],"any":false},"depths":{"level":18,"name":"Deepwater Lure","text":"Non-common rod species weights +5%. Conditions still apply.","branch":"rod","slot":3,"requires":["swift","patient"],"any":true},"rod_master":{"level":30,"name":"Master of the Rod","text":"Rod catch XP +25%.","branch":"rod","slot":4,"requires":["swift","patient","depths"],"any":false},"net_window":{"level":3,"name":"Soft Landing","text":"Net hook window +0.35 seconds.","branch":"net","slot":0,"requires":[],"any":false},"net_speed":{"level":8,"name":"Flowing Sweep","text":"Net waiting time reduced 20%.","branch":"net","slot":1,"requires":["net_window"],"any":false},"weaver":{"level":8,"name":"Net Weaver","text":"Net catch XP rises from 35% to 50% of rod XP.","branch":"net","slot":2,"requires":["net_window"],"any":false},"net_select":{"level":18,"name":"Selective Mesh","text":"Non-common net species weights +5%. Conditions still apply.","branch":"net","slot":3,"requires":["net_speed","weaver"],"any":true},"net_master":{"level":30,"name":"Master of the Net","text":"Net catch XP becomes 65%; bite chance rises from 85% to 92%.","branch":"net","slot":4,"requires":["net_speed","weaver","net_select"],"any":false},"pot_speed":{"level":3,"name":"Current Keeper","text":"Baskets fill in 18 real minutes instead of 20.","branch":"basket","slot":0,"requires":[],"any":false},"pot_study":{"level":8,"name":"Basket Study","text":"Basket catch XP rises from 20% to 35% of rod XP.","branch":"basket","slot":1,"requires":["pot_speed"],"any":false},"pot_frugal":{"level":8,"name":"Lasting Scent","text":"25% chance to retain fish bait when setting a basket. Does not stack with Careful Baiter.","branch":"basket","slot":2,"requires":["pot_speed"],"any":false},"keeper":{"level":18,"name":"Basket Keeper","text":"Place three baskets instead of two, in different fishing holes.","branch":"basket","slot":3,"requires":["pot_study","pot_frugal"],"any":true},"pot_master":{"level":30,"name":"Basket Network","text":"Place four baskets in different holes. Fill time becomes 15 real minutes.","branch":"basket","slot":4,"requires":["pot_study","pot_frugal","keeper"],"any":false},"scholar":{"level":3,"name":"River Scholar","text":"New-species discoveries give 15 extra XP.","branch":"water","slot":0,"requires":[],"any":false},"frugal":{"level":8,"name":"Careful Baiter","text":"25% chance to retain consumable fish bait, for every method.","branch":"water","slot":1,"requires":["scholar"],"any":false},"cook":{"level":8,"name":"Field Kitchen","text":"Craft two extra fish bait per batch.","branch":"water","slot":2,"requires":["scholar"],"any":false},"fieldguide":{"level":18,"name":"Read the Water","text":"At a fishing hole, see current eligible species odds, bite chance and feeding conditions.","branch":"water","slot":3,"requires":["frugal","cook"],"any":true},"eye":{"level":30,"name":"Trophy Eye","text":"Oversized trophy chance rises from 2.5% to 3.25%. No species rarity bonus.","branch":"water","slot":4,"requires":["frugal","cook","fieldguide"],"any":false},"rod_line":{"level":42,"name":"Fine Line","text":"Rod hook window +0.25s.","branch":"rod","slot":5,"requires":["rod_master"],"any":false,"effects":{"rod_hook":0.25}},"rod_rhythm":{"level":42,"name":"Casting Rhythm","text":"Rod wait time reduced another 5%.","branch":"rod","slot":6,"requires":["rod_master"],"any":false,"effects":{"rod_wait":0.05}},"rod_sense":{"level":54,"name":"Rod Instinct","text":"Rod bite chance +3 percentage points.","branch":"rod","slot":7,"requires":["rod_line","rod_rhythm"],"any":true,"effects":{"rod_bite":0.03}},"rod_archive":{"level":68,"name":"Rod Archive","text":"Rod catch XP multiplier +0.15.","branch":"rod","slot":8,"requires":["rod_sense"],"any":false,"effects":{"rod_xp":0.15}},"rod_abyss":{"level":68,"name":"Abyssal Lure","text":"Non-common rod species weight +2.5%; feeding windows still apply.","branch":"rod","slot":9,"requires":["rod_sense"],"any":false,"effects":{"rod_rarity":0.025}},"net_rim":{"level":42,"name":"Gentle Rim","text":"Net hook window +0.2s.","branch":"net","slot":5,"requires":["net_master"],"any":false,"effects":{"net_hook":0.2}},"net_current":{"level":42,"name":"Current Sweep","text":"Net wait time reduced another 5%.","branch":"net","slot":6,"requires":["net_master"],"any":false,"effects":{"net_wait":0.05}},"net_sense":{"level":54,"name":"Shoal Instinct","text":"Net bite chance +2.5 percentage points.","branch":"net","slot":7,"requires":["net_rim","net_current"],"any":true,"effects":{"net_bite":0.025}},"net_archive":{"level":68,"name":"Net Archive","text":"Net catch XP multiplier +0.15.","branch":"net","slot":8,"requires":["net_sense"],"any":false,"effects":{"net_xp":0.15}},"net_sieve":{"level":68,"name":"Moonlit Mesh","text":"Non-common net species weight +2.5%; conditions still apply.","branch":"net","slot":9,"requires":["net_sense"],"any":false,"effects":{"net_rarity":0.025}},"pot_relay":{"level":42,"name":"Basket Relay","text":"Baskets fill 2 real minutes sooner.","branch":"basket","slot":5,"requires":["pot_master"],"any":false,"effects":{"pot_minutes":2}},"pot_outpost":{"level":42,"name":"Shore Outpost","text":"Place one additional basket at a different hole.","branch":"basket","slot":6,"requires":["pot_master"],"any":false,"effects":{"basket_limit":1}},"pot_sense":{"level":54,"name":"Patient Study","text":"Basket catch XP multiplier +0.10.","branch":"basket","slot":7,"requires":["pot_relay","pot_outpost"],"any":true,"effects":{"pot_xp":0.1}},"pot_archive":{"level":68,"name":"Deepwater Log","text":"Basket catch XP multiplier +0.15.","branch":"basket","slot":8,"requires":["pot_sense"],"any":false,"effects":{"pot_xp":0.15}},"pot_reserve":{"level":68,"name":"Scent Reserve","text":"Basket fish bait retention +15 percentage points.","branch":"basket","slot":9,"requires":["pot_sense"],"any":false,"effects":{"pot_save":0.15}},"water_journal":{"level":42,"name":"Field Journal","text":"New-species discoveries award 15 additional XP.","branch":"water","slot":5,"requires":["eye"],"any":false,"effects":{"discovery_xp":15}},"water_recipe":{"level":42,"name":"Rich Recipes","text":"Craft two additional fish bait per batch.","branch":"water","slot":6,"requires":["eye"],"any":false,"effects":{"bait_yield":2}},"water_study":{"level":54,"name":"Record Study","text":"New personal species weight records award 10 additional XP.","branch":"water","slot":7,"requires":["water_journal","water_recipe"],"any":true,"effects":{"record_xp":10}},"water_trophy":{"level":68,"name":"Trophy Lore","text":"Trophy XP multiplier rises by 0.25.","branch":"water","slot":8,"requires":["water_study"],"any":false,"effects":{"trophy_xp":0.25}},"water_lens":{"level":68,"name":"Moonwater Lens","text":"Oversized trophy chance +0.5 percentage points; no rarity change.","branch":"water","slot":9,"requires":["water_study"],"any":false,"effects":{"trophy_chance":0.005}},"packing_satchel":{"level":3,"name":"Angler Satchel","text":"Keep five additional specimens.","branch":"packing","slot":0,"requires":[],"any":false,"effects":{"capacity":5}},"packing_sort":{"level":8,"name":"Careful Packing","text":"Keep five additional specimens.","branch":"packing","slot":1,"requires":["packing_satchel"],"any":false,"effects":{"capacity":5}},"packing_trade":{"level":8,"name":"Catch Valuer","text":"Fish sales earn 5% more Glimmers; rounded once at sale.","branch":"packing","slot":2,"requires":["packing_satchel"],"any":false,"effects":{"sale":0.05}},"packing_case":{"level":18,"name":"Travelling Case","text":"Keep ten additional specimens.","branch":"packing","slot":3,"requires":["packing_sort","packing_trade"],"any":true,"effects":{"capacity":10}},"packing_merchant":{"level":30,"name":"Shore Merchant","text":"Fish sales earn another 5% more Glimmers.","branch":"packing","slot":4,"requires":["packing_sort","packing_trade","packing_case"],"any":false,"effects":{"sale":0.05}},"packing_crate":{"level":42,"name":"Specimen Crate","text":"Keep ten additional specimens.","branch":"packing","slot":5,"requires":["packing_merchant"],"any":false,"effects":{"capacity":10}},"packing_frugal":{"level":42,"name":"Camp Supplies","text":"Consumable fish bait retention +5 percentage points.","branch":"packing","slot":6,"requires":["packing_merchant"],"any":false,"effects":{"bait_save":0.05}},"packing_porter":{"level":54,"name":"Expedition Porter","text":"Keep twenty additional specimens.","branch":"packing","slot":7,"requires":["packing_crate","packing_frugal"],"any":true,"effects":{"capacity":20}},"packing_bazaar":{"level":68,"name":"Glimmer Broker","text":"Fish sales earn another 10% more Glimmers.","branch":"packing","slot":8,"requires":["packing_porter"],"any":false,"effects":{"sale":0.1}},"packing_kit":{"level":68,"name":"Endless Kit","text":"Craft two additional fish bait per batch.","branch":"packing","slot":9,"requires":["packing_porter"],"any":false,"effects":{"bait_yield":2}},"steward_notes":{"level":3,"name":"Catch Notes","text":"All fishing catch XP +3%.","branch":"steward","slot":0,"requires":[],"any":false,"effects":{"all_xp":0.03}},"steward_release":{"level":8,"name":"Gentle Release","text":"All fishing catch XP +3% whether kept or released.","branch":"steward","slot":1,"requires":["steward_notes"],"any":false,"effects":{"all_xp":0.03}},"steward_recipes":{"level":8,"name":"Camp Recipes","text":"Craft one additional fish bait per batch.","branch":"steward","slot":2,"requires":["steward_notes"],"any":false,"effects":{"bait_yield":1}},"steward_lessons":{"level":18,"name":"Water Lessons","text":"New species award 10 additional XP.","branch":"steward","slot":3,"requires":["steward_release","steward_recipes"],"any":true,"effects":{"discovery_xp":10}},"steward_mentor":{"level":30,"name":"Quiet Mentor","text":"All fishing catch XP +5%.","branch":"steward","slot":4,"requires":["steward_release","steward_recipes","steward_lessons"],"any":false,"effects":{"all_xp":0.05}},"steward_patience":{"level":42,"name":"Patient Hands","text":"Rod and net hook windows +0.15s.","branch":"steward","slot":5,"requires":["steward_mentor"],"any":false,"effects":{"rod_hook":0.15,"net_hook":0.15}},"steward_reuse":{"level":42,"name":"Waste Nothing","text":"Consumable fish bait retention +5 percentage points.","branch":"steward","slot":6,"requires":["steward_mentor"],"any":false,"effects":{"bait_save":0.05}},"steward_records":{"level":54,"name":"Living Archive","text":"New personal species weight records award 10 additional XP.","branch":"steward","slot":7,"requires":["steward_patience","steward_reuse"],"any":true,"effects":{"record_xp":10}},"steward_master":{"level":68,"name":"Waterside Sage","text":"All fishing catch XP +8%.","branch":"steward","slot":8,"requires":["steward_records"],"any":false,"effects":{"all_xp":0.08}},"steward_trophy":{"level":68,"name":"Trophy Steward","text":"Trophy XP multiplier rises by 0.25.","branch":"steward","slot":9,"requires":["steward_records"],"any":false,"effects":{"trophy_xp":0.25}}}
const COSMETICS={5:{"id":"copper","name":"Copper Float","color":"#dbac75"},10:{"id":"reed","name":"Reedkeeper Rod","color":"#98d6ae"},15:{"id":"moon","name":"Moonwake Angler","color":"#b8c9f8"},20:{"id":"star","name":"Starlight Keeper","color":"#ffe5a2"},30:{"id":"aurora","name":"Aurora Angler","color":"#a4f0dd"},40:{"id":"crown","name":"Crowned Riverkeeper","color":"#ffce70"},60:{"id":"deep","name":"Deepwater Luminary","color":"#91b9fa"},80:{"id":"eternal","name":"Eternal Tidekeeper","color":"#e5bafa"}}
var reference:WeakRef
var records:RefCounted:
 get:return reference.get_ref() if reference!=null else null
 set(value):reference=weakref(value)
var last_xp=0
func state()->Dictionary:return records.state()
static func extras()->Dictionary:return {"mastery_version":VERSION,"resets":0,"legacy_pots":false,"xp":0,"talents":{},"bait":{"worms":0,"insects":0,"dough":0,"scraps":0},"gear":{"net":false,"pot":false},"method":"rod","selected_bait":"basic","pots":[],"cosmetic":"","discoveries":{},"recent":[]}
static func threshold(level:int)->int:
 var n=maxi(0,level-1)
 var late=maxi(0,level-40)
 return 80*n+35*n*(n-1)/2+8*n*(n-1)*(2*n-1)/6+200*late*late+40*late*late*late
func level()->int:return level_for(int(state().xp))
func has(id:String)->bool:return bool(state().talents.get(id,false))
static func old_threshold(lv:int)->int:
 var xp=0
 for n in range(1,lv):xp+=80+35*(n-1)
 return xp
static func migrate(s:Dictionary)->void:
 if int(s.get("mastery_version",1))>=VERSION:return
 var xp=int(s.get("xp",0));var old_level=1
 while old_level<20 and xp>=old_threshold(old_level+1):old_level+=1
 var partial=xp-old_threshold(old_level)
 s.xp=threshold(old_level)+(partial if old_level==20 else int(round(float(partial)*(threshold(old_level+1)-threshold(old_level))/(old_threshold(old_level+1)-old_threshold(old_level)))))
 s.xp=mini(1000000000,int(s.xp))
 s.legacy_pots=s.get("pots",[]).size()>2
 s.talents={};s.resets=0;s.mastery_version=VERSION
static func level_for(xp:int)->int:
 var low=1;var high=MAX_LEVEL
 while low<high:
  var mid:int=(low+high+1)/2
  if xp>=threshold(mid):low=mid
  else:high=mid-1
 return low
func earned_points()->int:return mini(MAX_POINTS,level()/3)
func available_points()->int:return earned_points()-state().talents.size()
static func prerequisites(id:String,owned:Dictionary)->bool:
 var spec=TALENTS[id]
 if spec.requires.is_empty():return true
 for parent in spec.requires:
  if bool(owned.get(parent,false))==bool(spec.any):return bool(spec.any)
 return not bool(spec.any)
func learn_reason(id:String)->String:
 if id not in TALENTS:return "Unknown mastery."
 if has(id):return "Already learned."
 if level()<int(TALENTS[id].level):return "Requires fishing level %d." % int(TALENTS[id].level)
 if not prerequisites(id,state().talents):return "Follow the connected branch first. The crown requires both forks."
 if available_points()<1:return "No points available. Earn a point every three levels through level 78."
 return ""
func choose(id:String)->bool:
 if not learn_reason(id).is_empty():return false
 state().talents[id]=true;records.save();return true
func reset_cost()->int:return mini(2500,500+250*int(state().resets))
func reset_tree()->String:
 if records.legacy.game.mode!="town":return "Return to town to reset your mastery."
 if state().talents.is_empty():return "Your mastery points are already unspent."
 if not state().pots.is_empty():return "Collect or retrieve all placed baskets before resetting."
 var cost=reset_cost()
 if not records.dev_preview() and not records.legacy.glimmers.debit(cost):return "Not enough Glimmers. Reset costs %d Glimmers." % cost
 state().talents={};state().resets=mini(1000000,int(state().resets)+1);records.save()
 return "Mastery reset. All earned points refunded; XP, gear and fish retained."
func perk_bonus(key:String)->float:
 var total=0.0
 for id in state().talents:
  if has(id):total+=float(TALENTS[id].get("effects",{}).get(key,0))
 return total
func basket_limit()->int:return (4 if has("pot_master") else 3 if has("keeper") else 2)+int(perk_bonus("basket_limit"))
func basket_minutes()->int:return maxi(10,(15 if has("pot_master") else 18 if has("pot_speed") else 20)-int(perk_bonus("pot_minutes")))
func trophy_bonus()->float:return (.0075 if has("eye") else 0.0)+perk_bonus("trophy_chance")
func rarity_bonus(method:String)->float:return (.05 if (method=="rod" and has("depths")) or (method=="net" and has("net_select")) else 0.0)+perk_bonus(method+"_rarity")
func wait_scale(method:String)->float:return maxf(.65,((.8 if has("net_speed") else 1.0) if method=="net" else (.85 if has("swift") else 1.0))-perk_bonus(method+"_wait"))
func bite_chance(method:String)->float:return minf(.98,((.92 if has("net_master") else .85) if method=="net" else (.78 if has("patient") else .70))+perk_bonus(method+"_bite"))
func hook_bonus(method:String)->float:return ((.35 if has("net_window") else 0.0) if method=="net" else (.5 if has("steady") else 0.0))+perk_bonus(method+"_hook")
func catch_scale(method:String)->float:
 if method=="rod":return (1.25 if has("rod_master") else 1.0)+perk_bonus("rod_xp")
 if method=="net":return (.65 if has("net_master") else .5 if has("weaver") else .35)+perk_bonus("net_xp")
 return (.35 if has("pot_study") else .2)+perk_bonus("pot_xp")
func award(catch:Dictionary,first:bool,record:bool,kept:bool=true)->void:
 var rarity=str(C.fish()[catch.species].rarity)
 var base=int({"Common":10,"Uncommon":15,"Rare":30,"Very rare":40,"Legendary":60,"Mystical":100}.get(rarity,10))
 var method=str(catch.get("method","rod"));var scale_factor=catch_scale(method)
 last_xp=maxi(1,int(round(base*scale_factor*((1.5+perk_bonus("trophy_xp")) if C.is_trophy(catch) else 1.0)*(1+perk_bonus("all_xp")))))+(25+(15 if has("scholar") else 0)+int(perk_bonus("discovery_xp")) if first else 5+int(perk_bonus("record_xp")) if record else 0)
 if not kept:last_xp=ceili(last_xp*1.25)
 state().xp=mini(1000000000,int(state().xp)+last_xp)
const BAIT_LEVELS={"basic":1,"worms":1,"dough":1,"insects":8,"scraps":12}
const GEAR={"net":{"level":5,"cost":60,"name":"River net"},"pot":{"level":10,"cost":90,"name":"Baited basket"}}
func bait_unlocked(id:String)->bool:return id in BAIT_LEVELS and level()>=int(BAIT_LEVELS[id])
func method_unlocked(id:String)->bool:
 return id=="rod" or (id in GEAR and level()>=int(GEAR[id].level) and bool(state().gear.get(id,false)))
func buy_gear(id:String)->String:
 if records.legacy.game.mode!="town":return "Return to town to buy equipment."
 if id not in GEAR:return "Unknown equipment."
 var spec=GEAR[id]
 if method_unlocked(id):return "You already own this equipment."
 if level()<int(spec.level):return "Unlocks at fishing level %d." % int(spec.level)
 if not records.legacy.glimmers.debit(int(spec.cost)):return "Not enough Glimmers. Sell catches or gathered goods."
 state().gear[id]=true;records.save();return "Purchased "+str(spec.name)+". Select it at the water."
func basket_summary(utc:float)->String:
 if state().pots.is_empty():return "No baskets placed."
 var ready=0;var remaining=1200.0
 for pot in state().pots:
  if utc>=float(pot.ready):ready+=1
  else:remaining=minf(remaining,float(pot.ready)-utc)
 return "%d basket(s) READY • open to collect" % ready if ready>0 else "%d basket(s) waiting • next in %02d:%02d" % [state().pots.size(),int(ceil(remaining))/60,int(ceil(remaining))%60]
func bait()->String:
 var id=str(state().selected_bait)
 return id if bait_unlocked(id) and (id=="basic" or int(state().bait.get(id,0))>0) else "basic"
func spend_bait(rng:RandomNumberGenerator,method:String="")->void:
 var id=bait()
 if id=="basic":return
 var retain=(.25 if has("frugal") or (method=="pot" and has("pot_frugal")) else 0.0)+perk_bonus("bait_save")+(perk_bonus("pot_save") if method=="pot" else 0.0)
 if rng.randf()<minf(.55,retain):return
 state().bait[id]=maxi(0,int(state().bait.get(id,0))-1);records.save()
func craft(id:String)->String:
 if not E.BAITS.has(id) or id=="basic":return "Choose a special fish bait."
 if not bait_unlocked(id):return "Unlocks at fishing level %d." % int(BAIT_LEVELS[id])
 if not records.legacy.glimmers.allowed():return "Return to a normal profile to craft."
 var economy=records.legacy.lodge_economy
 if not economy.can_pay(E.BAITS[id].needs):return "Gather or grow the ingredients shown on the recipe."
 if int(state().bait.get(id,0))>990:return "Your fish bait box is full."
 economy.pay(E.BAITS[id].needs);var amount=(8 if has("cook") else 6)+int(perk_bonus("bait_yield"))
 state().bait[id]=int(state().bait.get(id,0))+amount;records.save();return "Crafted %d %s." % [amount,E.BAITS[id].name]
func buy(id:String,game:Node)->String:
 if str(game.mode)!="town":return "Return to town to buy fish bait."
 if not E.BAITS.has(id) or id=="basic":return "Plain hooks are free."
 var price=int(E.BAITS[id].cost)
 if not bait_unlocked(id):return "Unlocks at fishing level %d." % int(BAIT_LEVELS[id])
 if int(state().bait.get(id,0))>990:return "Your fish bait box is full."
 if not records.legacy.glimmers.debit(price):return "Not enough Glimmers. Sell catches or gathered goods."
 state().bait[id]=int(state().bait.get(id,0))+3;records.save();game.save_profile();return "Bought three "+str(E.BAITS[id].name)+"."
func place(pool:String,utc:float,rng:RandomNumberGenerator)->String:
 if not method_unlocked("pot"):return "Buy a baited basket at fishing level 10 first."
 if bait()=="basic":return "A basket needs one consumable fish bait. Select worms, dough or an unlocked specialist fish bait."
 if not records.legacy.glimmers.allowed() and not records.dev_preview():return "Return to a normal profile to set a basket."
 if state().pots.size()>=basket_limit():return "All baskets are placed. Collect or retrieve one first."
 for pot in state().pots:
  if str(pot.pool)==pool:return "A basket is already placed in this fishing hole."
 var minutes=basket_minutes();var ready=utc+minutes*60
 if pool=="town_dawn" and not (float(E.WEATHER.context(ready).hour)>=4 and float(E.WEATHER.context(ready).hour)<6):return "Not enough dawn time: this basket needs %d real minutes before the shoal closes." % minutes
 var ctx=E.WEATHER.context(ready)
 if records.dev_preview() and records.legacy.game.get("town_life")!=null:
  var chosen=records.legacy.game.town_life.calendar.preview_weather
  if chosen in E.WEATHER.TYPES:ctx.weather=chosen
 var catch=C.roll(pool,rng,ctx,"pot",bait(),level(),trophy_bonus())
 if catch.is_empty():return "No suitable basket creatures feed here at that time."
 state().pots.append({"pool":pool,"placed":utc,"ready":ready,"catch":catch});spend_bait(rng,"pot");records.save();return "Basket set • return in %d real minutes. It stops when full." % minutes
func claim(index:int,utc:float,keep:bool=true)->String:
 if index<0 or index>=state().pots.size():return "That basket has already been collected."
 var pot:Dictionary=state().pots[index]
 if utc<float(pot.ready):return "Basket ready in %d minutes." % ceili((float(pot.ready)-utc)/60)
 var catch:Dictionary=pot.catch
 var legacy_before=bool(state().legacy_pots)
 # Remove before completion so the catch and basket removal share the same save.
 state().pots.remove_at(index)
 if state().pots.size()<=2:state().legacy_pots=false
 if not records.complete(catch,keep):
  state().pots.insert(index,pot);state().legacy_pots=legacy_before
  return "Cannot collect yet: make space in your collection or use Release catch."
 return ("Kept " if keep else "Released ")+str(C.fish()[catch.species].name)+" • +%d fishing XP." % last_xp
func tint()->Color:
 for milestone in COSMETICS:
  if str(COSMETICS[milestone].id)==str(state().cosmetic) and level()>=int(milestone):return Color(str(COSMETICS[milestone].color))
 return Color("#edc49a")
func title()->String:
 for milestone in COSMETICS:
  if str(COSMETICS[milestone].id)==str(state().cosmetic) and level()>=int(milestone):return str(COSMETICS[milestone].name)
 return "Apprentice Angler"
static func valid_extra(v:Dictionary)->bool:
 if not (v.get("xp",0) is int or v.get("xp",0) is float) or not is_finite(float(v.get("xp",0))) or float(v.get("xp",0))<0 or float(v.get("xp",0))>1e9:return false
 if v.get("method","rod") not in ["rod","net","pot"] or v.get("selected_bait","basic") not in E.BAITS:return false
 if v.has("gear"):
  if not v.gear is Dictionary or v.gear.size()!=2:return false
  for id in ["net","pot"]:
   if not v.gear.get(id) is bool:return false
 if not v.get("bait",{}) is Dictionary or v.get("bait",{}).size()>4:return false
 for id in v.get("bait",{}):
  var n=v.bait[id]
  if id not in E.BAITS or id=="basic" or not (n is int or n is float) or not is_finite(float(n)) or float(n)<0 or float(n)>1000:return false
 var version=v.get("mastery_version",1)
 if not (version is int or version is float) or not is_finite(float(version)) or float(version)!=floor(float(version)) or int(version) not in [1,VERSION]:return false
 if not v.get("talents",{}) is Dictionary:return false
 var owned:Dictionary=v.get("talents",{});var xp=int(v.get("xp",0));var limit=3
 if int(version)==1:
  if owned.size()>4:return false
  var tiers=[]
  for id in owned:
   if id not in LEGACY_LEVELS or owned[id]!=true:return false
   var tier=int(LEGACY_LEVELS[id])
   if tier in tiers or xp<old_threshold(tier):return false
   tiers.append(tier)
  if owned.size()>0 and owned.get("keeper",false):limit=3
  else:limit=2
 else:
  if not v.get("resets",0) is int and not v.get("resets",0) is float:return false
  if not is_finite(float(v.get("resets",0))) or float(v.get("resets",0))<0 or float(v.get("resets",0))>1000000 or float(v.get("resets",0))!=floor(float(v.get("resets",0))):return false
  if not v.get("legacy_pots",false) is bool:return false
  if owned.size()>mini(MAX_POINTS,level_for(xp)/3):return false
  for id in owned:
   if id not in TALENTS or owned[id]!=true:return false
   if xp<threshold(int(TALENTS[id].level)) or not prerequisites(id,owned):return false
  limit=(4 if owned.get("pot_master",false) else 3 if owned.get("keeper",false) or v.get("legacy_pots",false) else 2)+(1 if owned.get("pot_outpost",false) else 0)
 if not v.get("pots",[]) is Array or v.get("pots",[]).size()>limit:return false
 for pot in v.get("pots",[]):
  if not pot is Dictionary or pot.get("pool","") not in C.pools():return false
  for key in ["placed","ready"]:
   if not (pot.get(key) is int or pot.get(key) is float) or not is_finite(float(pot[key])) or float(pot[key])<0 or float(pot[key])>1e12:return false
  if float(pot.ready)<float(pot.placed) or not pot.get("catch",{}) is Dictionary or pot.catch.get("method","")!="pot" or pot.catch.get("pool","")!=pot.pool:return false
 if v.get("cosmetic","") not in ["","copper","reed","moon","star","aurora","crown","deep","eternal"]:return false
 if not v.get("discoveries",{}) is Dictionary or v.get("discoveries",{}).size()>40:return false
 for id in v.get("discoveries",{}):
  if not id is String or id.length()>64 or not v.discoveries[id] is String or v.discoveries[id].length()>32:return false
 if not v.get("recent",[]) is Array or v.get("recent",[]).size()>100:return false
 for id in v.get("recent",[]):
  if not id is String or id.length()>64:return false
 return true
