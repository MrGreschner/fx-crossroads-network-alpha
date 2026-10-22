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
static func roll(pool:String,rng:RandomNumberGenerator,ctx:Dictionary={},method:String="rod",bait:String="basic",level:int=1,trophy_bonus:float=0,rarity_bonus:float=0)->Dictionary:
 ctx=ctx.duplicate();ctx.region="night_crater" if pool=="voyage_night_crater" else str(pools().get(pool,{}).get("region",""))
 if not pools().has(pool):return {}
 var ids:Array=[];var weights:Array=[];var total=0.0
 for id in pools()[pool].fish:
  var w=preload("res://scripts/fishing_ecology.gd").weight(fish()[id],ctx,method,bait,level,rarity_bonus)
  if w>0:ids.append(id);weights.append(w);total+=w
 if ids.is_empty():return {}
 var choice=rng.randf()*total;var picked=str(ids.back())
 for n in ids.size():
  choice-=weights[n]
  if choice<=0:picked=str(ids[n]);break
 var spec:Dictionary=fish()[picked]
 # Species and size are independent: even an everyday fish can be a trophy.
 var trophy=rng.randf()<(.025+trophy_bonus)
 var weight=rng.randf_range(trophy_min_kg(picked),float(spec.max_kg)*4) if trophy else lerpf(float(spec.min_kg),float(spec.max_kg),pow(rng.randf(),1.5))
 weight=snappedf(weight,.01)
 if trophy:weight=maxf(weight,trophy_threshold_kg(picked))
 var length=clampf(float(spec.max_length)*pow(weight/(float(spec.max_kg)*4),.32),8,900)
 return {"id":"%d-%d" % [Time.get_ticks_usec(),rng.randi()],"species":picked,"kg":snappedf(weight,.01),"cm":snappedf(length,.1),"trophy":weight+.0000001>=mean_kg(picked)*2.5,"size_version":2,"trophy_rate":.025+trophy_bonus,"pool":pool,"date":Time.get_date_string_from_system(false),"method":method,"bait":bait}

static func typical_kg(id:String)->float:
 var spec:Dictionary=fish().get(id,{})
 if spec.is_empty():return 0
 # Median of the ordinary size distribution used by roll(), not species rarity.
 return lerpf(float(spec.min_kg),float(spec.max_kg),pow(.5,1.5))
static func mean_kg(id:String)->float:
 var spec:Dictionary=fish().get(id,{})
 return lerpf(float(spec.get("min_kg",0)),float(spec.get("max_kg",0)),.4)
static func trophy_threshold_kg(id:String)->float:return ceil(mean_kg(id)*250-.0000001)/100.0
static func trophy_min_kg(id:String)->float:return maxf(mean_kg(id)*2.5,float(fish()[id].max_kg)*1.1)
static func is_trophy(catch:Dictionary)->bool:return fish().has(str(catch.get("species",""))) and float(catch.get("kg",0))+.0000001>=mean_kg(str(catch.species))*2.5
static func size_percentile(id:String,kg:float,rate:float=.025)->float:
 var spec:Dictionary=fish().get(id,{})
 if spec.is_empty():return 0
 var low:float=float(spec.min_kg);var span:float=maxf(.001,float(spec.max_kg)-low)
 var ordinary:float=pow(clampf((kg-low)/span,0,1),2.0/3.0)
 var trophy:float=clampf((kg-trophy_min_kg(id))/maxf(.001,float(spec.max_kg)*4-trophy_min_kg(id)),0,1)
 return (ordinary*(1-rate)+trophy*rate)*100
static func size_summary(catch:Dictionary)->String:
 var id:String=str(catch.get("species",""));var mean:float=mean_kg(id)
 if mean<=0:return ""
 var percentile:float=size_percentile(id,float(catch.kg),clampf(float(catch.get("trophy_rate",.025)),0,1))
 var rank:String="TROPHY" if is_trophy(catch) else "Small" if percentile<25 else "Typical" if percentile<75 else "Large" if percentile<95 else "Exceptional"
 return "%s size • %.0f%% of species average\nAverage ordinary catch: %.2f kg • Trophy: %.2f+ kg\nHeavier than about %.0f%% of catches (current size model)" % [rank,float(catch.kg)/mean*100,mean,trophy_threshold_kg(id),percentile]
static var display_cache:Dictionary={}
static func display_geometry(id:String)->Dictionary:
 if display_cache.is_empty():
  var parsed=JSON.parse_string(FileAccess.get_file_as_string("res://content/fish_display_geometry.json"))
  if parsed is Dictionary:display_cache=parsed.get("fish",{})
 return display_cache.get(id,{"rect":[0,0,256,144],"area":18432.0,"source":[256,144]})
static func display_region(catch:Dictionary)->Rect2:
 var g=display_geometry(str(catch.species));var r:Array=g.rect;var source:Array=g.source;var tex=texture(str(catch.species))
 var ratio=Vector2(tex.get_width()/float(source[0]),tex.get_height()/float(source[1]))
 return Rect2(Vector2(float(r[0]),float(r[1]))*ratio,Vector2(float(r[2]),float(r[3]))*ratio)
static func display_size(catch:Dictionary,shared_scale:float=48.0)->Vector2:
 # Visible painted area grows with mass^(2/3); one common scale preserves ordering.
 # Cropping transparent padding keeps a thin loach comparable with a deep-bodied salmon.
 var g=display_geometry(str(catch.species));var r:Array=g.rect
 var linear=pow(maxf(.000001,float(catch.get("kg",0))),1.0/3.0)/sqrt(maxf(1,float(g.area)))
 return Vector2(float(r[2]),float(r[3]))*linear*shared_scale
static func tank_scale(catches:Array,limit:Vector2=Vector2(128,96))->float:
 var shared=48.0
 for catch in catches:
  if not catch is Dictionary or catch.is_empty():continue
  var unit=display_size(catch,1.0)
  shared=minf(shared,minf(limit.x/maxf(.001,unit.x),limit.y/maxf(.001,unit.y)))
 return shared
