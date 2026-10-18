extends RefCounted
## Anonymous portable-profile rankings. Server awards are short-lived and never saved as unlocks.
const IDS=["rank_week_damage","rank_week_fish","rank_all_damage"]
const CLOCK=preload("res://scripts/town_clock_math.gd")
var legacy:Node
var request:HTTPRequest
var snapshot:Dictionary={}
var busy:=false
var live_until:=0
var delay:=4.0
var server_offset:=0.0
var server_week=""
var week_start:=0.0
var week_end:=0.0
var status:="Connect to compare your profile"
var endpoint=""
var time_for_test:=-1.0
func now()->float:return time_for_test if time_for_test>=0 else Time.get_unix_time_from_system()+server_offset
static func week_at(utc:float)->String:
 var day=int(floor((utc+CLOCK.edmonton_offset(utc))/86400.0))
 return Time.get_date_string_from_unix_time((day-posmod(day+3,7))*86400)
func week()->String:return server_week if not server_week.is_empty() and now()>=week_start and now()<week_end else week_at(now())
func state()->Dictionary:
 if not legacy.data.has("cosmetic_rankings"):legacy.data.cosmetic_rankings={"version":1,"fish_week":week(),"fish":0.0,"fish_species":"","enabled":IDS.duplicate()}
 var s:Dictionary=legacy.data.cosmetic_rankings
 if str(s.fish_week)!=week():s.fish_week=week();s.fish=0.0;s.fish_species=""
 return s
static func valid(v:Variant)->bool:
 if not v is Dictionary or v.get("version")!=1 or not v.get("fish_week") is String or v.fish_week.length()!=10 or not v.get("enabled") is Array or v.enabled.size()>3:return false
 if not (v.get("fish") is int or v.get("fish") is float) or not is_finite(float(v.fish)) or float(v.fish)<0 or float(v.fish)>10000:return false
 if not v.get("fish_species") is String:return false
 if float(v.fish)>0:
  var fish=preload("res://scripts/fishing_catalog.gd").fish()
  if not fish.has(v.fish_species) or float(v.fish)>float(fish[v.fish_species].max_kg)*4+.01:return false
 var seen=[]
 for id in v.enabled:
  if id not in IDS or id in seen:return false
  seen.append(id)
 return true
func setup(owner:Node)->void:
 legacy=owner;state();delay=4+randf()*8
 endpoint=preload("res://scripts/brand.gd").network_url().replace("wss://","https://").replace("ws://","http://").trim_suffix("/")+"/cosmetics/sync"
 request=HTTPRequest.new();request.timeout=8;request.body_size_limit=8192;legacy.add_child(request);request.request_completed.connect(received)
func allowed()->bool:
 return not preload("res://scripts/profile_store.gd").progression_blocked() and not bool(legacy.data.get("teacher",false)) and not legacy.get_tree().root.has_meta("fx_dedicated_server")
func weekly_damage()->float:
 var total=0.0;var current=now();var civil=Time.get_unix_time_from_datetime_string(week()+"T00:00:00")
 var start=week_start if week_start>0 and now()>=week_start and now()<week_end else civil-CLOCK.edmonton_offset(civil)
 for bucket in legacy.crowns.state().buckets:
  var at=float(bucket[0])*60
  if at>=start and at<=current:total+=float(bucket[1])
 return minf(total,1e12)
func scores()->Dictionary:
 var activity=legacy.get_tree().root.get_node("FXActivity");activity.identity(legacy.game)
 var lifetime=minf(float(legacy.data.tasks.get("damage",0)),1e12)
 return {"version":1,"profile":str(legacy.data.analytics_id),"week":week(),"lifetime":lifetime,"damage":minf(lifetime,weekly_damage()),"fish":float(state().fish),"fish_species":str(state().fish_species)}
func catch_fish(catch:Dictionary)->void:
 if not allowed():return
 if float(catch.kg)>float(state().fish):state().fish=float(catch.kg);state().fish_species=str(catch.species)
 delay=minf(delay,5)
func step(delta:float)->void:
 if not allowed():return
 delay-=delta
 if delay<=0:sync()
func sync()->void:
 if not allowed() or not is_instance_valid(request):return
 if busy:return
 delay=60;status="Comparing with the server…"
 var problem=request.request(endpoint,["Content-Type: application/json"],HTTPClient.METHOD_POST,JSON.stringify(scores()))
 busy=problem==OK
 if problem!=OK:status="Rankings unavailable • retry when connected";delay=30+randf()*10
func fresh()->bool:return Time.get_ticks_msec()<live_until and str(snapshot.get("week",""))==week() and allowed()
func badges()->Array:return snapshot.get("badges",[]) if fresh() else []
func enabled(id:String)->bool:return id in state().enabled
func toggle(id:String)->void:
 if id not in IDS:return
 if enabled(id):state().enabled.erase(id)
 else:state().enabled.append(id)
 legacy.save();notify()
func lobby_payload()->Dictionary:
 return {"rank_ticket":str(snapshot.get("rank_ticket","")) if fresh() else "","rank_enabled":state().enabled,"rank_badges":badges().filter(func(id):return enabled(str(id))),"rank_until":int(snapshot.get("expires",0)) if fresh() else 0,"rank_week":str(snapshot.get("week",""))}
func display_payload()->Dictionary:
 var value=lobby_payload();value.erase("rank_ticket");value.erase("rank_enabled");return value
func received(result:int,code:int,_headers:PackedStringArray,body:PackedByteArray)->void:
 busy=false
 var parsed=JSON.new();var data:Variant=null
 if not body.is_empty() and parsed.parse(body.get_string_from_utf8())==OK:data=parsed.data
 if data is Dictionary and data.get("server_time") is float:server_offset=float(data.server_time)-Time.get_unix_time_from_system()
 if data is Dictionary and data.get("week_start") is float and data.get("reset_at") is float and data.get("week") is String:
  week_start=float(data.week_start);week_end=float(data.reset_at);server_week=str(data.week)
 if result!=HTTPRequest.RESULT_SUCCESS or code!=200 or not data is Dictionary:
  status="Rankings unavailable • local cosmetics still work";delay=1 if code==409 else 30+randf()*10;return
 var found:Variant=data.get("badges",null)
 if not found is Array or found.size()>3 or not data.get("rank_ticket") is String or str(data.rank_ticket).length()>2048:return
 for id in found:
  if id not in IDS:return
 if not data.get("expires") is float or not data.get("server_time") is float or not data.get("ranks") is Dictionary:return
 snapshot=data;live_until=Time.get_ticks_msec()+int(clampf(float(data.expires)-float(data.server_time),0,90)*1000);status="Compared with connected profiles • refreshed every minute";delay=45+randf()*5;notify()
func notify()->void:
 var g=legacy.game
 legacy.cosmetics.notify()
 if legacy.arcade and g.get("net_ready")==true and not g.started:g.send_net({"type":"lobby_cosmetic","cosmetic":g.local_cosmetic()})
