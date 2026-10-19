extends RefCounted
const CLOCK=preload("res://scripts/town_clock_math.gd")
const UI=preload("res://scripts/garden_ui.gd")
const DAYS=604800
var garden_ref:WeakRef
var garden:RefCounted:
 get:return garden_ref.get_ref() if garden_ref!=null else null
var timer_label:Label
var progress_bar:ProgressBar
var harvest_button:Button
func setup(owner:RefCounted)->void:garden_ref=weakref(owner);state()
func state()->Dictionary:
 if not garden.legacy.data.has("giant_garden"):garden.legacy.data.giant_garden={"version":1,"active":{},"records":{},"seasons":{},"last":{}}
 return garden.legacy.data.giant_garden
static func civil(utc:float)->String:return Time.get_datetime_string_from_unix_time(int(utc+CLOCK.edmonton_offset(utc)))
func date()->String:return civil(garden.now()).substr(0,10)
func season()->String:return date().substr(0,7)
func crop()->String:
 var month=int(date().substr(5,2))
 for id in garden.crops():
  if int(garden.crops()[id].get("month",0))==month:return id
 return ""
func start()->void:
 if not garden.allowed() or not state().active.is_empty():return
 var id=crop()
 if id.is_empty():return
 var spec=garden.crops()[id];var at=garden.now();var b=minf(.2,garden.bonus("yield",spec.family)*.5+garden.bonus("ingredients",spec.family)*.25+garden.bonus("seed",spec.family)*.15)
 garden.grant(id);garden.state().seeds[id]=int(garden.state().seeds[id])-1
 state().active={"seed":id,"start":at,"end":at+DAYS,"season":season(),"care":{},"roll":randf_range(.85,1.15),"perk":b}
 garden.message("Planted "+str(spec.name)+" in the fair plot. Return daily to help it grow larger.");garden.save()
func compost_id()->String:
 for id in garden.state().produce:
  if int(garden.state().produce[id])>0 and str(garden.crops()[id].get("rarity","Common")) in ["Common","Uncommon"]:return id
 return ""
func tend(compost:bool=false)->void:
 var a:Dictionary=state().active
 if not garden.allowed() or a.is_empty():return
 if garden.now()>=float(a.end):garden.message("Ready to harvest. Daily care is finished.");return
 if a.care.has(date()) or a.care.size()>=7:garden.message("Already tended today. Come back tomorrow.");return
 if compost:
  var id=compost_id()
  if id.is_empty():garden.message("Compost needs one Common or Uncommon harvested item. Free daily care is always available.");return
  garden.state().produce[id]=int(garden.state().produce[id])-1
 a.care[date()]=.08 if compost else .06;garden.message("Daily care complete • "+("+8% size with compost" if compost else "+6% size"));garden.save()
func size_bonus(a:Dictionary)->float:
 var total=float(a.perk)
 for value in a.care.values():total+=float(value)
 return total
func harvest()->void:
 var a:Dictionary=state().active
 if not garden.allowed() or a.is_empty():return
 if garden.now()<float(a.end):garden.message("This giant crop needs seven real days.");return
 var id=str(a.seed);var spec=garden.crops()[id];var kg=snappedf(float(spec.base_kg)*float(a.roll)*(1+size_bonus(a)),.001);var s=state();var record={"crop":id,"kg":kg,"care":a.care.size(),"season":a.season}
 s.active={};s.last=record;s.records[id]=maxf(float(s.records.get(id,0)),kg)
 if kg>float(s.seasons.get(a.season,{}).get("kg",0)):s.seasons[a.season]={"crop":id,"kg":kg}
 var keys=s.seasons.keys();keys.sort()
 while keys.size()>24:s.seasons.erase(keys.pop_front())
 garden.state().produce[id]=mini(1000000,int(garden.state().produce.get(id,0))+1);garden.state().harvests=int(garden.state().harvests)+1;garden.xp_gain(int(spec.xp));garden.legacy.community.delay=1;garden.save();garden.message("GROWERS FAIR • %s • %.3f kg • +%d Gardening XP" % [spec.name,kg,int(spec.xp)])
 var activity=garden.legacy.get_tree().root.get_node_or_null("FXActivity")
 if activity!=null:activity.event(garden.legacy.game,"garden_harvest","completed",0,{"garden_level":garden.level(),"garden_xp":int(spec.xp),"garden_yield":1,"garden_seconds":DAYS,"garden_fair_kg":kg,"seed_id":id})
