extends RefCounted
const WEATHER=preload("res://scripts/town_weather.gd")
const BAITS={"basic":{"name":"Bare hook \u2022 free","group":"","needs":{},"cost":0,"description":"Free fishing in each habitat and feeding window. Some exceptional Fabled fish require a specific bait."},"worms":{"name":"Scented Worms","group":"bottom","needs":{"worm":1,"mint":1},"cost":12,"description":"Bottom feeders \u00b7 gather worms at Willow Brook; mint can also be grown."},"insects":{"name":"Glowwing Fish bait","group":"surface","needs":{"firefly":1,"petal":1},"cost":18,"description":"Surface feeders \u00b7 lodge insects and garden petals."},"dough":{"name":"Sunleaf Dough","group":"school","needs":{"sunleaf":2},"cost":12,"description":"Schooling fish \u00b7 garden harvests or meadow gathering."},"scraps":{"name":"River Scraps","group":"predator","needs":{"mooncap":1,"willow":1},"cost":18,"description":"Predators and scavengers \u00b7 brew a scented mix, or buy at the market."},"honeygrain":{"name":"Honeygrain Paste","group":"","needs":{"sunleaf":2,"petal":1},"cost":15,"description":"Freshwater blend: attracts River Sprat, Russet River Chub and Olive Lake Perch. Does not alter feeding windows."},"moonmoth":{"name":"Moonmoth Lure","group":"","needs":{"firefly":2,"mooncap":1},"cost":24,"description":"Freshwater scent: attracts Midnight Glassfin, Violet Lake Eel and Bluebar Trout. Night-only fish still require night."},"saltflash":{"name":"Saltflash Strips","group":"","needs":{"mint":1,"petal":2},"cost":27,"regions":["voyage_coast"],"description":"Ocean only: attracts Copperback Mackerel, Squallfin Marlin and Pelagic Monarch. Rain requirements still apply."},"kelp_crumble":{"name":"Kelp Crumble","group":"","needs":{"sunleaf":2,"willow":1},"cost":21,"regions":["voyage_coast"],"description":"Ocean only: attracts Blue Spiny Lobster, Copper Reef Lobster and Crown Reef Crab; ideal for cages."},"roe":{"name":"Fish Roe","group":"","needs":{"mint":1},"cost":18,"methods":["pot"],"fish_source":"ordinary","description":"Cages/baskets only: attracts ocean lobsters and crabs plus freshwater crayfish. Craft with one ordinary Common/Uncommon kept rod fish and River Mint. Displayed fish, favourites and trophies are protected."}}
static func context(game:Node)->Dictionary:
 if game.get("voyage")!=null and game.voyage.active:return game.voyage.context()
 if game.get("town_life")!=null:
  var result=WEATHER.context(game.town_life.calendar.now);result.weather=game.town_life.calendar.weather();return result
 return WEATHER.context(Time.get_unix_time_from_system())
static func open(spec:Dictionary,ctx:Dictionary,method:String="rod",bait:String="")->bool:
 if not bait.is_empty() and spec.has("required_bait") and bait!=str(spec.required_bait):return false
 if method not in spec.get("methods",["rod"]):return false
 if ctx.has("hour"):
  if spec.has("days"):
   var match_day=false
   for day in spec.days:
    if int(day)==int(ctx.weekday):match_day=true
   if not match_day:return false
  if spec.has("weather") and str(ctx.weather) not in spec.weather:return false
  if spec.has("hours"):
   var in_window=false
   for span in spec.hours:
    var h=float(ctx.hour);var a=float(span[0]);var b=float(span[1])
    if (h>=a and h<b) if a<b else (h>=a or h<b):in_window=true
   if not in_window:return false
 return true
static func window_text(spec:Dictionary)->String:
 var parts=[]
 if spec.has("hours"):
  for span in spec.hours:parts.append("%02d:00–%02d:00" % [int(span[0]),int(span[1])])
 else:parts.append("Any hour")
 if spec.has("days"):
  var days=[]
  for day in spec.days:days.append(["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"][int(day)].left(3))
  parts.append("/".join(days))
 if spec.has("weather"):parts.append("/".join(spec.weather))
 if spec.has("required_bait"):parts.append("Requires "+str(BAITS.get(str(spec.required_bait),{}).get("name",spec.required_bait)))
 if spec.has("favoured_bait"):
  var favoured=[]
  for bait in spec.favoured_bait:favoured.append(str(BAITS[bait].name))
  parts.append("Favours "+" / ".join(favoured))
 return " · ".join(parts)
static func weight(spec:Dictionary,ctx:Dictionary,method:String,bait:String,level:int,rarity_bonus:float=0)->float:
 if not bait_usable(bait,method,str(ctx.get("region",""))) or not open(spec,ctx,method,bait):return 0
 var w=float(spec.chance)
 if bait in spec.get("favoured_bait",[]):w*=3.0
 if spec.rarity not in ["Common"]:w*=(1.0+.10*clampf((level-1)/39.0,0,1))*(1.0+rarity_bonus)
 var group=str(BAITS.get(bait,BAITS.basic).group)
 if not group.is_empty():w*=2.0 if str(spec.get("group",""))==group else .8
 return w

static func bait_usable(bait:String,method:String,region:String)->bool:
 var spec:Dictionary=BAITS.get(bait,{})
 return not spec.is_empty() and method in spec.get("methods",["rod","net","pot"]) and (not spec.has("regions") or region in spec.regions)
