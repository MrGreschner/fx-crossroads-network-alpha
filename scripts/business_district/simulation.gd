extends RefCounted
const C=preload("res://scripts/business_district/catalog.gd")
const PERIOD=180.0
const LIMIT=48
var state:Dictionary
var people:Array=[]
var workers:Array=[]
var effects:Array=[]
var clock=0.0
var spawn_clock=0.0
var rng=RandomNumberGenerator.new()
var next_id=0
var changed=false
var help_cooldown=0.0
var last_notice=""
var last_us=0
var max_us=0
func setup(value:Dictionary)->void:
 state=value;rng.seed=1983401+int(state.periods)*171;rebuild_workers()
func business(id:String)->Dictionary:return state.businesses.get(id,{})
func log_action(id:String,action:String,detail:String)->void:
 var b=business(id)
 b.decisions.append({"day":int(b.day)+1,"time":snappedf(b.elapsed,.1),"action":action,"detail":detail.left(300)})
 if b.decisions.size()>60:b.decisions.pop_front()
 changed=true
func transaction(id:String,kind:String,amount:float,detail:String)->void:
 var b=business(id);b.cash=snappedf(b.cash+amount,.01);b.ledger.append({"day":b.day+1,"kind":kind,"amount":snappedf(amount,.01),"balance":b.cash,"detail":detail.left(160)})
 if b.ledger.size()>100:b.ledger.pop_front()
 changed=true
func establish(id:String)->bool:
 if C.spec(id).is_empty() or state.businesses.has(id) or state.reserve<300:return false
 state.reserve-=300;state.businesses[id]=C.fresh_business(id);state.selected=id;log_action(id,"Establish","Allocated 300 market cash from the district reserve.");rebuild_workers();last_notice="Your premises are ready. Order supplies and meet your applicants.";return true
func hire(id:String,index:int)->bool:
 var b=business(id)
 if b.is_empty() or index<0 or index>=C.staff().size() or b.open or b.employees.size()>=3:return false
 for owned in state.businesses.values():
  if owned.employees.any(func(e):return int(e.id)==index):return false
 var fee=15.0
 if b.cash<fee:return false
 transaction(id,"Recruitment",-fee,"Hiring and induction for "+C.staff()[index].name)
 b.employees.append({"id":index,"role":"craft" if b.employees.is_empty() else "serve"});log_action(id,"Hire",C.staff()[index].name);rebuild_workers();return true
func role(id:String,index:int,value:String)->bool:
 var b=business(id)
 if value not in ["craft","serve","stock"] or b.is_empty() or index<0 or index>=b.employees.size():return false
 b.employees[index].role=value;log_action(id,"Assign role",C.staff()[int(b.employees[index].id)].name+" → "+value);rebuild_workers();return true
func order(id:String,units:int)->bool:
 var b=business(id)
 if b.is_empty() or units<1 or units>100 or not b.delivery.is_empty() or b.inputs+units>300:return false
 var total=float(C.spec(id).cost)*units*(1+.12*int(b.quality))+4
 if b.cash<total:last_notice="Not enough cash for that delivery.";return false
 transaction(id,"Supply purchase",-total,"%d units + 4 delivery" % units);b.delivery={"units":units,"cost":total};b.delivery_due=8.0+int(b.route)*3
 log_action(id,"Order","%d units, %.2f cash" % [units,total]);last_notice="Delivery dispatched. Watch the receiving bay.";return true
func improve(id:String,key:String)->bool:
 var b=business(id)
 if b.is_empty() or b.open or key not in ["equipment","quality","display","cold","brand","training"] or b[key]>=3:return false
 var cost=60.0+float(b[key])*45
 if b.cash<cost:return false
 transaction(id,"Investment",-cost,key);b[key]+=1;log_action(id,"Improve",key+" level "+str(b[key]));return true
func set_price(id:String,value:float)->bool:
 var b=business(id)
 if b.is_empty() or b.open or not is_finite(value) or value<1 or value>float(C.spec(id).price)*3:return false
 b.price=snappedf(value,.5);log_action(id,"Price","%.2f" % b.price);return true
func rearrange(id:String)->bool:
 var b=business(id)
 if b.is_empty() or b.open:return false
 b.layout=(int(b.layout)+1)%3;log_action(id,"Layout",["Compact","Open aisle","Display led"][b.layout]);return true
