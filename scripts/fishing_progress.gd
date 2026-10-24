extends RefCounted
const E=preload("res://scripts/fishing_ecology.gd")
const C=preload("res://scripts/fishing_catalog.gd")
const MAX_LEVEL=80
const VERSION=3
const MAX_POINTS=26
const LEGACY_LEVELS={"steady":5,"swift":5,"frugal":10,"cook":10,"weaver":15,"keeper":15,"eye":20,"scholar":20}
const BRANCHES=[{"id":"rod","name":"Rodcraft","color":"#80d7d0","nodes":["steady","swift","patient","depths","rod_master","rod_line","rod_rhythm","rod_sense","rod_archive","rod_abyss"]},{"id":"net","name":"Netcraft","color":"#91d5a6","nodes":["net_window","net_speed","weaver","net_select","net_master","net_rim","net_current","net_sense","net_archive","net_sieve"]},{"id":"basket","name":"Basketcraft","color":"#e7b77b","nodes":["pot_speed","pot_study","pot_frugal","keeper","pot_master","pot_relay","pot_outpost","pot_sense","pot_archive","pot_reserve"]},{"id":"water","name":"Watersense","color":"#bba9ed","nodes":["scholar","frugal","cook","fieldguide","eye","water_journal","water_recipe","water_study","water_trophy","water_lens"]},{"id":"packing","name":"Trailcraft","color":"#e2bd92","nodes":["packing_satchel","packing_sort","packing_trade","packing_case","packing_merchant","packing_crate","packing_frugal","packing_porter","packing_bazaar","packing_kit"]},{"id":"steward","name":"Stewardship","color":"#a6d9bf","nodes":["steward_notes","steward_release","steward_recipes","steward_lessons","steward_mentor","steward_patience","steward_reuse","steward_records","steward_master","steward_trophy"]}]
const TALENTS={"steady":{"level":3,"name":"Steady Hand","text":"Rod hook window +0.5 seconds.","branch":"rod","slot":0,"requires":[],"any":false,"position":[280,2302]},"swift":{"level":8,"name":"Quick Cast","text":"Rod waiting time reduced 15%.","branch":"rod","slot":1,"requires":["steady"],"any":false,"position":[133,1938],"exclusive":"rod_route"},"patient":{"level":8,"name":"Patient Angler","text":"Rod bite chance rises from 70% to 78%.","branch":"rod","slot":2,"requires":["steady"],"any":false,"position":[434,1966],"exclusive":"rod_route"},"depths":{"level":18,"name":"Deepwater Lure","text":"Non-common rod species weights +5%. Conditions still apply.","branch":"rod","slot":3,"requires":["patient"],"any":false,"position":[455,1560]},"rod_master":{"level":18,"name":"Master of the Rod","text":"Rod catch XP +25%.","branch":"rod","slot":4,"requires":["swift"],"any":false,"position":[105,1532]},"net_window":{"level":3,"name":"Soft Landing","text":"Net hook window +0.35 seconds.","branch":"net","slot":0,"requires":[],"any":false,"position":[840,2274]},"net_speed":{"level":8,"name":"Flowing Sweep","text":"Net waiting time reduced 20%.","branch":"net","slot":1,"requires":["net_window"],"any":false,"position":[644,1910],"exclusive":"net_route"},"weaver":{"level":8,"name":"Net Weaver","text":"Net catch XP rises from 35% to 50% of rod XP.","branch":"net","slot":2,"requires":["net_window"],"any":false,"position":[833,1770],"exclusive":"net_route"},"net_select":{"level":8,"name":"Selective Mesh","text":"Non-common net species weights +5%. Conditions still apply.","branch":"net","slot":3,"requires":["net_window"],"any":false,"position":[1036,1952],"exclusive":"net_route"},"net_master":{"level":18,"name":"Master of the Net","text":"Net catch XP becomes 65%; bite chance rises from 85% to 92%.","branch":"net","slot":4,"requires":["net_speed"],"any":false,"position":[630,1476]},"pot_speed":{"level":3,"name":"Current Keeper","text":"Baskets fill in 18 real minutes instead of 20.","branch":"basket","slot":0,"requires":[],"any":false,"position":[1400,2330]},"pot_study":{"level":8,"name":"Basket Study","text":"Basket catch XP rises from 20% to 35% of rod XP.","branch":"basket","slot":1,"requires":["pot_speed"],"any":false,"position":[1190,1938],"exclusive":"basket_route"},"pot_frugal":{"level":8,"name":"Lasting Scent","text":"25% chance to retain fish bait when setting a basket. Does not stack with Careful Baiter.","branch":"basket","slot":2,"requires":["pot_speed"],"any":false,"position":[1330,1770],"exclusive":"basket_route"},"keeper":{"level":8,"name":"Basket Keeper","text":"Place three baskets instead of two, in different holes.","branch":"basket","slot":3,"requires":["pot_speed"],"any":false,"position":[1477,1854],"exclusive":"basket_route"},"pot_master":{"level":8,"name":"Deep Baskets","text":"Each newly placed basket holds 7 fish instead of 5.","branch":"basket","slot":4,"requires":["pot_speed"],"any":false,"position":[1617,1980],"exclusive":"basket_route","effects":{"basket_capacity":2}},"scholar":{"level":3,"name":"River Scholar","text":"New-species discoveries give 15 extra XP.","branch":"water","slot":0,"requires":[],"any":false,"position":[1960,2316]},"frugal":{"level":8,"name":"Careful Baiter","text":"25% chance to retain consumable fish bait, for every method.","branch":"water","slot":1,"requires":["scholar"],"any":false,"position":[1778,2036]},"cook":{"level":8,"name":"Field Kitchen","text":"Craft two extra fish bait per batch.","branch":"water","slot":2,"requires":["scholar"],"any":false,"position":[1953,1840]},"fieldguide":{"level":8,"name":"Read the Water","text":"At a fishing hole, see current eligible species odds, bite chance and feeding conditions.","branch":"water","slot":3,"requires":["scholar"],"any":false,"position":[2149,1966]},"eye":{"level":30,"name":"Trophy Eye","text":"Oversized trophy chance rises from 2.5% to 3.25%. No species rarity bonus.","branch":"water","slot":4,"requires":["fieldguide"],"any":false,"position":[2149,1504]},"rod_line":{"level":30,"name":"Fine Line","text":"Rod hook window +0.25s.","branch":"rod","slot":5,"requires":["rod_master"],"any":false,"effects":{"rod_hook":0.25},"position":[63,1098]},"rod_rhythm":{"level":30,"name":"Casting Rhythm","text":"Rod wait time reduced another 5%.","branch":"rod","slot":6,"requires":["rod_master"],"any":false,"effects":{"rod_wait":0.05},"position":[231,1154]},"rod_sense":{"level":30,"name":"Rod Instinct","text":"Rod bite chance +3 percentage points.","branch":"rod","slot":7,"requires":["depths"],"any":false,"effects":{"rod_bite":0.03},"position":[441,1140]},"rod_archive":{"level":54,"name":"Rod Archive","text":"Rod catch XP multiplier +0.15.","branch":"rod","slot":8,"requires":["rod_line","rod_rhythm"],"any":true,"effects":{"rod_xp":0.15},"position":[126,552]},"rod_abyss":{"level":54,"name":"Abyssal Lure","text":"Non-common rod species weight +2.5%; feeding windows still apply.","branch":"rod","slot":9,"requires":["rod_sense"],"any":false,"effects":{"rod_rarity":0.025},"position":[462,398]},"net_rim":{"level":42,"name":"Gentle Rim","text":"Net hook window +0.2s.","branch":"net","slot":5,"requires":["net_master"],"any":false,"effects":{"net_hook":0.2},"position":[707,916]},"net_current":{"level":18,"name":"Current Sweep","text":"Net wait time reduced another 5%.","branch":"net","slot":6,"requires":["weaver"],"any":false,"effects":{"net_wait":0.05},"position":[854,1280]},"net_sense":{"level":42,"name":"Shoal Instinct","text":"Net bite chance +2.5 percentage points.","branch":"net","slot":7,"requires":["net_current"],"any":false,"effects":{"net_bite":0.025},"position":[812,594]},"net_archive":{"level":18,"name":"Net Archive","text":"Net catch XP multiplier +0.15.","branch":"net","slot":8,"requires":["net_select"],"any":false,"effects":{"net_xp":0.15},"position":[1043,1462]},"net_sieve":{"level":54,"name":"Moonlit Mesh","text":"Non-common net species weight +2.5%; conditions still apply.","branch":"net","slot":9,"requires":["net_archive"],"any":false,"effects":{"net_rarity":0.025},"position":[1001,790]},"pot_relay":{"level":42,"name":"Woven Chambers","text":"New baskets hold 3 additional fish (10 total) and fill 2 minutes sooner.","branch":"basket","slot":5,"requires":["pot_master"],"any":false,"effects":{"basket_capacity":3,"pot_minutes":2},"position":[1638,1322]},"pot_outpost":{"level":30,"name":"Shore Outpost","text":"Place one additional basket at a different hole.","branch":"basket","slot":6,"requires":["keeper"],"any":false,"effects":{"basket_limit":1},"position":[1491,1140]},"pot_sense":{"level":30,"name":"Patient Study","text":"Basket catch XP multiplier +0.10.","branch":"basket","slot":7,"requires":["pot_study"],"any":false,"effects":{"pot_xp":0.1},"position":[1190,1406]},"pot_archive":{"level":54,"name":"Deepwater Log","text":"Basket catch XP multiplier +0.15.","branch":"basket","slot":8,"requires":["pot_sense"],"any":false,"effects":{"pot_xp":0.15},"position":[1239,678]},"pot_reserve":{"level":30,"name":"Scent Reserve","text":"Basket fish bait retention +15 percentage points.","branch":"basket","slot":9,"requires":["pot_frugal"],"any":false,"effects":{"pot_save":0.15},"position":[1330,1014]},"water_journal":{"level":30,"name":"Field Journal","text":"New-species discoveries award 15 additional XP.","branch":"water","slot":5,"requires":["fieldguide"],"any":false,"effects":{"discovery_xp":15},"position":[2002,1462]},"water_recipe":{"level":30,"name":"Rich Recipes","text":"Craft two additional fish bait per batch.","branch":"water","slot":6,"requires":["cook"],"any":false,"effects":{"bait_yield":2},"position":[1890,1280]},"water_study":{"level":54,"name":"Record Study","text":"New personal species weight records award 10 additional XP.","branch":"water","slot":7,"requires":["water_journal","water_recipe"],"any":true,"effects":{"record_xp":10},"position":[1960,860]},"water_trophy":{"level":54,"name":"Trophy Lore","text":"Trophy XP multiplier rises by 0.25.","branch":"water","slot":8,"requires":["eye"],"any":false,"effects":{"trophy_xp":0.25},"position":[2170,916]},"water_lens":{"level":68,"name":"Moonwater Lens","text":"Oversized trophy chance +0.5 percentage points; no rarity change.","branch":"water","slot":9,"requires":["water_study"],"any":false,"effects":{"trophy_chance":0.005},"position":[2030,300]},"packing_satchel":{"level":3,"name":"Angler Satchel","text":"Keep five additional specimens. Boat cargo capacity +5 (lake and ocean).","branch":"packing","slot":0,"requires":[],"any":false,"effects":{"capacity":5,"voyage_capacity":5},"position":[2520,2302]},"packing_sort":{"level":8,"name":"Careful Packing","text":"Keep five additional specimens. Boat cargo capacity +5 (lake and ocean).","branch":"packing","slot":1,"requires":["packing_satchel"],"any":false,"effects":{"capacity":5,"voyage_capacity":5},"position":[2345,1952]},"packing_trade":{"level":8,"name":"Catch Valuer","text":"Fish sales earn 5% more Glimmers; rounded once at sale.","branch":"packing","slot":2,"requires":["packing_satchel"],"any":false,"effects":{"sale":0.05},"position":[2555,1840]},"packing_case":{"level":18,"name":"Travelling Case","text":"Keep ten additional specimens. Boat cargo capacity +10 (lake and ocean).","branch":"packing","slot":3,"requires":["packing_sort"],"any":false,"effects":{"capacity":10,"voyage_capacity":10},"position":[2310,1448]},"packing_merchant":{"level":30,"name":"Shore Merchant","text":"Fish sales earn another 5% more Glimmers.","branch":"packing","slot":4,"requires":["packing_trade"],"any":false,"effects":{"sale":0.05},"position":[2562,1336]},"packing_crate":{"level":42,"name":"Specimen Crate","text":"Keep ten additional specimens. Boat cargo capacity +10 (lake and ocean).","branch":"packing","slot":5,"requires":["packing_case"],"any":false,"effects":{"capacity":10,"voyage_capacity":10},"position":[2387,1028]},"packing_frugal":{"level":18,"name":"Camp Supplies","text":"Consumable fish bait retention +5 percentage points.","branch":"packing","slot":6,"requires":["packing_satchel"],"any":false,"effects":{"bait_save":0.05},"position":[2723,2050]},"packing_porter":{"level":54,"name":"Expedition Porter","text":"Keep twenty additional specimens. Boat cargo capacity +10 (lake and ocean).","branch":"packing","slot":7,"requires":["packing_crate"],"any":false,"effects":{"capacity":20,"voyage_capacity":10},"position":[2345,398]},"packing_bazaar":{"level":54,"name":"Glimmer Broker","text":"Fish sales earn another 10% more Glimmers.","branch":"packing","slot":8,"requires":["packing_merchant"],"any":false,"effects":{"sale":0.1},"position":[2625,664]},"packing_kit":{"level":42,"name":"Endless Kit","text":"Craft two additional fish bait per batch.","branch":"packing","slot":9,"requires":["packing_frugal"],"any":false,"effects":{"bait_yield":2},"position":[2723,1448]},"steward_notes":{"level":3,"name":"Catch Notes","text":"All fishing catch XP +3%.","branch":"steward","slot":0,"requires":[],"any":false,"effects":{"all_xp":0.03},"position":[3080,2330]},"steward_release":{"level":8,"name":"Gentle Release","text":"Release XP bonus +15 percentage points: +40% instead of +25%. Choose this OR Fair Trade.","branch":"steward","slot":1,"requires":["steward_notes"],"any":false,"effects":{"release_xp":0.15},"position":[2919,1966],"exclusive":"steward_route"},"steward_recipes":{"level":8,"name":"Fair Trade","text":"Sell kept fish for +5% Glimmers. Choose this OR Gentle Release.","branch":"steward","slot":2,"requires":["steward_notes"],"any":false,"effects":{"sale":0.05},"position":[3234,2036],"exclusive":"steward_route"},"steward_lessons":{"level":18,"name":"Return to the River","text":"Release XP bonus +10 percentage points.","branch":"steward","slot":3,"requires":["steward_release"],"any":false,"effects":{"release_xp":0.1},"position":[2884,1546]},"steward_mentor":{"level":30,"name":"Quiet Mentor","text":"Release XP bonus +15 percentage points.","branch":"steward","slot":4,"requires":["steward_lessons"],"any":false,"effects":{"release_xp":0.15},"position":[2877,1070]},"steward_patience":{"level":30,"name":"Patient Hands","text":"Rod and net hook windows +0.15s.","branch":"steward","slot":5,"requires":["steward_lessons"],"any":false,"effects":{"rod_hook":0.15,"net_hook":0.15},"position":[3045,1238]},"steward_reuse":{"level":18,"name":"Fresh Fish Market","text":"Fish sales earn another +10% Glimmers.","branch":"steward","slot":6,"requires":["steward_recipes"],"any":false,"effects":{"sale":0.1},"position":[3283,1518]},"steward_records":{"level":54,"name":"Living Waters","text":"Release XP bonus +15 percentage points.","branch":"steward","slot":7,"requires":["steward_mentor"],"any":false,"effects":{"release_xp":0.15},"position":[2940,426]},"steward_master":{"level":42,"name":"Waterside Trader","text":"Fish sales earn another +10% Glimmers.","branch":"steward","slot":8,"requires":["steward_reuse"],"any":false,"effects":{"sale":0.1},"position":[3150,986]},"steward_trophy":{"level":42,"name":"Prized Catch","text":"Fish sales earn another +15% Glimmers.","branch":"steward","slot":9,"requires":["steward_reuse"],"any":false,"effects":{"sale":0.15},"position":[3339,860]}}
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
 if int(s.get("mastery_version",1))==2:
  # The new exclusive routes cannot inherit the old symmetrical tree safely.
  s.legacy_pots=bool(s.get("legacy_pots",false)) or s.get("pots",[]).size()>2
  s.talents={};s.mastery_refunded=true;s.mastery_version=VERSION
  return
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
func excluded(id:String)->bool:
 var group=str(TALENTS.get(id,{}).get("exclusive",""))
 if group.is_empty():return false
 for other in state().talents:
  if other!=id and str(TALENTS[other].get("exclusive",""))==group:return true
 return false
