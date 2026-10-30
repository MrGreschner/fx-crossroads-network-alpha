extends CanvasLayer
const UI=preload("res://scripts/studio_ui.gd")
signal saved(encoded:String)
var close_button:Button
var heading:Label
var panel:PanelContainer
var canvas:Control
var hex:LineEdit
var swatch:ColorPickerButton
var hint:Label
var previews:Dictionary={}
func setup(encoded:String,title:String,poses:Dictionary={},blank_side:int=80)->void:
 layer=178
 var shade=ColorRect.new();shade.color=Color(.01,.03,.06,.96);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();panel.size=Vector2(920,620);add_child(panel)
 UI.apply(panel);UI.enter(panel)
 var body=VBoxContainer.new();panel.add_child(body)
 heading=Label.new();heading.text="PIXEL STUDIO • "+title;heading.add_theme_font_size_override("font_size",24);heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;body.add_child(heading)
 var split=HBoxContainer.new();split.size_flags_vertical=Control.SIZE_EXPAND_FILL;body.add_child(split)
 canvas=preload("res://scripts/studio_pixel_canvas.gd").new();canvas.size_flags_vertical=Control.SIZE_EXPAND_FILL;split.add_child(canvas);canvas.load_png(encoded,blank_side)
 var tools_scroll=ScrollContainer.new();tools_scroll.custom_minimum_size.x=450;tools_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;split.add_child(tools_scroll);var tools=VBoxContainer.new();tools.size_flags_horizontal=Control.SIZE_EXPAND_FILL;tools_scroll.add_child(tools);preload("res://scripts/touch_list_scroll.gd").attach(tools_scroll).form_controls=true
 var tools_heading=Label.new();tools_heading.text="TOOLS & PALETTE";tools_heading.add_theme_color_override("font_color",Color("#edcf91"));tools.add_child(tools_heading)
 var copy_row=HBoxContainer.new();tools.add_child(copy_row)
 button(copy_row,"Copy current picture",copy_picture);button(copy_row,"Paste picture",paste_picture)
 button(tools,"Graphic style explanation",func():preload("res://scripts/studio_art233.gd").open_guide(self))
 size_label=Label.new();size_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;size_label.custom_minimum_size.x=430;tools.add_child(size_label)
 var picker=OptionButton.new();tools.add_child(picker)
 for name in ["Pencil","Eraser","Fill","Pick"]:picker.add_item(name)
 picker.item_selected.connect(func(index:int):canvas.tool=picker.get_item_text(index))
 swatch=ColorPickerButton.new();swatch.color=canvas.ink;swatch.custom_minimum_size.y=38;tools.add_child(swatch)
 hex=LineEdit.new();hex.text="#ffd778";hex.placeholder_text="#RRGGBB or #RRGGBBAA";tools.add_child(hex)
 swatch.color_changed.connect(func(value:Color):canvas.ink=value;hex.text="#"+value.to_html(value.a<1))
 hex.text_submitted.connect(func(value:String):
  if Color.html_is_valid(value):canvas.ink=Color(value);swatch.color=canvas.ink;hint.text="Colour ready."
  else:hint.text="Use a valid hex colour, for example #7bd8de."
 )
 var palette=HBoxContainer.new();tools.add_child(palette)
 for value in ["#f5db9c","#b57651","#79bfd2","#9ac695","#b499d0","#eb8c7b","#ffffff","#142c3c"]:
  var b=Button.new();b.text="●";b.modulate=Color(value);palette.add_child(b);b.pressed.connect(func():canvas.ink=Color(value);swatch.color=canvas.ink;hex.text=value)
 var transforms=HBoxContainer.new();tools.add_child(transforms)
 for action in ["Mirror","Flip","←","→","↑","↓"]:button(transforms,action,func():canvas.transform_pose(action))
 button(tools,"Undo stroke / paste",canvas.undo)
 button(tools,"Fit to 80 × 80",func():canvas.fit_hero_canvas();hint.text="Fitted to 80 × 80 with crisp pixels. Undo restores the previous size.")
 var sizes=HBoxContainer.new();tools.add_child(sizes)
 for side in [80,32,64]:button(sizes,"New "+str(side)+" × "+str(side),func():
  var confirm=ConfirmationDialog.new();confirm.dialog_text="Replace this canvas with a blank grid? Unsaved pixels will be lost.";add_child(confirm);confirm.confirmed.connect(func():canvas.load_png("",side);confirm.queue_free());confirm.canceled.connect(confirm.queue_free);UI.apply(confirm);confirm.popup_centered()
 )
 if not poses.is_empty():
  var p=OptionButton.new();p.add_item("Copy an existing pose…");tools.add_child(p)
  for pose in poses:p.add_item(str(pose))
  p.item_selected.connect(func(index:int):if index>0:canvas.replace_picture(str(poses[p.get_item_text(index)]));hint.text="Copied pose into this editor. Undo restores your previous picture.")
 button(tools,"Design lesson • suggestions",lesson)
 hint=Label.new();hint.add_theme_font_size_override("font_size",15);hint.add_theme_color_override("font_color",Color("#b8d3d8"));hint.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;hint.text="Copy idle into walk 1 / walk 2, shift feet or wings by 1–2 pixels, and keep the face aligned. Copy and paste work across pose and attack-frame editors. Paste is independent and can be undone.";tools.add_child(hint)
 var footer=HBoxContainer.new();body.add_child(footer);button(footer,"Save image",func():flush_live();saved.emit(canvas.encoded());queue_free());button(footer,"Cancel",queue_free)
 canvas.changed.connect(func():swatch.color=canvas.ink;hex.text="#"+canvas.ink.to_html(canvas.ink.a<1))
