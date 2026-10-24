extends RefCounted
static var data:Dictionary={}
static func all()->Dictionary:
 if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://content/business-district.json"))
 return data
static func ventures()->Array:return all().ventures
static func staff()->Array:return current_pool if not current_pool.is_empty() else all().staff
static func spec(id:String)->Dictionary:
 for v in ventures()+all().get("legacy_ventures",[]):
  if v.id==id:return v
 return {}
static func plot(id:String)->Vector2:
 var p=spec(id).plot;return Vector2(p[0],p[1])
static func fresh_business(id:String)->Dictionary:
 var v=spec(id)
 return {"hires":[],"name":v.name,"cash":300.0,"inputs":0,"input_book":0.0,"stock":0,"stock_book":0.0,"price":float(v.price),"quality":0,"equipment":0,"display":0,"cold":0,"brand":0,"layout":0,"route":0,"open":false,"elapsed":0.0,"day":0,"reputation":55.0,"employees":[],"history":[],"decisions":[],"delivery":{},"delivery_due":0.0,"produce":0.0,"served":0,"lost":0,"revenue":0.0,"cogs":0.0,"wait_total":0.0,"expenses":0.0,"opening_cash":300.0,"opening_inventory":0.0,"ad":0.0,"training":0,"loan":0.0,"last_result":{},"reason":"Ready to prepare your first opening.","ledger":[],"note":""}
static func fresh()->Dictionary:return {"version":1,"reserve":0.0,"selected":"kitchen","businesses":{},"night":false,"visitors":0,"periods":0}
static func number(v:Variant,lo:float,hi:float)->bool:return (v is int or v is float) and is_finite(float(v)) and float(v)>=lo and float(v)<=hi
static func whole(v:Variant,lo:int,hi:int)->bool:return number(v,lo,hi) and float(v)==floorf(float(v))
static func valid_business(id:String,b:Variant)->bool:
 if not b is Dictionary or spec(id).is_empty():return false
 var required=fresh_business(id)
 for key in required:
  if not b.has(key):return false
 for k in ["name","reason","note"]:
  if not b[k] is String or b[k].length()>1000:return false
 if not b.open is bool:return false
 if not b.hires is Array or b.hires.size()>8:return false
 for time in b.hires:
  if not number(time,0,60):return false
 for k in ["cash","input_book","stock_book","revenue","cogs","wait_total","expenses","opening_cash","opening_inventory","ad","loan"]:
  if not number(b[k],-1000000 if k=="cash" or k=="opening_cash" else 0,100000000):return false
 if not number(b.price,1,float(spec(id).price)*3) or not number(b.reputation,0,100):return false
 for k in ["inputs","stock"]:
  if not whole(b[k],0,10000):return false
 for k in ["quality","equipment","display","cold","brand","layout","route","training"]:
  if not whole(b[k],0,3 if k!="layout" and k!="route" else 2):return false
 for k in ["day","served","lost"]:
  if not whole(b[k],0,1000000):return false
 for k in ["elapsed","delivery_due","produce"]:
  if not number(b[k],0,1000000):return false
 if not b.employees is Array or b.employees.size()>6:return false
 var unique=[]
 for e in b.employees:
  if not e is Dictionary or not e.get("id") is int and not e.get("id") is float or not whole(e.id,0,1000000) or e.id in unique or not e.get("role") in ["craft","serve","stock"]:return false
  unique.append(e.id)
 for k in ["history","decisions","ledger"]:
  if not b[k] is Array or b[k].size()>{"history":24,"decisions":60,"ledger":100}[k]:return false
  for entry in b[k]:
   if not entry is Dictionary or JSON.stringify(entry).length()>12000:return false
 for h in b.history:
  if not valid_report(h):return false
 for entry in b.decisions:
  if not whole(entry.get("day"),1,1000001) or not number(entry.get("time"),0,1000000) or not entry.get("action") is String or not entry.get("detail") is String:return false
 for entry in b.ledger:
  if not whole(entry.get("day"),1,1000001) or not number(entry.get("amount"),-100000000,100000000) or not number(entry.get("balance"),-100000000,100000000) or not entry.get("kind") is String or not entry.get("detail") is String:return false
 if not b.delivery is Dictionary or not b.last_result is Dictionary:return false
 if not b.delivery.is_empty():
  if not whole(b.delivery.get("units"),1,100) or not number(b.delivery.get("cost"),0,100000):return false
 if not b.last_result.is_empty() and not valid_report(b.last_result):return false
 return JSON.stringify(b).length()<150000 and valid_operations(b)
