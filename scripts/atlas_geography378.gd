extends RefCounted
## Schematic chart coordinates. Only the atlas uses these, never world travel/physics.
const TOWN=Vector2(283,205)
const WILDS=Vector2(512,205)
const TOWN_RIVER=[Vector2(295,154),Vector2(301,180),Vector2(301,207),Vector2(295,233),Vector2(305,264),Vector2(325,293)]
const WILDS_RIVER=[Vector2(529,93),Vector2(549,113),Vector2(543,137),Vector2(562,154),Vector2(574,176),Vector2(568,197),Vector2(572,216),Vector2(586,244),Vector2(605,279)]
const DIVIDE=[Vector2(435,68),Vector2(455,99),Vector2(450,132),Vector2(471,161),Vector2(466,188),Vector2(474,230),Vector2(460,259)]
const EAST_ROAD=[TOWN,Vector2(300,207),Vector2(338,210),Vector2(365,207),Vector2(401,213),Vector2(438,207),Vector2(480,211),WILDS]
const NORTH_TRAIL=[Vector2(338,210),Vector2(338,184),Vector2(346,165)]
const SOUTH_TRAIL=[TOWN,Vector2(267,218),Vector2(263,237),Vector2(258,251)]
const TOWN_BRIDGE=Rect2(284,203,35,8)
# Atlas-only tributaries, reserved for later fishing-area design. No active pools yet.
const STREAMS=[
 {"id":"ridge_lake_run","points":[Vector2(435,68),Vector2(420,78),Vector2(412,91),Vector2(391,101)],"outlet":"lake"},
 {"id":"ridge_wilds_upper","points":[Vector2(450,132),Vector2(471,143),Vector2(490,150),Vector2(517,164),Vector2(562,154)],"outlet":"wilds_river"},
 {"id":"ridge_wilds_lower","points":[Vector2(474,230),Vector2(490,238),Vector2(519,242),Vector2(545,244),Vector2(586,244)],"outlet":"wilds_river"}
]
const WEST_HILLS=[
 [Vector2(22,72),.85],[Vector2(68,64),.72],[Vector2(111,81),1.15],
 [Vector2(43,120),1.18],[Vector2(93,135),.72],[Vector2(133,117),.8],
 [Vector2(17,172),.9],[Vector2(58,187),1.08],[Vector2(113,178),.8],
 [Vector2(148,220),.68],[Vector2(29,236),.82],[Vector2(81,249),1.08],[Vector2(143,263),.7]
]
const SNOW_PEAKS=[[Vector2(615,79),1.0],[Vector2(626,112),.9],[Vector2(620,151),1.3],[Vector2(629,188),1.15],[Vector2(619,223),1.1],[Vector2(632,254),.9]]
