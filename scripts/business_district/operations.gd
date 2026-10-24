extends RefCounted
const C=preload("res://scripts/business_district/catalog.gd")
const R=preload("res://scripts/business_district/recruitment.gd")
const PERIOD=180.0
var state:Dictionary
var changed=false
var last_notice=""
var rng=RandomNumberGenerator.new()
var workers:Array=[]
var people:Array=[]
var effects:Array=[]
var access:Array=[]
var restricted=false
var ownership_limit=5
var public_catalog=false
var pending_resets:Array=[]
const PUBLIC_VENTURES=["kitchen","fishery","rental","mine","workshop","garden"]
var scene_changed=false
func setup(value:Dictionary)->void:
 state=C.upgrade(value);rng.seed=int(state.seed)+int(state.periods)*171;refresh_applicants();rebuild_workers()
func business(id:String)->Dictionary:return state.businesses.get(id,{})
func allowed(id:String)->bool:return id not in pending_resets and (not public_catalog or id in PUBLIC_VENTURES) and (not restricted or id in access)
func can_manage(id:String,closed:bool=false)->bool:
 var b=business(id)
 if not allowed(id):last_notice="Your teacher has not unlocked this premises.";return false
 if b.is_empty():return false
 if closed and b.open:last_notice="Close the trading period before changing this.";return false
 return true
func log_action(id:String,action:String,detail:String)->void:
 var b=business(id);b.decisions.append({"day":int(b.day)+1,"time":snappedf(b.elapsed,.1),"action":action,"detail":detail.left(300)})
 if b.decisions.size()>60:b.decisions.pop_front()
 changed=true
func transaction(id:String,kind:String,amount:float,detail:String)->void:
 var b=business(id);b.cash=snappedf(b.cash+amount,.01);b.ledger.append({"day":b.day+1,"kind":kind,"amount":snappedf(amount,.01),"balance":b.cash,"detail":detail.left(160)})
 if b.ledger.size()>100:b.ledger.pop_front()
 changed=true
func refresh_applicants()->void:
 var latest=0
 for b in state.businesses.values():latest=maxi(latest,int(b.get("summary",{}).get("full_days",0)))
 var epoch=int(latest/3)
 if epoch!=int(state.pool_epoch):
  var keep={}
  for b in state.businesses.values():
   for e in b.employees:
    if state.people_profiles.has(str(e.id)):keep[str(e.id)]=state.people_profiles[str(e.id)]
  state.applicants=R.pool(epoch,int(state.seed),keep.values().map(func(p):return p.name));state.people_profiles=keep
  for p in state.applicants:state.people_profiles[str(p.id)]=p
  state.pool_epoch=epoch;last_notice="A new group of 30 applicants is available. Existing employees stay with you.";changed=true
 C.profiles=state.people_profiles;C.current_pool=state.applicants
func acquisition(id:String)->float:
 var v=C.spec(id)
 if v.get("blank",false):return 900.0
 var cost=700.0
 for eq in v.base_equipment:cost+=C.ops().equipment[eq].cost*.65
 for p in v.starter_products:cost+=C.unit_cost(p)*5
 return snappedf(cost,1)
func establish(id:String,trade_id:String="")->bool:
 if C.spec(id).is_empty() or C.spec(id).get("archived",false) or state.businesses.has(id) or not allowed(id):last_notice="That premises is unavailable or locked by your teacher.";return false
 if ownership_limit>0 and state.businesses.size()>=ownership_limit:last_notice="Public districts can own five ventures. Your existing businesses are preserved.";return false
 var v=C.spec(id);var blank=bool(v.get("blank",false));var price=acquisition(id)
 if blank and C.spec(trade_id).is_empty():last_notice="Choose the type of business for your empty premises.";return false
 if state.started and state.reserve<price:last_notice="Save profits in the district reserve to pay %.0f for this premises." % price;return false
 var first=not state.started
 if not first:state.reserve-=price
 var b=C.fresh_business(id);b.trade=trade_id if blank else id;b.inputs=0;b.stock=0;b.input_book=0.0;b.stock_book=0.0;C.ensure_business(id,b);state.businesses[id]=b
 b.cash=2200.0 if first and blank else 1200.0 if first else 0.0;b.acquisition=price;b.opening_cash=b.cash
 if blank:b.menu={};b.assets={}
 else:
  for p in v.starter_products:
   for m in C.ops().products[p].materials:add_lot(b.materials,m,5*int(C.ops().products[p].materials[m]),C.ops().materials[m].cost*5*C.ops().products[p].materials[m],1.0)
 C.upgrade(state);state.started=true;state.selected=id;sync(b);log_action(id,"Acquire premises","First-start capital and inherited assets" if first else "Paid %.0f from saved reserve; transfer working capital before trading." % price);rebuild_workers();last_notice="Inspect the inherited menu, equipment and stock. You can change the business.";return true
