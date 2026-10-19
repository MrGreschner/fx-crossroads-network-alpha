extends CanvasLayer
const UI=preload("res://scripts/garden_ui.gd")
var progress:RefCounted
var fishing:Node
var legacy:Node
var previous=""
var map:Control
var panel:PanelContainer
var info:Label
var learn:Button
var tally:Label
var restore_visible=false
func setup(owner:Node)->void:
 fishing=owner;progress=fishing.records().progress;legacy=fishing.game.legacy;previous=fishing.menu_key();fishing.game.set("shop_open" if fishing.multi else "menu","fishing_mastery");fishing.game.mobile.reset_controls();layer=95;restore_visible=legacy.root.visible;legacy.root.hide()
 panel=PanelContainer.new();panel.add_theme_stylebox_override("panel",preload("res://scripts/studio_ui.gd").box("#142e35","#d6bb7d",12,2));add_child(panel)
 var margin=MarginContainer.new()
 for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,16)
 panel.add_child(margin);var col=VBoxContainer.new();margin.add_child(col)
 var top=HBoxContainer.new();col.add_child(top);tally=UI.label(top,"FISHING • THE ANGLER’S TREE",22);UI.button(top,"Close",close).size_flags_horizontal=Control.SIZE_SHRINK_END
 var controls=HBoxContainer.new();col.add_child(controls)
 UI.button(controls,"−",func():map.zoom_at(.8,map.size*.5)).size_flags_horizontal=Control.SIZE_SHRINK_END
 UI.button(controls,"+",func():map.zoom_at(1.25,map.size*.5)).size_flags_horizontal=Control.SIZE_SHRINK_END
 UI.button(controls,"Overview",func():map.overview()).size_flags_horizontal=Control.SIZE_SHRINK_END
 UI.label(controls,"Mouse wheel / pinch: zoom • drag: explore • click a symbol",15)
 UI.button(controls,"Reset mastery",confirm_reset).size_flags_horizontal=Control.SIZE_SHRINK_END
 var row=HBoxContainer.new();row.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(row)
 map=preload("res://scripts/fishing_mastery_map.gd").new();map.size_flags_horizontal=Control.SIZE_EXPAND_FILL;map.size_flags_vertical=Control.SIZE_EXPAND_FILL;row.add_child(map);map.setup(progress);map.picked.connect(select)
 var detail=VBoxContainer.new();detail.custom_minimum_size.x=250;row.add_child(detail);UI.label(detail,"PERK DETAILS",20)
 info=UI.label(detail,"Follow the trunk into Rodcraft, Netcraft, Basketcraft, Watersense, Trailcraft and Riverkeeping.\n\nClick any symbol to inspect a perk.\n\nGold: learned\nGreen: level & path ready\nSlate: locked\n\nOne point every three levels through level 78. Learn both forks for a branch crown.",17)
 learn=UI.button(detail,"Learn selected perk",func():progress.choose(map.selected);select(map.selected));learn.disabled=true
 UI.label(detail,"60 perks • 26 points maximum\nEquipment, XP and catches survive a mastery reset. Collect baskets first.",15)
 refresh_tally();layout()
func refresh_tally()->void:tally.text="FISHING TREE • %d points available • level %d" % [progress.available_points(),progress.level()]
func select(id:String)->void:
 if not map.perks().has(id):return
 var p=map.perks()[id];var requirements=[]
 for key in p.requires:requirements.append(str(map.perks()[key].name))
 info.text=str(p.name)+"\nLevel %d • 1 point\n\n" % int(p.level)+str(p.text)+("\n\nPath: "+(" or " if p.get("any",false) else " + ").join(requirements) if not requirements.is_empty() else "\n\nStart of the trunk.")+"\n\n"+("LEARNED" if progress.has(id) else "Inspect the level and connected path, then choose Learn.")
 learn.disabled=not progress.learn_reason(id).is_empty()
 refresh_tally();map.queue_redraw()
func confirm_reset()->void:
 var dialog=ConfirmationDialog.new();dialog.title="Reset Fishing mastery?";dialog.dialog_text="Spend %d Glimmers to refund your points? XP, equipment and catches remain. Collect or retrieve every basket first." % progress.reset_cost();add_child(dialog);dialog.confirmed.connect(func():info.text=progress.reset_tree();refresh_tally();map.queue_redraw();learn.disabled=true;dialog.queue_free());dialog.canceled.connect(dialog.queue_free);dialog.popup_centered()
func layout()->void:
 var view=get_viewport().get_visible_rect().size;var base=Vector2(maxf(900,view.x-32),maxf(560,view.y-32));var scale_by=minf(1,minf((view.x-20)/base.x,(view.y-20)/base.y));panel.size=base;panel.scale=Vector2.ONE*scale_by;panel.position=(view-base*scale_by)*.5
func _process(_delta:float)->void:layout()
func _unhandled_input(event:InputEvent)->void:
 if event.is_action_pressed("ui_cancel"):close();get_viewport().set_input_as_handled()
func close()->void:
 fishing.mastery_window=null
 fishing.game.set("shop_open" if fishing.multi else "menu",previous);fishing.game.mobile.reset_controls()
 if restore_visible:legacy.root.show();legacy.render()
 queue_free()
