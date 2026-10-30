extends RefCounted
## Residential footprint and doorstep routes are shared with collision and navigation.
const HOMES=[
 {"name":"Cliffside Cottage","art":"cliff_cottage","wall":Rect2(-1190,1418,280,200),"door":Vector2(-1050,1630)},
 {"name":"Willow Court Homes","art":"artists_duplex","wall":Rect2(-810,1490,270,200),"door":Vector2(-720,1702)},
 {"name":"Orchard House","art":"orchard_home","wall":Rect2(500,1910,280,200),"door":Vector2(640,2122)},
 {"name":"Lantern Row","art":"guard_townhouse","wall":Rect2(1100,1940,280,200),"door":Vector2(1240,2152)},
 {"name":"Reedbank House","art":"river_home","wall":Rect2(2600,1810,300,200),"door":Vector2(2750,2022)}]
const ROADS=[
 [Vector2(-1050,1630),Vector2(-850,1630),Vector2(-850,1200)],
 [Vector2(-720,1702),Vector2(-720,1740),Vector2(-560,1740)],
 [Vector2(-630,1702),Vector2(-630,1740)],
 [Vector2(640,2122),Vector2(640,2220),Vector2(420,2220),Vector2(420,1740)],
 [Vector2(1240,2152),Vector2(900,2152),Vector2(900,1740)],
 [Vector2(2750,2022),Vector2(2750,2080),Vector2(2470,2080)],
 [Vector2(2250,2080),Vector2(2000,2080)],
 [Vector2(2250,2080),Vector2(2470,2080)],
 [Vector2(-850,1025),Vector2(-1150,1025)]]
const COURT=Rect2(-1190,930,340,165)
const FOUNTAIN=Vector2(-1030,1010)
const TREES=[Vector2(-775,1430),Vector2(-875,1690),Vector2(460,2040),Vector2(775,2260),Vector2(1410,2070),Vector2(2570,1950),Vector2(2940,1950)]
var textures:Dictionary={}
func blocked(p:Vector2)->bool:
 for home in HOMES:
  if home.wall.grow(8).has_point(p):return true
 if p.distance_squared_to(FOUNTAIN)<2500:return true
 for tree in TREES:
  if p.distance_squared_to(tree)<625:return true
 return false
static func reserved(p:Vector2)->bool:
 for home in HOMES:
  if home.wall.grow(75).has_point(p):return true
 if COURT.grow(40).has_point(p):return true
 for route in ROADS:
  for n in range(1,route.size()):
   if Geometry2D.get_closest_point_to_segment(p,route[n-1],route[n]).distance_to(p)<70:return true
 return false
func draw_on(g:Node2D,camera:Vector2,clock:float)->void:
 var view=Rect2(camera,g.VIEW).grow(120)
 for index in HOMES.size():
  var home:Dictionary=HOMES[index];var wall:Rect2=home.wall
  if not view.intersects(wall.grow(100)):continue
  preload("res://scripts/town_nature243.gd").home(g,home.art,camera)
  var door:Vector2=home.door-camera
  # Mailboxes and a doorstep light identify homes without adding permanent labels.
  var box=door+Vector2(-wall.size.x*.38,-8)
  g.draw_line(box,box-Vector2(0,33),Color("#77684e"),4);g.draw_rect(Rect2(box-Vector2(10,48),Vector2(21,17)),Color("#6e8d89"));g.draw_line(box-Vector2(5,39),box+Vector2(5,-39),Color("#ddd0a0"),2)
  var lamp=door+Vector2(38,-50);g.draw_rect(Rect2(lamp-Vector2(4,6),Vector2(8,12)),Color("#405956"));g.draw_rect(Rect2(lamp-Vector2(2,4),Vector2(4,8)),Color("#bac5a5"))
  # Small chimney puffs, only for visible homes.
  var chimney=preload("res://scripts/town_nature243.gd").chimney(home.art)-camera
  for n in 3:
   var age=fposmod(clock*.23+n*.33+index*.15,1)
   g.draw_circle(chimney+Vector2(sin(age*4+index)*8,-age*30),3+age*5,Color(.79,.83,.8,(1-age)*.2))
  if g.position_in_world.distance_to(home.door)<110:
   var font=ThemeDB.fallback_font;var width=font.get_string_size(home.name,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x
   var sign=Rect2(door+Vector2(-width*.5-8,58),Vector2(width+16,25))
   if not sign.intersects(Rect2(g.position_in_world-camera-Vector2(28,56),Vector2(56,72))):
    preload("res://scripts/town_streets244.gd").plaque(g,sign)
    g.draw_string(font,door+Vector2(-width*.5,76),home.name,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#ead7ad"))
 for tree in TREES:
  if view.has_point(tree):g.draw_sprite("tree",tree-Vector2(48,103),Vector2(96,126))
 if view.intersects(COURT):draw_fountain(g,FOUNTAIN-camera,clock)
func draw_fountain(g:Node2D,p:Vector2,t:float)->void:
 preload("res://scripts/town_props240.gd").fountain(g,p,t,g.town_life.calendar.night_amount())
 for side in [-1,1]:
  var bench=p+Vector2(side*108,22);preload("res://scripts/town_streets244.gd").bench(g,bench,56,-21,34)