func transfer(id:String,amount:float,to_reserve:bool)->bool:
 if not can_manage(id,true) or amount<=0 or not is_finite(amount):return false
 var b=business(id)
 if to_reserve:
  if b.cash<amount or b.cash-amount<maxf(0,b.loan):last_notice="Keep enough cash to cover the outstanding loan.";return false
  transaction(id,"Reserve transfer",-amount,"Transfer to expansion reserve");state.reserve+=amount
 else:
  if state.reserve<amount:return false
  state.reserve-=amount;transaction(id,"Capital transfer",amount,"Working capital from expansion reserve")
 log_action(id,"Transfer","%.0f %s reserve" % [amount,"to" if to_reserve else "from"]);return true
func rebrand(id:String,name:String)->bool:
 if not can_manage(id,true):return false
 var error=C.clean_name(name)
 if not error.is_empty():last_notice=error;return false
 var b=business(id)
 if b.cash<25:last_notice="Rebranding and signage cost 25.";return false
 expense(id,"Rebrand",25,b.name+" → "+name.strip_edges());b.name=name.strip_edges();log_action(id,"Rebrand",b.name);return true
func select_product(id:String,key:String,enabled:bool)->bool:
 if not can_manage(id,true) or not C.ops().products.has(key):return false
 var b=business(id);var p=C.ops().products[key]
 if not C.can_offer(b.trade,p):return false
 if not b.menu.has(key) and b.menu.size()>=40:last_notice="Keep up to 40 product plans per business. Remove a product from the menu before adding more.";return false
 if not b.menu.has(key):b.menu[key]={"enabled":enabled,"price":float(p.price),"target":8}
 else:b.menu[key].enabled=enabled
 if not enabled:b.menu.erase(key)
 log_action(id,"Product line",p.name+": "+("enabled" if enabled else "removed from menu"));return true
func product_plan(id:String,key:String,price:float,target:int)->bool:
 if not can_manage(id,true):return false
 var b=business(id)
 if not b.menu.has(key) or price<1 or price>C.ops().products[key].price*3 or not is_finite(price) or target<1 or target>40:return false
 b.menu[key].price=snappedf(price,.5);b.menu[key].target=target;log_action(id,"Plan product",C.ops().products[key].name+" price %.2f; prepare up to %d" % [price,target]);return true
func add_lot(store:Dictionary,key:String,qty:int,cost:float,quality:float)->void:
 if not store.has(key):store[key]=[]
 var lots=store[key]
 if not lots.is_empty() and lots[-1].age==0:
  var old=lots[-1];old.quality=(old.quality*old.qty+quality*qty)/(old.qty+qty);old.qty+=qty;old.cost+=cost
 else:lots.append({"qty":qty,"cost":cost,"age":0,"quality":quality})
func quantity(store:Dictionary,key:String)->int:
 var n=0
 for lot in store.get(key,[]):n+=int(lot.qty)
 return n
func book(store:Dictionary)->float:
 var n=0.0
 for lots in store.values():
  for lot in lots:n+=float(lot.cost)
 return maxf(0,n)
func take(store:Dictionary,key:String,qty:int)->Dictionary:
 var cost=0.0;var quality=0.0;var left=qty;var lots=store.get(key,[])
 for lot in lots:
  var used=mini(left,int(lot.qty));var share=float(used)/maxi(1,int(lot.qty));cost+=lot.cost*share;quality+=lot.quality*used;lot.cost=maxf(0,lot.cost*(1-share));lot.qty-=used;left-=used
  if left==0:break
 store[key]=lots.filter(func(l):return l.qty>0)
 return {"cost":cost,"quality":quality/maxi(1,qty)}
func sync(b:Dictionary)->void:
 b.inputs=0;b.stock=0
 for key in b.materials:b.inputs+=quantity(b.materials,key)
 for key in b.finished:b.stock+=quantity(b.finished,key)
 b.input_book=book(b.materials);b.stock_book=book(b.finished)
