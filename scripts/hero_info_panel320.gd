extends CanvasLayer
signal dismissed
var frame:PanelContainer
var closer:Button
var previous_focus:Control

func skin(fill:String,border:String,padding:int=18)->StyleBoxFlat:
 var s:=StyleBoxFlat.new()
 s.bg_color=Color(fill);s.border_color=Color(border)
 s.set_border_width_all(1);s.set_corner_radius_all(12);s.set_content_margin_all(padding)
 return s

func text(parent:Node,value:String,size:int,color:String)->Label:
 var l:=Label.new();l.text=value;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",Color(color))
 l.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(l);return l

func open(parent:Node,title:String,subtitle:String,body:String,portrait:Texture2D=null,section:String="HERO CHRONICLE")->void:
 layer=80;parent.add_child(self);previous_focus=get_viewport().gui_get_focus_owner()
 var shade:=ColorRect.new();shade.color=Color(0.015,0.035,0.05,.82)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);shade.mouse_filter=Control.MOUSE_FILTER_STOP;add_child(shade)
 frame=PanelContainer.new();frame.add_theme_stylebox_override("panel",skin("#102b34","#ba9362",26));add_child(frame)
 var col:=VBoxContainer.new();col.add_theme_constant_override("separation",16);frame.add_child(col)
 var top:=HBoxContainer.new();col.add_child(top)
 text(top,section,14,"#dfb779")
 closer=Button.new();closer.text="Close  ×";closer.custom_minimum_size=Vector2(100,40)
 for state in ["normal","hover","pressed","focus"]:
  closer.add_theme_stylebox_override(state,skin("#294d58" if state!="normal" else "#193b46","#efca8d" if state=="focus" else "#627f85",10))
 closer.add_theme_color_override("font_color",Color("#fff1d0"));closer.pressed.connect(close);top.add_child(closer)
 var identity:=HBoxContainer.new();identity.add_theme_constant_override("separation",22);col.add_child(identity)
 if portrait!=null:
  var backing:=PanelContainer.new();backing.add_theme_stylebox_override("panel",skin("#183e48","#846e51",8));identity.add_child(backing)
  var pic:=TextureRect.new();pic.texture=portrait;pic.custom_minimum_size=Vector2(112,128)
  pic.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;pic.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  pic.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;backing.add_child(pic)
 var heading:=VBoxContainer.new();heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;identity.add_child(heading)
 heading.alignment=BoxContainer.ALIGNMENT_CENTER
 text(heading,title,28,"#f5e5bd");text(heading,subtitle,16,"#9bc5cb")
 var rule:=HSeparator.new();rule.add_theme_stylebox_override("separator",skin("#806f4f","#806f4f",0));col.add_child(rule)
 var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.custom_minimum_size.y=150;col.add_child(scroll)
 var copy:=VBoxContainer.new();copy.size_flags_horizontal=Control.SIZE_EXPAND_FILL;copy.add_theme_constant_override("separation",14);scroll.add_child(copy)
 for paragraph in body.split("\n\n"):
  var l:=text(copy,paragraph,19,"#e0e9e6");l.add_theme_constant_override("line_spacing",5)
 text(col,"CROSSROADS  /  REALMS BEYOND",12,"#8aa9ab")
 layout();closer.grab_focus()

func layout()->void:
 if frame==null:return
 var view:=get_viewport().get_visible_rect().size
 frame.size=Vector2(720,480);frame.scale=Vector2.ONE*minf(1.0,minf((view.x-24)/720,(view.y-24)/480))
 frame.position=(view-frame.size*frame.scale)*.5

func _process(_delta:float)->void:layout()
func _input(event:InputEvent)->void:
 if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
  get_viewport().set_input_as_handled();close()
func close()->void:
 dismissed.emit()
 if is_instance_valid(previous_focus):previous_focus.grab_focus()
 queue_free()
