extends CanvasLayer
const UI=preload("res://scripts/garden_ui.gd")
var gardening:RefCounted
var map:Control
var panel:PanelContainer
var info:Label
var learn:Button
var tally:Label
var restore_visible=false
func setup(owner:RefCounted)->void:
 gardening=owner;layer=95;restore_visible=gardening.legacy.root.visible;gardening.legacy.root.hide()
 panel=PanelContainer.new();panel.add_theme_stylebox_override("panel",preload("res://scripts/studio_ui.gd").box("#142e35","#d6bb7d",12,2));add_child(panel)
 var margin=MarginContainer.new()
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,16)
 panel.add_child(margin);var col=VBoxContainer.new();margin.add_child(col)
 var top=HBoxContainer.new();col.add_child(top);tally=UI.label(top,"GARDENING • THE LIVING TREE",22);UI.button(top,"Close",close).size_flags_horizontal=Control.SIZE_SHRINK_END
 top.get_child(top.get_child_count()-1).custom_minimum_size.x=100
 var controls=HBoxContainer.new();col.add_child(controls)
 UI.button(controls,"−",func():map.zoom_at(.8,map.size*.5)).size_flags_horizontal=Control.SIZE_SHRINK_END
 UI.button(controls,"+",func():map.zoom_at(1.25,map.size*.5)).size_flags_horizontal=Control.SIZE_SHRINK_END
 UI.button(controls,"Overview",func():map.overview()).size_flags_horizontal=Control.SIZE_SHRINK_END
 UI.label(controls,"Mouse wheel / pinch: zoom • drag: explore • click a symbol",15)
 UI.button(controls,"Reset mastery",confirm_reset).size_flags_horizontal=Control.SIZE_SHRINK_END
 for child in controls.get_children():
  if child is Button:child.custom_minimum_size.x=40 if child.text in ["−","+"] else 100 if child.text=="Overview" else 150
 var row=HBoxContainer.new();row.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(row)
 map=preload("res://scripts/garden_map.gd").new();map.size_flags_horizontal=Control.SIZE_EXPAND_FILL;map.size_flags_vertical=Control.SIZE_EXPAND_FILL;row.add_child(map);map.setup(gardening);map.picked.connect(select)
 var detail=VBoxContainer.new();detail.custom_minimum_size.x=250;row.add_child(detail);UI.label(detail,"PERK DETAILS",20)
 info=UI.label(detail,"Follow the trunk into Cultivation, Botany and Stewardship.\n\nClick any symbol to inspect a perk.\n\nGold: learned\nGreen: level & path ready\nSlate: locked\n\nOne point every three levels. Choose one perk at paired forks.",17)
 learn=UI.button(detail,"Learn selected perk",func():gardening.learn(map.selected);select(map.selected));learn.disabled=true
 UI.label(detail,"64 perks • 33 points maximum\nActive plants, seeds and XP survive a mastery reset.",15)
 refresh_tally();layout()
func refresh_tally()->void:tally.text="GARDENING TREE • %d points available • level %d" % [mini(33,gardening.level()/3)-gardening.state().perks.size(),gardening.level()]
func select(id:String)->void:
 if not gardening.perks().has(id):return
 gardening.selected_perk=id;var p=gardening.perks()[id];var requirements=[]
 for key in p.requires:requirements.append(str(gardening.perks()[key].name))
 info.text=str(p.name)+"\nLevel %d • 1 point\n\n" % int(p.level)+str(p.text)+("\n\nPath: "+(" or " if p.get("any",false) else " + ").join(requirements) if not requirements.is_empty() else "\n\nStart of the trunk.")+"\n\n"+("LEARNED" if gardening.state().perks.has(id) else "Inspect the level and connected path, then choose Learn.")
 learn.disabled=not gardening.allowed() or gardening.state().perks.has(id) or gardening.level()<int(p.level) or not gardening.prerequisites(p,gardening.state().perks) or gardening.state().perks.size()>=mini(33,gardening.level()/3)
 for other in gardening.state().perks:
  if not str(p.group).is_empty() and gardening.perks()[other].group==p.group:learn.disabled=true
 refresh_tally();map.queue_redraw()
func confirm_reset()->void:
 var dialog=ConfirmationDialog.new();dialog.title="Reset Gardening mastery?";dialog.dialog_text="Spend %d Glimmers to refund your points? Plants, XP and seeds stay safe. Giant crops keep their planting bonus." % gardening.reset_cost();add_child(dialog);dialog.confirmed.connect(func():gardening.reset();refresh_tally();map.queue_redraw();info.text=gardening.note;learn.disabled=true;dialog.queue_free());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered()
func layout()->void:
 var view=get_viewport().get_visible_rect().size;var base=Vector2(maxf(900,view.x-32),maxf(560,view.y-32));var scale_by=minf(1,minf((view.x-20)/base.x,(view.y-20)/base.y));panel.size=base;panel.scale=Vector2.ONE*scale_by;panel.position=(view-base*scale_by)*.5
func _process(_delta:float)->void:layout()
func _unhandled_input(event:InputEvent)->void:
 if event.is_action_pressed("ui_cancel"):close();get_viewport().set_input_as_handled()
func close()->void:
 gardening.tree_window=null
 if restore_visible:gardening.legacy.root.show();gardening.legacy.render()
 queue_free()
