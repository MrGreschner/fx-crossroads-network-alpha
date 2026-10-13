extends RefCounted
## Separate account economy. Analytic offline integration; no background process/server required.
const FOUNDRY=preload("res://scripts/mine_foundry.gd")
const CATALOG=preload("res://scripts/idle_mine_catalog.gd")
const RESOURCES=["gold","ore","gems"]
const SERVICES=["vent","lift","depot","tools","smelter","assay","pump","drill"]
const BOOSTS={"rally":{"name":"Crew Rally","duration":60,"cooldown":300,"depth":2},"air":{"name":"Vent Flush","duration":120,"cooldown":600,"depth":3},"survey":{"name":"Gem Survey","duration":180,"cooldown":900,"depth":3}}
var legacy:Node
var time_for_test=-1.0
var tick=0.0
var view:CanvasLayer
var arrival:Dictionary={}
func now()->float:return time_for_test if time_for_test>=0 else Time.get_unix_time_from_system()
static func zeros()->Dictionary:return {"gold":0.0,"ore":0.0,"gems":0.0}
static func fresh(stamp:float)->Dictionary:
 return {"version":1,"commissioned":false,"wallet":{"gold":120.0,"ore":0.0,"gems":0.0},"stored":zeros(),"lifetime":zeros(),"since_visit":zeros(),"last":stamp,"visit":stamp,"shafts":[],"levels":{"vent":1,"lift":1,"depot":1,"tools":1,"smelter":0,"assay":0,"pump":0,"drill":0},"job":{},"refine":{},"active":{"rally":0.0,"air":0.0,"survey":0.0},"ready":{"rally":0.0,"air":0.0,"survey":0.0},"milestones":[],"refined":0.0}
func setup(owner:Node)->void:
 legacy=owner
 if not legacy.data.has("mine") or not valid(legacy.data.mine):legacy.data.mine=fresh(now())
 FOUNDRY.state(self)
 advance()
func state()->Dictionary:return legacy.data.mine
func readonly()->bool:return preload("res://scripts/profile_store.gd").testing() and not bool(legacy.data.get("teacher",false))
func step(delta:float)->void:
 tick+=delta
 if tick>=5:tick=0;advance()
func depth()->int:return state().shafts.size()
func workers()->int:
 var total=0
 for shaft in state().shafts:total+=int(shaft.crew)
 return total
func level()->int:return mini(50,1+int(sqrt(float(state().lifetime.ore)/200)))
func capacity()->float:return 3600*pow(1.7,int(state().levels.depot)-1)
func stored_units()->float:return float(state().stored.gold)+float(state().stored.ore)+float(state().stored.gems)*10
func rates(at:float=-1)->Dictionary:
 if at<0:at=now()
 var s=state();var result={"gold":0.0,"ore":0.0,"gems":0.0,"dig":0.0,"lift":0.0,"air":1.0,"air_supply":0.0,"air_demand":0.0,"flow":0.0}
 if not s.commissioned:return result
 var digging=0.0
 for shaft in s.shafts:digging+=int(shaft.crew)*.65*(1+.15*(int(shaft.depth)-1))
 digging*=1+.15*int(s.levels.tools);digging*=1+.06*int(s.levels.drill)
 if depth()>=4:digging*=1+.03*int(s.levels.pump)
 if float(s.active.rally)>at:digging*=2
 var supply=6+14*int(s.levels.vent)
 if float(s.active.air)>at:supply*=2
 var demand=workers()+depth()*1.5+int(s.levels.drill)*2
 var air=clampf(supply/maxf(demand,1),.2,1)
 var lift=2.2*pow(1.41,int(s.levels.lift)-1)
 var flow=minf(digging*air,lift)
 result.merge({"dig":digging,"lift":lift,"air":air,"air_supply":supply,"air_demand":demand,"flow":flow,"gold":flow*.45,"ore":flow*.75,"gems":flow*(.0015+.00035*depth())*(1+.2*int(s.levels.assay))*(2 if float(s.active.survey)>at else 1)},true)
 return result