func advertise(id:String,amount:float)->bool:
 var b=business(id)
 if b.is_empty() or b.open or amount not in [0.0,10.0,25.0] or b.cash<amount:return false
 # Reserve the campaign at opening, not at selection.
 b.ad=amount;log_action(id,"Campaign","%.0f budget" % amount);return true
func finance(id:String)->bool:
 var b=business(id)
 if b.is_empty() or b.open:return false
 if b.loan>0:
  if b.cash<b.loan:return false
  transaction(id,"Loan repayment",-b.loan,"Repay full principal and agreed fee");b.loan=0;log_action(id,"Finance","Repaid 100.");return true
 transaction(id,"Loan received",90,"90 principal; 10 financing fee due on repayment");b.loan=100;log_action(id,"Finance","Borrowed 90; 100 due. Loan proceeds are not revenue.");return true
func start(id:String)->bool:
 var b=business(id)
 if b.is_empty() or b.open or b.cash<20+b.ad or b.inputs+b.stock==0:return false
 b.opening_cash=b.cash;b.opening_inventory=b.input_book+b.stock_book;b.open=true;b.elapsed=0.0;b.produce=0.0;b.served=0;b.lost=0;b.revenue=0.0;b.cogs=0.0;b.wait_total=0.0;b.expenses=0.0
 transaction(id,"Promotion",-b.ad,"Campaign for this period");b.expenses+=b.ad;b.reason="Customers are arriving.";log_action(id,"Open","180 active seconds; no offline trading.");last_notice="Open for business. Click customers and staff to see what is happening.";return true
func wage(id:String)->float:
 var total=0.0
 for e in business(id).employees:total+=float(C.staff()[int(e.id)].wage)
 return total
func close(id:String)->bool:
 var b=business(id)
 if b.is_empty() or not b.open:return false
 var fraction=clampf(b.elapsed/PERIOD,0,1);var wages=wage(id)*fraction;var rent=8.0*fraction
 transaction(id,"Wages",-wages,"Staff pay for active opening time");transaction(id,"Premises",-rent,"Rent and utilities for active opening time");b.expenses+=wages+rent
 var spoil=0;var spoil_cost=0.0
 if bool(C.spec(id).perishable):
  spoil=int(floor(float(b.stock)*(.5 if b.cold==0 else .2 if b.cold==1 else .08 if b.cold==2 else 0)))
  spoil_cost=spoil*float(b.stock_book)/maxi(1,int(b.stock));b.stock-=spoil;b.stock_book=maxf(0,b.stock_book-spoil_cost)
 b.expenses+=spoil_cost
 var profit=snappedf(b.revenue-b.cogs-b.expenses,.01)
 var report={"day":int(b.day)+1,"seconds":snappedf(b.elapsed,.1),"sold":int(b.served),"lost":int(b.lost),"revenue":b.revenue,"cogs":b.cogs,"expenses":snappedf(b.expenses,.01),"profit":profit,"cash":b.cash,"inventory":snappedf(b.input_book+b.stock_book,.01),"loan":b.loan,"wages":snappedf(wages,.01),"spoilage":spoil,"wait":snappedf(b.wait_total/maxi(1,int(b.served)),.1),"price":b.price,"layout":b.layout,"campaign":b.ad,"equipment":b.equipment,"quality":b.quality,"employees":b.employees.duplicate(true)}
 b.day+=1;state.periods+=1;b.last_result=report;b.history.append(report)
 if b.history.size()>24:b.history.pop_front()
 b.open=false;b.elapsed=0.0;b.reason="Period complete. Inspect the ledger, then adjust and reopen."
 for p in people:
  if p.shop==id and p.phase!="leave":p.phase="leave";p.path=[]
 log_action(id,"Close","Revenue %.2f − stock cost %.2f − expenses %.2f = profit %.2f" % [report.revenue,report.cogs,report.expenses,profit]);last_notice="Period complete • "+b.name+" • profit %.2f" % profit;return true
func station(id:String,kind:String)->Vector2:
 var o=C.plot(id);var b=business(id);var layout=int(b.get("layout",0))
 match kind:
  "craft":return o+Vector2(83 if layout!=1 else 260,155)
  "stock":return o+Vector2(325,72)
  "serve":return o+Vector2(210,174)
  "browse":return o+Vector2(318 if layout!=2 else 98,277)
  "entry":return o+Vector2(210,357)
 return o+Vector2(210,270)
