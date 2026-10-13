extends Node
## Anonymous, bounded activity estimates. Never uploads names, designs or student work.
var endpoint="https://fx-crossroads-rooms.onrender.com"
var enabled=true
var device=""
var profile=""
var session=""
var elapsed=0.0
var active_seconds=0.0
var last_input=0.0
var focused=true
var interval=5.0
var request:HTTPRequest
var dashboard:CanvasLayer
var was_dev=false
var was_frozen=false
var disconnects=0
func identifier()->String:return Crypto.new().generate_random_bytes(16).hex_encode()
func _ready()->void:
 var saved=JSON.parse_string(FileAccess.get_file_as_string("user://fx_activity_device.json")) if FileAccess.file_exists("user://fx_activity_device.json") else null
 enabled=bool(saved.get("enabled",true)) if saved is Dictionary else true
 device=str(saved.get("id","")) if saved is Dictionary else ""
 if not valid_id(device):
  device=identifier()
  var file=FileAccess.open("user://fx_activity_device.json",FileAccess.WRITE)
  if file!=null:file.store_string(JSON.stringify({"id":device}))
 last_input=Time.get_ticks_msec()/1000.0
func valid_id(value:String)->bool:
 if value.length()!=32:return false
 for c in value:if not c in "0123456789abcdef":return false
 return true
func _input(event:InputEvent)->void:
 if event is InputEventMouse or event is InputEventKey or event is InputEventScreenTouch or event is InputEventScreenDrag:last_input=Time.get_ticks_msec()/1000.0
func _notification(what:int)->void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:focused=false
 if what==NOTIFICATION_APPLICATION_FOCUS_IN:focused=true;last_input=Time.get_ticks_msec()/1000.0
func game_dev()->bool:
 var node=get_tree().root.get_node_or_null("FXDevSession")
 return node!=null and node.active
func _process(dt:float)->void:
 if game_dev():
  if not was_dev:clear_web_packet()
  elapsed=0;active_seconds=0;was_dev=true
  return
 if was_dev:
  was_dev=false;session="";profile="";interval=5
  if is_instance_valid(dashboard):dashboard.queue_free();dashboard=null
 if not enabled:return
 var game=get_tree().current_scene
 if game==null:return
 var legacy=game.get("legacy")
 if legacy==null or legacy.data.is_empty():return
 var current=str(legacy.data.get("analytics_id",""))
 if not valid_id(current):current=identifier();legacy.data["analytics_id"]=current;legacy.save()
 if current!=profile:profile=current;session=identifier();elapsed=0;active_seconds=0;interval=5
 if not focused:return
 var step=minf(dt,1.0)
 elapsed+=step
 if Input.is_anything_pressed() or Time.get_ticks_msec()/1000.0-last_input<120:active_seconds+=step
 var recovery=game.get("recovery")
 var frozen=bool(recovery.frozen) if recovery!=null else false
 if frozen and not was_frozen:disconnects=1
 was_frozen=frozen
 if elapsed>=interval:
  send(game);elapsed=0;active_seconds=0;disconnects=0;interval=60
func classification(game:Node)->String:
 var menu=str(game.get("menu"))
 if game.get("shop_open")!=null:menu=str(game.get("shop_open"))
 var fishing=game.get("fishing")
 if fishing!=null and fishing.busy():return "fishing"
 var legacy=game.get("legacy")
 if legacy!=null:
  if is_instance_valid(legacy.mine.view) and legacy.mine.view.active:return "mine"
  if is_instance_valid(legacy.commerce.view) and legacy.commerce.view.active:return "market"
 if "workshop" in menu or "studio" in menu:return "studio"
 if menu=="commerce":return "market"
 if "mine" in menu:return "mine"
 if "fishing" in menu:return "fishing"
 if not menu.is_empty() and menu!="<null>":return "menu"
 if game.get("started")!=null and not game.get("started"):return "menu"
 var mode=str(game.get("mode"))
 if mode=="run" or mode=="coop":return "realm"
 if mode in ["descent","defense","arena","battlegrounds","quest","town"]:return mode
 return "menu"
func safe_key(value:Variant)->String:
 var key=str(value)
 if key.begins_with("custom"):return "custom"
 if key.length()>64:return ""
 for c in key:if not c in "abcdefghijklmnopqrstuvwxyz0123456789_-":return ""
 return key
func send(game:Node)->void:
 var hero=game.get("selected_character")
 if hero==null:
  hero=game.get("selected_hero")
  var heroes=game.get("hero_ids")
  if heroes is Dictionary:hero=heroes.get(game.get("my_id"),hero)
 var realm=game.get("region_id")
 if realm==null:realm=game.get("realm_id")
 var seconds=mini(90,int(elapsed))
 var packet={"event":identifier(),"session":session,"profile":profile,"device":device,"category":classification(game),"hero":safe_key(hero),"realm":safe_key(realm),"build":165,"platform":"web" if OS.has_feature("web") else ("mobile" if OS.get_name() in ["Android","iOS"] else "desktop"),"seconds":seconds,"active":mini(seconds,int(active_seconds)),"disconnects":disconnects,"graphics":0}
 if OS.has_feature("web"):JavaScriptBridge.eval("window.fxAnonymousActivity="+JSON.stringify({"endpoint":endpoint,"packet":packet})+";",true)
 if is_instance_valid(request):return
 request=HTTPRequest.new();request.timeout=8;request.body_size_limit=4096;add_child(request)
 request.request_completed.connect(func(_result,_code,_headers,_body):request.queue_free();request=null)
 if request.request(endpoint+"/analytics/event",["Content-Type: application/json"],HTTPClient.METHOD_POST,JSON.stringify(packet))!=OK:request.queue_free();request=null
func open_dashboard()->void:
 if not game_dev():return
 if is_instance_valid(dashboard):dashboard.queue_free()
 dashboard=preload("res://scripts/activity_dashboard.gd").new();add_child(dashboard);dashboard.setup(self)

func clear_web_packet()->void:
 if OS.has_feature("web"):JavaScriptBridge.eval("window.fxAnonymousActivity=null;",true)
func set_enabled(value:bool)->void:
 enabled=value;elapsed=0;active_seconds=0;interval=5;session="";profile="";clear_web_packet()
 var file=FileAccess.open("user://fx_activity_device.json",FileAccess.WRITE)
 if file!=null:file.store_string(JSON.stringify({"id":device,"enabled":enabled}))