func integrate(seconds:float,at:float)->void:
 if seconds<=0:return
 var rate=rates(at);var weight=float(rate.gold)+float(rate.ore)+float(rate.gems)*10
 if weight<=0:return
 var duration=minf(seconds,maxf(0,capacity()-stored_units())/weight)
 preload("res://scripts/mine_geology.gd").integrate(self,duration,float(rate.flow))
 FOUNDRY.integrate(self,duration,float(rate.flow))
 for key in RESOURCES:
  var amount=float(rate[key])*duration
  for bucket in [state().stored,state().lifetime,state().since_visit]:bucket[key]=minf(1e15,float(bucket[key])+amount)
func advance()->void:
 if legacy==null or readonly():return
 var s=state();var end=now();var start=float(s.last)
 if end<=start:return # A backward clock never earns extra production.
 var limit=minf(end,start+CATALOG.data().offline_hours*3600)
 # Only scheduled state changes are segmented; long absences never loop by frame/second.
 var cursor=start
 for iteration in 12:
  if cursor>=limit:break
  var boundary=limit
  for key in BOOSTS:
   if float(s.active[key])>cursor:boundary=minf(boundary,float(s.active[key]))
  for key in ["job","refine"]:
   if not s[key].is_empty() and float(s[key].end)>cursor:boundary=minf(boundary,float(s[key].end))
  finish_jobs(cursor);integrate(boundary-cursor,cursor);cursor=boundary;finish_jobs(cursor)
 s.last=end;finish_jobs(end)
func finish_jobs(at:float)->void:
 preload("res://scripts/mine_geology.gd").finish(self,at)
 FOUNDRY.finish(self,at)
 var s=state()
 if not s.job.is_empty() and float(s.job.end)<=at:
  if s.job.kind=="shaft":s.shafts.append({"depth":depth()+1,"crew":1})
  else:s.levels[s.job.service]=int(s.levels[s.job.service])+1
  s.job={};FOUNDRY.completed_build(self)
 if not s.refine.is_empty() and float(s.refine.end)<=at:
  s.wallet.gold=minf(1e15,float(s.wallet.gold)+float(s.refine.reward));s.refined=minf(1e15,float(s.refined)+float(s.refine.amount));s.refine={}
func afford(cost:Dictionary)->bool:
 for key in RESOURCES:
  if float(state().wallet[key])+1e-7<float(cost.get(key,0)):return false
 return true
func pay(cost:Dictionary)->void:
 for key in RESOURCES:state().wallet[key]=maxf(0,float(state().wallet[key])-float(cost.get(key,0)))
func changed()->void:legacy.save()
func commission()->bool:
 if readonly() or state().commissioned:return false
 advance();var cost={"gold":80}
 if not afford(cost):return false
 pay(cost);state().commissioned=true;state().shafts=[{"depth":1,"crew":1}];state().last=now();changed();return true
func collect()->bool:
 if readonly():return false
 advance()
 preload("res://scripts/mine_geology.gd").collect(self)
 FOUNDRY.collect(self)
 for key in RESOURCES:state().wallet[key]=minf(1e15,float(state().wallet[key])+float(state().stored[key]));state().stored[key]=0.0
 changed();return true
func hire_cost(index:int)->Dictionary:return {"gold":ceil(30*pow(1.38,int(state().shafts[index].crew)-1)*(1+.1*index))}
func hire(index:int)->bool:
 if readonly() or index<0 or index>=depth() or int(state().shafts[index].crew)>=CATALOG.data().max_crew:return false
 advance();var cost=hire_cost(index)
 if not afford(cost):return false
 pay(cost);state().shafts[index].crew=int(state().shafts[index].crew)+1;changed();return true
func upgrade_cost(id:String)->Dictionary:
 var spec:Dictionary=CATALOG.data().services[id];var lv=int(state().levels[id]);var scale=pow(1.46,maxi(0,lv-1))
 return {"gold":ceil(float(spec.gold)*scale),"ore":ceil(float(spec.ore)*scale),"gems":ceil(float(spec.gems)*scale)+maxi(0,lv-4)}
