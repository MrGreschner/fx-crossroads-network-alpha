extends RefCounted
## Local classroom simulation. Business days are explicit, reproducible decision rounds.
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
const SEGMENTS=["Builders • value and durability","Collectors • quality and story","Guilds • reliability and service"]
const CHANNELS=["Street posters","Town gazette","Guild bulletin"]
const MESSAGES=["Honest value","Handcrafted wonder","Dependable supply"]
var legacy:Node
var view:CanvasLayer
var time_for_test=-1.0
var tick=0.0
var reward_date_for_test=""
func reward_date()->String:return reward_date_for_test if not reward_date_for_test.is_empty() else Time.get_date_string_from_system(false)
func supply_reward()->Dictionary:
 if not state().has("supply_reward"):state().supply_reward={"pending":0,"last_earned":"","claimed":0}
 return state().supply_reward
func earn_supply(profit:float,sold:int)->bool:
 if profit<=0 or sold<=0 or readonly() or bool(legacy.data.get("teacher",false)) or preload("res://scripts/profile_store.gd").progression_blocked():return false
 var reward=supply_reward()
 if str(reward.last_earned)==reward_date() or int(reward.pending)>=60:return false
 reward.pending=mini(60,int(reward.pending)+20);reward.last_earned=reward_date();return true
func claim_supply()->bool:
 if legacy.game.mode!="town" or readonly() or bool(legacy.data.get("teacher",false)) or preload("res://scripts/profile_store.gd").progression_blocked():return false
 var reward=supply_reward();var amount=int(reward.pending)
 if amount<=0:note="Complete a profitable market day with at least one sale to earn a supply dividend.";return false
 reward.pending=0;reward.claimed=int(reward.claimed)+amount;save();legacy.game.gold+=amount
 legacy.game.save_profile();note="Collected "+str(amount)+" CC for town supplies. Combat stats and multiplayer starting CC are unchanged.";save();return true
func now()->float:return time_for_test if time_for_test>=0 else Time.get_unix_time_from_system()
func busy()->bool:return not state().get("trading",{}).is_empty()
func step(delta:float)->void:
 tick+=delta
 if tick>=1:tick=0;advance()
func advance()->void:
 if legacy==null or readonly() or not busy():return
 if now()>=float(state().trading.end):
  state().trading={}
  settle_day()
func set_duration(seconds:float)->bool:
 if readonly() or busy() or seconds<300 or seconds>86400:return false
 state().day_seconds=seconds;save();return true
var note="Welcome! Choose Basic setup for your first stall, or prepare goods from your mine. Then open for a timed business day."
static func fresh()->Dictionary:
 var items={}
 for product in PRODUCTS:items[product.id]={"units":0,"book":0.0,"price":product.base}
 return {"version":1,"day_seconds":300.0,"trading":{},"cash":160.0,"debt":0.0,"day":0,"inventory":items,"product":0,"segment":0,"channel":0,"message":0,"budget":0.0,"quality":0,"service":0,"shop":0,"reputation":50.0,"revenue":0.0,"profit":0.0,"units":0,"marketing":0.0,"materials_ore":0.0,"materials_gems":0.0,"history":[],"brand":"Deepwell Goods","copy":"Built from the heart of the mountain.","forecast":"","reflection":""}
func setup(owner:Node)->void:
 legacy=owner
 if not legacy.data.has("commerce") or not valid(legacy.data.commerce):legacy.data.commerce=fresh()
 for d in PRODUCTS:
  if not state().inventory.has(d.id):state().inventory[d.id]={"units":0,"book":0.0,"price":d.base}
 for key in ["day_seconds","trading"]:
  if not state().has(key):state()[key]=fresh()[key]
 advance()
func state()->Dictionary:return legacy.data.commerce
func readonly()->bool:return legacy.mine.readonly()
func save()->void:legacy.save()
func unlocked(index:int)->bool:return index>=0 and index<PRODUCTS.size() and (index==0 or legacy.mine.depth()>=int(PRODUCTS[index].depth))
func stock(index:int,count:int)->bool:
 if readonly() or busy() or not unlocked(index) or count<1 or count>100:return false
 legacy.mine.advance()
 var d=PRODUCTS[index];var w=legacy.mine.state().wallet;var q=1+.25*int(state().quality)
 var ore=float(d.ore)*count;var gems=float(d.gems)*count;var cash=float(d.cost)*q*count
 var metal=str(d.get("bar",""));var bars=preload("res://scripts/mine_foundry.gd").state(legacy.mine).bars
 if not metal.is_empty() and float(bars[metal])<count:return false
 if w.ore+1e-7<ore or w.gems+1e-7<gems or state().cash+1e-7<cash:return false
 var item=state().inventory[d.id]
 if int(item.units)+count>10000:return false
 w.ore=maxf(0,w.ore-ore);w.gems=maxf(0,w.gems-gems);state().cash-=cash
 if not metal.is_empty():bars[metal]-=count
 item.units+=count;item.book+=cash+ore*.45+gems*8+(count*float(d.base)*.55 if not metal.is_empty() else 0.0) # teaching opportunity-cost convention, not a conversion.
 state().materials_ore+=ore;state().materials_gems+=gems;save();return true
