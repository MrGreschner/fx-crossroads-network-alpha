extends Control
## Reuse the profile card without clipping its fixed-coordinate artwork on phones.
var legacy:Node
var username=""
var card:Control
var compact=false
func _ready()->void:
 size_flags_horizontal=Control.SIZE_EXPAND_FILL;mouse_filter=Control.MOUSE_FILTER_IGNORE
 card=preload("res://scripts/player_card_view.gd").new();card.name="CloudPlayerCard";card.legacy=legacy;card.display_name_override=username;add_child(card)
 resized.connect(fit_card);fit_card()
func fit_card()->void:
 if not is_instance_valid(card):return
 var factor=minf(1.0,maxf(.1,size.x/1000.0))
 if compact:factor=minf(factor,maxf(.01,size.y/545.0))
 card.size=Vector2(1000,545);card.scale=Vector2.ONE*factor;card.position=Vector2(maxf(0,(size.x-1000*factor)*.5),maxf(0,(size.y-545*factor)*.5) if compact else 0)
 custom_minimum_size=Vector2(0,0 if compact else 545*factor)
