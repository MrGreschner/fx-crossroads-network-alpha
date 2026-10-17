extends Node
## Anonymous minute summaries and explicit completion events. Solo simulation remains local.
const BRAND=preload("res://scripts/brand.gd")
const MAX_QUEUE=12
var endpoint=BRAND.insights_http()
var enabled=true
var device=""
var profile=""
var session=""
var focused=true
var last_input=0.0
var request:HTTPRequest
var queue:Array=[]
var retry_at=0.0
var current:Dictionary={}
var elapsed=0.0
var active_seconds=0.0
var sample_timer=0.0
var stats:Dictionary={}
var seen:Dictionary={}
var last_frame=0.0
var dashboard:CanvasLayer
var status="Waiting for play"
var sent=0
var dropped=0
func identifier()->String:return Crypto.new().generate_random_bytes(16).hex_encode()
func valid_id(value:String)->bool:
 if value.length()!=32:return false
 for c in value:
  if not c in "0123456789abcdef":return false
 return true
func clock()->float:return Time.get_ticks_msec()/1000.0
func _ready()->void:
 var config=ConfigFile.new()
 if endpoint.is_empty() and config.load("user://crossroads_service.cfg")==OK:endpoint=str(config.get_value("reports","endpoint",""))
 var value=preload("res://scripts/profile_store.gd").read("user://fx_activity_device.json")
 enabled=bool(value.get("enabled",true));web_enabled();device=str(value.get("id",""))
 if not valid_id(device):device=identifier()
 preload("res://scripts/profile_store.gd").write("user://fx_activity_device.json",{"id":device,"enabled":enabled})
 last_input=clock();reset_stats()
func current_game()->Node:
 var game=get_tree().current_scene
 if not is_instance_valid(game):return null
 var nested=game.get("game")
 if typeof(nested)==TYPE_OBJECT:
  return nested if is_instance_valid(nested) and nested is Node else null
 return game
func game_dev()->bool:
 var dev=get_tree().root.get_node_or_null("FXDevSession")
 return dev!=null and dev.active
func allowed(game:Node=null)->bool:
 if endpoint.is_empty() or not enabled or game_dev() or preload("res://scripts/profile_store.gd").progression_blocked() or get_tree().root.has_meta("fx_dedicated_server"):return false
 if game==null:game=current_game()
 return is_instance_valid(game) and is_instance_valid(game.get("legacy")) and not bool(game.legacy.data.get("teacher",false))
func _input(event:InputEvent)->void:
 if event is InputEventMouse or event is InputEventKey or event is InputEventScreenTouch or event is InputEventScreenDrag:last_input=clock()
func _notification(what:int)->void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
  flush("interval");focused=false
 if what==NOTIFICATION_APPLICATION_FOCUS_IN:focused=true;last_input=clock();last_frame=0
func safe_key(value:Variant)->String:
 var key=str(value)
 if key.begins_with("custom"):return "custom"
 if key.length()>64:return ""
 for c in key:
  if not c in "abcdefghijklmnopqrstuvwxyz0123456789_-":return ""
 return key
func identity(game:Node)->void:
 var id=str(game.legacy.data.get("analytics_id",""))
 if not valid_id(id):id=identifier();game.legacy.data.analytics_id=id;game.legacy.save()
 if id==profile:return
 flush("interval");profile=id;session=identifier();current={};seen.clear();reset_stats()
func context(game:Node)->Dictionary:
 var mode=str(game.get("mode"));var realm=game.get("region_id")
 if realm==null:realm=game.get("realm_id")
 var hero=game.get("selected_character")
 if hero==null:hero=game.get("selected_hero")
 var category=classification(game)
 if game.get("gateway")!=null:return {}
 var route="dedicated" if game.get("net_ready")!=null else "legacy" if game.get("shop_open")!=null else "solo"
 if route=="dedicated" and not bool(game.get("started")):category="menu"
 return {"category":category,"mode":safe_key(mode),"realm":safe_key(realm),"hero":safe_key(hero),"route":route}
func classification(game:Node)->String:
 var expedition=game.get("expedition")
 if expedition!=null and expedition.special() and game.get("started")==true:return "overcharge" if expedition.kind=="overcharge" else "between"
 var legacy=game.get("legacy")
 if legacy!=null:
  if is_instance_valid(legacy.mine.view) and legacy.mine.view.active:return "mine"
  if is_instance_valid(legacy.commerce.view) and legacy.commerce.view.active:return "market"
 var fishing=game.get("fishing")
 if fishing!=null and fishing.busy():return "fishing"
 var menu=str(game.get("menu")) if game.get("shop_open")==null else str(game.get("shop_open"))
 if "workshop" in menu or "studio" in menu:return "studio"
 if "fishing" in menu:return "fishing"
 if game.get("waylight")!=null and game.waylight.active():return "between" if game.waylight.between() else "overcharge"
 if menu not in ["","<null>"]:return "menu"
 if game.get("started")!=null and not bool(game.started):return "menu"
 var mode=str(game.get("mode"))
 return "realm" if mode in ["run","coop"] else mode if mode in ["town","arena","defense","descent","battlegrounds","quest"] else "menu"
func reset_stats()->void:
 stats={"count":0,"fps_sum":0.0,"fps_min":1000.0,"fps_max":0.0,"below_50":0,"below_40":0,"frame_max_ms":0.0,"draw_max":0,"video_max_bytes":0,"rtt_max_ms":0.0,"rtt_sum_ms":0.0};elapsed=0;active_seconds=0;sample_timer=0