func material_cost(id:String="")->Dictionary:
 if id=="smelter" and int(state().levels.smelter)==0:return {} # A deep existing mine must be able to build its first furnace.
 return FOUNDRY.construction_cost(depth()+1 if id.is_empty() else depth(),0 if id.is_empty() else int(state().levels[id]))
func upgrade(id:String)->bool:
 if readonly() or id not in SERVICES:return false
 advance();var s=state();var spec:Dictionary=CATALOG.data().services[id]
 if not s.commissioned or not s.job.is_empty() or depth()<int(spec.depth) or int(s.levels[id])>=CATALOG.data().max_upgrade:return false
 var cost=upgrade_cost(id);var materials=material_cost(id)
 if not afford(cost) or not FOUNDRY.affordable(self,materials):return false
 FOUNDRY.reserve(self,materials)
 pay(cost);s.job={"kind":"upgrade","service":id,"end":now()+mini(600,int(spec.seconds)+int(s.levels[id])*8),"cost":cost};changed();return true
func next_shaft_cost()->Dictionary:
 var scale=pow(1.55,maxi(0,depth()-1))
 return {"gold":ceil(80*scale),"ore":ceil(50*scale),"gems":maxi(0,depth()-1)}
func next_requirement()->String:
 if depth()>=CATALOG.data().max_shafts:return "All twenty shafts are open. Keep improving your crews and buildings."
 var target=depth()+1
 var cleared=int(legacy.data.get("card",{}).get("descent_best",0))
 var required=5 if target<=10 else 10
 if target>=5 and not preload("res://scripts/realm_access.gd").unrestricted(legacy) and cleared<required:return "Clear Ram Descent floor %d to dig shafts %d–%d • best clear %d" % [required,5 if target<=10 else 11,10 if target<=10 else 20,cleared]
 if target>=5 and int(state().levels.smelter)==0:return "Needs Ramforge Smelter • forge bars for deeper construction"
 if level()<ceili(target/2.0):return "Needs Mine level "+str(ceili(target/2.0))+" • earn it through ore production"
 var vent=ceili(target/3.0);var pump=maxi(0,ceili((target-3)/4.0))
 if int(state().levels.vent)<vent:return "Needs Ventilation House level "+str(vent)
 if int(state().levels.pump)<pump:return "Needs Drainage Station level "+str(pump)
 return ""
func excavate()->bool:
 if readonly():return false
 advance();var s=state()
 if not s.commissioned or not s.job.is_empty() or depth()>=CATALOG.data().max_shafts or not next_requirement().is_empty():return false
 var cost=next_shaft_cost();var materials=material_cost()
 if not afford(cost) or not FOUNDRY.affordable(self,materials):return false
 FOUNDRY.reserve(self,materials)
 pay(cost);s.job={"kind":"shaft","service":"","end":now()+minf(1800,60*pow(1.25,depth()-1)),"cost":cost};changed();return true
func cancel_build()->void:
 if readonly():return
 advance();var s=state()
 if s.job.is_empty():return
 for key in RESOURCES:s.wallet[key]=minf(1e15,float(s.wallet[key])+float(s.job.cost.get(key,0)))
 s.job={};FOUNDRY.refund_build(self);changed()
func boost(id:String)->bool:
 if readonly() or id not in BOOSTS:return false
 advance();var s=state();var spec:Dictionary=BOOSTS[id]
 if depth()<int(spec.depth) or float(s.ready[id])>now() or id=="survey" and int(s.levels.assay)==0:return false
 s.active[id]=now()+int(spec.duration);s.ready[id]=now()+int(spec.cooldown);changed();return true
func refine()->bool:
 if readonly():return false
 advance();var s=state();var lv=int(s.levels.smelter)
 if lv<1 or not s.refine.is_empty() or not FOUNDRY.state(self).job.is_empty():return false
 var amount=30.0*lv
 if float(s.wallet.ore)<amount:return false
 s.wallet.ore-=amount;s.refine={"end":now()+30,"amount":amount,"reward":amount*(.6+.015*lv)};changed();return true
