extends RefCounted
const DEPOSITS={"coal":{"name":"Coal","depth":1,"rate":.03,"price":2,"color":"#5a667c"},"silver":{"name":"Silver","depth":2,"rate":.012,"price":5,"color":"#c2d7e4"},"ruby":{"name":"Rubies","depth":3,"rate":.003,"price":18,"color":"#ee586e"},"sapphire":{"name":"Sapphires","depth":5,"rate":.002,"price":25,"color":"#598feb"},"diamond":{"name":"Diamonds","depth":8,"rate":.001,"price":50,"color":"#a3f2ef"},"moonstone":{"name":"Moonstone","depth":12,"rate":.0006,"price":80,"color":"#cda8f0"}}
static var icons:Dictionary={}
static func fresh()->Dictionary:
 var stocks={}
 for id in DEPOSITS:stocks[id]=0.0
 return {"stored":stocks.duplicate(),"wallet":stocks.duplicate(),"lifetime":stocks.duplicate(),"order":{},"sales":0.0}
static func state(mine:RefCounted)->Dictionary:
 if not mine.state().has("geology"):mine.state().geology=fresh()
 return mine.state().geology
static func valid(value:Variant)->bool:
 if not value is Dictionary or value.size()!=5:return false
 for bucket in ["stored","wallet","lifetime"]:
  if not value.get(bucket) is Dictionary or value[bucket].size()!=6:return false
  for id in DEPOSITS:
   if not load("res://scripts/idle_mine.gd").numeric(value[bucket].get(id),0,1e15):return false
 if not load("res://scripts/idle_mine.gd").numeric(value.get("sales"),0,1e15) or not value.get("order") is Dictionary:return false
 var o:Dictionary=value.order
 return o.is_empty() or o.size()==3 and DEPOSITS.has(o.get("id")) and load("res://scripts/idle_mine.gd").numeric(o.get("amount"),1,25,true) and load("res://scripts/idle_mine.gd").numeric(o.get("end"),0,4102444800)
static func integrate(mine:RefCounted,seconds:float,flow:float)->void:
 var g=state(mine)
 for id in DEPOSITS:
  if mine.depth()<DEPOSITS[id].depth:continue
  var produced=seconds*flow*float(DEPOSITS[id].rate)*(1+.08*int(mine.state().levels.assay))
  # A separate display case holds 250 specimens of each kind; full storage pauses only that deposit.
  produced=minf(produced,maxf(0,250-float(g.stored[id])))
  g.stored[id]+=produced;g.lifetime[id]=minf(1e15,float(g.lifetime[id])+produced)
static func collect(mine:RefCounted)->void:
 var g=state(mine)
 for id in DEPOSITS:g.wallet[id]=minf(1e15,float(g.wallet[id])+float(g.stored[id]));g.stored[id]=0.0
static func finish(mine:RefCounted,stamp:float)->void:
 var g=state(mine);var o:Dictionary=g.order
 if o.is_empty() or stamp<float(o.end):return
 var earned=float(o.amount)*float(DEPOSITS[o.id].price)
 mine.state().wallet.gold=minf(1e15,float(mine.state().wallet.gold)+earned);g.sales=minf(1e15,float(g.sales)+earned);g.order={}
static func sell(mine:RefCounted,id:String)->bool:
 if mine.readonly() or not DEPOSITS.has(id):return false
 mine.advance();var g=state(mine)
 if not g.order.is_empty() or float(g.wallet[id])<1:return false
 var amount=mini(25,int(g.wallet[id]));g.wallet[id]-=amount;g.order={"id":id,"amount":amount,"end":mine.now()+60};mine.legacy.save();return true
static func icon(id:String)->Texture2D:
 if icons.has(id):return icons[id]
 var image=Image.create(24,24,false,Image.FORMAT_RGBA8);image.fill(Color.TRANSPARENT);var tint=Color(DEPOSITS[id].color)
 for y in range(3,21):
  for x in range(3,21):
   var inside=abs(x-12)+abs(y-11)<12 if id!="coal" else (x-12)*(x-12)+(y-12)*(y-12)<85
   if inside:image.set_pixel(x,y,tint.lightened(.3) if x+y<19 else tint.darkened(.3) if x>14 else tint)
 for n in 6:image.set_pixel(7+n,8,tint.lightened(.55))
 var texture=ImageTexture.create_from_image(image);icons[id]=texture;return texture
