extends RefCounted
const UI=preload("res://scripts/studio_ui.gd")
var panel:PanelContainer
var condition_panel:PanelContainer
var conditions:Label
var pool_label:Label
var pool_bar:ProgressBar
var hazard:Label
class WeatherBadge extends Control:
 var weather="Clear"
 func _draw()->void:
  var sun=Color("#f2d280");var cloud=Color("#bbd6da")
  if weather=="Clear":
   draw_circle(Vector2(15,15),7,sun)
   for n in 8:draw_line(Vector2(15,15)+Vector2.from_angle(n*TAU/8)*10,Vector2(15,15)+Vector2.from_angle(n*TAU/8)*14,sun,2)
  elif weather=="Mist":
   for y in [8,15,22]:draw_line(Vector2(2,y),Vector2(28,y),cloud,3)
  else:
   draw_circle(Vector2(10,12),7,cloud);draw_circle(Vector2(20,14),8,cloud);draw_line(Vector2(4,19),Vector2(27,19),cloud,5)
   if weather in ["Rain","Storm"]:
    for x in [8,16,24]:draw_line(Vector2(x,24),Vector2(x-3,29),Color("#8dbbde"),2)
var badge:WeatherBadge
func build(v:Node)->void:
 panel=PanelContainer.new();panel.name="VoyageBar";UI.apply(panel);v.hud.add_child(panel)
 var col=VBoxContainer.new();col.add_theme_constant_override("separation",3);panel.add_child(col)
 v.status=Label.new();v.status.add_theme_font_size_override("font_size",14);col.add_child(v.status)
 pool_label=Label.new();pool_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;pool_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;pool_label.add_theme_font_size_override("font_size",13);pool_label.add_theme_color_override("font_color",Color("#9ce6d6"));col.add_child(pool_label)
 pool_bar=ProgressBar.new();pool_bar.show_percentage=false;pool_bar.custom_minimum_size.y=8;pool_bar.tooltip_text="Fishing XP earned only after returning alive. Includes release and discovery bonuses; lost if the voyage fails.";col.add_child(pool_bar)
 v.strip=HBoxContainer.new();v.strip.add_theme_constant_override("separation",4);col.add_child(v.strip)
 v.anchor_button=small(v.strip,"Anchor",v.toggle_anchor);small(v.strip,"Chart",func():v.open_menu("voyage"));v.dock_button=small(v.strip,"Land",v.interact)
 hazard=Label.new();hazard.add_theme_font_size_override("font_size",12);hazard.add_theme_color_override("font_color",Color("#f0c28b"));col.add_child(hazard)
 condition_panel=PanelContainer.new();UI.apply(condition_panel);v.hud.add_child(condition_panel);var row=HBoxContainer.new();condition_panel.add_child(row)
 badge=WeatherBadge.new();badge.custom_minimum_size=Vector2(32,32);row.add_child(badge)
 conditions=Label.new();conditions.add_theme_font_size_override("font_size",16);conditions.tooltip_text="The same day, time and weather as town. These conditions affect feeding windows and the fish you can catch.";row.add_child(conditions)
func small(parent:Node,text:String,callback:Callable)->Button:
 var b=Button.new();b.text=text;b.custom_minimum_size=Vector2(58,29);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.add_theme_font_size_override("font_size",12)
 for state in ["normal","hover","pressed","focus"]:b.add_theme_stylebox_override(state,UI.box("#234a59","#527d8c",6,4))
 parent.add_child(b);b.pressed.connect(callback);return b
func refresh(v:Node)->void:
 var view=v.game.get_viewport_rect().size;panel.scale=Vector2.ONE;panel.size=Vector2(maxf(220,minf(235,view.x*.19-24)),0);panel.position=Vector2(12,view.y-panel.get_combined_minimum_size().y-12-(135 if v.game.mobile.enabled else 70 if view.x<1200 else 0))
 condition_panel.position=Vector2(maxf(14,view.x-condition_panel.get_combined_minimum_size().x-14) if view.y<500 else 14,100 if view.y<500 else 112);condition_panel.scale=Vector2.ONE*minf(1,(view.x-28)/maxf(1,condition_panel.get_combined_minimum_size().x))
 var cal=v.game.town_life.calendar;conditions.text=cal.label();badge.weather=cal.weather();badge.queue_redraw()
 v.status.text="Hull %d%% • Cargo %d/%d" % [ceili(v.hull),v.cargo.size(),v.capacity()]
 var xp=v.pending_xp();var p=v.records().progress;var level=p.level();pool_label.text="Safe-return XP: +%d" % xp;pool_bar.max_value=maxi(1,p.threshold(mini(p.MAX_LEVEL,level+1))-int(p.state().xp));pool_bar.value=xp
 if level==p.MAX_LEVEL:pool_bar.max_value=maxi(1,xp);pool_bar.value=xp
 var predicted=p.level_for(mini(1000000000,int(p.state().xp)+xp))
 if predicted>level:pool_label.text+=" • Lv %d → %d" % [level,predicted]
 hazard.text=v.surf.warning_at(v.boat)
 if hazard.text.is_empty() and v.debris.warning_at(v.boat):hazard.text="DRIFTING DEBRIS • steer clear"
 if hazard.text.is_empty() and v.night():hazard.text="Night • stay near the lantern"
 hazard.visible=not hazard.text.is_empty()
 v.anchor_button.text="Ashore" if v.ashore else "Sail" if v.anchored else "Anchor";v.anchor_button.disabled=v.ashore
 v.anchor_button.tooltip_text="Raise anchor to sail" if v.anchored else "Drop anchor to fish"
 v.dock_button.text="Board" if v.ashore else "Return" if v.boat.distance_to(v.HOME)<260 else "Land"
