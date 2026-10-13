extends CanvasLayer
## Small vector layout exercise. SVG source and raster PNG stay paired.
const UI=preload("res://scripts/studio_ui.gd")
var page:Node
var panel:PanelContainer
var preview:TextureRect
var title:LineEdit
var colour:ColorPickerButton
var accent:ColorPickerButton
var shape:OptionButton
var align:OptionButton
var latest:Dictionary={}
func setup(owner:Node)->void:
 page=owner;layer=115;panel=PanelContainer.new();panel.size=Vector2(640,620);add_child(panel);UI.apply(panel)
 var col=VBoxContainer.new();panel.add_child(col);page.label(col,"VECTOR CARD • shape, contrast, rhythm",23)
 page.label(col,"Create a scalable emblem and its PNG export. SVG stores shapes; PNG stores pixels. Explain typography in your journal or attach a title card made in another tool.",16)
 title=LineEdit.new();title.placeholder_text="Asset title";title.text="My guild emblem";title.max_length=80;col.add_child(title)
 var row=HBoxContainer.new();col.add_child(row);colour=ColorPickerButton.new();colour.color=Color("#173544");colour.text="Background";row.add_child(colour);accent=ColorPickerButton.new();accent.color=Color("#e2bc71");accent.text="Accent";row.add_child(accent)
 shape=OptionButton.new();for text in ["Circle & rings","Shield & chevron","Repeating tiles"]:shape.add_item(text)
 col.add_child(shape);align=OptionButton.new();for text in ["Centred balance","Left emphasis","Right emphasis"]:align.add_item(text)
 col.add_child(align);preview=TextureRect.new();preview.custom_minimum_size=Vector2(400,200);preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;col.add_child(preview)
 page.button(col,"Attach SVG + PNG to this assignment",capture);page.button(col,"Close",queue_free)
 for pick in [shape,align]:pick.item_selected.connect(func(_i:int):render())
 for pick in [colour,accent]:pick.color_changed.connect(func(_c:Color):render())
 title.text_changed.connect(func(_t:String):render());render()
func render()->void:
 var x=[128,72,184][align.selected];var bg=colour.color.to_html(false);var fg=accent.color.to_html(false)
 var body='<rect width="256" height="144" fill="#'+bg+'"/>'
 match shape.selected:
  0:body+='<circle cx="'+str(x)+'" cy="72" r="44" fill="none" stroke="#'+fg+'" stroke-width="5"/><circle cx="'+str(x)+'" cy="72" r="25" fill="#'+fg+'"/>'
  1:body+='<path d="M '+str(x-42)+' 27 L '+str(x+42)+' 27 L '+str(x+35)+' 92 L '+str(x)+' 119 L '+str(x-35)+' 92 Z" fill="#'+fg+'"/>'+'<path d="M '+str(x-22)+' 69 L '+str(x)+' 47 L '+str(x+22)+' 69" fill="none" stroke="#'+bg+'" stroke-width="5"/>'
  2:
   for n in 5:body+='<rect x="'+str(20+n*46)+'" y="'+str(45+(n%2)*16)+'" width="28" height="28" rx="5" fill="#'+fg+'"/>'
 var svg='<svg xmlns="http://www.w3.org/2000/svg" width="256" height="144" viewBox="0 0 256 144">'+body+'</svg>'
 var image=Image.new()
 if image.load_svg_from_string(svg)!=OK:return
 preview.texture=ImageTexture.create_from_image(image);latest={"image":Marshalls.raw_to_base64(image.save_png_to_buffer()),"svg":svg,"settings":{"title":title.text,"shape":shape.selected,"align":align.selected,"background":bg,"accent":fg,"width":256,"height":144}}
func capture()->void:
 var issue=preload("res://scripts/learning_store.gd").attach(page.data,page.module,"graphic",latest,title.text,"Vector Card • original layout")
 page.message.text="SVG and PNG attached." if issue.is_empty() else issue;page.render();queue_free()
func _process(_dt:float)->void:
 var view=get_viewport().get_visible_rect().size;var fit=minf(1,minf((view.x-24)/panel.size.x,(view.y-24)/panel.size.y));panel.scale=Vector2.ONE*fit;panel.position=(view-panel.size*fit)*.5