func learn_reason(id:String)->String:
 if id not in TALENTS:return "Unknown mastery."
 if has(id):return "Already learned."
 if level()<int(TALENTS[id].level):return "Requires fishing level %d." % int(TALENTS[id].level)
 var group=str(TALENTS[id].get("exclusive",""))
 if not group.is_empty():
  for other in state().talents:
   if other!=id and str(TALENTS[other].get("exclusive",""))==group:return "Another specialization is selected. Reset mastery to change this route."
 if not prerequisites(id,state().talents):return "Follow a connected path first."
 if available_points()<1:return "No points available. Earn a point every three levels through level 78."
 return ""
func choose(id:String)->bool:
 if not learn_reason(id).is_empty():return false
 state().talents[id]=true;state().mastery_refunded=false;records.save();return true
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
func basket_limit()->int:return maxi(3 if bool(state().legacy_pots) else 2,(3 if has("keeper") else 2)+int(perk_bonus("basket_limit")))
func basket_capacity()->int:return clampi(5+int(perk_bonus("basket_capacity")),5,10)
func voyage_capacity()->int:return clampi(20+int(perk_bonus("voyage_capacity")),20,60)
func release_bonus()->float:return .25+perk_bonus("release_xp")
static func basket_count(pot:Dictionary)->int:return 1+pot.get("reserves",[]).size()
func total_basket_fish()->int:
 var total=0
 for pot in state().pots:total+=basket_count(pot)
 return total
