extends "res://scripts/business_district/operations.gd"
const LIMIT=64
var clock=0.0
var spawn_clock=0.0
var next_id=0
var last_us=0
var max_us=0
func station(id:String,kind:String)->Vector2:
 var o=C.plot(id);var b=business(id);var layout=int(b.get("layout",0))
 match kind:
  "craft":return o+1.3*Vector2(83 if layout!=1 else 260,155)
  "stock":return o+1.3*Vector2(325,72)
  "serve":return o+1.3*Vector2(210,174)
  "browse":return o+1.3*Vector2(318 if layout!=2 else 98,277)
  "entry":return o+1.3*Vector2(210,357)
 return o+1.3*Vector2(210,270)
func rebuild_workers()->void:
 workers.clear()
 for id in state.businesses:
  if not business(id).open and id!=state.selected:continue
  workers.append({"shop":id,"person":-1,"role":"serve","pos":station(id,"serve"),"prev":station(id,"serve"),"dest":station(id,"serve"),"owner":true,"phase":0.0})
  for e in business(id).employees:
   workers.append({"shop":id,"person":int(e.id),"role":e.role,"pos":station(id,"stock"),"prev":station(id,"stock"),"dest":station(id,e.role),"owner":false,"phase":0.0})
func move_actor(p:Dictionary,goal:Vector2,speed:float,dt:float)->bool:
 p.prev=p.pos;p.pos=p.pos.move_toward(goal,speed*dt);return p.pos.distance_to(goal)<2
func spawn_customer(id:String)->void:
 if people.size()>=LIMIT:return
 var b=business(id);var keys=b.menu.keys().filter(func(k):return b.menu[k].enabled)
 if keys.is_empty():return
 next_id+=1
 var weights=0.0
 for key in keys:weights+=C.ops().products[key].demand
 var pick=rng.randf()*weights;var product=keys[0]
 for key in keys:
  pick-=C.ops().products[key].demand
  if pick<=0:product=key;break
 var unavailable=C.menu(b.trade).filter(func(x):return not b.menu.has(x.id) or not b.menu[x.id].enabled)
 if rng.randf()<.2 and not unavailable.is_empty():product=unavailable[rng.randi_range(0,unavailable.size()-1)].id
 var p=C.ops().products[product];var segment=next_id%3;var pos=station(id,"entry")+Vector2(180 if next_id%2 else -180,60)
 people.append({"id":next_id,"name":["Wren","Cedar","Edda","Finch","Rowan","Juniper","Soren","Clover"][next_id%8]+" • "+["traveller","town resident","collector"][segment],"segment":segment,"shop":id,"product":product,"person":-2-next_id%8,"pos":pos,"prev":pos,"phase":"approach","wait":0.0,"service":0.0,"age":0.0,"budget":float(p.price)*rng.randf_range([.9,1.0,1.1][segment],[1.35,1.55,1.8][segment]),"thought":"Looking for "+p.name,"path":[],"browse":rng.randf_range(1.5,3.8),"bought":false,"fade":1.0})
 state.visitors+=1;b.visitors+=1
