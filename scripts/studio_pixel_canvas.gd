extends Control
signal changed
var image:Image
var ink=Color("#ffd778")
var tool="Pencil"
var history:Array=[]
var mask_image:Image
var texture:ImageTexture
var remote_cell=Vector2i(-1,-1)
var remote_stamp=0
var selection=Rect2i()
var select_start=Vector2i.ZERO
var painting=false
var last=Vector2i(-1,-1)
func _ready()->void:
 custom_minimum_size=Vector2(430,430);mouse_filter=Control.MOUSE_FILTER_STOP;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func load_png(encoded:String,side:int=32)->void:
 image=Image.create(side,side,false,Image.FORMAT_RGBA8);image.fill(Color.TRANSPARENT)
 if not encoded.is_empty():
  var imported=Image.new()
  if imported.load_png_from_buffer(Marshalls.base64_to_raw(encoded))==OK:image=imported;image.convert(Image.FORMAT_RGBA8)
 history.clear();mask_image=null;selection=Rect2i();queue_redraw()
func cell_size()->float:return minf(size.x/image.get_width(),size.y/image.get_height())
func origin()->Vector2:return (size-Vector2(image.get_size())*cell_size())*.5
func snapshot()->void:
 history.append(image.duplicate())
 if history.size()>24:history.pop_front()
func undo()->void:
 if not history.is_empty():image=history.pop_back();queue_redraw();changed.emit()
func edit_at(position:Vector2)->void:
 var cell=Vector2i((position-origin())/cell_size())
 if cell.x<0 or cell.y<0 or cell.x>=image.get_width() or cell.y>=image.get_height():return
 if cell==last and tool!="Fill":return
 if tool=="Select":
  if last==Vector2i(-1,-1):select_start=cell
  last=cell;selection=Rect2i(select_start,cell-select_start).abs();selection.size+=Vector2i.ONE;queue_redraw();return
 last=cell
 if tool=="Pick":ink=image.get_pixelv(cell);changed.emit();return
 if selection.has_area() and not selection.has_point(cell):return
 var color=Color.TRANSPARENT if tool=="Eraser" else ink
 if tool=="Fill":
  var before=image.get_pixelv(cell)
  if before==color:return
  var pending:Array[Vector2i]=[cell];image.set_pixelv(cell,color)
  while not pending.is_empty():
   var point=pending.pop_back()
   for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
    var next:Vector2i=point+offset
    if next.x>=0 and next.y>=0 and next.x<image.get_width() and next.y<image.get_height() and (not selection.has_area() or selection.has_point(next)) and image.get_pixelv(next)==before:image.set_pixelv(next,color);pending.append(next)
 else:image.set_pixelv(cell,color)
 queue_redraw();changed.emit()
func _gui_input(event:InputEvent)->void:
 if image==null:return
 if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  painting=event.pressed
  if painting:snapshot();last=Vector2i(-1,-1);edit_at(event.position)
  accept_event()
 elif event is InputEventMouseMotion and painting:edit_at(event.position);accept_event()
 elif event is InputEventScreenTouch:
  painting=event.pressed
  if painting:snapshot();last=Vector2i(-1,-1);edit_at(event.position)
  accept_event()
 elif event is InputEventScreenDrag and painting:edit_at(event.position);accept_event()
func transform_pose(action:String)->void:
 snapshot()
 if action in ["Mirror","Flip"]:
  var r=selection if selection.has_area() else Rect2i(Vector2i.ZERO,image.get_size());var part=image.get_region(r)
  if action=="Mirror":part.flip_x()
  else:part.flip_y()
  image.blit_rect(part,Rect2i(Vector2i.ZERO,part.get_size()),r.position)
 else:
  var copy=image.duplicate();image.fill(Color.TRANSPARENT)
  var offset={"←":Vector2i.LEFT,"→":Vector2i.RIGHT,"↑":Vector2i.UP,"↓":Vector2i.DOWN}.get(action,Vector2i.ZERO)
  image.blit_rect(copy,Rect2i(Vector2i.ZERO,copy.get_size()),offset)
 queue_redraw();changed.emit()
func encoded()->String:return Marshalls.raw_to_base64(image.save_png_to_buffer())
func _draw()->void:
 if image==null:return
 var step=cell_size();var start=origin()
 var block=maxi(1,int(image.get_width()/32))
 for y in range(0,image.get_height(),block):
  for x in range(0,image.get_width(),block):
   var rect=Rect2(start+Vector2(x,y)*step,Vector2(mini(block,image.get_width()-x),mini(block,image.get_height()-y))*step)
   draw_rect(rect,Color("#344954" if (int(x/block)+int(y/block))%2==0 else "#263b46"))
 var shown=image
 if mask_image!=null and mask_image.get_size()==image.get_size():
  shown=image.duplicate()
  for y in shown.get_height():
   for x in shown.get_width():var c=shown.get_pixel(x,y);shown.set_pixel(x,y,Color(c,c.a*mask_image.get_pixel(x,y).a))
 if texture==null or texture.get_size()!=Vector2(shown.get_size()):texture=ImageTexture.create_from_image(shown)
 else:texture.update(shown)
 draw_texture_rect(texture,Rect2(start,Vector2(image.get_size())*step),false)
 if selection.has_area():draw_rect(Rect2(start+Vector2(selection.position)*step,Vector2(selection.size)*step),Color("#ffe08a"),false,2)
 if remote_cell.x>=0:
  var at=start+(Vector2(remote_cell)+Vector2.ONE*.5)*step
  draw_circle(at,maxf(4,step*.65),Color("#76e5ee"),false,2);draw_line(at-Vector2(6,0),at+Vector2(6,0),Color("#76e5ee"),1)
 if step>=6:
  for x in image.get_width()+1:draw_line(start+Vector2(x*step,0),start+Vector2(x*step,image.get_height()*step),Color(0,0,0,.16))
  for y in image.get_height()+1:draw_line(start+Vector2(0,y*step),start+Vector2(image.get_width()*step,y*step),Color(0,0,0,.16))

func _input(event:InputEvent)->void:
 if (event is InputEventMouseButton or event is InputEventScreenTouch) and not event.pressed:painting=false
func _notification(what:int)->void:
 if what==NOTIFICATION_APPLICATION_FOCUS_OUT:painting=false

func _process(_delta:float)->void:
 if remote_cell.x>=0 and Time.get_ticks_msec()-remote_stamp>1200:remote_cell=Vector2i(-1,-1);queue_redraw()
