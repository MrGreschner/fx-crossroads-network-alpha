extends Button
var game:Node
func _process(_dt:float)->void:
 var objective=game.arena_world.objective
 visible=game.started and objective.active() and game.arena_map=="crown_chase" and str(objective.crown.get("holder",""))==game.my_id and game.presentation.page.is_empty() and game.session_menu.page.is_empty() and game.shop_open.is_empty()
 position=Vector2(game.VIEW.x-220,255);size=Vector2(200,36)
 disabled=objective.elapsed<float(objective.crown.get("pickup_ready",0)) or int(game.health.get(game.my_id,0))<=0
