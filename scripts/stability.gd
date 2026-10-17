extends Node
## Local bounded diagnostics. Caps affect cosmetic queues, never combat logic.
const PATH="user://fx_stability.json"
const LAST="user://fx_last_session.json"
var school_mode:=OS.has_feature("web")
var fps_limit:=30 if OS.has_feature("web") else 60
var diagnostics_enabled:=true
var timer:=0.0
var samples:Array=[]
var previous:Dictionary={}
var interrupted:=false
var last_packet_bytes:=0
var packets_sent:=0
var buffered_bytes:=0
var deferred_states:=0
var send_errors:=0
var native_dialog:FileDialog
func _ready()->void:
 if FileAccess.file_exists(PATH):
  var saved:Variant=JSON.parse_string(FileAccess.get_file_as_string(PATH))
  if saved is Dictionary:
   school_mode=bool(saved.get("school_mode",school_mode));fps_limit=int(saved.get("fps_limit",30 if school_mode else 60));diagnostics_enabled=bool(saved.get("diagnostics_enabled",true))
   if fps_limit not in [30,60,120]:fps_limit=30 if school_mode else 60
 if FileAccess.file_exists(LAST):
  var saved:Variant=JSON.parse_string(FileAccess.get_file_as_string(LAST))
  if saved is Dictionary:previous=saved;interrupted=not bool(saved.get("ended",false))
 apply_mode()
 if OS.has_feature("web"):JavaScriptBridge.eval("window.fxDiagnosticsEnabled="+("true" if diagnostics_enabled else "false")+";"+FileAccess.get_file_as_string("res://web/diagnostics.js"),true)
 if diagnostics_enabled:capture()
func _process(delta:float)->void:
 var scene:=get_tree().current_scene
 if scene!=null:
  for key in ["effects","attack_effects","damage_labels","trails","sent_effects"]:
   var queue:Variant=scene.get(key)
   if queue is Array:trim(queue,48 if key=="damage_labels" else 24 if key=="trails" else 128 if key=="sent_effects" else 80)
 timer-=delta
 if timer<=0:
  timer=5.0
  if diagnostics_enabled:capture()
func trim(queue:Array,limit:int)->void:
 var cap:=limit if school_mode else limit*3
 # Preserve newest visual cues, discard oldest only.
 while queue.size()>cap:queue.pop_front()
func apply_mode()->void:
 Engine.max_fps=fps_limit
 get_tree().root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT if school_mode else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
func toggle()->void:
 school_mode=not school_mode;fps_limit=30 if school_mode else 60;apply_mode();save_settings()
func set_fps(value:int)->void:
 if value not in [30,60,120]:return
 fps_limit=value;apply_mode();save_settings()
func set_diagnostics(value:bool)->void:
 diagnostics_enabled=value;save_settings()
 if OS.has_feature("web"):JavaScriptBridge.eval("window.fxDiagnostics && window.fxDiagnostics.set_enabled("+("true" if value else "false")+");",true)
func save_settings()->void:
 var f:=FileAccess.open(PATH,FileAccess.WRITE)
 if f!=null:f.store_string(JSON.stringify({"school_mode":school_mode,"fps_limit":fps_limit,"diagnostics_enabled":diagnostics_enabled}))
func capture()->void:
 var scene:=get_tree().current_scene
 var sample:Dictionary={"time":Time.get_datetime_string_from_system(true),"fps":Engine.get_frames_per_second(),"memory_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),"draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),"video_memory_bytes":int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),"school_mode":school_mode,"fps_limit":fps_limit,"diagnostics_enabled":diagnostics_enabled,"packet_bytes":last_packet_bytes,"packets_sent":packets_sent,"max_buffered_bytes":buffered_bytes,"deferred_states":deferred_states,"send_errors":send_errors}
 sample.process_ms=Performance.get_monitor(Performance.TIME_PROCESS)*1000.0
 sample.physics_ms=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0
 sample.canvas_objects=int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
 sample.viewport_size=[get_tree().root.get_visible_rect().size.x,get_tree().root.get_visible_rect().size.y]
 if scene!=null:
  var cache:Variant=scene.get("terrain_cache")
  if cache!=null:sample.terrain_chunks=cache.chunks.size()
  sample.scene=scene.scene_file_path
  if scene.has_method("_close_link"):
   sample.network_links=scene.links.size();sample.incoming_backlog=scene.incoming_backlog;sample.received_packets=scene.received_packets
   sample.network_bytes_sent=scene.transport.sent_bytes;sample.stale_network_packets=scene.transport.stale;sample.deferred_realtime=scene.transport.deferred;sample.ping_ms=scene.transport.ping_ms;sample.smoothing_tracks=scene.smoothing.tracks.size();sample.raw_snapshot_bytes=scene.transport.raw_snapshot_bytes;sample.wire_snapshot_bytes=scene.transport.wire_snapshot_bytes;sample.partial_snapshots=scene.transport.assemblies.size()
  for key in ["mode","role","realm_id","region_id","wave","floor_number"]:
   var value:Variant=scene.get(key)
   if value!=null:sample[key]=value
  for key in ["opponents","enemies","effects","attack_effects","damage_labels","guards"]:
   var value:Variant=scene.get(key)
   if value is Array:sample[key]=value.size()
  if str(scene.get("mode"))=="battlegrounds":
   var bg:Variant=scene.get("battlegrounds")
   if bg!=null:sample.army_troops=bg.units.size();sample.airstrike_warnings=bg.bombs.size();sample.army_shots=bg.shots.size();sample.battleground_map=bg.map_id
  var adventure:Variant=scene.get("adventure")
  if adventure!=null and adventure.combat!=null:sample.projectiles=adventure.combat.projectiles.size()
 samples.append(sample)
 if samples.size()>120:samples.pop_front()
 var f:=FileAccess.open(LAST,FileAccess.WRITE)
 if f!=null:f.store_string(JSON.stringify({"version":"v169","ended":false,"sample":sample}))
 if OS.has_feature("web"):JavaScriptBridge.eval("window.fxDiagnostics && window.fxDiagnostics.sample("+JSON.stringify(sample)+");",true)
func report()->String:
 var engine_log:=FileAccess.get_file_as_string("user://logs/godot.log") if FileAccess.file_exists("user://logs/godot.log") else ""
 return JSON.stringify({"engine_log_tail":engine_log.right(16000),"version":"v169","platform":OS.get_name(),"previous_session_interrupted":interrupted,"previous_session":previous,"samples":samples},"  ")
func download()->void:
 capture()
 if OS.has_feature("web"):JavaScriptBridge.eval("window.fxDiagnostics.download();",true);return
 if is_instance_valid(native_dialog):native_dialog.queue_free()
 native_dialog=FileDialog.new();native_dialog.access=FileDialog.ACCESS_FILESYSTEM;native_dialog.file_mode=FileDialog.FILE_MODE_SAVE_FILE;native_dialog.current_file="crossroads-diagnostics.json";native_dialog.add_filter("*.json","Diagnostic report");add_child(native_dialog)
 native_dialog.file_selected.connect(func(path:String):
  var f:=FileAccess.open(path,FileAccess.WRITE)
  if f!=null:f.store_string(report())
  native_dialog.queue_free()
 );native_dialog.popup_centered(Vector2i(900,520))
func _exit_tree()->void:
 var f:=FileAccess.open(LAST,FileAccess.WRITE)
 if f!=null:f.store_string(JSON.stringify({"version":"v169","ended":true,"sample":samples.back() if not samples.is_empty() else {}}))