func order_material(id:String,key:String,qty:int,supplier_index:int)->bool:
 if not can_manage(id) or not C.ops().materials.has(key) or supplier_index<0 or supplier_index>=3:return false
 var b=business(id);var supplier=C.ops().suppliers[supplier_index]
 if C.ops().materials[key].cold and not b.assets.has("fridge") and not b.assets.has("freezer"):last_notice="Install cold storage before ordering "+C.ops().materials[key].name;return false
 if qty<int(supplier.minimum) or qty>100 or b.orders.size()>=40:return false
 var incoming=0
 for o in b.orders:incoming+=int(o.qty)
 if int(b.inputs)+incoming+qty>240+int(b.cold)*120:last_notice="Your storage is full. Use stock or improve storage before ordering.";return false
 var vendor_name=str(C.ops().materials[key].local_supplier) if supplier_index==0 else str(supplier.name)
 var total=snappedf(float(C.ops().materials[key].cost)*qty*supplier.multiplier+supplier.freight,.01)
 if b.cash<total:last_notice="Not enough cash for those specific materials and freight.";return false
 transaction(id,"Material order",-total,"%d %s • %s incl. freight" % [qty,C.ops().materials[key].name,vendor_name]);b.orders.append({"material":key,"qty":qty,"cost":total,"due":float(supplier.lead)+b.route*2,"quality":float(supplier.quality),"supplier":supplier.id,"vendor":vendor_name});log_action(id,"Order material","%s × %d from %s for %.2f" % [C.ops().materials[key].name,qty,vendor_name,total]);return true
func equipment(id:String,key:String,buy:bool)->bool:
 if not can_manage(id,true) or not C.ops().equipment.has(key):return false
 var b=business(id);var eq=C.ops().equipment[key]
 if buy:
  if b.cash<eq.cost or int(b.assets.get(key,{}).get("count",0))>=12:return false
  transaction(id,"Equipment purchase",-float(eq.cost),eq.name)
  if b.assets.has(key):
   var a=b.assets[key];a.condition=(a.condition*a.count+1)/(a.count+1);a.paid+=float(eq.cost);a.count+=1
  else:b.assets[key]={"condition":1.0,"paid":float(eq.cost),"count":1}
 else:
  if not b.assets.has(key):return false
  if b.rentals.any(func(h):return h.fleet==key):last_notice="Wait for this equipment to return from hire before selling it.";return false
  var a=b.assets[key];var cost_per_unit=a.paid/maxi(1,int(a.count));var value=snappedf(cost_per_unit*.55*a.condition,.01);transaction(id,"Equipment sale",value,eq.name+" • one used unit");a.count-=1;a.paid=maxf(0,a.paid-cost_per_unit)
  if a.count<=0:b.assets.erase(key)
 log_action(id,"Equipment",("Buy one " if buy else "Sell one ")+eq.name);return true
func expense(id:String,kind:String,cost:float,detail:String)->void:
 transaction(id,kind,-cost,detail)
 var b=business(id)
 if b.open:b.expenses+=cost
 else:b.pending_expenses+=cost
func asset_units(b:Dictionary)->int:
 var count=0
 for asset in b.assets.values():count+=int(asset.get("count",1))
 return count
func rental_fleet(product:String)->String:
 var eq=C.ops().products[product].equipment
 for key in ["ladder_fleet","tool_fleet","camp_fleet","handcart","rental_rack"]:
  if key in eq:return key
 return "rental_rack"
func rental_capacity(b:Dictionary,product:String)->int:return int(b.assets.get(rental_fleet(product),{}).get("count",0))*2
func on_hire(b:Dictionary,product:String)->int:return b.rentals.filter(func(h):return h.fleet==rental_fleet(product)).size()
func maintain(id:String)->bool:
 if not can_manage(id,true):return false
 var b=business(id);var cost=0.0
 for a in b.assets.values():cost+=(1-float(a.condition))*40*int(a.get("count",1))
 cost=snappedf(maxf(5,cost),.01)
 if b.cash<cost:return false
 expense(id,"Maintenance",cost,"Service all installed equipment")
 for a in b.assets.values():a.condition=1.0
 log_action(id,"Maintain","Equipment service %.2f" % cost);return true
func hire(id:String,index:int)->bool:
 if not can_manage(id,true) or index<0 or index>=C.staff().size():return false
 var b=business(id);var p=C.staff()[index]
 if b.employees.size()>=6 or b.cash<25:return false
 for owned in state.businesses.values():
  if owned.employees.any(func(e):return int(e.id)==int(p.id)):return false
 expense(id,"Recruitment",25,p.name+" • interview and induction");b.employees.append({"id":int(p.id),"role":"stock","wage":float(p.wage),"training":0,"morale":75.0});log_action(id,"Hire",p.name+" • assigned initially to receiving; choose their role");rebuild_workers();return true
