extends RefCounted
## Catch odds are relative weights within the selected water, not a promise of a rare catch.
static var cached:Dictionary={}
static func data()->Dictionary:
 if cached.is_empty():cached=JSON.parse_string(FileAccess.get_file_as_string("res://content/fishing.json"))
 return cached
static func fish()->Dictionary:return data().fish
static func pools()->Dictionary:return data().pools
static func spots(region:String)->Array:
 var result:Array=[]
 for id in pools():
  if str(pools()[id].region)==region:
   var spot:Dictionary=pools()[id].duplicate();spot.id=id;result.append(spot)
 return result
static func texture(id:String)->Texture2D:return preload("res://scripts/source_art.gd").texture("res://assets/fishing/"+id+".svg")
static func roll(pool:String,rng:RandomNumberGenerator)->Dictionary:
 if not pools().has(pool):return {}
 var ids:Array=pools()[pool].fish;var total=0.0
 for id in ids:total+=float(fish()[id].chance)
 var choice=rng.randf_range(0,total);var picked=str(ids.back())
 for id in ids:
  choice-=float(fish()[id].chance)
  if choice<=0:picked=str(id);break
 var spec:Dictionary=fish()[picked]
 # Species and size are independent: even an everyday fish can be a trophy.
 var trophy=rng.randf()<.025
 var weight=lerpf(float(spec.min_kg),float(spec.max_kg),pow(rng.randf(),1.5))*(rng.randf_range(2.1,4.0) if trophy else 1.0)
 var length=clampf(float(spec.max_length)*pow(weight/(float(spec.max_kg)*4),.32),8,900)
 return {"id":"%d-%d" % [Time.get_ticks_usec(),rng.randi()],"species":picked,"kg":snappedf(weight,.01),"cm":snappedf(length,.1),"trophy":trophy,"pool":pool,"date":Time.get_date_string_from_system(false)}

static func typical_kg(id:String)->float:
 var spec:Dictionary=fish().get(id,{})
 if spec.is_empty():return 0
 # Median of the ordinary size distribution used by roll(), not species rarity.
 return lerpf(float(spec.min_kg),float(spec.max_kg),pow(.5,1.5))
static func size_percentile(id:String,kg:float)->float:
 var spec:Dictionary=fish().get(id,{})
 if spec.is_empty():return 0
 var low:float=float(spec.min_kg);var span:float=maxf(.001,float(spec.max_kg)-low)
 var ordinary:float=pow(clampf((kg-low)/span,0,1),2.0/3.0)
 var trophy:=0.0
 # Integrate the 2.5% trophy multiplier branch, whose multiplier is uniform.
 for n in 64:
  var multiplier:float=lerpf(2.1,4.0,(n+.5)/64.0)
  trophy+=pow(clampf((kg/multiplier-low)/span,0,1),2.0/3.0)/64
 return (ordinary*.975+trophy*.025)*100
static func size_summary(catch:Dictionary)->String:
 var id:String=str(catch.get("species",""));var middle:float=typical_kg(id)
 if middle<=0:return ""
 var percentile:float=size_percentile(id,float(catch.kg))
 var rank:String="Small" if percentile<25 else "Typical" if percentile<75 else "Large" if percentile<95 else "Exceptional"
 return "%s size • %.0f%% of a typical catch\nTypical (middle-sized): %.2f kg\nHeavier than about %.0f%% of this species' catches" % [rank,float(catch.kg)/middle*100,middle,percentile]
static func display_size(catch:Dictionary)->Vector2:
 # Actual caught length drives scale across species and within a species.
 return Vector2(115,65)*clampf(float(catch.get("cm",30))/55.0,.32,1.13)
