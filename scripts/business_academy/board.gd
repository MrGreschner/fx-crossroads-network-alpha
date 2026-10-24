extends Control
const A=preload("res://scripts/business_district/art.gd")
const C=preload("res://scripts/business_district/catalog.gd")
var tool="opportunity"
var models:Dictionary={}
var clock=0.0
func _ready()->void:
 custom_minimum_size=Vector2(280,300);mouse_filter=Control.MOUSE_FILTER_IGNORE
func set_data(kind:String,value:Dictionary)->void:tool=kind;models=value;queue_redraw()
static func defaults(kind:String)->Dictionary:
 match kind:
  "finance":return {"funding":0,"principal":600.0,"rate":12.0,"months":12,"price":20.0,"unit_cost":8.0,"fixed":120.0,"units":20,"start":200.0,"delay":0,"share":25.0}
  "distribution":return {"channel":1,"transport":0,"distance":500.0,"product":0}
  "marketing":return {"target":0,"channel":0,"budget":10.0,"price":19.0,"layout":0}
  "operations":return {"structure":0,"incident":0,"response":0,"hours":8.0,"wage":15.0,"employees":2}
  "expansion":return {"strategy":0,"investment":300.0,"sales":600.0,"costs":420.0}
  "service":return {"customer":0,"response":0,"quantity":2,"price":19.0}
  "agriculture":return {"system":0,"supply":60.0,"demand":50.0,"quota":40.0}
  "planning":return {"likelihood":2,"impact":3,"response":0,"milestone":0}
  _:return {"choice":0}
static func finance(m:Dictionary)->Dictionary:
 var d=defaults("finance");d.merge(m,true)
 var principal=float(d.principal);var r=float(d.rate)/1200;var months=maxi(1,int(d.months));var payment=principal/months if is_zero_approx(r) else principal*r/(1-pow(1+r,-months))
 var contribution=float(d.price)-float(d.unit_cost);var break_even=float(d.fixed)/contribution if contribution>0 else -1.0
 var cash=float(d.start)+(principal if d.funding in [0,1] else 0);var points=[]
 for month in 6:
  var receipts=float(d.price)*float(d.units) if month>0 or d.delay==0 else 0.0
  var cost=float(d.fixed)+float(d.unit_cost)*float(d.units)+(payment if d.funding==0 and month<months else 0.0)
  cash+=receipts-cost;points.append(snappedf(cash,.01))
 return {"cash":points,"payment":payment if d.funding==0 else 0.0,"break_even":break_even,"profit":contribution*float(d.units)-float(d.fixed),"control":100-float(d.share) if d.funding==1 else 100.0}
func text_at(p:Vector2,t:String,size:int=17,color:Color=Color("#f0e4c4"))->void:A.ink(self,p,t,size,color)
func card(p:Vector2,size:Vector2,color:Color=Color("#315158"))->void:A.rounded(self,Rect2(p,size),color,9)
func line(a:Vector2,b:Vector2)->void:
 draw_line(a,b,Color("#b6c6ad"),3,true);var v=(a-b).normalized();draw_line(b,b+v.rotated(.5)*10,Color("#b6c6ad"),3,true);draw_line(b,b+v.rotated(-.5)*10,Color("#b6c6ad"),3,true)