func dismiss(id:String,index:int)->bool:
 if not can_manage(id,true):return false
 var b=business(id)
 if index<0 or index>=b.employees.size():return false
 var p=C.person(int(b.employees[index].id));var cost=float(p.wage)*.5
 if b.cash<cost:return false
 expense(id,"Staff departure",cost,p.name+" • transition cost");b.employees.remove_at(index);log_action(id,"Dismiss",p.name);rebuild_workers();return true
func role(id:String,index:int,value:String)->bool:
 if not can_manage(id,true) or value not in ["craft","serve","stock"]:return false
 var b=business(id)
 if index<0 or index>=b.employees.size():return false
 b.employees[index].role=value;log_action(id,"Assign role",C.person(int(b.employees[index].id)).name+" → "+value);rebuild_workers();return true
func improve(id:String,key:String)->bool:
 if not can_manage(id,true) or key not in ["quality","display","cold","brand","training"]:return false
 var b=business(id);var cost=60.0+b[key]*45
 if b[key]>=3 or b.cash<cost:return false
 if key in ["training","brand"]:expense(id,"Development",cost,key)
 else:transaction(id,"Investment",-cost,key)
 b[key]+=1;log_action(id,"Improve",key+" level "+str(b[key]));return true
func advertise(id:String,amount:float)->bool:
 if not can_manage(id,true) or amount not in [0.0,10.0,25.0]:return false
 business(id).ad=amount;log_action(id,"Campaign","%.0f reserved at opening" % amount);return true
func rearrange(id:String)->bool:
 if not can_manage(id,true):return false
 var b=business(id);b.layout=(int(b.layout)+1)%3;log_action(id,"Layout",str(b.layout));rebuild_workers();return true
func set_price(id:String,value:float)->bool:
 var b=business(id)
 if b.is_empty() or b.menu.is_empty():return false
 return product_plan(id,b.menu.keys()[0],value,int(b.menu.values()[0].target))
func finance(id:String)->bool:
 if not can_manage(id,true):return false
 var b=business(id)
 if b.loan>0:
  if b.cash<b.loan:return false
  transaction(id,"Loan repayment",-b.loan,"Principal and agreed fee");b.loan=0;b.pending_expenses+=10;return true
 transaction(id,"Loan received",90,"90 received; 100 due. Loan proceeds are not revenue.");b.loan=100;log_action(id,"Finance","Borrow 90; 100 due");return true
func wage(id:String)->float:
 var total=0.0
 for e in business(id).employees:total+=float(e.get("wage",C.person(int(e.id)).wage))
 return total
func ready_recipe(id:String,key:String)->String:
 var b=business(id);var p=C.ops().products[key]
 for eq in p.equipment:
  if not b.assets.has(eq):return "Needs "+C.ops().equipment[eq].name
  if b.assets[eq].condition<.15:return "Service "+C.ops().equipment[eq].name
 for m in p.materials:
  if quantity(b.materials,m)<p.materials[m]:return "Missing "+C.ops().materials[m].name
 return "Ready to prepare"
func skill(id:String,role_name:String,domain:String="")->float:
 var b=business(id);var total=.65 if role_name=="craft" else .8
 var active_domain=domain if not domain.is_empty() else str(b.trade)
 for e in b.employees:
  if e.role!=role_name:continue
  var p=C.person(int(e.id));var value=float(p.get("skills",{}).get(active_domain,p.get("craft",.8))) if role_name=="craft" else float(p.get("service",.8)) if role_name=="serve" else float(p.get("logistics",.8))
  var morale=float(e.get("morale",75))/100
  total+=value*(.7+morale*.3)*float(p.get("reliability",1.0))+.08*int(b.training)
 return total
func start(id:String)->bool:
 if not can_manage(id,true):return false
 var b=business(id)
 if b.failed:last_notice="This business has closed through insolvency. Review the ledger, then restart or recapitalise.";return false
 if ownership_limit>0 and state.businesses.values().filter(func(x):return x.open).size()>=ownership_limit:last_notice="At most five public ventures may trade together.";return false
 var enabled=b.menu.keys().filter(func(k):return b.menu[k].enabled)
 if b.cash<15+b.ad or enabled.is_empty():last_notice="Choose products and keep cash for opening costs.";return false
 var possible=enabled.any(func(k):return ready_recipe(id,k)=="Ready to prepare" or quantity(b.finished,k)>0)
 if not possible:last_notice="None of your menu can be made. Check specific ingredients and equipment.";return false
 scene_changed=true;b.opening_cash=b.cash;b.opening_inventory=b.input_book+b.stock_book;b.open=true;b.elapsed=0.0;b.produce=0.0;b.production_key="";b.observations={};b.missed={};b.served=0;b.lost=0;b.revenue=0.0;b.cogs=0.0;b.wait_total=0.0;b.expenses=float(b.pending_expenses);b.pending_expenses=0.0;b.asset_use={};b.visitors=0
 transaction(id,"Promotion",-b.ad,"Campaign for this period");b.expenses+=b.ad;b.reason="Open: watch preparation, stock and queues.";log_action(id,"Open","180 active seconds; no offline trading");rebuild_workers();return true
