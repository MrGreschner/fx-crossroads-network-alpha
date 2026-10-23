extends RefCounted
static var data:Dictionary={}
static func all()->Dictionary:
 if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://content/business-district.json"))
 return data
static func ventures()->Array:return all().ventures
static func staff()->Array:return all().staff
static func spec(id:String)->Dictionary:
 for v in ventures():
  if v.id==id:return v
 return {}
static func plot(id:String)->Vector2:
 var p=spec(id).plot;return Vector2(p[0],p[1])
static func fresh_business(id:String)->Dictionary:
 var v=spec(id)
 return {"hires":[],"name":v.name,"cash":300.0,"inputs":0,"input_book":0.0,"stock":0,"stock_book":0.0,"price":float(v.price),"quality":0,"equipment":0,"display":0,"cold":0,"brand":0,"layout":0,"route":0,"open":false,"elapsed":0.0,"day":0,"reputation":55.0,"employees":[],"history":[],"decisions":[],"delivery":{},"delivery_due":0.0,"produce":0.0,"served":0,"lost":0,"revenue":0.0,"cogs":0.0,"wait_total":0.0,"expenses":0.0,"opening_cash":300.0,"opening_inventory":0.0,"ad":0.0,"training":0,"loan":0.0,"last_result":{},"reason":"Ready to prepare your first opening.","ledger":[],"note":""}
static func fresh()->Dictionary:return {"version":1,"reserve":2700.0,"selected":"kitchen","businesses":{},"night":false,"visitors":0,"periods":0}
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
  if not whole(b[k],0,300):return false
 for k in ["quality","equipment","display","cold","brand","layout","route","training"]:
  if not whole(b[k],0,3 if k!="layout" and k!="route" else 2):return false
 for k in ["day","served","lost"]:
  if not whole(b[k],0,1000000):return false
 for k in ["elapsed","delivery_due","produce"]:
  if not number(b[k],0,1000000):return false
 if not b.employees is Array or b.employees.size()>3:return false
 var unique=[]
 for e in b.employees:
  if not e is Dictionary or not e.get("id") is int and not e.get("id") is float or not whole(e.id,0,7) or e.id in unique or not e.get("role") in ["craft","serve","stock"]:return false
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
 return JSON.stringify(b).length()<100000
static func valid(s:Variant)->bool:
 if not s is Dictionary or s.get("version")!=1 or not number(s.get("reserve"),0,100000000) or not s.get("selected") is String or spec(s.selected).is_empty() or not s.get("night") is bool:return false
 if not s.get("businesses") is Dictionary or s.businesses.size()>ventures().size():return false
 var assigned=[]
 for k in s.businesses:
  if not k is String or not valid_business(k,s.businesses[k]):return false
  for e in s.businesses[k].employees:
   if e.id in assigned:return false
   assigned.append(e.id)
 for k in ["visitors","periods"]:
  if not whole(s.get(k),0,100000000):return false
 return JSON.stringify(s).to_utf8_buffer().size()<1000000

static func valid_report(h:Variant)->bool:
 if not h is Dictionary:return false
 for key in ["day","sold","lost","spoilage","layout","equipment","quality"]:
  if not whole(h.get(key),0,1000001):return false
 for key in ["seconds","revenue","cogs","expenses","profit","cash","inventory","loan","wages","wait","price","campaign"]:
  if not number(h.get(key),-100000000 if key in ["cash","profit"] else 0,100000000):return false
 if not h.get("employees") is Array or h.employees.size()>3:return false
 for e in h.employees:
  if not e is Dictionary or not whole(e.get("id"),0,7) or e.get("role") not in ["craft","serve","stock"]:return false
 return true