func upgrade(kind:String)->bool:
 if readonly() or busy() or kind not in ["quality","service","shop"] or int(state()[kind])>=5:return false
 var cost=70*pow(1.8,int(state()[kind]))
 if state().cash<cost:return false
 state().cash-=cost;state()[kind]+=1;save();return true
func transfer(amount:float)->bool:
 if readonly() or busy() or amount<=0 or amount>10000 or state().cash<amount:return false
 state().cash-=amount;legacy.mine.state().wallet.gold=minf(1e15,legacy.mine.state().wallet.gold+amount);save();return true
func loan()->bool:
 if readonly() or busy() or state().debt>0:return false
 state().cash+=80;state().debt=100;note="Working-capital loan: received 80 cash; repay 100. Only one loan at a time. Borrowing is not revenue or profit.";save();return true
func repay()->bool:
 if readonly() or busy() or state().debt<=0 or state().cash<state().debt:return false
 state().cash-=state().debt;state().debt=0;note="Loan repaid. Keep a cash reserve for your next campaign.";save();return true
func research()->bool:
 if readonly() or busy() or state().cash<12:return false
 state().cash-=12;note="CUSTOMER SURVEY: Builders compare price and value. Collectors prefer quality and a handcrafted story. Guilds favour service and reliable supply. Posters reach builders; the gazette reaches collectors; bulletins reach guilds. Price above the reference cuts conversion. Forecast before spending.";save();return true
func start_problem()->String:
 if readonly():return "Playtest mode protects your business. Return to a normal profile to trade."
 if busy():return "Your market is already trading. Wait for the displayed countdown."
 var a=state();var product=PRODUCTS[int(a.product)]
 if not unlocked(int(a.product)):return "This product needs a deeper mine. Select Sorted ore, or use Basic setup."
 if int(a.inventory[product.id].units)<=0:return "No stock for this product. Prepare goods from collected mine materials, or choose Basic setup."
 var required=float(a.budget)+2+a.shop*2+a.service*2
 if float(a.cash)<required:return "Need %.1f market cash for advertising and daily overhead. Lower the budget or check your financing options." % required
 return ""
func basic_setup()->bool:
 if readonly() or busy():return false
 var a=state();var item=a.inventory.ore
 if int(item.units)==0:
  # A wholesale purchase starts a business without granting free mine materials.
  if a.cash<32:note="Basic setup needs 32 market cash: 30 for five wholesale units and 2 daily overhead. Reduce costs or use the working-capital loan.";return false
  a.cash-=30;item.units=5;item.book=30.0
 a.product=0;a.segment=0;a.channel=0;a.message=0;a.budget=0;item.price=12.0
 note="Basic setup ready: Sorted ore, builders, fair price, posters and no paid advertising. Five wholesale units cost 30 market cash if stock was empty. Press Open market; one day lasts your chosen time. Future stock can come from your mine."
 save();return true
func run_day()->bool:
 if readonly():return false
 advance()
 if busy():return false
 var a=state();var product=PRODUCTS[int(a.product)]
 var issue=start_problem()
 if not issue.is_empty():note=issue;return false
 a.trading={"start":now(),"end":now()+float(a.day_seconds),"seconds":float(a.day_seconds)}
 note="Market open. Customers are browsing; this business day settles when the countdown ends. You can adventure or close the game."
 save();return true
