extends RefCounted
static func show(g:Node,message:String)->void:
 if not g.is_inside_tree():return
 var layer=g.get_node_or_null("RecordNotices")
 if layer==null:
  layer=CanvasLayer.new();layer.name="RecordNotices";layer.layer=115;g.add_child(layer)
 var view=g.get_viewport_rect().size
 var box=PanelContainer.new();box.add_theme_stylebox_override("panel",preload("res://scripts/studio_ui.gd").box("#203e47","#f2d184",8,12));box.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(box)
 var text=Label.new();text.text=message;text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.add_theme_font_size_override("font_size",16);text.add_theme_color_override("font_color",Color("#ffe3a3"));text.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(text)
 var width=minf(660,view.x-32);box.position=Vector2((view.x-width)*.5,138+(layer.get_child_count()-1)*64);box.size=Vector2(width,56)
 var tween=g.create_tween();tween.tween_interval(5);tween.tween_property(box,"modulate:a",0.0,.5);tween.tween_callback(func():box.queue_free();for_remaining(layer))
static func for_remaining(layer:CanvasLayer)->void:
 var index=0
 for child in layer.get_children():
  if child.is_queued_for_deletion():continue
  child.position.y=138+index*64;index+=1
