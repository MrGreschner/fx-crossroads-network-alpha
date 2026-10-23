extends CanvasLayer
## Public editable vector composition; SVG paths and matching PNG remain paired.
const UI=preload("res://scripts/studio_ui.gd")
const PATH="user://fx_vector_studio.json"
var game:Node
var panel:PanelContainer
var canvas:Control
var title:LineEdit
var status:Label
var shapes:Array=[]
var selected=0
var colour:ColorPickerButton
var properties:VBoxContainer
var picker:OptionButton
var on_capture:Callable
var previous_menu=""
var previous_process=true
var syncing=false
func button(parent:Node,text:String,fn:Callable)->Button:
 var b=Button.new();b.text=text;b.custom_minimum_size.y=40;parent.add_child(b);b.pressed.connect(fn);return b
func label(parent:Node,text:String,size:int=17)->Label:
 var l=Label.new();l.text=text;l.add_theme_font_size_override("font_size",size);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;parent.add_child(l);return l
func setup(owner:Node,capture:Callable=Callable())->void:
 game=owner.game if owner.get("game")!=null else owner;on_capture=capture;layer=126;process_mode=Node.PROCESS_MODE_ALWAYS;previous_menu=game.menu;previous_process=game.is_processing();game.menu="vector_studio";game.set_process(false)
 var bg=ColorRect.new();bg.color=Color("#10232c");bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(bg)
 panel=PanelContainer.new();add_child(panel);UI.apply(panel);var col=VBoxContainer.new();panel.add_child(col)
 var head=HBoxContainer.new();col.add_child(head);var heading=label(head,"VECTOR STUDIO • compose your own emblem",25);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button(head,"Close",close)
 title=LineEdit.new();title.text="My faction emblem";title.max_length=80;col.add_child(title)
 label(col,"Add shapes, drag them on the canvas, change their size and colour, and reorder the layers. SVG stays editable; PNG is the matching pixel export.")
 var tools=HFlowContainer.new();col.add_child(tools)
 for type in ["Circle","Rectangle","Triangle","Line"]:
  var kind:String=type;button(tools,"+ "+type,func():if shapes.size()<16:shapes.append({"type":kind,"x":128.0,"y":72.0,"w":48.0,"h":48.0,"color":"#d5b779"});selected=shapes.size()-1;render())
 button(tools,"Clear canvas",func():shapes.clear();render())
 var row=HBoxContainer.new();row.size_flags_vertical=Control.SIZE_EXPAND_FILL;row.add_theme_constant_override("separation",18);col.add_child(row)
 canvas=VectorCanvas.new();canvas.custom_minimum_size=Vector2(760,460);canvas.size_flags_vertical=Control.SIZE_EXPAND_FILL;canvas.editor=self;row.add_child(canvas)
 properties=VBoxContainer.new();properties.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(properties)
 status=label(col,"Screen artboard: 256 × 144 • transparent background • 16 editable shapes maximum.")
 var actions=HFlowContainer.new();col.add_child(actions);UI.accent(button(actions,"Save editable composition",save_document));button(actions,"Download SVG",func():download("svg"));button(actions,"Download PNG",func():download("png"))
 if on_capture.is_valid():button(actions,"Attach SVG + PNG to module",func():var value=document();if not value.is_empty():save_document();on_capture.call(value);status.text="Frozen vector source and PNG attached.")
 var stored=preload("res://scripts/profile_store.gd").read(PATH,valid)
 shapes=[{"type":"Circle","x":128.0,"y":72.0,"w":92.0,"h":92.0,"color":"#769eb5"},{"type":"Triangle","x":128.0,"y":72.0,"w":60.0,"h":62.0,"color":"#edd494"}]
 if not stored.is_empty():shapes=stored.settings.shapes.duplicate(true);title.text=stored.settings.title
 render()
