extends RefCounted
const CLINIC_SPAWN=Vector2(1960,790)
const POINTS={"food":Vector2(1150,1150),"healer":Vector2(1960,740),"wayfinder":Vector2(1580,790),"seedhouse":Vector2(900,1615)}
var clock:=0.0
var route_filter:=0
const FILTERS=["All adventures","Easy / first steps","Medium / challenging","Hard / expert"]
const SOLIDS=[Rect2(1556,936,188,91),Rect2(408,1320,274,170),Rect2(435,295,330,235),Rect2(1125,410,330,175),Rect2(1065,973,170,134),Rect2(1830,500,260,195),Rect2(1470,555,220,175),Rect2(780,1410,240,160)]
func step(delta:float)->void:clock+=delta
func blocked(point:Vector2)->bool:
 for solid in SOLIDS:
  if solid.has_point(point):return true
 for statue in [Vector2(950,1080),Vector2(1550,350)]:
  if point.distance_to(statue)<23:return true
 return false
func interact(game:Node)->bool:
 if bool(game.legacy.data.town.get("bakery",false)) and game.position_in_world.distance_to(preload("res://scripts/town_v176.gd").BREAD)<92:
  game.hint="E • Hearth & Crumb • claim adventure bread"
  if Input.is_action_just_pressed("interact"):game.legacy.open_page("town")
  return true
 for key in POINTS:
  if game.position_in_world.distance_to(POINTS[key])<90:
   game.hint="E • "+{"food":"Talk to Moss at the Food Stand","healer":"Talk to Tessa, town healer","wayfinder":"Plan a route with Scout Alden","seedhouse":"Talk to Rowan, the gardener"}[key]
   if Input.is_action_just_pressed("interact"):game.menu=key
   return true
 return false
func difficulty(label:String)->int:
 var text:=label.to_lower()
 if text.contains("easy") or text.contains("first"):return 1
 if text.contains("medium") or text.contains("moderate") or text.contains("challenging"):return 2
 return 3
func route_entries(game:Node)->Array:
 var result:Array=[]
 for id in game.manifest.get("regions",[]):
  if route_filter==0 or difficulty(str(game.realms.get(id,{}).get("difficulty_label","Hard")))==route_filter:result.append(id)
 return result
func draw_menu(game:Node)->void:
 var font:Font=ThemeDB.fallback_font
 game.draw_rect(Rect2(180,110,920,510),Color(.09,.16,.19,.97));game.draw_rect(Rect2(180,110,920,510),Color("#c7ad78"),false,3)
 var text:Array[String]=[]
 if game.menu=="healer":
  text=["TESSA'S HEALER HOUSE","Rest easy. When an adventure defeats you, I help you recover here.","You return as your chosen hero, ready for another journey.","The blue crates and masks are supplied by the Quarantine Medic.","Pack a Berry Bun for automatic healing, or a pear to clear poison.","Food never brings you back from a lethal hit. Dodge before you need it!","Enter / Continue: return to town."]
 else:
  var state:String=game.provisions.crop
  text=["ROWAN'S SEEDHOUSE","A little patience can grow something useful.","1 / Plant: pay 8 CC to sow an Antidote Pear seed.","Clear a realm or a co-op adventure to ripen your crop.","Return and choose 1 / Harvest to pack the pear for free.","Only one crop grows at a time. Your food slot must be empty to harvest.","Crop: "+state.capitalize()+"    Food: "+game.provisions.name_of(game.provisions.packed),"Enter / Continue: close. Your crop saves on this browser."]
 var y:=160.0
 for line in text:
  y=game._draw_wrapped(line,Vector2(215,y),835,24 if y==160 else 20,Color("#f2deb2") if y==160 else Color.WHITE)+25
 if game.menu=="seedhouse" and game.message_time>0:game._draw_wrapped(game.message,Vector2(215,580),810,16,Color("#cde1b5"))
func npc(c:Node2D,p:Vector2,coat:Color,kind:String)->void:
 if not Rect2(Vector2.ZERO,c.get_viewport_rect().size).grow(85).has_point(p):return
 c.draw_circle(p+Vector2(0,4),13,Color(0,0,0,.22))
 c.draw_rect(Rect2(p+Vector2(-11,-26),Vector2(22,27)),Color("#314049"));c.draw_rect(Rect2(p+Vector2(-9,-25),Vector2(18,25)),coat)
 c.draw_rect(Rect2(p+Vector2(-9,-7),Vector2(18,3)),Color("#d7c79d"))
 for side in [-1,1]:
  c.draw_rect(Rect2(p+Vector2(side*7-3,0),Vector2(6,6)),Color("#343b42"))
  c.draw_rect(Rect2(p+Vector2(side*12-2,-20+sin(clock*2)*1.5),Vector2(4,12)),Color("#dab993"))
 var skin:Color=Color("#dfc69e") if kind not in ["ram","healer"] else Color("#e6e1ce")
 c.draw_rect(Rect2(p+Vector2(-10,-43),Vector2(20,21)),Color("#3a3c43"));c.draw_rect(Rect2(p+Vector2(-9,-42),Vector2(18,19)),skin)
 for side in [-1,1]:c.draw_rect(Rect2(p+Vector2(side*4-1,-35),Vector2(2,3)),Color("#34323a"))
 if kind=="ram":
  for side in [-1,1]:c.draw_arc(p+Vector2(side*10,-36),6,0,TAU,12,Color("#967d57"),3)
 elif kind=="cook":
  c.draw_rect(Rect2(p+Vector2(-12,-50),Vector2(24,10)),Color("#ede5c4"))
  for n in 3:c.draw_circle(p+Vector2(-8+n*8,-50),5,Color("#ede5c4"))
 elif kind=="healer":
  # Tessa is a rabbit healer, with long ears and a cream muzzle.
  for side in [-1,1]:
   c.draw_rect(Rect2(p+Vector2(side*6-3,-61),Vector2(6,20)),Color("#e6e1ce"))
   c.draw_rect(Rect2(p+Vector2(side*6-1,-58),Vector2(2,13)),Color("#dab0b1"))
  c.draw_circle(p+Vector2(0,-29),5,Color("#f4edda"))
  c.draw_rect(Rect2(p+Vector2(-10,-44),Vector2(20,5)),Color("#dce6d6"));c.draw_rect(Rect2(p+Vector2(-9,-29),Vector2(18,7)),Color("#a0d2d2"))
  c.draw_line(p+Vector2(0,-20),p+Vector2(0,-10),Color("#f4f0dc"),3);c.draw_line(p+Vector2(-4,-15),p+Vector2(4,-15),Color("#f4f0dc"),3)
 else:c.draw_rect(Rect2(p+Vector2(-11,-46),Vector2(22,7)),Color("#745b47"))
