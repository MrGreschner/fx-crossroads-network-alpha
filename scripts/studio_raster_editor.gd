extends CanvasLayer
## Editable layers and operations travel with the flattened game PNG.
signal saved(value:Dictionary)
const UI=preload("res://scripts/studio_ui.gd")
var workshop:Node
var value:Dictionary
var panel:PanelContainer
var canvas:Control
var active=0
var body:VBoxContainer
var status:Label
var mask=false
var brush:Image
func setup(owner:Node,source:Dictionary)->void:
 workshop=owner;value=source.duplicate(true);layer=79
 if not value.settings.has("filename"):value.settings.filename=value.name.validate_filename()+".png"
 if value.layers.is_empty():value.layers=[{"name":"Base artwork","image":value.image,"visible":true}]
 var shade=ColorRect.new();shade.color=Color("#071c27");shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(shade)
 panel=PanelContainer.new();panel.size=Vector2(1090,700);add_child(panel);UI.apply(panel)
 var col=VBoxContainer.new();panel.add_child(col);workshop.label(col,"RASTER STUDIO • editable layers",25)
 var top=HBoxContainer.new();col.add_child(top);workshop.button(top,"Apply artwork & source",finish);workshop.button(top,"Cancel",queue_free)
 var split=HBoxContainer.new();split.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(split)
 canvas=preload("res://scripts/studio_pixel_canvas.gd").new();canvas.size_flags_horizontal=Control.SIZE_EXPAND_FILL;split.add_child(canvas);canvas.load_png(value.layers[active].image);load_mask()
 if not str(value.get("brush","")).is_empty():brush=Image.new();brush.load_png_from_buffer(Marshalls.base64_to_raw(value.brush))
 var scroll=ScrollContainer.new();scroll.custom_minimum_size.x=460;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;split.add_child(scroll);body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body);preload("res://scripts/touch_list_scroll.gd").attach(scroll).form_controls=true
 status=workshop.label(col,"Edit one layer at a time. Select: drag a rectangle. Source layers, document settings and operation history stay in the object file.",15)
 render()
func record(action:String)->void:
 if value.operations.size()>=100:value.operations.pop_front()
 value.operations.append(action)
