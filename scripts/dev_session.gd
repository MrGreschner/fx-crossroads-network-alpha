extends Node
## Volatile testing session: never serialised, discarded on refresh/process restart.
var test_scene:Node
var active:=false
var discarding:=false
var memory:Dictionary={}
var departing:Node
var border:Control
var overlay:CanvasLayer
var last_size:=Vector2.ZERO
var tools:CanvasLayer
func _ready()->void:
 overlay=CanvasLayer.new();overlay.layer=90;add_child(overlay)
 border=Control.new();border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);border.mouse_filter=Control.MOUSE_FILTER_IGNORE;overlay.add_child(border);border.draw.connect(paint);overlay.hide()
 tools=preload("res://scripts/dev_tools.gd").new();add_child(tools);tools.setup(self)
func begin()->void:
 var research=get_tree().root.get_node_or_null("FXResearch")
 if research!=null:research.active=false;research.hide()
 memory.clear();active=true;overlay.show();border.queue_redraw();tools.opened=false;tools.panel.hide();tools.banner.hide()
func finish()->void:
 tools.close_desk();active=false;tools.opened=false;tools.panel.hide();tools.banner.hide();tools.hide();discarding=true;memory.clear();departing=get_tree().current_scene;overlay.hide()
 for key in ["fx_hero","fx_mode","fx_realm","fx_inspect_hero","fx_retry_realm","fx_clinic"]:
  if get_tree().root.has_meta(key):get_tree().root.remove_meta(key)
 get_tree().root.set_meta("fx_show_main",true)
 get_tree().change_scene_to_file("res://scenes/main.tscn")
func _process(_delta:float)->void:
 if get_tree().root.has_meta("fx_dev_match") and (not is_instance_valid(test_scene) or get_tree().current_scene!=test_scene):
  get_tree().root.remove_meta("fx_dev_match");test_scene=null
 if discarding and is_instance_valid(get_tree().current_scene) and get_tree().current_scene!=departing:discarding=false;memory.clear();departing=null
 if active and border.get_viewport_rect().size!=last_size:last_size=border.get_viewport_rect().size;border.queue_redraw()
func paint()->void:
 if not active:return
 var size:=border.get_viewport_rect().size
 for p in [Vector2(8,8),Vector2(size.x-8,8),Vector2(8,size.y-8),size-Vector2(8,8)]:
  var d=Vector2(1 if p.x<20 else -1,1 if p.y<20 else -1)
  border.draw_line(p,p+Vector2(d.x*34,0),Color("#98dce2"),2,true)
  border.draw_line(p,p+Vector2(0,d.y*24),Color("#dbbc86"),2,true)
 var box:=Rect2(Vector2(size.x*.5-142,size.y-25),Vector2(284,22))
 border.draw_rect(box,Color("#152b3a",.88));border.draw_string(ThemeDB.fallback_font,box.position+Vector2(0,15),"GAME DEV • TEST SESSION",HORIZONTAL_ALIGNMENT_CENTER,284,12,Color("#b6dedc"))