func step(dt:float)->void:
 var begin=Time.get_ticks_usec();clock+=dt;spawn_clock+=dt
 if spawn_clock>=1.5:
  spawn_clock=0
  for id in state.businesses:
   var b=business(id)
   if not b.open or not allowed(id):continue
   var count=people.filter(func(p):return p.shop==id and p.phase!="leave").size()
   var probability=.34+float(b.ad)*.008+float(b.brand)*.035+float(b.reputation)*.0015
   var appeal=0.0
   for key in b.menu:
    if b.menu[key].enabled:appeal+=C.ops().products[key].demand
   probability*=clampf(appeal/2.6,.45,1.4)
   var event=int(b.day)%4
   if event==1 and b.trade in ["kitchen","garden","fishery"]:probability*=1.3
   if event==2 and b.trade in ["workshop","mine","clothier"]:probability*=1.3
   if event==3:probability*=.4 if b.trade=="minigolf" else .7
   if count<9 and rng.randf()<probability:spawn_customer(id)
 for w in workers:
  var b=business(w.shop);w.phase+=dt;var destination=station(w.shop,w.role)
  if w.role=="craft" and int(clock/7)%3==0:destination=station(w.shop,"stock")
  if w.role=="stock" and int(clock/6)%2==1:destination=station(w.shop,"craft")
  if w.get("owner",false) and b.open and not b.production_key.is_empty():
   var ready_customer=people.any(func(p):return p.shop==w.shop and p.phase=="queue" and quantity(b.finished,p.product)>0)
   if not ready_customer:destination=station(w.shop,"craft")
  if not b.open:destination=station(w.shop,"stock")+Vector2(posmod(w.person,3)*18,35)
  w.dest=destination;move_actor(w,destination,68.0,dt)
 for id in state.businesses:
  var b=business(id)
  for i in b.hires.size():b.hires[i]=maxf(0,float(b.hires[i])-dt)
  b.hires=b.hires.filter(func(t):return t>0)
  for hire in b.rentals:hire.remaining=maxf(0,hire.remaining-dt)
  b.rentals=b.rentals.filter(func(h):return h.remaining>0)
  tick_business(id,dt)
 for p in people:
  p.age+=dt;var b=business(p.shop);var product=C.ops().products[p.product]
  if p.phase=="approach":
   if move_actor(p,station(p.shop,"entry"),70,dt):p.phase="browse"
  elif p.phase=="browse":
   if move_actor(p,station(p.shop,"browse")+Vector2((p.id%3)*12,0),68,dt):
    p.browse-=dt
    if p.browse<=0:
     var price=float(b.menu.get(p.product,{}).get("price",product.price));var fair=float(product.price)*(1+.05*b.quality)
     if not b.menu.has(p.product) or not b.menu[p.product].enabled:lose(p,"I wanted "+product.name+", but it is not offered.")
     elif price>minf(float(p.budget),fair*1.45):lose(p,"The "+product.name+" price is above my budget.")
     else:p.phase="queue";p.thought="Waiting for "+product.name
  elif p.phase=="queue":
   p.wait+=dt
   var queue=people.filter(func(q):return q.shop==p.shop and q.phase=="queue");var place=queue.find(p);var goal=station(p.shop,"serve")+Vector2(0,72+place*21)
   if int(b.layout)==0:goal.x+=minf(35,place*7)
   if move_actor(p,goal,73,dt) and place==0:
    if not b.open:lose(p,"The shop has closed.")
    elif b.trade=="rental" and on_hire(b,p.product)>=rental_capacity(b,p.product):p.thought="Waiting for hire equipment to return."
    elif quantity(b.finished,p.product)>0:
     p.service+=dt*(skill(p.shop,"serve")+(0.2 if b.layout==1 else 0))
     if p.service>=3.5:
      if float(product.get("service_duration",0))>0:
       var booking=begin_service(p.shop,p.product,p.wait)
       if booking>=0:p.phase="service";p.booking=booking;p.thought="Appointment in progress: "+product.name
       elif booking==-2:lose(p,"There is not enough time to finish before closing.")
       else:p.thought="Waiting for a free chair, care place or course slot."
      elif sell(p.shop,p.product,p.wait):
       p.bought=true;p.thought="Thank you for the "+product.name;p.phase="leave";effects.append({"pos":p.pos-Vector2(0,48),"text":"+%.0f" % b.menu[p.product].price,"life":1.5,"kind":"sale"})
    else:p.thought=ready_recipe(p.shop,p.product)+" • "+product.name
   if p.phase=="queue" and p.wait>([25,36,44][p.segment]+int(b.display)*3):lose(p,"Waited too long for "+product.name+". "+ready_recipe(p.shop,p.product))
  elif p.phase=="service":
   var active=b.services.filter(func(j):return j.id==p.get("booking",-1))
   if active.is_empty():p.phase="leave";p.bought=true;p.thought="Thank you!"
   else:
    var destination=station(p.shop,"entry")+Vector2(25,0) if b.trade=="daycare" else service_position(p.shop,int(active[0].slots[0]))
    move_actor(p,destination,70,dt)
  elif p.phase=="leave":
   if move_actor(p,station(p.shop,"entry")+Vector2(200,60),78,dt):p.fade-=dt*2
 people=people.filter(func(p):return p.fade>0 and p.age<150)
 for fx in effects:fx.life-=dt
 effects=effects.filter(func(f):return f.life>0)
 if effects.size()>30:effects=effects.slice(effects.size()-30)
 last_us=Time.get_ticks_usec()-begin;max_us=maxi(max_us,last_us)
func end_customers(id:String)->void:
 for p in people:
  if p.shop==id and p.phase!="leave":p.phase="leave"
func lose(p:Dictionary,reason:String)->void:
 if p.phase=="leave":return
 var b=business(p.shop)
 if not b.has("missed"):b.missed={}
 b.missed[p.product]=int(b.missed.get(p.product,0))+1
 b.lost+=1;b.reputation=clampf(b.reputation-.6,0,100);b.reason=reason;p.phase="leave";p.thought=reason;changed=true
