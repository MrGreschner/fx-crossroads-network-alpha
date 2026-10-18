extends RefCounted
## Persistent town wallet. CC and business simulation cash never convert into Glimmers.
const C=preload("res://scripts/fishing_catalog.gd")
const ING=preload("res://scripts/lodge_catalog.gd").INGREDIENTS
var legacy:Node
var last_credit=0
var last_crown_bonus=0
func state()->Dictionary:
 if not legacy.data.has("glimmers"):legacy.data.glimmers={"balance":0,"earned":0,"spent":0,"market_day":""}
 return legacy.data.glimmers
func allowed()->bool:
 return not preload("res://scripts/profile_store.gd").progression_blocked() or bool(legacy.data.get("teacher",false))
func balance()->int:return int(state().balance)
func crown_basis_points()->int:
 if legacy.get("crowns")==null or bool(legacy.data.get("teacher",false)):return 0
 legacy.crowns.refresh()
 return preload("res://scripts/rolling_crowns.gd").glimmer_basis_points(preload("res://scripts/rolling_crowns.gd").tier_from(legacy.crowns.total()))
func award_quote(amount:int)->Dictionary:
 var units=maxi(0,amount)*crown_basis_points()+int(state().get("crown_remainder",0))
 var extra=int(units/10000)
 return {"total":amount+extra,"bonus":extra,"remainder":units%10000}
func credit(amount:int)->bool:
 last_credit=0;last_crown_bonus=0
 if amount<=0 or amount>1000000000 or not allowed():return false
 var award=award_quote(amount)
 if balance()+int(award.total)>1000000000:return false
 state().balance+=int(award.total);state().earned+=int(award.total);state().crown_remainder=int(award.remainder)
 last_credit=int(award.total);last_crown_bonus=int(award.bonus);return true
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
 var paid=last_credit;var crown_extra=last_crown_bonus
 # One profile save includes the wallet and removal from collection/displays.
 records.release(id)
 return "Sold %s for %d Glimmers%s. Journal and fishing XP retained." % [C.fish()[catch.species].name,paid," • includes %d crown bonus" % crown_extra if crown_extra>0 else ""]
func ingredient_price(id:String)->int:return 1 if id in ["sunleaf","petal"] else 2
func sell_ingredient(id:String,count:int)->String:
 if legacy.game.mode!="town" or not allowed():return "Return to a normal town profile to trade."
 var stock=legacy.lodge_economy.state().ingredients
 if id not in ING or count<1 or count>100 or int(stock.get(id,0))<count:return "Not enough gathered ingredients."
 if not credit(ingredient_price(id)*count):return "Your Glimmer wallet is full."
 var paid=last_credit;var extra=last_crown_bonus
 stock[id]-=count;legacy.save();return "Sold %d %s for %d Glimmers%s." % [count,ING[id].name,paid," • includes %d crown bonus" % extra if extra>0 else ""]
func market_reward()->bool:
 if not allowed() or bool(legacy.data.get("teacher",false)):return false
 var date=legacy.commerce.reward_date()
 if str(state().market_day)==date:return false
 if not credit(10):return false
 state().market_day=date;return true
static func valid(v:Variant)->bool:
 if not v is Dictionary or v.size() not in [4,5]:return false
 if v.size()==5:
  var carry=v.get("crown_remainder")
  if not (carry is int or carry is float) or not is_finite(float(carry)) or float(carry)!=floorf(float(carry)) or carry<0 or carry>=10000:return false
 for key in ["balance","earned","spent"]:
  var n=v.get(key)
  if not (n is int or n is float) or not is_finite(float(n)) or float(n)!=floorf(float(n)) or n<0 or n>(1e9 if key=="balance" else 1e15):return false
 return v.get("market_day") is String and v.market_day.length()<=10 and int(v.earned)-int(v.spent)==int(v.balance)
