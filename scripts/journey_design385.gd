extends RefCounted
## Authored layouts use the existing quiet materials and scenery, without new game modes.
const Art=preload("res://scripts/wayfarer_art305.gd")
const COURSES={
 "beaver":{"theme":"riverbank braces","prop":"waterwheel","points":[Vector2(650,500),Vector2(1070,760),Vector2(1480,520)]},
 "drum":{"theme":"rehearsal stage","prop":"bell","points":[Vector2(720,650),Vector2(1000,650),Vector2(1290,650)]},
 "magnet":{"theme":"polarity workshop","prop":"valve","points":[Vector2(700,650),Vector2(1000,650),Vector2(1300,650)]},
 "spindle":{"theme":"winding track","prop":"rail","points":[Vector2(660,430),Vector2(1090,390),Vector2(1510,650),Vector2(1100,990),Vector2(650,930)]},
 "cloudloom":{"theme":"sky terrace","prop":"standing_stone","points":[Vector2(640,420),Vector2(1380,420),Vector2(1380,950),Vector2(640,950)]},
 "caelum":{"theme":"reflection court","prop":"arch","points":[Vector2(700,500),Vector2(700,850),Vector2(1250,850)]},
 "gopher":{"theme":"tunnel survey","prop":"rocks","points":[Vector2(850,650),Vector2(1260,880),Vector2(1620,650)]},
 "regent":{"theme":"memory gallery","prop":"standing_stone","points":[Vector2(520,650),Vector2(1000,650)]},
 "mantis":{"theme":"counter circle","prop":"seal","points":[Vector2(980,650)]},
 "tempo":{"theme":"near and far rings","prop":"bell","points":[Vector2(680,440),Vector2(1240,460),Vector2(1000,940)]},
 "anjali":{"theme":"archery lanes","prop":"rail","points":[Vector2(750,430),Vector2(1020,430),Vector2(1310,430),Vector2(1510,720),Vector2(1180,1020)]},
 "little_menace":{"theme":"root passages","prop":"roots","points":[Vector2(800,650),Vector2(1150,650),Vector2(1500,650)]},
 "santa":{"theme":"delivery sorting yard","prop":"tent","points":[Vector2(680,440),Vector2(1060,430),Vector2(1460,460),Vector2(1440,990),Vector2(850,1000)]},
 "reindeer":{"theme":"snow flight circuit","prop":"arch","points":[Vector2(670,470),Vector2(1190,410),Vector2(1530,760),Vector2(1050,1020)]},
 "nutcracker":{"theme":"parade lines","prop":"lantern","points":[Vector2(730,430),Vector2(1050,430),Vector2(1390,430),Vector2(1390,980),Vector2(730,980)]},
 "finch_frost":{"theme":"frost spear corridor","prop":"rocks","points":[Vector2(790,650),Vector2(970,650),Vector2(1150,650),Vector2(1330,650),Vector2(1510,650)]},
 "wick":{"theme":"hollow lantern walk","prop":"lantern","points":[Vector2(650,440),Vector2(1010,800),Vector2(1510,1000)]}
}
static func course(id:String)->Dictionary:
 return COURSES[id].duplicate(true)
static func draw(g:Node,d:Dictionary)->void:
 var cam:Vector2=g.camera
 var route=PackedVector2Array([Vector2(420,650)])
 for p in d.points:route.append(p)
 g.draw_polyline(PackedVector2Array(Array(route).map(func(p):return p-cam)),Color(.65,.55,.4,.18),56)
 # Landmark silhouettes are off the movement lanes; usable props retain their objective owner.
 for at in [Vector2(210,410),Vector2(1770,440),Vector2(210,1120),Vector2(1760,1100)]:
  var tex=Art.texture(str(d.prop))
  if tex!=null:g.draw_texture_rect(tex,Rect2(at-cam-Vector2(48,80),Vector2(96,100)),false)
 if g.journey_id=="beaver":
  g.draw_texture_rect(Art.repeat_texture("river"),Rect2(Vector2(1640,280)-cam,Vector2(160,900)),true)
 if g.journey_id=="drum":g.draw_texture_rect(Art.repeat_texture("wood"),Rect2(Vector2(620,540)-cam,Vector2(830,200)),true)
 if g.journey_id=="anjali":
  g.draw_texture_rect(Art.repeat_texture("road"),Rect2(Vector2(620,350)-cam,Vector2(960,170)),true)
  for x in [730,1000,1290]:g.draw_line(Vector2(x,350)-cam,Vector2(x,1100)-cam,Color(.77,.70,.52,.3),2)
 if g.journey_id=="tempo":
  for at in d.points:
   for radius in [95,190]:g.draw_arc(at-cam,radius,0,TAU,40,Color(.57,.74,.74,.25),2)
static func duel_arena(g:Node,id:String)->void:
 var library=load("res://scripts/hero_journeys373.gd").catalog()
 var spec:Dictionary=library[id]
 g.world_terrain=str(spec.ground)
 g.art.path=Art.repeat_texture(str(spec.ground))
 # Different tactical arrangements: open shooting lanes, side cover or a broken centre.
 var number=library.keys().find(id)
 var arrangements=[[],[Rect2(650,200,100,150),Rect2(650,650,100,150)],[Rect2(300,170,200,70),Rect2(900,760,200,70)],[Rect2(650,150,90,110),Rect2(650,740,90,110),Rect2(160,450,70,100),Rect2(1170,450,70,100)]]
 for rect in arrangements[number%arrangements.size()]:
  g.field_obstacles.append({"pos":rect.get_center(),"radius":float(minf(rect.size.x,rect.size.y))*.5,"kind":"rock"})
 g._rebuild_grid();g.terrain_cache.reset()