func payload()->Array:
 var result=[]
 for id in state().records:result.append({"scope":"all","crop":id,"kg":float(state().records[id])})
 for key in state().seasons:
  var r=state().seasons[key];result.append({"scope":key,"crop":r.crop,"kg":float(r.kg)})
 return result
static func month_valid(value:Variant)->bool:
 return value is String and value.length()==7 and value.substr(4,1)=="-" and value.substr(0,4).is_valid_int() and value.substr(5,2).is_valid_int() and int(value.substr(0,4))>=2020 and int(value.substr(0,4))<=2100 and int(value.substr(5,2))>=1 and int(value.substr(5,2))<=12
static func day_valid(value:Variant)->bool:
 if not value is String or value.length()!=10 or not month_valid(value.substr(0,7)) or value.substr(7,1)!="-" or not value.substr(8,2).is_valid_int():return false
 var stamp=Time.get_unix_time_from_datetime_string(value+"T00:00:00")
 return Time.get_date_string_from_unix_time(stamp)==value
static func positive(v:Variant,max_value:float)->bool:return (v is float or v is int) and is_finite(float(v)) and float(v)>0 and float(v)<=max_value
static func crop_valid(id:Variant)->bool:return id is String and load("res://scripts/gardening.gd").crops().has(id) and load("res://scripts/gardening.gd").crops()[id].get("source")=="seasonal"
static func record_valid(r:Variant,scope:String)->bool:
 return r is Dictionary and crop_valid(r.get("crop")) and positive(r.get("kg"),float(load("res://scripts/gardening.gd").crops()[r.crop].base_kg)*4) and (scope=="all" or month_valid(scope) and int(scope.substr(5,2))==int(load("res://scripts/gardening.gd").crops()[r.crop].month))
static func valid(v:Variant)->bool:
 if not v is Dictionary or v.size()!=5 or v.get("version")!=1 or not v.get("active") is Dictionary or not v.get("records") is Dictionary or v.records.size()>12 or not v.get("seasons") is Dictionary or v.seasons.size()>24 or not v.get("last") is Dictionary:return false
 for id in v.records:
  if not record_valid({"crop":id,"kg":v.records[id]},"all"):return false
 for key in v.seasons:
  if not key is String or not record_valid(v.seasons[key],key):return false
 if not v.last.is_empty() and (not record_valid(v.last,str(v.last.get("season",""))) or not v.last.get("care") is int and not v.last.get("care") is float or float(v.last.care)<0 or float(v.last.care)>7 or float(v.last.care)!=floor(float(v.last.care))):return false
 var a:Dictionary=v.active
 if a.is_empty():return true
 if a.size()!=7 or not crop_valid(a.get("seed")) or not month_valid(a.get("season")) or int(a.season.substr(5,2))!=int(load("res://scripts/gardening.gd").crops()[a.seed].month):return false
 if not positive(a.get("start"),4101840000) or not positive(a.get("end"),4102444800) or not is_equal_approx(float(a.end)-float(a.start),DAYS):return false
 if civil(float(a.start)).substr(0,7)!=a.season or not positive(a.get("roll"),1.15) or float(a.roll)<.85 or not (a.get("perk") is int or a.get("perk") is float) or not is_finite(float(a.perk)) or float(a.perk)<0 or float(a.perk)>.2:return false
 if not a.get("care") is Dictionary or a.care.size()>7:return false
 for day in a.care:
  if not day_valid(day) or day<civil(float(a.start)).substr(0,10) or day>civil(float(a.end)-1).substr(0,10) or not (a.care[day] is int or a.care[day] is float) or not (is_equal_approx(float(a.care[day]),.06) or is_equal_approx(float(a.care[day]),.08)):return false
 return true