func basket_minutes()->int:return maxi(10,(18 if has("pot_speed") else 20)-int(perk_bonus("pot_minutes")))
func trophy_bonus()->float:return (.0075 if has("eye") else 0.0)+perk_bonus("trophy_chance")
func rarity_bonus(method:String)->float:return (.05 if (method=="rod" and has("depths")) or (method=="net" and has("net_select")) else 0.0)+perk_bonus(method+"_rarity")
func wait_scale(method:String)->float:return maxf(.65,((.8 if has("net_speed") else 1.0) if method=="net" else (.85 if has("swift") else 1.0))-perk_bonus(method+"_wait"))
func bite_chance(method:String)->float:return minf(.98,((.92 if has("net_master") else .85) if method=="net" else (.78 if has("patient") else .70))+perk_bonus(method+"_bite"))
func hook_bonus(method:String)->float:return ((.35 if has("net_window") else 0.0) if method=="net" else (.5 if has("steady") else 0.0))+perk_bonus(method+"_hook")
func catch_scale(method:String)->float:
 if method=="rod":return (1.25 if has("rod_master") else 1.0)+perk_bonus("rod_xp")
 if method=="net":return (.65 if has("net_master") else .5 if has("weaver") else .35)+perk_bonus("net_xp")
 return (.35 if has("pot_study") else .2)+perk_bonus("pot_xp")
