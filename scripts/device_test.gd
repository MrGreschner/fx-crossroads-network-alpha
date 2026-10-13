extends CanvasLayer
## A bounded five-second observation, not a synthetic stress test or an internet speed test.
var game:Node
var panel:PanelContainer
var info:Label
var frames:Array=[]
var running:=false
var elapsed:=0.0
var last_usec:=0
func setup(owner:Node)->void:
 game=owner;layer=75
 game.session_menu.page="device";game.session_menu.backdrop.visible=false
 panel=PanelContainer.new();add_child(panel);panel.size=Vector2(800,590)
 var skin:=StyleBoxFlat.new();skin.bg_color=Color("#102c35");skin.border_color=Color("#d6bf83");skin.set_border_width_all(2);skin.set_corner_radius_all(14);skin.set_content_margin_all(22);panel.add_theme_stylebox_override("panel",skin)
 var body:=VBoxContainer.new();body.add_theme_constant_override("separation",14);panel.add_child(body)
 var title:=Label.new();title.text="DEVICE & GAME SPEED CHECK";title.add_theme_font_size_override("font_size",26);body.add_child(title)
 var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(750,410);scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(scroll)
 info=Label.new();info.custom_minimum_size.x=735;info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;info.add_theme_font_size_override("font_size",18);scroll.add_child(info)
 var row:=HBoxContainer.new();body.add_child(row)
 for title_text in ["Run 5-second check","Close"]:
  var b:=Button.new();b.text=title_text;b.custom_minimum_size=Vector2(300,48);row.add_child(b)
  if title_text=="Close":b.pressed.connect(queue_free)
  else:b.pressed.connect(start)
 start()
func start()->void:
 frames.clear();elapsed=0;last_usec=Time.get_ticks_usec();running=true
 info.text="Measuring the current screen for five seconds…\nThis does not change your settings or upload information.\nFor useful results, also run this from Options during a realm.\nLive multiplayer continues. Solo simulation stays paused during this check."
func _process(_delta:float)->void:
 var view:=get_viewport().get_visible_rect().size;var factor:=minf(1,minf((view.x-20)/800,(view.y-20)/590));panel.scale=Vector2.ONE*factor;panel.position=(view-panel.size*factor)*.5
 if not running:return
 var now:=Time.get_ticks_usec();var dt:float=(now-last_usec)/1000000.0;last_usec=now
 elapsed+=dt
 if dt>0 and frames.size()<2000:frames.append(dt)
 if elapsed>=5:running=false;info.text=summary()
func summary()->String:
 if frames.is_empty():return "No samples yet. Run the check again."
 var sorted:Array=frames.duplicate();sorted.sort();var total:=0.0;var hitches:=0
 for dt in frames:total+=float(dt);hitches+=int(float(dt)>.05)
 var stability:Node=get_tree().root.get_node("FXStability")
 var device:=OS.get_processor_name();var browser:="Native Godot build";var gpu:=RenderingServer.get_video_adapter_name();var memory:="Not reported"
 if OS.has_feature("web"):
  var raw:Variant=JavaScriptBridge.eval("JSON.stringify(window.fxDiagnostics ? window.fxDiagnostics.inspect() : {browser:navigator.userAgent})",true)
  var data:Variant=JSON.parse_string(str(raw))
  if data is Dictionary:
   browser=str(data.get("browser","Not reported"));gpu=str(data.get("graphics",{}).get("renderer","Hidden by browser"));device=str(data.get("device",{}).get("cores","Unknown"))+" logical cores";memory=str(data.get("device",{}).get("memoryGB","Hidden by browser"))+" GB (browser estimate)"
 var fps:float=frames.size()/maxf(total,.001);var p95:float=float(sorted[mini(sorted.size()-1,int(sorted.size()*.95))])*1000
 var scene:=game.get_tree().current_scene;var context:=str(scene.get("mode")) if scene!=null else "menu"
 var result:="Holding the selected cap" if fps>=stability.fps_limit*.9 and p95<=1000.0/stability.fps_limit*1.6 else "Frame delays detected — try School performance ON / 30 FPS"
 var network:="No live network connection"
 if game.get("transport")!=null and game.links.size()>0:network="Ping %.0f ms • skipped updates %d • incoming backlog %d"%[game.transport.ping_ms,game.transport.deferred,game.incoming_backlog]
 return "%s\n\nMeasured %.1f FPS / %d cap • 95%% frame time %.1f ms\nFrames over 50 ms: %d / %d • screen: %s\nGame CPU frame: %.1f ms • draw calls: %d\nGame memory: %.1f MB • render resolution: %s\nSchool performance: %s\n%s\n\nDevice: %s\nGraphics: %s\nDevice memory: %s\nBrowser: %s\n\nThis observes realm rendering and this panel; solo AI is paused. A capped 30 FPS result does not measure maximum hardware capacity. Browsers may hide hardware details. Share this screen with your teacher; nothing is uploaded."%[result,fps,stability.fps_limit,p95,hitches,frames.size(),context,Performance.get_monitor(Performance.TIME_PROCESS)*1000,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),Performance.get_monitor(Performance.MEMORY_STATIC)/1048576,get_viewport().get_visible_rect().size,"ON" if stability.school_mode else "OFF",network,device,gpu,memory,browser]

func _exit_tree()->void:
 if is_instance_valid(game) and not game.is_queued_for_deletion() and is_instance_valid(game.session_menu) and game.session_menu.page=="device":game.session_menu.open("options")
