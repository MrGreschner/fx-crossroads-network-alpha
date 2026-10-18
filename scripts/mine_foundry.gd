extends RefCounted
## Depth-gated metals, independent furnace, construction material escrow.
const METALS={
 "copper":{"name":"Copper","depth":2,"rate":.12,"ore":6,"coal":1,"seconds":24,"price":15,"color":"#d99565"},
 "iron":{"name":"Iron","depth":4,"rate":.10,"ore":8,"coal":2,"seconds":30,"price":24,"color":"#a1b5c5"},
 "cobalt":{"name":"Cobalt","depth":7,"rate":.07,"ore":10,"coal":3,"seconds":36,"price":38,"color":"#678ee2"},
 "mithril":{"name":"Mithril","depth":11,"rate":.045,"ore":12,"coal":4,"seconds":42,"price":60,"color":"#7bd7c5"},
 "emberite":{"name":"Emberite","depth":15,"rate":.03,"ore":14,"coal":5,"seconds":48,"price":90,"color":"#ec8b62"},
 "starsteel":{"name":"Starsteel","depth":18,"rate":.02,"ore":16,"coal":6,"seconds":54,"price":130,"color":"#c5b0ed"}}
static var icons:Dictionary={}
static func empty()->Dictionary:
 var result={}
 for id in METALS:result[id]=0.0
 return result
static func fresh()->Dictionary:return {"version":1,"stored":empty(),"wallet":empty(),"lifetime":empty(),"bars":empty(),"forged":empty(),"job":{},"reserved":{},"reinforced":false}
static func state(mine:RefCounted)->Dictionary:
 if not mine.state().has("foundry"):mine.state().foundry=fresh()
 return mine.state().foundry
static func valid(value:Variant)->bool:
 if not value is Dictionary or value.size()!=9 or value.get("version")!=1 or not value.get("reinforced") is bool:return false
 for bucket in ["stored","wallet","lifetime","bars","forged"]:
  if not value.get(bucket) is Dictionary or value[bucket].size()!=METALS.size():return false
  for id in METALS:
   if not load("res://scripts/idle_mine.gd").numeric(value[bucket].get(id),0,1e15):return false
   if bucket in ["bars","forged"] and not load("res://scripts/idle_mine.gd").numeric(value[bucket][id],0,1e15,true):return false
 if not value.get("reserved") is Dictionary or value.reserved.size()>METALS.size():return false
 for id in value.reserved:
  if not METALS.has(id) or not load("res://scripts/idle_mine.gd").numeric(value.reserved[id],1,10000,true):return false
 if not value.get("job") is Dictionary:return false
 var job:Dictionary=value.job
 if job.is_empty():return true
 return job.size()==5 and METALS.has(job.get("metal")) and load("res://scripts/idle_mine.gd").numeric(job.get("count"),1,10,true) and load("res://scripts/idle_mine.gd").numeric(job.get("start"),0,4102444800) and load("res://scripts/idle_mine.gd").numeric(job.get("end"),float(job.start),4102444800) and load("res://scripts/idle_mine.gd").numeric(job.get("seconds"),1,600) and is_equal_approx(float(job.end)-float(job.start),float(job.seconds))
static func integrate(mine:RefCounted,seconds:float,flow:float)->void:
 var s=state(mine)
 for id in METALS:
  if mine.depth()<int(METALS[id].depth):continue
  var produced=minf(seconds*flow*float(METALS[id].rate),maxf(0,1200-float(s.stored[id])))
  s.stored[id]+=produced;s.lifetime[id]=minf(1e15,float(s.lifetime[id])+produced)
static func collect(mine:RefCounted)->void:
 var s=state(mine)
 for id in METALS:s.wallet[id]=minf(1e15,float(s.wallet[id])+float(s.stored[id]));s.stored[id]=0.0
static func recipe(mine:RefCounted,id:String,count:int)->Dictionary:
 if not METALS.has(id):return {}
 var metal:Dictionary=METALS[id]
 return {"ore":int(metal.ore)*count,"coal":int(metal.coal)*count,"seconds":maxf(8,float(metal.seconds)*count/(1+.08*maxi(0,int(mine.state().levels.smelter)-1)))}
static func can_forge(mine:RefCounted,id:String,count:int)->bool:
 if not METALS.has(id) or count<1 or count>10:return false
 var s=state(mine);var cost=recipe(mine,id,count);var coal=preload("res://scripts/mine_geology.gd").state(mine)
 return mine.state().commissioned and mine.depth()>=int(METALS[id].depth) and int(mine.state().levels.smelter)>0 and s.job.is_empty() and mine.state().refine.is_empty() and float(s.wallet[id])+1e-7>=cost.ore and float(coal.wallet.coal)+1e-7>=cost.coal