static func valid(value:Variant)->bool:
 if not value is Dictionary or not value.get("settings") is Dictionary or not value.settings.get("shapes") is Array or value.settings.shapes.size()>16:return false
 if not value.settings.get("title") is String or value.settings.title.length()>80:return false
 for s in value.settings.shapes:
  if not s is Dictionary or s.get("type") not in ["Circle","Rectangle","Triangle","Line"] or not s.get("color") is String or not Color.html_is_valid(s.color):return false
  for key in ["x","y","w","h"]:
   if not (s.get(key) is int or s.get(key) is float) or not is_finite(float(s[key])) or s[key]<(4 if key in ["w","h"] else 0) or s[key]>256:return false
 return preload("res://scripts/learning_store.gd").valid_artifact({"kind":"graphic","value":value,"title":"Vector","time":"","origin":"Vector Studio","hash":preload("res://scripts/learning_store.gd").fingerprint(value)})
func render()->void:
 syncing=true
 for child in properties.get_children():properties.remove_child(child);child.queue_free()
 selected=clampi(selected,0,maxi(0,shapes.size()-1));picker=OptionButton.new();picker.custom_minimum_size.y=42;properties.add_child(picker)
 for n in shapes.size():picker.add_item(str(n+1)+" • "+shapes[n].type)
 if not shapes.is_empty():picker.select(selected)
 picker.item_selected.connect(func(index):selected=index;render())
 if not shapes.is_empty():
  var item:Dictionary=shapes[selected];colour=ColorPickerButton.new();colour.color=Color(item.color);colour.text="Shape colour";properties.add_child(colour);colour.color_changed.connect(func(c:Color):item.color="#"+c.to_html(false);canvas.queue_redraw())
  for key in ["x","y","w","h"]:
   var name:String=key;var line=HBoxContainer.new();properties.add_child(line);var text=label(line,{"x":"Position X","y":"Position Y","w":"Width","h":"Height"}[key]);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;var input=SpinBox.new();input.min_value=4 if key in ["w","h"] else 0;input.max_value=144 if key=="y" else 256;input.step=1;input.value=item[key];input.custom_minimum_size.x=110;line.add_child(input);input.value_changed.connect(func(v):item[name]=v;canvas.queue_redraw())
  button(properties,"Bring forward",func():if selected<shapes.size()-1:var value=shapes.pop_at(selected);selected+=1;shapes.insert(selected,value);render())
  button(properties,"Send backward",func():if selected>0:var value=shapes.pop_at(selected);selected-=1;shapes.insert(selected,value);render())
  button(properties,"Delete selected shape",func():shapes.remove_at(selected);render())
 label(properties,"Try the emblem small and large. Your source contains independent shapes, not a flattened drawing. Choose a brief, compare arrangements and explain what communicates best.",15)
 syncing=false;canvas.queue_redraw()
func document()->Dictionary:
 var body=""
 for s in shapes:
  var x=float(s.x);var y=float(s.y);var w=float(s.w);var h=float(s.h);var ink=str(s.color)
  match str(s.type):
   "Circle":body+='<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>' % [x,y,w/2,h/2,ink]
   "Rectangle":body+='<rect x="%s" y="%s" width="%s" height="%s" fill="%s"/>' % [x-w/2,y-h/2,w,h,ink]
   "Triangle":body+='<path d="M %s %s L %s %s L %s %s Z" fill="%s"/>' % [x,y-h/2,x+w/2,y+h/2,x-w/2,y+h/2,ink]
   "Line":body+='<path d="M %s %s L %s %s" stroke="%s" stroke-width="4"/>' % [x-w/2,y-h/2,x+w/2,y+h/2,ink]
 var svg='<svg xmlns="http://www.w3.org/2000/svg" width="256" height="144" viewBox="0 0 256 144">'+body+'</svg>';var image=Image.new()
 if image.load_svg_from_string(svg)!=OK:return {}
 return {"image":Marshalls.raw_to_base64(image.save_png_to_buffer()),"svg":svg,"settings":{"title":title.text,"shapes":shapes.duplicate(true),"width":256,"height":144}}
func save_document()->void:
 var d=document()
 if not valid(d):status.text="Composition could not be saved. Check the source limits.";return
 var result=preload("res://scripts/profile_store.gd").write(PATH,d);status.text="Editable vector composition saved." if result==OK else "Save failed; download your source."
