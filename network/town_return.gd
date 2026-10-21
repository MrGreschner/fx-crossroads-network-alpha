extends CanvasLayer
## Root-owned scene handoff. Release the SubViewport before loading the next scene.
const BUSY = "fx_scene_handoff"
var destination := "res://scenes/main.tscn"
var is_town := true
var title := "Returning to Crossroads…"
var status: Label
var retry: Button
var elapsed := 0.0
var phase := "waiting"
var attempt := 0
func mark(value: String) -> void:
 phase = value
 if OS.has_feature("web"):
  JavaScriptBridge.eval("console.log(\"CROSSROADS_SCENE " + value + "\");",true)

static func begin(owner: Node, path: String, town: bool = false) -> bool:
 var tree := owner.get_tree()
 if tree == null or tree.root.has_meta(BUSY): return false
 tree.root.set_meta(BUSY, true)
 var transition = load("res://network/town_return.gd").new()
 transition.destination = path
 transition.is_town = town
 transition.title = "Returning to Crossroads…" if town else "Preparing your adventure…"
 tree.root.call_deferred("add_child", transition)
 return true

func _ready() -> void:
 layer = 125
 process_mode = Node.PROCESS_MODE_ALWAYS
 var shade := ColorRect.new()
 shade.color = Color("#0d2733")
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(shade)
 var center := CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.add_child(center)
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation", 18)
 center.add_child(column)
 status = Label.new()
 status.text = title
 status.add_theme_font_size_override("font_size", 26)
 column.add_child(status)
 retry = Button.new()
 retry.text = "Return to town"
 retry.custom_minimum_size = Vector2(240, 48)
 retry.hide()
 retry.pressed.connect(func():
  destination = "res://scenes/main.tscn";is_town = true;retry.hide();elapsed = 0;call_deferred("handoff"))
 column.add_child(retry)
 call_deferred("handoff")

func handoff() -> void:
 attempt += 1
 var epoch := attempt
 var tree := get_tree()
 tree.paused = false
 mark("releasing")
 # First let the transition render. Then free the outgoing game and viewport.
 await tree.process_frame
 mark("unloading")
 tree.unload_current_scene()
 mark("unloaded")
 await tree.process_frame
 await tree.process_frame
 tree.root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 tree.root.gui_release_focus()
 mark("loading")
 # The non-threaded Web build must not wait indefinitely on a threaded load.
 var packed = load(destination) as PackedScene
 if packed == null:
  fail("Could not load the adventure. You can return to town.");return
 if is_town:
  for key in ["fx_retry_realm", "fx_solo_expedition", "fx_solo_party"]:
   if tree.root.has_meta(key): tree.root.remove_meta(key)
  tree.root.set_meta("fx_return_from_lobby", true)
 mark("entering")
 var error := tree.change_scene_to_packed(packed)
 if error != OK:
  fail("Could not open the adventure. You can return to town.");return
 # Check the actual scene, rather than relying only on a transition signal.
 for frame in 180:
  await tree.process_frame
  if epoch != attempt:return
  if tree.current_scene != null and tree.current_scene.scene_file_path == destination:
   await tree.process_frame
   tree.root.gui_release_focus()
   if OS.has_feature("web"): JavaScriptBridge.eval("document.getElementById('canvas')?.focus();", true)
   mark("done")
   tree.root.remove_meta(BUSY)
   queue_free()
   return
 fail("The adventure did not open. You can return to town.")

func _process(delta: float) -> void:
 elapsed += delta
 if elapsed > 12 and phase != "done" and not retry.visible:
  status.text = "This is taking longer than expected. Return to town to try again."
  retry.show()

func fail(message: String) -> void:
 phase = "failed"
 status.text = message
 retry.show()
