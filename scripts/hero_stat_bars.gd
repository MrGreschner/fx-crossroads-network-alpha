extends RefCounted
## Common numerical reference scales, not balance ratings or DPS estimates.
static func entries(hero:Dictionary)->Array:
 var primary:Dictionary=hero.get("primary",{})
 var delay=maxf(0,float(primary.get("cooldown",0)))
 var rate=1.0/delay if delay>0 else 0.0
 var definitions=[
  ["Health",float(hero.get("max_health",100)),200.0,"HP","#d68d92","Base maximum health."],
  ["Attack damage",float(primary.get("damage",0)),50.0,"","#e4b577","Base primary damage per hit/tick/companion; not total cast damage or DPS. See ability details for summons, multi-hit and charge effects."],
  ["Attack range",float(primary.get("range",0)),700.0,"px","#88bdc9","Primary reach or targeting range, not projectile speed or area radius."],
  ["Attack speed",rate,4.0,"/s","#c0addd","Primary activations per second before charge time, passives or items. Summons have their own attack rate. Base cooldown: %.2fs."%delay],
  ["Move speed",float(hero.get("speed",230)),350.0,"px/s","#9ac8a0","Base movement speed before effects, equipment or abilities."]
 ]
 var result:Array=[]
 for spec in definitions:
  var amount=maxf(0,float(spec[1]));var units=str(spec[3]);var value=("%.2f/s"%rate if delay>0 else "Hold") if str(spec[0])=="Attack speed" else (str(roundi(amount))+(" "+units if not units.is_empty() else ""))
  result.append({"label":str(spec[0]),"value":value,"amount":amount,"ceiling":float(spec[2]),"ratio":clampf(amount/float(spec[2]),0,1),"tint":str(spec[4]),"tip":str(spec[5])+" Full bar: "+str(spec[2])+units+"; larger values remain shown numerically."})
 return result
static func add_to(parent:Node,hero:Dictionary)->PanelContainer:
 var panel=PanelContainer.new();panel.name="HeroBaseStats";panel.custom_minimum_size.x=245
 var skin=StyleBoxFlat.new();skin.bg_color=Color("#15353d");skin.border_color=Color("#426773");skin.set_border_width_all(1);skin.set_corner_radius_all(7);skin.set_content_margin_all(9);panel.add_theme_stylebox_override("panel",skin);parent.add_child(panel)
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",6);panel.add_child(col)
 var title=Label.new();title.text="BASE STATS";title.add_theme_font_size_override("font_size",13);title.modulate=Color("#f0d49d");col.add_child(title)
 for entry in entries(hero):
  var row=HBoxContainer.new();row.add_theme_constant_override("separation",6);row.tooltip_text=entry.tip;col.add_child(row)
  var name_label=Label.new();name_label.text=entry.label;name_label.custom_minimum_size.x=89;name_label.add_theme_font_size_override("font_size",13);name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(name_label)
  var bar=ProgressBar.new();bar.custom_minimum_size=Vector2(56,7);bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;bar.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bar.show_percentage=false;bar.value=entry.ratio*100;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var track=StyleBoxFlat.new();track.bg_color=Color("#0b242b");track.set_corner_radius_all(3);bar.add_theme_stylebox_override("background",track)
  var fill=StyleBoxFlat.new();fill.bg_color=Color(entry.tint);fill.set_corner_radius_all(3);bar.add_theme_stylebox_override("fill",fill);row.add_child(bar)
  var number=Label.new();number.text=entry.value;number.custom_minimum_size.x=60;number.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;number.add_theme_font_size_override("font_size",13);number.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(number)
 var note=Label.new();note.text="Before items and passives";note.add_theme_font_size_override("font_size",11);note.modulate=Color("#aac5c8");col.add_child(note)
 return panel
