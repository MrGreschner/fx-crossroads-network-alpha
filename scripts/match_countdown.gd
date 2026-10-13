extends CanvasLayer
## Above both the lobby and world HUD: never hidden behind the party controls.
var game:Node
var card:PanelContainer
var number:Label
var heading:Label
func setup(owner:Node)->void:
 game=owner;layer=60
 card=PanelContainer.new();card.mouse_filter=Control.MOUSE_FILTER_IGNORE;card.size=Vector2(560,280);add_child(card)
 var skin:=StyleBoxFlat.new();skin.bg_color=Color("#102831",.97);skin.border_color=Color("#ffe085");skin.set_border_width_all(3);skin.set_corner_radius_all(18);skin.set_content_margin_all(22);card.add_theme_stylebox_override("panel",skin)
 var body:=VBoxContainer.new();body.mouse_filter=Control.MOUSE_FILTER_IGNORE;body.add_theme_constant_override("separation",4);card.add_child(body)
 heading=Label.new();heading.text="MATCH STARTING";heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;heading.add_theme_font_size_override("font_size",30);body.add_child(heading)
 number=Label.new();number.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;number.add_theme_font_size_override("font_size",104);number.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(number)
 var hint:=Label.new();hint.text="Host pressed Start • get ready!";hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.add_theme_font_size_override("font_size",19);hint.modulate=Color("#d6e4e8");body.add_child(hint)
 for child in body.get_children():child.mouse_filter=Control.MOUSE_FILTER_IGNORE
 update_view()
func update_view()->void:
 if not is_instance_valid(game):card.hide();return
 card.visible=game.started and game.start_countdown>0
 if not card.visible:return
 var count:=ceili(game.start_countdown);var tint:=Color("#ff7770") if count<=3 else Color("#ffe085")
 number.text=str(count);number.modulate=tint;heading.modulate=tint
 var skin:StyleBoxFlat=card.get_theme_stylebox("panel");skin.border_color=tint
 var view:=get_viewport().get_visible_rect().size;var factor:=minf(1,minf((view.x-24)/560,(view.y-24)/280));card.scale=Vector2.ONE*factor;card.position=(view-card.size*factor)*.5
func _process(_delta:float)->void:update_view()
