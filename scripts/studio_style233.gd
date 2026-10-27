extends CanvasLayer
const UI=preload("res://scripts/studio_ui.gd")
var panel:PanelContainer
func text(parent:Node,value:String,size:int=17)->Label:
 var l=Label.new();l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",size);parent.add_child(l);return l
func setup()->void:
 layer=195;add_to_group("studio_style_guide233")
 var shade=ColorRect.new();shade.color=Color("#081e29");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();panel.size=Vector2(980,650);add_child(panel);UI.apply(panel)
 var body=VBoxContainer.new();panel.add_child(body);var top=HBoxContainer.new();body.add_child(top);text(top,"GRAPHIC STYLE EXPLANATION",25).size_flags_horizontal=Control.SIZE_EXPAND_FILL
 var close=Button.new();close.text="Back to my artwork";close.custom_minimum_size.y=42;close.pressed.connect(queue_free);top.add_child(close)
 text(body,"Soft coloured edges • matte storybook shading • neutral poses",18)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;body.add_child(scroll)
 var col=VBoxContainer.new();col.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(col);preload("res://scripts/touch_list_scroll.gd").attach(scroll).form_controls=true
 var refs=HBoxContainer.new();col.add_child(refs)
 for id in ["ram","cat","book"]:
  var card=UI.card(refs,{"ram":"Young Ram","cat":"Crossroads Cat","book":"Living Book"}[id]);card.get_parent().size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var img=TextureRect.new();img.texture=preload("res://scripts/core_hero_art.gd").texture(id,"idle");img.custom_minimum_size=Vector2(160,160);img.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;img.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;img.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;card.add_child(img)
 text(col,"These are enlarged references. Judge detail at the small gameplay size, too.",14)
 var entries=[
 ["1 • Work on an 80 × 80 transparent canvas","Our refreshed hero frames use an 80 × 80 canvas. Keep the main body about 60–66 pixels tall, centred near x = 40, with feet or hover contact near y = 74. Leave clear space for ears, tails and equipment. Small animals and objects may be shorter. Existing drawings keep their size until you choose Fit to 80 × 80."],
 ["2 • Keep your own character","Preserve its species, personality, colours, silhouette and signature equipment. A ball bounces, a book hovers, a porcupine walks. Copy the references' simplicity and shading, not their anatomy, uniform or accessories."],
 ["3 • Soft edges, crisp pixels","Draw deliberate square-pixel clusters with only a few related midtones per material. Use muted brown contours on warm materials, slate/teal on cool cloth, or plum on purple details. Add gentle matte shadows to show fabric, fur, wood or metal. Avoid thick continuous black borders, white sticker rims, glossy highlights and blur around the whole character."],
 ["4 • Neutral movement and attacks","Keep head and torso front-facing, with both eyes visible where appropriate. Walk A and Walk B gently alternate feet or paws; floating objects change pages, cloth or hover details. Align the face and body between frames. No side-facing run or sideways lunge: the same drawing must work in every travel and aiming direction. Keep equipment on its established side."],
 ["5 • Copy once, then change the action","In any pixel editor, press Copy current picture. Open the destination pose or an Ability Lab attack/charge frame and press Paste picture. For example: copy Walk 1, open your Special ability's Attack frames, add a frame, then paste and edit. Paste copies the whole picture at its original pixel size. It does not link the two images. Undo restores the destination; Save image applies it."],
 ["6 • Keep the hero and effects readable","Hero Workshop uses Idle, Walk 1, Walk 2 and Primary attack body images. Ability Lab holds Primary, Secondary and Special attack/charge-effect frames. Keep effects contained and use the live replay: drawn effects explain the action, while range/radius settings determine hits. Our official six-pose sheets are a useful reference for the three abilities; a custom hero's body slots and effect frames are separate."],
 ["7 • A quick finishing check","Preview at normal gameplay size. Can you recognise the silhouette and equipment? Do both walking steps move different feet? Does the head stay steady? Do transparent edges stay clean? Can the attack aim left, right, up or down without the picture looking backwards? Test on dark and light scenery before sharing."]]
 for entry in entries:text(UI.card(col,entry[0]),entry[1])
 var palette=HBoxContainer.new();col.add_child(palette)
 for color in ["#795b4c","#b58e68","#dfc69e","#425e67","#77999c","#5b486d","#aa91b3"]:
  var sw=ColorRect.new();sw.color=Color(color);sw.custom_minimum_size=Vector2(90,30);sw.tooltip_text=color;palette.add_child(sw)
 text(col,"Example muted colours — use colours that suit your own hero.",14)
func _process(_dt:float)->void:
 var view=get_viewport().get_visible_rect().size;var fit=minf(1,minf((view.x-24)/980,(view.y-24)/650));panel.scale=Vector2.ONE*fit;panel.position=(view-panel.size*fit)*.5
func _input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:queue_free();get_viewport().set_input_as_handled()