func label(c:Node2D,font:Font,point:Vector2,text:String)->void:
 if not Rect2(Vector2.ZERO,c.get_viewport_rect().size).grow(200).has_point(point):return
 var size:Vector2=font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,16)
 if Rect2(point+Vector2(-size.x/2-8,-18),Vector2(size.x+16,24)).intersects(Rect2(c.position_in_world-c.camera-Vector2(25,60),Vector2(50,70))):return
 c.draw_rect(Rect2(point+Vector2(-size.x/2-8,-18),Vector2(size.x+16,24)),Color(.07,.15,.18,.9))
 c.draw_string(font,point+Vector2(-size.x/2,0),text,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#f3e1b5"))
func draw_on(c:Node2D,camera:Vector2,font:Font)->void:
 # Side tables display shields, tools and bottled supplies outside the stall.
 for table in [Vector2(1135,625),Vector2(1425,625)]:
  if not Rect2(camera,c.get_viewport_rect().size).grow(100).has_point(table):continue
  var p:Vector2=table-camera
  c.draw_rect(Rect2(p+Vector2(-25,-10),Vector2(50,13)),Color("#b39467"))
  for side in [-1,1]:c.draw_rect(Rect2(p+Vector2(side*20-2,3),Vector2(4,13)),Color("#6e5c43"))
  c.draw_circle(p+Vector2(-12,-15),8,Color("#8bafb6"));c.draw_line(p+Vector2(-12,-22),p+Vector2(-12,-9),Color("#d8c998"),2)
  c.draw_rect(Rect2(p+Vector2(5,-25),Vector2(8,14)),Color("#a4c7ad"));c.draw_rect(Rect2(p+Vector2(7,-30),Vector2(4,5)),Color("#e4c48c"))
 npc(c,Vector2(1290,635)-camera,Color("#a07b56"),"ram")
 npc(c,POINTS.food-camera,Color("#9b7f64"),"cook")
 npc(c,POINTS.healer-camera,Color("#779dac"),"healer")
 npc(c,POINTS.wayfinder-camera,Color("#59786c"),"human")
 npc(c,POINTS.seedhouse-camera,Color("#79915b"),"ram")
 for sign in [[Vector2(600,548),"CHARACTER HALL"],[Vector2(1290,517),"SUPPLY VENDOR • BARTLE"],[Vector2(1150,1198),"FOOD STAND"],[Vector2(1960,553),"HEALER HOUSE"],[Vector2(1580,613),"WAYFINDER LODGE"],[Vector2(900,1670),"SEEDHOUSE"]]:label(c,font,sign[0]-camera,sign[1])
 # Benches flank the statue plaza. Construction has a working carpenter.
 for place in [Vector2(820,1100),Vector2(1040,1030),Vector2(1760,720)]:
  if not Rect2(camera,c.get_viewport_rect().size).grow(100).has_point(place):continue
  var p:Vector2=place-camera
  for n in 3:c.draw_rect(Rect2(p+Vector2(-28,-19+n*7),Vector2(56,5)),Color("#b49268"))
  for side in [-1,1]:c.draw_rect(Rect2(p+Vector2(side*21-2,0),Vector2(4,13)),Color("#4f5148"))
 for tree in [Vector2(950,1080),Vector2(1550,350)]:
  if not Rect2(camera,c.get_viewport_rect().size).grow(200).has_point(tree):continue
  var p=tree-camera
  c.draw_texture_rect(preload("res://assets/town_ancient_tree.svg"),Rect2(p-Vector2(95,181),Vector2(190,218)),false)
 var carpenter:Vector2=Vector2(1510,1710)-camera
 npc(c,carpenter,Color("#a1825d"),"human")
 var hammer:Vector2=carpenter+Vector2(17,-26-sin(clock*4)*8)
 c.draw_line(carpenter+Vector2(11,-18),hammer,Color("#d1b080"),3);c.draw_rect(Rect2(hammer+Vector2(-5,-3),Vector2(13,7)),Color("#788b91"))
 if c.provisions.crop=="ready":
  var p:Vector2=POINTS.seedhouse-camera+Vector2(0,-67)
  c.draw_circle(p,12,Color("#cce2a2"));c.draw_string(font,p+Vector2(-6,5),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,17,Color("#354f3c"))
