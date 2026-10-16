extends Control
var container:SubViewportContainer
var viewport:SubViewport
var game:Node
var render_scale=1.0
func _ready()->void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);mouse_filter=Control.MOUSE_FILTER_IGNORE
 container=SubViewportContainer.new();container.stretch=true;container.mouse_filter=Control.MOUSE_FILTER_PASS;container.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_child(container)
 viewport=SubViewport.new();viewport.world_2d=World2D.new();viewport.disable_3d=true;viewport.size_2d_override_stretch=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;container.add_child(viewport)
 fit()
 game=preload("res://network/arena.gd").new();viewport.add_child(game);game.set_meta("fx_render_shell",self)
func _process(_delta:float)->void:fit()
func fit()->void:
 if viewport==null:return
 var logical=Vector2i(get_viewport_rect().size)
 var raster=Vector2i(maxi(2,roundi(logical.x*render_scale)),maxi(2,roundi(logical.y*render_scale)))
 viewport.size_2d_override=logical
 container.size=Vector2(raster);container.scale=Vector2(logical)/Vector2(raster)
func set_quality(value:float)->void:
 render_scale=clampf(value,.7,1);fit()
