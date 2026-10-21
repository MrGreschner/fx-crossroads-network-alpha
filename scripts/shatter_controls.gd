extends Button
var game:Node
func _process(_dt:float)->void:
 var mode=game.arena_world.shatter
 visible=game.started and mode.active() and not game.mobile.enabled and game.presentation.page.is_empty() and game.session_menu.page.is_empty() and not game.spectating()
 position=Vector2(game.VIEW.x-250,355);size=Vector2(230,38)
 disabled=not mode.playable(game.my_id) or mode.clock<float(mode.hop_ready.get(game.my_id,0))
 text="HOP • %.1fs" % maxf(0,float(mode.hop_ready.get(game.my_id,0))-mode.clock) if disabled else "HOP • RIGHT CLICK / SHIFT"

 if mode.dropping.has(game.my_id):text="FALLING • LANDING SOON"
 elif mode.eliminated.has(game.my_id):text="OUT • WATCH THE SURVIVORS"