func sync()->void:value.layers[active].image=canvas.encoded()
func render()->void:
 workshop.clear(body)
 var choose=OptionButton.new();body.add_child(choose)
 for l in value.layers:choose.add_item(l.name)
 choose.select(active);choose.item_selected.connect(func(n:int):sync();active=n;canvas.load_png(value.layers[n].image);load_mask();render())
 var title=LineEdit.new();title.text=value.layers[active].name;body.add_child(title);title.text_changed.connect(func(t:String):value.layers[active].name=t.left(60))
 var row=HBoxContainer.new();body.add_child(row)
 workshop.button(row,"Add layer",func():
  if value.layers.size()>=4:return
  sync();var img=Image.create(canvas.image.get_width(),canvas.image.get_height(),false,Image.FORMAT_RGBA8);img.fill(Color.TRANSPARENT);value.layers.append({"name":"Layer "+str(value.layers.size()+1),"image":Marshalls.raw_to_base64(img.save_png_to_buffer()),"visible":true});active=value.layers.size()-1;canvas.load_png(value.layers[active].image);record("Create layer");render()
 )
 workshop.button(row,"Move layer up",func():if active<value.layers.size()-1:sync();var l=value.layers[active];value.layers[active]=value.layers[active+1];value.layers[active+1]=l;active+=1;record("Arrange layers");render())
 var visible=CheckButton.new();visible.text="Include layer in export";visible.button_pressed=value.layers[active].visible;body.add_child(visible);visible.toggled.connect(func(on:bool):value.layers[active].visible=on;record("Layer visibility"))
 var tools=OptionButton.new();body.add_child(tools)
 for t in ["Pencil","Eraser","Fill","Pick","Select"]:tools.add_item(t)
 tools.item_selected.connect(func(n:int):canvas.tool=tools.get_item_text(n);record("Tool: "+canvas.tool))
 var swatch=ColorPickerButton.new();swatch.color=canvas.ink;body.add_child(swatch);swatch.color_changed.connect(func(c:Color):canvas.ink=c)
 var hex=LineEdit.new();hex.placeholder_text="#RRGGBB or #RRGGBBAA";body.add_child(hex);hex.text_submitted.connect(func(t:String):if Color.html_is_valid(t):canvas.ink=Color(t);swatch.color=canvas.ink)
 var transforms=HBoxContainer.new();body.add_child(transforms)
 for action in ["Mirror","Flip","←","→"]:workshop.button(transforms,action,func():canvas.transform_pose(action);record("Transform selection: "+action))
 workshop.button(body,"Clear selection",func():canvas.selection=Rect2i();canvas.queue_redraw())
 workshop.button(body,"Undo last stroke",canvas.undo)
 workshop.button(body,"Gradient • ink to transparent",func():effect("Gradient"))
 workshop.button(body,"Checker pattern • selected area",func():effect("Pattern"))
 workshop.button(body,"Correct tone • brighten selected area",func():effect("Tone"))
 workshop.button(body,"Mask • hide outside selection",func():effect("Mask"))
 workshop.button(body,"Remove layer mask",func():value.layers[active].erase("mask");canvas.mask_image=null;canvas.queue_redraw();record("Remove layer mask"))
 workshop.button(body,"Create custom brush from selection",func():
  brush=canvas.image.get_region(area());value.brush=Marshalls.raw_to_base64(brush.save_png_to_buffer());record("Create custom brush");status.text="Brush captured. Use Stamp brush to apply it at the centre of your selection."
 )
 workshop.button(body,"Stamp custom brush",func():
  if brush==null:status.text="Select an area and capture a brush first.";return
  canvas.snapshot();canvas.image.blend_rect(brush,Rect2i(Vector2i.ZERO,brush.get_size()),area().position);canvas.queue_redraw();record("Stamp custom brush")
 )
 workshop.button(body,"Document & output settings",settings)
 workshop.button(body,"Pixel art tips",func():
  var tips=[{"title":"Layers, selections and masks","body":"Layers separate parts of your image. A selection limits edits; masks hide areas without erasing the original pixels. Keep editable layers and a flattened PNG for playing. RGB colours suit screens."},{"title":"Readable game artwork","body":"Use a clear silhouette, a small palette and enough contrast to read against your realm. Test the artwork at its actual game size. Keep walking frames aligned so motion feels smooth."}]
  if preload("res://scripts/education_access.gd").student():tips.append({"title":"Module evidence","body":"Keep drafts, finished exports and tool history for your graphics assignments. Your teacher reviews design quality and the work itself."})
  UI.lesson(self,"PIXEL ART TIPS","Optional tools and techniques for your creations.",tips)
 )
func area()->Rect2i:return canvas.selection if canvas.selection.has_area() else Rect2i(Vector2i.ZERO,canvas.image.get_size())
func effect(kind:String)->void:
 canvas.snapshot();var r=area();var img:Image=canvas.image
 if kind=="Mask":
  var alpha=Image.create(img.get_width(),img.get_height(),false,Image.FORMAT_RGBA8);alpha.fill(Color.TRANSPARENT);alpha.fill_rect(r,Color.WHITE);value.layers[active].mask=Marshalls.raw_to_base64(alpha.save_png_to_buffer());canvas.mask_image=alpha;record("Mask");canvas.queue_redraw();return
 for y in img.get_height():
  for x in img.get_width():
   var at=Vector2i(x,y)
   if kind=="Mask":
    if not r.has_point(at):img.set_pixelv(at,Color.TRANSPARENT)
   elif r.has_point(at):
    if kind=="Gradient":img.set_pixelv(at,Color(canvas.ink,1-float(y-r.position.y)/maxi(1,r.size.y)))
    elif kind=="Pattern" and (x+y)%2==0:img.set_pixelv(at,canvas.ink)
    elif kind=="Tone":var c=img.get_pixelv(at);img.set_pixelv(at,Color(c.lightened(.1),c.a))
 canvas.queue_redraw();record(kind)
