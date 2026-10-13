extends Node2D
var source:Node
func _ready()->void:z_index=-1
func _process(_delta:float)->void:
 var game:Node=source.combat.adventure.game
 visible=source.active and source.combat.playing() and game.session_menu.page not in ["main","clear","options"] and not (source.combat.adventure.arcade and game.spectating())
 position=-game.camera
func _draw()->void:source.paint_world(self,Vector2.ZERO)