func tick_business(id:String,dt:float)->void:
 if id in pending_resets or public_catalog and id not in PUBLIC_VENTURES:return
 var b=business(id)
 for o in b.orders:
  o.due=maxf(0,o.due-dt*(1+.12*skill(id,"stock")))
  if o.due<=0:add_lot(b.materials,o.material,int(o.qty),float(o.cost),float(o.quality));effects.append({"pos":station(id,"stock"),"text":C.ops().materials[o.material].name+" received","life":2.0,"kind":"delivery"});changed=true
 b.orders=b.orders.filter(func(o):return o.due>0);sync(b)
 if not b.open:return
 if not allowed(id):b.open=false;b.reason="Trading paused by teacher access.";end_customers(id);changed=true;return
 b.elapsed+=dt;tick_services(id,dt)
 var choices=b.menu.keys().filter(func(k):return b.menu[k].enabled and quantity(b.finished,k)<b.menu[k].target and ready_recipe(id,k)=="Ready to prepare")
 if not choices.is_empty():
  if b.production_key not in choices:b.production_key=choices[0];b.produce=0.0
  # Prioritize a waiting customer's actual order over a menu item already on display.
  for p in people:
   if p.shop==id and p.get("product","") in choices and quantity(b.finished,p.product)==0:
    if b.production_key!=p.product:b.production_key=p.product;b.produce=0.0
    break
  var product=C.ops().products[b.production_key];var speed=(skill(id,"craft",product.trade)+.12*b.equipment)*(1+.08*b.training)
  if b.trade=="courier":speed*=1+.15*b.route
  var parallel=12
  for eq in product.equipment:parallel=mini(parallel,int(b.assets[eq].get("count",1)))
  var preparers=1+b.employees.filter(func(e):return e.role=="craft").size()
  speed*=mini(parallel,preparers)
  for eq in product.equipment:speed*=clampf(b.assets[eq].condition,.3,1)
  b.produce+=dt*speed
  if b.produce>=product.prep:
   make_one(id,b.production_key);b.produce=0.0;b.production_key=""
 else:b.production_key="";b.produce=0.0;b.reason="Check the menu for missing materials or equipment." if b.stock==0 else "Products ready; watch service and demand."
 if b.elapsed>=PERIOD:close(id)
func make_one(id:String,key:String)->bool:
 if ready_recipe(id,key)!="Ready to prepare":return false
 var b=business(id);var product=C.ops().products[key];var cost=0.0;var q=0.0
 for m in product.materials:
  var used=take(b.materials,m,int(product.materials[m]));cost+=used.cost;q+=used.quality
 q=q/maxi(1,product.materials.size());q*=clampf(.8+skill(id,"craft",product.trade)*.13,.8,1.2)
 add_lot(b.finished,key,1,cost,q)
 for eq in product.equipment:
  var asset=b.assets[eq];asset.condition=maxf(.1,asset.condition-(.004 if eq in ["stove","forge","oven","fryer","coffee_machine","saw"] else .002)/int(asset.get("count",1)));b.asset_use[eq]=float(b.asset_use.get(eq,0))+float(product.prep)
 sync(b);effects.append({"pos":station(id,"craft")-Vector2(0,50),"text":"+ "+product.name,"life":1.4,"kind":"make"});return true
func stock_help(id:String)->bool:
 if not can_manage(id):return false
 var b=business(id)
 if b.open:last_notice="The proprietor is already preparing during trading. Staff and equipment increase capacity.";return false
 for key in b.menu:
  if b.menu[key].enabled and quantity(b.finished,key)<b.menu[key].target and ready_recipe(id,key)=="Ready to prepare":
   # A preparation action incurs labour cost; repeated clicks cannot manufacture free labour.
   if b.cash<2:return false
   expense(id,"Owner preparation",2,C.ops().products[key].name);return make_one(id,key)
 last_notice="No planned product can be prepared with the current materials and equipment.";return false
