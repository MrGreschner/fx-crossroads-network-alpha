extends RefCounted
static func apply(b:Button)->void:
 b.add_theme_font_size_override("font_size",17)
 b.focus_mode=Control.FOCUS_NONE
 b.add_theme_color_override("font_color",Color("#edf0e1"))
 for state in ["normal","hover","pressed"]:
  var skin:=StyleBoxFlat.new();skin.bg_color=Color("#294653") if state=="normal" else Color("#3a6370") if state=="hover" else Color("#486d65");skin.border_color=Color("#bda16d") if state!="normal" else Color("#577a82");skin.set_border_width_all(1);skin.set_corner_radius_all(7);skin.content_margin_left=14;skin.content_margin_right=14;skin.content_margin_top=4;skin.content_margin_bottom=4;b.add_theme_stylebox_override(state,skin)
