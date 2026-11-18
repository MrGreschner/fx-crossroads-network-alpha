extends RefCounted
const Streets=preload("res://scripts/town_plan.gd")
const Town311=preload("res://scripts/town_layout311.gd")
## Civic notice board and read-only atlas. Pin positions are world entrances.
const BOARD=Town311.ATLAS_BOARD
const FOOTPRINT=Rect2(BOARD-Vector2(54,21),Vector2(108,29))
const APPROACH=BOARD+Vector2(0,32)
const CATEGORIES={"Adventure":"#b97049","Services":"#4d857d","Landmark":"#8b6c9c","Homes":"#677f4d"}
const ROUTES=[
 ["Crossroads Town",Vector2(250,193),"Regional hub","Find the marina for voyages or head through the east bridge toward Wayfarer Wilds."],
 ["Oldwater Lake",Vector2(208,75),"Upstream • north","Take the riverside trail from the Gatherers’ Lodge to the Oldwater Bay waypoint. The town marina offers ferries outside winter."],
 ["Coast & Open Sea",Vector2(202,306),"Downstream • south","Use the south trail waypoint by the marina or take a warm-season ferry to Tidecross Harbour. Launch sea voyages at the coastal pier with a Deep Sea Rod."],
 ["Wayfarer Wilds",Vector2(460,177),"East • over the bridge","Follow the town road east over the river. Continue into the forest to find the Wayfarer Wilds entrance."]
]
const PUBLIC=[
 ["Character Hall",Vector2(600,570),"Services","Choose and inspect heroes.","hall"],
 ["Supply Vendor • Bartle",Vector2(1290,635),"Services","Stock up on equipment and consumables.","supply"],
 ["Realm Portal",Vector2(900,670),"Adventure","Choose a realm or expedition from the civic square.",""],
 ["Elder Ram",Vector2(740,680),"Landmark","The town guide in the civic square.",""],
 ["Gladiator Arena",Vector2(130,1280),"Adventure","Arena entrance on the south side of the stadium.",""],
 ["North Gate Defence",Vector2(900,300),"Adventure","Defend the northern gate with your party.",""],
 ["Cave Descent",Town311.DESCENT_ENTRY,"Adventure","Enter the caves below the western cliffs.",""],
 ["Training Grounds",Vector2(1650,1050),"Adventure","Practise movement and abilities.","training"],
 ["Battlegrounds",Town311.BATTLE_ENTRY,"Adventure","Army battles on the far side of the north gate.",""],
 ["Wayfarer Wilds trail",Vector2(2940,1160),"Adventure","Cross the eastern bridge and continue to the forest entrance.",""],
 ["Challenge Lodge",Vector2(-1030,540),"Adventure","Challenge boards and trials on the western approach.",""],
 ["Oldwater Bay waypoint",Streets.BAY_TRAILHEAD,"Landmark","Pass the apple tree at the Gatherers’ Lodge and follow the east bank north to this year-round waypoint.",""],
 ["Tidecross Harbour waypoint",Streets.HARBOUR_TRAILHEAD,"Landmark","Follow the marina path past Tidekeeper Cottage to this year-round waypoint.",""],
 ["Gather Lodge",Vector2(2800,655),"Services","Gathering supplies and activities east of the river.","gather"],
 ["Community Records",Town311.RECORDS+Vector2(0,40),"Services","Browse community rankings and records.",""],
 ["Adventure Board",Vector2(820,935),"Adventure","Browse the adventures you can head out on.",""],
 ["Deepwell Mine",Vector2(-1080,800),"Services","Manage your mining operation.",""],
 ["Deepwell Exchange",Vector2(-815,825),"Services","Sell ore and gems and manage mining supplies.",""],
 ["Crossroads Market",Vector2(-180,775),"Services","Enter the business district. Makers & Wares sits beside the market.","market"],
 ["Makers & Wares",Vector2(125,720),"Services","Market stall next to the business district.",""],
 ["Market Office",Vector2(-580,490),"Services","Market services on the western road.","office"],
 ["Crossroads Studio",Vector2(-530,1375),"Services","Create and test your own heroes and abilities.",""],
 ["Crossroads Academy",Vector2(-1000,2080),"Services","Visit the academy in the southwest.",""],
 ["Gleam Atelier",Vector2(600,1155),"Services","Browse cosmetics and titles.","atelier"],
 ["Pondside Food Stand",Vector2(1150,1150),"Services","Buy a meal for your next adventure.","food"],
 ["Healer House",Vector2(1960,740),"Services","Healer and supply services.","healer"],
 ["Wayfinder Lodge",Vector2(1580,790),"Services","Find routes and realm information.","wayfinder"],
 ["Seedhouse",Vector2(900,1615),"Services","Indoor growing beds, Rowan’s seed shop and private plots.","seedhouse"],
 ["Squirrel Post",Vector2(550,1550),"Services","Profiles, post and food parcels.","post"],
 ["Apothecary",Vector2(-100,1680),"Services","Browse brews and supplies.","apothecary"],
 ["Mistglass Spire",Vector2(2090,1165),"Adventure","The arcane tower by the east bridge.","tower"],
 ["Ramguard Barracks",Vector2(1375,1520),"Services","Visit the town guard.","barracks"],
 ["Wayfarer’s Rest",Vector2(1370,1760),"Landmark","Tea, games and travellers’ stories.","pavilion"],
 ["Town Notices",Vector2(1800,1785),"Landmark","Read the local events board.",""],
 ["Ripple & Reel",Vector2(2000,2020),"Services","Fishing shop, gear and aquarium.","fishing"],
 ["Ripple & Reel Marina",Vector2(1860,2300),"Adventure","Board lake and coastal voyages here.",""],
 ["Marina Bait Stall",Vector2(1515,2362),"Services","Daily bait stock by the harbour.","bait"],
 ["Tidekeeper Cottage",Vector2(1405,2660),"Homes","Harbourside home south of the bait stall.",""],
 ["Lookout",Vector2(1720,420),"Landmark","Watch tower on the northern service street.",""],
 ["Town Pond",Vector2(200,365),"Landmark","Fish or look for seasonal visitors by the water.",""],
 ["Wishing Well",Vector2(1120,730),"Landmark","Make a wish beside the civic square.",""],
 ["Starlace Tree",Town311.STARLACE,"Landmark","The blue tree beside this map board.",""],
 ["West Fountain",Town311.WEST_FOUNTAIN,"Landmark","The courtyard between Deepwell Mine and Cave Descent.",""],
 ["Wayfarer’s Rest Fountain",Vector2(1494,1828),"Landmark","Fountain in the courtyard beside the pavilion.",""],
 ["Forest Camp",Vector2(2890,1450),"Landmark","The campfire clearing beyond the east bridge.",""],
 ["Pondside Bakery",Vector2(1360,1140),"Services","A town project for provisions.","bakery","bakery"],
 ["Fellowship Hall",Vector2(1800,1550),"Services","A town project for team adventures.","fellowship","fellowship"],
 ["Relay Workshop",Vector2(325,2030),"Services","A town project for supplies and meals.","relay","relay"],
 ["River Watermill",Vector2(2175,1580),"Landmark","The waterwheel town project.","mill","mill"],
 ["Quest Reading Room",Vector2(1070,1760),"Landmark","A town project with a quest preparation guide.","reading","library"]
]
static var board_art:Texture2D

