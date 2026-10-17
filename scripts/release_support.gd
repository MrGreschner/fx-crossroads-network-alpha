extends RefCounted
## Small release helpers. No uploads, progression changes or gameplay pop-ups.
static func context(game:Node)->String:
 var arcade:bool=game.has_method("_attack_request")
 var hero:String=str(game.hero_ids.get(game.my_id,"ram")) if arcade else str(game.selected_character)
 var st:Node=game.get_tree().root.get_node_or_null("FXStability")
 var fps:int=st.fps_limit if st!=null else Engine.max_fps
 var gpu:=RenderingServer.get_video_adapter_name()
 if OS.has_feature("web"):
  var inspected:Variant=JSON.parse_string(str(JavaScriptBridge.eval("JSON.stringify(window.fxDiagnostics ? window.fxDiagnostics.inspect() : {})",true)))
  if inspected is Dictionary:gpu=str(inspected.get("graphics",{}).get("renderer","Hidden by browser"))
 var raw:Variant=JavaScriptBridge.eval("navigator.userAgent",true) if OS.has_feature("web") else OS.get_name()
 return ("Version: v%d\nDevice/browser: " % preload("res://scripts/build_update.gd").BUILD)+str(raw)+"\nGraphics: "+gpu+"\nDraw calls: "+str(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))+"\nEngine memory MB: "+str(snappedf(Performance.get_monitor(Performance.MEMORY_STATIC)/1048576,.1))+"\nMode: "+str(game.mode)+"\nHero: "+str(game.characters.get(hero,{}).get("name",hero))+"\nTesting mode: "+str(preload("res://scripts/profile_store.gd").testing())+"\nFPS: "+str(Engine.get_frames_per_second())+" / cap "+str(fps)+"\nSchool performance: "+str(st.school_mode if st!=null else false)+"\nViewport: "+str(game.get_viewport().get_visible_rect().size)+"\nRole: "+str(game.get("role") if arcade else "solo")
static func bug_report(game:Node)->String:
 return "CROSSROADS: REALMS BEYOND BUG REPORT\n"+context(game)+"\n\nArea tested:\nSteps to reproduce (1, 2, 3):\nExpected:\nObserved:\nHow often (attempts / failures):\nPlayer impact:\nScreenshot or diagnostic filename:\nSuggested improvement:\nHow to verify the fix:\n\nNo report is sent automatically. Give this to your teacher or project maintainer."
static func copy_text(value:String)->void:
 if OS.has_feature("web"):
  JavaScriptBridge.eval("(()=>{const text="+JSON.stringify(value)+";if(navigator.clipboard&&navigator.clipboard.writeText){navigator.clipboard.writeText(text).catch(()=>{window.fxCopiedReport=text;});}else{const area=document.createElement('textarea');area.value=text;document.body.appendChild(area);area.select();document.execCommand('copy');area.remove();}})()",true)
 else:DisplayServer.clipboard_set(value)
static func scan_mastery(legacy:Node)->void:
 if preload("res://scripts/profile_store.gd").testing() or bool(legacy.data.get("teacher",false)):return
 var raw:Variant=legacy.data.get("backup_reminder",{})
 var b:Dictionary=raw if raw is Dictionary else {}
 if not b.get("known",null) is Array:b.known=[]
 b.pending=bool(b.get("pending",false));b.last_export=str(b.get("last_export",""))
 for id in legacy.data.heroes.keys():
  if not legacy.game.characters.has(id):continue
  for final in [false,true]:
   var ready:bool=legacy.final_eligible(str(id)) if final else legacy.eligible(str(id))
   var key:=str(id)+("/final" if final else "/first")
   if ready and key not in b.known:b.known.append(key);b.pending=true
 legacy.data.backup_reminder=b
static func backup_due(legacy:Node)->bool:
 var b:Variant=legacy.data.get("backup_reminder",{})
 return not preload("res://scripts/profile_store.gd").testing() and b is Dictionary and bool(b.get("pending",false))
static func exported(legacy:Node)->void:
 if preload("res://scripts/profile_store.gd").testing():return
 scan_mastery(legacy);legacy.data.backup_reminder.pending=false;legacy.data.backup_reminder.last_export=Time.get_datetime_string_from_system(true);legacy.save()
