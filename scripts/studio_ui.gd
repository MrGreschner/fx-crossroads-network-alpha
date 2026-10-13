extends RefCounted
## Shared Studio visual language. Applied only to creator interfaces.
const FONT=preload("res://assets/fonts/CrossroadsUI.ttf")
static func box(fill:String,edge:String="#345763",radius:int=10,padding:int=12)->StyleBoxFlat:
 var s=StyleBoxFlat.new();s.bg_color=Color(fill);s.border_color=Color(edge);s.set_border_width_all(1);s.set_corner_radius_all(radius);s.set_content_margin_all(padding);return s
static func apply(control:Variant)->void:
 var t=Theme.new();t.default_font=FONT;t.default_font_size=17
 t.set_color("font_color","Label",Color("#e5eff0"))
 for type in ["Button","OptionButton","CheckButton"]:
  t.set_stylebox("normal",type,box("#244854"));t.set_stylebox("hover",type,box("#356371","#84d9da"));t.set_stylebox("pressed",type,box("#173843","#efcf8c"));t.set_stylebox("focus",type,box("#244854","#efcf8c"));t.set_color("font_color",type,Color("#edf8f6"))
 for type in ["LineEdit","TextEdit","CodeEdit"]:
  t.set_stylebox("normal",type,box("#0b222d"));t.set_stylebox("focus",type,box("#102e3a","#86d1d6"));t.set_color("font_color",type,Color("#eff8f5"));t.set_color("caret_color",type,Color("#efcf8c"));t.set_color("selection_color",type,Color("#37647b"))
 t.set_constant("separation","VBoxContainer",12);t.set_constant("separation","HBoxContainer",12);t.set_constant("h_separation","GridContainer",12);t.set_constant("v_separation","GridContainer",12)
 t.set_stylebox("panel","PanelContainer",box("#102c38","#bba777",14,20))
 t.set_stylebox("panel","PopupMenu",box("#102c38","#84d9da"))
 t.set_stylebox("embedded_border","Window",box("#102c38","#bba777",12,12));t.set_stylebox("embedded_unfocused_border","Window",box("#102c38","#355b68",12,12));t.set_color("title_color","Window",Color("#edcf91"))
 for state in ["tab_selected","tab_unselected","tab_hovered"]:t.set_stylebox(state,"TabBar",box("#35616d" if state=="tab_selected" else "#183844","#83cad0" if state=="tab_selected" else "#345763",7,10))
 t.set_color("font_selected_color","TabBar",Color("#fff0c2"));t.set_color("font_unselected_color","TabBar",Color("#bfd5d9"))
 control.theme=t
static func enter(control:Control)->void:
 control.modulate.a=0
 control.create_tween().tween_property(control,"modulate:a",1.0,.18).set_trans(Tween.TRANS_SINE)
static func card(parent:Node,title:String,subtitle:String="")->VBoxContainer:
 var frame=PanelContainer.new();frame.add_theme_stylebox_override("panel",box("#183945","#355b68",10,14));parent.add_child(frame)
 var col=VBoxContainer.new();frame.add_child(col)
 if not title.is_empty():
  var heading=Label.new();heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;heading.text=title;heading.add_theme_font_size_override("font_size",20);heading.add_theme_color_override("font_color",Color("#edcf91"));col.add_child(heading)
 if not subtitle.is_empty():
  var l=Label.new();l.text=subtitle;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",15);l.add_theme_color_override("font_color",Color("#b8d3d8"));col.add_child(l)
 return col
static func accent(button:Button)->void:
 button.add_theme_stylebox_override("normal",box("#306254","#91c8a9"));button.add_theme_color_override("font_color",Color("#f2fff1"))
static func lesson(owner:Node,title:String,subtitle:String,topics:Array)->Node:
 var page=preload("res://scripts/studio_notes.gd").new();owner.add_child(page);page.setup(title,subtitle,topics);return page
