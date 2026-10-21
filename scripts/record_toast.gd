extends RefCounted
## One short draw-only message. Cannot create a modal or cover the fishing controls.
static func show(g:Node,message:String)->void:
 if not g.is_inside_tree() or message.is_empty():return
 var layer=g.get_node_or_null("RecordNotices")
 if layer==null:
  layer=CanvasLayer.new();layer.name="RecordNotices";layer.layer=115;g.add_child(layer)
 for old in layer.get_children():layer.remove_child(old);old.queue_free()
 var notice=preload("res://scripts/record_notice_draw.gd").new();notice.name="RecordToast";notice.message=message.left(180);notice.process_mode=Node.PROCESS_MODE_ALWAYS;layer.add_child(notice)
 var place=func():layout(g,layer)
 g.get_viewport().size_changed.connect(place)
 notice.tree_exiting.connect(func():
  if is_instance_valid(g) and g.get_viewport().size_changed.is_connected(place):g.get_viewport().size_changed.disconnect(place))
 layout(g,layer)
 var tween=notice.create_tween();tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS);tween.tween_interval(3);tween.tween_property(notice,"modulate:a",0.0,.4);tween.tween_callback(notice.queue_free)
static func layout(g:Node,layer:CanvasLayer)->void:
 if not is_instance_valid(g) or not is_instance_valid(layer):return
 var view:Vector2=g.get_viewport_rect().size
 for notice in layer.get_children():
  notice.size=Vector2(maxf(80,minf(580,view.x-24)),64 if view.x<420 else 46)
  notice.position=Vector2((view.x-notice.size.x)*.5,12);notice.queue_redraw()
