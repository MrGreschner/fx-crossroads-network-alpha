extends RefCounted
## Persistent town wallet. CC and business simulation cash never convert into Glimmers.
const C=preload("res://scripts/fishing_catalog.gd")
const ING=preload("res://scripts/lodge_catalog.gd").INGREDIENTS
var legacy:Node
func state()->Dictionary:
 if not legacy.data.has("glimmers"):legacy.data.glimmers={"balance":0,"earned":0,"spent":0,"market_day":""}
 return legacy.data.glimmers
func allowed()->bool:
 return not preload("res://scripts/profile_store.gd").progression_blocked() or bool(legacy.data.get("teacher",false))
func balance()->int:return int(state().balance)
func credit(amount:int)->bool:
 if amount<=0 or not allowed() or balance()+amount>1000000000:return false
 state().balance+=amount;state().earned+=amount;return true
func debit(amount:int)->bool:
 if amount<=0 or not allowed() or balance()<amount:return false
 state().balance-=amount;state().spent+=amount;return true
func fish_price(catch:Dictionary)->int:
 if catch.is_empty() or catch.get("species","") not in C.fish():return 0
 var base=int({"Common":4,"Uncommon":7,"Rare":15,"Very rare":22,"Legendary":45,"Mystical":70}.get(str(C.fish()[catch.species].rarity),4))
 var price=base+maxi(1,base/4) if C.is_trophy(catch) else base
 return maxi(1,int(round(price*(1+legacy.fishing_records.progress.perk_bonus("sale")))))
func sell_fish(id:String)->String:
 if legacy.game.mode!="town" or not allowed():return "Return to a normal town profile to trade."
 var records=legacy.fishing_records;var catch=records.specimen(id);var price=fish_price(catch)
 if price<=0:return "This catch has already been sold or released."
 if not credit(price):return "Your Glimmer wallet is full."
 # One profile save includes the wallet and removal from collection/displays.
 records.release(id)
 return "Sold %s for %d Glimmers. Journal and fishing XP retained." % [C.fish()[catch.species].name,price]
func ingredient_price(id:String)->int:return 1 if id in ["sunleaf","petal"] else 2
func sell_ingredient(id:String,count:int)->String:
 if legacy.game.mode!="town" or not allowed():return "Return to a normal town profile to trade."
 var stock=legacy.lodge_economy.state().ingredients
 if id not in ING or count<1 or count>100 or int(stock.get(id,0))<count:return "Not enough gathered ingredients."
 if not credit(ingredient_price(id)*count):return "Your Glimmer wallet is full."
 stock[id]-=count;legacy.save();return "Sold %d %s for %d Glimmers." % [count,ING[id].name,count*ingredient_price(id)]
func market_reward()->bool:
 if not allowed() or bool(legacy.data.get("teacher",false)):return false
 var date=legacy.commerce.reward_date()
 if str(state().market_day)==date:return false
 if not credit(10):return false
 state().market_day=date;return true
static func valid(v:Variant)->bool:
 if not v is Dictionary or v.size()!=4:return false
 for key in ["balance","earned","spent"]:
  var n=v.get(key)
  if not (n is int or n is float) or not is_finite(float(n)) or float(n)!=floorf(float(n)) or n<0 or n>(1e9 if key=="balance" else 1e15):return false
 return v.get("market_day") is String and v.market_day.length()<=10 and int(v.earned)-int(v.spent)==int(v.balance)
