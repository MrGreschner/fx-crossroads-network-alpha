extends RefCounted
## Bounded classroom sandboxes. No real mine inventory, money or profile rewards.
const FORMAT="fx-business-exercise"
const MODULES=["ENT1010","ENT1020","MAM1010"]
const TITLES={"ENT1010":"Opportunity Board","ENT1020":"Venture Pilot","MAM1010":"Merchandising A/B Lab"}
const FACTORS=["Price","Packaging","Service","Place","Promotion"]
const P=preload("res://scripts/workshop_project.gd")
static func fresh(code:String)->Dictionary:
 var settings={}
 match code:
  "ENT1010":settings={"ideas":[{"name":"Repair tools","need":4,"resources":3,"feasibility":4},{"name":"Gem gifts","need":3,"resources":4,"feasibility":3},{"name":"Ore delivery","need":5,"resources":2,"feasibility":2}],"weights":[4,3,2]}
  "ENT1020":settings={"cash":500,"fixed":60,"cost":5,"price":12,"stock":40,"demand":30,"reserve":80,"scenario":0}
  "MAM1010":settings={"visitors":100,"stock":60,"cost":5,"price":12,"budget":20,"factor":0,"a":12,"b":10}
 return {"format":FORMAT,"version":1,"module":code,"settings":settings,"reflection":"","results":{}}
static func n(v:Variant,lo:float,hi:float)->bool:return P.number(v,lo,hi)
static func whole(v:Variant,lo:float,hi:float)->bool:return n(v,lo,hi) and float(v)==floorf(float(v))
static func valid_settings(code:String,s:Variant)->bool:
 if not s is Dictionary:return false
 match code:
  "ENT1010":
   if not s.get("ideas") is Array or s.ideas.size()!=3 or not s.get("weights") is Array or s.weights.size()!=3:return false
   for weight in s.weights:if not whole(weight,1,5):return false
   for idea in s.ideas:
    if not idea is Dictionary or not idea.get("name") is String or idea.name.strip_edges().is_empty() or idea.name.length()>80:return false
    for key in ["need","resources","feasibility"]:if not whole(idea.get(key),0,5):return false
   return true
  "ENT1020":
   for key in ["cash","fixed","reserve"]:if not n(s.get(key),0,10000):return false
   for key in ["cost","price"]:if not n(s.get(key),1,200):return false
   for key in ["stock","demand"]:if not whole(s.get(key),0,500):return false
   return whole(s.get("scenario"),0,2)
  "MAM1010":
   if not whole(s.get("visitors"),10,500) or not whole(s.get("stock"),0,500) or not n(s.get("cost"),1,200) or not n(s.get("price"),1,200) or not n(s.get("budget"),0,500) or not whole(s.get("factor"),0,4):return false
   return n(s.get("a"),1,200) and n(s.get("b"),1,200) if int(s.factor)==0 else whole(s.get("a"),0,3) and whole(s.get("b"),0,3)
 return false
static func solve(code:String,s:Dictionary)->Dictionary:
 if not valid_settings(code,s):return {}
 match code:
  "ENT1010":
   var scores=[];var best=-1;var greatest=-1.0;var ties=[]
   for i in 3:
    var idea:Dictionary=s.ideas[i];var score=float(idea.need*s.weights[0]+idea.resources*s.weights[1]+idea.feasibility*s.weights[2]);scores.append(score)
    if score>greatest:greatest=score;best=i;ties=[i]
    elif score==greatest:ties.append(i)
   return {"scores":scores,"best":best,"ties":ties,"maximum":5*(s.weights[0]+s.weights[1]+s.weights[2])}
  "ENT1020":
   var cost=float(s.cost)*(1.35 if int(s.scenario)==1 else 1.0);var demand=int(s.demand*.6) if int(s.scenario)==2 else int(s.demand)
   var available=maxf(0,float(s.cash)-float(s.fixed)-float(s.reserve));var affordable=int(floorf(available/cost));var stocked=mini(int(s.stock),affordable);var sold=mini(stocked,demand)
   var revenue=sold*float(s.price);var operating=float(s.fixed)+sold*cost;var profit=revenue-operating;var cash_end=float(s.cash)-float(s.fixed)-stocked*cost+revenue;var margin=float(s.price)-cost
   return {"unit_cost":cost,"stocked":stocked,"sold":sold,"revenue":revenue,"operating_cost":operating,"profit":profit,"ending_cash":cash_end,"unsold":stocked-sold,"inventory_value":(stocked-sold)*cost,"break_even":int(ceilf(float(s.fixed)/margin)) if margin>0 else -1,"reserve_met":cash_end>=float(s.reserve),"funded":float(s.cash)>=float(s.fixed)+float(s.reserve)}
  "MAM1010":return {"a":campaign(s,float(s.a)),"b":campaign(s,float(s.b)),"factor":FACTORS[int(s.factor)]}
 return {}
static func campaign(s:Dictionary,choice:float)->Dictionary:
 var price=float(s.price);var rate=.22;var extra=0.0;var reach=float(s.visitors)+float(s.budget)*.4
 match int(s.factor):
  0:price=choice
  1:rate+=choice*.035;extra=choice*.5
  2:rate+=choice*.025;extra=choice*.7
  3:reach*=1+choice*.16;extra=choice*.35
  4:reach+=choice*12;extra=choice*.45
 rate=clampf(rate*(12/maxf(1,price)),.02,.8)
 var wanted=int(floorf(reach*rate));var sold=mini(int(s.stock),wanted);var revenue=sold*price;var costs=sold*(float(s.cost)+extra)+float(s.budget)
 return {"visitors":int(reach),"conversion":rate,"demand":wanted,"sold":sold,"price":price,"unit_extra":extra,"revenue":revenue,"costs":costs,"profit":revenue-costs,"stock_limited":wanted>int(s.stock)}
static func valid(v:Variant)->bool:
 if not v is Dictionary or v.get("format")!=FORMAT or v.get("version")!=1 or not v.get("module") in MODULES or not v.get("reflection") is String or v.reflection.length()>3000 or not v.get("results") is Dictionary or JSON.stringify(v).length()>12000:return false
 if not valid_settings(v.module,v.get("settings")):return false
 # Imported reports must match their saved decisions; do not trust a fabricated profit.
 return v.results.is_empty() or preload("res://scripts/learning_store.gd").fingerprint(v.results)==preload("res://scripts/learning_store.gd").fingerprint(solve(v.module,v.settings))
static func run(v:Dictionary)->void:v.results=solve(v.module,v.settings)
static func summary(v:Dictionary)->String:
 var r=solve(v.module,v.settings)
 if r.is_empty():return "Invalid exercise."
 match v.module:
  "ENT1010":return "Weighted scores: "+str(r.scores)+" / "+str(r.maximum)+" • recommended: "+str(v.settings.ideas[int(r.best)].name)+(" • tied scores: justify your choice" if r.ties.size()>1 else "")
  "ENT1020":return "Sold %d / stocked %d • revenue %.2f • operating profit %.2f\nEnding cash %.2f • unsold inventory %.2f • break-even %s units\nCash includes the cost of buying UNSOLD stock; profit includes only sold stock cost." % [r.sold,r.stocked,r.revenue,r.profit,r.ending_cash,r.inventory_value,str(r.break_even) if r.break_even>=0 else "unreachable"]
  "MAM1010":return "Same audience, stock and budget • only "+r.factor+" changes\nA: sold %d • revenue %.2f • profit %.2f\nB: sold %d • revenue %.2f • profit %.2f" % [r.a.sold,r.a.revenue,r.a.profit,r.b.sold,r.b.revenue,r.b.profit]
 return ""