func sell(id:String,key:String,wait:float)->bool:
 var b=business(id)
 if not b.menu.has(key) or quantity(b.finished,key)<1:return false
 if b.trade=="rental" and on_hire(b,key)>=rental_capacity(b,key):return false
 var used=take(b.finished,key,1);var price=float(b.menu[key].price);b.served+=1;b.revenue+=price;b.cogs+=used.cost;b.wait_total+=wait
 transaction(id,"Sale",price,C.ops().products[key].name);b.reputation=clampf(b.reputation+(used.quality-.8)*1.3,0,100);sync(b)
 if b.trade=="rental":
  var fleet=rental_fleet(key);b.rentals.append({"product":key,"fleet":fleet,"remaining":28.0});b.asset_use[fleet]=float(b.asset_use.get(fleet,0))+28.0
  if b.assets.has(fleet):b.assets[fleet].condition=maxf(.1,b.assets[fleet].condition-.012/maxi(1,int(b.assets[fleet].count)))
 b.observations[key]=int(b.observations.get(key,0))+1;changed=true;return true
func close(id:String)->bool:
 var b=business(id)
 if b.is_empty() or not b.open:return false
 var unfinished=0.0
 for job in b.services:unfinished+=float(job.cost);b.lost+=1
 b.services.clear();b.expenses+=unfinished
 var fraction=clampf(b.elapsed/PERIOD,.05,1);var wages=wage(id)*fraction;var rent=(24.0+asset_units(b)*1.5)*fraction
 transaction(id,"Wages",-wages,"Staff pay for active opening time");transaction(id,"Premises",-rent,"Rent, utilities and equipment running costs");b.expenses+=wages+rent
 var spoiled=0;var loss=0.0
 for store_key in ["materials","finished"]:
  var store=b[store_key]
  for key in store:
   var life=int(C.ops().materials[key].life if store_key=="materials" else C.ops().products[key].life)
   if life==0:continue
   for lot in store[key]:
    lot.age+=1;lot.quality=maxf(.4,lot.quality-.04)
    var protected=store_key=="materials" and C.ops().materials[key].cold and b.assets.has("fridge") or store_key=="finished" and b.assets.has("freezer")
    if lot.age>=life+(1 if protected else 0)+int(b.cold):spoiled+=int(lot.qty);loss+=float(lot.cost);lot.qty=0;lot.cost=0.0
   store[key]=store[key].filter(func(l):return l.qty>0)
 b.expenses+=loss;sync(b)
 var idle=0;var utilisation={}
 for eq in b.assets:
  var a=b.assets[eq];var used=float(b.asset_use.get(eq,0));utilisation[eq]=snappedf(minf(100,used/maxf(1,b.elapsed*int(a.count))*100),.1)
  if used==0:idle+=int(a.count)
 var day_profit=snappedf(b.revenue-b.cogs-b.expenses,.01);var full_day=b.elapsed>=PERIOD-.2
 b.summary.profit+=day_profit;b.summary.spoilage_cost+=loss
 if full_day:
  b.summary.full_days+=1;b.summary.idle_equipment_days+=idle
  if day_profit>0:b.summary.profitable_days+=1;b.summary.streak+=1;b.summary.best_streak=maxi(int(b.summary.best_streak),int(b.summary.streak))
  else:b.summary.streak=0
 for e in b.employees:e.morale=clampf(float(e.get("morale",75))+(1 if b.cash>0 else -12),0,100)
 b.arrears=int(b.arrears)+1 if b.cash<0 else 0;b.failed=b.cash< -200 or b.arrears>=3
 var report={"day":int(b.day)+1,"seconds":snappedf(b.elapsed,.1),"sold":int(b.served),"lost":int(b.lost),"revenue":snappedf(b.revenue,.01),"cogs":snappedf(b.cogs,.01),"expenses":snappedf(b.expenses,.01),"profit":snappedf(b.revenue-b.cogs-b.expenses,.01),"cash":b.cash,"inventory":snappedf(b.input_book+b.stock_book,.01),"loan":b.loan,"wages":snappedf(wages,.01),"spoilage":spoiled,"wait":snappedf(b.wait_total/maxi(1,int(b.served)),.1),"price":b.price,"layout":b.layout,"campaign":b.ad,"equipment":b.equipment,"quality":b.quality,"employees":b.employees.duplicate(true),"products_sold":b.observations.duplicate(true),"missed_requests":b.get("missed",{}).duplicate(true),"spoilage_cost":snappedf(loss,.01),"visitors":int(b.visitors),"idle_units":idle,"utilisation":utilisation,"full_day":full_day,"unfinished_service_cost":unfinished}
 b.day+=1;state.periods+=1;b.last_result=report;b.history.append(report)
 if b.history.size()>24:b.history.pop_front()
 b.open=false;b.elapsed=0.0;b.reason="Insolvent: trading stopped. Review costs, recapitalise or start over." if b.failed else "Period complete. Compare product demand, waste and cash before reopening."
 scene_changed=true;end_customers(id);log_action(id,"Close","Operating profit %.2f; %d lost customers; %d spoiled units" % [report.profit,b.lost,spoiled]);refresh_applicants();rebuild_workers();last_notice=b.name+": "+b.reason;return true
