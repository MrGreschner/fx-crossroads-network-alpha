extends CanvasLayer
## Root-owned transition survives removal of the multiplayer SubViewport.
var started=0
var status:Label
var dots=0.0
func _ready()->void:
 layer=125;process_mode=Node.PROCESS_MODE_ALWAYS;started=Time.get_ticks_msec()
 var shade=ColorRect.new();shade.color=Color("#0d2733");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 var center=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.add_child(center)
 status=Label.new();status.text="Returning to Crossroads…";status.add_theme_font_size_override("font_size",26);center.add_child(status)
 var error=ResourceLoader.load_threaded_request("res://scenes/main.tscn")
 if error!=OK and error!=ERR_BUSY:status.text="Could not open town. Please reload after keeping a profile backup.";set_process(false)
func _process(delta:float)->void:
 dots+=delta;status.text="Returning to Crossroads"+".".repeat(1+int(dots*2)%3)
 var state=ResourceLoader.load_threaded_get_status("res://scenes/main.tscn")
 if state==ResourceLoader.THREAD_LOAD_FAILED or state==ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
  status.text="Town could not load. Please reload the page. Your saved profile is unchanged.";set_process(false);return
 if state!=ResourceLoader.THREAD_LOAD_LOADED or Time.get_ticks_msec()-started<120:return
 set_process(false);call_deferred("enter_town")
func enter_town()->void:
 var packed=ResourceLoader.load_threaded_get("res://scenes/main.tscn") as PackedScene
 if packed==null:status.text="Town could not load. Please reload the page.";return
 var tree=get_tree();tree.paused=false
 tree.root.set_meta("fx_return_from_lobby",true)
 var error=tree.change_scene_to_packed(packed)
 if error!=OK:status.text="Town could not open. Please reload the page.";return
 await tree.scene_changed
 await tree.process_frame
 tree.root.gui_release_focus()
 if OS.has_feature("web"):JavaScriptBridge.eval("document.getElementById('canvas')?.focus();",true)
 queue_free()