func quote_xp(catch:Dictionary,first:bool,record:bool,kept:bool=true)->int:
 var rarity=str(C.fish()[catch.species].rarity)
 var base=int({"Common":10,"Uncommon":15,"Rare":30,"Very rare":40,"Legendary":60,"Fabled":180,"Mystical":100}.get(rarity,10))
 var method=str(catch.get("method","rod"));var scale_factor=catch_scale(method)
 var amount=maxi(1,int(round(base*scale_factor*((1.5+perk_bonus("trophy_xp")) if C.is_trophy(catch) else 1.0)*(1+perk_bonus("all_xp")))))+(25+(15 if has("scholar") else 0)+int(perk_bonus("discovery_xp")) if first else 5+int(perk_bonus("record_xp")) if record else 0)
 if not kept:amount=ceili(amount*(1+release_bonus()))
 return amount
func award(catch:Dictionary,first:bool,record:bool,kept:bool=true)->void:
 var before=level()
 last_xp=quote_xp(catch,first,record,kept);state().xp=mini(1000000000,int(state().xp)+last_xp)
 if level()>before:preload("res://scripts/skill_celebration.gd").show_level(records.legacy.game,"Fishing",before,level(),earned_points()-mini(MAX_POINTS,before/3))
const BAIT_LEVELS={"basic":1,"worms":1,"dough":1,"insects":8,"scraps":12,"honeygrain":5,"moonmoth":10,"saltflash":12,"kelp_crumble":8,"roe":10}
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
 var ready=0;var ready_fish=0;var remaining=1200.0
 for pot in state().pots:
  if utc>=float(pot.ready):ready+=1;ready_fish+=basket_count(pot)
  else:remaining=minf(remaining,float(pot.ready)-utc)
 return "%d basket(s) READY • %d fish waiting" % [ready,ready_fish] if ready>0 else "%d basket(s) waiting • next in %02d:%02d" % [state().pots.size(),int(ceil(remaining))/60,int(ceil(remaining))%60]