func build(parent:Node)->void:
 var id=crop();var spec=garden.crops()[id];UI.label(parent,"GIANT GROWERS FAIR • "+str(spec.name).to_upper(),22)
 UI.label(parent,"One dedicated plot • 7 real days • a different crop each month",15)
 var card=preload("res://scripts/studio_ui.gd").card(parent,"YOUR FAIR PLOT","");var a:Dictionary=state().active
 if a.is_empty():
  UI.button(card,"Plant this month’s "+str(spec.name)+" • seed provided",func():start();garden.legacy.render()).disabled=not garden.allowed();UI.icon(card,id,2,Vector2(160,125))
 else:
  var layout=HBoxContainer.new();card.add_child(layout)
  UI.icon(layout,str(a.seed),3 if garden.now()>=float(a.end) else 2 if garden.now()-float(a.start)>259200 else 1,Vector2(160,140))
  var details=VBoxContainer.new();details.size_flags_horizontal=Control.SIZE_EXPAND_FILL;layout.add_child(details)
  UI.label(details,str(garden.crops()[a.seed].name),20);timer_label=UI.label(details,"");progress_bar=ProgressBar.new();progress_bar.show_percentage=false;details.add_child(progress_bar)
  var row=HFlowContainer.new();details.add_child(row)
  UI.button(row,"Tend today • free",func():tend();garden.legacy.render()).disabled=a.care.has(date()) or garden.now()>=float(a.end) or not garden.allowed()
  UI.button(row,"Tend with compost",func():tend(true);garden.legacy.render()).disabled=a.care.has(date()) or garden.now()>=float(a.end) or not garden.allowed()
  harvest_button=UI.button(row,"Harvest giant crop",func():harvest();garden.legacy.render());step()
  UI.label(details,"%d / 7 daily visits • +%.0f%% size from care & planting mastery" % [a.care.size(),size_bonus(a)*100],16)
  if not garden.note.is_empty():UI.label(details,garden.note,15).modulate=Color("#efd08c")
 UI.label(card,"Free daily care adds 6% size. Compost uses one Common or Uncommon harvested item for 8% instead. Up to seven visits; missing a day never ruins the crop. Yield, ingredient and seed mastery contribute up to 20% when planted. Ordinary growth-time perks do not shorten the seven days.",16)
 UI.label(card,"Size also varies naturally. Harvest earns 24,000 Gardening XP and one usable produce. Monthly records follow the planting month (Edmonton time).",15)
 if not state().last.is_empty():UI.label(parent,"Last harvest: %s • %.3f kg" % [garden.crops()[state().last.crop].name,float(state().last.kg)],20)
 UI.button(parent,"View community garden records",func():garden.legacy.community.category="garden";garden.legacy.community.open())
 UI.label(parent,"THE YEAR AHEAD",20)
 var grid=GridContainer.new();grid.columns=3;parent.add_child(grid)
 for key in garden.crops():
  var entry=garden.crops()[key]
  if entry.source!="seasonal":continue
  var month=preload("res://scripts/studio_ui.gd").card(grid,"%02d • %s" % [int(entry.month),entry.name],"7 days • base %.2f kg" % float(entry.base_kg));month.get_parent().custom_minimum_size.x=270;UI.icon(month,key,3,Vector2(120,90))
func step()->void:
 if not is_instance_valid(timer_label) or state().active.is_empty():return
 var a:Dictionary=state().active;var remaining=maxf(0,float(a.end)-garden.now());timer_label.text="READY TO HARVEST" if remaining<=0 else garden.duration(remaining)+" remaining • grows while you are away";progress_bar.value=clampf(100*(garden.now()-float(a.start))/DAYS,0,100)
 if is_instance_valid(harvest_button):harvest_button.disabled=remaining>0 or not garden.allowed()
