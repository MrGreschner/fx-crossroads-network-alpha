extends RefCounted
## Instant mining counter. Original commerce fields are retained as a read-only archive.
const PRODUCTS=[
 {"id":"ore","name":"Sorted ore","depth":1,"ore":10.0,"gems":0.0,"cost":2.0,"base":12.0,"segment":0},
 {"id":"bars","name":"Forged tool blanks","depth":2,"ore":18.0,"gems":0.0,"cost":5.0,"base":24.0,"segment":0},
 {"id":"crystals","name":"Polished crystals","depth":3,"ore":2.0,"gems":1.0,"cost":6.0,"base":32.0,"segment":1},
 {"id":"jewelry","name":"Silverfall pendants","depth":6,"ore":12.0,"gems":2.0,"cost":14.0,"base":68.0,"segment":1},
 {"id":"lamps","name":"Crystal lanterns","depth":10,"ore":28.0,"gems":3.0,"cost":22.0,"base":112.0,"segment":2},
 {"id":"clockwork","name":"Clockwork keepsakes","depth":14,"ore":45.0,"gems":5.0,"cost":38.0,"base":185.0,"segment":2},
 {"id":"copper_bar","name":"Copper bars","depth":2,"ore":0.0,"gems":0.0,"cost":1.0,"base":15.0,"segment":0,"bar":"copper"},
 {"id":"iron_bar","name":"Iron bars","depth":4,"ore":0.0,"gems":0.0,"cost":2.0,"base":24.0,"segment":0,"bar":"iron"},
 {"id":"cobalt_bar","name":"Cobalt bars","depth":7,"ore":0.0,"gems":0.0,"cost":3.0,"base":38.0,"segment":2,"bar":"cobalt"},
 {"id":"mithril_bar","name":"Mithril bars","depth":11,"ore":0.0,"gems":0.0,"cost":4.0,"base":60.0,"segment":1,"bar":"mithril"},
 {"id":"emberite_bar","name":"Emberite bars","depth":15,"ore":0.0,"gems":0.0,"cost":6.0,"base":90.0,"segment":2,"bar":"emberite"},
 {"id":"starsteel_bar","name":"Starsteel bars","depth":18,"ore":0.0,"gems":0.0,"cost":8.0,"base":130.0,"segment":1,"bar":"starsteel"}]
const GOLD_CAP=1e15
var legacy:Node
var view:CanvasLayer
var note="Choose the finds to sell. Mine Gold pays for your mine and its supplies."
var reward_date_for_test=""
func reward_date()->String:return reward_date_for_test if not reward_date_for_test.is_empty() else Time.get_date_string_from_system(false)
static func exchange_defaults()->Dictionary:
 return {"version":1,"settled":true,"cash":0.0,"stock":0.0,"upgrades":0.0,"debt":0.0,"credit":0.0,"pending":0.0,"sold":0,"earned":0.0,"notice_seen":true}
static func valid_exchange(v:Variant)->bool:
 if not v is Dictionary or v.size()!=11 or v.get("version")!=1 or v.get("settled")!=true or not v.get("notice_seen") is bool:return false
 for k in ["cash","stock","upgrades","debt","credit","pending","earned","sold"]:
  if not (v.get(k) is float or v.get(k) is int) or not is_finite(float(v[k])) or v[k]<0 or v[k]>1e17:return false
 return v.sold==floorf(float(v.sold)) and v.pending<=v.credit
static func fresh()->Dictionary:
 var items={}
 for product in PRODUCTS:items[product.id]={"units":0,"book":0.0,"price":product.base}
 return {"version":1,"day_seconds":300.0,"trading":{},"cash":160.0,"debt":0.0,"day":0,"inventory":items,"product":0,"segment":0,"channel":0,"message":0,"budget":0.0,"quality":0,"service":0,"shop":0,"reputation":50.0,"revenue":0.0,"profit":0.0,"units":0,"marketing":0.0,"materials_ore":0.0,"materials_gems":0.0,"history":[],"brand":"Deepwell Goods","copy":"Built from the heart of the mountain.","forecast":"","reflection":"","exchange":exchange_defaults()}
func setup(owner:Node)->void:
 legacy=owner
 if not legacy.data.has("commerce") or not valid(legacy.data.commerce):legacy.data.commerce=fresh()
 migrate()
func state()->Dictionary:return legacy.data.commerce
func exchange()->Dictionary:return state().get("exchange",exchange_defaults())
func readonly()->bool:return legacy.mine.readonly()
func save()->void:legacy.save()
func busy()->bool:return false
func step(_delta:float)->void:pass # No campaigns, passive trading or business simulation here.
func advance()->void:pass
func migrate()->bool:
 if readonly() or state().has("exchange"):return false
 var a=state();var x=exchange_defaults();var invested=not a.trading.is_empty() if a.has("trading") else false
 invested=invested or a.day>0 or a.cash!=160 or a.debt>0 or a.revenue>0 or a.materials_ore>0 or a.materials_gems>0
 for product in a.inventory.values():
  x.stock+=float(product.book);invested=invested or product.units>0 or product.book>0
 for k in ["quality","service","shop"]:
  for level in int(a[k]):x.upgrades+=70*pow(1.8,level)
 invested=invested or x.upgrades>0
 if invested:
  x.cash=float(a.cash);x.debt=float(a.debt);x.credit=maxf(0,x.cash+x.stock+x.upgrades-x.debt);x.pending=x.credit;x.notice_seen=false
 # Keep the old cash, stock, upgrades and reports untouched for recovery/history.
 # An unused default 160-credit stall is not an investment and earns no conversion.
 a.exchange=x
 claim_credit(false)
 return true
