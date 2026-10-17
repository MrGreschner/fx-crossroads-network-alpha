extends RefCounted
const WEATHER=preload("res://scripts/town_weather.gd")
const BAITS={"basic":{"name":"Bare hook • free","group":"","needs":{},"cost":0,"description":"No bait needed. Always free; every rod species remains possible in its habitat and feeding window."},"worms":{"name":"Scented Worms","group":"bottom","needs":{"worm":1,"mint":1},"cost":12,"description":"Bottom feeders · gather worms at Willow Brook; mint can also be grown."},"insects":{"name":"Glowwing Bait","group":"surface","needs":{"firefly":1,"petal":1},"cost":18,"description":"Surface feeders · lodge insects and garden petals."},"dough":{"name":"Sunleaf Dough","group":"school","needs":{"sunleaf":2},"cost":12,"description":"Schooling fish · garden harvests or meadow gathering."},"scraps":{"name":"River Scraps","group":"predator","needs":{"mooncap":1,"willow":1},"cost":18,"description":"Predators and scavengers · brew a scented mix, or buy at the market."}}
static func context(game:Node)->Dictionary:
 if game.get("town_life")!=null:
  var result=WEATHER.context(game.town_life.calendar.now);result.weather=game.town_life.calendar.weather();return result
 return WEATHER.context(Time.get_unix_time_from_system())
static func open(spec:Dictionary,ctx:Dictionary,method:String="rod")->bool:
 if method not in spec.get("methods",["rod"]):return false
 if not ctx.is_empty():
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
 return " · ".join(parts)
static func weight(spec:Dictionary,ctx:Dictionary,method:String,bait:String,level:int,rarity_bonus:float=0)->float:
 if not open(spec,ctx,method):return 0
 var w=float(spec.chance)
 if spec.rarity not in ["Common"]:w*=(1.0+.10*clampf((level-1)/39.0,0,1))*(1.0+rarity_bonus)
 var group=str(BAITS.get(bait,BAITS.basic).group)
 if not group.is_empty():w*=2.0 if str(spec.get("group",""))==group else .8
 return w
