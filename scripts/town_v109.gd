extends RefCounted
const TOWER=Vector2(2090,1165)
const BARRACKS=Vector2(1375,1520)
const BUILDINGS={"fellowship":Rect2(1670,1390,260,130),"relay":Rect2(210,1850,230,125),"tower":Rect2(1960,950,260,155),"barracks":Rect2(1240,1290,270,165)}
const ENTRIES={"fellowship":Vector2(1800,1550),"relay":Vector2(325,2030),"tower":TOWER,"barracks":BARRACKS}
var textures:Dictionary={"fellowship":preload("res://scripts/source_art.gd").texture("res://assets/fellowship_v109.svg"),"relay":preload("res://scripts/source_art.gd").texture("res://assets/relay_v109.svg"),"tower":preload("res://scripts/source_art.gd").texture("res://assets/mistglass_v109.svg"),"barracks":preload("res://scripts/source_art.gd").texture("res://assets/barracks_v109.svg"),"mill":preload("res://scripts/source_art.gd").texture("res://assets/mill_v109.svg")}
var guard:Texture2D=preload("res://scripts/source_art.gd").texture("res://assets/guard_melee.svg")
var archer:Texture2D=preload("res://scripts/source_art.gd").texture("res://assets/guard_ranged.svg")
var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
func solid_rect(id:String)->Rect2:
 var r:Rect2=BUILDINGS[id]
 return Rect2(r.position-Vector2(20,90),r.size+Vector2(40,90))
func blocked(p:Vector2)->bool:return solid_rect("tower").has_point(p) or solid_rect("barracks").has_point(p)
func interact(g:Node)->bool:
 for place in [[TOWER,"arcane_tower","Mistglass Spire"],[BARRACKS,"barracks","Ramguard Barracks"]]:
  if g.position_in_world.distance_to(place[0])<80:
   g.hint="E • "+str(place[2])
   if Input.is_action_just_pressed("interact"):g.menu=place[1]
   return true
 return false
func plaque(c:Node2D,p:Vector2,label:String,width:float)->void:
 if Rect2(p-Vector2(width*.5,17),Vector2(width,24)).intersects(Rect2(c.position_in_world-c.camera-Vector2(25,60),Vector2(50,70))):return
 c.draw_rect(Rect2(p-Vector2(width*.5,17),Vector2(width,24)),Color("#203b45"));c.draw_rect(Rect2(p-Vector2(width*.5,17),Vector2(width,24)),Color("#ceb784"),false,1)
 c.draw_string(font,p-Vector2(width*.5,0),label,HORIZONTAL_ALIGNMENT_CENTER,width,14,Color("#f1dab0"))
func building(c:Node2D,camera:Vector2,id:String,title:String)->void:
 var r:Rect2=BUILDINGS[id];var art:=Rect2(r.position-Vector2(20,100)-camera,r.size+Vector2(40,110))
 if not Rect2(Vector2.ZERO,c.get_viewport_rect().size).grow(100).intersects(art):return
 c.draw_texture_rect(textures[id],art,false)
 var sign:Vector2=art.position+Vector2(art.size.x*.5,art.size.y*.4+8)
 plaque(c,sign,title,art.size.x*(.58 if id=="relay" else .5 if id=="barracks" else .46))
 var entry:Vector2=ENTRIES[id]-camera
 c.draw_rect(Rect2(entry-Vector2(50,35),Vector2(100,54)),Color(.8,.76,.55,.1))
 if c.position_in_world.distance_to(ENTRIES[id])<80:c.draw_arc(entry,35,0,TAU,24,Color("#efd69b"),2,true)
func draw_projects(c:Node2D,camera:Vector2,data:Dictionary)->void:
 for id in ["fellowship","relay"]:
  if bool(data.town.get(id,false)):building(c,camera,id,"FELLOWSHIP" if id=="fellowship" else "RELAY WORKSHOP")