static func blocked(point:Vector2)->bool:
 return FOOTPRINT.grow(7).has_point(point)

static func entries(g:Node)->Array:
 var rows:Array=PUBLIC.duplicate(true)
 var plans:Dictionary=g.legacy.data.get("town",{})
 for row in rows:
  if row.size()>5 and not bool(plans.get(row[5],false)):row[3]+=" Planned site."
  elif row.size()>5:row[3]+=" Built."
 for home in preload("res://scripts/town_neighborhood.gd").HOMES:
  rows.append([home.name,home.door,"Homes","Residential building.",""])
 return rows

static func interact(g:Node)->bool:
 if g.position_in_world.distance_to(APPROACH)>68:return false
 g.hint="E • Read the town and region maps"
 if Input.is_action_just_pressed("interact"):
  g.presentation.window("Crossroads Atlas","town_atlas")
  var panel=preload("res://scripts/town_atlas_panel307.gd").new()
  panel.setup(g,entries(g),ROUTES,CATEGORIES)
 return true

static func draw_on(g:Node2D,camera:Vector2)->void:
 if not Rect2(camera,g.VIEW).grow(110).has_point(BOARD):return
 if board_art==null:
  var image=Image.new()
  if image.load_svg_from_string(FileAccess.get_file_as_string("res://assets/atlas307/board.svg"))!=OK:return
  board_art=ImageTexture.create_from_image(image)
 var at=BOARD-camera
 g.draw_texture_rect(board_art,Rect2(at-Vector2(74,106),Vector2(148,118)),false)
 g.draw_string(ThemeDB.fallback_font,at+Vector2(-60,-87),"TOWN MAP",HORIZONTAL_ALIGNMENT_CENTER,120,8,Color("#f3dfa9"))
