extends RefCounted
## Shared presentation follows the same groups that govern realm access.
const ACCESS=preload("res://scripts/realm_access.gd")
const TITLES={"starter":"Easy / first steps","moderate":"Moderate","medium":"Medium","challenging":"Challenging","hard":"Hard","expert":"Expert","extreme":"Extreme"}
const COLORS={"starter":"#a6d6b3","moderate":"#98cdd6","medium":"#ddcd91","challenging":"#ddbc91","hard":"#dba3a0","expert":"#bfa9d9","extreme":"#d7a3cc"}
static func tier(id:String)->String:
 for pair in [[ACCESS.BEGINNER,"starter"],[ACCESS.INTRO_MODERATE,"moderate"],[ACCESS.MEDIUM,"medium"],[ACCESS.CHALLENGING,"challenging"],[ACCESS.HARD,"hard"],[ACCESS.EXPERT,"expert"],[ACCESS.EXTREME,"extreme"]]:
  if id in pair[0]:return pair[1]
 return "starter"
static func title(id:String)->String:return TITLES[tier(id)]
static func color(id:String)->Color:return Color(COLORS[tier(id)])
static func style(button:Button,id:String)->void:
 var tint=color(id)
 for state in ["normal","hover","pressed","hover_pressed","focus"]:
  var selected=state in ["pressed","hover_pressed","focus"]
  var skin=StyleBoxFlat.new();skin.bg_color=Color("#244854").lerp(tint,.16 if selected else .08 if state=="hover" else .035)
  skin.border_color=Color("#efcf8c") if selected else tint.darkened(.22);skin.set_border_width_all(2 if selected else 1);skin.border_width_left=4;skin.set_corner_radius_all(10);skin.set_content_margin_all(10)
  button.add_theme_stylebox_override(state,skin)
 button.add_theme_color_override("font_color",Color("#edf8f6"));button.add_theme_color_override("font_pressed_color",Color("#fff0cc"));button.add_theme_color_override("font_hover_pressed_color",Color("#fff0cc"))
