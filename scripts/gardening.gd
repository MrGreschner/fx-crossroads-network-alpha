extends RefCounted
## Portable local progression. Absolute real timestamps; harvests never rot.
static var catalog:Dictionary={}
static var talents:Dictionary={}
var legacy:Node
var time_for_test:float=-1
var page="beds"
var family="all"
var inventory_filter="owned"
var selected_perk=""
var note=""
var tick:float=0
var labels:Array=[]
var world_region=""
var caches:Array=[]
static func crops()->Dictionary:
 if catalog.is_empty():catalog=JSON.parse_string(FileAccess.get_file_as_string("res://content/gardening.json")).seeds
 return catalog
static func perks()->Dictionary:
 if talents.is_empty():talents=JSON.parse_string(FileAccess.get_file_as_string("res://content/garden-perks.json"))
 return talents
static func threshold(lv:int)->int:
 var n=maxi(0,lv-1);return 90*n*n+4*n*n*n
func level()->int:
 var lv=1
 while lv<100 and int(state().xp)>=threshold(lv+1):lv+=1
 return lv
func now()->float:return time_for_test if time_for_test>=0 else Time.get_unix_time_from_system()
func allowed()->bool:return not bool(legacy.data.get("teacher",false)) and not preload("res://scripts/profile_store.gd").progression_blocked() and not legacy.get_tree().root.has_meta("fx_dedicated_server")
func setup(owner:Node)->void:
 legacy=owner;world_region="";caches.clear()
 var migrate=not legacy.data.has("gardening") and not legacy.arcade and legacy.game.provisions.crop in ["growing","ready"]
 state();save()
 if migrate:legacy.game.provisions.crop="empty";legacy.game.provisions.save()
func state()->Dictionary:
 if not legacy.data.has("gardening"):
  legacy.data.gardening={"version":1,"xp":0,"seeds":{"orchard0":3,"river0":3,"flowers0":3},"produce":{},"beds":[{},{},{},{},{},{},{},{},{},{}],"perks":{},"seen":["orchard0","river0","flowers0"],"claims":{},"harvests":0,"resets":0}
  var pr=legacy.game.provisions
  if not legacy.arcade and pr.crop in ["growing","ready"] and crops().has(pr.garden_id):
   legacy.data.gardening.beds[0]={"seed":pr.garden_id,"start":now(),"end":now() if pr.crop=="ready" else now()+180,"duration":180}
 return legacy.data.gardening
static func valid(v:Variant)->bool:
 if not v is Dictionary or v.get("version")!=1:return false
 for key in ["xp","harvests","resets"]:
  if not (v.get(key) is float or v.get(key) is int) or not is_finite(float(v[key])) or float(v[key])<0 or float(v[key])>1e9:return false
 for key in ["seeds","produce"]:
  if not v.get(key) is Dictionary or v[key].size()>crops().size():return false
  for id in v[key]:
   if not crops().has(id) or not (v[key][id] is float or v[key][id] is int) or not is_finite(float(v[key][id])) or float(v[key][id])<0 or float(v[key][id])>1000000 or float(v[key][id])!=floor(float(v[key][id])):return false
 if not v.get("beds") is Array or v.beds.size()!=10 or not v.get("perks") is Dictionary or v.perks.size()>33:return false
 for b in v.beds:
  if not b is Dictionary:return false
  if b.is_empty():continue
  if b.size()!=4 or not crops().has(b.get("seed")):return false
  for key in ["start","end","duration"]:
   if not (b.get(key) is float or b.get(key) is int) or not is_finite(float(b[key])) or float(b[key])<0 or float(b[key])>4102444800:return false
  if float(b.end)<float(b.start) or float(b.duration)<=0 or not is_equal_approx(float(b.end)-float(b.start),float(b.duration)) and float(b.end)!=float(b.start):return false
 if not v.get("seen") is Array or v.seen.size()>crops().size() or not v.get("claims") is Dictionary or v.claims.size()>256:return false
 for key in v.claims:
  if not key is String or key.length()>100 or v.claims[key]!=true:return false
 for id in v.seen:
  if not crops().has(id):return false
 for id in v.perks:
  if not perks().has(id) or v.perks[id]!=true:return false
 var lv=1
 while lv<100 and int(v.xp)>=threshold(lv+1):lv+=1
 if v.perks.size()>mini(33,lv/3):return false
 for id in v.perks:
  var p=perks()[id]
  if lv<int(p.level):return false
  if not prerequisites(p,v.perks):return false
  for other in v.perks:
   if id!=other and not str(p.group).is_empty() and str(perks()[other].group)==str(p.group):return false
 return true
