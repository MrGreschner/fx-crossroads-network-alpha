extends Node2D
var game:Node
func _process(_delta:float)->void:
 var shown=is_instance_valid(game) and bool(game.get_meta("records_unofficial",false)) and str(game.get("mode"))!="town"
 if visible!=shown:visible=shown
 if shown:queue_redraw()
func _draw()->void:
 if is_instance_valid(game):preload("res://scripts/record_eligibility.gd").badge(game,self)
