extends RefCounted
## The atlas reads the same anchors and shoreline data as travel and collision.
const GEO=preload("res://scripts/atlas_geography378.gd")
const BAY=preload("res://scripts/oldwater_bay361.gd")
const PORT=preload("res://scripts/tidecross359.gd")
const COAST=preload("res://scripts/tidecross_coast360.gd")
const STREETS=preload("res://scripts/town_plan.gd")
const AREAS=["town","bay","harbour"]
const TITLES=["Crossroads","Oldwater Bay","Tidecross Harbour"]
const FIELDS={"town":Rect2(-1450,-480,4850,3390),"bay":BAY.BOUNDS,"harbour":Rect2(1080,2820,1820,1490)}
# Regional illustration positions, not world coordinates or teleport targets.
const ROUTES=[
 ["Crossroads Town",GEO.TOWN,"Main town • riverside hub","Crossroads stands beside the river. Follow the north riverside trail to Oldwater Bay or the south trail to Tidecross Harbour. The forest begins across the eastern bridge."],
 ["Oldwater Bay",Vector2(386,125),"Lakeside outpost • northeast","Follow the riverside trail from the Gatherers’ Lodge to the Oldwater waypoint. Walk through the bay forest to the Outback Cabin and its two docks."],
 ["Tidecross Harbour",Vector2(246,280),"Harbour settlement • south","Follow the south trail past Tidekeeper Cottage and use its waypoint. The cliffside port has a trading post, bait stall, river ferry and Sea Expeditions office."],
 ["Wayfarer Wilds",GEO.WILDS,"Woodland settlement • east","Follow the forest trail over the middle ridge. Wayfarer Wilds lies inland west of its own river. Beyond the river and a forest belt, distant snowy mountains rise to the east. Small ridge streams feed the two separate watersheds."],
 ["Oldwater Lake",Vector2(258,78),"Lake adventure • north","Begin a lake adventure at the Outback Dock or the town marina outside winter. In winter the bay freezes; use the walking route for ice fishing."],
 ["Open Sea",Vector2(477,299),"Sea expedition • south","Speak to Harbourmaster Nell at Tidecross’s Sea Expeditions office. A Deep Sea Rod is required. Sea departures stay open through winter."]
]
static func current_area(p:Vector2)->String:
 if PORT.is_cove(p):return "bay"
 if PORT.is_port(p):return "harbour"
 return "town"
static func route_area(index:int)->String:return ["town","bay","harbour","town","bay","harbour"][clampi(index,0,5)]
static func locations(g:Node,area:String,town_rows:Array)->Array:
 if area=="town":return town_rows.duplicate(true)
 var winter=g.town_life.calendar.season()=="Winter"
 var ferry="River ferry paused in winter; use the trail." if winter else "Warm-season ferry back to the Crossroads town marina."
 if area=="bay":
  var result=[
   ["To Crossroads • forest trail",BAY.TRAIL_EXIT,"Travel","Year-round waypoint back to the north riverside trail in town.",""],
   ["Outback Cabin",BAY.CABIN_DOOR,"Landmark","Cabin log and an occasional visiting angler. The path reaches the cabin from the southern forest.",""],
   ["Outback Dock • lake adventures",BAY.BERTH,"Travel","Lake departures paused while the bay is frozen." if winter else "Begin and return from Oldwater Lake adventures at this boat.",""],
   ["River ferry • Crossroads",BAY.FERRY,"Travel",ferry,""],
   ["Cabin campfire",BAY.CAMP,"Landmark","A sheltered fire beside the cabin path.",""]
  ]
  var pools=preload("res://scripts/fishing_catalog.gd").pools()
  if winter:
   for id in BAY.POOLS:
    var spot=pools[id].duplicate(true);spot.id=id;spot=BAY.spot(spot,g.town_life.calendar.day_number)
    result.append([str(spot.name).replace("Oldwater Cove","Oldwater Bay"),Vector2(spot.bank[0],spot.bank[1]),"Fishing","Winter ice hole. These holes rotate through five positions every two Crossroads weeks.",""])
  else:
   var p:Array=pools.oldwater_shore.bank
   result.append(["Shore Dock • fishing",Vector2(p[0],p[1]),"Fishing","Cast from the shore end of the Outback Dock. Separate from the lake-adventure boat.",""])
  return result
 var p:Array=preload("res://scripts/fishing_catalog.gd").pools().tidecross_saltwater.bank
 var result=[
  ["To Crossroads • south trail",PORT.HARBOUR_TRAIL_EXIT,"Travel","Year-round waypoint to the south trail beside Tidekeeper Cottage in town.",""],
  ["Sea Expeditions • Nell",PORT.SEA_OFFICE,"Travel","Talk to Harbourmaster Nell to begin a sea expedition. The harbour stays open in winter.",""],
  ["Saltwater fishing pier",Vector2(p[0],p[1]),"Fishing","The east fishing pier is separate from the west Sea Expeditions pier.",""],
  ["River ferry • Crossroads",PORT.FERRY,"Travel",ferry,""],
  ["Dockside Bait",PORT.BAIT,"Services","Fishing bait beside the saltwater pier.",""],
  ["Tidecross Trading Post",PORT.TRADER,"Services","Rotating seeds and ingredients, bought with Glimmers.",""],
  ["Old Sailor’s Hut • Ives",PORT.SAILOR,"Landmark","Captain Ives tells stories of the sea at his hut above the coast.",""]
 ]
 for i in PORT.RESIDENTS.size():result.append([str(PORT.BUILDINGS[i][2]),PORT.RESIDENTS[i][2],"Homes","A resident’s cliffside cottage. Paths join the quay road.",""])
 return result
static func footprints(area:String)->Dictionary:
 if area=="bay":return {"Outback Cabin":BAY.CABIN}
 if area=="harbour":
  var result={}
  for b in PORT.BUILDINGS:result[str(b[2])]=b[1]
  result["Old Sailor’s Hut • Ives"]=PORT.BUILDINGS[4][1];result["Sea Expeditions • Nell"]=PORT.OFFICE_FRAME
  return result
 return {}
static func roads(area:String)->Array:
 if area=="bay":return BAY.ROUTES
 if area=="harbour":
  COAST.prepare();var result=[]
  for route in COAST.layout.roads:
   var points=[]
   for p in route[1]:points.append(Vector2(p[0],p[1]))
   result.append(points)
  result.append([PORT.HARBOUR_TRAIL_EXIT,Vector2(1475,3020)])
  return result
 return STREETS.ROADS+preload("res://scripts/town_neighborhood.gd").ROADS