static func prerequisites(spec:Dictionary,owned:Dictionary)->bool:
 if spec.requires.is_empty():return true
 for id in spec.requires:
  if spec.get("any",false) and owned.has(id):return true
  if not spec.get("any",false) and not owned.has(id):return false
 return not spec.get("any",false)
func bonus(effect:String,family:String="")->float:
 var total=0.0
 for id in state().perks:
  var p=perks()[id]
  if str(p.effect)==effect and str(p.get("family","")) in ["",family]:total+=float(p.amount)
 return total
func capacity()->int:
 var n=1
 for lv in [5,15,30,50,75,90,100]:
  if level()>=lv:n+=1
 return mini(10,n+int(bonus("beds")))
func xp_gain(amount:int)->void:state().xp=mini(1000000000,int(state().xp)+amount)
func message(value:String)->void:note=value;legacy.game.message=value;legacy.game.message_time=5
func save()->void:legacy.save()
func buy_seed(id:String)->void:
 if not allowed() or not crops().has(id):return
 var spec=crops()[id]
 if spec.source!="shop" or level()<int(spec.level):message("Find this seed at its source, or reach its required level.");return
 if not legacy.glimmers.debit(int(spec.seed_price)):message("Not enough Glimmers for these seeds.");return
 grant(id,1);message("Bought "+str(spec.name)+" seeds.");save()
func grant(id:String,count:int=1)->void:
 if not crops().has(id):return
 state().seeds[id]=mini(1000000,int(state().seeds.get(id,0))+count)
 if id not in state().seen:state().seen.append(id)
func plant(index:int,id:String)->void:
 if not allowed() or index<0 or index>=capacity() or not crops().has(id):return
 var s=state();var spec=crops()[id]
 if not s.beds[index].is_empty():message("Harvest this bed before planting again.");return
 if level()<int(spec.level):message("Requires Gardening level %d." % int(spec.level));return
 if int(s.seeds.get(id,0))<1:message("Find or buy this seed first.");return
 s.seeds[id]=int(s.seeds[id])-1
 var duration=maxf(60,float(spec.seconds)*(1-minf(.30,bonus("time",str(spec.family)))));var stamp=now()
 s.beds[index]={"seed":id,"start":stamp,"end":stamp+duration,"duration":duration};message("Planted "+str(spec.name)+". Grows in real time, even while you are away.");save()
func harvest(index:int)->void:
 if not allowed() or index<0 or index>=state().beds.size():return
 var b:Dictionary=state().beds[index]
 if b.is_empty() or now()<float(b.end):message("This plant is still growing.");return
 var id=str(b.seed);var spec=crops()[id];var count=2+(1 if randf()<minf(.65,bonus("yield",str(spec.family))) else 0)
 state().beds[index]={};state().produce[id]=mini(1000000,int(state().produce.get(id,0))+count);state().harvests=int(state().harvests)+1
 var xp=int(round(float(spec.xp)*(1+minf(.6,bonus("xp",str(spec.family))))));xp_gain(xp)
 if randf()<minf(.50,.05+bonus("seed",str(spec.family))):grant(id)
 message("Harvested %d %s • +%d Gardening XP." % [count,spec.produce,xp]);save()
 var activity=legacy.get_tree().root.get_node_or_null("FXActivity")
 if activity!=null:activity.event(legacy.game,"garden_harvest","completed",0,{"garden_level":level(),"garden_xp":xp,"garden_yield":count,"garden_seconds":float(b.duration),"seed_id":id})
