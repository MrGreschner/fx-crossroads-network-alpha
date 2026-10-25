extends Node2D
## Visible terrain tiles keep detailed masonry to a few texture draws.
var source:Node
var background:=false
var last_cell:=Vector2i(-999,-999)
var last_size:=Vector2.ZERO
func _ready()->void:z_index=-1;texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
func _process(_dt:float)->void:
 var game=source.adventure.game
 visible=source.active and str(source.data.get("id",""))=="silverfall" and (game.started if source.adventure.arcade else game.mode=="run") and game.session_menu.page not in ["main","clear","options"]
 position=-game.camera
 var cell=Vector2i(floori(game.camera.x/512),floori(game.camera.y/512));var size=get_viewport_rect().size
 if cell!=last_cell or size!=last_size:last_cell=cell;last_size=size;queue_redraw()
func _draw()->void:source.silver_art.draw_baked(self,source.adventure.game.camera)
