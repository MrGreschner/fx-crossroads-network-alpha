extends Control
const Catalog=preload("res://scripts/idle_mine_catalog.gd")
var mine:RefCounted
var font:Font=preload("res://assets/fonts/CrossroadsUI.ttf")
const Art=preload("res://scripts/cast_art232.gd")
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
 Art.draw_prop(self,kind,Rect2(p+Vector2(-4,-25),Vector2(88,75)))
 text(p+Vector2(0,67),title+" "+str(lv),Color("#dcc69c"),12)
 if kind=="vent":
  var center=p+Vector2(40,15)
  for n in 4:
   var a=clock*2+n*PI*.5;draw_line(center,center+Vector2(cos(a),sin(a))*10,Color("#a2b6b4"),2)
 if kind=="smelter":
  for n in 2:draw_circle(p+Vector2(61+sin(clock+n)*3,-20-fposmod(clock*8+n*12,22)),3,Color(.7,.67,.62,.15))
func _draw()->void:
 var clip=visible_area();var width=630.0
 draw_rect(Rect2(Vector2.ZERO,custom_minimum_size),Color("#14252e"))
 if clip.intersects(Rect2(0,0,width,190)):
  draw_rect(Rect2(0,0,width,40),Color("#345150"));draw_rect(Rect2(0,110,width,15),Color("#887759"))
  for n in 12:draw_line(Vector2(n*53,125),Vector2(n*53+14,142),Color("#534b3f"),3)
  building(Vector2(20,56),"Fresh air","vent",Color("#567b80"));building(Vector2(115,56),"Tools","tools",Color("#826653"));building(Vector2(212,56),"Smelter","smelter",Color("#806659"));building(Vector2(308,56),"Drill","drill",Color("#536f7e"));building(Vector2(405,56),"Depot","depot",Color("#746e54"));building(Vector2(512,56),"Assay","assay",Color("#686783"))
  if int(mine.state().levels.pump)>0:
   Art.draw_prop(self,"pump",Rect2(410,129,68,41));text(Vector2(410,185),"Pump "+str(mine.state().levels.pump),Color("#bccfd1"),12)
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
   var p=Vector2(92+n*48 if n<2 else 427+(n-2)*48,y+84);var working=fposmod(clock*1.3+n*.3+index,1)>.55
   Art.draw(self,"miner",p,3 if working else 0,39)
   if working:draw_rect(Rect2(p+Vector2(22,-7),Vector2(2,2)),Color(accent,.7))
  var cart=Vector2(170+fposmod(clock*24+index*49,93),y+91)
  Art.draw_prop(self,"cart",Rect2(cart-Vector2(20,28),Vector2(40,28)))
  Art.draw_prop(self,"ore",Rect2(575,y+43,38,43),Color(accent))
 var cage_y=160+fposmod(clock*38,maxf(30,mine.depth()*125))
 if clip.intersects(Rect2(303,cage_y,50,45)):Art.draw_prop(self,"lift",Rect2(303,cage_y,50,45))