func recommendation()->String:
 var r=rates()
 if not state().commissioned:return "Commission the starter camp, then hire a second ram digger."
 if stored_units()/capacity()>.85:return "Collect your depot. Upgrade it if you want longer idle stretches."
 if float(r.air)<.95:return "Air supply is holding the mine back. Improve ventilation or use Vent Flush."
 if float(r.lift)<float(r.dig)*float(r.air):return "The lift is the bottleneck. More diggers will not increase surface output yet."
 if not state().job.is_empty():return "Construction is running. Collect metals, forge bars or deliver reinforcements to shorten this build."
 if not next_requirement().is_empty():return next_requirement()+" before digging deeper."
 return "Hire more diggers or excavate a deeper seam. Watch transport and air as your mine grows."
func milestones()->Array:
 return [
  {"id":"crew","name":"A proper crew","need":workers(),"target":3,"reward":{"gold":25,"ore":15}},
  {"id":"depth2","name":"Below the roots","need":depth(),"target":2,"reward":{"gold":60,"ore":30}},
  {"id":"depot","name":"Room to grow","need":int(state().levels.depot),"target":3,"reward":{"gold":100,"gems":2}},
  {"id":"refine","name":"First furnace order","need":float(state().refined),"target":30,"reward":{"gold":80,"ore":40}},
  {"id":"gems","name":"Crystal finder","need":float(state().lifetime.gems),"target":10,"reward":{"gold":150,"gems":4}},
  {"id":"depth5","name":"Deepwell foreman","need":depth(),"target":5,"reward":{"gold":400,"ore":250}},
  {"id":"crew20","name":"Busy galleries","need":workers(),"target":20,"reward":{"gold":600,"gems":8}},
  {"id":"depth10","name":"Sapphire pioneer","need":depth(),"target":10,"reward":{"gold":1500,"ore":1000,"gems":15}},
  {"id":"ore","name":"Ore entrepreneur","need":float(state().lifetime.ore),"target":100000,"reward":{"gold":3000,"gems":25}},
  {"id":"depth15","name":"Emberstone explorer","need":depth(),"target":15,"reward":{"gold":7000,"ore":5000,"gems":40}},
  {"id":"crew100","name":"A ram-run industry","need":workers(),"target":100,"reward":{"gold":12000,"gems":60}},
  {"id":"depth20","name":"Master of Deepwell","need":depth(),"target":20,"reward":{"gold":25000,"ore":15000,"gems":100}}]
func claim(id:String)->bool:
 if readonly() or id in state().milestones:return false
 advance()
 for item in milestones():
  if item.id==id and float(item.need)>=float(item.target):
   state().milestones.append(id)
   for key in RESOURCES:state().wallet[key]=minf(1e15,float(state().wallet[key])+float(item.reward.get(key,0)))
   changed();return true
 return false
func visit()->Dictionary:
 advance();arrival={"seconds":maxf(0,now()-float(state().visit)),"resources":state().since_visit.duplicate(true)}
 if not readonly():state().since_visit=zeros();state().visit=now();changed()
 return arrival
func open()->void:
 if legacy.arcade or legacy.game.mode!="town":return
 legacy.close();visit()
 if not is_instance_valid(view):view=preload("res://scripts/idle_mine_view.gd").new();legacy.game.add_child(view);view.setup(self)
 view.open()
func preview()->void:
 legacy.data.mine=fresh(now());var s=state();s.commissioned=true
 for n in CATALOG.data().max_shafts:s.shafts.append({"depth":n+1,"crew":12})
 for id in SERVICES:s.levels[id]=25
 var foundry=FOUNDRY.state(self)
 for id in FOUNDRY.METALS:foundry.wallet[id]=1000.0;foundry.bars[id]=100.0
 preload("res://scripts/mine_geology.gd").state(self).wallet.coal=1000.0
 s.lifetime.ore=500000.0
 s.wallet={"gold":1000000.0,"ore":1000000.0,"gems":10000.0}