func settle_day()->bool:
 if readonly():return false
 var a=state();var index=int(a.product)
 if not unlocked(index):return false
 var product=PRODUCTS[index];var item=a.inventory[product.id];var price=float(item.price)
 var budget=float(a.budget);var overhead=2+int(a.shop)*2+int(a.service)*2
 if int(item.units)<=0 or a.cash<budget+overhead:return false
 # Campaign and customer fit are visible to learners. Seeded calendar events are shared per business day.
 var event_index=int(a.day)%5;var events=["Ordinary market day","Builders repair the bridge","Collectors visit town","Guild procurement day","Rain reduces foot traffic"]
 var target=int(a.segment);var match=target==int(product.segment)
 var channel_fit=1.0 if int(a.channel)==target else .4
 var message_fit=1.0 if int(a.message)==target else .45
 var reach=80+int(a.shop)*22+int(budget*8*channel_fit)
 var visits=int(reach*(.17+.05*message_fit)*(.7+float(a.reputation)/150))
 if event_index==target+1:visits=int(visits*1.35)
 if event_index==4:visits=int(visits*.7)
 var ratio=price/(float(product.base)*(1+.08*int(a.quality)))
 var conversion=clampf(.55*(1.18 if match else .68)*pow(maxf(.25,ratio),-1.8)*(1+.05*int(a.service)),.02,.95)
 var demand=maxi(0,int(round(visits*conversion)));var sold=mini(demand,int(item.units))
 var unit_cost=float(item.book)/maxi(1,int(item.units));var cogs=sold*unit_cost
 var revenue=sold*price;var profit=revenue-cogs-budget-overhead
 if profit>0 and sold>0:legacy.weekly.advance("market",1)
 # COGS was committed at preparation. Cash receives sales minus today's operating spend, without double payment.
 a.cash=minf(1e15,maxf(0,a.cash+revenue-budget-overhead));item.units-=sold;item.book=maxf(0,item.book-cogs)
 var satisfaction=clampf(68+int(a.quality)*4+int(a.service)*4-(ratio-1)*30+(8 if match else -8),0,100)
 a.reputation=clampf(a.reputation*.85+satisfaction*.15-(4 if demand>sold else 0),0,100)
 a.day+=1;a.revenue+=revenue;a.profit+=profit;a.units+=sold;a.marketing+=budget
 var row={"day":a.day,"event":events[event_index],"product":product.name,"target":SEGMENTS[target],"price":price,"stock":sold+int(item.units),"sold":sold,"unmet":demand-sold,"reach":reach,"visits":visits,"conversion":conversion,"revenue":revenue,"cogs":cogs,"advertising":budget,"overhead":overhead,"profit":profit,"satisfaction":satisfaction,"roas":revenue/budget if budget>0 else 0.0,"forecast":a.forecast,"reflection":a.reflection,"brand":a.brand,"copy":a.copy,"channel":CHANNELS[int(a.channel)],"message":MESSAGES[int(a.message)]}
 a.history.append(row)
 preload("res://scripts/learning_store.gd").activity("Market day completed",str(product.name)+" • day "+str(a.day))
 if a.history.size()>100:a.history.pop_front()
 note="DAY %d • %s\nSold %d • missed demand %d • revenue %.1f • profit %.1f\nYour market day is complete. Restock or adjust your stall for the next day." % [a.day,row.event,sold,demand-sold,revenue,profit]
 if earn_supply(profit,sold):note+="\nSupply dividend earned: +20 CC. Collect it in the Market floor tab."
 save();return true
func ore_level()->int:return mini(50,1+int(sqrt(float(legacy.mine.state().lifetime.ore)/200)))
func gem_level()->int:return mini(50,1+int(sqrt(float(legacy.mine.state().lifetime.gems)/2)))
func report()->String:
 var business=state().duplicate(true)
 if not preload("res://scripts/education_access.gd").student():
  business.erase("forecast");business.erase("reflection")
  for row in business.history:row.erase("forecast");row.erase("reflection")
 return JSON.stringify({"format":"fx-commerce-report","version":1,"testing_mode":"Game Dev" if bool(legacy.data.teacher) else "Playtest" if readonly() else "Normal","simulation":"Educational model, not real market predictions","mine":{"depth_m":legacy.mine.depth()*30,"ore_level":ore_level(),"gem_level":gem_level(),"lifetime":legacy.mine.state().lifetime},"business":business},"  ")
func open()->void:
 if legacy.game.mode!="town":return
 if not is_instance_valid(view):view=preload("res://scripts/commerce_view.gd").new();legacy.game.add_child(view);view.setup(self)
 view.open()
static func valid(value:Variant)->bool:
 if not value is Dictionary:return false
 var d:Dictionary=value
 if d.has("supply_reward"):
  var reward=d.supply_reward
  if not reward is Dictionary:return false
  for key in ["pending","claimed"]:
   if not (reward.get(key) is int or reward.get(key) is float) or not is_finite(float(reward[key])) or float(reward[key])!=floorf(float(reward[key])) or float(reward[key])<0:return false
  if int(reward.pending)>60 or int(reward.pending)%20!=0 or float(reward.claimed)>1e12:return false
  if not reward.get("last_earned") is String or reward.last_earned.length()>10:return false
 for key in fresh():
  if key not in ["day_seconds","trading"] and not d.has(key):return false
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