func rebuild_workers()->void:
 workers.clear()
 for id in state.businesses:
  workers.append({"shop":id,"person":8,"role":"serve","pos":station(id,"serve"),"prev":station(id,"serve"),"dest":station(id,"serve"),"owner":true,"phase":0.0})
  for e in business(id).employees:
   workers.append({"shop":id,"person":int(e.id),"role":e.role,"pos":station(id,"stock"),"prev":station(id,"stock"),"dest":station(id,e.role),"owner":false,"phase":0.0})
func move_actor(p:Dictionary,goal:Vector2,speed:float,dt:float)->bool:
 p.prev=p.pos;p.pos=p.pos.move_toward(goal,speed*dt);return p.pos.distance_to(goal)<2
func spawn_customer(id:String)->void:
 if people.size()>=LIMIT:return
 next_id+=1
 var index=next_id%8;var v=C.spec(id);var o=C.plot(id);var b=business(id)
 var segment=next_id%3
 var names=["Wren","Cedar","Edda","Finch","Rowan","Juniper","Soren","Clover","Moss","Hazel","Iris","Vale"]
 var pos=o+Vector2(40 if next_id%2 else 400,405)
 people.append({"id":next_id,"name":names[next_id%names.size()]+" • "+["traveller","town resident","collector"][segment],"segment":segment,"shop":id,"person":index,"pos":pos,"prev":pos,"phase":"approach","wait":0.0,"service":0.0,"age":0.0,"budget":float(v.price)*rng.randf_range([1.0,1.1,1.3][segment],[1.4,1.65,1.9][segment]),"thought":"Looking for "+v.product.to_lower(),"path":[],"browse":rng.randf_range(1.5,3.8),"bought":false,"fade":1.0})
 state.visitors+=1