static func forge(mine:RefCounted,id:String,count:int)->bool:
 if mine.readonly():return false
 mine.advance()
 if not can_forge(mine,id,count):return false
 var s=state(mine);var cost=recipe(mine,id,count)
 s.wallet[id]=maxf(0,float(s.wallet[id])-cost.ore);preload("res://scripts/mine_geology.gd").state(mine).wallet.coal=maxf(0,float(preload("res://scripts/mine_geology.gd").state(mine).wallet.coal)-cost.coal)
 s.job={"metal":id,"count":count,"start":mine.now(),"end":mine.now()+cost.seconds,"seconds":cost.seconds};mine.changed();return true
static func finish(mine:RefCounted,stamp:float)->void:
 var s=state(mine)
 if s.job.is_empty() or stamp<float(s.job.end):return
 var id:String=s.job.metal;var count:int=s.job.count
 s.bars[id]=minf(1e15,float(s.bars[id])+count);s.forged[id]=minf(1e15,float(s.forged[id])+count);s.job={}
static func cancel_forge(mine:RefCounted)->bool:
 if mine.readonly():return false
 mine.advance();var s=state(mine)
 if s.job.is_empty():return false
 var id:String=s.job.metal;var cost=recipe(mine,id,int(s.job.count))
 s.wallet[id]=minf(1e15,float(s.wallet[id])+cost.ore);var g=preload("res://scripts/mine_geology.gd").state(mine);g.wallet.coal=minf(1e15,float(g.wallet.coal)+cost.coal);s.job={};mine.changed();return true
static func construction_cost(target_depth:int,level:int=0)->Dictionary:
 if target_depth<5:return {}
 var metal="copper"
 for id in METALS:
  if int(METALS[id].depth)<=target_depth-1:metal=id
 return {metal:mini(10000,(1+int(level/5))*int(ceil(pow(1.16,maxi(0,target_depth-20)))))}
static func affordable(mine:RefCounted,cost:Dictionary)->bool:
 var s=state(mine)
 for id in cost:
  if not METALS.has(id) or float(s.bars[id])+1e-7<float(cost[id]):return false
 return true
static func reserve(mine:RefCounted,cost:Dictionary)->void:
 var s=state(mine)
 for id in cost:s.bars[id]=maxf(0,float(s.bars[id])-cost[id]);s.reserved[id]=float(s.reserved.get(id,0))+cost[id]
static func completed_build(mine:RefCounted)->void:var s=state(mine);s.reserved={};s.reinforced=false
static func refund_build(mine:RefCounted)->void:
 var s=state(mine)
 for id in s.reserved:s.bars[id]=minf(1e15,float(s.bars[id])+float(s.reserved[id]))
 completed_build(mine)
static func reinforce_cost(mine:RefCounted)->Dictionary:return construction_cost(maxi(5,mine.depth()+1))
static func reinforce(mine:RefCounted)->bool:
 if mine.readonly():return false
 mine.advance();var s=state(mine);var cost=reinforce_cost(mine)
 if mine.state().job.is_empty() or s.reinforced or not affordable(mine,cost):return false
 reserve(mine,cost);s.reinforced=true
 var remaining=maxf(0,float(mine.state().job.end)-mine.now());mine.state().job.end=mine.now()+remaining*.65;mine.changed();return true
static func icon(id:String,bar:bool=false)->Texture2D:
 var key=id+(":bar" if bar else ":ore")
 if icons.has(key):return icons[key]
 var image=Image.create(24,24,false,Image.FORMAT_RGBA8);image.fill(Color.TRANSPARENT);var tint=Color(METALS[id].color)
 for y in range(4,20):
  for x in range(2,22):
   var inside=(y>=9 and y<19 and x>=4 and x<21) or (y>=5 and y<10 and x>=8 and x<21) if bar else abs(x-12)+abs(y-12)<13
   if inside:image.set_pixel(x,y,tint.lightened(.35) if y<10 else tint.darkened(.3) if x>17 else tint)
 if bar:
  for x in range(8,20):image.set_pixel(x,5,tint.lightened(.6))
 else:
  for n in 5:image.set_pixel(7+n,8,tint.lightened(.6))
 var texture=ImageTexture.create_from_image(image);icons[key]=texture;return texture
