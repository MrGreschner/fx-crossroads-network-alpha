extends CanvasLayer
## Direct, touch-friendly choices; titles and ribbons remain cosmetic-only.
var journey:Node
var panel:PanelContainer
var body:VBoxContainer
var was_open:=false
var signature:=""
const REQUIREMENTS=["Available from the start","Choose a hero, train, and enter the Grove","Clear Whispering Grove","Clear Lanternmarsh","Clear the Shattered Oath","Revive allies three times"]
func setup(owner:Node)->void:
 journey=owner;layer=36;panel=PanelContainer.new();panel.size=Vector2(900,620);panel.hide();add_child(panel)
 var skin:=StyleBoxFlat.new();skin.bg_color=Color("#142e35");skin.border_color=Color("#cab68b");skin.set_border_width_all(2);skin.set_corner_radius_all(12);skin.set_content_margin_all(22);panel.add_theme_stylebox_override("panel",skin)
 body=VBoxContainer.new();body.add_theme_constant_override("separation",10);panel.add_child(body)
func label(parent:Node,value:String,size:int=17)->Label:
 var l:=Label.new();l.text=value;l.add_theme_font_size_override("font_size",size);parent.add_child(l);return l
func equip(index:int,ribbon:bool)->void:
 if not journey.data.unlocked.has(journey.TITLES[index]):return
 if ribbon:journey.data.colour=index
 else:journey.data.title=journey.TITLES[index]
 journey.save();render()
func render()->void:
 for child in body.get_children():body.remove_child(child);child.queue_free()
 label(body,"YOUR JOURNEY • COSMETICS",26).modulate=Color("#efd19b")
 label(body,"Choose a title and ribbon directly. These rewards change appearance only.")
 for step in [["hero","Choose a hero"],["practice","Land three training hits"],["grove","Enter Whispering Grove"]]:
  label(body,("Done • " if bool(journey.data.quest.get(step[0],false)) else "Next • ")+str(step[1]),15).modulate=Color("#b4d6ba")
 var welcome:=CheckButton.new();welcome.text="Show welcome checklist";welcome.custom_minimum_size.y=40;welcome.button_pressed=not bool(journey.data.skipped);welcome.toggled.connect(func(value:bool):journey.data.skipped=not value;journey.save());body.add_child(welcome)
 var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;body.add_child(scroll)
 var choices:=VBoxContainer.new();choices.size_flags_horizontal=Control.SIZE_EXPAND_FILL;choices.add_theme_constant_override("separation",8);scroll.add_child(choices)
 for index in journey.TITLES.size():
  var title:String=journey.TITLES[index];var unlocked:bool=title in journey.data.unlocked
  var row:=HBoxContainer.new();row.add_theme_constant_override("separation",12);choices.add_child(row)
  var name:=label(row,title+" • "+("earned" if unlocked else "locked"));name.custom_minimum_size=Vector2(270,40);name.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;name.tooltip_text=REQUIREMENTS[index]
  var choose:=Button.new();choose.text="Title equipped" if title==journey.data.title else "Equip title";choose.custom_minimum_size=Vector2(180,40);choose.disabled=not unlocked;choose.tooltip_text=REQUIREMENTS[index];choose.pressed.connect(equip.bind(index,false));row.add_child(choose)
  var colour:=Button.new();colour.text="Ribbon equipped" if index==int(journey.data.colour) else "Equip ribbon";colour.custom_minimum_size=Vector2(180,40);colour.disabled=not unlocked;colour.modulate=journey.COLOURS[index] if unlocked else Color("#7d8990");colour.pressed.connect(equip.bind(index,true));colour.tooltip_text=REQUIREMENTS[index];row.add_child(colour)
 var close:=Button.new();close.text="Done • Enter / Escape";close.custom_minimum_size.y=44;close.pressed.connect(func():journey.game.menu="";journey.game.mobile.reset_controls());body.add_child(close)
 signature=JSON.stringify(journey.data)
func _process(_delta:float)->void:
 if journey==null:return
 var show:bool=journey.game.get("menu")=="journey_cosmetics"
 panel.visible=show
 if show and (not was_open or signature!=JSON.stringify(journey.data)):render()
 was_open=show
 if not show:return
 var view:=get_viewport().get_visible_rect().size;var f:=minf(1,minf((view.x-24)/900,(view.y-24)/620));panel.scale=Vector2.ONE*f;panel.position=(view-panel.size*panel.scale)*.5
