extends CanvasLayer
## Scrollable teaching cards and assignment briefs; no combat or profile changes.
const UI=preload("res://scripts/studio_ui.gd")
var panel:PanelContainer
var content:VBoxContainer
var scroll:ScrollContainer
var topics:Array=[]
var selected=0
var choices:Array[Button]=[]
func setup(title:String,subtitle:String,entries:Array)->void:
 layer=90
 var ancestor=get_parent()
 while ancestor!=null:
  if ancestor is CanvasLayer:layer=maxi(layer,ancestor.layer+1)
  ancestor=ancestor.get_parent()
 add_to_group("studio_notes_overlay240");topics=entries
 var shade=ColorRect.new();shade.color=Color(.015,.04,.065,.96);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();panel.size=Vector2(960,620);add_child(panel);UI.apply(panel)
 var body=VBoxContainer.new();panel.add_child(body)
 var header=HBoxContainer.new();body.add_child(header)
 var label=Label.new();label.text=title;label.add_theme_font_size_override("font_size",26);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(label)
 var close=Button.new();close.text="Close";close.custom_minimum_size.y=44;header.add_child(close);close.pressed.connect(queue_free)
 var intro=Label.new();intro.text=subtitle;intro.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;intro.add_theme_color_override("font_color",Color("#b8d3d8"));body.add_child(intro)
 var split=HBoxContainer.new();split.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(split)
 var nav_scroll=ScrollContainer.new();nav_scroll.custom_minimum_size.x=250;nav_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;split.add_child(nav_scroll)
 var nav=VBoxContainer.new();nav.size_flags_horizontal=Control.SIZE_EXPAND_FILL;nav_scroll.add_child(nav)
 for i in topics.size():
  var b=Button.new();b.text=str(i+1)+"  "+str(topics[i].title);b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.custom_minimum_size=Vector2(230,54);b.clip_text=true;b.tooltip_text=topics[i].title;nav.add_child(b);choices.append(b);b.pressed.connect(show_topic.bind(i))
 preload("res://scripts/touch_list_scroll.gd").attach(nav_scroll)
 scroll=ScrollContainer.new();scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;split.add_child(scroll)
 content=VBoxContainer.new();content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(content);preload("res://scripts/touch_list_scroll.gd").attach(scroll)
 var hint=Label.new();hint.text="Choose a topic • scroll to explore • Escape closes this page";hint.add_theme_font_size_override("font_size",14);hint.add_theme_color_override("font_color",Color("#9dbcc4"));body.add_child(hint)
 show_topic(0);UI.enter(panel)
func show_topic(index:int)->void:
 selected=index
 for child in content.get_children():content.remove_child(child);child.queue_free()
 for i in choices.size():choices[i].add_theme_stylebox_override("normal",UI.box("#35616d" if i==index else "#183844","#edcf91" if i==index else "#355b68"))
 var topic:Dictionary=topics[index]
 var heading=Label.new();heading.text=topic.title;heading.add_theme_font_size_override("font_size",25);heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;content.add_child(heading)
 for pair in [["summary","THE IDEA"],["body","HOW TO APPROACH IT"],["task","TRY THIS"],["deliver","WHAT TO SHARE"],["criteria","CHECK YOUR WORK"]]:
  if not str(topic.get(pair[0],"")).is_empty():
   var card=UI.card(content,pair[1]);var text=Label.new();text.text=str(topic[pair[0]]);text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;text.add_theme_font_size_override("font_size",17);card.add_child(text)
 scroll.scroll_vertical=0
func _process(_delta:float)->void:
 var partner=get_tree().root.get_node_or_null("FXStudioPartner")
 var view=partner.editor_view() if partner!=null else get_viewport().get_visible_rect().size;panel.size=Vector2(960,620);var factor=minf(1,minf((view.x-24)/panel.size.x,(view.y-24)/panel.size.y));panel.scale=Vector2.ONE*factor;panel.position=(view-panel.size*factor)*.5
func _input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:queue_free();get_viewport().set_input_as_handled()
