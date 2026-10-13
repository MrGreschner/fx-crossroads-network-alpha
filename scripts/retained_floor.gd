extends Node2D
var source:Node
var floor:Dictionary
var background:=false
func _ready()->void:z_index=-2 if background else -1
func _process(_delta:float)->void:
 var game:Node=source.adventure.game
 visible=source.active and (game.started and not game.spectating() if source.adventure.arcade else game.mode=="run") and game.session_menu.page not in ["main","clear","options"]
 position=-game.camera
 if visible and background and (source.data.id in ["silverfall","lantern_marsh"] or not source.data.lake.is_empty()):queue_redraw()
 if visible and not background:visible=source.visible(source.floor_bounds(floor),game.camera)
func _draw()->void:
 if background:source.draw_water(self,Vector2.ZERO)
 else:source.draw_floor(self,floor)
