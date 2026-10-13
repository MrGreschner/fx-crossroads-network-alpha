extends CanvasLayer
const UI=preload("res://scripts/studio_ui.gd")
var lab:Node
var panel:PanelContainer
var slot="animation"
func setup(owner:Node,kind:String="animation")->void:
 lab=owner;slot=kind;layer=75
 var shade=ColorRect.new();shade.color=Color(.015,.04,.065,.96);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();panel.size=Vector2(940,620);add_child(panel);UI.apply(panel);UI.enter(panel)
 var body=VBoxContainer.new();panel.add_child(body)
 var header=HBoxContainer.new();body.add_child(header);lab.workshop.label(header,"CHARGE ANIMATION" if slot=="charge_animation" else "ATTACK ANIMATION",26).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 lab.workshop.button(header,"Done",queue_free)
 lab.workshop.label(body,"Draw a readable wind-up or attack. Up to eight frames play at 8 FPS.",16)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;body.add_child(scroll)
 var grid=GridContainer.new();grid.columns=4;grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(grid);preload("res://scripts/touch_list_scroll.gd").attach(scroll)
 var frames:Array=lab.attack.get(slot,[])
 for i in frames.size():
  var card=UI.card(grid,"Frame "+str(i+1));var preview=preload("res://scripts/studio_animation.gd").new();card.add_child(preview);preview.setup([frames[i]]);preview.show_caption=false;preview.custom_minimum_size=Vector2(150,105)
  lab.workshop.button(card,"Edit pixels",func():lab.edit_frame(i,self,slot))
 if frames.is_empty():
  var empty=PanelContainer.new();empty.custom_minimum_size=Vector2(800,130);empty.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(empty);grid.hide()
  var col=UI.card(empty,"YOUR FIRST FRAME","Start with one image. Copy it to build a consistent animation.")
  lab.workshop.label(col,"Use a clear silhouette and a small palette. Preview the motion below as you add frames.",16)
 var actions=HBoxContainer.new();body.add_child(actions)
 if frames.size()<8:UI.accent(lab.workshop.button(actions,"Add / copy last frame",func():lab.edit_frame(frames.size(),self,slot)))
 if not frames.is_empty():lab.workshop.button(actions,"Remove last frame",func():lab.attack[slot].pop_back();lab.apply_code();lab.animation_editor(slot);queue_free())
 var preview_card=UI.card(body,"LIVE PREVIEW","Artwork shows the action; range and radius still control collision.")
 var animated=preload("res://scripts/studio_animation.gd").new();preview_card.add_child(animated);animated.setup(frames);animated.interval=.125;animated.custom_minimum_size=Vector2(130,105)
func _process(_delta:float)->void:
 var view=get_viewport().get_visible_rect().size;panel.size=Vector2(940,620);var factor=minf(1,minf((view.x-24)/panel.size.x,(view.y-24)/panel.size.y));panel.scale=Vector2.ONE*factor;panel.position=(view-panel.size*factor)*.5
func _input(event:InputEvent)->void:
 if visible and event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:queue_free();get_viewport().set_input_as_handled()