func claim_credit(persist:bool=true)->bool:
 if readonly() or not state().has("exchange"):return false
 var x=exchange();var amount=minf(float(x.pending),maxf(0,GOLD_CAP-float(legacy.mine.state().wallet.gold)))
 if amount<=0:return false
 x.pending=maxf(0,float(x.pending)-amount);legacy.mine.state().wallet.gold+=amount
 if persist:save()
 return true
func supply_reward()->Dictionary:
 if not state().has("supply_reward"):state().supply_reward={"pending":0,"last_earned":"","claimed":0}
 return state().supply_reward
func claim_supply()->bool:
 if legacy.game.mode!="town" or readonly() or bool(legacy.data.get("teacher",false)) or preload("res://scripts/profile_store.gd").progression_blocked():return false
 var reward=supply_reward();var amount=int(reward.pending)
 if amount<=0:return false
 reward.pending=0;reward.claimed+=amount;legacy.game.gold+=amount;legacy.game.save_profile();save();note="Collected your remaining old supply reward: "+str(amount)+" CC.";return true
func goods()->Array:
 var list=[{"id":"ore","name":"Loose ore","price":.45,"kind":"ore","hint":"Useful for mine construction and refining."},{"id":"gems","name":"Gem fragments","price":8.0,"kind":"gem","hint":"Keep some for deeper mine upgrades."}]
 for id in preload("res://scripts/mine_geology.gd").DEPOSITS:
  var d=preload("res://scripts/mine_geology.gd").DEPOSITS[id]
  list.append({"id":"deposit:"+id,"name":d.name,"price":float(d.price),"kind":"ore" if id=="coal" else "gem","hint":"Coal fuels the foundry." if id=="coal" else "A find from the deeper seams."})
 for id in legacy.mine.FOUNDRY.METALS:
  var d=legacy.mine.FOUNDRY.METALS[id]
  list.append({"id":"metal:"+id,"name":d.name+" ore","price":float(d.price)*.55/float(d.ore),"kind":"ore","hint":"Forge this into bars at your mine."})
  list.append({"id":"bar:"+id,"name":d.name+" bars","price":float(d.price),"kind":"bar","hint":"Bars are also needed for deeper construction."})
 return list
func bucket(id:String)->Dictionary:
 if id in ["ore","gems"]:return legacy.mine.state().wallet
 if id.begins_with("deposit:"):return preload("res://scripts/mine_geology.gd").state(legacy.mine).wallet
 return legacy.mine.FOUNDRY.state(legacy.mine).bars if id.begins_with("bar:") else legacy.mine.FOUNDRY.state(legacy.mine).wallet
func key_for(id:String)->String:return id.get_slice(":",1) if ":" in id else id
func amount(id:String)->float:return float(bucket(id).get(key_for(id),0))
func quote(selection:Dictionary)->Dictionary:
 if selection.is_empty() or selection.size()>20:return {}
 var available={}
 for d in goods():available[d.id]=d
 var rows=[];var total=0.0
 var ids=selection.keys();ids.sort()
 for id in ids:
  var n:Variant=selection[id]
  if not available.has(id) or not (n is int or n is float) or not is_finite(float(n)) or n!=floorf(float(n)) or n<1 or n>1000000000 or amount(id)+1e-7<float(n):return {}
  var d=available[id];var value=float(n)*float(d.price);rows.append({"id":id,"name":d.name,"count":int(n),"price":d.price,"value":value});total+=value
 return {"rows":rows,"total":total}
func sell(selection:Dictionary,expected:Dictionary)->bool:
 if readonly() or legacy.game.mode!="town":return false
 var offer=quote(selection)
 if offer.is_empty() or JSON.stringify(offer)!=JSON.stringify(expected):note="Your selection changed. Review the sale again.";return false
 if float(legacy.mine.state().wallet.gold)+offer.total>GOLD_CAP:note="Not enough room in your Mine Gold wallet. Spend some at the mine first.";return false
 for row in offer.rows:
  var stock=bucket(row.id);stock[key_for(row.id)]=maxf(0,float(stock[key_for(row.id)])-row.count)
 legacy.mine.state().wallet.gold+=offer.total
 var x=exchange();var count=0
 for row in offer.rows:count+=row.count
 x.sold=mini(int(1e17),int(x.sold)+count);x.earned=minf(1e17,float(x.earned)+offer.total)
 note="Sold "+str(count)+" finds for %.2f Mine Gold." % offer.total
 save();return true