func recapitalise(id:String)->bool:
 if not can_manage(id,true):return false
 var b=business(id)
 if not b.failed or b.cash<100:return false
 b.failed=false;b.arrears=0;log_action(id,"Recovery","Resumed after capital transfer; previous losses remain recorded.");return true
func restart()->void:
 var old_count=int(state.restart_count);var archive={"periods":int(state.periods),"ventures":state.businesses.keys(),"cash":0.0,"reason":"Player confirmed a fresh district"}
 for b in state.businesses.values():archive.cash+=float(b.cash)
 var history=state.archives.duplicate(true);history.append(archive)
 if history.size()>5:history.pop_front()
 var clean=C.upgrade(C.fresh());clean.restart_count=old_count+1;clean.archives=history
 state.clear();state.merge(clean);people.clear();effects.clear();setup(state);changed=true;last_notice="Fresh district started. Earlier submitted assignments and adventure progress are unchanged."
func station(_id:String,_kind:String)->Vector2:return Vector2.ZERO
func rebuild_workers()->void:pass
func end_customers(_id:String)->void:pass

func investigate(id:String)->bool:
 if C.spec(id).is_empty():return false
 var v=C.spec(id);state.research[id]={"period":int(state.periods),"need":v.need,"tradeoff":v.tradeoff,"acquisition":acquisition(id)};changed=true;last_notice="Premises inspection saved: "+v.name;return true

func maintenance_quote(id:String)->float:
 var cost=0.0
 for a in business(id).assets.values():cost+=(1-float(a.condition))*40*int(a.get("count",1))
 return snappedf(maxf(5,cost),.01)

func service_capacity(b:Dictionary,key:String)->int:
 var product=C.ops().products[key];var trade_id=str(product.trade);var preparers=1+b.employees.filter(func(e):return e.role=="craft").size()
 if trade_id=="salon":return mini(6,mini(int(b.assets.get("barber_chair",{}).get("count",0)),preparers))
 if trade_id=="daycare":return mini(8,mini(int(b.assets.get("dog_pen",{}).get("count",0))*3,preparers*2))
 if trade_id=="minigolf":
  var course="putting_green" if key in ["golf_practice","golf_coaching"] else "golf_course"
  return mini(12,mini(int(b.assets.get(course,{}).get("count",0))*4,mini(int(b.assets.get("golf_clubs",{}).get("count",0))*4,preparers*4)))
 return 0
func service_weight(key:String)->int:return 2 if key=="family_round" else 1
func occupied_slots(b:Dictionary)->int:
 var total=0
 for job in b.services:total+=job.slots.size()
 return total
func service_seconds(id:String,key:String)->float:
 return float(C.ops().products[key].get("service_duration",0))/maxf(.5,skill(id,"craft"))
func service_position(id:String,slot:int)->Vector2:
 var b=business(id);var origin=C.plot(id)
 if b.trade=="salon":return origin+Vector2(105+(slot%3)*155,270+(slot/3)*85)
 if b.trade=="daycare":return origin+Vector2(95+(slot%4)*110,220+(slot/4)*70)
 return origin+Vector2(80+(slot%3)*168,242+(slot/3)*45)
func begin_service(id:String,key:String,wait:float)->int:
 if not can_manage(id) or not business(id).open or business(id).failed or not business(id).menu.get(key,{}).get("enabled",false):return -1
 var b=business(id);var slots=service_weight(key);var duration=service_seconds(id,key)
 if quantity(b.finished,key)<1 or occupied_slots(b)+slots>service_capacity(b,key):return -1
 if PERIOD-b.elapsed<duration+1:return -2
 for eq in C.ops().products[key].equipment:
  if not b.assets.has(eq) or b.assets[eq].condition<.15:return -1
 var used=take(b.finished,key,1);var occupied=[]
 for job in b.services:occupied+=job.slots
 var positions=[]
 for n in range(service_capacity(b,key)):
  if not n in occupied:positions.append(n)
  if positions.size()==slots:break
 if positions.size()!=slots:return -1
 b.next_service+=1;b.services.append({"id":int(b.next_service),"product":key,"remaining":duration,"duration":duration,"slots":positions,"cost":float(used.cost),"quality":float(used.quality),"price":float(b.menu[key].price),"wait":wait})
 sync(b);log_action(id,"Service begins",C.ops().products[key].name);return int(b.next_service)
