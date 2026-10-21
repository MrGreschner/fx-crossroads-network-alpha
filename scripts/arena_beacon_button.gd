extends Button
var game:Node
func _process(_dt:float)->void:
 visible=is_instance_valid(game) and game.started and game.mode=="arena" and game.arena_map=="lanternfall" and game.results_reason.is_empty() and game.presentation.page.is_empty() and game.session_menu.page.is_empty() and game.shop_open.is_empty()