func bait()->String:
 var id=str(state().selected_bait)
 return id if bait_unlocked(id) and (id=="basic" or int(state().bait.get(id,0))>0) else "basic"
func spend_bait(rng:RandomNumberGenerator,method:String="")->void:
 var id=bait()
 if id=="basic":return
 var retain=(.25 if has("frugal") or (method=="pot" and has("pot_frugal")) else 0.0)+perk_bonus("bait_save")+(perk_bonus("pot_save") if method=="pot" else 0.0)
 if rng.randf()<minf(.55,retain):return
 state().bait[id]=maxi(0,int(state().bait.get(id,0))-1);records.save()
func bait_fish_index(id:String)->int:
 if not E.BAITS.get(id,{}).has("fish_source"):return -2
 var s=state()
 for n in s.kept.size():
  var fish:Dictionary=s.kept[n];var spec:Dictionary=C.fish()[fish.species]
  if "rod" in spec.methods and spec.rarity in ["Common","Uncommon"] and not C.is_trophy(fish) and fish.id!=s.favorite and fish.id not in s.display:return n
 return -1
func craft(id:String)->String:
 if not E.BAITS.has(id) or id=="basic":return "Choose a special fish bait."
 if not bait_unlocked(id):return "Unlocks at fishing level %d." % int(BAIT_LEVELS[id])
 if not records.legacy.glimmers.allowed():return "Return to a normal profile to craft."
 var economy=records.legacy.lodge_economy
 if not economy.can_pay(E.BAITS[id].needs):return "Gather or grow the ingredients shown on the recipe."
 if int(state().bait.get(id,0))>990:return "Your fish bait box is full."
 var source=bait_fish_index(id)
 if source==-1:return "Keep an ordinary Common/Uncommon rod fish first. Trophies, favourites and displayed specimens are protected."
 if source>=0:
  state().stored_ids.erase(str(state().kept[source].id));state().kept.remove_at(source)
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
 if str(C.pools().get(pool,{}).get("region","")).begins_with("voyage_"):return "Use a voyage cage from your anchored boat; these catches must return alive."
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
 var reserves:Array=[]
 for n in basket_capacity()-1:
  var extra=C.roll(pool,rng,ctx,"pot",bait(),level(),trophy_bonus())
  if extra.is_empty():return "No suitable creatures feed here."
  reserves.append(extra)
 state().pots.append({"pool":pool,"placed":utc,"ready":ready,"catch":catch,"reserves":reserves});spend_bait(rng,"pot");records.save();return "Basket set • %d fish in %d real minutes. Stops when full." % [basket_capacity(),minutes]
