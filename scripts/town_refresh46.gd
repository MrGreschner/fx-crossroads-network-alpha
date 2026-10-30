extends RefCounted
## Small culled props, shared collision footprints and a scheduled social destination.
const PAVILION=Rect2(1260,1615,220,100)
const REST=Vector2(1370,1760)
const FOUNTAIN=Vector2(1460,1880)
const NOTICE=Vector2(1800,1740)
const MASSIF=Rect2(-1650,465,450,870)
const POSTS=[Vector2(-1210,1260),Vector2(-945,1260)]
static func reserved(p:Vector2)->bool:return MASSIF.grow(100).has_point(p) or Rect2(1220,1545,310,255).has_point(p) or p.distance_to(FOUNTAIN)<90 or p.distance_to(NOTICE)<65
static func blocked(p:Vector2)->bool:
 if p.distance_to(FOUNTAIN)<47 or Rect2(NOTICE-Vector2(28,20),Vector2(56,35)).has_point(p):return true
 if Rect2(-1700,360,500,990).has_point(p) or PAVILION.grow(6).has_point(p):return true
 for at in POSTS:
  if p.distance_to(at)<15:return true
 return false
static func interact(g:Node)->bool:
 if g.position_in_world.distance_to(NOTICE+Vector2(0,45))<65:
  g.hint="E • Town notices • what’s happening today"
  if Input.is_action_just_pressed("interact"):
   g.presentation.window("TOWN NOTICES","town_notices")
   g.presentation.label(g.presentation.content,g.town_life.calendar.label(),20)
   var notices=["Faraway Flavours • 10 am–3 pm. Tea at Wayfarer’s Rest • noon–1 pm.","Marina deliveries • 10 am–noon. Board games at Wayfarer’s Rest • 6–8 pm.","Tea at Wayfarer’s Rest • noon–1 pm. Music in the civic square • 6–10 pm.","Marina deliveries • 10 am–noon. Board games at Wayfarer’s Rest • 6–8 pm.","Tea at Wayfarer’s Rest • noon–1 pm. Lantern walk • 8–10 pm.","Makers’ Fair • 11 am–4 pm. Stories Under Stars at the forest camp • 10 pm–midnight.","Marina fishing afternoon • 3–6 pm. Travellers’ stories at Wayfarer’s Rest • 4–7 pm."]
   g.presentation.label(g.presentation.content,notices[g.town_life.calendar.weekday],18)
   g.presentation.label(g.presentation.content,"Anglers’ notice: cast from the eastern marina finger dock. Different visitors emerge at night; a baited basket can collect freshwater mussels.",16)
   g.presentation.button(g.presentation.content,"Back to town",g.presentation.close)
  return true
 if g.position_in_world.distance_to(REST)>75:return false
 g.hint="E • Wayfarer’s Rest • tea, games & travellers’ stories"
 if Input.is_action_just_pressed("interact"):
  g.presentation.window("WAYFARER’S REST","wayfarers_rest")
  g.presentation.label(g.presentation.content,"A little space to meet the people of Crossroads.",20)
  g.presentation.label(g.presentation.content,"Monday, Wednesday & Friday • lunch and tea, noon–1 pm\nTuesday & Thursday • board games, 6–8 pm\nSunday • travellers’ stories, 4–7 pm\nThe pavilion stays open for a quiet rest between gatherings.",17)
  g.presentation.button(g.presentation.content,"Back to town",g.presentation.close)
 return true
static func cliffs(g:Node2D,camera:Vector2)->void:
 preload("res://scripts/town_art246.gd").cliffs(g,camera)
 # Keep the cave's open stone court and exact eastern approach.
 var court=Rect2(Vector2(-1175,1195)-camera,Vector2(245,130));g.draw_rect(court,Color("#929781"))
 for y in range(1200,1325,25):
  for x in range(-1170,-930,40):g.draw_rect(Rect2(Vector2(x+(10 if y%2 else 0),y)-camera,Vector2(36,21)),Color("#b3b29a"),false,1)

static func draw(g:Node2D,camera:Vector2)->void:
 preload("res://scripts/town_art246.gd").rest_details(g,camera)
 var view=Rect2(camera,g.VIEW).grow(170);var night=float(g.town_life.calendar.night_amount())
 if view.intersects(PAVILION.grow(130)):
  var p=PAVILION.position-camera
  preload("res://scripts/town_shops242.gd").draw(g,"pavilion",camera)
  for x in [-15,235]:preload("res://scripts/town_calendar.gd").draw_lantern(g,p+Vector2(x,90),night)
  # An inexpensive chime supplies small motion without particles or simulation actors.
  var sway=sin(g.town_life.clock*1.3)*3
  for n in 3:g.draw_line(p+Vector2(199+n*6,11),p+Vector2(199+n*6+sway,24+n*3),Color("#d2bd86"),2)
 if view.has_point(FOUNTAIN):
  var p=FOUNTAIN-camera;var t=g.town_life.clock
  preload("res://scripts/town_props240.gd").fountain(g,p,t,night)
 if view.has_point(NOTICE):
  var p=NOTICE-camera
  preload("res://scripts/town_streets244.gd").draw(g,"notice",Rect2(p+Vector2(-46,-92),Vector2(92,108)))
  g.draw_string(ThemeDB.fallback_font,p+Vector2(-53,35),"TOWN NOTICES",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("#eee0b4"))
 if view.intersects(Rect2(-1240,1050,350,300)):
  for at in POSTS:
   var p=at-camera;g.draw_line(p,p-Vector2(0,105),Color("#c0ab7b"),4)
   var wave=sin(g.town_life.clock*1.4)*2
   g.draw_colored_polygon(PackedVector2Array([p+Vector2(1,-100),p+Vector2(28+wave,-98),p+Vector2(28,-45),p+Vector2(13,-34),p+Vector2(1,-44)]),Color("#436e77"))
   g.draw_arc(p+Vector2(14,-74),8,PI,TAU,16,Color("#f2d99c"),3)
