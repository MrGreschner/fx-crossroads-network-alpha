extends RefCounted
## Reward artwork is independent of font glyph coverage and platform emoji fonts.
static func texture(kind:String="star")->Texture2D:
 return preload("res://scripts/source_art.gd").texture("res://assets/ui_reward_"+(kind if kind in ["star","trophy","building"] else "star")+".svg")
static func row(parent:Node,value:String,kind:String="star",font_size:int=20)->HBoxContainer:
 var line=HBoxContainer.new();line.add_theme_constant_override("separation",10);line.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(line)
 var icon=TextureRect.new();icon.texture=texture(kind);icon.custom_minimum_size=Vector2(30,30);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER;icon.set_meta("reward_icon",kind);line.add_child(icon)
 var label=Label.new();label.text=value;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.add_theme_font_size_override("font_size",font_size);label.add_theme_color_override("font_color",Color("#f3d895"));label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(label)
 return line