func _process(delta:float)->void:
 var game=current_game()
 if not allowed(game):
  if enabled:flush("interval")
  current={};reset_stats();clear_web_packet();return
 identity(game)
 var next=context(game)
 if next!=current:
  flush("interval");current=next;reset_stats()
 if focused:
  var step=minf(maxf(delta,0),1.0);elapsed+=step
  if Input.is_anything_pressed() or clock()-last_input<120:active_seconds+=step
  sample_timer+=step;stats.frame_max_ms=maxf(float(stats.frame_max_ms),minf(delta*1000,60000))
  if sample_timer>=1:
   sample_timer=0;sample(game)
  if elapsed>=60:flush("interval")
 pump()
func sample(game:Node)->void:
 var fps=clampf(float(Engine.get_frames_per_second()),0,1000);stats.count+=1;stats.fps_sum+=fps;stats.fps_min=minf(stats.fps_min,fps);stats.fps_max=maxf(stats.fps_max,fps)
 if fps<50:stats.below_50+=1
 if fps<40:stats.below_40+=1
 stats.draw_max=maxi(stats.draw_max,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
 stats.video_max_bytes=maxi(stats.video_max_bytes,int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)))
 var metrics=game.get("metrics");var rtt=float(metrics.get("rtt_ms",0)) if metrics is Dictionary else 0
 stats.rtt_max_ms=maxf(stats.rtt_max_ms,rtt);stats.rtt_sum_ms+=rtt
func packet(kind:String,result:String="",duration:float=0,metrics:Dictionary={})->Dictionary:
 var count=maxi(1,int(stats.count));var p={"version":1,"event":identifier(),"session":session,"profile":profile,"device":device,"build":BRAND.BUILD,"release":preload("res://network/release.gd").BUILD,"platform":"web" if OS.has_feature("web") else "mobile" if OS.get_name() in ["Android","iOS"] else "desktop","kind":kind,"result":result,"duration":clampf(duration,0,604800),"seconds":clampf(elapsed,0,90),"active":clampf(active_seconds,0,minf(elapsed,90)),"stats":{"samples":stats.count,"fps_mean":stats.fps_sum/count,"fps_min":stats.fps_min if int(stats.count)>0 else 0,"fps_max":stats.fps_max,"below_50":stats.below_50,"below_40":stats.below_40,"frame_max_ms":stats.frame_max_ms,"draw_max":stats.draw_max,"video_max_bytes":stats.video_max_bytes,"rtt_mean_ms":stats.rtt_sum_ms/count,"rtt_max_ms":stats.rtt_max_ms},"metrics":metrics}
 p.merge(current);return p
func flush(kind:String="interval")->void:
 if current.is_empty() or elapsed<.5 or not enabled:return
 enqueue(packet(kind));reset_stats()
func enqueue(p:Dictionary)->void:
 if queue.size()>=MAX_QUEUE:queue.pop_front();dropped+=1
 queue.append(p);status="Queued"
 if OS.has_feature("web"):JavaScriptBridge.eval("window.fxAnonymousActivity="+JSON.stringify({"endpoint":endpoint,"packet":p})+";",true)
func event(game:Node,kind:String,result:String="",duration:float=0,metrics:Dictionary={},key:String="")->bool:
 if not allowed(game):return false
 identity(game)
 if not key.is_empty() and seen.has(key):return false
 if not key.is_empty():
  seen[key]=true
  if seen.size()>128:seen.erase(seen.keys()[0])
 var old=current;current=context(game)
 var p=packet(kind,result,duration,metrics);p.seconds=0;p.active=0;enqueue(p);current=old;return true
func pump()->void:
 if request!=null or queue.is_empty() or clock()<retry_at or not enabled:return
 request=HTTPRequest.new();request.timeout=6;request.body_size_limit=8192;add_child(request)
 var id=str(queue[0].event);var ref=request
 request.request_completed.connect(func(_result,code,_headers,_body):
  ref.queue_free();request=null
  if not queue.is_empty() and str(queue[0].event)==id:
   if code in [200,201,400,413]:queue.pop_front()
   if code in [200,201]:sent+=1;status="Saved"
   else:status="Offline / unavailable";retry_at=clock()+30)
 if request.request(endpoint+"/activity/ingest",["Content-Type: application/json"],HTTPClient.METHOD_POST,JSON.stringify(queue[0]))!=OK:
  request.queue_free();request=null;retry_at=clock()+30;status="Offline / unavailable"
func set_enabled(value:bool)->void:
 enabled=value;web_enabled();queue.clear();current={};reset_stats();clear_web_packet()
 if request!=null:request.cancel_request();request.queue_free();request=null
 preload("res://scripts/profile_store.gd").write("user://fx_activity_device.json",{"id":device,"enabled":enabled})
func clear_web_packet()->void:
 if OS.has_feature("web"):JavaScriptBridge.eval("window.fxAnonymousActivity=null;",true)
func open_dashboard()->void:
 if not game_dev():return
 if is_instance_valid(dashboard):dashboard.queue_free()
 dashboard=preload("res://scripts/activity_dashboard.gd").new();add_child(dashboard);dashboard.setup(self)

func web_enabled()->void:
 if OS.has_feature("web"):JavaScriptBridge.eval("window.fxAnonymousActivityEnabled="+("true" if enabled else "false")+";if(window.fxReports)window.fxReports.set_enabled("+("true" if enabled else "false")+");",true)

func configure_endpoint(value:String)->bool:
 var url=value.strip_edges().replace("wss://","https://").replace("ws://","http://").trim_suffix("/")
 if not url.begins_with("https://") and not url.begins_with("http://127.0.0.1:"):return false
 if "@" in url or "\n" in url or "\r" in url or url.length()>256:return false
 endpoint=url
 var config=ConfigFile.new();config.set_value("reports","endpoint",url);config.save("user://crossroads_service.cfg")
 return true