func person(p:Vector2,i:int,caption:String)->void:A.person(self,p,i,0,1.1);text_at(p+Vector2(-43,21),caption,13)
func _draw()->void:
 var scale_factor=minf(size.x/860.0,size.y/300.0);draw_set_transform(Vector2((size.x-860*scale_factor)*.5,0),0,Vector2.ONE*scale_factor)
 A.rounded(self,Rect2(0,0,860,300),Color("#19383e"),12)
 var m=defaults(tool);m.merge(models.get(tool,{}),true)
 match tool:
  "finance":
   var f=finance(m);text_at(Vector2(25,31),"THE FUNDING DESK  •  SIX-MONTH CASH VIEW",18)
   var min_cash=minf(0,float(f.cash.min()));var max_cash=maxf(100,float(f.cash.max()));var span=maxf(1,max_cash-min_cash)
   draw_line(Vector2(44,226),Vector2(590,226),Color("#809f99"),1)
   var points=PackedVector2Array()
   for i in 6:
    var x=65+i*96;var y=220-(float(f.cash[i])-min_cash)/span*150;points.append(Vector2(x,y));draw_circle(Vector2(x,y),5,Color("#efcf86"));text_at(Vector2(x-23,253),"M"+str(i+1),14);text_at(Vector2(x-30,y-13),"%.0f" % f.cash[i],14)
   draw_polyline(points,Color("#e6c780"),3,true);card(Vector2(631,58),Vector2(207,194))
   text_at(Vector2(648,87),["Loan","Equity","Own savings"][int(m.funding)],20);text_at(Vector2(648,119),"Payment %.2f" % f.payment,16);text_at(Vector2(648,149),"Owner control %.0f%%" % f.control,15);text_at(Vector2(648,180),"Break-even "+("none" if f.break_even<0 else "%.1f units" % f.break_even),15);text_at(Vector2(648,213),"Operating profit %.0f" % f.profit,14)
   text_at(Vector2(25,283),"Teaching figures • repayments affect cash; loan proceeds are not revenue",14)
  "distribution":
   text_at(Vector2(25,32),"FROM MAKER TO CUSTOMER",20);var names=["Maker","Wholesaler","Retailer","Customer"]
   var xs=[90,300,510,740];var used=[0,3] if m.channel==0 else [0,2,3] if m.channel==1 else [0,1,2,3]
   for i in used.size():
    var idx=used[i];var p=Vector2(xs[idx],160)
    if i>0:line(Vector2(xs[used[i-1]]+43,155),p-Vector2(45,5))
    card(p-Vector2(48,49),Vector2(96,89));A.goods(self,p-Vector2(20,6),"artisan" if idx==0 else "courier",3,1.2);text_at(p+Vector2(-45,66),names[idx],15)
   var unit_cost=[.08,.04,.02,.22][int(m.transport)]*float(m.distance)+[10,35,40,50][int(m.transport)]+int(m.channel)*12
   var hours=float(m.distance)/[60,80,25,550][int(m.transport)]+int(m.channel)*2
   text_at(Vector2(25,80),["Road","Rail","Water","Air"][int(m.transport)]+" • %.0f km • model shipment cost %.2f • %.1f hours" % [m.distance,unit_cost,hours],17);text_at(Vector2(25,277),"Channel roles and transport mode are different decisions. These are fictional rates.",14)
  "operations":
   text_at(Vector2(25,31),"PEOPLE, RESPONSIBILITY & COMMUNICATION",19);card(Vector2(333,48),Vector2(186,46));text_at(Vector2(361,77),"Venture manager",17)
   for i in 3:
    var p=Vector2(165+i*265,191);line(Vector2(426,98),p-Vector2(0,56));card(p-Vector2(97,69),Vector2(194,137));person(p,i,["Preparation","Service","Receiving"][i])
   text_at(Vector2(25,251),"Fictional gross payroll: %.0f people × %.1f hours × %.2f = %.2f" % [m.employees,m.hours,m.wage,m.employees*m.hours*m.wage],15)
   text_at(Vector2(25,281),["Functional responsibility","Geographical branches","Matrix / shared project team"][int(m.structure)]+" • illustrative structure; annotate the real roles in your evidence",14)
  "marketing":
   text_at(Vector2(25,32),"MATCH THE OFFER TO THE CUSTOMER",20)
   for i in 3:person(Vector2(120+i*170,157),[4,2,5][i],["Traveller","Resident","Collector"][i]);draw_arc(Vector2(120+i*170,126),53,0,TAU,32,Color("#edce86") if i==int(m.target) else Color("#54756f"),3,true)
   card(Vector2(590,60),Vector2(238,190),Color("#5d6d55"));text_at(Vector2(610,91),["Market poster","Local message","Personal service"][int(m.channel)],18);A.goods(self,Vector2(644,141),"tailor",3,1.8);text_at(Vector2(610,204),"Price %.1f • budget %.0f" % [m.price,m.budget],17)
   text_at(Vector2(25,251),"Product + price + place + promotion • choose a coherent offer",17);text_at(Vector2(25,277),"Channels form your plan; the district models promotion as aggregate walk-in interest.",13)
  "expansion":
   text_at(Vector2(25,32),"THE NEXT BRANCH — OR STAY THE SAME SIZE",19)
   var positions=[Vector2(180,163),Vector2(430,120),Vector2(680,182)]
   for i in 3:
    if i>0:line(positions[i-1]+Vector2(40,0),positions[i]-Vector2(50,0))
    var p=positions[i];card(p-Vector2(70,54),Vector2(140,105),Color("#4c7465") if i<=int(m.strategy) else Color("#3b4c4e"));A.goods(self,p-Vector2(32,0),["grower","cook","rental"][i],4,1.3);text_at(p+Vector2(-56,76),["Current stall","Processing","New service"][i],14)
   text_at(Vector2(25,277),"Investment %.0f • forecast sales %.0f − costs %.0f = %.0f" % [m.investment,m.sales,m.costs,m.sales-m.costs],17)
  "service":
   text_at(Vector2(25,32),"EVERY CUSTOMER MATTERS",20);person(Vector2(180,183),2,"Customer");person(Vector2(430,183),6,"Service");line(Vector2(235,134),Vector2(373,134));card(Vector2(570,63),Vector2(251,183),Color("#e4d5ad"));text_at(Vector2(591,95),"SALES RECEIPT",18,Color("#304b4d"));text_at(Vector2(591,139),"%d × %.2f" % [m.quantity,m.price],18,Color("#304b4d"));text_at(Vector2(591,182),"TOTAL %.2f" % (m.quantity*m.price),22,Color("#304b4d"));text_at(Vector2(25,270),["Listen and clarify","Check receipt and policy","Explain options and record"][int(m.response)],18)
  "agriculture":
   text_at(Vector2(25,32),"HARVEST TO MARKET  •  FICTIONAL TEACHING MODEL",18)
   for i in 12:A.goods(self,Vector2(70+(i%6)*48,104+(i/6)*61),"grower",1,2.0)
   var available=minf(m.supply,m.quota) if m.system==1 else float(m.supply);var price=clampf(10*float(m.demand)/maxf(1,available),1,30)
   card(Vector2(432,67),Vector2(382,164));text_at(Vector2(452,100),"Quota-limited case" if m.system==1 else "Open-market case",20);text_at(Vector2(452,139),"Available %.0f • demand %.0f" % [available,m.demand],18);text_at(Vector2(452,181),"Model price %.2f" % price,22);text_at(Vector2(25,278),"Compare stakeholders; research real systems instead of treating this as current law.",14)
  "planning":
   text_at(Vector2(25,32),"A PLAN THAT CAN CHANGE",20)
   for i in 4:
    var p=Vector2(116+i*207,119);card(p-Vector2(83,32),Vector2(166,68),Color("#6c7b59") if i==int(m.milestone) else Color("#34535a"));text_at(p-Vector2(64,-8),["Goal","Resources","Opening","Review"][i],18)
    if i<3:line(p+Vector2(85,0),p+Vector2(121,0))
   text_at(Vector2(25,228),"Risk likelihood %d × impact %d = priority %d" % [m.likelihood,m.impact,m.likelihood*m.impact],19);text_at(Vector2(25,273),"A priority score is a discussion aid. Explain prevention, contingency and responsibility.",14)
  _:
   text_at(Vector2(25,32),"NEEDS → ALTERNATIVES → A JUSTIFIED CHOICE",19)
   for i in 3:
    var p=Vector2(150+i*280,147);card(p-Vector2(121,79),Vector2(242,172),Color("#476b60") if i==int(m.choice) else Color("#2d4c54"));A.goods(self,p-Vector2(27,18),["cook","artisan","rental"][i],3,1.7);text_at(p+Vector2(-95,35),["Quick meals","Useful repairs","Equipment hire"][i],17);text_at(p+Vector2(-95,66),"Inspect before choosing",16)
   text_at(Vector2(25,277),"Inspect customer needs, compare resources and confirm a reasoned plan.",14)