static func numeric(value:Variant,lo:float,hi:float,integer:bool=false)->bool:
 return (value is int or value is float) and is_finite(float(value)) and float(value)>=lo and float(value)<=hi and (not integer or float(value)==floor(float(value)))
static func resources(value:Variant)->bool:
 if not value is Dictionary or value.size()!=3:return false
 for key in RESOURCES:if not numeric(value.get(key),0,1e15):return false
 return true
static func valid(value:Variant)->bool:
 if value is Dictionary and value.has("foundry"):
  if not FOUNDRY.valid(value.foundry):return false
  if not value.get("job") is Dictionary or not value.get("refine") is Dictionary:return false
  if value.get("job",{}).is_empty() and (not value.foundry.reserved.is_empty() or value.foundry.reinforced):return false
  if not value.foundry.job.is_empty() and not value.get("refine",{}).is_empty():return false
  value=value.duplicate(true);value.erase("foundry")
 if value is Dictionary and value.has("geology"):
  if not preload("res://scripts/mine_geology.gd").valid(value.geology):return false
  value=value.duplicate(true);value.erase("geology")
 if not value is Dictionary or value.get("version")!=1 or not value.get("commissioned") is bool:return false
 var keys=["version","commissioned","wallet","stored","lifetime","since_visit","last","visit","shafts","levels","job","refine","active","ready","milestones","refined"]
 if value.size()!=keys.size():return false
 for key in value:if key not in keys:return false
 for key in ["wallet","stored","lifetime","since_visit"]:if not resources(value.get(key)):return false
 for key in ["last","visit"]:if not numeric(value.get(key),0,4102444800):return false
 if not numeric(value.get("refined"),0,1e15):return false
 if not value.get("shafts") is Array or value.shafts.size()>20 or value.commissioned!=(not value.shafts.is_empty()):return false
 for n in value.shafts.size():
  var shaft:Variant=value.shafts[n]
  if not shaft is Dictionary or shaft.size()!=2 or shaft.get("depth")!=n+1 or not numeric(shaft.get("crew"),1,12,true):return false
 if not value.get("levels") is Dictionary or value.levels.size()!=SERVICES.size():return false
 for id in SERVICES:if not numeric(value.levels.get(id),1 if id in ["vent","lift","depot","tools"] else 0,25,true):return false
 for key in ["active","ready"]:
  if not value.get(key) is Dictionary or value[key].size()!=3:return false
  for id in BOOSTS:if not numeric(value[key].get(id),0,4102444800):return false
 if not value.get("milestones") is Array or value.milestones.size()>12:return false
 var ids=["crew","depth2","depot","refine","gems","depth5","crew20","depth10","ore","depth15","crew100","depth20"]
 for id in value.milestones:if not id is String or id not in ids:return false
 if not value.get("job") is Dictionary or not value.get("refine") is Dictionary:return false
 if not value.job.is_empty():
  var job:Dictionary=value.job
  if job.size()!=4 or job.get("kind") not in ["shaft","upgrade"] or not numeric(job.get("end"),0,4102444800) or not job.get("cost") is Dictionary:return false
  if job.get("kind")=="upgrade" and job.get("service") not in SERVICES:return false
  if job.get("kind")=="shaft" and (job.get("service")!="" or value.shafts.size()>=20):return false
  if job.get("kind")=="upgrade" and int(value.levels.get(job.get("service"),25))>=25:return false
  if not value.commissioned:return false
  if job.cost.size()!=3:return false
  for id in RESOURCES:if not numeric(job.cost.get(id),0,1e15):return false
 if not value.refine.is_empty():
  var order:Dictionary=value.refine
  if order.size()!=3 or not numeric(order.get("end"),0,4102444800) or not numeric(order.get("amount"),1,750) or not numeric(order.get("reward"),0,1000):return false
 return true