func download(kind:String)->void:
 var d=document()
 if d.is_empty():return
 var bytes=d.svg.to_utf8_buffer() if kind=="svg" else Marshalls.base64_to_raw(d.image)
 if OS.has_feature("web"):JavaScriptBridge.download_buffer(bytes,"crossroads-emblem."+kind,"image/svg+xml" if kind=="svg" else "image/png")
 else:
  var dialog=FileDialog.new();dialog.access=FileDialog.ACCESS_FILESYSTEM;dialog.file_mode=FileDialog.FILE_MODE_SAVE_FILE;dialog.current_file="crossroads-emblem."+kind;add_child(dialog);dialog.file_selected.connect(func(path):var f=FileAccess.open(path,FileAccess.WRITE);if f!=null:f.store_buffer(bytes);f.close();dialog.queue_free());dialog.popup_centered(Vector2i(700,500))
func close()->void:game.menu=previous_menu;game.set_process(previous_process);queue_free()
func _process(_dt:float)->void:
 var view=get_viewport().get_visible_rect().size;panel.size=Vector2(1180,760);var fit=minf(1,minf((view.x-20)/1180,(view.y-20)/760));panel.scale=Vector2.ONE*fit;panel.position=(view-panel.size*fit)*.5
class VectorCanvas extends Control:
 var editor:Node
 var dragging=false
 var offset=Vector2.ZERO
 func _ready():mouse_filter=Control.MOUSE_FILTER_STOP;clip_contents=true
 func artboard()->Rect2:
  var extent=Vector2(256,144)*minf(size.x/256,size.y/144)
  return Rect2((size-extent)*.5,extent)
 func point()->Vector2:
  var rect=artboard();return (get_local_mouse_position()-rect.position)/rect.size*Vector2(256,144)
 func _gui_input(event):
  if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
   dragging=event.pressed
   if event.pressed:
    var p=point()
    for i in range(editor.shapes.size()-1,-1,-1):
     var s=editor.shapes[i]
     if Rect2(Vector2(s.x-s.w/2,s.y-s.h/2),Vector2(s.w,s.h)).grow(3).has_point(p):editor.selected=i;offset=Vector2(s.x,s.y)-p;editor.render();accept_event();return
    dragging=false
   else:editor.render()
  elif event is InputEventMouseMotion and dragging and not editor.shapes.is_empty():
   var p=(point()+offset).clamp(Vector2.ZERO,Vector2(256,144));var s=editor.shapes[editor.selected];s.x=snappedf(p.x,1);s.y=snappedf(p.y,1);queue_redraw();accept_event()
 func _draw():
  draw_rect(Rect2(Vector2.ZERO,size),Color("#243e47"))
  var rect=artboard();draw_rect(rect,Color("#19323b"))
  for x in range(0,257,16):draw_line(rect.position+Vector2(x/256.0*rect.size.x,0),rect.position+Vector2(x/256.0*rect.size.x,rect.size.y),Color("#2e4a52"),1)
  for y in range(0,145,16):draw_line(rect.position+Vector2(0,y/144.0*rect.size.y),rect.position+Vector2(rect.size.x,y/144.0*rect.size.y),Color("#2e4a52"),1)
  draw_set_transform(rect.position,0,rect.size/Vector2(256,144))
  for i in editor.shapes.size():
   var s=editor.shapes[i];var p=Vector2(s.x,s.y);var half=Vector2(s.w,s.h)*.5;var ink=Color(s.color)
   match str(s.type):
    "Circle":
     var points=PackedVector2Array()
     for n in 40:points.append(p+Vector2(cos(n*TAU/40),sin(n*TAU/40))*half)
     draw_colored_polygon(points,ink)
    "Rectangle":draw_rect(Rect2(p-half,half*2),ink)
    "Triangle":draw_colored_polygon(PackedVector2Array([p-Vector2(0,half.y),p+half,p+Vector2(-half.x,half.y)]),ink)
    "Line":draw_line(p-half,p+half,ink,4,true)
   if i==editor.selected:draw_rect(Rect2(p-half,half*2).grow(2),Color("#f0d398"),false,.7)
  draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