func tick_services(id:String,dt:float)->void:
 var b=business(id)
 for job in b.services:
  job.remaining=maxf(0,job.remaining-dt)
  if job.remaining>0:continue
  b.served+=1;b.revenue+=job.price;b.cogs+=job.cost;b.wait_total+=job.wait;b.observations[job.product]=int(b.observations.get(job.product,0))+1
  b.reputation=clampf(b.reputation+(job.quality-.75),0,100);transaction(id,"Service completed",job.price,C.ops().products[job.product].name)
  for eq in C.ops().products[job.product].equipment:
   if b.assets.has(eq):b.assets[eq].condition=maxf(.1,b.assets[eq].condition-.008/maxi(1,int(b.assets[eq].count)));b.asset_use[eq]=float(b.asset_use.get(eq,0))+float(job.duration)
 b.services=b.services.filter(func(j):return j.remaining>0)
func work_in_progress(b:Dictionary)->float:
 var value=0.0
 for job in b.services:value+=float(job.cost)
 return value

func divestment_quote(id:String)->float:
 var b=business(id);var value=300.0+float(b.cash)-float(b.loan)+float(b.input_book+b.stock_book)*.5
 for asset in b.assets.values():value+=float(asset.paid)*.55*float(asset.condition)
 return snappedf(value,.01)
func divest(id:String)->bool:
 if not can_manage(id,true):return false
 var b=business(id)
 if not b.rentals.is_empty() or not b.services.is_empty():last_notice="Finish outstanding services and wait for hired equipment to return.";return false
 var value=divestment_quote(id)
 if value<0:last_notice="The remaining assets and cash do not cover the loan.";return false
 if not state.has("divestments"):state.divestments=[]
 state.divestments.append({"id":id,"name":b.name,"days":int(b.day),"profit":float(b.summary.profit),"returned":value})
 if state.divestments.size()>20:state.divestments.pop_front()
 state.reserve+=value;state.businesses.erase(id);state.started=true;end_customers(id);rebuild_workers();changed=true;last_notice="Venture sold; %.2f returned to the expansion reserve. Startup support cannot be claimed again." % value;return true

func demand_factor(id:String,key:String)->float:
 var b=business(id);var cycle=int(b.day)/3;var token=str(state.seed)+":"+str(cycle)+":"+key
 var value=posmod(token.hash(),100)
 var seasonal=1.18 if (posmod(int(b.day),4)==1 and C.ops().products[key].trade in ["kitchen","cafe","dessert","garden","fishery"]) else .78 if posmod(int(b.day),4)==3 and C.ops().products[key].trade=="minigolf" else 1.0
 return ([.55,.8,1.0,1.25,1.6][mini(4,value/20)])*seasonal
func trend_text(id:String,key:String)->String:
 var factor=demand_factor(id,key)
 return ("Cooling" if factor<.85 else "Growing" if factor>1.2 else "Steady")+" • demand ×%.2f • outlook changes every 3 trading days" % factor

func restart_business(id:String)->bool:
 if not can_manage(id,true):return false
 var previous=business(id);var title=str(previous.name);var trade_id=str(previous.trade);var cost=float(previous.acquisition)
 var before={"id":id,"name":title,"day":previous.day,"cash":previous.cash,"summary":previous.summary.duplicate(true),"employees":previous.employees.size()}
 if not state.has("business_reset_history"):state.business_reset_history=[]
 state.business_reset_history.append(before);if state.business_reset_history.size()>20:state.business_reset_history.pop_front()
 var b=C.fresh_business(id);b.trade=trade_id;b.inputs=0;b.stock=0;b.input_book=0;b.stock_book=0;C.ensure_business(id,b);b.name=title;b.acquisition=cost;b.cash=2200.0 if C.spec(id).get("blank",false) else 1200.0;b.opening_cash=b.cash;b.reset_epoch=int(previous.get("reset_epoch",0))+1
 if C.spec(id).get("blank",false):b.menu={};b.assets={}
 else:
  for key in C.spec(trade_id).starter_products:
   for m in C.ops().products[key].materials:add_lot(b.materials,m,5*int(C.ops().products[key].materials[m]),C.ops().materials[m].cost*5*C.ops().products[key].materials[m],1)
 state.businesses[id]=b;C.upgrade(state);sync(b);end_customers(id);rebuild_workers();scene_changed=true;last_notice="Business restarted. Other businesses, reserve savings and submitted work are preserved.";return true

func retire_unavailable(id:String)->bool:
 if not public_catalog or id in PUBLIC_VENTURES or not state.businesses.has(id):return false
 public_catalog=false
 if business(id).open:close(id)
 var ok=divest(id);public_catalog=true;return ok