func settings()->void:
 var dialog=AcceptDialog.new();dialog.title="Document settings";add_child(dialog);UI.apply(dialog)
 var col=VBoxContainer.new();dialog.add_child(col)
 workshop.label(col,"RGBA8 • RGB • square pixels • lossless PNG\nEditable layers are included in the JSON project.",18)
 var name=LineEdit.new();name.text=str(value.settings.get("filename",value.name.validate_filename()+".png"));col.add_child(name);name.text_changed.connect(func(t:String):value.settings.filename=t.left(100))
 var credits=LineEdit.new();credits.text=value.source;credits.placeholder_text="Creator / source / licence";col.add_child(credits);credits.text_changed.connect(func(t:String):value.source=t.left(200))
 for side in [32,64,128]:workshop.button(col,"Resize document to "+str(side)+" × "+str(side),func():
  sync()
  for l in value.layers:
   var img=Image.new();img.load_png_from_buffer(Marshalls.base64_to_raw(l.image));img.resize(side,side,Image.INTERPOLATE_NEAREST);l.image=Marshalls.raw_to_base64(img.save_png_to_buffer())
   if not str(l.get("mask","")).is_empty():var alpha=Image.new();alpha.load_png_from_buffer(Marshalls.base64_to_raw(l.mask));alpha.resize(side,side,Image.INTERPOLATE_NEAREST);l.mask=Marshalls.raw_to_base64(alpha.save_png_to_buffer())
  canvas.load_png(value.layers[active].image);load_mask();record("Document resize: "+str(side));dialog.queue_free()
 )
 dialog.confirmed.connect(dialog.queue_free);dialog.popup_centered(Vector2i(570,370))
func finish()->void:
 sync();var merged=Image.create(canvas.image.get_width(),canvas.image.get_height(),false,Image.FORMAT_RGBA8);merged.fill(Color.TRANSPARENT)
 for l in value.layers:
  if not l.visible:continue
  var image=Image.new();image.load_png_from_buffer(Marshalls.base64_to_raw(l.image));image.resize(merged.get_width(),merged.get_height(),Image.INTERPOLATE_NEAREST)
  if not str(l.get("mask","")).is_empty():
   var alpha=Image.new();alpha.load_png_from_buffer(Marshalls.base64_to_raw(l.mask));alpha.resize(image.get_width(),image.get_height(),Image.INTERPOLATE_NEAREST)
   for y in image.get_height():
    for x in image.get_width():var c=image.get_pixel(x,y);image.set_pixel(x,y,Color(c,c.a*alpha.get_pixel(x,y).a))
  merged.blend_rect(image,Rect2i(Vector2i.ZERO,image.get_size()),Vector2i.ZERO)
 value.image=Marshalls.raw_to_base64(merged.save_png_to_buffer());value.settings.dimensions=[merged.get_width(),merged.get_height()];record("Export flattened PNG + editable source");saved.emit(value);queue_free()
func _process(_dt:float)->void:
 var view=get_viewport().get_visible_rect().size;panel.size=Vector2(1090,700);var fit=minf(1,minf((view.x-24)/panel.size.x,(view.y-24)/panel.size.y));panel.scale=Vector2.ONE*fit;panel.position=(view-panel.size*fit)*.5

func load_mask()->void:
 canvas.mask_image=null
 if not str(value.layers[active].get("mask","")).is_empty():
  canvas.mask_image=Image.new();canvas.mask_image.load_png_from_buffer(Marshalls.base64_to_raw(value.layers[active].mask))
