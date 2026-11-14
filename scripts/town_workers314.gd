extends RefCounted

# Town civil hours, Monday through Sunday. Empty shifts are days off.
const POST_SHIFTS=[
 [[8,16.5],[9,13.5],[11,15]],[[7.5,16],[8.5,14],[9,12]],
 [[8.5,16.5],[10,15],[12,15.5]],[[7.5,16],[8.5,14],[9,12]],
 [[8,16],[9,12.5],[11,15]],[[9,13],[10.5,12],[]],[[],[],[]],
]
const MARKET_SHIFTS=[
 [[8,15],[9,14],[10,13]],[[7,15.5],[8,15],[8.5,12]],
 [[9,16],[10,14],[]],[[7,16],[8,15],[9,14]],
 [[8.5,16],[10,15],[12,14]],[[8,17],[9,16],[10,15]],[[11,14],[],[]],
]
# Stops contain position, time spent working there, and task on departure.
const POST_ROUTES=[
 ["post_sort",[[Vector2(550,1516),1,""],[Vector2(550,1542),0,""],[Vector2(486,1544),4,"parcel"],[Vector2(426,1557),5,""],[Vector2(474,1575),2,""],[Vector2(550,1542),0,""]]],
 ["post_dispatch",[[Vector2(550,1516),1,""],[Vector2(568,1538),0,"parcel"],[Vector2(642,1543),0,"parcel"],[Vector2(682,1555),6,""],[Vector2(636,1576),2,""],[Vector2(575,1556),0,""]]],
 ["post_rounds",[[Vector2(550,1516),2,""],[Vector2(536,1540),0,""],[Vector2(580,1562),5,""],[Vector2(606,1585),4,"parcel"],[Vector2(526,1580),0,"parcel"],[Vector2(517,1545),0,""]]],
]
const MARKET_ROUTES=[
 ["market_load",[[Vector2(-474,694),1,""],[Vector2(-474,720),4,"parcel"],[Vector2(-370,749),0,"parcel"],[Vector2(-260,750),6,""],[Vector2(-365,775),1,""],[Vector2(-480,761),0,""]]],
 ["market_sort",[[Vector2(128,706),1,""],[Vector2(128,735),5,""],[Vector2(51,750),3,"parcel"],[Vector2(-79,754),6,""],[Vector2(22,785),2,""],[Vector2(143,766),0,""]]],
 ["market_cart",[[Vector2(-321,727),1,"cart_loaded"],[Vector2(-320,753),3,"cart_loaded"],[Vector2(-228,775),0,"cart_loaded"],[Vector2(-111,782),7,"cart"],[Vector2(-209,797),0,"cart"],[Vector2(-305,779),0,"cart"]]],
]
const SPEED=54.0

static func active(zone:String,hour:float,weekday:int)->Array[Dictionary]:
 var routes:=POST_ROUTES if zone=="post" else MARKET_ROUTES
 var shifts:Array=(POST_SHIFTS if zone=="post" else MARKET_SHIFTS)[posmod(weekday,7)]
 var workers:Array[Dictionary]=[]
 for index in routes.size():
  var shift:Array=shifts[index]
  if shift.is_empty() or hour<float(shift[0]) or hour>=float(shift[1]):continue
  var worker:=sample(routes[index][1],(hour-float(shift[0]))*3600.0,(float(shift[1])-float(shift[0]))*3600.0)
  worker.id=routes[index][0]
  workers.append(worker)
 return workers

static func sample(stops:Array,elapsed:float,shift_seconds:float)->Dictionary:
 var duration:=0.0
 for i in stops.size():
  var at:Vector2=stops[i][0]
  duration+=float(stops[i][1])+at.distance_to(stops[(i+1)%stops.size()][0])/SPEED
 # Fit complete loops inside the shift so workers end at the doorway.
 var cycles:=maxi(1,roundi(shift_seconds/duration))
 var phase:=fposmod(elapsed*cycles/shift_seconds,1.0)*duration
 for i in stops.size():
  var stop:Array=stops[i]
  var at:Vector2=stop[0]
  var next:Vector2=stops[(i+1)%stops.size()][0]
  var wait:float=stop[1]
  var task:=str(stop[2])
  if phase<wait:return {"pos":at,"moving":false,"task":task if task.begins_with("cart") else ""}
  phase-=wait
  var travel:=at.distance_to(next)/SPEED
  if phase<travel:return {"pos":at.lerp(next,phase/travel),"moving":true,"task":task}
  phase-=travel
 return {"pos":stops[0][0],"moving":false,"task":""}