func draw_mill(c:Node2D,camera:Vector2)->void:
 var art:=Rect2(Vector2(2070,1290)-camera,Vector2(250,280))
 if not Rect2(Vector2.ZERO,c.get_viewport_rect().size).grow(90).intersects(art):return
 c.draw_texture_rect(textures.mill,art,false);plaque(c,Vector2(2175,1412)-camera,"WATERMILL",110)
 var p:=Vector2(2300,1515)-camera;var t:=Time.get_ticks_msec()*.0005
 c.draw_circle(p,49,Color("#725b41"));c.draw_arc(p,43,0,TAU,32,Color("#cdb58b"),5,true)
 for n in 10:
  var a:float=t+n*TAU/10;var tip:=p+Vector2.from_angle(a)*44;c.draw_line(p,tip,Color("#ccb389"),4,true);c.draw_line(tip-Vector2.from_angle(a+PI/2)*7,tip+Vector2.from_angle(a+PI/2)*7,Color("#92724b"),6,true)
 c.draw_circle(p,7,Color("#d5cfaf"))
 for n in 4:c.draw_circle(p+Vector2(22+n*10,43+sin(t*3+n)*3),2,Color(.7,.91,.95,.6))
func draw_on(c:Node2D,camera:Vector2)->void:
 building(c,camera,"tower","MISTGLASS SPIRE");building(c,camera,"barracks","RAMGUARD")
 var visible:=Rect2(camera,c.get_viewport_rect().size).grow(100);var t:=Time.get_ticks_msec()/1000.0
 if visible.has_point(TOWER):
  var p:=Vector2(2170,1115)-camera
  c.draw_line(p,Vector2(2268,1115)-camera,Color("#7e9fa2"),8,true)
  for n in 5:
   var x:float=fposmod(t*12+n*20,95);c.draw_circle(p+Vector2(x,-3),2,Color(.66,.9,1,.5))
 if visible.has_point(BARRACKS):
  for n in 3:
   var world:=Vector2(1245+n*112+sin(t*.2+n)*25,1500+cos(t*.2+n)*10)
   var texture:Texture2D=archer if n==1 else guard
   c.draw_texture_rect(texture,Rect2(world-camera-Vector2(22,53),Vector2(44,58)),false)
   if n==2:c.draw_arc(world-camera-Vector2(0,50),10,PI,TAU,12,Color("#e9c67c"),3,true)
  for x in [1225,1510]:
   var p:=Vector2(x,1490)-camera;c.draw_line(p,p-Vector2(0,80),Color("#8c7860"),4);c.draw_colored_polygon(PackedVector2Array([p-Vector2(0,80),p+Vector2(29,-70),p+Vector2(0,-46)]),Color("#7cabc5"))

func construction(c:Node2D,camera:Vector2,r:Rect2,label:String)->void:
 if not Rect2(camera,c.VIEW).grow(100).intersects(r):return
 var p=r.position-camera
 c.draw_rect(Rect2(p,r.size),Color("#77664e"))
 for n in 4:
  var q=p+Vector2(n*r.size.x/3,0)
  c.draw_line(q,q+Vector2(0,-42),Color("#aa8151"),5)
 c.draw_line(p-Vector2(0,22),p+Vector2(r.size.x,-22),Color("#c1a073"),5)
 for n in 3:
  var q=p+Vector2(14+n*18,9)
  c.draw_rect(Rect2(q,Vector2(15,6)),Color("#cab68b"))
 plaque(c,p+Vector2(r.size.x*.5,r.size.y+19),label+" • PLANNED",maxf(r.size.x,minf(280,font.get_string_size(label+" • PLANNED",HORIZONTAL_ALIGNMENT_LEFT,-1,14).x+18)))
func draw_future_sites(c:Node2D,camera:Vector2,data:Dictionary)->void:
 var sites={"fellowship":Rect2(1670,1390,260,80),"relay":Rect2(210,1850,230,80),"mill":Rect2(2100,1420,115,110),"bakery":Rect2(750,1260,135,65),"library":Rect2(1020,1700,100,40),"statue":Rect2(1040,1130,40,25)}
 for id in sites:
  if not bool(data.town.get(id,false)):construction(c,camera,sites[id],str(id).capitalize())
 # Existing buildings expand in place: show scaffold signs rather than a second building.
 for entry in [["market",Vector2(1290,487),"VENDOR CANOPY"],["clinic",Vector2(1960,585),"HEALER WING"],["observatory",Vector2(1720,365),"OBSERVATORY"]]:
  if not bool(data.town.get(entry[0],false)) and Rect2(camera,c.VIEW).has_point(entry[1]):plaque(c,entry[1]-camera,entry[2]+" • PLANNED",220)
