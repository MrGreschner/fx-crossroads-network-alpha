extends Control
## Bounded animated storefront. Shares product icons with the mining interface.
var market:RefCounted
const WALKERS=[preload("res://assets/ram_idle.png"),preload("res://assets/cat_idle.png"),preload("res://assets/medic_idle.png")]
var clerk=preload("res://scripts/town_cast230.gd").texture("supply_keeper")
var clock=0.0
var elapsed=0.0
static func icon(c:CanvasItem,p:Vector2,index:int,scale:float=1)->void:
 if index>=6:
  var id=str(preload("res://scripts/commerce.gd").PRODUCTS[clampi(index,6,11)].bar)
  c.draw_texture_rect(preload("res://scripts/mine_foundry.gd").icon(id,true),Rect2(p-Vector2(18,18)*scale,Vector2(36,36)*scale),false);return
 var colours=[Color("#bfa777"),Color("#a9c2c5"),Color("#9ddbd9"),Color("#e1be87"),Color("#a3e4d9"),Color("#dbb891")]
 var colour=colours[clampi(index,0,5)]
 if index==0:
  c.draw_colored_polygon(PackedVector2Array([p+Vector2(-14,8)*scale,p+Vector2(-12,-6)*scale,p+Vector2(2,-15)*scale,p+Vector2(17,-2)*scale,p+Vector2(12,10)*scale]),colour)
  c.draw_line(p+Vector2(-8,3)*scale,p+Vector2(7,-6)*scale,Color("#eee1aa"),3*scale,true)
 elif index==1:
  for n in 3:c.draw_rect(Rect2(p+Vector2(-15+n*5,-8+n*5)*scale,Vector2(26,9)*scale),colour.darkened(n*.12))
 elif index==2 or index==3:
  c.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-18)*scale,p+Vector2(12,0)*scale,p+Vector2(0,17)*scale,p+Vector2(-12,0)*scale]),colour)
  c.draw_line(p-Vector2(0,18)*scale,p+Vector2(0,17)*scale,Color("#f4eee0"),2*scale)
  if index==3:c.draw_arc(p-Vector2(0,16)*scale,9*scale,PI,TAU,12,Color("#dab471"),2*scale)
 elif index==4:
  c.draw_rect(Rect2(p+Vector2(-12,-14)*scale,Vector2(24,29)*scale),Color("#638f97"));c.draw_rect(Rect2(p+Vector2(-8,-9)*scale,Vector2(16,18)*scale),colour);c.draw_arc(p-Vector2(0,14)*scale,7*scale,PI,TAU,12,colour,2*scale)
 else:
  c.draw_circle(p,15*scale,colour);c.draw_circle(p,9*scale,Color("#537883"))
  for n in 8:c.draw_line(p+Vector2.from_angle(n*PI/4)*12*scale,p+Vector2.from_angle(n*PI/4)*19*scale,colour,3*scale)
func _ready()->void:
 custom_minimum_size=Vector2(0,205);mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta:float)->void:
 if not is_visible_in_tree():return
 clock+=delta;elapsed+=delta
 if elapsed>=.067:elapsed=0;queue_redraw()
func person(p:Vector2,tint:Color,phase:float)->void:
 preload("res://scripts/town_cast230.gd").draw(self,"exchange_worker",p,phase,true,.7)
func _draw()->void:
 if market==null:return
 var w=size.x;var font=preload("res://assets/fonts/CrossroadsUI.ttf")
 draw_rect(Rect2(Vector2.ZERO,size),Color("#314d50"))
 draw_rect(Rect2(12,10,w-24,155),Color("#7e8467"))
 var counter=Vector2(w*.42,77)
 draw_rect(Rect2(counter-Vector2(135,10),Vector2(270,58)),Color("#a07f57"));draw_rect(Rect2(counter-Vector2(141,10),Vector2(282,12)),Color("#c6ac76"))
 for n in 6:icon(self,counter+Vector2(-110+n*44,-22),n,.75)
 draw_texture_rect(clerk,Rect2(counter+Vector2(-22,-68),Vector2(44,52)),false)
 var running=market.busy()
 for n in 5:
  var progress=fposmod(clock*(.07 if running else .025)+n*.2,1)
  var point=Vector2(30+progress*(w-70),146+sin(n)*6)
  draw_circle(point+Vector2(0,7),10,Color(0,0,0,.15));draw_texture_rect(WALKERS[n%3],Rect2(point+Vector2(-17,-34+sin(clock*4+n)*2),Vector2(34,43)),false)
  if running and progress>.35 and progress<.8:icon(self,point+Vector2(15,-12),int(market.state().product),.4)
 var sign=Vector2(w-235,20);draw_rect(Rect2(sign,Vector2(210,83)),Color("#203a47"));draw_rect(Rect2(sign,Vector2(210,83)),Color("#d4b87d"),false,2)
 draw_string(font,sign+Vector2(12,22),"YOUR CAMPAIGN",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#d9ca93"))
 var copy=str(market.state().copy).left(24);draw_string(font,sign+Vector2(12,44),copy,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#e7efe2"))
 draw_string(font,sign+Vector2(12,67),"Budget %.0f • %s" % [market.state().budget,"LIVE" if running else "planning"],HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#a6d8bd"))
 var progress=0.0
 if running:progress=clampf((market.now()-market.state().trading.start)/market.state().trading.seconds,0,1)
 draw_rect(Rect2(12,177,w-24,12),Color("#233c43"));draw_rect(Rect2(12,177,(w-24)*progress,12),Color("#d4b66e"))
 draw_string(font,Vector2(18,164),"CUSTOMERS BROWSING • decisions locked until closing" if running else "STOREFRONT • prepare your stock and open for trading",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#eff0d6"))
