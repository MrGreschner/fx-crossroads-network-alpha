extends Control
## Estimated within-species size distribution; never presented as a live leaderboard.
var percentile=50.0
var accent=Color("#79cdd6")
func _ready()->void:custom_minimum_size=Vector2(180,30);size_flags_horizontal=Control.SIZE_EXPAND_FILL;mouse_filter=Control.MOUSE_FILTER_PASS
func _draw()->void:
 var track=Rect2(0,3,size.x,9)
 draw_style_box(preload("res://scripts/studio_ui.gd").box("#112b38","#426575",4,0),track)
 for zone in [[0,.25,"#487c98"],[.25,.75,"#4f9eaa"],[.75,.95,"#a59b60"],[.95,1.0,"#c4a357"]]:
  draw_rect(Rect2(size.x*float(zone[0]),5,size.x*(float(zone[1])-float(zone[0])),5),Color(zone[2]))
 var x=clampf(percentile/100,0,1)*(size.x-4)+2
 draw_line(Vector2(x,0),Vector2(x,15),accent,3,true)
 draw_colored_polygon(PackedVector2Array([Vector2(x,17),Vector2(x-4,22),Vector2(x+4,22)]),accent)
 var font=preload("res://scripts/studio_ui.gd").FONT
 draw_string(font,Vector2(0,29),"SMALL",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#a9cbd5"))
 draw_string(font,Vector2(size.x*.43,29),"TYPICAL",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#b7d8d6"))
 draw_string(font,Vector2(size.x-35,29),"LARGE",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#ead59c"))