func claim(index:int,utc:float,keep:bool=true)->String:
 if index<0 or index>=state().pots.size():return "That basket has already been collected."
 var pot:Dictionary=state().pots[index]
 if utc<float(pot.ready):return "Basket ready in %d minutes." % ceili((float(pot.ready)-utc)/60)
 var catch:Dictionary=pot.catch
 var original=pot.duplicate(true);var legacy_before=bool(state().legacy_pots)
 var reserves:Array=pot.get("reserves",[]);var removed=reserves.is_empty()
 # Advance the queue BEFORE complete() saves. A reload cannot award this fish twice.
 if reserves.is_empty():state().pots.remove_at(index)
 else:pot.catch=reserves.pop_front();pot.reserves=reserves
 if state().pots.size()<=2:state().legacy_pots=false
 if not records.complete(catch,keep):
  if removed:state().pots.insert(index,original)
  else:state().pots[index]=original
  state().legacy_pots=legacy_before
  return "Cannot collect yet: make space in your collection or use Release catch."
 var game=records.legacy.game;var activity=game.get_tree().root.get_node_or_null("FXActivity")
 if activity!=null:activity.event(game,"fish_catch","completed",0,{"species_id":str(catch.species),"fish_level":level(),"fish_weight":float(catch.kg),"fish_xp_gain":last_xp,"fish_trophy":1 if C.is_trophy(catch) else 0,"fish_kept":1 if keep else 0})
 return ("Kept " if keep else "Released ")+str(C.fish()[catch.species].name)+" • +%d fishing XP." % last_xp