func use_produce(id:String,kind:String)->void:
 if not allowed() or not crops().has(id) or int(state().produce.get(id,0))<1:return
 var spec=crops()[id]
 if kind=="food":
  if str(spec.food).is_empty() or not legacy.game.provisions.packed.is_empty():message("Choose a food crop and empty your packed food slot first.");return
  legacy.game.provisions.packed=spec.food;legacy.game.provisions.paid=0;legacy.game.provisions.save()
 elif kind=="sell":
  if not legacy.glimmers.credit(int(round(float(spec.price)*(1+minf(.75,bonus("sell",str(spec.family))))))):message("Glimmer wallet is full.");return
 elif kind=="ingredients":
  var inventory=legacy.lodge_economy.state().ingredients;var key=str(spec.ingredient)
  inventory[key]=mini(100000,int(inventory.get(key,0))+1+(1 if randf()<minf(.8,bonus("ingredients",str(spec.family))) else 0))
 else:return
 state().produce[id]=int(state().produce[id])-1;message("Packed food." if kind=="food" else "Sold for Glimmers." if kind=="sell" else "Prepared ingredients for fish bait and existing potion recipes.");save()
func learn(id:String)->void:
 if not allowed() or not perks().has(id) or state().perks.has(id):return
 var p=perks()[id]
 if level()<int(p.level) or state().perks.size()>=mini(33,level()/3):message("Not enough mastery points, or Gardening level too low.");return
 if not prerequisites(p,state().perks):message("Learn a connected prerequisite first.");return
 for other in state().perks:
  if not str(p.group).is_empty() and str(perks()[other].group)==str(p.group):message("Choose one perk at this fork. Reset to change paths.");return
 state().perks[id]=true;save();message("Learned "+str(p.name)+".")
func reset_cost()->int:return 2000+state().perks.size()*100+int(state().resets)*500
func reset()->void:
 if not allowed() or state().perks.is_empty():return
 if not legacy.glimmers.debit(reset_cost()):message("Not enough Glimmers to reset mastery.");return
 state().perks={};state().resets=int(state().resets)+1;save();message("Gardening mastery reset. Active plants and XP stay safe.")
func find_seed(source:String,realm:String="",forced:bool=false)->String:
 if not allowed():return ""
 var chance=.20 if source=="elite" else .08 if source=="gather" else .012
 var choices=[]
 for id in crops():
  var p=crops()[id]
  if p.source==source and (source!="realm" or p.realm==realm) and int(p.level)<=mini(100,level()+20):choices.append(id)
 if choices.is_empty():return ""
 var id=str(choices.pick_random())
 if not forced and randf()>=minf(.45,chance*(1+bonus("hunt",str(crops()[id].family)))):return ""
 grant(id);save();message("SEED DISCOVERED • "+str(crops()[id].name));return id
func open()->void:legacy.open_page("gardening")
func build(parent:Node)->void:preload("res://scripts/garden_ui.gd").build(self,parent)
func step(delta:float)->void:
 tick+=delta
 if tick<1:return
 tick=0
 for entry in labels:
  if is_instance_valid(entry.label):entry.label.text=bed_text(int(entry.index))
func bed_text(index:int)->String:
 var b:Dictionary=state().beds[index]
 if b.is_empty():return "Empty • plant one owned seed" if index<capacity() else "Locked • grows with your Gardening level"
 var remaining=maxf(0,float(b.end)-now())
 return str(crops()[b.seed].name)+" • "+("READY TO HARVEST" if remaining<=0 else duration(remaining)+" remaining • grows while away")
static func duration(seconds:float)->String:
 if seconds>=86400:return "%.1f days" % (seconds/86400)
 if seconds>=3600:return "%.1f hours" % (seconds/3600)
 return "%dm %02ds" % [int(seconds)/60,int(seconds)%60]