static func valid(s:Variant)->bool:
 if not s is Dictionary or s.get("version")!=1 or not number(s.get("reserve"),0,100000000) or not s.get("selected") is String or spec(s.selected).is_empty() or not s.get("night") is bool:return false
 if not s.get("businesses") is Dictionary or s.businesses.size()>ventures().size()+all().get("legacy_ventures",[]).size():return false
 var assigned=[]
 for k in s.businesses:
  if not k is String or not valid_business(k,s.businesses[k]):return false
  for e in s.businesses[k].employees:
   if e.id in assigned:return false
   assigned.append(e.id)
 for k in ["visitors","periods"]:
  if not whole(s.get(k),0,100000000):return false
 return JSON.stringify(s).to_utf8_buffer().size()<2000000

static func valid_report(h:Variant)->bool:
 if not h is Dictionary:return false
 for key in ["day","sold","lost","spoilage","layout","equipment","quality"]:
  if not whole(h.get(key),0,1000001):return false
 for key in ["seconds","revenue","cogs","expenses","profit","cash","inventory","loan","wages","wait","price","campaign"]:
  if not number(h.get(key),-100000000 if key in ["cash","profit"] else 0,100000000):return false
 if not h.get("employees") is Array or h.employees.size()>6:return false
 for e in h.employees:
  if not e is Dictionary or not whole(e.get("id"),0,1000000) or e.get("role") not in ["craft","serve","stock"]:return false
 return true

static var operations:Dictionary={}
static var profiles:Dictionary={}
static var current_pool:Array=[]
static func ops()->Dictionary:
 if operations.is_empty():operations=JSON.parse_string(FileAccess.get_file_as_string("res://content/business-operations.json"))
 return operations
static func person(id:int)->Dictionary:
 if profiles.has(str(id)):return profiles[str(id)]
 var old=all().staff
 return old[posmod(id,old.size())]
static func trade(id:String,b:Dictionary)->String:return str(b.get("trade","kitchen" if spec(id).get("blank",false) else id))
static func menu(trade_id:String)->Array:
 return ops().products.values().filter(func(p):return p.trade==trade_id)
static func unit_cost(product_id:String)->float:
 var p=ops().products[product_id];var total=0.0
 for m in p.materials:total+=ops().materials[m].cost*p.materials[m]
 return total
static func ensure_business(id:String,b:Dictionary)->void:
 if b.has("operations"):return
 var v=spec(id);var t=trade(id,b);var model=spec(t);var menu_items=model.starter_products
 b.operations=2;b.trade=t;b.menu={};b.materials={};b.finished={};b.assets={};b.orders=[];b.failed=false;b.arrears=0;b.production_key="";b.owner_role="craft";b.observations={};b.acquisition=0.0
 for eq in model.base_equipment:b.assets[eq]={"condition":1.0,"paid":float(ops().equipment[eq].cost),"count":1}
 for p in menu_items:b.menu[p]={"enabled":true,"price":float(ops().products[p].price),"target":8}
 if not menu_items.is_empty():
  var first=menu_items[0];var recipe=ops().products[first];var total=maxf(.01,unit_cost(first))
  for material in recipe.materials:
   var share=ops().materials[material].cost*recipe.materials[material]/total
   if b.inputs>0:b.materials[material]=[{"qty":int(b.inputs)*int(recipe.materials[material]),"cost":float(b.input_book)*share,"age":0,"quality":1.0}]
  if b.stock>0:b.finished[first]=[{"qty":int(b.stock),"cost":float(b.stock_book),"age":0,"quality":1.0}]
 # Convert a legacy pending generic shipment exactly once, without charging it again.
 if not b.delivery.is_empty() and not menu_items.is_empty():
  var recipe=ops().products[menu_items[0]];var line_cost=float(b.delivery.cost)/recipe.materials.size()
  for material in recipe.materials:b.orders.append({"material":material,"qty":int(b.delivery.units)*int(recipe.materials[material]),"cost":line_cost,"due":float(b.delivery_due),"quality":1.0,"supplier":"legacy"})
 b.delivery={};b.delivery_due=0;b.inputs=0
 for lots in b.materials.values():
  for lot in lots:b.inputs+=int(lot.qty)
