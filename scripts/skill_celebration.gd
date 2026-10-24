extends RefCounted
## A short, non-modal reward. No progression writes; triggered only by earned XP.
static func show_level(game:Node,skill:String,before:int,after:int,points:int=0)->void:
 if not is_instance_valid(game) or not game.is_inside_tree() or after<=before:return
 var root=game.get_tree().root
 var previous=root.get_node_or_null("SkillCelebration")
 if previous!=null:previous.free()
 var layer=CanvasLayer.new();layer.name="SkillCelebration";layer.layer=95;root.add_child(layer)
 var box=PanelContainer.new();layer.add_child(box);box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP);box.offset_left=-190;box.offset_right=190;box.offset_top=154;box.offset_bottom=262;box.custom_minimum_size=Vector2(380,108);box.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var skin=StyleBoxFlat.new();skin.bg_color=Color("#173c43");skin.border_color=Color("#efd38b");skin.set_border_width_all(2);skin.set_corner_radius_all(14);skin.content_margin_left=20;skin.content_margin_right=20;skin.content_margin_top=12;skin.content_margin_bottom=12;box.add_theme_stylebox_override("panel",skin)
 var rows=VBoxContainer.new();rows.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.add_child(rows)
 var title=Label.new();title.text="FISHING LEVEL UP!" if skill=="Fishing" else "GARDENING LEVEL UP!";title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;title.add_theme_color_override("font_color",Color("#ffe19b"));title.add_theme_font_size_override("font_size",21);rows.add_child(title)
 var level=Label.new();level.text="LEVEL %d" % after;level.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;level.add_theme_font_size_override("font_size",28);rows.add_child(level)
 var detail=Label.new();detail.text=("+%d mastery point%s • " % [points,"" if points==1 else "s"] if points>0 else "")+"Your practice is paying off";detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;detail.add_theme_font_size_override("font_size",14);detail.add_theme_color_override("font_color",Color("#c4e7d1"));rows.add_child(detail)
 box.modulate.a=0;var tween=box.create_tween();tween.tween_property(box,"modulate:a",1,.2);tween.tween_interval(3.6);tween.tween_property(box,"modulate:a",0,.5);tween.tween_callback(layer.queue_free)
