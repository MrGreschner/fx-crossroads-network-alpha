extends Control
const Catalog=preload("res://scripts/idle_mine_catalog.gd")
var mine:RefCounted
var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
var ram:Texture2D=preload("res://assets/ram_walk1.png")
var clock=0.0
var redraw_clock=0.0
func _ready()->void:
 custom_minimum_size=Vector2(630,190+mine.depth()*125);mouse_filter=Control.MOUSE_FILTER_IGNORE;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(delta:float)->void:
 if not is_visible_in_tree():return
 clock+=delta;redraw_clock+=delta
 if redraw_clock>=.067:redraw_clock=0;queue_redraw()
func visible_area()->Rect2:
 var parent=get_parent() as Control;var rect=parent.get_global_rect();var inv=get_global_transform().affine_inverse()
 return Rect2(inv*rect.position,(inv*rect.end)-(inv*rect.position)).grow(15)
func text(p:Vector2,value:String,colour:Color=Color("#d7d3c5"),sz:int=14)->void:draw_string(font,p,value,HORIZONTAL_ALIGNMENT_LEFT,-1,sz,colour)
func building(p:Vector2,title:String,kind:String,colour:Color)->void:
 var lv=int(mine.state().levels[kind])
 if lv<=0:return
 draw_rect(Rect2(p,Vector2(80,48)),colour);draw_rect(Rect2(p+Vector2(3,3),Vector2(74,42)),Color(colour,.6),false,2)
 draw_colored_polygon(PackedVector2Array([p+Vector2(-5,2),p+Vector2(40,-20),p+Vector2(85,2)]),Color("#a0957f"))
 draw_rect(Rect2(p+Vector2(12,15),Vector2(14,16)),Color("#91bbbd"));draw_rect(Rect2(p+Vector2(49,17),Vector2(20,31)),Color("#263b40"))
 text(p+Vector2(0,67),title+" "+str(lv),Color("#dcc69c"),12)
 if kind=="vent":
  var center=p+Vector2(40,15)
  for n in 4:
   var a=clock*2+n*PI*.5;draw_line(center,center+Vector2(cos(a),sin(a))*17,Color("#b4d6d5"),4,true)
  draw_circle(center,4,Color("#536d73"))
 if kind=="drill":
  for n in 3:draw_line(p+Vector2(30,15+n*5),p+Vector2(50,15+n*5+sin(clock*6)*3),Color("#c3d1d1"),3,true)
 if kind=="smelter":
  draw_rect(Rect2(p+Vector2(30,-26),Vector2(12,22)),Color("#59585b"))
  for n in 3:draw_circle(p+Vector2(36+sin(clock+n)*5,-28-fposmod(clock*12+n*12,35)),5,Color(.7,.67,.62,.2))
 if kind=="assay":draw_colored_polygon(PackedVector2Array([p+Vector2(36,27),p+Vector2(45,10),p+Vector2(53,27),p+Vector2(44,37)]),Color("#bba0db"))