static func upgrade(s:Dictionary)->Dictionary:
 if not s.has("seed"):s.seed=int(Time.get_unix_time_from_system())%1000000
 if not s.has("pool_epoch"):s.pool_epoch=-1
 if not s.has("people_profiles"):s.people_profiles={}
 if not s.has("applicants"):s.applicants=[]
 if not s.has("started"):s.started=not s.businesses.is_empty()
 if not s.has("restart_count"):s.restart_count=0
 if not s.has("archives"):s.archives=[]
 if not s.has("research"):s.research={}
 for id in s.businesses:
  var b=s.businesses[id];ensure_business(id,b)
  if not b.has("summary"):b.summary={"full_days":0,"profitable_days":0,"streak":0,"best_streak":0,"profit":0.0,"spoilage_cost":0.0,"idle_equipment_days":0}
  for key in ["pending_expenses","visitors"]:
   if not b.has(key):b[key]=0.0
  if not b.has("asset_use"):b.asset_use={}
  if not b.has("rentals"):b.rentals=[]
  if not b.has("services"):b.services=[]
  if not b.has("next_service"):b.next_service=0
  for asset in b.assets.values():
   if not asset.has("count"):asset.count=1
 profiles=s.people_profiles;current_pool=s.applicants
 return s
static func clean_name(value:String)->String:
 var name=value.strip_edges()
 if name.length()<3 or name.length()>32 or name.replace(" ","").replace("-","").replace(".","").replace("&","").replace("'","").is_empty():return "Use 3–32 characters."
 var allowed=RegEx.new();allowed.compile("^[\\p{L}\\p{N} '&.-]+$")
 if allowed.search(name)==null:return "Use letters, numbers, spaces, apostrophes, & or hyphens."
 var normalized=name.to_lower().replace("0","o").replace("1","i").replace("3","e").replace("4","a").replace("5","s").replace("7","t")
 for symbol in [" ","-",".","'","&"]:normalized=normalized.replace(symbol,"")
 for word in ["fuck","shit","bitch","cunt","nigger","faggot","porn","dickhead","asshole"]:
  if word in normalized:return "Choose a school-appropriate business name."
 return ""
static func valid_operations(b:Dictionary)->bool:
 if b.get("operations")!=2:return not b.has("operations")
 for key in ["menu","materials","finished","assets","observations"]:
  if not b.get(key) is Dictionary or b[key].size()>80:return false
 if not b.get("trade") in ["kitchen","workshop","clothier","fishery","garden","mine","store","courier","rental","salon","daycare","minigolf","dessert","cafe"] or not clean_name(b.name).is_empty():return false
 if not b.get("failed") is bool or not whole(b.get("arrears"),0,1000000) or not b.get("production_key") is String:return false
 for key in b.menu:
  var m=b.menu[key]
  if not ops().products.has(key) or ops().products[key].trade!=b.trade or not m is Dictionary or not m.get("enabled") is bool or not number(m.get("price"),1,ops().products[key].price*3) or not whole(m.get("target"),1,40):return false
 for kind in ["materials","finished"]:
  var definitions=ops().materials if kind=="materials" else ops().products;var units=0;var total=0.0
  for key in b[kind]:
   if not definitions.has(key) or not b[kind][key] is Array or b[kind][key].size()>24:return false
   for lot in b[kind][key]:
    if not lot is Dictionary or not whole(lot.get("qty"),1,10000) or not number(lot.get("cost"),0,100000000) or not whole(lot.get("age"),0,1000000) or not number(lot.get("quality"),.1,2):return false
    units+=int(lot.qty);total+=float(lot.cost)
  if units!=int(b.inputs if kind=="materials" else b.stock) or absf(total-float(b.input_book if kind=="materials" else b.stock_book))>.02:return false
 for key in b.assets:
  if not ops().equipment.has(key) or not b.assets[key] is Dictionary or not number(b.assets[key].get("condition"),.1,1) or not number(b.assets[key].get("paid"),0,100000000) or not whole(b.assets[key].get("count"),1,12):return false
 if not b.get("orders") is Array or b.orders.size()>40:return false
 for order in b.orders:
  if not order is Dictionary or not ops().materials.has(order.get("material")) or not whole(order.get("qty"),1,1000) or not number(order.get("cost"),0,100000000) or not number(order.get("due"),0,1000000) or not number(order.get("quality"),.1,2):return false
 if b.has("services"):
  if not b.services is Array or b.services.size()>80:return false
  for job in b.services:
   if not job is Dictionary or not ops().products.has(job.get("product")) or not whole(job.get("id"),1,1000000) or not number(job.get("remaining"),0,200) or not number(job.get("duration"),.1,200) or not job.get("slots") is Array or job.slots.is_empty() or job.slots.size()>2 or not number(job.get("cost"),0,100000000) or not number(job.get("price"),0,100000000):return false
 return true

static func visible_ventures(s:Dictionary)->Array:
 return ventures()+all().get("legacy_ventures",[]).filter(func(v):return s.businesses.has(v.id))
