extends Control
var frames:Array=[]
var textures:Array=[]
var clock=0.0
var interval=.18
var show_caption=true
func setup(encoded:Array)->void:
 frames=encoded.duplicate();textures.clear();custom_minimum_size=Vector2(130,140);texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;mouse_filter=Control.MOUSE_FILTER_IGNORE
 for frame in frames:
  if str(frame).is_empty():continue
  var img=Image.new()
  if img.load_png_from_buffer(Marshalls.base64_to_raw(str(frame)))==OK:textures.append(ImageTexture.create_from_image(img))
func _process(delta:float)->void:
 if not is_visible_in_tree():return
 clock+=delta;queue_redraw()
func _draw()->void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("#0c222b"))
 var side=minf(size.x-24,size.y-(34 if show_caption else 16));var rect=Rect2(Vector2((size.x-side)*.5,8),Vector2.ONE*side)
 if not textures.is_empty():draw_texture_rect(textures[int(clock/interval)%textures.size()],rect,false)
 if show_caption:draw_string(preload("res://assets/fonts/CrossroadsUI.ttf"),Vector2(12,size.y-10),"Frame "+str(int(clock/interval)%maxi(1,textures.size())+1),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#e8d19c"))