func buy_supply(id:String,expected:Dictionary)->bool:
 if readonly() or legacy.game.mode!="town" or not legacy.mine.SERVICES.has(id):return false
 if JSON.stringify(legacy.mine.upgrade_cost(id))!=JSON.stringify(expected):note="The upgrade changed. Check its price again.";return false
 var ok=legacy.mine.upgrade(id)
 note="Your mine crew has started the upgrade." if ok else "Check your materials, shaft depth or current construction job."
 return ok
func ore_level()->int:return mini(50,1+int(sqrt(float(legacy.mine.state().lifetime.ore)/200)))
func gem_level()->int:return mini(50,1+int(sqrt(float(legacy.mine.state().lifetime.gems)/2)))
func report()->String:return JSON.stringify({"format":"fx-retired-commerce-archive","version":1,"business":state()},"  ")
func open()->void:
 if legacy.game.mode!="town":return
 migrate();claim_credit();save()
 if not is_instance_valid(view):view=preload("res://scripts/commerce_view.gd").new();legacy.game.add_child(view);view.setup(self)
 view.open()
static func valid(value:Variant)->bool:
 if not value is Dictionary:return false
 var d:Dictionary=value
 if d.has("exchange") and not valid_exchange(d.exchange):return false
 if d.has("supply_reward"):
  var reward=d.supply_reward
  if not reward is Dictionary:return false
  for key in ["pending","claimed"]:
   if not (reward.get(key) is int or reward.get(key) is float) or not is_finite(float(reward[key])) or float(reward[key])!=floorf(float(reward[key])) or float(reward[key])<0:return false
  if int(reward.pending)>60 or int(reward.pending)%20!=0 or float(reward.claimed)>1e12:return false
  if not reward.get("last_earned") is String or reward.last_earned.length()>10:return false
 for key in fresh():
  if key not in ["day_seconds","trading","exchange"] and not d.has(key):return false
 if d.has("day_seconds") and (not (d.day_seconds is int or d.day_seconds is float) or not is_finite(float(d.day_seconds)) or d.day_seconds<300 or d.day_seconds>86400):return false
 if d.has("trading"):
  if not d.trading is Dictionary:return false
  if not d.trading.is_empty():
   for key in ["start","end","seconds"]:
    if not d.trading.has(key) or not (d.trading[key] is int or d.trading[key] is float) or not is_finite(float(d.trading[key])) or d.trading[key]<0 or d.trading[key]>4102444800:return false
   if d.trading.seconds<300 or d.trading.seconds>86400 or not is_equal_approx(float(d.trading.end)-float(d.trading.start),float(d.trading.seconds)):return false
 for key in ["cash","debt","revenue","profit","marketing","materials_ore","materials_gems","budget","reputation"]:
  if not (d[key] is int or d[key] is float) or not is_finite(float(d[key])) or absf(float(d[key]))>1e15:return false
  if key!="profit" and d[key]<0:return false
 if d.debt!=0 and d.debt!=100:return false
 if d.reputation>100 or d.budget>100 or d.version!=1:return false
 for key in ["day","units","quality","service","shop","product","segment","channel","message"]:
  if not (d[key] is int or d[key] is float) or float(d[key])!=floor(float(d[key])) or d[key]<0 or d[key]>1000000000:return false
 for key in ["quality","service","shop"]:
  if d[key]>5:return false
 if d.product>=PRODUCTS.size() or d.segment>2 or d.channel>2 or d.message>2:return false
 for key in ["brand","copy","forecast","reflection"]:
  if not d[key] is String or d[key].length()>1000:return false
 if not d.inventory is Dictionary or d.inventory.size()<6 or d.inventory.size()>PRODUCTS.size():return false
 for id in d.inventory:
  if id not in PRODUCTS.map(func(p):return p.id):return false
 for p in PRODUCTS:
  if not d.inventory.has(p.id) and p.has("bar"):continue
  if not d.inventory.get(p.id) is Dictionary:return false
  var i=d.inventory[p.id]
  for key in ["units","book","price"]:
   if not i.has(key) or not (i[key] is int or i[key] is float) or not is_finite(float(i[key])) or i[key]<0 or i[key]>1e15:return false
  if i.units>10000 or i.units!=floor(i.units) or i.price<1 or i.price>p.base*4:return false
 if not d.history is Array or d.history.size()>100:return false
 for row in d.history:
  if not row is Dictionary or JSON.stringify(row).length()>10000:return false
  for key in ["day","price","stock","sold","unmet","reach","visits","conversion","revenue","cogs","advertising","overhead","profit","satisfaction","roas"]:
   if not row.has(key) or not (row[key] is int or row[key] is float) or not is_finite(float(row[key])) or absf(float(row[key]))>1e15:return false
  for key in ["event","product","target","forecast","reflection","brand","copy","channel","message"]:
   if not row.get(key) is String or row[key].length()>1000:return false
 return true