func claim_all(index:int,utc:float,keep:bool)->String:
 if index<0 or index>=state().pots.size():return "Basket not found."
 var pot:Dictionary=state().pots[index]
 if utc<float(pot.ready):return "This basket is not ready."
 var count=basket_count(pot);var pool=str(pot.pool);var total_xp=0
 if keep and records.bag_count()+count>records.capacity():return "Not enough bag space for all %d fish. Inspect individually or release them." % count
 for n in count:
  if index>=state().pots.size() or str(state().pots[index].pool)!=pool:break
  var id=str(state().pots[index].catch.id);var message=claim(index,utc,keep)
  if not records.state().recent.has(id):return message
  total_xp+=last_xp
 return ("Kept " if keep else "Released ")+"%d fish • +%d fishing XP." % [count,total_xp]
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
 if not v.get("bait",{}) is Dictionary or v.get("bait",{}).size()>E.BAITS.size()-1:return false
 for id in v.get("bait",{}):
  var n=v.bait[id]
  if id not in E.BAITS or id=="basic" or not (n is int or n is float) or not is_finite(float(n)) or float(n)<0 or float(n)>1000:return false
 var version=v.get("mastery_version",1)
 if not (version is int or version is float) or not is_finite(float(version)) or float(version)!=floor(float(version)) or int(version) not in [1,2,VERSION]:return false
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
   if id not in TALENTS or not owned[id] is bool or not bool(owned[id]):return false
   if int(version)==VERSION:
    if xp<threshold(int(TALENTS[id].level)) or not prerequisites(id,owned):return false
    var group=str(TALENTS[id].get("exclusive",""))
    if not group.is_empty():
     for other in owned:
      if other!=id and str(TALENTS.get(other,{}).get("exclusive",""))==group:return false
  limit=5 if v.get("legacy_pots",false) or int(version)==2 else (3 if owned.get("keeper",false) else 2)+(1 if owned.get("pot_outpost",false) else 0)
 if not v.get("pots",[]) is Array or v.get("pots",[]).size()>limit:return false
 for pot in v.get("pots",[]):
  if not pot is Dictionary or pot.get("pool","") not in C.pools():return false
  if not pot.get("reserves",[]) is Array or pot.get("reserves",[]).size()>9:return false
  for catch in pot.get("reserves",[]):
   if not catch is Dictionary or catch.get("method","")!="pot" or catch.get("pool","")!=pot.pool:return false
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