func step(dt:float)->void:
 var begin=Time.get_ticks_usec();clock+=dt;spawn_clock+=dt;help_cooldown=maxf(0,help_cooldown-dt)
 if spawn_clock>=1.5:
  spawn_clock=0
  for id in state.businesses:
   var b=business(id)
   if not b.open:continue
   var count=people.filter(func(p):return p.shop==id and p.phase!="leave").size()
   var probability=.40+float(b.ad)*.012+float(b.brand)*.06+float(b.reputation)*.002
   # Four period events give observable demand changes without a hidden random economy.
   var event=int(b.day)%4
   if event==1 and id in ["kitchen","garden","fishery"]:probability*=1.35
   if event==2 and id in ["workshop","mine","rental"]:probability*=1.35
   if event==3:probability*=.8
   if count<8 and rng.randf()<probability:spawn_customer(id)
 for w in workers:
  var b=business(w.shop);w.phase+=dt
  var destination=station(w.shop,w.role)
  if w.role=="craft" and int(clock/7)%3==0:destination=station(w.shop,"stock")
  if not b.open:destination=station(w.shop,"stock")+Vector2((w.person%3)*18,35)
  w.dest=destination;move_actor(w,destination,58.0,dt)
 for id in state.businesses:
  var b=business(id);var v=C.spec(id)
  for i in b.hires.size():b.hires[i]=maxf(0,float(b.hires[i])-dt)
  var returned=b.hires.filter(func(t):return t<=0).size()
  if returned>0:
   b.hires=b.hires.filter(func(t):return t>0);effects.append({"pos":station(id,"stock"),"text":"Equipment returned","life":1.5,"kind":"return"});changed=true
  if not b.delivery.is_empty():
   b.delivery_due=maxf(0,b.delivery_due-dt)
   if b.delivery_due<=0:
    b.inputs+=int(b.delivery.units);b.input_book+=float(b.delivery.cost);b.delivery={};b.reason="Supplies received at the loading bay.";last_notice=b.name+": delivery received.";changed=true
  if not b.open:continue
  b.elapsed+=dt
  if b.inputs>0 and b.stock<30+int(b.display)*10:
   var crafting=workers.filter(func(w):return w.shop==id and not w.owner and w.role=="craft" and w.pos.distance_to(station(id,"craft"))<15)
   # The proprietor handles preparation between customers; dedicated staff improve capacity.
   var speed=.8+float(b.equipment)*.35+float(b.training)*.10
   for e in b.employees:
    if e.role=="stock":speed+=.15
   for w in crafting:speed+=float(C.staff()[w.person].craft)*.65
   if id=="courier":speed*=1.0+float(b.route)*.18
   b.produce+=dt*speed
   if b.produce>=float(v.prep)*(1+.08*int(b.quality)):
    b.produce=0;var cost=float(b.input_book)/maxi(1,int(b.inputs));b.inputs-=1;b.input_book=maxf(0,b.input_book-cost);b.stock+=1;b.stock_book+=cost;effects.append({"pos":station(id,"craft")-Vector2(0,50),"text":"+1","life":1.0,"kind":"make"})
  if b.elapsed>=PERIOD:close(id)
 for p in people:
  p.age+=dt;var b=business(p.shop)
  if p.phase=="approach":
   if move_actor(p,station(p.shop,"entry"),58,dt):p.phase="browse"
  elif p.phase=="browse":
   if move_actor(p,station(p.shop,"browse")+Vector2((p.id%3)*12,0),55,dt):
    p.browse-=dt
    if p.browse<=0:
     var fair=float(C.spec(p.shop).price)*(1+.1*int(b.quality)+.04*int(b.display))
     if b.price>minf(float(p.budget),fair*1.7):lose(p,"The price is above my budget.")
     else:p.phase="queue";p.thought="Waiting to be served."
  elif p.phase=="queue":
   p.wait+=dt
   var queue=people.filter(func(q):return q.shop==p.shop and q.phase=="queue");var place=queue.find(p)
   var goal=station(p.shop,"serve")+Vector2(0,68+place*23)
   # Layout changes queue approach and the available service aisle.
   if int(b.layout)==0:goal.x+=minf(35,place*7)
   if move_actor(p,goal,61,dt) and place==0:
    if not b.open:lose(p,"The shop has closed.")
    elif p.shop=="rental" and b.hires.size()>=2+int(b.equipment)*2:p.thought="Waiting for hired equipment to return."
    elif b.stock>0:
     var service=1.0+float(b.training)*.15+(0.2 if b.layout==1 else 0)
     for e in b.employees:
      if e.role=="serve":service+=float(C.staff()[int(e.id)].service)*.55
     p.service+=dt*service
     if p.service>=2.8:
      var cost=float(b.stock_book)/maxi(1,int(b.stock));b.stock-=1;b.stock_book=maxf(0,b.stock_book-cost);b.served+=1;b.revenue+=b.price;b.cogs+=cost;b.wait_total+=p.wait
      if p.shop=="rental":b.hires.append(28.0)
      transaction(p.shop,"Sale",b.price,C.spec(p.shop).product);b.reputation=clampf(b.reputation+.3,0,100);p.bought=true;p.thought="Thank you! I'll tell a friend.";p.phase="leave";effects.append({"pos":p.pos-Vector2(0,48),"text":"+%.0f" % b.price,"life":1.5,"kind":"sale"});changed=true
    else:p.thought="Waiting for the next prepared item."
   if p.phase=="queue" and p.wait>([25,36,44][p.segment]+int(b.display)*3):lose(p,"The wait was too long." if b.stock>0 else "Nothing was ready in time.")
  elif p.phase=="leave":
   if move_actor(p,station(p.shop,"entry")+Vector2(160,45),65,dt):p.fade-=dt*2
 people=people.filter(func(p):return p.fade>0 and p.age<150)
 for fx in effects:fx.life-=dt
 effects=effects.filter(func(f):return f.life>0)
 if effects.size()>30:effects=effects.slice(effects.size()-30)
 last_us=Time.get_ticks_usec()-begin;max_us=maxi(max_us,last_us)
func lose(p:Dictionary,reason:String)->void:
 if p.phase=="leave":return
 var b=business(p.shop);b.lost+=1;b.reputation=clampf(b.reputation-.6,0,100);b.reason=reason;p.phase="leave";p.thought=reason;changed=true
func stock_help(id:String)->bool:
 var b=business(id)
 if b.is_empty() or b.inputs<=0 or b.stock>=60 or help_cooldown>0:return false
 help_cooldown=2.0
 var cost=float(b.input_book)/maxi(1,int(b.inputs));b.inputs-=1;b.input_book=maxf(0,b.input_book-cost);b.stock+=1;b.stock_book+=cost;log_action(id,"Owner helps","Prepared one unit at the workstation.");return true