func _draw()->void:
 var clip=visible_area();var width=630.0
 draw_rect(Rect2(Vector2.ZERO,custom_minimum_size),Color("#14252e"))
 if clip.intersects(Rect2(0,0,width,190)):
  draw_rect(Rect2(0,0,width,40),Color("#345150"));draw_rect(Rect2(0,110,width,15),Color("#887759"))
  for n in 12:draw_line(Vector2(n*53,125),Vector2(n*53+14,142),Color("#534b3f"),3)
  building(Vector2(20,56),"Fresh air","vent",Color("#567b80"));building(Vector2(115,56),"Tools","tools",Color("#826653"));building(Vector2(212,56),"Smelter","smelter",Color("#806659"));building(Vector2(308,56),"Drill","drill",Color("#536f7e"));building(Vector2(405,56),"Depot","depot",Color("#746e54"));building(Vector2(512,56),"Assay","assay",Color("#686783"))
  if int(mine.state().levels.pump)>0:
   draw_rect(Rect2(316,142,57,26),Color("#467a86"));draw_circle(Vector2(342,140),18,Color("#79a7a6"));draw_arc(Vector2(342,140),12,0,TAU,18,Color("#253e48"),3);text(Vector2(311,185),"Pump "+str(mine.state().levels.pump),Color("#bccfd1"),12)
  text(Vector2(18,25),"RAM-RUN INDUSTRY • surface camp",Color("#dde4cd"),17)
 for index in mine.depth():
  var y=190+index*125
  if not clip.intersects(Rect2(0,y,width,125)):continue
  var biome=Catalog.biome(index+1);var rock=Color(biome.rock);var accent=Color(biome.accent)
  draw_rect(Rect2(0,y,width,125),rock)
  var deposits=preload("res://scripts/mine_geology.gd")
  var choices=deposits.DEPOSITS.keys().filter(func(id):return int(deposits.DEPOSITS[id].depth)<=index+1)
  for n in 5:
   var id=str(choices[(index+n)%choices.size()]);draw_texture_rect(deposits.icon(id),Rect2(Vector2(45+n*118,y+98),Vector2(20,20)),false)
  for id in mine.FOUNDRY.METALS:
   if int(mine.FOUNDRY.METALS[id].depth)==index+1:
    draw_texture_rect(mine.FOUNDRY.icon(id),Rect2(Vector2(555,y+4),Vector2(26,26)),false);text(Vector2(365,y+17),str(mine.FOUNDRY.METALS[id].name)+" discovered",Color(mine.FOUNDRY.METALS[id].color),12)
  for n in 8:
   var p=Vector2(32+fposmod(n*91+index*13,560),y+17+posmod(n*19,90));draw_line(p,p+Vector2(20,-5),Color(accent,.25),2,true)
  draw_rect(Rect2(28,y+26,550,65),Color("#203038"));draw_rect(Rect2(302,y-2,52,125),Color("#16232c"))
  for x in [302,354]:draw_line(Vector2(x,y),Vector2(x,y+125),Color("#a9a296"),3)
  for x in [49,271,399,565]:
   draw_rect(Rect2(x,y+21,7,78),Color("#927852"));draw_line(Vector2(x,y+20),Vector2(x+20,y+39),Color("#baa077"),3)
  draw_line(Vector2(30,y+87),Vector2(582,y+87),Color("#9a9690"),2)
  for n in 16:draw_line(Vector2(30+n*35,y+87),Vector2(30+n*35,y+96),Color("#7b725e"),3)
  text(Vector2(15,y+17),"SHAFT "+str(index+1)+" • "+str((index+1)*30)+"m • "+str(biome.name),accent,15)
  for n in mini(4,int(mine.state().shafts[index].crew)):
   var p=Vector2(92+n*48 if n<2 else 427+(n-2)*48,y+77);var swing=sin(clock*3+n+index)
   draw_circle(p+Vector2(0,6),13,Color(0,0,0,.18));draw_texture_rect(ram,Rect2(p+Vector2(-16,-37+swing),Vector2(32,39)),false)
   draw_arc(p+Vector2(0,-33+swing),10,PI,TAU,12,Color("#d6b15e"),4);draw_circle(p+Vector2(0,-37),3,Color("#f7e4a2"))
   var hand=p+Vector2(14,-13);var tip=hand+Vector2(16+swing*4,-14+swing*8)
   draw_line(hand,tip,Color("#b89465"),3);draw_line(tip+Vector2(-8,-3),tip+Vector2(9,4),Color("#c9d1cd"),3)
   if swing>.5:draw_circle(p+Vector2(26,-9),2,Color(accent,.7))
  var cart=Vector2(170+fposmod(clock*24+index*49,93),y+74)
  draw_rect(Rect2(cart+Vector2(-17,-8),Vector2(35,18)),Color("#749198"))
  for x in [-11,11]:draw_circle(cart+Vector2(x,14),5,Color("#283139"))
  for n in 4:draw_circle(cart+Vector2(-12+n*8,-7),5,accent)
  for n in 5:
   var gem=Vector2(600,y+28+n*13);draw_colored_polygon(PackedVector2Array([gem,gem+Vector2(7,-9),gem+Vector2(13,0),gem+Vector2(7,6)]),Color(accent,.8))
 var cage_y=160+fposmod(clock*38,maxf(30,mine.depth()*125))
 if clip.intersects(Rect2(303,cage_y,50,45)):
  draw_rect(Rect2(308,cage_y,40,35),Color("#68898d"));draw_rect(Rect2(312,cage_y+4,32,26),Color("#b5c3a9"),false,2)
  for n in 3:draw_line(Vector2(316+n*11,cage_y),Vector2(316+n*11,cage_y+35),Color("#263b45"),2)