func button(parent:Node,text:String,action:Callable)->void:
 var b=Button.new();b.text=text;b.custom_minimum_size.y=42;b.pressed.connect(action);parent.add_child(b)
 if text=="Save image":UI.accent(b)
 if text=="Cancel":close_button=b
func lesson()->void:
 UI.lesson(self,"PIXEL DESIGN NOTES","Build a readable silhouette, then bring it to life.",preload("res://scripts/studio_lessons.gd").design())
func _process(_delta:float)->void:
 if size_label!=null and canvas!=null:size_label.text="Canvas: %d × %d pixels • hero reference: 80 × 80"%[canvas.image.get_width(),canvas.image.get_height()]
 live_tick+=_delta
 if live_tick>=.12:live_tick=0;flush_live()
 var partner_view=get_tree().root.get_node_or_null("FXStudioPartner")
 var view=partner_view.editor_view() if partner_view!=null else get_viewport().get_visible_rect().size;panel.size=Vector2(920,620);var scale_factor=minf(1,minf((view.x-20)/panel.size.x,(view.y-20)/panel.size.y));panel.scale=Vector2.ONE*scale_factor;panel.position=(view-panel.size*scale_factor)*.5

func _input(event:InputEvent)->void:
 if not get_tree().get_nodes_in_group("studio_style_guide233").is_empty() or not get_tree().get_nodes_in_group("studio_notes_overlay240").is_empty():return
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:flush_live();queue_free();get_viewport().set_input_as_handled()

var live_path:Array=[]
var live_baseline:Image
var live_dirty=false
var live_tick=0.0
func bind_live(path:Array)->void:
 live_path=path;live_baseline=canvas.image.duplicate();add_to_group("studio_live_pixels")
 canvas.changed.connect(func():live_dirty=true)
 var partner=get_tree().root.get_node_or_null("FXStudioPartner")
 if partner!=null and not partner.code.is_empty():
  heading.text+=" • LIVE";close_button.text="Close editor"
  hint.text="TWO PENCILS • live edits are shared immediately. Latest edit wins on the same pixel. Undo changes your recent stroke; closing keeps shared edits.\n"+hint.text
  partner.set_image(live_path,canvas.encoded());partner.sync_draft()
func flush_live()->void:
 if not live_dirty or live_path.is_empty():return
 var partner=get_tree().root.get_node_or_null("FXStudioPartner")
 if partner==null or partner.code.is_empty() or partner.waiting or not partner.outgoing.is_empty():return
 var runs:Array=[];var image:Image=canvas.image
 if image.get_size()!=live_baseline.get_size():
  # Canvas size changes are a deliberate full reset, not a paint stroke.
  partner.set_image(live_path,canvas.encoded());live_baseline=image.duplicate();live_dirty=false;return
 var run:Array=[]
 for y in image.get_height():
  for x in image.get_width():
   var at=y*image.get_width()+x;var color=image.get_pixel(x,y)
   if color==live_baseline.get_pixel(x,y):continue
   var hex_color="#"+color.to_html(true)
   if not run.is_empty() and run[0]+run[1]==at and run[2]==hex_color:run[1]+=1
   else:
    if not run.is_empty():runs.append(run)
    run=[at,1,hex_color]
 if not run.is_empty():runs.append(run)
 if runs.size()>4096:hint.text="This transform changes too many separate pixels; save the image to share it.";return
 if not runs.is_empty():
  partner.local_pixels(live_path,image.get_width(),image.get_height(),runs,canvas.encoded())
  if canvas.last.x>=0:partner.send({"type":"partner_cursor","path":live_path,"x":canvas.last.x,"y":canvas.last.y})
 live_baseline=image.duplicate();live_dirty=false
func remote_image(encoded:String)->void:
 var image=Image.new()
 if image.load_png_from_buffer(Marshalls.base64_to_raw(encoded))!=OK:return
 image.convert(Image.FORMAT_RGBA8)
 # Keep pixels drawn since the last send; they will be the next ordered edit.
 if live_dirty and live_baseline!=null and image.get_size()==canvas.image.get_size() and image.get_size()==live_baseline.get_size():
  for y in image.get_height():
   for x in image.get_width():
    if canvas.image.get_pixel(x,y)!=live_baseline.get_pixel(x,y):image.set_pixel(x,y,canvas.image.get_pixel(x,y))
 canvas.image=image;canvas.queue_redraw()
 if not live_dirty:live_baseline=image.duplicate()

var size_label:Label
func copy_picture()->void:
 if preload("res://scripts/studio_art233.gd").copy_picture(canvas.encoded(),heading.text):hint.text="Picture copied. Open any destination pose or attack frame, then Paste picture."
func paste_picture()->void:
 var clip=preload("res://scripts/studio_art233.gd")
 if clip.clipboard.is_empty():hint.text="Nothing copied yet. Use Copy current picture in the source editor first.";return
 if canvas.replace_picture(clip.clipboard):hint.text="Pasted an independent picture. Edit it, then Save image. Undo restores the destination."
